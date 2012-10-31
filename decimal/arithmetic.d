// Written in the D programming language

/**
 *	A D programming language implementation of the
 *	General Decimal Arithmetic Specification,
 *	Version 1.70, (25 March 2009).
 *	http://www.speleotrove.com/decimal/decarith.pdf)
 *
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt or copy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

// (A)TODO: ensure context flags are being set and cleared properly.

// (A)TODO: opEquals unit test should include numerically equal testing.

// (A)TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// (A)TODO: to/from real or double (float) values needs definition and implementation.

module decimal.arithmetic;

import decimal.context;
import decimal.conv : isDecimal, isFixedDecimal, toBigDecimal;
import decimal.decimal;
//import decimal.rounding;

import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;
import std.string;

//--------------------------------
// classification functions
//--------------------------------

	/// Returns a string indicating the class and sign of the argument.
	/// Classes are: sNaN, NaN, Infinity, Zero, Normal, and Subnormal.
	/// The sign of any NaN values is ignored in the classification.
	/// The argument is not rounded and no flags are changed.
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

//--------------------------------
// copy functions
//--------------------------------

/// Returns a copy of the operand.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy' function in the specification. (p. 43)
public T copy(T)(const T arg) if (isDecimal!T) {
	return arg.dup;
}

/// Returns a copy of the operand with a positive sign.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-abs' function in the specification. (p. 44)
public T copyAbs(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = false;
	return copy;
}

/// Returns a copy of the operand with the sign inverted.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-negate' function in the specification. (p. 44)
public T copyNegate(T)(const T arg) if (isDecimal!T) {
	T copy = arg.dup;
	copy.sign = !arg.sign;
	return copy;
}

/// Returns a copy of the first operand with the sign of the second operand.
/// The copy is unaffected by context and is quiet -- no flags are changed.
/// Implements the 'copy-sign' function in the specification. (p. 44)
public T copySign(T)(const T arg1, const T arg2) if (isDecimal!T) {
	T copy = arg1.dup;
	copy.sign = arg2.sign;
	return copy;
}

/// Returns "the integer which is the exponent of the magnitude
/// of the most significant digit of the operand.
/// (As though the operand were truncated to a single digit
/// while maintaining the value of that digit and without
/// limiting the resulting exponent)".
/// May set the INVALID_OPERATION and DIVISION_BY_ZERO flags.
/// Implements the 'logb' function in the specification. (p. 47)
public T logb(T)(const T arg) {

	T result = T.nan;

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

/// If the first operand is infinite then that operand is returned,
/// otherwise the result is the first operand modified by
/// adding the value of the second operand to its exponent.
/// The second operand must be a finite integer with an exponent of zero.
/// The result may overflow or underflow.
/// Flags: INVALID_OPERATION, UNDERFLOW, OVERFLOW.
/// Implements the 'scaleb' function in the specification. (p. 48)
public T scaleb(T)(const T arg1, const T arg2) if (isDecimal!T) {
	T result = T.nan;
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
	// (A)TODO: check for overflow/underflow -- should this be part of setting
	// the exponent? Don't want that in construction but maybe do here.
	result.exponent = result.exponent + scale;
	return result;
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
/// Flags: INVALID_OPERATION
public T reduce(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T reduced = plus!T(arg, context);
	if (!reduced.isFinite()) {
		return reduced;
	}

	int digits = reduced.digits;
	auto temp = reduced.coefficient;
	int zeros = trimZeros(temp, digits);

	if (zeros) {
		reduced.coefficient = temp;
		reduced.digits = digits - zeros;
		reduced.exponent = reduced.exponent + zeros;
	}
	return reduced;
}

// just a wrapper TODO: can we alias this? does that work?
public T normalize(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	return reduce!T(arg, context);
}

/// Returns the absolute value of the argument.
/// This operation rounds the result and may set flags.
/// The result is equivalent to plus(arg) for positive numbers
/// and to minus(arg) for negative numbers.
/// To return the absolute value without rounding or setting flags
/// use the 'copyAbs' function.
/// Implements the 'abs' function in the specification. (p. 26)
/// Flags: INVALID_OPERATION
public T abs(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T result = T.nan;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = copyAbs!T(arg);
	return round!T(result, context);
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

/// Returns a copy of the argument with same sign as the argument.
/// This operation rounds the result and may set flags.
/// The result is equivalent to add('0', arg).
/// To copy without rounding or setting flags use the 'copy' function.
/// Implements the 'plus' function in the specification. (p. 33)
/// Flags: INVALID_OPERATION
public T plus(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T result = T.nan;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
	return round(result, context);
}

/// Returns a copy of the argument with the opposite sign.
/// This operation rounds the argument and may set flags.
/// Result is equivalent to subtract('0', arg).
/// To copy without rounding or setting flags use the 'copyNegate' function.
/// Implements the 'minus' function in the specification. (p. 37)
/// Flags: INVALID_OPERATION
public T minus(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T result = T.nan;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = copyNegate!T(arg);
	return round(result, context);
}

//-----------------------------------
// next-plus, next-minus, next-toward
//-----------------------------------

/// Returns the smallest representable number that is larger than
/// the argument.
/// Implements the 'next-plus' function in the specification. (p. 34)
/// Flags: INVALID_OPERATION
public T nextPlus(T)(const T arg1,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T result = T.nan;
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
	int adjustedExpo = arg1.exponent + arg1.digits - context.precision;
	if (adjustedExpo < context.tinyExpo) {
			return T(0L, context.tinyExpo);
	}
	// (A)TODO: must add the increment w/o setting flags
	T arg2 = T(1L, adjustedExpo);
	result = add!T(arg1, arg2, context, true);
	// (A)TODO: should be context.max
	if (result > T.max(context)) {
		result = T.infinity;
	}
	return result;
}

/// Returns the largest representable number that is smaller than
/// the argument.
/// Implements the 'next-minus' function in the specification. (p. 34)
/// Flags: INVALID_OPERATION
public T nextMinus(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {

	T result = T.nan;
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
	// This is necessary to catch the special case where the coefficient == 1
	T reduced = reduce!T(arg, context);
	int adjustedExpo = reduced.exponent + reduced.digits - context.precision;
	if (arg.coefficient == 1) adjustedExpo--;
	if (adjustedExpo < context.tinyExpo) {
		return T(0L, context.tinyExpo);
	}
	T addend = T(1, adjustedExpo);
	result = sub!T(arg, addend, context, true);	//(A)TODO: are the flags set/not set correctly?
		if (result < copyNegate!T(T.max(context))) {
		result = copyNegate!T(T.infinity);
	}
	return result;
}

/// Returns the representable number that is closest to the
/// first operand (but not the first operand) in the
/// direction toward the second operand.
/// Implements the 'next-toward' function in the specification. (p. 34-35)
/// Flags: INVALID_OPERATION
public T nextToward(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T result = T.nan;
	if (invalidBinaryOp!T(arg1, arg2, result)) {
		return result;
	}
	// compare them but don't round
	int comp = compare!T(arg1, arg2, context);
	if (comp < 0) return nextPlus!T(arg1, context);
	if (comp > 0) return nextMinus!T(arg1, context);
	result = copySign!T(arg1, arg2);
	return round(result, context);
}

//--------------------------------
// comparison functions
//--------------------------------

/// Compares two operands numerically to the current precision.
/// Returns -1, 0, or +1 if the second operand is, respectively,
/// less than, equal to, or greater than the first operand.
/// Implements the 'compare' function in the specification. (p. 27)
/// Flags: INVALID_OPERATION
public int compare(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context,
		bool roundResult = true) if (isDecimal!T) {
//writeln("compare 1");
	// any operation with a signaling NaN is invalid.
	// if both are signaling, return as if arg1 > arg2.
	if (arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return arg1.isSignaling ? 1 : -1;
	}
//writeln("compare 2");

	// NaN returns > any number, including NaN
	// if both are NaN, return as if arg1 > arg2.
	if (arg1.isNaN || arg2.isNaN) {
		return arg1.isNaN ? 1 : -1;
	}
//writeln("compare 3");

//	// if either is infinite...
//	if (arg1.isInfinite || arg2.isInfinite) {
//		return (arg1.isInfinite && arg2.isInfinite && arg1.isSigned == arg2.isSigned);
//	}

	// if signs differ, just compare the signs
	if (arg1.sign != arg2.sign) {
		// check for zeros: +0 and -0 are equal
		if (arg1.isZero && arg2.isZero) {
			return 0;
		}
		return arg1.sign ? -1 : 1;
	}
//writeln("compare 4");

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
//writeln("compare 5");

	// when all else fails, subtract
	T result = sub!T(arg1, arg2, context, roundResult);
//writefln("result = %s", result);

	// test the coefficient
	// result.isZero may not be true if the result hasn't been rounded
	if (result.coefficient == 0) {
		return 0;
	}
	return result.sign ? -1 : 1;
}

/// Returns true if the operands are equal to the current precision.
/// Finite numbers are equal if they are numerically equal
/// to the current precision.
/// A NaN is not equal to any number, not even another NaN or itself.
/// Infinities are equal if they have the same sign.
/// Zeros are equal regardless of sign.
/// A decimal NaN is not equal to itself (this != this).
/// This function is not included in the specification.
/// Flags: INVALID_OPERATION
public bool equals(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context,
		const bool roundResult = true) if (isDecimal!T) {

//writefln("arg1 = %s", arg1);
//writefln("arg2 = %s", arg2);
	// any operation with a signaling NaN is invalid.
//writeln("equals 1");
	if (arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return false;
	}
//writeln("equals 2");

	// if either is NaN...
	// NaN is never equal to any number, not even another NaN
	if (arg1.isNaN || arg2.isNaN) return false;

//writeln("equals 3");
	// if either is infinite...
	if (arg1.isInfinite || arg2.isInfinite) {
		return (arg1.isInfinite && arg2.isInfinite && arg1.isSigned == arg2.isSigned);
	}

//writeln("equals 4");
	// if either is zero...
	if (arg1.isZero || arg2.isZero) {
		return (arg1.isZero && arg2.isZero);
	}

//writeln("equals 5");
	// if their signs differ...
	if (arg1.sign != arg2.sign) {
		return false;
	}
//writeln("equals 6");

//writefln("arg1.coefficient = %s", arg1.coefficient);
//writefln("arg1.digits = %s", arg1.digits);
//writefln("arg1.exponent = %s", arg1.exponent);
//writefln("arg2.coefficient = %s", arg2.coefficient);
//writefln("arg2.digits = %s", arg2.digits);
//writefln("arg2.exponent = %s", arg2.exponent);
	int diff = (arg1.exponent + arg1.digits) - (arg2.exponent + arg2.digits);
//writefln("diff = %s", diff);
	if (diff != 0) {
		return false;
	}
//writeln("equals 7");

	// if they have the same representation, they are equal
	auto op1c = arg1.coefficient;
	auto op2c = arg2.coefficient;
//writefln("op1c = %s", op1c);
//writefln("op2c = %s", op2c);
//writefln("op1c == op2c = %s", op1c == op2c);
	if (arg1.exponent == arg2.exponent && op1c == op2c) { //arg1.coefficient == arg2.coefficient) {
		return true;
	}
//writeln("equals 8");

	// otherwise they are equal if they represent the same value
	T result = sub!T(arg1, arg2, context, roundResult);
	return result.coefficient == 0;
}

/// Compares the numeric values of two numbers. CompareSignal is identical to
/// compare except that quiet NaNs are treated as if they were signaling.
/// This operation may set the invalid-operation flag.
/// Implements the 'compare-signal' function in the specification. (p. 27)
/// Flags: INVALID_OPERATION
public int compareSignal(T) (const T arg1, const T arg2,
		const DecimalContext context = T.context,
		bool roundResult = true) if (isDecimal!T) {

	// any operation with NaN is invalid.
	// if both are NaN, return as if arg1 > arg2.
	if (arg1.isNaN || arg2.isNaN) {
		contextFlags.setFlags(INVALID_OPERATION);
		return arg1.isNaN ? 1 : -1;
	}
	return (compare!T(arg1, arg2, context, roundResult));
}

/// Numbers (representations which are not NaNs) are ordered such that
/// a larger numerical value is higher in the ordering.
/// If two representations have the same numerical value
/// then the exponent is taken into account;
/// larger (more positive) exponents are higher in the ordering.
/// Compares the operands using their abstract representation rather than
/// their numerical value.
/// Returns 0 if the numbers are equal and have the same representation.
/// Implements the 'compare-total' function in the specification. (p. 42-43)
/// Flags: NONE.
public int compareTotal(T)(const T arg1, const T arg2) if (isDecimal!T) {

	int ret1 =	1;
	int ret2 = -1;

	// if signs differ...
	if (arg1.sign != arg2.sign) {
		return !arg1.sign ? ret1 : ret2;
	}

	// TODO: Move this back into the fixed modules
	// quick bitwise comparison
	static if (isFixedDecimal!T) {
		if (arg1.bits == arg2.bits) return 0;
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

	// is this test really a shortcut? have to get size (digits)!
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
		mant1 = shiftLeft(mant1, diff);
	}
	else if (diff < 0) {
		mant2 = shiftLeft(mant2, -diff);
	}
	auto result = mant1 - mant2;

	// if equal after alignment, compare the original exponents
	if (result == 0) {
		return (arg1.exponent > arg2.exponent) ? ret1 : ret2;
	}
	// otherwise return the numerically larger
	return (result > 0) ? ret1 : ret2;
}

/// compare-total-magnitude takes two numbers and compares them
/// using their abstract representation rather than their numerical value
/// and with their sign ignored and assumed to be 0.
/// The result is identical to that obtained by using compare-total
/// on two operands which are the copy-abs copies of the operands.
/// Implements the 'compare-total-magnitude' function in the specification.
/// (p. 43)
/// Flags: NONE.
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

/// Returns the maximum of the two operands (or NaN).
/// If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
/// Otherwise, Any finite or infinite number is larger than a NaN.
/// If they are not numerically equal, the larger is returned.
/// If they are numerically equal:
/// 1) If the signs differ, the one with the positive sign is returned.
/// 2) If they are positive, the one with the larger exponent is returned.
/// 3) If they are negative, the one with the smaller exponent is returned.
/// 4) Otherwise, they are indistinguishable; the first is returned.
/// The returned number will be rounded to the current context.
/// Implements the 'max' function in the specification. (p. 32)
/// Flags: INVALID_OPERATION, ROUNDED.
const(T) max(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// if both are NaNs or either is an sNan, return NaN.
	if (arg1.isNaN && arg2.isNaN || arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}

	// result will be a finite number or infinity
	// use arg1 as default value
	T result = arg1.dup;

	// if one op is a quiet NaN return the other
	if (arg1.isQuiet || arg2.isQuiet) {
		if (arg1.isQuiet) result = arg2;
	}
	// if the signs differ, return the unsigned operand
	else if (arg1.sign != arg2.sign) {
		if (arg1.sign) result = arg2;
	}
	else {
		// if not numerically equal, return the larger
		int comp = compare!T(arg1, arg2, context);
		if (comp != 0) {
			if (comp < 0) result = arg2;
		}
		// if they have the same exponent they are identical, return either
		else if (arg1.exponent == arg2.exponent) {
			// no assignment -- use default value
		}
		// if they are non-negative, return the one with larger exponent.
		else if (arg1.sign == 0) {
			if (arg1.exponent < arg2.exponent) result = arg2;
		}
		else {
			// else they are negative; return the one with smaller exponent.
			if (arg1.exponent > arg2.exponent) result = arg2;
		}
	}
	// result must be rounded
	return round(result);
}

/// Returns the larger of the two operands (or NaN). Returns the same result
/// as the 'max' function if the signs of the operands are ignored.
/// Implements the 'max-magnitude' function in the specification. (p. 32)
/// Flags: NONE.
const(T) maxMagnitude(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	return max(copyAbs!T(arg1), copyAbs!T(arg2), context);
}


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
/// Flags: INVALID OPERATION, ROUNDED.
const(T) min(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// if both are NaNs or either is an sNan, return NaN.
	if (arg1.isNaN && arg2.isNaN || arg1.isSignaling || arg2.isSignaling) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}

	// result will be a finite number or infinity
	// use arg1 as default value
	T result = arg1.dup;

	// if one op is a quiet NaN return the other
	if (arg1.isQuiet || arg2.isQuiet) {
		if (arg1.isQuiet) result = arg2;
	}

	// if the signs differ, return the signed operand
	if (arg1.sign != arg2.sign) {
		if (!arg1.sign) result = arg2;
	}
	else {
		// if not numerically equal, return the smaller
		int comp = compare!T(arg1, arg2, context);
		if (comp != 0) {
			if (comp > 0) result = arg2;
		}
		// if they have the same exponent they are identical, return either
		else if (arg1.exponent == arg2.exponent) {
			// no assignment -- use default value
		}
		// if they are non-negative, return the one with smaller exponent.
		else if (arg1.sign == 0) {
			if (arg1.exponent > arg2.exponent) result = arg2;
		}
		else {
			// else they are negative; return the one with larger exponent.
			if (arg1.exponent > arg2.exponent) result = arg2;
		}
	}
	// result must be rounded
	return round(result);
}

/// Returns the smaller of the two operands (or NaN). Returns the same result
/// as the 'max' function if the signs of the operands are ignored.
/// Implements the 'min-magnitude' function in the specification. (p. 33)
/// Flags: INVALID OPERATION, ROUNDED.
const(T) minMagnitude(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	return min(copyAbs!T(arg1), copyAbs!T(arg2), context);
}

// TODO: need to check for overflow?
/// Returns a number with a coefficient of 1 and
/// the same exponent as the argument.
/// Not required by the specification.
/// Flags: NONE.
public const (T) quantum(T)(const T arg) if (isDecimal!T) {
		return T(1, arg.exponent);
	}

//--------------------------------
// binary shift
//--------------------------------

public T shl(T)(const T arg, const int n,
		const DecimalContext context = T.context) if (isDecimal!T) {

	T result = T.nan;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
	result.coefficient = result.coefficient << n;
	result.digits = result.digits + 1;
	return round(result, context);
}

public T shr(T)(const T arg, const int n,
		const DecimalContext context = T.context) if (isDecimal!T) {

	T result = T.nan;
	if (invalidOperand!T(arg, result)) {
		return result;
	}
	result = arg;
	result.coefficient = result.coefficient >> n;
	result.digits = result.digits - 1;
	return round(result, context);
}

unittest {
	write("shr, shl...");
	Decimal big, expect, actual;
	big = Decimal(4);
	expect = Decimal(16);
	actual = shl!Decimal(big, 2);
writefln("expect = %s", expect.toAbstract);
writefln("actual = %s", actual.toAbstract);
	assert(expect == actual);
	writeln("test missing");
}


//--------------------------------
// decimal shift and rotate
//--------------------------------

/// Shifts the first operand by the specified number of decimal digits.
/// (Not binary digits!) Positive values of the second operand shift the
/// first operand left (multiplying by tens). Negative values shift right
/// (dividing by tens). If the number is NaN, or if the shift value is less
/// than -precision or greater than precision, an INVALID_OPERATION is signaled.
/// An infinite number is returned unchanged.
/// Implements the 'shift' function in the specification. (p. 49)
public T shift(T)(const T arg, const int n,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// check for NaN operand
	if (invalidOperand!T(arg, arg)) {
		return T.nan;
	}
	// can't shift more than precision
	if (n < -context.precision || n > context.precision) {
		return setInvalidFlag!T();
	}
	// shift by zero returns the argument
	if (n == 0) {
		return arg;
	}
	// shift of an infinite number returns the argument
	if (arg.isInfinite) {
		return arg.dup;
	}

	Decimal result = toBigDecimal!T(arg);
	if (n > 0) {
		shiftLeft(result.coefficient, n, context.precision);
	}
	else {
		shiftRight(result.coefficient, n, context.precision);
	}
	return T(result);
}

unittest {
	write("shift...");
	import decimal.dec32;
    Dec32 num;
	shift!Dec32(num, 4, num.context);
	writeln("test missing");
}

/// Rotates the first operand by the specified number of decimal digits.
/// (Not binary digits!) Positive values of the second operand rotate the
/// first operand left (multiplying by tens). Negative values rotate right
/// (divide by 10s). If the number is NaN, or if the rotate value is less
/// than -precision or greater than precision, an INVALID_OPERATION is signaled.
/// An infinite number is returned unchanged.
/// Implements the 'rotate' function in the specification. (p. 47-48)
public T rotate(T)(const T arg, const int n,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// check for NaN operand
	if (invalidOperand!T(arg, result)) {
		return T.nan;
	}
	if (n < -context.precision || n > context.precision) {
		return setInvalidFlag();
	}
	if (arg.isInfinite) {
		return arg;
	}
	if (n == 0) {
		return arg;
	}

	result = arg.dup;
	Decimal result = toBigDecimal!T(arg);
	if (n > 0) {
		shiftLeft(result);
	}
	else {
		shiftRight(result);
	}
	return T(result);

//	return n < 0 ? decRotR!T(// (L)TODO: And then a miracle happens....

	return result;
}

//------------------------------------------
// binary arithmetic operations
//------------------------------------------

/// Adds the two operands.
/// The result may be rounded and context flags may be set.
/// Implements the 'add' function in the specification. (p. 26)
/// Flags: INVALID_OPERATION, OVERFLOW.
public T add(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context,
		bool roundResult = true) if (isDecimal!T) {
//writefln("add.arg1 = %s", arg1);
//writefln("add.arg2 = %s", arg2);
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
	// calculate in Decimal and convert before return
	Decimal sum = Decimal.zero;
	Decimal augend = toBigDecimal!T(arg1);
	Decimal addend = toBigDecimal!T(arg2);
//writefln("augend = %s", augend);
//writefln("addend = %s", addend);
	// TODO: If the operands are too far apart, one of them will end up zero.
	// align the operands
	alignOps(augend, addend);//, context);
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
	if (roundResult) {
		return round(result, context);
	}
	return result;
}	 // end add(arg1, arg2)


/// Adds a long value to a decimal number. The result is identical to that of
/// the 'add' function as if the long value were converted to a decimal number.
/// The result may be rounded and context flags may be set.
/// This function is not included in the specification.
/// Flags: INVALID_OPERATION, OVERFLOW.
public T addLong(T)(const T arg1, const long arg2,
		const DecimalContext context = T.context,
		bool roundResult = true) if (isDecimal!T) {
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
	// calculate in Decimal and convert before return
	Decimal sum = Decimal.zero;
	Decimal augend = toBigDecimal!T(arg1);
	Decimal addend = Decimal(arg2);
	// align the operands
	alignOps(augend, addend); //, context);
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
	if (roundResult) {
		return round(result, context);
	}
	return result;
}	 // end add(arg1, arg2)

/// Subtracts the second operand from the first operand.
/// The result may be rounded and context flags may be set.
/// Implements the 'subtract' function in the specification. (p. 26)
public T sub(T) (const T arg1, const T arg2,
		const DecimalContext context = T.context,
		const bool roundResult = true) if (isDecimal!T) {
//writefln("sub.arg1 = %s", arg1);
//writefln("sub.arg2 = %s", arg2);
	return add!T(arg1, copyNegate!T(arg2), context , roundResult);
}	 // end sub(arg1, arg2)


/// Subtracts a long value from a decimal number.
/// The result is identical to that of the 'subtract' function
/// as if the long value were converted to a decimal number.
/// This function is not included in the specification.
public T subLong(T) (const T arg1, const long arg2,
		const DecimalContext context = T.context,
		const bool roundResult = true) if (isDecimal!T) {
	return addLong!T(arg1, -arg2, context , roundResult);
}	 // end sub(arg1, arg2)


/// Multiplies the two operands.
/// The result may be rounded and context flags may be set.
/// Implements the 'multiply' function in the specification. (p. 33-34)
public T mul(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context,
		const bool roundResult = true) if (isDecimal!T) {

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
		Decimal product = Decimal.zero;
		static if (is(T:Decimal)) {
			product.coefficient = arg1.coefficient * arg2.coefficient;
		}
		else {
			product.coefficient = T.bigmul(arg1, arg2);
		}

/*		Decimal product = Decimal.zero;
		BigInt mant1 = arg1.coefficient;
		BigInt mant2 = arg2.coefficient;
		product.coefficient = mant1 * mant2;*/
		// (A)TODO: can't convert to BigInt below because the template can't
		// determine the type.
//		product.coefficient = BigInt(arg1.coefficient) * BigInt(arg2.coefficient);
		product.exponent = arg1.exponent + arg2.exponent;
		product.sign = arg1.sign ^ arg2.sign;
		product.digits = numDigits(product.coefficient);
		result = T(product);
	}

	// only needs rounding if
	if (roundResult) {
		return round(result, T.context);
	}
	return result;
}

/// Multiplies a decimal number by a long integer.
/// The result may be rounded and context flags may be set.
/// Not a required function, but useful because it avoids
/// an unnecessary conversion to a decimal when multiplying.
public T mulLong(T)(const T arg1, long arg2,
		const DecimalContext context = T.context,
		const bool roundResult = true)
		if (isDecimal!T) {

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
		Decimal product = Decimal.zero;
		product.coefficient = arg1.coefficient * arg2;
		product.exponent = arg1.exponent;
		product.sign = arg1.sign ^ (arg2 < 0);
		product.digits = numDigits(product.coefficient);
		result = T(product);
	}
	// only needs rounding if
	if (roundResult) {
		return round(result, context);
	}
	return result;
}

/// Multiplies the first two operands and adds the third operand to the result.
/// The result of the multiplication is not rounded prior to the addition.
/// The result may be rounded and context flags may be set.
/// Implements the 'fused-multiply-add' function in the specification. (p. 30)
public T fma(T)(const T arg1, const T arg2, const T arg3,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// (A)TODO: should these both be Decimal?
	T product = mul!T(arg1, arg2, context, false);
	return add!T(product, arg3, context);
}

/// Divides the first operand by the second operand and returns their quotient.
/// Division by zero sets a flag and returns infinity.
/// Result may be rounded and context flags may be set.
/// Implements the 'divide' function in the specification. (p. 27-29)
public T div(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context,
		bool roundResult = true) if (isDecimal!T) {

	// check for NaN and divide by zero
	T result = T.nan;
	if (invalidDivision!T(arg1, arg2, result)) {
		return result;
	}
	Decimal dividend = toBigDecimal!T(arg1);
	Decimal divisor	= toBigDecimal!T(arg2);
	Decimal quotient = Decimal.zero;
	int diff = dividend.exponent - divisor.exponent;
	if (diff > 0) {
		dividend.coefficient = shiftLeft(dividend.coefficient, diff);
		dividend.exponent = dividend.exponent - diff;
		dividend.digits = dividend.digits + diff;
	}
	int shift = 4 + context.precision + divisor.digits - dividend.digits;
	if (shift > 0) {
		dividend.coefficient = shiftLeft(dividend.coefficient, shift);
		dividend.exponent = dividend.exponent - shift;
		dividend.digits = dividend.digits + shift;
	}
	quotient.coefficient = dividend.coefficient / divisor.coefficient;
	quotient.exponent = dividend.exponent - divisor.exponent;
	quotient.sign = dividend.sign ^ divisor.sign;
	quotient.digits = numDigits(quotient.coefficient);
	if (roundResult) {
		round(quotient, context);
//		/// TODO why is this flag being checked?
		if (!contextFlags.getFlag(INEXACT)) {
			quotient = reduce(quotient, context);
		}
	}
	return T(quotient);
}

// TODO: Does this implement the actual spec operation?
/// Divides the first operand by the second and returns the integer portion
/// of the quotient.
/// Division by zero sets a flag and returns infinity.
/// The result may be rounded and context flags may be set.
/// Implements the 'divide-integer' function in the specification. (p. 30)
public T divideInteger(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	// check for NaN and divide by zero
	T result = T.nan;
	if (invalidDivision!T(arg1, arg2, result)) {
		return result;
	}

	Decimal dividend = toBigDecimal!T(arg1);
	Decimal divisor	= toBigDecimal!T(arg2);
	Decimal quotient = Decimal.zero;

	// align operands
	int diff = dividend.exponent - divisor.exponent;
	if (diff < 0) {
		divisor.coefficient = shiftLeft(divisor.coefficient, -diff);
	}
	if (diff > 0) {
		dividend.coefficient = shiftLeft(dividend.coefficient, diff);
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

/// Divides the first operand by the second and returns the
/// fractional remainder.
/// Division by zero sets a flag and returns infinity.
/// The sign of the remainder is the same as that of the first operand.
/// The result may be rounded and context flags may be set.
/// Implements the 'remainder' function in the specification. (p. 37-38)
public T rem(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(arg1, arg2, quotient)) {
		return quotient;
	}
	quotient = divideInteger!T(arg1, arg2, context);
	T remainder = arg1 - mul!T(arg2, quotient, context, false);
	return remainder;
}

// (A)TODO: should not be identical to remainder.
/// Divides the first operand by the second and returns the
/// fractional remainder.
/// Division by zero sets a flag and returns Infinity.
/// The sign of the remainder is the same as that of the first operand.
/// This function corresponds to the "remainder" function
/// in the General Decimal Arithmetic Specification.
public T remainderNear(T)(const T dividend, const T divisor,
		const DecimalContext context = T.context) if (isDecimal!T) {
	T quotient;
	if (invalidDivision!T(dividend, divisor, quotient)) {
		return quotient;
	}
	quotient = divideInteger(dividend, divisor, context);
	T remainder = dividend - mul!T(divisor, quotient, context, false);
	return remainder;
}

// (A)TODO: add 'remquo' function. (Uses remainder-near(?))

//--------------------------------
// rounding routines
//--------------------------------

/// Returns the number which is equal in value and sign
/// to the first operand with the exponent of the second operand.
/// The returned value is rounded to the current precision.
/// This operation may set the invalid-operation flag.
/// Implements the 'quantize' function in the specification. (p. 36-37)
public T quantize(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {

	T result = T.nan;
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

	// (A)TODO: this shift can cause integer overflow for fixed size decimals
	if (diff > 0) {
		result.coefficient = shiftLeft(result.coefficient, diff, context.precision);
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

// (A)TODO: Not clear what this does.
/// Returns a value as if this were the quantize function using
/// the given operand as the left-hand-operand.
/// The result is and context flags may be set.
/// Implements the 'round-to-integral-exact' function
/// in the specification. (p. 39)
public T roundToIntegralExact(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	if (arg.isSignaling) return setInvalidFlag!T();
	if (arg.isSpecial) return arg.dup;
	if (arg.exponent >= 0) return arg.dup;
	const T ONE = T(1L);
	T result = quantize!T(arg, ONE, context.setPrecision(arg.digits));
	return result;
}

// (A)TODO: need to re-implement this so no flags are set.
/// The result may be rounded and context flags may be set.
/// Implements the 'round-to-integral-value' function
/// in the specification. (p. 39)
public T roundToIntegralValue(T)(const T arg,
		const DecimalContext context = T.context) if (isDecimal!T) {
	if (arg.isSignaling) return setInvalidFlag!T();
	if (arg.isQuiet) return arg.dup;
	if (arg.isSpecial) return arg.dup;
	if (arg.exponent >= 0) return arg.dup;
	const T ONE = T(1L);
	T result = quantize!T(arg, ONE, context.setPrecision(arg.digits));
	return result;
}

// (A)TODO: Need to check for subnormal and inexact(?). Or is this done by caller?
// (A)TODO: has non-standard flag setting
// TODO: Try to combine reduce, reduceToIdeal and quantize.
/// Reduces operand to the specified (ideal) exponent.
/// All trailing zeros are removed.
/// (Used to return the "ideal" value following division. p. 28-29)
/*private T reduceToIdeal(T)(const T arg, int ideal,
		const DecimalContext context = T.context) if (isDecimal!T) {
//writefln("arg in = %s", arg);
	T result = T.nan;
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
		// (A)TODO: needed?
		result.exponent = 0;
	}
	result.digits = numDigits(result.coefficient);
//writefln("arg out = %s", result);
	return result;
}*/

/// Aligns the two operands by raising the smaller exponent
/// to the value of the larger exponent, and adjusting the
/// coefficient so the value remains the same.
/// No flags are set and the result is not rounded.
private void alignOps(ref Decimal arg1, ref Decimal arg2)//,
//		const DecimalContext context = T.context) {
	{
	int diff = arg1.exponent - arg2.exponent;
	if (diff > 0) {
		arg1.coefficient = shiftLeft(arg1.coefficient, diff); //, context.precision);
		arg1.exponent = arg2.exponent;
	}
	else if (diff < 0) {
		arg2.coefficient = shiftLeft(arg2.coefficient, -diff); //., context.precision);
		arg2.exponent = arg1.exponent;
	}
}

//--------------------------------
// logical operations
//--------------------------------

/// Returns true if the argument is a valid logical string.
/// All characters in a valid logical string must be either '1' or '0'.
private bool isLogicalString(const string str) {
	foreach(char ch; str) {
		if (ch != '0' && ch != '1') return false;
	}
	return true;
}

/// Returns true if the argument is a valid logical decimal number.
/// The sign and exponent must both be zero, and all (decimal) digits
/// in the coefficient must be either '1' or '0'.
public bool isLogical(T)(const T arg) if (isDecimal!T) {
	if (arg.sign != 0 || arg.exponent != 0) return false;
	string str = decimal.conv.to!string(arg.coefficient);
	return isLogicalString(str);
}

/// Returns true and outputs a valid logical string if the argument is
/// a valid logical decimal number.
/// The sign and exponent must both be zero, and all (decimal) digits
/// in the coefficient must be either '1' or '0'.
private bool isLogicalOperand(T)(const T arg, out string str) if (isDecimal!T) {
	if (arg.sign != 0 || arg.exponent != 0) return false;
	str = decimal.conv.to!string(arg.coefficient);
	return isLogicalString(str);
}

	unittest {	// logical string/number tests
		import decimal.dec32;
		assert(isLogicalString("010101010101"));
		assert(isLogical(Dec32("1010101")));
		string str;
		assert(isLogicalOperand(Dec32("1010101"), str));
		assert(str == "1010101");
	}

//--------------------------------
// unary logical operations
//--------------------------------

/// Inverts and returns a decimal logical number.
/// Implements the 'invert' function in the specification. (p. 44)
public T invert(T)(T arg) if (isDecimal!T) {
	string str;
	if (!isLogicalOperand(arg, str)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	return T(invert(str));
}

/// Inverts and returns a logical string.
/// Each each '1' is changed to a '0', and vice versa.
private T invert(T: string)(T arg) {
	char[] result = new char[arg.length];
	for(int i = 0; i < arg.length; i++) {
		if (arg[i] == '0') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

	unittest {	// inverse
		import decimal.dec64;
		assert(invert(Dec64(101001)) == 10110);
		assert(invert(Dec64(1)) == 0);
		assert(invert(Dec64(0)) == 1);
	}

//--------------------------------
// binary logical operations
//--------------------------------

/// called by opBinary.
private T opLogical(string op, T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if(isDecimal!T) {
	int precision = T.context.precision;
	string str1;
	if (!isLogicalOperand(arg1, str1)) {
		return setInvalidFlag!T;
	}
	string str2;
	if (!isLogicalOperand(arg2, str2)) {
		return setInvalidFlag!T;
	}
	static if (op == "and") {
		string str = and(str1, str2);
	}
	static if (op == "or") {
		string str = or(str1, str2);
	}
	static if (op == "xor") {
		string str = xor(str1, str2);
	}
	return T(str);
}

//----------------------

/// Performs a logical 'and' of the arguments and returns the result
/// Implements the 'and' function in the specification. (p. 41)
public T and(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	return opLogical!("and", T)(arg1, arg2, context);
}

/// Performs a logical 'and' of the (string) arguments and returns the result
T and(T: string)(const T arg1, const T arg2) {
	string str1, str2;
	int length, diff;
	if (arg1.length > arg2.length) {
		length = arg2.length;
		diff = arg1.length - arg2.length;
		str2 = arg1;
		str1 = rightJustify(arg2, arg1.length, '0');
	}
	else if (arg1.length < arg2.length) {
		length = arg1.length;
		diff = arg2.length - arg1.length;
		str1 = rightJustify(arg1, arg2.length, '0');
		str2 = arg2;
	} else {
		length = arg1.length;
		diff = 0;
		str1 = arg1;
		str2 = arg2;
	}
	char[] result = new char[length];
	for(int i = 0; i < length; i++) {
		if (str1[i + diff] == '1' && str2[i + diff] == '1') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

//----------------------

/// Performs a logical 'or' of the arguments and returns the result
/// Implements the 'or' function in the specification. (p. 47)
public T or(T)(const T arg1, const T arg2,
		const DecimalContext context = T.context) if (isDecimal!T) {
	return opLogical!("or", T)(arg1, arg2, context);
}

/// Performs a logical 'or' of the (string) arguments and returns the result
T or(T: string)(const T arg1, const T arg2) {
	string str1, str2;
	int length;
	if (arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, arg1.length, '0');
	}
	if (arg1.length < arg2.length) {
		length = arg2.length;
		str1 = rightJustify(arg1, arg2.length, '0');
		str2 = arg2;
	} else {
		length = arg1.length;
		str1 = arg1;
		str2 = arg2;
	}
	char[] result = new char[length];
	for(int i = 0; i < length; i++) {
		if (str1[i] == '1' || str2[i] == '1') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

//----------------------

	/// Performs a logical 'xor' of the arguments and returns the result
	/// Implements the 'xor' function in the specification. (p. 49)
	public T xor(T)(const T arg1, const T arg2,
			const DecimalContext context = T.context) if (isDecimal!T) {
		return opLogical!("xor", T)(arg1, arg2, context);
	}

	/// Performs a logical 'xor' of the (string) arguments
	/// and returns the result.
	T xor(T: string)(const T arg1, const T arg2) {
		string str1, str2;
		int length;
		if (arg1.length > arg2.length) {
			length = arg1.length;
			str1 = arg1;
			str2 = rightJustify(arg2, arg1.length, '0');
		}
		if (arg1.length < arg2.length) {
			length = arg2.length;
			str1 = rightJustify(arg1, arg2.length, '0');
			str2 = arg2;
		} else {
			length = arg1.length;
			str1 = arg1;
			str2 = arg2;
		}
		char[] result = new char[length];
		for(int i = 0; i < length; i++) {
			if (str1[i] != str2[i]) {
				result[i] = '1';
			} else {
				result[i] = '0';
			}
		}
		return result.idup;
	}

	unittest { // binary logical ops
		Decimal op1, op2;
		op1 = 10010101;
		op2 = 11100100;
		assert((op1 & op2) == Decimal(10000100));
		assert((op1 | op2) == Decimal(11110101));
		assert((op1 ^ op2) == Decimal( 1110001));
		op1 =   100101;
		op2 = 11100100;
		assert((op1 & op2) == Decimal(  100100));
		assert((op1 | op2) == Decimal(11100101));
		assert((op1 ^ op2) == Decimal(11000001));
	}

//--------------------------------
// validity functions
//--------------------------------

/// Sets the invalid-operation flag and returns a quiet NaN.
private T setInvalidFlag(T)(ushort payload = 0) if (isDecimal!T) {
	contextFlags.setFlags(INVALID_OPERATION);
	T result = T.nan;
	if (payload != 0) {
		result.payload = payload;
	}
	return result;
}

/// Returns true and sets the invalid-operation flag if either operand
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

//--------------------------------
// unit tests
//--------------------------------

unittest {
	writeln("===================");
	writeln("arithmetic....begin");
	writeln("===================");
}

unittest {	// classify
	Decimal arg;
	arg = Decimal("Inf");
	assert("+Infinity" == classify(arg));
	arg = Decimal("1E-10");
	assert("+Normal" == classify(arg));
	arg = Decimal("-0");
	assert("-Zero" == classify(arg));
	arg = Decimal("-0.1E-99");
	assert("-Subnormal" == classify(arg));
	arg = Decimal("NaN");
	assert("NaN" == classify(arg));
	arg = Decimal("sNaN");
	assert("sNaN" == classify(arg));
}

unittest {	// copy
	Decimal arg, expect;
	arg  = Decimal("2.1");
	expect = Decimal("2.1");
	assert(compareTotal(copy(arg),expect) == 0);
	arg  = Decimal("-1.00");
	expect = Decimal("-1.00");
	assert(compareTotal(copy(arg),expect) == 0);
}

unittest {	// copyAbs
	Decimal arg, expect;
	arg  = 2.1;
	expect = 2.1;
	assert(compareTotal(copyAbs(arg),expect) == 0);
	arg  = Decimal("-1.00");
	expect = Decimal("1.00");
	assert(compareTotal(copyAbs(arg),expect) == 0);
}

unittest {	// copyNegate
	Decimal arg	= "101.5";
	Decimal expect = "-101.5";
	assert(compareTotal(copyNegate(arg),expect) == 0);
}

unittest {	// copySign
	Decimal arg1, arg2, expect;
	arg1 = 1.50; arg2 = 7.33; expect = 1.50;
	assert(compareTotal(copySign(arg1, arg2),expect) == 0);
	arg2 = -7.33;
	expect = -1.50;
	assert(compareTotal(copySign(arg1, arg2),expect) == 0);
}

unittest {	// logb
	Decimal arg, expect, actual;
	arg = Decimal("250");
	expect = Decimal("2");
	actual = logb(arg);
	assert(expect == actual);
}

unittest {	// scaleb
	Decimal expect, actual;
	auto arg1 = Decimal("7.50");
	auto arg2 = Decimal("-2");
	expect = Decimal("0.0750");
	actual = scaleb(arg1, arg2);
	assert(expect == actual);
}

unittest {	// reduce
	Decimal arg;
	string expect, actual;
	arg = Decimal("1.200");
	expect = "1.2";
	actual = reduce(arg).toString;
	assert(expect == actual);
}

unittest {	// abs
	Decimal arg;
	Decimal expect, actual;
	arg = Decimal("-Inf");
	expect = Decimal("Inf");
	actual = abs(arg, decimal.context.testContext);
	assert(expect == actual);
	arg = 101.5;
	expect = 101.5;
	actual = abs(arg, testContext);
	assert(expect == actual);
	arg = -101.5;
	actual = abs(arg, testContext);
	assert(expect == actual);
}

unittest {	// sgn
	Decimal arg;
	arg = -123;
	assert(-1 == sgn(arg));
	arg = 2345;
	assert( 1 == sgn(arg));
	arg = Decimal("0.0000");
	assert( 0 == sgn(arg));
	arg = Decimal.infinity(true);
	assert(-1 == sgn(arg));
}

unittest {	// plus
	Decimal zero = Decimal.zero;
	Decimal arg, expect, actual;
	arg = 1.3;
	expect = add(zero, arg, testContext);
	actual = plus(arg, testContext);
	assert(expect == actual);
	arg = -1.3;
	expect = add(zero, arg, testContext);
	actual = plus(arg, testContext);
	assert(expect == actual);
}

unittest {	// minus
	Decimal zero = Decimal(0);
	Decimal arg, expect, actual;
	arg = 1.3;
	expect = sub(zero, arg, testContext);
	actual = minus(arg, testContext);
	assert(expect == actual);
	arg = -1.3;
	expect = sub(zero, arg, testContext);
	actual = minus(arg, testContext);
	assert(expect == actual);
}

unittest {	// nextPlus
	Decimal arg, expect, actual;
	arg = 1;
	expect = Decimal("1.00000001");
	actual = nextPlus(arg, testContext);
	assert(expect == actual);
	arg = 10;
	expect = Decimal("10.0000001");
	actual = nextPlus(arg, testContext);
	assert(expect == actual);
}

unittest {	// nextMinus
	Decimal arg, expect, actual;
	arg = 1;
	expect = 0.999999999;
	actual = nextMinus(arg, testContext);
	assert(expect == actual);
	arg = -1.00000003;
	expect = -1.00000004;
	actual = nextMinus(arg, testContext);
	assert(expect == actual);
}

unittest {	// nextToward
	Decimal arg1, arg2, expect, actual;
	arg1 = 1;
	arg2 = 2;
	expect = 1.00000001;
	actual = nextToward(arg1, arg2, testContext);
	assert(expect == actual);
	arg1 = -1.00000003;
	arg2 = 0;
	expect = -1.00000002;
	actual = nextToward(arg1, arg2, testContext);
	assert(expect == actual);
}

unittest {	// compare
	Decimal arg1, arg2;
	arg1 = Decimal(2.1);
	arg2 = Decimal("3");
	assert(compare(arg1, arg2, testContext) == -1);
	arg1 = 2.1;
	arg2 = Decimal(2.1);
	assert(compare(arg1, arg2, testContext) == 0);
}

unittest {	// equals
	Decimal arg1, arg2;
	arg1 = 123.4567;
	arg2 = 123.4568;
	assert(!equals!Decimal(arg1, arg2, Decimal.context));
	arg2 = 123.4567;
	assert(equals!Decimal(arg1, arg2, Decimal.context));
}

unittest {
	write("compareSignal...");
	writeln("test missing");
}

unittest {	// compareTotal
	Decimal arg1, arg2;
	int result;
	arg1 = Decimal("12.30");
	arg2 = Decimal("12.3");
	result = compareTotal(arg1, arg2);
	assert(result == -1);
	arg1 = Decimal("12.30");
	arg2 = Decimal("12.30");
	result = compareTotal(arg1, arg2);
	assert(result == 0);
	arg1 = Decimal("12.3");
	arg2 = Decimal("12.300");
	result = compareTotal(arg1, arg2);
	assert(result == 1);
}

unittest {	// sameQuantum
	Decimal arg1, arg2;
	arg1 = 2.17;
	arg2 = 0.001;
	assert(!sameQuantum(arg1, arg2));
	arg2 = 0.01;
	assert(sameQuantum(arg1, arg2));
	arg2 = 0.1;
	assert(!sameQuantum(arg1, arg2));
}

unittest {	// max
	Decimal arg1, arg2, expect, actual;
	arg1 = 3; arg2 = 2; expect = 3;
	actual = max(arg1, arg2, testContext);
	assert(expect == actual);
	arg1 = -10; arg2 = 3; expect = 3;
	actual = max(arg1, arg2, testContext);
	assert(expect == actual);
}

unittest {
	write("maxMagnitude...");
	writeln("test missing");
}

unittest {	// min
	Decimal arg1, arg2, expect, actual;
	arg1 = 3; arg2 = 2; expect = 2;
	actual = min(arg1, arg2, testContext);
	assert(expect == actual);
	arg1 = -10; arg2 = 3; expect = -10;
	actual = min(arg1, arg2, testContext);
	assert(expect == actual);
}

unittest {
	write("minMagnitude...");
	writeln("test missing");
}

unittest {	// quantum
	Decimal arg, expect, actual;
	arg = 23.14E-12;
	expect = 1E-14;
	actual = quantum(arg);
	assert(expect == actual);
}

unittest {	// add
	// (A)TODO: change inputs to real numbers
	Decimal arg1, arg2, sum;
	arg1 = Decimal("12");
	arg2 = Decimal("7.00");
	sum = add(arg1, arg2, testContext);
	assert("19.00" == sum.toString);
	arg1 = Decimal("1E+2");
	arg2 = Decimal("1E+4");
	sum = add(arg1, arg2, testContext);
	assert("1.01E+4" == sum.toString);
}

unittest {	// addLong
	Decimal arg1, sum;
	long arg2;
	arg2 = 12;
	arg1 = Decimal("7.00");
	sum = addLong(arg1, arg2, testContext);
	assert("19.00" == sum.toString);
	arg1 = Decimal("1E+2");
	arg2 = 10000;
	sum = addLong(arg1, arg2, testContext);
	assert("10100" == sum.toString);
}

unittest {	// mul
	Decimal arg1, arg2, result;
	arg1 = Decimal("1.20");
	arg2 = 3;
	result = mul(arg1, arg2, testContext);
	assert("3.60" == result.toString());
	arg1 = 7;
	result = mul(arg1, arg2, testContext);
	assert("21" == result.toString());
}

unittest { // mulLong
	Decimal arg1, result;
	long arg2;
	arg1 = Decimal("1.20");
	arg2 = 3;
	result = mulLong(arg1, arg2, testContext);
	assert("3.60" == result.toString());
	arg1 = -7000;
	result = mulLong(arg1, arg2, testContext);
	assert("-21000" == result.toString());
}

unittest {	// fma
	Decimal arg1, arg2, arg3, expect, actual;
	arg1 = 3; arg2 = 5; arg3 = 7;
	expect = 22;
	actual = (fma(arg1, arg2, arg3, testContext));
	assert(expect == actual);
	arg1 = 3; arg2 = -5; arg3 = 7;
	expect = -8;
	actual = (fma(arg1, arg2, arg3, testContext));
	assert(expect == actual);
	arg1 = 888565290;
	arg2 = 1557.96930;
	arg3 = -86087.7578;
	expect = Decimal(1.38435736E+12);
	actual = (fma(arg1, arg2, arg3, testContext));
	assert(expect == actual);
}

unittest {	// div
	Decimal arg1, arg2, actual, expect;
	arg1 = 1;
	arg2 = 3;
	actual = div(arg1, arg2, testContext);
	expect = Decimal(0.333333333);
	assert(expect == actual);
	assert(expect.toString == actual.toString);
	arg1 = 1;
	arg2 = 10;
	expect = 0.1;
	actual = div(arg1, arg2, testContext);
	assert(expect == actual);
}

unittest {	// divideInteger
	Decimal arg1, arg2, actual, expect;
	arg1 = 2;
	arg2 = 3;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 0;
	assert(expect == actual);
	arg1 = 10;
	actual = divideInteger(arg1, arg2, testContext);
	expect = 3;
	assert(expect == actual);
	arg1 = 1;
	arg2 = 0.3;
	actual = divideInteger(arg1, arg2, testContext);
	assert(expect == actual);
}

unittest {	// remainder
	Decimal arg1, arg2, actual, expect;
	arg1 = 2.1;
	arg2 = 3;
	actual = rem(arg1, arg2, testContext);
	expect = 2.1;
	assert(expect == actual);
	arg1 = 10;
	actual = rem(arg1, arg2, testContext);
	expect = 1;
	assert(expect == actual);
}

unittest {
	write("remainderNear...");
	writeln("test missing");
}

unittest {	// quantize
    auto context = testContext;
	Decimal arg1, arg2, actual, expect;
	string str;
	arg1 = Decimal("2.17");
	arg2 = Decimal("0.001");
	expect = Decimal("2.170");
	actual = quantize!Decimal(arg1, arg2, context);
	assert(expect == actual);
	arg1 = Decimal("2.17");
	arg2 = Decimal("0.01");
	expect = Decimal("2.17");
	actual = quantize(arg1, arg2, context);
	assert(expect == actual);
	arg1 = Decimal("2.17");
	arg2 = Decimal("0.1");
	expect = Decimal("2.2");
	actual = quantize(arg1, arg2, context);
	assert(expect == actual);
	arg1 = Decimal("2.17");
	arg2 = Decimal("1e+0");
	expect = Decimal("2");
	actual = quantize(arg1, arg2, context);
	assert(expect == actual);
	arg1 = Decimal("2.17");
	arg2 = Decimal("1e+1");
	expect = Decimal("0E+1");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("-Inf");
	arg2 = Decimal("Infinity");
	expect = Decimal("-Infinity");
	actual = quantize(arg1, arg2, context);
	assert(expect == actual);
	arg1 = Decimal("2");
	arg2 = Decimal("Infinity");
	expect = Decimal("NaN");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("-0.1");
	arg2 = Decimal("1");
	expect = Decimal("-0");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("-0");
	arg2 = Decimal("1e+5");
	expect = Decimal("-0E+5");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("+35236450.6");
	arg2 = Decimal("1e-2");
	expect = Decimal("NaN");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("-35236450.6");
	arg2 = Decimal("1e-2");
	expect = Decimal("NaN");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("217");
	arg2 = Decimal("1e-1");
	expect = Decimal( "217.0");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("217");
	arg2 = Decimal("1e+0");
	expect = Decimal("217");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("217");
	arg2 = Decimal("1e+1");
	expect = Decimal("2.2E+2");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	arg1 = Decimal("217");
	arg2 = Decimal("1e+2");
	expect = Decimal("2E+2");
	actual = quantize(arg1, arg2, context);
	assert(expect.toString, actual.toString);
	assert(expect == actual);
}

unittest { // roundToIntegralExact
	Decimal arg, expect, actual;
	arg = 2.1;
	expect = 2;
	actual = roundToIntegralExact(arg, testContext);
	assert(expect == actual);
	arg = 100;
	expect = 100;
	actual = roundToIntegralExact(arg, testContext);
	assert(expect == actual);
	assert(expect.toString, actual.toString);
}

unittest {
	write("reduceToIdeal...");
	writeln("test missing");
}

unittest {	// setInvalidFlag
	Decimal arg, expect, actual;
	// (A)TODO: Can't actually test payloads at this point.
	arg = Decimal("sNaN123");
	expect = Decimal("NaN123");
	actual = abs!Decimal(arg, testContext);
	assert(actual.isQuiet);
	assert(contextFlags.getFlag(INVALID_OPERATION));
//	  assert(actual.toAbstract == expect.toAbstract);
}

unittest { // alignOps
	Decimal arg1, arg2;
	arg1 = 1.3E35;
	arg2 = -17.4E29;
	alignOps(arg1, arg2);
	assert(arg1.coefficient == 13000000);
	assert(arg2.exponent == 28);
}

unittest {
	write("invalidBinaryOp...");
	writeln("test missing");
}

unittest {
	write("invalidOperand...");
	writeln("test missing");
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


