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

// TODO: ensure context flags are being set and cleared properly.

// TODO: opEquals unit test should include numerically equal testing.

// TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// TODO: to/from real or double (float) values needs definition and implementation.

// TODO: define values for payloads.

module decimal.arithmetic;

import decimal.context;
import decimal.conv : isDecimal;
import decimal.decimal;
import decimal.rounding;
import std.array: insertInPlace;
import std.bigint;
import std.conv;
import std.ctype: isdigit;
import std.stdio: write, writeln;
import std.string;

// BigInt BIG_ONE = BigInt(1);
// TODO: BIG_ONE, BIG_ZERO

//--------------------------------
// conversion to/from strings
//--------------------------------

// READY: toSciString.
/**
 * Converts a Decimal to a string representation.
 */
public string toSciString(const Decimal num) {
    return decimal.conv.toSciString!Decimal(num);
};    // end toSciString()

// READY: toEngString.
/**
 * Converts a Decimal to an engineering string representation.
 */
public string toEngString(const Decimal num) {
   return decimal.conv.toEngString!Decimal(num);
}; // end toEngString()

// UNREADY: toNumber. Description. Corner Cases. Context.
/**
 * Converts a string into a Decimal.
 */
public Decimal toNumber(const string inStr) {

    Decimal num;
    num.clear;
    num.sign = false;

    // strip, copy, tolower
    char[] str = strip(inStr).dup;
    tolowerInPlace(str);

    // get sign, if any
    if (startsWith(str,"-")) {
        num.sign = true;
        str = str[1..$];
    }
    else if (startsWith(str,"+")) {
        str = str[1..$];
    }

    // check for NaN
    if (startsWith(str,"nan")) {
        num.sval = SV.QNAN;
        if (str == "nan") {
            num.mant = BigInt(0);
            return num;
        }
        // set payload
        str = str[3..$];
        // ensure string is all digits
        foreach(char c; str) {
            if (!isdigit(c)) {
                return num;
            }
        }
        // convert string to payload
        num.mant = BigInt(str.idup);
        return num;
    };

    // check for sNaN
    if (startsWith(str,"snan")) {
        num.sval = SV.SNAN;
        if (str == "snan") {
            num.mant = BigInt(0);
            return num;
        }
        // set payload
        str = str[4..$];
        // ensure string is all digits
        foreach(char c; str) {
            if (!isdigit(c)) {
                return num;
            }
        }
        // convert string to payload
        num.mant = BigInt(str.idup);
        return num;
    };

    // check for infinity
    if (str == "inf" || str == "infinity") {
        num.sval = SV.INF;
        return num;
    };

    // up to this point, num has been qNaN
    num.clear();
    // check for exponent
    int pos = indexOf(str, 'e');
    if (pos > 0) {
        // if it's just a trailing 'e', return NaN
        if (pos == str.length - 1) {
            num.sval = SV.QNAN;
            return num;
        }
        // split the string into coefficient and exponent
        char[] xstr = str[pos+1..$];
        str = str[0..pos];
        // assume exponent is positive
        bool xneg = false;
        // check for minus sign
        if (startsWith(xstr, "-")) {
            xneg = true;
            xstr = xstr[1..$];
        }
        // check for plus sign
        else if (startsWith(xstr, "+")) {
            xstr = xstr[1..$];
        }

        // ensure it's not now empty
        if (xstr.length < 1) {
            num.sval = SV.QNAN;
            return num;
        }

        // ensure exponent is all digits
        foreach(char c; xstr) {
            if (!isdigit(c)) {
                num.sval = SV.QNAN;
            return num;
            }
        }

        // trim leading zeros
        while (xstr[0] == '0' && xstr.length > 1) {
            xstr = xstr[1..$];
        }

        // make sure it will fit into an int
        if (xstr.length > 10) {
            num.sval = SV.QNAN;
            return num;
        }
        if (xstr.length == 10) {
            // try to convert it to a long (should work) and
            // then see if the long value is too big (or small)
            long lex = to!long(xstr);
            if ((xneg && (-lex < int.min)) || lex > int.max) {
                num.sval = SV.QNAN;
        return num;
            }
            num.expo = cast(int) lex;
        }
        else {
            // everything should be copacetic at this point
            num.expo = to!int(xstr);
        }
        if (xneg) {
            num.expo = -num.expo;
        }
    }
    else {
        num.expo = 0;
    }

    // remove trailing decimal point
    if (endsWith(str, ".")) {
        str = str[0..$-1];
    }
    // strip leading zeros
    while (str[0] == '0' && str.length > 1) {
        str = str[1..$];
    }

    // remove internal decimal point
    int point = indexOf(str, '.');
    if (point >= 0) {
        // excise the point and adjust exponent
        str = str[0..point] ~ str[point+1..$];
        int diff = str.length - point;
        num.expo -= diff;
    }

    // ensure string is not empty
    if (str.length < 1) {
        num.sval = SV.QNAN;
        return num;
    }

    // ensure string is all digits
    foreach(char c; str) {
        if (!isdigit(c)) {
            num.sval = SV.QNAN;
            return num;
        }
    }
    // convert coefficient string to BigInt
    num.mant = BigInt(str.idup);
    num.digits = numDigits(num.mant);
    if (num.mant == BigInt(0)) {
         num.sval = SV.ZERO;
    }

    return num;
}

unittest {
    Decimal f = Decimal("1.0");
    assert(f.toString() == "1.0");
    f = Decimal(".1");
    assert(f.toString() == "0.1");
    f = Decimal("-123");
    assert(f.toString() == "-123");
    f = Decimal("1.23E3");
    assert(f.toString() == "1.23E+3");
    f = Decimal("1.23E-3");
    assert(f.toString() == "0.00123");
}

//--------------------------------
// classification functions
//--------------------------------

// READY: radix
/**
 * Returns the radix of this representation (10).
 */
public int radix() {
    return 10;
}

unittest {
    assert(radix() == 10);
}

// READY: classify
/**
 * Returns a string indicating the class and sign of the number.
 * Classes are: sNaN, NaN, Infinity, Subnormal, Zero, Normal.
 */
public string classify(T)(const T num) if (isDecimal!T) {
    if (num.isSignaling()) {
        return "sNaN";
    }
    if (num.isQuiet) {
        return "NaN";
    }
    if (num.isInfinite) {
        return num.sign ? "-Infinity" : "+Infinity";
    }
    if (num.isSubnormal) {
        return num.sign ? "-Subnormal" : "+Subnormal";
    }
    if (num.isZero) {
        return num.sign ? "-Zero" : "+Zero";
    }
    return num.sign ? "-Normal" : "+Normal";
}

unittest {
    Decimal num;
    num = Decimal("Inf");
    assert(classify(num) == "+Infinity");
    num = Decimal("1E-10");
    assert(classify(num) == "+Normal");
    num = Decimal("-0");
    assert(classify(num) == "-Zero");
    num = Decimal("-0.1E-99");
    assert(classify(num) == "-Subnormal");
    num = Decimal("NaN");
    assert(classify(num) == "NaN");
    num = Decimal("sNaN");
    assert(classify(num) == "sNaN");
}

//--------------------------------
// copy functions
//--------------------------------

// READY: copy
/**
 * Returns a copy of the operand.
 * The copy is unaffected by context; no flags are changed.
 */
public T copy(T)(const T num) if (isDecimal!T) {
    return num.dup;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    Decimal num, expd;
    num  = Decimal("2.1");
    expd = Decimal("2.1");
    assert(copy(num) == expd);
    num  = Decimal("-1.00");
    expd = Decimal("-1.00");
    assert(copy(num) == expd);
}

// READY: copyAbs
/**
 * Returns a copy of the operand with a positive sign.
 * The copy is unaffected by context; no flags are changed.
 */
public T copyAbs(T)(const Decimal num) if (isDecimal!T) {
    T copy = num.dup;
    copy.sign = false;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    Decimal num, expect;
    num  = 2.1;
    expect = 2.1;
    assert(copyAbs!Decimal(num) == expect);
    num  = Decimal("-1.00");
    expect = Decimal("1.00");
    assert(copyAbs!Decimal(num) == expect);
}

// READY: copyNegate
/**
 * Returns a copy of the operand with the sign inverted.
 * The copy is unaffected by context; no flags are changed.
 */
public T copyNegate(T)(const Decimal num) if (isDecimal!T) {
    T copy = num.dup;
    copy.sign = !num.sign;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    Decimal num  = "101.5";
    Decimal expect = "-101.5";
    assert(copyNegate!Decimal(num) == expect);
}

// READY: copySign
/**
 * Returns a copy of the first operand with the sign of the second operand.
 * The copy is unaffected by context; no flags are changed.
 */
public T copySign(T)(const T op1, const T op2) if (isDecimal!T) {
    T copy = op1.dup;
    copy.sign = op2.sign;
    return copy;
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
    Decimal num1, num2, expect;
    num1 = 1.50;
    num2 = 7.33;
    expect = 1.50;
    assert(copySign(num1, num2) == expect);
    num2 = -7.33;
    expect = -1.50;
    assert(copySign(num1, num2) == expect);
}

// UNREADY: quantize. Logic.
/**
 * Returns the number which is equal in value and sign
 * to the first operand and which has its exponent set
 * to be equal to the exponent of the second operand.
 */
public T quantize(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    T result;
    if (isInvalidBinaryOp!T(op1, op2, result, context)) {
        return result;
    }
    if (op1.isInfinite != op2.isInfinite() ||
        op2.isInfinite != op1.isInfinite()) {
        return flagInvalid!T(context);
    }
    if (op1.isInfinite() && op2.isInfinite()) {
        return op1.dup;
    }
    result = op1;
    int diff = op1.expo - op2.expo;
    if (diff == 0) {
        return result;
    }
    // need to add a check where the result is zero and op1 is negative --
    // then the result is -zero.
    if (diff > 0) {
        decShl(result.mant, diff);
        result.digits += diff;
        result.expo = op2.expo;
        if (result.digits > context.precision) {
            result = T.nan;
        }
        return result;
    }
    else {
//        pushContext(context);
        context.precision = (-diff > op1.digits) ? 0 : op1.digits + diff;
        round(result, context);
        result.expo = op2.expo;
        if (result.isZero && op1.isSigned) {
            result.sign = true;
        }
//        context = popContext;
        return result;
    }
}

unittest {
    Decimal op1, op2, result, expd;
    string str;
    op1 = Decimal("2.17");
    op2 = Decimal("0.001");
    expd = Decimal("2.170");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = Decimal("2.17");
    op2 = Decimal("0.01");
    expd = Decimal("2.17");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = Decimal("2.17");
    op2 = Decimal("0.1");
    expd = Decimal("2.2");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = Decimal("2.17");
    op2 = Decimal("1e+0");
    expd = Decimal("2");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = Decimal("2.17");
    op2 = Decimal("1e+1");
    expd = Decimal("0E+1");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-Inf");
    op2 = Decimal("Infinity");
    expd = Decimal("-Infinity");
    result = quantize(op1, op2, context);
    assert(result == expd);
    op1 = Decimal("2");
    op2 = Decimal("Infinity");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-0.1");
    op2 = Decimal("1");
    expd = Decimal("-0");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-0");
    op2 = Decimal("1e+5");
    expd = Decimal("-0E+5");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("+35236450.6");
    op2 = Decimal("1e-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("-35236450.6");
    op2 = Decimal("1e-2");
    expd = Decimal("NaN");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1e-1");
    expd = Decimal( "217.0");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1e+0");
    expd = Decimal("217");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1e+1");
    expd = Decimal("2.2E+2");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    op1 = Decimal("217");
    op2 = Decimal("1e+2");
    expd = Decimal("2E+2");
    result = quantize(op1, op2, context);
    assert(result.toString() == expd.toString());
    assert(result == expd);
}

/**
 * Returns the integer which is the exponent of the magnitude
 * of the most significant digit of the operand.
 * (As though the operand were truncated to a single digit
 * while maintaining the value of that digit and without
 * limiting the resulting exponent).
 */
// NOTE: flags only
public T logb(T)(const T num, DecimalContext context) {

    T result;

    if (invalidOperand!T(num, result, context)) {
        return result;
    }
    if (num.isInfinite) {
        return T.infinity;
    }
    if (num.isZero) {
        context.setFlag(DIVISION_BY_ZERO);
        // FIXTHIS: Why doesn't NEG_INF work?
        result = T.infinity; //NEG_INF;
        result.sign = true;
        return result; //Decimal.NEG_INF;
    }
    int expo = num.digits + num.exponent - 1;
    return T(cast(long)expo);
}

unittest {
    Decimal num, expd;
    num = Decimal("250");
    expd = Decimal("2");
    assert(logb(num, context) == expd);
}

/**
 * If the first operand is infinite then that Infinity is returned,
 * otherwise the result is the first operand modified by
 * adding the value of the second operand to its exponent.
 * The result may Overflow or Underflow.
 */
// NOTE: flags only
public T scaleb(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    T result;
    if (isInvalidBinaryOp!T(op1, op2, result, context)) {
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
    }
    int expo = op2.expo;
    if (expo != 0 /* && not within range */) {
        result = flagInvalid!T(context);
        return result;
    }
    result = op1;
    int scale = cast(int)op2.mant.toInt;
    if (op2.isSigned) {
        scale = -scale;
    }
    result.expo += scale;
    return result;
}

unittest {
    auto num1 = Decimal("7.50");
    auto num2 = Decimal("-2");
    auto expd = Decimal("0.0750");
    assert(scaleb(num1, num2, context) == expd);
}

//--------------------------------
// absolute value, unary plus and minus functions
//--------------------------------

// UNREADY: reduce. Description. Flags.
/**
 * Reduces operand to simplest form. Trailing zeros are removed.
 */
// NOTE: flags only
public T reduce(T)(const T num, DecimalContext context) if (isDecimal!T) {
    T result;
    if (invalidOperand!T(num, result, context)) {
        return result;
    }
    result = num;
    if (!result.isFinite()) {
        return result;
    }

    // TODO: is there a more efficient way to do this?
    // Is checking the coefficient for trailing zeros easier to compute?
    BigInt temp = result.mant % 10;
    while (result.mant != 0 && temp == 0) {
        result.expo++;
        result.mant = result.mant / 10;
        temp = result.mant % 10;
    }
    if (result.mant == 0) {
        result.sval = SV.ZERO;
        result.expo = 0;
    }
    result.digits = numDigits(result.mant);
    return result;
}

unittest {
    Decimal num, red;
    string str;
    num = Decimal("1.200");
    str = "1.2";
    red = reduce(num, context);
    assert(red.toString() == str);
}

// READY: abs
/**
 *    Absolute value -- returns a copy and clears the negative sign, if needed.
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to plus(num) for positive numbers
 *    and to minus(num) for negative numbers.
 *    To return the absolute value without rounding or setting flags
 *    use the "copyAbs" function.
 */
/// Returns a new Decimal equal to the absolute value of this Decimal.
// NOTE: flags only
public T abs(T)(const T op1, DecimalContext context) if (isDecimal!T) {
    T result;
    if(invalidOperand!T(op1, result, context)) {
        return result;
    }
    result = copyAbs!T(op1);
    round(result, context);
    return result;
}

unittest {
    Decimal num;
    Decimal expect;
    num = Decimal("-Inf");
    expect = Decimal("Inf");
    assert(abs(num, context) == expect);
    num = 101.5;
    expect = 101.5;
    assert(abs(num, context) == expect);
    num = -101.5;
    assert(abs(num, context) == expect);
}

// READY: plus
/**
 *    Unary plus -- returns a copy with same sign as the number.
 *    Does NOT return a positive copy of a negative number!
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to add('0', number).
 *    To copy without rounding or setting flags use the "copy" function.
 */
public T plus(T)(const T op1, DecimalContext context) if (isDecimal!T) {
    T result;
    if(invalidOperand!T(op1, result, context)) {
        return result;
    }
    result = op1;
    round(result, context);
    return result;
}

unittest {
    Decimal zero = Decimal(0);
    Decimal num, expect;
    num = 1.3;
    expect = add(zero, num, context);
    assert(plus(num, context) == expect);
    num = -1.3;
    expect = add(zero, num, context);
    assert(plus(num, context) == expect);
}

// READY: minus
/**
 *    Unary minus -- returns a copy with the opposite sign.
 *    This operation rounds the number and may set flags.
 *    Result is equivalent to subtract('0', number).
 *    To copy without rounding or setting flags use the "copyNegate" function.
 */
public T minus(T)(const T op1, DecimalContext context) if (isDecimal!T) {
    T result;
    if(invalidOperand!T(op1, result, context)) {
        return result;
    }
    result = copyNegate!T(op1);
    round(result, context);
    return result;
}

unittest {
    Decimal zero = Decimal(0);
    Decimal num, expect;
    num = 1.3;
    expect = subtract(zero, num, context);
    assert(minus(num, context) == expect);
    num = -1.3;
    expect = subtract(zero, num, context);
    assert(minus(num, context) == expect);
}

//-----------------------------------
// next-plus, next-minus, next-toward
//-----------------------------------

// UNREADY: nextPlus. Description. Unit Tests.
public T nextPlus(T)(const T op1, DecimalContext context) if (isDecimal!T) {
    T result;
    if (invalidOperand!T(op1, result, context)) {
        return result;
    }
    if (op1.isInfinite) {
        if (op1.sign) {
            return copyNegate!T(T.max);
        }
        else {
            return op1.dup;
        }
    }
    int adjx = op1.expo + op1.digits - context.precision;
    if (adjx < context.eTiny) {
            return T(0L, context.eTiny);
    }
    T addend = T(1, adjx);
    result = add!T(op1, addend, context, true); // FIXTHIS: really? does this guarantee no flags?
    // FIXTHIS: should be context.max
    if (result > T.max) {
        result = T.infinity;
    }
    return result;
}

unittest {
    pushContext(context);
    Decimal num, expect;
    num = 1;
    expect = Decimal("1.00000001");
    assert(nextPlus(num, context) == expect);
    num = 10;
    expect = Decimal("10.0000001");
    assert(nextPlus(num, context) == expect);
}

// UNREADY: nextMinus. Description. Unit Tests.
public T nextMinus(T)(const T op1, DecimalContext context) if (isDecimal!T) {

    T result;
    if (invalidOperand!T(op1, result, context)) {
        return result;
    }
    if (op1.isInfinite) {
        if (!op1.sign) {
            return T.max;
        }
        else {
            return op1.dup;
        }
    }
    // This is necessary to catch the special case where mant == 1
    T red = reduce!T(op1, context);
    int adjx = red.expo + red.digits - context.precision;
    if (op1.mant == 1) adjx--;
    if (adjx < context.eTiny) {
        return T(0L, context.eTiny);
    }
    T addend = T(1, adjx);
    result = op1 - addend; //subtract(op1, addend, true); // really? does this guarantee no flags?
    if (result < copyNegate!T(T.max)) {
        result = copyNegate!T(T.infinity);
    }
    return result;
}

unittest {
    Decimal num, expect;
    num = 1;
    expect = 0.999999999;
    assert(nextMinus(num, context) == expect);
    num = -1.00000003;
    expect = -1.00000004;
    assert(nextMinus(num, context) == expect);
}

// UNREADY: nextToward. Description. Unit Tests.
// NOTE: rounds
public T nextToward(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    T result;
    if (isInvalidBinaryOp!T(op1, op2, result, context)) {
        return result;
    }
    // compare them but don't round
    int comp = compare!T(op1, op2, context);
    if (comp < 0) return nextPlus!T(op1, context);
    if (comp > 0) return nextMinus!T(op1, context);
    result = copySign!T(op1, op2);
    round(result, context);
    return result;
}

unittest {
    Decimal op1, op2, expect;
    op1 = 1;
    op2 = 2;
    expect = 1.00000001;
    assert(nextToward(op1, op2, context) == expect);
    op1 = -1.00000003;
    op2 = 0;
    expect = -1.00000002;
    assert(nextToward(op1, op2, context) == expect);
}

//--------------------------------
// comparison functions
//--------------------------------

// READY: sameQuantum
/**
 * Returns true if the numbers have the same exponent.
 * No context flags are set.
 * If either operand is NaN or Infinity, returns true if and only if
 * both operands are NaN or Infinity, respectively.
 */
// NOTE: No context
public bool sameQuantum(T)(const T op1, const T op2) if (isDecimal!T) {
    if (op1.isNaN || op2.isNaN) {
        return op1.isNaN && op2.isNaN;
    }
    if (op1.isInfinite || op2.isInfinite) {
        return op1.isInfinite && op2.isInfinite;
    }
    return op1.expo == op2.expo;
}

unittest {
    Decimal op1, op2;
    op1 = 2.17;
    op2 = 0.001;
    assert(!sameQuantum(op1, op2));
    op2 = 0.01;
    assert(sameQuantum(op1, op2));
    op2 = 0.1;
    assert(!sameQuantum(op1, op2));
}

// UNREADY: compare
public int compare(T)(const T op1, const T op2, DecimalContext context,
        bool rounded = true) if (isDecimal!T) {

    // any operation with a signaling NaN is invalid.
    // if both are signaling, return as if op1 > op2.
    if (op1.isSignaling || op2.isSignaling) {
        context.setFlag(INVALID_OPERATION);
        return op1.isSignaling ? 1 : -1;
    }

    // NaN returns > any number, including NaN
    // if both are NaN, return as if op1 > op2.
    if (op1.isNaN || op2.isNaN) {
        return op1.isNaN ? 1 : -1;
    }

    // if signs differ, just compare the signs
    if (op1.sign != op2.sign) {
        // check for zeros: +0 and -0 are equal
        if (op1.isZero && op2.isZero) {
            return 0;
        }
        return op1.sign ? -1 : 1;
    }

    // otherwise, compare the numbers numerically
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (!op1.sign) {
        if (diff > 0) return 1;
        if (diff < 0) return -1;
    }
    else {
        if (diff > 0) return -1;
        if (diff < 0) return 1;
    }

    // when all else fails, subtract
    T result = subtract!T(op1, op2, context, rounded);

    // test the coefficient
    // result.isZero may not be true if the result hasn't been rounded
    if (result.mant == 0) return 0;
    return result.sign ? -1 : 1;
}

unittest {
    Decimal op1, op2;
    op1 = 2.1;
    op2 = 3;
    assert(compare(op1, op2, context) == -1);
    op1 = 2.1;
    op2 = 2.1;
    assert(compare(op1, op2, context) == 0);
}

// UNREADY: equals. Verify 'equals' is identical to 'compare == 0'.
/**
 * Returns true if this Decimal is equal to the specified Decimal.
 * A NaN is not equal to any number, not even to another NaN.
 * Infinities are equal if they have the same sign.
 * Zeros are equal regardless of sign.
 * Finite numbers are equal if they are numerically equal to the current precision.
 * A Decimal is not equal to itself (this != this) if it is a NaN.
 */
public bool equals(T)(const T op1, const T op2, DecimalContext context,
        const bool rounded = true) if (isDecimal!T) {

    // any operation with a signaling NaN is invalid.
    // NaN is never equal to anything, not even another NaN
    if (op1.isSignaling || op2.isSignaling) {
        context.setFlag(INVALID_OPERATION);
        return false;
    }

    // if either is NaN...
    if (op1.isNaN || op2.isNaN) return false;

    // if either is infinite...
    if (op1.isInfinite || op2.isInfinite) {
        return (op1.sval == op2.sval && op1.sign == op2.sign);
    }

    // if either is zero...
    if (op1.isZero || op2.isZero) {
        return (op1.isZero && op2.isZero);
    }

    // if their signs differ
    if (op1.sign != op2.sign) {
        return false;
    }

    // compare the numbers numerically
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (diff != 0) {
        return false;
    }

    // if they have the same representation, they are equal
    if (op1.expo == op2.expo && op1.mant == op2.mant) {
        return true;
    }

    // otherwise they are equal if they represent the same value
    T result = subtract!T(op1, op2, context, rounded);
    return result.mant == 0;
}

// NOTE: change these to true opEquals calls.
unittest {
    Decimal op1, op2;
    op1 = 123.4567;
    op2 = 123.4568;
    assert(op1 != op2);
    op2 = 123.4567;
    assert(op1 == op2);
}

// UNREADY: compareSignal. Unit Tests.
/**
 * Compares the numeric values of two numbers. CompareSignal is identical to
 * compare except that quiet NaNs are treated as if they were signaling.
 */
public int compareSignal(T) (const T op1, const T op2,
        DecimalContext context, bool rounded = true) if (isDecimal!T) {

    // any operation with NaN is invalid.
    // if both are NaN, return as if op1 > op2.
    if (op1.isNaN || op2.isNaN) {
        context.setFlag(INVALID_OPERATION);
        return op1.isNaN ? 1 : -1;
    }
    return (compare!T(op1, op2, context, rounded));
}

// UNREADY: compareTotal
/// Returns 0 if the numbers are equal and have the same representation
// NOTE: no context
public int compareTotal(T)(const T op1, const T op2) if (isDecimal!T) {
    if (op1.sign != op2.sign) {
        return op1.sign ? -1 : 1;
    }
    if (op1.isQuiet || op2.isQuiet) {
        if (op1.isQuiet && op2.isQuiet) {
            return 0;
        }
        return op1.isQuiet ? 1 : -1;
    }
    if (op1.isSignaling || op2.isSignaling) {
        return 0;
    }
    if (op1.isInfinite || op2.isInfinite) {
        return 0;
    }
    int diff = (op1.expo + op1.digits) - (op2.expo + op2.digits);
    if (diff > 0) return 1;
    if (diff < 0) return -1;
    T result = op1 - op2;
    if (result.isZero) {
        if (op1.expo > op2.expo) return 1;
        if (op1.expo < op2.expo) return -1;
        return 0;
    }
    return result.sign ? -1 : 1;
}

unittest {
    Decimal op1, op2;
    int result;
    op1 = Decimal("12.30");
    op2 = Decimal("12.3");
    result = compareTotal(op1, op2);
    assert(result == -1);
    op1 = Decimal("12.30");
    op2 = Decimal("12.30");
    result = compareTotal(op1, op2);
    assert(result == 0);
    op1 = Decimal("12.3");
    op2 = Decimal("12.300");
    result = compareTotal(op1, op2);
    assert(result == 1);
}

// UNREADY: compareTotalMagnitude
int compareTotalMagnitude(T)(const T op1, const T op2) if (isDecimal!T) {
    return compareTotal(copyAbs!T(op1), copyAbs!T(op2));
}

// UNREADY: max. Flags.
// TODO: this is where the need for flags comes in.
/**
 * Returns the maximum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is larger than a NaN.
 * If they are not numerically equal, the larger is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the positive sign is returned.
 * 2) If they are positive, the one with the larger exponent is returned.
 * 3) If they are negative, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
// NOTE: flags only
const(T) max(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    // if both are NaNs or either is an sNan, return NaN.
    if (op1.isNaN && op2.isNaN || op1.isSignaling || op2.isSignaling) {
        return T.nan;
    }
    // if one op is a quiet NaN return the other
    if (op1.isQuiet || op2.isQuiet) {
        return (op1.isQuiet) ? op2 : op1;
    }
    // if the signs differ, return the unsigned operand
    if (op1.sign != op2.sign) {
        return op1.sign ? op2 : op1;
    }
    // if not numerically equal, return the larger
    int comp = compare!T(op1, op2, context);
    if (comp != 0) {
        return comp > 0 ? op1 : op2;
    }
    // if they have the same exponent they are identical, return either
    if (op1.expo == op2.expo) {
        return op1;
    }
    // if they are non-negative, return the one with larger exponent.
    if (op1.sign == 0) {
        return op1.expo > op2.expo ? op1 : op2;
    }
    // else they are negative; return the one with smaller exponent.
    return op1.expo > op2.expo ? op2 : op1;
}

unittest {
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(max(op1, op2, context) == op1);
    op1 = -10;
    op2 = 3;
    assert(max(op1, op2, context) == op2);
}

// UNREADY: maxMagnitude. Flags.
const(T) maxMagnitude(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    return max(copyAbs!T(op1), copyAbs!T(op2), context);
}

// UNREADY: min. Flags.
/**
 * Returns the minimum of the two operands (or NaN).
 * If either is a signaling NaN, or both are quiet NaNs, a NaN is returned.
 * Otherwise, Any (finite or infinite) number is smaller than a NaN.
 * If they are not numerically equal, the smaller is returned.
 * If they are numerically equal:
 * 1) If the signs differ, the one with the negative sign is returned.
 * 2) If they are negative, the one with the larger exponent is returned.
 * 3) If they are positive, the one with the smaller exponent is returned.
 * 4) Otherwise, they are indistinguishable; the first is returned.
 */
const(T) min(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    // if both are NaNs or either is an sNan, return NaN.
    if (op1.isNaN && op2.isNaN || op1.isSignaling || op2.isSignaling) {
/*        Decimal result;
        result.flags = INVALID_OPERATION;*/
        return T.nan;
    }
    // if one op is a quiet NaN return the other
    if (op1.isQuiet || op2.isQuiet) {
        return (op1.isQuiet) ? op2 : op1;
    }
    // if the signs differ, return the unsigned operand
    if (op1.sign != op2.sign) {
        return op1.sign ? op1 : op2;
    }
    // if not numerically equal, return the smaller
    int comp = compare!T(op1, op2, context);
    if (comp != 0) {
        return comp < 0 ? op1 : op2;
    }
    // if they have the same exponent they are identical, return either
    if (op1.expo == op2.expo) {
        return op1;
    }
    // if they are non-negative, return the one with smaller exponent.
    if (op1.sign == 0) {
        return op1.expo < op2.expo ? op1 : op2;
    }
    // else they are negative; return the one with larger exponent.
    return op1.expo < op2.expo ? op2 : op1;
}

unittest {
    Decimal op1, op2;
    op1 = 3;
    op2 = 2;
    assert(min(op1, op2, context) == op2);
    op1 = -10;
    op2 = 3;
    assert(min(op1, op2, context) == op1);
}

// UNREADY: minMagnitude. Flags.
const(T) minMagnitude(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    return min(copyAbs!T(op1), copyAbs!T(op2), context);
}

//------------------------------------------
// binary arithmetic operations
//------------------------------------------

/**
 * Shifts the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand shift the
 * first operand left (multiplying by tens). Negative values shift right
 * (divide by 10s). If the number is NaN, or if the shift value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public T shift(T)(const T op1, const int op2,DecimalContext context)
        if (isDecimal!T) {

    T result;
    // check for NaN operand
    if (invalidOperand!T(op1, result, context)) {
        return result;
    }
    if (op2 < -context.precision || op2 > context.precision) {
        result = flagInvalid!T(context);
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
    }
    if (op2 == 0) {
        return op1.dup;
    }
    result = op1.dup;
    if (op2 > 0) {
        decShl(result.mant, op2);
    }
    else {
        decShr(result.mant, -op2);
    }
    result.expo -= op2;
    result.digits += op2;

    return result;
}

unittest {
    Decimal num = 34;
    int digits = 8;
    Decimal act = shift(num, digits, context);
    num = 12;
    digits = 9;
    act = shift(num, digits, context);
    num = 123456789;
    digits = -2;
    act = shift(num, digits, context);
    digits = 0;
    act = shift(num, digits, context);
    digits = 2;
    act = shift(num, digits, context);
}

/**
 * Rotates the first operand by the specified number of decimal digits.
 * (Not binary digits!) Positive values of the second operand rotate the
 * first operand left (multiplying by tens). Negative values rotate right
 * (divide by 10s). If the number is NaN, or if the rotate value is less
 * than -precision or greater than precision, an INVALID_OPERATION is signaled.
 * An infinite number is returned unchanged.
 */
public T rotate(T)(const T op1, const int op2, DecimalContext context)
        if (isDecimal!T) {

    T result;
    // check for NaN operand
    if (invalidOperand!T(op1, result, context)) {
        return result;
    }
    if (op2 < -context.precision || op2 > context.precision) {
        result = flagInvalid(context);
        return result;
    }
    if (op1.isInfinite) {
        return op1.dup;
    }
    if (op2 == 0) {
        return op1.dup;
    }
    result = op1.dup;

    // TODO: And then a miracle happens....

    return result;
}

// READY: add
/**
 * Adds two numbers.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for the Decimal struct.
 */
public T add(T)(const T op1, const T op2, DecimalContext context,
        bool rounded = true) if (isDecimal!T) {
    T augend = op1.dup;
    T addend = op2.dup;
    T sum;    // sum is initialized to quiet NaN
    // check for NaN operand(s)
    if (isInvalidBinaryOp!T(augend, addend, sum, context)) {
        return sum;
    }
    // if both operands are infinite
    if (augend.isInfinite && addend.isInfinite) {
        // (+inf) + (-inf) => invalid operation
        if (augend.sign != addend.sign) {
            return flagInvalid!T(context);
        }
        // both infinite with same sign
        return augend;
    }

    if (isInvalidAddition(augend, addend, sum)) {
        return sum;
    }
    // only augend is infinite,
    if (augend.isInfinite) {
        return augend;
    }
    // only addend is infinite
    if (addend.isInfinite) {
        return addend;
    }

    // add(0, 0)
    if (augend.isZero && addend.isZero) {
        sum = augend;
        sum.sign = augend.sign && addend.sign;
        return sum;
    }

    // TODO: this can never return zero, right?
    // align the operands
    alignOps(augend, addend);

    // at this point, the result will be finite and not zero
    // (before rounding)
    sum.clear();

    // if operands have the same sign...
    if (augend.sign == addend.sign) {
        sum.mant = augend.mant + addend.mant;
        sum.sign = augend.sign;
    }
    // ...else operands have different signs
    else {
        sum.mant = augend.mant - addend.mant;
        sum.sign = augend.sign;
        if (sum.mant < BigInt(0)) {
            sum.mant = -sum.mant;
            sum.sign = !sum.sign;
        }
    }
    // set the number of digits and the exponent
    sum.digits = numDigits(sum.mant);
    sum.expo = augend.expo;

    // round the result
    if (rounded) {
        round(sum, context);
    }
    return sum;
}    // end add(augend, addend)

// TODO: these tests need to be cleaned up to rely less on strings
// and to check the NaN, Inf combinations better.
unittest {
    Decimal op1, op2, sum;
    op1 = Decimal("12");
    op2 = Decimal("7.00");
    sum = add(op1, op2, context);
    assert(sum.toString() == "19.00");
    op1 = Decimal("1E+2");
    op2 = Decimal("1E+4");
    sum = add(op1, op2, context);
    assert(sum.toString() == "1.01E+4");
}

// READY: subtract
/**
 * Subtracts a number from another number.
 *
 * This function corresponds to the "add and subtract" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opAdd and opSub functions for the Decimal struct.
 */
public T subtract(T) (const T minuend, const T subtrahend,
        DecimalContext context, const bool rounded = true) if (isDecimal!T) {
    return add!T(minuend, copyNegate!T(subtrahend), context , rounded);
}    // end subtract(minuend, subtrahend)

// READY: multiply
/**
 * Multiplies two numbers.
 *
 * This function corresponds to the "multiply" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opMul function for the Decimal struct.
 */
public T multiply(T)(const T op1, const T op2, DecimalContext context,
        const bool rounded = true) if (isDecimal!T) {

    T product;
    // if invalid, return NaN
    if (isInvalidMultiplication!T(op1, op2, product, context)) {
        return product;
    }
    // if either operand is infinite, return infinity
    if (op1.isInfinite || op2.isInfinite) {
        product = T.infinity;
        product.sign = op1.sign ^ op2.sign;
        return product;
    }
    // product is finite
    product.clear();
    product.mant = cast(BigInt)op1.mant * cast(BigInt)op2.mant;
    product.expo = op1.expo + op2.expo;
    product.sign = op1.sign ^ op2.sign;
    product.digits = numDigits(product.mant);
    if (rounded) {
        round(product, context);
    }
    return product;
}

unittest {
    Decimal op1, op2, result;
    op1 = Decimal("1.20");
    op2 = 3;
    result = multiply(op1, op2, context);
    assert(result.toString() == "3.60");
    op1 = 7;
    result = multiply(op1, op2, context);
    assert(result.toString() == "21");
}

// READY: fma
/**
 * Multiplies two numbers and adds a third number to the result.
 * The result of the multiplication is not rounded prior to the addition.
 *
 * This function corresponds to the "fused-multiply-add" function
 * in the General Decimal Arithmetic Specification.
 */
public T fma(T)(const T op1, const T op2, const T op3,
        DecimalContext context) if (isDecimal!T) {

    T product = multiply!T(op1, op2, context, false);
    return add!T(product, op3, context);
}

unittest {
    Decimal op1, op2, op3, result;
    op1 = 3; op2 = 5; op3 = 7;
    result = (fma(op1, op2, op3, context));
    assert(result == Decimal(22));
    op1 = 3; op2 = -5; op3 = 7;
    result = (fma(op1, op2, op3, context));
    assert(result == Decimal(-8));
    op1 = 888565290;
    op2 = 1557.96930;
    op3 = -86087.7578;
    result = (fma(op1, op2, op3, context));
    assert(result == Decimal(1.38435736E+12));
}

// READY: divide
/**
 * Divides one number by another and returns the quotient.
 * Division by zero sets a flag and returns Infinity.
 *
 * This function corresponds to the "divide" function
 * in the General Decimal Arithmetic Specification and is the basis
 * for the opDiv function for the Decimal struct.
 */
public T divide(T)(const T op1, const T op2,
        DecimalContext context, bool rounded = true) if (isDecimal!T) {

    T quotient;
    // check for NaN and divide by zero
    if (isInvalidDivision!T(op1, op2, quotient, context)) {
        return quotient;
    }
    // if op1 is zero, quotient is zero
    if (isZeroDividend!T(op1, op2, quotient, context)) {
        return quotient;
    }

    quotient.clear();
    // TODO: are two guard digits necessary? sufficient?
    context.precision += 2;
    T dividend = op1.dup;
    T divisor  = op2.dup;
    int diff = dividend.expo - divisor.expo;
    if (diff > 0) {
        decShl(dividend.mant, diff);
        dividend.expo -= diff;
        dividend.digits += diff;
    }
    int shift = 2 + context.precision + divisor.digits - dividend.digits;
    if (shift > 0) {
        decShl(dividend.mant, shift);
        dividend.expo -= shift;
        dividend.digits += diff;
    }
    quotient.mant = dividend.mant / divisor.mant;
    quotient.expo = dividend.expo - divisor.expo;
    quotient.sign = dividend.sign ^ divisor.sign;
    quotient.digits = numDigits(quotient.mant);
    context.precision -= 2;
    if (rounded) {
        round(quotient, context);
        if (!context.getFlag(INEXACT)) {
            quotient = reduceToIdeal(quotient, diff, context);
        }
    }
    return quotient;
}

unittest {
    pushContext(context);
    context.precision = 9;
    Decimal op1, op2, actual, expect;
    op1 = 1;
    op2 = 3;
    actual = divide(op1, op2, context);
    expect = Decimal(0.333333333);
    assert(actual == expect);
    assert(actual.toString() == expect.toString());
    op1 = 1;
    op2 = 10;
    expect = 0.1;
    actual = divide(op1, op2, context);
    assert(actual == expect);
// TODO: what's wrong here?
//    writeln("expect = ", expect);
//    writeln("actual = ", actual);
//    assert(actual.toString() == expect.toString());
    context = popContext;
}

// UNREADY: divideInteger. Error if integer value > precision digits. Duplicates code with divide?
/**
 * Divides one number by another and returns the integer portion of the quotient.
 * Division by zero sets a flag and returns Infinity.
 *
 * This function corresponds to the "divide-integer" function
 * in the General Decimal Arithmetic Specification.
 */
public T divideInteger(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {

    T quotient;
    if (isInvalidDivision!T(op1, op2, quotient, context)) {
        return quotient;
    }
    // TODO: surely invalid division includes a zero dividend check.
    if (isZeroDividend!T(op1, op2, quotient, context)) {
        return quotient;
    }

    quotient.clear();
    T divisor = op1.dup;
    T dividend = op2.dup;
    // align operands
    int diff = dividend.expo - divisor.expo;
    if (diff < 0) {
        decShl(divisor.mant, -diff);
    }
    if (diff > 0) {
        decShl(dividend.mant, diff);
    }
    quotient.mant = divisor.mant / dividend.mant;
    quotient.expo = 0;
    quotient.sign = dividend.sign ^ divisor.sign;
    quotient.digits = numDigits(quotient.mant);
    if (quotient.mant == 0) quotient.sval = SV.ZERO;
    return quotient;
}

unittest {
    write("div-int......");
    Decimal dividend;
    Decimal divisor;
    Decimal quotient;
    Decimal expd;
    dividend = 2;
    divisor = 3;
    quotient = divideInteger(dividend, divisor, context);
    expd = 0;
    assert(quotient == expd);
    dividend = 10;
    quotient = divideInteger(dividend, divisor, context);
    expd = 3;
    assert(quotient == expd);
    dividend = 1;
    divisor = 0.3;
    quotient = divideInteger(dividend, divisor, context);
    assert(quotient == expd);
    writeln("passed");
}

// UNREADY: remainder. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public T remainder(T)(const T op1, const T op2,
        DecimalContext context) if (isDecimal!T) {
    T quotient;
    if (isInvalidDivision!T(op1, op2, quotient, context)) {
        return quotient;
    }
    if (isZeroDividend!T(op1, op2, quotient, context)) {
        return quotient;
    }
    quotient = divideInteger!T(op1, op2, context);
    T remainder = op1 - multiply!T(op2, quotient, context, false);
    return remainder;
}

unittest {
    write("remainder....");
    Decimal dividend;
    Decimal divisor;
    Decimal quotient;
    Decimal expected;
    dividend = 2.1;
    divisor = 3;
    quotient = remainder(dividend, divisor, context);
    expected = 2.1;
    assert(quotient == expected);
    dividend = 10;
    quotient = remainder(dividend, divisor, context);
    expected = 1;
    assert(quotient == expected);
    dividend = -10;
    quotient = remainder(dividend, divisor, context);
    expected = -1;
    assert(quotient == expected);
    dividend = 10.2;
    divisor = 1;
    quotient = remainder(dividend, divisor, context);
    expected = 0.2;
    assert(quotient == expected);
    dividend = 10;
    divisor = 0.3;
    quotient = remainder(dividend, divisor, context);
    expected = 0.1;
    assert(quotient == expected);
    dividend = 3.6;
    divisor = 1.3;
    quotient = remainder(dividend, divisor, context);
    expected = 1.0;
    assert(quotient == expected);
    writeln("passed");
}

// UNREADY: remainderNear. Unit tests. Logic?
/**
 * Divides one number by another and returns the fractional remainder.
 * Division by zero sets a flag and returns Infinity.
 * The sign of the remainder is the same as that of the first operand.
 *
 * This function corresponds to the "remainder" function
 * in the General Decimal Arithmetic Specification.
 */
public T remainderNear(T)(const T dividend, const T divisor,
        DecimalContext context) if (isDecimal!T) {
    T quotient;
    if (isInvalidDivision!T(dividend, divisor, quotient, context)) {
        return quotient;
    }
    if (isZeroDividend!T(dividend, divisor, quotient, context)) {
        return quotient;
    }
    quotient = divideInteger(dividend, divisor, context);
    T remainder = dividend - multiply!T(divisor, quotient, context, false);
    return remainder;
}

unittest {
    write("rem-near.....");
    writeln("test missing");
}

//--------------------------------
// rounding routines
//--------------------------------

// UNREADY: roundToIntegralExact. Description. Name. Order.
// could set flags and then pop the context??
public T roundToIntegralExact(T)(const T num,
        DecimalContext context) if (isDecimal!T) {
    if (num.isSignaling) return flagInvalid!T(context);
    if (num.isSpecial) return num.dup;
    if (num.expo >= 0) return num.dup;
//    pushContext(context);
    context.precision = num.digits;
    const T ONE = T(1L);
    T result = quantize!T(num, ONE, context);
//    context = popContext;
    return result;
}

unittest {
    write("rnd-int-ex...");
    Decimal num, expd, actual;
    num = 2.1;
    expd = 2;
    actual = roundToIntegralExact(num, context);
    assert(actual == expd);
    num = 100;
    expd = 100;
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = Decimal("100.0");
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = Decimal("101.5");
    expd = 102;
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = -101.5;
    expd = -102;
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = Decimal("10E+5");
    expd = Decimal("1.0E+6");
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = 7.89E+77;
    expd = 7.89E+77;
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    num = Decimal("-Inf");
    expd = Decimal("-Infinity");
    assert(roundToIntegralExact(num, context) == expd);
    assert(roundToIntegralExact(num, context).toString() == expd.toString());
    writeln("passed");
}

// UNREADY: roundToIntegralValue. Description. Name. Order. Logic.
public T roundToIntegralValue(T)(const T num,
        DecimalContext context) if (isDecimal!T) {
    // this operation shouldn't affect the inexact or rounded flags
    // so we'll save them in case they were already set.
    bool inexact = context.getFlag(INEXACT);
    bool rounded = context.getFlag(ROUNDED);
    T result = roundToIntegralExact!T(num, context);
    context.setFlag(INEXACT, inexact);
    context.setFlag(ROUNDED, rounded);
    return result;
}

unittest {
    write("rnd-int-val..");
    writeln("test missing");
}

// UNREADY: setDigits. Description. Ordering.
/**
 * Sets the number of digits to the current precision.
 */
// TODO: template this?
package void setDigits(ref Decimal num) {
    int diff = num.digits - context.precision;
    if (diff > 0) {
        round(num, context);
    }
}

unittest {
    write("setDigits...");
    writeln("test missing");
}


// UNREADY: reduceToIdeal. Description. Flags.
/**
 * Reduces operand to simplest form. All trailing zeros are removed.
 * Reduces operand to specified exponent.
 */
 // TODO: has non-standard flag setting
// NOTE: flags only
private T reduceToIdeal(T)(const T num, int ideal,
        DecimalContext context) if (isDecimal!T) {
    T result;
    if (invalidOperand!T(num, result, context)) {
        return result;
    }
    result = num;
    if (!result.isFinite()) {
        return result;
    }
    BigInt temp = result.mant % 10;
    while (result.mant != 0 && temp == 0 && result.expo < ideal) {
        result.expo++;
        result.mant = result.mant / 10;
        temp = result.mant % 10;
    }
    if (result.mant == 0) {
        result.sval = SV.ZERO;
        result.expo = 0;
    }
    result.digits = numDigits(result.mant);
    return result;
}

unittest {
    write("reduceToIdeal...");
    writeln("test missing");
}

// UNREADY: flagInvalid. Unit Tests.
/**
 * Sets the invalid-operation flag and
 * returns a quiet NaN.
 */
private T flagInvalid(T)(DecimalContext context, ulong payload = 0)
        if (isDecimal!T) {
    context.setFlag(INVALID_OPERATION);
    T result = T.nan;
    if (payload != 0) {
        result.setNaNPayload(payload);
    }
    return result;
}

unittest {
    write("invalid......");
    Decimal num, expect, actual;

    // FIXTHIS: Can't actually test payloads at this point.
    num = Decimal("sNaN123");
    expect = Decimal("NaN123");
    actual = abs!Decimal(num, context);
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);
    num = Decimal("NaN123");
    actual = abs(num, context);
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);

    num = Decimal("sNaN123");
    expect = Decimal("NaN123");
    actual = -num;
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);
    num = Decimal("NaN123");
    actual = -num;
    assert(actual.isQuiet);
    assert(context.getFlag(INVALID_OPERATION));
//    assert(actual.toAbstract == expect.toAbstract);*/
    writeln("passed");
}

// UNREADY: alignOps. Unit tests. Todo.
// TODO: can this be used in division as well as addition?
/**
 * Aligns the two operands by raising the smaller exponent
 * to the value of the larger exponent, and adjusting the
 * coefficient so the value remains the same.
 */
// TODO: template this?
private void alignOps(ref Decimal op1, ref Decimal op2) {
    int diff = op1.expo - op2.expo;
    if (diff > 0) {
        op1.mant = decShl(op1.mant, diff);
        op1.expo = op2.expo;
    }
    else if (diff < 0) {
        op2.mant = decShl(op2.mant, -diff);
        op2.expo = op1.expo;
    }
}

unittest {
    write("alignOps...");
    writeln("test missing");
}

// UNREADY: isInvalidBinaryOp. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool isInvalidBinaryOp(T)(const T op1, const T op2,
        ref T result, DecimalContext context) if (isDecimal!T) {
    // if either operand is a signaling NaN...
    if (op1.isSignaling || op2.isSignaling) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the first sNaN operand
        result = op1.isSignaling ? op1 : op2;
        // retain sign and payload; convert to qNaN
        result.sval = SV.QNAN;
        return true;
    }
    // ...else if either operand is a quiet NaN...
    if (op1.isQuiet || op2.isQuiet) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the first qNaN operand
        result = op1.isQuiet ? op1 : op2;
        return true;
    }
    // ...otherwise, no flags are set and result is unchanged
    return false;
}

unittest {
    write("isInvalidBinaryOp...");
    writeln("test missing");
}

// UNREADY: invalidOperand. Unit Tests. Payload.
/*
 * "The result of any arithmetic operation which has an operand
 * which is a NaN (a quiet NaN or a signaling NaN) is [s,qNaN]
 * or [s,qNaN,d]. The sign and any diagnostic information is copied
 * from the first operand which is a signaling NaN, or if neither is
 * signaling then from the first operand which is a NaN."
 * -- General Decimal Arithmetic Specification, p. 24
 */
private bool invalidOperand(T)(const T op1, ref T result,
        DecimalContext context) if (isDecimal!T) {
    // if the operand is a signaling NaN...
    if (op1.isSignaling) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the sNaN operand
        result = op1;
        // retain sign and payload; convert to qNaN
        result = T.nan;
        return true;
    }
    // ...else if the operand is a quiet NaN...
    if (op1.isQuiet) {
        // flag the invalid operation
        context.setFlag(INVALID_OPERATION);
        // set the result to the qNaN operand
        result = op1;
        return true;
    }
    // ...otherwise, no flags are set and result is unchanged
    return false;
}

unittest {
    write("invalidOperand...");
    writeln("test missing");
}

// UNREADY: isInvalidAddition. Description.
/*
 *    Checks for NaN operands and +infinity added to -infinity.
 *    If found, sets flags, sets the sum to NaN and returns true.
 *
 *    -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidAddition(T) (T op1, T op2, ref T result) {
    if (isInvalidBinaryOp!T(op1, op2, result, context)) {
        return true;
    }
    // if both operands are infinite
    if (op1.isInfinite && op2.isInfinite) {
        // (+inf) + (-inf) => invalid operation
        if (op1.sign != op2.sign) {
            result = flagInvalid!T(context);
            return true;
        }
    }
    return false;
}

unittest {
    write("isInvalidAddition...");
    writeln("test missing");
}

// UNREADY: isInvalidMultiplication. Flags. Unit Tests.
/*
 *    Checks for NaN operands and Infinity * Zero.
 *    If found, sets flags, sets the product to NaN and returns true.
 *
 *    -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidMultiplication(T)(const T op1, const T op2,
        ref T result, DecimalContext context) if (isDecimal!T) {

    if (isInvalidBinaryOp!T(op1, op2, result, context)) {
        return true;
    }
    if (op1.isZero && op2.isInfinite || op1.isInfinite && op2.isZero) {
        //TODO: does this set any flags?
        result = T.nan;
        return true;
    }
    return false;
}

unittest {
    write("isInvalidMultiplication...");
    writeln("test missing");
}

// UNREADY: isInvalidDivision. Unit Tests.
/*
 *    Checks for NaN operands and division by zero.
 *    If found, sets flags, sets the quotient to NaN or Infinity respectively
 *    and returns true.
 *
 * -- General Decimal Arithmetic Specification, p. 52, "Invalid operation"
 */
private bool isInvalidDivision(T)(const T dividend, const T divisor,
        ref T quotient, DecimalContext context) if (isDecimal!T) {

    if (isInvalidBinaryOp!T(dividend, divisor, quotient, context)) {
        return true;
    }
    if (divisor.isZero()) {
        if (dividend.isZero()) {
            quotient = flagInvalid!T(context);
        }
        else {
            context.setFlag(DIVISION_BY_ZERO);
            quotient.sval = SV.INF;
            // FIXTHIS: This isn't always a bigint.
            quotient.mant = BigInt(0);
            quotient.sign = dividend.sign ^ divisor.sign;
        }
        return true;
    }
    return false;
}

unittest {
    write("isInvalidDivision...");
    writeln("test missing");
}

// UNREADY: isZeroDividend. Unit tests.
/**
 * Checks for a zero dividend. If found, sets the quotient to zero.
 */
// NOTE: is this used?
private bool isZeroDividend(T)(const T dividend, const T divisor,
        ref T quotient, DecimalContext context) if (isDecimal!T) {
    if (dividend.isZero()) {
        quotient.sval = SV.ZERO;
        quotient.mant = BigInt(0);
        quotient.expo = 0;
        quotient.digits = dividend.digits; // TODO: ??? should be 1???
        quotient.sign = dividend.sign;
        return true;
    }
    return false;
}

unittest {
    write("isZeroDividend...");
    writeln("test missing");
}

//--------------------------------

