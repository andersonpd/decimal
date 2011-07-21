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
/*          Copyright Paul D. Anderson 2009 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */

// TODO: unittest opPostDec && opPostInc.

// TODO: this(str): add tests for just over/under int.max, int.min

// TODO: opEquals unit test should include numerically equal testing.

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
    writeln("decimal.....testing");
    writeln("-------------------");
}

alias Decimal.context context;

// special values for NaN, Inf, etc.
private static enum SV {NONE, ZERO, INF, QNAN, SNAN};

/**
 * A struct representing an arbitrary-precision floating-point number.
 *
 * The implementation follows the General Decimal Arithmetic
 * Specification, Version 1.70 (25 Mar 2009),
 * http://www.speleotrove.com/decimal. This specification conforms with
 * IEEE standard 754-2008.
 */
struct Decimal {

    private static decimal.context.DecimalContext context = DEFAULT_CONTEXT.dup;

    // TODO: make these private
    private SV sval = SV.QNAN;        // special values: default value is quiet NaN
    private bool signed = false;        // true if the value is negative, false otherwise.
    private int expo = 0;            // the exponent of the Decimal value
    private BigInt mant;            // the coefficient of the Decimal value
    // NOTE: not a uint -- causes math problems down the line.
    package int digits;                 // the number of decimal digits in this number.
                                     // (unless the number is a special value)
    /**
     * clears the special value flags
     */
    public void clear() {
        sval = SV.NONE;
    }

private:

// common decimal "numbers"
    static Decimal NAN      = Decimal(SV.QNAN);
    static Decimal SNAN     = Decimal(SV.SNAN);
    static Decimal POS_INF  = Decimal(SV.INF);
    static Decimal NEG_INF  = Decimal(true, SV.INF);
    static Decimal ZERO     = Decimal(SV.ZERO);
    static Decimal NEG_ZERO = Decimal(true, SV.ZERO);

//    static immutable BigInt BIG_ZERO  = cast(immutable)BigInt(0);

/*    static immutable Decimal ONE  = cast(immutable)Decimal(1);
    static immutable Decimal TWO  = cast(immutable)Decimal(2);
    static immutable Decimal FIVE = cast(immutable)Decimal(5);
    static immutable Decimal TEN  = cast(immutable)Decimal(10);*/

unittest {
	write("special values...");
    Decimal num;
    num = NAN;
    assert(num.toString == "NaN");
    num = SNAN;
    assert(num.toString == "sNaN");
    assert("Decimal(SV.QNAN).toAbstract = ", NAN.toAbstract);
    num = NEG_ZERO;
    assert(num.toString == "-0");
	writeln("passed");
}

public:


//--------------------------------
// construction
//--------------------------------

    // special value constructors:

    // UNREADY: Unit Tests.
    /**
     * Constructs a new number, given the sign, the special value and the payload.
     */
    public this(const bool sign, const SV sv, const uint payload = 0) {
        this.signed = sign;
        this.sval = sv;
        this.mant = BigInt(payload);
    }

    unittest {
        write("this(bool, SV, payload)...");
        Decimal num = Decimal(true, SV.INF);
        writeln("num.toSciString = ", num.toSciString);
        writeln("num.toAbstract = ", num.toAbstract);
//        assert(toSciString!Decimal(num) == "-Infinity");
//        assert(num.toAbstract() == "[1,inf]");
        writeln("failed");
    }

    // UNREADY: Unit Tests.
    /**
     * Constructs a new number, given the special value.
     * The sign is set to true (positive), and the payload is set to zero.
     */
    private this(SV sv) {
        sval = sv;
    }

    unittest {
        write("this(SV)...");
        writeln("test missing");
    }

    // BigInt constructors:

    // UNREADY: Unit Tests.
    /**
     * Constructs a number from a sign, a BigInt coefficient and
     * an optional integer exponent.
     * The intial precision of the number is deduced from the number of decimal
     * digits in the coefficient.
     */
    this(const bool sign, const BigInt coefficient, const int exponent) {
        // TODO: clarify the sign and coefficient relationship:
        // the actual call is to sign, abs(coefficient).
        BigInt big = cast(BigInt) coefficient;
        this.clear();
        if (big < BigInt(0)) {
            this.signed = !sign;
            this.mant = -big;
        }
        else {
            this.signed = sign;
            this.mant = big;
//            if (big == BigInt(0)) {
//                this.sval = SV.ZERO;
//            }
        }
        this.expo = exponent;
        this.digits = numDigits(this.mant);
    }

    unittest {
        write("this(bool, BigInt, int)...");
        writeln("test missing");
    }

    // UNREADY: this(const BigInt, const int). Flags. Unit Tests.
    /**
     * Constructs a Decimal from a BigInt coefficient and an
     * optional integer exponent. The sign of the number is the sign
     * of the coefficient. The initial precision is determined by the number
     * of digits in the coefficient.
     */
    this(const BigInt coefficient, const int exponent) {
        BigInt big = cast(BigInt) coefficient;
        bool sign = big < BigInt(0);
        if (sign) big = -big;
        this(sign, big, exponent);
    };

    unittest {
        write("this(BigInt, int)...");
        writeln("test missing");
    }

    // UNREADY: this(const BigInt, const int). Flags. Unit Tests.
    /**
     * Constructs a Decimal from a BigInt coefficient and an
     * optional integer exponent. The sign of the number is the sign
     * of the coefficient. The initial precision is determined by the number
     * of digits in the coefficient.
     */
    this(const BigInt coefficient) {
        BigInt big = cast(BigInt) coefficient;
        bool sign = big < BigInt(0);
        if (sign) big = -big;
        this(sign, big, 0);
    };

    unittest {
        write("this(BigInt, int)...");
        writeln("test missing");
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
        write("this(long, int..");
        writeln("test missing");
    }

    // UNREADY: this(const long, const int). Flags. Unit Tests.
    /**
     * Constructs a number from an long coefficient
     * and an optional integer exponent.
     */
    this(const long coefficient) {
        this(BigInt(coefficient), 0);
    }

    unittest {
        write("this(long, int..");
        writeln("test missing");
    }

    // string constructors:

    // UNREADY: this(const string). Flags. Unit Tests.
    // construct from string representation
    this(const string str) {
        this = decimal.conv.toNumber(str);
    };

    unittest {
        write("this(string)...");
        writeln("test missing");
    }

    // floating point constructors:

    // UNREADY: this(const real). Flags. Unit Tests.
    /**
     *    Constructs a number from a real value.
     */
    this(const real r) {
        string str = format("%.*G", cast(int)context.precision, r);
        this(str);
    }

    unittest {
        write("this(real)...");
        writeln("test missing");
    }

    // UNREADY: this(const real, const int). Flags. Unit Tests.
    /**
     * Constructs a number from a double value.
     * Set to the specified precision
     */
/*    this(const real r, const int precision) {
        string str = format("%.*E", precision, r);
        this = str;
    }

    unittest {
        write("this(real, int..");
        writeln("test missing");
    }*/

    // copy constructor:


    // UNREADY: this(Decimal). Flags. Unit Tests.
    // copy constructor
    this(const Decimal that) {
        this = that;
    };

    unittest {
        write("this(Decimal)...");
        writeln("test missing");
    }

/**
 * Returns this(Dec32).
 */

    this(const decimal.dec32.Dec32 num) {
    bool sign = num.sign;
    auto mant = num.coefficient;
    int  expo = num.exponent;

    if (num.isFinite) {
        this = Decimal(sign, BigInt(mant), expo);
    }
    else if (num.isInfinite) {
        this = Decimal(sign, SV.INF, 0);
    }
    else if (num.isQuiet) {
        this = Decimal(sign, SV.QNAN, mant);
    }
    else if (num.isSignaling) {
       this = Decimal(sign, SV.SNAN, mant);
    }

    }
    // UNREADY: dup. Flags. Unit Tests.
    /**
     * dup property
     */
    const Decimal dup() {
        Decimal copy;
        copy.sval = sval;
        copy.signed = signed;
        copy.expo = expo;
        copy.mant = cast(BigInt) mant;
        copy.digits = digits;
        return copy;
    }

    unittest {
        write("dup...");
        writeln("test missing");
    }

unittest {
    write("construction.");
    Decimal f = Decimal(1234L, 567);
    f = Decimal(1234, 567);
    assert(f.toString() == "1.234E+570");
    f = Decimal(1234L);
    assert(f.toString() == "1234");
    f = Decimal(123400L);
    assert(f.toString() == "123400");
    f = Decimal(1234L);
    assert(f.toString() == "1234");
    // TODO: these tests are checks of this(x, x, precision) which is
    // deprecated. But we should add a routine to setPrecision
/*    f = Decimal(1234);
    writeln("f.toString() = ", f.toString());
//    assert(f.toString() == "1234.00000");
    f = Decimal(1234, 1, 9);
//    assert(f.toString() == "12340.0000");
    f = Decimal(12, 1, 9);
//    assert(f.toString() == "120.000000");
    f = Decimal(int.max, -4, 9);
    assert(f.toString() == "214748.365");
    f = Decimal(int.max, -4);
    assert(f.toString() == "214748.3647");
    f = Decimal(1234567, -2, 5);
    assert(f.toString() == "12346");*/
    writeln("passed");
}

//--------------------------------
// assignment
//--------------------------------

    // UNREADY: opAssign(T: Decimal)(const Decimal). Flags. Unit Tests.
    /// Assigns a Decimal (makes a copy)
    void opAssign/*(T:Decimal)*/(const Decimal that) {
        this.signed = that.signed;
        this.sval = that.sval;
        this.digits = that.digits;
        this.expo = that.expo;
        this.mant = cast(BigInt) that.mant;
    }

    unittest {
        write("opAssign(Decimal)...");
        writeln("test missing");
    }

    // UNREADY: opAssign(T)(const T). Flags.
    ///    Assigns a floating point value.
    void opAssign/*(T)*/(const long that) {
        this = Decimal(that);
    }

    unittest {
        write("opAssign(long)...");
        writeln("test missing");
    }

    // UNREADY: opAssign(T)(const T). Flags. Unit Tests.
    ///    Assigns a floating point value.
    void opAssign/*(T)*/(const real that) {
        this = Decimal(that);
    }

    unittest {
        write("opAssign(real)...");
        writeln("test missing");
    }

//--------------------------------
// string representations
//--------------------------------

/**
 * Converts a number to an abstract string representation.
 */
public const string toAbstract() {
    switch (sval) {
        case SV.SNAN:
            string payload = mant == BigInt(0) ? "" : "," ~ toDecString(mant);
            return format("[%d,%s%s]", signed ? 1 : 0, "sNaN", payload);
        case SV.QNAN:
            string payload = mant == BigInt(0) ? "" : "," ~ toDecString(mant);
            return format("[%d,%s%s]", signed ? 1 : 0, "qNaN", payload);
        case SV.INF:
            return format("[%d,%s]", signed ? 1 : 0, "inf");
        default:
            return format("[%d,%s,%d]", signed ? 1 : 0, toDecString(mant), expo);
    }
}

unittest {
    write("toAbstract...");
    writeln("test missing");
}

/**
 * Converts a number to its string representation.
 */
const string toString() {
    return toSciString();
};    // end toString()

// READY: toSciString.
/**
 * Converts a Decimal to a string representation.
 */
const string toSciString() {
    return decimal.conv.toSciString!Decimal(this);
};    // end toSciString()

// READY: toEngString.
/**
 * Converts a Decimal to an engineering string representation.
 */
const string toEngString() {
   return decimal.conv.toEngString!Decimal(this);
}; // end toEngString()


unittest {
    write("toString...");
    writeln("test missing");
}

//--------------------------------
// member properties
//--------------------------------

// TODO: make these true properties.

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

    unittest {
        write("exponent...");
        writeln("test missing");
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

    unittest {
        write("coefficient.");
        writeln("test missing");
    }

    /// returns the adjusted exponent of this number
    const int adjustedExponent() {
        return expo + digits - 1;
    }

    unittest {
        write("adjustedExponent...");
        writeln("test missing");
    }

    /// returns the number of decimal digits in the coefficient of this number
    const int getDigits() {
        return this.digits;
    }

    unittest {
        write("getDigits...");
        writeln("test missing");
    }

    @property const bool sign() {
        return signed;
    }

    @property bool sign(bool value) {
        signed = value;
        return signed;
    }

    /// returns the sign of this number
    const int sgn() {
        if (isZero) return 0;
        return signed ? -1 : 1;
    }

    unittest {
        write("sgn...");
        writeln("test missing");
    }

    /// returns a number with the same exponent as this number
    /// and a coefficient of 1.
    const Decimal quantum() {
        return Decimal(1, this.expo);
    }

    unittest {
        write("quantum...");
        writeln("test missing");
    }

    // TODO: check for NaN? Is this the right thing to do here?
    const ulong getNaNPayload() {
        if (!isNaN) throw new Exception("Invalid Operation");
        return cast(ulong)this.mant.toLong;
    }

    unittest {
        write("getNanPayload...");
        writeln("test missing");
    }

    // TODO: check for NaN? Is this the right thing to do here?
    void setNaNPayload(const ulong payload) {
        if (!isNaN) throw new Exception("Invalid Operation");
        this.mant = BigInt(payload);
    }

    unittest {
        write("setNaNPayload...");
        writeln("test missing");
    }

//    void setZero() {
//        this.sval = SV.ZERO;
//    }

//--------------------------------
// floating point properties
//--------------------------------

    unittest {
        writeln("-------------------");
        writeln("floating pt properties");
        writeln("-------------------");
    }

    static int precision() {
        return context.precision;
    }

    /// returns the default value for this type (NaN)
    static Decimal init() {
        return NAN.dup;
    }

    /// Returns NaN
    static Decimal nan() {
        return NAN.dup;
    }

    /// Returns signaling NaN
    static Decimal snan() {
        return SNAN.dup;
    }

    /// Returns infinity.
    static Decimal infinity(bool signed = false) {
        if (signed) return NEG_INF.dup;
        return POS_INF.dup;
    }

    /// Returns zero.
    static Decimal zero(bool signed = false) {
        if (signed) return NEG_ZERO.dup;
        return ZERO.dup;
    }

    /// Returns the maximum number of decimal digits in this context.
    static uint dig() {
        return context.precision;
    }

    /// Returns the number of binary digits in this context.
    static int mant_dig() {
        return cast(int)(context.precision/LOG2);
    }

    static int min_exp() {
        return cast(int)(context.eMin/LOG2);
    }

    static int max_exp() {
        return cast(int)(context.eMax/LOG2);
    }

    // Returns the maximum representable normal value in the current context.
    // FIXTHIS: this doesn't always access the current context. Move it to context?
    static Decimal max() {
        string cstr = "9." ~ replicate("9", context.precision-1)
            ~ "E" ~ format("%d", context.eMax);
        return Decimal(cstr);
    }

    // Returns the minimum representable normal value in the current context.
    static Decimal min_normal() {
        return Decimal(1, context.eMin);
    }

    // Returns the minimum representable subnormal value in the current context.
    static Decimal min() {
        return Decimal(1, context.eTiny);
    }

    // returns the smallest available increment to 1.0 in this context
    static Decimal epsilon() {
        return Decimal(1, -context.precision);
    }

    static int min_10_exp() {
        return context.eMin;
    }

    static int max_10_exp() {
        return context.eMax;
    }

//--------------------------------
//  classification properties
//--------------------------------

    /**
     * Returns true if this number's representation is canonical (always true).
     */
    const bool isCanonical() {
        return  true;
    }

    unittest {
        write("isCanonical...");
        writeln("test missing");
    }

    /**
     * Returns the canonical form of the number.
     */
    const Decimal canonical() {
        return this.dup;
    }

    unittest {
        write("canonical....");
        Decimal num = Decimal("2.50");
        assert(num.isCanonical);
        writeln("passed");
    }

    /**
     * Returns true if this number is + or - zero.
     */
    const bool isZero() {
        return isFinite && coefficient == 0;
    }

    unittest {
        write("isZero.......");
        Decimal num;
        num = Decimal("0");
        assert(num.isZero);
        num = Decimal("2.50");
        assert(!num.isZero);
        num = Decimal("-0E+2");
        assert(num.isZero);
        writeln("passed");
    }

    /**
     * Returns true if this number is a quiet or signaling NaN.
     */
    const bool isNaN() {
        return this.sval == SV.QNAN || this.sval == SV.SNAN;
    }

    unittest {
        write("isNaN........");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isNaN);
        num = Decimal("NaN");
        assert(num.isNaN);
        num = Decimal("-sNaN");
        assert(num.isNaN);
        writeln("passed");
    }

    /**
     * Returns true if this number is a signaling NaN.
     */
    const bool isSignaling() {
        return this.sval == SV.SNAN;
    }

    unittest {
        write("isSignaling..");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isSignaling);
        num = Decimal("NaN");
        assert(!num.isSignaling);
        num = Decimal("sNaN");
        assert(num.isSignaling);
        writeln("passed");
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return this.sval == SV.QNAN;
    }

    unittest {
        write("isQuiet......");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isQuiet);
        num = Decimal("NaN");
        assert(num.isQuiet);
        num = Decimal("sNaN");
        assert(!num.isQuiet);
        writeln("passed");
    }

    /**
     * Returns true if this number is + or - infinity.
     */
    const bool isInfinite() {
        return this.sval == SV.INF;
    }

    unittest {
        write("isInfinite...");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isInfinite);
        num = Decimal("-Inf");
        assert(num.isInfinite);
        num = Decimal("NaN");
        assert(!num.isInfinite);
        writeln("passed");
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
        write("isFinite.....");
        Decimal num;
        num = Decimal("2.50");
        assert(num.isFinite);
        num = Decimal("-0.3");
        assert(num.isFinite);
        num = 0;
        assert(num.isFinite);
        num = Decimal("Inf");
        assert(!num.isFinite);
        num = Decimal("-Inf");
        assert(!num.isFinite);
        num = Decimal("NaN");
        assert(!num.isFinite);
        writeln("passed");
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
        write("isSpecial....");
        writeln("test missing");
    }

    /**
     * Returns true if this number is negative. (Includes -0)
     */
    const bool isSigned() {
        return this.signed;
    }

    unittest {
        write("isSigned.....");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isSigned);
        num = Decimal("-12");
        assert(num.isSigned);
        num = Decimal("-0");
        assert(num.isSigned);
        writeln("passed");
    }

    const bool isNegative() {
        return this.signed;
    }

    unittest {
        write("isNegative...");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isNegative);
        num = Decimal("-12");
        assert(num.isNegative);
        num = Decimal("-0");
        assert(num.isNegative);
        writeln("passed");
    }

    /**
     * Returns true if this number is subnormal.
     */
    const bool isSubnormal() {
        if (sval != SV.NONE) return false;
        return adjustedExponent < context.eMin;
    }

    unittest {
        write("isSubnormal..");
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isSubnormal);
        num = Decimal("0.1E-99");
        assert(num.isSubnormal);
        num = Decimal("0.00");
        assert(!num.isSubnormal);
        num = Decimal("-Inf");
        assert(!num.isSubnormal);
        num = Decimal("NaN");
        assert(!num.isSubnormal);
        writeln("passed");
    }

    /**
     * Returns true if this number is normal.
     */
    const bool isNormal() {
        if (isFinite && !isZero) {
            return adjustedExponent >= context.eMin;
        }
        return false;
    }

    unittest {
        write("isNormal.....");
        Decimal num;
        num = Decimal("2.50");
        assert(num.isNormal);
        num = Decimal("0.1E-99");
        assert(!num.isNormal);
        num = Decimal("0.00");
        assert(!num.isNormal);
        num = Decimal("-Inf");
        assert(!num.isNormal);
        num = Decimal("NaN");
        assert(!num.isNormal);
        writeln("passed");
    }

    /**
     * Returns true if this number is integral;
     * that is, its fractional part is zero.
     */
     const bool isIntegral() {
        return expo >= 0;
     }

    unittest {
        write("isIntegral...");
        writeln("test missing");
    }

//--------------------------------
// comparison
//--------------------------------

    /**
     * Returns -1, 0 or 1, if this number is less than, equal to or
     * greater than the argument, respectively.
     */
    const int opCmp(const Decimal that) {
        return compare!Decimal(this, that, context);
    }

unittest {
    write("opCmp...");
    writeln("test missing");
}

    /**
     * Returns true if this number is equal to the specified Decimal.
     * A NaN is not equal to any number, not even to another NaN.
     * Infinities are equal if they have the same sign.
     * Zeros are equal regardless of sign.
     * Finite numbers are equal if they are numerically equal to the current precision.
     * A Decimal may not be equal to itself (this != this) if it is a NaN.
     */
    const bool opEquals (ref const Decimal that) {
        return equals!Decimal(this, that, context);
    }

unittest {
    write("opEquals...");
    writeln("test missing");
}

//--------------------------------
// unary arithmetic operators
//--------------------------------

    /**
     * unary minus -- returns a copy with the opposite sign.
     * This operation may set flags -- equivalent to
     * subtract('0', b);
     */
    const Decimal opNeg() {
        return minus!Decimal(this, context);
    }

    unittest {
        write("opUnary...");
        writeln("test missing");
    }

    /**
     * unary plus -- returns a copy.
     * This operation may set flags -- equivalent to
     * add('0', a);
     */
    const Decimal opPos() {
        return plus!Decimal(this, context);
    }

    unittest {
        write("opUnary...");
        writeln("test missing");
    }

    /**
     * Returns this + 1.
     */
    Decimal opPostInc() {
        this += 1;
        return this;
    }

    unittest {
        write("opUnary...");
        writeln("test missing");
    }

    /**
     * Returns this - 1.
     */
    Decimal opPostDec() {
        this -= 1;
        return this;
    }

    unittest {
        write("opUnary...");
        writeln("test missing");
    }

//--------------------------------
//  binary arithmetic operators
//--------------------------------

    //TODO: these should be converted to opBinary, etc.

    /**
     * If the operand is a Decimal, act directly on it.
     */
/*    const Decimal opBinary(string op, T:Decimal)(const T operand) {
        return opBinary!op(this, operand);
    }*/

    // TODO: is there some sort of compile time check we can do here?
    // i.e., if T convertible to Decimal?
    /**
     * If the operand is a type that can be converted to Decimal,
     * make the conversion and call the Decimal version.
     */
/*    const Decimal opBinary(string op, T)(const T operand) {
        return opBinary!op(this, Decimal(operand));
    }*/

    /**
     * Adds a number to this and returns the result.
     */
/*    const Decimal opBinary(string op)(const Decimal addend) if (op == "+") {
        return add(this, addend);
    }*/

    /// Adds a Decimal to this and returns the Decimal result
    const Decimal opAdd(T:Decimal)(const T addend) {
        return add!Decimal(this, addend, context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    // Adds a number to this and returns the result.
    const Decimal opAdd(T)(const T addend) {
        return add!Decimal(this, Decimal(BigInt(addend)), context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opSub(T:Decimal)(const T subtrahend) {
        return subtract!Decimal(this, subtrahend, context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opSub(T)(const T subtrahend) {
        return subtract!Decimal(this, Decimal(BigInt(subtrahend)), context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMul(T:Decimal)(const T multiplier) {
        return multiply!Decimal(this, multiplier, context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMul(T:long)(const T multiplier) {
        return multiply!Decimal(this, Decimal(BigInt(multiplier)), context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opDiv(T:Decimal)(const T divisor) {
        return divide!Decimal(this, divisor, context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opDiv(T)(const T divisor) {
        return divide!Decimal(this, Decimal(divisor), context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMod(T:Decimal)(const T divisor) {
        return remainder!Decimal(this, divisor, context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMod(T)(const T divisor) {
        return remainder(this, Decimal(divisor), context);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

//--------------------------------
//  arithmetic assignment operators
//--------------------------------

    Decimal opAddAssign(T)(const T addend) {
        this = this + addend;
        return this;
    }

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

/*    ref Decimal opOpAssign(string op, T)(const T operand) {
        return opBinary!op(this, operand);
    }*/

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

    Decimal opSubAssign(T)(const T subtrahend) {
        this = this - subtrahend;
        return this;
    }

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

    Decimal opMulAssign(T)(const T factor) {
        this = this * factor;
        return this;
    }

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

    Decimal opDivAssign(T)(const T divisor) {
        this = this / divisor;
        return this;
    }

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

    Decimal opModAssign(T)(const T divisor) {
        this = this % divisor;
        return this;
    }

    unittest {
        write("opOpAssign...");
        writeln("test missing");
    }

//-----------------------------
// nextUp, nextDown, nextAfter
//-----------------------------

    const Decimal nextUp() {
        return nextPlus!Decimal(this, context);
    }

    unittest {
        write("nextUp...");
        writeln("test missing");
    }

    const Decimal nextDown() {
        return nextMinus!Decimal(this, context);
    }

    unittest {
        write("nextMinus...");
        writeln("test missing");
    }

    const Decimal nextAfter(const Decimal num) {
        return nextToward!Decimal(this, num, context);
    }

unittest {
    write("nextAfter...");
    writeln("test missing");
}

//-----------------------------
// helper functions
//-----------------------------

     /**
     * Returns (BigInt) ten raised to the specified power.
     */
    static BigInt pow10(const int n) {
        BigInt big = BigInt(1);
        return decShl(big, n);
    }

    unittest {
        write("pow10..........");
        int n;
        BigInt pow;
        n = 3;
        assert(pow10(n) == 1000);
        writeln("passed");
    }

}    // end struct Decimal

unittest {
    writeln();
    writeln("-------------------");
    writeln("Decimal......tested");
    writeln("-------------------");
    writeln();
}

