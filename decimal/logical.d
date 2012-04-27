// Written in the D programming language

/**
 *	A D programming language implementation of the
 *	General Decimal Arithmetic Specification,
 *	Version 1.70, (25 March 2009).
 *	http://www.speleotrove.com/decimal/decarith.pdf)
 *
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt ofcopy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

module decimal.logical;

import std.stdio;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.conv;
import decimal.test;

// (L)TODO: add units tests to test.d


unittest {
	writeln("===================");
	writeln("logical.......begin");
	writeln("===================");
}

unittest {
	write("string invert...");
	string str;
	string expected, actual;
	str = "0";
	actual = invert(str);
	expected = "1";
	assertEqual(expected, actual);
	str = "101010";
	actual = invert(str);
	expected = "010101";
	assertEqual(expected, actual);
	writeln("passed");
}

unittest {
	write("decimal invert..");
	import decimal.dec32;
	Dec32 arg;
	Dec32 expected, actual;
	arg = Dec32.TRUE;
	actual = invert(arg, Dec32.context);
	expected = Dec32.FALSE;
	assertEqual(expected, actual);
	actual = invert(actual, Dec32.context);
	expected = Dec32.TRUE;
	assertEqual(expected, actual);
	arg = Dec32("131010");
	actual = invert(arg, Dec32.context);
	assertTrue(actual.isNaN);
	arg = Dec32("101010");
	actual = invert(arg, Dec32.context);
	expected = Dec32("010101");
	assertEqual(expected, actual);
	writeln("passed");
}

unittest {
	write("string binary...");
	string str1, str2;
	string expected, actual;
	str1 = "0";
	str2 = "0";
	actual = and(str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = or(str1, str2);
	assertEqual(expected, actual);
	actual = xor(str1, str2);
	assertEqual(expected, actual);
	str1 = "0";
	str2 = "1";
	actual = and(str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = or(str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = xor(str1, str2);
	assertEqual(expected, actual);
	str1 = "1";
	str2 = "0";
	actual = and(str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = or(str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = xor(str1, str2);
	assertEqual(expected, actual);
	str1 = "1";
	str2 = "1";
	actual = and(str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = or(str1, str2);
	assertEqual(expected, actual);
	actual = xor(str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	str1 = "101100111000";
	str2 = "1111";
	expected = "1000";
	actual = and!Dec64(str1, str2);
	assertEqual(expected, actual);
	expected = "101100111111";
//	actual = or!Dec64(str1, str2);
	assertEqual(expected, actual);
	str1 = "101100111000";
	str2 = "0001111";
	expected = "0001000";
	actual = and(str1, str2);
	assertEqual(expected, actual);
	writeln("passed");
}

unittest { // and, or, xor
	import decimal.dec32;
	write("decimal binary..");
	Dec32 arg1, arg2;
	Dec32 expected, actual;

	arg1 = 0;
	arg2 = 0;
	actual = and(arg1, arg2, Dec32.context);
	expected = 0;
	actual = of(arg1, arg2, Dec32.context);
	expected = 0;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context);
	expected = 0;
	assertEqual(expected, actual);

	arg1 = 10;
	arg2 = 0;
	actual = and(arg1, arg2, Dec32.context);
	expected = 0;
	arg1 = 10;
	arg2 = 10;
	actual = and (arg1, arg2, Dec32.context);
	expected = 10;
	assertEqual(expected, actual);
	arg1 = 1011;
	arg2 = 10;
	actual = and(arg1, arg2, Dec32.context);
	expected = 10;
	assertEqual(expected, actual);
	arg1 = 1011;
	arg2 = 01;
	actual = and(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);

	arg1 = 0;
	arg2 = 1;
	actual = and(arg1, arg2, Dec32.context);
	expected = 0;
	actual = of(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);

	arg1 = 1;
	arg2 = 0;
	actual = and(arg1, arg2, Dec32.context);
	expected = 0;
	actual = of(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);

	arg1 = 1;
	arg2 = 1;
	actual = and(arg1, arg2, Dec32.context);
	expected = 1;
	actual = of(arg1, arg2, Dec32.context);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context);
	expected = 0;
	assertEqual(expected, actual);

	writeln("passed");
}

/*unittest {
	BigDecimal num = 34;
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
	act = shift(num, digits, testContext);
}*/


unittest {
	writeln("===================");
	writeln("logical.........end");
	writeln("===================");
}

