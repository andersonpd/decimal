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

module decimal.logical;

import std.stdio;
import std.string;

import decimal.arithmetic;
import decimal.context;
import decimal.conv;
import decimal.utils;

unittest {
	writeln("-------------------");
	writeln("logical.......begin");
	writeln("-------------------");
}

// TODO: move units tests to test.d
// NOTE: arguments must be of the same type -- e.g. can't and Dec32 w/ Dec64

/**
 * isLogical.
 */
public bool isLogicalString(const string str) {
	foreach(char ch; str) {
		if(ch != '0' && ch != '1') return false;
	}
	return true;
}

public bool isLogical(T)(const T arg) if (isDecimal!T) {
	if(arg.sign != 0 || arg.exponent != 0) return false;
	string str = to!string(arg.coefficient);
	return isLogicalString(str);
}

private bool isLogicalOperand(T)(const T arg, out string str) if (isDecimal!T) {
	if(arg.sign != 0 || arg.exponent != 0) return false;
	str = to!string(arg.coefficient);
	return isLogicalString(str);
}

T invert(T: string)(T arg) {
	char[] result = new char[arg.length];
	for(int i = 0; i < arg.length; i++) {
		if(arg[i] == '0') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
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

/**
 * Decimal version of invert.
 * Required by General Decimal Arithmetic Specification
 */
T invert(T)(T arg, DecimalContext context) if (isDecimal!T) {
	string str;
	if(!isLogicalOperand(arg, str)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	return T(invert(str));
}

unittest {
	write("decimal invert..");
	import decimal.dec32;
	Dec32 arg;
	Dec32 expected, actual;
	arg = Dec32.TRUE;
	actual = invert(arg, Dec32.context32);
	expected = Dec32.FALSE;
	assertEqual(expected, actual);
	actual = invert(actual, Dec32.context32);
	expected = Dec32.TRUE;
	assertEqual(expected, actual);
	arg = Dec32("131010");
	actual = invert(arg, Dec32.context32);
	assertTrue(actual.isNaN);
	arg = Dec32("101010");
	actual = invert(arg, Dec32.context32);
	expected = Dec32("010101");
	assertEqual(expected, actual);
	writeln("passed");
}

T strAnd (T: string)(const T arg1, const T arg2) {
	string str1, str2;
	int length;
	if(arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if(arg1.length < arg2.length) {
		length = arg2.length;
		str1 = rightJustify(arg1, '0');
		str2 = arg2;
	} else {
		length = arg1.length;
		str1 = arg1;
		str2 = arg2;
	}
	char[] result = new char[length];
	for(int i = 0; i < length; i++) {
		if(str1[i] == '1' && str2[i] == '1') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

T strOr (T: string)(const T arg1, const T arg2) {
	string str1, str2;
	int length;
	if(arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if(arg1.length < arg2.length) {
		length = arg2.length;
		str1 = rightJustify(arg1, '0');
		str2 = arg2;
	} else {
		length = arg1.length;
		str1 = arg1;
		str2 = arg2;
	}
	char[] result = new char[length];
	for(int i = 0; i < length; i++) {
		if(str1[i] == '1' || str2[i] == '1') {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

T strXor(T: string)(const T arg1, const T arg2) {
	string str1, str2;
	int length;
	if(arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if(arg1.length < arg2.length) {
		length = arg2.length;
		str1 = rightJustify(arg1, '0');
		str2 = arg2;
	} else {
		length = arg1.length;
		str1 = arg1;
		str2 = arg2;
	}
	char[] result = new char[length];
	for(int i = 0; i < length; i++) {
		if(str1[i] != str2[i]) {
			result[i] = '1';
		} else {
			result[i] = '0';
		}
	}
	return result.idup;
}

unittest {
	write("string binary...");
	string str1, str2;
	string expected, actual;
	str1 = "0";
	str2 = "0";
	actual = strAnd (str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = strOr (str1, str2);
	assertEqual(expected, actual);
	actual = strXor(str1, str2);
	assertEqual(expected, actual);
	str1 = "0";
	str2 = "1";
	actual = strAnd (str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = strOr (str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = strXor(str1, str2);
	assertEqual(expected, actual);
	str1 = "1";
	str2 = "0";
	actual = strAnd (str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	actual = strOr (str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = strXor(str1, str2);
	assertEqual(expected, actual);
	str1 = "1";
	str2 = "1";
	actual = strAnd (str1, str2);
	expected = "1";
	assertEqual(expected, actual);
	actual = strOr (str1, str2);
	assertEqual(expected, actual);
	actual = strXor(str1, str2);
	expected = "0";
	assertEqual(expected, actual);
	str1 = "1";
	str2 = "10";
	expected = "00";
	actual = strAnd (str1, str2);
	assertEqual(expected, actual);
	writeln("passed");
}

// TODO: add opBinary("&", "|", "^")
/**
 * Decimal version of and.
 * Required by General Decimal Arithmetic Specification
 */
private T opLogical(string op, T)(const T arg1, const T arg2, DecimalContext context) {
	string str1;
	if(!isLogicalOperand(arg1, str1)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	string str2;
	if(!isLogicalOperand(arg2, str2)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	static if(op == "and") {
		string str = strAnd (str1, str2);
	}
	static if(op == "or") {
		string str = strOr (str1, str2);
	}
	static if(op == "xor") {
		string str = strXor(str1, str2);
	}
	return T(str);
}

/**
 * Decimal version of and.
 * Required by General Decimal Arithmetic Specification
 */
public T and (T)(const T arg1, const T arg2, DecimalContext context) if (isDecimal!T) {
	return opLogical!("and", T)(arg1, arg2, context);
}

/**
 * Decimal version of or.
 * Required by General Decimal Arithmetic Specification
 */
public T or (T)(const T arg1, const T arg2, DecimalContext context) if (isDecimal!T) {
	return opLogical!("or", T)(arg1, arg2, context);
}

/**
 * Decimal version of xor.
 * Required by General Decimal Arithmetic Specification
 */

public T xor(T)(const T arg1, const T arg2, DecimalContext context) if (isDecimal!T) {
	return opLogical!("xor", T)(arg1, arg2, context);
}

unittest {
	import decimal.dec32;
	write("decimal binary..");
	Dec32 arg1, arg2;
	Dec32 expected, actual;

	arg1 = 0;
	arg2 = 0;
	actual = and (arg1, arg2, Dec32.context32);
	expected = 0;
	actual = or (arg1, arg2, Dec32.context32);
	expected = 0;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context32);
	expected = 0;
	assertEqual(expected, actual);

	arg1 = 0;
	arg2 = 1;
	actual = and (arg1, arg2, Dec32.context32);
	expected = 0;
	actual = or (arg1, arg2, Dec32.context32);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context32);
	expected = 1;
	assertEqual(expected, actual);

	arg1 = 1;
	arg2 = 0;
	actual = and (arg1, arg2, Dec32.context32);
	expected = 0;
	actual = or (arg1, arg2, Dec32.context32);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context32);
	expected = 1;
	assertEqual(expected, actual);

	arg1 = 1;
	arg2 = 1;
	actual = and (arg1, arg2, Dec32.context32);
	expected = 1;
	actual = or (arg1, arg2, Dec32.context32);
	expected = 1;
	assertEqual(expected, actual);
	actual = xor(arg1, arg2, Dec32.context32);
	expected = 0;
	assertEqual(expected, actual);

	writeln("passed");
}

unittest {
	writeln("-------------------");
	writeln("logical.........end");
	writeln("-------------------");
}

