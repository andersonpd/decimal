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

module decimal.dec128;

import std.bigint;
import std.conv;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;
import decimal.dec32;
import decimal.dec64;
import decimal.integer;

unittest {
	writeln("===================");
	writeln("dec128.......testing");
	writeln("===================");
}

private static ZERO = uint128.ZERO;

struct Dec128 {

//private static const uint128 TEST = uint128(127UL, 123UL);

private:
	// The total number of bits in the decimal number.
	// This is equal to the number of bits in the underlying integer;
	// (must be 32, 64, or 128).
	immutable uint bitLength = 129;

	// the number of bits in the sign bit (1, obviously)
	immutable uint signBit = 1;

	// The number of bits in the unsigned value of the decimal number.
	immutable uint unsignedBits = 127; // = bitLength - signBit;

	// The number of bits in the (biased) exponent.
	immutable uint expoBits = 14;

	// The number of bits in the coefficient when the value is
	// explicitly represented.
	immutable uint EXPL_SHFT = 49;

	// The number of bits used to indicate special values and implicit
	// representation
	immutable uint testBits = 2;

	// The number of bits in the coefficient when the value is implicitly
	// represented. The three missing bits (the most significant bits)
	// are always '100'.
	immutable uint IMPL_SHFT = 47; // = EXPL_SHFT - testBits;

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
	immutable int PRECISION = 34;
	// The maximum coefficient that fits in an explicit number.
/*	immutable ulong C_MAX_EXPLICIT = 0x1FFFFFFFFFFFFF;  // = 36028797018963967
	// The maximum coefficient allowed in an implicit number.
	immutable ulong C_MAX_IMPLICIT = 9999999999999999;  // = 0x2386F26FC0FFFF
	// masks for coefficients
	immutable ulong C_IMPLICIT_BITS = 0x1FFFFFFFFFFFFF;
	immutable ulong C_EXPLICIT_BITS = 0x7FFFFFFFFFFFF;*/

	// The maximum unbiased exponent. The largest binary number that can fit
	// in the width of the exponent field without setting
	// either of the first two bits to 1.
	immutable uint MAX_EXPO = 12287; // = 0x2FFF
	// The exponent bias. The exponent is stored as an unsigned number and
	// the bias is subtracted from the unsigned value to give the true
	// (signed) exponent.
	immutable int BIAS = 6176;		 // = 0x1820
	// The maximum representable exponent.
	immutable int E_LIMIT = 6111;	 // MAX_EXPO - BIAS
	// The min and max adjusted exponents.
	immutable int E_MAX =  6144; 	 // E_LIMIT + C_LENGTH - 1
	immutable int E_MIN = -6143; 	 // = 1 - E_MAX

	/// The context for this type.
	private static const DecimalContext
		context = DecimalContext(PRECISION, E_MAX, Rounding.HALF_EVEN);

	/*public*/ private uint128 bits = uint128(0x7C00000000000000UL, 0x0000000000000000UL);

	private const ulong highBits() {
		return bits.getLong(0);
	}

	private void highBits(ulong value) {
		bits.setLong(0, value);
	}

	private const ulong lowBits() {
		return bits.getLong(1);
	}

	private void lowBits(ulong value) {
		bits.setLong(1, value);
	}
	private ulong SIGN_BIT =  0x8000000000000000UL;

	private ulong IMPL_BITS = 0x7000000000000000UL; // mask = s111_0000_0...
	private ulong IMPL_TEST = 0x6000000000000000UL; // impl = s110_0000_0...

	private ulong INF_BITS =  0x7C00000000000000UL;	// mask = s111_1100_0...
	private ulong INF_TEST =  0x7800000000000000UL;	// inf  = s111_1000_0...

	private ulong NAN_BITS =  0x7E00000000000000UL; // mask = s111_1110_0...
	private ulong NAN_TEST =  0x7C00000000000000UL; // nan  = s111_1100_0...

	private ulong SIG_BITS =  0x7F00000000000000UL; // mask = s111_1111_0...
	private ulong SIG_TEST =  0x7E00000000000000UL; // snan = s111_1110_0...

	private ulong SPCL_TEST = 0x7800000000000000UL; // spcl = s111_1000_0...

/*	private ulong IMPL_EXPO = 0x1FFF800000000000UL;
	private ulong IMPL_MANT = 0x00007FFFFFFFFFFFUL;
	private ulong IMPLIED   = 4UL << IMPL_SHFT;*/

	private ulong EXPL_EXPO = 0x7FFE000000000000UL;
	private ulong EXPL_MANT = 0x0001FFFFFFFFFFFFUL;
	private uint128 MAX_COEFFICIENT = uint128(0x00001ED09BEAD87C0UL, 0x378D8E63FFFFFFFFUL);

public:
	immutable Dec128 NAN      = Dec128(uint128(0x7C00000000000000UL,0x0UL));
//	immutable Dec128 SNAN     = Dec128(uint128(0xFE00000000000000UL));//,0x0UL));
	immutable Dec128 SNAN     = Dec128(uint128(0x7E00000000000000UL,0x0UL));
	immutable Dec128 INFINITY = Dec128(uint128(0x7800000000000000UL,0x0UL));
	immutable Dec128 NEG_INF  = Dec128(uint128(0xF800000000000000UL,0x0UL));
	immutable Dec128 ZERO     = Dec128(uint128(0x3040000000000000UL,0x0UL));
	immutable Dec128 NEG_ZERO = Dec128(uint128(0xB040000000000000UL,0x0UL));
//	immutable Dec128 MAX      = Dec128(uint128(0x77FB86F26FC0FFFFUL,0x0UL));
	immutable Dec128 NEG_MAX  = Dec128(uint128(0xF7FB86F26FC0FFFFUL,0x0UL));
	immutable Dec128 MAX 	  = Dec128(uint128(0x5FFFED09BEAD87C0UL,0x378D8E63FFFFFFFFUL));

	// small integers
	immutable Dec128 ONE 	  = Dec128(uint128(0x3040000000000000UL,0x1UL));
	immutable Dec128 NEG_ONE  = Dec128(uint128(0xB040000000000000UL,0x1UL));
	immutable Dec128 TWO 	  = Dec128(uint128(0x3040000000000000UL,0x2UL));
	immutable Dec128 NEG_TWO  = Dec128(uint128(0xB040000000000000UL,0x2UL));
	immutable Dec128 FIVE	  = Dec128(uint128(0x3040000000000000UL,0x5UL));
	immutable Dec128 NEG_FIVE = Dec128(uint128(0xB040000000000000UL,0x5UL));
	immutable Dec128 TEN 	  = Dec128(uint128(0x3040000000000000UL,0xAUL));
	immutable Dec128 NEG_TEN  = Dec128(uint128(0xB040000000000000UL,0xAUL));
/*
	immutable Dec128 NAN      = Dec128(BITS.POS_NAN);
	immutable Dec128 SNAN     = Dec128(BITS.POS_SIG);
	immutable Dec128 INFINITY = Dec128(BITS.POS_INF);
	immutable Dec128 NEG_INF  = Dec128(BITS.NEG_INF);
	immutable Dec128 ZERO     = Dec128(BITS.POS_ZRO);
	immutable Dec128 NEG_ZERO = Dec128(BITS.NEG_ZRO);
	immutable Dec128 MAX      = Dec128(BITS.POS_MAX);
	immutable Dec128 NEG_MAX  = Dec128(BITS.NEG_MAX);

	// small integers
	immutable Dec128 ONE 	  = Dec128(BITS.POS_ONE);
	immutable Dec128 NEG_ONE  = Dec128(BITS.NEG_ONE);
	immutable Dec128 TWO 	  = Dec128(BITS.POS_TWO);
	immutable Dec128 NEG_TWO  = Dec128(BITS.NEG_TWO);
	immutable Dec128 FIVE	  = Dec128(BITS.POS_FIV);
	immutable Dec128 NEG_FIVE = Dec128(BITS.NEG_FIV);
	immutable Dec128 TEN 	  = Dec128(BITS.POS_TEN);
	immutable Dec128 NEG_TEN  = Dec128(BITS.NEG_TEN);

/*
	// mathamatical constants
	immutable Dec128 TAU 	 = Dec128(BITS.TAU);
	immutable Dec128 PI		 = Dec128(BITS.PI);
	immutable Dec128 PI_2	 = Dec128(BITS.PI_2);
	immutable Dec128 PI_SQR	 = Dec128(BITS.PI_SQR);
	immutable Dec128 SQRT_PI  = Dec128(BITS.SQRT_PI);
	immutable Dec128 SQRT_2PI = Dec128(BITS.SQRT_2PI);

	immutable Dec128 E		 = Dec128(BITS.E);
	immutable Dec128 LOG2_E	 = Dec128(BITS.LOG2_E);
	immutable Dec128 LOG10_E  = Dec128(BITS.LOG10_E);
	immutable Dec128 LN2 	 = Dec128(BITS.LN2);
	immutable Dec128 LOG10_2  = Dec128(BITS.LOG10_2);
	immutable Dec128 LN10	 = Dec128(BITS.LN10);
	immutable Dec128 LOG2_10  = Dec128(BITS.LOG2_10);
	immutable Dec128 SQRT2	 = Dec128(BITS.SQRT2);
	immutable Dec128 PHI 	 = Dec128(BITS.PHI);
	immutable Dec128 GAMMA	 = Dec128(BITS.GAMMA);
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
//	private this(const BITS bits) {
//		intBits = bits;
//	}

	private this(const ulong highBits, const ulong lowBits) {
		bits = uint128(highBits, lowBits);
	}

	unittest {	// classification tests
		Dec128 num;
		num = SNAN;
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = copyNegate(SNAN);
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(!num.isNormal);
		num = NAN;
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = copyNegate(NAN);
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(num.isQuiet);
		num = INFINITY;
		assert(num.isInfinite);
		assert(!num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = NEG_INF;
		assert(!num.isSignaling);
		assert(num.isInfinite);
		assert(num.isNegative);
		assert(!num.isFinite);
		num = ZERO;
		assert(num.isFinite);
		assert(num.isZero);
		assert(!num.isNegative);
		assert(num.isNormal);
		num = NEG_ZERO;
		assert(!num.isSignaling);
		assert(num.isZero);
		assert(num.isNegative);
		assert(num.isFinite);
	}

	/**
	 * Creates a Dec128 from a long integer.
	 */
	public this(const long n) {
		this = zero;
		sign = n < 0;
		coefficient = sign ? uint128(-n) : uint128(n);
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
		assert(num.toString == "1.234568E+9");
		num = Dec128(0);
		assert(num.toString == "0");
		num = Dec128(1);
		assert(num.toString == "1");
		num = Dec128(-1);
		assert(num.toString == "-1");
		num = Dec128(5);
		assert(num.toString == "5");
	}
*/
	/**
	 * Creates a Dec128 from a boolean value.
	 */
	public this(const bool value) {
		this = value ? ONE : ZERO;
	}

/*	Dec128 diff
	unittest {
		Dec128 num;
		num = Dec128(1234567890L);
		assert(num.toString == "1234567890"); //1.234567890E+9");
		num = Dec128(0);
		assert(num.toString == "0");
		num = Dec128(1);
		assert(num.toString == "1");
		num = Dec128(-1);
		assert(num.toString == "-1");
		num = Dec128(5);
		assert(num.toString == "5");
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
		assert(num.toString == "1.234567890E+14");
		num = Dec128(0, 2);
		assert(num.toString == "0E+2");
		num = Dec128(1, 75);
		assert(num.toString == "1E+75");
		num = Dec128(-1, -75);
		assert(num.toString == "-1E-75");
		num = Dec128(5, -3);
		assert(num.toString == "0.005");
		num = Dec128(true, 1234567890L, 5);
		assert(num.toString == "-1.234567890E+14");
		num = Dec128(0, 0, 2);
		assert(num.toString == "0E+2");
	}

	/**
	 * Creates a Dec128 from a boolean sign, an unsigned long integer,
	 * and an integer exponent.
	 */
	public this(const bool sign, const ulong mant, const int expo) {
		this(mant, expo);
		this.sign = sign;
	}

	unittest {
		Dec128 num;
		num = Dec128(1234567890L, 5);
		assert(num.toString == "1.234567890E+14");
		num = Dec128(0, 2);
		assert(num.toString == "0E+2");
		num = Dec128(1, 75);
		assert(num.toString == "1E+75");
		num = Dec128(-1, -75);
		assert(num.toString == "-1E-75");
		num = Dec128(5, -3);
		assert(num.toString == "0.005");
		num = Dec128(true, 1234567890L, 5);
		assert(num.toString == "-1.234567890E+14");
		num = Dec128(0, 0, 2);
		assert(num.toString == "0E+2");
	}

	/**
	 * Creates a Dec128 from a Decimal
	 */
	public this(const Decimal num) {
//writefln("num = %s", num);

		// check for special values
		if (num.isInfinite) {
			this = infinity(num.sign);
//writefln("this = %s", this);
			return;
		}
		if (num.isQuiet) {
			this = nan();
			this.sign = num.sign;
			this.payload = num.payload;
//writefln("this = %s", this);
			return;
		}
		if (num.isSignaling) {
			this = snan();
			this.sign = num.sign;
			this.payload = num.payload;
//writefln("this = %X", this);
			return;
		}

		Decimal big = plus!Decimal(num, context);
//writefln("big = %s", big);

		if (big.isFinite) {
			this = zero;
//writefln("big.coefficient = %s", big.coefficient);
			this.coefficient = uint128(big.coefficient);
//writefln("this.coefficient = %s", this.coefficient);
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
		Dec128 num = dec;
		assert(dec.toString == num.toString);
		dec = 1;
		num = dec;
//writefln("dec = |%s|", dec.toString);
//writefln("num = |%s|", num.toString);
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
	 * Creates a Dec128 from a string.
	 */
	public this(const string str) {
		Decimal big = Decimal(str);
//writefln("biggie = %s", big);
		this(big);
//writefln("this one = %s", this);
	}

	unittest {
		Dec128 num;
		num = Dec128("1.234568E+9");
		assert(num.toString == "1.234568E+9");
		num = Dec128("NaN");
		assert(num.isQuiet && num.isSpecial && num.isNaN);
		num = Dec128("-inf");
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
		// (128)TODO: this won't do -- no rounding has occured.
		string str = format("%.*G", cast(int)context.precision, r);
//writefln("r = %g", r);
//writefln("real str = %s", str);
		this(str);
//writefln("real this = %s", this);
	}

	unittest {
		float f = 1.2345E+16f;
//writefln("f = %g", f);
//string str = f;
		Dec128 actual = Dec128(f);
		Dec128 expect = Dec128("12344999802830847.999");
		assert(actual == expect);
		real r = 1.2345E+16;
		actual = Dec128(r);
		expect = Dec128("1.2345E+16");
		assert(actual == expect);
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

/*	/// Returns the raw bits of this number.
	@property
	const uint128 bits() {
		return this.bits;
	}

	/// Sets the raw bits of this number.
	@property
	uint128 bits(const uint128 raw) {
		this.bits = raw;
		return raw;
	}*/

	/// Returns the sign of this number.
	@property
	const bool sign() {
		return (highBits & SIGN_BIT) ? true: false;
	}

	/// Sets the sign of this number and returns the sign.
	@property
	bool sign(const bool value) {
		if (value) {
			highBits = highBits | SIGN_BIT;
		}
		else {
			highBits = highBits & (~SIGN_BIT);
		}
		return value;
	}

	/// Returns the exponent of this number.
	/// The exponent is undefined for infinities and NaNs: zero is returned.
	@property
	const int exponent() {
		if (this.isExplicit) {
			return cast(int)((highBits & EXPL_EXPO) >> EXPL_SHFT) - BIAS;
		}
		// infinity or NaN.
		return 0;
	}

	unittest {
		Dec128 num;
		int expect, actual;
		// reals
		num = std.math.PI;
		expect = -19;
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
/*
		// These should test rounding of long coefficients.
		num = Dec128("9.999998E23");
		expect = 17;
		actual = num.exponent;
		assert(actual == expect);
		num = Dec128("9.999999E23");
writefln("num = %s", num);
writefln("num.toAbstract = %s", num.toAbstract);
writefln("num.toExact = %s", num.toExact);
		expect = 8;
		actual = num.exponent;
		assert(actual == expect);*/
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
			this = sign ? NEG_INF : INFINITY;
			contextFlags.setFlags(OVERFLOW);
			return 0;
		}
		// check for underflow
		if (expo < context.minExpo) {
			// if the exponent is too small even for a subnormal number,
			// the number is set to zero.
			if (expo < context.tinyExpo) {
				this = sign ? NEG_ZERO : ZERO;
				setExplicitExponent(context.tinyExpo);
				contextFlags.setFlags(SUBNORMAL);
				contextFlags.setFlags(UNDERFLOW);
				return context.tinyExpo;
			}
			// at this point the exponent is between minExpo and tinyExpo.
			// (128)TODO: I don't think this needs special handling
		}
		// if explicit...
		if (this.isExplicit) {
			setExplicitExponent(expo);
			return expo;
		}
		// if this point is reached the number is either infinity or NaN;
		// these have undefined exponent values.
		contextFlags.setFlags(INVALID_OPERATION);
		this = nan;
		return 0;
	}

	private void setExplicitExponent(const int expo) {
		ulong biased = expo + BIAS;
		ulong expoMask = ~EXPL_EXPO;
		ulong high = highBits & expoMask;
		biased = biased << EXPL_SHFT;
		highBits = high | biased;
	}

	unittest {
		Dec128 num;
		num = Dec128(-12000,5);
		num.exponent = 10;
		assert(num.exponent == 10);
		num = Dec128(-9000053,-14);
		num.exponent = -27;
		assert(num.exponent == -27);
		num = infinity;
		assert(num.exponent == 0);
	}

	/// Returns the coefficient of this number.
	/// The exponent is undefined for infinities and NaNs: zero is returned.
	@property
	const uint128 coefficient() {
		if (this.isExplicit) {
			return uint128(highBits & EXPL_MANT, lowBits);
		}
		// Infinity or NaN.
		return uint128(0);
	}

	private void setCoefficient(uint128 mant) {
		ulong mantMask = ~EXPL_MANT;
		ulong high = highBits & mantMask;
		highBits = high | mant.getLong(0);
		lowBits = mant.getLong(1);
	}

	// Sets the coefficient of this number.
	@property
	uint128 coefficient(const uint128 mant) {
		// if not finite, convert to NaN and return 0.
		if (!this.isExplicit) {
			this = nan;
			contextFlags.setFlags(INVALID_OPERATION);
			return uint128(0);
		}
		// if too large, round
		if (mant > MAX_COEFFICIENT) {
			int expo = 0;
			uint digits = numDigits(mant);
			uint128 copy = mant;
			expo = setExponent(sign, copy, digits, context);
			setExplicitExponent(exponent + expo);
		}
		setCoefficient(mant);
		return mant;
	}

	unittest {
		Dec128 num;
		assert(num.coefficient == 0);
		num = Dec128("9.998742");
		assert(num.coefficient == 9998742);
//		num = 9.998743;
//		assert(num.coefficient == 9998742999999999);
		// note the difference between real and string values!
		num = Dec128("9.998743");
		assert(num.coefficient == 9998743);
		num = Dec128(9999213,-6);
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
			return cast(ushort)this.lowBits;
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
			this.lowBits(value);
			return cast(ushort)this.lowBits;
		}
		return 0;
	}

	unittest {
		Dec128 num;
		assert(num.payload == 0);
		num = snan;
		assert(num.payload == 0);
//writefln("num.payload = %s", num.payload);
		num.payload = 234;
//writefln("num.payload = %s", num.payload);
		assert(num.payload == 234);
		assert(num.toString == "sNaN234");
		num = 1234567;
		assert(num.payload == 0);
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
		return Dec128(1, -context.precision);
	}
//	static Dec128 min_normal() {
//		return Dec128(1, context.minExpo);
//	}
	static Dec128 min()		  {
		return Dec128(1, context.minExpo);
	} //context.tinyExpo); }

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

	/// Returns the maximum number of decimal digits in this ctx.
	static uint precision(const DecimalContext ctx = context32) {
		return ctx.precision;
	}
*/
	/*	static int dig()		{ return context.precision; }
		static int mant_dig()	{ return cast(int)context.mant_dig;; }
		static int max_10_exp() { return context.maxExpo; }
		static int min_10_exp() { return context.minExpo; }
		static int max_exp()	{ return cast(int)(context.maxExpo/LOG2); }
		static int min_exp()	{ return cast(int)(context.minExpo/LOG2); }*/

	/// Returns the maximum number of decimal digits in this ctx.
	static uint precision() {
		return context.precision;
	}


	/*	  /// Returns the maximum number of decimal digits in this ctx.
		static uint dig(const DecimalContext ctx = context) {
			return ctx.precision;
		}

		/// Returns the number of binary digits in this ctx.
		static uint mant_dig(const DecimalContext ctx = context) {
			return cast(int)ctx.mant_dig;
		}

		static int min_exp(const DecimalContext ctx = context) {
			return ctx.min_exp;
		}

		static int max_exp(const DecimalContext ctx = context) {
			return ctx.max_exp;
		}

//		/// Returns the minimum representable normal value in this ctx.
//		static Dec128 min_normal(const DecimalContext ctx = context) {
//			return Dec128(1, ctx.minExpo);
//		}

		/// Returns the minimum representable subnormal value in this ctx.
		static Dec128 min(const DecimalContext ctx = context) {
			return Dec128(1, ctx.tinyExpo);
		}

		/// returns the smallest available increment to 1.0 in this context
		static Dec128 epsilon(const DecimalContext ctx = context) {
			return Dec128(1, -ctx.precision);
		}

		static int min_10_exp(const DecimalContext ctx = context) {
			return ctx.minExpo;
		}

		static int max_10_exp(const DecimalContext ctx = context) {
			return ctx.maxExpo;
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
//		if (isInfinite) return padInf == 0;
//		if (isNaN) return sign == 0 && padNaN == 0;
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
//			copy.padInf = 0;
			return copy;
		}
		else { /* isNaN */
			copy.sign = 0;
//			copy.padNaN = 0;
			return copy;
		}
	}

	/**
	 * Returns true if this number is +\- zero.
	 */
	const bool isZero() {
		return isFinite && coefficient == 0;
	}

	/**
	 * Returns true if this number is a NaN or infinity.
	 */
	const bool isSpecial() {
		return (highBits & SPCL_TEST) == SPCL_TEST;
	}

	/**
	 * Returns true if this number is a quiet or signaling NaN.
	 */
	const bool isNaN() {
		return (highBits & NAN_TEST) == NAN_TEST;
	}

	/**
	 * Returns true if this number is a signaling NaN.
	 */
	const bool isSignaling() {
//writefln("highBits = %X", highBits);
//writefln("SIG_BITS = %X", SIG_BITS);
//writefln("SIG_TEST = %X", SIG_TEST);
//writefln("highBits & SIG_BITS = %X", highBits & SIG_BITS);
		return (highBits & SIG_BITS) == SIG_TEST;
	}

	/**
	 * Returns true if this number is a quiet NaN.
	 */
	const bool isQuiet() {
//writefln("highBits = %X", highBits);
//writefln("NAN_BITS = %X", NAN_BITS);
//writefln("highBits & NAN_BITS = %X", highBits & NAN_BITS);
		return (highBits & NAN_BITS) == NAN_TEST;
	}

	/**
	 * Returns true if this number is +\- infinity.
	 */
	const bool isInfinite() {
		return (highBits & INF_BITS) == INF_TEST;
	}

	/**
	 * Returns true if this number is neither infinite nor a NaN.
	 */
	const bool isFinite() {
		return !isSpecial;
	}

	const bool isExplicit() {
		return (highBits & IMPL_TEST) != IMPL_TEST;
	}

	const bool isImplicit() {
		return (highBits & IMPL_BITS) == IMPL_TEST;
	}

	/**
	 * Returns true if this number is negative. (Includes -0)
	 */
	const bool isSigned() {
		return (highBits & SIGN_BIT) ? true: false;
	}

	const bool isNegative() {
		return isSigned;
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
	const bool isSubnormal(const DecimalContext ctx = context) {
		if (isSpecial) return false;
		return adjustedExponent < ctx.minExpo;
	}

	/**
	 * Returns true if this number is normal.
	 */
	const bool isNormal(const DecimalContext ctx = context) {
		if (isSpecial) return false;
		return adjustedExponent >= ctx.minExpo;
	}

	/**
	 * Returns true if this number is an integer.
	 */
	const bool isIntegral(const DecimalContext ctx = context) {
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
		assert(num.isIntegral);
		num = 200E-2;
		assert(num.isIntegral);
		num = 201E-2;
		assert(!num.isIntegral);
		num = Dec128.INFINITY;
		assert(!num.isIntegral);
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
	 * Converts a Dec128 to a Decimal
	 */
	const Decimal toBigDecimal() {
		if (isFinite) {
			BigInt big = coefficient.toBigInt;
//writefln("coefficient = %s", coefficient);
//writefln("big = %s", big);
			return Decimal(sign, big, exponent);
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
		Dec128 num = Dec128("12345E+17");
		Decimal expect = Decimal("12345E+17");
		Decimal actual = num.toBigDecimal;
		assert(actual == expect);
	}

	const int toInt() {
		int n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec128(int.max) || (isInfinite && !isSigned)) return int.max;
		if (this < Dec128(int.min) || (isInfinite &&  isSigned)) return int.min;
		//quantize!Dec128(this, ONE, context);
		n = 0;  //cast(int)coefficient;
		return sign ? -n : n;
	}

// (128)TODO: These tests cause out-of-range errors in rounding

/*	unittest {
		Dec128 num;
		num = 12345;
		assert(num.toInt == 12345);
		num = 1.0E6;
		assert(num.toInt == 1000000);
		num = -1.0E60;
		assert(num.toInt == int.min);
		num = NEG_INF;
		assert(num.toInt == int.min);
	}*/

	const long toLong() {
		long n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > Dec128(long.max) || (isInfinite && !isSigned)) return long.max;
		if (this < Dec128(long.min) || (isInfinite &&  isSigned)) return long.min;
		//quantize!Dec128(this, ONE, context);
//writefln("coefficient = %s", coefficient);
		n = coefficient.toLong;
		return sign ? -n : n;
	}

/*	unittest {
		Dec128 num;
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
	}*/

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
//		return 0.0;
	}

	unittest {
//		write("toReal...");
		Dec128 num;
		real expect, actual;
		num = Dec128(1.5);
		expect = 1.5;
		actual = num.toReal;
		assert(actual == expect);
//		writeln("passed");
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
		assert(num.toString == "-1.2345E-41");
	}

	/**
	 * Creates an exact representation of this number.
	 */
	const string toExact() {
		return decimal.conv.toExact!Dec128(this);
	}


	unittest {
		Dec128 num;
		string expect, actual;
		expect = "+NaN";
		actual = num.toExact;
		assert(actual == expect);
//writefln("MAX = %s", MAX);
		num = Dec128.max;
//writefln("num = %s", num);
//writefln("num.toExact = %s", num.toExact);
//		num = Dec128("9999_9999_9999_99999_99999_9999_99999_9999_99E+1");
//writefln("num = %s", num);
		expect = "9.999999999999999999999999999999999E+6144";
		actual = num.toString;
		assert(actual == expect);
		expect = "+9999999999999999999999999999999999E+6111";
		actual = num.toExact;
		assert(actual == expect);
		num = Dec128.min;
		num = 1;
		assert(num.toExact == "+1E+00");
		num = infinity(true);
		assert(num.toExact == "-Infinity");
	}

	/**
	 * Creates an abstract representation of this number.
	 */
	const string toAbstract() {
		if (this.isFinite) {
			return format("[%d,%s,%d]", sign ? 1 : 0, coefficient, exponent);
		}
		if (this.isInfinite) {
			return format("[%d,%s]", sign ? 1 : 0, "inf");
		}
		if (this.isQuiet) {
			if (payload) {
				return format("[%d,%s,%d]", sign ? 1 : 0, "qNaN", payload);
			}
			return format("[%d,%s]", sign ? 1 : 0, "qNaN");
		}
		// this.isSignaling
		if (payload) {
			return format("[%d,%s,%d]", sign ? 1 : 0, "sNaN", payload);
		}
		return format("[%d,%s]", sign ? 1 : 0, "sNaN");
	}

	unittest {
		Dec128 num;
		num = Dec128("-25.67E+2");
		assert(num.toAbstract == "[1,2567,0]");
	}

	/**
	 * Converts this number to a hexadecimal string representation.
	 */
	const string toHexString() {
		return format("0x%016X%016X", highBits, lowBits);
	}

	/**
	 * Converts this number to a binary string representation.
	 */
	const string toBinaryString() {
		return format("%0#64b%0#64b", highBits, lowBits);
	}

	unittest {
		Dec128 num = 12345;
		string expect, actual;
		expect = "0x30400000000000000000000000003039";
		actual = num.toHexString;
		assert(actual == expect);
		expect = "00110000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000111001";
		actual = num.toBinaryString;
		assert(actual == expect);
	}

//--------------------------------
//	comparison
//--------------------------------

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
const int opCmp(T:Dec128)(const T that) {
		return 0; //compare!Dec128(this, that, context);
	}

	/**
	 * Returns -1, 0 or 1, if this number is less than, equal to or
	 * greater than the argument, respectively.
	 */
	const int opCmp(T)(const T that) if (isPromotable!T) {
		return opCmp!Dec128(Dec128(that));
	}

/*	unittest {
		Dec128 a, b;
		a = Dec128(104.0);
		b = Dec128(105.0);
		assert(a < b);
		assert(b > a);
	}*/

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
		// TODO: calls toBigDecimal
		return equals!Dec128(this, that, context);
//		return false;
	}

	unittest {
		Dec128 a, b;
		a = Dec128(105);
		b = Dec128(105);
		assert(a == b);
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
		assert(a == c);
		real d = 105.0;
writefln("d = %s", d);
writefln("a = %s", a);
writefln("a == d = %s", a == d);
//		assert(a == d);
		assert(a == 105);
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
		this.bits = that.bits;
	}

	unittest {
		Dec128 rhs, lhs;
		rhs = Dec128(270E-5);
		lhs = rhs;
		assert(lhs == rhs);
	}

	// (128)TODO: flags?
	///    Assigns a numeric value.
	void opAssign(T)(const T that) {
		this = Dec128(that);
	}

	unittest {
		Dec128 rhs;
		string expect, actual;
		rhs = 332089;
		expect = "332089";
		actual = rhs.toString;
		assert(actual == expect);
		rhs = Dec128("3.1415E+3");
		expect = "3141.5";
		actual = rhs.toString;
		assert(actual == expect);
		rhs = 3.1415E+3;
		actual = rhs.toString;
		assert(expect != actual);
	}

//--------------------------------
// unary operators
//--------------------------------

	const Dec128 opUnary(string op)() {
		static if (op == "+") {
			return plus!Dec128(this, context);
		} else static if (op == "-") {
			return minus!Dec128(this, context);
		} else static if (op == "++") {
			return add!Dec128(this, Dec128(1), context);
		} else static if (op == "--") {
			return sub!Dec128(this, Dec128(1), context);
		}
	}

	unittest {
		Dec128 num, actual, expect;
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
		num = Dec128(9999999, 90);
		expect = num;
		actual = num++;
		assert(actual == expect);
		num = Dec128("12.35");
		expect = Dec128("11.35");
		actual = --num;
		assert(actual == expect);
	}

//--------------------------------
// binary operators
//--------------------------------

const T opBinary(string op, T:Dec128)(const T rhs)
//	  const Dec128 opBinary(string op)(const Dec128 rhs)
	{
		static if (op == "+") {
			return add!Dec128(this, rhs, context);
		} else static if (op == "-") {
			return sub!Dec128(this, rhs, context);
		} else static if (op == "*") {
			return mul!Dec128(this, rhs, context);
		} else static if (op == "/") {
			return div!Dec128(this, rhs, context);
		} else static if (op == "%") {
			return remainder!Dec128(this, rhs, context);
		}
	}

	unittest {
		Dec128 op1, op2, actual, expect;
		op1 = 4;
		op2 = 8;
		actual = op1 + op2;
		expect = 12;
		assert(actual == expect);
		actual = op1 - op2;
		expect = -4;
		assert(actual == expect);
		actual = op1 * op2;
		expect = 32;
		assert(actual == expect);
		op1 = 5;
		op2 = 2;
		actual = op1 / op2;
		expect = Dec128("2.5");
writefln("expect = %s", expect);
writefln("actual = %s", actual);
writefln("actual == expect = %s", actual == expect);
//		assert(actual == expect);
		op1 = 10;
		op2 = 3;
		actual = op1 % op2;
		expect = 1;
		assert(actual == expect);
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
		Dec128 num, expect, actual;
		num = Dec128("591.3");
		expect = Dec128("2956.5");
		actual = num * 5;
		assert(actual == expect);
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
		op1 = Dec128("23.56");
		op2 = Dec128("-2.07");
		op1 += op2;
		expect = Dec128("21.49");
		actual = op1;
		assert(actual == expect);
		op1 *= op2;
		expect = Dec128("-44.4843");
		actual = op1;
		assert(actual == expect);
		op1 = 95;
		op1 %= 90;
		actual = op1;
		expect = 5;
		assert(actual == expect);
	}

	/**
	 * Returns a uint128 value of ten raised to the specified power.
	 */
	static uint128 pow10(const int n) {
		return uint128(10U)^^n;
	}

	unittest {
		int n;
		n = 3;
		assert(pow10(n) == 1000);
	}

	///	Returns the BigInt product of the coefficients
	public static BigInt bigmul(const Dec128 arg1, const Dec128 arg2) {
		BigInt big = arg1.coefficient.toBigInt;
		return big * arg2.coefficient.toBigInt;
	}

}	// end Dec128 struct

/*// NOTE: this is used only when a Decimal is converted to a Decimal128.
// The BigInt is guaranteed to be < uint128.max;
private uint128 toUint(BigInt big) {
writefln("big = %s", big);
writefln("big = %X", big);
	BigInt divisor = BigInt(1) << 64;
writefln("divisor = %X", divisor);
writefln("big/divisor = %X", big/divisor);
	ulong hi = (big / divisor).toLong;
writefln("hi = %X", hi);
writefln("big mod divisor = %X", big % divisor);
	ulong lo = (big % divisor).toLong;
writefln("lo = %X", lo);
	return uint128(hi, lo);
}*/

unittest {
	writeln("===================");
	writeln("dec128...........end");
	writeln("===================");
}

/*	// union providing different views of the number representation.
	union {
		uint128 intBits = uint128(0x7C00000000000000UL, 0x0000000000000000UL);
		union {	// entire 64-bit unsigned integer
			ulong hiWord; // = BITS.POS_NAN;    // set to the initial value: NaN

			// unsigned value and sign bit
			mixin (bitfields!(
				ulong, "uBits", unsignedBits,
				bool, "signed", signBit)
			);
			// Ex = explicit finite number:
			//	   full coefficient, exponent and sign
			mixin (bitfields!(
				ulong, "mantEx", EXPL_SHFT,
				uint, "expoEx", expoBits,
				bool, "signEx", signBit)
			);
			// Im = implicit finite number:
			//		partial coefficient, exponent, test bits and sign bit.
			mixin (bitfields!(
				ulong, "mantIm", IMPL_SHFT,
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
		ulong lowWord;
	}*/

/*	// (128)TODO: Move this test to test.d?
	unittest {
		Dec128 num;
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
	}*/

//--------------------------------
//	special bit patterns
//--------------------------------

/*private:
	// The value of the (6) special bits when the number is a signaling NaN.
	immutable uint SIG_BITS = 0x3F;
	// The value of the (6) special bits when the number is a quiet NaN.
	immutable uint NAN_BITS = 0x3E;
	// The value of the (5) special bits when the number is infinity.
	immutable uint INF_BITS = 0x1E;*/

//--------------------------------
//	special values and constants
//--------------------------------

// Integer values passed to the constructors are not copied but are modified
// and inserted into the sign, coefficient and exponent fields.
// This enum is used to force the constructor to copy the bit pattern,
// rather than treating it as a integer.

private const TEST = uint128(0x0UL, 0x0UL);

/*
private:
//	Dec128 diff
		// common small integers

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
*/

