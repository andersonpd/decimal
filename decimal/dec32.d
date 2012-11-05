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

module decimal.dec32;

import std.bigint;
import std.bitmanip;
import std.conv;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;

unittest {
	writeln("===================");
	writeln("dec32.........begin");
	writeln("===================");
}

struct Dec32 {

private:
	// The total number of bits in the decimal number.
	// This is equal to the number of bits in the underlying integer;
	// (must be 32, 64, or 128).
	immutable uint bitLength = 32;

	// the number of bits in the sign bit (1, obviously)
	immutable uint signBit = 1;

	// The number of bits in the unsigned value of the decimal number.
	immutable uint unsignedBits = 31; // = bitLength - signBit;

	// The number of bits in the (biased) exponent.
	immutable uint expoBits = 8;

	// The number of bits in the coefficient when the value is
	// explicitly represented.
	immutable uint explicitBits = 23;

	// The number of bits used to indicate special values and implicit
	// representation
	immutable uint testBits = 2;

	// The number of bits in the coefficient when the value is implicitly
	// represented. The three missing bits (the most significant bits)
	// are always '100'.
	immutable uint implicitBits = 21; // = explicitBits - testBits;

	// The number of special bits, including the two test bits.
	// These bits are used to denote infinities and NaNs.
	immutable uint specialBits = 4;

	// The number of bits that follow the special bits.
	// Their number is the number of bits in an special value
	// when the others (sign and special) are accounted for.
	immutable uint spclPadBits = 27;
	// = bitLength - specialBits - signBit;

	// The number of infinity bits, including the special bits.
	// These bits are used to denote infinity.
	immutable uint infinityBits = 5;

	// The number of bits that follow the special bits in infinities.
	// These bits are always set to zero in canonical representations.
	// Their number is the remaining number of bits in an infinity
	// when all others (sign and infinity) are accounted for.
	immutable uint infPadBits = 26;
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
	immutable uint nanPadBits = 9;
	// = bitLength - payloadBits - specialBits - signBit;

	// length of the coefficient in decimal digits.
	immutable int PRECISION = 7;
	// The maximum coefficient that fits in an explicit number.
	immutable uint C_MAX_EXPLICIT = 0x7FFFFF; // = 8388607;
	// The maximum coefficient allowed in an implicit number.
	immutable uint C_MAX_IMPLICIT = 9999999;  // = 0x98967F;
	// masks for coefficients
	immutable uint C_IMPLICIT_MASK = 0x1FFFFF;
	immutable uint C_EXPLICIT_MASK = 0x7FFFFF;

	// The maximum unbiased exponent. The largest binary number that can fit
	// in the width of the exponent field without setting
	// either of the first two bits to 1.
	immutable uint MAX_EXPO = 0xBF; // = 191
	// The exponent bias. The exponent is stored as an unsigned number and
	// the bias is subtracted from the unsigned value to give the true
	// (signed) exponent.
	immutable int BIAS = 101;		// = 0x65
	// The maximum representable exponent.
	immutable int E_LIMIT = 191;	// MAX_EXPO - BIAS
	// The min and max adjusted exponents.
	immutable int E_MAX =  96;		// E_LIMIT + PRECISION - 1
	immutable int E_MIN = -95;		// = 1 - E_MAX

	/// The context for this type.
	public static const DecimalContext
		context = DecimalContext(PRECISION, E_MAX, Rounding.HALF_EVEN);

	// union providing different views of the number representation.
	union {

		// entire 32-bit unsigned integer
		uint intBits = 0x7C000000;	  // set to the initial value: NaN

		// unsigned value and sign bit
		mixin (bitfields!(
			uint, "uBits", unsignedBits,
			bool, "signed", signBit)
		);
		// Ex = explicit finite number:
		//	   full coefficient, exponent and sign
		mixin (bitfields!(
			uint, "mantEx", explicitBits,
			uint, "expoEx", expoBits,
			bool, "signEx", signBit)
		);
		// Im = implicit finite number:
		//		partial coefficient, exponent, test bits and sign bit.
		mixin (bitfields!(
			uint, "mantIm", implicitBits,
			uint, "expoIm", expoBits,
			uint, "testIm", testBits,
			bool, "signIm", signBit)
		);
		// Spcl = special values: non-finite numbers
		//		unused bits, special bits and sign bit.
		mixin (bitfields!(
			uint, "padSpcl",  spclPadBits,
			uint, "testSpcl", specialBits,
			bool, "signSpcl", signBit)
		);
		// Inf = infinities:
		//		payload, unused bits, infinitu bits and sign bit.
		mixin (bitfields!(
			uint, "padInf",  infPadBits,
			uint, "testInf", infinityBits,
			bool, "signInf", signBit)
		);
		// Nan = not-a-number: qNaN and sNan
		//		payload, unused bits, nan bits and sign bit.
		mixin (bitfields!(
			ushort, "pyldNaN", payloadBits,
			uint, "padNaN",  nanPadBits,
			uint, "testNaN", nanBits,
			bool, "signNaN", signBit)
		);
	}

//--------------------------------
//	special bit patterns
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
	static enum BITS : uint
	{
		POS_SIG = 0x7E000000,
		NEG_SIG = 0xFE000000,
		POS_NAN = 0x7C000000,
		NEG_NAN = 0xFC000000,
		POS_INF = 0x78000000,
		NEG_INF = 0xF8000000,
		POS_ZRO = 0x32800000,
		NEG_ZRO = 0xB2800000,
		POS_MAX = 0x77F8967F,
		NEG_MAX = 0xF7F8967F,
		POS_ONE = 0x32800001,
		NEG_ONE = 0xB2800001,
		POS_TWO = 0x32800002,
		NEG_TWO = 0xB2800002,
		POS_FIV = 0x32800005,
		NEG_FIV = 0xB2800005,
		POS_TEN = 0x3280000A,
		NEG_TEN = 0xB280000A,

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
		E		= 0x2FA97A4A,
		LOG2_E	= 0x2F960387,
		LOG10_E = 0x2F4244A1,
		LN2 	= 0x2F69C410,
		LOG10_2 = 0x30007597,
		LN10	= 0x2FA32279,
		LOG2_10 = 0x2FB2B048,
		SQRT2	= 0x2F959446,
		SQRT1_2 = 0x2F6BE55C
	}

public:
	// special values
	immutable Dec32 NAN 	 = Dec32(BITS.POS_NAN);
	immutable Dec32 NEG_NAN  = Dec32(BITS.NEG_NAN);
	immutable Dec32 SNAN	 = Dec32(BITS.POS_SIG);
	immutable Dec32 NEG_SNAN = Dec32(BITS.NEG_SIG);
	immutable Dec32 INFINITY = Dec32(BITS.POS_INF);
	immutable Dec32 NEG_INF  = Dec32(BITS.NEG_INF);
	immutable Dec32 ZERO	 = Dec32(BITS.POS_ZRO);
	immutable Dec32 NEG_ZERO = Dec32(BITS.NEG_ZRO);
	immutable Dec32 MAX 	 = Dec32(BITS.POS_MAX);
	immutable Dec32 NEG_MAX  = Dec32(BITS.NEG_MAX);

	// small integers
	immutable Dec32 ONE 	 = Dec32(BITS.POS_ONE);
	immutable Dec32 NEG_ONE  = Dec32(BITS.NEG_ONE);
	immutable Dec32 TWO 	 = Dec32(BITS.POS_TWO);
	immutable Dec32 NEG_TWO  = Dec32(BITS.NEG_TWO);
	immutable Dec32 FIVE	 = Dec32(BITS.POS_FIV);
	immutable Dec32 NEG_FIVE = Dec32(BITS.NEG_FIV);
	immutable Dec32 TEN 	 = Dec32(BITS.POS_TEN);
	immutable Dec32 NEG_TEN  = Dec32(BITS.NEG_TEN);

	// mathamatical constants
	immutable Dec32 TAU 	 = Dec32(BITS.TAU);
	immutable Dec32 PI		 = Dec32(BITS.PI);
	immutable Dec32 PI_2	 = Dec32(BITS.PI_2);
	immutable Dec32 PI_SQR	 = Dec32(BITS.PI_SQR);
	immutable Dec32 SQRT_PI  = Dec32(BITS.SQRT_PI);
	immutable Dec32 SQRT_2PI = Dec32(BITS.SQRT_2PI);

	immutable Dec32 E		 = Dec32(BITS.E);
	immutable Dec32 LOG2_E	 = Dec32(BITS.LOG2_E);
	immutable Dec32 LOG10_E  = Dec32(BITS.LOG10_E);
	immutable Dec32 LN2 	 = Dec32(BITS.LN2);
	immutable Dec32 LOG10_2  = Dec32(BITS.LOG10_2);
	immutable Dec32 LN10	 = Dec32(BITS.LN10);
	immutable Dec32 LOG2_10  = Dec32(BITS.LOG2_10);
	immutable Dec32 SQRT2	 = Dec32(BITS.SQRT2);
	immutable Dec32 SQRT1_2	 = Dec32(BITS.SQRT1_2);
	immutable Dec32 PHI 	 = Dec32(BITS.PHI);
	immutable Dec32 GAMMA	 = Dec32(BITS.GAMMA);

	// boolean constants
	immutable Dec32 TRUE	 = ONE;
	immutable Dec32 FALSE	 = ZERO;

//--------------------------------
//	constructors
//--------------------------------

	/// Creates a Dec32 from a special value.
	private this(const BITS bits) {
		intBits = bits;
	}

	/// Creates a Dec32 from a long integer.
	public this(const long n) {
		this = zero;
		signed = n < 0;
		coefficient = signed ? -n : n;
	}

	unittest {	// this(long)
		Dec32 num;
		num = Dec32(1234567890L);
		assert(num.toString == "1.234568E+9");
		num = Dec32(0);
		assert(num.toString == "0");
		num = Dec32(1);
		assert(num.toString == "1");
		num = Dec32(-1);
		assert(num.toString == "-1");
		num = Dec32(5);
		assert(num.toString == "5");
	}

	/// Creates a Dec32 from a boolean value.
	public this(const bool value) {
		this = value ? ONE : ZERO;
	}

	/// Creates a Dec32 from a long integer coefficient and an int exponent.
	public this(const long mant, const int expo) {
		this(mant);
		exponent = exponent + expo;
	}

	unittest {	// this(long,int)
		Dec32 num;
		num = Dec32(1234567890L, 5);
		assert(num.toString == "1.234568E+14");
		num = Dec32(0, 2);
		assert(num.toString == "0E+2");
		num = Dec32(1, 75);
		assert(num.toString == "1E+75");
		num = Dec32(-1, -75);
		assert(num.toString == "-1E-75");
		num = Dec32(5, -3);
		assert(num.toString == "0.005");
		num = Dec32(true, 1234567890L, 5);
		assert(num.toString == "-1.234568E+14");
		num = Dec32(0, 0, 2);
		assert(num.toString == "0E+2");
	}

	///Creates a Dec32 from a boolean sign, an unsigned long
	/// coefficient, and an integer exponent.
	public this(const bool sign, const ulong mant, const int expo) {
		this(mant, expo);
		signed = sign;
	}

	unittest {	// this(bool, ulong, int)
		Dec32 num;
		num = Dec32(1234567890L, 5);
		assert(num.toString == "1.234568E+14");
		num = Dec32(0, 2);
		assert(num.toString == "0E+2");
		num = Dec32(1, 75);
		assert(num.toString == "1E+75");
		num = Dec32(-1, -75);
		assert(num.toString == "-1E-75");
		num = Dec32(5, -3);
		assert(num.toString == "0.005");
		num = Dec32(true, 1234567890L, 5);
		assert(num.toString == "-1.234568E+14");
		num = Dec32(0, 0, 2);
		assert(num.toString == "0E+2");
	}

	/// Creates a Dec32 from a Decimal
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

		// must be finite
		// copy and round to this context
		Decimal big = plus!Decimal(num, context);

		// check that it's still finite after rounding
		if (big.isFinite) {
			this = zero;
			this.coefficient = cast(ulong)big.coefficient.toLong;
			this.exponent = big.exponent;
			this.sign = big.sign;
			return;
		}
		// special values
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

	unittest {	// this(Decimal)
		Decimal dec = 0;
		Dec32 num = dec;
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
		assert(num.toString == "4.294967E+9");
		assert(dec.toString == "4294967295");
		dec = 9999999E+12;
		num = dec;
		assert(dec.toString == num.toString);
	}

	/// Creates a Dec32 from a string.
	public this(const string str) {
		Decimal big = Decimal(str);
		this(big);
	}

	unittest {	// this(string)
		Dec32 num;
		num = Dec32("1.234568E+9");
		assert(num.toString == "1.234568E+9");
		num = Dec32("NaN");
		assert(num.isQuiet && num.isSpecial && num.isNaN);
		num = Dec32("-inf");
		assert(num.isInfinite && num.isSpecial && num.isNegative);
	}

	///	Constructs a number from a real value.
	public this(const real r) {
		// check for special values
		if (!std.math.isFinite(r)) {
			this = std.math.isInfinity(r) ? INFINITY : NAN;
			this.sign = cast(bool)std.math.signbit(r);
			return;
		}
		string str = format("%.*G", cast(int)context.precision + 2, r);
		this(str);
	}

	unittest {	// this(real)
		float f = 1.2345E+16f;
		Dec32 actual = Dec32(f);
		Dec32 expect = Dec32("1.2345E+16");
		assert(actual == expect);
		real r = 1.2345E+16;
		actual = Dec32(r);
		expect = Dec32("1.2345E+16");
		assert(actual == expect);
	}

	/// Copy constructor.
	public this(const Dec32 that) {
		this.bits = that.bits;
	}

	/// Returns a mutable copy
	public const Dec32 dup() {
		return Dec32(this);
	}

//--------------------------------
//	properties
//--------------------------------

public:

	/// Returns the raw bits of the number.
	@property
	const uint bits() {
		return intBits;
	}

	/// Sets the raw bits of the number.
	@property
	uint bits(const uint raw) {
		intBits = raw;
		return intBits;
	}

	/// Returns the sign of the number.
	@property
	const bool sign() {
		return signed;
	}

	/// Sets the sign of the number and returns the sign.
	@property
	bool sign(const bool value) {
		signed = value;
		return signed;
	}

	/// Returns the exponent of the number.
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

	/// Sets the exponent of the number.
	/// If the number is infinity or NaN, the number is converted to
	/// a quiet NaN and the invalid operation flag is set.
	/// Otherwise, if the input value exceeds the maximum allowed exponent,
	/// the number is converted to infinity and the overflow flag is set.
	/// If the input value is less than the minimum allowed exponent,
	/// the number is converted to zero, the exponent is set to tinyExpo
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
			// NOTE: I don't think this needs special handling
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

	unittest {	// exponent
		Dec32 num;
		// reals
		num = std.math.PI;
		assert(num.exponent == -6);
		num = 9.75E89;
		assert(num.exponent == 87);
		// explicit
		num = 8388607;
		assert(num.exponent == 0);
		// implicit
		num = 8388610;
		assert(num.exponent == 0);
		num = 9.999998E23;
		assert(num.exponent == 17);
		num = 9.999999E23;
		assert(num.exponent == 17);
		// setter
		num = Dec32(-12000,5);
		num.exponent = 10;
		assert(num.exponent == 10);
		num = Dec32(-9000053,-14);
		num.exponent = -27;
		assert(num.exponent == -27);
		num = Dec32.infinity;
		assert(num.exponent == 0);
	}

	/// Returns the coefficient of the number.
	/// The exponent is undefined for infinities and NaNs: zero is returned.
	@property
	const uint coefficient() {
		if (this.isExplicit) {
			return mantEx;
		}
		if (this.isFinite) {
			return mantIm | (0b100 << implicitBits);
		}
		// Infinity or NaN.
		return 0;
	}

	// Sets the coefficient of the number. This may cause an
	// explicit number to become an implicit number, and vice versa.
	@property
	uint coefficient(const ulong mant) {
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
		// at this point, the number <= C_MAX_IMPLICIT
		if (copy <= C_MAX_EXPLICIT) {
			// if implicit, convert to explicit
			if (this.isImplicit) {
				expoEx = expoIm;
			}
			mantEx = cast(uint)copy;
			return mantEx;
		}
		else {	// copy <= C_MAX_IMPLICIT
			// if explicit, convert to implicit
			if (this.isExplicit) {
				expoIm = expoEx;
				testIm = 0x3;
			}
			mantIm = cast(uint)copy & C_IMPLICIT_MASK;
			return mantIm | (0b100 << implicitBits);
		}
	}

	unittest {	// coefficient
		Dec32 num;
		assert(num.coefficient == 0);
		num = 9.998743;
		assert(num.coefficient == 9998743);
		num = Dec32(9999213,-6);
		assert(num.coefficient == 9999213);
		num = -125;
		assert(num.coefficient == 125);
		num = -99999999;
		assert(num.coefficient == 1000000);
	}

	/// Returns the number of digits in the number's coefficient.
	@property
	const int digits() {
		return numDigits(this.coefficient);
	}

	/// Has no effect.
	@property
	const int digits(const int digs) {
		return digits;
	}

	/// Returns the payload of the number.
	/// If this is a NaN, returns the value of the payload bits.
	/// Otherwise returns zero.
	@property
	const ushort payload() {
		if (this.isNaN) {
			return pyldNaN;
		}
		return 0;
	}

	// (32)TODO: need to ensure this won't overflow into other bits.
	/// Sets the payload of the number.
	/// If the number is not a NaN (har!) no action is taken and zero
	/// is returned.
	@property
	ushort payload(const ushort value) {
		if (isNaN) {
			pyldNaN = value;
			return pyldNaN;
		}
		return 0;
	}

	unittest {	// payload
		Dec32 num;
		assert(num.payload == 0);
		num = Dec32.snan;
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

	static Dec32 zero(const bool signed = false) {
		return signed ? NEG_ZERO : ZERO;
	}

	static Dec32 max(const bool signed = false) {
		return signed ? NEG_MAX : MAX;
	}

	static Dec32 infinity(const bool signed = false) {
		return signed ? NEG_INF : INFINITY;
	}

	static Dec32 nan(const ushort payload = 0) {
		if (payload) {
			Dec32 result = NAN;
			result.payload = payload;
			return result;
		}
		return NAN;
	}

	static Dec32 snan(const ushort payload = 0) {
		if (payload) {
			Dec32 result = SNAN;
			result.payload = payload;
			return result;
		}
		return SNAN;
	}

	// floating point properties
	static Dec32 init() 	  { return NAN; }
	static Dec32 epsilon()	  { return Dec32(1, -7); }
	static Dec32 min()		  { return Dec32(1, context.tinyExpo); }

	static int dig()		{ return 7; }
	static int mant_dig()	{ return 24; }
	static int max_10_exp() { return context.maxExpo; }
	static int min_10_exp() { return context.minExpo; }
	static int max_exp()	{ return cast(int)(context.maxExpo/std.math.LOG2); }
	static int min_exp()	{ return cast(int)(context.minExpo/std.math.LOG2); }

	/// Returns the maximum number of decimal digits in this context.
	static uint precision(const DecimalContext context = this.context) {
		return context.precision;
	}

	/// Returns the maximum number of decimal digits in this context.
	static uint dig(const DecimalContext context = this.context) {
		return context.precision;
	}

	/// Returns the minimum representable subnormal value in this context.
	/// NOTE: Creation of any number will not set the
	/// subnormal flag until it is used. The operations will
	/// set the flags as needed.
	static Dec32 min(const DecimalContext context = this.context) {
		return Dec32(1, context.tinyExpo);
	}

	/// returns the smallest available increment to 1.0 in this context
	static Dec32 epsilon(const DecimalContext context = this.context) {
		return Dec32(1, -context.precision);
	}

	/// Returns the radix (10)
	immutable int radix = 10;

//--------------------------------
//	classification properties
//--------------------------------

	/// Returns true if the number's representation is canonical.
	/// Finite numbers are always canonical.
	/// Infinities and NaNs are canonical if their unused bits are zero.
	const bool isCanonical() {
		if (isInfinite) return padInf == 0;
		if (isNaN) return signed == 0 && padNaN == 0;
		// finite numbers are always canonical
		return true;
	}

	/// Returns a copy of the number in canonical form.
	/// Finite numbers are always canonical.
	/// Infinities and NaNs are canonical if their unused bits are zero.
	const Dec32 canonical() {
		Dec32 copy = this;
		if (!this.isSpecial) return copy;
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

	/// Returns true if the number is +\- zero.
	const bool isZero() {
		return isExplicit && mantEx == 0;
	}

	/// Returns true if the number is a quiet or signaling NaN.
	const bool isNaN() {
		return testNaN == NAN_BITS || testNaN == SIG_BITS;
	}

	/// Returns true if the number is a signaling NaN.
	const bool isSignaling() {
		return testNaN == SIG_BITS;
	}

	/// Returns true if the number is a quiet NaN.
	const bool isQuiet() {
		return testNaN == NAN_BITS;
	}

	/// Returns true if the number is +\- infinity.
	const bool isInfinite() {
		return testInf == INF_BITS;
	}

	/// Returns true if the number is neither infinite nor a NaN.
	const bool isFinite() {
		return testSpcl != 0xF;
	}

	/// Returns true if the number is a NaN or infinity.
	const bool isSpecial() {
		return testSpcl == 0xF;
	}

	const bool isExplicit() {
		return testIm != 0x3;
	}

	const bool isImplicit() {
		return testIm == 0x3 && testSpcl != 0xF;
	}

	/// Returns true if the number is negative. (Includes -0)
	const bool isSigned() {
		return signed;
	}

	const bool isNegative() {
		return signed;
	}

	const bool isPositive() {
		return !isNegative;
	}

	// NOTE: NaN is false, Infinity is true
	const bool isTrue() {
		return !isNaN || isInfinite || coefficient != 0;
	}

	// NOTE: NaN is false, Infinity is true
	const bool isFalse() {
		return isNaN || (isFinite && coefficient == 0);
	}

	const bool isZeroCoefficient() {
		return !isSpecial && coefficient == 0;
	}

	/// Returns true if the number is subnormal.
	const bool isSubnormal(const DecimalContext context = this.context) {
		if (isSpecial) return false;
		return adjustedExponent < context.minExpo;
	}

	/// Returns true if the number is normal.
	const bool isNormal(const DecimalContext context = this.context) {
		if (isSpecial) return false;
		return adjustedExponent >= context.minExpo;
	}

	/// Returns the value of the adjusted exponent.
	const int adjustedExponent() {
		return exponent + digits - 1;
	}

	unittest {	// classification
		Dec32 num;
		num = Dec32.snan;
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num.sign = true;
		assert(num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(!num.isNormal);
		num = Dec32.nan;
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num.sign = true;
		assert(!num.isSignaling);
		assert(num.isNaN);
		assert(num.isNegative);
		assert(num.isQuiet);
		num = Dec32.infinity;
		assert(num.isInfinite);
		assert(!num.isNaN);
		assert(!num.isNegative);
		assert(!num.isNormal);
		num = Dec32.infinity(true);
		assert(!num.isSignaling);
		assert(num.isInfinite);
		assert(num.isNegative);
		assert(!num.isFinite);
		num = Dec32.zero;
		assert(num.isFinite);
		assert(num.isZero);
		assert(!num.isNegative);
		assert(num.isNormal);
		num = Dec32.zero(true);
		assert(!num.isSignaling);
		assert(num.isZero);
		assert(num.isNegative);
		assert(num.isFinite);
	}

	/// Returns true if the number is an integer.
	const bool isIntegral() {
		if (isSpecial) return false;
		if (exponent >= 0) return true;
		uint expo = std.math.abs(exponent);
		if (expo >= PRECISION) return false;
		if (coefficient % 10^^expo == 0) return true;
		return false;
	}

	unittest {	// isIntegral
		Dec32 num;
		num = 22;
		assert(num.isIntegral);
		num = 200E-2;
		assert(num.isIntegral);
		num = 201E-2;
		assert(!num.isIntegral);
		num = Dec32.INFINITY;
		assert(!num.isIntegral);
	}

//--------------------------------
//	conversions
//--------------------------------

	/// Converts a Dec32 to a Decimal
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
			dec = Decimal.nan;
		}
		if (isSignaling) {
			dec = Decimal.snan(sign);
		}
		if (payload) {
			dec.payload(payload);
		}
		if (isSigned) dec.sign = true;
		return dec;
	}

	unittest {	// toBigDecimal
		Dec32 num = Dec32("12345E+17");
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
		if (this > Dec32(int.max) || (isInfinite && !isSigned)) return int.max;
		if (this < Dec32(int.min) || (isInfinite &&  isSigned)) return int.min;
		quantize!Dec32(this, ONE, context);
		n = coefficient;
		return signed ? -n : n;
	}

	unittest {	// toInt
		Dec32 num;
		num = 12345;
		assert(num.toInt == 12345);
		num = 1.0E6;
		assert(num.toInt == 1000000);
		num = -1.0E60;
		assert(num.toInt == int.min);
		num = Dec32.NEG_INF;
		assert(num.toInt == int.min);
	}

	const long toLong() {
		long n;
		if (isNaN) {
			contextFlags.setFlags(INVALID_OPERATION);
			return 0;
		}
		if (this > long.max || (isInfinite && !isSigned)) return long.max;
		if (this < long.min || (isInfinite &&  isSigned)) return long.min;
		quantize!Dec32(this, ONE, context);
		n = coefficient;
		return signed ? -n : n;
	}

	unittest {	// toLong
		Dec32 num;
		num = -12345;
		assert(num.toLong == -12345);
		num = 2 * int.max;
		assert(num.toLong == 2 * int.max);
		num = 1.0E6;
		assert(num.toLong == 1000000);
		num = -1.0E60;
		assert(num.toLong == long.min);
		num = Dec32.NEG_INF;
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
		Dec32 num;
		real expect, actual;
		num = Dec32(1.5);
		expect = 1.5;
		actual = num.toReal;
		assert(actual == expect);
		writeln("passed");
	}

	// Converts the number to an exact scientific-style string representation.
	const string toSciString() {
		return decimal.conv.sciForm!Dec32(this);
	}

	// Converts the number to an exact engineering-style string representation.
	const string toEngString() {
		return decimal.conv.engForm!Dec32(this);
	}

	// Converts a Dec32 to a standard string
	const public string toString() {
		 return toSciString();
	}

	unittest {	// toString
		string str;
		str = "-12.345E-42";
		Dec32 num = Dec32(str);
		assert(num.toString == "-1.2345E-41");
	}

	/// Creates an exact representation of the number.
	const string toExact() {
		return decimal.conv.toExact!Dec32(this);
	}

	unittest {	// toExact
		Dec32 num;
		assert(num.toExact == "+NaN");
		num = Dec32.max;
		assert(num.toExact == "+9999999E+90");
		num = 1;
		assert(num.toExact == "+1E+00");
	//	num = C_MAX_EXPLICIT;
	//	assert(num.toExact == "+8388607E+00");
		num = Dec32.infinity(true);
		assert(num.toExact == "-Infinity");
	}

	// TODO: use conversion module
	/// Creates an abstract representation of the number.
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

	unittest {	// toAbstract
		Dec32 num;
		num = Dec32("-25.67E+2");
		assert(num.toAbstract == "[1,2567,0]");
	}

	/// Converts the number to a hexadecimal string representation.
	const string toHexString() {
		 return format("0x%08X", bits);
	}

	/// Converts the number to a binary string.
	const string toBinaryString() {
		return format("%0#32b", bits);
	}

	unittest {	// toHex, toBinary
		Dec32 num = 12345;
		assert(num.toHexString == "0x32803039");
		assert(num.toBinaryString == "00110010100000000011000000111001");
	}

//--------------------------------
//	comparison
//--------------------------------

	/// Returns -1, 0 or 1, if the number is less than, equal to or
	/// greater than the argument, respectively.
	const int opCmp(T:Dec32)(const T that) {
		return compare!Dec32(this, that, context);
	}

	/// Returns -1, 0 or 1, if the number is less than, equal to or
	/// greater than the argument, respectively.
	const int opCmp(T)(const T that) if (isPromotable!T) {
		return opCmp!Dec32(Dec32(that));
	}

	 /// Returns true if the number is equal to the specified number.
	const bool opEquals(T:Dec32)(const T that) {
		// quick bitwise check
		if (this.bits == that.bits) {
			if (!this.isSpecial) return true;
			if (this.isQuiet) return false;
			// let the main routine handle the signaling NaN
		}
		return equals!Dec32(this, that, context);
	}

	 /// Returns true if the number is equal to the specified number.
	const bool opEquals(T)(const T that) if (isPromotable!T) {
		return opEquals!Dec32(Dec32(that));
	}

	/// Returns true if the numbers are identical.
	const bool isIdentical(const Dec32 that) {
		return this.bits == that.bits;
	}

	unittest {	// comparison
		Dec32 a, b;
		a = Dec32(104);
		b = Dec32(105);
		assert(a < b);
		assert(b > a);
		a = Dec32(105);
		assert(a == b);
		int c = 105;
		assert(a == c);
		real d = 105.0;
		assert(a == d);
		assert(a == 105);
	}

//--------------------------------
// assignment
//--------------------------------

	// (32)TODO: flags?
	/// Assigns a Dec32 (copies that to this).
	void opAssign(T:Dec32)(const T that) {
		this.intBits = that.intBits;
	}

	// (32)TODO: flags?
	///    Assigns a numeric value.
	void opAssign(T)(const T that) {
		this = Dec32(that);
	}

	unittest {	// opAssign
		Dec32 that, lhs;
		that = Dec32(270E-5);
		lhs = that;
		assert(lhs == that);
		that = 332089;
		assert(that.toString == "332089");
		that = 3.1415E+3;
		assert(that.toString == "3141.5");
	}

//--------------------------------
// unary operators
//--------------------------------

	const Dec32 opUnary(string op)() {
		static if (op == "+") {
			return plus!Dec32(this, context);
		} else static if (op == "-") {
			return minus!Dec32(this, context);
		} else static if (op == "++") {
			return add!Dec32(this, ONE, context);
		} else static if (op == "--") {
			return sub!Dec32(this, ONE, context);
		}
	}

	unittest {	// opUnary
		Dec32 num, actual, expect;
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
		num = 1.00E12;
		expect = num;
		actual = --num;
		assert(actual == expect);
		actual = num--;
		assert(actual == expect);
		num = 1.00E12;
		expect = num;
		actual = ++num;
		assert(actual == expect);
		actual = num++;
		assert(actual == expect);
		num = Dec32(9999999, 90);
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

	const T opBinary(string op, T:Dec32)(const T that)
	{
		static if (op == "+") {
			return add!Dec32(this, that, context);
		} else static if (op == "-") {
			return sub!Dec32(this, that, context);
		} else static if (op == "*") {
			return mul!Dec32(this, that, context);
		} else static if (op == "/") {
			return div!Dec32(this, that, context);
		} else static if (op == "%") {
			return remainder!Dec32(this, that, context);
		} else static if (op == "&") {
			return and!Dec32(this, that, context);
		} else static if (op == "|") {
			return or!Dec32(this, that, context);
		} else static if (op == "^") {
			return xor!Dec32(this, that, context);
		}
	}

	/// Detect whether T is promotable to decimal32 type.
	private template isPromotable(T) {
		enum bool isPromotable = is(T:ulong) || is(T:real);
	}

	const Dec32 opBinary(string op, T)(const T that) if (isPromotable!T) {
		return opBinary!(op,Dec32)(Dec32(that));
	}

	unittest {	// opBinary
		Dec32 op1, op2, actual, expect;
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
		expect = 2.5;
		assert(actual == expect);
		op1 = 10;
		op2 = 3;
		actual = op1 % op2;
		expect = 1;
		assert(actual == expect);
		op1 = Dec32("101");
		op2 = Dec32("110");
		actual = op1 & op2;
		expect = 100;
		assert(actual == expect);
		actual = op1 | op2;
		expect = 111;
		assert(actual == expect);
		actual = op1 ^ op2;
		expect = 11;
		assert(actual == expect);
		Dec32 num = Dec32(591.3);
		Dec32 result = num * 5;
		assert(result == Dec32(2956.5));
	}

//-----------------------------
// operator assignment
//-----------------------------

	ref Dec32 opOpAssign(string op, T:Dec32) (T that) {
		this = opBinary!op(that);
		return this;
	}

 	ref Dec32 opOpAssign(string op, T) (T that) if (isPromotable!T) {
		this = opBinary!op(that);
		return this;
	}

	unittest {	// opOpAssign
		Dec32 op1, op2, actual, expect;
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

	/// Returns uint ten raised to the specified power.
	static uint pow10(const int n) {
		// TODO: limit n to max exponent
		return cast(uint)TENS[n];
	}

	unittest { // pow10
		int n;
		n = 3;
		assert(Dec32.pow10(n) == 1000);
	}

	///	Helper function used in arithmetic multiply
	static BigInt bigmul(const Dec32 arg1, const Dec32 arg2) {
		BigInt big = BigInt(arg1.coefficient);
		return big * arg2.coefficient;
	}

}	// end Dec32 struct

// (32)TODO: set context flags
public Dec32 sqrt(Dec32 arg) {
	if (arg.isNaN) {
		// (32)TODO: set a flag
		return Dec32.NAN;
	}
	if (arg.isZero) {
		return Dec32.zero(arg.sign);
	}
	if (arg.isNegative) {
		return Dec32.NAN;
	}
	if (arg.isInfinite) {
		return Dec32.INFINITY;
	}
	return Dec32(std.math.sqrt(arg.toReal));
}

unittest {
	write("sqrt...");
	Dec32 num = 1.0;
	assert(num ==  sqrt(num));
	num = 2.0;
	assert(Dec32(std.math.sqrt(2.0)) ==  sqrt(num));
	assert(Dec32.SQRT_PI ==  sqrt(Dec32.PI));
	num = 2174;
	assert(Dec32(std.math.sqrt(2174.0)) ==  sqrt(num));
	writeln("test missing");
}

public Dec32 exp(Dec32 arg) {
	if (arg.isNaN) {
		return Dec32.NAN;
	}
	if (arg.isInfinite) {
		if (arg.isNegative) {
			return Dec32.ZERO;
		}
		else {
			return Dec32.INFINITY;
		}
	}
	if (arg.isZero) {
		return Dec32.ONE;
	}
//	if (arg == Dec32.ONE) {
//		return arg;
//	}
	return Dec32(std.math.exp(arg.toReal));
}

unittest {
	write("exp...");
	writeln("test missing");
}

public Dec32 ln(Dec32 arg) {
	if (arg.isNegative || arg.isNaN) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	if (arg.isInfinite) {
		return Dec32.INFINITY;
	}
	if (arg.isZero) {
		return Dec32.NEG_INF;
	}
	if (arg == Dec32.ONE) {
		return Dec32.ZERO;
	}
	// (32)TODO: check for a NaN? or special value?
	return Dec32(std.math.log(arg.toReal));
}


unittest {
	write("ln...");
	writeln("test missing");
}

public Dec32 log10(Dec32 arg) {
	if (arg.isNegative || arg.isNaN) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	if (arg.isInfinite) {
		return Dec32.INFINITY;
	}
	if (arg.isZero) {
		return Dec32.NEG_INF;
	}
	if (arg == Dec32.ONE) {
		return Dec32.ZERO;
	}
	// (32)TODO: check for a NaN? or special value?
	return Dec32(std.math.log10(arg.toReal));
}

unittest {
	write("log10...");
	writeln("test missing");
}

/// a decimal32 raised to an integer power
public Dec32 power(Dec32 x, int n) {
	// if x is NaN, result is NaN
	if (x.isNaN) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	// if x and n are zero, result is NaN
	if (x.isZero && n == 0) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	// if n is zero, result is one
	if (n == 0) {
		return Dec32.ONE;
	}
	// if x is infinite, result is infinity or zero:
	// for +infinity...
	if (x == Dec32.INFINITY) {
		if (n > 0) {  // if positive
			return Dec32.INFINITY;
		}
		else {
			return Dec32.ZERO;
		}
	}
	// for -infinity...
	if (x == Dec32.NEG_INF) {
		if (n > 0) {  // if positive
			return Dec32.infinity(isOdd(n));	// if n is odd, sign matches x
		}
		else {
			return Dec32.zero(isOdd(n));	// if n is odd, sign matches x
		}
	}
	// if x is zero, result is infinity or zero:
	// for +zero...
	if (x == Dec32.ZERO) {
		if (n > 0) {  // if positive
			return Dec32.ZERO;
		}
		else {
			return Dec32.INFINITY;
		}
	}
	// for -zero...
	if (x == Dec32.NEG_ZERO) {
		if (n > 0) {  // if positive
			return Dec32.zero(isOdd(n));	// if n is odd, sign matches x
		}
		else {
			return Dec32.infinity(isOdd(n));	// if n is odd, sign matches x
		}
	}
	// (32)TODO: this is a place where an integer op is needed
	return exp(Dec32(n) * ln(x));
}

public Dec32 power(Dec32 x, Dec32 y) {
	if (y.isIntegral) {
		return power(x, y.toInt);
	}
	// if either arg is NaN, result is NaN
	if (x.isNaN || y.isNaN) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	// if both args are zero, result is NaN
	if (x.isZero && y.isZero) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	// if y is zero, result is one
	if (y.isZero) {
		return Dec32.ONE;
	}
	// if x is infinite, result is infinity or zero
	if (x.isInfinite) {
		return y.isNegative ? Dec32.ZERO : Dec32.INFINITY;
	}
	// x is zero, result is zero or infinity
	if (x.isZero) {
		return y.isNegative ? Dec32.INFINITY : Dec32.ZERO;
	}
	// if x is negative, result is a NaN
	if (x.isNegative) {
		// set invalid op flag(?)
		return Dec32.NAN;
	}
	// at this point all the special cases have been checked
	// result will be inexact
	return exp(y * ln(x));
}

unittest {
	write("power...");
	writeln("test missing");
}

unittest {
	writeln("===================");
	writeln("dec32...........end");
	writeln("===================");
}

