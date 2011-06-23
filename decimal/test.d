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

alias Decimal.context.precision precision;*/

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
    Decimal f;
    string str = "0";
    f = Decimal(str);
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
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = 2.17;
    op2 = 0.01;
    expd = 2.17;
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = 2.17;
    op2 = 0.1;
    expd = 2.2;
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = 2.17;
    op2 = Decimal("1E+0");
    expd = 2;
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = 2.17;
    op2 = Decimal("1E+1");
    expd = Decimal("0E+1");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-Inf");
    op2 = Decimal("Infinity");
    expd = Decimal("-Infinity");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = 2;
    op2 = Decimal("Infinity");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = -0.1;
    op2 = 1;
    expd = Decimal("-0");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-0");
    op2 = Decimal("1E+5");
    expd = Decimal("-0E+5");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("+35236450.6");
    op2 = Decimal("1E-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-35236450.6");
    op2 = Decimal("1E-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E-1");
    expd = Decimal("217.0");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+0");
    expd = Decimal("217");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+1");
    expd = Decimal("2.2E+2");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1E+2");
    expd = Decimal("2E+2");
    result = quantize(op1, op2, context);
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
    assert(logb(num, context) == expd);
    num = Decimal("2.50");
    expd = Decimal("0");
    assert(logb(num, context) == expd);
    num = Decimal("0.03");
    expd = Decimal("-2");
    assert(logb(num, context) == expd);
    num = Decimal("0");
    expd = Decimal("-Infinity");
    assert(logb(num, context) == expd);
    writeln("passed");
}

unittest {
    write("scaleb.......");
    Decimal op1, op2, expd;
    op1 = Decimal("7.50");
    op2 = Decimal("-2");
    expd = Decimal("0.0750");
    assert(scaleb(op1, op2, context) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("0");
    expd = Decimal("7.50");
    assert(scaleb(op1, op2, context) == expd);
    op1 = Decimal("7.50");
    op2 = Decimal("3");
    expd = Decimal("7.50E+3");
    assert(scaleb(op1, op2, context) == expd);
    op1 = Decimal("-Infinity");
    op2 = Decimal("4.5");
    expd = Decimal("-Infinity");
    assert(scaleb(op1, op2, context) == expd);
    writeln("passed");
}

unittest {
    write("reduce.......");
    Decimal num;
    Decimal red;
    string str;
    num = Decimal("2.1");
    str = "2.1";
    red = reduce(num, context);
    assert(red.toString() == str);
    num = Decimal("-2.0");
    str = "-2";
    red = reduce(num, context);
    assert(red.toString() == str);
    num = Decimal("1.200");
    str = "1.2";
    red = reduce(num, context);
    assert(red.toString() == str);
    num = Decimal("-120");
    str = "-1.2E+2";
    red = reduce(num, context);
    assert(red.toString() == str);
    num = Decimal("120.00");
    str = "1.2E+2";
    red = reduce(num, context);
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
    assert(abs(num, context).isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    num = Decimal("NaN");
    assert(abs(num, context).isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
    num = Decimal("Inf");
    expd = Decimal("Inf");
    assert(abs(num, context) == expd);
    num = Decimal("-Inf");
    expd = Decimal("Inf");
    assert(abs(num, context) == expd);
    num = Decimal("0");
    expd = Decimal("0");
    assert(abs(num, context) == expd);
    num = Decimal("-0");
    expd = Decimal("0");
    assert(abs(num, context) == expd);
    num = Decimal("2.1");
    expd = Decimal("2.1");
    assert(abs(num, context) == expd);
    num = -100;
    expd = 100;
    assert(abs(num, context) == expd);
    num = 101.5;
    expd = 101.5;
    assert(abs(num, context) == expd);
    num = -101.5;
    assert(abs(num, context) == expd);
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
    writeln("---------------------");
    writeln("arithmetic...finished");
    writeln("---------------------");
}

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
    DecimalContext context;
    context.precision = 5;
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
    pushContext(context);
    context.precision = 3;
    round(after, context);
    assert(after.toString() == "1.00E+4");
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
    before = 1235;
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12359;
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,2]");
    before = 1245;
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12459;
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,125,2]");
    context = popContext();
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
    DecimalContext context;
    context.precision = 5;
    context.mode = Rounding.HALF_EVEN;
    long num; uint digits; int expo;
    num = 1000;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 1000 && expo == 0 && digits == 4);
    num = 1000000;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 10000 && expo == 2 && digits == 5);
    num = 99999;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 99999 && expo == 0 && digits == 5);
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 12346 && expo == 2 && digits == 5);
    context.mode = Rounding.DOWN;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 12345 && expo == 2 && digits == 5);
    context.mode = Rounding.UP;
    num = 1234550;
    digits = numDigits(num);
    expo = setExponent(num, digits, context);
    assert(num == 12346 && expo == 2 && digits == 5);
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


