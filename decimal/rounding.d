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

module decimal.rounding;

import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;

import decimal.arithmetic: compare, copyNegate, equals;
import decimal.context;
import decimal.conv;
import decimal.decimal;
import decimal.test;

/// Rounds the referenced number using the precision and rounding mode of
/// the context parameter.
/// Flags: SUBNORMAL, CLAMPED, OVERFLOW, INEXACT, ROUNDED.
public void round(T)(ref T num,
		const DecimalContext context = T.context) if (isDecimal!T) {

	// special values aren't rounded
	if (!num.isFinite) return;

	// zero values aren't rounded, but they are checked for
	// subnormal and out of range exponents.
	if (num.isZero) {
/*		if (num.exponent < context.minExpo) {
			contextFlags.setFlags(SUBNORMAL);
			if (num.exponent < context.tinyExpo) {
				int temp = context.tinyExpo;
				num.exponent = context.tinyExpo;
			}
		}*/
		return;
	}

	// handle subnormal numbers
	if (num.isSubnormal(context)) {
		contextFlags.setFlags(SUBNORMAL);
		int diff = context.minExpo - num.adjustedExponent;
		// decrease the precision and round
		int precision = context.precision - diff;
		if (num.digits > precision) {
			auto ctx = BigDecimal.setPrecision(precision);
			roundByMode(num, ctx);
		}
		// if the result of rounding a subnormal is zero
		// the clamped flag is set. (Spec. p. 51)
		if (num.isZero) {
			num.exponent = context.tinyExpo;
			contextFlags.setFlags(CLAMPED);
		}
		return;
	}

	// check for overflow
	if (overflow(num, context)) return;
	// round the number
	roundByMode(num, context);
	// check again for an overflow
	overflow(num, context);

} // end round()

//--------------------------------
// private methods
//--------------------------------

/// Returns true if the number overflows and adjusts the number
/// according to the rounding mode.
/// Implements the 'overflow' processing in the specification. (p. 53)
/// Flags: OVERFLOW, ROUNDED, INEXACT.
private bool overflow(T)(ref T num,
		const DecimalContext context = T.context) if (isDecimal!T) {
	if (num.adjustedExponent <= context.maxExpo) return false;
	switch (context.rounding) {
		case Rounding.HALF_UP:
		case Rounding.HALF_EVEN:
		case Rounding.HALF_DOWN:
		case Rounding.UP:
			num = T.infinity(num.sign);
			break;
		case Rounding.DOWN:
			num = T.max(num.sign);
			break;
		case Rounding.CEILING:
			num = num.sign ? T.max(true) : T.infinity;
			break;
		case Rounding.FLOOR:
			num = num.sign ? T.infinity(true) : T.max;
			break;
		default:
			break;
	}
	contextFlags.setFlags(OVERFLOW | INEXACT | ROUNDED);
	return true;
}

/// Rounds the number to the context precision.
/// The number is rounded using the context rounding mode.
private void roundByMode(T)(ref T num,
		const DecimalContext context = T.context) if (isDecimal!T) {
	// calculate remainder
	T remainder = getRemainder(num, context);
	// if the number wasn't rounded, return
	if (remainder.isZero) {
		return;
	}
	switch (context.rounding) {
		case Rounding.UP:
			T temp = T.zero;
			if (remainder != temp) {
				incrementAndRound(num);
			}
			return;
		case Rounding.DOWN:
			return;
		case Rounding.CEILING:
			T temp = T.zero;
			if (!num.sign && (remainder != temp)) {
				incrementAndRound(num);
			}
			return;
		case Rounding.FLOOR:
			T temp = T.zero;
			if (num.sign && remainder != temp) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_UP:
			if (firstDigit(remainder.coefficient) >= 5) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_DOWN:
			if (testFive(remainder.coefficient) > 0) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_EVEN:
			switch (testFive(remainder.coefficient)) {
				case -1:
					break;
				case 1:
					incrementAndRound(num);
					break;
				default:
					if (lastDigit(num.coefficient) & 1) {
						incrementAndRound(num);
					}
					break;
				}
			return;
		default:
			return;
	}	// end switch(mode)
}	// end roundByMode()

/// Shortens the coefficient of the number to the context precision,
/// adjusts the exponent, and returns the (unsigned) remainder.
/// If the number is already less than or equal to the precision, the
/// number is unchanged and the remainder is zero.
/// Otherwise the rounded flag is set, and if the remainder is not zero
/// the inexact flag is also set.
/// Flags: ROUNDED, INEXACT.
private T getRemainder(T) (ref T num,
		const DecimalContext context = T.context) if (isDecimal!T) {

	T remainder = T.zero;
	int diff = num.digits - context.precision;
	if (diff <= 0) {
		return remainder;
	}
	contextFlags.setFlags(ROUNDED);
	// the precision can be zero when rounding subnormal numbers
	if (context.precision == 0) {
		num = T.zero(num.sign);
	} else {
		auto divisor = T.pow10(diff);
		auto dividend = num.coefficient;
		auto quotient = dividend/divisor;
		auto mant = dividend - quotient*divisor;
		if (mant != 0) {
			remainder.zero;
			remainder.digits = diff;
			remainder.exponent = num.exponent;
			remainder.coefficient = mant;
			contextFlags.setFlags(INEXACT);
		}
		num.coefficient = quotient;
		num.digits = context.precision;
		num.exponent = num.exponent + diff;
	}

	return remainder;
}

/// Increments the coefficient by 1. If this causes an overflow
/// the coefficient is adjusted by clipping the last digit (it will be zero)
/// and incrementing the exponent.
private void incrementAndRound(T)(ref T num) if (isDecimal!T) {
	int digits = num.digits;
	num.coefficient = num.coefficient + 1;
	if (lastDigit(num.coefficient) == 0) {
		if (num.coefficient / T.pow10(digits) > 0) {
			num.coefficient = num.coefficient / 10;
			num.exponent = num.exponent + 1;
		}
	}
}

/// Returns -1, 0, or 1 if the remainder is less than, equal to, or more than
/// half of the least significant digit of the shortened coefficient.
/// Exactly half is a five followed by zero or more zero digits.
public int testFive(const ulong n) {
	int digits = numDigits(n);
	int first = cast(int)(n / TENS[digits-1]);
	if (first < 5) return -1;
	if (first > 5) return +1;
	int zeros = cast(int)(n % TENS[digits-1]);
	return (zeros != 0) ? 1 : 0;
}

/// Returns -1, 1, or 0 if the remainder is less than, more than,
/// or exactly half the least significant digit of the shortened coefficient.
/// Exactly half is a five followed by zero or more zero digits.
public int testFive(const BigInt arg) {
	BigInt big = mutable(arg);
	int first = firstDigit(arg);
	if (first < 5) return -1;
	if (first > 5) return +1;
	int zeros = (big % tens(numDigits(big)-1)).toInt;
	return (zeros != 0) ? 1 : 0;
}

/// Converts an integer to a decimal (coefficient and exponent) form.
/// The input value is rounded to the context precision,
/// the number of digits is adjusted, and the exponent is returned.
public uint setExponent(const bool sign, ref ulong mant, ref uint digits,
		const DecimalContext context) {

	uint inDigits = digits;
	ulong remainder = clipRemainder(mant, digits, context.precision);
	int expo = inDigits - digits;

	// if the remainder is zero, return
	if (remainder == 0) {
		return expo;
	}

	switch (context.rounding) {
	case Rounding.DOWN:
		break;
	case Rounding.HALF_UP:
		if (firstDigit(remainder, digits) >= 5) {
			increment(mant, digits);
		}
		break;
	case Rounding.HALF_EVEN:
		int five = testFive(remainder);
		if (five > 0) {
			increment(mant, digits);
			break;
		}
		if (five < 0) {
			break;
		}
		// remainder == 5
		// if last digit is odd...
		if (mant & 1) {
			increment(mant, digits);
		}
		break;
	case Rounding.CEILING:
		if (!sign) {
			increment(mant, digits);
		}
		break;
	case Rounding.FLOOR:
		if (sign) {
			increment(mant, digits);
		}
		break;
	case Rounding.HALF_DOWN:
		if (firstDigit(remainder, digits) > 5) {
			increment(mant, digits);
		}
		break;
	case Rounding.UP:
		if (remainder != 0) {
			increment(mant, digits);
		}
		break;
	default:
		break;
	}	 // end switch(mode)

	// this can only be true if the number was all 9s and rolled over;
	// e.g., 999 + 1 = 1000. So clip a zero and increment the exponent.
	if (digits > context.precision) {
		mant /= 10;
		expo++;
		digits--;
	}
	return expo;

} // end setExponent()

/// Shortens the number to the specified precision and
/// returns the (unsigned) remainder.
/// Flags: ROUNDED, INEXACT.
private ulong clipRemainder(ref ulong num, ref uint digits, uint precision) {
	ulong remainder = 0;
	int diff = digits - precision;
	// if diff is less than or equal to zero no rounding is required.
	if (diff <= 0) {
		return remainder;
	}
	// if (remainder != 0) {...} ?
	//contextFlags.setFlags(ROUNDED);

	if (precision == 0) {
		num = 0;
	} else {
		// can't overflow -- diff <= 19
		ulong divisor = 10L^^diff;
		ulong dividend = num;
		ulong quotient = dividend / divisor;
		num = quotient;
		remainder = dividend - quotient*divisor;
		digits = precision;
	}
	return remainder;
}

/// Increments the number by 1.
/// Re-calculates the number of digits -- the increment may have caused
/// an increase in the number of digits, i.e., input number was all 9s.
private void increment(T:ulong)(ref T num, ref uint digits) {
	num++;
	digits = numDigits(num);
}

//-----------------------------
// useful constants
//-----------------------------

// BigInt has problems with const and immutable; these should be const values.
// Best I can do is to make them private.
// (R)TODO: properties with getters & no setters?
private BigInt BIG_ZERO = BigInt(0);
private BigInt BIG_ONE  = BigInt(1);
private BigInt BIG_FIVE = BigInt(5);
private BigInt BIG_TEN  = BigInt(10);
private BigInt BILLION  = BigInt(1_000_000_000);
private BigInt QUINTILLION = BigInt(1_000_000_000_000_000_000);

/// An array of unsigned long integers with values of
/// powers of ten from 10^^0 to 10^^18
public static ulong[19] TENS = [10L^^0,
		10L^^1,  10L^^2,  10L^^3,  10L^^4,  10L^^5,  10L^^6,
		10L^^7,  10L^^8,  10L^^9,  10L^^10, 10L^^11, 10L^^12,
		10L^^13, 10L^^14, 10L^^15, 10L^^16, 10L^^17, 10L^^18];

/// An array of unsigned long integers with values of
/// powers of five from 5^^0 to 5^^26
public static ulong[27] FIVES = [5L^^0,
		5L^^1,  5L^^2,  5L^^3,  5L^^4,  5L^^5,  5L^^6,
		5L^^7,  5L^^8,  5L^^9,  5L^^10, 5L^^11, 5L^^12,
		5L^^13, 5L^^14, 5L^^15, 5L^^16, 5L^^17, 5L^^18,
		5L^^19, 5L^^20, 5L^^21, 5L^^22, 5L^^23, 5L^^24,
		5L^^25, 5L^^26];

/// The maximum number of decimal digits that fit in an int value.
public const int MAX_INT_DIGITS = 9;
/// The maximum decimal value that fits in an int.
public const uint MAX_DECIMAL_INT = 10U^^MAX_INT_DIGITS - 1;
/// The maximum number of decimal digits that fit in a long value.
public const int MAX_LONG_DIGITS = 18;
/// The maximum decimal value that fits in a long.
public const ulong MAX_DECIMAL_LONG = 10UL^^MAX_LONG_DIGITS - 1;

//-----------------------------
// decimal digit functions
//-----------------------------

/// Returns the number of digits in the argument.
public int numDigits(const BigInt arg) {
    // special cases
	if (arg == 0) return 0;
    BigInt big = mutable(arg);
    if (big < BIG_TEN) return 1;
    // otherwise reduce until number fits into a long integer...
	int count = 0;
	while (big > QUINTILLION) {
		big /= QUINTILLION;
		count += 18;
	}
	/// ...and delegate result to long integer version
	long n = big.toLong;
	return count + numDigits(n);
}

/// Returns the number of digits in the argument,
/// where the argument is an unsigned long integer.
public int numDigits(const ulong n, const int maxValue = 19) {
    // special cases:
	if (n == 0) return 0;
	if (n < 10) return 1;
	if (n >= TENS[maxValue - 1]) return maxValue;
    // use a binary search to count the digits
	int min = 1;
	int max = maxValue - 1;
	while (min <= max) {
		int mid = (min + max)/2;
		if (n < TENS[mid]) {
			max = mid - 1;
		}
		else {
			min = mid + 1;
		}
	}
	return min;
}

/// Returns the first digit of the argument.
public int firstDigit(const BigInt arg) {
	BigInt big = mutable(arg);
	while (big > QUINTILLION) {
		big /= QUINTILLION;
	}
	long n = big.toLong();
	return firstDigit(n);
}

/// Returns the first digit of the argument.
public int firstDigit(const ulong n, int maxValue = 19) {
	if (n == 0) return 0;
	if (n < 10) return cast(int) n;
	int d = numDigits(n, maxValue);
	return cast(int)(n/TENS[d-1]);
}

/// Shifts the number left by the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted right.
public BigInt shiftLeft(BigInt num, const int n, const int precision) {
	if (n > 0) {
		BigInt fives = n < 27 ? BigInt(FIVES[n]) : BIG_FIVE^^n;
		num = num << n;
		num *= fives;
	}
	if (n < 0) {
		num = shiftRight(num, -n, precision);
	}
	return num;
}

/// Shifts the number left by the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted right.
public BigInt shiftLeft(BigInt num, const int n) {
	return shiftLeft(num, n, int.max);
// const int precision = int.max
/*	if (n > 0) {
		BigInt fives = n < 27 ? BigInt(FIVES[n]) : BIG_FIVE^^n;
		num = num << n;
		num *= fives;
	}
	if (n < 0) {
		num = shiftRight(num, -n, precision);
	}
	return num;*/
}

/// Shifts the number to the left by the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted to the right.
public ulong shiftLeft(ulong num, const int n,
		const int precision = MAX_LONG_DIGITS) {
	if (n > precision) return 0;
	if (n > 0) {
		// may need to clip before shifting
		int m = numDigits(num);
		int diff = precision - m - n;
		if (diff < 0 ) {
			num %= cast(ulong)TENS[m + diff];
		}
		ulong scale = cast(ulong)TENS[n];
		num *= scale;
	}
	if (n < 0) {
		num = shiftRight(num, -n, precision);
	}
	return num;
}

/// Shifts the number left by the specified number of decimal digits.
/// If n <= 0 the number is returned unchanged.
/// If n < 0 the number is shifted to the right.
public uint shiftLeft(uint num, const int n, int precision = MAX_INT_DIGITS) {
	if (n > precision) return 0;
	if (n > 0) {
		// may need to clip before shifting
		int m = numDigits(num);
		int diff = precision - m - n;
		if (diff < 0 ) {
			num %= cast(uint)TENS[m + diff];
		}
		uint scale = cast(uint)TENS[n];
		num *= scale;
	}
	if (n < 0) {
		num = shiftRight(num, -n, precision);
	}
	return num;
}

/// Shifts the number right the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted left.
public BigInt shiftRight(BigInt num, const int n,
		const int precision = BigDecimal.context.precision) {
	if (n > 0) {
		BigInt fives = n < 27 ? BigInt(FIVES[n]) : BIG_FIVE^^n;
		num = num >> n;
		num /= fives;
	}
	if (n < 0) {
		num = shiftLeft(num, -n, precision);
	}
	return num;
}

/// Shifts the number right the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted left.
public ulong shiftRight(ulong num, int n,
		const int precision = MAX_LONG_DIGITS) {
	if (n > 0) {
		num /= TENS[n];
	}
	if (n < 0) {
		num = shiftLeft(num, -n, precision);
	}
	return num;
}
/// Shifts the number right (truncates) the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted left.
public uint shiftRight(uint num, int n,
		const int precision = MAX_INT_DIGITS) {
	if (n >precision) return 0;
	if (n > 0) {
		num /= TENS[n];
	}
	if (n < 0) {
		num = shiftLeft(num, -n, precision);
	}
	return num;
}

/// Rotates the number to the left by the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is rotated to the right.
public ulong rotateLeft(ulong num, const int n, const int precision) {
	if (n > precision) return 0;
	if (n > 0) {
		int m = precision - n;
		ulong rem = num / TENS[m];
		num %= TENS[m];
		num *= TENS[n];
		num += rem;
	}
	if (n < 0) {
		num = rotateRight(num, precision, -n);
	}
	return num;
}

unittest {
	writeln("rotateLeft...");
	ulong num = 1234567;
writeln("num = ", num);
	ulong rot = rotateLeft(num, 7, 2);
writeln("rot = ", rot);
	writeln("test missing");
}

/// Rotates the number to the right by the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is rotated to the left.
public ulong rotateRight(ulong num, const int n, const int precision) {
	if (n > precision) return 0;
	if (n == precision) return num;
	if (n > 0) {
		int m = precision - n;
		ulong rem = num / TENS[n];
		num %= TENS[n];
		num *= TENS[m];
		num += rem;
	}
	if (n < 0) {
		num = rotateLeft(num, precision, -n);
	}
	return num;
}

unittest {
	writeln("rotateRight...");
	ulong num = 1234567;
writeln("num = ", num);
	ulong rot = rotateRight(num, 7, 2);
writeln("rot = ", rot);
	 rot = rotateRight(num, 9, 2);
writeln("rot = ", rot);
	 rot = rotateRight(num, 7, -2);
writeln("rot = ", rot);
	 rot = rotateRight(num, 7, 7);
writeln("rot = ", rot);
	writeln("test missing");
}


/// Returns the last digit of the argument.
public uint lastDigit(const BigInt arg) {
	BigInt big = mutable(arg);
	BigInt digit = big % BigInt(10);
	if (digit < 0) digit = -digit;
	return cast(uint)digit.toInt;
}

/// Returns the last digit of the argument.
public uint lastDigit(const long num) {
	ulong n = std.math.abs(num);
	return cast(uint)(n % 10UL);
}

/// Returns the number of trailing zeros in the argument.
public int trailingZeros(const BigInt arg, const int maxValue) {
	BigInt n = mutable(arg);
	// shortcuts for frequent values
	if (n == 0) return 0;
	if (n % 10) return 0;
	if (n % 100) return 1;
	// find by binary search
	int min = 3;
	int max = maxValue - 1;
	while (min <= max) {
		int mid = (min + max)/2;
		if (n % tens(mid) != 0) {
			max = mid - 1;
		}
		else {
			min = mid + 1;
		}
	}
	return max;
}

/// Returns the number of trailing zeros in the argument.
public int trailingZeros(const ulong n, const int maxValue = 19) {
	// shortcuts for frequent values
	if (n == 0) return 0;
	if (n % 10) return 0;
	if (n % 100) return 1;
	// find by binary search
	int min = 3;
	int max = maxValue - 1;
	while (min <= max) {
		int mid = (min + max)/2;
		if (n % TENS[mid]) {
			max = mid - 1;
		}
		else {
			min = mid + 1;
		}
	}
	return max;
}

/// Trims trailing zeros from the argument and returns the number of zeros trimmed.
public int trimZeros(ref ulong n, const int maxValue = 19) {
	int zeros = trailingZeros(n);
	if (zeros == 0) return 0;
	n /= TENS[zeros];
	return zeros;
}

/// Trims trailing zeros from the argument and returns the number of zeros trimmed.
public int trimZeros(ref BigInt n, const int maxValue ) {
	int zeros = trailingZeros(cast(const)n, maxValue);
	if (zeros == 0) return 0;
	n /= tens(zeros);
	return zeros;
}

/// Returns a BigInt value of ten raised to the specified power.
public BigInt tens(const int n) {
	if (n <= 19) return BigInt(TENS[n]);
	BigInt num = 1;
	return shiftLeft(num, n);
}

//-----------------------------
// helper functions
//-----------------------------

/// Returns true if argument is odd.
public bool isOdd(const ulong n) {
	return n & 1;
}

/// Returns a mutable copy of a BigInt
public BigInt mutable(const BigInt num) {
	BigInt big = cast(BigInt)num;
	return big;
}

/// Returns the absolute value of a BigInt
public BigInt abs(const BigInt num) {
	BigInt big = mutable(num);
	return big < BIG_ZERO ? -big : big;
}

/// Returns -1, 0, or 1
/// if the argument is negative, zero, or positive, respectively.
public int sgn(const BigInt num) {
	BigInt big = mutable(num);
	if (big < BIG_ZERO) return -1;
	if (big > BIG_ZERO) return 1;
	return 0;
}

//--------------------------------
// unit tests
//--------------------------------

import decimal.dec32;
import decimal.dec64;

unittest {
	writeln("===================");
	writeln("rounding......begin");
	writeln("===================");
}

unittest {
	// round
	BigDecimal before = BigDecimal(9999);
	BigDecimal after = before;
	DecimalContext ctx3 = DecimalContext(3, 99, Rounding.HALF_EVEN);
	round(after, ctx3);
	assertEqual("1.00E+4", after.toString);
	before = BigDecimal(1234567890);
	after = before;
	round(after, ctx3);
	assertEqual(after.toString(), "1.23E+9");
	after = before;
	DecimalContext ctx4 = DecimalContext(4, 99, Rounding.HALF_EVEN);
	round(after, ctx4);;
	assertEqual(after.toString(), "1.235E+9");
	after = before;
	DecimalContext ctx5 = DecimalContext(5, 99, Rounding.HALF_EVEN);
	round(after, ctx5);;
	assertEqual(after.toString(), "1.2346E+9");
	after = before;
	DecimalContext ctx6 = DecimalContext(6, 99, Rounding.HALF_EVEN);
	round(after, ctx6);;
	assertEqual(after.toString(), "1.23457E+9");
	after = before;
	DecimalContext ctx7 = DecimalContext(7, 99, Rounding.HALF_EVEN);
	round(after, ctx7);;
	assertEqual(after.toString(), "1.234568E+9");
	after = before;
	DecimalContext ctx8 = DecimalContext(8, 99, Rounding.HALF_EVEN);
	round(after, ctx8);;
	assertEqual(after.toString(), "1.2345679E+9");
	before = 1235;
	after = before;
	round(after, ctx3);;
	assertEqual("[0,124,1]", after.toAbstract());
	before = 12359;
	after = before;
	round(after, ctx3);;
	assertEqual("[0,124,2]", after.toAbstract());
	before = 1245;
	after = before;
	round(after, ctx3);
	assertEqual("[0,124,1]", after.toAbstract());
	before = 12459;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,125,2]");
	Dec32 a = Dec32(0.1);
writeln("********** a = ", a);
	Dec32 b = Dec32.min * Dec32(8888888);
writeln("********** b = ", b);
	assertEqual("[0,8888888,-101]", b.toAbstract);
	Dec32 c = a * b;
writeln("********* c = ", c);
	assertEqual("[0,888889,-101]",c.toAbstract);
	Dec32 d = a * c;
	assertEqual("[0,88889,-101]", d.toAbstract);
	Dec32 e = a * d;
	assertEqual("[0,8889,-101]", e.toAbstract);
	Dec32 f = a * e;
	assertEqual("[0,889,-101]", f.toAbstract);
	Dec32 g = a * f;
	assertEqual("[0,89,-101]", g.toAbstract);
	Dec32 h = a * g;
	assertEqual("[0,9,-101]", h.toAbstract);
	Dec32 i = a * h;
	assertEqual("[0,0,-101]", i.toAbstract);
}

unittest {
	// roundByMode
	DecimalContext ctxHE = DecimalContext(5, 99, Rounding.HALF_EVEN);
	BigDecimal num;
	num = 1000;
	roundByMode(num, ctxHE);
	assertTrue(num.coefficient == 1000 && num.exponent == 0 && num.digits == 4);
	num = 1000000;
	roundByMode(num, ctxHE);
	assertTrue(num.coefficient == 10000 && num.exponent == 2 && num.digits == 5);
	num = 99999;
	roundByMode(num, ctxHE);
	assertTrue(num.coefficient == 99999 && num.exponent == 0 && num.digits == 5);
	num = 1234550;
	roundByMode(num, ctxHE);
	assertTrue(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
	DecimalContext ctxDN = ctxHE.setRounding(Rounding.DOWN);
	num = 1234550;
	roundByMode(num, ctxDN);
	assertTrue(num.coefficient == 12345 && num.exponent == 2 && num.digits == 5);
	DecimalContext ctxUP = ctxHE.setRounding(Rounding.UP);
	num = 1234550;
	roundByMode(num, ctxUP);
	assertTrue(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
}

unittest {	// testFive
	assertEqual( 0, testFive(5000));
	assertEqual(-1, testFive(4999));
	assertEqual( 1, testFive(5001));
	assertEqual( 0, testFive(BigInt("5000000000000000000000")));
	assertEqual(-1, testFive(BigInt("4999999999999999999999")));
	assertEqual( 1, testFive(BigInt("5000000000000000000001")));
}

unittest {
	// getRemainder
	DecimalContext ctx5 = testContext.setPrecision(5);
	BigDecimal num, acrem, exnum, exrem;
	num = BigDecimal(1234567890123456L);
	acrem = getRemainder(num, ctx5);
	exnum = BigDecimal("1.2345E+15");
	assertTrue(num == exnum);
	exrem = 67890123456;
	assertTrue(acrem == exrem);
}

unittest {
	// increment(BigDecimal)
	BigDecimal num, expect;
	num = 10;
	expect = 11;
	incrementAndRound(num);
	assertTrue(num == expect);
	num = 19;
	expect = 20;
	incrementAndRound(num);
	assertTrue(num == expect);
	num = 999;
	expect = 1000;
	incrementAndRound(num);
	assertTrue(num == expect);
}

unittest {
	// numDigits(ulong)
	ulong num, expect;
	uint digits;
	num = 10;
	expect = 11;
	digits = numDigits(num);
	increment(num, digits);
	assertTrue(num == expect);
	assertTrue(digits == 2);
	num = 19;
	expect = 20;
	digits = numDigits(num);
	increment(num, digits);
	assertTrue(num == expect);
	assertTrue(digits == 2);
	num = 999;
	expect = 1000;
	digits = numDigits(num);
	increment(num, digits);
	assertTrue(num == expect);
	assertTrue(digits == 4);
}

unittest {
	// setExponent
	DecimalContext ctx = testContext.setPrecision(5);
	ulong num;
	uint digits;
	int expo;
	num = 1000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assertTrue(num == 1000 && expo == 0 && digits == 4);
	num = 1000000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assertTrue(num == 10000 && expo == 2 && digits == 5);
	num = 99999;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assertTrue(num == 99999 && expo == 0 && digits == 5);
}

unittest {
	// numDigits(BigInt)
	BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertEqual(101, numDigits(big));
}

unittest {
	// firstDigit(BigInt)
	BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertEqual(8, firstDigit(big));
}

unittest {
	// shiftLeft(BigInt)
	BigInt m;
	int n;
	m = 12345;
	n = 2;
	assertTrue(shiftLeft(m, n, 100) == 1234500);
	m = 1234567890;
	n = 7;
	assertTrue(shiftLeft(m, n, 100) == BigInt(12345678900000000));
	m = 12;
	n = 2;
	assertTrue(shiftLeft(m, n, 100) == 1200);
	m = 12;
	n = 4;
	assertTrue(shiftLeft(m, n, 100) == 120000);
	uint k;
	k = 12345;
	n = 2;
	assertEqual!uint(1234500, cast(uint)shiftLeft(k, n, 9));
	k = 1234567890;
	n = 7;
	assertEqual!uint(900000000, cast(uint)shiftLeft(k, n, 9));
	k = 12;
	n = 2;
	assertEqual!uint(1200, cast(uint)shiftLeft(k, n, 9));
	k = 12;
	n = 4;
	assertEqual!uint(120000, cast(uint)shiftLeft(k, n, 9));
}

unittest {
	// lastDigit(ulong)
	long n;
	n = 7;
	assertTrue(lastDigit(n) == 7);
	n = -13;
	assertTrue(lastDigit(n) == 3);
	n = 999;
	assertTrue(lastDigit(n) == 9);
	n = -9999;
	assertTrue(lastDigit(n) == 9);
	n = 25987;
	assertTrue(lastDigit(n) == 7);
	n = -5008615;
	assertTrue(lastDigit(n) == 5);
	n = 3234567893;
	assertTrue(lastDigit(n) == 3);
	n = -10000000000;
	assertTrue(lastDigit(n) == 0);
	n = 823456789012348;
	assertTrue(lastDigit(n) == 8);
	n = 4234567890123456;
	assertTrue(lastDigit(n) == 6);
	n = 623456789012345674;
	assertTrue(lastDigit(n) == 4);
	n = long.max;
	assertTrue(lastDigit(n) == 7);
}

unittest {
	// lastDigit(BigInt)
	BigInt n;
	n = 7;
	assertTrue(lastDigit(n) == 7);
	n = -13;
	assertTrue(lastDigit(n) == 3);
	n = 999;
	assertTrue(lastDigit(n) == 9);
	n = -9999;
	assertTrue(lastDigit(n) == 9);
	n = 25987;
	assertTrue(lastDigit(n) == 7);
	n = -5008615;
	assertTrue(lastDigit(n) == 5);
	n = 3234567893;
	assertTrue(lastDigit(n) == 3);
	n = -10000000000;
	assertTrue(lastDigit(n) == 0);
	n = 823456789012348;
	assertTrue(lastDigit(n) == 8);
	n = 4234567890123456;
	assertTrue(lastDigit(n) == 6);
	n = 623456789012345674;
	assertTrue(lastDigit(n) == 4);
	n = long.max;
	assertTrue(lastDigit(n) == 7);
}

unittest {
	// shiftLeft
	long m;
	int n;
	m = 12345;
	n = 2;
	assertTrue(shiftLeft(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assertTrue(shiftLeft(m,n) == 12345678900000000);
	m = 12;
	n = 2;
	assertTrue(shiftLeft(m,n) == 1200);
	m = 12;
	n = 4;
	assertTrue(shiftLeft(m,n) == 120000);
}

unittest {
	// firstDigit
	long n;
	n = 7;
	int expected, actual;
	expected = 7;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 13;
	expected = 1;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 999;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 9999;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 25987;
	expected = 2;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 5008617;
	expected = 5;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 3234567890;
	expected = 3;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 10000000000;
	expected = 1;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 823456789012345;
	expected = 8;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 4234567890123456;
	expected = 4;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 623456789012345678;
	expected = 6;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = long.max;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
}

unittest {
	// numDigits
	long n;
	n = 7;
	int expect = 1;
	int actual = numDigits(n);
	assertEqual(expect, actual);
	n = 13;
	expect = 2;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 999;
	expect = 3;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 9999;
	expect = 4;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 25987;
	expect = 5;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 2008617;
	expect = 7;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 1234567890;
	expect = 10;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 10000000000;
	expect = 11;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 123456789012345;
	expect = 15;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 1234567890123456;
	expect = 16;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = 123456789012345678;
	expect = 18;
	actual = numDigits(n);
	assertEqual(expect, actual);
	n = long.max;
	expect = 19;
	actual = numDigits(n);
	assertEqual(expect, actual);
}

unittest {
	// clipRemainder
	ulong num, acrem, exnum, exrem;
	uint digits, precision;
	num = 1234567890123456L;
	digits = 16;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 67890123456L;
	assertTrue(acrem == exrem);

	num = 12345768901234567L;
	digits = 17;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 768901234567L;
	assertTrue(acrem == exrem);

	num = 123456789012345678L;
	digits = 18;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 6789012345678L;
	assertTrue(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 67890123456789L;
	assertTrue(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19;
	precision = 4;
	acrem = clipRemainder(num, digits, precision);
	exnum = 1234L;
	assertTrue(num == exnum);
	exrem = 567890123456789L;
	assertTrue(acrem == exrem);

	num = 9223372036854775807L;
	digits = 19;
	precision = 1;
	acrem = clipRemainder(num, digits, precision);
	exnum = 9L;
	assertTrue(num == exnum);
	exrem = 223372036854775807L;
	assertTrue(acrem == exrem);

}

unittest {
	writeln("===================");
	writeln("rounding........end");
	writeln("===================");
}


