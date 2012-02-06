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

// TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// TODO: to/from real or double (float) values needs definition and implementation.

module decimal.decimal;

import decimal.context;
import decimal.rounding;
import decimal.arithmetic;

import std.bigint;
import std.exception: assumeUnique;
import std.conv;
import std.array: replicate;
import std.ascii: isDigit;
import std.math: PI, LOG2;
import std.stdio: write, writeln;
import std.string;

unittest {
	writeln("-------------------");
	writeln("decimal.......begin");
	writeln("-------------------");
}

alias BigDecimal.bigContext bigContext;

// special values for NaN, Inf, etc.
private static enum SV {NONE, INF, QNAN, SNAN};

/**
 * A struct representing an arbitrary-precision floating-point number.
 *
 * The implementation follows the General Decimal Arithmetic
 * Specification, Version 1.70 (25 Mar 2009),
 * http://www.speleotrove.com/decimal. This specification conforms with
 * IEEE standard 754-2008.
 */
struct BigDecimal {

	private static DecimalContext bigContext = DecimalContext(9, 99, Rounding.HALF_EVEN);

	private SV sval = SV.QNAN;		// special values: default value is quiet NaN
	private bool signed = false;	// true if the value is negative, false otherwise.
	private int expo = 0;			// the exponent of the BigDecimal value
	private BigInt mant;			// the coefficient of the BigDecimal value
	// NOTE: not a uint -- causes math problems down the line.
	package int digits; 			// the number of decimal digits in this number.
									// (unless the number is a special value)

private:

// common decimal "numbers"
	immutable BigDecimal NAN	  = BigDecimal(SV.QNAN);
	immutable BigDecimal SNAN	  = BigDecimal(SV.SNAN);
	immutable BigDecimal INFINITY = BigDecimal(SV.INF);
	immutable BigDecimal NEG_INF  = BigDecimal(SV.INF, true);
	immutable BigDecimal ZERO	  = BigDecimal(SV.NONE);
	immutable BigDecimal NEG_ZERO = BigDecimal(SV.NONE, true);

	immutable BigInt BIG_ZERO = cast(immutable)BigInt(0);
	immutable BigInt BIG_ONE  = cast(immutable)BigInt(1);
	immutable BigInt BIG_TWO  = cast(immutable)BigInt(2);

//	static BigDecimal DONE = BigDecimal(BIG_ONE);
//	static immutable BigDecimal TWO  = cast(immutable)BigDecimal(2);
//	static immutable BigDecimal FIVE = cast(immutable)BigDecimal(5);
//	static immutable BigDecimal TEN  = cast(immutable)BigDecimal(10);

unittest {
	BigDecimal num;
	num = NAN;
	assertTrue(num.toString == "NaN");
	num = SNAN;
	assertTrue(num.toString == "sNaN");
//	writeln("BigDecimal(SV.QNAN).toAbstract = ", NAN.toAbstract);
	num = NEG_ZERO;
	assertTrue(num.toString == "-0");
}

public:

//--------------------------------
// construction
//--------------------------------

	/**
	 * Constructs a new number given a special value and an optional sign.
	 */
	public this(const SV sv, const bool sign = false) {
		this.signed = sign;
		this.sval = sv;
	}

	unittest {
		BigDecimal num = BigDecimal(SV.INF, true);
		assertTrue(num.toSciString == "-Infinity");
		assertTrue(num.toAbstract() == "[1,inf]");
	}

	/**
	 * Creates a BigDecimal from a boolean value.
	 */
	public this(const bool value)
	{
		this = zero;
        if (value) {
        	coefficient = 1;
        }
	}

	/**
	 * Constructs a number from a sign, a BigInt coefficient and
	 * an optional(?) integer exponent.
	 * The sign of the number is the value of the sign parameter,
	 * regardless of the sign of the coefficient.
	 * The intial precision of the number is deduced from the number of decimal
	 * digits in the coefficient.
	 */
	this(const bool sign, const BigInt coefficient, const int exponent = 0) {
		BigInt big = abs(coefficient);
		this = zero();
		this.signed = sign;
		this.mant = big;
		this.expo = exponent;
        // TODO: If we specify the number of digits this can be CTFE.
        // The numDigits call is not CTFE.
		this.digits = numDigits(this.mant);
	}

	unittest {
		BigDecimal num;
		num = BigDecimal(true, BigInt(7254), 94);
		assertTrue(num.toString == "-7.254E+97");
	}

	// UNREADY: this(const BigInt, const int). Flags.
	/**
	 * Constructs a BigDecimal from a BigInt coefficient and an
	 * optional integer exponent. The sign of the number is the sign
	 * of the coefficient. The initial precision is determined by the number
	 * of digits in the coefficient.
	 */
	this(const BigInt coefficient, const int exponent = 0) {
		BigInt big = mutable(coefficient);
		bool sign = decimal.rounding.sgn(big) < 0;
		this(sign, big, exponent);
	};

	unittest {
		BigDecimal num;
		num = BigDecimal(BigInt(7254), 94);
		assertTrue(num.toString == "7.254E+97");
		num = BigDecimal(BigInt(-7254));
		assertTrue(num.toString == "-7254");
	}

	// long constructors:

	// UNREADY: this(bool, const int, const int). Flags. Unit Tests.
	/**
	 * Constructs a number from a sign, a long integer coefficient and
	 * an integer exponent.
	 */
	this(const bool sign, const long coefficient, const int exponent) {
		this(sign, BigInt(coefficient), exponent);
	}

	// UNREADY: this(const long, const int). Flags. Unit Tests.
	/**
	 * Constructs a number from an long coefficient
	 * and an optional integer exponent.
	 */
	this(const long coefficient, const int exponent) {
		this(BigInt(coefficient), exponent);
	}

	unittest {
	}

	// UNREADY: this(const long). Flags. Unit Tests.
	/**
	 * Constructs a number from an long coefficient
	 * and an optional integer exponent.
	 */
	this(const long coefficient) {
		this(BigInt(coefficient), 0);
	}

	// string constructors:

	// UNREADY: this(const string). Flags. Unit Tests.
	// construct from string representation
// TODO: this(str): add tests for just over/under int.max, int.min

	this(const string str) {
		this = decimal.conv.toNumber(str);
	};

	unittest {
		BigDecimal num;
		string str;
		num = BigDecimal(1, 12334, -5);
		str = "-0.12334";
		assertTrue(num.toString == str);
		num = BigDecimal(-23456, 10);
		str = "-2.3456E+14";
		assertTrue(num.toString == str);
		num = BigDecimal(234568901234);
		str = "234568901234";
		assertTrue(num.toString == str);
		num = BigDecimal("123.457E+29");
		str = "1.23457E+31";
		assertTrue(num.toString == str);
		num = std.math.E;
		str = "2.71828183";
		assertEqual!string(str, num.toString);
		num = std.math.LOG2;
		BigDecimal copy = BigDecimal(num);
		assertTrue(compareTotal!BigDecimal(num, copy) == 0);
	}

	// floating point constructors:

	// UNREADY: this(const real). Flags. Unit Tests.
	/**
	 *	  Constructs a number from a real value.
	 */
	this(const real r) {
		string str = format("%.*G", cast(int)bigContext.precision, r);
		this(str);
	}

	// UNREADY: this(BigDecimal). Flags. Unit Tests.
	// copy constructor
	this(const BigDecimal that) {
		this.signed = that.signed;
		this.sval	= that.sval;
		this.digits = that.digits;
		this.expo	= that.expo;
		this.mant	= cast(BigInt) that.mant;
	};

	// UNREADY: dup. Flags.
	/**
	 * dup property
	 */
	const BigDecimal dup() {
		return BigDecimal(this);
	}

	unittest {
		BigDecimal num = BigDecimal(std.math.PI);
		BigDecimal copy = num.dup;
		assertTrue(num == copy);
	}

//--------------------------------
// assignment
//--------------------------------

	// UNREADY: opAssign(T: BigDecimal)(const BigDecimal). Flags. Unit Tests.
	/// Assigns a BigDecimal (makes a copy)
	void opAssign(T:BigDecimal)(const T that) {
		this.signed = that.signed;
		this.sval	= that.sval;
		this.digits = that.digits;
		this.expo	= that.expo;
		this.mant	= cast(BigInt) that.mant;
	}

	// UNREADY: opAssign(T)(const T). Flags.
	///    Assigns a floating point value.
	void opAssign(T:BigInt)(const T that) {
		this = BigDecimal(that);
	}

	// UNREADY: opAssign(T)(const T). Flags.
	///    Assigns a floating point value.
	void opAssign(T:long)(const T that) {
		this = BigDecimal(that);
	}

	// UNREADY: opAssign(T)(const T). Flags. Unit Tests.
	///    Assigns a floating point value.
	void opAssign(T:real)(const T that) {
		this = BigDecimal(that);
	}

	void opAssign(T)(const T that) if (isDecimal!T) {
		this = decimal.conv.toBigDecimal!T(that);
	}

	unittest {
		import decimal.dec32;

		BigDecimal num;
		string str;
		num = BigDecimal(1, 245, 8);
		str = "-2.45E+10";
		assertTrue(num.toString == str);
		num = long.max;
		str = "9223372036854775807";
		assertTrue(num.toString == str);
		num = real.max;
		str = "1.1897315E+4932";
		assertEqual!string(str, num.toString);
		num = Dec32.max;
		str = "9.999999E+96";
		assertTrue(num.toString == str);
		num = BigInt("123456098420234978023480");
		str = "123456098420234978023480";
		assertTrue(num.toString == str);
	}

//--------------------------------
// string representations
//--------------------------------

	/**
	 * Converts a number to an abstract string representation.
	 */
	public const string toAbstract() {
		return decimal.conv.toAbstract!BigDecimal(this);
	}

unittest {
	BigDecimal num;
	string str;
	num = BigDecimal("-inf");
	str = "[1,inf]";
	assertTrue(num.toAbstract == str);
	num = BigDecimal("nan");
	str = "[0,qNaN]";
	assertTrue(num.toAbstract == str);
	num = BigDecimal("snan1234");
	str = "[0,sNaN1234]";
	assertTrue(num.toAbstract == str);
}

// READY: toSciString.
/**
 * Converts a BigDecimal to a string representation.
 */
const string toSciString() {
	return decimal.conv.toSciString!BigDecimal(this);
};

// READY: toEngString.
/**
 * Converts a BigDecimal to an engineering string representation.
 */
const string toEngString() {
   return decimal.conv.toEngString!BigDecimal(this);
};

/**
 * Converts a number to its string representation.
 */
const string toString() {
	return toSciString();
};

unittest {
	BigDecimal num;
	string str;
	num = BigDecimal(200000, 71);
	str = "2.00000E+76";
	assertTrue(num.toString == str);
}

//--------------------------------
// member properties
//--------------------------------

	/// returns the exponent of this number
	@property
	const int exponent() {
		return this.expo;
	}

	@property
	int exponent(int expo) {
		this.expo = expo;
		return this.expo;
	}

	@property
	const BigInt coefficient() {
		return cast(BigInt)this.mant;
	}

	@property
	BigInt coefficient(BigInt mant) {
		this.mant = mant;
		return this.mant;
	}

	@property
	BigInt coefficient(long mant) {
		this.mant = BigInt(mant);
		return this.mant;
	}

	@property
	const uint payload() {
		if (this.isNaN) {
			return cast(uint)(this.mant.toLong);
		}
		return 0;
	}

	@property
	uint payload(uint value) {
		if (this.isNaN) {
			this.mant = BigInt(value);
			return value;
		}
		return 0;
	}

	unittest {
		BigDecimal big = -123.45E12;
		assertEqual!int(10, big.exponent);
		assertEqual!BigInt(BigInt(12345), big.coefficient);
//		assertTrue(big.coefficient == 12345);
		assertTrue(big.sign);
		big.coefficient = 23456;
		big.exponent = 12;
		big.sign = false;
		assertEqual!BigDecimal(BigDecimal(234.56E14),big);
		big = nan;
		assertTrue(big.payload == 0);
		big = snan(1250);
		assertTrue(big.payload == 1250);
	}

	const string toExact() {
		return decimal.conv.toExact!BigDecimal(this);
	}

	unittest {
		BigDecimal num;
		assertTrue(num.toExact == "+NaN");
		num = +9999999E+90;
		assertEqual!string("+9999999E+90", num.toExact);
		num = 1;
		assertTrue(num.toExact == "+1E+00");
		num = infinity(true);
		assertTrue(num.toExact == "-Infinity");
	}

	/// returns the adjusted exponent of this number
	@property const int adjustedExponent() {
		return expo + digits - 1;
	}

	/// returns the number of decimal digits in the coefficient of this number
	const int getDigits() {
		return this.digits;
	}

	@property const bool sign() {
		return signed;
	}

	@property bool sign(bool value) {
		signed = value;
		return signed;
	}

//--------------------------------
// floating point properties
//--------------------------------

	/// returns the default value for this type (NaN)
	static BigDecimal init() {
		return NAN.dup;
	}

	/// Returns NaN
	static BigDecimal nan(uint payload = 0) {
		if (payload) {
			BigDecimal dec = NAN.dup;
			dec.payload = payload;
			return dec;
		}
		return NAN.dup;
	}

	/// Returns signaling NaN
	static BigDecimal snan(uint payload = 0) {
		if (payload) {
			BigDecimal dec = SNAN.dup;
			dec.payload = payload;
			return dec;
		}
		return SNAN.dup;
	}

	/// Returns infinity.
	static BigDecimal infinity(bool signed = false) {
		return signed ? NEG_INF.dup : INFINITY.dup;
	}

	/// Returns zero.
	static BigDecimal zero(bool signed = false) {
		return signed ? NEG_ZERO.dup : ZERO.dup;
	}

	/// Returns the maximum number of decimal digits in this context.
	static uint precision(DecimalContext context = bigContext) {
		return context.precision;
	}

	/// Returns the maximum number of decimal digits in this context.
	static uint dig(DecimalContext context = bigContext) {
		return context.precision;
	}

	/// Returns the number of binary digits in this context.
	static int mant_dig(DecimalContext context = bigContext) {
		return cast(int)(context.precision/LOG2);
	}

	static int min_exp(DecimalContext context = bigContext) {
		return cast(int)(context.eMin);
	}

	static int max_exp(DecimalContext context = bigContext) {
		return cast (int)(context.eMax);
	}

/*	// TODO: is there a way to make this const w/in a context?
	// TODO: This is only used by BigDecimal -- maybe should move it there?
	// TODO: The mantissa is 10^^(precision - 1), so probably don't need
	//			to implement as a string.
	// Returns the maximum representable normal value in the current context.
	const string maxString() {
		string cstr = "9." ~ replicate("9", precision - 1)
					~ "E" ~ format("%d", eMax);
		return cstr;
	}*/
	// Returns the maximum representable normal value in the current context.
	// TODO: this is a fairly expensive operation. Can it be fixed?
	static BigDecimal max(DecimalContext context = bigContext) {
		return BigDecimal(context.maxString);
	}

	// Returns the maximum representable normal value in the current context.
	// TODO: this is a fairly expensive operation. Can it be fixed?
	// TODO: is this needed?
	static BigDecimal max(const bool sign, DecimalContext context = bigContext) {
		BigDecimal result = BigDecimal(context.maxString);
		return sign ? -result : result;
	}

	/// Returns the minimum representable normal value in this context.
	static BigDecimal min_normal(DecimalContext context = bigContext) {
		return BigDecimal(1, context.eMin);
	}

	/// Returns the minimum representable subnormal value in this context.
	static BigDecimal min(DecimalContext context = bigContext) {
		return BigDecimal(1, context.eTiny);
	}

	/// returns the smallest available increment to 1.0 in this context
	static BigDecimal epsilon(DecimalContext context = bigContext) {
		return BigDecimal(1, -context.precision);
	}

	static int min_10_exp(DecimalContext context = bigContext) {
		return context.eMin;
	}

	static int max_10_exp(DecimalContext context = bigContext) {
		return context.eMax;
	}

//--------------------------------
//	classification properties
//--------------------------------

	/**
	 * Returns true if this number's representation is canonical (always true).
	 */
	const bool isCanonical() {
		return	true;
	}

	/**
	 * Returns the canonical form of the number.
	 */
	const BigDecimal canonical() {
		return this.dup;
	}

	unittest {
		BigDecimal num = BigDecimal("2.50");
		assertTrue(num.isCanonical);
		BigDecimal copy = num.canonical;
		assertTrue(compareTotal(num, copy) == 0);
	}

	/**
	 * Returns true if this number is + or - zero.
	 */
	const bool isZero() {
		return isFinite && coefficient == 0;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("0");
		assertTrue(num.isZero);
		num = BigDecimal("2.50");
		assertTrue(!num.isZero);
		num = BigDecimal("-0E+2");
		assertTrue(num.isZero);
	}

	/**
	 * Returns true if this number is a quiet or signaling NaN.
	 */
	const bool isNaN() {
		return this.sval == SV.QNAN || this.sval == SV.SNAN;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isNaN);
		num = BigDecimal("NaN");
		assertTrue(num.isNaN);
		num = BigDecimal("-sNaN");
		assertTrue(num.isNaN);
	}

	/**
	 * Returns true if this number is a signaling NaN.
	 */
	const bool isSignaling() {
		return this.sval == SV.SNAN;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isSignaling);
		num = BigDecimal("NaN");
		assertTrue(!num.isSignaling);
		num = BigDecimal("sNaN");
		assertTrue(num.isSignaling);
	}

	/**
	 * Returns true if this number is a quiet NaN.
	 */
	const bool isQuiet() {
		return this.sval == SV.QNAN;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isQuiet);
		num = BigDecimal("NaN");
		assertTrue(num.isQuiet);
		num = BigDecimal("sNaN");
		assertTrue(!num.isQuiet);
	}

	/**
	 * Returns true if this number is + or - infinity.
	 */
	const bool isInfinite() {
		return this.sval == SV.INF;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isInfinite);
		num = BigDecimal("-Inf");
		assertTrue(num.isInfinite);
		num = BigDecimal("NaN");
		assertTrue(!num.isInfinite);
	}

	/**
	 * Returns true if this number is not + or - infinity and not a NaN.
	 */
	const bool isFinite() {
		return sval != SV.INF
			&& sval != SV.QNAN
			&& sval != SV.SNAN;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(num.isFinite);
		num = BigDecimal("-0.3");
		assertTrue(num.isFinite);
		num = 0;
		assertTrue(num.isFinite);
		num = BigDecimal("Inf");
		assertTrue(!num.isFinite);
		num = BigDecimal("-Inf");
		assertTrue(!num.isFinite);
		num = BigDecimal("NaN");
		assertTrue(!num.isFinite);
	}

	/**
	 * Returns true if this number is a NaN or infinity.
	 */
	const bool isSpecial() {
		return sval == SV.INF
			|| sval == SV.QNAN
			|| sval == SV.SNAN;
	}

	unittest {
		BigDecimal num;
		num = infinity(true);
		assertTrue(num.isSpecial);
		num = snan(1234);
		assertTrue(num.isSpecial);
		num = 12378.34;
		assertTrue(!num.isSpecial);
	}

	/**
	 * Returns true if this number is negative. (Includes -0)
	 */
	const bool isSigned() {
		return this.signed;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isSigned);
		num = BigDecimal("-12");
		assertTrue(num.isSigned);
		num = BigDecimal("-0");
		assertTrue(num.isSigned);
	}

	const bool isNegative() {
		return this.signed;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isNegative);
		num = BigDecimal("-12");
		assertTrue(num.isNegative);
		num = BigDecimal("-0");
		assertTrue(num.isNegative);
	}

	/**
	 * Returns true if this number is subnormal.
	 */
	const bool isSubnormal(DecimalContext context = bigContext) {
		if (!isFinite) return false;
		return adjustedExponent < context.eMin;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(!num.isSubnormal);
		num = BigDecimal("0.1E-99");
		assertTrue(num.isSubnormal);
		num = BigDecimal("0.00");
		assertTrue(!num.isSubnormal);
		num = BigDecimal("-Inf");
		assertTrue(!num.isSubnormal);
		num = BigDecimal("NaN");
		assertTrue(!num.isSubnormal);
	}

	/**
	 * Returns true if this number is normal.
	 */
	const bool isNormal(DecimalContext context = bigContext) {
		if (isFinite && !isZero) {
			return adjustedExponent >= context.eMin;
		}
		return false;
	}

	unittest {
		BigDecimal num;
		num = BigDecimal("2.50");
		assertTrue(num.isNormal);
		num = BigDecimal("0.1E-99");
		assertTrue(!num.isNormal);
		num = BigDecimal("0.00");
		assertTrue(!num.isNormal);
		num = BigDecimal("-Inf");
		assertTrue(!num.isNormal);
		num = BigDecimal("NaN");
		assertTrue(!num.isNormal);
	}

	/**
	 * Returns true if this number is integral;
	 * that is, its fractional part is zero.
	 */
	 const bool isIntegral() {
	 	// TODO: need to take trailing zeros into account
		return expo >= 0;
	 }

	unittest {
		BigDecimal num;
		num = 12345;
		assertTrue(num.isIntegral);
		num = BigInt("123456098420234978023480");
		assertTrue(num.isIntegral);
		num = 1.5;
		assertTrue(!num.isIntegral);
		num = 1.5E+1;
		assertTrue(num.isIntegral);
		num = 0;
		assertTrue(num.isIntegral);
	}

	const bool isZeroCoefficient() {
		return !isSpecial && coefficient == 0;
	}

	unittest {
		BigDecimal num;
		num = 0;
		assertTrue(num.isZeroCoefficient);
		num = BigInt("-0");
		assertTrue(num.isZeroCoefficient);
		num = BigDecimal("0E+4");
		assertTrue(num.isZeroCoefficient);
		num = 12345;
		assertFalse(num.isZeroCoefficient);
		num = 1.5;
		assertFalse(num.isZeroCoefficient);
		num = BigDecimal.NAN;
		assertFalse(num.isZeroCoefficient);
		num = BigDecimal.INFINITY;
		assertFalse(num.isZeroCoefficient);
	}

//--------------------------------
// comparison
//--------------------------------

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
	const int opCmp(const BigDecimal that) {
		return compare!BigDecimal(this, that, bigContext);
	}

	unittest {
		BigDecimal num1, num2;
		num1 = 105;
		num2 = 10.543;
		assertTrue(num1 > num2);
		assertTrue(num2 < num1);
		num1 = 10.543;
		assertTrue(num1 >= num2);
		assertTrue(num2 <= num1);
	}

	/**
	 * Returns true if this number is equal to the specified BigDecimal.
	 * A NaN is not equal to any number, not even to another NaN.
	 * Infinities are equal if they have the same sign.
	 * Zeros are equal regardless of sign.
	 * Finite numbers are equal if they are numerically equal to the current precision.
	 * A BigDecimal may not be equal to itself (this != this) if it is a NaN.
	 */
	const bool opEquals (ref const BigDecimal that) {
		return equals!BigDecimal(this, that, bigContext);
	}

	unittest {
		BigDecimal num1, num2;
		num1 = 105;
		num2 = 10.543;
		assertTrue(num1 != num2);
		num1 = 10.543;
		assertTrue(num1 == num2);
	}

//--------------------------------
// unary arithmetic operators
//--------------------------------

	const BigDecimal opUnary(string op)()
	{
		static if (op == "+") {
			return plus!BigDecimal(this, bigContext);
		}
		else static if (op == "-") {
			return minus!BigDecimal(this, bigContext);
		}
		else static if (op == "++") {
			return add!BigDecimal(this, BigDecimal(1), bigContext);
		}
		else static if (op == "--") {
			return sub!BigDecimal(this, BigDecimal(1), bigContext);
		}
	}

	unittest {
		BigDecimal num, actual, expect;
		num = 134;
		expect = num;
		actual = +num;
		assertEqual!BigDecimal(expect, actual);
		num = 134.02;
		expect = -134.02;
		actual = -num;
		assertEqual!BigDecimal(expect, actual);
		num = 134;
		expect = 135;
		actual = ++num;
		assertEqual!BigDecimal(expect, actual);
		num = 1.00E8;
		expect = num - 1;
		actual = --num;
		assertEqual!BigDecimal(expect, actual);
		num = 1.00E8;
		expect = num;
		actual = num--;
		assertEqual!BigDecimal(expect, actual);
		num = BigDecimal(9999999, 90);
		expect = num;
		actual = num++;
		assertEqual!BigDecimal(expect, actual);
		num = 12.35;
		expect = 11.35;
		actual = --num;
		assertEqual!BigDecimal(expect, actual);
	}

//--------------------------------
//	binary arithmetic operators
//--------------------------------

	const BigDecimal opBinary(string op, T:BigDecimal)(const T rhs)
	{
		static if (op == "+") {
			return add!BigDecimal(this, rhs, bigContext);
		}
		else static if (op == "-") {
			return sub!BigDecimal(this, rhs, bigContext);
		}
		else static if (op == "*") {
			return mul!BigDecimal(this, rhs, bigContext);
		}
		else static if (op == "/") {
			return div!BigDecimal(this, rhs, bigContext);
		}
		else static if (op == "%") {
			return remainder!BigDecimal(this, rhs, bigContext);
		}
	}

	/**
	 * Detect whether T is promotable to decimal32 type.
	 */
	private template isPromotable(T) {
		enum bool isPromotable = is(T:ulong) || is(T:real);
	}

	const BigDecimal opBinary(string op, T)(const T rhs) if(isPromotable!T)	{
		return opBinary!(op,BigDecimal)(BigDecimal(rhs));
	}

	unittest {
		BigDecimal num = BigDecimal(591.3);
		BigDecimal result = num * 5;
		assertTrue(result == BigDecimal(2956.5));
	}

	unittest {
		BigDecimal op1, op2, actual, expect;
		op1 = 4;
		op2 = 8;
		actual = op1 + op2;
		expect = 12;
		assertEqual!BigDecimal(expect, actual);
		actual = op1 - op2;
		expect = -4;
		assertEqual!BigDecimal(expect, actual);
		actual = op1 * op2;
		expect = 32;
		assertEqual!BigDecimal(expect, actual);
		op1 = 5;
		op2 = 2;
		actual = op1 / op2;
		expect = 2.5;
		assertEqual!BigDecimal(expect, actual);
		op1 = 10;
		op2 = 3;
		actual = op1 % op2;
		expect = 1;
		assertEqual!BigDecimal(expect, actual);
	}

//-----------------------------
// operator assignment
//-----------------------------

	ref BigDecimal opOpAssign(string op) (BigDecimal rhs) {
		this = opBinary!op(rhs);
		return this;
	}

	unittest {
		BigDecimal op1, op2, actual, expect;
		op1 = 23.56;
		op2 = -2.07;
		op1 += op2;
		expect = 21.49;
		actual = op1;
		assertEqual!BigDecimal(expect, actual);
		op1 *= op2;
		expect = -44.4843;
		actual = op1;
		assertEqual!BigDecimal(expect, actual);
	}

//-----------------------------
// nextUp, nextDown, nextAfter
//-----------------------------

	const BigDecimal nextUp() {
		return nextPlus!BigDecimal(this, bigContext);
	}

	const BigDecimal nextDown() {
		return nextMinus!BigDecimal(this, bigContext);
	}

	const BigDecimal nextAfter(const BigDecimal num) {
		return nextToward!BigDecimal(this, num, bigContext);
	}

	unittest {
		BigDecimal big, expect;
		big = 123.45;
		assertTrue(big.nextUp == BigDecimal(123.450001));
		big = 123.45;
		assertTrue(big.nextDown == BigDecimal(123.449999));
		big = 123.45;
		expect = big.nextUp;
		assertTrue(big.nextAfter(BigDecimal(123.46)) == expect);
		big = 123.45;
		expect = big.nextDown;
		assertTrue(big.nextAfter(BigDecimal(123.44)) == expect);
	}

	/**
	 * Returns (BigInt) ten raised to the specified power.
	 */
	public static BigInt pow10(const int n) {
		BigInt num = 1;
		return decShl(num, n);
	}

	unittest {
		assertTrue(pow10(3) == 1000);
	}

}	 // end struct BigDecimal

unittest {
	writeln("-------------------");
	writeln("decimal.........end");
	writeln("-------------------");
}

