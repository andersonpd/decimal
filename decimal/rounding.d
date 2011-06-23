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

module decimal.rounding;

import decimal.context;
import decimal.conv;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.conv;
import std.ctype: isdigit;
import std.stdio: write, writeln;
import std.string;
import std.typecons: Tuple;

private BigInt tens[18];
private BigInt fives[18];

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
    DecimalContext context;
    context.precision = 5;
}

//public static ZERO = BigInt();

// TODO: preload the powers of ten and powers of five (& powers of 2?)
// TODO: compare benchmarks for division by chunks of a quintillion vs. tens.
// TODO: compare benchmarks for division by powers of 10 vs. 2s * 5s.

// BigInt versions

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
    writeln("---------------------");
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


/*private static context = DEFAULT_CONTEXT.dup;

private static ContextStack contextStack;

private static void pushContext(DecimalContext context) {
     contextStack.push(context);
}

private static DecimalContext popContext() {
    return contextStack.pop;
}
*/
//TODO: add ref context flags to parameters.
// UNREADY: round. Description. Private or public?
public void round(T)(ref T num, ref DecimalContext context) if (isDecimal!T) {

    // no rounding of special values
    if (!num.isFinite) return;

    // check for subnormal
    bool subnormal = false;
    if (num.isSubnormal()) {
        context.setFlag(SUBNORMAL);
        subnormal = true;
    }

    // check for overflow
    if (num.adjustedExponent > context.eMax) {
//        writeln("num.adjustedExponent = ", num.adjustedExponent);
//        writeln("context.eMax = ", context.eMax);
        context.setFlag(OVERFLOW);
        switch (context.mode) {
            case Rounding.HALF_UP:
            case Rounding.HALF_EVEN:
            case Rounding.HALF_DOWN:
            case Rounding.UP:
                bool sign = num.sign;
                num = T.infinity;
                num.sign = sign;
                break;
            case Rounding.DOWN:
                bool sign = num.sign;
                num = T.max;
                num.sign = sign;
                break;
            case Rounding.CEILING:
                if (num.sign) {
                    num = T.max;
                    num.sign = true;
                }
                else {
                    num = T.infinity;
                }
                break;
            case Rounding.FLOOR:
                if (num.sign) {
                    num = -T.infinity;
                } else {
                    num = T.max;
                }
                break;
        }
        context.setFlag(INEXACT);
        context.setFlag(ROUNDED);
        return;
    }
    roundByMode(num, context);
    // check for underflow
    if (num.isSubnormal /*&& num.isInexact*/) {
        context.setFlag(SUBNORMAL);
        int diff = context.eTiny - num.adjustedExponent;
        if (diff > num.digits) {
            num.mant = 0;
            num.expo = context.eTiny;
        } else if (diff > 0) {
            // TODO: do something about this
            writeln("We got a tiny one!");
        }
    }
    // check for zero
    if (is(T : Decimal)) {
        if (num.sval == SV.NONE && num.mant == BigInt(0)) {
            num.sval = SV.ZERO;
        }
    }
    // subnormal rounding to zero == clamped
    // Spec. p. 51
    if (subnormal && num.isZero) {
        context.setFlag(CLAMPED);
    }
    return;

} // end round()

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

//--------------------------------
// private rounding routines
//--------------------------------

// TODO: Move into round routine.
// UNREADY: roundByMode. Description. Order.
private void roundByMode(T)(ref T num, ref DecimalContext context)
        if (isDecimal!T) {

    uint digits = num.digits;
    T remainder = getRemainder(num, context);

    // if the number wasn't rounded...
    if (num.digits == digits) {
        return;
    }
    // if the remainder is zero...
    if (remainder.isZero) {
        return;
    }

    switch (context.mode) {
        case Rounding.DOWN:
            return;
        case Rounding.HALF_UP:
            if (firstDigit(remainder.mant) >= 5) {
                increment(num);
            }
            return;
        case Rounding.HALF_EVEN:
            Decimal five = Decimal(5, remainder.digits + remainder.expo - 1);
            int result = decimal.arithmetic.compare(remainder, five, context, false);
            if (result > 0) {
                increment(num);
                return;
            }
            if (result < 0) {
                return;
            }
            // remainder == 5
            // if last digit is odd...
            if (lastDigit(num.mant) % 2) {
            // TODO: isn't this just num.mant % 2?
            // I can't imagine the other is more efficient
                increment(num);
            }
            return;
        case Rounding.CEILING:
            if (!num.sign && remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
        case Rounding.FLOOR:
            if (num.sign && remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
        case Rounding.HALF_DOWN:
            if (firstDigit(remainder.mant) > 5) {
                increment(num);
            }
            return;
        case Rounding.UP:
            if (remainder != Decimal.ZERO) {
                increment(num);
            }
            return;
    }    // end switch(mode)
} // end roundByMode()

unittest {
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
}

// UNREADY: getRemainder. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private Decimal getRemainder(ref Decimal num, ref DecimalContext context) {
    Decimal remainder = Decimal.ZERO.dup;
    int diff = num.digits - context.precision;
    if (diff <= 0) {
        return remainder;
    }
    context.setFlag(ROUNDED);

    // the context can be zero when...??
    if (context.precision == 0) {
        num = num.sign ? Decimal.NEG_ZERO : Decimal.ZERO;
    } else {
        BigInt divisor = pow10(diff);
        BigInt dividend = num.mant;
        BigInt quotient = dividend/divisor;
        BigInt modulo = dividend - quotient*divisor;
        if (modulo != BigInt(0)) {
            remainder.digits = diff;
            remainder.expo = num.expo;
            remainder.mant = modulo;
            remainder.sval = SV.NONE;
        }
        num.mant = quotient;
        num.digits = context.precision;
        num.expo += diff;
    }
    if (remainder != Decimal.ZERO) {
        context.setFlag(INEXACT);
    }

    return remainder;
}

unittest {
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
}

// UNREADY: increment. Order.
/**
 * Increments the coefficient by 1. If this causes an overflow, divides by 10.
 */
private void increment(ref Decimal num) {
    num.mant += 1;
    // check if the num was all nines --
    // did the coefficient roll over to 1000...?
    Decimal test1 = Decimal(1, num.digits + num.expo);
    Decimal test2 = num;
    test2.digits++;
    int comp = decimal.arithmetic.compare(test1, test2, context, false);
    if (comp == 0) {
        num.digits++;
        // check if there are now too many digits...
        if (num.digits > context.precision) {
            round(num, context);
        }
    }
}

unittest {
    Decimal num, expect;
    num = 10;
    expect = 11;
    increment(num);
    assert(num == expect);
    num = 19;
    expect = 20;
    increment(num);
    assert(num == expect);
    num = 999;
    expect = 1000;
    increment(num);
    assert(num == expect);
}

// UNREADY: setExponent. Description. Order.
public uint setExponent(ref long num, ref uint digits, const DecimalContext context) {

    uint inDigits = digits;
    ulong unum = std.math.abs(num);
    bool sign = num < 0;
    ulong remainder = getRemainder(unum, digits, context.precision);
    int expo = inDigits - digits;

    // if the remainder is zero, return
    if (remainder == 0) {
        num = sign ? -unum : unum;
        return expo;
    }

    switch (context.mode) {
        case Rounding.DOWN:
            break;
        case Rounding.HALF_UP:
            if (firstDigit(remainder) >= 5) {
                increment(unum, digits);
            }
            break;
        case Rounding.HALF_EVEN:
            ulong first = firstDigit(remainder);
            if (first > 5) {
                increment(unum, digits);
            }
            if (first < 5) {
                break;
            }
            // remainder == 5
            // if last digit is odd...
            if (unum & 1) {
                increment(unum, digits);
            }
            break;
        case Rounding.CEILING:
            if (!sign && remainder != 0) {
                increment(unum, digits);
            }
            break;
        case Rounding.FLOOR:
            if (sign && remainder != 0) {
                increment(unum, digits);
            }
            break;
        case Rounding.HALF_DOWN:
            if (firstDigit(remainder) > 5) {
                increment(unum, digits);
            }
            break;
        case Rounding.UP:
            if (remainder != 0) {
                increment(unum, digits);
            }
            break;
    }    // end switch(mode)

    num = sign ? -unum : unum;
    return expo;

} // end setExponent()

unittest {
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
}

// UNREADY: getRemainder. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private ulong getRemainder(ref ulong num, ref uint digits, uint precision) {
    ulong remainder = 0;
    int diff = digits - precision;
    if (diff <= 0) {
        return remainder;
    }
    // if (remainder != 0) {...} ?
    //context.setFlag(ROUNDED);

    // TODO: This is a fictitious case .. the context can be zero when...??
    if (precision == 0) {
        num = 0;
    } else {
        ulong divisor = 10L^^diff;
        ulong dividend = num;
        ulong quotient = dividend / divisor;
        num = quotient;
        remainder = dividend - quotient*divisor;
        digits = precision;
    }
    // TODO: num.digits == precision.
    // TODO: num.expo == diff;
    return remainder;
}

unittest {
    ulong num, acrem, exnum, exrem;
    uint digits, precision;
    num = 1234567890123456L;
    digits = 16; precision = 5;
    acrem = getRemainder(num, digits, precision);
    exnum = 12345L;
    assert(num == exnum);
    exrem = 67890123456L;
    assert(acrem == exrem);
}

/**
 * Increments the number by 1.
 * Re-calculates the number of digits -- the increment may have caused
 * an increase in the number of digits, i.e., input number was all 9s.
 */
private void increment(ref ulong num, ref uint digits) {
    num++;
    digits = numDigits(num);
}

unittest {
    ulong num, expect;
    uint digits;
    num = 10;
    expect = 11;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expect);
    assert(digits == 2);
    num = 19;
    expect = 20;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expect);
    assert(digits == 2);
    num = 999;
    expect = 1000;
    digits = numDigits(num);
    increment(num, digits);
    assert(num == expect);
    assert(digits == 4);
}


