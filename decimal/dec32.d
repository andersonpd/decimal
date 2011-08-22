// Written in the D programming language

/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */
/*          Copyright Paul D. Anderson 2009 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */

module decimal.dec32;

import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.stdio;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;
import decimal.rounding;

struct Dec32 {


    /// The global context for this type.
    private static decimal.context.DecimalContext context32 = {
        precision : 7,
        rounding : Rounding.HALF_EVEN,
        eMax : E_MAX
    };

    /// The number of bits in the signed value of the decimal number.
    /// This is equal to the number of bits in the underlying integer;
    /// (must be 32, 64, or 128).
    immutable uint svalBits = 32;

    /// the number of bits in the sign bit (1, obviously)
    immutable uint signBit = 1;

    /// The number of bits in the unsigned value of the decimal number.
    immutable uint unsignedBits = 31; // = svalBits - signBit;

    /// The number of bits in the (biased) exponent.
    immutable uint expoBits = 8;

    /// The number of bits in the coefficient when the value is
    /// explicitly represented.
    immutable uint explicitBits = 23;

    /// The number of bits used to indicate special values and implicit
    /// representation
    immutable uint testBits = 2;

    /// The number of bits in the coefficient when the value is implicitly
    /// represented. The three missing bits (the most significant bits)
    /// are always '100'.
    immutable uint implicitBits = 21; // = explicitBits - testBits;

    /// The number of special bits, including the two test bits.
    /// These bits are used to denote infinities and NaNs.
    immutable uint specialBits = 6;

    /// The number of infinity bits, a subset of the special bits.
    /// These bits are used to denote infinity.
    immutable uint infinityBits = 5;

    /// The number of bits in the payload of a NaN.
    immutable uint payloadBits = 16;

    /// The number of bits that follow the special bits in NaNs.
    /// These bits are always set to zero in canonical representations.
    /// Their number is the remaining number of bits in a NaN
    /// when all others (sign, special and payload) are accounted for.
    immutable uint nanPadBits = 9;
            // = svalBits - payloadBits - specialBits - signBit;

    /// The number of bits that follow the special bits in infinities.
    /// These bits are always set to zero in canonical representations.
    /// Their number is the remaining number of bits in an infinity
    /// when all others (sign and infinity) are accounted for.
    immutable uint infPadBits = 26;
            // = svalBits - infinityBits - signBit;

    /// The exponent bias. The exponent is stored as an unsigned number and
    /// the bias is subtracted from the unsigned value to give the true
    /// (signed) exponent.
    immutable int BIAS = 101;   // = 0x65

    /// The maximum biased exponent.
    /// The largest binary number that can fit in the width of the
    /// exponent without setting either of the first two bits to 1.
    immutable uint MAX_BSXP = 0xBF; // = 191

    // length of the coefficient in decimal digits.
    immutable int MANT_LENGTH = 7;
    // The maximum coefficient that fits in an explicit number.
    immutable uint MAX_XPLC = 0x7FFFFF; // = 8388607;
    // The maximum coefficient allowed in an implicit number.
    immutable uint MAX_IMPL = 9999999;  // = 0x98967F;
    // The maximum representable exponent.
    immutable int  MAX_EXPO  =   90;    // = MAX_BSXP - BIAS;
    // The minimum representable exponent.
    immutable int  MIN_EXPO  = -101;    // = 0 - BIAS.

    // The min and max adjusted exponents.
    immutable int E_MAX   = MAX_EXPO;
    immutable int E_MIN   = -E_MAX;  // TODO: might want to make this -E_MAX

    // masks for coefficients
    immutable uint MASK_IMPL = 0x1FFFFF;
    immutable uint MASK_XPLC = 0x7FFFFF;

    // union providing different views of the number representation.
    private union {

        // entire 32-bit unsigned integer
        uint value = SV.POS_NAN;

        // unsigned value and sign bit
        mixin (bitfields!(
            uint, "uValue", unsignedBits,
            bool, "signed", signBit)
        );
        // Ex = explicit finite number:
        //     full coefficient, exponent and sign
        mixin (bitfields!(
            uint, "mantEx", explicitBits,
            uint, "expoEx", expoBits,
            bool, "signEx", signBit)
        );
        // Im = implicit finite number:
        //      partial coefficient, exponent, test bits and sign bit.
        mixin (bitfields!(
            uint, "mantIm", implicitBits,
            uint, "expoIm", expoBits,
            uint, "testIm", testBits,
            bool, "signIm", signBit)
        );
        // Inf = infinities:
        //      payload, unused bits, special bits and sign bit.
        mixin (bitfields!(
            uint, "anonInf", infPadBits,
            uint, "testInf", infinityBits,
            bool, "signInf", signBit)
        );
        // Nan = special values: qNaN and sNan:
        //      payload, unused bits, special bits and sign bit.
        mixin (bitfields!(
            uint, "pyldNaN", payloadBits,
            uint, "anonNaN", nanPadBits,
            uint, "testNaN", specialBits,
            bool, "signNaN", signBit)
        );
    }

/*    unittest {
        Dec32 num;
        num = 0;
writeln("num = ", num);
writeln("num.toAbstract = ", num.toAbstract);
writeln("num.exponent = ", num.exponent);
writeln("num.coefficient = ", num.coefficient);
writeln("num.mantEx = ", num.mantEx);
writeln("num.expoEx = ", num.expoEx);
writeln("num.mantIm = ", num.mantIm);
writeln("num.expoIm = ", num.expoIm);
        num = 8388607;
writeln("num = ", num);
writeln("num.toAbstract = ", num.toAbstract);
writeln("num.exponent = ", num.exponent);
writeln("num.coefficient = ", num.coefficient);
writeln("num.mantEx = ", num.mantEx);
writeln("num.expoEx = ", num.expoEx);
writeln("num.mantIm = ", num.mantIm);
writeln("num.expoIm = ", num.expoIm);
        num = Dec32(8388608);
writeln("num = ", num);
writeln("num.isImplicit = ", num.isImplicit);
writeln("num.toAbstract = ", num.toAbstract);
writeln("num.exponent = ", num.exponent);
writeln("num.coefficient = ", num.coefficient);
writeln("num.mantEx = ", num.mantEx);
writeln("num.expoEx = ", num.expoEx);
writeln("num.mantIm = ", num.mantIm);
writeln("num.expoIm = ", num.expoIm);



    }*/

//--------------------------------
//  special values
//--------------------------------

    // The value of the (6) special bits when the number is a signaling NaN.
    immutable uint SV_SIG = 0x3F;
    // The value of the (6) special bits when the number is a quiet NaN.
    immutable uint SV_NAN = 0x3E;
    // The value of the (5) special bits when the number is infinity.
    immutable uint SV_INF = 0x1E;

    private static enum SV : uint
    {
        // The value corresponding to a positive signaling NaN.
        POS_SIG = 0x7E000000,
        // The value corresponding to a negative signaling NaN.
        NEG_SIG = 0xFE000000,

        // The value corresponding to a positive quiet NaN.
        POS_NAN = 0x7C000000,
        // The value corresponding to a negative quiet NaN.
        NEG_NAN = 0xFC000000,

        // The value corresponding to positive infinity.
        POS_INF = 0x78000000,
        // The value corresponding to negative infinity.
        NEG_INF = 0xF8000000,

        // The value corresponding to positive zero. (+0)
        POS_ZRO = 0x32800000,
        // The value corresponding to negative zero. (-0)
        NEG_ZRO = 0xB2800000
    }

    private immutable Dec32 QNAN     = Dec32(SV.POS_NAN);
    private immutable Dec32 SNAN     = Dec32(SV.POS_SIG);
    private immutable Dec32 INFINITY = Dec32(SV.POS_INF);
    private immutable Dec32 NEG_INF  = Dec32(SV.NEG_INF);
    private immutable Dec32 ZERO     = Dec32(SV.POS_ZRO);
    private immutable Dec32 NEG_ZERO = Dec32(SV.NEG_ZRO);

//--------------------------------
//  constructors
//--------------------------------

    /**
     * Creates a Dec32 from a special value.
     */
    private this(const SV sv) {
        value = sv;
    }

    unittest {
        Dec32 num;
        num = Dec32(SV.POS_SIG);
        assert(num.isSignaling);
        assert(num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec32(SV.NEG_SIG);
        assert(num.isSignaling);
        assert(num.isNaN);
        assert(num.isNegative);
        assert(!num.isNormal);
        num = Dec32(SV.POS_NAN);
        assert(!num.isSignaling);
        assert(num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec32(SV.NEG_NAN);
        assert(!num.isSignaling);
        assert(num.isNaN);
        assert(num.isNegative);
        assert(num.isQuiet);
        num = Dec32(SV.POS_INF);
        assert(num.isInfinite);
        assert(!num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec32(SV.NEG_INF);
        assert(!num.isSignaling);
        assert(num.isInfinite);
        assert(num.isNegative);
        assert(!num.isFinite);
        num = Dec32(SV.POS_ZRO);
        assert(num.isFinite);
        assert(num.isZero);
        assert(!num.isNegative);
        assert(num.isNormal);
        num = Dec32(SV.NEG_ZRO);
        assert(!num.isSignaling);
        assert(num.isZero);
        assert(num.isNegative);
        assert(num.isFinite);
    }

    /**
     * Creates a Dec32 from a long integer.
     */
    public this(const long n)
    {
        this = zero;
        signed = n < 0;
        ulong mant = std.math.abs(n);
        coefficient(mant);
    }

    unittest {
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

    /**
     * Creates a Dec32 from an unsigned integer and integer exponent.
     */
    public this(const long mant, const int expo) {
        this(mant);
        exponent = exponent + expo;
    }

    unittest {
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
    }

    /**
     * Creates a Dec32 from a Decimal
     */
    public this(const Decimal num) {

        Decimal big = plus!Decimal(num, context32);

        if (big.isFinite) {
            this = zero;
            this.coefficient(cast(ulong)big.coefficient.toLong);
            this.exponent(big.exponent);
            this.sign(big.sign);
            return;
        }
        // check for special values
        else if (big.isInfinite) {
            bits(SV.POS_INF);
            signed = big.sign;
            return;
        }
        else if (big.isQuiet) {
            value = SV.POS_NAN;
            signed = big.sign;
            return;
        }
        else if (big.isSignaling) {
            value = SV.POS_SIG;
            signed = big.sign;
            return;
        }

    }

   // TODO: add a test for 999999E+x -- I think it's rounding when it shouldn't
   unittest {
        Decimal dec = Decimal(0);
        Dec32 num = Dec32(dec);
        assert(dec.toString == num.toString);
        dec = Decimal(1);
        num = Dec32(dec);
        assert(dec.toString == num.toString);
        dec = Decimal(-1);
        num = Dec32(dec);
        assert(dec.toString == num.toString);
        dec = Decimal(-16000);
        num = Dec32(dec);
        assert(dec.toString == num.toString);
        dec = Decimal(uint.max);
        num = Dec32(dec);
        assert(num.toString == "4.294967E+9");
        assert(dec.toString == "4294967295");
    }

    /**
     * Creates a Dec32 from a string.
     */
    public this(const string str) {
        Decimal big = Decimal(str);
        this(big);
    }

    unittest {
        Dec32 num;
        num = Dec32("1.234568E+9");
        assert(num.toString == "1.234568E+9");
        num = Dec32("NaN");
        assert(num.isQuiet && num.isSpecial && num.isNaN);
        num = Dec32("-inf");
        assert(num.isInfinite && num.isSpecial && num.isNegative);
    }

    /**
     *    Constructs a number from a real value.
     */
    // TODO: change this to use fields from bitmanip
    this(const real r) {
        string str = format("%.*G", cast(int)context32.precision, r);
        this(str);
    }

    unittest {
        real r = 1.2345E+16;
        Dec32 actual = Dec32(r);
        Dec32 expect = Dec32("1.2345E+16");
        assert(expect == actual);
    }

    /**
     * Copy constructor.
     */
    public this(const Dec32 that) {
        this.bits = that.bits;
    }

//--------------------------------
//  properties
//--------------------------------

    public:

    /// Returns the raw bits of this number.
    @property
    const uint bits() {
        return value;
    }

    /// Sets the raw bits of this number.
    @property
    uint bits(const uint raw) {
        value = raw;
        return value;
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
        Dec32 num;
        // reals
        num = std.math.PI;
        assert(num.exponent = -6);
        num = 9.75E89;
        assert(num.exponent = 87);
        // explicit
        num = 8388607;
        assert(num.exponent = 0);
        // implicit
        num = 8388610;
        assert(num.exponent = 0);
        num = 9.999998E23;
        assert(num.exponent = 17);
        num = 9.999999E23;
        assert(num.exponent = 17);
    }

    /// Sets the exponent of this number.
    /// If this number is infinity or NaN, this number is converted to
    /// a quiet NaN and the invalid operation flag is set.
    /// Otherwise, if the input value exceeds the maximum allowed exponent,
    /// this number is converted to infinity and the overflow flag is set.
    /// If the input value is less than the minimum allowed exponent,
    /// this number is converted to zero, the exponent is set to eTiny
    /// and the underflow flag is set.
    @property
     int exponent(const int expo) {
        // check for overflow
        if (expo > context32.eMax) {
            this = signed ? NEG_INF : INFINITY;
            context32.setFlag(OVERFLOW);
            return 0;
        }
        // check for underflow
        if (expo < context32.eMin) {
            // if the exponent is too small even for a subnormal number,
            // the number is set to zero.
            if (expo < context32.eTiny) {
                this = signed ? NEG_ZERO : ZERO;
                expoEx = context32.eTiny + BIAS;
                context32.setFlag(SUBNORMAL);
                context32.setFlag(UNDERFLOW);
                return context32.eTiny;
            }
            // at this point the exponent is between eMin and eTiny.
            // TODO: still needs work -- may have to round the coefficient.
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
        context32.setFlag(INVALID_OPERATION);
        this = SV.POS_NAN;
        return 0;
    }

    unittest {
	write("exponent...");
    Dec32 num;
    num = Dec32(-12000,5);
    num.exponent(10);
    assert(num.exponent == 10);
    num = Dec32(-9000053,-14);
    num.exponent(-27);
    assert(num.exponent == -27);
    num = infinity;
    assert(num.exponent == 0);
    // TODO: test overflow and underflow.
    writeln("passed");
    }

    /// Returns the coefficient of this number.
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

    // Sets the coefficient of this number. This may cause an
    // explicit number to become an implicit number, and vice versa.
    @property
    uint coefficient(const ulong mant) {
        // if not finite, convert to NaN and return 0.
        if (!this.isFinite) {
            this = nan;
            context32.setFlag(INVALID_OPERATION);
            return 0;
        }
        long mant1 = mant;
        if (mant1 > MAX_IMPL) {
            int expo = 0;
            uint digits = numDigits(mant1);
            expo = setExponent(mant1, digits, context32);
            if (this.isExplicit) {
                expoEx = expoEx + expo;
            }
            else {
                expoIm = expoIm + expo;
            }
        }
        uint mant2 = cast(uint)mant1;
        if (mant2 <= MAX_XPLC) {
            // if implicit, convert to explicit
            if (this.isImplicit) {
                expoEx = expoIm;
            }
            mantEx = mant2;
            return mantEx;
        }
        else {  // mant2 <= MAX_IMPL
            // if explicit, convert to implicit
            if (this.isExplicit) {
                expoIm = expoEx;
                testIm = 0b11;
            }
            mantIm = mant2 & MASK_IMPL;
            return mantIm | (0b100 << implicitBits);
        }
    }

    unittest {
	    write("coefficient...");
        Dec32 num;
        assert(num.coefficient == 0);
        num = 9.998743;
// TODO: rounding problem
//        assert(num.coefficient == 9998743);
        num = Dec32(9999213,-6);
        assert(num.coefficient == 9999213);
        num = -125;
        assert(num.coefficient == 125);
        num = -99999999;
// TODO: rounding problem
writeln("num = ", num);
writeln("num.coefficient = ", num.coefficient);
//        assert(num.coefficient == 1000000);
        // TODO: test explicit, implicit, nan and infinity.
	    writeln("failed");
    }

    /// Returns the number of digits in this number's coefficient.
    @property
    const int digits() {
        return numDigits(this.coefficient);
    }

    // TODO: this is a stopgap
    // NOTE: if we really want to set the digits then we need to
    // adjust the context value, right?
    // TODO: there is info in the spec about minimum # of digits.
    @property
    const int digits(const int digs) {
        return digs;
    }

    /// Returns the payload of this number.
    /// If this is a NaN, returns the value of the payload bits.
    /// Otherwise returns zero.
    @property
    const uint payload() {
        if (this.isNaN) {
            return pyldNaN;
        }
        return 0;
    }

    /// Sets the payload of this number.
    /// If the number is not a NaN (har!) no action is taken and zero
    /// is returned.
    @property
    uint payload(const uint value) {
        if (isNaN) {
            pyldNaN = value;
            return pyldNaN;
        }
        return 0;
    }

    unittest {
	    write("payload...");
        Dec32 num;
        assert(num.payload == 0);
        num = snan;
        assert(num.payload == 0);
        num.payload(234);
        assert(num.payload == 234);
        assert(num.toString == "sNaN234");
        num = 1234567;
        assert(num.payload == 0);
	    writeln("passed");
    }


//--------------------------------
//  constants
//--------------------------------

    const Dec32 dup() {
        Dec32 copy;
        copy.bits(this.bits);
        return copy;
    }

    static Dec32 zero(const bool signed = false) {
        return signed ? NEG_ZERO.dup : ZERO.dup;
    }

    static Dec32 infinity(const bool signed = false) {
        return signed ? NEG_INF.dup : INFINITY.dup;
    }

    // floating point properties
    static Dec32 init()       { return QNAN; }
    static Dec32 nan()        { return QNAN; }
    static Dec32 snan()       { return SNAN; }

    static Dec32 epsilon()    { return Dec32(1, -context32.precision); }
    static Dec32 max()        { return Dec32("9999999E+90"); }
    static Dec32 min_normal() { return Dec32(1, context32.eMin); }

    static int dig()        { return 7; }
    static int mant_dig()   { return 24; }
    static int max_10_exp() { return context32.eMax; }
    static int min_10_exp() { return context32.eMin; }
    static int max_exp()    { return cast(int)(context32.eMax/LOG2); }
    static int min_exp()    { return cast(int)(context32.eMin/LOG2); }

    /// Returns the maximum number of decimal digits in this context.
    static uint precision(DecimalContext context = context32) {
        return context.precision;
    }

    /// Returns the maximum number of decimal digits in this context.
    static uint dig(DecimalContext context = context32) {
        return context.precision;
    }

    /// Returns the number of binary digits in this context.
    static uint mant_dig(DecimalContext context = context32) {
        return cast(int)context.mant_dig;
    }

    static int min_exp(DecimalContext context = context32) {
        return context.min_exp;
    }

    static int max_exp(DecimalContext context = context32) {
        return context.max_exp;
    }

    // Returns the maximum representable normal value in the current context.
    // TODO: this is a fairly expensive operation. Can it be fixed?
    static Dec32 max(DecimalContext context = context32) {
        string cstr = "9." ~ replicate("9", context.precision-1)
            ~ "E" ~ format("%d", context.eMax);
        return Dec32(cstr);
    }

    /// Returns the minimum representable normal value in this context.
    static Dec32 min_normal(DecimalContext context = context32) {
        return Dec32(1, context.eMin);
    }

    /// Returns the minimum representable subnormal value in this context.
    static Dec32 min(DecimalContext context = context32) {
        return Dec32(1, context.eTiny);
    }

    /// returns the smallest available increment to 1.0 in this context
    static Dec32 epsilon(DecimalContext context = context32) {
        return Dec32(1, -context.precision);
    }

    static int min_10_exp(DecimalContext context = context32) {
        return context.eMin;
    }

    static int max_10_exp(DecimalContext context = context32) {
        return context.eMax;
    }

//--------------------------------
//  classification properties
//--------------------------------

    const bool isExplicit() {
        return testIm != 0b11;
    }

    const bool isImplicit() {
        return isFinite() && !isExplicit();
    }

    /**
     * Returns true if this number's representation is canonical.
     */
    const bool isCanonical() {
        return true;
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
        return isQuiet || isSignaling;
    }

    /**
     * Returns true if this number is a signaling NaN.
     */
    const bool isSignaling() {
        return testNaN == SV_SIG;
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return testNaN == SV_NAN;
    }

    /**
     * Returns true if this number is +\- infinity.
     */
    const bool isInfinite() {
        return testInf == SV_INF;
    }

    /**
     * Returns true if this number is neither infinite nor a NaN.
     */
    const bool isFinite() {
        return !isNaN && !isInfinite;
    }

    /**
     * Returns true if this number is a NaN or infinity.
     */
    const bool isSpecial() {
        return isInfinite || isNaN;
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

    /**
     * Returns true if this number is subnormal.
     */
    const bool isSubnormal() {
        if (isSpecial) return false;
        return adjustedExponent < MIN_EXPO;
    }

    /**
     * Returns true if this number is normal.
     */
    const bool isNormal() {
        if (isSpecial) return false;
        return adjustedExponent >= MIN_EXPO;
    }

    // TODO: this is where the "digits" come into play.
    /**
     * Returns the value of the adjusted exponent.
     */
     const int adjustedExponent() {
        return exponent + 6;
     }

//--------------------------------
//  conversions
//--------------------------------

    /**
     * Converts a Dec32 to a Decimal
     */
    public const Decimal toDecimal() {

        if (isFinite) {
            return Decimal(sign, BigInt(coefficient), exponent);
        }
        if (isInfinite) {
            return Decimal.infinity(sign);
        }
        // TODO: include payloads
        if (isQuiet) {
            return Decimal.nan(sign);
        }
        else { // isSignaling
            return Decimal.snan(sign);
        }
    }

    unittest {
        write("toDecimal...");
        writeln("test missing");
    }

    /**
     * Converts a Dec32 to a hexadecimal string
     */
    const public string toHexString() {
         return format("0x%08X", value);
    }

    unittest {
        write("toHexString...");
        writeln("test missing");
    }

    /**
     * Converts a Dec32 to a string
     */
    const public string toString() {
         return toSciString(this);
    }

    /**
     * Converts a Dec32 to a string
     */
    public const string toAbstract()
    {
        if (this.isSignaling) {
            if (payload) {
                return format("[%d,%s,%d]", signed ? 1 : 0, "sNaN", payload);
            }
            return format("[%d,%s]", signed ? 1 : 0, "sNaN");
        }
        if (this.isQuiet) {
            if (payload) {
                return format("[%d,%s,%d]", signed ? 1 : 0, "qNaN", payload);
            }
            return format("[%d,%s%s]", signed ? 1 : 0, "qNaN", coefficient);
        }
        if (this.isInfinite) {
            return format("[%d,%s]", signed ? 1 : 0, "inf");
        }
        return format("[%d,%s,%d]", signed ? 1 : 0, coefficient, exponent);
    }

//--------------------------------
//  comparison
//--------------------------------

    /**
     * Returns -1, 0 or 1, if this number is less than, equal to or
     * greater than the argument, respectively.
     */
    const int opCmp(const Dec32 that) {
        return compare!Dec32(this, that, context32);
    }

    unittest {
        write("opCmp........");
        Dec32 a, b;
        a = Dec32(104.0);
        b = Dec32(105.0);
        assert(a < b);
        assert(b > a);
        writeln("passed");
    }

    /**
     * Returns true if this number is equal to the specified number.
     */
    const bool opEquals(ref const Dec32 that) {
        return equals!Dec32(this, that, context32);
    }

    unittest {
        write("opEquals.....");
        Dec32 a, b;
        a = Dec32(105);
        b = Dec32(105);
        assert(a == b);
        writeln("passed");
    }

//--------------------------------
// assignment
//--------------------------------

    // UNREADY: opAssign(T: Dec32)(const Dec32). Flags. Unit Tests.
    /// Assigns a Dec32 (copies that to this).
    void opAssign(T:Dec32)(const T that) {
        this.value = that.value;
    }

    unittest {
        write("opAssign(Dec32)..");
        Dec32 rhs, lhs;
        rhs = Dec32(270E-5);
        lhs = rhs;
        assert(lhs == rhs);
        writeln("passed");
    }

    // UNREADY: opAssign(T)(const T). Flags.
    ///    Assigns a numeric value.
    void opAssign(T)(const T that) {
        this = Dec32(that);
    }

    unittest {
        write("opAssign(numeric)...");
        Dec32 rhs;
        rhs = 332089;
        assert(rhs.toString == "332089");
        rhs = 3.1415E+3;
        assert(rhs.toString == "3141.5");
        writeln("passed");
    }

//--------------------------------
// unary operators
//--------------------------------

    const Dec32 opUnary(string op)()
    {
        static if (op == "+") {
            return plus!Dec32(this, context32);
        }
        else static if (op == "-") {
            return minus!Dec32(this, context32);
        }
        else static if (op == "++") {
            return add!Dec32(this, Dec32(1), context32);
        }
        else static if (op == "--") {
            return subtract!Dec32(this, Dec32(1), context32);
        }
    }

    unittest {
	write("opUnary......");
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
    // TODO: seems to be broken for nums like 1.000E8
    num = 12.35;
    expect = 11.35;
    actual = --num;
    assert(actual == expect);
	writeln("passed");
}


//--------------------------------
// binary operators
//--------------------------------

    const Dec32 opBinary(string op)(const Dec32 rhs)
    {
        static if (op == "+") {
            return add!Dec32(this, rhs, context32);
        }
        else static if (op == "-") {
            return subtract!Dec32(this, rhs, context32);
        }
        else static if (op == "*") {
            return multiply!Dec32(this, rhs, context32);
        }
        else static if (op == "/") {
            return divide!Dec32(this, rhs, context32);
        }
        else static if (op == "%") {
            return remainder!Dec32(this, rhs, context32);
        }
    }

    unittest {
	write("opBinary.....");
    Dec32 op1, op2, actual, expect;
    op1 = 4;
    op2 = 8;
    actual = op1 + op2;
    expect = 12;
    assert(expect == actual);
    actual = op1 - op2;
    expect = -4;
    assert(expect == actual);
    actual = op1 * op2;
    expect = 32;
    assert(expect == actual);
    op1 = 5;
    op2 = 2;
    actual = op1 / op2;
    expect = 2.5;
    assert(expect == actual);
    op1 = 10;
    op2 = 3;
    actual = op1 % op2;
    expect = 1;
    assert(expect == actual);
	writeln("passed");
}


//-----------------------------
// operator assignment
//-----------------------------

    ref Dec32 opOpAssign(string op) (Dec32 rhs) {
        this = opBinary!op(rhs);
        return this;
    }

    unittest {
	write("opOpAssign...");
    Dec32 op1, op2, actual, expect;
    op1 = 23.56;
    op2 = -2.07;
    op1 += op2;
    expect = 21.49;
    actual = op1;
    assert(expect == actual);
    op1 *= op2;
    expect = -44.4843;
    actual = op1;
    assert(expect == actual);
	writeln("passed");
}


//-----------------------------
// helper functions
//-----------------------------

    /**
     * Has no effect -- simplifies templates.
     */
//    public void clear() { }

     /**
     * Returns uint ten raised to the specified power.
     */
    static uint pow10(const int n) {
        return 10U^^n;
    }

    unittest {
        write("pow10..........");
        int n;
        BigInt pow;
        n = 3;
        assert(pow10(n) == 1000);
        writeln("passed");
    }

}   // end Dec32 struct

    /**
     * Returns special.
     */
/*    public static Dec32 special(const uint value) {
        Dec32 num;
        num.value = value;
        return num;
    }*/

/**
 * Detect whether T is a decimal type.
 */
/*template isDecimal(T) {
    enum bool isDecimal = is(T: Dec32);
}

unittest {
    write("isDecimal(T)...");
    writeln("test missing");
}*/

/*    staticIndexOf!(Unqual!(T),
        Dec32) >= 0;*/

/*unittest
{
    static assert(isIntegral!(byte));
    static assert(isIntegral!(const(byte)));
    static assert(isIntegral!(immutable(byte)));
    static assert(isIntegral!(shared(byte)));
    static assert(isIntegral!(shared(const(byte))));
}*/


// UNREADY: toSciString. Description. Unit Tests.
/**
 * Converts a Decimal number to a string representation.
 */
public string toSciString(const Dec32 num) {
    return decimal.conv.toSciString!Dec32(num);
}

// UNREADY: toEngString. Description. Unit Tests.
/**
 * Converts a Decimal number to a string representation.
 */
public string toEngString(const Dec32 num) {
    return decimal.conv.toEngString!Dec32(num);
}

unittest {
    writeln("---------------------");
    writeln("decimal32....finished");
    writeln("---------------------");
}


