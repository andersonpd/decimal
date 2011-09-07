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
import std.stdio;
import decimal.arithmetic;
import decimal.context;
import decimal.decimal;
import decimal.dec32;
import decimal.rounding;
import decimal.conv;

unittest {
    writeln("-------------------");
    writeln("test........testing");
    writeln("-------------------");
}

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


bool expectEquals(T)(T expected, T actual,
        string file = __FILE__, int line = __LINE__ ) {
    if (expected == actual) {
        return true;
    }
    writeln("failed at ", std.path.basename(file), "(", line, "):",
//             " (", expected, " == ", actual, ")");
            " expected \"", expected, "\"",
            " but found \"", actual, "\".");
    return false;
}

bool expectTrue(bool actual, string file = __FILE__, int line = __LINE__ ) {
    return expectEquals(true, actual, file, line);
}


unittest {
	writeln("test...");
    expectEquals(1,2);
    expectTrue(false);
	writeln("test missing");
}

//--------------------------------
// unit tests
//--------------------------------

unittest {
    bool passed = true;
    long n = 12345;
    Test!long.isEqual!uint(lastDigit(n), 5, "digits 1");
    Test!long.isEqual(numDigits(n), 5, "digits 2");
    Test!long.isEqual(firstDigit(n), 1, "digits 3");
    Test!long.isEqual(firstDigit(n), 8, "digits 4");
    BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    Test!long.isEqual!uint(lastDigit(big), 5, "digits 5");
    Test!long.isEqual(numDigits(big), 101, "digits 6");
    Test!long.isEqual(numDigits(big), 22, "digits 7");
    Test!long.isEqual(firstDigit(n), 1, "digits 8");
//    assert(lastDigit(big) == 5);
//    assert(numDigits(big) == 101);
//    assert(firstDigit(big) == 1);
}

private DecimalContext testContext = DecimalContext();

unittest {
    writeln("---------------------");
    writeln("conversion....testing");
    writeln("---------------------");
}

unittest {
    write("toDecimal...");
    Dec32 small;
    Decimal big;
    small = 5;
    big = toDecimal!Dec32(small);
    assert(big.toString == small.toString);
    writeln("passed");
}

unittest {
    write("isDecimal(T)...");
    assert(isSmallDecimal!Dec32);
    assert(!isSmallDecimal!Decimal);
    assert(isDecimal!Dec32);
    assert(isDecimal!Decimal);
    assert(!isBigDecimal!Dec32);
    assert(isBigDecimal!Decimal);
    writeln("passed");
}

unittest {
    write("to-sci-str...");
    Dec32 num = Dec32(123); //(false, 123, 0);
    assert(toSciString!Dec32(num) == "123");
    assert(num.toAbstract() == "[0,123,0]");
    writeln("num = ", num);
    writeln("num.toAbstract = ", num.toAbstract);
    num = Dec32(-123, 0);
    writeln("num = ", num);
    writeln("num.toAbstract = ", num.toAbstract);
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
    num = Dec32(123, -5);
    assert(toSciString!Dec32(num) == "0.00123");
    assert(num.toAbstract() == "[0,123,-5]");
    num = Dec32(123, -10);
    assert(toSciString!Dec32(num) == "1.23E-8");
    assert(num.toAbstract() == "[0,123,-10]");
    num = Dec32(-123, -12);
    assert(toSciString!Dec32(num) == "-1.23E-10");
    assert(num.toAbstract() == "[1,123,-12]");
    num = Dec32(0, 0);
    assert(toSciString!Dec32(num) == "0");
    assert(num.toAbstract() == "[0,0,0]");
    num = Dec32(0, -2);
    assert(toSciString!Dec32(num) == "0.00");
    assert(num.toAbstract() == "[0,0,-2]");
    num = Dec32(0, 2);
    assert(toSciString!Dec32(num) == "0E+2");
    assert(num.toAbstract() == "[0,0,2]");
/*    num = -Dec32(0, 0);
    assert(toSciString!Dec32(num) == "-0");
    assert(num.toAbstract() == "[1,0,0]");*/
    num = Dec32(5, -6);
    assert(toSciString!Dec32(num) == "0.000005");
    assert(num.toAbstract() == "[0,5,-6]");
    num = Dec32(50,-7);
    assert(toSciString!Dec32(num) == "0.0000050");
    assert(num.toAbstract() == "[0,50,-7]");
    num = Dec32(5, -7);
    assert(toSciString!Dec32(num) == "5E-7");
    assert(num.toAbstract() == "[0,5,-7]");
    writeln("-------");
    num = Dec32("inf");
    writeln("num = ", num);
    writeln("num.toAbstract = ", num.toAbstract);
    assert(toSciString!Dec32(num) == "Infinity");
    assert(num.toAbstract() == "[0,inf]");
/*    num = Dec32(true, SV.INF);
    assert(toSciString!Dec32(num) == "-Infinity");
    assert(num.toAbstract() == "[1,inf]");
    num = Dec32(false, SV.QNAN);
    assert(toSciString!Dec32(num) == "NaN");
    assert(num.toAbstract() == "[0,qNaN]");*/
    // TODO: This test doesn't pass because we the payload setter won't compile.
//    num = Dec32(false, SV.QNAN, 123);
//    assert(toSciString!Dec32(num) == "NaN123");
//    assert(num.toAbstract() == "[0,qNaN,123]");
/*    num = Dec32(true, SV.SNAN);
    assert(toSciString!Dec32(num) == "-sNaN");
    assert(num.toAbstract() == "[1,sNaN]");*/
    writeln("passed");
}

unittest {
    write("to-eng-str...");
    string str = "1.23E+3";
    Decimal num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "123E+3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "12.3E-9";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "-123E-12";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "700E-9";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "70";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0E-9";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.00E-6";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.0E-6";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.000000";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
/*    str = "0.00E-3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.0E-3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);*/
    str = "0.000";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.00";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.0";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.00E+3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.0E+3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0E+3";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.00E+6";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.0E+6";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0E+6";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    str = "0.00E+9";
    num = Decimal(str);
    assert(toEngString!Decimal(num) == str);
    writeln("passed");
}

unittest {
//    write("to-number....");
    string title = "toNumber";
    uint passed = 0;
    uint failed = 0;
    Decimal f;
    string str = "0";
    f = Decimal(str);
    expectEquals(f.toString(), str) ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,0,0]") ? passed++ : failed++;
    str = "0.00";
    f = Decimal(str);
    expectEquals(f.toString(), str) ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,0,-2]") ? passed++ : failed++;
    str = "0.0";
    f = Decimal(str);
    expectEquals(f.toString(), str) ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,0,-1]") ? passed++ : failed++;
    f = Decimal("0.");
    expectEquals(f.toString(), "0") ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,0,0]") ? passed++ : failed++;
    f = Decimal(".0");
    expectEquals(f.toString(), "0.0") ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,0,-1]") ? passed++ : failed++;
    str = "1.0";
    f = Decimal(str);
    expectEquals(f.toString(), str) ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,10,-1]") ? passed++ : failed++;
    str = "1.";
    f = Decimal(str);
    expectEquals(f.toString(), "1") ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,1,0]") ? passed++ : failed++;
    str = ".1";
    f = Decimal(str);
    expectEquals(f.toString(), "0.1") ? passed++ : failed++;
    expectEquals(f.toAbstract(), "[0,1,-1]") ? passed++ : failed++;
    f = Decimal("123");
    expectEquals(f.toString(), "123") ? passed++ : failed++;
    f = Decimal("-123");
    expectEquals(f.toString(), "-123") ? passed++ : failed++;
    f = Decimal("1.23E3");
    expectEquals(f.toString(), "1.23E+3") ? passed++ : failed++;
    f = Decimal("1.23E");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("1.23E-");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("1.23E+");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("1.23E+3");
    expectEquals(f.toString(), "1.23E+3") ? passed++ : failed++;
    f = Decimal("1.23E3B");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("12.3E+007");
    expectEquals(f.toString(), "1.23E+8") ? passed++ : failed++;
    f = Decimal("12.3E+70000000000");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("12.3E+7000000000");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("12.3E+700000000");
    expectEquals(f.toString(), "1.23E+700000001") ? passed++ : failed++;
    f = Decimal("12.3E-700000000");
    expectEquals(f.toString(), "1.23E-699999999") ? passed++ : failed++;
    // NOTE: since there will still be adjustments -- maybe limit to 99999999?
    f = Decimal("12.0");
    expectEquals(f.toString(), "12.0") ? passed++ : failed++;
    f = Decimal("12.3");
    expectEquals(f.toString(), "12.3") ? passed++ : failed++;
    f = Decimal("1.23E-3");
    expectEquals(f.toString(), "0.00123") ? passed++ : failed++;
    f = Decimal("0.00123");
    expectEquals(f.toString(), "0.00123") ? passed++ : failed++;
    f = Decimal("-1.23E-12");
    expectEquals(f.toString(), "-1.23E-12") ? passed++ : failed++;
    f = Decimal("-0");
    expectEquals(f.toString(), "-0") ? passed++ : failed++;
    f = Decimal("inf");
    expectEquals(f.toString(), "Infinity") ? passed++ : failed++;
    f = Decimal("NaN");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    f = Decimal("-NaN");
    expectEquals(f.toString(), "-NaN") ? passed++ : failed++;
    f = Decimal("sNaN");
    expectEquals(f.toString(), "sNaN") ? passed++ : failed++;
    f = Decimal("Fred");
    expectEquals(f.toString(), "NaN") ? passed++ : failed++;
    writefln("unittest %s: passed %d; failed %d", title, passed, failed);
}

unittest {
    writeln("---------------------");
    writeln("conversion...finished");
    writeln("---------------------");
}

unittest {
    writeln("---------------------");
    writeln("arithmetic....testing");
    writeln("---------------------");
}

unittest {
    string title = "radix";
    uint passed = 0;
    uint failed = 0;
    expectEquals(radix, 10) ? passed++ : failed++;
    writefln("unittest %s: passed %d; failed %d", title, passed, failed);
}

unittest {
    write("class........");
    Decimal num;
    num = Decimal("Infinity");
    expectEquals(classify(num), "+Infinity");
    num = Decimal("1E-10");
    expectEquals(classify(num), "+Normal");
    num = Decimal("2.50");
    expectEquals(classify(num), "+Normal");
    num = Decimal("0.1E-99");
    expectEquals(classify(num), "+Subnormal");
    num = Decimal("0");
    expectEquals(classify(num), "+Zero");
    num = Decimal("-0");
    expectEquals(classify(num), "-Zero");
    num = Decimal("-0.1E-99");
    expectEquals(classify(num), "-Subnormal");
    num = Decimal("-1E-10");
    expectEquals(classify(num), "-Normal");
    num = Decimal("-2.50");
    expectEquals(classify(num), "-Normal");
    num = Decimal("-Infinity");
    expectEquals(classify(num), "-Infinity");
    num = Decimal("NaN");
    expectEquals(classify(num), "NaN");
    num = Decimal("-NaN");
    expectEquals(classify(num), "NaN");
    num = Decimal("sNaN");
    expectEquals(classify(num), "sNaN");
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
    assert(abs(num, testContext).isQuiet);  // converted to quiet Nan per spec.
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
    num = Decimal("-Infinity");
    expect = Decimal("-9.99999999E+999");
    assert(nextPlus(num, testContext) == expect);
    testContext = popContext;
    writeln("passed");
}

unittest {
    write("next-minus...");
    pushContext(testContext);
//    testContext.eMin = -999;
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
    writeln("Decimal.......testing");
    writeln("---------------------");
}

unittest {
    write("this().......");
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
    num = Decimal(SV.INF, true);
    assert(num.toSciString == "-Infinity");
    assert(num.toAbstract() == "[1,inf]");
    num = Decimal(true, BigInt(7254), 94);
    assert(num.toString == "-7.254E+97");
    num = Decimal(BigInt(7254), 94);
    assert(num.toString == "7.254E+97");
    num = Decimal(BigInt(-7254));
    assert(num.toString == "-7254");
    num = Decimal(1234L, 567);
    assert(num.toString() == "1.234E+570");
    num = Decimal(1234, 567);
    assert(num.toString() == "1.234E+570");
    num = Decimal(1234L);
    assert(num.toString() == "1234");
    num = Decimal(123400L);
    assert(num.toString() == "123400");
    num = Decimal(1234L);
    assert(num.toString() == "1234");
    writeln("passed");
}

unittest {
    write("dup..........");
    Decimal num = Decimal(std.math.PI);
    Decimal copy = num.dup;
    assert(num == copy);
    writeln("passed");
}

unittest {
    write("toString.....");
    Decimal f = Decimal(1234L, 567);
    f = Decimal(1234, 567);
    assert(f.toString() == "1.234E+570");
    f = Decimal(1234L);
    assert(f.toString() == "1234");
    f = Decimal(123400L);
    assert(f.toString() == "123400");
    f = Decimal(1234L);
    assert(f.toString() == "1234");
    writeln("passed");
}

unittest {
    write("opAssign.....");
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
    writeln("passed");
    num = Dec32.max;
    str = "9.999999E+96";
    assert(num.toString == str);
}

unittest {
    write("toAbstract...");
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
    writeln("passed");
}

unittest {
    write("toString.....");
    Decimal num;
    string str;
    num = Decimal(200000, 71);
    str = "2.00000E+76";
    assert(num.toString == str);
    writeln("passed");
}

unittest {
    write("canonical....");
    Decimal num = Decimal("2.50");
    assert(num.isCanonical);
    Decimal copy = num.canonical;
    assert(compareTotal(num, copy) == 0);
    writeln("passed");
}

unittest {
	write("special values...");
    Decimal num;
    num = Decimal.NAN;
    assert(num.toString == "NaN");
    num = Decimal.SNAN;
    assert(num.toString == "sNaN");
    assert("Decimal(SV.QNAN).toAbstract = ", Decimal.NAN.toAbstract);
    num = Decimal.NEG_ZERO;
    assert(num.toString == "-0");
	writeln("passed");
}

unittest {
    write("toExact...");
    Decimal num;
    assert(num.toExact == "+NaN");
    num = +9999999E+90;
    assert(num.toExact == "+9999999E+90");
    num = 1;
    assert(num.toExact == "+1E+00");
    num = Decimal.infinity(true);
    assert(num.toExact == "-Infinity");
    writeln("passed");
}

unittest {
    write("canonical....");
    Decimal num = Decimal("2.50");
    assert(num.isCanonical);
    writeln("passed");
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

unittest {
    write("isSpecial....");
    Decimal num;
    num = Decimal.infinity(true);
    assert(num.isSpecial);
    num = Decimal.snan(1234);
    assert(num.isSpecial);
    num = 12378.34;
    assert(!num.isSpecial);
    writeln("passed");
}

unittest {
    write("isIntegral...");
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
    writeln("passed");
}

unittest {
    writeln("-------------------");
    writeln("Decimal....finished");
    writeln("-------------------");
}

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
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

unittest {
    write("numDigits......");
    BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    assert(numDigits(big) == 101);
    writeln("passed");
}

unittest {
    write("firstDigit.....");
    BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    assert(firstDigit(big) == 8);
    writeln("passed");
}

unittest {
    write("decShl.........");
    BigInt m;
    int n;
    m = 12345;
    n = 2;
//    writeln("decShl(m,n) = ", decShl(m,n));
    assert(decShl(m,n) == 1234500);
    m = 1234567890;
    n = 7;
    assert(decShl(m,n) == BigInt(12345678900000000));
    m = 12;
    n = 2;
    assert(decShl(m,n) == 1200);
    m = 12;
    n = 4;
    assert(decShl(m,n) == 120000);
    writeln("passed");
}

unittest {
    write("decShr.........");
    BigInt m;
    int n;
    m = 12345;
    n = 2;
    assert(decShr(m,n) == 123);
    m = 12345678901234567;
    n = 7;
    assert(decShr(m,n) == 1234567890);
    m = 12;
    n = 2;
    assert(decShr(m,n) == 0);
    m = 12;
    n = 4;
    assert(decShr(m,n) == 0);
    m = long.max;
    n = 18;
    assert(decShr(m,n) == 9);
    writeln("passed");
}

unittest {
    write("lastDigit......");
    BigInt n;
    n = 7;
    assert(lastDigit(n) == 7);
    n = -13;
    assert(lastDigit(n) == 3);
    n = 999;
    assert(lastDigit(n) == 9);
    n = -9999;
    assert(lastDigit(n) == 9);
    n = 25987;
    assert(lastDigit(n) == 7);
    n = -5008615;
    assert(lastDigit(n) == 5);
    n = 3234567893;
    assert(lastDigit(n) == 3);
    n = -10000000000;
    assert(lastDigit(n) == 0);
    n = 823456789012348;
    assert(lastDigit(n) == 8);
    n = 4234567890123456;
    assert(lastDigit(n) == 6);
    n = 623456789012345674;
    assert(lastDigit(n) == 4);
    n = long.max;
    assert(lastDigit(n) == 7);
    writeln("passed");
}

unittest {
    write("decShr.........");
    long m;
    int n;
    m = 12345;
    n = 2;
    assert(decShr(m,n) == 123);
    m = 12345678901234567;
    n = 7;
    assert(decShr(m,n) == 1234567890);
    m = 12;
    n = 2;
    assert(decShr(m,n) == 0);
    m = 12;
    n = 4;
    assert(decShr(m,n) == 0);
    m = long.max;
    n = 18;
    assert(decShr(m,n) == 9);
    writeln("passed");
}

unittest {
    write("decShl.........");
    long m;
    int n;
    m = 12345;
    n = 2;
    assert(decShl(m,n) == 1234500);
    m = 1234567890;
    n = 7;
    assert(decShl(m,n) == 12345678900000000);
    m = 12;
    n = 2;
    assert(decShl(m,n) == 1200);
    m = 12;
    n = 4;
    assert(decShl(m,n) == 120000);
/*    m = long.max;
    n = 18;
    assert(decShl(m,n) == 9);*/
    writeln("passed");
}

unittest {
    write("lastDigit......");
    long n;
    n = 7;
    assert(lastDigit(n) == 7);
    n = -13;
    assert(lastDigit(n) == 3);
    n = 999;
    assert(lastDigit(n) == 9);
    n = -9999;
    assert(lastDigit(n) == 9);
    n = 25987;
    assert(lastDigit(n) == 7);
    n = -5008615;
    assert(lastDigit(n) == 5);
    n = 3234567893;
    assert(lastDigit(n) == 3);
    n = -10000000000;
    assert(lastDigit(n) == 0);
    n = 823456789012348;
    assert(lastDigit(n) == 8);
    n = 4234567890123456;
    assert(lastDigit(n) == 6);
    n = 623456789012345674;
    assert(lastDigit(n) == 4);
    n = long.max;
    assert(lastDigit(n) == 7);
    writeln("passed");
}

unittest {
    write("firstDigit.....");
    long n;
    n = 7;
    assert(firstDigit(n) == 7);
    n = -13;
    assert(firstDigit(n) == 1);
    n = 999;
    assert(firstDigit(n) == 9);
    n = -9999;
    assert(firstDigit(n) == 9);
    n = 25987;
    assert(firstDigit(n) == 2);
    n = -5008617;
    assert(firstDigit(n) == 5);
    n = 3234567890;
    assert(firstDigit(n) == 3);
    n = -10000000000;
    assert(firstDigit(n) == 1);
    n = 823456789012345;
    assert(firstDigit(n) == 8);
    n = 4234567890123456;
    assert(firstDigit(n) == 4);
    n = 623456789012345678;
    assert(firstDigit(n) == 6);
    n = long.max;
    assert(firstDigit(n) == 9);
    writeln("passed");
}

unittest {
    write("numDigits......");
    long n;
    n = 7;
    assert(numDigits(n) ==  1);
    n = -13;
    assert(numDigits(n) ==  2);
    n = 999;
    assert(numDigits(n) ==  3);
    n = -9999;
    assert(numDigits(n) ==  4);
    n = 25987;
    assert(numDigits(n) ==  5);
    n = -2008617;
    assert(numDigits(n) ==  7);
    n = 1234567890;
    assert(numDigits(n) == 10);
    n = -10000000000;
    assert(numDigits(n) == 11);
    n = 123456789012345;
    assert(numDigits(n) == 15);
    n = 1234567890123456;
    assert(numDigits(n) == 16);
    n = 123456789012345678;
    assert(numDigits(n) == 18);
    n = long.max;
    assert(numDigits(n) == 19);
    writeln("passed");
}

/*unittest {
    write("roundByMode....");
//    DecimalContext context;
    context.precision = 5;
    context.rounding = Rounding.HALF_EVEN;
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
    context.rounding = Rounding.DOWN;
    num = 1234550;
    roundByMode(num, context);
    assert(num.mant == 12345 && num.expo == 2 && num.digits == 5);
    context.rounding = Rounding.UP;
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
    testContext.rounding = Rounding.HALF_EVEN;
    ulong num; uint digits; int expo;
    num = 1000;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
    assert(num == 1000 && expo == 0 && digits == 4);
    num = 1000000;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
    assert(num == 10000 && expo == 2 && digits == 5);
    num = 99999;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
    assert(num == 99999 && expo == 0 && digits == 5);
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
    assert(num == 12346 && expo == 2 && digits == 5);
    testContext.rounding = Rounding.DOWN;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
    assert(num == 12345 && expo == 2 && digits == 5);
    testContext.rounding = Rounding.UP;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(false, num, digits, testContext);
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
    num = Dec32(0);
    assert(num.toString == "0");
    num = Dec32(1);
    assert(num.toString == "1");
    num = Dec32(-1);
    assert(num.toString == "-1");
    num = Dec32(5);
    assert(num.toString == "5");
    writeln("passed");
}

unittest {
    writeln("this(long, int)....");
    Dec32 num;
    num = Dec32(1234567890L, 5);
    assert(num.toString == "1.234568E+14");
    num = Dec32(0, 2);
    assert(num.toString == "0E+2");
    num = Dec32(1, 75);
    assert(num.toString == "1E+75");
    num = Dec32(-1, -75);
    assert(num.toString == "-1E-75");
    num = Dec32(5, -3);
    assert(num.toString == "0.005");
    writeln("passed");
}

// TODO: is there a this(BigInt)?
// should there be?
/*unittest {
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
    writeln("passed");
}*/

unittest {
	write("this(Decimal)...");
    Decimal dec = 0;
    Dec32 num = dec;
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
    assert(num.toString == "4.294967E+9");
    assert(dec.toString == "4294967295");
    dec = 9999999E+12;
    num = dec;
    assert(dec.toString == num.toString);
	writeln("passed");
}

unittest {
    write("this(str)....");
    Dec32 num;
    num = Dec32("1.234568E+9");
    assert(num.toString == "1.234568E+9");
    num = Dec32("NaN");
    assert(num.isQuiet && num.isSpecial && num.isNaN);
    num = Dec32("-inf");
    assert(num.isInfinite && num.isSpecial && num.isNegative);
    writeln("passed");
}

unittest {
    write("this(real)....");
    real r = 1.2345E+16;
    Dec32 actual = Dec32(r);
    Dec32 expect = Dec32("1.2345E+16");
    assert(expect == actual);
    writeln("passed");
}

unittest {
     write("coefficient...");
    Dec32 num;
    assert(num.coefficient == 0);
    num = 9.998743;
    assert(num.coefficient == 9998743);
    num = Dec32(9999213,-6);
    assert(num.coefficient == 9999213);
    num = -125;
    assert(num.coefficient == 125);
    num = 99999999;
    assert(num.coefficient == 1000000);
    // TODO: test explicit, implicit, nan and infinity.
    writeln("passed");
}

unittest {
	write("exponent...");
    Dec32 num;
    // reals
    num = std.math.PI;
    assert(num.exponent = -6);
    num = 9.75E89;
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

    num = Dec32(-12000,5);
    num.exponent = 10;
    assert(num.exponent == 10);
    num = Dec32(-9000053,-14);
    num.exponent = -27;
    assert(num.exponent == -27);
    num = Dec32.infinity;
    assert(num.exponent == 0);
    // (4) TODO: test overflow and underflow.
    writeln("passed");
}

unittest {
 write("payload...");
    Dec32 num;
    assert(num.payload == 0);
    num = Dec32.snan;
    assert(num.payload == 0);
    num.payload = 234;
    assert(num.payload == 234);
    assert(num.toString == "sNaN234");
    num = 1234567;
    assert(num.payload == 0);
 writeln("passed");
}

unittest {
    write("opCmp........");
    Dec32 a, b;
    a = Dec32(104.0);
    b = Dec32(105.0);
    assert(a < b);
    assert(b > a);
    writeln("passed");
}

unittest {
    write("opEquals.....");
    Dec32 a, b;
    a = Dec32(105);
    b = Dec32(105);
    assert(a == b);
    writeln("passed");
}

unittest {
    write("opAssign(Dec32)..");
    Dec32 rhs, lhs;
    rhs = Dec32(270E-5);
    lhs = rhs;
    assert(lhs == rhs);
    writeln("passed");
}

unittest {
    write("opAssign(numeric)...");
    Dec32 rhs;
    rhs = 332089;
    assert(rhs.toString == "332089");
    rhs = 3.1415E+3;
    assert(rhs.toString == "3141.5");
    writeln("passed");
}

unittest {
	write("opUnary......");
    Dec32 num, actual, expect;
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
    // TODO: seems to be broken for nums like 1.000E8
    num = 12.35;
    expect = 11.35;
    actual = --num;
    assert(actual == expect);
	writeln("passed");
}

unittest {
	write("opBinary.....");
    Dec32 op1, op2, actual, expect;
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
	writeln("passed");
}

unittest {
	write("opOpAssign...");
    Dec32 op1, op2, actual, expect;
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
	writeln("passed");
}

unittest {
    write("toDecimal...");
    Dec32 num = Dec32("12345E+17");
    Decimal expected = Decimal("12345E+17");
    Decimal actual = num.toDecimal;
    assert(actual == expected);
    writeln("passed");
}

unittest {
    write("toLong...");
    Dec32 num;
    num = -12345;
    assert(num.toLong == -12345);
    num = 2 * int.max;
    assert(num.toLong == 2 * int.max);
    num = 1.0E6;
    assert(num.toLong == 1000000);
    num = -1.0E60;
    assert(num.toLong == long.min);
    num = Dec32.infinity(true);
    assert(num.toLong == long.min);
    writeln("passed");
}

unittest {
    write("toInt...");
    Dec32 num;
    num = 12345;
    assert(num.toInt == 12345);
    num = 1.0E6;
    assert(num.toInt == 1000000);
    num = -1.0E60;
    assert(num.toInt == int.min);
    num = Dec32.infinity(true);
    assert(num.toInt == int.min);
    writeln("passed");
}

unittest {
    write("toString...");
    string str;
    str = "-12.345E-42";
    Dec32 num = Dec32(str);
    assert(num.toString == "-1.2345E-41");
    writeln("passed");
}

unittest {
    write("toAbstract...");
    Dec32 num;
    num = Dec32("-25.67E+2");
    assert(num.toAbstract == "[1,2567,0]");
    writeln("test missing");
}

unittest {
    write("toExact...");
    Dec32 num;
    assert(num.toExact == "+NaN");
    num = Dec32.max;
    assert(num.toExact == "+9999999E+90");
    num = 1;
    assert(num.toExact == "+0000001E+00");
    num = Dec32.infinity(true);
    assert(num.toExact == "-Infinity");
    writeln("passed");
}

unittest {
    write("pow10..........");
    assert(Dec32.pow10(3) == 1000);
    writeln("passed");
}

unittest {
	write("hexstring...");
    Dec32 num = 12345;
    assert(num.toHexString == "0x32803039");
    assert(num.toBinaryString == "00110010100000000011000000111001");
	writeln("passed");
}

unittest {
    writeln("---------------------");
    writeln("decimal32....finished");
    writeln("---------------------");
}

unittest {
    writeln("---------------------");
    writeln("test.........finished");
    writeln("---------------------");
}


