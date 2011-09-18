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

module decimal.dec64;

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

unittest {
    writeln("-------------------");
    writeln("Dec64.......testing");
    writeln("-------------------");
}

// (4) TODO: problem with unary ops (++).
// (5) TODO: subnormal creation.
struct Dec64 {

    /// The global context for this type.
    private static decimal.context.DecimalContext context64 = {
        precision : 16,
        rounding : Rounding.HALF_EVEN,
        eMax : E_MAX
    };

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
    immutable int C_LENGTH = 16;
    // The maximum coefficient that fits in an explicit number.
    immutable ulong C_MAX_EXPLICIT = 0x1FFFFFFFFFFFFF; // = 8388607; 36028797018963968
    // The maximum coefficient allowed in an implicit number.
    immutable ulong C_MAX_IMPLICIT = 9999999999999999;  // = 0x98967F; 2386F26FC0FFFF 2386F26FC10000
    // masks for coefficients
    immutable ulong C_IMPLICIT_MASK = 0x1FFFFFFFFFFFFF;
    immutable ulong C_EXPLICIT_MASK =  0x7FFFFFFFFFFFF;

    // The maximum unbiased exponent. The largest binary number that can fit
    // in the width of the exponent field without setting
    // either of the first two bits to 1.
    immutable uint MAX_EXPO = 0x2FF; // = 767
    // The exponent bias. The exponent is stored as an unsigned number and
    // the bias is subtracted from the unsigned value to give the true
    // (signed) exponent.
    immutable int BIAS = 398;        // = 0x65
    // The maximum representable exponent.
    immutable int E_LIMIT = 369;     // MAX_EXPO - BIAS
    // The min and max adjusted exponents.
    immutable int E_MAX =  386;      // E_LIMIT + C_LENGTH - 1
    immutable int E_MIN = -385;      // = 1 - E_MAX

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
        //     full coefficient, exponent and sign
        mixin (bitfields!(
            ulong, "mantEx", explicitBits,
            uint, "expoEx", expoBits,
            bool, "signEx", signBit)
        );
        // Im = implicit finite number:
        //      partial coefficient, exponent, test bits and sign bit.
        mixin (bitfields!(
            ulong, "mantIm", implicitBits,
            uint, "expoIm", expoBits,
            uint, "testIm", testBits,
            bool, "signIm", signBit)
        );
        // Spcl = special values: non-finite numbers
        //      unused bits, special bits and sign bit.
        mixin (bitfields!(
            ulong, "padSpcl",  spclPadBits,
            uint, "testSpcl", specialBits,
            bool, "signSpcl", signBit)
        );
        // Inf = infinities:
        //      payload, unused bits, infinitu bits and sign bit.
        mixin (bitfields!(
            uint, "padInf",  infPadBits,
            ulong, "testInf", infinityBits,
            bool, "signInf", signBit)
        );
        // Nan = not-a-number: qNaN and sNan
        //      payload, unused bits, nan bits and sign bit.
        mixin (bitfields!(
            ushort, "pyldNaN", payloadBits,
            ulong, "padNaN",  nanPadBits,
            uint, "testNaN", nanBits,
            bool, "signNaN", signBit)
        );
    }

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
//  special values
//--------------------------------

private:
    // The value of the (6) special bits when the number is a signaling NaN.
    immutable uint SIG_VAL = 0x3F;
    // The value of the (6) special bits when the number is a quiet NaN.
    immutable uint NAN_VAL = 0x3E;
    // The value of the (5) special bits when the number is infinity.
    immutable uint INF_VAL = 0x1E;

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
        POS_MAX = 0x77F8967FFFFFFFFF,
        // The value of the largest representable negative number.
        NEG_MAX = 0xF7F8967FFFFFFFFF
    }

public:
    immutable Dec64 NAN      = Dec64(SV.POS_NAN);
    immutable Dec64 SNAN     = Dec64(SV.POS_SIG);
    immutable Dec64 INFINITY = Dec64(SV.POS_INF);
    immutable Dec64 NEG_INF  = Dec64(SV.NEG_INF);
    immutable Dec64 ZERO     = Dec64(SV.POS_ZRO);
    immutable Dec64 NEG_ZERO = Dec64(SV.NEG_ZRO);
    immutable Dec64 MAX      = Dec64(SV.POS_MAX);
    immutable Dec64 NEG_MAX  = Dec64(SV.NEG_MAX);
    immutable Dec64 ONE      = Dec64( 1);
    immutable Dec64 NEG_ONE  = Dec64(-1);

//--------------------------------
//  constructors
//--------------------------------

    /**
     * Creates a Dec64 from a special value.
     */
    private this(const SV sv) {
        intBits = sv;
    }

    // this unit test uses private values
    unittest {
        Dec64 num;
        num = Dec64(SV.POS_SIG);
        assert(num.isSignaling);
        assert(num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec64(SV.NEG_SIG);
        assert(num.isSignaling);
        assert(num.isNaN);
        assert(num.isNegative);
        assert(!num.isNormal);
        num = Dec64(SV.POS_NAN);
        assert(!num.isSignaling);
        assert(num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec64(SV.NEG_NAN);
        assert(!num.isSignaling);
        assert(num.isNaN);
        assert(num.isNegative);
        assert(num.isQuiet);
        num = Dec64(SV.POS_INF);
        assert(num.isInfinite);
        assert(!num.isNaN);
        assert(!num.isNegative);
        assert(!num.isNormal);
        num = Dec64(SV.NEG_INF);
        assert(!num.isSignaling);
        assert(num.isInfinite);
        assert(num.isNegative);
        assert(!num.isFinite);
        num = Dec64(SV.POS_ZRO);
        assert(num.isFinite);
        assert(num.isZero);
        assert(!num.isNegative);
        assert(num.isNormal);
        num = Dec64(SV.NEG_ZRO);
        assert(!num.isSignaling);
        assert(num.isZero);
        assert(num.isNegative);
        assert(num.isFinite);
    }

    /**
     * Creates a Dec64 from a long integer.
     */
    public this(const long n)
    {
        this = zero;
        signed = n < 0;
        coefficient = std.math.abs(n);
//writeln("coefficient = ", coefficient);
//writeln("exponent = ", exponent);
    }

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

    /**
     * Creates a Dec64 from an unsigned integer and integer exponent.
     */
    public this(const long mant, const int expo) {
        this(mant);
        exponent = exponent + expo;
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
     * Creates a Dec64 from an unsigned integer and integer exponent.
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

        Decimal big = plus!Decimal(num, context64);
        if (big.isFinite) {
            this = zero;
            this.coefficient = cast(ulong)big.coefficient.toLong;
            this.exponent = big.exponent;
            this.sign = big.sign;
            return;
        }
        // check for special values
        else if (big.isInfinite) {
            this = infinity(big.sign);
            return;
        }
        else if (big.isQuiet) {
            this = nan();
            return;
        }
        else if (big.isSignaling) {
            this = snan();
            return;
        }
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
     *    Constructs a number from a real value.
     */
    public this(const real r) {
        // check for special values
        if (!std.math.isFinite(r)) {
            this = std.math.isInfinity(r) ? INFINITY : NAN;
            this.sign = cast(bool)std.math.signbit(r);
            return;
        }
        string str = format("%.*G", cast(int)context64.precision, r);
        this(str);
    }

    unittest {
        float f = 1.2345E+16f;
        Dec64 actual = Dec64(f);
        Dec64 expect = Dec64("1.234499980283085E+16");
//writeln("actual = ", actual);
//writeln("expect = ", expect);
        assert(expect == actual);
        real r = 1.2345E+16;
        actual = Dec64(r);
        expect = Dec64("1.2345E+16");
//writeln("actual = ", actual);
//writeln("expect = ", expect);
        assert(expect == actual);
    }

    /**
     * Copy constructor.
     */
    public this(const Dec64 that) {
        this.bits = that.bits;
    }

    /**
     * duplicator.
     */
    const Dec64 dup() {
        return Dec64(this);
    }

//--------------------------------
//  properties
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
//writeln("expoEx = ", expoEx);
            return expoEx - BIAS;
        }
        if (this.isImplicit) {
//writeln("expoIm = ", expoIm);
            return expoIm - BIAS;
        }
        // infinity or NaN.
        return 0;
    }

    unittest {
        Dec64 num;
        // reals
        num = std.math.PI;
        assert(num.exponent = -15);
        num = 9.75E9;
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
        if (expo > context64.eMax) {
            this = signed ? NEG_INF : INFINITY;
            context64.setFlag(OVERFLOW);
            return 0;
        }
        // check for underflow
        if (expo < context64.eMin) {
            // if the exponent is too small even for a subnormal number,
            // the number is set to zero.
            if (expo < context64.eTiny) {
                this = signed ? NEG_ZERO : ZERO;
                expoEx = context64.eTiny + BIAS;
                context64.setFlag(SUBNORMAL);
                context64.setFlag(UNDERFLOW);
                return context64.eTiny;
            }
            // at this point the exponent is between eMin and eTiny.
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
        context64.setFlag(INVALID_OPERATION);
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
//            return mantIm | (0b100 << implicitBits);
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
            context64.setFlag(INVALID_OPERATION);
            return 0;
        }
        ulong copy = mant;
        if (copy > C_MAX_IMPLICIT) {
            int expo = 0;
            uint digits = numDigits(copy);
            expo = setExponent(sign, copy, digits, context64);
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
        else {  // copy <= C_MAX_IMPLICIT
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
        Dec64 num;
        assert(num.coefficient == 0);
        // TODO: why doesn't 9.998743 work?
        num = 9.998742;
        assert(num.coefficient == 9998742);
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
//  constants
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
        }
        return NAN;
    }

    static Dec64 snan(const ushort payload = 0) {
        if (payload) {
            Dec64 result = SNAN;
            result.payload = payload;
        }
        return SNAN;
    }

    // floating point properties
    static Dec64 init()       { return NAN; }
    static Dec64 nan()        { return NAN; }
    static Dec64 snan()       { return SNAN; }

    static Dec64 epsilon()    { return Dec64(1, -7); }
    static Dec64 max()        { return MAX; }
    static Dec64 min_normal() { return Dec64(1, context64.eMin); }
    static Dec64 min()        { return Dec64(1, context64.eTiny); }

    static int dig()        { return 7; }
    static int mant_dig()   { return 24; }
    static int max_10_exp() { return context64.eMax; }
    static int min_10_exp() { return context64.eMin; }
    static int max_exp()    { return cast(int)(context64.eMax/LOG2); }
    static int min_exp()    { return cast(int)(context64.eMin/LOG2); }

    /// Returns the maximum number of decimal digits in this context.
    static uint precision(DecimalContext context = context64) {
        return context.precision;
    }

    /// Returns the maximum number of decimal digits in this context.
    static uint dig(DecimalContext context = context64) {
        return context.precision;
    }

    /// Returns the number of binary digits in this context.
    static uint mant_dig(DecimalContext context = context64) {
        return cast(int)context.mant_dig;
    }

    static int min_exp(DecimalContext context = context64) {
        return context.min_exp;
    }

    static int max_exp(DecimalContext context = context64) {
        return context.max_exp;
    }

    /// Returns the minimum representable normal value in this context.
    static Dec64 min_normal(DecimalContext context = context64) {
        return Dec64(1, context.eMin);
    }

    /// Returns the minimum representable subnormal value in this context.
    // (5) TODO: does this set the subnormal flag?
    // Do others do the same on creation??
    static Dec64 min(DecimalContext context = context64) {
        return Dec64(1, context.eTiny);
    }

    /// returns the smallest available increment to 1.0 in this context
    static Dec64 epsilon(DecimalContext context = context64) {
        return Dec64(1, -context.precision);
    }

    static int min_10_exp(DecimalContext context = context64) {
        return context.eMin;
    }

    static int max_10_exp(DecimalContext context = context64) {
        return context.eMax;
    }

//--------------------------------
//  classification properties
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

    /**
     * Returns true if this number is subnormal.
     */
    const bool isSubnormal() {
        if (isSpecial) return false;
        return adjustedExponent < E_MIN;
    }

    /**
     * Returns true if this number is normal.
     */
    const bool isNormal() {
        if (isSpecial) return false;
        return adjustedExponent >= E_MIN;
    }

    /**
     * Returns the value of the adjusted exponent.
     */
     const int adjustedExponent() {
        return exponent - digits + 1;
     }

//--------------------------------
//  conversions
//--------------------------------

    /**
     * Converts a Dec64 to a Decimal
     */
    const Decimal toDecimal() {
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
        Decimal actual = num.toDecimal;
        assert(actual == expected);
    }

    const int toInt() {
        int n;
        if (isNaN) {
            context64.setFlag(INVALID_OPERATION);
            return 0;
        }
        if (this > Dec64(int.max) || (isInfinite && !isSigned)) return int.max;
        if (this < Dec64(int.min) || (isInfinite &&  isSigned)) return int.min;
        quantize!Dec64(this, ONE, context64);
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
            context64.setFlag(INVALID_OPERATION);
            return 0;
        }
        // TODO: make these constants. (The compiler probably already does.)
        if (this > Dec64(long.max) || (isInfinite && !isSigned)) return long.max;
        if (this < Dec64(long.min) || (isInfinite &&  isSigned)) return long.min;
        quantize!Dec64(this, ONE, context64);
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

    /**
     * Converts this number to an exact scientific-style string representation.
     */
    const string toSciString() {
        return decimal.conv.toSciString!Dec64(this);
    }

    /**
     * Converts this number to an exact engineering-style string representation.
     */
    const string toEngString() {
        return decimal.conv.toEngString!Dec64(this);
    }

    /**
     * Converts a Dec64 to a string
     */
    const public string toString() {
         return toSciString();
    }

    unittest {
        string str;
        str = "-12.345E-42";
        Dec64 num = Dec64(str);
        assert(num.toString == "-1.2345E-41");
    }

    /**
     * Creates an exact representation of this number.
     */
    const string toExact()
    {
        if (this.isFinite) {
            return format("%s%016dE%s%02d", signed ? "-" : "+", coefficient,
                    exponent < 0 ? "-" : "+", exponent);
        }
        if (this.isInfinite) {
            return format("%s%s", signed ? "-" : "+", "Infinity");
        }
        if (this.isQuiet) {
            if (payload) {
                return format("%s%s%d", signed ? "-" : "+", "NaN", payload);
            }
            return format("%s%s", signed ? "-" : "+", "NaN");
        }
        // this.isSignaling
        if (payload) {
            return format("%s%s%d", signed ? "-" : "+", "sNaN", payload);
        }
        return format("%s%s", signed ? "-" : "+", "sNaN");
    }

    unittest {
/*        Dec64 num;
        assert(num.toExact == "+NaN");
        num = max;
        assert(num.toExact == "+9999999E+90");
        num = 1;
        assert(num.toExact == "+0000001E+00");
        num = C_MAX_EXPLICIT;
        assert(num.toExact == "+8388607E+00");
        num = infinity(true);
        assert(num.toExact == "-Infinity");*/
    }

    /**
     * Creates an abstract representation of this number.
     */
    const string toAbstract()
    {
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
        Dec64 num;
        num = Dec64("-25.67E+2");
        assert(num.toAbstract == "[1,2567,0]");
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
        Dec64 num = 12345;
        assert(num.toHexString == "0x31C0000000003039");
        assert(num.toBinaryString ==
            "0011000111000000000000000000000000000000000000000011000000111001");
    }

//--------------------------------
//  comparison
//--------------------------------

    /**
     * Returns -1, 0 or 1, if this number is less than, equal to or
     * greater than the argument, respectively.
     */
    const int opCmp(T:Dec64)(const T that) {
        return compare!Dec64(this, that, context64);
    }

    /**
     * Returns -1, 0 or 1, if this number is less than, equal to or
     * greater than the argument, respectively.
     */
    const int opCmp(T)(const T that) if(isPromotable!T){
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
        return equals!Dec64(this, that, context64);
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
    const bool opEquals(T)(const T that) if(isPromotable!T) {
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

    // (7) UNREADY: opAssign(T: Dec64)(const Dec64). Flags. Unit Tests.
    /// Assigns a Dec64 (copies that to this).
    void opAssign(T:Dec64)(const T that) {
        this.intBits = that.intBits;
    }

    unittest {
        Dec64 rhs, lhs;
        rhs = Dec64(270E-5);
        lhs = rhs;
        assert(lhs == rhs);
    }

    // (7) UNREADY: opAssign(T)(const T). Flags.
    ///    Assigns a numeric value.
    void opAssign(T)(const T that) {
        this = Dec64(that);
    }

    unittest {
        Dec64 rhs;
        rhs = 332089;
        assert(rhs.toString == "332089");
        rhs = 3.1415E+3;
        assert(rhs.toString == "3141.5");
    }

//--------------------------------
// unary operators
//--------------------------------

    const Dec64 opUnary(string op)()
    {
        static if (op == "+") {
            return plus!Dec64(this, context64);
        }
        else static if (op == "-") {
            return minus!Dec64(this, context64);
        }
        else static if (op == "++") {
            return add!Dec64(this, Dec64(1), context64);
        }
        else static if (op == "--") {
            return subtract!Dec64(this, Dec64(1), context64);
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
// TODO:   actual = --num; // fails!
//        actual = num--;
//        assert(actual == expect);
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

    const T opBinary(string op, T:Dec64)(const T rhs)
//    const Dec64 opBinary(string op)(const Dec64 rhs)
    {
        static if (op == "+") {
            return add!Dec64(this, rhs, context64);
        }
        else static if (op == "-") {
            return subtract!Dec64(this, rhs, context64);
        }
        else static if (op == "*") {
            return multiply!Dec64(this, rhs, context64);
        }
        else static if (op == "/") {
            return divide!Dec64(this, rhs, context64);
        }
        else static if (op == "%") {
            return remainder!Dec64(this, rhs, context64);
        }
    }

    unittest {
        Dec64 op1, op2, actual, expect;
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
    }

    /**
     * Detect whether T is a decimal type.
     */
    public template isPromotable(T) {
        enum bool isPromotable = is(T:ulong) || is(T:real);
    }

    const Dec64 opBinary(string op, T)(const T rhs) if(isPromotable!T)
    {
    	return opBinary!(op,Dec64)(Dec64(rhs));
    }

	unittest {
		Dec64 num = Dec64(591.3);
		Dec64 result = num * 5;
		assert(result == Dec64(2956.5));
	}

//-----------------------------
// operator assignment
//-----------------------------

    ref Dec64 opOpAssign(string op, T:Dec64) (T rhs) {
        this = opBinary!op(rhs);
        return this;
    }

    ref Dec64 opOpAssign(string op, T) (T rhs) if (isPromotable!T) {
        this = opBinary!op(rhs);
        return this;
	}

    unittest {
        Dec64 op1, op2, actual, expect;
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
		op1 = 95;
		op1 %= 90;
		actual = op1;
		expect = 5;
        assert(expect == actual);
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
        assert(pow10(n) == 1000);
    }

unittest {
    writeln("-------------------");
    writeln("Dec64......finished");
    writeln("-------------------");
}
}   // end Dec64 struct

