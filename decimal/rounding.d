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

import decimal.arithmetic: copyNegate, equals;
import decimal.context;
import decimal.conv;
import decimal.dec32;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.conv;
import std.ascii: isDigit;
import std.stdio: write, writeln;
import std.string;
import std.typecons: Tuple;

private BigInt tens[18];
private BigInt fives[18];

private static DecimalContext roundContext = DecimalContext().dup;
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

//    writeln("num = ", num);

    //writeln("context.precision = ", context.precision);
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
                    num = T.infinity(true);
                } else {
                    num = T.max;
                }
                break;
            default:
                break;
        }
        context.setFlag(INEXACT);
        context.setFlag(ROUNDED);
        return;
    }
//    writeln("rounding by mode");
    roundByMode(num, context);
//    writeln("num = ", num);
    // check for underflow
    if (num.isSubnormal /*&& num.isInexact*/) {
        context.setFlag(SUBNORMAL);
        int diff = context.eTiny - num.adjustedExponent;
        if (diff > num.digits) {
            num.coefficient = 0;
            num.exponent = context.eTiny;
        } else if (diff > 0) {
            // TODO: do something about this
            writeln("We got a tiny one!");
        }
    }
    // check for zero
    if (is(T : Decimal)) {
//        if (num.sval == SV.NONE && num.coefficient == BigInt(0)) {
        if (num.coefficient == 0) {
            num.clear;
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
    DecimalContext contextX;
    contextX.precision = 3;
    round(after, contextX);
//    writeln("after.toString = ", after.toString);
    assert(after.toString() == "1.00E+4");
    before = Decimal(1234567890);
    after = before;
    contextX.precision = 3;
    round(after, contextX);;
    assert(after.toString() == "1.23E+9");
    after = before;
    contextX.precision = 4;
    round(after, contextX);;
    assert(after.toString() == "1.235E+9");
    after = before;
    contextX.precision = 5;
    round(after, contextX);;
    assert(after.toString() == "1.2346E+9");
    after = before;
    contextX.precision = 6;
    round(after, contextX);;
    assert(after.toString() == "1.23457E+9");
    after = before;
    contextX.precision = 7;
    round(after, contextX);;
    assert(after.toString() == "1.234568E+9");
    after = before;
    contextX.precision = 8;
    round(after, contextX);;
    assert(after.toString() == "1.2345679E+9");
    before = 1235;
    after = before;
    contextX.precision = 3;
    round(after, contextX);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12359;
    after = before;
    contextX.precision = 3;
    round(after, contextX);;
    assert(after.toAbstract() == "[0,124,2]");
    before = 1245;
    after = before;
    contextX.precision = 3;
    round(after, contextX);;
    assert(after.toAbstract() == "[0,124,1]");
    before = 12459;
    after = before;
    contextX.precision = 3;
    round(after, contextX);;
    assert(after.toAbstract() == "[0,125,2]");
//    contextX = popContext();
    writeln("passed");
}

//--------------------------------
// private rounding routines
//--------------------------------

// TODO: Move into round routine.
// UNREADY: roundByMode. Description. Order.
private void roundByMode(T)(ref T num, ref DecimalContext context)
        if (isDecimal!T) {

//    writeln("roundByMode");
    uint digits = num.digits;
    T remainder = getRemainder(num, context);
//    writeln("remainder = ", remainder);


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
//            writeln("DOWN");
            return;
        case Rounding.HALF_UP:
//            writeln("HALF_UP");
            if (firstDigit(remainder.coefficient) >= 5) {
                increment(num, context);
            }
            return;
        case Rounding.HALF_EVEN:
//            writeln("HALF_EVEN");
//            writeln("remainder = ", remainder);
            T five = T(5, remainder.digits + remainder.exponent - 1);
//            writeln("five = ", five);
            int result = decimal.arithmetic.compare(remainder, five, context, false);
//            writeln("result = ", result);
            if (result > 0) {
//                writeln("result > 0");
                increment(num, context);
                return;
            }
            if (result < 0) {
//                writeln("result < 0");
                return;
            }
//            writeln("result == 0");
            // remainder == 5
            // if last digit is odd...
            if (lastDigit(num.coefficient) % 2) {
            // TODO: isn't this just num.coefficient % 2?
            // I can't imagine the other is more efficient
                increment(num, context);
            }
            return;
        case Rounding.CEILING:
//            writeln("CEILING");
            auto temp = T.zero;
            if (!num.sign && (remainder != temp)) {
                increment(num, context);
            }
            return;
        case Rounding.FLOOR:
//            writeln("FLOOR");
            auto temp = T.zero;
            if (num.sign && remainder != temp) {
                increment(num, context);
            }
            return;
        case Rounding.HALF_DOWN:
//            writeln("HALF_DOWN");
            if (firstDigit(remainder.coefficient) > 5) {
                increment(num, context);
            }
            return;
        case Rounding.UP:
//            writeln("UP");
            auto temp = T.zero;
            if (remainder != temp) {
                increment(num, context);
            }
            return;
        default:
            return;
    }    // end switch(mode)
} // end roundByMode()

unittest {
    write("roundByMode....");
    DecimalContext ctxB;
    ctxB.precision = 5;
    ctxB.mode = Rounding.HALF_EVEN;
    Decimal num;
    num = 1000;
    roundByMode(num, ctxB);
    assert(num.coefficient == 1000 && num.exponent == 0 && num.digits == 4);
    num = 1000000;
    roundByMode(num, ctxB);
    assert(num.coefficient == 10000 && num.exponent == 2 && num.digits == 5);
    num = 99999;
    roundByMode(num, ctxB);
    assert(num.coefficient == 99999 && num.exponent == 0 && num.digits == 5);
    num = 1234550;
    roundByMode(num, ctxB);
    assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
    ctxB.mode = Rounding.DOWN;
    num = 1234550;
    roundByMode(num, ctxB);
    assert(num.coefficient == 12345 && num.exponent == 2 && num.digits == 5);
    ctxB.mode = Rounding.UP;
    num = 1234550;
    roundByMode(num, ctxB);
    assert(num.coefficient == 12346 && num.exponent == 2 && num.digits == 5);
    writeln("passed");
}

// UNREADY: getRemainder. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private T getRemainder(T)(ref T num, ref DecimalContext context)
        if (isDecimal!T){
//    writeln("getRemainder");
    // TODO: should be setZero(remainder);
    T remainder = T.zero;
//    writeln("remainder = ", remainder);

    int diff = num.digits - context.precision;
    if (diff <= 0) {
        return remainder;
    }
    context.setFlag(ROUNDED);
//    writeln("rounded");
    // the context can be zero when...??
//    writeln("context.precision = ", context.precision);

    if (context.precision == 0) {
        num = T.zero(num.sign);
    } else {
        auto divisor = T.pow10(diff);
        auto dividend = num.coefficient;
        auto quotient = dividend/divisor;
        auto modulo = dividend - quotient*divisor;
//        writeln("divisor = ", divisor);
//        writeln("dividend = ", dividend);
//        writeln("quotient = ", quotient);
//        writeln("modulo = ", modulo);
        if (modulo != 0) {
            remainder.digits = diff;
            remainder.exponent = num.exponent;
            remainder.coefficient = modulo;
            remainder.clear;
        }
        num.coefficient = quotient;
        num.digits = context.precision;
        num.exponent = num.exponent + diff;
    }
    auto temp = T.zero;
    if (remainder != temp) {
        context.setFlag(INEXACT);
    }

//    writeln("num = ", num);
//    writeln("remainder = ", remainder);
//    writeln("exit getRemainder");
    return remainder;
}

unittest {
    pushContext(roundContext);
    roundContext.precision = 5;
    Decimal num, acrem, exnum, exrem;
    num = Decimal(1234567890123456L);
    acrem = getRemainder(num, roundContext);
    exnum = Decimal("1.2345E+15");
    assert(num == exnum);
    exrem = 67890123456;
    assert(acrem == exrem);
    roundContext = popContext();
}

// UNREADY: increment. Order.
/**
 * Increments the coefficient by 1. If this causes an overflow, divides by 10.
 */
private void increment(ref Decimal num, const DecimalContext context) {
    num.coefficient = num.coefficient + 1;
    // check if the num was all nines --
    // did the coefficient roll over to 1000...?
    Decimal test1 = Decimal(1, num.digits + num.exponent);
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
    increment(num, roundContext);
    assert(num == expect);
    num = 19;
    expect = 20;
    increment(num, roundContext);
    assert(num == expect);
    num = 999;
    expect = 1000;
    increment(num, roundContext);
    assert(num == expect);
}

// UNREADY: setExponent. Description. Order.
public uint setExponent(ref long num, ref uint digits, const DecimalContext context) {

    uint inDigits = digits;
    ulong unum = std.math.abs(num);
    bool sign = num < 0;
    ulong remainder = clipRemainder(unum, digits, context.precision);
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
        default:
            break;
    }    // end switch(mode)

    num = sign ? -unum : unum;
    return expo;

} // end setExponent()

unittest {
    DecimalContext roundContext;
    roundContext.precision = 5;
    roundContext.mode = Rounding.HALF_EVEN;
    long num; uint digits; int expo;
    num = 1000;
    digits = numDigits(num);
    expo = setExponent(num, digits, roundContext);
    assert(num == 1000 && expo == 0 && digits == 4);
    num = 1000000;
    digits = numDigits(num);
    expo = setExponent(num, digits, roundContext);
    assert(num == 10000 && expo == 2 && digits == 5);
    num = 99999;
    digits = numDigits(num);
    expo = setExponent(num, digits, roundContext);
    assert(num == 99999 && expo == 0 && digits == 5);
}

// UNREADY: getRemainder. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private ulong clipRemainder(ref ulong num, ref uint digits, uint precision) {
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
    // TODO: num.exponent == diff;
    return remainder;
}

unittest {
    ulong num, acrem, exnum, exrem;
    uint digits, precision;
    num = 1234567890123456L;
    digits = 16; precision = 5;
    acrem = clipRemainder(num, digits, precision);
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
private void increment(ref Dec32 num, const DecimalContext context) {
    num.coefficient = num.coefficient + 1;
    num.digits = numDigits(num.coefficient);
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

unittest {
    writeln("---------------------");
    writeln("digits........testing");
    writeln("---------------------");
}

// TODO: preload the powers of ten and powers of five (& powers of 2?)
// TODO: compare benchmarks for division by chunks of a quintillion vs. tens.
// TODO: compare benchmarks for division by powers of 10 vs. 2s * 5s.

// BigInt versions

/**
 * Returns the number of digits in the number.
 */
public int numDigits(const BigInt big) {
    BigInt billion = Decimal.pow10(9);
    BigInt quintillion = Decimal.pow10(18);
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
    BigInt billion = Decimal.pow10(9);
    BigInt quintillion = Decimal.pow10(18);
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
 * Shifts the number left by the specified number of decimal digits.
 * If n <= 0 the number is returned unchanged.
 */
public BigInt decShl(BigInt big, const uint n) {
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
public BigInt decShr(BigInt big, const uint n) {
    if (n <= 0) { return big; }

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
public ulong decShr(ulong num, int n) {
    if (n <= 0) { return num; }
    if (n > 18) { return 0; }
    long scale = 10UL^^n;
    num /= scale;
    return num;
}

unittest {
    write("decShr.........");
    long m;
    int n;
    m = 12345;
    n = 2;
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
public ulong decShl(ulong num, int n) {
    if (n <= 0) { return num; }
    long scale = 10UL^^n;
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



