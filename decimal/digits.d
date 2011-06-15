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

module decimal.digits;

import std.bigint;
import std.conv;
import std.stdio: write, writeln;
import std.string;
import std.typecons: Tuple;

private BigInt tens[18];
private BigInt fives[18];

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
}

//public static ZERO = BigInt();

// TODO: preload the powers of ten and powers of five (& powers of 2?)
// TODO: compare benchmarks for division by chunks of a quintillion vs. tens.
// TODO: compare benchmarks for division by powers of 10 vs. 2s * 5s.

// BigInt versions
unittest {
    writeln(" -- BigInt functions --");
}

/**
 * Returns the number of digits in the number.
 */
public int numDigits(const BigInt big) {
    BigInt billion = pow10(9);
    BigInt quintillion = pow10(18);
    BigInt dig = cast(BigInt)big;
    int count = 0;
    while (dig > quintillion) {
        dig = decShr(dig, 18);
        count += 18;
    }
/*    if (dig > billion) {
        dig = decShr(dig, 9);
        count += 9;
    }*/

    long n = dig.toLong;
    return count + numDigits(n);
}

unittest {
    write("numDigits......");
    BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    assert(numDigits(big) == 101);
    writeln("passed");
}

/**
 * Returns the first digit of the number.
 */
public int firstDigit(const BigInt big) {
    BigInt billion = pow10(9);
    BigInt quintillion = pow10(18);
    BigInt dig = cast()big;
    while (dig > quintillion) {
        dig = decShr(dig, 18);
    }
    if (dig > billion) {
        dig = decShr(dig, 9);
    }

    long n = dig.toLong();
    return firstDigit(n);
}

unittest {
    write("firstDigit.....");
    BigInt big = BigInt("82345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
    assert(firstDigit(big) == 8);
    writeln("passed");
}

/**
 * Returns ten raised to the specified power.
 */
public BigInt pow10(const int n) {
    BigInt big = BigInt(1);
    return decShl(big, n);
}

unittest {
    write("pow10..........");
    int n;
    BigInt pow;
    n = 3;
    assert(pow10(n) == 1000);
    writeln("passed");
}

/**
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public BigInt decShl(ref BigInt big, int n) {
    if (n <= 0) { return big; }

    BigInt fives = 1;
    for (int i = 0; i < n; i++) {
        fives *= 5;
    }
    big = big << n;
    big *= fives;
    return big;
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

/**
 * Shifts the number right by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public BigInt decShr(ref BigInt big, int n) {
    if (n <= 0) { return big; }

    BigInt twos;
    BigInt fives = 1;
    for (int i = 0; i < n; i++) {
        fives *= 5;
    }

    big = big >> n;
    if (big == 0) {
        return big;
    }
    big /= fives;
    return big;
}

unittest {
    write("decShr.........");
    BigInt m;
    int n;
    m = 12345;
    n = 2;
//    writeln("decShr(m,n) = ", decShr(m,n));
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

/**
 * Returns decimal string.
 */
string toDecString(const BigInt x){
    string outbuff="";
    void sink(const(char)[] s) { outbuff ~= s; }
    x.toString(&sink, "d");
    return outbuff;
}

unittest {
    write("toDecString....");
    BigInt num;
    num = 512;
    assert(toDecString(num) == "512");
    writeln("passed");
}

/**
 * Returns a non-const copy of the number.
 */
public BigInt dup(const BigInt big) {
    const BigInt copy = big;
    return cast(BigInt)copy;
}

unittest {
    write("dup(BigInt)....");
    BigInt num, copy;
    num = 145;
    copy = dup(num);
    assert(num is copy);
    writeln("passed");
}

/**
 * Returns the last digit of the number.
 */
public int lastDigit(BigInt big) {
    BigInt digit = big % 10;
    if (digit < 0) digit = -digit;
    // NOTE: this cast is necessary because "BigInt.toInt" returns a long.
    return cast(int)digit.toInt;
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

//    long integer versions
unittest {
    writeln(" -- long integer functions --");
}

/**
 * Shifts the number right by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged. If n > 18 zero is returned.
 */
public long decShr(ref long num, int n) {
    if (n <= 0) { return num; }
    if (n > 18) { return 0; }
    long scale = std.math.pow(10L,n);
    num /= scale;
    return num;
}

unittest {
    write("decShr.........");
    long m;
    int n;
    m = 12345;
    n = 2;
//    writeln("decShr(m,n) = ", decShr(m,n));
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

// TODO: check for overflow
/**
 * Function:   decShl
 * Returns:    the shifted number
 * Parameters: num :the number to shift.
 *             n   :the number of digits to shift.
 */
public long decShl(ref long num, int n) {
    if (n <= 0) { return num; }
    long scale = std.math.pow(10L,n);
    num *= scale;
    return num;
}

unittest {
    write("decShl.........");
    long m;
    int n;
    m = 12345;
    n = 2;
//    writeln("decShl(m,n) = ", decShl(m,n));
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

public int lastDigit(const long num) {
    ulong n = std.math.abs(num);
    return cast(int)(n % 10UL);
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

alias Tuple!(int, "first", int, "count") NumInfo;

public NumInfo numberInfo(const long num) {
    ulong n = std.math.abs(num);
    int count = 1;
    for(int i = 0; i < 6; i++) {
        while (n >= ultens[i]) {
            n /= ultens[i];
            count += ulpwrs[i];
        }
    }
    return NumInfo(cast(int)n, count);
}

unittest {
    write("numberInfo.....");
    NumInfo info;
    info = numberInfo(7);
    assert(info.first == 7);
    assert(info.count == 1);
    info = numberInfo(-13);
    assert(info.first == 1);
    assert(info.count == 2);
    long n;
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

public int firstDigit(const long num) {
    ulong n = std.math.abs(num);
    for(int i = 0; i < 6; i++) {
        while (n >= ultens[i]) {
            n /= ultens[i];
        }
    }
    return cast(int)n;
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

private ulong p10(const uint n) {
    return 10UL^^n;
}

private immutable ulong[6] ulpwrs = [18, 16, 8, 4, 2, 1];
private immutable ulong[6] ultens = [p10(18), p10(16), p10(8), p10(4), p10(2), p10(1)];

public int numDigits(const long num) {

    ulong n = std.math.abs(num);
    int count = 1;
    for(int i = 0; i < 6; i++) {
        while (n >= ultens[i]) {
            n /= ultens[i];
            count += ulpwrs[i];
        }
    }
    return count;
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

/*
public long decShr(ref long num, uint n) {
    for (int m = 0; m < n; m++) {
        num /= 10;
        if (num == 0) break;
    }
    return num;
}

public long decShl(ref long num, uint n) {
    for (int m = 0; m < n; m++) {
        num *= 10;
    }
    return num;
}
*/

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

unittest {
    writeln("-------------------");
    writeln("digits...end testing");
    writeln("-------------------");
    writeln();
}


