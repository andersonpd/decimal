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

module decimal.dec128;

import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;
import decimal.dec32;
import decimal.dec64;
import decimal.rounding;
import decimal.test;

unittest {
	writeln("===================");
	writeln("dec128.......testing");
	writeln("===================");
}

struct Dec128 {

private:
	// The total number of bits in the decimal number.
	// This is equal to the number of bits in the underlying integer;
	// (must be 32, 64, or 128).
	immutable uint bitLength = 64;

	// the number of bits in the sign bit (1, obviously)
	immutable uint signBit = 1;

	// The number of bits in the unsigned value of the decimal number.
	immutable uint unsignedBits = 63; // = bitLength - signBit;

	// The number of bits in the (biased) exponent.
	immutable uint expoBits = 10;

	// The number of bits in the coefficient when the value is
	// explicitly represented.
	immutable uint explicitBits = 53;

	// The number of bits used to indicate special values and implicit
	// representation
	immutable uint testBits = 2;

	// The number of bits in the coefficient when the value is implicitly
	// represented. The three missing bits (the most significant bits)
	// are always '100'.
	immutable uint implicitBits = 51; // = explicitBits - testBits;

	// The number of special bits, including the two test bits.
	// These bits are used to denote infinities and NaNs.
	immutable uint specialBits = 4;

	// The number of bits that follow the special bits.
	// Their number is the number of bits in a special value
	// when the others (sign and special) are accounted for.
	immutable uint spclPadBits = 59;
	// = bitLength - specialBits - signBit;

	// The number of infinity bits, including the special bits.
	// These bits are used to denote infinity.
	immutable uint infinityBits = 5;

	// The number of bits that follow the special bits in infinities.
	// These bits are always set to zero in canonical representations.
	// Their number is the remaining number of bits in an infinity
	// when all others (sign and infinity) are accounted for.
	immutable uint infPadBits = 58;
	// = bitLength - infinityBits - signBit;

	// The number of nan bits, including the special bits.
	// These bits are used to denote NaN.
	immutable uint nanBits = 6;

	// The number of bits in the payload of a NaN.
	immutable uint payloadBits = 16;

	// The number of bits that follow the nan bits in NaNs.
	// These bits are always set to zero in canonical representations.
	// Their number is the remaining number of bits in a NaN
	// when all others (sign, nan and payload) are accounted for.
	immutable uint nanPadBits = 41;
	// = bitLength - payloadBits - specialBits - signBit;

	// length of the coefficient in decimal digits.
	immutable int PRECISION = 16;
	// The maximum coefficient that fits in an explicit number.
	immutable ulong C_MAX_EXPLICIT = 0x1FFFFFFFFFFFFF;  // = 36028797018963967
	// The maximum coefficient allowed in an implicit number.
	immutable ulong C_MAX_IMPLICIT = 9999999999999999;  // = 0x2386F26FC0FFFF
	// masks for coefficients
	immutable ulong C_IMPLICIT_MASK = 0x1FFFFFFFFFFFFF;
	immutable ulong C_EXPLICIT_MASK = 0x7FFFFFFFFFFFF;

	// The maximum unbiased exponent. The largest binary number that can fit
	// in the width of the exponent field without setting
	// either of the first two bits to 1.
	immutable uint MAX_EXPO = 0x2FF; // = 767
	// The exponent bias. The exponent is stored as an unsigned number and
	// the bias is subtracted from the unsigned value to give the true
	// (signed) exponent.
	immutable int BIAS = 398;		 // = 0x65
	// The maximum representable exponent.
	immutable int E_LIMIT = 369;	 // MAX_EXPO - BIAS
	// The min and max adjusted exponents.
	immutable int E_MAX =  386; 	 // E_LIMIT + C_LENGTH - 1
	immutable int E_MIN = -385; 	 // = 1 - E_MAX

	/// The context for this type.
	private static DecimalContext
	context128 = DecimalContext(PRECISION, E_MAX, Rounding.HALF_EVEN);

	// union providing different views of the number representation.
	union {

		// entire 64-bit unsigned integer
		ulong intBits = SV.POS_NAN;    // set to the initial value: NaN

		// unsigned value and sign bit
		mixin (bitfields!(
			ulong, "uBits", unsignedBits,
			bool, "signed", signBit)
		);
		// Ex = explicit finite number:
		//	   full coefficient, exponent and sign
		mixin (bitfields!(
			ulong, "mantEx", explicitBits,
			uint, "expoEx", expoBits,
			bool, "signEx", signBit)
		);
		// Im = implicit finite number:
		//		partial coefficient, exponent, test bits and sign bit.
		mixin (bitfields!(
			ulong, "mantIm", implicitBits,
			uint, "expoIm", expoBits,
			uint, "testIm", testBits,
			bool, "signIm", signBit)
		);
		// Spcl = special values: non-finite numbers
		//		unused bits, special bits and sign bit.
		mixin (bitfields!(
			ulong, "padSpcl",  spclPadBits,
			uint, "testSpcl", specialBits,
			bool, "signSpcl", signBit)
		);
		// Inf = infinities:
		//		payload, unused bits, infinitu bits and sign bit.
		mixin (bitfields!(
			uint, "padInf",  infPadBits,
			ulong, "testInf", infinityBits,
			bool, "signInf", signBit)
		);
		// Nan = not-a-number: qNaN and sNan
		//		payload, unused bits, nan bits and sign bit.
		mixin (bitfields!(
			ushort, "pyldNaN", payloadBits,
			ulong, "padNaN",  nanPadBits,
			uint, "testNaN", nanBits,
			bool, "signNaN", signBit)
		);
	}

	// (128)TODO: Move this test to test.d?
	unittest {
		Dec128 num;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.pyldNaN = 1;
		// NOTE: this test should fail when bitmanip is fixed.
		assertTrue(num.toHexString != "0x7C00000000000001");
		assertTrue(num.toHexString == "0x0000000000000001");
		num.bits = ulong.max;
		assertTrue(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num.pyldNaN = 2;
		// NOTE: this test should fail when bitmanip is fixed.
		assertTrue(num.toHexString != "0xFFFFFFFFFFFF0002");
		assertTrue(num.toHexString == "0x00000000FFFF0002");
		num.bits = ulong.max;
		assertTrue(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num.testNaN = 0b10;
		assertTrue(num.toHexString == "0x85FFFFFFFFFFFFFF");
		num.bits = ulong.max;
		assertTrue(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.pyldNaN = ushort.max;
		// NOTE: this test should fail when bitmanip is fixed.
		assertTrue(num.toHexString == "0x000000000000FFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.padInf = ushort.max;
		// NOTE: This works as expected;
		assertTrue(num.toHexString == "0x7C0000000000FFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.padSpcl = ushort.max;
		assertTrue(num.toHexString == "0x780000000000FFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.bits = num.bits | 0xFFFF;
		assertTrue(num.toHexString == "0x7C0000000000FFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.mantEx = uint.max;
		assertTrue(num.toHexString == "0x7C000000FFFFFFFF");
		num = nan;
		assertTrue(num.toHexString == "0x7C00000000000000");
		num.mantIm = uint.max;
		assertTrue(num.toHexString == "0x7C000000FFFFFFFF");
	}

//--------------------------------
//	special values
//--------------------------------

private:
	// The value of the (6) special bits when the number is a signaling NaN.
	immutable uint SIG_VAL = 0x3F;
	// The value of the (6) special bits when the number is a quiet NaN.
	immutable uint NAN_VAL = 0x3E;
	// The value of the (5) special bits when the number is infinity.
	immutable uint INF_VAL = 0x1E;

//--------------------------------
//	special values and constants
//--------------------------------

// (128)TODO: this needs to be cleaned up -- SV is not the best name
private:
	static enum SV : ulong
	{
		// The value corresponding to a positive signaling NaN.
		POS_SIG = 0x7E00000000000000,
		// The value corresponding to a negative signaling NaN.
		NEG_SIG = 0xFE00000000000000,

		// The value corresponding to a positive quiet NaN.
		POS_NAN = 0x7C00000000000000,
		// The value corresponding to a negative quiet NaN.
		NEG_NAN = 0xFC00000000000000,

		// The value corresponding to positive infinity.
		POS_INF = 0x7800000000000000,
		// The value corresponding to negative infinity.
		NEG_INF = 0xF800000000000000,

		// The value corresponding to positive zero. (+0)
		POS_ZRO = 0x31C0000000000000,
		// The value corresponding to negative zero. (-0)
		NEG_ZRO = 0xB1C0000000000000,

		// The value of the largest representable positive number.
		POS_MAX = 0x77FB86F26FC0FFFF, //  0x77F8967FFFFFFFFF (128)TODO: why is this different?
		// The value of the largest representable negative number.
		NEG_MAX = 0xF7FB86F26FC0FFFF
/*	Dec128 diff
		// common small integers
		POS_ONE = 0x32800001,
		NEG_ONE = 0xB2800001,
		POS_TWO = 0x32800002,
		NEG_TWO = 0xB2800002,
		POS_FIV = 0x32800005,
		NEG_FIV = 0xB2800005,
		POS_TEN = 0x3280000A,
		NEG_TEN = 0xB280000A,

		// pi and related values
		PI		 = 0x2FAFEFD9,
		TAU 	 = 0x2FDFDFB2,
		PI_2	 = 0x2F97F7EC,
		PI_SQR	 = 0x6BF69924,
		SQRT_PI  = 0x2F9B0BA6,
		SQRT_2PI = 0x2F9B0BA6,
		// 1/PI
		// 1/SQRT_PI
		// 1/SQRT_2PI

		PHI 	= 0x2F98B072,
		GAMMA	= 0x2F58137D,

		// logarithms
		E		= 0x2FA97A4A,
		LOG2_E	= 0x2F960387,
		LOG10_E = 0x2F4244A1,
		LN2 	= 0x2F69C410,
		LOG10_2 = 0x30007597,
		LN10	= 0x2FA32279,
		LOG2_10 = 0x2FB2B048,

		// roots and squares of common values
		SQRT2	= 0x2F959446,
		SQRT1_2 = 0x2F6BE55C
	}

*/	}

public:
	immutable Dec128 NAN 	 = Dec128(SV.POS_NAN);
	immutable Dec128 SNAN	 = Dec128(SV.POS_SIG);
	immutable Dec128 INFINITY = Dec128(SV.POS_INF);
	immutable Dec128 NEG_INF  = Dec128(SV.NEG_INF);
	immutable Dec128 ZERO	 = Dec128(SV.POS_ZRO);
	immutable Dec128 NEG_ZERO = Dec128(SV.NEG_ZRO);
	immutable Dec128 MAX 	 = Dec128(SV.POS_MAX);
	immutable Dec128 NEG_MAX  = Dec128(SV.NEG_MAX);
	immutable Dec128 ONE 	 = Dec128( 1);
	immutable Dec128 NEG_ONE  = Dec128(-1);

/*	Dec128 diff
	// small integers
	immutable Dec128 ONE 	 = Dec128(SV.POS_ONE);
	immutable Dec128 NEG_ONE  = Dec128(SV.NEG_ONE);
	immutable Dec128 TWO 	 = Dec128(SV.POS_TWO);
	immutable Dec128 NEG_TWO  = Dec128(SV.NEG_TWO);
	immutable Dec128 FIVE	 = Dec128(SV.POS_FIV);
	immutable Dec128 NEG_FIVE = Dec128(SV.NEG_FIV);
	immutable Dec128 TEN 	 = Dec128(SV.POS_TEN);
	immutable Dec128 NEG_TEN  = Dec128(SV.NEG_TEN);

	// mathamatical constants
	immutable Dec128 TAU 	 = Dec128(SV.TAU);
	immutable Dec128 PI		 = Dec128(SV.PI);
	immutable Dec128 PI_2	 = Dec128(SV.PI_2);
	immutable Dec128 PI_SQR	 = Dec128(SV.PI_SQR);
	immutable Dec128 SQRT_PI  = Dec128(SV.SQRT_PI);
	immutable Dec128 SQRT_2PI = Dec128(SV.SQRT_2PI);

	immutable Dec128 E		 = Dec128(SV.E);
	immutable Dec128 LOG2_E	 = Dec128(SV.LOG2_E);
	immutable Dec128 LOG10_E  = Dec128(SV.LOG10_E);
	immutable Dec128 LN2 	 = Dec128(SV.LN2);
	immutable Dec128 LOG10_2  = Dec128(SV.LOG10_2);
	immutable Dec128 LN10	 = Dec128(SV.LN10);
	immutable Dec128 LOG2_10  = Dec128(SV.LOG2_10);
	immutable Dec128 SQRT2	 = Dec128(SV.SQRT2);
	immutable Dec128 PHI 	 = Dec128(SV.PHI);
	immutable Dec128 GAMMA	 = Dec128(SV.GAMMA);
*/
	// boolean constants
	immutable Dec128 TRUE	 = ONE;
	immutable Dec128 FALSE	 = ZERO;

//--------------------------------
//	constructors
//--------------------------------

	/**
	 * Creates a Dec128 from a special value.
	 */
	private this(const SV sv) {
		intBits = sv;
	}

	// this unit test uses private values
	unittest {
		Dec128 num;
		num = Dec128(SV.POS_SIG);
		assertTrue(num.isSignaling);
		assertTrue(num.isNaN);
		assertTrue(!num.isNegative);
		assertTrue(!num.isNormal);
		num = Dec128(SV.NEG_SIG);
		assertTrue(num.isSignaling);
		assertTrue(num.isNaN);
		assertTrue(num.isNegative);
		assertTrue(!num.isNormal);
		num = Dec128(SV.POS_NAN);
		assertTrue(!num.isSignaling);
		assertTrue(num.isNaN);
		assertTrue(!num.isNegative);
		assertTrue(!num.isNormal);
		num = Dec128(SV.NEG_NAN);
		assertTrue(!num.isSignaling);
		assertTrue(num.isNaN);
		assertTrue(num.isNegative);
		assertTrue(num.isQuiet);
		num = Dec128(SV.POS_INF);
		assertTrue(num.isInfinite);
		assertTrue(!num.isNaN);
		assertTrue(!num.isNegative);
		assertTrue(!num.isNormal);
		num = Dec128(SV.NEG_INF);
		assertTrue(!num.isSignaling);
		assertTrue(num.isInfinite);
		assertTrue(num.isNegative);
		assertTrue(!num.isFinite);
		num = Dec128(SV.POS_ZRO);
		assertTrue(num.isFinite);
		assertTrue(num.isZero);
		assertTrue(!num.isNegative);
		assertTrue(num.isNormal);
		num = Dec128(SV.NEG_ZRO);
		assertTrue(!num.isSignaling);
		assertTrue(num.isZero);
		assertTrue(num.isNegative);
		assertTrue(num.isFinite);
	}

	/**
	 * Creates a Dec128 from a long integer.
	 */
	public this(const long n) {
		this = zero;
		signed = n < 0;
		coefficient = std.math.abs(n);
	}

/*	Dec128 diff
	unittest {
		real L10_2 = std.math.log10(2.0);
		Dec128 LOG10_2 = Dec128(L10_2);
		writeln("L10_2 = ", L10_2);
		writeln("LOG10_2 = ", LOG10_2);
		writeln("LOG10_2.toHexString = ", LOG10_2.toHexString);
		real L2T = std.math.log2(10.0);
		Dec128 LOG2_10 = Dec128(L2T);
		writeln("L2T = ", L2T);
		writeln("LOG2_10 = ", LOG2_10);
		writeln("LOG2_10.toHexString = ", LOG2_10.toHexString);
		Dec128 num;
		num = Dec128(1234567890L);
		assertTrue(num.toString == "1.234568E+9");
		num = Dec128(0);
		assertTrue(num.toString == "0");
		num = Dec128(1);
		assertTrue(num.toString == "1");
		num = Dec128(-1);
		assertTrue(num.toString == "-1");
		num = Dec128(5);
		assertTrue(num.toString == "5");
	}
*/
	/**
	 * Creates a Dec128 from a boolean value.
	 */
	public this(const bool value) {
		this = zero;
		if (value) {
			coefficient = 1;
		}
	}

/*	Dec128 diff
	unittest {
		Dec128 num;
		num = Dec128(1234567890L);
		assertTrue(num.toString == "1234567890"); //1.234567890E+9");
		num = Dec128(0);
		assertTrue(num.toString == "0");
		num = Dec128(1);
		assertTrue(num.toString == "1");
		num = Dec128(-1);
		assertTrue(num.toString == "-1");
		num = Dec128(5);
		assertTrue(num.toString == "5");
	}
*/
	/**
	 * Creates a Dec128 from an long integer and an integer exponent.
	 */
	public this(const long mant, const int expo) {
		this(mant);
		exponent = exponent + expo;
	}

	unittest {
		Dec128 num;
		num = Dec128(1234567890L, 5);
		assertTrue(num.toString == "1.234567890E+14");
		num = Dec128(0, 2);
		assertTrue(num.toString == "0E+2");
		num = Dec128(1, 75);
		assertTrue(num.toString == "1E+75");
		num = Dec128(-1, -75);
		assertTrue(num.toString == "-1E-75");
		num = Dec128(5, -3);
		assertTrue(num.toString == "0.005");
		num = Dec128(true, 1234567890L, 5);
		assertTrue(num.toString == "-1.234567890E+14");
		num = Dec128(0, 0, 2);
		assertTrue(num.toString == "0E+2");
	}

	/**
	 * Creates a Dec128 from a boolean sign, an unsigned long integer,
	 * and an integer exponent.
	 */
	public this(const bool sign, const ulong mant, const int expo) {
		this(mant, expo);
		signed = sign;
	}

	unittest {
		Dec128 num;
		num = Dec128(1234567890L, 5);
		assertTrue(num.toString == "1.234567890E+14");
		num = Dec128(0, 2);
		assertTrue(num.toString == "0E+2");
		num = Dec128(1, 75);
		assertTrue(num.toString == "1E+75");
		num = Dec128(-1, -75);
		assertTrue(num.toString == "-1E-75");
		num = Dec128(5, -3);
		assertTrue(num.toString == "0.005");
		num = Dec128(true, 1234567890L, 5);
		assertTrue(num.toString == "-1.234567890E+14");
		num = Dec128(0, 0, 2);
		assertTrue(num.toString == "0E+2");
	}

	/**
	 * Creates a Dec128 from a BigDecimal
	 */
	public this(const BigDecimal num) {

		// check for special values
		if (num.isInfinite) {
			this = infinity(num.sign);
			return;
		}
		if (num.isQuiet) {
			this = nan();
			this.sign = num.sign;
			this.payload = num.payload;
			return;
		}
		if (num.isSignaling) {
			this = snan();
			this.sign = num.sign;
			this.payload = num.payload;
			return;
		}

		BigDecimal big = plus!BigDecimal(num, context128);

		if (big.isFinite) {
			this = zero;
			this.coefficient = cast(ulong)big.coefficient.toLong;
			this.exponent = big.exponent;
			this.sign = big.sign;
			return;
		}
		// check again for special values
		if (big.isInfinite) {
			this = infinity(big.sign);
			return;
		}
		if (big.isSignaling) {
			this = snan();
			this.payload = big.payload;
			return;
		}
		if (big.isQuiet) {
			this = nan();
			this.payload = big.payload;
			return;
		}
		this = nan;
	}

	unittest {
		BigDecimal dec = 0;
		Dec128 num = dec;
		assertTrue(dec.toString == num.toString);
		dec = 1;
		num = dec;
		assertTrue(dec.toString == num.toString);
		dec = -1;
		num = dec;
		assertTrue(dec.toString == num.toString);
		dec = -16000;
		num = dec;
		assertTrue(dec.toString == num.toString);
		dec = uint.max;
		num = dec;
		assertTrue(num.toString == "4294967295");
		assertTrue(dec.toString == "4294967295");
		dec = 9999999E+12;
		num = dec;
		assertTrue(dec.toString == num.toString);
	}

	/**
	 * Creates a Dec128 from a string.
	 */
	public this(const string str) {
		BigDecimal big = BigDecimal(str);
		this(big);
	}

	unittest {
		Dec128 num;
		num = Dec128("1.234568E+9");
		assertTrue(num.toString == "1.234568E+9");
		num = Dec128("NaN");
		assertTrue(num.isQuiet && num.isSpecial && num.isNaN);
		num = Dec128("-inf");
		assertTrue(num.isInfinite && num.isSpecial && num.isNegative);
	}

	/**
	 *	  Constructs a number from a real value.
	 */
	public this(const real r) {
		// check for special values
		if (!std.math.isFinite(r)) {
			this = std.math.isInfinity(r) ? INFINITY : NAN;
			this.sign = cast(bool)std.math.signbit(r);
			return;
		}
		// (128)TODO: this won't do -- no rounding has occured.
		string str = format("%.*G", cast(int)context128.precision, r);
		this(str);
	}

	unittest {
		float f = 1.2345E+16f;
		Dec128 actual = Dec128(f);
		Dec128 expect = Dec128("1.234499980283085E+16");
		assertEqual(expect,actual);
		real r = 1.2345E+16;
		actual = Dec128(r);
		expect = Dec128("1.2345E+16");
		assertEqual(expect,actual);
	}

	/**
	 * Copy constructor.
	 */
	public this(const Dec128 that) {
		this.bits = that.bits;
	}

	/**
	 * Duplicator.
	 */
	public const Dec128 dup() {
		return Dec128(this);
	}

//--------------------------------
//	properties
//--------------------------------

public:

	/// Returns the raw bits of this number.
	@property
	const ulong bits() {
		return intBits;
	}

	/// Sets the raw bits of this number.
	@property
	ulong bits(const ulong raw) {
		intBits = raw;
		return intBits;
	}

	/// Returns the sign of this number.
	@property
	const bool sign() {
		return signed;
	}

	/// Sets the sign of this number and returns the sign.
	@property
	bool sign(const bool value) {
		signed = value;
		return signed;
	}

	/// Returns the exponent of this number.
	/// The exponent is undefined for infinities and NaNs: zero is returned.
	@property
	const int exponent() {
		if (this.isExplicit) {
			return expoEx - BIAS;
		}
		if (this.isImplicit) {
			return expoIm - BIAS;
		}
		// infinity or NaN.
		return 0;
	}

	unittest {
		Dec128 num;
		int expected, actual;
		// reals
		num = std.math.PI;
		expected = -15;
		actual = num.exponent;
		assertEqual(expected, actual);
		num = 9.75E9;
		expected = 0;
		actual = num.exponent;
		assertEqual(expected, actual);
		// explicit
		num = 8388607;
		expected = 0;
		actual = num.exponent;
		assertEqual(expected, actual);
		// implicit
		num = 8388610;
		expected = 0;
		actual = num.exponent;
		assertEqual(expected, actual);
		num = 9.999998E23;
		expected = 17;
		actual = num.exponent;
		assertEqual(expected, actual);
		num = 9.999999E23;
		expected = 8;
		actual = num.exponent;
		assertEqual(expected, actual);
	}

	/// Sets the exponent of this number.
	/// If this number is infinity or NaN, this number is converted to
	/// a quiet NaN and the invalid operation flag is set.
	/// Otherwise, if the input value exceeds the maximum allowed exponent,
	/// this number is converted to infinity and the overflow flag is set.
	/// If the input value is less than the minimum allowed exponent,
	/// this number is converted to zero, the exponent is set to tinyExpo
	/// and the underflow flag is set.
	@property
	int exponent(const int expo) {
		// check for overflow
		if (expo > context128.maxExpo) {
			this = signed ? NEG_INF : INFINITY;
			contextFlags.setFlags(OVERFLOW);
			return 0;
		}
		// check for underflow
		if (expo < context128.minExpo) {
			// if the exponent is too small even for a subnormal number,
			// the number is set to zero.
			if (expo < context128.tinyExpo) {
				this = signed ? NEG_ZERO : ZERO;
				expoEx = context128.tinyExpo + BIAS;
				contextFlags.setFlags(SUBNORMAL);
				contextFlags.setFlags(UNDERFLOW);
				return context128.tinyExpo;
			}
			// at this point the exponent is between minExpo and tinyExpo.
			// (128)TODO: I don't think this needs special handling
		}
		// if explicit...
		if (this.isExplicit) {
			expoEx = expo + BIAS;
			return expoEx;
		}
		// if implicit...
		if (this.isFinite) {
			expoIm = expo + BIAS;
			return expoIm;
		}
		// if this point is reached the number is either infinity or NaN;
		// these have undefined exponent values.
		contextFlags.setFlags(INVALID_OPERATION);
		this = nan;
		return 0;
	}

	unittest {
		Dec128 num;
		num = Dec128(-12000,5);
		num.exponent = 10;
		assertTrue(num.exponent == 10);
		num = Dec128(-9000053,-14);
		num.exponent = -27;
		assertTrue(num.exponent == -27);
		num = infinity;
		assertTrue(num.exponent == 0);
	}

	/// Returns the coefficient of this number.
	/// The exponent is undefined for infinities and NaNs: zero is returned.
	@property
	const ulong coefficient() {
		if (this.isExplicit) {
			return mantEx;
		}
		if (this.isFinite) {
			return mantIm | (4UL << implicitBits);
		}
		// Infinity or NaN.
		return 0;
	}

	// Sets the coefficient of this number. This may cause an
	// explicit number to become an implicit number, and vice versa.
	@property
	ulong coefficient(const ulong mant) {
		// if not finite, convert to NaN and return 0.
		if (!this.isFinite) {
			this = nan;
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		ulong copy = mant;
		// if too large for explicit representation, round
		if (copy > C_MAX_IMPLICIT) {
			int expo = 0;
			uint digits = numDigits(copy);
			expo = setExponent(sign, copy, digits, context128);
			if (this.isExplicit) {
				expoEx = expoEx + expo;
			}
			else {
				expoIm = expoIm + expo;
			}
		}
		// at this point, the number <= C_MAX_IMPLICIT
		if (copy <= C_MAX_EXPLICIT) {
			// if implicit, convert to explicit
			if (this.isImplicit) {
				expoEx = expoIm;
			}
			mantEx = cast(ulong)copy;
			return mantEx;
		}
		else {	// copy <= C_MAX_IMPLICIT
			// if explicit, convert to implicit
			if (this.isExplicit) {
				expoIm = expoEx;
				testIm = 0x3;
			}
			mantIm = cast(ulong)copy & C_IMPLICIT_MASK;
			return mantIm | (0b100UL << implicitBits);
		}
	}

	unittest {
		Dec128 num;
		assertTrue(num.coefficient == 0);
		num = 9.998742;
		assertTrue(num.coefficient == 9998742);
		num = 9.998743;
		assertTrue(num.coefficient == 9998742999999999);
		// note the difference between real and string values!
		num = Dec128("9.998743");
		assertTrue(num.coefficient == 9998743);
		num = Dec128(9999213,-6);
		assertTrue(num.coefficient == 9999213);
		num = -125;
		assertTrue(num.coefficient == 125);
		num = -99999999;
		assertTrue(num.coefficient == 99999999);
	}

	/// Returns the number of digits in this number's coefficient.
	@property
	const int digits() {
		return numDigits(this.coefficient);
	}

	/// Has no effect.
	@property
	const int digits(const int digs) {
		return digits;
	}

	/// Returns the payload of this number.
	/// If this is a NaN, returns the value of the payload bits.
	/// Otherwise returns zero.
	@property
	const ushort payload() {
		if (this.isNaN) {
			return pyldNaN;
		}
		return 0;
	}

	// (128)TODO: need to ensure this won't overflow into other bits.
	/// Sets the payload of this number.
	/// If the number is not a NaN (har!) no action is taken and zero
	/// is returned.
	@property
	ushort payload(const ushort value) {
		if (this.isNaN) {
			// NOTE: hack because bitmanip is broken
			this.bits = bits & 0xFFFFFFFFFFFF0000;
			this.bits = bits | value;
			return pyldNaN;
		}
		return 0;
	}

	unittest {
		Dec128 num;
		assertTrue(num.payload == 0);
		num = snan;
		assertTrue(num.payload == 0);
		num.payload = 234;
		assertTrue(num.payload == 234);
		assertTrue(num.toString == "sNaN234");
		num = 1234567;
		assertTrue(num.payload == 0);
	}

//--------------------------------
//	constants
//--------------------------------

	static Dec128 zero(const bool signed = false) {
		return signed ? NEG_ZERO : ZERO;
	}

	static Dec128 max(const bool signed = false) {
		return signed ? NEG_MAX : MAX;
	}

	static Dec128 infinity(const bool signed = false) {
		return signed ? NEG_INF : INFINITY;
	}

	static Dec128 nan(const ushort payload = 0) {
		if (payload) {
			Dec128 result = NAN;
			result.payload = payload;
			return result;
		}
		return NAN;
	}

	static Dec128 snan(const ushort payload = 0) {
		if (payload) {
			Dec128 result = SNAN;
			result.payload = payload;
			return result;
		}
		return SNAN;
	}


	// floating point properties
	static Dec128 init() 	  {
		return NAN;
	}
	static Dec128 epsilon()	  {
		return Dec128(1, -context128.precision);
	}
//	static Dec128 min_normal() {
//		return Dec128(1, context128.minExpo);
//	}
	static Dec128 min()		  {
		return Dec128(1, context128.minExpo);
	} //context128.tinyExpo); }

/* dec32diff
	static Dec128 init() 	  { return NAN; }
	static Dec128 epsilon()	  { return Dec128(1, -7); }
	static Dec128 min()		  { return Dec128(1, context32.tinyExpo); }

	static int dig()		{ return 7; }
	static int mant_dig()	{ return 24; }
	static int max_10_exp() { return context32.maxExpo; }
	static int min_10_exp() { return context32.minExpo; }
	static int max_exp()	{ return cast(int)(context32.maxExpo/LOG2); }
	static int min_exp()	{ return cast(int)(context32.minExpo/LOG2); }

	/// Returns the maximum number of decimal digits in this context.
	static uint precision(const DecimalContext context = context32) {
		return context.precision;
	}
*/
	/*	static int dig()		{ return context128.precision; }
		static int mant_dig()	{ return cast(int)context128.mant_dig;; }
		static int max_10_exp() { return context128.maxExpo; }
		static int min_10_exp() { return context128.minExpo; }
		static int max_exp()	{ return cast(int)(context128.maxExpo/LOG2); }
		static int min_exp()	{ return cast(int)(context128.minExpo/LOG2); }*/

	/// Returns the maximum number of decimal digits in this context.
	static uint precision() {
		return context128.precision;
	}


	/*	  /// Returns the maximum number of decimal digits in this context.
		static uint dig(const DecimalContext context = context128) {
			return context.precision;
		}

		/// Returns the number of binary digits in this context.
		static uint mant_dig(const DecimalContext context = context128) {
			return cast(int)context.mant_dig;
		}

		static int min_exp(const DecimalContext context = context128) {
			return context.min_exp;
		}

		static int max_exp(const DecimalContext context = context128) {
			return context.max_exp;
		}

//		/// Returns the minimum representable normal value in this context.
//		static Dec128 min_normal(const DecimalContext context = context128) {
//			return Dec128(1, context.minExpo);
//		}

		/// Returns the minimum representable subnormal value in this context.
		static Dec128 min(const DecimalContext context = context128) {
			return Dec128(1, context.tinyExpo);
		}

		/// returns the smallest available increment to 1.0 in this context
		static Dec128 epsilon(const DecimalContext context = context128) {
			return Dec128(1, -context.precision);
		}

		static int min_10_exp(const DecimalContext context = context128) {
			return context.minExpo;
		}

		static int max_10_exp(const DecimalContext context = context128) {
			return context.maxExpo;
		}*/

	/// Returns the radix (10)
	immutable int radix = 10;

//--------------------------------
//	classification properties
//--------------------------------

	/**
	 * Returns true if this number's representation is canonical.
	 * Finite numbers are always canonical.
	 * Infinities and NaNs are canonical if their unused bits are zero.
	 */
	const bool isCanonical() {
		if (isInfinite) return padInf == 0;
		if (isNaN) return signed == 0 && padNaN == 0;
		// finite numbers are always canonical
		return true;
	}

	/**
	 * Returns true if this number's representation is canonical.
	 * Finite numbers are always canonical.
	 * Infinities and NaNs are canonical if their unused bits are zero.
	 */
	const Dec128 canonical() {
		Dec128 copy = this;
		if (this.isCanonical) return copy;
		if (this.isInfinite) {
			copy.padInf = 0;
			return copy;
		}
		else { /* isNaN */
			copy.signed = 0;
			copy.padNaN = 0;
			return copy;
		}
	}

	/**
	 * Returns true if this number is +\- zero.
	 */
	const bool isZero() {
		return isExplicit && mantEx == 0;
	}

	/**
	 * Returns true if the coefficient of this number is zero.
	 */
	const bool coefficientIsZero() {
		return coefficient == 0;
	}

	/**
	 * Returns true if this number is a quiet or signaling NaN.
	 */
	const bool isNaN() {
		return testNaN == NAN_VAL || testNaN == SIG_VAL;
	}

	/**
	 * Returns true if this number is a signaling NaN.
	 */
	const bool isSignaling() {
		return testNaN == SIG_VAL;
	}

	/**
	 * Returns true if this number is a quiet NaN.
	 */
	const bool isQuiet() {
		return testNaN == NAN_VAL;
	}

	/**
	 * Returns true if this number is +\- infinity.
	 */
	const bool isInfinite() {
		return testInf == INF_VAL;
	}

	/**
	 * Returns true if this number is neither infinite nor a NaN.
	 */
	const bool isFinite() {
		return testSpcl != 0xF;
	}

	/**
	 * Returns true if this number is a NaN or infinity.
	 */
	const bool isSpecial() {
		return testSpcl == 0xF;
	}

	const bool isExplicit() {
		return testIm != 0x3;
	}

	const bool isImplicit() {
		return testIm == 0x3 && testSpcl != 0xF;
	}

	/**
	 * Returns true if this number is negative. (Includes -0)
	 */
	const bool isSigned() {
		return signed;
	}

	const bool isNegative() {
		return signed;
	}

	const bool isPositive() {
		return !isNegative;
	}

	const bool isTrue() {
		return coefficient != 0;
	}

	const bool isFalse() {
		return coefficient == 0;
	}

	const bool isZeroCoefficient() {
		return coefficient == 0;
	}
	/**
	 * Returns true if this number is subnormal.
	 */
	const bool isSubnormal(const DecimalContext context = context128) {
		if (isSpecial) return false;
		return adjustedExponent < context.minExpo;
	}

	/**
	 * Returns true if this number is normal.
	 */
	const bool isNormal(const DecimalContext context = context128) {
		if (isSpecial) return false;
		return adjustedExponent >= context.minExpo;
	}

	/**
	 * Returns true if this number is an integer.
	 */
	const bool isIntegral(const DecimalContext context = context128) {
		if (isSpecial) return false;
		if (exponent >= 0) return true;
		uint expo = std.math.abs(exponent);
		if (expo >= PRECISION) return false;
		if (coefficient % 10^^expo == 0) return true;
		return false;
	}

	unittest {
		Dec128 num;
		num = 22;
		assertTrue(num.isIntegral);
		num = 200E-2;
		assertTrue(num.isIntegral);
		num = 201E-2;
		assertTrue(!num.isIntegral);
		num = Dec128.INFINITY;
		assertTrue(!num.isIntegral);
	}

	/**
	 * Returns the value of the adjusted exponent.
	 */
	// (128)TODO: what if this is special?
	const int adjustedExponent() {
		return exponent + digits - 1;
	}

//--------------------------------
//	conversions
//--------------------------------

	/**
	 * Converts a Dec128 to a BigDecimal
	 */
	const BigDecimal toBigDecimal() {
		if (isFinite) {
			return BigDecimal(sign, BigInt(coefficient), exponent);
		}
		if (isInfinite) {
			return BigDecimal.infinity(sign);
		}
		// number is a NaN
		BigDecimal dec;
		if (isQuiet) {
			dec = BigDecimal.nan(sign);
		}
		if (isSignaling) {
			dec = BigDecimal.snan(sign);
		}
		if (payload) {
			dec.payload(payload);
		}
		return dec;
	}

	unittest {
		Dec128 num = Dec128("12345E+17");
		BigDecimal expected = BigDecimal("12345E+17");
		BigDecimal actual = num.toBigDecimal;
		assertTrue(actual == expected);
	}

	const int toInt() {
		int n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec128(int.max) || (isInfinite && !isSigned)) return int.max;
		if (this < Dec128(int.min) || (isInfinite &&  isSigned)) return int.min;
		quantize!Dec128(this, ONE, context128);
		n = cast(int)coefficient;
		return signed ? -n : n;
	}

	unittest {
		Dec128 num;
		num = 12345;
		assertTrue(num.toInt == 12345);
		num = 1.0E6;
		assertTrue(num.toInt == 1000000);
		num = -1.0E60;
		assertTrue(num.toInt == int.min);
		num = NEG_INF;
		assertTrue(num.toInt == int.min);
	}

	const long toLong() {
		long n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec128(long.max) || (isInfinite && !isSigned)) return long.max;
		if (this < Dec128(long.min) || (isInfinite &&  isSigned)) return long.min;
		quantize!Dec128(this, ONE, context128);
		n = coefficient;
		return signed ? -n : n;
	}

	unittest {
		Dec128 num;
		num = -12345;
		assertTrue(num.toLong == -12345);
		num = 2 * int.max;
		assertTrue(num.toLong == 2 * int.max);
		num = 1.0E6;
		assertTrue(num.toLong == 1000000);
		num = -1.0E60;
		assertTrue(num.toLong == long.min);
		num = NEG_INF;
		assertTrue(num.toLong == long.min);
	}

	public real toReal() {
		if (isNaN) {
			return real.nan;
		}
		if (isInfinite) {
			return isNegative ? -real.infinity : real.infinity;
		}
		if (isZero) {
			return isNegative ? -0.0 : 0.0;
		}
		string str = this.toSciString;
		return to!real(str);
	}

	unittest {
		write("toReal...");
		Dec128 num;
		real expect, actual;
		num = Dec128(1.5);
		expect = 1.5;
		actual = num.toReal;
		assertEqual(expect, actual);
		writeln("passed");
	}

	/**
	 * Converts this number to an exact scientific-style string representation.
	 */
	const string toSciString() {
		return decimal.conv.sciForm!Dec128(this);
	}

	/**
	 * Converts this number to an exact engineering-style string representation.
	 */
	const string toEngString() {
		return decimal.conv.engForm!Dec128(this);
	}

	/**
	 * Converts a Dec128 to a string
	 */
	const public string toString() {
		return toSciString();
	}

	unittest {
		string str;
		str = "-12.345E-42";
		Dec128 num = Dec128(str);
		assertTrue(num.toString == "-1.2345E-41");
	}

	/**
	 * Creates an exact representation of this number.
	 */
	const string toExact() {
		return decimal.conv.toExact!Dec128(this);
	}


	unittest {
		Dec128 num;
		assertTrue(num.toExact == "+NaN");
		num = Dec128.max;
		assertTrue(num.toExact == "+9999999999999999E+369");
		num = Dec128.min;
		num = 1;
		assertTrue(num.toExact == "+1E+00");
		num = C_MAX_EXPLICIT;
		assertTrue(num.toExact == "+9007199254740991E+00");
		num = C_MAX_IMPLICIT;
		assertTrue(num.toExact == "+9999999999999999E+00");
		num = infinity(true);
		assertTrue(num.toExact == "-Infinity");
	}

	/**
	 * Creates an abstract representation of this number.
	 */
	const string toAbstract() {
		if (this.isFinite) {
			return format("[%d,%s,%d]", signed ? 1 : 0, coefficient, exponent);
		}
		if (this.isInfinite) {
			return format("[%d,%s]", signed ? 1 : 0, "inf");
		}
		if (this.isQuiet) {
			if (payload) {
				return format("[%d,%s,%d]", signed ? 1 : 0, "qNaN", payload);
			}
			return format("[%d,%s]", signed ? 1 : 0, "qNaN");
		}
		// this.isSignaling
		if (payload) {
			return format("[%d,%s,%d]", signed ? 1 : 0, "sNaN", payload);
		}
		return format("[%d,%s]", signed ? 1 : 0, "sNaN");
	}

	unittest {
		Dec128 num;
		num = Dec128("-25.67E+2");
		assertTrue(num.toAbstract == "[1,2567,0]");
	}

	/**
	 * Converts this number to a hexadecimal string representation.
	 */
	const string toHexString() {
		return format("0x%016X", bits);
	}

	/**
	 * Converts this number to a binary string representation.
	 */
	const string toBinaryString() {
		return format("%0#64b", bits);
	}

	unittest {
		Dec128 num = 12345;
		assertTrue(num.toHexString == "0x31C0000000003039");
		assertTrue(num.toBinaryString ==
		"0011000111000000000000000000000000000000000000000011000000111001");
	}

//--------------------------------
//	comparison
//--------------------------------

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
const int opCmp(T:Dec128)(const T that) {
		return compare!Dec128(this, that, context128);
	}

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
	const int opCmp(T)(const T that) if (isPromotable!T) {
		return opCmp!Dec128(Dec128(that));
	}

	unittest {
		Dec128 a, b;
		a = Dec128(104.0);
		b = Dec128(105.0);
		assertTrue(a < b);
		assertTrue(b > a);
	}

	/**
	 * Returns true if this number is equal to the specified number.
	 */
const bool opEquals(T:Dec128)(const T that) {
		// quick bitwise check
		if (this.bits == that.bits) {
			if (this.isFinite) return true;
			if (this.isInfinite) return true;
			if (this.isQuiet) return false;
			// let the main routine handle the signaling NaN
		}
		return equals!Dec128(this, that, context128);
	}

	unittest {
		Dec128 a, b;
		a = Dec128(105);
		b = Dec128(105);
		assertTrue(a == b);
	}
	/**
	 * Returns true if this number is equal to the specified number.
	 */
	const bool opEquals(T)(const T that) if (isPromotable!T) {
		return opEquals!Dec128(Dec128(that));
	}

	unittest {
		Dec128 a, b;
		a = Dec128(105);
		b = Dec128(105);
		int c = 105;
		assertTrue(a == c);
		real d = 105.0;
		assertTrue(a == d);
		assertTrue(a == 105);
	}

	const bool isIdentical(const Dec128 that) {
		return this.bits == that.bits;
	}

//--------------------------------
// assignment
//--------------------------------

	// (128)TODO: flags?
	/// Assigns a Dec128 (copies that to this).
	void opAssign(T:Dec128)(const T that) {
		this.intBits = that.intBits;
	}

	unittest {
		Dec128 rhs, lhs;
		rhs = Dec128(270E-5);
		lhs = rhs;
		assertTrue(lhs == rhs);
	}

	// (128)TODO: flags?
	///    Assigns a numeric value.
	void opAssign(T)(const T that) {
		this = Dec128(that);
	}

	unittest {
		Dec128 rhs;
		rhs = 332089;
		assertTrue(rhs.toString == "332089");
		rhs = 3.1415E+3;
		assertTrue(rhs.toString == "3141.5");
	}

//--------------------------------
// unary operators
//--------------------------------

	const Dec128 opUnary(string op)() {
		static if (op == "+") {
			return plus!Dec128(this, context128);
		} else static if (op == "-") {
			return minus!Dec128(this, context128);
		} else static if (op == "++") {
			return add!Dec128(this, Dec128(1), context128);
		} else static if (op == "--") {
			return sub!Dec128(this, Dec128(1), context128);
		}
	}

	unittest {
		Dec128 num, actual, expect;
		num = 134;
		expect = num;
		actual = +num;
		assertTrue(actual == expect);
		num = 134.02;
		expect = -134.02;
		actual = -num;
		assertTrue(actual == expect);
		num = 134;
		expect = 135;
		actual = ++num;
		assertTrue(actual == expect);
		num = 1.00E8;
		expect = num;
		actual = num--;
		assertTrue(actual == expect);
		num = Dec128(9999999, 90);
		expect = num;
		actual = num++;
		assertTrue(actual == expect);
		num = 12.35;
		expect = 11.35;
		actual = --num;
		assertTrue(actual == expect);
	}

//--------------------------------
// binary operators
//--------------------------------

const T opBinary(string op, T:Dec128)(const T rhs)
//	  const Dec128 opBinary(string op)(const Dec128 rhs)
	{
		static if (op == "+") {
			return add!Dec128(this, rhs, context128);
		} else static if (op == "-") {
			return sub!Dec128(this, rhs, context128);
		} else static if (op == "*") {
			return mul!Dec128(this, rhs, context128);
		} else static if (op == "/") {
			return div!Dec128(this, rhs, context128);
		} else static if (op == "%") {
			return remainder!Dec128(this, rhs, context128);
		}
	}

	unittest {
		Dec128 op1, op2, actual, expect;
		op1 = 4;
		op2 = 8;
		actual = op1 + op2;
		expect = 12;
		assertEqual(expect,actual);
		actual = op1 - op2;
		expect = -4;
		assertEqual(expect,actual);
		actual = op1 * op2;
		expect = 32;
		assertEqual(expect,actual);
		op1 = 5;
		op2 = 2;
		actual = op1 / op2;
		expect = 2.5;
		assertEqual(expect,actual);
		op1 = 10;
		op2 = 3;
		actual = op1 % op2;
		expect = 1;
		assertEqual(expect,actual);
	}

	/**
	 * Detect whether T is a decimal type.
	 */
	private template isPromotable(T) {
		enum bool isPromotable = is(T:ulong) || is(T:real) ||
			is(T:Dec32) || is(T:Dec64);
	}

	const Dec128 opBinary(string op, T)(const T rhs) if (isPromotable!T) {
		return opBinary!(op,Dec128)(Dec128(rhs));
	}

	unittest {
		Dec128 num = Dec128(591.3);
		Dec128 result = num * 5;
		assertTrue(result == Dec128(2956.5));
	}

//-----------------------------
// operator assignment
//-----------------------------

ref Dec128 opOpAssign(string op, T:Dec128) (T rhs) {
		this = opBinary!op(rhs);
		return this;
	}

	ref Dec128 opOpAssign(string op, T) (T rhs) if (isPromotable!T) {
		this = opBinary!op(rhs);
		return this;
	}

	unittest {
		Dec128 op1, op2, actual, expect;
		op1 = 23.56;
		op2 = -2.07;
		op1 += op2;
		expect = 21.49;
		actual = op1;
		assertEqual(expect,actual);
		op1 *= op2;
		expect = -44.4843;
		actual = op1;
		assertEqual(expect,actual);
		op1 = 95;
		op1 %= 90;
		actual = op1;
		expect = 5;
		assertEqual(expect,actual);
	}

	/**
	 * Returns ulong ten raised to the specified power.
	 */
	static ulong pow10(const int n) {
		return 10U^^n;
	}

	unittest {
		int n;
		n = 3;
		assertTrue(pow10(n) == 1000);
	}

}	// end Dec128 struct

unittest {
	writeln("===================");
	writeln("dec128...........end");
	writeln("===================");
}

