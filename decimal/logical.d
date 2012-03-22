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
	writeln("===================");
	writeln("logical.......begin");
	writeln("===================");
}

// (L)TODO: move units tests to test.d
// NOTE: arguments must be of the same type -- e.g. can't 'and' Dec32 w/ Dec64
// (L)TODO: Why not?

/**
 * isLogical.
 */
public bool isLogicalString(const string str) {
	foreach(char ch; str) {
		if (ch != '0' && ch != '1') return false;
	}
	return true;
}

public bool isLogical(T)(const T arg) if (isDecimal!T) {
	if (arg.sign != 0 || arg.exponent != 0) return false;
	string str = to!string(arg.coefficient);
	return isLogicalString(str);
}

private bool isLogicalOperand(T)(const T arg, out string str) if (isDecimal!T) {
	if (arg.sign != 0 || arg.exponent != 0) return false;
	str = to!string(arg.coefficient);
	return isLogicalString(str);
}

T invert(T: string)(T arg) {
	char[] result = new char[arg.length];
	for(int i = 0; i < arg.length; i++) {
		if (arg[i] == '0') {
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
T invert(T)(T arg, const DecimalContext context) if (isDecimal!T) {
	string str;
	if (!isLogicalOperand(arg, str)) {
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
	if (arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if (arg1.length < arg2.length) {
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
		if (str1[i] == '1' && str2[i] == '1') {
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
	if (arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if (arg1.length < arg2.length) {
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
		if (str1[i] == '1' || str2[i] == '1') {
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
	if (arg1.length > arg2.length) {
		length = arg1.length;
		str1 = arg1;
		str2 = rightJustify(arg2, '0');
	}
	if (arg1.length < arg2.length) {
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
		if (str1[i] != str2[i]) {
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

// (L)TODO: add opBinary("&", "|", "^")
/**
 * Decimal version of and.
 * Required by General Decimal Arithmetic Specification
 */
private T opLogical(string op, T)(const T arg1, const T arg2, const DecimalContext context) {
	string str1;
	if (!isLogicalOperand(arg1, str1)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	string str2;
	if (!isLogicalOperand(arg2, str2)) {
		contextFlags.setFlags(INVALID_OPERATION);
		return T.nan;
	}
	static if (op == "and") {
		string str = strAnd (str1, str2);
	}
	static if (op == "or") {
		string str = strOr (str1, str2);
	}
	static if (op == "xor") {
		string str = strXor(str1, str2);
	}
	return T(str);
}

/**
 * Decimal version of and.
 * Required by General Decimal Arithmetic Specification
 */
public T and (T)(const T arg1, const T arg2, const DecimalContext context) if (isDecimal!T) {
	return opLogical!("and", T)(arg1, arg2, context);
}

/**
 * Decimal version of or.
 * Required by General Decimal Arithmetic Specification
 */
public T or (T)(const T arg1, const T arg2, const DecimalContext context) if (isDecimal!T) {
	return opLogical!("or", T)(arg1, arg2, context);
}

/**
 * Decimal version of xor.
 * Required by General Decimal Arithmetic Specification
 */

public T xor(T)(const T arg1, const T arg2, const DecimalContext context) if (isDecimal!T) {
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

// (L)TODO: move this to decimal.logical
/// Shifts the first operand by the specified number of decimal digits.
/// (Not binary digits!) Positive values of the second operand shift the
/// first operand left (multiplying by tens). Negative values shift right
/// (divide by 10s). If the number is NaN, or if the shift value is less
/// than -precision or greater than precision, an INVALID_OPERATION is signaled.
/// An infinite number is returned unchanged.
/// Implements the 'shift' function in the specification. (p. 49)
public T shift(T)(const T arg, const int n, DecimalContext context)
		if (isDecimal!T) {

	T arg2;
	// check for NaN operand
	if (invalidOperand!T(arg, arg2)) {
		return arg2;
	}
	if (n < -context.precision || n > context.precision) {
		arg2 = setInvalidFlag!T();
		return arg2;
	}
	if (arg.isInfinite) {
		return arg.dup;
	}
	if (n == 0) {
		return arg.dup;
	}
	BigDecimal shifted = toBigDecimal!T(arg);
	BigInt pow10 = BigInt(10)^^std.math.abs(n);
	if (n > 0) {
		shifted.coefficient = shifted.coefficient * pow10;
	}
	else {
		shifted.coefficient = shifted.coefficient / pow10;
	}
	return T(shifted);
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


/// Rotates the first operand by the specified number of decimal digits.
/// (Not binary digits!) Positive values of the second operand rotate the
/// first operand left (multiplying by tens). Negative values rotate right
/// (divide by 10s). If the number is NaN, or if the rotate value is less
/// than -precision or greater than precision, an INVALID_OPERATION is signaled.
/// An infinite number is returned unchanged.
/// Implements the 'rotate' function in the specification. (p. 47-48)
public T rotate(T)(const T arg1, const int arg2, DecimalContext context)
		if (isDecimal!T) {

	T result;
	// check for NaN operand
	if (invalidOperand!T(arg1, result)) {
		return result;
	}
	if (arg2 < -context.precision || arg2 > context.precision) {
		result = setInvalidFlag();
		return result;
	}
	if (arg1.isInfinite) {
		return arg1.dup;
	}
	if (arg2 == 0) {
		return arg1.dup;
	}
	result = arg1.dup;

	// (L)TODO: And then a miracle happens....

	return result;
}



unittest {
	writeln("===================");
	writeln("logical.........end");
	writeln("===================");
}

