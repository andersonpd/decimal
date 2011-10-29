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

private static DecimalContext testContextR = DecimalContext().dup;

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

//TODO: add ref context flags to parameters.
// UNREADY: round. Description. Private or public?
public void round(T)(ref T num, ref DecimalContext context) if (isDecimal!T) {

	// no rounding of special values
	if (!num.isFinite) return;

	// no rounding of zeros
	if (num.isZero) {
		if (num.exponent < context.eMin) {
			context.setFlag(SUBNORMAL);
			if (num.exponent < context.eTiny) {
				num.exponent = context.eTiny;
//				  context.setFlag(CLAMPED);   // TODO: is this right?
			}
		}
		return;
	}

	// check for subnormal
	if (num.isSubnormal(context)) {
		context.setFlag(SUBNORMAL);
		int diff = context.eMin - num.adjustedExponent;
		// decrease the precision and round
		int precision = context.precision - diff;
		if (num.digits > precision) {
			pushContext(context);
			context.precision = precision;
			roundByMode(num, context);
			context = popContext;
		}
		// subnormal rounding to zero == clamped (Spec. p. 51)
		if (num.isZero) {
			num.exponent = context.eTiny;
			context.setFlag(CLAMPED);
		}
		return;
	}

	// check for overflow
	if (num.adjustedExponent > context.eMax) {
		context.setFlag(OVERFLOW);
		switch (context.rounding) {
			case RoundingMode.HALF_UP:
			case RoundingMode.HALF_EVEN:
			case RoundingMode.HALF_DOWN:
			case RoundingMode.UP:
				num = T.infinity(num.sign);
				break;
			case RoundingMode.DOWN:
				num = T.max(num.sign);
				break;
			case RoundingMode.CEILING:
				num = num.sign ? T.max(true) : T.infinity;
				break;
			case RoundingMode.FLOOR:
				num = num.sign ? T.infinity(true) : T.max;
				break;
			default:
				break;
		}
		context.setFlag(INEXACT);
		context.setFlag(ROUNDED);
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
	DecimalContext contextX;
	contextX.precision = 3;
	round(after, contextX);
	assert(after.toString() == "1.00E+4");
	before = BigDecimal(1234567890);
	after = before;
	contextX.precision = 3;
	round(after, contextX);
	assert(after.toString() == "1.23E+9");
	after = before;
	contextX.precision = 4;
	round(after, contextX);;
	assert(after.toString() == "1.235E+9");
	after = before;
	contextX.precision = 5;
	round(after, contextX);;
	assert(after.toString() == "1.2346E+9");
	after = before;
	contextX.precision = 6;
	round(after, contextX);;
	assert(after.toString() == "1.23457E+9");
	after = before;
	contextX.precision = 7;
	round(after, contextX);;
	assert(after.toString() == "1.234568E+9");
	after = before;
	contextX.precision = 8;
	round(after, contextX);;
	assert(after.toString() == "1.2345679E+9");
	before = 1235;
	after = before;
	contextX.precision = 3;
	round(after, contextX);;
	assert(after.toAbstract() == "[0,124,1]");
	before = 12359;
	after = before;
	contextX.precision = 3;
	round(after, contextX);;
	assert(after.toAbstract() == "[0,124,2]");
	before = 1245;
	after = before;
	contextX.precision = 3;
	round(after, contextX);;
	assert(after.toAbstract() == "[0,125,1]");
	before = 12459;
	after = before;
	contextX.precision = 3;
	round(after, contextX);;
	assert(after.toAbstract() == "[0,125,2]");
	Dec32 a = Dec32(0.1);
	Dec32 b = Dec32.min * Dec32(8888888);
	assert(b.toAbstract == "[0,8888888,-101]");
	Dec32 c = a * b;
	assert(c.toAbstract == "[0,888889,-101]");
	Dec32 d = a * c;
	assert(d.toAbstract == "[0,88889,-101]");
	Dec32 e = a * d;
	assert(e.toAbstract == "[0,8889,-101]");
	Dec32 f = a * e;
	assert(f.toAbstract == "[0,889,-101]");
	Dec32 g = a * f;
	assert(g.toAbstract == "[0,89,-101]");
	Dec32 h = a * g;
	assert(h.toAbstract == "[0,9,-101]");
	Dec32 i = a * h;
	assert(i.toAbstract == "[0,0,-101]");

// TUDO: problem with subtraction.
// sub = sub - Dec32(1);//BigDecimal(1); doesn't wotk with Dec32 either!
//sub = sub - 1;  // doesn't work BigDecimal op int
//sub--;  // doesn't work, don't know why
//Dec32 ans = sub + sub;
//writeln("ans = ", ans.toAbstract);
/*sub = Dec32.min_normal;
//writeln("sub = ", sub.toAbstract);
sub = Dec32.min_normal - Dec32.min;// * 50;
//writeln("sub = ", sub.toAbstract);
Dec32 abc = Dec32.min + Dec32.min;
//writeln("abc = ", abc);*/
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
		case RoundingMode.DOWN:
			return;
		case RoundingMode.HALF_UP:
			if (firstDigit(remainder.coefficient) >= 5) {
				increment(num, context);
			}
			return;
		case RoundingMode.HALF_EVEN:
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
		case RoundingMode.CEILING:
			auto temp = T.zero;
			if (!num.sign && (remainder != temp)) {
				increment(num, context);
			}
			return;
		case RoundingMode.FLOOR:
			auto temp = T.zero;
			if (num.sign && remainder != temp) {
				increment(num, context);
			}
			return;
		case RoundingMode.HALF_DOWN:
			if (firstDigit(remainder.coefficient) > 5) {
				increment(num, context);
			}
			return;
		case RoundingMode.UP:
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
	pushContext(testContextR);
	testContextR.precision = 5;
	testContextR.rounding = RoundingMode.HALF_EVEN;
	BigDecimal num;
	num = 1000;
	roundByMode(num, testContextR);
	assert(num.coefficient == 1000 && num.exponent == 0 && num.digits == 4);
	num = 1000000;
	roundByMode(num, testContextR);
	assert(num.coefficient == 10000 && num.exponent == 2 && num.digits == 5);
	num = 99999;
	roundByMode(num, testContextR);
	assert(num.coefficient == 99999 && num.exponent == 0 && num.digits == 5);
	num = 1234550;
	roundByMode(num, testContextR);
	assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
	testContextR.rounding = RoundingMode.DOWN;
	num = 1234550;
	roundByMode(num, testContextR);
	assert(num.coefficient == 12345 && num.exponent == 2 && num.digits == 5);
	testContextR.rounding = RoundingMode.UP;
	num = 1234550;
	roundByMode(num, testContextR);
	assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
	testContextR = popContext;
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
	context.setFlag(ROUNDED);
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
		context.setFlag(INEXACT);
	}

	return remainder;
}

unittest {
	pushContext(testContextR);
	testContextR.precision = 5;
	BigDecimal num, acrem, exnum, exrem;
	num = BigDecimal(1234567890123456L);
	acrem = getRemainder(num, testContextR);
	exnum = BigDecimal("1.2345E+15");
	assert(num == exnum);
	exrem = 67890123456;
	assert(acrem == exrem);
	testContextR = popContext();
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
	increment(num, testContextR);
	assert(num == expect);
	num = 19;
	expect = 20;
	increment(num, testContextR);
	assert(num == expect);
	num = 999;
	expect = 1000;
	increment(num, testContextR);
	assert(num == expect);
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
		case RoundingMode.DOWN:
			break;
		case RoundingMode.HALF_UP:
			if (firstDigit(remainder) >= 5) {
				increment(mant, digits);
			}
			break;
		case RoundingMode.HALF_EVEN:
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
		case RoundingMode.CEILING:
			if (!sign) {
				increment(mant, digits);
			}
			break;
		case RoundingMode.FLOOR:
			if (sign) {
				increment(mant, digits);
			}
			break;
		case RoundingMode.HALF_DOWN:
			if (firstDigit(remainder) > 5) {
				increment(mant, digits);
			}
			break;
		case RoundingMode.UP:
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
	DecimalContext testContextR;
	testContextR.precision = 5;
	testContextR.rounding = RoundingMode.HALF_EVEN;
	ulong num; uint digits; int expo;
	num = 1000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, testContextR);
	assert(num == 1000 && expo == 0 && digits == 4);
	num = 1000000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, testContextR);
	assert(num == 10000 && expo == 2 && digits == 5);
	num = 99999;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, testContextR);
	assert(num == 99999 && expo == 0 && digits == 5);
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
	//context.setFlag(ROUNDED);

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
	assert(num == exnum);
	exrem = 67890123456L;
	assert(acrem == exrem);

	num = 12345768901234567L;
	digits = 17; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 768901234567L;
	assert(acrem == exrem);

	num = 123456789012345678L;
	digits = 18; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 6789012345678L;
	assert(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19; precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 67890123456789L;
	assert(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19; precision = 4;
	acrem = clipRemainder(num, digits, precision);
	exnum = 1234L;
	assert(num == exnum);
	exrem = 567890123456789L;
	assert(acrem == exrem);

	num = 9223372036854775807L;
	digits = 19; precision = 1;
	acrem = clipRemainder(num, digits, precision);
	exnum = 9L;
	assert(num == exnum);
	exrem = 223372036854775807L;
	assert(acrem == exrem);

}

/**
 * Increments the number by 1.
 * Re-calculates the number of digits -- the increment may have caused
 * an increase in the number of digits, i.e., input number was all 9s.
 */
private void increment(T)(ref T num, const DecimalContext context) if (isSmallDecimal!T) {
	num.coefficient = num.coefficient + 1;
	num.digits = numDigits(num.coefficient);
}

/**
 * Increments the number by 1.
 * Re-calculates the number of digits -- the increment may have caused
 * an increase in the number of digits, i.e., input number was all 9s.
 */
private void increment(T:ulong)(ref T num, ref uint digits) { //const DecimalContext context) if (isSmallDecimal!T) {
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
	assert(num == expect);
	assert(digits == 2);
	num = 19;
	expect = 20;
	digits = numDigits(num);
	increment(num, digits);
	assert(num == expect);
	assert(digits == 2);
	num = 999;
	expect = 1000;
	digits = numDigits(num);
	increment(num, digits);
	assert(num == expect);
	assert(digits == 4);
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
	assert(numDigits(big) == 101);
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
	assert(firstDigit(big) == 8);
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
	assert(decShl(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assert(decShl(m,n) == BigInt(12345678900000000));
	m = 12;
	n = 2;
	assert(decShl(m,n) == 1200);
	m = 12;
	n = 4;
	assert(decShl(m,n) == 120000);
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
	assert(lastDigit(n) == 7);
	n = -13;
	assert(lastDigit(n) == 3);
	n = 999;
	assert(lastDigit(n) == 9);
	n = -9999;
	assert(lastDigit(n) == 9);
	n = 25987;
	assert(lastDigit(n) == 7);
	n = -5008615;
	assert(lastDigit(n) == 5);
	n = 3234567893;
	assert(lastDigit(n) == 3);
	n = -10000000000;
	assert(lastDigit(n) == 0);
	n = 823456789012348;
	assert(lastDigit(n) == 8);
	n = 4234567890123456;
	assert(lastDigit(n) == 6);
	n = 623456789012345674;
	assert(lastDigit(n) == 4);
	n = long.max;
	assert(lastDigit(n) == 7);
}

unittest {
	BigInt n;
	n = 7;
	assert(lastDigit(n) == 7);
	n = -13;
	assert(lastDigit(n) == 3);
	n = 999;
	assert(lastDigit(n) == 9);
	n = -9999;
	assert(lastDigit(n) == 9);
	n = 25987;
	assert(lastDigit(n) == 7);
	n = -5008615;
	assert(lastDigit(n) == 5);
	n = 3234567893;
	assert(lastDigit(n) == 3);
	n = -10000000000;
	assert(lastDigit(n) == 0);
	n = 823456789012348;
	assert(lastDigit(n) == 8);
	n = 4234567890123456;
	assert(lastDigit(n) == 6);
	n = 623456789012345674;
	assert(lastDigit(n) == 4);
	n = long.max;
	assert(lastDigit(n) == 7);
}

unittest {
	long m;
	int n;
	m = 12345;
	n = 2;
	assert(decShl(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assert(decShl(m,n) == 12345678900000000);
	m = 12;
	n = 2;
	assert(decShl(m,n) == 1200);
	m = 12;
	n = 4;
	assert(decShl(m,n) == 120000);
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
	assert(firstDigit(n) == 7);
	n = -13;
	assert(firstDigit(n) == 1);
	n = 999;
	assert(firstDigit(n) == 9);
	n = -9999;
	assert(firstDigit(n) == 9);
	n = 25987;
	assert(firstDigit(n) == 2);
	n = -5008617;
	assert(firstDigit(n) == 5);
	n = 3234567890;
	assert(firstDigit(n) == 3);
	n = -10000000000;
	assert(firstDigit(n) == 1);
	n = 823456789012345;
	assert(firstDigit(n) == 8);
	n = 4234567890123456;
	assert(firstDigit(n) == 4);
	n = 623456789012345678;
	assert(firstDigit(n) == 6);
	n = long.max;
	assert(firstDigit(n) == 9);
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
	assert(numDigits(n) ==	1);
	n = -13;
	assert(numDigits(n) ==	2);
	n = 999;
	assert(numDigits(n) ==	3);
	n = -9999;
	assert(numDigits(n) ==	4);
	n = 25987;
	assert(numDigits(n) ==	5);
	n = -2008617;
	assert(numDigits(n) ==	7);
	n = 1234567890;
	assert(numDigits(n) == 10);
	n = -10000000000;
	assert(numDigits(n) == 11);
	n = 123456789012345;
	assert(numDigits(n) == 15);
	n = 1234567890123456;
	assert(numDigits(n) == 16);
	n = 123456789012345678;
	assert(numDigits(n) == 18);
	n = long.max;
	assert(numDigits(n) == 19);
}

unittest {
	writeln("-------------------");
	writeln("rounding........end");
	writeln("-------------------");
}


