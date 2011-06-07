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

//public static ZERO = BigInt();

// TODO: preload the powers of ten and powers of five (& powers of 2?)
// TODO: compare benchmarks for division by chunks of a quintillion vs. tens.
// TODO: compare benchmarks for division by powers of 10 vs. 2s * 5s.

// BigInt versions

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

public BigInt pow10(const int n) {
    BigInt big = BigInt(1);
    return decShl(big, n);
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

string toDecString(const BigInt x){
    string outbuff="";
    void sink(const(char)[] s) { outbuff ~= s; }
    x.toString(&sink, "d");
    return outbuff;
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

public BigInt dup(const BigInt big) {
    return cast(BigInt)big;
}

public int lastDigit(BigInt big) {
    return cast(int)(big % 10); // big % 10;
}

//
//    long integer versions
//

// TODO: check for overflow
public long decShr(ref long num, int n) {
    if (n <= 0) { return num; }
    long scale = std.math.pow(10L,n);
    num /= scale;
    return num;
}

// TODO: check for overflow
public long decShl(ref long num, int n) {
    if (n <= 0) { return num; }
    long scale = std.math.pow(10L,n);
    num *= scale;
    return num;
}

public int lastDigit(const long num) {
    return cast(int)(num % 10);
}

public int firstDigit(const long num) {
    long n = num;
    while(n > 10) {
        n /= 10;
    }
    return cast(int)n;
}

public int numDigits(const long num) {
    long n = num;
    int count = 1;
    while (n >= 10) {
        n /= 10;
        count++;
    }
    return count;
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


