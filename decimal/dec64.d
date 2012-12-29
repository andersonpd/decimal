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

module decimal.dec64;

import std.bigint;
import std.bitmanip;
import std.conv;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;

unittest {
	writeln("===================");
	writeln("dec64.......testing");
	writeln("===================");
}

struct Dec64 {

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
	immutable ulong C_EXPLICIT_MASK = 0x7FFFFFFFFFFFFF;

	// The maximum unbiased exponent. The largest binary number that can fit
	// in the width of the exponent field without setting
	// either of the first two bits to 1.
	immutable uint MAX_EXPO = 0x2FF; // = 767
	// The exponent bias. The exponent is stored as an unsigned number and
	// the bias is subtracted from the unsigned value to give the true
	// (signed) exponent.
	immutable int BIAS = 398;		 // = 0x18E
	// The maximum representable exponent.
	immutable int E_LIMIT = 369;	 // MAX_EXPO - BIAS
	// The min and max adjusted exponents.
	immutable int E_MAX =  386; 	 // E_LIMIT + C_LENGTH - 1
	immutable int E_MIN = -385; 	 // = 1 - E_MAX

	/// The context for this type.
	public static DecimalContext
	context = DecimalContext(PRECISION, E_MAX, Rounding.HALF_EVEN);

	// union providing different views of the number representation.
	union {

		// entire 64-bit unsigned integer
		ulong intBits = BITS.POS_NAN;    // set to the initial value: NaN

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

	// (64)TODO: Move this test to test.d?
	unittest {
		Dec64 num;
		assert(num.toHexString == "0x7C00000000000000");

		num.pyldNaN = 1;
		// NOTE: this test should fail when bitmanip is fixed.
		assert(num.toHexString != "0x7C00000000000001");
		assert(num.toHexString == "0x0000000000000001");
		num.bits = ulong.max;
		assert(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num.pyldNaN = 2;
		// NOTE: this test should fail when bitmanip is fixed.
		assert(num.toHexString != "0xFFFFFFFFFFFF0002");
		assert(num.toHexString == "0x00000000FFFF0002");
		num.bits = ulong.max;
		assert(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num.testNaN = 0b10;
		assert(num.toHexString == "0x85FFFFFFFFFFFFFF");
		num.bits = ulong.max;
		assert(num.toHexString == "0xFFFFFFFFFFFFFFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.pyldNaN = ushort.max;
		// NOTE: this test should fail when bitmanip is fixed.
		assert(num.toHexString == "0x000000000000FFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.padInf = ushort.max;
		// NOTE: This works as expected;
		assert(num.toHexString == "0x7C0000000000FFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.padSpcl = ushort.max;
		assert(num.toHexString == "0x780000000000FFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.bits = num.bits | 0xFFFF;
		assert(num.toHexString == "0x7C0000000000FFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.mantEx = uint.max;
		assert(num.toHexString == "0x7C000000FFFFFFFF");
		num = nan;
		assert(num.toHexString == "0x7C00000000000000");
		num.mantIm = uint.max;
		assert(num.toHexString == "0x7C000000FFFFFFFF");
	}

//--------------------------------
//	special values
//--------------------------------

private:
	// The value of the (6) special bits when the number is a signaling NaN.
	immutable uint SIG_BITS = 0x3F;
	// The value of the (6) special bits when the number is a quiet NaN.
	immutable uint NAN_BITS = 0x3E;
	// The value of the (5) special bits when the number is infinity.
	immutable uint INF_BITS = 0x1E;

//--------------------------------
//	special values and constants
//--------------------------------

// Integer values passed to the constructors are not copied but are modified
// and inserted into the sign, coefficient and exponent fields.
// This enum is used to force the constructor to copy the bit pattern,
// rather than treating it as a integer.
private:
	static enum BITS : ulong
	{
		POS_SIG = 0x7E00000000000000,
		NEG_SIG = 0xFE00000000000000,
		POS_NAN = 0x7C00000000000000,
		NEG_NAN = 0xFC00000000000000,
		POS_INF = 0x7800000000000000,
		NEG_INF = 0xF800000000000000,
		POS_ZRO = 0x31C0000000000000,
		NEG_ZRO = 0xB1C0000000000000,
		POS_MAX = 0x77FB86F26FC0FFFF,
		NEG_MAX = 0xF7FB86F26FC0FFFF,
		POS_ONE = 0x31C0000000000001,
		NEG_ONE = 0xB1C0000000000001,
		POS_TWO = 0x31C0000000000002,
		NEG_TWO = 0xB1C0000000000002,
		POS_FIV = 0x31C0000000000005,
		NEG_FIV = 0xB1C0000000000005,
		POS_TEN = 0x31C000000000000A,
		NEG_TEN = 0xB1C000000000000A,

		// pi and related values
		PI		 = 0x2FEB29430A256D21,
		TAU 	 = 0x2FF65286144ADA42,
		PI_2	 = 0x2FE594A18512B691,
		PI_SQR	 = 0x6BFB105A58668B4F,
		SQRT_PI  = 0x2FE64C099229FBAC,
		SQRT_2PI = 0x2FE8E7C3DFE4B159,
		INV_PI   = 0x2FCB4F02F4F1DE53,
		// 1/SQRT_PI
		// 1/SQRT_2PI

		// logarithms
		E		= 0x2FE9A8434EC8E225,
		LOG2_E	= 0x2FE5201F9D6E7083,
		LOG10_E = 0x2FCF6DE2A337B1C6,
		LN2 	= 0x2FD8A0230ABE4EDD,
		LOG10_2 = 0x2FCAB1DA13953844,
		LN10	= 0x2FE82E305E8873FE,
		LOG2_10 = 0x2FEBCD46A810ADC2,
/*	Dec32 diff
		PHI 	= 0x2F98B072,
		GAMMA	= 0x2F58137D,
*/
		// roots and squares of common values
		SQRT2	= 0x2FE50638410593E7,
		SQRT1_2 = 0x2FD91F19451BE383
	}


public:
	immutable Dec64 NAN 	 = Dec64(BITS.POS_NAN);
	immutable Dec64 SNAN	 = Dec64(BITS.POS_SIG);
	immutable Dec64 INFINITY = Dec64(BITS.POS_INF);
	immutable Dec64 NEG_INF  = Dec64(BITS.NEG_INF);
	immutable Dec64 ZERO	 = Dec64(BITS.POS_ZRO);
	immutable Dec64 NEG_ZERO = Dec64(BITS.NEG_ZRO);
	immutable Dec64 MAX 	 = Dec64(BITS.POS_MAX);
	immutable Dec64 NEG_MAX  = Dec64(BITS.NEG_MAX);

	// small integers
	immutable Dec64 ONE 	 = Dec64(BITS.POS_ONE);
	immutable Dec64 NEG_ONE  = Dec64(BITS.NEG_ONE);
	immutable Dec64 TWO 	 = Dec64(BITS.POS_TWO);
	immutable Dec64 NEG_TWO  = Dec64(BITS.NEG_TWO);
	immutable Dec64 FIVE	 = Dec64(BITS.POS_FIV);
	immutable Dec64 NEG_FIVE = Dec64(BITS.NEG_FIV);
	immutable Dec64 TEN 	 = Dec64(BITS.POS_TEN);
	immutable Dec64 NEG_TEN  = Dec64(BITS.NEG_TEN);

	// mathamatical constants
	immutable Dec64 TAU 	 = Dec64(BITS.TAU);
	immutable Dec64 PI		 = Dec64(BITS.PI);
	immutable Dec64 PI_2	 = Dec64(BITS.PI_2);
	immutable Dec64 PI_SQR	 = Dec64(BITS.PI_SQR);
	immutable Dec64 SQRT_PI  = Dec64(BITS.SQRT_PI);
	immutable Dec64 SQRT_2PI = Dec64(BITS.SQRT_2PI);
	immutable Dec64 INV_PI   = Dec64(BITS.INV_PI);

	immutable Dec64 E		 = Dec64(BITS.E);
	immutable Dec64 LOG2_E	 = Dec64(BITS.LOG2_E);
	immutable Dec64 LOG10_E  = Dec64(BITS.LOG10_E);
	immutable Dec64 LN2 	 = Dec64(BITS.LN2);
	immutable Dec64 LOG10_2  = Dec64(BITS.LOG10_2);
	immutable Dec64 LN10	 = Dec64(BITS.LN10);
	immutable Dec64 LOG2_10  = Dec64(BITS.LOG2_10);
	immutable Dec64 SQRT2	 = Dec64(BITS.SQRT2);
	immutable Dec64 SQRT1_2	 = Dec64(BITS.SQRT1_2);
/*	Dec32 diff
	immutable Dec64 PHI 	 = Dec64(BITS.PHI);
	immutable Dec64 GAMMA	 = Dec64(BITS.GAMMA);
*/
	// boolean constants
	immutable Dec64 TRUE	 = ONE;
	immutable Dec64 FALSE	 = ZERO;

//--------------------------------
//	constructors
//--------------------------------

/*unittest {
	write("constants...");
writeln("PI = ", PI);
writeln("INV_PI = ", INV_PI);
	Dec64 test;
	test = PI * INV_PI;
writeln("test = ", test);
writeln("test.toHexString = ", test.toHexString);
	writeln("test missing");
}*/

	/**
	 * Creates a Dec64 from a special value.
	 */
	private this(const BITS bits) {
		intBits = bits;
	}

	// this unit test uses private values
	unittest {
	Dec64 num;
		num = Dec64(BITS.POS_SIG);
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = Dec64(BITS.NEG_SIG);
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(!num.isNormal);
		num = Dec64(BITS.POS_NAN);
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = Dec64(BITS.NEG_NAN);
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(num.isQuiet);
		num = Dec64(BITS.POS_INF);
		assert(num.isInfinite);
		assert(!num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = Dec64(BITS.NEG_INF);
		assert(!num.isSignaling);
		assert(num.isInfinite);
		assert(num.isNegative);
		assert(!num.isFinite);
		num = Dec64(BITS.POS_ZRO);
		assert(num.isFinite);
		assert(num.isZero);
		assert(!num.isNegative);
		assert(num.isNormal);
		num = Dec64(BITS.NEG_ZRO);
		assert(!num.isSignaling);
		assert(num.isZero);
		assert(num.isNegative);
		assert(num.isFinite);
	}

	/**
	 * Creates a Dec64 from a long integer.
	 */
	public this(const long n) {
		this = zero;
		signed = n < 0;
		coefficient = signed ? -n : n;
	}

	unittest {
		Dec64 num;
		num = Dec64(123456789012345678L);
		assert(num.toString == "1.234567890123457E+17");
		num = Dec64(0);
		assert(num.toString == "0");
		num = Dec64(1);
		assert(num.toString == "1");
		num = Dec64(-1);
		assert(num.toString == "-1");
		num = Dec64(5);
		assert(num.toString == "5");
	}

	/**
	 * Creates a Dec64 from a boolean value.
	 */
	public this(const bool value) {
		this = value ? ONE : ZERO;
	}

/*	Dec32 diff
	unittest {
		Dec64 num;
		num = Dec64(1234567890L);
		assert(num.toString == "1234567890"); //1.234567890E+9");
		num = Dec64(0);
		assert(num.toString == "0");
		num = Dec64(1);
		assert(num.toString == "1");
		num = Dec64(-1);
		assert(num.toString == "-1");
		num = Dec64(5);
		assert(num.toString == "5");
	}
*/
	/**
	 * Creates a Dec64 from an long integer and an integer exponent.
	 */
	public this(const long mant, const int expo) {
		this(mant);
		exponent = exponent + expo;
	}

	unittest {
		Dec64 num;
		num = Dec64(1234567890L, 5);
		assert("1.234567890E+14", num.toString);
		num = Dec64(0, 2);
		assert("0E+2" == num.toString);
		num = Dec64(1, 75);
		assert("1E+75" == num.toString);
		num = Dec64(-1, -75);

		assert("-1E-75" == num.toString);
		num = Dec64(5, -3);
		assert("0.005" == num.toString);
		num = Dec64(true, 1234567890L, 5);
		assert("-1.234567890E+14" == num.toString);
		num = Dec64(0, 0, 2);
		assert("0E+2" == num.toString);
	}

	/**
	 * Creates a Dec64 from a boolean sign, an unsigned long integer,
	 * and an integer exponent.
	 */
	public this(const bool sign, const ulong mant, const int expo) {
		this(mant, expo);
		signed = sign;
	}

	unittest {
		Dec64 num;
		num = Dec64(1234567890L, 5);
		assert(num.toString == "1.234567890E+14");
		num = Dec64(0, 2);
		assert(num.toString == "0E+2");
		num = Dec64(1, 75);
		assert(num.toString == "1E+75");
		num = Dec64(-1, -75);
		assert(num.toString == "-1E-75");
		num = Dec64(5, -3);
		assert(num.toString == "0.005");
		num = Dec64(true, 1234567890L, 5);
		assert(num.toString == "-1.234567890E+14");
		num = Dec64(0, 0, 2);
		assert(num.toString == "0E+2");
	}

	/**
	 * Creates a Dec64 from a Decimal
	 */
	public this(const Decimal num) {

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

		Decimal big = plus!Decimal(num, context);

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
		Decimal dec = 0;
		Dec64 num = dec;
		assert(dec.toString == num.toString);
		dec = 1;
		num = dec;
		assert(dec.toString == num.toString);
		dec = -1;
		num = dec;
		assert(dec.toString == num.toString);
		dec = -16000;
		num = dec;
		assert(dec.toString == num.toString);
		dec = uint.max;
		num = dec;
		assert(num.toString == "4294967295");
		assert(dec.toString == "4294967295");
		dec = 9999999E+12;
		num = dec;
		assert(dec.toString == num.toString);
	}

	/**
	 * Creates a Dec64 from a string.
	 */
	public this(const string str) {
		Decimal big = Decimal(str);
		this(big);
	}

	unittest {
		Dec64 num;
		num = Dec64("1.234568E+9");
		assert(num.toString == "1.234568E+9");
		num = Dec64("NaN");
		assert(num.isQuiet && num.isSpecial && num.isNaN);
		num = Dec64("-inf");
		assert(num.isInfinite && num.isSpecial && num.isNegative);
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
		// (64)TODO: this won't do -- no rounding has occured.
		string str = format("%.*G", cast(int)context.precision, r);
		this(str);
	}

	unittest {
		float f = 1.2345E+16f;
		Dec64 actual = Dec64(f);
		Dec64 expect = Dec64("1.234499980283085E+16");
		assert(actual == expect);
		real r = 1.2345E+16;
		actual = Dec64(r);
		expect = Dec64("1.2345E+16");
		assert(actual == expect);
	}

	/**
	 * Copy constructor.
	 */
	public this(const Dec64 that) {
		this.bits = that.bits;
	}

	/**
	 * Duplicator.
	 */
	public const Dec64 dup() {
		return Dec64(this);
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
		Dec64 num;
		int expect, actual;
		// reals
		num = std.math.PI;
		expect = -15;
		actual = num.exponent;
		assert(actual == expect);
		num = 9.75E9;
		expect = 0;
		actual = num.exponent;
		assert(actual == expect);
		// explicit
		num = 8388607;
		expect = 0;
		actual = num.exponent;
		assert(actual == expect);
		// implicit
		num = 8388610;
		expect = 0;
		actual = num.exponent;
		assert(actual == expect);
		num = 9.999998E23;
		expect = 17;
		actual = num.exponent;
		assert(actual == expect);
		num = 9.999999E23;
		expect = 8;
		actual = num.exponent;
		assert(actual == expect);
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
		if (expo > context.maxExpo) {
			this = signed ? NEG_INF : INFINITY;
			contextFlags.setFlags(OVERFLOW);
			return 0;
		}
		// check for underflow
		if (expo < context.minExpo) {
			// if the exponent is too small even for a subnormal number,
			// the number is set to zero.
			if (expo < context.tinyExpo) {
				this = signed ? NEG_ZERO : ZERO;
				expoEx = context.tinyExpo + BIAS;
				contextFlags.setFlags(SUBNORMAL);
				contextFlags.setFlags(UNDERFLOW);
				return context.tinyExpo;
			}
			// at this point the exponent is between minExpo and tinyExpo.
			// (64)TODO: I don't think this needs special handling
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
		Dec64 num;
		num = Dec64(-12000,5);
		num.exponent = 10;
		assert(num.exponent == 10);
		num = Dec64(-9000053,-14);
		num.exponent = -27;
		assert(num.exponent == -27);
		num = infinity;
		assert(num.exponent == 0);
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
			expo = setExponent(sign, copy, digits, context);
			if (this.isExplicit) {
				expoEx = expoEx + expo;
			}
			else {
				expoIm = expoIm + expo;
			}
		}
		// at this point, the number <=
		if (copy <= C_MAX_EXPLICIT) {
			// if implicit, convert to explicit
			if (this.isImplicit) {
				expoEx = expoIm;
			}
			mantEx = /*cast(ulong)*/copy;
			return mantEx;
		}
		else {	// copy <= C_MAX_IMPLICITwriteln(" = ", );
			// if explicit, convert to implicit
			if (this.isExplicit) {
				expoIm = expoEx;
				testIm = 0x3;
			}
			mantIm = cast(ulong)copy & C_IMPLICIT_MASK;
			ulong shifted = mantIm | (0b100UL << implicitBits);
			return mantIm | (0b100UL << implicitBits);
		}
	}

	unittest {
		Dec64 num;
		assert(0 == num.coefficient);
		num = 9.998742;
		assert(9998742 == num.coefficient);
		num = 9.998743;
		assert(9998742999999999 == num.coefficient);
		// note the difference between real and string values!
		num = Dec64("9.998743");
		assert(num.coefficient == 9998743);
		num = Dec64(9999213,-6);
		assert(num.coefficient == 9999213);
		num = -125;
		assert(num.coefficient == 125);
		num = -99999999;
		assert(num.coefficient == 99999999);
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

	// (64)TODO: need to ensure this won't overflow into other bits.
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

	unittest {	// payload
		Dec64 num;
		assert(num.payload == 0);
		num = snan;
		assert(num.payload == 0);
		num.payload = 234;
		assert(num.payload == 234);
		assert(num.toString == "sNaN234");
		num = 1234567;
		assert(num.payload == 0);
	}

//--------------------------------
//	constants
//--------------------------------

	static Dec64 zero(const bool signed = false) {
		return signed ? NEG_ZERO : ZERO;
	}

	static Dec64 max(const bool signed = false) {
		return signed ? NEG_MAX : MAX;
	}

	static Dec64 infinity(const bool signed = false) {
		return signed ? NEG_INF : INFINITY;
	}

	static Dec64 nan(const ushort payload = 0) {
		if (payload) {
			Dec64 result = NAN;
			result.payload = payload;
			return result;
		}
		return NAN;
	}

	static Dec64 snan(const ushort payload = 0) {
		if (payload) {
			Dec64 result = SNAN;
			result.payload = payload;
			return result;
		}
		return SNAN;
	}


	// floating point properties
	static Dec64 init() 	  {
		return NAN;
	}
	static Dec64 epsilon()	  {
		return Dec64(1, -context.precision);
	}
//	static Dec64 min_normal() {
//		return Dec64(1, context.minExpo);
//	}
	static Dec64 min()		  {
		return Dec64(1, context.minExpo);
	} //context.tinyExpo); }

/* dec32diff
	static Dec32 init() 	  { return NAN; }
	static Dec32 epsilon()	  { return Dec32(1, -7); }
	static Dec32 min()		  { return Dec32(1, context32.tinyExpo); }

	static int dig()		{ return 7; }
	static int mant_dig()	{ return 24; }
	static int max_10_exp() { return context32.maxExpo; }
	static int min_10_exp() { return context32.minExpo; }
	static int max_exp()	{ return cast(int)(context32.maxExpo/LOG2); }
	static int min_exp()	{ return cast(int)(context32.minExpo/LOG2); }

	/// Returns the maximum number of decimal digits in this context.
	static uint precision(const DecimalContext context = this.context) {
		return context.precision;
	}
*/
	/*	static int dig()		{ return context.precision; }
		static int mant_dig()	{ return cast(int)context.mant_dig;; }
		static int max_10_exp() { return context.maxExpo; }
		static int min_10_exp() { return context.minExpo; }
		static int max_exp()	{ return cast(int)(context.maxExpo/LOG2); }
		static int min_exp()	{ return cast(int)(context.minExpo/LOG2); }*/

	/// Returns the maximum number of decimal digits in this context.
	static uint precision() {
		return context.precision;
	}


	/*	  /// Returns the maximum number of decimal digits in this context.
		static uint dig(const DecimalContext context = this.context) {
			return context.precision;
		}

		/// Returns the number of binary digits in this context.
		static uint mant_dig(const DecimalContext context = this.context) {
			return cast(int)context.mant_dig;
		}

		static int min_exp(const DecimalContext context = this.context) {
			return context.min_exp;
		}

		static int max_exp(const DecimalContext context = this.context) {
			return context.max_exp;
		}

//		/// Returns the minimum representable normal value in this context.
//		static Dec64 min_normal(const DecimalContext context = this.context) {
//			return Dec64(1, context.minExpo);
//		}

		/// Returns the minimum representable subnormal value in this context.
		static Dec64 min(const DecimalContext context = this.context) {
			return Dec64(1, context.tinyExpo);
		}

		/// returns the smallest available increment to 1.0 in this context
		static Dec64 epsilon(const DecimalContext context = this.context) {
			return Dec64(1, -context.precision);
		}

		static int min_10_exp(const DecimalContext context = this.context) {
			return context.minExpo;
		}

		static int max_10_exp(const DecimalContext context = this.context) {
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
	const Dec64 canonical() {
		Dec64 copy = this;
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
	 * Returns true if this number is a quiet or signaling NaN.
	 */
	const bool isNaN() {
		return testNaN == NAN_BITS || testNaN == SIG_BITS;
	}

	/**
	 * Returns true if this number is a signaling NaN.
	 */
	const bool isSignaling() {
		return testNaN == SIG_BITS;
	}

	/**
	 * Returns true if this number is a quiet NaN.
	 */
	const bool isQuiet() {
		return testNaN == NAN_BITS;
	}

	/**
	 * Returns true if this number is +\- infinity.
	 */
	const bool isInfinite() {
		return testInf == INF_BITS;
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

	/// Returns true if this number is a true value.
	/// Non-zero finite numbers are true.
	/// Infinity is true and NaN is false.
	const bool isTrue() {
		return isFinite && !isZero || isInfinite;
	}

	/// Returns true if this number is a false value.
	/// Finite numbers with zero coefficient are false.
	/// Infinity is true and NaN is false.
	const bool isFalse() {
		return isNaN || isZero;
	}

	unittest {	//isTrue/isFalse
		assert(Dec64("1").isTrue);
		assert(!Dec64("0").isTrue);
		assert(infinity.isTrue);
		assert(!nan.isTrue);

		assert(Dec64("0").isFalse);
		assert(!Dec64("1").isFalse);
		assert(!infinity.isFalse);
		assert(nan.isFalse);
	}

	const bool isZeroCoefficient() {
		return !isSpecial && coefficient == 0;
	}

	/**
	 * Returns true if this number is subnormal.
	 */
	const bool isSubnormal(const DecimalContext context = this.context) {
		if (isSpecial) return false;
		return adjustedExponent < context.minExpo;
	}

	/**
	 * Returns true if this number is normal.
	 */
	const bool isNormal(const DecimalContext context = this.context) {
		if (isSpecial) return false;
		return adjustedExponent >= context.minExpo;
	}

	/**
	 * Returns true if this number is an integer.
	 */
	const bool isIntegral(const DecimalContext context = this.context) {
		if (isSpecial) return false;
		if (exponent >= 0) return true;
		uint expo = std.math.abs(exponent);
		if (expo >= PRECISION) return false;
		if (coefficient % 10^^expo == 0) return true;
		return false;
	}

	unittest {
		Dec64 num;
		num = 22;
		assert(num.isIntegral);
		num = 200E-2;
		assert(num.isIntegral);
		num = 201E-2;
		assert(!num.isIntegral);
		num = Dec64.INFINITY;
		assert(!num.isIntegral);
	}

	// (64)TODO: Spec reference
	/// Returns the value of the adjusted exponent.
	/// NOTE: This routine shouldn't be called on special numbers.
	const int adjustedExponent() {
		return exponent + digits - 1;
	}

//--------------------------------
//	conversions
//--------------------------------

	/**
	 * Converts a Dec64 to a Decimal
	 */
	const Decimal toBigDecimal() {
		if (isFinite) {
			return Decimal(sign, BigInt(coefficient), exponent);
		}
		if (isInfinite) {
			return Decimal.infinity(sign);
		}
		// number is a NaN
		Decimal dec;
		if (isQuiet) {
			dec = Decimal.nan(sign);
		}
		if (isSignaling) {
			dec = Decimal.snan(sign);
		}
		if (payload) {
			dec.payload(payload);
		}
		return dec;
	}

	unittest {
		Dec64 num = Dec64("12345E+17");
		Decimal expected = Decimal("12345E+17");
		Decimal actual = num.toBigDecimal;
		assert(actual == expected);
	}

	const int toInt() {
		int n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec64(int.max) || (isInfinite && !isSigned)) return int.max;
		if (this < Dec64(int.min) || (isInfinite &&  isSigned)) return int.min;
		quantize!Dec64(this, ONE, context);
		n = cast(int)coefficient;
		return signed ? -n : n;
	}

	unittest {
		Dec64 num;
		num = 12345;
		assert(num.toInt == 12345);
		num = 1.0E6;
		assert(num.toInt == 1000000);
		num = -1.0E60;
		assert(num.toInt == int.min);
		num = NEG_INF;
		assert(num.toInt == int.min);
	}

	const long toLong() {
		long n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec64(long.max) || (isInfinite && !isSigned)) return long.max;
		if (this < Dec64(long.min) || (isInfinite &&  isSigned)) return long.min;
		quantize!Dec64(this, ONE, context);
		n = coefficient;
		return signed ? -n : n;
	}

	unittest {
		Dec64 num;
		num = -12345;
		assert(num.toLong == -12345);
		num = 2 * int.max;
		assert(num.toLong == 2 * int.max);
		num = 1.0E6;
		assert(num.toLong == 1000000);
		num = -1.0E60;
		assert(num.toLong == long.min);
		num = NEG_INF;
		assert(num.toLong == long.min);
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
		Dec64 num;
		real expect, actual;
		num = Dec64(1.5);
		expect = 1.5;
		actual = num.toReal;
		assert(actual == expect);
		writeln("passed");
	}

	// Converts this number to an exact scientific-style string representation.
	const string toSciString() {
		return decimal.conv.sciForm!Dec64(this);
	}

	// Converts this number to an exact engineering-style string representation.
	const string toEngString() {
		return decimal.conv.engForm!Dec64(this);
	}

	// Converts this Dec64 to a string
	const public string toString() {
		return toSciString();
	}

	unittest {
		string str;
		str = "-12.345E-42";
		Dec64 num = Dec64(str);
		assert(num.toString == "-1.2345E-41");
	}

	 // Returns a verbose representation of this number.
	const string toExact() {
		return decimal.conv.toExact!Dec64(this);
	}

	unittest {
		Dec64 num;
		assert(num.toExact == "+NaN");
		num = Dec64.max;
		assert(num.toExact == "+9999999999999999E+369");
		num = Dec64.min;
		num = 1;
		assert(num.toExact == "+1E+00");
		num = C_MAX_EXPLICIT;
		assert(num.toExact == "+9007199254740991E+00");
		num = C_MAX_IMPLICIT;
		assert(num.toExact == "+9999999999999999E+00");
		num = infinity(true);
		assert(num.toExact == "-Infinity");
	}

	/// Returns an abstract representation of this number.
	const string toAbstract() {
		return decimal.conv.toAbstract!Dec64(this);
	}

	unittest {
		Dec64 num;
		num = Dec64("-25.67E+2");
		assert(num.toAbstract == "[1,2567,0]");
	}

	/// Returns a hexadecimal string representation.
	const string toHexString() {
		return format("0x%016X", bits);
	}

	/// Returns a binary string representation.
	const string toBinaryString() {
		return format("%0#64b", bits);
	}

	unittest {
		Dec64 num = 12345;
		assert(num.toHexString == "0x31C0000000003039");
		assert(num.toBinaryString ==
		"0011000111000000000000000000000000000000000000000011000000111001");
	}

//--------------------------------
//	comparison
//--------------------------------

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
const int opCmp(T:Dec64)(const T that) {
		return compare!Dec64(this, that, context);
	}

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
	const int opCmp(T)(const T that) if (isPromotable!T) {
		return opCmp!Dec64(Dec64(that));
	}

	unittest {
		Dec64 a, b;
		a = Dec64(104.0);
		b = Dec64(105.0);
		assert(a < b);
		assert(b > a);
	}

	/**
	 * Returns true if this number is equal to the specified number.
	 */
	const bool opEquals(T:Dec64)(const T that) {
		// quick bitwise check
		if (this.bits == that.bits) {
			if (this.isFinite) return true;
			if (this.isInfinite) return true;
			if (this.isQuiet) return false;
			// let the main routine handle the signaling NaN
		}
		return equals!Dec64(this, that, context);
	}

	unittest {
		Dec64 a, b;
		a = Dec64(105);
		b = Dec64(105);
		assert(a == b);
	}
	/**
	 * Returns true if this number is equal to the specified number.
	 */
	const bool opEquals(T)(const T that) if (isPromotable!T) {
		return opEquals!Dec64(Dec64(that));
	}

	unittest {
		Dec64 a, b;
		a = Dec64(105);
		b = Dec64(105);
		int c = 105;
		assert(a == c);
		real d = 105.0;
		assert(a == d);
		assert(a == 105);
	}

	const bool isIdentical(const Dec64 that) {
		return this.bits == that.bits;
	}

//--------------------------------
// assignment
//--------------------------------

	/// Assigns a Dec64 (copies that to this).
	void opAssign(T:Dec64)(const T that) {
		this.intBits = that.intBits;
	}

	unittest {
		Dec64 that, lhs;
		that = Dec64(270E-5);
		lhs = that;
		assert(lhs == that);
	}

	/// Assigns a numeric value.
	void opAssign(T)(const T that) {
		this = Dec64(that);
	}

	unittest {
		Dec64 that;
		that = 332089;
		assert(that.toString == "332089");
		that = 3.1415E+3;
		assert(that.toString == "3141.5");
	}

//--------------------------------
// unary operators
//--------------------------------

	private Dec64 opUnary(string op)() {
		static if (op == "+") {
			return plus!Dec64(this, context);
		} else static if (op == "-") {
			return minus!Dec64(this, context);
		} else static if (op == "++") {
			this = add!Dec64(this, Dec64(1), context);
			return this;
		} else static if (op == "--") {
			this = sub!Dec64(this, Dec64(1), context);
			return this;
		}
	}

	unittest {
		Dec64 num, actual, expect;
		num = 134;
		expect = num;
		actual = +num;
		assert(actual == expect);
		num = 134.02;
		expect = -134.02;
		actual = -num;
		assert(actual == expect);
		num = 134;
		expect = 135;
		actual = ++num;
		assert(actual == expect);
		num = 1.00E8;
		expect = num;
		actual = num--;
		assert(actual == expect);
		num = Dec64(9999999, 90);
		expect = num;
		actual = num++;
		assert(actual == expect);
		num = 12.35;
		expect = 11.35;
		actual = --num;
		assert(actual == expect);
	}

//--------------------------------
// binary operators
//--------------------------------

	// NOTE: "const Dec64 opBinary(string op)(const Dec64 that)"
	//     doesn't work becaus of a DMD compiler bug.

	/// operations on Dec64 arguments
	private const T opBinary(string op, T:Dec64)(const T that)
	{
		static if (op == "+") {
			return add!Dec64(this, that, context);
		} else static if (op == "-") {
			return sub!Dec64(this, that, context);
		} else static if (op == "*") {
			return mul!Dec64(this, that, context);
		} else static if (op == "/") {
			return div!Dec64(this, that, context);
		} else static if (op == "%") {
			return remainder!Dec64(this, that, context);
		} else static if (op == "&") {
			return and!Dec64(this, that, context);
		} else static if (op == "|") {
			return or!Dec64(this, that, context);
		} else static if (op == "^") {
			return xor!Dec64(this, that, context);
		}
	}

	unittest {	// opBinary
		Dec64 op1, op2, actual, expect;
		op1 = 4; op2 = 8;
		assert(op1 + op2 == Dec64(12));
		assert(op1 - op2 == Dec64(-4));
		assert(op1 * op2 == Dec64(32));
		op1 = 5; op2 = 2;
		assert(op1 / op2 == Dec64(2.5));
		op1 = 10; op2 = 3;
		assert(op1 % op2 == Dec64(1));
		op1 = 10; op2 = 110;
		assert(isLogical(op1));
		assert((op1 & op2) == Dec64(10));
//		assert((op1 | op2) == Dec64(1100));
//		assert((op1 ^ op2) == Dec64(1100));
	}

	 /// Can T be promoted to a Dec64?
	private template isPromotable(T) {
		enum bool isPromotable = is(T:ulong) || is(T:real); // || is(T:Dec32);
	}

	// (64)TODO: fix this to pass integers without promotion
	/// operations on promotable arguments
	const Dec64 opBinary(string op, T)(const T that) if (isPromotable!T) {
		return opBinary!(op,Dec64)(Dec64(that));
	}

	unittest {
		Dec64 num = Dec64(591.3);
		Dec64 result = num * 5;
		assert(result == Dec64(2956.5));
	}

//-----------------------------
// operator assignment
//-----------------------------

	private ref Dec64 opOpAssign(string op, T:Dec64) (T that) {
		this = opBinary!op(that);
		return this;
	}

	private ref Dec64 opOpAssign(string op, T) (T that) if (isPromotable!T) {
		this = opBinary!op(that);
		return this;
	}

	unittest {	// opOpAssign
		Dec64 op1, op2, actual, expect;
		op1 = 23.56;
		op2 = -2.07;
		op1 += op2;
		expect = 21.49;
		actual = op1;
		assert(actual == expect);
		op1 *= op2;
		expect = -44.4843;
		actual = op1;
		assert(actual == expect);
		op1 = 95;
		op1 %= 90;
		actual = op1;
		expect = 5;
		assert(actual == expect);
	}

	/// Returns ulong ten raised to the specified power.
	static ulong pow10(const int n) {
		return TENS[n];
	}

	unittest {	// pow10
		assert(pow10(3) == 1000);
	}

	///	Returns the BigInt product of the coefficients
	public static BigInt bigmul(const Dec64 arg1, const Dec64 arg2) {
		BigInt big = BigInt(arg1.coefficient);
		return big * arg2.coefficient;
	}

}	// end Dec64 struct

unittest {
	writeln("===================");
	writeln("dec64...........end");
	writeln("===================");
}

