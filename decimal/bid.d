﻿// Written in the D programming language

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

module decimal.bid;

import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.stdio;
import std.string;

struct Dec64 {

    private immutable uint w = 10;
    private immutable uint j = 5;
    private immutable uint p = (3*j) + 1;
    static assert(p == 16);
    private immutable uint bp = 3 * (1 << (w - 3)) + p - 2;
    static assert(bp == 398);
    private immutable uint xr = 3 * (1 << (w - 2)) - 1;
    static assert(xr == 767);

    immutable uint expoBits = 10;
    immutable uint bias = 398;
    immutable int  max_expo = 767 - bias;
    static assert (max_expo == 369);
    immutable int  min_expo = -bias;

    immutable uint mantBits = 10*j + 3;
    immutable uint signBits = 1;
    immutable uint testBits = 2;
    immutable uint normBits = mantBits - testBits;
    immutable uint unsignedBits = 63;

    immutable ulong snan_val = 0x7E00000000000000;
    immutable ulong max_snan = 0x7FFFFFFFFFFFFFFF;
    immutable ulong qnan_val = 0x7C00000000000000;
    immutable ulong max_qnan = 0x7DFFFFFFFFFFFFFF;
    immutable ulong inf_val  = 0x7800000000000000;
    immutable ulong max_inf  = 0x7BFFFFFFFFFFFFFF;

    immutable ulong max_norm = (1L << normBits) - 1;
    immutable ulong max_mant = (1L << mantBits) - 1;

    private union {
        ulong value = qnan_val;

        mixin (bitfields!(
            ulong, "unsigned", 63,
            bool,  "signbit", signBits)
        );
        mixin (bitfields!(
            ulong, "mant1", mantBits,
            uint,  "expo1", expoBits,
            bool,  "sign1", signBits)
        );
        mixin (bitfields!(
            ulong, "mant2", normBits,
            uint,  "expo2", expoBits,
            uint,  "test" , testBits,
            bool,  "sign2", signBits)
        );
    }
    public:

    @property bool sign() {
        return signbit;
    }

    @property bool sign(bool value) {
        signbit = value;
        return signbit;
    }

    @property
    const int exponent() {
        if (this.isExplicit) {
            return expo1;
        }
        else {
            return expo2;
        }
    }

    // TODO: Need to add range checks >= minExpo and <= maxExpo
    // TODO: Need to define exceptions. Out of range exponents: infinity or zero.
    @property
     int exponent(int expo) {
        if (this.isExplicit) {
            expo1 = expo;
        }
        else {
            expo2 = expo;
        }
        return expo;
    }

    @property
    const ulong coefficient() {
        if (this.isExplicit) {
            return mant1;
        }
        else if (isSpecial) {
            return mant2;
        }
        else {
            return mant2 | 0x7FFFFFFFFFFFFFFF;
        }
    }

    @property
    ulong coefficient(ulong mant) {
        if (this.isExplicit) {
            mant = value;
        }
        else {
            mant = value | 0x7FFFFFFFFFFFFFFF;
        }
        return mant;
    }

    @property
    int digits() {
        return 7;
    }

//--------------------------------
//  classification properties
//--------------------------------

    const bool isExplicit() {
        return test != 0b11;
    }

    /**
     * Returns true if this number's representation is canonical.
     */
    const bool isCanonical() {
        return isInfinite  && unsigned == inf_val  ||
               isQuiet     && unsigned == qnan_val ||
               isSignaling && unsigned == snan_val;
    }

    /**
     * Returns true if this number is +\- zero.
     */
    const bool isZero() {
        return unsigned == 0;
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
        return unsigned == snan_val ||
            unsigned > snan_val && unsigned <= max_snan;
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return unsigned == qnan_val || unsigned > qnan_val && unsigned <= max_qnan;
    }

    /**
     * Returns true if this number is +\- infinity.
     */
    const bool isInfinite() {
        return unsigned == inf_val || unsigned > inf_val && unsigned <= max_inf;
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
        return signbit;
    }

    const bool isNegative() {
        return signbit;
    }

    /**
     * Returns true if this number is subnormal.
     */
/*    const bool isSubnormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent < context.eMin;
    }*/

    /**
     * Returns true if this number is normal.
     */
/*    const bool isNormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent >= context.eMin;
    }*/

}

struct Dec32 {

    immutable uint bias = 101;
    immutable uint mantBits = 23;;
    immutable uint expoBits = 8;
    immutable uint signBits = 1;
    immutable uint testBits = 2;
    immutable uint normBits = mantBits - testBits;
    immutable uint unsignedBits = 31;

    immutable uint snan_val = 0x7E000000;
    immutable uint max_snan = 0x7FFFFFFF;
    immutable uint qnan_val = 0x7C000000;
    immutable uint max_qnan = 0x7DFFFFFF;
    immutable uint inf_val  = 0x78000000;
    immutable uint max_inf = 0x7BFFFFFF;

    immutable uint max_norm = (1 << normBits) - 1;
    immutable uint max_mant = (1 << mantBits) - 1;
    immutable int max_expo =   90;
    immutable int min_expo = -101;

    private union {
        uint value = qnan_val;

        mixin (bitfields!(
            uint, "unsigned", 31,
            bool, "signbit", signBits)
        );
        mixin (bitfields!(
            uint, "mant1", mantBits,
            uint, "expo1", expoBits,
            bool, "sign1", signBits)
        );
        mixin (bitfields!(
            uint, "mant2", normBits,
            uint, "expo2", expoBits,
            uint, "test" , testBits,
            bool, "sign2", signBits)
        );
    }

    public:

    @property bool sign() {
        return signbit;
    }

    @property bool sign(bool value) {
        signbit = value;
        return signbit;
    }

    @property
    const int exponent() {
        if (this.isExplicit) {
            return expo1;
        }
        else {
            return expo2;
        }
    }

    // TODO: Need to add range checks >= minExpo and <= maxExpo
    // TODO: Need to define exceptions. Out of range exponents: infinity or zero.
    @property
     int exponent(int expo) {
        if (this.isExplicit) {
            expo1 = expo;
        }
        else {
            expo2 = expo;
        }
        return expo;
    }

    @property
    const uint coefficient() {
        if (this.isExplicit) {
            return mant1;
        }
        else if (isSpecial) {
            return mant2;
        }
        else {
            return mant2 | 0x7FFFFFFF;
        }
    }

    @property
    uint coefficient(uint mant) {
        if (this.isExplicit) {
            mant = value;
        }
        else {
            mant = value | 0x7FFFFFFF;
        }
        return mant;
    }

    @property
    int digits() {
        return 7;
    }

    immutable Dec32 qNaN = Dec32(qnan_val);
    immutable Dec32 sNaN = Dec32(snan_val);
    immutable Dec32 Infinity = Dec32(inf_val);
    immutable Dec32 Zero = Dec32(0);

//--------------------------------
//  floating point properties
//--------------------------------

    static Dec32 init() {
        return qNaN;
    }

    static Dec32 nan() {
        return qNaN;
    }

    static int dig() {
        return 7;
    }

//--------------------------------
//  classification properties
//--------------------------------

    const bool isExplicit() {
        return test != 0b11;
    }

    /**
     * Returns true if this number's representation is canonical.
     */
    const bool isCanonical() {
        return isInfinite  && unsigned == inf_val  ||
               isQuiet     && unsigned == qnan_val ||
               isSignaling && unsigned == snan_val;
    }

    /**
     * Returns true if this number is +\- zero.
     */
    const bool isZero() {
        return unsigned == 0;
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
        return unsigned == snan_val ||
            unsigned > snan_val && unsigned <= max_snan;
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return unsigned == qnan_val || unsigned > qnan_val && unsigned <= max_qnan;
    }

    /**
     * Returns true if this number is +\- infinity.
     */
    const bool isInfinite() {
        return unsigned == inf_val || unsigned > inf_val && unsigned <= max_inf;
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
        return signbit;
    }

    const bool isNegative() {
        return signbit;
    }

    /**
     * Returns true if this number is subnormal.
     */
/*    const bool isSubnormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent < context.eMin;
    }*/

    /**
     * Returns true if this number is normal.
     */
/*    const bool isNormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent >= context.eMin;
    }*/

//--------------------------------
//  constructors
//--------------------------------

    /**
     * Creates a Dec32 from an unsigned integer.
     */
    public this(const uint u) {
        value = u;
    }

    /**
     * Creates a Dec32 from a long integer.
     */
    public this(const long n) {
        signbit = n < 0;
        expo1 = 0;
        mant1 = cast(uint) std.math.abs(n);
    }

    /**
     * Creates a Dec32 from a Decimal
     */
    public this(Decimal num) {
        // check for special values
        if (num.isInfinite) {
            value = inf_val;
            signbit = num.sign;
            return;
        }
        if (num.isQuiet) {
            value = qnan_val;
            signbit = num.sign;
            return;
        }
        if (num.isSignaling) {
            value = snan_val;
            signbit = num.sign;
            return;
        }
        if (num.isZero) {
            value = 0;
            signbit = num.sign;
            return;
        }

        // number is finite
        writefln("num.mant = %d", num.mant);
        writeln("num.expo = ", num.expo);
        if (num.mant > max_mant || num.expo > max_expo || num.expo < min_expo) {
            throw new Exception("Can't fit in this struct!");
        }

        uint mant = cast(uint)num.mant.toInt;
        if (mant > max_norm) {
            // set the test bits
            test = 0b11;
            signbit = num.sign;
            expo2 = num.expo;
            // TODO: this can be done with a mask.
            mant2 = mant % max_norm;
        }
        else {
            signbit = num.sign;
            expo1 = num.expo;
            mant1 = mant;
        }
    }

	unittest {
		writeln("this(Decimal)...");
		writeln("test missing");
		writeln("failed");
	}

//--------------------------------
//  conversions
//--------------------------------

    /**
     * Converts a Dec32 to a Decimal
     */
    public Decimal toDecimal() {
        uint mant;
        int  expo;
        bool sign;

        if (isExplicit) {
            mant = mant1;
            sign = signbit;
            expo = expo1 - bias;
        }
        else {
            // check for special values
            if (signbit) {
                sign = true;
                mant = value & 0x7FFFFFFF;
            }
            else {
                sign = false;
                mant = value;
            }
            if (mant == inf_val || value > inf_val && value <= max_inf) {
                return Decimal(sign, "Inf", 0);
            }
            if (mant == qnan_val || value > qnan_val && value <= max_qnan) {
                return Decimal(sign, "qNaN", 0);
            }
            if (mant == snan_val || value > snan_val && value <= max_snan) {
                return Decimal(sign, "sNan", 0);
            }
            // number is finite, set msbs
            mant = mant2 | (0b100 << normBits);
            expo = expo2 - bias;
            sign = signbit;
        }
        return Decimal(sign, BigInt(mant), expo);
    }

	unittest {
		writeln("toDecimal...");
		writeln("test missing");
		writeln("failed");
	}

    /**
     * Converts a Dec32 to a hexadecimal string
     */
    const public string toHexString() {
         return format("0x%08X", value);
    }

	unittest {
		writeln("toHexString...");
		writeln("test missing");
		writeln("failed");
	}

    /**
     * Converts a Dec32 to a string
     */
    const public string toString() {
         return toSciString!Dec32(this);
    }

	unittest {
		writeln("toString...");
		writeln("test missing");
		writeln("failed");
	}

}

/**
 * Detect whether T is a built-in integral type. Types $(D bool), $(D
 * char), $(D wchar), and $(D dchar) are not considered integral.
 */

template isDecimal(T) {
    enum bool isDecimal = is(T: Dec32);
}

unittest {
	writeln("isDecimal(T)...");
	writeln("test missing");
	writeln("failed");
}

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
public string toSciString(T)(const T num) if (isDecimal!T) {

    auto mant = num.coefficient;
    int  expo = num.exponent;
    bool signed = num.isSigned;

    // string representation of special values
    if (num.isSpecial) {
        string str;
        if (num.isInfinite) {
            str = "Infinity";
        }
        else if (num.isSignaling) {
            str = "sNaN";
        }
        else {
            str = "NaN";
        }
        // add payload to NaN, if present
        if (num.isNaN && mant != 0) {
            str ~= to!string(mant);
        }
        // add sign, if present
        return signed ? "-" ~ str : str;
    }

    // string representation of finite numbers
    string temp = to!string(mant);
    char[] cstr = temp.dup;
    int clen = cstr.length;
    int adjx = expo + clen - 1;

    // if exponent is small, don't use exponential notation
    if (expo <= 0 && adjx >= -6) {
        // if exponent is not zero, insert a decimal point
        if (expo != 0) {
            int point = std.math.abs(expo);
            // if coefficient is too small, pad with zeroes
            if (point > clen) {
                cstr = zfill(cstr, point);
                clen = cstr.length;
            }
            // if no chars precede the decimal point, prefix a zero
            if (point == clen) {
                cstr = "0." ~ cstr;
            }
            // otherwise insert a decimal point
            else {
                insertInPlace(cstr, cstr.length - point, ".");
            }
        }
        return signed ? ("-" ~ cstr).idup : cstr.idup;
    }
    // use exponential notation
    if (clen > 1) {
        insertInPlace(cstr, 1, ".");
    }
    string xstr = to!string(adjx);
    if (adjx >= 0) {
        xstr = "+" ~ xstr;
    }
    string str = (cstr ~ "E" ~ xstr).idup;
    return signed ? "-" ~ str : str;

};    // end toSciString()

unittest {
	write("toSciString...");
	writeln("Unit tests missing");
	writeln("failed");
}

unittest {
//    writefln("num.mant = 0x%08X", num.mant);
    writefln("max_mant = 0x%08X", Dec32.max_mant);
    writefln("max_norm = 0x%08X", Dec32.max_norm);
    writeln("max_expo = ", Dec32.max_expo);
    writeln("min_expo = ", Dec32.min_expo);

    writefln("qnan_val = 0x%08X", Dec32.qnan_val);
    writeln("Dec32.qNaN = ", Dec32.qNaN);

    Dec32 dec = Dec32();
    writeln("dec = ", dec);
    writeln("dec.mant1 = ", dec.mant1);

    Decimal num = Decimal(0);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = Decimal(1);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = Decimal(-1);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = Decimal(-16000);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = Decimal(uint.max);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);
}

