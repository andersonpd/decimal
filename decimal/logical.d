// Written in the D programming language

/**
 *
 * A D programming language implementation of the
 * General T Arithmetic Specification,
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

import decimal.conv;
import decimal.context;
import decimal.arithmetic;
import std.stdio;
import std.string;

unittest {
    writeln("-------------------");
    writeln("logical.......begin");
    writeln("-------------------");
}

/**
 * isLogical.
 */
public bool isLogicalString(const string str) {
    foreach (char ch; str) {
        if (ch != '0' && ch != '1') return false;
    }
    return true;
}

public bool isLogical(T)(const T num) if (isDecimal!T) {
    if (num.sign != 0 || num.exponent != 0) return false;
    string str = to!string(num.coefficient);
    return isLogicalString(str);
}

private bool isLogicalOperand(T)(const T num, out string str) if (isDecimal!T) {
    if (num.sign != 0 || num.exponent != 0) return false;
    str = to!string(num.coefficient);
    return isLogicalString(str);
}

/*public T toLogical(T)(const T num) if (isDecimal!T) {
    T logical = num.dup;
    logical.sign = 0;
    logical.exponent = 0;
    string str = to!string(logical.coefficient);
    if (isLogicalString(str)) {
        return logical;
    }
    char[] mant = new char[str.length];
    for (int i = 0; i < str.length; i++) {
        char ch = str[i];
        mant[i] = (ch == '0') ? '0' : '1';
    }
    return T(mant.idup);
}

unittest {
    import decimal.dec32;
    write("isLogical....");
    Dec32 num = Dec32("10101");
    assertTrue(isLogical(num));
    num = 3;
    assertFalse(isLogical(num));
    num = 10101;
    assertTrue(isLogical(num));
    num = -10101;
    assertFalse(isLogical(num));
    num = 10101E21;
    assertFalse(isLogical(num));
    writeln("passed");

    write("toLogical....");
    num = Dec32("10101");
    string expect, actual;
    expect = "10101";
    actual = toLogical(num).toString;
    assertEqual(expect, actual);
    num = 3;
    expect = "1";
    actual = toLogical(num).toString;
    assertEqual(expect, actual);
    num = 10101;
    expect = "10101";
    actual = toLogical(num).toString;
    assertEqual(expect, actual);
    num = -10101;
    expect = "10101";
    actual = toLogical(num).toString;
    assertEqual(expect, actual);
    num = 12345;
    expect = "11111";
    actual = toLogical(num).toString;
    assertEqual(expect, actual);
    writeln("passed");
}

public T toLogical(T)(
        const string str, DecimalContext context) if (isDecimal!T) {
    string mant = str[$ - context.precision..$];
    return T(mant.idup);
}*/

T invert(T:string)(T arg1) {
    char[] result = new char[arg1.length];
    for (int i = 0; i < arg1.length; i++) {
        if (arg1[i] == '0') {
            result[i] = '1';
        }
        else {
            result[i] = '0';
        }
    }
    return result.idup;
}

unittest {
    write("invert...");
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

T and(T:string)(const T arg1, const T arg2) {
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
    }
    else {
        length = arg1.length;
        str1 = arg1;
        str2 = arg2;
    }
    char[] result = new char[length];
    for (int i = 0; i < length; i++) {
        if (str1[i] == '1' && str2[i] == '1') {
            result[i] = '1';
        }
        else {
            result[i] = '0';
        }
    }
    return result.idup;
}

T or(T:string)(const T arg1, const T arg2) {
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
    }
    else {
        length = arg1.length;
        str1 = arg1;
        str2 = arg2;
    }
    char[] result = new char[length];
    for (int i = 0; i < length; i++) {
        if (str1[i] == '1' || str2[i] == '1') {
            result[i] = '1';
        }
        else {
            result[i] = '0';
        }
    }
    return result.idup;
}

T xor(T:string)(const T arg1, const T arg2) {
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
    }
    else {
        length = arg1.length;
        str1 = arg1;
        str2 = arg2;
    }
    char[] result = new char[length];
    for (int i = 0; i < length; i++) {
        if (str1[i] != str2[i]) {
            result[i] = '1';
        }
        else {
            result[i] = '0';
        }
    }
    return result.idup;
}


unittest {
    write("string ops...");
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
    str1 = "1";
    str2 = "10";
    expected = "00";
    actual = and(str1, str2);
    assertEqual(expected, actual);
    writeln("passed");
}

/**
 * T version of invert.
 * Required by General T Arithmetic Specification
 */
T invert(T)(T arg, DecimalContext context) if (isDecimal!T) {
    string str;
    if (!isLogicalOperand(arg, str)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    return T(invert(str));
}

unittest {
    write("invert...");
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

// TODO: add opBinary("&", "|", "^")
/**
 * T version of and.
 * Required by General T Arithmetic Specification
 */
T opLogical(string op, T)(const T arg1, const T arg2, DecimalContext context) {
    string str1;
    if (!isLogicalOperand(arg1, str1)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    string str2;
    if (!isLogicalOperand(arg2, str2)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    static if (op == "and") {
        string str = and(str1, str2);
    }
    static if (op == "or") {
        string str = or(str1, str2);
    }
    static if (op == "xor") {
        string str = xor(str1, str2);
    }
    return T(str);
}

// TODO: unit test these -- compare opLogical template vs. copied implementation
/**
 * T version of and.
 * Required by General T Arithmetic Specification
 */
T and(T)(const T arg1, const T arg2, DecimalContext context) {
    return opLogical!("and", T)(arg1, arg2, context);
}

T or(T)(const T arg1, const T arg2, DecimalContext context) {
    return opLogical!("or", T)(arg1, arg2, context);
}

T xor(T)(const T arg1, const T arg2, DecimalContext context) {
    return opLogical!("xor", T)(arg1, arg2, context);
}

/**
 * T version of or.
 * Required by General T Arithmetic Specification
 */
/*T or(T)(const T arg1, const T arg2, DecimalContext context) {
    string str1;
    if (!isLogicalOperand(arg1, str1)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    string str2;
    if (!isLogicalOperand(arg2, str2)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    string str = or(str1, str2);
    return T(str);
}*/

/**
 * T version of xor.
 * Required by General T Arithmetic Specification
 */
/*T xor(T)(const T arg1, const T arg2, DecimalContext context) {
    string str1;
    if (!isLogicalOperand(arg1, str1)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    string str2;
    if (!isLogicalOperand(arg2, str2)) {
        context.setFlags(INVALID_OPERATION);
        return T.nan;
    }
    string str = xor(str1, str2);
    return T(str);
}*/


unittest {
    import decimal.dec32;
    write("decimal ops.");
    Dec32 arg1, arg2;
    Dec32 expected, actual;

    arg1 = 0;
    arg2 = 0;
    actual = and(arg1, arg2, Dec32.context32);
    expected = 0;
    actual = or(arg1, arg2, Dec32.context32);
    expected = 0;
    assertEqual(expected, actual);
    actual = xor(arg1, arg2, Dec32.context32);
    expected = 0;
    assertEqual(expected, actual);

    arg1 = 0;
    arg2 = 1;
    actual = and(arg1, arg2, Dec32.context32);
    expected = 0;
    actual = or(arg1, arg2, Dec32.context32);
    expected = 1;
    assertEqual(expected, actual);
    actual = xor(arg1, arg2, Dec32.context32);
    expected = 1;
    assertEqual(expected, actual);

    arg1 = 1;
    arg2 = 0;
    actual = and(arg1, arg2, Dec32.context32);
    expected = 0;
    actual = or(arg1, arg2, Dec32.context32);
    expected = 1;
    assertEqual(expected, actual);
    actual = xor(arg1, arg2, Dec32.context32);
    expected = 1;
    assertEqual(expected, actual);

    arg1 = 1;
    arg2 = 1;
    actual = and(arg1, arg2, Dec32.context32);
    expected = 1;
    actual = or(arg1, arg2, Dec32.context32);
    expected = 1;
    assertEqual(expected, actual);
    actual = xor(arg1, arg2, Dec32.context32);
    expected = 0;
    assertEqual(expected, actual);

    writeln("passed");
}
/*    actual = or(arg1, arg2);
    assertEqual(expected, actual);
    actual = xor(arg1, arg2);
    assertEqual(expected, actual);
    arg1 = "0";
    arg2 = "1";
    actual = and(arg1, arg2);
    expected = "0";
    assertEqual(expected, actual);
    actual = or(arg1, arg2);
    expected = "1";
    assertEqual(expected, actual);
    actual = xor(arg1, arg2);
    assertEqual(expected, actual);
    arg1 = "1";
    arg2 = "0";
    actual = and(arg1, arg2);
    expected = "0";
    assertEqual(expected, actual);
    actual = or(arg1, arg2);
    expected = "1";
    assertEqual(expected, actual);
    actual = xor(arg1, arg2);
    assertEqual(expected, actual);
    arg1 = "1";
    arg2 = "1";
    actual = and(arg1, arg2);
    expected = "1";
    assertEqual(expected, actual);
    actual = or(arg1, arg2);
    assertEqual(expected, actual);
    actual = xor(arg1, arg2);
    expected = "0";
    assertEqual(expected, actual);
    arg1 = "1";
    arg2 = "10";
    expected = "00";
    actual = and(arg1, arg2);
    assertEqual(expected, actual);*/

unittest {
    writeln("-------------------");
    writeln("logical.........end");
    writeln("-------------------");
}

