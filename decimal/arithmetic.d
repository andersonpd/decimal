/**
 *
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */
/*			Copyright Paul D. Anderson 2009 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *	  (See accompanying file LICENSE_1_0.txt or copy at
 *			http://www.boost.org/LICENSE_1_0.txt)
 */

// TODO: ensure context flags are being set and cleared properly.

// TODO: opEquals unit test should include numerically equal testing.

// TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// TODO: to/from real or double (float) values needs definition and implementation.

module decimal.arithmetic;

import decimal.context;
import decimal.conv : isDecimal, isFixedDecimal, toBigDecimal;
import decimal.decimal;
import decimal.rounding;

import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;
import std.string;

unittest {
	writeln("-------------------");
	writeln("arithmetic....begin");
	writeln("-------------------");
}

//--------------------------------
// classification functions
//--------------------------------

/**
 * Returns a string indicating the class and sign of the number.
 * Classes are: sNaN, NaN, Infinity, Subnormal, Zero, Normal.
 * Can be used by any decimal number
 */
public string classify(T)(const T arg) if (isDecimal!T) {
	if (arg.isFinite) {
		if (arg.isZero) 	 { return arg.sign ? "-Zero" : "+Zero"; }
		if (arg.isNormal)	 { return arg.sign ? "-Normal" : "+Normal"; }
		if (arg.isSubnormal) { return arg.sign ? "-Subnormal" : "+Subnormal"; }
	}
	if (arg.isInfinite)  { return arg.sign ? "-Infinity" : "+Infinity"; }
	if (arg.isSignaling) { return "sNaN"; }
	return "NaN";
}

unittest {
	BigDecimal num;
	num = BigDecimal("Inf");
	assertEqual(classify(num), "+Infinity");
	num = BigDecimal("1E-10");
	assertTrue(classify(num) == "+Normal");
	num = BigDecimal("-0");
	assertTrue(classify(num) == "-Zero");
	num = BigDecimal("-0.1E-99");
	assertTrue(classify(num) == "-Subnormal");
	num = BigDecimal("NaN");
	assertTrue(classify(num) == "NaN");
	num = BigDecimal("sNaN");
	assertTrue(classify(num) == "sNaN");
}

//--------------------------------
// copy functions
//--------------------------------

/**
 * Returns a copy of the operand.
 * The copy is unaffected by context; no flags are changed.
 */
public T copy(T)(const T arg) if (isDecimal!T) {
	return arg.dup;
}

unittest {
	BigDecimal num, expect;
	num  = BigDecimal("2.1");
	expect = BigDecimal("2.1");
	assertTrue(compareTotal(copy(num),expect) == 0);
	num  = BigDecimal("-1.00");
	expect = BigDecimal("-1.00");
	assertTrue(compareTotal(copy(num),expect) == 0);
}

/**
 * Returns a copy of the operand with a positive sign.
 * The copy is unaffected by context; no flags are changed.
 */
public T copyAbs(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = false;
	return copy;
}

unittest {
	BigDecimal num, expect;
	num  = 2.1;
	expect = 2.1;
	assertTrue(compareTotal(copyAbs(num),expect) == 0);
	num  = BigDecimal("-1.00");
	expect = BigDecimal("1.00");
	assertTrue(compareTotal(copyAbs(num),expect) == 0);
}

/**
 * Returns a copy of the operand with the sign inverted.
 * The copy is unaffected by context; no flags are changed.
 */
public T copyNegate(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = !arg.sign;
	return copy;
}

unittest {
	BigDecimal num	= "101.5";
	BigDecimal expect = "-101.5";
	assertTrue(compareTotal(copyNegate(num),expect) == 0);
}

/**
 * Returns a copy of the first operand with the sign of the second operand.
 * The copy is unaffected by context; no flags are changed.
 */
public T copySign(T)(const T arg1, const T arg2) if (isDecimal!T) {
	T copy = arg1.dup;
	copy.sign = arg2.sign;
	return copy;
}

unittest {
	BigDecimal num1, num2, expect;
	num1 = 1.50;
	num2 = 7.33;
	expect = 1.50;
	assertTrue(compareTotal(copySign(num1, num2),expect) == 0);
	num2 = -7.33;
	expect = -1.50;
	assertTrue(compareTotal(copySign(num1, num2),expect) == 0);
}

// UNREADY: quantize. Logic.
/**
 * Returns the number which is equal in value and sign
 * to the first operand and which has its exponent set
 * to be equal to the exponent of the second operand.
 */
public T quantize(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {

	T result;
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// if one argument is infinite and the other is not...
	if (arg1.isInfinite != arg2.isInfinite()) {
		return setInvalidFlag!T();
	}
	// if both arguments are infinite
	if (arg1.isInfinite() && arg2.isInfinite()) {
		return arg1.dup;
	}
	result = arg1;
	int diff = arg1.exponent - arg2.exponent;

	if (diff == 0) {
		return result;
	}

	// TODO: this shift can cause integer overflow for fixed size decimals
	if (diff > 0) {
		result.coefficient = decShl(result.coefficient, diff);
		result.digits = result.digits + diff;
		result.exponent = arg2.exponent;
		if (result.digits > context.precision) {
			result = T.nan;
		}
		return result;
	}
	else {
		uint precision = (-diff > arg1.digits) ? 0 : arg1.digits + diff;
		DecimalContext tempContext = context.setPrecision(precision);
		round!T(result, tempContext);
		result.exponent = arg2.exponent;
		if (result.isZero && arg1.isSigned) {
			result.sign = true;
		}
		return result;
	}
}

unittest {
    auto context = testContext;
	BigDecimal arg1, arg2, actual, expect;
	string str;
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("0.001");
	expect = BigDecimal("2.170");
	actual = quantize!BigDecimal(arg1, arg2, context);
	assertTrue(actual == expect);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("0.01");
	expect = BigDecimal("2.17");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual == expect);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("0.1");
	expect = BigDecimal("2.2");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual == expect);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("1e+0");
	expect = BigDecimal("2");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual == expect);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("1e+1");
	expect = BigDecimal("0E+1");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("-Inf");
	arg2 = BigDecimal("Infinity");
	expect = BigDecimal("-Infinity");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual == expect);
	arg1 = BigDecimal("2");
	arg2 = BigDecimal("Infinity");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("-0.1");
	arg2 = BigDecimal("1");
	expect = BigDecimal("-0");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("-0");
	arg2 = BigDecimal("1e+5");
	expect = BigDecimal("-0E+5");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("+35236450.6");
	arg2 = BigDecimal("1e-2");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("-35236450.6");
	arg2 = BigDecimal("1e-2");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e-1");
	expect = BigDecimal( "217.0");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+0");
	expect = BigDecimal("217");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+1");
	expect = BigDecimal("2.2E+2");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+2");
	expect = BigDecimal("2E+2");
	actual = quantize(arg1, arg2, context);
	assertTrue(actual.toString() == expect.toString());
	assertTrue(actual == expect);
}

/**
 * Returns the integer which is the exponent of the magnitude
 * of the most significant digit of the operand.
 * (As though the operand were truncated to a single digit
 * while maintaining the value of that digit and without
 * limiting the resulting exponent).
 */
public T logb(T)(const T arg) {

	T result;

	if (invalidOperand!T(arg, result)) {
		return result;
	}
	if (arg.isInfinite) {
		return T.infinity;
	}
	if (arg.isZero) {
		contextFlags.setFlags(DIVISION_BY_ZERO);
		result = T.infinity(true);
		return result;
	}
	int expo = arg.digits + arg.exponent - 1;
	return T(cast(long)expo);
}

unittest {
	BigDecimal num, expd;
	num = BigDecimal("250");
	expd = BigDecimal("2");
	assertTrue(logb(num) == expd);
}

/**
 * If the first operand is infinite then that operand is returned,
 * otherwise the result is the first operand modified by
 * adding the value of the second operand to its exponent.
 * The result may overflow or underflow.
 */
public T scaleb(T)(const T arg1, const T arg2) if (isDecimal!T) {
	T result;
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	if (arg1.isInfinite) {
		return arg1.dup;
	}
	int expo = arg2.exponent;
	if (expo != 0 /* && not within range */) {
		result = setInvalidFlag!T();
		return result;
	}
	result = arg1;
	int scale = cast(int)arg2.coefficient.toInt;
	if (arg2.isSigned) {
		scale = -scale;
	}
	result.exponent = result.exponent + scale;
	return result;
}

unittest {
	auto num1 = BigDecimal("7.50");
	auto num2 = BigDecimal("-2");
	auto expd = BigDecimal("0.0750");
	assertTrue(scaleb(num1, num2) == expd);
}

//--------------------------------
// absolute value, unary plus and minus functions
//--------------------------------

// UNREADY: reduce. Description. Flags.
/**
 * Reduces operand to simplest form. Trailing zeros are removed.
 */
public T reduce(T)(const T arg) if (isDecimal!T) {
	T result;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
	if (!result.isFinite()) {
		return result;
	}

	// TODO: doing this in bigints when the coefficient is ulong or uint
	// is a big waste
	auto temp = result.coefficient % 10;
	while (result.coefficient != 0 && temp == 0) {
		result.exponent = result.exponent + 1;
		result.coefficient = result.coefficient / 10;
		temp = result.coefficient % 10;
	}
	if (result.coefficient == 0) {
		if (result.isSigned) {
			result = copyNegate(T.zero);
		}
		else {
			result = T.zero;
		}
		result.exponent = 0;
	}
	result.digits = numDigits(result.coefficient);
	return result;
}

unittest {
	BigDecimal num, red;
	string str;
	num = BigDecimal("1.200");
	str = "1.2";
	red = reduce(num);
	assertTrue(red.toString == str);
}

/**
 *	  Absolute value -- returns a copy and clears the negative sign, if needed.
 *	  This operation rounds the number and may set flags.
 *	  Result is equivalent to plus(num) for positive numbers
 *	  and to minus(num) for negative numbers.
 *	  To return the absolute value without rounding or setting flags
 *	  use the "copyAbs" function.
 */
public T abs(T)(const T arg, DecimalContext context) if (isDecimal!T) {
	T result;
	if(invalidOperand!T(arg, result)) {
		return result;
	}
	result = copyAbs!T(arg);
	round(result, context);
	return result;
}

unittest {
	BigDecimal num;
	BigDecimal expect;
	num = BigDecimal("-Inf");
	expect = BigDecimal("Inf");
	assertTrue(abs(num, testContext) == expect);
	num = 101.5;
	expect = 101.5;
	assertTrue(abs(num, testContext) == expect);
	num = -101.5;
	assertTrue(abs(num, testContext) == expect);
}

/**
 *	Returns the sign of the number: -1, 0, -1;
 */
public int sgn(T)(const T arg) if (isDecimal!T) {
	if (arg.isZero) return 0;
	return arg.isNegative ? -1 : 1;
}

unittest {
	BigDecimal big;
	big = -123;
	assertTrue(sgn(big) == -1);
	big = 2345;
	assertTrue(sgn(big) == 1);
	big = BigDecimal("0.0000");
	assertTrue(sgn(big) == 0);
	big = BigDecimal.infinity(true);
	assertTrue(sgn(big) == -1);
}

/**
 *	  Unary plus -- returns a copy with same sign as the number.
 *	  Does NOT return a positive copy of a negative number!
 *	  This operation rounds the number and may set flags.
 *	  Result is equivalent to add('0', number).
 *	  To copy without rounding or setting flags use the "copy" function.
 */
public T plus(T)(const T arg, DecimalContext context) if (isDecimal!T) {
	T result;
	if(invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
	round(result, context);
	return result;
}

unittest {
	BigDecimal zero = BigDecimal.zero;
	BigDecimal num, expect, actual;
	num = 1.3;
	expect = add(zero, num, testContext);
	actual = plus(num, testContext);
	assertTrue(plus(num, testContext) == expect);
	num = -1.3;
	expect = add(zero, num, testContext);
	assertTrue(plus(num, testContext) == expect);
}

/**
 *	  Unary minus -- returns a copy with the opposite sign.
 *	  This operation rounds the number and may set flags.
 *	  Result is equivalent to subtract('0', number).
 *	  To copy without rounding or setting flags use the "copyNegate" function.
 */
public T minus(T)(const T arg, DecimalContext context) if (isDecimal!T) {
	T result;
	if(invalidOperand!T(arg, result)) {
		return result;
	}
	result = copyNegate!T(arg);
	round(result, context);
	return result;
}

unittest {
	BigDecimal zero = BigDecimal(0);
	BigDecimal num, expect;
	num = 1.3;
	expect = subtract(zero, num, testContext);
	assertTrue(minus(num, testContext) == expect);
	num = -1.3;
	expect = subtract(zero, num, testContext);
	assertTrue(minus(num, testContext) == expect);
}

//-----------------------------------
// next-plus, next-minus, next-toward
//-----------------------------------

// UNREADY: nextPlus. Description. Unit Tests.
public T nextPlus(T)(const T arg1, DecimalContext context) if (isDecimal!T) {
	T result;
	if (invalidOperand!T(arg1, result)) {
		return result;
	}
	if (arg1.isInfinite) {
		if (arg1.sign) {
			return copyNegate!T(T.max(context));
		}
		else {
			return arg1.dup;
		}
	}
	int adjx = arg1.exponent + arg1.digits - context.precision;
	if (adjx < context.eTiny) {
			return T(0L, context.eTiny);
	}
	T arg2 = T(1L, adjx);
	result = add!T(arg1, arg2, context, true); // FIXTHIS: really? does this guarantee no flags?
	// FIXTHIS: should be context.max
	if (result > T.max(context)) {
		result = T.infinity;
	}
	return result;
}

unittest {
	BigDecimal num, expect;
	num = 1;
	expect = BigDecimal("1.00000001");
	assertTrue(nextPlus(num, testContext) == expect);
	num = 10;
	expect = BigDecimal("10.0000001");
	assertTrue(nextPlus(num, testContext) == expect);
}

// UNREADY: nextMinus. Description. Unit Tests.
public T nextMinus(T)(const T arg, DecimalContext context) if (isDecimal!T) {

	T result;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	if (arg.isInfinite) {
		if (!arg.sign) {
			return T.max(context);
		}
		else {
			return arg.dup;
		}
	}
	// This is necessary to catch the special case where coefficient == 1
	T red = reduce!T(arg);
	int adjx = red.exponent + red.digits - context.precision;
	if (arg.coefficient == 1) adjx--;
	if (adjx < context.eTiny) {
		return T(0L, context.eTiny);
	}
	T addend = T(1, adjx);
	result = subtract!T(arg, addend, context, true);	//TODO: are the flags set/not set correctly?
		if (result < copyNegate!T(T.max(context))) {
		result = copyNegate!T(T.infinity);
	}
	return result;
}

unittest {
	BigDecimal num, expect;
	num = 1;
	expect = 0.999999999;
	assertTrue(nextMinus(num, testContext) == expect);
	num = -1.00000003;
	expect = -1.00000004;
	assertTrue(nextMinus(num, testContext) == expect);
}

// UNREADY: nextToward. Description. Unit Tests.
// NOTE: rounds
public T nextToward(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	T result;
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// compare them but don't round
	int comp = compare!T(arg1, arg2, context);
	if (comp < 0) return nextPlus!T(arg1, context);
	if (comp > 0) return nextMinus!T(arg1, context);
	result = copySign!T(arg1, arg2);
	round(result, context);
	return result;
}

unittest {
	BigDecimal arg1, arg2, expect;
	arg1 = 1;
	arg2 = 2;
	expect = 1.00000001;
	assertTrue(nextToward(arg1, arg2, testContext) == expect);
	arg1 = -1.00000003;
	arg2 = 0;
	expect = -1.00000002;
	assertTrue(nextToward(arg1, arg2, testContext) == expect);
}

//--------------------------------
// comparison functions
//--------------------------------

/**
 * Returns true if the numbers have the same exponent.
 * No context flags are set.
 * If either operand is NaN or Infinity, returns true if and only if
 * both operands are NaN or Infinity, respectively.
 */
public bool sameQuantum(T)(const T arg1, const T arg2) if (isDecimal!T) {
	if (arg1.isNaN || arg2.isNaN) {
		return arg1.isNaN && arg2.isNaN;
	}
	if (arg1.isInfinite || arg2.isInfinite) {
		return arg1.isInfinite && arg2.isInfinite;
	}
	return arg1.exponent == arg2.exponent;
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = 2.17;
	arg2 = 0.001;
	assertTrue(!sameQuantum(arg1, arg2));
	arg2 = 0.01;
	assertTrue(sameQuantum(arg1, arg2));
	arg2 = 0.1;
	assertTrue(!sameQuantum(arg1, arg2));
}

// UNREADY: compare
public int compare(T)(const T arg1, const T arg2, DecimalContext context,
		bool rounded = true) if (isDecimal!T) {

	// any operation with a signaling NaN is invalid.
	// if both are signaling, return as if arg1 > arg2.
	if (arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return arg1.isSignaling ? 1 : -1;
	}

	// NaN returns > any number, including NaN
	// if both are NaN, return as if arg1 > arg2.
	if (arg1.isNaN || arg2.isNaN) {
		return arg1.isNaN ? 1 : -1;
	}

	// if signs differ, just compare the signs
	if (arg1.sign != arg2.sign) {
		// check for zeros: +0 and -0 are equal
		if (arg1.isZero && arg2.isZero) {
			return 0;
		}
		return arg1.sign ? -1 : 1;
	}

	// otherwise, compare the numbers numerically
	int diff = (arg1.exponent + arg1.digits) - (arg2.exponent + arg2.digits);
	if (!arg1.sign) {
		if (diff > 0) return 1;
		if (diff < 0) return -1;
	}
	else {
		if (diff > 0) return -1;
		if (diff < 0) return 1;
	}

	// when all else fails, subtract
	T result = subtract!T(arg1, arg2, context, rounded);

	// test the coefficient
	// result.isZero may not be true if the result hasn't been rounded
	if (result.coefficient == 0) {
		return 0;
	}
	return result.sign ? -1 : 1;
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = BigDecimal(2.1);
	arg2 = BigDecimal("3");
	assertTrue(compare(arg1, arg2, testContext) == -1);
	arg1 = 2.1;
	arg2 = BigDecimal(2.1);
	assertTrue(compare(arg1, arg2, testContext) == 0);
}

/**
 * Returns true if this decimal number is equal to the specified decimal number.
 * A NaN is not equal to any number, not even to another NaN.
 * Infinities are equal if they have the same sign.
 * Zeros are equal regardless of sign.
 * Finite numbers are equal if they are numerically equal
 * to the current precision.
 * A decimal NaN is not equal to itself (this != this).
 */
public bool equals(T)(const T arg1, const T arg2, DecimalContext context,
		const bool rounded = true) if (isDecimal!T) {

	// any operation with a signaling NaN is invalid.
	// NaN is never equal to anything, not even another NaN
	if (arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return false;
	}

	// if either is NaN...
	if (arg1.isNaN || arg2.isNaN) return false;

	// if either is infinite...
	if (arg1.isInfinite || arg2.isInfinite) {
		return (arg1.isInfinite && arg2.isInfinite && arg1.isSigned == arg2.isSigned);
	}

	// if either is zero...
	if (arg1.isZero || arg2.isZero) {
		return (arg1.isZero && arg2.isZero);
	}

	// if their signs differ...
	if (arg1.sign != arg2.sign) {
		return false;
	}

	int diff = (arg1.exponent + arg1.digits) - (arg2.exponent + arg2.digits);
	if (diff != 0) {
		return false;
	}

	// if they have the same representation, they are equal
	auto op1c = arg1.coefficient;
	auto op2c = arg2.coefficient;
	if (arg1.exponent == arg2.exponent && op1c == op2c) { //arg1.coefficient == arg2.coefficient) {
		return true;
	}

	// otherwise they are equal if they represent the same value
	T result = subtract!T(arg1, arg2, context, rounded);
	return result.coefficient == 0;
}

// NOTE: change these to true opEquals calls.
unittest {
	BigDecimal arg1, arg2;
	arg1 = 123.4567;
	arg2 = 123.4568;
	assertTrue(arg1 != arg2);
	arg2 = 123.4567;
	assertTrue(arg1 == arg2);
}

// UNREADY: compareSignal. Unit Tests.
/**
 * Compares the numeric values of two numbers. CompareSignal is identical to
 * compare except that quiet NaNs are treated as if they were signaling.
 */
public int compareSignal(T) (const T arg1, const T arg2,
		DecimalContext context, bool rounded = true) if (isDecimal!T) {

	// any operation with NaN is invalid.
	// if both are NaN, return as if arg1 > arg2.
	if (arg1.isNaN || arg2.isNaN) {
		contextFlags.setFlags(INVALID_OPERATION);
		return arg1.isNaN ? 1 : -1;
	}
	return (compare!T(arg1, arg2, context, rounded));
}

// UNREADY: compareTotal
/// Returns 0 if the numbers are equal and have the same representation
// NOTE: no context
// TODO: just compare signs, coefficients and exponenents.
public int compareTotal(T)(const T arg1, const T arg2) if (isDecimal!T) {

	int ret1 =	1;
	int ret2 = -1;

	// if signs differ...
	if (arg1.sign != arg2.sign) {
		return !arg1.sign ? ret1 : ret2;
	}

	// if both numbers are signed swap the return values
	if (arg1.sign) {
		ret1 = -1;
		ret2 =	1;
	}

	// if either is zero...
	if (arg1.isZero || arg2.isZero) {
		// if both are zero compare exponents
		if (arg1.isZero && arg2.isZero) {
			auto result = arg1.exponent - arg2.exponent;
			if (result == 0) return 0;
			return (result > 0) ? ret1 : ret2;
		}
		return arg1.isZero ? ret1 : ret2;
	}

	// if either is infinite...
	if (arg1.isInfinite || arg2.isInfinite) {
		if (arg1.isInfinite && arg2.isInfinite) {
			return 0;
		}
		return arg1.isInfinite ? ret1 : ret2;
	}

	// if either is quiet...
	if (arg1.isQuiet || arg2.isQuiet) {
		// if both are quiet compare payloads.
		if (arg1.isQuiet && arg2.isQuiet) {
			auto result = arg1.payload - arg2.payload;
			if (result == 0) return 0;
			return (result > 0) ? ret1 : ret2;
		}
		return arg1.isQuiet ? ret1 : ret2;
	}

	// if either is signaling...
	if (arg1.isSignaling || arg2.isSignaling) {
		// if both are signaling compare payloads.
		if (arg1.isSignaling && arg2.isSignaling) {
			auto result = arg1.payload - arg2.payload;
			if (result == 0) return 0;
			return (result > 0) ? ret1 : ret2;
		}
		return arg1.isSignaling ? ret1 : ret2;
	}

	// if both exponents are equal, any difference is in the coefficient
	if (arg1.exponent == arg2.exponent) {
		auto result = arg1.coefficient - arg2.coefficient;
		if (result == 0) return 0;
		return (result > 0) ? ret1 : ret2;
	}

	// if the (finite) numbers have different magnitudes...
	int diff = (arg1.exponent + arg1.digits) - (arg2.exponent + arg2.digits);
	if (diff > 0) return ret1;
	if (diff < 0) return ret2;


	// we know the numbers have the same magnitude;
	// align the coefficients for comparison
	diff = arg1.exponent - arg2.exponent;
	BigInt mant1 = arg1.coefficient;
	BigInt mant2 = arg2.coefficient;
	if (diff > 0) {
		mant1 = decShl(mant1, diff);
	}
	else if (diff < 0) {
		mant2 = decShl(mant2, -diff);
	}
	auto result = mant1 - mant2;

	// if equal after alignment, compare the original exponents
	if (result == 0) {
		return (arg1.exponent > arg2.exponent) ? ret1 : ret2;
	}
	// otherwise return the numerically larger
	return (result > 0) ? ret1 : ret2;
}

unittest {
	BigDecimal arg1, arg2;
	int result;
	arg1 = BigDecimal("12.30");
	arg2 = BigDecimal("12.3");
	result = compareTotal(arg1, arg2);
	assertTrue(result == -1);
	arg1 = BigDecimal("12.30");
	arg2 = BigDecimal("12.30");
	result = compareTotal(arg1, arg2);
	assertTrue(result == 0);
	arg1 = BigDecimal("12.3");
	arg2 = BigDecimal("12.300");
	result = compareTotal(arg1, arg2);
	assertTrue(result == 1);
}

// UNREADY: compareTotalMagnitude
int compareTotalMagnitude(T)(const T arg1, const T arg2) if (isDecimal!T) {
	return compareTotal(copyAbs!T(arg1), copyAbs!T(arg2));
}

// UNREADY: max. Flags.
// TODO: this is where the need for flags comes in.
/**
 * Returns the maximum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is larger than a NaN.
 * If they are not numerically equal, the larger is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the positive sign is returned.
 * 2) If they are positive, the one with the larger exponent is returned.
 * 3) If they are negative, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
// NOTE: flags only
const(T) max(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	// if both are NaNs or either is an sNan, return NaN.
	if (arg1.isNaN && arg2.isNaN || arg1.isSignaling || arg2.isSignaling) {
		return T.nan;
	}
	// if one op is a quiet NaN return the other
	if (arg1.isQuiet || arg2.isQuiet) {
		return (arg1.isQuiet) ? arg2 : arg1;
	}
	// if the signs differ, return the unsigned operand
	if (arg1.sign != arg2.sign) {
		return arg1.sign ? arg2 : arg1;
	}
	// if not numerically equal, return the larger
	int comp = compare!T(arg1, arg2, context);
	if (comp != 0) {
		return comp > 0 ? arg1 : arg2;
	}
	// if they have the same exponent they are identical, return either
	if (arg1.exponent == arg2.exponent) {
		return arg1;
	}
	// if they are non-negative, return the one with larger exponent.
	if (arg1.sign == 0) {
		return arg1.exponent > arg2.exponent ? arg1 : arg2;
	}
	// else they are negative; return the one with smaller exponent.
	return arg1.exponent > arg2.exponent ? arg2 : arg1;
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = 3;
	arg2 = 2;
	assertTrue(max(arg1, arg2, testContext) == arg1);
	arg1 = -10;
	arg2 = 3;
	assertTrue(max(arg1, arg2, testContext) == arg2);
}

// UNREADY: maxMagnitude. Flags.
const(T) maxMagnitude(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	return max(copyAbs!T(arg1), copyAbs!T(arg2), context);
}

// UNREADY: min. Flags.
/**
 * Returns the minimum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is smaller than a NaN.
 * If they are not numerically equal, the smaller is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the negative sign is returned.
 * 2) If they are negative, the one with the larger exponent is returned.
 * 3) If they are positive, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
const(T) min(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	// if both are NaNs or either is an sNan, return NaN.
	if (arg1.isNaN && arg2.isNaN || arg1.isSignaling || arg2.isSignaling) {
/*		  BigDecimal result;
		result.flags = INVALID_OPERATION;*/
		return T.nan;
	}
	// if one op is a quiet NaN return the other
	if (arg1.isQuiet || arg2.isQuiet) {
		return (arg1.isQuiet) ? arg2 : arg1;
	}
	// if the signs differ, return the unsigned operand
	if (arg1.sign != arg2.sign) {
		return arg1.sign ? arg1 : arg2;
	}
	// if not numerically equal, return the smaller
	int comp = compare!T(arg1, arg2, context);
	if (comp != 0) {
		return comp < 0 ? arg1 : arg2;
	}
	// if they have the same exponent they are identical, return either
	if (arg1.exponent == arg2.exponent) {
		return arg1;
	}
	// if they are non-negative, return the one with smaller exponent.
	if (arg1.sign == 0) {
		return arg1.exponent < arg2.exponent ? arg1 : arg2;
	}
	// else they are negative; return the one with larger exponent.
	return arg1.exponent < arg2.exponent ? arg2 : arg1;
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = 3;
	arg2 = 2;
	assertTrue(min(arg1, arg2, testContext) == arg2);
	arg1 = -10;
	arg2 = 3;
	assertTrue(min(arg1, arg2, testContext) == arg1);
}

// UNREADY: minMagnitude. Flags.
const(T) minMagnitude(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	return min(copyAbs!T(arg1), copyAbs!T(arg2), context);
}

/// Returns a number with the same exponent as this number
/// and a coefficient of 1.
const (T) quantum(T)(const T arg) if (isDecimal!T) {
		return T(1, arg.exponent);
	}

unittest {
	BigDecimal num, qnum;
	num = 23.14E-12;
	qnum = 1E-14;
	assertTrue(quantum(num) == qnum);
}

//------------------------------------------
// binary arithmetic operations
//------------------------------------------

/**
 * Shifts the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand shift the
 * first operand left (multiplying by tens). Negative values shift right
 * (divide by 10s). If the number is NaN, or if the shift value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public T shift(T)(const T arg, const int n, DecimalContext context)
		if (isDecimal!T) {

	T arg2;
	// check for NaN operand
	if (invalidOperand!T(arg, arg2)) {
		return arg2;
	}
	if (n < -context.precision || n > context.precision) {
		arg2 = setInvalidFlag!T();
		return arg2;
	}
	if (arg.isInfinite) {
		return arg.dup;
	}
	if (n == 0) {
		return arg.dup;
	}
	BigDecimal shifted = toBigDecimal!T(arg);
	BigInt pow10 = BigInt(10)^^std.math.abs(n);
	if (n > 0) {
		shifted.coefficient = shifted.coefficient * pow10;
	}
	else {
		shifted.coefficient = shifted.coefficient / pow10;
	}
	return T(shifted);
}

unittest {
	BigDecimal num = 34;
	int digits = 8;
	BigDecimal act = shift(num, digits, testContext);
	num = 12;
	digits = 9;
	act = shift(num, digits, testContext);
	num = 123456789;
	digits = -2;
	act = shift(num, digits, testContext);
	digits = 0;
	act = shift(num, digits, testContext);
	digits = 2;
	act = shift(num, digits, testContext);
}

/**
 * Rotates the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand rotate the
 * first operand left (multiplying by tens). Negative values rotate right
 * (divide by 10s). If the number is NaN, or if the rotate value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public T rotate(T)(const T arg1, const int arg2, DecimalContext context)
		if (isDecimal!T) {

	T result;
	// check for NaN operand
	if (invalidOperand!T(arg1, result)) {
		return result;
	}
	if (arg2 < -context.precision || arg2 > context.precision) {
		result = setInvalidFlag();
		return result;
	}
	if (arg1.isInfinite) {
		return arg1.dup;
	}
	if (arg2 == 0) {
		return arg1.dup;
	}
	result = arg1.dup;

	// TODO: And then a miracle happens....

	return result;
}

/**
 * Adds two numbers.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for decimal numbers.
 */
public T add(T)(const T arg1, const T arg2, DecimalContext context,
		bool rounded = true) if (isDecimal!T) {
	T result = T.nan;	 // sum is initialized to quiet NaN

	// check for NaN operand(s)
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// if both operands are infinite
	if (arg1.isInfinite && arg2.isInfinite) {
		// (+inf) + (-inf) => invalid operation
		if (arg1.sign != arg2.sign) {
			return setInvalidFlag!T();
		}
		// both infinite with same sign
		return arg1.dup;
	}
	// only augend is infinite,
	if (arg1.isInfinite) {
		return arg1.dup;
	}
	// only addend is infinite
	if (arg2.isInfinite) {
		return arg2.dup;
	}
	// add(0, 0)
	if (arg1.isZero && arg2.isZero) {
		result = arg1;
		result.exponent = std.algorithm.min(arg1.exponent, arg2.exponent);
		result.sign = arg1.sign && arg2.sign;
		return result;
	}
	// add(0,f)
	if (arg1.isZero) {
		result = arg2;
		result.exponent = std.algorithm.min(arg1.exponent, arg2.exponent);
		return result;
	}
	// add(f,0)
	if (arg2.isZero) {
		result = arg1;
		result.exponent = std.algorithm.min(arg1.exponent, arg2.exponent);
		return result;
	}

	// at this point, the result will be finite and not zero.
	// calculate in BigDecimal and convert before return
	BigDecimal sum = BigDecimal.zero;
	BigDecimal augend = toBigDecimal!T(arg1);
	BigDecimal addend = toBigDecimal!T(arg2);
	// align the operands
	alignOps(augend, addend, context);
	// if operands have the same sign...
	if (augend.sign == addend.sign) {
		sum.coefficient = augend.coefficient + addend.coefficient;
		sum.sign = augend.sign;
	}
	// ...else operands have different signs
	else {
		if (augend.coefficient >= addend.coefficient)
		{
			sum.coefficient = augend.coefficient - addend.coefficient;
			sum.sign = augend.sign;
		}
		else
		{
			sum.coefficient = addend.coefficient - augend.coefficient;
			sum.sign = addend.sign;
		}
	}
	// set the number of digits and the exponent
	sum.digits = numDigits(sum.coefficient);
	sum.exponent = augend.exponent;

	result = T(sum);
	// round the result
	if (rounded) {
		round(result, context);
	}
	return result;
}	 // end add(arg1, arg2)

unittest {
	BigDecimal arg1, arg2, sum;
	arg1 = BigDecimal("12");
	arg2 = BigDecimal("7.00");
	sum = add(arg1, arg2, testContext);
	assertTrue(sum.toString() == "19.00");
	arg1 = BigDecimal("1E+2");
	arg2 = BigDecimal("1E+4");
	sum = add(arg1, arg2, testContext);
	assertTrue(sum.toString() == "1.01E+4");
}

/**
 * Subtracts a number from another number.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for decimal numbers.
 */
public T subtract(T) (const T arg1, const T arg2,
		DecimalContext context, const bool rounded = true) if (isDecimal!T) {
	return add!T(arg1, copyNegate!T(arg2), context , rounded);
}	 // end subtract(arg1, arg2)

/**
 * Multiplies two numbers.
 *
 * This function corresponds to the "multiply" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opMul function for decimal numbers.
 */
public T multiply(T)(const T arg1, const T arg2, DecimalContext context,
		const bool rounded = true) if (isDecimal!T) {

	T result = T.nan;
	// if invalid, return NaN
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// infinity * zero => invalid operation
	if (arg1.isZero && arg2.isInfinite || arg1.isInfinite && arg2.isZero) {
		return result;
	}
	// if either operand is infinite, return infinity
	if (arg1.isInfinite || arg2.isInfinite) {
		result = T.infinity;
		result.sign = arg1.sign ^ arg2.sign;
		return result;
	}

	// product is finite
	// mul(0,f) or (f,0)
	if (arg1.isZero || arg2.isZero) {
		result = T.zero;
		result.exponent = arg1.exponent + arg2.exponent;
		result.sign = arg1.sign ^ arg2.sign;
	}
	// product is non-zero
	else {
		BigDecimal product = BigDecimal.zero();
		product.coefficient = arg1.coefficient * arg2.coefficient;
		product.exponent = arg1.exponent + arg2.exponent;
		product.sign = arg1.sign ^ arg2.sign;
		product.digits = numDigits(product.coefficient);
		result = T(product);
	}

	// only needs rounding if
	if (rounded) {
		round(result, context);
	}
	return result;
}

unittest {
	BigDecimal arg1, arg2, result;
	arg1 = BigDecimal("1.20");
	arg2 = 3;
	result = multiply(arg1, arg2, testContext);
	assertTrue(result.toString() == "3.60");
	arg1 = 7;
	result = multiply(arg1, arg2, testContext);
	assertTrue(result.toString() == "21");
}

/**
 * Multiplies two numbers and adds a third number to the result.
 * The result of the multiplication is not rounded prior to the addition.
 *
 * This function corresponds to the "fused-multiply-add" function
 * in the General Decimal Arithmetic Specification.
 */
public T fma(T)(const T arg1, const T arg2, const T arg3,
		DecimalContext context) if (isDecimal!T) {

	T product = multiply!T(arg1, arg2, context, false);
	return add!T(product, arg3, context);
}

unittest {
	BigDecimal arg1, arg2, arg3, result;
	arg1 = 3; arg2 = 5; arg3 = 7;
	result = (fma(arg1, arg2, arg3, testContext));
	assertTrue(result == BigDecimal(22));
	arg1 = 3; arg2 = -5; arg3 = 7;
	result = (fma(arg1, arg2, arg3, testContext));
	assertTrue(result == BigDecimal(-8));
	arg1 = 888565290;
	arg2 = 1557.96930;
	arg3 = -86087.7578;
	result = (fma(arg1, arg2, arg3, testContext));
	assertTrue(result == BigDecimal(1.38435736E+12));
}

/**
 * Divides one number by another and returns the quotient.
 * Division by zero sets a flag and returns infinity.
 *
 * This function corresponds to the "divide" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opDiv function for decimal numbers.
 */
public T divide(T)(const T arg1, const T arg2,
		DecimalContext context, bool rounded = true) if (isDecimal!T) {

	T quotient;
	// check for NaN and divide by zero
	if (invalidDivision!T(arg1, arg2, quotient, context)) {
		return quotient;
	}
	quotient= T.zero();
	// TODO: are two guard digits necessary? sufficient?
    DecimalContext ctx = context.setPrecision(context.precision + 2);
	BigDecimal dividend = toBigDecimal!T(arg1);
	BigDecimal divisor	= toBigDecimal!T(arg2);
	BigDecimal working = BigDecimal.zero;
//	  working = BigDecimal.zero();
	int diff = dividend.exponent - divisor.exponent;
	if (diff > 0) {
		decShl(dividend.coefficient, diff);
		dividend.exponent = dividend.exponent - diff;
		dividend.digits = dividend.digits + diff;
	}
	int shift = 2 + ctx.precision + divisor.digits - dividend.digits;
	if (shift > 0) {
		dividend.coefficient = decShl(dividend.coefficient, shift);
		dividend.exponent = dividend.exponent - shift;
		dividend.digits = dividend.digits + diff;
	}
	working.coefficient = dividend.coefficient / divisor.coefficient;
	working.exponent = dividend.exponent - divisor.exponent;
	working.sign = dividend.sign ^ divisor.sign;
	working.digits = numDigits(working.coefficient);
//	context.precision -= 2;
	if (rounded) {
		round(working, context);
		if (!contextFlags.getFlag(INEXACT)) {
			working = reduceToIdeal(working, diff, context);
		}
	}
	quotient = T(working);
	return quotient;
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 1;
	arg2 = 3;
	actual = divide(arg1, arg2, testContext);
	expect = BigDecimal(0.333333333);
	assertTrue(actual == expect);
	assertTrue(actual.toString() == expect.toString());
	arg1 = 1;
	arg2 = 10;
	expect = 0.1;
	actual = divide(arg1, arg2, testContext);
	assertTrue(actual == expect);
}

// UNREADY: divideInteger. Error if integer value > precision digits. Duplicates code with divide?
/**
 * Divides one number by another and returns the integer portion of the quotient.
 * Division by zero sets a flag and returns Infinity.
 *
 * This function corresponds to the "divide-integer" function
 * in the General Decimal Arithmetic Specification.
 */
public T divideInteger(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {

	T quotient;
	if (invalidDivision!T(arg1, arg2, quotient, context)) {
		return quotient;
	}

	quotient = T.zero();
	T divisor  = copy!T(arg1);
	T dividend = copy!T(arg2);
	// align operands
	int diff = dividend.exponent - divisor.exponent;
	if (diff < 0) {
		divisor.coefficient = decShl(divisor.coefficient, -diff);
	}
	if (diff > 0) {
		dividend.coefficient = decShl(dividend.coefficient, diff);
	}
	quotient.coefficient = divisor.coefficient / dividend.coefficient;
	quotient.exponent = 0;
	quotient.sign = dividend.sign ^ divisor.sign;
	quotient.digits = numDigits(quotient.coefficient);
	if (quotient.coefficient == 0) quotient = T.zero;
	return quotient;
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 2;
	arg2 = 3;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 0;
	assertTrue(actual == expect);
	arg1 = 10;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 3;
	assertTrue(actual == expect);
	arg1 = 1;
	arg2 = 0.3;
	actual = divideInteger(arg1, arg2, testContext);
	assertTrue(actual == expect);
}

// UNREADY: remainder. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public T remainder(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(arg1, arg2, quotient, context)) {
		return quotient;
	}
	quotient = divideInteger!T(arg1, arg2, context);
	T remainder = arg1 - multiply!T(arg2, quotient, context, false);
	return remainder;
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 2.1;
	arg2 = 3;
	actual = remainder(arg1, arg2, testContext);
	expect = 2.1;
	assertTrue(actual == expect);
	arg1 = 10;
	actual = remainder(arg1, arg2, testContext);
	expect = 1;
	assertTrue(actual == expect);
}

// UNREADY: remainderNear. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public T remainderNear(T)(const T dividend, const T divisor,
		DecimalContext context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(dividend, divisor, quotient, context)) {
		return quotient;
	}
	quotient = divideInteger(dividend, divisor, context);
	T remainder = dividend - multiply!T(divisor, quotient, context, false);
	return remainder;
}

//--------------------------------
// rounding routines
//--------------------------------

// UNREADY: roundToIntegralExact. Description. Name. Order.
// could set flags and then pop the context??
public T roundToIntegralExact(T)(const T num,
		DecimalContext context) if (isDecimal!T) {
	if (num.isSignaling) return setInvalidFlag!T();
	if (num.isSpecial) return num.dup;
	if (num.exponent >= 0) return num.dup;
	const T ONE = T(1L);
	T result = quantize!T(num, ONE, context.setPrecision(num.digits));
	return result;
}

unittest {
	BigDecimal num, expect, actual;
	num = 2.1;
	expect = 2;
	actual = roundToIntegralExact(num, testContext);
	assertTrue(actual == expect);
	num = 100;
	expect = 100;
	actual = roundToIntegralExact(num, testContext);
	assertTrue(actual == expect);
	assertTrue(actual.toString() == expect.toString());
}

// UNREADY: roundToIntegralValue. Description. Name. Order. Logic.
public T roundToIntegralValue(T)(const T num,
		DecimalContext context) if (isDecimal!T) {
	// this operation shouldn't affect the inexact or rounded flags
	// so we'll save them in case they were already set.
	// TODO: Why save the context in this instance?
	bool inexact = context.getFlag(INEXACT);
	bool rounded = context.getFlag(ROUNDED);
	T result = roundToIntegralExact!T(num, context);
	contextFlags.setFlags(INEXACT, inexact);
	contextFlags.setFlags(ROUNDED, rounded);
	return result;
}

// UNREADY: reduceToIdeal. Description. Flags.
/**
 * Reduces operand to simplest form. All trailing zeros are removed.
 * Reduces operand to specified exponent.
 */
 // TODO: has non-standard flag setting
// NOTE: flags only
private T reduceToIdeal(T)(const T num, int ideal,
		DecimalContext context) if (isDecimal!T) {
	T result;
	if (invalidOperand!T(num, result)) {
		return result;
	}
	result = num;
	if (!result.isFinite()) {
		return result;
	}
	BigInt temp = result.coefficient % 10;
	while (result.coefficient != 0 && temp == 0 && result.exponent < ideal) {
		result.exponent = result.exponent + 1;
		result.coefficient = result.coefficient / 10;
		temp = result.coefficient % 10;
	}
	if (result.coefficient == 0) {
		result = T.zero;
		// TODO: needed?
		result.exponent = 0;
	}
	result.digits = numDigits(result.coefficient);
	return result;
}

// UNREADY: setInvalidFlag. Unit Tests.
/**
 * Sets the invalid-operation flag and
 * returns a quiet NaN.
 */
private T setInvalidFlag(T)(ushort payload = 0) if (isDecimal!T) {
	contextFlags.setFlags(INVALID_OPERATION);
	T result = T.nan;
	if (payload != 0) {
		result.payload = payload;
	}
	return result;
}

unittest {
	BigDecimal num, expect, actual;
	// FIXTHIS: Can't actually test payloads at this point.
	num = BigDecimal("sNaN123");
	expect = BigDecimal("NaN123");
	actual = abs!BigDecimal(num, testContext);
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);
}

/**
 * Aligns the two operands by raising the smaller exponent
 * to the value of the larger exponent, and adjusting the
 * coefficient so the value remains the same.
 */
private void alignOps(ref BigDecimal arg1, ref BigDecimal arg2, DecimalContext context) {
	int diff = arg1.exponent - arg2.exponent;
	if (diff > 0) {
		arg1.coefficient = decShl(arg1.coefficient, diff);
		arg1.exponent = arg2.exponent;
	}
	else if (diff < 0) {
		arg2.coefficient = decShl(arg2.coefficient, -diff);
		arg2.exponent = arg1.exponent;
	}
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = 1.3E35;
	arg2 = -17.4E29;
	alignOps(arg1, arg2, bigContext);
	assertTrue(arg1.coefficient == 13000000);
	assertTrue(arg2.exponent == 28);
}

// UNREADY: invalidBinaryOp. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool invalidBinaryOp(T)(const T arg1, const T arg2, T num) if (isDecimal!T) {
	// if either operand is a signaling NaN...
	if (arg1.isSignaling || arg2.isSignaling) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the num to the first sNaN operand
		num = arg1.isSignaling ? arg1 : arg2;

		// retain sign and payload; convert to qNaN
		//num = T(num.sign, SV.QNAN, 0); // FIXTHIS: add payload, num.coefficient);
		return true;
	}
	// ...if either operand is a quiet NaN...
	if (arg1.isQuiet || arg2.isQuiet) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the num to the first qNaN operand
		num = arg1.isQuiet ? arg1 : arg2;
		return true;
	}
	// ...otherwise, no flags are set and num is unchanged
	return false;
}

// UNREADY: invalidOperand. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool invalidOperand(T)(const T arg, ref T result) if (isDecimal!T) {
	// if the operand is a signaling NaN...
	if (arg.isSignaling) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the result to the sNaN operand
		result = arg;
		// retain sign and payload; convert to qNaN
		result = T.nan;
		return true;
	}
	// ...else if the operand is a quiet NaN...
	if (arg.isQuiet) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the result to the qNaN operand
		result = arg;
		return true;
	}
	// ...otherwise, no flags are set and result is unchanged
	return false;
}

// UNREADY: invalidDivision. Unit Tests.
/*
 *	  Checks for NaN operands and division by zero.
 *	  If found, sets flags, sets the quotient to NaN or Infinity respectively
 *	  and returns true.
 *	  Also checks for zero dividend and calculates the result as needed.
 *
 * -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool invalidDivision(T)(const T dividend, const T divisor,
		ref T quotient, DecimalContext context) if (isDecimal!T) {

	if (invalidBinaryOp!T(dividend, divisor, quotient)) {
		return true;
	}
	if (divisor.isZero()) {
		if (dividend.isZero()) {
			quotient = setInvalidFlag!T();
		}
		else {
			contextFlags.setFlags(DIVISION_BY_ZERO);
			quotient = T.infinity;
			quotient.coefficient = 0;
			quotient.sign = dividend.sign ^ divisor.sign;
		}
		return true;
	}
	if (dividend.isZero()) {
		quotient = T.zero;
		return true;
	}
	return false;
}

unittest {
	writeln("-------------------");
	writeln("arithmetic......end");
	writeln("-------------------");
}


