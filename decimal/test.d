/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */

/* Copyright Paul D. Anderson 2009 - 2012.
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 *  http://www.boost.org/LICENSE_1_0.txt)
 */

module decimal.test;


import std.bigint;
import std.stdio;
import decimal.arithmetic;
import decimal.context;
import decimal.conv;
import decimal.dec32;
import decimal.dec64;
import decimal.dec128;
import decimal.decimal;
import decimal.rounding;
import decimal.utils;

unittest {
	writeln("---------------------------");
	writeln("test................testing");
	writeln("---------------------------");
}


public void testDecimal() {

}
//--------------------------------
// unit tests
//--------------------------------

unittest {
	writeln("---------------------");
	writeln("conversion....testing");
	writeln("---------------------");
}

unittest {
	write("toBigDecimal...");
	Dec32 small;
	BigDecimal big;
	small = 5;
	big = toBigDecimal!Dec32(small);
	assertTrue(big.toString == small.toString);
	writeln("passed");
}

unittest {
	write("isDecimal(T)...");
	assertTrue(isFixedDecimal!Dec32);
	assertTrue(!isFixedDecimal!BigDecimal);
	assertTrue(isDecimal!Dec32);
	assertTrue(isDecimal!BigDecimal);
	assertTrue(!isBigDecimal!Dec32);
	assertTrue(isBigDecimal!BigDecimal);
	writeln("passed");
}

unittest {
	write("to-sci-str.....");
	Dec32 num = Dec32(123); //(false, 123, 0);
	assertTrue(sciForm!Dec32(num) == "123");
	assertTrue(num.toAbstract() == "[0,123,0]");
	num = Dec32(-123, 0);
	assertTrue(sciForm!Dec32(num) == "-123");
	assertTrue(num.toAbstract() == "[1,123,0]");
	num = Dec32(123, 1);
	assertTrue(sciForm!Dec32(num) == "1.23E+3");
	assertTrue(num.toAbstract() == "[0,123,1]");
	num = Dec32(123, 3);
	assertTrue(sciForm!Dec32(num) == "1.23E+5");
	assertTrue(num.toAbstract() == "[0,123,3]");
	num = Dec32(123, -1);

	assertTrue(sciForm!Dec32(num) == "12.3");
	assertTrue(num.toAbstract() == "[0,123,-1]");
	num = Dec32(123, -5);
	assertTrue(sciForm!Dec32(num) == "0.00123");
	assertTrue(num.toAbstract() == "[0,123,-5]");
	num = Dec32(123, -10);
	assertTrue(sciForm!Dec32(num) == "1.23E-8");
	assertTrue(num.toAbstract() == "[0,123,-10]");
	num = Dec32(-123, -12);
	assertTrue(sciForm!Dec32(num) == "-1.23E-10");
	assertTrue(num.toAbstract() == "[1,123,-12]");
	num = Dec32(0, 0);
	assertTrue(sciForm!Dec32(num) == "0");
	assertTrue(num.toAbstract() == "[0,0,0]");
	num = Dec32(0, -2);
	assertTrue(sciForm!Dec32(num) == "0.00");
	assertTrue(num.toAbstract() == "[0,0,-2]");
	num = Dec32(0, 2);
	assertTrue(sciForm!Dec32(num) == "0E+2");
	assertTrue(num.toAbstract() == "[0,0,2]");
	num = -Dec32(0, 0);
	assertTrue(sciForm!Dec32(num) == "-0");
	assertTrue(num.toAbstract() == "[1,0,0]");
	num = Dec32(5, -6);
	assertTrue(sciForm!Dec32(num) == "0.000005");
	assertTrue(num.toAbstract() == "[0,5,-6]");
	num = Dec32(50,-7);
	assertTrue(sciForm!Dec32(num) == "0.0000050");
	assertTrue(num.toAbstract() == "[0,50,-7]");
	num = Dec32(5, -7);
	assertTrue(sciForm!Dec32(num) == "5E-7");
	assertTrue(num.toAbstract() == "[0,5,-7]");
	num = Dec32("inf");
	assertTrue(sciForm!Dec32(num) == "Infinity");
	assertTrue(num.toAbstract() == "[0,inf]");
	num = Dec32.infinity(true);
	assertTrue(sciForm!Dec32(num) == "-Infinity");
	assertTrue(num.toAbstract() == "[1,inf]");
	num = Dec32("naN");
	assertTrue(sciForm!Dec32(num) == "NaN");
	assertTrue(num.toAbstract() == "[0,qNaN]");
	num = Dec32.nan(123);
	assertTrue(sciForm!Dec32(num) == "NaN123");
	assertTrue(num.toAbstract() == "[0,qNaN,123]");
	num = Dec32("-SNAN");
	assertTrue(sciForm!Dec32(num) == "-sNaN");
	assertTrue(num.toAbstract() == "[1,sNaN]");
	writeln("passed");
}

unittest {
	write("to-eng-str.....");
	string str = "1.23E+3";
	BigDecimal num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "123E+3";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "12.3E-9";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "-123E-12";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "700E-9";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "70";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0E-9";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.00E-6";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.0E-6";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.000000";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	/*	  str = "0.00E-3";
		num = BigDecimal(str);
		assertTrue(engForm!BigDecimal(num) == str);
		str = "0.0E-3";
		num = BigDecimal(str);
		assertTrue(engForm!BigDecimal(num) == str);*/
	str = "0.000";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.00";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.0";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.00E+3";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.0E+3";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0E+3";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.00E+6";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.0E+6";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0E+6";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	str = "0.00E+9";
	num = BigDecimal(str);
	assertTrue(engForm!BigDecimal(num) == str);
	writeln("passed");
}

unittest {
	string title = "toNumber";
	/*	uint passed = 0;
		uint failed = 0;
		BigDecimal f;
		string str = "0";
		f = BigDecimal(str);
		assertEqual(f.toString(), str) ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,0,0]") ? passed++ : failed++;
		str = "0.00";
		f = BigDecimal(str);
		assertEqual(f.toString(), str) ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,0,-2]") ? passed++ : failed++;
		str = "0.0";
		f = BigDecimal(str);
		assertEqual(f.toString(), str) ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,0,-1]") ? passed++ : failed++;
		f = BigDecimal("0.");
		assertEqual(f.toString(), "0") ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,0,0]") ? passed++ : failed++;
		f = BigDecimal(".0");
		assertEqual(f.toString(), "0.0") ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,0,-1]") ? passed++ : failed++;
		str = "1.0";
		f = BigDecimal(str);
		assertEqual(f.toString(), str) ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,10,-1]") ? passed++ : failed++;
		str = "1.";
		f = BigDecimal(str);
		assertEqual(f.toString(), "1") ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,1,0]") ? passed++ : failed++;
		str = ".1";
		f = BigDecimal(str);
		assertEqual(f.toString(), "0.1") ? passed++ : failed++;
		assertEqual(f.toAbstract(), "[0,1,-1]") ? passed++ : failed++;
		f = BigDecimal("123");
		assertEqual(f.toString(), "123") ? passed++ : failed++;
		f = BigDecimal("-123");
		assertEqual(f.toString(), "-123") ? passed++ : failed++;
		f = BigDecimal("1.23E3");
		assertEqual(f.toString(), "1.23E+3") ? passed++ : failed++;
		f = BigDecimal("1.23E");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("1.23E-");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("1.23E+");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("1.23E+3");
		assertEqual(f.toString(), "1.23E+3") ? passed++ : failed++;
		f = BigDecimal("1.23E3B");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("12.3E+007");
		assertEqual(f.toString(), "1.23E+8") ? passed++ : failed++;
		f = BigDecimal("12.3E+70000000000");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("12.3E+7000000000");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("12.3E+700000000");
		assertEqual(f.toString(), "1.23E+700000001") ? passed++ : failed++;
		f = BigDecimal("12.3E-700000000");
		assertEqual(f.toString(), "1.23E-699999999") ? passed++ : failed++;
		// (T)TODO: since there will still be adjustments -- maybe limit to 99999999?
		f = BigDecimal("12.0");
		assertEqual(f.toString(), "12.0") ? passed++ : failed++;
		f = BigDecimal("12.3");
		assertEqual(f.toString(), "12.3") ? passed++ : failed++;
		f = BigDecimal("1.23E-3");
		assertEqual(f.toString(), "0.00123") ? passed++ : failed++;
		f = BigDecimal("0.00123");
		assertEqual(f.toString(), "0.00123") ? passed++ : failed++;
		f = BigDecimal("-1.23E-12");
		assertEqual(f.toString(), "-1.23E-12") ? passed++ : failed++;
		f = BigDecimal("-0");
		assertEqual(f.toString(), "-0") ? passed++ : failed++;
		f = BigDecimal("inf");
		assertEqual(f.toString(), "Infinity") ? passed++ : failed++;
		f = BigDecimal("NaN");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		f = BigDecimal("-NaN");
		assertEqual(f.toString(), "-NaN") ? passed++ : failed++;
		f = BigDecimal("sNaN");
		assertEqual(f.toString(), "sNaN") ? passed++ : failed++;
		f = BigDecimal("Fred");
		assertEqual(f.toString(), "NaN") ? passed++ : failed++;
		writefln("unittest %s: passed %d; failed %d", title, passed, failed);*/
}

unittest {
	write("toExact........");
	Dec32 num;
	assertTrue(num.toExact == "+NaN");
	num = Dec32.max;
	assertTrue(num.toExact == "+9999999E+90");
	num = 1;
	assertTrue(num.toExact == "+1E+00");
	num = Dec32.infinity(true);
	assertTrue(num.toExact == "-Infinity");
	writeln("passed");
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
	write("radix........");
	assertEqual!int(10, Dec32.radix);
	assertNotEqual!int(16, BigDecimal.radix);
	writeln("passed");
}

unittest {
	write("class........");
	BigDecimal num;
	num = BigDecimal("Infinity");
	assertEqual(classify(num), "+Infinity");
	num = BigDecimal("1E-10");
	assertEqual(classify(num), "+Normal");
	num = BigDecimal("2.50");
	assertEqual(classify(num), "+Normal");
	num = BigDecimal("0.1E-99");
	assertEqual(classify(num), "+Subnormal");
	num = BigDecimal("0");
	assertEqual(classify(num), "+Zero");
	num = BigDecimal("-0");
	assertEqual(classify(num), "-Zero");
	num = BigDecimal("-0.1E-99");
	assertEqual(classify(num), "-Subnormal");
	num = BigDecimal("-1E-10");
	assertEqual(classify(num), "-Normal");
	num = BigDecimal("-2.50");
	assertEqual(classify(num), "-Normal");
	num = BigDecimal("-Infinity");
	assertEqual(classify(num), "-Infinity");
	num = BigDecimal("NaN");
	assertEqual(classify(num), "NaN");
	num = BigDecimal("-NaN");
	assertEqual(classify(num), "NaN");
	num = BigDecimal("sNaN");
	assertEqual(classify(num), "sNaN");
	writeln("passed");
}

// (T)TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
	write("copy.........");
	BigDecimal num;
	BigDecimal expd;
	num  = 2.1;
	expd = 2.1;
	assertTrue(copy(num) == expd);
	num  = BigDecimal("-1.00");
	expd = BigDecimal("-1.00");
	assertTrue(copy(num) == expd);
	writeln("passed");

	num  = 2.1;
	expd = 2.1;
	write("copy-abs.....");
	assertTrue(copyAbs!BigDecimal(num) == expd);
	num  = BigDecimal("-1.00");
	expd = BigDecimal("1.00");
	assertTrue(copyAbs!BigDecimal(num) == expd);
	writeln("passed");

	num  = 101.5;
	expd = -101.5;
	write("copy-negate..");
	assertTrue(copyNegate!BigDecimal(num) == expd);
	BigDecimal num1;
	BigDecimal num2;
	num1 = 1.50;
	num2 = 7.33;
	expd = 1.50;
	writeln("passed");

	write("copy-sign....");
	assertTrue(copySign(num1, num2) == expd);
	num1 = -1.50;
	num2 = 7.33;
	expd = 1.50;
	assertTrue(copySign(num1, num2) == expd);
	num1 = 1.50;
	num2 = -7.33;
	expd = -1.50;
	assertTrue(copySign(num1, num2) == expd);
	num1 = -1.50;
	num2 = -7.33;
	expd = -1.50;
	assertTrue(copySign(num1, num2) == expd);
	writeln("passed");
}

unittest {
	write("quantize.....");
	auto ctx = testContext;
	BigDecimal op1, op2;
	BigDecimal result, expd;
	string str;
	op1 = 2.17;
	op2 = 0.001;
	expd = BigDecimal("2.170");
	result = quantize(op1, op2, testContext);
	assertEqual(expd, result);
	op1 = 2.17;
	op2 = 0.01;
	expd = 2.17;
	result = quantize(op1, op2, testContext);
	assertEqual(expd, result);
	op1 = 2.17;
	op2 = 0.1;
	expd = 2.2;
	result = quantize(op1, op2, testContext);
	assertEqual(expd, result);
	op1 = 2.17;
	op2 = BigDecimal("1E+0");
	expd = 2;
	result = quantize(op1, op2, testContext);
	assertEqual(expd, result);
	op1 = 2.17;
	op2 = BigDecimal("1E+1");
	expd = BigDecimal("0E+1");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("-Inf");
	op2 = BigDecimal("Infinity");
	expd = BigDecimal("-Infinity");
	result = quantize(op1, op2, testContext);
	assertEqual(expd, result);
	op1 = 2;
	op2 = BigDecimal("Infinity");
	expd = BigDecimal("NaN");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = -0.1;
	op2 = 1;
	expd = BigDecimal("-0");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("-0");
	op2 = BigDecimal("1E+5");
	expd = BigDecimal("-0E+5");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("+35236450.6");
	op2 = BigDecimal("1E-2");
	expd = BigDecimal("NaN");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("-35236450.6");
	op2 = BigDecimal("1E-2");
	expd = BigDecimal("NaN");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("217");
	op2 = BigDecimal("1E-1");
	expd = BigDecimal("217.0");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("217");
	op2 = BigDecimal("1E+0");
	expd = BigDecimal("217");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("217");
	op2 = BigDecimal("1E+1");
	expd = BigDecimal("2.2E+2");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	op1 = BigDecimal("217");
	op2 = BigDecimal("1E+2");
	expd = BigDecimal("2E+2");
	result = quantize(op1, op2, testContext);
	assertTrue(result.toString() == expd.toString());
	assertEqual(expd, result);
	writeln("passed");
}

unittest {
	write("logb.........");
	BigDecimal num;
	BigDecimal expect;
	num = BigDecimal("250");
	expect = BigDecimal("2");
	assertTrue(logb(num) == expect);
	num = BigDecimal("2.50");
	expect = BigDecimal("0");
	assertTrue(logb(num) == expect);
	num = BigDecimal("0.03");
	expect = BigDecimal("-2");
	assertTrue(logb(num) == expect);
	num = BigDecimal("0");
	expect = BigDecimal("-Infinity");
	assertTrue(logb(num) == expect);
	writeln("passed");
}

unittest {
	write("scaleb.......");
	BigDecimal op1, op2, expd;
	op1 = BigDecimal("7.50");
	op2 = BigDecimal("-2");
	expd = BigDecimal("0.0750");
	assertTrue(scaleb(op1, op2) == expd);
	op1 = BigDecimal("7.50");
	op2 = BigDecimal("0");
	expd = BigDecimal("7.50");
	assertTrue(scaleb(op1, op2) == expd);
	op1 = BigDecimal("7.50");
	op2 = BigDecimal("3");
	expd = BigDecimal("7.50E+3");
	assertTrue(scaleb(op1, op2) == expd);
	op1 = BigDecimal("-Infinity");
	op2 = BigDecimal("4.5");
	expd = BigDecimal("-Infinity");
	assertTrue(scaleb(op1, op2) == expd);
	writeln("passed");
}

unittest {
	write("reduce.......");
	BigDecimal num;
	BigDecimal red;
	string str;
	num = BigDecimal("2.1");
	str = "2.1";
	red = reduce(num);
	assertTrue(red.toString() == str);
	num = BigDecimal("-2.0");
	str = "-2";
	red = reduce(num);
	assertTrue(red.toString() == str);
	num = BigDecimal("1.200");
	str = "1.2";
	red = reduce(num);
	assertTrue(red.toString() == str);
	num = BigDecimal("-120");
	str = "-1.2E+2";
	red = reduce(num);
	assertTrue(red.toString() == str);
	num = BigDecimal("120.00");
	str = "1.2E+2";
	red = reduce(num);
	assertTrue(red.toString() == str);
	writeln("passed");
}

unittest {
	write("quantum......");
	Dec64 num, qnum;
	num = 23.14E-12;
	qnum = 1E-14;
	assertTrue(quantum(num) == qnum);
	writeln("passed");
}

unittest {
	// (T)TODO: add rounding tests
	writeln("-------------------");
	write("abs..........");
	BigDecimal num;
	BigDecimal expd;
	num = BigDecimal("sNaN");
	assertTrue(abs(num, testContext).isQuiet);	// converted to quiet Nan per spec.
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
	num = BigDecimal("NaN");
	assertTrue(abs(num, testContext).isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
	num = BigDecimal("Inf");
	expd = BigDecimal("Inf");
	assertTrue(abs(num, testContext) == expd);
	num = BigDecimal("-Inf");
	expd = BigDecimal("Inf");
	assertTrue(abs(num, testContext) == expd);
	num = BigDecimal("0");
	expd = BigDecimal("0");
	assertTrue(abs(num, testContext) == expd);
	num = BigDecimal("-0");
	expd = BigDecimal("0");
	assertTrue(abs(num, testContext) == expd);
	num = BigDecimal("2.1");
	expd = BigDecimal("2.1");
	assertTrue(abs(num, testContext) == expd);
	num = -100;
	expd = 100;
	assertTrue(abs(num, testContext) == expd);
	num = 101.5;
	expd = 101.5;
	assertTrue(abs(num, testContext) == expd);
	num = -101.5;
	assertTrue(abs(num, testContext) == expd);
	writeln("passed");
}

unittest {
	write("plus.........");
	// NOTE: result should equal 0 + this or 0 - this
	BigDecimal zero = BigDecimal(0);
	BigDecimal num;
	BigDecimal expd;
	num = 1.3;
	expd = zero + num;
	assertTrue(+num == expd);
	num = -1.3;
	expd = zero + num;
	assertTrue(+num == expd);
	// (T)TODO: add tests that check flags.
	writeln("passed");
}

unittest {
	write("minus........");
	// NOTE: result should equal 0 + this or 0 - this
	BigDecimal zero = BigDecimal(0);
	BigDecimal num;
	BigDecimal expd;
	num = 1.3;
	expd = zero - num;
	assertTrue(-num == expd);
	num = -1.3;
	expd = zero - num;
	assertTrue(-num == expd);
	// (T)TODO: add tests that check flags.
	writeln("passed");
}

unittest {
	write("next-plus....");
	DecimalContext ctx999 = testContext.setMaxExponent(999);
	BigDecimal num, expect;
	num = 1;
	expect = BigDecimal("1.00000001");
	assertTrue(nextPlus(num, ctx999) == expect);
	num = 10;
	expect = BigDecimal("10.0000001");
	assertTrue(nextPlus(num, ctx999) == expect);
	num = 1E5;
	expect = BigDecimal("100000.001");
	assertTrue(nextPlus(num, ctx999) == expect);
	num = 1E8;
	expect = BigDecimal("100000001");
	assertTrue(nextPlus(num, ctx999) == expect);
	// num digits exceeds precision...
	num = BigDecimal("1234567891");
	expect = BigDecimal("1.23456790E9");
	assertTrue(nextPlus(num, ctx999) == expect);
	// result < tiny
	num = BigDecimal("-1E-1007");
	expect = BigDecimal("-0E-1007");
	assertTrue(nextPlus(num, ctx999) == expect);
	num = BigDecimal("-1.00000003");
	expect = BigDecimal("-1.00000002");
	assertTrue(nextPlus(num, ctx999) == expect);
	num = BigDecimal("-Infinity");
	expect = BigDecimal("-9.99999999E+999");
	assertTrue(nextPlus(num, ctx999) == expect);
	writeln("passed");
}

unittest {
	write("next-minus...");
	DecimalContext ctx999 = testContext.setMaxExponent(999);
	BigDecimal num;
	BigDecimal expect;
	num = 1;
	expect = BigDecimal("0.999999999");
	assertTrue(nextMinus(num, ctx999) == expect);
	num = BigDecimal("1E-1007");
	expect = BigDecimal("0E-1007");
	assertTrue(nextMinus(num, ctx999) == expect);
	num = BigDecimal("-1.00000003");
	expect = BigDecimal("-1.00000004");
	assertTrue(nextMinus(num, ctx999) == expect);
	/*	  num = BigDecimal("Infinity");
		expect = BigDecimal("9.99999999E+999");
		assertTrue(nextMinus(num, ctx999) == expect);*/
	writeln("passed");
}

unittest {
	write("next-toward..");
	BigDecimal op1, op2, expect;
	op1 = 1;
	op2 = 2;
	expect = BigDecimal("1.00000001");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = BigDecimal("-1E-1007");
	op2 = 1;
	expect = BigDecimal("-0E-1007");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = BigDecimal("-1.00000003");
	op2 = 0;
	expect = BigDecimal("-1.00000002");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = 1;
	op2 = 0;
	expect = BigDecimal("0.999999999");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = BigDecimal("1E-1007");
	op2 = -100;
	expect = BigDecimal("0E-1007");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = BigDecimal("-1.00000003");
	op2 = -10;
	expect = BigDecimal("-1.00000004");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	op1 = BigDecimal("0.00");
	op2 = BigDecimal("-0.0000");
	expect = BigDecimal("-0.00");
	assertTrue(nextToward(op1, op2, testContext) == expect);
	writeln("passed");
}

unittest {
	write("same-quantum.");
	BigDecimal op1, op2;
	op1 = 2.17;
	op2 = 0.001;
	assertTrue(!sameQuantum(op1, op2));
	op2 = 0.01;
	assertTrue(sameQuantum(op1, op2));
	op2 = 0.1;
	assertTrue(!sameQuantum(op1, op2));
	op2 = 1;
	assertTrue(!sameQuantum(op1, op2));
	op1 = BigDecimal("Inf");
	op2 = BigDecimal("Inf");
	assertTrue(sameQuantum(op1, op2));
	op1 = BigDecimal("NaN");
	op2 = BigDecimal("NaN");
	assertTrue(sameQuantum(op1, op2));
	writeln("passed");
}

unittest {
	write("compare......");
	BigDecimal op1, op2;
	int result;
	op1 = 2.1;
	op2 = 3;
	result = compare(op1, op2, testContext);
	assertTrue(result == -1);
	op1 = 2.1;
	op2 = 2.1;
	result = compare(op1, op2, testContext);
	assertTrue(result == 0);
	op1 = BigDecimal("2.1");
	op2 = BigDecimal("2.10");
	result = compare(op1, op2, testContext);
	assertTrue(result == 0);
	op1 = 3;
	op2 = 2.1;
	result = compare(op1, op2, testContext);
	assertTrue(result == 1);
	op1 = 2.1;
	op2 = -3;
	result = compare(op1, op2, testContext);
	assertTrue(result == 1);
	op1 = -3;
	op2 = 2.1;
	result = compare(op1, op2, testContext);
	assertTrue(result == -1);
	op1 = -3;
	op2 = -4;
	result = compare(op1, op2, testContext);
	assertTrue(result == 1);
	op1 = -300;
	op2 = -4;
	result = compare(op1, op2, testContext);
	assertTrue(result == -1);
	op1 = 3;
	op2 = BigDecimal.max;
	result = compare(op1, op2, testContext);
	assertTrue(result == -1);
	op1 = -3;
	op2 = copyNegate!BigDecimal(BigDecimal.max);
	result = compare!BigDecimal(op1, op2, testContext);
	assertTrue(result == 1);
	writeln("passed");
}

// (T)TODO: change these to true opEquals calls.
unittest {
	write("equals.......");
	BigDecimal op1, op2;
	op1 = BigDecimal("NaN");
	op2 = BigDecimal("NaN");
	assertTrue(op1 != op2);
	op1 = BigDecimal("inf");
	op2 = BigDecimal("inf");
	assertTrue(op1 == op2);
	op2 = BigDecimal("-inf");
	assertTrue(op1 != op2);
	op1 = BigDecimal("-inf");
	assertTrue(op1 == op2);
	op2 = BigDecimal("NaN");
	assertTrue(op1 != op2);
	op1 = 0;
	assertTrue(op1 != op2);
	op2 = 0;
	assertTrue(op1 == op2);
	writeln("passed");
}

unittest {
	write("comp-signal..");
	writeln("test missing");
}

unittest {
	write("comp-total..");
	BigDecimal op1;
	BigDecimal op2;
	int result;
	op1 = 12.73;
	op2 = 127.9;
	result = compareTotal(op1, op2);
	assertTrue(result == -1);
	op1 = -127;
	op2 = 12;
	result = compareTotal(op1, op2);
	assertTrue(result == -1);
	op1 = BigDecimal("12.30");
	op2 = BigDecimal("12.3");
	result = compareTotal(op1, op2);
	assertTrue(result == -1);
	op1 = BigDecimal("12.30");
	op2 = BigDecimal("12.30");
	result = compareTotal(op1, op2);
	assertTrue(result == 0);
	op1 = BigDecimal("12.3");
	op2 = BigDecimal("12.300");
	result = compareTotal(op1, op2);
	assertTrue(result == 1);
	op1 = BigDecimal("12.3");
	op2 = BigDecimal("NaN");
	result = compareTotal(op1, op2);
	assertTrue(result == -1);
	writeln("passed");
}

unittest {
	write("comp-tot-mag..");
	writeln("test missing");
}

unittest {
	write("max..........");
	BigDecimal op1, op2;
	op1 = 3;
	op2 = 2;
	assertTrue(max(op1, op2, testContext) == op1);
	op1 = -10;
	op2 = 3;
	assertTrue(max(op1, op2, testContext) == op2);
	op1 = BigDecimal("1.0");
	op2 = 1;
	assertTrue(max(op1, op2, testContext) == op2);
	op1 = 7;
	op2 = BigDecimal("NaN");
	assertTrue(max(op1, op2, testContext) == op1);
	writeln("passed");
}

unittest {
	write("max-mag......");
	writeln("test missing");
}

unittest {
	write("min..........");
	BigDecimal op1, op2;
	op1 = 3;
	op2 = 2;
	assertTrue(min(op1, op2, testContext) == op2);
	op1 = -10;
	op2 = 3;
	assertTrue(min(op1, op2, testContext) == op1);
	op1 = BigDecimal("1.0");
	op2 = 1;
	assertTrue(min(op1, op2, testContext) == op1);
	op1 = 7;
	op2 = BigDecimal("NaN");
	assertTrue(min(op1, op2, testContext) == op1);
	writeln("passed");
}

unittest {
	write("min-mag......");
	writeln("test missing");
}

unittest {
	write("shift........");
/*	BigDecimal num = 34;
	int digits = 8;
	BigDecimal act = shift(num, digits, testContext);
	num = 12;
	digits = 9;
	act = shift(num, digits, testContext);
	num = 123456789;
	digits = -2;
	act = shift(num, digits, testContext);
	digits = 0;
	act = shift(num, digits, testContext);
	digits = 2;
	act = shift(num, digits, testContext);*/
	writeln("test missing");
}

unittest {
	write("rotate.......");
/*	BigDecimal num = 34;
	int digits = 8;
	BigDecimal act = rotate(num, digits);
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
	writeln("act = ", act);	*/
	writeln("test missing");
}

// (T)TODO: these tests need to be cleaned up to rely less on strings
// and to check the NaN, Inf combinations better.
unittest {
	write("add..........");
	BigDecimal op1 = BigDecimal("12");
	BigDecimal op2 = BigDecimal("7.00");
	BigDecimal sum = add(op1, op2, testContext);
	assertTrue(sum.toString() == "19.00");
	op1 = BigDecimal("1E+2");
	op2 = BigDecimal("1E+4");
	sum = add(op1, op2, testContext);
	assertTrue(sum.toString() == "1.01E+4");
	op1 = BigDecimal("1.3");
	op2 = BigDecimal("1.07");
	sum = sub(op1, op2, testContext);
	assertTrue(sum.toString() == "0.23");
	op2 = BigDecimal("1.30");
	sum = sub(op1, op2, testContext);
	assertTrue(sum.toString() == "0.00");
	op2 = BigDecimal("2.07");
	sum = sub(op1, op2, testContext);
	assertTrue(sum.toString() == "-0.77");
	op1 = BigDecimal("Inf");
	op2 = 1;
	sum = add(op1, op2, testContext);
	assertTrue(sum.toString() == "Infinity");
	op1 = BigDecimal("NaN");
	op2 = 1;
	sum = add(op1, op2, testContext);
	assertTrue(sum.isQuiet);
	op2 = BigDecimal("Infinity");
	sum = add(op1, op2, testContext);
	assertTrue(sum.isQuiet);
	op1 = 1;
	sum = sub(op1, op2, testContext);
	assertTrue(sum.toString() == "-Infinity");
	op1 = BigDecimal("-0");
	op2 = 0;
	sum = sub(op1, op2, testContext);
	assertTrue(sum.toString() == "-0");
	writeln("passed");
}

unittest {
	write("subtract.....");
	writeln("test missing");
}

unittest {
	// (T)TODO: change these to mul(op1, op2) tests.
	write("multiply.....");
	BigDecimal op1, op2, result;
	op1 = BigDecimal("1.20");
	op2 = 3;
	result = op1 * op2;
	assertTrue(result.toString() == "3.60");
	op1 = 7;
	result = op1 * op2;
	assertTrue(result.toString() == "21");
	op1 = BigDecimal("0.9");
	op2 = BigDecimal("0.8");
	result = op1 * op2;
	assertTrue(result.toString() == "0.72");
	op1 = BigDecimal("0.9");
	op2 = BigDecimal("-0.0");
	result = op1 * op2;
	assertTrue(result.toString() == "-0.00");
	op1 = BigDecimal(654321);
	op2 = BigDecimal(654321);
	result = op1 * op2;
	assertTrue(result.toString() == "4.28135971E+11");
	op1 = -1;
	op2 = BigDecimal("Infinity");
	result = op1 * op2;
	assertTrue(result.toString() == "-Infinity");
	op1 = -1;
	op2 = 0;
	result = op1 * op2;
	assertTrue(result.toString() == "-0");
	writeln("passed");
}

unittest {
	write("fma..........");
	BigDecimal op1, op2, op3, result;
	op1 = 3;
	op2 = 5;
	op3 = 7;
	result = (fma(op1, op2, op3, testContext));
	assertTrue(result == BigDecimal(22));
	op1 = 3;
	op2 = -5;
	op3 = 7;
	result = (fma(op1, op2, op3, testContext));
	assertTrue(result == BigDecimal(-8));
	op1 = BigDecimal("888565290");
	op2 = BigDecimal("1557.96930");
	op3 = BigDecimal("-86087.7578");
	result = (fma(op1, op2, op3, testContext));
	assertTrue(result == BigDecimal("1.38435736E+12"));
	writeln("passed");
}

unittest {
	write("divide.......");
	BigDecimal op1, op2;
	BigDecimal expd;
	op1 = 1;
	op2 = 3;
	BigDecimal quotient = div(op1, op2, testContext);
	expd = BigDecimal("0.333333333");
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op1 = 2;
	op2 = 3;
	quotient = div(op1, op2, testContext);
	expd = BigDecimal("0.666666667");
	assertTrue(quotient == expd);
	op1 = 5;
	op2 = 2;
	contextFlags.clearFlags();
	quotient = div(op1, op2, testContext);
//	  assertTrue(quotient == expd);
//	  assertTrue(quotient.toString() == expd.toString());
	op1 = 1;
	op2 = 10;
	expd = 0.1;
	quotient = div(op1, op2, testContext);
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op1 = BigDecimal("8.00");
	op2 = 2;
	expd = BigDecimal("4.00");
	quotient = div(op1, op2, testContext);
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op1 = BigDecimal("2.400");
	op2 = BigDecimal("2.0");
	expd = BigDecimal("1.20");
	quotient = div(op1, op2, testContext);
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op1 = 1000;
	op2 = 100;
	expd = 10;
	quotient = div(op1, op2, testContext);
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op2 = 1;
	quotient = div(op1, op2, testContext);
	expd = 1000;
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	op1 = 2.40E+6;
	op2 = 2;
	expd = 1.20E+6;
	quotient = div(op1, op2, testContext);
	assertTrue(quotient == expd);
	assertTrue(quotient.toString() == expd.toString());
	writeln("passed");
}


unittest {
	write("div-int......");
	BigDecimal op1, op2, actual, expect;
	op1 = 2;
	op2 = 3;
	actual = divideInteger(op1, op2, testContext);
	expect = 0;
	assertTrue(actual == expect);
	op1 = 10;
	actual = divideInteger(op1, op2, testContext);
	expect = 3;
	assertTrue(actual == expect);
	op1 = 1;
	op2 = 0.3;
	actual = divideInteger(op1, op2, testContext);
	assertTrue(actual == expect);
	writeln("passed");
}

unittest {
	write("remainder....");
	BigDecimal op1, op2, actual, expect;
	op1 = 2.1;
	op2 = 3;
	actual = remainder(op1, op2, testContext);
	expect = 2.1;
	assertTrue(actual == expect);
	op1 = 10;
	actual = remainder(op1, op2, testContext);
	expect = 1;
	assertTrue(actual == expect);
	op1 = -10;
	actual = remainder(op1, op2, testContext);
	expect = -1;
	assertTrue(actual == expect);
	op1 = 10.2;
	op2 = 1;
	actual = remainder(op1, op2, testContext);
	expect = 0.2;
	assertTrue(actual == expect);
	op1 = 10;
	op2 = 0.3;
	actual = remainder(op1, op2, testContext);
	expect = 0.1;
	assertTrue(actual == expect);
	op1 = 3.6;
	op2 = 1.3;
	actual = remainder(op1, op2, testContext);
	expect = 1.0;
	assertTrue(actual == expect);
	writeln("passed");
}

unittest {
	write("rem-near.....");
	writeln("test missing");
}

unittest {
	write("rnd-int-ex...");
	BigDecimal num, expect, actual;
	num = 2.1;
	expect = 2;
	actual = roundToIntegralExact(num, testContext);
	assertTrue(actual == expect);
	num = 100;
	expect = 100;
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = BigDecimal("100.0");
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = BigDecimal("101.5");
	expect = 102;
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = -101.5;
	expect = -102;
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = BigDecimal("10E+5");
	expect = BigDecimal("1.0E+6");
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = 7.89E+77;
	expect = 7.89E+77;
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	num = BigDecimal("-Inf");
	expect = BigDecimal("-Infinity");
	assertTrue(roundToIntegralExact(num, testContext) == expect);
	assertTrue(roundToIntegralExact(num, testContext).toString() == expect.toString());
	writeln("passed");
}

unittest {
	write("rnd-int-val..");
	writeln("test missing");
}

unittest {
	write("reduce.......");
	writeln("test missing");
}

unittest {
	write("invalid......");
	BigDecimal num, expect, actual;

	// (T)TODO: FIXTHIS: Can't actually test payloads at this point.
	num = BigDecimal("sNaN123");
	expect = BigDecimal("NaN123");
	actual = abs!BigDecimal(num, testContext);
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);
	num = BigDecimal("NaN123");
	actual = abs(num, testContext);
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);

	num = BigDecimal("sNaN123");
	expect = BigDecimal("NaN123");
	actual = -num;
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);
	num = BigDecimal("NaN123");
	actual = -num;
	assertTrue(actual.isQuiet);
	assertTrue(contextFlags.getFlag(INVALID_OPERATION));
//	  assertTrue(actual.toAbstract == expect.toAbstract);*/
	writeln("passed");
}

unittest {
	write("alignOps.....");
	writeln("test missing");
}

unittest {
	write("isInvalidBinaryOp...");
	writeln("test missing");
}

unittest {
	write("invalidOperand......");
	writeln("test missing");
}

unittest {
	write("isInvalidAddition...");
	writeln("test missing");
}

unittest {
	write("isInvalidMultiplication..");
	writeln("missing");
}

unittest {
	write("isInvalidDivision...");
	writeln("test missing");
}

unittest {
	write("isZeroDividend......");
	writeln("test missing");
}

unittest {
	writeln("---------------------");
	writeln("arithmetic...finished");
	writeln("---------------------");
}

unittest {
	writeln("---------------------");
	writeln("BigDecimal....testing");
	writeln("---------------------");
}

unittest {
	write("this().......");
	BigDecimal num;
	string str;
	num = BigDecimal(1, 12334, -5);
	str = "-0.12334";
	assertTrue(num.toString == str);
	num = BigDecimal(-23456, 10);
	str = "-2.3456E+14";
	assertTrue(num.toString == str);
	num = BigDecimal(234568901234);
	str = "234568901234";
	assertTrue(num.toString == str);
	num = BigDecimal("123.457E+29");
	str = "1.23457E+31";
	assertTrue(num.toString == str);
	num = std.math.E;
	str = "2.71828183";
	assertTrue(num.toString == str);
	num = std.math.LOG2;
	BigDecimal copy = BigDecimal(num);
	assertTrue(compareTotal!BigDecimal(num, copy) == 0);
	num = BigDecimal(SV.INF, true);
	assertTrue(num.toSciString == "-Infinity");
	assertTrue(num.toAbstract() == "[1,inf]");
	num = BigDecimal(true, BigInt(7254), 94);
	assertTrue(num.toString == "-7.254E+97");
	num = BigDecimal(BigInt(7254), 94);
	assertTrue(num.toString == "7.254E+97");
	num = BigDecimal(BigInt(-7254));
	assertTrue(num.toString == "-7254");
	num = BigDecimal(1234L, 567);
	assertTrue(num.toString() == "1.234E+570");
	num = BigDecimal(1234, 567);
	assertTrue(num.toString() == "1.234E+570");
	num = BigDecimal(1234L);
	assertTrue(num.toString() == "1234");
	num = BigDecimal(123400L);
	assertTrue(num.toString() == "123400");
	num = BigDecimal(1234L);
	assertTrue(num.toString() == "1234");
	writeln("passed");
}

unittest {
	write("dup..........");
	BigDecimal num = BigDecimal(std.math.PI);
	BigDecimal copy = num.dup;
	assertTrue(num == copy);
	writeln("passed");
}

unittest {
	write("toString.....");
	BigDecimal f = BigDecimal(1234L, 567);
	f = BigDecimal(1234, 567);
	assertTrue(f.toString() == "1.234E+570");
	f = BigDecimal(1234L);
	assertTrue(f.toString() == "1234");
	f = BigDecimal(123400L);
	assertTrue(f.toString() == "123400");
	f = BigDecimal(1234L);
	assertTrue(f.toString() == "1234");
	writeln("passed");
}

unittest {
	write("opAssign.....");
	BigDecimal num;
	string str;
	num = BigDecimal(1, 245, 8);
	str = "-2.45E+10";
	assertTrue(num.toString == str);
	num = long.max;
	str = "9223372036854775807";
	assertTrue(num.toString == str);
	num = real.max;
	str = "1.1897315E+4932";
	assertTrue(num.toString == str);
	writeln("passed");
	num = Dec32.max;
	str = "9.999999E+96";
	assertTrue(num.toString == str);
}

unittest {
	write("toAbstract...");
	BigDecimal num;
	string str;
	num = BigDecimal("-inf");
	str = "[1,inf]";
	assertTrue(num.toAbstract == str);
	num = BigDecimal("nan");
	str = "[0,qNaN]";
	assertTrue(num.toAbstract == str);
	num = BigDecimal("snan1234");
	str = "[0,sNaN1234]";
	assertTrue(num.toAbstract == str);
	writeln("passed");
}

unittest {
	write("toString.....");
	BigDecimal num;
	string str;
	num = BigDecimal(200000, 71);
	str = "2.00000E+76";
	assertTrue(num.toString == str);
	writeln("passed");
}

unittest {
	write("canonical....");
	BigDecimal num = BigDecimal("2.50");
	assertTrue(num.isCanonical);
	BigDecimal copy = num.canonical;
	assertTrue(compareTotal(num, copy) == 0);
	writeln("passed");
}

unittest {
	write("spcl values..");
	BigDecimal num;
	num = BigDecimal.NAN;
	assertTrue(num.toString == "NaN");
	num = BigDecimal.SNAN;
	assertTrue(num.toString == "sNaN");
//	writeln("BigDecimal(SV.QNAN).toAbstract = ", BigDecimal.NAN.toAbstract);
	num = BigDecimal.NEG_ZERO;
	assertTrue(num.toString == "-0");
	writeln("passed");
}

unittest {
	write("toExact......");
	BigDecimal num;
	assertTrue(num.toExact == "+NaN");
	num = +9999999E+90;
	assertTrue(num.toExact == "+9999999E+90");
	num = 1;
	assertTrue(num.toExact == "+1E+00");
	num = BigDecimal.infinity(true);
	assertTrue(num.toExact == "-Infinity");
	writeln("passed");
}

unittest {
	write("canonical....");
	BigDecimal num = BigDecimal("2.50");
	assertTrue(num.isCanonical);
	writeln("passed");
}

unittest {
	write("isZero.......");
	BigDecimal num;
	num = BigDecimal("0");
	assertTrue(num.isZero);
	num = BigDecimal("2.50");
	assertTrue(!num.isZero);
	num = BigDecimal("-0E+2");
	assertTrue(num.isZero);
	writeln("passed");
}

unittest {
	write("isNaN........");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isNaN);
	num = BigDecimal("NaN");
	assertTrue(num.isNaN);
	num = BigDecimal("-sNaN");
	assertTrue(num.isNaN);
	writeln("passed");
}

unittest {
	write("isSignaling..");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isSignaling);
	num = BigDecimal("NaN");
	assertTrue(!num.isSignaling);
	num = BigDecimal("sNaN");
	assertTrue(num.isSignaling);
	writeln("passed");
}

unittest {
	write("isQuiet......");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isQuiet);
	num = BigDecimal("NaN");
	assertTrue(num.isQuiet);
	num = BigDecimal("sNaN");
	assertTrue(!num.isQuiet);
	writeln("passed");
}

unittest {
	write("isInfinite...");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isInfinite);
	num = BigDecimal("-Inf");
	assertTrue(num.isInfinite);
	num = BigDecimal("NaN");
	assertTrue(!num.isInfinite);
	writeln("passed");
}

unittest {
	write("isFinite.....");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(num.isFinite);
	num = BigDecimal("-0.3");
	assertTrue(num.isFinite);
	num = 0;
	assertTrue(num.isFinite);
	num = BigDecimal("Inf");
	assertTrue(!num.isFinite);
	num = BigDecimal("-Inf");
	assertTrue(!num.isFinite);
	num = BigDecimal("NaN");
	assertTrue(!num.isFinite);
	writeln("passed");
}

unittest {
	write("isSigned.....");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isSigned);
	num = BigDecimal("-12");
	assertTrue(num.isSigned);
	num = BigDecimal("-0");
	assertTrue(num.isSigned);
	writeln("passed");
}

unittest {
	write("isNegative...");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isNegative);
	num = BigDecimal("-12");
	assertTrue(num.isNegative);
	num = BigDecimal("-0");
	assertTrue(num.isNegative);
	writeln("passed");
}

unittest {
	write("isSubnormal..");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(!num.isSubnormal);
	num = BigDecimal("0.1E-99");
	assertTrue(num.isSubnormal);
	num = BigDecimal("0.00");
	assertTrue(!num.isSubnormal);
	num = BigDecimal("-Inf");
	assertTrue(!num.isSubnormal);
	num = BigDecimal("NaN");
	assertTrue(!num.isSubnormal);
	writeln("passed");
}

unittest {
	write("isNormal.....");
	BigDecimal num;
	num = BigDecimal("2.50");
	assertTrue(num.isNormal);
	num = BigDecimal("0.1E-99");
	assertTrue(!num.isNormal);
	num = BigDecimal("0.00");
	assertTrue(!num.isNormal);
	num = BigDecimal("-Inf");
	assertTrue(!num.isNormal);
	num = BigDecimal("NaN");
	assertTrue(!num.isNormal);
	writeln("passed");
}

unittest {
	write("isSpecial....");
	BigDecimal num;
	num = BigDecimal.infinity(true);
	assertTrue(num.isSpecial);
	num = BigDecimal.snan(1234);
	assertTrue(num.isSpecial);
	num = 12378.34;
	assertTrue(!num.isSpecial);
	writeln("passed");
}

unittest {
	write("isIntegral...");
	BigDecimal num;
	num = 12345;
	assertTrue(num.isIntegral);
	num = BigInt("123456098420234978023480");
	assertTrue(num.isIntegral);
	num = 1.5;
	assertTrue(!num.isIntegral);
	num = 1.5E+1;
	assertTrue(num.isIntegral);
	num = 0;
	assertTrue(num.isIntegral);
	writeln("passed");
}

unittest {
	write("components...");
	BigDecimal big = -123.45E12;
	assertTrue(big.exponent == 10);
	assertTrue(big.coefficient == 12345);
	assertTrue(big.sign);
	big.coefficient = 23456;
	big.exponent = 12;
	big.sign = false;
	assertTrue(big == BigDecimal(234.56E14));
	big = BigDecimal.nan;
	assertTrue(big.payload == 0);
	big = BigDecimal.snan(1250);
	assertTrue(big.payload == 1250);
	writeln("passed");
}

unittest {
	write("sgn..........");
	BigDecimal big;
	big = -123;
	assertTrue(sgn(big) == -1);
	big = 2345;
	assertTrue(sgn(big) == 1);
	big = BigDecimal("0.0000");
	assertTrue(sgn(big) == 0);
	big = BigDecimal.infinity(true);
	assertTrue(sgn(big) == -1);
	writeln("passed");
}

unittest {
	write("opCmp........");
	BigDecimal num1, num2;
	num1 = 105;
	num2 = 10.543;
	assertTrue(num1 > num2);
	assertTrue(num2 < num1);
	num1 = 10.543;
	assertTrue(num1 >= num2);
	assertTrue(num2 <= num1);
	writeln("passed");
}

unittest {
	write("opEquals.....");
	BigDecimal num1, num2;
	num1 = 105;
	num2 = 10.543;
	assertTrue(num1 != num2);
	num1 = 10.543;
	assertTrue(num1 == num2);
	writeln("passed");
}

unittest {
	write("opUnary......");
	BigDecimal num, actual, expect;
	num = 134;
	expect = num;
	actual = +num;
	assertTrue(actual == expect);
	num = 134.02;
	expect = -134.02;
	actual = -num;
	assertTrue(actual == expect);
	num = 134;
	expect = 135;
	actual = ++num;
	assertTrue(actual == expect);
	num = 1.00E8;
	expect = num;
// (T)TODO:   actual = --num; // fails!
	actual = num--;
	assertTrue(actual == expect);
	num = BigDecimal(9999999, 90);
	expect = num;
	actual = num++;
	assertTrue(actual == expect);
	num = 12.35;
	expect = 11.35;
	actual = --num;
	assertTrue(actual == expect);
	writeln("passed");
}

unittest {
	write("opBinary.....");
	BigDecimal op1, op2, actual, expect;
	op1 = 4;
	op2 = 8;
	actual = op1 + op2;
	expect = 12;
	assertEqual(expect,actual);
	actual = op1 - op2;
	expect = -4;
	assertEqual(expect,actual);
	actual = op1 * op2;
	expect = 32;
	assertEqual(expect,actual);
	op1 = 5;
	op2 = 2;
	actual = op1 / op2;
	expect = 2.5;
	assertEqual(expect,actual);
	op1 = 10;
	op2 = 3;
	actual = op1 % op2;
	expect = 1;
	assertEqual(expect,actual);
	writeln("passed");
}

unittest {
	write("opOpAssign...");
	BigDecimal op1, op2, actual, expect;
	op1 = 23.56;
	op2 = -2.07;
	op1 += op2;
	expect = 21.49;
	actual = op1;
	assertEqual(expect,actual);
	op1 *= op2;
	expect = -44.4843;
	actual = op1;
	assertEqual(expect,actual);
	writeln("passed");
}

unittest {
	write("next.........");
	BigDecimal big, expect;
	big = 123.45;
	assertTrue(big.nextUp == BigDecimal(123.450001));
	big = 123.45;
	assertTrue(big.nextDown == BigDecimal(123.449999));
	big = 123.45;
	expect = big.nextUp;
	assertTrue(big.nextAfter(BigDecimal(123.46)) == expect);
	big = 123.45;
	expect = big.nextDown;
	assertTrue(big.nextAfter(BigDecimal(123.44)) == expect);
	writeln("passed");
}

unittest {
	writeln("---------------------");
	writeln("BigDecimal...finished");
	writeln("---------------------");
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
	writeln("---------------------");
	writeln("rounding......testing");
	writeln("---------------------");
}

unittest {
	write("round........");
	BigDecimal before = BigDecimal(9999);
	BigDecimal after = before;
	DecimalContext ctx3 = testContext.setPrecision(3);
	DecimalContext ctx4 = testContext.setPrecision(4);
	DecimalContext ctx5 = testContext.setPrecision(5);
	DecimalContext ctx6 = testContext.setPrecision(6);
	DecimalContext ctx7 = testContext.setPrecision(7);
	DecimalContext ctx8 = testContext.setPrecision(8);
	round(after, ctx3);
	assertEqual("1.00E+4", after.toString());
	before = BigDecimal(1234567890);
	after = before;
	round(after, ctx3);
	assertTrue(after.toString() == "1.23E+9");
	after = before;
	round(after, ctx4);;
	assertTrue(after.toString() == "1.235E+9");
	after = before;
	round(after, ctx5);;
	assertTrue(after.toString() == "1.2346E+9");
	after = before;
	round(after, ctx6);;
	assertTrue(after.toString() == "1.23457E+9");
	after = before;
	round(after, ctx7);;
	assertTrue(after.toString() == "1.234568E+9");
	after = before;
	round(after, ctx8);;
	assertTrue(after.toString() == "1.2345679E+9");
	before = 1235;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,124,1]");
	before = 12359;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,124,2]");
	before = 1245;
	after = before;
	round(after, ctx3);;
//writeln("after = ", after.toAbstract);
	assertTrue(after.toAbstract() == "[0,125,1]");
	before = 12459;
	after = before;
	round(after, ctx3);;
	assertTrue(after.toAbstract() == "[0,125,2]");
	Dec32 a = Dec32(0.1);
	Dec32 b = Dec32(1, Dec32.context32.minExpo) * Dec32(8888888);
//	  assertTrue(b.toAbstract == "[0,8888888,-95]");
	Dec32 c = a * b;
//	  assertTrue(c.toAbstract == "[0,888889,-96]");
	Dec32 d = a * a * b;
//	  assertTrue(d.toAbstract == "[0,88889,-97]");
	Dec32 e = a * a * a * b;
//	  assertTrue(e.toAbstract == "[0,8889,-98]");
	Dec32 f = a * a * a * a * b;
//	  assertTrue(f.toAbstract == "[0,889,-99]");
	Dec32 g = a * a * a * a * a * b;
//	  assertTrue(g.toAbstract == "[0,89,-100]");
	Dec32 h = a * a * a * a * a * a * b;
//	  assertTrue(h.toAbstract == "[0,9,-101]");
	Dec32 i = a * a * a * a * a * a * a * b;
//	  assertTrue(i.toAbstract == "[0,0,-101]");
	writeln("passed");
}

unittest {
	write("numDigits....");
	BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertTrue(numDigits(big) == 101);
	writeln("passed");
}

unittest {
	write("firstDigit...");
	BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	assertTrue(firstDigit(big) == 8);
	writeln("passed");
}

unittest {
	write("decShl.......");
	BigInt m;
	int n;
	m = 12345;
	n = 2;
//	  writeln("decShl(m,n) = ", decShl(m,n));
	assertEqual!BigInt(decShl(m,n), BigInt(1234500));
	m = 1234567890;
	n = 7;
	assertEqual(decShl(m,n), BigInt(12345678900000000));
	m = 12;
	n = 2;
	assertEqual!BigInt(decShl(m,n), BigInt(1200));
	m = 12;
	n = 4;
	assertEqual!BigInt(decShl(m,n), BigInt(120000));
	writeln("passed");
}

unittest {
	write("lastDigit....");
	BigInt n;
	n = 7;
	assertTrue(lastDigit(n) == 7);
	n = -13;
	assertTrue(lastDigit(n) == 3);
	n = 999;
	assertTrue(lastDigit(n) == 9);
	n = -9999;
	assertTrue(lastDigit(n) == 9);
	n = 25987;
	assertTrue(lastDigit(n) == 7);
	n = -5008615;
	assertTrue(lastDigit(n) == 5);
	n = 3234567893;
	assertTrue(lastDigit(n) == 3);
	n = -10000000000;
	assertTrue(lastDigit(n) == 0);
	n = 823456789012348;
	assertTrue(lastDigit(n) == 8);
	n = 4234567890123456;
	assertTrue(lastDigit(n) == 6);
	n = 623456789012345674;
	assertTrue(lastDigit(n) == 4);
	n = long.max;
	assertTrue(lastDigit(n) == 7);
	writeln("passed");
}

unittest {
	write("decShl.......");
	long m;
	int n;
	m = 12345;
	n = 2;
	assertTrue(decShl(m,n) == 1234500);
	m = 1234567890;
	n = 7;
	assertTrue(decShl(m,n) == 12345678900000000);
	m = 12;
	n = 2;
	assertTrue(decShl(m,n) == 1200);
	m = 12;
	n = 4;
	assertTrue(decShl(m,n) == 120000);
	/*	  m = long.max;
		n = 18;
		assertTrue(decShl(m,n) == 9);*/
	writeln("passed");
}

unittest {
	write("lastDigit....");
	long n;
	n = 7;
	assertTrue(lastDigit(n) == 7);
	n = -13;
	assertTrue(lastDigit(n) == 3);
	n = 999;
	assertTrue(lastDigit(n) == 9);
	n = -9999;
	assertTrue(lastDigit(n) == 9);
	n = 25987;
	assertTrue(lastDigit(n) == 7);
	n = -5008615;
	assertTrue(lastDigit(n) == 5);
	n = 3234567893;
	assertTrue(lastDigit(n) == 3);
	n = -10000000000;
	assertTrue(lastDigit(n) == 0);
	n = 823456789012348;
	assertTrue(lastDigit(n) == 8);
	n = 4234567890123456;
	assertTrue(lastDigit(n) == 6);
	n = 623456789012345674;
	assertTrue(lastDigit(n) == 4);
	n = long.max;
	assertTrue(lastDigit(n) == 7);
	writeln("passed");
}

unittest {
	write("firstDigit...");
	long n;
	n = 7;
	int expected, actual;
	expected = 7;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 13;
	expected = 1;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 999;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 9999;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 25987;
	expected = 2;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 5008617;
	expected = 5;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 3234567890;
	expected = 3;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 10000000000;
	expected = 1;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 823456789012345;
	expected = 8;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 4234567890123456;
	expected = 4;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = 623456789012345678;
	expected = 6;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	n = long.max;
	expected = 9;
	actual = firstDigit(n);
	assertEqual(expected, actual);
	writeln("passed");
}

unittest {
	write("numDigits....");
	ulong n;
	int expect, actual;
	n = 7;
	expect = 1;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 13;
	expect = 2;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 999;
	expect = 3;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 9999;
	expect = 4;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 25987;
	expect = 5;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 2008617;
	expect = 7;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 1234567890;
	expect = 10;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 10000000000;
	expect = 11;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 123456789012345;
	expect = 15;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 1234567890123456;
	expect = 16;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = 123456789012345678;
	expect = 18;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	n = long.max;
	expect = 19;
	actual = numDigits(n);
	assertEqual!int(expect, actual);
	writeln("passed");
}

/*unittest {
	write("roundByMode....");
//	  DecimalContext context;
	context.precision = 5;
	context.rounding = Rounding.HALF_EVEN;
	BigDecimal num;
	num = 1000;
	roundByMode(num, context);
	assertTrue(num.mant == 1000 && num.expo == 0 && num.digits == 4);
	num = 1000000;
	roundByMode(num, context);
	assertTrue(num.mant == 10000 && num.expo == 2 && num.digits == 5);
	num = 99999;
	roundByMode(num, context);
	assertTrue(num.mant == 99999 && num.expo == 0 && num.digits == 5);
	num = 1234550;
	roundByMode(num, context);
	assertTrue(num.mant == 12346 && num.expo == 2 && num.digits == 5);
	context.rounding = Rounding.DOWN;
	num = 1234550;
	roundByMode(num, context);
	assertTrue(num.mant == 12345 && num.expo == 2 && num.digits == 5);
	context.rounding = Rounding.UP;
	num = 1234550;
	roundByMode(num, context);
	assertTrue(num.mant == 12346 && num.expo == 2 && num.digits == 5);
	writeln("passed");
}*/

/*unittest {
	write("getRemainder...");
	pushContext(context);
	context.precision = 5;
	BigDecimal num, acrem, exnum, exrem;
	num = BigDecimal(1234567890123456L);
	acrem = getRemainder(num, context);
	exnum = BigDecimal("1.2345E+15");
	assertTrue(num == exnum);
	exrem = 67890123456;
	assertTrue(acrem == exrem);
	context = popContext();
	writeln("passed");
}*/

/*unittest {
	write("increment......");
	BigDecimal num;
	BigDecimal expd;
	num = 10;
	expd = 11;
	increment(num);
	assertTrue(num == expd);
	num = 19;
	expd = 20;
	increment(num);
	assertTrue(num == expd);
	num = 999;
	expd = 1000;
	increment(num);
	assertTrue(num == expd);
	writeln("passed");
	writeln("---------------------");
}*/

unittest {
	write("setExponent..");
	auto ctx5 = testContext.setPrecision(5);
	ulong num;
	uint digits;
	int expo;
	num = 1000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx5);
	assertTrue(num == 1000 && expo == 0 && digits == 4);
	num = 1000000;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx5);
	assertTrue(num == 10000 && expo == 2 && digits == 5);
	num = 99999;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx5);
	assertTrue(num == 99999 && expo == 0 && digits == 5);
	num = 1234550;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctx5);
	assertTrue(num == 12346 && expo == 2 && digits == 5);
	auto ctxDn = ctx5.setRounding(Rounding.DOWN);
	num = 1234550;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctxDn);
	assertTrue(num == 12345 && expo == 2 && digits == 5);
	auto ctxUp = ctx5.setRounding(Rounding.UP);
	num = 1234550;
	digits = numDigits(num);
	expo = setExponent(false, num, digits, ctxUp);
	assertTrue(num == 12346 && expo == 2 && digits == 5);
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
	assertTrue(num == exnum);
	exrem = 67890123456L;
	assertTrue(acrem == exrem);
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
	assertTrue(num == expd);
	assertTrue(digits == 2);
	num = 19;
	expd = 20;
	digits = numDigits(num);
	increment(num, digits);
	assertTrue(num == expd);
	assertTrue(digits == 2);
	num = 999;
	expd = 1000;
	digits = numDigits(num);
	increment(num, digits);
	assertTrue(num == expd);
	assertTrue(digits == 4);
	writeln("passed");
}
*/
unittest {
	writeln("---------------------");
	writeln("rounding.....finished");
	writeln("---------------------");
}

unittest {
	writeln("---------------------");
	writeln("decimal32.....testing");
	writeln("---------------------");
}

unittest {
	write("this(long)........");
	Dec32 num = Dec32(1234567890L);
	assertTrue(num.toString == "1.234568E+9");
	num = Dec32(0);
	assertTrue(num.toString == "0");
	num = Dec32(1);
	assertTrue(num.toString == "1");
	num = Dec32(-1);
	assertTrue(num.toString == "-1");
	num = Dec32(5);
	assertTrue(num.toString == "5");
	writeln("passed");
}

unittest {
	write("this(long,int)....");
	Dec32 num;
	num = Dec32(1234567890L, 5);
	assertTrue(num.toString == "1.234568E+14");
	num = Dec32(0, 2);
	assertTrue(num.toString == "0E+2");
	num = Dec32(1, 75);
	assertTrue(num.toString == "1E+75");
	num = Dec32(-1, -75);
	assertTrue(num.toString == "-1E-75");
	num = Dec32(5, -3);
	assertTrue(num.toString == "0.005");
	writeln("passed");
}

// (T)TODO: is there a this(BigInt)?
// should there be?
/*unittest {
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
	writeln("passed");
}*/

unittest {
	write("this(BigDecimal)..");
	BigDecimal dec = 0;
	Dec32 num = dec;
	assertTrue(dec.toString == num.toString);
	dec = 1;
	num = dec;
	assertTrue(dec.toString == num.toString);
	dec = -1;
	num = dec;
	assertTrue(dec.toString == num.toString);
	dec = -16000;
	num = dec;
	assertTrue(dec.toString == num.toString);
	dec = uint.max;
	num = dec;
	assertTrue(num.toString == "4.294967E+9");
	assertTrue(dec.toString == "4294967295");
	dec = 9999999E+12;
	num = dec;
	assertTrue(dec.toString == num.toString);
	writeln("passed");
}

unittest {
	write("this(str).........");
	Dec32 num;
	num = Dec32("1.234568E+9");
	assertTrue(num.toString == "1.234568E+9");
	num = Dec32("NaN");
	assertTrue(num.isQuiet && num.isSpecial && num.isNaN);
	num = Dec32("-inf");
	assertTrue(num.isInfinite && num.isSpecial && num.isNegative);
	writeln("passed");
}

unittest {
	write("this(real)........");
	real r = 1.2345E+16;
	Dec32 actual = Dec32(r);
	Dec32 expect = Dec32("1.2345E+16");
	assertEqual(expect,actual);
	writeln("passed");
}

unittest {
	write("coefficient.......");
	Dec32 num;
	assertTrue(num.coefficient == 0);
	num = 9.998743;
	assertTrue(num.coefficient == 9998743);
	num = Dec32(9999213,-6);
	assertTrue(num.coefficient == 9999213);
	num = -125;
	assertTrue(num.coefficient == 125);
	num = 99999999;
	assertTrue(num.coefficient == 1000000);
	// (T)TODO: test explicit, implicit, nan and infinity.
	writeln("passed");
}

unittest {
	write("exponent..........");
	Dec32 num;
	// reals
	num = std.math.PI;
	assertTrue(num.exponent == -6);
	num = 9.75E89;
	assertTrue(num.exponent == 87);
	// explicit
	num = 8388607;
	assertTrue(num.exponent == 0);
	// implicit
	num = 8388610;
	assertTrue(num.exponent == 0);
	num = 9.999998E23;
	assertTrue(num.exponent == 17);
	num = 9.999999E23;
	assertTrue(num.exponent == 17);

	num = Dec32(-12000,5);
	num.exponent = 10;
	assertTrue(num.exponent == 10);
	num = Dec32(-9000053,-14);
	num.exponent = -27;
	assertTrue(num.exponent == -27);
	num = Dec32.infinity;
	assertTrue(num.exponent == 0);
	// (4) (T)TODO: test overflow and underflow.
	writeln("passed");
}

unittest {
	write("payload...........");
	Dec32 num;
	assertTrue(num.payload == 0);
	num = Dec32.snan;
	assertTrue(num.payload == 0);
	num.payload = 234;
	assertTrue(num.payload == 234);
	assertTrue(num.toString == "sNaN234");
	num = 1234567;
	assertTrue(num.payload == 0);
	writeln("passed");
}

unittest {
	write("opCmp.............");
	Dec32 a, b;
	a = Dec32(104.0);
	b = Dec32(105.0);
	assertTrue(a < b);
	assertTrue(b > a);
	writeln("passed");
}

unittest {
	write("opEquals..........");
	Dec32 a, b;
	a = Dec32(105);
	b = Dec32(105);
	assertTrue(a == b);
	writeln("passed");
}

unittest {
	write("opAssign(Dec32)...");
	Dec32 rhs, lhs;
	rhs = Dec32(270E-5);
	lhs = rhs;
	assertTrue(lhs == rhs);
	writeln("passed");
}

unittest {
	write("opAssign(numeric).");
	Dec32 rhs;
	rhs = 332089;
	assertTrue(rhs.toString == "332089");
	rhs = 3.1415E+3;
	assertTrue(rhs.toString == "3141.5");
	writeln("passed");
}

unittest {
	write("opUnary...........");
	Dec32 num, actual, expect;
	num = 134;
	expect = num;
	actual = +num;
	assertTrue(actual == expect);
	num = 134.02;
	expect = -134.02;
	actual = -num;
	assertTrue(actual == expect);
	num = 134;
	expect = 135;
	actual = ++num;
	assertTrue(actual == expect);
	// (T)TODO: seems to be broken for nums like 1.000E8
	num = 12.35;
	expect = 11.35;
	actual = --num;
	assertTrue(actual == expect);
	writeln("passed");
}

unittest {
	write("opBinary..........");
	Dec32 op1, op2, actual, expect;
	op1 = 4;
	op2 = 8;
	actual = op1 + op2;
	expect = 12;
	assertEqual(expect,actual);
	actual = op1 - op2;
	expect = -4;
	assertEqual(expect,actual);
	actual = op1 * op2;
	expect = 32;
	assertEqual(expect,actual);
	op1 = 5;
	op2 = 2;
	actual = op1 / op2;
	expect = 2.5;
	assertEqual(expect,actual);
	op1 = 10;
	op2 = 3;
	actual = op1 % op2;
	expect = 1;
	assertEqual(expect,actual);
	writeln("passed");
}

unittest {
	write("opOpAssign........");
	Dec32 op1, op2, actual, expect;
	op1 = 23.56;
	op2 = -2.07;
	op1 += op2;
	expect = 21.49;
	actual = op1;
	assertEqual(expect,actual);
	op1 *= op2;
	expect = -44.4843;
	actual = op1;
	assertEqual(expect,actual);
	writeln("passed");
}

unittest {
	write("toBigDecimal......");
	Dec32 num = Dec32("12345E+17");
	BigDecimal expected = BigDecimal("12345E+17");
	BigDecimal actual = num.toBigDecimal;
	assertTrue(actual == expected);
	writeln("passed");
}

unittest {
	write("toLong............");
	Dec32 num;
	num = -12345;
	assertTrue(num.toLong == -12345);
	num = 2 * int.max;
	assertTrue(num.toLong == 2 * int.max);
	num = 1.0E6;
	assertTrue(num.toLong == 1000000);
	num = -1.0E60;
	assertTrue(num.toLong == long.min);
	num = Dec32.infinity(true);
	assertTrue(num.toLong == long.min);
	writeln("passed");
}

unittest {
	write("toInt.............");
	Dec32 num;
	num = 12345;
	assertTrue(num.toInt == 12345);
	num = 1.0E6;
	assertTrue(num.toInt == 1000000);
	num = -1.0E60;
	assertTrue(num.toInt == int.min);
	num = Dec32.infinity(true);
	assertTrue(num.toInt == int.min);
	writeln("passed");
}

unittest {
	write("toString..........");
	string str;
	str = "-12.345E-42";
	Dec32 num = Dec32(str);
	assertTrue(num.toString == "-1.2345E-41");
	writeln("passed");
}

unittest {
	write("toAbstract........");
	Dec32 num;
	num = Dec32("-25.67E+2");
	assertTrue(num.toAbstract == "[1,2567,0]");
	writeln("test missing");
}

unittest {
	write("toExact...........");
	Dec32 num;
	assertTrue(num.toExact == "+NaN");
	num = Dec32.max;
	assertTrue(num.toExact == "+9999999E+90");
	num = 1;
	assertTrue(num.toExact == "+1E+00");
	num = Dec32.infinity(true);
	assertTrue(num.toExact == "-Infinity");
	writeln("passed");
}

unittest {
	write("pow10.............");
	assertTrue(Dec32.pow10(3) == 1000);
	writeln("passed");
}

unittest {
	write("hexstring.........");
	Dec32 num = 12345;
	assertTrue(num.toHexString == "0x32803039");
	assertTrue(num.toBinaryString == "00110010100000000011000000111001");
	writeln("passed");
}

unittest {
	write("isIntegral........");
	Dec32 num;
	num = 22;
	assertTrue(num.isIntegral);
	num = 200E-2;
	assertTrue(num.isIntegral);
	num = 201E-2;
	assertTrue(!num.isIntegral);
	num = Dec32.INFINITY;
	assertTrue(!num.isIntegral);
	writeln("passed");
}

unittest {
	writeln("---------------------");
	writeln("decimal32....finished");
	writeln("---------------------");
}

unittest {
	writeln("---------------------------");
	writeln("test...............finished");
	writeln("---------------------------");
}

