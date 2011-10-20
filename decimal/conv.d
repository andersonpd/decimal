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

import decimal.dec32;
import decimal.dec64;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.string;

unittest {
    writeln("-------------------");
    writeln("conv........testing");
    writeln("-------------------");
}
//--------------------------------
//  conversions
//--------------------------------

/**
 * Temporary hack to allow to!string(BigInt).
 * NOTE: the 'int' version is needed because there are
 * routines that call 'int' or 'BigInt' based on the coefficient type.
 */
T to(T:string)(const long n) {
    return format("%d", n);
}

/**
 * Temporary hack to allow to!string(BigInt).
 */
T to(T:string)(const BigInt num) {
    string outbuff="";
    void sink(const(char)[] s) { outbuff ~= s; }
    num.toString(&sink, "%d");
/*    string str = outbuff;
    string t = munch(str, "0");
    if (str.length == 0) str = "0";
    if (str != outbuff) {
writeln("outbuff = ", outbuff);
writeln("str = ", str);
        writeln(outbuff);
        writeln(str);
    }*/
    return outbuff;
}

// TODO: need to replace this with one toDecimal template
/**
 * Converts any decimal to a small decimal
 */
public T toSmallDecimal(T,U)(const U num) if (isDecimal!T) {

    static if(is(typeof(num) == T)) {return num.dup;}
//    static if(is(typeof(num) == BigDecimal)) {return T(num);}

    bool sign = num.sign;
    if (num.isFinite) {
        auto mant = num.coefficient;
        int  expo = num.exponent;
        return T(sign, mant, expo);
    }
    else if (num.isInfinite) {
        return T.infinity(sign);
    }
    else if (num.isSignaling) {
        return T.snan(num.payload);
    }
    else if (num.isQuiet) {
        return T.nan(num.payload);
    }
    return T.nan;
}

/**
 * Converts any decimal to a big decimal
 */
public BigDecimal toDecimal(T)(const T num) if (isDecimal!T) {

    static if(is(typeof(num) == BigDecimal)) {return num.dup;}

    bool sign = num.sign;
    if (num.isFinite) {
        auto mant = num.coefficient;
        int  expo = num.exponent;
        return BigDecimal(sign, mant, expo);
    }
    else if (num.isInfinite) {
        return BigDecimal.infinity(sign);
    }
    else if (num.isSignaling) {
        return BigDecimal.snan(num.payload);
    }
    else if (num.isQuiet) {
        return BigDecimal.nan(num.payload);
    }
    return BigDecimal.nan;
}

unittest {
    Dec32 small;
    BigDecimal big;
    small = 5;
    big = toDecimal!Dec32(small);
    assert(big.toString == small.toString);
}

/**
 * Detect whether T is a decimal type.
 */
public template isDecimal(T) {
    enum bool isDecimal = is(T:Dec32) || is(T:Dec64) || is(T:BigDecimal);
}

/**
 * Detect whether T is a big decimal type.
 */
public template isBigDecimal(T) {
    enum bool isBigDecimal = is(T:BigDecimal);
}

/**
 * Detect whether T is a small decimal type.
 */
public template isSmallDecimal(T) {
    enum bool isSmallDecimal = is(T:Dec32) || is(T: Dec64);
}

unittest {
    assert(isSmallDecimal!Dec32);
    assert(!isSmallDecimal!BigDecimal);
    assert(isDecimal!Dec32);
    assert(isDecimal!BigDecimal);
    assert(!isBigDecimal!Dec32);
    assert(isBigDecimal!BigDecimal);
}

/**
 * Converts a BigDecimal number to a scientific string representation.
 */
public string toSciString(T)(const T num) if (isDecimal!T) {
    return toStdString!T(num, false);
};    // end toSciString()

/**
 * Converts a BigDecimal number to an engineering string representation.
 */
public string toEngString(T)(const T num) if (isDecimal!T) {
    return toStdString!T(num, true);
};    // end toEngString()

/**
 * Converts a BigDecimal number to one of two standard string representations.
 */
private string toStdString(T)
        (const T num, bool engineering = false) if (isDecimal!T) {

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
        if (num.isNaN && num.payload != 0) {
            str ~= to!string(num.payload);
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
                cstr = rightJustify(cstr, point, '0');
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

    if (engineering) {
        // use exponential notation
        if (num.isZero) {
            adjx += 2;
        }

        int mod = adjx % 3;
        // the % operator rounds down; we need it to round to floor.
        if (mod < 0) {
            mod = -(mod + 3);
        }

        int dot = std.math.abs(mod) + 1;
        adjx = adjx - dot + 1;

        if (num.isZero) {
            dot = 1;
            clen = 3 - std.math.abs(mod);
            cstr.length = 0;
            for (int i = 0; i < clen; i++) {
                cstr ~= '0';
            }
        }

        while (dot > clen) {
            cstr ~= '0';
            clen++;
        }
        if (clen > dot) {
            insertInPlace(cstr, dot, ".");
        }
        string str = cstr.idup;
        if (adjx != 0) {
            string xstr = to!string(adjx);
            if (adjx > 0) {
                xstr = '+' ~ xstr;
            }
            str = str ~ "E" ~ xstr;
        }
        return signed ? "-" ~ str : str;
    }
    else {
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
    }

};    // end toEngString()

unittest {
    Dec32 num = Dec32(123); //(false, 123, 0);
    assert(toSciString!Dec32(num) == "123");
    assert(num.toAbstract() == "[0,123,0]");
//    writeln("num = ", num);
//    writeln("num.toAbstract = ", num.toAbstract);
    num = Dec32(-123, 0);
//    writeln("num = ", num);
//    writeln("num.toAbstract = ", num.toAbstract);
    assert(toSciString!Dec32(num) == "-123");
    assert(num.toAbstract() == "[1,123,0]");
    num = Dec32(123, 1);
    assert(toSciString!Dec32(num) == "1.23E+3");
    assert(num.toAbstract() == "[0,123,1]");
    num = Dec32(123, 3);
    assert(toSciString!Dec32(num) == "1.23E+5");
    assert(num.toAbstract() == "[0,123,3]");
    num = Dec32(123, -1);
    assert(toSciString!Dec32(num) == "12.3");
    assert(num.toAbstract() == "[0,123,-1]");
    num = Dec32("inf");
//    writeln("num = ", num);
//    writeln("num.toAbstract = ", num.toAbstract);
    assert(toSciString!Dec32(num) == "Infinity");
    assert(num.toAbstract() == "[0,inf]");
    string str = "1.23E+3";
    BigDecimal dec = BigDecimal(str);
    assert(toEngString!BigDecimal(dec) == str);
    str = "123E+3";
    dec = BigDecimal(str);
    assert(toEngString!BigDecimal(dec) == str);
    str = "12.3E-9";
    dec = BigDecimal(str);
    assert(toEngString!BigDecimal(dec) == str);
    str = "-123E-12";
    dec = BigDecimal(str);
    assert(toEngString!BigDecimal(dec) == str);
}

// NOTE: Doesn't work yet, returns scientific string.
/**
 * Converts a BigDecimal number to a string representation.
 */
public string writeTo(T)
	(const T num, string fmt = "") if (isDecimal!T) {

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
        if (num.isNaN && num.payload != 0) {
            str ~= to!string(num.payload);
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
                cstr = rightJustify(cstr, point, '0');
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

    if (engineering) {
        // use exponential notation
        if (num.isZero) {
            adjx += 2;
        }

        int mod = adjx % 3;
        // the % operator rounds down; we need it to round to floor.
        if (mod < 0) {
            mod = -(mod + 3);
        }

        int dot = std.math.abs(mod) + 1;
        adjx = adjx - dot + 1;

        if (num.isZero) {
            dot = 1;
            clen = 3 - std.math.abs(mod);
            cstr.length = 0;
            for (int i = 0; i < clen; i++) {
                cstr ~= '0';
            }
        }

        while (dot > clen) {
            cstr ~= '0';
            clen++;
        }
        if (clen > dot) {
            insertInPlace(cstr, dot, ".");
        }
        string str = cstr.idup;
        if (adjx != 0) {
            string xstr = to!string(adjx);
            if (adjx > 0) {
                xstr = '+' ~ xstr;
            }
            str = str ~ "E" ~ xstr;
        }
        return signed ? "-" ~ str : str;
    }
    else {
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
    }

};    // end toEngString()

/**
 * Converts a string into a BigDecimal.
 */
public BigDecimal toNumber(const string inStr) {

    BigDecimal num;
    BigDecimal NAN = BigDecimal.nan;
    bool sign = false;

    // strip, copy, tolower
    char[] str = strip(inStr).dup;
    toLowerInPlace(str);

    // get sign, if any
    if (startsWith(str,"-")) {
        sign = true;
        str = str[1..$];
    }
    else if (startsWith(str,"+")) {
        str = str[1..$];
    }

    // check for NaN
    if (startsWith(str,"nan")) {
        num = NAN;
        num.sign = sign;
        // if no payload, return
        if (str == "nan") {
            return num;
        }
        // set payload
        str = str[3..$];
        // payload has a max length of 6 digits
        if (str.length > 6) return NAN;
        // ensure string is all digits
        foreach(char c; str) {
            if (!isDigit(c)) {
                return NAN;
            }
        }
        // convert string to number
        uint payload = std.conv.to!uint(str);
        // check for overflow
        if (payload > ushort.max) {
            return NAN;
        }
        num.payload = payload;
        return num;
    };

    // check for sNaN
    if (startsWith(str,"snan")) {
        num = BigDecimal.snan;
        num.sign = sign;
        if (str == "snan") {
            num.payload = 0;
            return num;
        }
        // set payload
        str = str[4..$];
        // payload has a max length of 6 digits
        if (str.length > 6) return NAN;
        // ensure string is all digits
        foreach(char c; str) {
            if (!isDigit(c)) {
                return NAN;
            }
        }
        // convert string to payload
        uint payload = std.conv.to!uint(str);
        // check for overflow
        if (payload > ushort.max) {
            return NAN;
        }
        num.payload = payload;
        return num;
    };

    // check for infinity
    if (str == "inf" || str == "infinity") {
        num = BigDecimal.infinity(sign);
        return num;
    };

    // at this point, num must be finite
    num = BigDecimal.zero(sign);
    // check for exponent
    int pos = indexOf(str, 'e');
    if (pos > 0) {
        // if it's just a trailing 'e', return NaN
        if (pos == str.length - 1) {
            return NAN;
        }
        // split the string into coefficient and exponent
        char[] xstr = str[pos+1..$];
        str = str[0..pos];
        // assume exponent is positive
        bool xneg = false;
        // check for minus sign
        if (startsWith(xstr, "-")) {
            xneg = true;
            xstr = xstr[1..$];
        }
        // check for plus sign
        else if (startsWith(xstr, "+")) {
            xstr = xstr[1..$];
        }

        // ensure it's not now empty
        if (xstr.length < 1) {
            return NAN;
        }

        // ensure exponent is all digits
        foreach(char c; xstr) {
            if (!isDigit(c)) {
                return NAN;
            }
        }

        // trim leading zeros
        while (xstr[0] == '0' && xstr.length > 1) {
            xstr = xstr[1..$];
        }

        // make sure it will fit into an int
        if (xstr.length > 10) {
            return NAN;
        }
        if (xstr.length == 10) {
            // try to convert it to a long (should work) and
            // then see if the long value is too big (or small)
            long lex = std.conv.to!long(xstr);
            if ((xneg && (-lex < int.min)) || lex > int.max) {
                return NAN;
            }
            num.exponent = cast(int) lex;
        }
        else {
            // everything should be copacetic at this point
            num.exponent = std.conv.to!int(xstr);
        }
        if (xneg) {
            num.exponent = -num.exponent;
        }
    }
    else {
        num.exponent = 0;
    }
    // remove trailing decimal point
    if (endsWith(str, ".")) {
        str = str[0..$-1];
    }
    // strip leading zeros
    while (str[0] == '0' && str.length > 1) {
        str = str[1..$];
    }

    // remove internal decimal point
    int point = indexOf(str, '.');
    if (point >= 0) {
        // excise the point and adjust the exponent
        str = str[0..point] ~ str[point+1..$];
        int diff = str.length - point;
        num.exponent = num.exponent - diff;
    }

    // ensure string is not empty
    if (str.length < 1) {
        return NAN;
    }

    // ensure string is all digits
    foreach(char c; str) {
        if (!isDigit(c)) {
            return NAN;
        }
    }
    // convert coefficient string to BigInt
    num.coefficient = BigInt(str.idup);
    num.digits = decimal.rounding.numDigits(num.coefficient);

    return num;
}

unittest {
    BigDecimal f = BigDecimal("1.0");
    assert(f.toString() == "1.0");
    f = BigDecimal(".1");
    assert(f.toString() == "0.1");
    f = BigDecimal("-123");
    assert(f.toString() == "-123");
    f = BigDecimal("1.23E3");
    assert(f.toString() == "1.23E+3");
    f = BigDecimal("1.23E-3");
    assert(f.toString() == "0.00123");
}

/**
 * Returns an abstract string representation of a number.
 */
public string toAbstract(T)(const T num) if (isDecimal!T)
{
    if (num.isFinite) {
        return format("[%d,%s,%d]", num.sign ? 1 : 0,
                to!string(num.coefficient), num.exponent);
    }
    if (num.isInfinite) {
        return format("[%d,%s]", num.sign ? 1 : 0, "inf");
    }
    if (num.isQuiet) {
        if (num.payload) {
            return format("[%d,%s%d]", num.sign ? 1 : 0, "qNaN", num.payload);
        }
        return format("[%d,%s]", num.sign ? 1 : 0, "qNaN");
    }
    if (num.isSignaling) {
        if (num.payload) {
            return format("[%d,%s%d]", num.sign ? 1 : 0, "sNaN", num.payload);
        }
        return format("[%d,%s]", num.sign ? 1 : 0, "sNaN");
    }
    return "[0,qNAN]";
}

/**
 * Returns a full, exact representation of a number. Similar to toAbstract,
 * but it provides a valid string that can be converted back into a number.
 */
public string toExact(T)(const T num) if (isDecimal!T)
    {
        if (num.isFinite) {
//            string str = to!string(num.coefficient);
//            writeln("str = ", str);
            return format("%s%sE%s%02d", num.sign ? "-" : "+",
                    to!string(num.coefficient),
                    num.exponent < 0 ? "-" : "+", num.exponent);
        }
        if (num.isInfinite) {
            return format("%s%s", num.sign ? "-" : "+", "Infinity");
        }
        if (num.isQuiet) {
            if (num.payload) {
                return format("%s%s%d", num.sign ? "-" : "+", "NaN", num.payload);
            }
            return format("%s%s", num.sign ? "-" : "+", "NaN");
        }
        if (num.isSignaling) {
            if (num.payload) {
                return format("%s%s%d", num.sign ? "-" : "+", "sNaN", num.payload);
            }
            return format("%s%s", num.sign ? "-" : "+", "sNaN");
        }
        return "+NaN";
    }

unittest {
    writeln("-------------------");
    writeln("conv.........tested");
    writeln("-------------------");
}


