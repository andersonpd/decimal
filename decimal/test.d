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

/*template Test(T) {
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
*/
private DecimalContext testContext = DEFAULT_CONTEXT;

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
    Decimal f;
    string str = "0";
    f = Decimal(str);
//    writeln("str = ", str);
//    writeln("f = ", f);
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,0]");
    str = "0.00";
    f = Decimal(str);
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,-2]");
    str = "0.0";
    f = Decimal(str);
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,0,-1]");
    f = Decimal("0.");
    assert(f.toString() == "0");
    assert(f.toAbstract() == "[0,0,0]");
    f = Decimal(".0");
    assert(f.toString() == "0.0");
    assert(f.toAbstract() == "[0,0,-1]");
    str = "1.0";
    f = Decimal(str);
    assert(f.toString() == str);
    assert(f.toAbstract() == "[0,10,-1]");
    str = "1.";
    f = Decimal(str);
    assert(f.toString() == "1");
    assert(f.toAbstract() == "[0,1,0]");
    str = ".1";
    f = Decimal(str);
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

unittest {
    write("radix........");
    assert(radix() == 10);
    writeln("passed");
}

unittest {
    write("class........");
    Decimal num;
    num = Decimal("Infinity");
    assert(classify(num) == "+Infinity");
    num = Decimal("1E-10");
    assert(classify(num) == "+Normal");
    num = Decimal("2.50");
    assert(classify(num) == "+Normal");
    num = Decimal("0.1E-99");
    assert(classify(num) == "+Subnormal");
    num = Decimal("0");
    assert(classify(num) == "+Zero");
    num = Decimal("-0");
    assert(classify(num) == "-Zero");
    num = Decimal("-0.1E-99");
    assert(classify(num) == "-Subnormal");
    num = Decimal("-1E-10");
    assert(classify(num) == "-Normal");
    num = Decimal("-2.50");
    assert(classify(num) == "-Normal");
    num = Decimal("-Infinity");
    assert(classify(num) == "-Infinity");
    num = Decimal("NaN");
    assert(classify(num) == "NaN");
    num = Decimal("-NaN");
    assert(classify(num) == "NaN");
    num = Decimal("sNaN");
    assert(classify(num) == "sNaN");
    writeln("passed");
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    write("copy.........");
    Decimal num;
    Decimal expd;
    num  = 2.1;
    expd = 2.1;
    assert(copy(num) == expd);
    num  = Decimal("-1.00");
    expd = Decimal("-1.00");
    assert(copy(num) == expd);
    writeln("passed");

    num  = 2.1;
    expd = 2.1;
    write("copy-abs.....");
    assert(copyAbs!Decimal(num) == expd);
    num  = Decimal("-1.00");
    expd = Decimal("1.00");
    assert(copyAbs!Decimal(num) == expd);
    writeln("passed");

    num  = 101.5;
    expd = -101.5;
    write("copy-negate..");
    assert(copyNegate!Decimal(num) == expd);
    Decimal num1;
    Decimal num2;
    num1 = 1.50;
    num2 = 7.33;
    expd = 1.50;
    writeln("passed");

    write("copy-sign....");
    assert(copySign(num1, num2) == expd);
    num1 = -1.50;
    num2 = 7.33;
    expd = 1.50;
    assert(copySign(num1, num2) == expd);
    num1 = 1.50;
    num2 = -7.33;
    expd = -1.50;
    assert(copySign(num1, num2) == expd);
    num1 = -1.50;
    num2 = -7.33;
    expd = -1.50;
    assert(copySign(num1, num2) == expd);
    writeln("passed");
}

unittest {
    write("quantize.....");
    Decimal op1, op2, result, expd;
    string str;
    op1 = 2.17;
    op2 = 0.001;
    expd = Decimal("2.170");
    result = quantize(op1, op2, testContext);
    assert(result == expd);
    op1 = 2.17;
    op2 = 0.01;
    expd = 2.17;
    result = quantize(op1, op2, testContext);
    assert(result == expd);
    op1 = 2.17;
    op2 = 0.1;
    expd = 2.2;
    result = quantize(op1, op2, testContext);
    assert(result == expd);
    op1 = 2.17;
    op2 = Decimal("1E+0");
    expd = 2;
    result = quantize(op1, op2, testContext);
    assert(result == expd);
    op1 = 2.17;
    op2 = Decimal("1E+1");
    expd = Decimal("0E+1");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-Inf");
    op2 = Decimal("Infinity");
    expd = Decimal("-Infinity");
    result = quantize(op1, op2, testContext);
    assert(result == expd);
    op1 = 2;
    op2 = Decimal("Infinity");
    expd = Decimal("NaN");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = -0.1;
    op2 = 1;
    expd = Decimal("-0");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-0");
    op2 = Decimal("1E+5");
    expd = Decimal("-0E+5");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("+35236450.6");
    op2 = Decimal("1E-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-35236450.6");
    op2 = Decimal("1E-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E-1");
    expd = Decimal("217.0");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+0");
    expd = Decimal("217");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+1");
    expd = Decimal("2.2E+2");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+2");
    expd = Decimal("2E+2");
    result = quantize(op1, op2, testContext);
    assert(result.toString() == expd.toString());
    assert(result == expd);
    writeln("passed");
}

unittest {
    write("logb.........");
    Decimal num;
    Decimal expd;
    num = Decimal("250");
    expd = Decimal("2");
    assert(logb(num, testContext) == expd);
    num = Decimal("2.50");
    expd = Decimal("0");
    assert(logb(num, testContext) == expd);
    num = Decimal("0.03");
    expd = Decimal("-2");
    assert(logb(num, testContext) == expd);
    num = Decimal("0");
    expd = Decimal("-Infinity");
    assert(logb(num, testContext) == expd);
    writeln("passed");
}

unittest {
    write("scaleb.......");
    Decimal op1, op2, expd;
    op1 = Decimal("7.50");
    op2 = Decimal("-2");
    expd = Decimal("0.0750");
    assert(scaleb(op1, op2, testContext) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("0");
    expd = Decimal("7.50");
    assert(scaleb(op1, op2, testContext) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("3");
    expd = Decimal("7.50E+3");
    assert(scaleb(op1, op2, testContext) == expd);
    op1 = Decimal("-Infinity");
    op2 = Decimal("4.5");
    expd = Decimal("-Infinity");
    assert(scaleb(op1, op2, testContext) == expd);
    writeln("passed");
}

unittest {
    write("reduce.......");
    Decimal num;
    Decimal red;
    string str;
    num = Decimal("2.1");
    str = "2.1";
    red = reduce(num, testContext);
    assert(red.toString() == str);
    num = Decimal("-2.0");
    str = "-2";
    red = reduce(num, testContext);
    assert(red.toString() == str);
    num = Decimal("1.200");
    str = "1.2";
    red = reduce(num, testContext);
    assert(red.toString() == str);
    num = Decimal("-120");
    str = "-1.2E+2";
    red = reduce(num, testContext);
    assert(red.toString() == str);
    num = Decimal("120.00");
    str = "1.2E+2";
    red = reduce(num, testContext);
    assert(red.toString() == str);
    writeln("passed");
}

unittest {
    // TODO: add rounding tests
    writeln("-------------------");
    write("abs..........");
    Decimal num;
    Decimal expd;
    num = Decimal("sNaN");
    assert(abs(num, testContext).isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
    num = Decimal("NaN");
    assert(abs(num, testContext).isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
    num = Decimal("Inf");
    expd = Decimal("Inf");
    assert(abs(num, testContext) == expd);
    num = Decimal("-Inf");
    expd = Decimal("Inf");
    assert(abs(num, testContext) == expd);
    num = Decimal("0");
    expd = Decimal("0");
    assert(abs(num, testContext) == expd);
    num = Decimal("-0");
    expd = Decimal("0");
    assert(abs(num, testContext) == expd);
    num = Decimal("2.1");
    expd = Decimal("2.1");
    assert(abs(num, testContext) == expd);
    num = -100;
    expd = 100;
    assert(abs(num, testContext) == expd);
    num = 101.5;
    expd = 101.5;
    assert(abs(num, testContext) == expd);
    num = -101.5;
    assert(abs(num, testContext) == expd);
    writeln("passed");
}

unittest {
    write("plus.........");
    // NOTE: result should equal 0 + this or 0 - this
    Decimal zero = Decimal(0);
    Decimal num;
    Decimal expd;
    num = 1.3;
    expd = zero + num;
    assert(+num == expd);
    num = -1.3;
    expd = zero + num;
    assert(+num == expd);
    // TODO: add tests that check flags.
    writeln("passed");
}

unittest {
    write("minus........");
    // NOTE: result should equal 0 + this or 0 - this
    Decimal zero = Decimal(0);
    Decimal num;
    Decimal expd;
    num = 1.3;
    expd = zero - num;
    assert(-num == expd);
    num = -1.3;
    expd = zero - num;
    assert(-num == expd);
    // TODO: add tests that check flags.
    writeln("passed");
}

unittest {
    write("next-plus....");
    pushContext(testContext);
    testContext.eMax = 999;
    testContext.eMin = -999;
    Decimal num, expect;
    num = 1;
    expect = Decimal("1.00000001");
    assert(nextPlus(num, testContext) == expect);
    num = 10;
    expect = Decimal("10.0000001");
    assert(nextPlus(num, testContext) == expect);
    num = 1E5;
    expect = Decimal("100000.001");
    assert(nextPlus(num, testContext) == expect);
    num = 1E8;
    expect = Decimal("100000001");
    assert(nextPlus(num, testContext) == expect);
    // num digits exceeds precision...
    num = Decimal("1234567891");
    expect = Decimal("1.23456790E9");
    assert(nextPlus(num, testContext) == expect);
    // result < tiny
    num = Decimal("-1E-1007");
    expect = Decimal("-0E-1007");
    assert(nextPlus(num, testContext) == expect);
    num = Decimal("-1.00000003");
    expect = Decimal("-1.00000002");
    assert(nextPlus(num, testContext) == expect);
    // FIXTHIS: max doesn't pass the current context
/*    num = Decimal("-Infinity");
    expect = Decimal("-9.99999999E+999");
    writeln("expect = ", expect);
    writeln("nextPlus(num, testContext) = ", nextPlus(num, testContext));
    assert(nextPlus(num, testContext) == expect);*/
    testContext = popContext;
    writeln("passed");
}

unittest {
    write("next-minus...");
    pushContext(testContext);
    testContext.eMin = -999;
    testContext.eMax = 999;
    Decimal num;
    Decimal expect;
    num = 1;
    expect = Decimal("0.999999999");
    assert(nextMinus(num, testContext) == expect);
    num = Decimal("1E-1007");
    expect = Decimal("0E-1007");
    assert(nextMinus(num, testContext) == expect);
    num = Decimal("-1.00000003");
    expect = Decimal("-1.00000004");
    assert(nextMinus(num, testContext) == expect);
/*    num = Decimal("Infinity");
    expect = Decimal("9.99999999E+999");
    assert(nextMinus(num, testContext) == expect);*/
    testContext = popContext;
    writeln("passed");
}

unittest {
    write("next-toward..");
    Decimal op1, op2, expect;
    op1 = 1;
    op2 = 2;
    expect = Decimal("1.00000001");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = Decimal("-1E-1007");
    op2 = 1;
    expect = Decimal("-0E-1007");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = Decimal("-1.00000003");
    op2 = 0;
    expect = Decimal("-1.00000002");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = 1;
    op2 = 0;
    expect = Decimal("0.999999999");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = Decimal("1E-1007");
    op2 = -100;
    expect = Decimal("0E-1007");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = Decimal("-1.00000003");
    op2 = -10;
    expect = Decimal("-1.00000004");
    assert(nextToward(op1, op2, testContext) == expect);
    op1 = Decimal("0.00");
    op2 = Decimal("-0.0000");
    expect = Decimal("-0.00");
    assert(nextToward(op1, op2, testContext) == expect);
    writeln("passed");
}

unittest {
    write("same-quantum.");
    Decimal op1, op2;
    op1 = 2.17;
    op2 = 0.001;
    assert(!sameQuantum(op1, op2));
    op2 = 0.01;
    assert(sameQuantum(op1, op2));
    op2 = 0.1;
    assert(!sameQuantum(op1, op2));
    op2 = 1;
    assert(!sameQuantum(op1, op2));
    op1 = Decimal("Inf");
    op2 = Decimal("Inf");
    assert(sameQuantum(op1, op2));
    op1 = Decimal("NaN");
    op2 = Decimal("NaN");
    assert(sameQuantum(op1, op2));
    writeln("passed");
}

unittest {
    write("compare......");
    Decimal op1, op2;
    int result;
    op1 = 2.1;
    op2 = 3;
    result = compare(op1, op2, testContext);
    assert(result == -1);
    op1 = 2.1;
    op2 = 2.1;
    result = compare(op1, op2, testContext);
    assert(result == 0);
    op1 = Decimal("2.1");
    op2 = Decimal("2.10");
    result = compare(op1, op2, testContext);
    assert(result == 0);
    op1 = 3;
    op2 = 2.1;
    result = compare(op1, op2, testContext);
    assert(result == 1);
    op1 = 2.1;
    op2 = -3;
    result = compare(op1, op2, testContext);
    assert(result == 1);
    op1 = -3;
    op2 = 2.1;
    result = compare(op1, op2, testContext);
    assert(result == -1);
    op1 = -3;
    op2 = -4;
    result = compare(op1, op2, testContext);
    assert(result == 1);
    op1 = -300;
    op2 = -4;
    result = compare(op1, op2, testContext);
    assert(result == -1);
    op1 = 3;
    op2 = Decimal.max;
    result = compare(op1, op2, testContext);
    assert(result == -1);
    op1 = -3;
    op2 = copyNegate!Decimal(Decimal.max);
    result = compare!Decimal(op1, op2, testContext);
    assert(result == 1);
    writeln("passed");
}

// NOTE: change these to true opEquals calls.
unittest {
    write("equals.......");
    Decimal op1, op2;
    op1 = Decimal("NaN");
    op2 = Decimal("NaN");
    assert(op1 != op2);
    op1 = Decimal("inf");
    op2 = Decimal("inf");
    assert(op1 == op2);
    op2 = Decimal("-inf");
    assert(op1 != op2);
    op1 = Decimal("-inf");
    assert(op1 == op2);
    op2 = Decimal("NaN");
    assert(op1 != op2);
    op1 = 0;
    assert(op1 != op2);
    op2 = 0;
    assert(op1 == op2);
    writeln("passed");
}

unittest {
    write("comp-signal..");
    writeln("test missing");
}

unittest {
    write("comp-total...");
    Decimal op1;
    Decimal op2;
    int result;
    op1 = 12.73;
    op2 = 127.9;
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = -127;
    op2 = 12;
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = Decimal("12.30");
    op2 = Decimal("12.3");
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = Decimal("12.30");
    op2 = Decimal("12.30");
    result = compareTotal(op1, op2);
    assert(result == 0);
    op1 = Decimal("12.3");
    op2 = Decimal("12.300");
    result = compareTotal(op1, op2);
    assert(result == 1);
    op1 = Decimal("12.3");
    op2 = Decimal("NaN");
    result = compareTotal(op1, op2);
    assert(result == -1);
    writeln("passed");
}

unittest {
    write("comp-tot-mag..");
    writeln("test missing");
}

unittest {
    write("max..........");
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(max(op1, op2, testContext) == op1);
    op1 = -10;
    op2 = 3;
    assert(max(op1, op2, testContext) == op2);
    op1 = Decimal("1.0");
    op2 = 1;
    assert(max(op1, op2, testContext) == op2);
    op1 = 7;
    op2 = Decimal("NaN");
    assert(max(op1, op2, testContext) == op1);
    writeln("passed");
}

unittest {
    write("max-mag......");
    writeln("test missing");
}

unittest {
    write("min..........");
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(min(op1, op2, testContext) == op2);
    op1 = -10;
    op2 = 3;
    assert(min(op1, op2, testContext) == op1);
    op1 = Decimal("1.0");
    op2 = 1;
    assert(min(op1, op2, testContext) == op1);
    op1 = 7;
    op2 = Decimal("NaN");
    assert(min(op1, op2, testContext) == op1);
    writeln("passed");
}

unittest {
    write("min-mag......");
    writeln("test missing");
}

unittest {
    write("shift........");
    Decimal num = 34;
    int digits = 8;
    Decimal act = shift(num, digits, testContext);
    num = 12;
    digits = 9;
    act = shift(num, digits, testContext);
    num = 123456789;
    digits = -2;
    act = shift(num, digits, testContext);
    digits = 0;
    act = shift(num, digits, testContext);
    digits = 2;
    act = shift(num, digits, testContext);
    writeln("failed");
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

// TODO: these tests need to be cleaned up to rely less on strings
// and to check the NaN, Inf combinations better.
unittest {
    write("add..........");
    Decimal op1 = Decimal("12");
    Decimal op2 = Decimal("7.00");
    Decimal sum = add(op1, op2, testContext);
    assert(sum.toString() == "19.00");
    op1 = Decimal("1E+2");
    op2 = Decimal("1E+4");
    sum = add(op1, op2, testContext);
    assert(sum.toString() == "1.01E+4");
    op1 = Decimal("1.3");
    op2 = Decimal("1.07");
    sum = subtract(op1, op2, testContext);
    assert(sum.toString() == "0.23");
    op2 = Decimal("1.30");
    sum = subtract(op1, op2, testContext);
    assert(sum.toString() == "0.00");
    op2 = Decimal("2.07");
    sum = subtract(op1, op2, testContext);
    assert(sum.toString() == "-0.77");
    op1 = Decimal("Inf");
    op2 = 1;
    sum = add(op1, op2, testContext);
    assert(sum.toString() == "Infinity");
    op1 = Decimal("NaN");
    op2 = 1;
    sum = add(op1, op2, testContext);
    assert(sum.isQuiet);
    op2 = Decimal("Infinity");
    sum = add(op1, op2, testContext);
    assert(sum.isQuiet);
    op1 = 1;
    sum = subtract(op1, op2, testContext);
    assert(sum.toString() == "-Infinity");
    op1 = Decimal("-0");
    op2 = 0;
    sum = subtract(op1, op2, testContext);
    assert(sum.toString() == "-0");
    writeln("passed");
}

unittest {
    write("subtract.....");
    writeln("test missing");
}

unittest {
    // TODO: change these to mul(op1, op2) tests.
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
    op2 = Decimal("Infinity");
    result = op1 * op2;
    assert(result.toString() == "-Infinity");
    op1 = -1;
    op2 = 0;
    result = op1 * op2;
    assert(result.toString() == "-0");
    writeln("passed");
}

unittest {
    write("fma..........");
    Decimal op1, op2, op3, result;
    op1 = 3; op2 = 5; op3 = 7;
    result = (fma(op1, op2, op3, testContext));
    assert(result == Decimal(22));
    op1 = 3; op2 = -5; op3 = 7;
    result = (fma(op1, op2, op3, testContext));
    assert(result == Decimal(-8));
    op1 = Decimal("888565290");
    op2 = Decimal("1557.96930");
    op3 = Decimal("-86087.7578");
    result = (fma(op1, op2, op3, testContext));
    assert(result == Decimal("1.38435736E+12"));
    writeln("passed");
}

unittest {
    write("divide.......");
    pushContext(testContext);
    testContext.precision = 9;
    Decimal op1, op2;
    Decimal expd;
    op1 = 1;
    op2 = 3;
    Decimal quotient = divide(op1, op2, testContext);
    expd = Decimal("0.333333333");
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op1 = 2;
    op2 = 3;
    quotient = divide(op1, op2, testContext);
    expd = Decimal("0.666666667");
    assert(quotient == expd);
    op1 = 5;
    op2 = 2;
    testContext.clearFlags();
    quotient = divide(op1, op2, testContext);
//    assert(quotient == expd);
//    assert(quotient.toString() == expd.toString());
    op1 = 1;
    op2 = 10;
    expd = 0.1;
    quotient = divide(op1, op2, testContext);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op1 = Decimal("8.00");
    op2 = 2;
    expd = Decimal("4.00");
    quotient = divide(op1, op2, testContext);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op1 = Decimal("2.400");
    op2 = Decimal("2.0");
    expd = Decimal("1.20");
    quotient = divide(op1, op2, testContext);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op1 = 1000;
    op2 = 100;
    expd = 10;
    quotient = divide(op1, op2, testContext);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op2 = 1;
    quotient = divide(op1, op2, testContext);
    expd = 1000;
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    op1 = 2.40E+6;
    op2 = 2;
    expd = 1.20E+6;
    quotient = divide(op1, op2, testContext);
    assert(quotient == expd);
    assert(quotient.toString() == expd.toString());
    testContext = popContext();
    writeln("passed");
}


unittest {
    write("div-int......");
    Decimal op1, op2, actual, expect;
    op1 = 2;
    op2 = 3;
    actual = divideInteger(op1, op2, testContext);
    expect = 0;
    assert(actual == expect);
    op1 = 10;
    actual = divideInteger(op1, op2, testContext);
    expect = 3;
    assert(actual == expect);
    op1 = 1;
    op2 = 0.3;
    actual = divideInteger(op1, op2, testContext);
    assert(actual == expect);
    writeln("passed");
}

unittest {
    write("remainder....");
    Decimal op1, op2, actual, expect;
    op1 = 2.1;
    op2 = 3;
    actual = remainder(op1, op2, testContext);
    expect = 2.1;
    assert(actual == expect);
    op1 = 10;
    actual = remainder(op1, op2, testContext);
    expect = 1;
    assert(actual == expect);
    op1 = -10;
    actual = remainder(op1, op2, testContext);
    expect = -1;
    assert(actual == expect);
    op1 = 10.2;
    op2 = 1;
    actual = remainder(op1, op2, testContext);
    expect = 0.2;
    assert(actual == expect);
    op1 = 10;
    op2 = 0.3;
    actual = remainder(op1, op2, testContext);
    expect = 0.1;
    assert(actual == expect);
    op1 = 3.6;
    op2 = 1.3;
    actual = remainder(op1, op2, testContext);
    expect = 1.0;
    assert(actual == expect);
    writeln("passed");
}

unittest {
    write("rem-near.....");
    writeln("test missing");
}

unittest {
    write("rnd-int-ex...");
    Decimal num, expect, actual;
    num = 2.1;
    expect = 2;
    actual = roundToIntegralExact(num, testContext);
    assert(actual == expect);
    num = 100;
    expect = 100;
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = Decimal("100.0");
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = Decimal("101.5");
    expect = 102;
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = -101.5;
    expect = -102;
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = Decimal("10E+5");
    expect = Decimal("1.0E+6");
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = 7.89E+77;
    expect = 7.89E+77;
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    num = Decimal("-Inf");
    expect = Decimal("-Infinity");
    assert(roundToIntegralExact(num, testContext) == expect);
    assert(roundToIntegralExact(num, testContext).toString() == expect.toString());
    writeln("passed");
}

unittest {
    write("rnd-int-val..");
    writeln("test missing");
}

unittest {
    write("reduceToIdeal...");
    writeln("test missing");
}

unittest {
    write("invalid......");
    Decimal num, expect, actual;

    // FIXTHIS: Can't actually test payloads at this point.
    num = Decimal("sNaN123");
    expect = Decimal("NaN123");
    actual = abs!Decimal(num, testContext);
    assert(actual.isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);
    num = Decimal("NaN123");
    actual = abs(num, testContext);
    assert(actual.isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);

    num = Decimal("sNaN123");
    expect = Decimal("NaN123");
    actual = -num;
    assert(actual.isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);
    num = Decimal("NaN123");
    actual = -num;
    assert(actual.isQuiet);
    assert(testContext.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);*/
    writeln("passed");
}

unittest {
    write("alignOps...");
    writeln("test missing");
}

unittest {
    write("isInvalidBinaryOp...");
    writeln("test missing");
}

unittest {
    write("invalidOperand...");
    writeln("test missing");
}

unittest {
    write("isInvalidAddition...");
    writeln("test missing");
}

unittest {
    write("isInvalidMultiplication...");
    writeln("test missing");
}

unittest {
    write("isInvalidDivision...");
    writeln("test missing");
}

unittest {
    write("isZeroDividend...");
    writeln("test missing");
}

unittest {
    writeln("---------------------");
    writeln("arithmetic...finished");
    writeln("---------------------");
}

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
/*    context.precision = 5;*/
}

unittest {
    writeln("---------------------");
    writeln("digits.......finished");
    writeln("---------------------");
    writeln("rounding......testing");
    writeln("---------------------");
}

unittest {
    write("round..........");
    Decimal before = Decimal(9999);
    Decimal after = before;
    pushContext(testContext);
    testContext.precision = 3;
    round(after, testContext);
    assert(after.toString() == "1.00E+4");
    before = Decimal(1234567890);
    after = before;
    testContext.precision = 3;
    round(after, testContext);;
    assert(after.toString() == "1.23E+9");
    after = before;
    testContext.precision = 4;
    round(after, testContext);;
    assert(after.toString() == "1.235E+9");
    after = before;
    testContext.precision = 5;
    round(after, testContext);;
    assert(after.toString() == "1.2346E+9");
    after = before;
    testContext.precision = 6;
    round(after, testContext);;
    assert(after.toString() == "1.23457E+9");
    after = before;
    testContext.precision = 7;
    round(after, testContext);;
    assert(after.toString() == "1.234568E+9");
    after = before;
    testContext.precision = 8;
    round(after, testContext);;
    assert(after.toString() == "1.2345679E+9");
    before = 1235;
    after = before;
    testContext.precision = 3;
    round(after, testContext);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12359;
    after = before;
    testContext.precision = 3;
    round(after, testContext);;
    assert(after.toAbstract() == "[0,124,2]");
    before = 1245;
    after = before;
    testContext.precision = 3;
    round(after, testContext);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12459;
    after = before;
    testContext.precision = 3;
    round(after, testContext);;
    assert(after.toAbstract() == "[0,125,2]");
    testContext = popContext;
    writeln("passed");
}

/*unittest {
    write("roundByMode....");
//    DecimalContext context;
    context.precision = 5;
    context.mode = Rounding.HALF_EVEN;
    Decimal num;
    num = 1000;
    roundByMode(num, context);
    assert(num.mant == 1000 && num.expo == 0 && num.digits == 4);
    num = 1000000;
    roundByMode(num, context);
    assert(num.mant == 10000 && num.expo == 2 && num.digits == 5);
    num = 99999;
    roundByMode(num, context);
    assert(num.mant == 99999 && num.expo == 0 && num.digits == 5);
    num = 1234550;
    roundByMode(num, context);
    assert(num.mant == 12346 && num.expo == 2 && num.digits == 5);
    context.mode = Rounding.DOWN;
    num = 1234550;
    roundByMode(num, context);
    assert(num.mant == 12345 && num.expo == 2 && num.digits == 5);
    context.mode = Rounding.UP;
    num = 1234550;
    roundByMode(num, context);
    assert(num.mant == 12346 && num.expo == 2 && num.digits == 5);
    writeln("passed");
}*/

/*unittest {
    write("getRemainder...");
    pushContext(context);
    context.precision = 5;
    Decimal num, acrem, exnum, exrem;
    num = Decimal(1234567890123456L);
    acrem = getRemainder(num, context);
    exnum = Decimal("1.2345E+15");
    assert(num == exnum);
    exrem = 67890123456;
    assert(acrem == exrem);
    context = popContext();
    writeln("passed");
}*/

/*unittest {
    write("increment......");
    Decimal num;
    Decimal expd;
    num = 10;
    expd = 11;
    increment(num);
    assert(num == expd);
    num = 19;
    expd = 20;
    increment(num);
    assert(num == expd);
    num = 999;
    expd = 1000;
    increment(num);
    assert(num == expd);
    writeln("passed");
    writeln("---------------------");
}*/

unittest {
    write("setExponent....");
    pushContext(testContext);
    testContext.precision = 5;
    testContext.mode = Rounding.HALF_EVEN;
    long num; uint digits; int expo;
    num = 1000;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 1000 && expo == 0 && digits == 4);
    num = 1000000;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 10000 && expo == 2 && digits == 5);
    num = 99999;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 99999 && expo == 0 && digits == 5);
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 12346 && expo == 2 && digits == 5);
    testContext.mode = Rounding.DOWN;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 12345 && expo == 2 && digits == 5);
    testContext.mode = Rounding.UP;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, testContext);
    assert(num == 12346 && expo == 2 && digits == 5);
    testContext = popContext;
    writeln("passed");
}

/*unittest {
    write("getRemainder...");
    ulong num, acrem, exnum, exrem;
    uint digits, precision;
    num = 1234567890123456L;
    digits = 16; precision = 5;
    acrem = getRemainder(num, digits, precision);
    exnum = 12345L;
    assert(num == exnum);
    exrem = 67890123456L;
    assert(acrem == exrem);
    writeln("passed");
}*/

/*unittest {
    write("increment......");
    ulong num;
    uint digits;
    ulong expd;
    num = 10;
    expd = 11;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expd);
    assert(digits == 2);
    num = 19;
    expd = 20;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expd);
    assert(digits == 2);
    num = 999;
    expd = 1000;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expd);
    assert(digits == 4);
    writeln("passed");
}
*/
unittest {
    writeln("---------------------");
    writeln("rounding.....finished");
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
    Decimal num = Decimal(0);
    Dec32 dec = Dec32(num);
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
+/

