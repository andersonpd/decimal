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
import decimal.digits;
import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.conv;
import std.ctype: isdigit;
import std.stdio: write, writeln;
import std.string;


//TODO: add ref context flags to parameters.
// TODO: No. Don't modify round; modify roundByMode.
/**
 * Rounds the integral number to the specified precision.
 * Returns the exponent value corresponding to number of digits rounded.
 */
/*public int round(ref long num, uint precision) {

    roundByMode(num, context);
} // end round()*/

unittest {
    write("long round...");
    writeln("test missing");
}

// UNREADY: round. Description. Private or public?
public void round(ref Decimal num, DecimalContext context) {

    if (!num.isFinite) return;

    // TODO: No! don't clear the flags!!! That's for the user to do.
    // context.clearFlags();
    // check for subnormal

    bool subnormal = false;
    if (num.isSubnormal()) {
        context.setFlag(SUBNORMAL);
        subnormal = true;
    }

    // check for overflow
    if (willOverflow(num, context)) {
        context.setFlag(OVERFLOW);
        switch (context.mode) {
            case Rounding.HALF_UP:
            case Rounding.HALF_EVEN:
            case Rounding.HALF_DOWN:
            case Rounding.UP:
                bool sign = num.sign;
                num = Decimal.POS_INF;
                num.sign = sign;
                break;
            case Rounding.DOWN:
                bool sign = num.sign;
                num = Decimal.max;
                num.sign = sign;
                break;
            case Rounding.CEILING:
                if (num.sign) {
                    num = Decimal.max;
                    num.sign = true;
                }
                else {
                    num = Decimal.POS_INF;
                }
                break;
            case Rounding.FLOOR:
                if (num.sign) {
                    num = Decimal.NEG_INF;
                } else {
                    num = Decimal.max;
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
    if (num.sval == Decimal.SV.CLEAR && num.mant == BigInt(0)) {
        num.sval = Decimal.SV.ZERO;
        // subnormal rounding to zero == clamped
        // Spec. p. 51
        if (subnormal) {
            context.setFlag(CLAMPED);
        }
        return;
    }
} // end round()

unittest {
    writeln("-------------");
    write("round........");
    Decimal before = Decimal(9999);
    Decimal after = before;
    pushPrecision;
    context.precision = 3;
    round(after, context);;
    assert(after.toString() == "1.00E+5");
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
    before = "1235";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = "12359";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,2]");
    before = "1245";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,124,1]");
    before = "12459";
    after = before;
    context.precision = 3;
    round(after, context);;
    assert(after.toAbstract() == "[0,125,2]");
    popPrecision;
    writeln("passed");
}

//--------------------------------
// private rounding routines
//--------------------------------

// UNREADY: shorten. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private Decimal shorten(ref Decimal num, DecimalContext context) {
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
            remainder.sval = Decimal.SV.CLEAR;
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
    write("shorten...");
    writeln("test missing");
}

// UNREADY: shorten. Order. Unit tests.
/**
 * Clips the coefficient of the number to the specified precision.
 * Returns the (unsigned) remainder for adjustments based on rounding mode.
 * Sets the ROUNDED and INEXACT flags.
 */
private ulong shorten(ref ulong num, ref uint digits, uint precision) {
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
        remainder = dividend - quotient*divisor;
        digits = precision;
    }
    // TODO: num.digits == precision.
    // TODO: num.expo == diff;
    return remainder;
}

unittest {
    write("shorten ulong...");
    writeln("test missing");
}

// UNREADY: increment. Unit tests. Order.
// TODO: unittest this
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
    int result = decimal.arithmetic.compare(test1, test2, false);
    if (result == 0) {
        num.expo++;
        num.digits++;
        setDigits(num);
    }
}

unittest {
    write("increment...");
    writeln("test missing");
}

/**
 * Increments the coefficient by 1.
 * Returns true if the increment resulted in
 * an increase in the number of digits;  i.e. input number was all 9s.
 */
private bool increment(ref ulong num) {
    uint digits = numDigits(num);
    num ++;
    if (numDigits(num) > digits) {
        return true;
    }
    else {
        return false;
    }
}

unittest {
    write("increment ulong...");
    writeln("test missing");
}

/**
 * Detect whether T is a decimal type.
 */
template isDecimal(T) {
    enum bool isDecimal = is(T: Decimal);
}

unittest {
    write("isDecimal(T)...");
    writeln("test missing");
}

// TODO: All decimal numbers must have an adjusted exponent routine.
// NOTE: This function is only called within the rounding processing.
/**
 * Tests whether the number is too large to be represented
 * in the specified context.
 */
private bool willOverflow(T)(const T num, DecimalContext context) if (isDecimal!T) {
    return num.adjustedExponent > context.eMax;
}

unittest{
    write("willOverflow.....");
    Decimal dec = Decimal(123, 99);
    assert(willOverflow!Decimal(dec, Decimal.context));
    dec = Decimal(12, 99);
    assert(willOverflow!Decimal(dec, Decimal.context));
    dec = Decimal(1, 99);
    assert(!willOverflow!Decimal(dec, Decimal.context));
    dec = Decimal(9, 99);
    assert(!willOverflow!Decimal(dec, Decimal.context));
    writeln("passed");
}

// UNREADY: roundByMode. Description. Order.
private void roundByMode(ref Decimal num, DecimalContext context) {
    Decimal remainder = shorten(num, context);

    // if the rounded flag is not set by the shorten operation, return
    if (!context.getFlag(ROUNDED)) {
        return;
    }
    // if the remainder is zero, return
    if (!context.getFlag(INEXACT)) {
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
            int result = decimal.arithmetic.compare(remainder, five, false);
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
    write("roundByMode...");
    writeln("test missing");
}

// UNREADY: roundByMode. Description. Order.
private void roundByMode(bool sign, ref ulong num, ref uint digits, const uint precision, const Rounding mode) {
    ulong remainder = shorten(num, digits, precision);

    // if the remainder is zero, return
    if (remainder == 0) {
        return;
    }

    switch (mode) {
        case Rounding.DOWN:
            return;
        case Rounding.HALF_UP:
            if (firstDigit(remainder) >= 5) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
        case Rounding.HALF_EVEN:
            ulong first = firstDigit(remainder);
            if (first > 5) {
                if (increment(num)) {
                    digits++;
                }
                return;
            }
            if (first < 5) {
                return;
            }
            // remainder == 5
            // if last digit is odd...
            if (lastDigit(num) % 2) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
        case Rounding.CEILING:
            if (!sign && remainder != 0) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
        case Rounding.FLOOR:
            if (sign && remainder != 0) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
        case Rounding.HALF_DOWN:
            if (firstDigit(remainder) > 5) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
        case Rounding.UP:
            if (remainder != 0) {
                if (increment(num)) {
                    digits++;
                }
            }
            return;
    }    // end switch(mode)
} // end roundByMode()

unittest {
    write("roundByMode ulong...");
    writeln("test missing");
}

// UNREADY: setDigits. Description. Ordering.
/**
 * Sets the number of digits to the current precision.
 */
package void setDigits(ref Decimal num) {
    int diff = num.digits - context.precision;
    if (diff > 0) {
        round(num, context);
    }
    else if (diff < 0) {
        num.mant = decShl(num.mant, -diff);
        num.expo += diff;
    }
    num.digits = context.precision;
}

unittest {
    write("setDigits...");
    writeln("test missing");
}


