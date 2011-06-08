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

module decimal.conv;

import decimal.bid;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.stdio;
import std.string;

//--------------------------------
//  conversions
//--------------------------------

/**
 * Converts an encoded decimal to a Decimal
 */
public Decimal toDecimal(T)(const T num) if (isSmallDecimal!T) {
    auto mant = num.coefficient;
    int  expo = num.exponent;
    bool sign = num.sign;

    if (num.isExplicit) {
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
    write("toDecimal...");
    writeln("test missing");
}

/**
 * Converts an encoded decimal number to a hexadecimal string
 */
public string toHexString(T)(const T num) if (isSmallDecimal!T) {
    // TODO: what's the syntax for a variable format string?
    return format("0x%016X", value);
}

unittest {
    write("toHexString...");
    writeln("test missing");
}

/**
 * Detect whether T is a decimal type.
 */
template isDecimal(T) {
    enum bool isDecimal = is(T: Dec32) || is(T: Dec64);
}

unittest {
    write("isDecimal(T)...");
    writeln("test missing");
}

/**
 * Detect whether T is a decimal type.
 */
template isBigDecimal(T) {
    enum bool isBigDecimal = is(T: Decimal);
}

unittest {
    write("isBigDecimal(T)...");
    writeln("test missing");
}

/**
 * Detect whether T is a decimal type.
 */
template isSmallDecimal(T) {
    enum bool isSmallDecimal = is(T: Dec32) || is(T: Dec64);
}

unittest {
    write("isSmallDecimal(T)...");
    writeln("test missing");
}

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
    writeln("test missing");
}

unittest {
/*    writefln("num.mant = 0x%08X", num.mant);
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
    writeln("dec = ", dec);*/
}
