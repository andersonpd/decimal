// Written in the D programming language

/**
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt or copy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

module decimal.unsigned;

import std.conv;
import std.stdio;
import std.traits;

unittest {
	writeln("===================");
	writeln("unsigned......begin");
	writeln("===================");
}

alias Unsigned unsigned;
alias uint digit;
alias ulong pair;

public struct Unsigned {

//--------------------------------
// structure
//--------------------------------

	private static const uint N = 4;
	private static const pair BASE_BITS = digit.sizeof;
	public static const pair BASE = 1UL << 32;

	// digits are right to left:
	// lowest digit = digit[0]; highest digit = digit[N-1]
	private digit[N] digits = 0;

	@property
	public static unsigned init() {
		return ZERO;
	}

	@property
	public static unsigned max() {
		return MAX;
	}

	@property
	public static unsigned min() {
		return MIN;
	}

//--------------------------------
// construction
//--------------------------------

	public this(const pair value) {
		digits[0] = low(value);
		digits[1] = high(value);
	}

	public this(const digit[] array) {
		uint length = array.length >= N ? N : array.length;
		for (int i = 0; i < length; i++)
			digits[i] = array[i];
	}

/*	unittest {	// construction
		unsigned num = unsigned(7503UL);
		assert(num.digits[0] == 7503);
		assert(num.digits[0] != 7502);
		num = unsigned(2^^16);
		num = unsigned(uint.max);
		num = unsigned(cast(ulong)uint.max + 1);
		assert(num.digits[0] == 0);
		assert(num.digits[1] == 1);
		num.digits[0] = 16;
		num.digits[1] = 32;
	}*/

//--------------------------------
// copy
//--------------------------------

	/// Copy constructor.
	public this(const unsigned that) {
		this.digits = that.digits;
	}

	/// Returns a copy of the number.
	public const unsigned dup() {
		return unsigned(this);
	}

	unittest {	// copy
		unsigned num = unsigned(9305);
		assert(unsigned(num) == num);
		assert(num.dup == num);
//		assert(num.abs == unsigned(9305));
//		assert(abs(num) == unsigned(9305));
	}

//--------------------------------
// constants
//--------------------------------

	public static unsigned ZERO = unsigned(0);
	public static unsigned ONE  = unsigned(1);
	public static unsigned TWO  = unsigned(2);
	public static unsigned FIVE = unsigned(5);
	public static unsigned TEN  = unsigned(10);
	// TODO: value of MAX & MIN
	public static unsigned MAX = unsigned(ulong.max);
	public static unsigned MIN = unsigned(ulong.min);

	unittest {	// constants
		unsigned num = FIVE;
		assert(num == unsigned(5));
	}

//--------------------------------
// classification
//--------------------------------

//	public const bool isZero() {
//		return digits = 0;
//	}

//--------------------------------
// conversion
//--------------------------------

	import std.array;
	import std.format;
	import std.string;

	/// Converts to a string.
	public const string toString() {
		char[] str;
		int length = numDigits(digits);
		if (length == 0) {
			return ("0x_00000000");
		}
		for (int i = 0; i < length; i++) {
//		foreach(pair value; digits) {
			str = format("_%08X", digits[i]) ~ str;
		}
//  		while (front(str) == '0' && str.length > 0) popFront(str);
		return "0x" ~ str.idup;
	}

	/// Converts to an integer.
	public const uint toInt() {
		return cast(uint)digits[0];
	}

	/// Converts to a long integer.
	public const ulong toLong() {
		return digits[0];
	}

	unittest {	// conversion
//		assert(unsigned(156).toString == "_0x9C");
		assert(unsigned(8754).toInt == 8754);
		assert(unsigned(9100).toLong == 9100L);
	}

//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0 or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T:unsigned)(const T that) {
		if (this.digits < that.digits) return -1;
		if (this.digits > that.digits) return 1;
		return 0;
	}

	/// Returns -1, 0 or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T)(const T that) if (isIntegral!T) {
		return opCmp(unsigned(that));
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T:unsigned)(const T that) {
		return this.digits == that.digits;
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T)(const T that) if (isIntegral!T) {
		return opEquals(unsigned(that));
	}

	unittest { // comparison
		assert(unsigned(5) < unsigned(6));
		assert(unsigned(5) < 6);
		assert(unsigned(-3) > unsigned(-10));
		assert(unsigned(195) >= unsigned(195));
		assert(unsigned(195) >= 195);
	}

	public static unsigned max(const unsigned arg1, const unsigned arg2) {
		if (arg1 < arg2) return arg2;
		return arg1;
	}

	public static unsigned min(const unsigned arg1, const unsigned arg2) {
		if (arg1 > arg2) return arg2;
		return arg1;
	}

//--------------------------------
// assignment
//--------------------------------

	private const digit opIndex(const uint i) {
		return digits[i];
	}

	private void opIndexAssign(T)(const uint i, const T that)
			if (isIntegral!T) {
		digits[i] = that;
	}

//	private const digit opIndexUnary(uint i) {
//		return opUnaryords[i];
//	}
//
//	private const digit opIndexOpAssign( uint i) {
//		return digits[i];
//	}

	/// Assigns an unsigned integer (copies that to this).
	private void opAssign(T:unsigned)(const T that) {
		this.digits = that.digits;
	}

	/// Assigns an integral number
	private void opAssign(T)(const T that) if (isIntegral!T) {
		opAssign(unsigned(that));
	}

	private ref unsigned opOpAssign(string op, T:unsigned) (T that) {
		this = opBinary!op(that);
		return this;
	}

	/// Assigns an unsigned (copies that to this).
	private ref unsigned opOpAssign(T)(string op, const T that) if (isIntegral!T) {
		opOpAssign(unsigned(that));
	}

//--------------------------------
// unary operations
//--------------------------------

	private const unsigned opUnary(string op)() {
		static if (op == "+") {
			return plus();
		} else static if (op == "-") {
			return comp2();
		} else static if (op == "++") {
			return uadd(this, unsigned(1));
		} else static if (op == "--") {
			return usub(this, unsigned(1));
		} else static if (op == "~") {
			return comp1();
		}
	}

	public const unsigned plus() {
		return unsigned(this.digits);
	}

	public const unsigned comp1()() {
		unsigned w;
		for (int i = 0; i < N; i++)
			w.digits[i] = ~digits[i];
		return w;
	}

	public const unsigned comp2()() {
		unsigned w = this.comp1;
		return ++w;
	}

	public const unsigned sqr() {
		// special cases
		if (this == ZERO) return ZERO;
		if (this == ONE)  return ONE;

		unsigned x = this;
		digit[2*N] w;
		for (uint i = 0; i < N; i++) {
			pair inner = w[2*i]
					+ cast(pair)(x[i]) * cast(pair)(x[i]);
			pair carry = high(inner);
			w[2*i] = low(inner);
			for (uint j = i+1; j < N; j++) {
				inner = carry + w[i+j] + 2UL * x[j] * x[i];
				carry = high(inner);
				w[i+j] = low(inner);
			}
		// if (carry >1) { overflow }
		}
		return unsigned(w[0..N-1]);
	}

	unittest {	// opUnary
		unsigned op1 = 4;
		import std.stdio;
//		assert(+op1 == op1);
//		assert( -op1 == unsigned(-4));
//		assert( -(-op1) == unsigned(4));
		assert(++op1 == unsigned(5));
//		assert(--op1 == unsigned(3));
		op1 = unsigned(0x000011111100UL);
//		assert(~op1 == 0xFFFFFFFFEEEEEEFFUL);
//		assert(op1.comp2 == 0xFFFFFFFFEEEEEF00UL);

	}

//--------------------------------
// binary operations
//--------------------------------

	private const unsigned opBinary(string op, T:unsigned)(const T that)
	{
		static if (op == "+") {
			return uadd(this, that);
		} else static if (op == "-") {
			return usub(this, that);
		} else static if (op == "*") {
			return umul(this, that);
		} else static if (op == "/") {
			return udiv(this, that);
		} else static if (op == "%") {
			return mod(this, that);
		} else static if (op == "^^") {
			return pow(this, that);
		} else static if (op == "&") {
			return and(this, that);
		} else static if (op == "|") {
			return or(this, that);
		} else static if (op == "^") {
			return xor(this, that);
		} else static if (op == "<<") {
			return shl(this, that);
		} else static if (op == ">>") {
			return shr(this, that);
		}
	}

	private const unsigned opBinary(string op, T)(const T that) if (isIntegral!T) {
		return opBinary!(op, unsigned)(unsigned(that));
	}

/*	unittest {	// opBinary
		unsigned op1, op2;
		op1 = 4; op2 = 8;
		assert(op1 + op2 == 12);
		op1 = 4; int iop = 8;
		assert(op1 + iop == 12);
		assert(op2 - op1 == unsigned(4));
		assert(op1 * op2 == 32);
		op1 = 5; op2 = 2;
writefln("op1/op2 = %s", op1/op2);
//		assert(op1 / op2 == 2);
		assert(op1 % op2 == 1);
		assert(op1 ^^ op2 == 25);
		op1 = 10101; op2 = 10001;
		assert((op1 & op2) == 10001);
		assert((op1 | op2) == 10101);
		assert((op1 ^ op2) == 100);
		op2 = 2;
		assert(op1 << op2 == 40404);
		assert(op1 >> op2 == 2525);
		op1 = 4; op2 = unsigned([0,1]);
		assert(op1 + op2 == 0x100000004);

	}*/

	public const unsigned uadd(const unsigned x, const unsigned y) {
        return unsigned(add(x.digits, y.digits));
	}

	public const unsigned usub(const unsigned x, const unsigned y) {
		return unsigned(sub(x.digits, y.digits));
	}

	public const unsigned umul(const unsigned x, const unsigned y) {
		// special cases
		if (x == ZERO || y == ZERO) return ZERO;
		if (y == ONE) return x;
		if (x == ONE) return y;

		digit[] w = mul(x.digits, y.digits);
		return unsigned(w[0..N-1]);
	}

	public const unsigned udiv(const unsigned a, const unsigned b) {

		uint n = numDigits(a.digits);
		if (n == 0) return ZERO;
		uint t = numDigits(b.digits);
		if (t == 0) return ZERO; // TODO: should throw
		if (b == ONE) return a;

		return unsigned(div(a.digits, b.digits));
	}

	public const unsigned mod(const unsigned x, const unsigned y) {
		return unsigned(x.digits[0] % y.digits[0]);
	}

	public const unsigned pow(const unsigned x, const unsigned y) {
		return unsigned(x.digits[0] ^^ y.digits[0]);
	}

	public const unsigned and(const unsigned x, const unsigned y) {
		unsigned result;
		for (int i = 0; i < N; i++)
			result.digits[i] = (x.digits[i] & y.digits[i]);
		return result;
	}

	public const unsigned or(const unsigned x, const unsigned y) {
		unsigned result;
		for (int i = 0; i < N; i++)
			result.digits[i] = (x.digits[i] | y.digits[i]);
		return result;
	}

	public const unsigned xor(const unsigned x, const unsigned y) {
		unsigned result;
		for (int i = 0; i < N; i++)
			result.digits[i] = (x.digits[i] ^ y.digits[i]);
		return result;
	}

	public const unsigned shl(const unsigned x, const unsigned y) {
		return unsigned(x.digits[0] << y.digits[0]);
	}

	public const unsigned shr(const unsigned x, const unsigned y) {
		return unsigned(x.digits[0] >> y.digits[0]);
	}


}

//--------------------------------
// unsigned operations
//--------------------------------

	/// Returns the absolute value of the number.
	/// No effect on unsigned numbers -- just copies.
	public unsigned abs(const unsigned arg) {
		return arg.dup;
	}

/*	public unsigned sqr(const unsigned x) {
		// special cases
//		if (this == ZERO) return ZERO;
//		if (this == ONE)  return ONE;

		digit[2*N] w;
		for (uint i = 0; i < N; i++) {
			pair inner = w[2*i]
					+ cast(pair)(x[i]) * cast(pair)(x[i]);
			pair carry = high(inner);
			w[2*i] = low(inner);
			for (uint j = i+1; j < N; j++) {
				inner = carry + w[i+j] + 2UL * x[j] * x[i];
				carry = high(inner);
				w[i+j] = low(inner);
			}
		// if (carry >1) { overflow }
		}
		return unsigned(w[0..N-1]);
	}*/

private digit low(const pair pr)
    { return pr & 0xFFFFFFFFUL; }

private digit high(const pair pr)
    { return (pr & 0xFFFFFFFF00000000UL) >> 32; }

private pair pack(digit hi, digit lo) {
	pair pr = (cast(pair) hi) << 32;
	pr |= lo;
	return pr;
}

// shifts by whole digits (not bits)
private digit[] digitShift(digit[] array, int n) {
	if (n > 0)
		return array ~ new digit[n];
	if (n < 0)
		return new digit[-n] ~ array;
	// n == 0
	return array;
}

/*unittest {
	writeln("digitShift...");
	digit[] input, output;
	input = [ 1, 2, 3 ];
	output = digitShift(input, 0);
	input = [ 1, 2, 3 ];
	output = digitShift(input, 2);
	output = digitShift(input, -2);
	writeln("test missing");
}*/

private digit[] bitShift(digit[] array, int n) {
	return array;
}

private digit[] shift(digit[] array, int n) {
	bool sign = false;
	if (n < 0) {
		n = -n;
		sign = true;
	}
	int digits = n / digit.sizeof;
	int bits = n % digit.sizeof;
	if (sign) {
		digits = -digits;
		bits = -bits;
	}
	digitShift(array, digits);
	digitShift(array, bits);
	return array;
}

//--------------------------------
// array operations
//--------------------------------

	/// Returns the number of digits in the array.
	/// Trailing zero digits are not counted.
	/// If all digits are zero, returns length = 0.
	private int numDigits(const digit[] digits) {
		int count;
		for (count = digits.length; count > 0; count--) {
			if (digits[count-1]) break;
		}
		return count;
	}

/*	unittest {
		digit[] array;
		array = [ 1, 2, 3, 5 ];
		assert(numDigits(array) == 4);
		array = [ 1, 2, 3, 0 ];
		assert(numDigits(array) == 3);
		array = [ 1, 0, 0, 0, 0 ];
		assert(numDigits(array) == 1);
		array = [ 0, 0, 0, 0, 0 ];
		assert(numDigits(array) == 0);
	}*/

	/// Compares two arrays of digits.
	/// Returns -1, 0, or 1 if the second argument is, respectively,
	/// smaller than, equal to or larger than the first.
	private int compare(const digit[] a, const digit[] b) {

		// if lengths differ...
		uint m = numDigits(a);
		uint n = numDigits(b);
		if (m > n) return -1;
		if (m < n) return  1;

		// same length; return the first difference
		for (int i = n-1; i >= 0; i--) {
			if (a[i] < b[i]) return  1;
			if (a[i] > b[i]) return -1;
		}
		// no differences; return 0
		return 0;
	}

	/// Compares two arrays of digits.
	/// Returns -1, 0, or 1 if the second argument is, respectively,
	/// smaller than, equal to or larger than the first.
	private int compare(const digit[] a, const digit k) {
		uint[] b = [ k ];
		return compare(a,b);
	}

/*	unittest {
		writeln("compare...");
		digit[] a, b;
		a = [4, 3, 2, 0 ];
		b = [4, 3, 2];
		int c = compare(a, b);
		writeln("test missing");
	}*/

//--------------------------------
// addition and subtraction
//--------------------------------

	/// Returns the sum of the two arrays.
	private digit[] add(const digit[] x, const digit[] y) {
		uint n = numDigits(x);
		uint m = numDigits(y);
		digit[] a, b;
		if (m > n) {
			a = y[0..m].dup;
			b = x[0..n].dup;
			uint t = n;
			n = m;
			m = t;
		}
		else {
			a = x[0..n].dup;
			b = y[0..m].dup;
		}
		digit[] sum = new digit[n + 1];
		digit carry = 0;
		pair temp;
		for (uint i = 0; i < m; i++) {
			temp = a[i] + b[i] + carry;
			sum[i] = low(temp);
			carry = high(temp);
		}
		for (int j = m; j < n; j++) {
			if (carry) {
				temp = x[j] + carry;
				sum[j] = low(temp);
				carry = high(temp);
			}
			else {
				sum[j] = x[j];
			}
		}
		// if (length == N && carry == 1) { overflow }
		return sum;
	}

	/// Returns the sum of the array and a single digit.
	private static digit[] add(const digit[] x, const digit y) {
		uint n = numDigits(x);
		digit[] sum = new digit[n + 1];
		pair temp = x[0] + y;
		sum[0] = low(temp);
		digit carry = high(temp);
		for (int i = 1; i < n; i++) {
			if (carry) {
				temp = x[i] + carry;
				sum[i] = low(temp);
				carry = high(temp);
			}
			else {
				sum[i] = x[i];
			}
		}
		// if (length == N && carry == 1) { overflow }
		return sum;
	}

	// Subtracts one array from another.
	// precondition: x >= y.
	private digit[] sub(const digit[] x, const digit[] y) {
		uint n = numDigits(x);
  		digit[] diff = new digit[n];
		digit borrow = 0;
		for (int i = 0; i < n; i++) {
			diff[i] = x[i] - y[i] - borrow;
			borrow = diff[i] < 0 ? 1 : 0;
		}
		// if (borrow == 1) { diff is negative }
		return diff;
	}

//--------------------------------
// multiplication and squaring
//--------------------------------

	// Returns the product of the two arrays.
	private digit[] mul(const digit[] x, const digit[] y) {
		uint n = numDigits(x);
		uint t = numDigits(y);
		digit[] w = new digit[n + t + 1];
		w[] = 0;
		for (uint i = 0; i < t; i++) {
			pair carry = 0;
			for (uint j = 0; j < n; j++) {
				pair inner = carry + w[i+j]
					+ cast(pair)(x[j]) * cast(pair)(y[i]);
				carry = high(inner);
				w[i+j] = low(inner);
			}
			w[i+n] = low(carry);
		// if (n >= N && carry > 1) { overflow }
		}
		return w;
	}

/*	/// Multiplies an array of digits by a single digit
	private digit[] mul(const digit[] x, const digit k) {
		int m = numDigits(x);
		digit[] w = new digit[m+1];
		pair carry = 0;
		for (int i = 0; i < m; i++) {
			pair temp = cast(long)k * x[i] + carry;
			w[i] = low(temp);
			carry = high(temp);
		}
		w[m] = low(carry);
		// if carry != 0 then overflow
		return w;
	}*/

	// Returns the square of the argument.
	public digit[] sqr(const digit[] x) {
		uint n = numDigits(x);
		digit[] sqrx = new digit[2*n];
		for (uint i = 0; i < n; i++) {
			pair inner = sqrx[2*i]	+ cast(pair)x[i] * cast(pair)x[i];
			pair carry = high(inner);
			sqrx[2*i] = low(inner);
			for (uint j = i+1; j < n; j++) {
				inner = carry + sqrx[i+j] + 2 * cast(pair)x[j] * cast(pair)x[i];
				carry = high(inner);
				sqrx[i+j] = low(inner);
			}
			sqrx[i+n] = low(carry);
		// if (carry >1) { overflow }
		}
		return sqrx;
	}

//--------------------------------
// division and modulus
//--------------------------------

	/// Returns the quotient of the first array divided by the second.
	private digit[] div(const digit[] a, const digit[] b) {

		uint n = numDigits(a) - 1;
		uint t = numDigits(b) - 1;
		digit[] x = a[0..n+1].dup;
		digit[] y = b[0..t+1].dup;
		digit[] q = new digit[n-t+1];
		for (int i = 0; i < n-t+1; i++)
		q[i] = 0;
		digit[] ys = digitShift(y,t-n); // TODO: fix shift -- I Ithink its backwards
		while (compare(x,ys) <0) {
			q[n-t]++;
			x = sub(x, ys);
		}
		for (int i = n; i >= t+1; i--) {
			int ix = i - t - 1;
			if (x[i] == y[t]) {
				q[ix] = unsigned.BASE - 1; // uint.max
			}
			else {
				q[ix] = div(x[i-1..i+1], y[t])[0];
			}
			int count = 0;
			while ((compare(mul(y[t-1..t+1], q[ix..ix+1]), x[i-2..i+1])) > 0) {
				q[ix]++;
				count++;
				if (count > 10) break;
			}
			x = sub(x, mul(ys, q[ix..ix+1]));
			if (compare(x, 0)) {
				x = add(x, digitShift(y,ix));
				q[ix]--;
			}
		}
		return q;
	}

	/// Divides an array of digits by a single digit
	private digit[] div(const digit[] x, const digit k) {
		int m = numDigits(x);
		digit[] q = x[0..m].dup;
		digit[] remainder;
		pair carry = 0;
		for (int i = m-1; i >= 0; i--) {
			pair temp = carry * unsigned.BASE + x[i];
			q[i] = low(temp / k);
			carry = temp % k;
		}
		return q;
	}

unittest {
	write("div...");
	digit[] input, output;
	digit k;
	input = [28, 20, 48, 76];
	output = div(input, 2);
//writefln("output = %s", output);
writefln("unsigned(output) = %s", unsigned(output));
	input = random(4);
//writefln("input = %s", input);
writefln("unsigned(input) = %s", unsigned(input));
	k = randomDigit;
writefln("k = %X", k);
	output = div(input, k);
writefln("unsigned(output) = %s", unsigned(output));
//writefln("output = %s", output);
	digit[] ka = [ k ];
writefln("unsigned(mul(output, ka) = %s", unsigned(mul(output, ka)));

	writeln("test  ----- missing");
}

	// Minefield, Algorithm 5: Remainder
	private digit[] modDigit(digit[] x, digit k) {
		int m = numDigits(x);
		digit[] quotient = x[0..m];
		digit[] remainder;
		pair carry = 0;
		for (int i = m-1; i >= 0; i--) {
			pair temp = carry * unsigned.BASE + x[i];
//			x[i] = cast(digit)temp / k;
			carry = temp % k;
		}
		return [ cast(digit)carry ];
	}

//--------------------------------
// logical operations
//--------------------------------

	private digit[] and(const digit[] a, const digit[] b) {
		uint m = numDigits(a);
		uint n = numDigits(b);
		if (n > m) {
		}
		else if (m > n) {
		}
		digit[] and = new digit[n];
		for (int i = 0; i < n; i++) {
			and[i] = a[i] & b[i];
		}
		return and[];

	}

//--------------------------------
// random numbers
//--------------------------------

	private digit[] random(uint n) {
		digit[] rand = new digit[n];
		for (int i = 0; i <n; i++) {
			rand[i] = randomDigit;
		}
	    return rand;
	}

	private digit randomDigit() {
		return std.random.uniform(0, digit.max);
	}

unittest {
	writeln("random digits...");
	digit[] r = random(4);
//writefln("r = %s", r);
writefln("unsigned(r) = %s", unsigned(r));
	digit[] s = random(4);
//writefln("s = %s", s);
writefln("unsigned(s) = %s", unsigned(s));
writefln("compare(r,s) = %s", compare(r,s));
	digit[] t;
	if (compare(r,s) < 0) {
		t = sub(r,s);
writefln("unsigned(t) = %s", unsigned(t));
writefln("unsigned(add(t,s)) = %s", unsigned(add(t,s)));
	}
	else {
		t = add(r,s);
writefln("unsigned(t) = %s", unsigned(t));
writefln("unsigned(sub(t,r)) = %s", unsigned(sub(t,r)));
	}
   	digit[] x = random(2);
	digit[] y = random(2);
	digit[] z = mul(x,y);
writefln("unsigned(x) = %s", unsigned(x));
writefln("unsigned(y) = %s", unsigned(y));
writefln("unsigned(z) = %s", unsigned(z));

	digit[] abc = div(z,y);
writefln("unsigned(abc) = %s", unsigned(abc));
	digit[] k = random(1);
	z = mul(x,k[0..1]);
writefln("unsigned(k) = %s", unsigned(k));
writefln("unsigned(z) = %s", unsigned(z));

	digit[] rt = random(1);
writefln("unsigned(rt) = %s", unsigned(rt));
	digit[] px = mul(rt,rt);
writefln("unsigned(px) = %s", unsigned(px));
	rt = sqr(rt);
writefln("unsigned(rt) = %s", unsigned(rt));
	writeln("passed");
}

unittest {
	writeln("===================");
	writeln("unsigned........end");
	writeln("===================");
}

