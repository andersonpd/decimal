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
    writeln("---------------------");
    writeln("BigInt functions");
    writeln("---------------------");
}

public int numDigits(const BigInt big) {
    BigInt billion = pow10(9);
    BigInt quintillion = pow10(18);
    BigInt dig = cast()big;
    int count = 0;
    while (dig > quintillion) {
        dig = decShr(dig, 18);
        count += 18;
    }
    if (dig > billion) {
        dig = decShr(dig, 9);
        count += 9;
    }

    long n = dig.toLong;
    return count + numDigits(n);
}

public int firstDigit(const BigInt big) {
    BigInt billion = pow10(9);
    BigInt quintillion = pow10(18);
    BigInt dig = cast(BigInt)big;
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
    writeln("test missing");
}

unittest {
    write("numDigits......");
    writeln("test missing");
}

public BigInt pow10(const int n) {
    BigInt big = BigInt(1);
    return decShl(big, n);
}

unittest {
    write("pow10..........");
    writeln("test missing");
}

public BigInt decShl(ref BigInt big, int n) {
    if (n <= 0) { return big; }

    BigInt twos;
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
    writeln("test missing");
}

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
    writeln("test missing");
}

string toDecString(const BigInt x){
    string outbuff="";
    void sink(const(char)[] s) { outbuff ~= s; }
    x.toString(&sink, "d");
    return outbuff;
}

unittest {
    write("toDecString....");
    writeln("test missing");
}

public BigInt dup(const BigInt big) {
    return cast(BigInt)big;
}

unittest {
    write("dup(BigInt)....");
    writeln("test missing");
}

public int lastDigit(BigInt big) {
    return cast(int)(big % 10); // big % 10;
}

unittest {
    write("lastDigit......");
    writeln("test missing");
}

//    long integer versions
unittest {
    writeln("---------------------");
    writeln("long integer functions");
    writeln("---------------------");
}

// TODO: check for overflow
public long decShr(ref long num, int n) {
    if (n <= 0) { return num; }
    long scale = std.math.pow(10L,n);
    num /= scale;
    return num;
}

unittest {
    write("decShr.........");
    writeln("test missing");
}

// TODO: check for overflow
public long decShl(ref long num, int n) {
    if (n <= 0) { return num; }
    long scale = std.math.pow(10L,n);
    num *= scale;
    return num;
}

unittest {
    write("decShl.........");
    writeln("test missing");
}

public int lastDigit(const long num) {
    return cast(int)(num % 10);
}

unittest {
    write("lastDigit......");
    writeln("test missing");
}

public int firstDigit(const long num) {
    long n = num;
    while(n > 10) {
        n /= 10;
    }
    return cast(int)n;
}

unittest {
    write("firstDigit.....");
    writeln("test missing");
}


public int numDigits(const long num) {

    static ulong pow(ulong n) { return 10UL^^n; }

    immutable ulong[6] pwrs = [    18,      16,      8,     4,       2,      1];
    immutable ulong[6] tens = [pow(18), pow(16), pow(8), pow(4), pow(2), pow(1)];
    ulong n = std.math.abs(num);
    int count = 1;
    for(int i = 0; i < 6; i++) {
        while (n >= tens[i]) {
            n /= tens[i];
            count += pwrs[i];
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


