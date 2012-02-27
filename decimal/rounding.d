/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */

/* Copyright Paul D. Anderson 2009 - 2012.
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 *  http://www.boost.org/LICENSE_1_0.txt)
 */

module decimal.rounding;

import decimal.arithmetic:compare, copyNegate, equals;
import decimal.context;
import decimal.conv;
import decimal.utils;
import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;

// NOTE: these imports are only needed for testing.
import decimal.dec32;
import decimal.dec64;
// NOTE: this import is only used once outside of testing.
import decimal.decimal;

unittest {
	writeln("===================");
	writeln("rounding......begin");
	writeln("===================");
}

// NOTE: it would be nice to make these const, but the BigInt class
// complains about casting. They are private so I know they won't change,
// but it's inconvenient
private BigInt BIG_ZERO = BigInt(0);
private BigInt BIG_ONE = BigInt(1);
private BigInt BIG_TEN = BigInt(10);
private BigInt BILLION = BigInt(1_000_000_000);
private BigInt QUINTILLION = BigInt(1_000_000_000_000_000_000);

//-----------------------------
// helper functions
//-----------------------------

public BigInt mutable(const BigInt num) {
	BigInt big = cast(BigInt)num;
	return big;
}

public BigInt abs(const BigInt num) {
	BigInt big = mutable(num);
	return big < BIG_ZERO ? -big : big;
}

public int sgn(const BigInt num) {
	BigInt big = mutable(num);
	if (big < BIG_ZERO) return -1;
	if (big > BIG_ZERO) return 1;
	return 0;
}

public void round(T)(ref T num, const DecimalContext context) if (isDecimal!T) {

	// no rounding of special values
	if (!num.isFinite) return;

	// no rounding of zeros
	if (num.isZero) {
		if (num.exponent < context.eMin) {
			contextFlags.setFlags(SUBNORMAL);
			if (num.exponent < context.eTiny) {
				num.exponent = context.eTiny;
			}
		}
		return;
	}

	// check for subnormal
	if (num.isSubnormal(context)) {
		contextFlags.setFlags(SUBNORMAL);
		int diff = context.eMin - num.adjustedExponent;
		// decrease the precision and round
		int precision = context.precision - diff;
		if (num.digits > precision) {
			auto ctx = context.setPrecision(precision);
			roundByMode(num, ctx);
		}
		// subnormal rounding to zero == clamped (Spec. p. 51)
		if (num.isZero) {
			num.exponent = context.eTiny;
			contextFlags.setFlags(CLAMPED);
		}
		return;
	}

	// check for overflow
	if (num.adjustedExponent > context.eMax) {
		contextFlags.setFlags(OVERFLOW);
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
		contextFlags.setFlags(INEXACT);
		contextFlags.setFlags(ROUNDED);
		return;
	}
	roundByMode(num, context);
	// check for zero
static if (is(T : BigDecimal)) {
		if (num.coefficient == 0) {
			num.zero(num.sign);
		}
	}
	return;

} // end round()

unittest {
	BigDecimal before = BigDecimal(9999);
	BigDecimal after = before;
	DecimalContext ctx3 = DecimalContext(3, 99, Rounding.HALF_EVEN);
	round(after, ctx3);
	assertTrue(after.toString() == "1.00E+4");
	before = BigDecimal(1234567890);
	after = before;
	round(after, ctx3);
	assertTrue(after.toString() == "1.23E+9");
	after = before;
	DecimalContext ctx4 = DecimalContext(4, 99, Rounding.HALF_EVEN);
	round(after, ctx4);;
	assertTrue(after.toString() == "1.235E+9");
	after = before;
	DecimalContext ctx5 = DecimalContext(5, 99, Rounding.HALF_EVEN);
	round(after, ctx5);;
	assertTrue(after.toString() == "1.2346E+9");
	after = before;
	DecimalContext ctx6 = DecimalContext(6, 99, Rounding.HALF_EVEN);
	round(after, ctx6);;
	assertTrue(after.toString() == "1.23457E+9");
	after = before;
	DecimalContext ctx7 = DecimalContext(7, 99, Rounding.HALF_EVEN);
	round(after, ctx7);;
	assertTrue(after.toString() == "1.234568E+9");
	after = before;
	DecimalContext ctx8 = DecimalContext(8, 99, Rounding.HALF_EVEN);
	round(after, ctx8);;
	assertTrue(after.toString() == "1.2345679E+9");
	before = 1235;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,124,1]");
	before = 12359;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,124,2]");
	before = 1245;
	after = before;
	round(after, ctx3);
	assertTrue(after.toAbstract() == "[0,125,1]");
	before = 12459;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,125,2]");
	Dec32 a = Dec32(0.1);
	Dec32 b = Dec32.min * Dec32(8888888);
	assertTrue(b.toAbstract == "[0,8888888,-101]");
	Dec32 c = a * b;
	assertTrue(c.toAbstract == "[0,888889,-101]");
	Dec32 d = a * c;
	assertTrue(d.toAbstract == "[0,88889,-101]");
	Dec32 e = a * d;
	assertTrue(e.toAbstract == "[0,8889,-101]");
	Dec32 f = a * e;
	assertTrue(f.toAbstract == "[0,889,-101]");
	Dec32 g = a * f;
	assertTrue(g.toAbstract == "[0,89,-101]");
	Dec32 h = a * g;
	assertTrue(h.toAbstract == "[0,9,-101]");
	Dec32 i = a * h;
	assertTrue(i.toAbstract == "[0,0,-101]");
}

//--------------------------------
// private rounding routines
//--------------------------------

/// Rounds the subject number by the specified context mode
private void roundByMode(T)(ref T num, const DecimalContext context)
		if (isDecimal!T) {

	// calculate remainder
	T remainder = getRemainder(num, context);
	// if the number wasn't rounded, return
	if (remainder.isZero) {
		return;
	}
	//
	// TODO: the first digit function now has a maxValue parameter for
	// Dec32 & Dec64
	switch (context.rounding) {
	case Rounding.UP:
		auto temp = T.zero;
		if (remainder != temp) {
			increment(num, context);
		}
		return;
	case Rounding.DOWN:
		return;
	case Rounding.CEILING:
		auto temp = T.zero;
		if (!num.sign && (remainder != temp)) {
			increment(num, context);
		}
		return;
	case Rounding.FLOOR:
		auto temp = T.zero;
		if (num.sign && remainder != temp) {
			increment(num, context);
		}
		return;
	case Rounding.HALF_UP:
		if (firstDigit(remainder.coefficient) >= 5) {
			increment(num, context);
		}
		return;
	case Rounding.HALF_DOWN:
		if (firstDigit(remainder.coefficient) > 5) {
			increment(num, context);
		}
		return;
	case Rounding.HALF_EVEN:
		int first = firstDigit(remainder.coefficient);
		if (first > 5) {
			increment(num, context);
			break;
		}
		if (first < 5) {
			break;
		}
		// remainder == 5
		// if last digit is odd...
		if (first & 1) {
			increment(num, context);
		}
		return;
	default:
		return;
	}	 // end switch(mode)
} // end roundByMode()

unittest {
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

/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private T getRemainder(T)(ref T num, const DecimalContext context)
if (isDecimal!T) {
	T remainder = T.zero;

	int diff = num.digits - context.precision;
	if (diff <= 0) {
		return remainder;
	}
	contextFlags.setFlags(ROUNDED);
	// the context can be zero when...??
	if (context.precision == 0) {
		num = T.zero(num.sign);
	} else {
		auto divisor = T.pow10(diff);
		auto dividend = num.coefficient;
		auto quotient = dividend/divisor;
		auto modulo = dividend - quotient*divisor;
		if (modulo != 0) {
			remainder.zero;
			remainder.digits = diff;
			remainder.exponent = num.exponent;
			remainder.coefficient = modulo;
		}
		num.coefficient = quotient;
		num.digits = context.precision;
		num.exponent = num.exponent + diff;
	}
	auto temp = T.zero;
	if (remainder != temp) {
		contextFlags.setFlags(INEXACT);
	}

	return remainder;
}

unittest {
	DecimalContext ctx5 = testContext.setPrecision(5);
	BigDecimal num, acrem, exnum, exrem;
	num = BigDecimal(1234567890123456L);
	acrem = getRemainder(num, ctx5);
	exnum = BigDecimal("1.2345E+15");
	assertTrue(num == exnum);
	exrem = 67890123456;
	assertTrue(acrem == exrem);
}

/**
 * Increments the coefficient by 1. If this causes an overflow, divides by 10.
 */
private void increment(T:BigDecimal)(ref T num, const DecimalContext context) {
	num.coefficient = num.coefficient + 1;
	// check if the num was all nines --
	// did the coefficient roll over to 1000...?
	BigDecimal test1 = BigDecimal(1, num.digits + num.exponent);
	BigDecimal test2 = num;
	test2.digits++;
	int comp = decimal.arithmetic.compare(test1, test2, context, false);
	if (comp == 0) {
		num.digits++;
		// check if there are now too many digits...
		if (num.digits > context.precision) {
			round(num, context);
		}
	}
}

unittest {
	BigDecimal num, expect;
	num = 10;
	expect = 11;
	increment(num, testContext);
	assertTrue(num == expect);
	num = 19;
	expect = 20;
	increment(num, testContext);
	assertTrue(num == expect);
	num = 999;
	expect = 1000;
	increment(num, testContext);
	assertTrue(num == expect);
}

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
		if (firstDigit(remainder) >= 5) {
			increment(mant, digits);
		}
		break;
	case Rounding.HALF_EVEN:
		ulong first = firstDigit(remainder);
		if (first > 5) {
			increment(mant, digits);
			break;
		}
		if (first < 5) {
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
		if (firstDigit(remainder) > 5) {
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
//writeln("mant5 = ", mant);
		mant /= 10;
//writeln("mant6 = ", mant);
		expo++;
		digits--;
	}
	return expo;

} // end setExponent()

unittest {
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

/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private ulong clipRemainder(ref ulong num, ref uint digits, uint precision) {
	ulong remainder = 0;
	int diff = digits - precision;
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

unittest {
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

/**
 * Increments the number by 1.
 * Re-calculates the number of digits -- the increment may have caused
 * an increase in the number of digits, i.e., input number was all 9s.
 */
private void increment(T)(ref T num, const DecimalContext context) if (isFixedDecimal!T) {
	num.coefficient = num.coefficient + 1;
	num.digits = numDigits(num.coefficient);
}

/**
 * Increments the number by 1.
 * Re-calculates the number of digits -- the increment may have caused
 * an increase in the number of digits, i.e., input number was all 9s.
 */
private void increment(T:ulong)(ref T num, ref uint digits) { //const DecimalContext context) if (isFixedDecimal!T) {
//private void incrementLong(ref ulong num, ref uint digits) {
	num++;
	digits = numDigits(num);
}

unittest {
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

// BigInt versions

/**
 * Returns the number of digits in the number.
 */
public int numDigits(const BigInt arg) {

	if (arg == 0) return 0;

	BigInt big = mutable(arg);

	if (big < BIG_TEN) return 1;

	int count = 0;
	while (big > QUINTILLION) {
		big /= QUINTILLION;
		count += 18;
	}
	long n = big.toLong;
	return count + numDigits(n);
}

unittest {
	BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertTrue(numDigits(big) == 101);
}

/**
 * Returns the first digit of the number.
 */
public int firstDigit(const BigInt big) {
	BigInt dig = cast()big;
	while (dig > QUINTILLION) {
		dig /= QUINTILLION;
	}
	if (dig > BILLION) {
		dig /= BILLION;
	}
	long n = dig.toLong();
	return firstDigit(n);
}

unittest {
	BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertTrue(firstDigit(big) == 8);
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public BigInt decShl(BigInt num, const int n) {
	if (n <= 0) {
		return num;
	}
	BigInt fives = BigInt(5)^^n;
	num = num << n;
	num *= fives;
	return num;
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public ulong decShl(ulong num, const int n) {
	if (n <= 0) {
		return num;
	}
	ulong scale = 10UL^^n;
	num = num * scale;
	return num;
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public uint decShl(uint num, const int n) {
	if (n <= 0) {
		return num;
	}
	uint scale = 10U^^n;
	num = num * scale;
	return num;
}

unittest {
	BigInt m;
	int n;
	m = 12345;
	n = 2;
	assertTrue(decShl(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assertTrue(decShl(m,n) == BigInt(12345678900000000));
	m = 12;
	n = 2;
	assertTrue(decShl(m,n) == 1200);
	m = 12;
	n = 4;
	assertTrue(decShl(m,n) == 120000);
}

/**
 * Returns the last digit of the number.
 */
public uint lastDigit(const long num) {
	ulong n = std.math.abs(num);
	return cast(uint)(n % 10UL);
}

/**
 * Returns the last digit of the number.
 */
public uint lastDigit(/*const*/ BigInt big) {
	BigInt digit = big % BigInt(10);
	if (digit < 0) digit = -digit;
	return cast(uint)digit.toInt;
}

unittest {
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
	long m;
	int n;
	m = 12345;
	n = 2;
	assertTrue(decShl(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assertTrue(decShl(m,n) == 12345678900000000);
	m = 12;
	n = 2;
	assertTrue(decShl(m,n) == 1200);
	m = 12;
	n = 4;
	assertTrue(decShl(m,n) == 120000);
}

public bool isOdd(const ulong n) {
	return n & 1;
}

///
/// Returns the number of trailing zeros in binary.
/// Algorithm adapted from Bit Twiddling Hacks  by Sean Eron Anderson
/// (graphics.standford.edu/~seander/bithacks.html)
///
public int trailingZerosBinary(const uint arg) {

	if (arg & 1) return 0;
	int n = arg;
	int count = 1;
	if ((n & 0xFFFF) == 0) {
		n >>= 16;
		count += 16;
	}
	if ((n & 0xFF) == 0) {
		n >>= 8;
		count += 8;
	}
	if ((n & 0xF) == 0) {
		n >>= 4;
		count += 4;
	}
	if ((n & 0x3) == 0) {
		n >>= 2;
		count += 2;
	}
	count -= n & 1;
	return count;
}

public static ulong[19] TENS = [10L^^0,
		10L^^1,  10^^2,   10L^^3,  10L^^4,  10L^^5,  10L^^6,
		10L^^7,  10L^^8,  10L^^9,  10L^^10, 10L^^11, 10L^^12,
		10L^^13, 10L^^14, 10L^^15, 10L^^16, 10L^^17, 10L^^18];

public int numDigits(const ulong n, const int maxValue = 19) {

	// special cases:
	if (n == 0) return 0;
	if (n < 10) return 1;

	if (n >= TENS[maxValue - 1]) return maxValue;

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

unittest {
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

public int firstDigit(const ulong n, int maxValue = 19) {
	if (n == 0) return 0;
	if (n < 10) return cast(int) n;
	int d = numDigits(n, maxValue);
	return cast(int)(n/TENS[d-1]);
}

unittest {
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

public int trailingZeros(const ulong n, const int maxValue = 19) {

	// special cases:
	if (n == 0) return 0;
	if (n % 10) return 0;
	if (n % 100) return 1;

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


unittest {
	writeln("===================");
	writeln("rounding........end");
	writeln("===================");
}


