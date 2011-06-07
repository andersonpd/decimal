﻿// Written in the D programming language

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

module decimal.bcd;

import std.conv: ConvError;
import std.math;
import std.stdio: write, writeln;
import std.string: strip;

alias ubyte Digit;

public immutable Bcd ZERO = { digits:[0] };
public immutable Bcd ONE  = { digits:[1] };
public immutable Bcd NEG_ONE = { sign:true, digits:[1] };

public struct Bcd {

    // members
    /**
     * The sign of the BCD integer. Sign is kept explicitly.
     **/
    private bool sign = false;
    /**
     * An array of decimal digits in reverse (right-to-left) order
     * representing an integral value.
     * Trailing zeros have no effect on the value of the number;
     * they correspond to leading zeros in a left-to-right representation.
    **/
    private Digit[] digits = [ 0 ];

    // access methods

    // access to sign
    const bool getSign() {
        return sign;
    }

    void setSign(bool sign) {
        this.sign = sign;
    }

    const bool isSigned() {
        return sign;
    }

    // access to digits
    const uint numDigits() {
        return digits.length;
    }

    void setNumDigits(uint n) {
        digits.length = n;
    }

    const uint firstDigit() {
        return digits[$-1];
    }

    const uint lastDigit() {
        return digits[0];
    }

    void setDigit(uint n, Digit value) {
        digits[$-n-1] = value;
    }

    const int getDigit(int n) {
        return digits[$-n-1];
    }

    unittest {
        write("digits...");
        Bcd bcd = Bcd(12345678L);
        assert(bcd.numDigits() == 8);
        assert(bcd.firstDigit() == 1);
        assert(bcd.lastDigit() == 8);
        assert(bcd.getDigit(3) == 4);
        bcd.setDigit(3, 7);
        assert(bcd.getDigit(3) == 7);
        bcd.setNumDigits(10);
        assert(bcd.numDigits == 10);
        assert(bcd.firstDigit() == 0);
        assert(bcd.getDigit(5) == 7);
        bcd.setNumDigits(5);
        assert(bcd.getDigit(2) == 6);
//        writeln("bcd = ", bcd);
        writeln("passed!");
    }

    // constructors
    public this(this) {
        digits = digits.dup;
    }

/+    public this(const Bcd bcd) {
//        this();
        this = Bcd(bcd);
    }+/

/+    public this(const Bcd bcd, uint numDigits) {
        this = bcd;
        setNumDigits(numDigits);
    }+/

    public this(const long n) {
        uint m;
        if (n < 0) {
            sign = true;
            m = std.math.abs(n);
        }
        else {
            sign = false;
            m = n;
        }
        Digit[20] dig;
        int i = 0;
        do {
            uint q = m/10;
            uint r = m%10;
            dig[i] = cast(Digit) r;
            m = q;
            i++;
        } while (m > 0);
        digits = dig[0..i].dup;
    }

    public this(const long n, uint numDigits) {
        this = n;
        setNumDigits(numDigits);
    }

    public this(const string str) {
        this = parse(str);
    }

    const string toString() {
        return format(this);
    }

    unittest {
        writeln("toString...");
        writeln("passed!");
    }

    const hash_t toHash() {
        hash_t hash = 0;
        foreach(Digit digit; digits) {
            hash += digit;
        }
        return hash;
    }

    unittest {
        writeln("toHash...");
        writeln("passed!");
    }

    const bool isZero() {
        writeln("stripping");
        Bcd temp = stripLeadingZeros(this);
        writeln("stripped");
        writeln("temp = ", temp);
        if (temp.numDigits > 1) return false;
        return temp.lastDigit == 0;
    }

    const bool hasLeadingZeros() {
        return numDigits > 0 && firstDigit == 0;
    }

    Bcd opAssign(const Bcd that) {
        this.sign = that.sign;
        this.digits.length = that.digits.length;
        this.digits[] = that.digits[];
        return this;
    }

    void opAssign(const string str) {
        this = Bcd(str);
    }

    void opAssign(const long n) {
        this = Bcd(n);
/+        uint m;
        if (n < 0) {
            sign = true;
            m = std.math.abs(n);
        }
        else {
            sign = false;
            m = n;
        }
        Digit[20] dig;
        int i = 0;
        do {
            uint q = m/10;
            uint r = m%10;
            dig[i] = cast(Digit) r;
            m = q;
            i++;
        } while (m > 0);
        digits = dig[0..i].dup;+/
    }


    // index operator
    Digit opIndex(uint index) {
        return this.digits[index];
    }

    // index assign operator
    void opIndexAssign(Digit value, uint index) {
        this.digits[index] = value;
    }

/+    int opApply(int delegate (ref Digit) dg) {
        int result = 0;
        for (int i = 0; i < numDigits; i++) {
            result = dg(digits[i]);
            if (result) break;
        }
        return result;
    }

    int opApply(int delegate (ref Digit) dg) {
        int result = 0;
        for (int i = 0; i < numDigits; i++) {
            result = dg(digits[i]);
            if (result) break;
        }
        return result;
    }

    int opApplyReverse(int delegate (ref Digit) dg) {
        int result = 0;
        for (int i = 0; i < numDigits; i++) {
            result = dg(digits[i]);
            if (result) break;
        }
        return result;
    }+/

/+    const Bcd dup() {
        Bcd bcd;
        bcd.sign = this.sign;
        bcd.digits.length = this.digits.length;
        bcd.digits[] = this.digits[];
        return bcd;
    }+/

    // TODO: always uncertain how this is done...will it make an unnecessary copy?
    const Bcd opPos() {
        return copy(this);
/+        Bcd a = this;          // this is what I'm talking about
        return a;+/
    }

    const Bcd opNeg() {
        return negate(this);
    }

    const Bcd opCom() {
        return complement(this);
    }

    const Bcd opNot() {
        return not(this);
    }

/+    const Bcd opAnd(const Bcd bcd) {
        const Bcd a = this;
        return and(a, bcd);
    }+/

/+    const Bcd opOr(const Bcd bcd) {
        return or(this, bcd);
    }

    const Bcd opXor(const Bcd bcd) {
        return xor(cast(const) this, bcd);
    }+/

    // TODO: what's the matter with the one-digit numbers??
    const bool opEquals(T:Bcd)(const T that) {
//        writeln("equating");
        if (this.sign != that.sign) return false;     // what about +/- zero?
//        writeln("same signs");
        Bcd thisOne = stripLeadingZeros(this);
//        writeln("this = ", thisOne);
        Bcd thatOne = stripLeadingZeros(that);
//        writeln("that = ", thatOne);
        if (thisOne.digits.length != thatOne.digits.length) return false;
//        writeln("length = ", thisOne.digits.length);
//        foreach(int i, Digit digit; thisOne) {    // todo: have to make opApply here.
//        }
        foreach_reverse(int i, Digit digit; thisOne.digits) {
/+            writeln("i = ", i);
            writeln("this[i] = ", thisOne.digits[i]);
            writeln("that[i] = ", thatOne.digits[i]);
            writeln("this = ", thisOne.digits);
            writeln("that = ", thatOne.digits);+/
            if (digit != thatOne.digits[i]) return false;
        }
        return true;
    }

    const bool opEquals(T)(const T that) {
        return opEquals(Bcd(that));
    }

} // end struct Bcd

private bool isDigit(const char ch) {
    return (ch >= '0' && ch <= '9');
}

public string format(const Bcd bcd, bool showPlus = false, bool showLeadingZeros = false) {
    int len = bcd.digits.length;
    if (bcd.sign) len++;
    char[] str = new char[len];

    int index = 0;
    if (bcd.sign) {
        str[index] = '-';
        index++;
    }

    foreach_reverse(Digit digit; bcd.digits) {
        str[index] = cast(char) digit + '0';
        index++;
    }
    return str.idup;
}

public Bcd parse(string str) {
    Bcd bcd;
    // are leading zeros retained?
    bool lz = false;

    // strip whitespace, convert to char array
    char[] str1 = str.strip.dup;

    // check for leading '-'
    if (str1[0] == '-') {
        bcd.sign = true;
        str1 = str1[1..$];
        lz = true;
    }

    // check for leading '+'
    if (str1[0] == '+') {
        bcd.sign = false;
        str1 = str1[1..$];
        lz = true;
    }

    // verify chars are digits, strip out underscores
    int index = 0;
    char[] str2 = new char[str1.length];
    foreach_reverse(char ch; str1) {
        if (isDigit(ch)) {
            str2[index] = ch;
            index++;
            continue;
        }
        if (ch == '_') {
            continue;
        }
        throw (new ConvError("Invalid character: " ~ ch));
    }
    str2.length = index;

    bcd.digits.length = index;
    foreach(int i, char ch; str2) {
        bcd.digits[i] = cast(Digit)(ch - '0');
    }

    if (!lz) return stripLeadingZeros(cast(const) bcd);
    return bcd;
}

public Bcd copy(const Bcd bcd) {
    return cast(Bcd) bcd;
}

public Bcd negate(const Bcd bcd) {
    Bcd copy = cast(Bcd) bcd;
    copy.sign = !bcd.sign;
    return copy;
}

public Bcd abs(const Bcd bcd) {
    return bcd.isSigned ? -bcd: +bcd;
}

public Bcd stripLeadingZeros(const Bcd bcd) {
    Bcd result = cast(Bcd) bcd;
    if (!bcd.hasLeadingZeros) return result;
    int len = bcd.numDigits;
    int i = 0;
    while(i < len-1 && bcd.getDigit(i) == 0) {
        i++;
    }
    result.setNumDigits(len - i);
    return result;
}


unittest {
    write("strip...");
    Bcd bcd;
    bcd = "+00123";
    assert(bcd.toString == "00123");
    bcd = stripLeadingZeros(bcd);
    writeln("bcd = ", bcd);
    assert(bcd.toString == "123");
    bcd = "+000";
    writeln("bcd = ", bcd);
    assert(bcd.toString == "000");
    bcd = stripLeadingZeros(bcd);
    writeln("bcd = ", bcd);
    writeln("passed");
}

public bool sameLength(const Bcd a, const Bcd b) {
    return a.numDigits == b.numDigits;
}

public int setSameLength(ref Bcd a, ref Bcd b) {
    if (sameLength(cast(const)a, cast(const)b)) return a.numDigits;
    uint alen = a.numDigits;
    uint blen = b.numDigits;
    if (alen > blen) {
        b.setNumDigits(alen);
    }
    else {
        a.setNumDigits(blen);
    }
    return a.numDigits();
}

public Bcd complement(const Bcd a) {
    Bcd b = Bcd(0, a.numDigits);
    foreach(int i, Digit digit; a.digits) {
        b.digits[i] = digit == 0 ? 1 : 0 ;
    }
    return b;
}

unittest {
    write("com...");
    Bcd bcd;
    bcd = 123;
    assert(complement(bcd).toString == "000");
    bcd = 40509;
    assert(complement(bcd).toString == "01010");
//    writeln("bcd = ", bcd);
//    writeln("~bcd = ", complement(bcd));
    writeln("passed");
}

public int sgn(Bcd bcd) {
    if (bcd.isZero) return 0;
    return bcd.isSigned ? -1 : 1;
}

public Bcd not(const Bcd x) {
    Bcd result = cast(Bcd) x;
    for (int i = 0; i < x.numDigits; i++) {
        result[i] = not(result[i]);
    }
    return result;
}

private Digit not(const Digit a) {
    return a != 0;
}

public Bcd and(const Bcd x, const Bcd y) {
    Bcd a = cast(Bcd) x;
    Bcd b = cast(Bcd) y;
    int len = setSameLength(a,b);
    Bcd result = Bcd(0, len);
    for (int i = 0; i < len; i++) {
        result[i] = and(a[i], b[i]);
    }
    return result;
}

private Digit and(in Digit a, in Digit b) {
    return a != 0 && b != 0;
}

unittest {
    write("and...");
    Bcd a;
    Bcd b;
    a = 123000;
    b = 123000;
    assert(and(a,b).toString == "111000");
    b = 12300;
    assert(and(a,b).toString == "011000");
    a = 1234567;
    b = 7654321;
    assert(and(a,b).toString == "1111111");
    a = 1010;
    b = 101;
    writeln("a = ", a);
    writeln("b = ", b);
    writeln("and = ", and(a,b));
    assert(and(a,b).isZero);
    writeln("passed!");
}

// TODO: looks like there's some room for templates or mixins here.
public Bcd or(const Bcd x, const Bcd y) {
    Bcd a = cast(Bcd) x;
    Bcd b = cast(Bcd) y;
    int len = setSameLength(a,b);
    Bcd result = Bcd(0, len);
    for (int i = 0; i < len; i++) {
        result[i] = or(a[i], b[i]);
    }
    return result;
}

private Digit or(const Digit a, const Digit b) {
    return a != 0 || b != 0;
}


public Bcd xor(const Bcd x, const Bcd y) {
    Bcd a = cast(Bcd) x;
    Bcd b = cast(Bcd) y;
    int len = setSameLength(a,b);
    Bcd result = Bcd(0, len);
    for (int i = 0; i < len; i++) {
        result[i] = xor(a[i], b[i]);
    }
    return result;
}

private Digit xor(const Digit a, const Digit b) {
    return (a == 0 && b != 0) || (a != 0 && b == 0);
}

/**
 * Adds two BCD integers without regard to sign
**/
private Bcd addBasic(const Bcd a, const Bcd b) {
    Bcd x,y;
    writeln("wad");
    x = cast(Bcd) a; y = cast(Bcd) b;
    writeln("wax");
    int len = setSameLength(x, y);
    writeln("war");
    Bcd result = Bcd(0, len+1);
    writeln("wag");
    Digit carry = 0;
    uint i;
    for (i = 0; i < len; i++) {
        result[i] = add(x[i], y[i], carry);
    }
    writeln("wan");
    if (carry) {
        result[i] = 1;
    writeln("was");
    }
/+    else {
        result = stripLeadingZeros(result);
    }+/
    return result;
}
/**
 * Adds two digits and a carry digit.
 * Returns the (single-digit) sum and sets or resets the carry digit.
**/
private Digit add(const Digit a, const Digit b, ref Digit carry) {
    Digit sum = a + b + carry;
    carry = sum > 9;
    if (carry) sum -= 10;
    return sum;
}

unittest {
    write("add...");
    Bcd a, b;
    a = 123;
    b = 222;
    Bcd sum = addBasic(a,b);
    assert(sum == 345);
    a = 2;
    b = 102000;
    sum = addBasic(a,b);
    assert(sum == 102002);
    writeln("passed!");
}

private Bcd tensComp(const Bcd a) {
    int len = a.numDigits;
    Bcd x;
    writeln("boo");
    x.setNumDigits(len);
    writeln("bob");
    for (int i = 0; i < len; i++) {
        x[i] = 9 - a.digits[i];
    }
    writeln("box");
    return addBasic(cast(const) x, Bcd(1));
}

unittest {
    write("tensComp...");
    Bcd a, b, c;
    a = 123456;
    b = tensComp(a);
    c = 876544;
    assert(b == c);
    a = Bcd(0, 4);
    b = tensComp(a);
    c = 10000;
    assert(b == c);
    a = Bcd(1, 4);
    b = tensComp(a);
    c = 9999;
    assert(b == c);
    a = 9999;
    b = tensComp(a);
    c = 1;
    assert(b == c);
    a = 10000;
    b = tensComp(a);
    c = 90000;
    assert(b == c);
    a = 1;
    b = tensComp(a);
    c = 9;
    writeln("a = ", a);
    writeln("b = ", b);
    assert(b == c);
    writeln("passed");
}

//==========================================

public void main() {
    writeln("Hello, world");
/+    Bcd bcd;
    writeln("bcd = ", format(bcd));
    bcd = parse("12");
    writeln("bcd = ", format(bcd));
    bcd = parse("012");
    writeln("bcd = ", format(bcd));
    bcd = parse("-012");
    writeln("bcd = ", format(bcd));
    bcd = parse("+012");
    writeln("bcd = ", format(bcd));
    bcd = parse("-0");
    writeln("bcd = ", format(bcd));
    bcd = parse("012_345_678");
    writeln("bcd = ", format(bcd));

    bcd = 1234;
    writeln("bcd = ", format(bcd));
    bcd = 12345678L;
    writeln("bcd = ", format(bcd));
    writeln("a == b : ", Bcd(0) == Bcd(0));
    writeln("a == b : ", Bcd(4) == Bcd(4));
    writeln("a == b : ", Bcd(40) == Bcd(40));
    writeln("a == b : ", Bcd(-400) == Bcd(-400));
    writeln("a == b : ", Bcd(12345678) == Bcd(+12345678));
    writeln("a != b : ", Bcd(40) == Bcd(53));
    writeln("a != b : ", Bcd(402) == Bcd(531));
    writeln("a != b : ", Bcd(402) == Bcd(-402));
    writeln("a != b : ", Bcd(65432) == Bcd(65431));
    writeln("a != b : ", Bcd(2) == Bcd(1));
    writeln("a != b : ", Bcd(1) == Bcd(2));
    writeln("OK!");+/
}



