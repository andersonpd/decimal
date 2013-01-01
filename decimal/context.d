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

module decimal.context;

import std.bigint;

import decimal.arithmetic: compare, copyNegate, equals;
import decimal.conv;
import decimal.decimal;
import decimal.integer;

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.......begin");
	writeln("===================");
}

//--------------------------
// Pre-defined decimal contexts
//--------------------------

/// The context used in examples of operations in the specification.
static DecimalContext testContext = DecimalContext(9, 99, Rounding.HALF_EVEN);

/// The basic default context. In addition the inexact, rounded and subnormal
/// trap-enablers should set to 0; all others should be set to 1 (that is,
/// the other conditions are treated as errors)
/// General Decimal Arithmetic Specification, p. 16.
immutable static DecimalContext BASIC_CONTEXT =
		DecimalContext(9, 999, Rounding.HALF_UP);

/// An extended default context. No trap-enablers should be set.
immutable static DecimalContext EXTENDED_CONTEXT =
	DecimalContext(999, 9999, Rounding.HALF_EVEN);

//--------------------------
// DecimalContext struct
//--------------------------

/// The available rounding modes. For cumulative operations use the
/// HALF_EVEN mode to prevent accumulation of errors. Otherwise the
/// HALF_UP and HALF_DOWN modes are satisfactory. The UP, DOWN, FLOOR,
/// and CEILING modes are also useful for some operations.
/// General Decimal Arithmetic Specification, p. 13-14.
public enum Rounding {
    HALF_EVEN,
    HALF_DOWN,
    HALF_UP,
    DOWN,
    UP,
    FLOOR,
    CEILING,
}

/// The available flags and trap-enablers.
/// The larger value have higher precedence.
/// If more than one flag is set by an operation and traps are enabled,
/// the flag with higher precedence will throw its exception.
/// General Decimal Arithmetic Specification, p. 15.
public enum : ubyte {
	INVALID_OPERATION  = 0x80,
	DIVISION_BY_ZERO   = 0x40,
	OVERFLOW           = 0x20,
	SUBNORMAL          = 0x10,
	INEXACT            = 0x08,
	ROUNDED            = 0x04,
	UNDERFLOW          = 0x02,
	CLAMPED            = 0x01
}

/// Arithmetic context for decimal operations.
/// "The user-selectable parameters and rules
/// which govern the results of arithmetic operations",
/// General Decimal Arithmetic Specification, p. 13-14.
public struct DecimalContext {

	/// Maximum length of the coefficient in decimal digits.
	public uint precision;
	/// Maximum value of the adjusted exponent.
	public int maxExpo;
	/// Rounding mode.
	public Rounding rounding;

	/// Smallest normalized exponent.
	@property
	public const int minExpo() {
		return 1 - maxExpo;
	}

	/// Smallest non-normalized exponent.
	@property
	public const int tinyExpo() {
		return 2 - maxExpo - precision;
	}

/*	@property
	public uint precision() {
		return precision;
	}*/

	/// Returns a copy of the context with a new precision.
	public const DecimalContext setPrecision(immutable uint precision) {
		return DecimalContext(precision, this.maxExpo, this.rounding);
	}

	/// Returns a copy of the context with a new maximum exponent.
	public const DecimalContext setMaxExponent(immutable int maxExpo) {
		return DecimalContext(this.precision, maxExpo, this.rounding);
	}
	/// Returns a copy of the context with a new rounding mode.
	public const DecimalContext setRounding(immutable Rounding rounding) {
		return DecimalContext(this.precision, this.maxExpo, rounding);
	}

	// (X)TODO: is there a way to make this const w/in a context?
	// (X)TODO: This is only used by Decimal -- maybe should move it there?
	// (X)TODO: The mantissa is 10^^(precision - 1), so probably don't need
	//			to implement as a string.
	// Returns the maximum representable normal value in the current context.
	const string maxString() {
		string cstr = "9." ~ std.array.replicate("9", precision - 1)
					~ "E" ~ std.string.format("%d", maxExpo);
		return cstr;
	}
}	// end struct DecimalContext

/// "The exceptional conditions are grouped into signals,
/// which can be controlled individually.
/// The context contains a flag (which is either 0 or 1)
/// and a trap-enabler (which also is either 0 or 1) for each signal.
/// For each of the signals, the corresponding flag is
/// set to 1 when the signal occurs.
/// It is only reset to 0 by explicit user action."
/// General Decimal Arithmetic Specification, p. 15.
public struct ContextFlags {

	private static ubyte flags;
	private static ubyte traps;

	/// Sets or resets the specified context flag(s).
	void setFlags(const ubyte flags, const bool value = true) {
		if (value) {
			ubyte saved = this.flags;
			this.flags |= flags;
			ubyte changed = saved ^ flags;
			checkFlags(changed);
			// (X)TODO: if this flag is trapped an exception should be thrown.
		} else {
			this.flags &= !flags;
		}
	}

	// Checks the state of the flags. If a flag is set and its
	// trap-enabler is set, an exception is thrown.
	 void checkFlags(const ubyte flags) {
		if (flags & INVALID_OPERATION && traps & INVALID_OPERATION) {
			throw new InvalidOperationException("INVALID_OPERATION");
		}
		if (flags & DIVISION_BY_ZERO && traps & DIVISION_BY_ZERO) {
			throw new DivByZeroException("DIVISION_BY_ZERO");
		}
		if (flags & OVERFLOW && traps & OVERFLOW) {
			throw new OverflowException("OVERFLOW");
		}
		if (flags & SUBNORMAL && traps & SUBNORMAL) {
			throw new SubnormalException("SUBNORMAL");
		}
		if (flags & INEXACT && traps & INEXACT) {
			throw new InexactException("INEXACT");
		}
		if (flags & ROUNDED && traps & ROUNDED) {
			throw new RoundedException("ROUNDED");
		}
		if (flags & UNDERFLOW && traps & UNDERFLOW) {
			throw new UnderflowException("UNDERFLOW");
		}
		if (flags & CLAMPED && traps & CLAMPED) {
			throw new ClampedException("CLAMPED");
		}
	}

	/// Gets the value of the specified context flag.
	 bool getFlag(const ubyte flag) {
		return (this.flags & flag) == flag;
	}

	/// Returns a snapshot of the context flags.
	 ubyte getFlags() {
		return flags;
	}

	/// Clears all the context flags.
	void clearFlags() {
		flags = 0;
	}

	/// Sets or resets the specified trap(s).
	void setTrap(const ubyte traps, const bool value = true) {
		if (value) {
			this.traps |= traps;
		} else {
			this.traps &= !traps;
		}
	}

	/// Returns the value of the specified trap.
	 bool getTrap(const ubyte trap) {
		return (this.traps & trap) == trap;
	}

	/// Returns a snapshot of traps.
	public ubyte getTraps() {
		return traps;
	}

	/// Clears all the traps.
	void clearTraps() {
		traps = 0;
	}

};

// this is the single instance of the context flags
static ContextFlags contextFlags;


private const uint128 TEN128 = uint128(10);
/*private const uint128 THOU128 = TEN128^^3;
private const uint128 MILL128 = THOU128^^3;
private const uint128 BILL128 = MILL128^^3;
private const uint128 TRIL128 = BILL128^^3;
private const uint128 QUAD128 = TRIL128^^3;
private const uint128 QUINT128 = QUAD128^^3;
private const uint128 FIVE128 = uint128(5);*/

/// Rounds the referenced number using the precision and rounding mode of
/// the context parameter.
/// Flags: SUBNORMAL, CLAMPED, OVERFLOW, INEXACT, ROUNDED.
public T roundToPrecision(T)(const T num,
		const DecimalContext context = T.context,
		const bool setFlags = true) if (isDecimal!T) {

	T result = num.dup;

	// special values aren't rounded
	if (!num.isFinite) return result;

	// zero values aren't rounded, but they are checked for
	// subnormal and out of range exponents.
	if (num.isZero) {
		if (num.exponent < context.minExpo) {
			contextFlags.setFlags(SUBNORMAL);
			if (num.exponent < context.tinyExpo) {
				int temp = context.tinyExpo;
				result.exponent = context.tinyExpo;
			}
		}
		return result;
	}

	// handle subnormal numbers
	if (num.isSubnormal(context)) {
		if (setFlags) contextFlags.setFlags(SUBNORMAL);
		int diff = context.minExpo - result.adjustedExponent;
		// decrease the precision and round
		int precision = context.precision - diff;
		if (result.digits > precision) {
			auto ctx = Decimal.setPrecision(precision);
			roundByMode(result, ctx);
		}
		// if the result of rounding a subnormal is zero
		// the clamped flag is set. (Spec. p. 51)
		if (result.isZero) {
			result.exponent = context.tinyExpo;
			if (setFlags) contextFlags.setFlags(CLAMPED);
		}
		return result;
	}

	// check for overflow
	if (overflow(result, context)) return result;
	// round the number
	roundByMode(result, context);
	// check again for an overflow
	overflow(result, context);
	return result;

} // end roundToPrecision()

unittest {	// roundToPrecision
	import decimal.dec32;

	Decimal before = Decimal(9999);
	Decimal after = before;
	DecimalContext ctx3 = DecimalContext(3, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx3);
	assert("1.00E+4" == after.toString);
	before = Decimal(1234567890);
	after = before;
	after = roundToPrecision(after, ctx3);
	assert(after.toString == "1.23E+9");
	after = before;
	DecimalContext ctx4 = DecimalContext(4, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx4);;
	assert(after.toString == "1.235E+9");
	after = before;
	DecimalContext ctx5 = DecimalContext(5, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx5);;
	assert(after.toString == "1.2346E+9");
	after = before;
	DecimalContext ctx6 = DecimalContext(6, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx6);;
	assert(after.toString == "1.23457E+9");
	after = before;
	DecimalContext ctx7 = DecimalContext(7, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx7);;
	assert(after.toString == "1.234568E+9");
	after = before;
	DecimalContext ctx8 = DecimalContext(8, 99, Rounding.HALF_EVEN);
	after = roundToPrecision(after, ctx8);;
	assert(after.toString == "1.2345679E+9");
	before = 1235;
	after = before;
	after = roundToPrecision(after, ctx3);;
	assert("[0,124,1]" == after.toAbstract());
	before = 12359;
	after = before;
	after = roundToPrecision(after, ctx3);;
	assert("[0,124,2]" == after.toAbstract());
	before = 1245;
	after = before;
	after = roundToPrecision(after, ctx3);
	assert("[0,124,1]" == after.toAbstract());
	before = 12459;
	after = before;
	after = roundToPrecision(after, ctx3);;
	assert(after.toAbstract() == "[0,125,2]");
	Dec32 a = Dec32(0.1);
	Dec32 b = Dec32.min * Dec32(8888888);
	assert("[0,8888888,-101]" == b.toAbstract);
	Dec32 c = a * b;
	assert("[0,888889,-101]" == c.toAbstract);
	Dec32 d = a * c;
	assert("[0,88889,-101]" == d.toAbstract);
	Dec32 e = a * d;
	assert("[0,8889,-101]" == e.toAbstract);
	Dec32 f = a * e;
	assert("[0,889,-101]" == f.toAbstract);
	Dec32 g = a * f;
	assert("[0,89,-101]" == g.toAbstract);
	Dec32 h = a * g;
	assert("[0,9,-101]" == h.toAbstract);
	Dec32 i = a * h;
	assert("[0,1,-101]" == i.toAbstract);
}

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

private bool halfRounding(DecimalContext context) {
	return (context.rounding == Rounding.HALF_EVEN ||
	 		context.rounding == Rounding.HALF_UP ||
	 		context.rounding == Rounding.HALF_DOWN);
}

/// Rounds the number to the context precision.
/// The number is rounded using the context rounding mode.
private void roundByMode(T)(ref T num,
		const DecimalContext context = T.context) if (isDecimal!T) {
	int dig = num.digits;
	T save = num.dup;

	// calculate remainder
	T remainder = getRemainder(num, context);
	// if the number wasn't rounded, return
	if (remainder.isZero) {
		return;
	}
	// check for deleted leading zeros in the remainder.
	// makes a difference only in round-half modes.
	if (halfRounding(context) &&
		numDigits(remainder.coefficient) != remainder.digits) {
		return;
	}
//	// check for deleted leading zeros in the remainder.
//	bool leadingZeros = numDigits(remainder.coefficient) != remainder.digits;

	switch (context.rounding) {
		case Rounding.UP:
			incrementAndRound(num);
			return;
		case Rounding.DOWN:
			return;
		case Rounding.CEILING:
			if (!num.sign) {
				incrementAndRound(num);
			}
			return;
		case Rounding.FLOOR:
			if (num.sign) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_UP:
//			if (leadingZeros) return;
			if (firstDigit(remainder.coefficient) >= 5) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_DOWN:
//			if (leadingZeros) return;
			if (testFive(remainder.coefficient) > 0) {
				incrementAndRound(num);
			}
			return;
		case Rounding.HALF_EVEN:
//			if (leadingZeros) return;
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

unittest {
	// roundByMode
	DecimalContext ctxHE = DecimalContext(5, 99, Rounding.HALF_EVEN);
	Decimal num;
	num = 1000;
	roundByMode(num, ctxHE);
	assert(num.coefficient == 1000 && num.exponent == 0 && num.digits == 4);
	num = 1000000;
	roundByMode(num, ctxHE);
	assert(num.coefficient == 10000 && num.exponent == 2 && num.digits == 5);
	num = 99999;
	roundByMode(num, ctxHE);
	assert(num.coefficient == 99999 && num.exponent == 0 && num.digits == 5);
	num = 1234550;
	roundByMode(num, ctxHE);
	assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
	DecimalContext ctxDN = ctxHE.setRounding(Rounding.DOWN);
	num = 1234550;
	roundByMode(num, ctxDN);
	assert(num.coefficient == 12345 && num.exponent == 2 && num.digits == 5);
	DecimalContext ctxUP = ctxHE.setRounding(Rounding.UP);
	num = 1234550;
	roundByMode(num, ctxUP);
	assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
}

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
	return remainder;
}

unittest {	// getRemainder
	DecimalContext ctx5 = testContext.setPrecision(5);
	Decimal num, acrem, exnum, exrem;
	num = Decimal(1234567890123456L);
	acrem = getRemainder(num, ctx5);
	exnum = Decimal("1.2345E+15");
	assert(num == exnum);
	exrem = 67890123456;
	assert(acrem == exrem);
}

/// Increments the coefficient by 1. If this causes an overflow
/// the coefficient is adjusted by clipping the last digit (it will be zero)
/// and incrementing the exponent.
private void incrementAndRound(T)(ref T num) if (isDecimal!T) {

	num.coefficient = num.coefficient + 1;
	int digits = num.digits;
	// if num was zero
	if (digits == 0) {
		num.digits = 1;
	}
	else if (lastDigit(num.coefficient) == 0) {
		if (num.coefficient / T.pow10(digits) > 0) {
			num.coefficient = num.coefficient / 10;
			num.exponent = num.exponent + 1;
		}
	}
}

unittest {	// increment(Decimal)
	Decimal num, expect;
	num = 10;
	expect = 11;
	incrementAndRound(num);
	assert(num == expect);
	num = 19;
	expect = 20;
	incrementAndRound(num);
	assert(num == expect);
	num = 999;
	expect = 1000;
	incrementAndRound(num);
	assert(num == expect);
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
// TODO: calls firstDigit and then numDigits: combine these calls.
public int testFive(const uint128 arg) {
	int first = firstDigit(arg);
	if (first < 5) return -1;
	if (first > 5) return +1;
	uint128 zeros = (arg % TEN128^^(numDigits(arg)-1)).toUint;
	return (zeros != 0) ? 1 : 0;
}

/// Returns -1, 1, or 0 if the remainder is less than, more than,
/// or exactly half the least significant digit of the shortened coefficient.
/// Exactly half is a five followed by zero or more zero digits.
// TODO: calls firstDigit and then numDigits: combine these calls.
public int testFive(const BigInt arg) {
	int first = firstDigit(arg);
	if (first < 5) return -1;
	if (first > 5) return +1;
	BigInt big = mutable(arg);
	BigInt zeros = big % BIG_TEN^^(numDigits(arg)-1);
	return (zeros != 0) ? 1 : 0;
}

unittest {	// firstDigit(BigInt)
	BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assert(firstDigit(big) == 8);
}

/// Returns -1, 1, or 0 if the remainder is less than, more than,
/// or exactly half the least significant digit of the shortened coefficient.
/// Exactly half is a five followed by zero or more zero digits.
/*public int testFive(const BigInt arg) {
	return testFive(bigToLong(arg));
}*/

unittest {	// testFive
	assert( 0 == testFive(5000));
	assert(-1 == testFive(4999));
	assert( 1 == testFive(5001));
	assert( 0 == testFive(BigInt("5000000000000000000000")));
	assert(-1 == testFive(BigInt("4999999999999999999999")));
	assert( 1 == testFive(BigInt("50000000000000000000000000000000000000000000000001")));
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

/*	// check for deleted leading zeros in the remainder.
	// makes a difference only in round-half modes.
	if (halfRounding(context) &&
		numDigits(remainder.coefficient) != remainder.digits) {
		return;
	}*/

	switch (context.rounding) {
	case Rounding.DOWN:
		break;
	case Rounding.HALF_UP:
		if (firstDigit(remainder) >= 5) {
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
		mant /= 10;
		expo++;
		digits--;
	}
	return expo;

} // end setExponent()

unittest {	// setExponent
	DecimalContext ctx = testContext.setPrecision(5);
	ulong num;
	uint digits;
	int expo;
	num = 1000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assert(num == 1000 && expo == 0 && digits == 4);
	num = 1000000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assert(num == 10000 && expo == 2 && digits == 5);
	num = 99999;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx);
	assert(num == 99999 && expo == 0 && digits == 5);
}

/// Converts an integer to a decimal (coefficient and exponent) form.
/// The input value is rounded to the context precision,
/// the number of digits is adjusted, and the exponent is returned.
public uint setExponent(const bool sign, ref uint128 mant, ref uint digits,
		const DecimalContext context) {

	uint inDigits = digits;
	uint128 remainder = clipRemainder(mant, digits, context.precision);
	int expo = inDigits - digits;

	// if the remainder is zero, return
	if (remainder == 0) {
		return expo;
	}

/*	// check for deleted leading zeros in the remainder.
	// makes a difference only in round-half modes.
	if (halfRounding(context) &&
		numDigits(remainder.coefficient) != remainder.digits) {
		return;
	}*/

	switch (context.rounding) {
	case Rounding.DOWN:
		break;
	case Rounding.HALF_UP:
		if (firstDigit(remainder) >= 5) {
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
		if (isOdd(mant)) {
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
		mant  =  mant / 10;
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

unittest {	// clipRemainder
	ulong num, acrem, exnum, exrem;
	uint digits, precision;
	num = 1234567890123456L;
	digits = 16;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 67890123456L;
	assert(acrem == exrem);

	num = 12345768901234567L;
	digits = 17;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 768901234567L;
	assert(acrem == exrem);

	num = 123456789012345678L;
	digits = 18;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 6789012345678L;
	assert(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19;
	precision = 5;
	acrem = clipRemainder(num, digits, precision);
	exnum = 12345L;
	assert(num == exnum);
	exrem = 67890123456789L;
	assert(acrem == exrem);

	num = 1234567890123456789L;
	digits = 19;
	precision = 4;
	acrem = clipRemainder(num, digits, precision);
	exnum = 1234L;
	assert(num == exnum);
	exrem = 567890123456789L;
	assert(acrem == exrem);

	num = 9223372036854775807L;
	digits = 19;
	precision = 1;
	acrem = clipRemainder(num, digits, precision);
	exnum = 9L;
	assert(num == exnum);
	exrem = 223372036854775807L;
	assert(acrem == exrem);
}

/// Shortens the number to the specified precision and
/// returns the (unsigned) remainder.
/// Flags: ROUNDED, INEXACT.
private uint128 clipRemainder(ref uint128 num, ref uint digits, uint precision) {
	uint128 remainder = 0;
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
		uint128 divisor = 10L^^diff;
		uint128 dividend = num;
		uint128 quotient = dividend / divisor;
		num = quotient;
		remainder = dividend - quotient*divisor;
		digits = precision;
	}
	return remainder;
}

/// Increments the number by 1.
/// Re-calculates the number of digits -- the increment may have caused
/// an increase in the number of digits, i.e., input number was all 9s.
private void increment(T)(ref T num, ref uint digits) {
	num++;
	digits = numDigits(num);
}

//-----------------------------
// useful constants
//-----------------------------

// BigInt has problems with const and immutable; these should be const values.
// the best I can do is to make them private.
private BigInt BIG_ZERO = BigInt(0);
private BigInt BIG_ONE  = BigInt(1);
private BigInt BIG_FIVE = BigInt(5);
private BigInt BIG_TEN  = BigInt(10);
private BigInt BILLION  = BigInt(1_000_000_000);
private BigInt QUINTILLION = BigInt(1_000_000_000_000_000_000);

//private uint128 TEN128 = 10;
//private uint128 QUINT128 = uint128.TEN^^18; //uint128(1_000_000_000_000_000_000);

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
	int count = 0;
	long n = bigToLong(arg, count);
	return count + numDigits(n);
}

unittest {	// numDigits(BigInt)
	BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assert(101 == numDigits(big));
}

/// Returns the number of digits in the argument.
public int numDigits(const uint128 arg) {
    // special cases
	if (arg == 0) return 0;
    if (arg < 10) return 1;
    // otherwise reduce until number fits into a long integer...
	int count = 0;
	uint128 num = arg;
	// TODO: why is this commented out?
/*	if (num > QUINT128) {
		num /= QUINT128;
writefln("QUINT128 = %s", QUINT128);
		count += 18;
	}*/
	/// ...and delegate result to long integer version
	long n = num.toUlong;
//writefln("num = %s", num);
//writefln("n = %s", n);
	return count + numDigits(n);
}

/// Returns the number of digits in the argument,
/// where the argument is an unsigned long integer.
public int numDigits(const ulong n) {
    // special cases:
	if (n == 0) return 0;
	if (n < 10) return 1;
	if (n >= TENS[18]) return 19;
    // use a binary search to count the digits
	int min = 2;
	int max = 18;
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

unittest {	// numDigits(ulong)
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


unittest {	// numDigits
	long n;
	n = 7;
	int expect = 1;
	int actual = numDigits(n);
	assert(actual == expect);
	n = 13;
	expect = 2;
	actual = numDigits(n);
	assert(actual == expect);
	n = 999;
	expect = 3;
	actual = numDigits(n);
	assert(actual == expect);
	n = 9999;
	expect = 4;
	actual = numDigits(n);
	assert(actual == expect);
	n = 25987;
	expect = 5;
	actual = numDigits(n);
	assert(actual == expect);
	n = 2008617;
	expect = 7;
	actual = numDigits(n);
	assert(actual == expect);
	n = 1234567890;
	expect = 10;
	actual = numDigits(n);
	assert(actual == expect);
	n = 10000000000;
	expect = 11;
	actual = numDigits(n);
	assert(actual == expect);
	n = 123456789012345;
	expect = 15;
	actual = numDigits(n);
	assert(actual == expect);
	n = 1234567890123456;
	expect = 16;
	actual = numDigits(n);
	assert(actual == expect);
	n = 123456789012345678;
	expect = 18;
	actual = numDigits(n);
	assert(actual == expect);
	n = long.max;
	expect = 19;
	actual = numDigits(n);
	assert(actual == expect);
}

public ulong bigToLong(const BigInt arg) {
	BigInt big = mutable(arg);
	while (big > QUINTILLION) {
		big /= QUINTILLION;
	}
	return big.toLong;
}

public ulong bigToLong(const BigInt arg, out int count) {
	count = 0;
	BigInt big = mutable(arg);
	while (big > QUINTILLION) {
		big /= QUINTILLION;
		count += 18;
	}
	return big.toLong;
}

/// Returns the first digit of the argument.
public int firstDigit(const BigInt arg) {
	return firstDigit(bigToLong(arg));
}

/// Returns the first digit of the argument.
public int firstDigit(const uint128 arg) {
	if (arg == 0) return 0;
	if (arg < 10) return arg.toUint();
	uint128 n = arg;
	while (n > TEN128^^18) {
		n /= TEN128^^18;
	}
	return firstDigit(n.toUlong());
}

/// Returns the first digit of the argument.
public int firstDigit(const ulong n) { //, int maxValue = 19) {
	if (n == 0) return 0;
	if (n < 10) return cast(int) n;
	int d = numDigits(n); //, maxValue);
	return cast(int)(n/TENS[d-1]);
}

unittest {	// firstDigit
	long n;
	n = 7;
	int expect, actual;
	expect = 7;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 13;
	expect = 1;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 999;
	expect = 9;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 9999;
	expect = 9;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 25987;
	expect = 2;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 5008617;
	expect = 5;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 3234567890;
	expect = 3;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 10000000000;
	expect = 1;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 823456789012345;
	expect = 8;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 4234567890123456;
	expect = 4;
	actual = firstDigit(n);
	assert(actual == expect);
	n = 623456789012345678;
	expect = 6;
	actual = firstDigit(n);
	assert(actual == expect);
	n = long.max;
	expect = 9;
	actual = firstDigit(n);
	assert(actual == expect);
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

unittest {	// shiftLeft(BigInt)
	BigInt m;
	int n;
	m = 12345;
	n = 2;
	assert(shiftLeft(m, n, 100) == 1234500);
	m = 1234567890;
	n = 7;
	assert(shiftLeft(m, n, 100) == BigInt(12345678900000000));
	m = 12;
	n = 2;
	assert(shiftLeft(m, n, 100) == 1200);
	m = 12;
	n = 4;
	assert(shiftLeft(m, n, 100) == 120000);
	uint k;
	k = 12345;
	n = 2;
	assert(1234500 == cast(uint)shiftLeft(k, n, 9));
	k = 1234567890;
	n = 7;
	assert(900000000 == cast(uint)shiftLeft(k, n, 9));
	k = 12;
	n = 2;
	assert(1200 == cast(uint)shiftLeft(k, n, 9));
	k = 12;
	n = 4;
	assert(120000 == cast(uint)shiftLeft(k, n, 9));
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

unittest {	// shiftLeft
	long m;
	int n;
	m = 12345;
	n = 2;
	assert(shiftLeft(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assert(shiftLeft(m,n) == 12345678900000000);
	m = 12;
	n = 2;
	assert(shiftLeft(m,n) == 1200);
	m = 12;
	n = 4;
	assert(shiftLeft(m,n) == 120000);
}

/// Shifts the number right the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted left.
public BigInt shiftRight(BigInt num, const int n,
		const int precision = Decimal.context.precision) {
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
// TODO: test these fctns
/// Shifts the number right (truncates) the specified number of decimal digits.
/// If n == 0 the number is returned unchanged.
/// If n < 0 the number is shifted left.
public uint shiftRight(uint num, int n,
		const int precision = MAX_INT_DIGITS) {
	if (n > precision) return 0;
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

unittest {	// lastDigit(BigInt)
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

/// Returns the last digit of the argument.
public uint lastDigit(const uint128 arg) {
	return (abs(arg) % 10UL).toUint();
}

/// Returns the last digit of the argument.
public uint lastDigit(const long num) {
	return cast(uint)(std.math.abs(num) % 10UL);
}

unittest {	// lastDigit(ulong)
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

/// Returns the number of trailing zeros in the argument.
public int trailingZeros(const BigInt arg, const int digits) {
	BigInt n = mutable(arg);
	// shortcuts for frequent values
	if (n == 0) return 0;
	if (n % 10) return 0;
	if (n % 100) return 1;
	// find by binary search
	int min = 3;
	int max =  digits - 1;
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
public int trailingZeros(const ulong n) {
	// shortcuts for frequent values
	if (n == 0) return 0;
	if (n % 10) return 0;
	if (n % 100) return 1;
	// find by binary search
	int min = 3;
	int max = 18;
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

/// Trims any trailing zeros and returns the number of zeros trimmed.
public int trimZeros(ref ulong n, const int dummy) {
	int zeros = trailingZeros(n);
	if (zeros == 0) return 0;
	n /= TENS[zeros];
	return zeros;
}

/// Trims any trailing zeros and returns the number of zeros trimmed.
public int trimZeros(ref BigInt n, const int digits) {
	int zeros = trailingZeros(n, digits);
	if (zeros == 0) return 0;
	n /= tens(zeros);
	return zeros;
}

/// Returns a BigInt value of ten raised to the specified power.
public BigInt tens(const int n) {
	if (n < 19) return BigInt(TENS[n]);
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

public bool isOdd(const uint128 n) {
	return n.getLong(1) & 1;
}


/// Returns a mutable copy of a BigInt
public BigInt mutable(const BigInt num) {
	BigInt big = cast(BigInt)num;
	return big;
}

/// Returns the absolute value of a BigInt
public BigInt abs(const BigInt num) {
	BigInt big = mutable(num);
	return big < 0 ? -big : big;
}

/// Returns the absolute value of a uint128
public uint128 abs(const uint128 num) {
	uint128 copy = num.dup;
	return num < 0 ? -copy : copy;
}

//--------------------------
// Context flags and trap-enablers
//--------------------------

/// The base class for all decimal arithmetic exceptions.
class DecimalException: object.Exception {
	this(string msg, string file = __FILE__,
		uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when the exponent of a result has been altered or constrained
/// in order to fit the constraints of a specific concrete representation.
/// General Decimal Arithmetic Specification, p. 15.
class ClampedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a non-zero dividend is divided by zero.
/// General Decimal Arithmetic Specification, p. 15.
class DivByZeroException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is not exact (one or more non-zero coefficient
/// digits were discarded during rounding).
/// General Decimal Arithmetic Specification, p. 15.
class InexactException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result would be undefined or impossible.
/// General Decimal Arithmetic Specification, p. 15.
class InvalidOperationException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when the exponent of a result is too large to be represented.
/// General Decimal Arithmetic Specification, p. 15.
class OverflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result has been rounded (that is, some zero or non-zero
/// coefficient digits were discarded).
/// General Decimal Arithmetic Specification, p. 15.
class RoundedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is subnormal (its adjusted exponent is less
/// than the minimum exponent) before any rounding.
/// General Decimal Arithmetic Specification, p. 15.
class SubnormalException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is both subnormal and inexact.
/// General Decimal Arithmetic Specification, p. 15.
class UnderflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.........end");
	writeln("===================");
}

