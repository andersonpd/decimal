/// A D programming language implementation of the
/// General Decimal Arithmetic Specification,
/// Version 1.70, (25 March 2009).
/// (http://www.speleotrove.com/decimal/decarith.pdf)

/// License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
/// Authors: Paul D. Anderson

///			Copyright Paul D. Anderson 2009 - 2012.
/// Distributed under the Boost Software License, Version 1.0.
///	  (See accompanying file LICENSE_1_0.txt or copy at
///			http://www.boost.org/LICENSE_1_0.txt)

// TODO: ensure context flags are being set and cleared properly.

// TODO: opEquals unit test should include numerically equal testing.

// TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// TODO: to/from real or double (float) values needs definition and implementation.

module decimal.arithmetic;

import decimal.context;
import decimal.conv : isDecimal, isFixedDecimal, toBigDecimal;
import decimal.decimal;
import decimal.rounding;
import decimal.utils;

import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;
import std.string;

unittest {
	writeln("===================");
	writeln("arithmetic....begin");
	writeln("===================");
}

//--------------------------------
// classification functions
//--------------------------------

/// Returns a string indicating the class and sign of the argument.
/// Classes are: sNaN, NaN, Infinity, Zero, Normal, and Subnormal.
/// The sign of any NaN values is ignored in the classification.
/// Implements the 'class' function in the specification. (p. 42)
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
	BigDecimal arg;
	arg = BigDecimal("Inf");
	assertEqual("+Infinity", classify(arg));
	arg = BigDecimal("1E-10");
	assertEqual("+Normal", classify(arg));
	arg = BigDecimal("-0");
	assertEqual("-Zero", classify(arg));
	arg = BigDecimal("-0.1E-99");
	assertEqual("-Subnormal", classify(arg));
	arg = BigDecimal("NaN");
	assertEqual("NaN", classify(arg));
	arg = BigDecimal("sNaN");
	assertEqual("sNaN", classify(arg));
}

//--------------------------------
// copy functions
//--------------------------------

/// Returns a copy of the operand.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy' function in the specification. (p. 43)
public T copy(T)(const T arg) if (isDecimal!T) {
	return arg.dup;
}

unittest {
	BigDecimal arg, expect;
	arg  = BigDecimal("2.1");
	expect = BigDecimal("2.1");
	assertTrue(compareTotal(copy(arg),expect) == 0);
	arg  = BigDecimal("-1.00");
	expect = BigDecimal("-1.00");
	assertTrue(compareTotal(copy(arg),expect) == 0);
}


/// Returns a copy of the operand with a positive sign.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-abs' function in the specification. (p. 44)
public T copyAbs(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = false;
	return copy;
}

unittest {
	BigDecimal arg, expect;
	arg  = 2.1;
	expect = 2.1;
	assertTrue(compareTotal(copyAbs(arg),expect) == 0);
	arg  = BigDecimal("-1.00");
	expect = BigDecimal("1.00");
	assertTrue(compareTotal(copyAbs(arg),expect) == 0);
}


/// Returns a copy of the operand with the sign inverted.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-negate' function in the specification. (p. 44)
public T copyNegate(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = !arg.sign;
	return copy;
}

unittest {
	BigDecimal arg	= "101.5";
	BigDecimal expect = "-101.5";
	assertTrue(compareTotal(copyNegate(arg),expect) == 0);
}


/// Returns a copy of the first operand with the sign of the second operand.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-sign' function in the specification. (p. 44)
public T copySign(T)(const T arg1, const T arg2) if (isDecimal!T) {
	T copy = arg1.dup;
	copy.sign = arg2.sign;
	return copy;
}

unittest {
	BigDecimal arg1, arg2, expect;
	arg1 = 1.50; arg2 = 7.33; expect = 1.50;
	assertTrue(compareTotal(copySign(arg1, arg2),expect) == 0);
	arg2 = -7.33;
	expect = -1.50;
	assertTrue(compareTotal(copySign(arg1, arg2),expect) == 0);
}

/// Returns "the integer which is the exponent of the magnitude
/// of the most significant digit of the operand.
/// (As though the operand were truncated to a single digit
/// while maintaining the value of that digit and without
/// limiting the resulting exponent)".
/// Implements the 'logb' function in the specification. (p. 47)
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
	BigDecimal arg, expect, actual;
	arg = BigDecimal("250");
	expect = BigDecimal("2");
	actual = logb(arg);
	assertEqual(expect, actual);
}

/// If the first operand is infinite then that operand is returned,
/// otherwise the result is the first operand modified by
/// adding the value of the second operand to its exponent.
/// The second operand must be a finite integer with an exponent of zero.
/// The result may overflow or underflow.
/// Implements the 'scaleb' function in the specification. (p. 48)
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
	BigDecimal expect, actual;
	auto arg1 = BigDecimal("7.50");
	auto arg2 = BigDecimal("-2");
	expect = BigDecimal("0.0750");
	actual = scaleb(arg1, arg2);
	assertEqual(expect, actual);
}

//--------------------------------
// absolute value, unary plus and minus functions
//--------------------------------

/// Returns the operand reduced to its simplest form.
/// It has the same semantics as the plus operation,
/// except that if the final result is finite it is
/// reduced to its simplest form, with all trailing
/// zeros removed and its sign preserved.
/// Implements the 'reduce' function in the specification. (p. 37)
/// "This operation was called 'normalize' prior to
/// version 1.68 of the specification." (p. 37)
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
	BigDecimal arg;
	string expect, actual;
	string str;
	arg = BigDecimal("1.200");
	expect = "1.2";
	actual = reduce(arg).toString;
	assertEqual(expect, actual);
}


/// Returns the absolute value of the argument.
/// This operation rounds the result and may set flags.
/// The result is equivalent to plus(arg) for positive numbers
/// and to minus(arg) for negative numbers.
/// To return the absolute value without rounding or setting flags
/// use the 'copyAbs' function.
/// Implements the 'abs' function in the specification. (p. 26)
public T abs(T)(const T arg, const DecimalContext context) if (isDecimal!T) {
	T result;
	if(invalidOperand!T(arg, result)) {
		return result;
	}
	result = copyAbs!T(arg);
	round(result, context);
	return result;
}

unittest {
	BigDecimal arg;
	BigDecimal expect, actual;
	arg = BigDecimal("-Inf");
	expect = BigDecimal("Inf");
	actual = abs(arg, testContext);
	assertEqual(expect, actual);
	arg = 101.5;
	expect = 101.5;
	actual = abs(arg, testContext);
	assertEqual(expect, actual);
	arg = -101.5;
	actual = abs(arg, testContext);
	assertEqual(expect, actual);
}


/// Returns the sign of the argument: -1, 0, -1.
/// If the argument is (signed or unsigned) zero, 0 is returned.
/// If the argument is negative, -1 is returned.
/// Otherwise +1 is returned.
/// This function is not required by the specification.
public int sgn(T)(const T arg) if (isDecimal!T) {
	if (arg.isZero) return 0;
	return arg.isNegative ? -1 : 1;
}

unittest {
	BigDecimal arg;
	arg = -123;
	assertEqual(-1, sgn(arg));
	arg = 2345;
	assertEqual( 1, sgn(arg));
	arg = BigDecimal("0.0000");
	assertEqual( 0, sgn(arg));
	arg = BigDecimal.infinity(true);
	assertEqual(-1, sgn(arg));
}


/// Returns a copy of the argument with same sign as the argument.
/// This operation rounds the result and may set flags.
/// The result is equivalent to add('0', arg).
/// To copy without rounding or setting flags use the 'copy' function.
/// Implements the 'plus' function in the specification. (p. 33)
public T plus(T)(const T arg, const DecimalContext context) if (isDecimal!T) {
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
	BigDecimal arg, expect, actual;
	arg = 1.3;
	expect = add(zero, arg, testContext);
	actual = plus(arg, testContext);
	assertEqual(expect, actual);
	arg = -1.3;
	expect = add(zero, arg, testContext);
	actual = plus(arg, testContext);
	assertEqual(expect, actual);
}

/// Returns a copy of the argument with the opposite sign.
/// This operation rounds the argument and may set flags.
/// Result is equivalent to subtract('0', arg).
/// To copy without rounding or setting flags use the 'copyNegate' function.
/// Implements the 'minus' function in the specification. (p. 37)
public T minus(T)(const T arg, const DecimalContext context) if (isDecimal!T) {
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
	BigDecimal arg, expect, actual;
	arg = 1.3;
	expect = sub(zero, arg, testContext);
	actual = minus(arg, testContext);
	assertEqual(expect, actual);
	arg = -1.3;
	expect = sub(zero, arg, testContext);
	actual = minus(arg, testContext);
	assertEqual(expect, actual);
}

//-----------------------------------
// next-plus, next-minus, next-toward
//-----------------------------------

/// Returns the smallest representable number that is larger than
/// the argument.
/// Implements the 'next-plus' function in the specification. (p. 34)
public T nextPlus(T)(const T arg1, const DecimalContext context) if (isDecimal!T) {
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
	// TODO: should be context.max
	if (result > T.max(context)) {
		result = T.infinity;
	}
	return result;
}

unittest {
	BigDecimal arg, expect, actual;
	arg = 1;
	expect = BigDecimal("1.00000001");
	actual = nextPlus(arg, testContext);
	assertEqual(expect, actual);
	arg = 10;
	expect = BigDecimal("10.0000001");
	actual = nextPlus(arg, testContext);
	assertEqual(expect, actual);
}

/// Returns the largest representable number that is smaller than
/// the argument.
/// Implements the 'next-minus' function in the specification. (p. 34)
public T nextMinus(T)(const T arg, const DecimalContext context)
		if (isDecimal!T) {

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
	result = sub!T(arg, addend, context, true);	//TODO: are the flags set/not set correctly?
		if (result < copyNegate!T(T.max(context))) {
		result = copyNegate!T(T.infinity);
	}
	return result;
}

unittest {
	BigDecimal arg, expect, actual;
	arg = 1;
	expect = 0.999999999;
	actual = nextMinus(arg, testContext);
	assertEqual(expect, actual);
	arg = -1.00000003;
	expect = -1.00000004;
	actual = nextMinus(arg, testContext);
	assertEqual(expect, actual);
}

/// Returns the representable number that is closest to the
/// first operand (but not the first operand) in the
/// direction toward the second operand.
/// Implements the 'next-toward' function in the specification. (p. 34-35)
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
	BigDecimal arg1, arg2, expect, actual;
	arg1 = 1;
	arg2 = 2;
	expect = 1.00000001;
	actual = nextToward(arg1, arg2, testContext);
	assertEqual(expect, actual);
	arg1 = -1.00000003;
	arg2 = 0;
	expect = -1.00000002;
	actual = nextToward(arg1, arg2, testContext);
	assertEqual(expect, actual);
}

//--------------------------------
// comparison functions
//--------------------------------

/// Compares two operands numerically to the current precision.
/// Returns -1, 0, or +1 if the second operand is, respectively,
/// less than, equal to, or greater than the first operand.
/// Implements the 'compare' function in the specification. (p. 27)
/// This operation may set the invalid-operation flag.
public int compare(T)(const T arg1, const T arg2, const DecimalContext context,
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
	T result = sub!T(arg1, arg2, context, rounded);

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
	assertEqual(-1, compare(arg1, arg2, testContext));
	arg1 = 2.1;
	arg2 = BigDecimal(2.1);
	assertEqual(0, compare(arg1, arg2, testContext));
}

/// Returns true if the operands are equal to the current precision.
/// Finite numbers are equal if they are numerically equal
/// to the current precision.
/// A NaN is not equal to any number, not even to another NaN.
/// Infinities are equal if they have the same sign.
/// Zeros are equal regardless of sign.
/// A decimal NaN is not equal to itself (this != this).
/// This operation may set the invalid-operation flag.
/// This function is not included in the specification.
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
	T result = sub!T(arg1, arg2, context, rounded);
	return result.coefficient == 0;
}

unittest {
	BigDecimal arg1, arg2;
	arg1 = 123.4567;
	arg2 = 123.4568;
	assertTrue(!equals!BigDecimal(arg1, arg2, bigContext));
	arg2 = 123.4567;
	assertTrue(equals!BigDecimal(arg1, arg2, bigContext));
}

/// Compares the numeric values of two numbers. CompareSignal is identical to
/// compare except that quiet NaNs are treated as if they were signaling.
/// This operation may set the invalid-operation flag.
/// Implements the 'compare-signal' function in the specification. (p. 27)
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

unittest {
	write("compareSignal...");
	writeln("test missing");
}

// TODO: this is either a true abstract representation compare or it isn't
/// Compares the operands using their abstract representation rather than
/// their numerical value.
/// Returns 0 if the numbers are equal and have the same representation.
/// This operation does not set any flags.
/// Implements the 'compare-total' function in the specification. (p. 42-43)
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

/// compare-total-magnitude takes two numbers and compares them
/// using their abstract representation rather than their numerical value
/// and with their sign ignored and assumed to be 0.
/// The result is identical to that obtained by using compare-total
/// on two operands which are the copy-abs copies of the operands.
/// Implements the 'compare-total-magnitude' function in the specification.
/// (p. 43)
int compareTotalMagnitude(T)(const T arg1, const T arg2) if (isDecimal!T) {
	return compareTotal(copyAbs!T(arg1), copyAbs!T(arg2));
}

/// Returns true if the numbers have the same exponent.
/// If either operand is NaN or Infinity, returns true if and only if
/// both operands are NaN or Infinity, respectively.
/// No context flags are set.
/// Implements the 'same-quantum' function in the specification. (p. 48)
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

// TODO: Need to set flags per specification (p. 32).
/// Returns the maximum of the two operands (or NaN).
/// If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
/// Otherwise, Any (finite or infinite) number is larger than a NaN.
/// If they are not numerically equal, the larger is returned.
/// If they are numerically equal:
/// 1) If the signs differ, the one with the positive sign is returned.
/// 2) If they are positive, the one with the larger exponent is returned.
/// 3) If they are negative, the one with the smaller exponent is returned.
/// 4) Otherwise, they are indistinguishable; the first is returned.
/// Implements the 'max' function in the specification. (p. 32)
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
	BigDecimal arg1, arg2, expect, actual;
	arg1 = 3; arg2 = 2; expect = 3;
	actual = max(arg1, arg2, testContext);
	assertEqual(expect, actual);
	arg1 = -10; arg2 = 3; expect = 3;
	actual = max(arg1, arg2, testContext);
	assertEqual(expect, actual);
}

/// Returns the larger of the two operands (or NaN). Returns the same result
/// as the 'max' function if the signs of the operands are ignored.
/// Implements the 'max-magnitude' function in the specification. (p. 32)
const(T) maxMagnitude(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	return max(copyAbs!T(arg1), copyAbs!T(arg2), context);
}

unittest {
	write("maxMagnitude...");
	writeln("test missing");
}


// TODO: Need to set flags per specification (p. 32).
/// Returns the minimum of the two operands (or NaN).
/// If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
/// Otherwise, Any (finite or infinite) number is smaller than a NaN.
/// If they are not numerically equal, the smaller is returned.
/// If they are numerically equal:
/// 1) If the signs differ, the one with the negative sign is returned.
/// 2) If they are negative, the one with the larger exponent is returned.
/// 3) If they are positive, the one with the smaller exponent is returned.
/// 4) Otherwise, they are indistinguishable; the first is returned.
/// Implements the 'min' function in the specification. (p. 32-33)
const(T) min(T)(const T arg1, const T arg2,
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
	BigDecimal arg1, arg2, expect, actual;
	arg1 = 3; arg2 = 2; expect = 2;
	actual = min(arg1, arg2, testContext);
	assertEqual(expect, actual);
	arg1 = -10; arg2 = 3; expect = -10;
	actual = min(arg1, arg2, testContext);
	assertEqual(expect, actual);
}

/// Returns the smaller of the two operands (or NaN). Returns the same result
/// as the 'max' (TODO: ?) function if the signs of the operands are ignored.
/// Implements the 'min-magnitude' function in the specification. (p. 33)
const(T) minMagnitude(T)(const T arg1, const T arg2,
		DecimalContext context) if (isDecimal!T) {
	return min(copyAbs!T(arg1), copyAbs!T(arg2), context);
}

unittest {
	write("minMagnitude...");
	writeln("test missing");
}

/// Returns a number with a coefficient of 1 and
/// the same exponent as the argument.
/// No context flags are set.
/// Not required by the specification.
public const (T) quantum(T)(const T arg) if (isDecimal!T) {
		return T(1, arg.exponent);
	}

unittest {
	BigDecimal arg, expect, actual;
	arg = 23.14E-12;
	expect = 1E-14;
	actual = quantum(arg);
	assertEqual(expect, actual);
}

//------------------------------------------
// binary arithmetic operations
//------------------------------------------

/// Adds the two operands.
/// The result may be rounded and context flags may be set.
/// Implements the 'add' function in the specification. (p. 26)
public T add(T)(const T arg1, const T arg2, const DecimalContext context,
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
	// TODO: change inputs to real njumbers
	BigDecimal arg1, arg2, sum;
	arg1 = BigDecimal("12");
	arg2 = BigDecimal("7.00");
	sum = add(arg1, arg2, testContext);
	assertEqual("19.00", sum.toString);
	arg1 = BigDecimal("1E+2");
	arg2 = BigDecimal("1E+4");
	sum = add(arg1, arg2, testContext);
	assertEqual("1.01E+4", sum.toString);
}


/// Adds a long value to a decimal number. The result is identical to that of
/// the 'add' function as if the long value were converted to a decimal number.
/// The result may be rounded and context flags may be set.
/// This function is not included in the specification.
public T addLong(T)(const T arg1, const long arg2, const DecimalContext context,
		bool rounded = true) if (isDecimal!T) {
	T result = T.nan;	 // sum is initialized to quiet NaN

	// check for NaN operand(s)
	if (invalidOperand!T(arg1, result)) {
		return result;
	}
	// if both operands are infinite
	if (arg1.isInfinite) {
		// (+inf) + (-inf) => invalid operation
		if (arg1.sign != (arg2 < 0)) {
			return setInvalidFlag!T();
		}
		// both infinite with same sign
		return arg1.dup;
	}
	// only augend is infinite,
	if (arg1.isInfinite) {
		return arg1.dup;
	}
	// add(0, 0)
	if (arg1.isZero && arg2 == 0) {
		result = arg1;
		result.exponent = std.algorithm.min(arg1.exponent, 0);
		result.sign = arg1.sign && (arg2 < 0);
		return result;
	}
	// add(0,f)
	if (arg1.isZero) {
		result = T(arg2);
		result.exponent = std.algorithm.min(arg1.exponent, 0);
		return result;
	}
	// add(f,0)
	if (arg2 == 0) {
		result = arg1;
		result.exponent = std.algorithm.min(arg1.exponent, 0);
		return result;
	}

	// at this point, the result will be finite and not zero.
	// calculate in BigDecimal and convert before return
	BigDecimal sum = BigDecimal.zero;
	BigDecimal augend = toBigDecimal!T(arg1);
	BigDecimal addend = BigDecimal(arg2);
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
	BigDecimal arg1, sum;
	long arg2;
	arg2 = 12;
	arg1 = BigDecimal("7.00");
	sum = addLong(arg1, arg2, testContext);
	assertEqual("19.00", sum.toString);
	arg1 = BigDecimal("1E+2");
	arg2 = 10000;
	sum = addLong(arg1, arg2, testContext);
	assertEqual("10100", sum.toString);
}


/// Subtracts the second operand from the first operand.
/// The result may be rounded and context flags may be set.
/// Implements the 'subtract' function in the specification. (p. 26)
public T sub(T) (const T arg1, const T arg2, const DecimalContext context,
		 const bool rounded = true) if (isDecimal!T) {
	return add!T(arg1, copyNegate!T(arg2), context , rounded);
}	 // end sub(arg1, arg2)


/// Subtracts a long value from a decimal number.
/// The result is identical to that of the 'subtract' function
/// as if the long value were converted to a decimal number.
/// This function is not included in the specification.
public T subLong(T) (const T arg1, const long arg2,
		DecimalContext context, const bool rounded = true) if (isDecimal!T) {
	return addLong!T(arg1, -arg2, context , rounded);
}	 // end sub(arg1, arg2)


/// Multiplies the two operands.
/// The result may be rounded and context flags may be set.
/// Implements the 'multiply' function in the specification. (p. 33-34)
public T mul(T)(const T arg1, const T arg2, const DecimalContext context,
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
		BigInt mant1 = arg1.coefficient;
		BigInt mant2 = arg2.coefficient;
		product.coefficient = mant1 * mant2;
		// TODO: can't convert to BigInt below because the template can't
		// determine the type.
//		product.coefficient = BigInt(arg1.coefficient) * BigInt(arg2.coefficient);
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
	result = mul(arg1, arg2, testContext);
	assertEqual("3.60", result.toString());
	arg1 = 7;
	result = mul(arg1, arg2, testContext);
	assertEqual("21", result.toString());
}

/// Multiplies a decimal number by a long integer.
/// The result may be rounded and context flags may be set.
/// Not a required function, but useful because it avoids
/// an unnecessary conversion to a decimal when multiplying.
public T mulLong(T)(const T arg1, long arg2, DecimalContext context,
		const bool rounded = true) if (isDecimal!T) {

	T result = T.nan;
	// if invalid, return NaN
	if (invalidOperand!T(arg1, result)) {
		return result;
	}
	// infinity * zero => invalid operation
	if (arg1.isInfinite && arg2 == 0) {
		return result;
	}
	// if either operand is infinite, return infinity
	if (arg1.isInfinite) {
		result = T.infinity;
		result.sign = arg1.sign ^ (arg2 < 0);
		return result;
	}

	// product is finite
	// mul(0,f) or (f,0)
	if (arg1.isZero || arg2 == 0) {
		result = T.zero;
		result.exponent = arg1.exponent;
		result.sign = arg1.sign ^ (arg2 < 0);
	}
	// product is non-zero
	else {
		BigDecimal product = BigDecimal.zero();
		product.coefficient = arg1.coefficient * arg2;
		product.exponent = arg1.exponent;
		product.sign = arg1.sign ^ (arg2 < 0);
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
	BigDecimal arg1, result;
	long arg2;
	arg1 = BigDecimal("1.20");
	arg2 = 3;
	result = mulLong(arg1, arg2, testContext);
	assertEqual("3.60", result.toString());
	arg1 = -7000;
	result = mulLong(arg1, arg2, testContext);
	assertEqual("-21000", result.toString());
}


/// Multiplies the first two operands and adds the third operand to the result.
/// The result of the multiplication is not rounded prior to the addition.
/// The result may be rounded and context flags may be set.
/// Implements the 'fused-multiply-add' function in the specification. (p. 30)
public T fma(T)(const T arg1, const T arg2, const T arg3,
		DecimalContext context) if (isDecimal!T) {

	// TODO: should these both be BigDecimal?
	T product = mul!T(arg1, arg2, context, false);
	return add!T(product, arg3, context);
}

unittest {
	BigDecimal arg1, arg2, arg3, expect, actual;
	arg1 = 3; arg2 = 5; arg3 = 7;
	expect = 22;
	actual = (fma(arg1, arg2, arg3, testContext));
	assertEqual(expect, actual);
	arg1 = 3; arg2 = -5; arg3 = 7;
	expect = -8;
	actual = (fma(arg1, arg2, arg3, testContext));
	assertEqual(expect, actual);
	arg1 = 888565290;
	arg2 = 1557.96930;
	arg3 = -86087.7578;
	expect = BigDecimal(1.38435736E+12);
	actual = (fma(arg1, arg2, arg3, testContext));
	assertEqual(expect, actual);
}

/// Divides the first operand by the second operand and returns their quotient.
/// Division by zero sets a flag and returns infinity.
/// Result may be rounded and context flags may be set.
/// Implements the 'divide' function in the specification. (p. 27-29)
public T div(T)(const T arg1, const T arg2, const DecimalContext context,
		bool rounded = true) if (isDecimal!T) {

	// check for NaN and divide by zero
	T result;
	if (invalidDivision!T(arg1, arg2, result)) {
		return result;
	}
	BigDecimal dividend = toBigDecimal!T(arg1);
	BigDecimal divisor	= toBigDecimal!T(arg2);
	BigDecimal quotient = BigDecimal.zero;
	int diff = dividend.exponent - divisor.exponent;
	if (diff > 0) {
		decShl(dividend.coefficient, diff);
		dividend.exponent = dividend.exponent - diff;
		dividend.digits = dividend.digits + diff;
	}
	int shift = 4 + context.precision + divisor.digits - dividend.digits;
	if (shift > 0) {
		dividend.coefficient = decShl(dividend.coefficient, shift);
		dividend.exponent = dividend.exponent - shift;
		dividend.digits = dividend.digits + diff;
	}
	quotient.coefficient = dividend.coefficient / divisor.coefficient;
	quotient.exponent = dividend.exponent - divisor.exponent;
	quotient.sign = dividend.sign ^ divisor.sign;
	quotient.digits = numDigits(quotient.coefficient);
	if (rounded) {
		round(quotient, context);
		/// TODO why is this flag being checked?
		if (!contextFlags.getFlag(INEXACT)) {
			quotient = reduceToIdeal(quotient, diff, context);
		}
	}
	return T(quotient);
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 1;
	arg2 = 3;
	actual = div(arg1, arg2, testContext);
	expect = BigDecimal(0.333333333);
	assertEqual(expect, actual);
	assertStringEqual(expect, actual);
	arg1 = 1;
	arg2 = 10;
	expect = 0.1;
	actual = div(arg1, arg2, testContext);
	assertEqual(expect, actual);
}


/// Divides the first operand by the second and returns the integer portion
/// of the quotient.
/// Division by zero sets a flag and returns infinity.
/// The result may be rounded and context flags may be set.
/// Implements the 'divide-integer' function in the specification. (p. 30)
public T divideInteger(T)(const T arg1, const T arg2,
		const DecimalContext context) if (isDecimal!T) {
	// check for NaN and divide by zero
	T result;
	if (invalidDivision!T(arg1, arg2, result)) {
		return result;
	}

	BigDecimal dividend = toBigDecimal!T(arg1);
	BigDecimal divisor	= toBigDecimal!T(arg2);
	BigDecimal quotient = BigDecimal.zero;

	// align operands
	int diff = dividend.exponent - divisor.exponent;
	if (diff < 0) {
		divisor.coefficient = decShl(divisor.coefficient, -diff);
	}
	if (diff > 0) {
		dividend.coefficient = decShl(dividend.coefficient, diff);
	}
	quotient.sign = dividend.sign ^ divisor.sign;
	quotient.coefficient = dividend.coefficient / divisor.coefficient;
	if (quotient.coefficient == 0) return T.zero(quotient.sign);
	quotient.exponent = 0;
	// number of digits cannot exceed precision
	int digits = numDigits(quotient.coefficient);
	if (digits > context.precision) {
		return setInvalidFlag!T();
	}
	quotient.digits = digits;
	return T(quotient);
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 2;
	arg2 = 3;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 0;
	assertEqual(expect, actual);
	arg1 = 10;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 3;
	assertEqual(expect, actual);
	arg1 = 1;
	arg2 = 0.3;
	actual = divideInteger(arg1, arg2, testContext);
	assertEqual(expect, actual);
}

/// Divides the first operand by the second and returns the
/// fractional remainder.
/// Division by zero sets a flag and returns infinity.
/// The sign of the remainder is the same as that of the first operand.
/// The result may be rounded and context flags may be set.
/// Implements the 'remainder' function in the specification. (p. 37-38)
public T remainder(T)(const T arg1, const T arg2,
		const DecimalContext context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(arg1, arg2, quotient)) {
		return quotient;
	}
	quotient = divideInteger!T(arg1, arg2, context);
	T remainder = arg1 - mul!T(arg2, quotient, context, false);
	return remainder;
}

unittest {
	BigDecimal arg1, arg2, actual, expect;
	arg1 = 2.1;
	arg2 = 3;
	actual = remainder(arg1, arg2, testContext);
	expect = 2.1;
	assertEqual(expect, actual);
	arg1 = 10;
	actual = remainder(arg1, arg2, testContext);
	expect = 1;
	assertEqual(expect, actual);
}

// TODO: should not be identical to remainder.
/// Divides the first operand by the second and returns the
/// fractional remainder.
/// Division by zero sets a flag and returns Infinity.
/// The sign of the remainder is the same as that of the first operand.
/// This function corresponds to the "remainder" function
/// in the General Decimal Arithmetic Specification.
public T remainderNear(T)(const T dividend, const T divisor,
		DecimalContext context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(dividend, divisor, quotient)) {
		return quotient;
	}
	quotient = divideInteger(dividend, divisor, context);
	T remainder = dividend - mul!T(divisor, quotient, context, false);
	return remainder;
}

unittest {
	write("remainderNear...");
	writeln("test missing");
}

// TODO: add 'remquo' function. (Uses remainder-near(?))

//--------------------------------
// rounding routines
//--------------------------------

/// Returns the number which is equal in value and sign
/// to the first operand with the exponent of the second operand.
/// The returned value is rounded to the current precision.
/// This operation may set the invalid-operation flag.
/// Implements the 'quantize' function in the specification. (p. 36-37)
public T quantize(T)(const T arg1, const T arg2,
		const DecimalContext context) if (isDecimal!T) {

	T result;
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// if one operand is infinite and the other is not...
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
	assertEqual(expect, actual);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("0.01");
	expect = BigDecimal("2.17");
	actual = quantize(arg1, arg2, context);
	assertEqual(expect, actual);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("0.1");
	expect = BigDecimal("2.2");
	actual = quantize(arg1, arg2, context);
	assertEqual(expect, actual);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("1e+0");
	expect = BigDecimal("2");
	actual = quantize(arg1, arg2, context);
	assertEqual(expect, actual);
	arg1 = BigDecimal("2.17");
	arg2 = BigDecimal("1e+1");
	expect = BigDecimal("0E+1");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("-Inf");
	arg2 = BigDecimal("Infinity");
	expect = BigDecimal("-Infinity");
	actual = quantize(arg1, arg2, context);
	assertEqual(expect, actual);
	arg1 = BigDecimal("2");
	arg2 = BigDecimal("Infinity");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("-0.1");
	arg2 = BigDecimal("1");
	expect = BigDecimal("-0");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("-0");
	arg2 = BigDecimal("1e+5");
	expect = BigDecimal("-0E+5");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("+35236450.6");
	arg2 = BigDecimal("1e-2");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("-35236450.6");
	arg2 = BigDecimal("1e-2");
	expect = BigDecimal("NaN");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e-1");
	expect = BigDecimal( "217.0");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+0");
	expect = BigDecimal("217");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+1");
	expect = BigDecimal("2.2E+2");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	arg1 = BigDecimal("217");
	arg2 = BigDecimal("1e+2");
	expect = BigDecimal("2E+2");
	actual = quantize(arg1, arg2, context);
	assertStringEqual(expect, actual);
	assertEqual(expect, actual);
}

// TODO: Not clear what this does.
/// Returns a value as if this were the quantize function using
/// the given operand as the left-hand-operand.
/// The result is and context flags may be set.
/// Implements the 'round-to-integral-exact' function
/// in the specification. (p. 39)
public T roundToIntegralExact(T)(const T arg,
		DecimalContext context) if (isDecimal!T) {
	if (arg.isSignaling) return setInvalidFlag!T();
	if (arg.isSpecial) return arg.dup;
	if (arg.exponent >= 0) return arg.dup;
	const T ONE = T(1L);
	T result = quantize!T(arg, ONE, context.setPrecision(arg.digits));
	return result;
}

unittest {
	BigDecimal arg, expect, actual;
	arg = 2.1;
	expect = 2;
	actual = roundToIntegralExact(arg, testContext);
	assertEqual(expect, actual);
	arg = 100;
	expect = 100;
	actual = roundToIntegralExact(arg, testContext);
	assertEqual(expect, actual);
	assertStringEqual(expect, actual);
}

// TODO: need to re-implement this so no flags are set.
/// The result may be rounded and context flags may be set.
/// Implements the 'round-to-integraL-value' function
/// in the specification. (p. 39)
public T roundToIntegralValue(T)(const T arg,
		DecimalContext context) if (isDecimal!T) {
	if (arg.isSignaling) return setInvalidFlag!T();
	if (arg.isQuiet) return arg.dup;
	if (arg.isSpecial) return arg.dup;
	if (arg.exponent >= 0) return arg.dup;
	const T ONE = T(1L);
	T result = quantize!T(arg, ONE, context.setPrecision(arg.digits));
	return result;
}

// TODO: Need to check for subnormal and inexact(?). Or is this done by caller?
// TODO: has non-standard flag setting
/// Reduces operand to the specified (ideal) exponent.
/// All trailing zeros are removed.
/// (Used to return the "ideal" value following division. p. 28-29)
private T reduceToIdeal(T)(const T arg, int ideal,
		const DecimalContext context) if (isDecimal!T) {
	T result;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
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

unittest {
	write("reduceToIdeal...");
	writeln("test missing");
}

/// Sets the invalid-operation flag and returns a quiet NaN.
private T setInvalidFlag(T)(ushort payload = 0) if (isDecimal!T) {
	contextFlags.setFlags(INVALID_OPERATION);
	T result = T.nan;
	if (payload != 0) {
		result.payload = payload;
	}
	return result;
}

unittest {
	BigDecimal arg, expect, actual;
	// TODO: Can't actually test payloads at this point.
	arg = BigDecimal("sNaN123");
	expect = BigDecimal("NaN123");
	actual = abs!BigDecimal(arg, testContext);
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);
}


/// Aligns the two operands by raising the smaller exponent
/// to the value of the larger exponent, and adjusting the
/// coefficient so the value remains the same.
/// No flags are set and the result is not rounded.
private void alignOps(ref BigDecimal arg1, ref BigDecimal arg2,
		const DecimalContext context) {
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

///  Returns true and sets the invalid-operation flag if either operand
/// is a NaN.
/// "The result of any arithmetic operation which has an operand
/// which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
/// or [s,qNaN,d]. The sign and any diagnostic information is copied
/// from the first operand which is a signaling NaN, or if neither is
/// signaling then from the first operand which is a NaN."
/// -- General Decimal Arithmetic Specification, p. 24
private bool invalidBinaryOp(T)(const T arg1, const T arg2, T result)
		if (isDecimal!T) {
	// if either operand is a quiet NaN...
	if (arg1.isQuiet || arg2.isQuiet) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the result to the first qNaN operand
		result = arg1.isQuiet ? arg1 : arg2;
		return true;
	}
	// ...if either operand is a signaling NaN...
	if (arg1.isSignaling || arg2.isSignaling) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// set the result to the first sNaN operand
		result = arg1.isSignaling ? T.nan(arg1.payload) : T.nan(arg2.payload);
		return true;
	}
	// ...otherwise, no flags are set and result is unchanged
	return false;
}

unittest {
	write("invalidBinaryOp...");
	writeln("test missing");
}

/// Returns true and sets the invalid-operation flag if the operand
/// is a NaN.
/// "The result of any arithmetic operation which has an operand
/// which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
/// or [s,qNaN,d]. The sign and any diagnostic information is copied
/// from the first operand which is a signaling NaN, or if neither is
/// signaling then from the first operand which is a NaN."
/// -- General Decimal Arithmetic Specification, p. 24
private bool invalidOperand(T)(const T arg, ref T result) if (isDecimal!T) {
	// if the operand is a signaling NaN...
	if (arg.isSignaling) {
		// flag the invalid operation
		contextFlags.setFlags(INVALID_OPERATION);
		// retain payload; convert to qNaN
		result = T.nan(arg.payload);
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

unittest {
	write("invalidOperand...");
	writeln("test missing");
}

/// Checks for invalid operands and division by zero.
/// If found, the function sets the quotient to NaN or infinity, respectively,
/// and returns true after setting the context flags.
/// Also checks for zero dividend and calculates the result as needed.
/// This is a helper function implementing checks for division by zero
/// and invalid operation in the specification. (p. 51-52)
private bool invalidDivision(T)(const T dividend, const T divisor,
		ref T quotient) if (isDecimal!T) {

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
	write("invalidDivision...");
	writeln("test missing");
}

unittest {
	writeln("===================");
	writeln("arithmetic......end");
	writeln("===================");
}


