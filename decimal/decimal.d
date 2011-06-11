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
import decimal.digits;
import decimal.arithmetic;
import std.bigint;
import std.exception: assumeUnique;
import std.conv;
import std.ctype: isdigit;
import std.math: PI, LOG2;
import std.stdio: write, writeln;
import std.string;

unittest {
    writeln("-------------------");
    writeln("decimal.....testing");
    writeln("-------------------");
}

alias Decimal.context context;
// alias Decimal.context.precision precision;

/// precision stack
private static Stack!(uint) precisionStack;

/// saves the current precision
package static void pushPrecision() {
    precisionStack.push(context.precision);
}

unittest {
    write("pushPrecision...");
    writeln("test missing");
}

/// restores the previous precision
package static void popPrecision() {
    context.precision = precisionStack.pop();
}

unittest {
    write("popPrecision...");
    writeln("test missing");
}

/**
 * A struct representing an arbitrary-precision floating-point number.
 *
 * The implementation follows the General Decimal Arithmetic
 * Specification, Version 1.70 (25 Mar 2009),
 * http://www.speleotrove.com/decimal. This specification conforms with
 * IEEE standard 754-2008.
 */
struct Decimal {

// special values for NaN, Inf, etc.
private static enum SV {CLEAR, ZERO, INF, QNAN, SNAN};

/*public @property bool sign() { return m_sign; };
public @property void sign(bool value) { m_sign = value; };

public @property int expo() { return m_expo; };
public @property void expo(int value) { m_expo = value; };

public @property int digits() { return m_digits; };
public @property void digits(int value) { m_digits = value; };*/

    package static context = DEFAULT_CONTEXT.dup;

    package SV sval = SV.QNAN;        // special values: default value is quiet NaN
    package bool sign = false;        // true if the value is negative, false otherwise.
    package int expo = 0;            // the exponent of the Decimal value
    package BigInt mant;            // the coefficient of the Decimal value
    // NOTE: not a uint -- causes math problems down the line.
    package int digits;                 // the number of decimal digits in this number.
                                     // (unless the number is a special value)
//private:
    /**
     * clears the special value flags
     */
    public void clear() {
        sval = SV.CLEAR;
    }

public:

// common decimal "numbers"
    static immutable Decimal NaN      = cast(immutable)Decimal(SV.QNAN);
    static immutable Decimal POS_INF  = cast(immutable)Decimal(SV.INF);
    static immutable Decimal NEG_INF  = cast(immutable)Decimal(true, SV.INF);
    static immutable Decimal ZERO     = cast(immutable)Decimal(SV.ZERO);
    static immutable Decimal NEG_ZERO = cast(immutable)Decimal(true, SV.ZERO);

//    static immutable BigInt BIG_ZERO  = cast(immutable)BigInt(0);

/*    static immutable Decimal ONE  = cast(immutable)Decimal(1);
    static immutable Decimal TWO  = cast(immutable)Decimal(2);
    static immutable Decimal FIVE = cast(immutable)Decimal(5);
    static immutable Decimal TEN  = cast(immutable)Decimal(10);*/


//--------------------------------
// construction
//--------------------------------

    // UNREADY: this(bool, SV). Flags. Unit Tests.
    private this(bool sign, SV sv) {
        this.sign = sign;
        sval = sv;
    }

    unittest {
        write("this(bool, SV)...");
        writeln("test missing");
    }

    // UNREADY: this(SV). Flags. Unit Tests.
    private this(SV sv) {
        sval = sv;
    }

    unittest {
        write("this(SV)...");
        writeln("test missing");
    }

    // UNREADY: this(bool, const BigInt, const int). Flags. Unit Tests.
    /**
     * Constructs a number from a sign, a BigInt coefficient and
     * an integer exponent.
     * The precision of the number is deduced from the number of decimal
     * digits in the coefficient.
     */
    this(const bool sign, const BigInt coefficient, const int exponent) {
//        writeln("calling this(1)");
        BigInt big = cast(BigInt) coefficient;
//        writeln("1");
        this.clear();
//        writeln("2");
        if (big < BigInt(0)) {
            this.sign = !sign;
//        writeln("3");
            this.mant = -big;
//        writeln("4");
        }
        else {
            this.sign = sign;
//        writeln("5");
            this.mant = big;
//        writeln("6");
            if (big == BigInt(0)) {
                this.sval = SV.ZERO;
//        writeln("7");
            }
        }
        this.expo = exponent;
//        writeln("8");
        this.digits = numDigits(this.mant);
//        writeln("0");
    }

    unittest {
        write("this(bool, BigInt, int)...");
        writeln("test missing");
    }

/*    /// Assign a BigInt
    void opAssign(const BigInt big) {
        BigInt _big = cast(BigInt) big;
        sval = (_big == BigInt(0)) ? SV.ZERO : SV.CLEAR;
        sign = _big < 0;
        mant = sign ? -_big : _big;
        expo = 0;
        digits = numDigits(mant);
    }*/

    // UNREADY: this(bool, const int, const int). Flags. Unit Tests.
    /**
     * Constructs a number from a sign, an integer coefficient and
     * an integer exponent.
     */
/*    this(const bool sign, const long coefficient, const int exponent) {
        this(sign, BigInt(coefficient), exponent);
    }*/

    // UNREADY: this(bool, string, uint = 0). Flags. Unit Tests.
    /**
     * Constructs a number from a sign, a special value string and
     * an optional payload.
     */
    this(const bool sign, string str, const uint payload = 0) {
//        writeln("calling this(2)");
        this.clear();;
        this.sign = sign;
        if (icmp(str, "inf") == 0 || icmp(str, "infinity") == 0) {
            sval = SV.INF;
            return;
        }
        if (icmp(str, "snan") == 0) {
            sval = SV.SNAN;
        }
        else {
            sval = SV.QNAN;
        }
        mant = payload;
    }

    unittest {
        write("this(bool, string, uint)...");
        writeln("test missing");
    }

    // UNREADY: this(const BigInt, const int). Flags. Unit Tests.
    /**
     * Constructs a Decimal from a BigInt coefficient and an int exponent.
     * The sign of the number is the sign of the coefficient.
     */
    this(const BigInt coefficient, const int exponent = 0) {
//        writeln("calling this(3)");
        this(false, coefficient, exponent);
    };

    unittest {
        write("this(BigInt, int)...");
        writeln("test missing");
    }

    // UNREADY: this(const BigInt). Flags. Unit Tests.
    /**
     * Constructs a number from a BigInt.
     */
/*    this(const BigInt coefficient) {
        this(coefficient, 0);
    };
*/
    // UNREADY: this(const long, const int). Flags. Unit Tests.
    /**
     * Constructs a number from an long coefficient and an integer exponent.
     */
    this(const long coefficient, const int exponent) {
//        writeln("calling this(5)");
        this(BigInt(coefficient), exponent);
    }

    unittest {
        write("this(long, int..");
        writeln("test missing");
    }

    // UNREADY: this(const long). Flags. Unit Tests.
    /**
     * Constructs a number from an integer value.
     */
    this(const long coefficient) {
//        writeln("calling this(6)");
        this(BigInt(coefficient));
    }

    unittest {
        write("this(long)...");
        writeln("test missing");
    }

    // UNREADY: this(const long, const int, const int). Flags. Unit Tests.
    /**
     * Constructs a number from an integer coefficient, exponent and precision.
     */
     // TODO: should this set flags? probably not.
    this(const long coefficient, const int exponent, const int precision) {
//        writeln("calling this(7)");
//        pushPrecision;
        this(coefficient, exponent);
        context.precision = precision;
        setDigits(this);
//        popPrecision;
    }

    unittest {
        write("this(long, int, int)...");
        writeln("test missing");
    }

    // UNREADY: this(const long, const int, const int). Flags. Unit Tests.
    /**
     * Constructs a number from an integer coefficient, exponent and precision.
     */
     // TODO: should this set flags? probably not.
/*    this(const bool sign, const ulong coefficient, const int exponent) {
        writeln("calling this(7)");
//        pushPrecision;
        this(coefficient, exponent);
        context.precision = precision;
        setDigits(this);
//        popPrecision;
    }
*/
    // UNREADY: this(const string). Flags. Unit Tests.
    // construct from string representation
    this(const string str) {
        this = str;
    };

    unittest {
        write("this(string)...");
        writeln("test missing");
    }

    // UNREADY: this(const real). Flags. Unit Tests.
    /**
     *    Constructs a number from a real value.
     */
    this(const real r) {
        string str = format("%.*G", cast(int)context.precision, r);
        this = str;
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
    this(const real r, const int precision) {
        string str = format("%.*E", precision, r);
        this = str;
    }

    unittest {
        write("this(real, int..");
        writeln("test missing");
    }

    // UNREADY: this(Decimal). Flags. Unit Tests.
    // copy constructor
    this(const Decimal that) {
        this = that;
    };

    unittest {
        write("this(Decimal)...");
        writeln("test missing");
    }

    // UNREADY: dup. Flags. Unit Tests.
    /**
     * dup property
     */
    const Decimal dup() {
        Decimal copy;
        copy.sval = sval;
        copy.sign = sign;
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
    f = Decimal(1234, 0, 9);
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
    assert(f.toString() == "12346");
    writeln("passed");
}

//--------------------------------
// assignment
//--------------------------------

    // UNREADY: opAssign(T: Decimal)(const Decimal). Flags. Unit Tests.
    /// Assigns a Decimal (makes a copy)
    void opAssign/*(T:Decimal)*/(const Decimal that) {
        this.sign = that.sign;
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

    // TODO: Don says this implicit cast is "disgusting"!!
    /// Assigns a string
    void opAssign/*(T:string)*/(const string numeric_string) {
        this = toNumber(numeric_string);
    }

    unittest {
        write("opAssign(string)...");
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
            return format("[%d,%s%s]", sign ? 1 : 0, "sNaN", payload);
        case SV.QNAN:
            string payload = mant == BigInt(0) ? "" : "," ~ toDecString(mant);
            return format("[%d,%s%s]", sign ? 1 : 0, "qNaN", payload);
        case SV.INF:
            return format("[%d,%s]", sign ? 1 : 0, "inf");
        default:
            return format("[%d,%s,%d]", sign ? 1 : 0, toDecString(mant), expo);
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
    return toSciString(this);
};    // end toString()

unittest {
    write("toString...");
    writeln("test missing");
}

//--------------------------------
// member properties
//--------------------------------

// TODO: make these true properties.

    /// returns the exponent of this number
    const int exponent() {
        return this.expo;
    }

unittest {
    write("exponent...");
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

    /// returns the coefficient of this number
    const const(BigInt) coefficient() {
        return this.mant;
    }

unittest {
    write("coefficient...");
    writeln("test missing");
}

    /// returns the sign of this number
    const int sgn() {
        if (isZero) return 0;
        return sign ? -1 : 1;
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

unittest {
    write("precision...");
    writeln("test missing");
}

    /// returns the default value for this type (NaN)
    static Decimal init() {
        return NaN.dup;
    }

unittest {
    write("init...");
    writeln("test missing");
}

    /// Returns NaN
    static Decimal nan() {
        return NaN.dup;
    }

    unittest {
        write("nan...");
        writeln("test missing");
    }

    /// Returns positive infinity.
    static Decimal infinity() {
        return POS_INF.dup;
    }

    unittest {
        write("infinity...");
        writeln("test missing");
    }

    /// Returns the number of decimal digits in this context.
    static uint dig() {
        return context.precision;
    }

    unittest {
        write("dig...");
        writeln("test missing");
    }

    /// Returns the number of binary digits in this context.
    static int mant_dig() {
        return cast(int)(context.precision/LOG2);
    }

    unittest {
        write("mant_dig...");
        writeln("test missing");
    }

    static int min_exp() {
        return cast(int)(context.eMin/LOG2);
    }

    unittest {
        write("min_exp...");
        writeln("test missing");
    }

    static int max_exp() {
        return cast(int)(context.eMax/LOG2);
    }

    unittest {
        write("max_exp...");
        writeln("test missing");
    }

    // Returns the maximum representable normal value in the current context.
    static Decimal max() {
        string cstr = "9." ~ repeat("9", context.precision-1)
            ~ "E" ~ format("%d", context.eMax);
        return Decimal(cstr);
    }

    unittest {
        write("max...");
        writeln("test missing");
    }

    // Returns the minimum representable normal value in the current context.
    static Decimal min_normal() {
        return Decimal(1, context.eMin);
    }

    unittest {
        write("min_normal...");
        writeln("test missing");
    }

    // Returns the minimum representable subnormal value in the current context.
    static Decimal min() {
        return Decimal(1, context.eTiny);
    }

    unittest {
        write("min...");
        writeln("test missing");
    }

    // returns the smallest available increment to 1.0 in this context
    static Decimal epsilon() {
        return Decimal(1, -context.precision);
    }

    unittest {
        write("epsilon...");
        writeln("test missing");
    }

    static int min_10_exp() {
        return context.eMin;
    }

    unittest {
        write("min_10_exp...");
        writeln("test missing");
    }

    static int max_10_exp() {
        return context.eMax;
    }

    unittest {
        write("max_10_exp...");
        writeln("test missing");
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
        return sval == SV.ZERO;
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
        return this.sign;
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
        return this.sign;
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
        if (sval != SV.CLEAR) return false;
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
        if (sval != SV.CLEAR) return false;
        return adjustedExponent >= context.eMin;
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
        return compare(this, that);
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
    const bool opEquals(ref const Decimal that) {
        return equals(this, that);
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
        return minus(this);
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
        return plus(this);
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
        return add(this, addend);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    // Adds a number to this and returns the result.
    const Decimal opAdd(T)(const T addend) {
        return add(this, Decimal(addend));
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opSub(T:Decimal)(const T subtrahend) {
        return subtract(this, subtrahend);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opSub(T)(const T subtrahend) {
        return subtract(this, Decimal(subtrahend));
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMul(T:Decimal)(const T multiplier) {
        return multiply(this, multiplier);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMul(T)(const T multiplier) {
        return multiply(this, Decimal(multiplier));
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opDiv(T:Decimal)(const T divisor) {
        return divide(this, divisor);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opDiv(T)(const T divisor) {
        return divide(this, Decimal(divisor));
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMod(T:Decimal)(const T divisor) {
        return remainder(this, divisor);
    }

    unittest {
        write("opBinary...");
        writeln("test missing");
    }

    const Decimal opMod(T)(const T divisor) {
        return remainder(this, Decimal(divisor));
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
        return nextPlus(this);
    }

unittest {
    write("nextUp...");
    writeln("test missing");
}

    const Decimal nextDown() {
        return nextMinus(this);
    }

unittest {
    write("nextMinus...");
    writeln("test missing");
}

    const Decimal nextAfter(const Decimal dcm) {
        return nextToward(this, dcm);
    }

unittest {
    write("nextAfter...");
    writeln("test missing");
}

//-----------------------------
// helper functions
//-----------------------------

}    // end struct Decimal

unittest {
    writeln();
    writeln("-------------------");
    writeln("Decimal......tested");
    writeln("-------------------");
    writeln();
}

