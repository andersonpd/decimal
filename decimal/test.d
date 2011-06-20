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

module decimal.test;

import std.bigint;
import decimal.arithmetic;
import decimal.decimal;
import decimal.dec32;
import decimal.rounding;

//--------------------------------
// unit test methods
//--------------------------------

template Test(T) {
    bool isEqual(T)(T actual, T expected, string label, string message = "") {
        bool equal = (expected == actual);
        if (!equal) {
            writeln("Test ", label, ": Expected [", expected, "] but found [", actual, "]. ", message);
        }
        return equal;
    }
}


//--------------------------------
// unit tests
//--------------------------------

unittest {
    bool passed = true;
    long n = 12345;
    Test!(long).isEqual(lastDigit(n), 5, "digits 1");
    Test!(long).isEqual(numDigits(n), 5, "digits 2");
    Test!(long).isEqual(firstDigit(n), 1, "digits 3");
    Test!(long).isEqual(firstDigit(n), 8, "digits 4");
    BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    Test!(long).isEqual(lastDigit(big), 5, "digits 5");
    Test!(long).isEqual(numDigits(big), 101, "digits 6");
    Test!(long).isEqual(numDigits(big), 22, "digits 7");
    Test!(long).isEqual(firstDigit(n), 1, "digits 8");
//    assert(lastDigit(big) == 5);
//    assert(numDigits(big) == 101);
//    assert(firstDigit(big) == 1);
}

import decimal.context; //: INVALID_OPERATION;
/*
import decimal.digits;
import decimal.decimal;
import decimal.arithmetic;
import decimal.math;
import std.bigint;
import std.stdio: write, writeln;
import std.string;

alias BigDecimal.context.precision precision;*/

private DecimalContext context = DEFAULT_CONTEXT;

unittest {
    writeln("---------------------");
    writeln("arithmetic....testing");
    writeln("---------------------");
}

unittest {
    write("to-sci-str...");
    // test moved to decimal.conv
    writeln("passed");
}

unittest {
    write("to-eng-str...");
    // test moved to decimal.conv
    writeln("passed");
}

unittest {
    write("to-number....");
    BigDecimal f;
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
    f = BigDecimal("123");
    assert(f.toString() == "123");
    f = BigDecimal("-123");
    assert(f.toString() == "-123");
    f = BigDecimal("1.23E3");
    assert(f.toString() == "1.23E+3");
    f = BigDecimal("1.23E");
    assert(f.toString() == "NaN");
    f = BigDecimal("1.23E-");
    assert(f.toString() == "NaN");
    f = BigDecimal("1.23E+");
    assert(f.toString() == "NaN");
    f = BigDecimal("1.23E+3");
    assert(f.toString() == "1.23E+3");
    f = BigDecimal("1.23E3B");
    assert(f.toString() == "NaN");
    f = BigDecimal("12.3E+007");
    assert(f.toString() == "1.23E+8");
    f = BigDecimal("12.3E+70000000000");
    assert(f.toString() == "NaN");
    f = BigDecimal("12.3E+7000000000");
    assert(f.toString() == "NaN");
    f = BigDecimal("12.3E+700000000");
    assert(f.toString() == "1.23E+700000001");
    f = BigDecimal("12.3E-700000000");
    assert(f.toString() == "1.23E-699999999");
    // NOTE: since there will still be adjustments -- maybe limit to 99999999?
    f = BigDecimal("12.0");
    assert(f.toString() == "12.0");
    f = BigDecimal("12.3");
    assert(f.toString() == "12.3");
    f = BigDecimal("1.23E-3");
    assert(f.toString() == "0.00123");
    f = BigDecimal("0.00123");
    assert(f.toString() == "0.00123");
    f = BigDecimal("-1.23E-12");
    assert(f.toString() == "-1.23E-12");
    f = BigDecimal("-0");
    assert(f.toString() == "-0");
    f = BigDecimal("inf");
    assert(f.toString() == "Infinity");
    f = BigDecimal("NaN");
    assert(f.toString() == "NaN");
    f = BigDecimal("-NaN");
    assert(f.toString() == "-NaN");
    f = BigDecimal("sNaN");
    assert(f.toString() == "sNaN");
    f = BigDecimal("Fred");
    assert(f.toString() == "NaN");
    writeln("passed");
}

unittest {
    write("radix........");
    assert(radix() == 10);
    writeln("passed");
}

unittest {
    write("class........");
    BigDecimal num;
    num = "Infinity";
    assert(classify(num) == "+Infinity");
    num = "1E-10";
    assert(classify(num) == "+Normal");
    num = "2.50";
    assert(classify(num) == "+Normal");
    num = "0.1E-99";
    assert(classify(num) == "+Subnormal");
    num = "0";
    assert(classify(num) == "+Zero");
    num = "-0";
    assert(classify(num) == "-Zero");
    num = "-0.1E-99";
    assert(classify(num) == "-Subnormal");
    num = "-1E-10";
    assert(classify(num) == "-Normal");
    num = "-2.50";
    assert(classify(num) == "-Normal");
    num = "-Infinity";
    assert(classify(num) == "-Infinity");
    num = "NaN";
    assert(classify(num) == "NaN");
    num = "-NaN";
    assert(classify(num) == "NaN");
    num = "sNaN";
    assert(classify(num) == "sNaN");
    writeln("passed");
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy.........");
    BigDecimal num;
    BigDecimal expd;
    num  = "2.1";
    expd = "2.1";
    assert(copy(num) == expd);
    num  = "-1.00";
    expd = "-1.00";
    assert(copy(num) == expd);
    writeln("passed");

    num  = "2.1";
    expd = "2.1";
    write("copy-abs.....");
    assert(copyAbs(num) == expd);
    num  = "-1.00";
    expd = "1.00";
    assert(copyAbs(num) == expd);
    writeln("passed");

    num  = "101.5";
    expd = "-101.5";
    write("copy-negate..");
    assert(copyNegate(num) == expd);
    BigDecimal num1;
    BigDecimal num2;
    num1 = "1.50";
    num2 = "7.33";
    expd = "1.50";
    writeln("passed");

    write("copy-sign....");
    assert(copySign(num1, num2) == expd);
    num1 = "-1.50";
    num2 = "7.33";
    expd = "1.50";
    assert(copySign(num1, num2) == expd);
    num1 = "1.50";
    num2 = "-7.33";
    expd = "-1.50";
    assert(copySign(num1, num2) == expd);
    num1 = "-1.50";
    num2 = "-7.33";
    expd = "-1.50";
    assert(copySign(num1, num2) == expd);
    writeln("passed");
}

unittest {
    write("quantize.....");
    BigDecimal op1, op2, result, expd;
    string str;
    op1 = "2.17";
    op2 = "0.001";
    expd = "2.170";
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = "2.17";
    op2 = "0.01";
    expd = "2.17";
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = "2.17";
    op2 = "0.1";
    expd = "2.2";
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = "2.17";
    op2 = "1e+0";
    expd = "2";
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = "2.17";
    op2 = "1e+1";
    expd = "0E+1";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "-Inf";
    op2 = "Infinity";
    expd = "-Infinity";
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = "2";
    op2 = "Infinity";
    expd = "NaN";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "-0.1";
    op2 = "1";
    expd = "-0";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "-0";
    op2 = "1e+5";
    expd = "-0E+5";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "+35236450.6";
    op2 = "1e-2";
    expd = "NaN";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "-35236450.6";
    op2 = "1e-2";
    expd = "NaN";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e-1";
    expd = "217.0";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+0";
    expd = "217";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+1";
    expd = "2.2E+2";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = "217";
    op2 = "1e+2";
    expd = "2E+2";
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    assert(result == expd);
    writeln("passed");
}

unittest {
    write("logb.........");
    BigDecimal num;
    BigDecimal expd;
    num = BigDecimal("250");
    expd = BigDecimal("2");
    assert(logb(num, context) == expd);
    num = BigDecimal("2.50");
    expd = BigDecimal("0");
    assert(logb(num, context) == expd);
    num = BigDecimal("0.03");
    expd = BigDecimal("-2");
    assert(logb(num, context) == expd);
    num = BigDecimal("0");
    expd = BigDecimal("-Infinity");
    assert(logb(num, context) == expd);
    writeln("passed");
}

unittest {
    write("scaleb.......");
    BigDecimal op1, op2, expd;
    op1 = BigDecimal("7.50");
    op2 = BigDecimal("-2");
    expd = BigDecimal("0.0750");
    assert(scaleb(op1, op2, context) == expd);
    op1 = BigDecimal("7.50");
    op2 = BigDecimal("0");
    expd = BigDecimal("7.50");
    assert(scaleb(op1, op2, context) == expd);
    op1 = BigDecimal("7.50");
    op2 = BigDecimal("3");
    expd = BigDecimal("7.50E+3");
    assert(scaleb(op1, op2, context) == expd);
    op1 = BigDecimal("-Infinity");
    op2 = BigDecimal("4.5");
    expd = BigDecimal("-Infinity");
    assert(scaleb(op1, op2, context) == expd);
    writeln("passed");
}

unittest {
    writeln("---------------------");
    writeln("arithmetic...finished");
    writeln("---------------------");
    writeln();
}

unittest {
    writeln("---------------------");
    writeln("decimal32.....testing");
    writeln("---------------------");
}

unittest {
    write("this(long)...");
    Dec32 num = Dec32(1234567890L);
    assert(num.toString == "1.234568E+9");
    writeln("passed");
}

 unittest {
    writeln("this(big)....");
    BigDecimal num = BigDecimal(0);
    Dec32 dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = BigDecimal(1);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = BigDecimal(-1);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = BigDecimal(-16000);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);

    num = BigDecimal(uint.max);
    dec = Dec32(num);
    writeln("num = ", num);
    writeln("dec = ", dec);
    writeln("test missing");
}

unittest {
    write("this(str)....");
    Dec32 num = Dec32("1.234568E+9");
    assert(num.toString == "1.234568E+9");
    writeln("passed");
}

unittest {
    writeln("---------------------");
    writeln("decimal32....finished");
    writeln("---------------------");
}


