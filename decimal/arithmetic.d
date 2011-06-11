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

// TODO: ensure context flags are being set and cleared properly.

// TODO: opEquals unit test should include numerically equal testing.

// TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// TODO: to/from real or double (float) values needs definition and implementation.

// TODO: define values for payloads.

module decimal.arithmetic;

import decimal.context;
import decimal.digits;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.conv;
import std.ctype: isdigit;
import std.stdio: write, writeln;
import std.string;

unittest {
    writeln("---------------------");
    writeln("arithmetic....testing");
    writeln("---------------------");
}

// BigInt BIG_ONE = BigInt(1);
// TODO: BIG_ONE, BIG_ZERO

//--------------------------------
// conversion to/from strings
//--------------------------------

// UNREADY: toSciString. Description. Unit Tests.
/**
 * Converts a Dec32 to a string representation.
 */
public string toSciString(const Decimal num) {

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
        if (num.isNaN && num.coefficient != 0) {
            str ~= toDecString(num.coefficient);
//            str ~= to!string(num.coefficient);
        }
        // add sign, if present
        return num.isSigned ? "-" ~ str : str;
    }

    // string representation of finite numbers
    string temp = toDecString(num.coefficient);
//    string temp = to!string(coefficient);
    char[] cstr = temp.dup;
    int clen = cstr.length;
    int adjx = num.exponent + clen - 1;

    // if exponent is small, don't use exponential notation
    if (num.exponent <= 0 && adjx >= -6) {
        // if exponent is not zero, insert a decimal point
        if (num.exponent != 0) {
            int point = std.math.abs(num.exponent);
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
        return num.isSigned ? ("-" ~ cstr).idup : cstr.idup;
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
    return (num.isSigned) ? "-" ~ str : str;

};    // end toSciString()

unittest {
    writeln("-------------------");
    write("to-sci-str...");
    Decimal dec = Decimal(123); //(false, 123, 0);
    assert(dec.toString() == "123");
    assert(dec.toAbstract() == "[0,123,0]");
    dec = Decimal(-123, 0);
    assert(dec.toString() == "-123");
    assert(dec.toAbstract() == "[1,123,0]");
    dec = Decimal(123, 1);
    assert(dec.toString() == "1.23E+3");
    assert(dec.toAbstract() == "[0,123,1]");
    dec = Decimal(123, 3);
    assert(dec.toString() == "1.23E+5");
    assert(dec.toAbstract() == "[0,123,3]");
    dec = Decimal(123, -1);
    assert(dec.toString() == "12.3");
    assert(dec.toAbstract() == "[0,123,-1]");
    dec = Decimal(123, -5);
    assert(dec.toString() == "0.00123");
    assert(dec.toAbstract() == "[0,123,-5]");
    dec = Decimal(123, -10);
    assert(dec.toString() == "1.23E-8");
    assert(dec.toAbstract() == "[0,123,-10]");
    dec = Decimal(-123, -12);
    assert(dec.toString() == "-1.23E-10");
    assert(dec.toAbstract() == "[1,123,-12]");
    dec = Decimal(0, 0);
    assert(dec.toString() == "0");
    assert(dec.toAbstract() == "[0,0,0]");
    dec = Decimal(0, -2);
    assert(dec.toString() == "0.00");
    assert(dec.toAbstract() == "[0,0,-2]");
    dec = Decimal(0, 2);
    assert(dec.toString() == "0E+2");
    assert(dec.toAbstract() == "[0,0,2]");
    dec = -Decimal(0, 0);
    assert(dec.toString() == "-0");
    assert(dec.toAbstract() == "[1,0,0]");
    dec = Decimal(5, -6);
    assert(dec.toString() == "0.000005");
    assert(dec.toAbstract() == "[0,5,-6]");
    dec = Decimal(50,-7);
    assert(dec.toString() == "0.0000050");
    assert(dec.toAbstract() == "[0,50,-7]");
    dec = Decimal(5, -7);
    assert(dec.toString() == "5E-7");
    assert(dec.toAbstract() == "[0,5,-7]");
    dec = Decimal("inf");
    assert(dec.toString() == "Infinity");
    assert(dec.toAbstract() == "[0,inf]");
    dec = Decimal(true, "inf");
    assert(dec.toString() == "-Infinity");
    assert(dec.toAbstract() == "[1,inf]");
    dec = Decimal(false, "NaN");
    assert(dec.toString() == "NaN");
    assert(dec.toAbstract() == "[0,qNaN]");
    dec = Decimal(false, "NaN", 123);
    assert(dec.toString() == "NaN123");
    assert(dec.toAbstract() == "[0,qNaN,123]");
    dec = Decimal(true, "sNaN");
    assert(dec.toString() == "-sNaN");
    assert(dec.toAbstract() == "[1,sNaN]");
    writeln("passed");
}

// UNREADY: toEngString. Not implemented: returns toSciString
/**
 * Converts a Decimal to an engineering string representation.
 */
// UNREADY: toEngString. Description. Unit Tests.
/**
 * Converts a Dec32 to a string representation.
 */
public string toEngString(const Decimal num) {

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
        if (num.isNaN && num.coefficient != 0) {
            str ~= toDecString(num.coefficient);
//            str ~= to!string(num.coefficient);
        }
        // add sign, if present
        return num.isSigned ? "-" ~ str : str;
    }

    // string representation of finite numbers
    string temp = toDecString(num.coefficient);
//    string temp = to!string(coefficient);
    char[] cstr = temp.dup;
    int clen = cstr.length;
    int adjx = num.exponent + clen - 1;

    // if exponent is small, don't use exponential notation
    if (/*num.isZero ||*/ num.exponent <= 0 && adjx >= -6) {
        // if exponent is not zero, insert a decimal point
        if (num.exponent != 0) {
            int point = std.math.abs(num.exponent);
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
        if (!num.isZero) {
            return num.isSigned ? ("-" ~ cstr).idup : cstr.idup;
        }
    }

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
    }

    if (num.isZero) {
/*        writeln("mod = ", mod);
        writeln("dot = ", dot);
        writeln("cstr = ", cstr);
        writeln("clen = ", clen);*/
        clen = 3 - std.math.abs(mod);
        cstr.length = 0;
        for (int i = 0; i < clen; i++) {
            cstr ~= '0';
        }
/*        writeln("clen = ", clen);
        writeln("cstr = ", cstr);*/
    }

    while (dot > clen) {
        cstr ~= '0';
        clen++;
    }
    if (clen > dot) {
        insertInPlace(cstr, dot, ".");
    }

    string str = cstr.idup;
    if (adjx != 0) { // || num.isZero) {
        string xstr = to!string(adjx);
        if (adjx > 0) {
            xstr = '+' ~ xstr;
        }
        str = str ~ "E" ~ xstr;
    }
    return num.isSigned ? "-" ~ str : str;

};    // end toEngString()


unittest {
    write("to-eng-str...");
    string str = "1.23E+3";
    Decimal dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "123E+3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "12.3E-9";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "-123E-12";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "700E-9";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "70";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0E-6";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.00E-3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.0E-3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0E-3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.00";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.0";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.00E+3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.0E+3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0E+3";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.00E+6";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.0E+6";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0E+6";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    str = "0.00E+9";
    dec = Decimal(str);
    assert(toEngString(dec) == str);
    writeln("passed");
}

// UNREADY: toNumber. Description. Corner Cases.
/**
 * Converts a string into a Decimal.
 */
public Decimal toNumber(const string numeric_string) {
    Decimal num;
    num.clear;
    num.sign = false;

    // strip, copy, tolower
    char[] str = strip(numeric_string).dup;
    tolowerInPlace(str);

    // get sign, if any
    if (startsWith(str,"-")) {
        num.sign = true;
        str = str[1..$];
    }
    else if (startsWith(str,"+")) {
        str = str[1..$];
    }

    // check for NaN
    if (startsWith(str,"nan")) {
        num.sval = Decimal.SV.QNAN;
        if (str == "nan") {
            num.mant = BigInt(0);
//            writeln("return 1");
            return num;
        }
        // set payload
        str = str[3..$];
        // ensure string is all digits
        foreach(char c; str) {
            if (!isdigit(c)) {
//                writeln("return 2");
                return num;
            }
        }
        // convert string to payload
        num.mant = BigInt(str.idup);
//        writeln("return 3");
        return num;
    };

    // check for sNaN
    if (startsWith(str,"snan")) {
        num.sval = Decimal.SV.SNAN;
        if (str == "snan") {
            num.mant = BigInt(0);
//            writeln("return 4");
            return num;
        }
        // set payload
        str = str[4..$];
        // ensure string is all digits
        foreach(char c; str) {
            if (!isdigit(c)) {
//                writeln("return 5");
                return num;
            }
        }
        // convert string to payload
        num.mant = BigInt(str.idup);
//        writeln("return 6");
        return num;
    };

    // check for infinity
    if (str == "inf" || str == "infinity") {
        num.sval = Decimal.SV.INF;
//        writeln("return 7");
        return num;
    };

    // up to this point, num has been qNaN
    num.clear();
    // check for exponent
    int pos = indexOf(str, 'e');
    if (pos > 0) {
        // if it's just a trailing 'e', return NaN
        if (pos == str.length - 1) {
            num.sval = Decimal.SV.QNAN;
//            writeln("return 8");
            return num;
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
            num.sval = Decimal.SV.QNAN;
//            writeln("return 9");
            return num;
        }

        // ensure exponent is all digits
        foreach(char c; xstr) {
            if (!isdigit(c)) {
                num.sval = Decimal.SV.QNAN;
//                writeln("return 10");
        return num;
            }
        }

        // trim leading zeros
        while (xstr[0] == '0' && xstr.length > 1) {
            xstr = xstr[1..$];
        }

        // make sure it will fit into an int
        if (xstr.length > 10) {
            num.sval = Decimal.SV.QNAN;
//            writeln("return 11");
            return num;
        }
        if (xstr.length == 10) {
            // try to convert it to a long (should work) and
            // then see if the long value is too big (or small)
            long lex = to!long(xstr);
            if ((xneg && (-lex < int.min)) || lex > int.max) {
                num.sval = Decimal.SV.QNAN;
//                writeln("return 12");
        return num;
            }
            num.expo = cast(int) lex;
        }
        else {
            // everything should be copacetic at this point
            num.expo = to!int(xstr);
        }
        if (xneg) {
            num.expo = -num.expo;
        }
    }
    else {
        num.expo = 0;
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
        // excise the point and adjust exponent
        str = str[0..point] ~ str[point+1..$];
        int diff = str.length - point;
        num.expo -= diff;
    }

    // ensure string is not empty
    if (str.length < 1) {
        num.sval = Decimal.SV.QNAN;
//        writeln("return 13");
        return num;
    }

    // ensure string is all digits
    foreach(char c; str) {
        if (!isdigit(c)) {
            num.sval = Decimal.SV.QNAN;
//            writeln("return 14");
            return num;
        }
    }
    // convert string to BigInt
    num.mant = BigInt(str.idup);
    num.digits = numDigits(num.mant);
    if (num.mant == BigInt(0)) {
         num.sval = Decimal.SV.ZERO;
    }

//    writeln("return 15");
    return num;
}

unittest {
    write("to-number....");
    Decimal f;
    string str = "0";
    f = str;
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,0]");
    str = "0.00";
    f = str;
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,-2]");
    str = "0.0";
    f = str;
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,-1]");
    f = "0.";
    assert(f.toString() == "0");
    assert(f.toAbstract() == "[0,0,0]");
    f = ".0";
    assert(f.toString() == "0.0");
    assert(f.toAbstract() == "[0,0,-1]");
    str = "1.0";
    f = str;
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,10,-1]");
    str = "1.";
    f = str;
    assert(f.toString() == "1");
    assert(f.toAbstract() == "[0,1,0]");
    str = ".1";
    f = str;
    assert(f.toString() == "0.1");
    assert(f.toAbstract() == "[0,1,-1]");
    f = Decimal("123");
    assert(f.toString() == "123");
    f = Decimal("-123");
    assert(f.toString() == "-123");
    f = Decimal("1.23E3");
    assert(f.toString() == "1.23E+3");
    f = Decimal("1.23E");
    assert(f.toString() == "NaN");
    f = Decimal("1.23E-");
    assert(f.toString() == "NaN");
    f = Decimal("1.23E+");
    assert(f.toString() == "NaN");
    f = Decimal("1.23E+3");
    assert(f.toString() == "1.23E+3");
    f = Decimal("1.23E3B");
    assert(f.toString() == "NaN");
    f = Decimal("12.3E+007");
    assert(f.toString() == "1.23E+8");
    f = Decimal("12.3E+70000000000");
    assert(f.toString() == "NaN");
    f = Decimal("12.3E+7000000000");
    assert(f.toString() == "NaN");
    f = Decimal("12.3E+700000000");
    assert(f.toString() == "1.23E+700000001");
    f = Decimal("12.3E-700000000");
    assert(f.toString() == "1.23E-699999999");
    // NOTE: since there will still be adjustments -- maybe limit to 99999999?
    f = Decimal("12.0");
    assert(f.toString() == "12.0");
    f = Decimal("12.3");
    assert(f.toString() == "12.3");
    f = Decimal("1.23E-3");
    assert(f.toString() == "0.00123");
    f = Decimal("0.00123");
    assert(f.toString() == "0.00123");
    f = Decimal("-1.23E-12");
    assert(f.toString() == "-1.23E-12");
    f = Decimal("-0");
    assert(f.toString() == "-0");
    f = Decimal("inf");
    assert(f.toString() == "Infinity");
    f = Decimal("NaN");
    assert(f.toString() == "NaN");
    f = Decimal("-NaN");
    assert(f.toString() == "-NaN");
    f = Decimal("sNaN");
    assert(f.toString() == "sNaN");
    f = Decimal("Fred");
    assert(f.toString() == "NaN");
    writeln("passed");
}

//--------------------------------
// classification functions
//--------------------------------

// READY: radix
/**
 * Returns the radix of this representation (10).
 */
public int radix() {
    return 10;
}

unittest {
    write("radix........");
    assert(radix() == 10);
    writeln("passed");
}

// READY: classify
/**
 * Returns a string indicating the class and sign of the number.
 * Classes are: sNaN, NaN, Infinity, Subnormal, Zero, Normal.
 */
public string classify(const Decimal num) {
    if (num.isSignaling()) {
        return "sNaN";
    }
    if (num.isQuiet) {
        return "NaN";
    }
    if (num.isInfinite) {
        return num.sign ? "-Infinity" : "+Infinity";
    }
    if (num.isSubnormal) {
        return num.sign ? "-Subnormal" : "+Subnormal";
    }
    if (num.isZero) {
        return num.sign ? "-Zero" : "+Zero";
    }
    return num.sign ? "-Normal" : "+Normal";
}

unittest {
    write("class........");
    Decimal dcm;
    dcm = "Infinity";
    assert(classify(dcm) == "+Infinity");
    dcm = "1E-10";
    assert(classify(dcm) == "+Normal");
    dcm = "2.50";
    assert(classify(dcm) == "+Normal");
    dcm = "0.1E-99";
    assert(classify(dcm) == "+Subnormal");
    dcm = "0";
    assert(classify(dcm) == "+Zero");
    dcm = "-0";
    assert(classify(dcm) == "-Zero");
    dcm = "-0.1E-99";
    assert(classify(dcm) == "-Subnormal");
    dcm = "-1E-10";
    assert(classify(dcm) == "-Normal");
    dcm = "-2.50";
    assert(classify(dcm) == "-Normal");
    dcm = "-Infinity";
    assert(classify(dcm) == "-Infinity");
    dcm = "NaN";
    assert(classify(dcm) == "NaN");
    dcm = "-NaN";
    assert(classify(dcm) == "NaN");
    dcm = "sNaN";
    assert(classify(dcm) == "sNaN");
    writeln("passed");
}


//--------------------------------
// copy functions
//--------------------------------

// READY: copy
/**
 * Returns a copy of the operand.
 * The copy is unaffected by context; no flags are changed.
 */
public Decimal copy(const Decimal num) {
    return num.dup;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy.........");
    Decimal dcm;
    Decimal expd;
    dcm  = "2.1";
    expd = "2.1";
    assert(copy(dcm) == expd);
    dcm  = "-1.00";
    expd = "-1.00";
    assert(copy(dcm) == expd);
    writeln("passed");

    dcm  = "2.1";
    expd = "2.1";
    write("copy-abs.....");
    assert(copyAbs(dcm) == expd);
    dcm  = "-1.00";
    expd = "1.00";
    assert(copyAbs(dcm) == expd);
    writeln("passed");

    dcm  = "101.5";
    expd = "-101.5";
    write("copy-negate..");
    assert(copyNegate(dcm) == expd);
    Decimal dcm1;
    Decimal dcm2;
    dcm1 = "1.50";
    dcm2 = "7.33";
    expd = "1.50";
    writeln("passed");

    write("copy-sign....");
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "-1.50";
    dcm2 = "7.33";
    expd = "1.50";
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "1.50";
    dcm2 = "-7.33";
    expd = "-1.50";
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "-1.50";
    dcm2 = "-7.33";
    expd = "-1.50";
    assert(copySign(dcm1, dcm2) == expd);
    writeln("passed");
}

// READY: copyAbs
/**
 * Returns a copy of the operand with a positive sign.
 * The copy is unaffected by context; no flags are changed.
 */
public Decimal copyAbs(const Decimal num) {
    Decimal copy = num.dup;
    copy.sign = false;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy-abs.....");
    Decimal dcm;
    Decimal expd;
    dcm  = "2.1";
    expd = "2.1";
    assert(copyAbs(dcm) == expd);
    dcm  = "-1.00";
    expd = "1.00";
    assert(copyAbs(dcm) == expd);
    writeln("passed");
}

// READY: copyNegate
/**
 * Returns a copy of the operand with the sign inverted.
 * The copy is unaffected by context; no flags are changed.
 */
public Decimal copyNegate(const Decimal num) {
    Decimal copy = num.dup;
    copy.sign = !num.sign;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy-negate..");
    Decimal dcm, expd;
    dcm  = "101.5";
    expd = "-101.5";
    assert(copyNegate(dcm) == expd);
    Decimal dcm1;
    Decimal dcm2;
    dcm1 = "1.50";
    dcm2 = "7.33";
    expd = "1.50";
    writeln("passed");
}

// READY: copySign
/**
 * Returns a copy of the first operand with the sign of the second operand.
 * The copy is unaffected by context; no flags are changed.
 */
public Decimal copySign(const Decimal op1, const Decimal op2) {
    Decimal copy = op1.dup;
    copy.sign = op2.sign;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy-sign....");
    Decimal dcm1, dcm2, expd;
    dcm1 = "1.50";
    dcm2 = "7.33";
    expd = "1.50";
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "-1.50";
    dcm2 = "7.33";
    expd = "1.50";
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "1.50";
    dcm2 = "-7.33";
    expd = "-1.50";
    assert(copySign(dcm1, dcm2) == expd);
    dcm1 = "-1.50";
    dcm2 = "-7.33";
    expd = "-1.50";
    assert(copySign(dcm1, dcm2) == expd);
    writeln("passed");
}

// UNREADY: quantize. Description. Logic.
/**
 * Returns the number which is equal in value and sign
 * to the first operand and which has its exponent set
 * to be equal to the exponent of the second operand.
 */
public Decimal quantize(const Decimal op1, const Decimal op2) {
    Decimal result;
    if (isInvalidBinaryOp(op1, op2, result)) {
        return result;
    }
    if (op1.isInfinite != op2.isInfinite() ||
        op2.isInfinite != op1.isInfinite()) {
        return flagInvalid();
    }
    if (op1.isInfinite() && op2.isInfinite()) {
        return op1.dup;
    }
    result = op1;
    int diff = op1.expo - op2.expo;
    if (diff == 0) {
        return result;
    }
    // need to add a check where the result is zero and op1 is negative --
    // then the result is -zero.
    if (diff > 0) {
        decShl(result.mant, diff);
        result.digits += diff;
        result.expo = op2.expo;
        if (result.digits > context.precision) {
            result = Decimal.NaN;
        }
        return result;
    }
    else {
        pushPrecision;
        context.precision = (-diff > op1.digits) ? 0 : op1.digits + diff;
        round(result, context);
        result.expo = op2.expo;
        popPrecision;
        return result;
    }
}

unittest {
    write("quantize.....");
    Decimal op1;
    Decimal op2;
    Decimal result;
    Decimal expd;
    string str;
    op1 = "2.17";
    op2 = "0.001";
    expd = "2.170";
    result = quantize(op1, op2);
//    writeln("op1 = ", op1);
//    writeln("op2 = ", op2);
//    writeln("expd = ", expd);
//    writeln("qresult = ", result);
    assert(result == expd);
    op1 = "2.17";
    op2 = "0.01";
    expd = "2.17";
    result = quantize(op1, op2);
    assert(result == expd);
    op1 = "2.17";
    op2 = "0.1";
    expd = "2.2";
    result = quantize(op1, op2);
    assert(result == expd);
    op1 = "2.17";
    op2 = "1e+0";
    expd = "2";
    result = quantize(op1, op2);
    assert(result == expd);
    op1 = "2.17";
    op2 = "1e+1";
    expd = "0E+1";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "-Inf";
    op2 = "Infinity";
    expd = "-Infinity";
    result = quantize(op1, op2);
    assert(result == expd);
    op1 = "2";
    op2 = "Infinity";
    expd = "NaN";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "-0.1";
    op2 = "1";
    expd = "-0";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "-0";
    op2 = "1e+5";
    expd = "-0E+5";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "+35236450.6";
    op2 = "1e-2";
    expd = "NaN";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "-35236450.6";
    op2 = "1e-2";
    expd = "NaN";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e-1";
    expd = "217.0";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+0";
    expd = "217";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+1";
    expd = "2.2E+2";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+2";
    expd = "2E+2";
    result = quantize(op1, op2);
    assert(result.toString() == expd.toString());
    assert(result == expd);
    writeln("passed");
}

/**
 * Returns the integer which is the exponent of the magnitude
 * of the most significant digit of the operand.
 * (As though the operand were truncated to a single digit
 * while maintaining the value of that digit and without
 * limiting the resulting exponent).
 */
public Decimal logb(const Decimal num) {
    Decimal result;
    if (invalidOperand(num, result)) {
        return result;
    }
    if (num.isInfinite) {
        return Decimal.POS_INF.dup;
    }
    if (num.isZero) {
        context.setFlag(DIVISION_BY_ZERO);
        return Decimal.NEG_INF.dup;
    }
    int expo = num.digits + num.exponent - 1;
    return Decimal(expo);
}

unittest {
    write("logb.........");
    Decimal num;
    Decimal expd;
    num = Decimal("250");
    expd = Decimal("2");
    assert(logb(num) == expd);
    num = Decimal("2.50");
    expd = Decimal("0");
    assert(logb(num) == expd);
    num = Decimal("0.03");
    expd = Decimal("-2");
    assert(logb(num) == expd);
    num = Decimal("0");
    expd = Decimal("-Infinity");
    assert(logb(num) == expd);
    writeln("passed");
}

/**
 * If the first operand is infinite then that Infinity is returned,
 * otherwise the result is the first operand modified by
 * adding the value of the second operand to its exponent.
 * The result may Overflow or Underflow.
 */
public Decimal scaleb(const Decimal op1, const Decimal op2) {
    Decimal result;
    if (isInvalidBinaryOp(op1, op2, result)) {
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
//        result = Decimal.infinity;
//        return op1.isSigned ? -result : result;
    }
    int expo = op2.expo;
    if (expo != 0 /* && not within range */) {
        result = flagInvalid();
        return result;
    }
    result = op1;
    int scale = cast(int)op2.mant.toInt;
    if (op2.isSigned) {
        scale = -scale;
    }
    result.expo += scale;
    return result;
}

unittest {
    write("scaleb.......");
    Decimal op1, op2, expd;
    op1 = Decimal("7.50");
    op2 = Decimal("-2");
    expd = Decimal("0.0750");
    assert(scaleb(op1,op2) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("0");
    expd = Decimal("7.50");
    assert(scaleb(op1,op2) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("3");
    expd = Decimal("7.50E+3");
    assert(scaleb(op1,op2) == expd);
    op1 = Decimal("-Infinity");
    op2 = Decimal("4.5");
    expd = Decimal("-Infinity");
    assert(scaleb(op1,op2) == expd);
    writeln("passed");
}

//--------------------------------
// absolute value, unary plus and minus functions
//--------------------------------

// UNREADY: reduce. Description. Flags.
/**
 * Reduces operand to simplest form. Trailing zeros are removed.
 */
public Decimal reduce(const Decimal num) {
    Decimal result;
    if (invalidOperand(num, result)) {
        return result;
    }
    result = num;
    if (!result.isFinite()) {
        return result;
    }

    // TODO: is there a more efficient way to do this?
    // Is checking the coefficient for trailing zeros easier to compute?
    BigInt temp = result.mant % 10;
    while (result.mant != 0 && temp == 0) {
        result.expo++;
        result.mant = result.mant / 10;
        temp = result.mant % 10;
    }
    if (result.mant == 0) {
        result.sval = Decimal.SV.ZERO;
        result.expo = 0;
    }
    result.digits = numDigits(result.mant);
    return result;
}

unittest {
    write("reduce.......");
    Decimal num;
    Decimal red;
    string str;
    num = "2.1";
    str = "2.1";
    red = reduce(num);
    assert(red.toString() == str);
    num = "-2.0";
    str = "-2";
    red = reduce(num);
    assert(red.toString() == str);
    num = "1.200";
    str = "1.2";
    red = reduce(num);
    assert(red.toString() == str);
    num = "-120";
    str = "-1.2E+2";
    red = reduce(num);
    assert(red.toString() == str);
    num = "120.00";
    str = "1.2E+2";
    red = reduce(num);
    assert(red.toString() == str);
    writeln("passed");
}

// READY: abs
/**
 *    Absolute value -- returns a copy and clears the negative sign, if needed.
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to plus(num) for positive numbers
 *    and to minus(num) for negative numbers.
 *    To return the absolute value without rounding or setting flags
 *    use the "copyAbs" function.
 */
/// Returns a new Decimal equal to the absolute value of this Decimal.
public Decimal abs(const Decimal num) {
    Decimal result;
    if(invalidOperand(num, result)) {
        return result;
    }
    result = copyAbs(num);
    round(result, context);
    return result;
}

unittest {
    // TODO: add rounding tests
    writeln("-------------------");
    write("abs..........");
    Decimal num;
    Decimal expd;
    num = "sNaN";
    assert(abs(num).isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    num = "NaN";
    assert(abs(num).isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    num = "Inf";
    expd = "Inf";
    assert(abs(num) == expd);
    num = "-Inf";
    expd = "Inf";
    assert(abs(num) == expd);
    num = "0";
    expd = "0";
    assert(abs(num) == expd);
    num = "-0";
    expd = "0";
    assert(abs(num) == expd);
    num = "2.1";
    expd = "2.1";
    assert(abs(num) == expd);
    num = -100;
    expd = 100;
    assert(abs(num) == expd);
    num = 101.5;
    expd = 101.5;
    assert(abs(num) == expd);
    num = -101.5;
    assert(abs(num) == expd);
    writeln("passed");
}

// READY: plus
/**
 *    Unary plus -- returns a copy with same sign as the number.
 *    Does NOT return a positive copy of a negative number!
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to add('0', number).
 *    To copy without rounding or setting flags use the "copy" function.
 */
public Decimal plus(const Decimal num) {
    Decimal result;
    if(invalidOperand(num, result)) {
        return result;
    }
    result = num;
    round(result, context);
    return result;
}

unittest {
    write("plus.........");
    // NOTE: result should equal 0 + this or 0 - this
    Decimal zero = Decimal(0);
    Decimal num;
    Decimal expd;
    num = "1.3";
    expd = zero + num;
    assert(+num == expd);
    num = "-1.3";
    expd = zero + num;
    assert(+num == expd);
    // TODO: add tests that check flags.
    writeln("passed");
}

// READY: minus
/**
 *    Unary minus -- returns a copy with the opposite sign.
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to subtract('0', number).
 *    To copy without rounding or setting flags use the "copyNegate" function.
 */
public Decimal minus(const Decimal num) {
    Decimal result;
    if(invalidOperand(num, result)) {
        return result;
    }
    result = copyNegate(num);
    round(result, context);
    return result;
}

unittest {
    write("minus........");
    // NOTE: result should equal 0 + this or 0 - this
    Decimal zero = Decimal(0);
    Decimal num;
    Decimal expd;
    num = "1.3";
    expd = zero - num;
    assert(-num == expd);
    num = "-1.3";
    expd = zero - num;
    assert(-num == expd);
    // TODO: add tests that check flags.
    writeln("passed");
}

//-----------------------------------
// next-plus, next-minus, next-toward
//-----------------------------------

// UNREADY: nextPlus. Description. Unit Tests.
public Decimal nextPlus(const Decimal num) {
    Decimal result;
    if (invalidOperand(num, result)) {
        return result;
    }
    if (num.isInfinite) {
        if (num.sign) {
            return copyNegate(Decimal.max);
        }
        else {
            return num.dup;
        }
    }
    int adjx = num.expo + num.digits - context.precision;
    if (adjx < context.eTiny) {
            return Decimal(0L, context.eTiny);
    }
    Decimal addend = Decimal(1, adjx);
    result = add(num, addend, true); // really? does this guarantee no flags?
    if (result > Decimal.max) {
        result = Decimal.POS_INF;
    }
    return result;
}

unittest {
    write("next-plus....");
    pushPrecision;
    int savedMin = context.eMin;
    int savedMax = context.eMax;
    context.eMax = 999;
    context.eMin = -999;
    Decimal dcm;
    Decimal expd;
    dcm = 1;
    expd = "1.00000001";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    dcm = 10;
    expd = "10.0000001";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    dcm = 1E5;
    expd = "100000.001";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    dcm = 1E8;
    expd = "100000001";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    // num digits exceeds precision...
    dcm = "1234567891";
    expd = "1.23456790E9";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    // result < tiny
    dcm = "-1E-1007";
    expd = "-0E-1007";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    dcm = "-1.00000003";
    expd = "-1.00000002";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    dcm = "-Infinity";
    expd = "-9.99999999E+999";
//    writeln("expd = ", expd);
    assert(nextPlus(dcm) == expd);
    popPrecision;
    context.eMin = savedMin;
    context.eMax = savedMax;
    writeln("passed");
}

// UNREADY: nextMinus. Description. Unit Tests.
public Decimal nextMinus(const Decimal num) {
    Decimal result;
    if (invalidOperand(num, result)) {
        return result;
    }
    if (num.isInfinite) {
        if (!num.sign) {
            return Decimal.max;
        }
        else {
            return num.dup;
        }
    }
    // This is necessary to catch the special case where mant == 1
    Decimal red = reduce(num);
    int adjx = red.expo + red.digits - context.precision;
    if (num.mant == 1) adjx--;
    if (adjx < context.eTiny) {
        return Decimal(0L, context.eTiny);
    }
    Decimal addend = Decimal(1, adjx);
    result = num - addend; //subtract(num, addend, true); // really? does this guarantee no flags?
    if (result < copyNegate(Decimal.max)) {
        result = Decimal.NEG_INF;
    }
    return result;
}

unittest {
    write("next-minus...");
    int savedMin = context.eMin;
    int savedMax = context.eMax;
    context.eMin = -999;
    context.eMax = 999;
    Decimal dcm;
    Decimal expd;
    dcm = 1;
    expd = "0.999999999";
    assert(nextMinus(dcm) == expd);
    dcm = "1E-1007";
    expd = "0E-1007";
    assert(nextMinus(dcm) == expd);
    dcm = "-1.00000003";
    expd = "-1.00000004";
    assert(nextMinus(dcm) == expd);
    dcm = "Infinity";
    expd = "9.99999999E+999";
//    writeln("dcm = ", dcm);
//    writeln("expd = ", expd);
//    writeln("nextMinus(dcm) = ", nextMinus(dcm));
    assert(nextMinus(dcm) == expd);
    context.eMin = savedMin;
    context.eMax = savedMax;
    writeln("passed");
}

// UNREADY: nextToward. Description. Unit Tests.
public Decimal nextToward(const Decimal op1, const Decimal op2) {
    Decimal result;
    if (isInvalidBinaryOp(op1, op2, result)) {
        return result;
    }
    int comp = compare(op1, op2);
    if (comp < 0) return nextPlus(op1);
    if (comp > 0) return nextMinus(op1);
    result = copySign(op1, op2);
    round(result, context);
    return result;
}

unittest {
    write("next-toward..");
    Decimal dcm1, dcm2;
    Decimal expd;
    dcm1 = 1;
    dcm2 = 2;
    expd = "1.00000001";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = "-1E-1007";
    dcm2 = 1;
    expd = "-0E-1007";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = "-1.00000003";
    dcm2 = 0;
    expd = "-1.00000002";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = 1;
    dcm2 = 0;
    expd = "0.999999999";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = "1E-1007";
    dcm2 = -100;
    expd = "0E-1007";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = "-1.00000003";
    dcm2 = -10;
    expd = "-1.00000004";
    assert(nextToward(dcm1,dcm2) == expd);
    dcm1 = "0.00";
    dcm2 = "-0.0000";
    expd = "-0.00";
    assert(nextToward(dcm1,dcm2) == expd);
    writeln("passed");
}

//--------------------------------
// comparison functions
//--------------------------------

// READY: sameQuantum
/**
 * Returns true if the numbers have the same exponent.
 * No context flags are set.
 * If either operand is NaN or Infinity, returns true if and only if
 * both operands are NaN or Infinity, respectively.
 */
public bool sameQuantum(const Decimal op1, const Decimal op2) {
    if (op1.isNaN || op2.isNaN) {
        return op1.isNaN && op2.isNaN;
    }
    if (op1.isInfinite || op2.isInfinite) {
        return op1.isInfinite && op2.isInfinite;
    }
    return op1.expo == op2.expo;
}

unittest {
    write("same-quantum.");
    Decimal op1;
    Decimal op2;
    op1 = "2.17";
    op2 = "0.001";
    assert(!sameQuantum(op1, op2));
    op2 = "0.01";
    assert(sameQuantum(op1, op2));
    op2 = "0.1";
    assert(!sameQuantum(op1, op2));
    op2 = "1";
    assert(!sameQuantum(op1, op2));
    op1 = "Inf";
    op2 = "Inf";
    assert(sameQuantum(op1, op2));
    op1 = "NaN";
    op2 = "NaN";
    assert(sameQuantum(op1, op2));
    writeln("passed");
}

// UNREADY: compare
public int compare(const Decimal op1, const Decimal op2, bool rounded = true) {

    // any operation with a signaling NaN is invalid.
    // if both are signaling, return as if op1 > op2.
    if (op1.isSignaling || op2.isSignaling) {
        context.setFlag(INVALID_OPERATION);
        return op1.isSignaling ? 1 : -1;
    }

    // NaN returns > any number, including NaN
    // if both are NaN, return as if op1 > op2.
    if (op1.isNaN || op2.isNaN) {
        return op1.isNaN ? 1 : -1;
    }

    // if signs differ, just compare the signs
    if (op1.sign != op2.sign) {
        // check for zeros: +0 and -0 are equal
        if (op1.isZero && op2.isZero) {
            return 0;
        }
        return op1.sign ? -1 : 1;
    }

    // otherwise, compare the numbers numerically
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (!op1.sign) {
        if (diff > 0) return 1;
        if (diff < 0) return -1;
    }
    else {
        if (diff > 0) return -1;
        if (diff < 0) return 1;
    }

    // when all else fails, subtract
    Decimal result = subtract(op1, op2, rounded);

    // test the coefficient
    // result.isZero may not be true if the result isn't rounded
    if (result.mant == 0) return 0;
    return result.sign ? -1 : 1;
}

unittest {
    write("compare......");
    Decimal op1;
    Decimal op2;
    int result;
    op1 = "2.1";
    op2 = "3";
    result = compare(op1, op2);
    assert(result == -1);
    op1 = "2.1";
    op2 = "2.1";
    result = compare(op1, op2);
    assert(result == 0);
    op1 = "2.1";
    op2 = "2.10";
    result = compare(op1, op2);
    assert(result == 0);
    op1 = "3";
    op2 = "2.1";
    result = compare(op1, op2);
    assert(result == 1);
    op1 = "2.1";
    op2 = "-3";
    result = compare(op1, op2);
    assert(result == 1);
    op1 = "-3";
    op2 = "2.1";
    result = compare(op1, op2);
    assert(result == -1);
    op1 = -3;
    op2 = -4;
    result = compare(op1, op2);
    assert(result == 1);
    op1 = -300;
    op2 = -4;
    result = compare(op1, op2);
    assert(result == -1);
    op1 = 3;
    op2 = Decimal.max;
    result = compare(op1, op2);
    assert(result == -1);
    op1 = -3;
    op2 = copyNegate(Decimal.max);
    result = compare(op1, op2);
    assert(result == 1);

    writeln("passed");
}

// UNREADY: equals. Verify 'equals' is identical to 'compare == 0'.
/**
 * Returns true if this Decimal is equal to the specified Decimal.
 * A NaN is not equal to any number, not even to another NaN.
 * Infinities are equal if they have the same sign.
 * Zeros are equal regardless of sign.
 * Finite numbers are equal if they are numerically equal to the current precision.
 * A Decimal is not equal to itself (this != this) if it is a NaN.
 */
public bool equals(
    const Decimal op1, const Decimal op2, const bool rounded = true) {

    // any operation with a signaling NaN is invalid.
    // NaN is never equal to anything, not even another NaN
    if (op1.isSignaling || op2.isSignaling) {
        context.setFlag(INVALID_OPERATION);
        return false;
    }

    // if either is NaN...
    if (op1.isNaN || op2.isNaN) return false;

    // if either is infinite...
    if (op1.isInfinite || op2.isInfinite) {
        return (op1.sval == op2.sval && op1.sign == op2.sign);
    }

    // if either is zero...
    if (op1.isZero || op2.isZero) {
        return (op1.isZero && op2.isZero);
    }

    // if their signs differ
    if (op1.sign != op2.sign) {
        return false;
    }

    // compare the numbers numerically
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (diff != 0) {
        return false;
    }

    // if they have the same representation, they are equal
    if (op1.expo == op2.expo && op1.mant == op2.mant) {
        return true;
    }

    // otherwise they are equal if they represent the same value
    Decimal result = subtract(op1, op2, rounded);
    return result.mant == 0;
}

unittest {
    write("equals.......");
    Decimal op1;
    Decimal op2;
    op1 = "NaN";
    op2 = "NaN";
    assert(op1 != op2);
    op1 = "inf";
    op2 = "inf";
    assert(op1 == op2);
    op2 = "-inf";
    assert(op1 != op2);
    op1 = "-inf";
    assert(op1 == op2);
    op2 = "NaN";
    assert(op1 != op2);
    op1 = 0;
    assert(op1 != op2);
    op2 = 0;
    assert(op1 == op2);
    writeln("passed");
}

// UNREADY: compareSignal. Unit Tests.
/**
 * Compares the numeric values of two numbers. CompareSignal is identical to
 * compare except that quiet NaNs are treated as if they were signaling.
 */
public int compareSignal(const Decimal op1, const Decimal op2,
        bool rounded = true) {

    // any operation with NaN is invalid.
    // if both are NaN, return as if op1 > op2.
    if (op1.isNaN || op2.isNaN) {
        context.setFlag(INVALID_OPERATION);
        return op1.isNaN ? 1 : -1;
    }
    return (compare(op1, op2, rounded));
}

unittest {
    write("comp-signal..");
    writeln("test missing");
}

// UNREADY: compareTotal
/// Returns 0 if the numbers are equal and have the same representation
public int compareTotal(const Decimal op1, const Decimal op2) {
    if (op1.sign != op2.sign) {
        return op1.sign ? -1 : 1;
    }
    if (op1.isQuiet || op2.isQuiet) {
        if (op1.isQuiet && op2.isQuiet) {
            return 0;
        }
        return op1.isQuiet ? 1 : -1;
    }
    if (op1.isSignaling || op2.isSignaling) {
        return 0;
    }
    if (op1.isInfinite || op2.isInfinite) {
        return 0;
    }
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (diff > 0) return 1;
    if (diff < 0) return -1;
    Decimal result = op1 - op2;
    if (result.isZero) {
        if (op1.expo > op2.expo) return 1;
        if (op1.expo < op2.expo) return -1;
        return 0;
    }
    return result.sign ? -1 : 1;
}

unittest {
    write("comp-total...");
    Decimal op1;
    Decimal op2;
    int result;
    op1 = "12.73";
    op2 = "127.9";
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = "-127";
    op2 = "12";
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = "12.30";
    op2 = "12.3";
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = "12.30";
    op2 = "12.30";
    result = compareTotal(op1, op2);
    assert(result == 0);
    op1 = "12.3";
    op2 = "12.300";
    result = compareTotal(op1, op2);
    assert(result == 1);
    op1 = "12.3";
    op2 = "NaN";
    result = compareTotal(op1, op2);
    assert(result == -1);
    writeln("passed");
}

// UNREADY: compareTotalMagnitude
int compareTotalMagnitude(const Decimal op1, const Decimal op2) {
    return compareTotal(copyAbs(op1), copyAbs(op2));
}

unittest {
    write("comp-tot-mag..");
    writeln("test missing");
}

// UNREADY: max. Flags.
// TODO: this is where the need for flags comes in.
/**
 * Returns the maximum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is larger than a NaN.
 * If they are not numerically equal, the larger is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the positive sign is returned.
 * 2) If they are positive, the one with the larger exponent is returned.
 * 3) If they are negative, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
const(Decimal) max(const Decimal op1, const Decimal op2) {
    // if both are NaNs or either is an sNan, return NaN.
    if (op1.isNaN && op2.isNaN || op1.isSignaling || op2.isSignaling) {
        return Decimal.NaN;
    }
    // if one op is a quiet NaN return the other
    if (op1.isQuiet || op2.isQuiet) {
        return (op1.isQuiet) ? op2 : op1;
    }
    // if the signs differ, return the unsigned operand
    if (op1.sign != op2.sign) {
        return op1.sign ? op2 : op1;
    }
    // if not numerically equal, return the larger
    int comp = compare(op1, op2);
    if (comp != 0) {
        return comp > 0 ? op1 : op2;
    }
    // if they have the same exponent they are identical, return either
    if (op1.expo == op2.expo) {
        return op1;
    }
    // if they are non-negative, return the one with larger exponent.
    if (op1.sign == 0) {
        return op1.expo > op2.expo ? op1 : op2;
    }
    // else they are negative; return the one with smaller exponent.
    return op1.expo > op2.expo ? op2 : op1;
}

unittest {
    write("max..........");
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(max(op1, op2) == op1);
    op1 = -10;
    op2 = 3;
    assert(max(op1, op2) == op2);
    op1 = "1.0";
    op2 = "1";
    assert(max(op1, op2) == op2);
    op1 = "7";
    op2 = "NaN";
    assert(max(op1, op2) == op1);
    writeln("passed");
}

// UNREADY: maxMagnitude. Flags.
const(Decimal) maxMagnitude(const Decimal op1, const Decimal op2) {
    return max(copyAbs(op1), copyAbs(op2));
}

unittest {
    write("max-mag......");
    writeln("test missing");
}

// UNREADY: min. Flags.
/**
 * Returns the minimum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is smaller than a NaN.
 * If they are not numerically equal, the smaller is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the negative sign is returned.
 * 2) If they are negative, the one with the larger exponent is returned.
 * 3) If they are positive, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
const(Decimal) min(const Decimal op1, const Decimal op2) {
    // if both are NaNs or either is an sNan, return NaN.
    if (op1.isNaN && op2.isNaN || op1.isSignaling || op2.isSignaling) {
/*        Decimal result;
        result.flags = INVALID_OPERATION;*/
        return Decimal.NaN;
    }
    // if one op is a quiet NaN return the other
    if (op1.isQuiet || op2.isQuiet) {
        return (op1.isQuiet) ? op2 : op1;
    }
    // if the signs differ, return the unsigned operand
    if (op1.sign != op2.sign) {
        return op1.sign ? op1 : op2;
    }
    // if not numerically equal, return the smaller
    int comp = compare(op1, op2);
    if (comp != 0) {
        return comp < 0 ? op1 : op2;
    }
    // if they have the same exponent they are identical, return either
    if (op1.expo == op2.expo) {
        return op1;
    }
    // if they are non-negative, return the one with smaller exponent.
    if (op1.sign == 0) {
        return op1.expo < op2.expo ? op1 : op2;
    }
    // else they are negative; return the one with larger exponent.
    return op1.expo < op2.expo ? op2 : op1;
}

unittest {
    write("min..........");
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(min(op1, op2) == op2);
    op1 = -10;
    op2 = 3;
    assert(min(op1, op2) == op1);
    op1 = "1.0";
    op2 = "1";
    assert(min(op1, op2) == op1);
    op1 = "7";
    op2 = "NaN";
    assert(min(op1, op2) == op1);
    writeln("passed");
}

// UNREADY: minMagnitude. Flags.
const(Decimal) minMagnitude(const Decimal op1, const Decimal op2) {
    return min(copyAbs(op1), copyAbs(op2));
}

unittest {
    write("min-mag......");
    writeln("test missing");
}

//------------------------------------------
// binary arithmetic operations
//------------------------------------------

/**
 * Shifts the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand shift the
 * first operand left (multiplying by tens). Negative values shift right
 * (divide by 10s). If the number is NaN, or if the shift value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public Decimal shift(const Decimal op1, const int op2) {

    Decimal result;
    // check for NaN operand
    if (invalidOperand(op1, result)) {
        return result;
    }
    if (op2 < -context.precision || op2 > context.precision) {
        result = flagInvalid();
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
    }
    if (op2 == 0) {
        return op1.dup;
    }
    result = op1.dup;
    if (op2 > 0) {
        decShl(result.mant, op2);
    }
    else {
        decShr(result.mant, -op2);
    }
    result.expo -= op2;
    result.digits += op2;

    return result;
}

unittest {
    write("shift........");
    Decimal num = 34;
    int digits = 8;
    Decimal act = shift(num, digits);
//    writeln("act = ", act);
    num = 12;
    digits = 9;
    act = shift(num, digits);
//    writeln("act = ", act);
    num = 123456789;
    digits = -2;
    act = shift(num, digits);
//    writeln("act = ", act);
    digits = 0;
    act = shift(num, digits);
//    writeln("act = ", act);
    digits = 2;
    act = shift(num, digits);
//    writeln("act = ", act);
    writeln("failed");
}

/**
 * Rotates the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand rotate the
 * first operand left (multiplying by tens). Negative values rotate right
 * (divide by 10s). If the number is NaN, or if the rotate value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public Decimal rotate(const Decimal op1, const int op2) {

    Decimal result;
    // check for NaN operand
    if (invalidOperand(op1, result)) {
        return result;
    }
    if (op2 < -context.precision || op2 > context.precision) {
        result = flagInvalid();
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
    }
    if (op2 == 0) {
        return op1.dup;
    }
    result = op1.dup;

    // TODO: And then a miracle happens....

    return result;
}

unittest {
    write("rotate.......");
/*    Decimal num = 34;
    int digits = 8;
    Decimal act = rotate(num, digits);
    writeln("act = ", act);
    num = 12;
    digits = 9;
    act = rotate(num, digits);
    writeln("act = ", act);
    num = 123456789;
    digits = -2;
    act = rotate(num, digits);
    writeln("act = ", act);
    digits = 0;
    act = rotate(num, digits);
    writeln("act = ", act);
    digits = 2;
    act = rotate(num, digits);
    writeln("act = ", act);*/
    writeln("failed");
}

// READY: add
/**
 * Adds two numbers.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for the Decimal struct.
 */
public Decimal add(const Decimal op1, const Decimal op2, bool rounded = true) {
    Decimal augend = op1.dup;
    Decimal addend = op2.dup;
    Decimal sum;    // sum is initialized to quiet NaN
    // check for NaN operand(s)
    if (isInvalidBinaryOp(augend, addend, sum)) {
        return sum;
    }
    // if both operands are infinite
    if (augend.isInfinite && addend.isInfinite) {
        // (+inf) + (-inf) => invalid operation
        if (augend.sign != addend.sign) {
            return flagInvalid();
        }
        // both infinite with same sign
        return augend;
    }

    if (isInvalidAddition(augend, addend, sum)) {
        return sum;
    }
    // only augend is infinite,
    if (augend.isInfinite) {
        return augend;
    }
    // only addend is infinite
    if (addend.isInfinite) {
        return addend;
    }

    // add(0, 0)
    if (augend.isZero && addend.isZero) {
        sum = augend;
        sum.sign = augend.sign && addend.sign;
        return sum;
    }

    // TODO: this can never return zero, right?
    // align the operands
    alignOps(augend, addend);

    // at this point, the result will be finite and not zero
    // (before rounding)
    sum.clear();

    // if operands have the same sign...
    if (augend.sign == addend.sign) {
        sum.mant = augend.mant + addend.mant;
        sum.sign = augend.sign;
    }
    // ...else operands have different signs
    else {
        sum.mant = augend.mant - addend.mant;
        sum.sign = augend.sign;
        if (sum.mant < BigInt(0)) {
            sum.mant = -sum.mant;
            sum.sign = !sum.sign;
        }
    }
    // set the number of digits and the exponent
    sum.digits = numDigits(sum.mant);
    sum.expo = augend.expo;

    // round the result
    if (rounded) {
        round(sum, context);
    }
    return sum;
}    // end add(augend, addend)

// TODO: these tests need to be cleaned up to rely less on strings
// and to check the NaN, Inf combinations better.
unittest {
    write("add..........");
    Decimal dcm1 = Decimal("12");
    Decimal dcm2 = Decimal("7.00");
    Decimal sum = add(dcm1, dcm2);
    assert(sum.toString() == "19.00");
    dcm1 = Decimal("1E+2");
    dcm2 = Decimal("1E+4");
    sum = add(dcm1, dcm2);
    assert(sum.toString() == "1.01E+4");
    dcm1 = Decimal("1.3");
    dcm2 = Decimal("1.07");
    sum = subtract(dcm1, dcm2);
    assert(sum.toString() == "0.23");
    dcm2 = Decimal("1.30");
    sum = subtract(dcm1, dcm2);
    assert(sum.toString() == "0.00");
    dcm2 = Decimal("2.07");
    sum = subtract(dcm1, dcm2);
    assert(sum.toString() == "-0.77");
    dcm1 = "Inf";
    dcm2 = 1;
    sum = add(dcm1, dcm2);
    assert(sum.toString() == "Infinity");
    dcm1 = "NaN";
    dcm2 = 1;
    sum = add(dcm1, dcm2);
    assert(sum.isQuiet);
    dcm2 = "Infinity";
    sum = add(dcm1, dcm2);
    assert(sum.isQuiet);
    dcm1 = 1;
    sum = subtract(dcm1, dcm2);
    assert(sum.toString() == "-Infinity");
    dcm1 = "-0";
    dcm2 = 0;
    sum = subtract(dcm1, dcm2);
    assert(sum.toString() == "-0");
    writeln("passed");
}

// READY: subtract
/**
 * Subtracts a number from another number.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for the Decimal struct.
 */
public Decimal subtract(const Decimal minuend, const Decimal subtrahend,
        const bool rounded = true) {
    return add(minuend, copyNegate(subtrahend), rounded);
}    // end subtract(minuend, subtrahend)

unittest {
    write("subtract.....");
    writeln("test missing");
}

// READY: multiply
/**
 * Multiplies two numbers.
 *
 * This function corresponds to the "multiply" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opMul function for the Decimal struct.
 */
public Decimal multiply(
        const Decimal op1, const Decimal op2, const bool rounded = true) {

    Decimal product;
    // if invalid, return NaN
    if (isInvalidMultiplication(op1, op2, product)) {
        return product;
    }
    // if either operand is infinite, return infinity
    if (op1.isInfinite || op2.isInfinite) {
        product = Decimal.infinity;
        product.sign = op1.sign ^ op2.sign;
        return product;
    }
    // product is finite
    product.clear();
    product.mant = cast(BigInt)op1.mant * cast(BigInt)op2.mant;
    product.expo = op1.expo + op2.expo;
    product.sign = op1.sign ^ op2.sign;
    product.digits = numDigits(product.mant);
    if (rounded) {
        round(product, context);
    }
    return product;
}

unittest {
    write("multiply.....");
    Decimal op1, op2, result;
    op1 = Decimal("1.20");
    op2 = 3;
    result = op1 * op2;
    assert(result.toString() == "3.60");
    op1 = 7;
    result = op1 * op2;
    assert(result.toString() == "21");
    op1 = Decimal("0.9");
    op2 = Decimal("0.8");
    result = op1 * op2;
    assert(result.toString() == "0.72");
    op1 = Decimal("0.9");
    op2 = Decimal("-0.0");
    result = op1 * op2;
    assert(result.toString() == "-0.00");
    op1 = Decimal(654321);
    op2 = Decimal(654321);
    result = op1 * op2;
    assert(result.toString() == "4.28135971E+11");
    op1 = -1;
    op2 = "Infinity";
    result = op1 * op2;
    assert(result.toString() == "-Infinity");
    op1 = -1;
    op2 = 0;
    result = op1 * op2;
    assert(result.toString() == "-0");
    writeln("passed");
}

// READY: fma
/**
 * Multiplies two numbers and adds a third number to the result.
 * The result of the multiplication is not rounded prior to the addition.
 *
 * This function corresponds to the "fused-multiply-add" function
 * in the General Decimal Arithmetic Specification.
 */
public Decimal fma(
        const Decimal op1, const Decimal op2, const Decimal op3) {

    Decimal product = multiply(op1, op2, false);
    return add(product, op3);
}

unittest {
    write("fma..........");
    Decimal op1, op2, op3, result;
    op1 = 3; op2 = 5; op3 = 7;
    result = (fma(op1, op2, op3));
    assert(result == Decimal(22));
    op1 = 3; op2 = -5; op3 = 7;
    result = (fma(op1, op2, op3));
    assert(result == Decimal(-8));
    op1 = "888565290";
    op2 = "1557.96930";
    op3 = "-86087.7578";
    result = (fma(op1, op2, op3));
    assert(result == Decimal("1.38435736E+12"));
    writeln("passed");
}

// READY: divide
/**
 * Divides one number by another and returns the quotient.
 * Division by zero sets a flag and returns Infinity.
 *
 * This function corresponds to the "divide" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opDiv function for the Decimal struct.
 */
public Decimal divide(
        const Decimal op1, const Decimal op2, bool rounded = true) {

    Decimal quotient;
    // check for NaN and divide by zero
    if (isInvalidDivision(op1, op2, quotient)) {
        return quotient;
    }
    // if op1 is zero, quotient is zero
    if (isZeroDividend(op1, op2, quotient)) {
        return quotient;
    }

    quotient.clear();
    // TODO: are two guard digits necessary? sufficient?
    context.precision += 2;
    Decimal dividend = op1.dup;
    Decimal divisor  = op2.dup;
    int diff = dividend.expo - divisor.expo;
    if (diff > 0) {
        decShl(dividend.mant, diff);
        dividend.expo -= diff;
        dividend.digits += diff;
    }
    int shift = 2 + context.precision + divisor.digits - dividend.digits;
    if (shift > 0) {
        decShl(dividend.mant, shift);
        dividend.expo -= shift;
        dividend.digits += diff;
    }
    quotient.mant = dividend.mant / divisor.mant;
    quotient.expo = dividend.expo - divisor.expo;
    quotient.sign = dividend.sign ^ divisor.sign;
    quotient.digits = numDigits(quotient.mant);
    context.precision -= 2;
    if (rounded) {
        round(quotient, context);
        if (!context.getFlag(INEXACT)) {
            quotient = reduceToIdeal(quotient, diff);
        }
    }
    return quotient;
}

unittest {
    write("divide.......");
    Decimal dcm1, dcm2;
    Decimal expd;
    dcm1 = 1;
    dcm2 = 3;
    context.precision = 9;
    Decimal quotient = divide(dcm1, dcm2);
    expd = "0.333333333";
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm1 = 2;
    dcm2 = 3;
    quotient = divide(dcm1, dcm2);
    expd = "0.666666667";
    assert(quotient == expd);
    dcm1 = 5;
    dcm2 = 2;
    context.clearFlags();
    quotient = divide(dcm1, dcm2);
//    assert(quotient == expd);
//    assert(quotient.toString() == expd.toString());
    dcm1 = 1;
    dcm2 = 10;
    expd = 0.1;
    quotient = divide(dcm1, dcm2);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm1 = "8.00";
    dcm2 = 2;
    expd = "4.00";
    quotient = divide(dcm1, dcm2);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm1 = "2.400";
    dcm2 = "2.0";
    expd = "1.20";
    quotient = divide(dcm1, dcm2);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm1 = 1000;
    dcm2 = 100;
    expd = 10;
    quotient = divide(dcm1, dcm2);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm2 = 1;
    quotient = divide(dcm1, dcm2);
    expd = 1000;
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    dcm1 = "2.40E+6";
    dcm2 = 2;
    expd = "1.20E+6";
    quotient = divide(dcm1, dcm2);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    writeln("passed");
}

// UNREADY: divideInteger. Error if integer value > precision digits. Duplicates code with divide?
/**
 * Divides one number by another and returns the integer portion of the quotient.
 * Division by zero sets a flag and returns Infinity.
 *
 * This function corresponds to the "divide-integer" function
 * in the General Decimal Arithmetic Specification.
 */
public Decimal divideInteger(const Decimal op1, const Decimal op2) {

    Decimal quotient;
    if (isInvalidDivision(op1, op2, quotient)) {
        return quotient;
    }
    if (isZeroDividend(op1, op2, quotient)) {
        return quotient;
    }

    quotient.clear();
    Decimal divisor = op1.dup;
    Decimal dividend = op2.dup;
    // align operands
    int diff = dividend.expo - divisor.expo;
    if (diff < 0) {
        decShl(divisor.mant, -diff);
    }
    if (diff > 0) {
        decShl(dividend.mant, diff);
    }
    quotient.mant = divisor.mant / dividend.mant;
    quotient.expo = 0;
    quotient.sign = dividend.sign ^ divisor.sign;
    quotient.digits = numDigits(quotient.mant);
    if (quotient.mant == 0) quotient.sval = Decimal.SV.ZERO;
    return quotient;
}

unittest {
    write("div-int......");
    Decimal dividend;
    Decimal divisor;
    Decimal quotient;
    Decimal expd;
    dividend = 2;
    divisor = 3;
    quotient = divideInteger(dividend, divisor);
    expd = 0;
    assert(quotient == expd);
    dividend = 10;
    quotient = divideInteger(dividend, divisor);
    expd = 3;
    assert(quotient == expd);
    dividend = 1;
    divisor = "0.3";
    quotient = divideInteger(dividend, divisor);
    assert(quotient == expd);
    writeln("passed");
}

// UNREADY: remainder. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public Decimal remainder(const Decimal op1, const Decimal op2) {
    Decimal quotient;
    if (isInvalidDivision(op1, op2, quotient)) {
        return quotient;
    }
    if (isZeroDividend(op1, op2, quotient)) {
        return quotient;
    }
    quotient = divideInteger(op1, op2);
    Decimal remainder = op1 - multiply(op2, quotient, false);
    return remainder;
}

unittest {
    write("remainder....");
    Decimal dividend;
    Decimal divisor;
    Decimal quotient;
    Decimal expected;
    dividend = "2.1";
    divisor = 3;
    quotient = remainder(dividend, divisor);
    expected = "2.1";
    assert(quotient == expected);
    dividend = 10;
    quotient = remainder(dividend, divisor);
    expected = 1;
    assert(quotient == expected);
    dividend = -10;
    quotient = remainder(dividend, divisor);
    expected = -1;
    assert(quotient == expected);
    dividend = 10.2;
    divisor = 1;
    quotient = remainder(dividend, divisor);
    expected = "0.2";
    assert(quotient == expected);
    dividend = 10;
    divisor = 0.3;
    quotient = remainder(dividend, divisor);
    expected = "0.1";
    assert(quotient == expected);
    dividend = 3.6;
    divisor = 1.3;
    quotient = remainder(dividend, divisor);
    expected = "1.0";
    assert(quotient == expected);
    writeln("passed");
}

// UNREADY: remainderNear. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public Decimal remainderNear(const Decimal dividend, const Decimal divisor) {
    Decimal quotient;
    if (isInvalidDivision(dividend, divisor, quotient)) {
        return quotient;
    }
    if (isZeroDividend(dividend, divisor, quotient)) {
        return quotient;
    }
    quotient = divideInteger(dividend, divisor);
    Decimal remainder = dividend - multiply(divisor, quotient, false);
    return remainder;
}

unittest {
    write("rem-near.....");
    writeln("test missing");
}

//--------------------------------
// rounding routines
//--------------------------------

// UNREADY: roundToIntegralExact. Description. Name. Order.
// could set flags and then pop the context??
public Decimal roundToIntegralExact(const Decimal num){
    if (num.isSignaling) return flagInvalid();
    if (num.isSpecial) return num.dup;
    if (num.expo >= 0) return num.dup;
    pushPrecision();
    context.precision = num.digits;
    const Decimal ONE = Decimal(1);
    Decimal result = quantize(num, ONE);
    popPrecision;
    return result;
}

unittest {
    write("rnd-int-ex...");
    Decimal dec, expd, actual;
    dec = 2.1;
    expd = 2;
    actual = roundToIntegralExact(dec);
    assert(actual == expd);
    dec = 100;
    expd = 100;
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "100.0";
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "101.5";
    expd = 102;
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "-101.5";
    expd = -102;
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "10E+5";
    expd = "1.0E+6";
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "7.89E+77";
    expd = "7.89E+77";
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    dec = "-Inf";
    expd = "-Infinity";
    assert(roundToIntegralExact(dec) == expd);
    assert(roundToIntegralExact(dec).toString() == expd.toString());
    writeln("passed");
}

// UNREADY: roundToIntegralValue. Description. Name. Order. Logic.
public Decimal roundToIntegralValue(const Decimal num){
    // this operation shouldn't affect the inexact or rounded flags
    // so we'll save them in case they were already set.
    bool inexact = context.getFlag(INEXACT);
    bool rounded = context.getFlag(ROUNDED);
    Decimal result = roundToIntegralExact(num);
    context.setFlag(INEXACT, inexact);
    context.setFlag(ROUNDED, rounded);
    return result;
}

unittest {
    write("rnd-int-val..");
    writeln("test missing");
}

// UNREADY: round. Description. Private or public?
public void round(ref Decimal num, DecimalContext context) {

    if (!num.isFinite) return;

    context.clearFlags();
    // check for subnormal
    bool subnormal = false;
    if (num.isSubnormal()) {
        context.setFlag(SUBNORMAL);
        subnormal = true;
    }

    // check for overflow
    if (willOverflow(num)) {
        context.setFlag(OVERFLOW);
        switch (context.mode) {
            case Rounding.HALF_UP:
            case Rounding.HALF_EVEN:
            case Rounding.HALF_DOWN:
            case Rounding.UP:
                bool sign = num.sign;
                num = Decimal.POS_INF;
                num.sign = sign;
                break;
            case Rounding.DOWN:
                bool sign = num.sign;
                num = Decimal.max;
                num.sign = sign;
                break;
            case Rounding.CEILING:
                if (num.sign) {
                    num = Decimal.max;
                    num.sign = true;
                }
                else {
                    num = Decimal.POS_INF;
                }
                break;
            case Rounding.FLOOR:
                if (num.sign) {
                    num = Decimal.NEG_INF;
                } else {
                    num = Decimal.max;
                }
                break;
        }
        context.setFlag(INEXACT);
        context.setFlag(ROUNDED);
        return;
    }
    roundByMode(num);
    // check for underflow
    if (num.isSubnormal /*&& num.isInexact*/) {
        context.setFlag(SUBNORMAL);
        int diff = context.eTiny - num.adjustedExponent;
        if (diff > num.digits) {
            num.mant = 0;
            num.expo = context.eTiny;
        } else if (diff > 0) {
            // TODO: do something about this
            writeln("We got a tiny one!");
        }
    }
    // check for zero
    if (num.sval == Decimal.SV.CLEAR && num.mant == BigInt(0)) {
        num.sval = Decimal.SV.ZERO;
        // subnormal rounding to zero == clamped
        // Spec. p. 51
        if (subnormal) {
            context.setFlag(CLAMPED);
        }
        return;
    }
} // end round()

unittest {
    writeln("-------------");
    write("round........");
    Decimal before = Decimal(9999);
    Decimal after = before;
    pushPrecision;
    context.precision = 3;
    round(after, context);;
    assert(after.toString() == "1.00E+5");
    before = Decimal(1234567890);
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toString() == "1.23E+9");
    after = before;
    context.precision = 4;
    round(after, context);;
    assert(after.toString() == "1.235E+9");
    after = before;
    context.precision = 5;
    round(after, context);;
    assert(after.toString() == "1.2346E+9");
    after = before;
    context.precision = 6;
    round(after, context);;
    assert(after.toString() == "1.23457E+9");
    after = before;
    context.precision = 7;
    round(after, context);;
    assert(after.toString() == "1.234568E+9");
    after = before;
    context.precision = 8;
    round(after, context);;
    assert(after.toString() == "1.2345679E+9");
    before = "1235";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = "12359";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,2]");
    before = "1245";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = "12459";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,125,2]");
    popPrecision;
    writeln("passed");
}

//--------------------------------
// private rounding routines
//--------------------------------

// UNREADY: shorten. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private Decimal shorten(ref Decimal num) {
    Decimal remainder = Decimal.ZERO.dup;
    int diff = num.digits - context.precision;
    if (diff <= 0) {
        return remainder;
    }
    context.setFlag(ROUNDED);

    // the context can be zero when...??
    if (context.precision == 0) {
        num = num.sign ? Decimal.NEG_ZERO : Decimal.ZERO;
    } else {
        BigInt divisor = pow10(diff);
        BigInt dividend = num.mant;
        BigInt quotient = dividend/divisor;
        BigInt modulo = dividend - quotient*divisor;
        if (modulo != BigInt(0)) {
            remainder.digits = diff;
            remainder.expo = num.expo;
            remainder.mant = modulo;
            remainder.sval = Decimal.SV.CLEAR;
        }
        num.mant = quotient;
        num.digits = context.precision;
        num.expo += diff;
    }
    if (remainder != Decimal.ZERO) {
        context.setFlag(INEXACT);
    }

    return remainder;
}

unittest {
    write("shorten...");
    writeln("test missing");
}

// UNREADY: increment. Unit tests. Order.
// TODO: unittest this
/**
 * Increments the coefficient by 1. If this causes an overflow, divides by 10.
 */
private void increment(ref Decimal num) {
    num.mant += 1;
    // check if the num was all nines --
    // did the coefficient roll over to 1000...?
    Decimal test1 = Decimal(1, num.digits + num.expo);
    Decimal test2 = num;
    test2.digits++;
    int result = compare(test1, test2, false);
    if (result == 0) {
        num.expo++;
        num.digits++;
        setDigits(num);
    }
}

unittest {
    write("increment...");
    writeln("test missing");
}

private bool willOverflow(const Decimal num) {
    return num.adjustedExponent > context.eMax;
}

unittest{
    write("willOverflow.....");
    Decimal dec = Decimal(123, 99);
    assert(willOverflow(dec));
    dec = Decimal(12, 99);
    assert(willOverflow(dec));
    dec = Decimal(1, 99);
    assert(!willOverflow(dec));
    dec = Decimal(9, 99);
    assert(!willOverflow(dec));
    writeln("passed");
}

// UNREADY: roundByMode. Description. Order.
private void roundByMode(ref Decimal num) {
    Decimal remainder = shorten(num);

    // if the rounded flag is not set by the shorten operation, return
    if (!context.getFlag(ROUNDED)) {
        return;
    }
    // if the remainder is zero, return
    if (!context.getFlag(INEXACT)) {
        return;
    }

    switch (context.mode) {
        case Rounding.DOWN:
            return;
        case Rounding.HALF_UP:
            if (firstDigit(remainder.mant) >= 5) {
                increment(num);
            }
            return;
        case Rounding.HALF_EVEN:
            Decimal five = Decimal(5, remainder.digits + remainder.expo - 1);
            int result = compare(remainder, five, false);
            if (result > 0) {
                increment(num);
                return;
            }
            if (result < 0) {
                return;
            }
            // remainder == 5
            // if last digit is odd...
            if (lastDigit(num.mant) % 2) {
                increment(num);
            }
            return;
        case Rounding.CEILING:
            if (!num.sign && remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
        case Rounding.FLOOR:
            if (num.sign && remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
        case Rounding.HALF_DOWN:
            if (firstDigit(remainder.mant) > 5) {
                increment(num);
            }
            return;
        case Rounding.UP:
            if (remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
    }    // end switch(mode)
} // end roundByMode()

unittest {
    write("roundByMode...");
    writeln("test missing");
}

// UNREADY: setDigits. Description. Ordering.
/**
 * Sets the number of digits to the current precision.
 */
package void setDigits(ref Decimal num) {
    int diff = num.digits - context.precision;
    if (diff > 0) {
        round(num, context);
    }
}

unittest {
    write("setDigits...");
    writeln("test missing");
}

// UNREADY: reduceToIdeal. Description. Flags.
/**
 * Reduces operand to simplest form. All trailing zeros are removed.
 * Reduces operand to specified exponent.
 */
 // TODO: has non-standard flag setting
private Decimal reduceToIdeal(const Decimal num, int ideal) {
    Decimal result;
    if (invalidOperand(num, result)) {
        return result;
    }
    result = num;
    if (!result.isFinite()) {
        return result;
    }
    BigInt temp = result.mant % 10;
    while (result.mant != 0 && temp == 0 && result.expo < ideal) {
        result.expo++;
        result.mant = result.mant / 10;
        temp = result.mant % 10;
    }
    if (result.mant == 0) {
        result.sval = Decimal.SV.ZERO;
        result.expo = 0;
    }
    result.digits = numDigits(result.mant);
    return result;
}

unittest {
    write("reduceToIdeal...");
    writeln("test missing");
}

// UNREADY: flagInvalid. Unit Tests.
/**
 * Sets the invalid-operation flag and
 * returns a quiet NaN.
 */
private Decimal flagInvalid(ulong payload = 0) {
    context.setFlag(INVALID_OPERATION);
    Decimal result = Decimal.NaN.dup;
    if (payload != 0) {
        result.setNaNPayload(payload);
    }
    return result;
}

unittest {
    write("invalid......");
    Decimal dcm;
    Decimal expd;
    Decimal actual;

    dcm = "sNaN123";
    expd = "NaN123";
    actual = abs(dcm);
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    assert(actual.toAbstract == expd.toAbstract);
    dcm = "NaN123";
    actual = abs(dcm);
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    assert(actual.toAbstract == expd.toAbstract);

    dcm = "sNaN123";
    expd = "NaN123";
    actual = -dcm;
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    assert(actual.toAbstract == expd.toAbstract);
    dcm = "NaN123";
    actual = -dcm;
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    assert(actual.toAbstract == expd.toAbstract);
    writeln("passed");
}

// UNREADY: alignOps. Unit tests. Todo.
// TODO: can this be used in division as well as addition?
/**
 * Aligns the two operands by raising the smaller exponent
 * to the value of the larger exponent, and adjusting the
 * coefficient so the value remains the same.
 */
private void alignOps(ref Decimal op1, ref Decimal op2) {
    int diff = op1.expo - op2.expo;
    if (diff > 0) {
        op1.mant = decShl(op1.mant, diff);
        op1.expo = op2.expo;
    }
    else if (diff < 0) {
        op2.mant = decShl(op2.mant, -diff);
        op2.expo = op1.expo;
    }
}

unittest {
    write("alignOps...");
    writeln("test missing");
}

// UNREADY: isInvalidBinaryOp. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool isInvalidBinaryOp(const Decimal op1, const Decimal op2,
        ref Decimal result) {
    // if either operand is a signaling NaN...
    if (op1.isSignaling || op2.isSignaling) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the first sNaN operand
        result = op1.isSignaling ? op1 : op2;
        // retain sign and payload; convert to qNaN
        result.sval = Decimal.SV.QNAN;
        return true;
    }
    // ...else if either operand is a quiet NaN...
    if (op1.isQuiet || op2.isQuiet) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the first qNaN operand
        result = op1.isQuiet ? op1 : op2;
        return true;
    }
    // ...otherwise, no flags are set and result is unchanged
    return false;
}

unittest {
    write("isInvalidBinaryOp...");
    writeln("test missing");
}

// UNREADY: invalidOperand. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool invalidOperand(const Decimal op1, ref Decimal result) {
    // if the operand is a signaling NaN...
    if (op1.isSignaling) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the sNaN operand
        result = op1;
        // retain sign and payload; convert to qNaN
        result.sval = Decimal.SV.QNAN;
        return true;
    }
    // ...else if the operand is a quiet NaN...
    if (op1.isQuiet) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the qNaN operand
        result = op1;
        return true;
    }
    // ...otherwise, no flags are set and result is unchanged
    return false;
}

unittest {
    write("invalidOperand...");
    writeln("test missing");
}

// UNREADY: isInvalidAddition. Description.
/*
 *    Checks for NaN operands and +infinity added to -infinity.
 *    If found, sets flags, sets the sum to NaN and returns true.
 *
 *    -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidAddition(Decimal op1, Decimal op2, ref Decimal result) {
    if (isInvalidBinaryOp(op1, op2, result)) {
        return true;
    }
    // if both operands are infinite
    if (op1.isInfinite && op2.isInfinite) {
        // (+inf) + (-inf) => invalid operation
        if (op1.sign != op2.sign) {
            result = flagInvalid();
            return true;
        }
    }
    return false;
}

unittest {
    write("isInvalidAddition...");
    writeln("test missing");
}

// UNREADY: isInvalidMultiplication. Flags. Unit Tests.
/*
 *    Checks for NaN operands and Infinity * Zero.
 *    If found, sets flags, sets the product to NaN and returns true.
 *
 *    -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidMultiplication(
        const Decimal op1, const Decimal op2, ref Decimal result) {
    if (isInvalidBinaryOp(op1, op2, result)) {
        return true;
    }
    if (op1.isZero && op2.isInfinite || op1.isInfinite && op2.isZero) {
        result = Decimal.NaN;
        return true;
    }
    return false;
}

unittest {
    write("isInvalidMultiplication...");
    writeln("test missing");
}

// UNREADY: isInvalidDivision. Unit Tests.
/*
 *    Checks for NaN operands and division by zero.
 *    If found, sets flags, sets the quotient to NaN or Infinity respectively
 *    and returns true.
 *
 * -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidDivision(
    const Decimal dividend, const Decimal divisor, ref Decimal quotient) {
    if (isInvalidBinaryOp(dividend, divisor, quotient)) {
        return true;
    }
    if (divisor.isZero()) {
        if (dividend.isZero()) {
            quotient = flagInvalid();
        }
        else {
            context.setFlag(DIVISION_BY_ZERO);
            quotient.sval = Decimal.SV.INF;
            quotient.mant = BigInt(0);
            quotient.sign = dividend.sign ^ divisor.sign;
        }
        return true;
    }
    return false;
}

unittest {
    write("isInvalidDivision...");
    writeln("test missing");
}

// UNREADY: isZeroDividend. Unit tests.
/**
 * Checks for a zero dividend. If found, sets the quotient to zero.
 */
private bool isZeroDividend(const Decimal dividend, const Decimal divisor,
        Decimal quotient) {
    if (dividend.isZero()) {
        quotient.sval = Decimal.SV.ZERO;
        quotient.mant = BigInt(0);
        quotient.expo = 0;
        quotient.digits = dividend.digits; // TODO: ??? should be 1???
        quotient.sign = dividend.sign;
        return true;
    }
    return false;
}

unittest {
    write("isZeroDividend...");
    writeln("test missing");
}

unittest {
    writeln("---------------------");
    writeln("arithmetic...finished");
    writeln("---------------------");
    writeln();
}

//--------------------------------

