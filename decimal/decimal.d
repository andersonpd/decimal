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

alias Decimal.bigContext bigContext;

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

    private static DecimalContext bigContext = DecimalContext();

    // TODO: make these private
    private SV sval = SV.QNAN;        // special values: default value is quiet NaN
    private bool signed = false;        // true if the value is negative, false otherwise.
    private int expo = 0;            // the exponent of the Decimal value
    private BigInt mant;            // the coefficient of the Decimal value
    // NOTE: not a uint -- causes math problems down the line.
    package int digits;                 // the number of decimal digits in this number.
                                     // (unless the number is a special value)

private:

// common decimal "numbers"
    immutable Decimal NAN      = Decimal(SV.QNAN);
    immutable Decimal SNAN     = Decimal(SV.SNAN);
    immutable Decimal INFINITY = Decimal(SV.INF);
    immutable Decimal NEG_INF  = Decimal(SV.INF, true);
    immutable Decimal ZERO     = Decimal(SV.ZERO);
    immutable Decimal NEG_ZERO = Decimal(SV.ZERO, true);

    immutable BigInt BIG_ZERO  = cast(immutable)BigInt(0);

//    static immutable Decimal ONE  = cast(immutable)Decimal(1);
//    static immutable Decimal TWO  = cast(immutable)Decimal(2);
//    static immutable Decimal FIVE = cast(immutable)Decimal(5);
//    static immutable Decimal TEN  = cast(immutable)Decimal(10);

unittest {
    Decimal num;
    num = NAN;
    assert(num.toString == "NaN");
    num = SNAN;
    assert(num.toString == "sNaN");
    assert("Decimal(SV.QNAN).toAbstract = ", NAN.toAbstract);
    num = NEG_ZERO;
    assert(num.toString == "-0");
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
    public this(const SV sv, const bool sign = false) {
        this.signed = sign;
        this.sval = sv != SV.ZERO ? sv : SV.NONE;
    }

    unittest {
        Decimal num = Decimal(SV.INF, true);
        assert(num.toSciString == "-Infinity");
        assert(num.toAbstract() == "[1,inf]");
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
        this.digits = numDigits(this.mant);
    }

    unittest {
        Decimal num;
        num = Decimal(true, BigInt(7254), 94);
        assert(num.toString == "-7.254E+97");
    }

    // UNREADY: this(const BigInt, const int). Flags.
    /**
     * Constructs a Decimal from a BigInt coefficient and an
     * optional integer exponent. The sign of the number is the sign
     * of the coefficient. The initial precision is determined by the number
     * of digits in the coefficient.
     */
    this(const BigInt coefficient, const int exponent = 0) {
        BigInt big = copy(coefficient);
        bool sign = decimal.rounding.sgn(big) < 0;
        this(sign, big, exponent);
    };

    unittest {
        Decimal num;
        num = Decimal(BigInt(7254), 94);
        assert(num.toString == "7.254E+97");
        num = Decimal(BigInt(-7254));
        assert(num.toString == "-7254");
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

    // UNREADY: this(const long, const int). Flags. Unit Tests.
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
    this(const string str) {
        this = decimal.conv.toNumber(str);
    };

    unittest {
        Decimal num;
        string str;
        num = Decimal(1, 12334, -5);
        str = "-0.12334";
        assert(num.toString == str);
        num = Decimal(-23456, 10);
        str = "-2.3456E+14";
        assert(num.toString == str);
        num = Decimal(234568901234);
        str = "234568901234";
        assert(num.toString == str);
        num = Decimal("123.457E+29");
        str = "1.23457E+31";
        assert(num.toString == str);
        num = std.math.E;
        str = "2.71828183";
        assert(num.toString == str);
        num = std.math.LOG2;
        Decimal copy = Decimal(num);
        assert(compareTotal!Decimal(num, copy) == 0);
    }

    // floating point constructors:

    // UNREADY: this(const real). Flags. Unit Tests.
    /**
     *    Constructs a number from a real value.
     */
    this(const real r) {
        string str = format("%.*G", cast(int)bigContext.precision, r);
        this(str);
    }

    // UNREADY: this(Decimal). Flags. Unit Tests.
    // copy constructor
    this(const Decimal that) {
        this = that;
    };

    // UNREADY: dup. Flags.
    /**
     * dup property
     */
    const Decimal dup() {
        return Decimal(this);
    }

    unittest {
        Decimal num = Decimal(std.math.PI);
        Decimal copy = num.dup;
        assert(num == copy);
    }

//--------------------------------
// assignment
//--------------------------------

    // UNREADY: opAssign(T: Decimal)(const Decimal). Flags. Unit Tests.
    /// Assigns a Decimal (makes a copy)
    void opAssign(T:Decimal)(const T that) {
        this.signed = that.signed;
        this.sval   = that.sval;
        this.digits = that.digits;
        this.expo   = that.expo;
        this.mant   = cast(BigInt) that.mant;
    }

    // UNREADY: opAssign(T)(const T). Flags.
    ///    Assigns a floating point value.
    void opAssign(T:BigInt)(const T that) {
        this = Decimal(that);
    }

    // UNREADY: opAssign(T)(const T). Flags.
    ///    Assigns a floating point value.
    void opAssign(T:long)(const T that) {
        this = Decimal(that);
    }

    // UNREADY: opAssign(T)(const T). Flags. Unit Tests.
    ///    Assigns a floating point value.
    void opAssign(T:real)(const T that) {
        this = Decimal(that);
    }

    void opAssign(T)(const T that) if (isDecimal!T) {
        this = decimal.conv.toDecimal!T(that);
    }

    unittest {
        import decimal.dec32;

        Decimal num;
        string str;
        num = Decimal(1, 245, 8);
        str = "-2.45E+10";
        assert(num.toString == str);
        num = long.max;
        str = "9223372036854775807";
        assert(num.toString == str);
        num = real.max;
        str = "1.1897315E+4932";
        assert(num.toString == str);
        num = Dec32.max;
        str = "9.999999E+96";
        assert(num.toString == str);
        num = BigInt("123456098420234978023480");
        str = "123456098420234978023480";
        assert(num.toString == str);
    }

//--------------------------------
// string representations
//--------------------------------

    /**
     * Converts a number to an abstract string representation.
     */
    public const string toAbstract() {
        return decimal.conv.toAbstract!Decimal(this);
    }

unittest {
    Decimal num;
    string str;
    num = Decimal("-inf");
    str = "[1,inf]";
    assert(num.toAbstract == str);
    num = Decimal("nan");
    str = "[0,qNaN]";
    assert(num.toAbstract == str);
    num = Decimal("snan1234");
    str = "[0,sNaN1234]";
    assert(num.toAbstract == str);
}

// READY: toSciString.
/**
 * Converts a Decimal to a string representation.
 */
const string toSciString() {
    return decimal.conv.toSciString!Decimal(this);
};

// READY: toEngString.
/**
 * Converts a Decimal to an engineering string representation.
 */
const string toEngString() {
   return decimal.conv.toEngString!Decimal(this);
};

/**
 * Converts a number to its string representation.
 */
const string toString() {
    return toSciString();
};

unittest {
    Decimal num;
    string str;
    num = Decimal(200000, 71);
    str = "2.00000E+76";
    assert(num.toString == str);
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
        write("payload");
        writeln("test missing");
    }

    const string toExact() {
        return decimal.conv.toExact!Decimal(this);
    }

    unittest {
        Decimal num;
        assert(num.toExact == "+NaN");
        num = +9999999E+90;
        assert(num.toExact == "+9999999E+90");
        num = 1;
        assert(num.toExact == "+1E+00");
        num = infinity(true);
        assert(num.toExact == "-Infinity");
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

//--------------------------------
// floating point properties
//--------------------------------

    /// returns the default value for this type (NaN)
    static Decimal init() {
        return NAN.dup;
    }

    /// Returns NaN
    static Decimal nan(uint payload = 0) {
        if (payload) {
            Decimal dec = NAN.dup;
            dec.payload = payload;
            return dec;
        }
        return NAN.dup;
    }

    /// Returns signaling NaN
    static Decimal snan(uint payload = 0) {
        if (payload) {
            Decimal dec = SNAN.dup;
            dec.payload = payload;
            return dec;
        }
        return SNAN.dup;
    }

    /// Returns infinity.
    static Decimal infinity(bool signed = false) {
        return signed ? NEG_INF.dup : INFINITY.dup;
    }

    /// Returns zero.
    static Decimal zero(bool signed = false) {
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
        return context.mant_dig;
    }

    static int min_exp(DecimalContext context = bigContext) {
        return context.min_exp;
    }

    static int max_exp(DecimalContext context = bigContext) {
        return context.max_exp;
    }

    // Returns the maximum representable normal value in the current context.
    // TODO: this is a fairly expensive operation. Can it be fixed?
    static Decimal max(DecimalContext context = bigContext) {
        return Decimal(context.maxString);
    }

    /// Returns the minimum representable normal value in this context.
    static Decimal min_normal(DecimalContext context = bigContext) {
        return Decimal(1, context.eMin);
    }

    /// Returns the minimum representable subnormal value in this context.
    static Decimal min(DecimalContext context = bigContext) {
        return Decimal(1, context.eTiny);
    }

    /// returns the smallest available increment to 1.0 in this context
    static Decimal epsilon(DecimalContext context = bigContext) {
        return Decimal(1, -context.precision);
    }

    static int min_10_exp(DecimalContext context = bigContext) {
        return context.eMin;
    }

    static int max_10_exp(DecimalContext context = bigContext) {
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

    /**
     * Returns the canonical form of the number.
     */
    const Decimal canonical() {
        return this.dup;
    }

    unittest {
        Decimal num = Decimal("2.50");
        assert(num.isCanonical);
        Decimal copy = num.canonical;
        assert(compareTotal(num, copy) == 0);
    }

    /**
     * Returns true if this number is + or - zero.
     */
    const bool isZero() {
        return isFinite && coefficient == 0;
    }

    unittest {
        Decimal num;
        num = Decimal("0");
        assert(num.isZero);
        num = Decimal("2.50");
        assert(!num.isZero);
        num = Decimal("-0E+2");
        assert(num.isZero);
    }

    /**
     * Returns true if this number is a quiet or signaling NaN.
     */
    const bool isNaN() {
        return this.sval == SV.QNAN || this.sval == SV.SNAN;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isNaN);
        num = Decimal("NaN");
        assert(num.isNaN);
        num = Decimal("-sNaN");
        assert(num.isNaN);
    }

    /**
     * Returns true if this number is a signaling NaN.
     */
    const bool isSignaling() {
        return this.sval == SV.SNAN;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isSignaling);
        num = Decimal("NaN");
        assert(!num.isSignaling);
        num = Decimal("sNaN");
        assert(num.isSignaling);
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return this.sval == SV.QNAN;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isQuiet);
        num = Decimal("NaN");
        assert(num.isQuiet);
        num = Decimal("sNaN");
        assert(!num.isQuiet);
    }

    /**
     * Returns true if this number is + or - infinity.
     */
    const bool isInfinite() {
        return this.sval == SV.INF;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isInfinite);
        num = Decimal("-Inf");
        assert(num.isInfinite);
        num = Decimal("NaN");
        assert(!num.isInfinite);
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
        Decimal num;
        num = infinity(true);
        assert(num.isSpecial);
        num = snan(1234);
        assert(num.isSpecial);
        num = 12378.34;
        assert(!num.isSpecial);
    }

    /**
     * Returns true if this number is negative. (Includes -0)
     */
    const bool isSigned() {
        return this.signed;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isSigned);
        num = Decimal("-12");
        assert(num.isSigned);
        num = Decimal("-0");
        assert(num.isSigned);
    }

    const bool isNegative() {
        return this.signed;
    }

    unittest {
        Decimal num;
        num = Decimal("2.50");
        assert(!num.isNegative);
        num = Decimal("-12");
        assert(num.isNegative);
        num = Decimal("-0");
        assert(num.isNegative);
    }

    /**
     * Returns true if this number is subnormal.
     */
    const bool isSubnormal() {
        if (!isFinite) return false;
        return adjustedExponent < bigContext.eMin;
    }

    unittest {
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
    }

    /**
     * Returns true if this number is normal.
     */
    const bool isNormal() {
        if (isFinite && !isZero) {
            return adjustedExponent >= bigContext.eMin;
        }
        return false;
    }

    unittest {
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
    }

    /**
     * Returns true if this number is integral;
     * that is, its fractional part is zero.
     */
     const bool isIntegral() {
        return expo >= 0;
     }

    unittest {
        Decimal num;
        num = 12345;
        assert(num.isIntegral);
        num = BigInt("123456098420234978023480");
        assert(num.isIntegral);
        num = 1.5;
        assert(!num.isIntegral);
        num = 1.5E+1;
        assert(num.isIntegral);
        num = 0;
        assert(num.isIntegral);
    }

//--------------------------------
// comparison
//--------------------------------

    /**
     * Returns -1, 0 or 1, if this number is less than, equal to or
     * greater than the argument, respectively.
     */
    const int opCmp(const Decimal that) {
        return compare!Decimal(this, that, bigContext);
    }

    unittest {
        Decimal num1, num2;
        num1 = 105;
        num2 = 10.543;
        assert(num1 > num2);
        assert(num2 < num1);
        num1 = 10.543;
        assert(num1 >= num2);
        assert(num2 <= num1);
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
        return equals!Decimal(this, that, bigContext);
    }

    unittest {
        Decimal num1, num2;
        num1 = 105;
        num2 = 10.543;
        assert(num1 != num2);
        num1 = 10.543;
        assert(num1 == num2);
    }

//--------------------------------
// unary arithmetic operators
//--------------------------------

    const Decimal opUnary(string op)()
    {
        static if (op == "+") {
            return plus!Decimal(this, bigContext);
        }
        else static if (op == "-") {
            return minus!Decimal(this, bigContext);
        }
        else static if (op == "++") {
            return add!Decimal(this, Decimal(1), bigContext);
        }
        else static if (op == "--") {
            return subtract!Decimal(this, Decimal(1), bigContext);
        }
    }

    unittest {
        Decimal num, actual, expect;
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
        num = Decimal(9999999, 90);
        expect = num;
        actual = num++;
        assert(actual == expect);
        num = 12.35;
        expect = 11.35;
        actual = --num;
        assert(actual == expect);
    }

//--------------------------------
//  binary arithmetic operators
//--------------------------------

    const Decimal opBinary(string op)(const Decimal rhs)
    {
        static if (op == "+") {
            return add!Decimal(this, rhs, bigContext);
        }
        else static if (op == "-") {
            return subtract!Decimal(this, rhs, bigContext);
        }
        else static if (op == "*") {
            return multiply!Decimal(this, rhs, bigContext);
        }
        else static if (op == "/") {
            return divide!Decimal(this, rhs, bigContext);
        }
        else static if (op == "%") {
            return remainder!Decimal(this, rhs, bigContext);
        }
    }

    unittest {
        Decimal op1, op2, actual, expect;
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

//-----------------------------
// operator assignment
//-----------------------------

    ref Decimal opOpAssign(string op) (Decimal rhs) {
        this = opBinary!op(rhs);
        return this;
    }

    unittest {
        Decimal op1, op2, actual, expect;
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
    }

//-----------------------------
// nextUp, nextDown, nextAfter
//-----------------------------

    const Decimal nextUp() {
        return nextPlus!Decimal(this, bigContext);
    }

    unittest {
        write("nextUp...");
        writeln("test missing");
    }

    const Decimal nextDown() {
        return nextMinus!Decimal(this, bigContext);
    }

    unittest {
        write("nextMinus...");
        writeln("test missing");
    }

    const Decimal nextAfter(const Decimal num) {
        return nextToward!Decimal(this, num, bigContext);
    }

    unittest {
        write("nextAfter...");
        writeln("test missing");
    }

    /**
     * Returns (BigInt) ten raised to the specified power.
     */
    public static BigInt pow10(const int n) {
        BigInt num = 1;
        return decShl(num, n);
    }


    unittest {
        assert(pow10(3) == 1000);
    }

}    // end struct Decimal

unittest {
    writeln("-------------------");
    writeln("decimal....finsihed");
    writeln("-------------------");
}

