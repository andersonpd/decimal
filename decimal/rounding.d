// Written in the D programming language

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

module decimal.rounding;

import decimal.arithmetic: compare, copyNegate, equals;
import decimal.context;
import decimal.conv;
import decimal.dec32;
import decimal.dec64;
import decimal.decimal;
import std.array: insertInPlace;
import std.ascii: isDigit;
import std.bigint;

unittest {
	writeln("-------------------");
	writeln("rounding......begin");
	writeln("-------------------");
}

// NOTE: it would be nice to make these const, but the BigInt class
// complains about casting. They are private so I know they won't change,
// but it's inconvenient
private BigInt BILLION = BigInt(1_000_000_000);
private BigInt QUINTILLION = BigInt(1_000_000_000_000_000_000);

//-----------------------------
// helper functions
//-----------------------------

public BigInt abs(const BigInt num) {
	BigInt big = copy(num);
	return big < BigInt(0) ? -big : big;
}

public BigInt copy(const BigInt num) {
	BigInt big = cast(BigInt)num;
	return big;
}

public int sgn(const BigInt num) {
	BigInt zero = BigInt(0);
	BigInt big = copy(num);
	if (big < zero) return -1;
	if (big < zero) return 1;
	return 0;
}

public void round(T)(ref T num, ref DecimalContext context) if (isDecimal!T) {

	// no rounding of special values
	if (!num.isFinite) return;

	// no rounding of zeros
	if (num.isZero) {
		if (num.exponent < context.eMin) {
			context.setFlags(SUBNORMAL);
			if (num.exponent < context.eTiny) {
				num.exponent = context.eTiny;
			}
		}
		return;
	}

	// check for subnormal
	if (num.isSubnormal(context)) {
		context.setFlags(SUBNORMAL);
		int diff = context.eMin - num.adjustedExponent;
		// decrease the precision and round
		int precision = context.precision - diff;
		if (num.digits > precision) {
			DecimalContext tempContext = context.setPrecision(precision);
			roundByMode(num, tempContext);
		}
		// subnormal rounding to zero == clamped (Spec. p. 51)
		if (num.isZero) {
			num.exponent = context.eTiny;
			context.setFlags(CLAMPED);
		}
		return;
	}

	// check for overflow
	if (num.adjustedExponent > context.eMax) {
		context.setFlags(OVERFLOW);
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
		context.setFlags(INEXACT);
		context.setFlags(ROUNDED);
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

// UNREADY: roundByMode. Description. Order.
private void roundByMode(T)(ref T num, ref DecimalContext context)
		if (isDecimal!T) {

	uint digits = num.digits;
	T remainder = getRemainder(num, context);


	// if the number wasn't rounded...
	if (num.digits == digits) {
		return;
	}
	// if the remainder is zero...
	if (remainder.isZero) {
		return;
	}
	switch (context.rounding) {
		case Rounding.DOWN:
			return;
		case Rounding.HALF_UP:
			if (firstDigit(remainder.coefficient) >= 5) {
				increment(num, context);
			}
			return;
		case Rounding.HALF_EVEN:
			ulong first = firstDigit(remainder.coefficient);
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
		case Rounding.HALF_DOWN:
			if (firstDigit(remainder.coefficient) > 5) {
				increment(num, context);
			}
			return;
		case Rounding.UP:
			auto temp = T.zero;
			if (remainder != temp) {
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
private T getRemainder(T)(ref T num, ref DecimalContext context)
		if (isDecimal!T){
	T remainder = T.zero;

	int diff = num.digits - context.precision;
	if (diff <= 0) {
		return remainder;
	}
	context.setFlags(ROUNDED);
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
		context.setFlags(INEXACT);
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
	ulong num; uint digits; int expo;
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
	//context.setFlags(ROUNDED);

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
	digits = 16; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 67890123456L;
	assertTrue(acrem == exrem);

	num = 12345768901234567L;
	digits = 17; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 768901234567L;
	assertTrue(acrem == exrem);

	num = 123456789012345678L;
	digits = 18; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 6789012345678L;
	assertTrue(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assertTrue(num == exnum);
	exrem = 67890123456789L;
	assertTrue(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19; precision = 4;
	acrem = clipRemainder(num, digits, precision);
	exnum = 1234L;
	assertTrue(num == exnum);
	exrem = 567890123456789L;
	assertTrue(acrem == exrem);

	num = 9223372036854775807L;
	digits = 19; precision = 1;
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
public int numDigits(const BigInt big) {
	BigInt dig = cast(BigInt)big;
	int count = 0;
	while (dig > QUINTILLION) {
		dig /= QUINTILLION;
		count += 18;
	}
	long n = dig.toLong;
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
	if (n <= 0) { return num; }
	BigInt fives = 1;
	for (int i = 0; i < n; i++) {
		fives *= 5;
	}
	num = num << n;
	num *= fives;
	return num;
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public ulong decShl(ulong num, const int n) {
	if (n <= 0) { return num; }
	ulong scale = 10UL^^n;
	num = num * scale;
	return num;
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public uint decShl(uint num, const int n) {
	if (n <= 0) { return num; }
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

public int firstDigit(const long num) {
	ulong n = std.math.abs(num);
	for(int i = 0; i < 6; i++) {
		while (n >= ultens[i]) {
			n /= ultens[i];
		}
	}
	return cast(int)n;
}

unittest {
	long n;
	n = 7;
	assertTrue(firstDigit(n) == 7);
	n = -13;
	assertTrue(firstDigit(n) == 1);
	n = 999;
	assertTrue(firstDigit(n) == 9);
	n = -9999;
	assertTrue(firstDigit(n) == 9);
	n = 25987;
	assertTrue(firstDigit(n) == 2);
	n = -5008617;
	assertTrue(firstDigit(n) == 5);
	n = 3234567890;
	assertTrue(firstDigit(n) == 3);
	n = -10000000000;
	assertTrue(firstDigit(n) == 1);
	n = 823456789012345;
	assertTrue(firstDigit(n) == 8);
	n = 4234567890123456;
	assertTrue(firstDigit(n) == 4);
	n = 623456789012345678;
	assertTrue(firstDigit(n) == 6);
	n = long.max;
	assertTrue(firstDigit(n) == 9);
}

private ulong p10(const uint n) {
	return 10UL^^n;
}

private immutable ulong[6] ulpwrs = [18, 16, 8, 4, 2, 1];
private immutable ulong[6] ultens = [p10(18), p10(16), p10(8), p10(4), p10(2), p10(1)];

public int numDigits(const long num) {

	ulong n = std.math.abs(num);
	int count = 1;
	for(int i = 0; i < 6; i++) {
		while (n >= ultens[i]) {
			n /= ultens[i];
			count += ulpwrs[i];
		}
	}
	return count;
}

unittest {
	long n;
	n = 7;
	assertTrue(numDigits(n) ==	1);
	n = -13;
	assertTrue(numDigits(n) ==	2);
	n = 999;
	assertTrue(numDigits(n) ==	3);
	n = -9999;
	assertTrue(numDigits(n) ==	4);
	n = 25987;
	assertTrue(numDigits(n) ==	5);
	n = -2008617;
	assertTrue(numDigits(n) ==	7);
	n = 1234567890;
	assertTrue(numDigits(n) == 10);
	n = -10000000000;
	assertTrue(numDigits(n) == 11);
	n = 123456789012345;
	assertTrue(numDigits(n) == 15);
	n = 1234567890123456;
	assertTrue(numDigits(n) == 16);
	n = 123456789012345678;
	assertTrue(numDigits(n) == 18);
	n = long.max;
	assertTrue(numDigits(n) == 19);
}

unittest {
	writeln("-------------------");
	writeln("rounding........end");
	writeln("-------------------");
}


