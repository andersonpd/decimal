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
//alias uint uint;

public struct Unsigned {

//--------------------------------
// structure
//--------------------------------

	private static const uint N = 4;
	private static const ulong BASE_BITS = uint.sizeof;
	public static const ulong BASE = 1UL << 32;

	// digits are right to left:
	// lowest uint = uint[0]; highest uint = uint[N-1]
	private uint[N] digits = 0;

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

	public this(const ulong value) {
		digits[0] = low(value);
		digits[1] = high(value);
	}

	public this(const uint[] array) {
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

/*	unittest {	// copy
		unsigned num = unsigned(9305);
		assert(unsigned(num) == num);
		assert(num.dup == num);
//		assert(num.abs == unsigned(9305));
//		assert(abs(num) == unsigned(9305));
	}*/

//--------------------------------
// constants
//--------------------------------

	public const unsigned ZERO = unsigned(0);
	public static unsigned ONE  = unsigned(1);
	public static unsigned TWO  = unsigned(2);
	public static unsigned FIVE = unsigned(5);
	public static unsigned TEN  = unsigned(10);
	// TODO: value of MAX & MIN
	public const unsigned MAX = unsigned([uint.max, uint.max, uint.max, uint.max]);
	public static unsigned MIN = unsigned(0);

/*	unittest {	// constants
		unsigned num = FIVE;
		assert(num == unsigned(5));
	}*/

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
//		foreach(ulong value; digits) {
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

/*	unittest {	// conversion
//		assert(unsigned(156).toString == "_0x9C");
		assert(unsigned(8754).toInt == 8754);
		assert(unsigned(9100).toLong == 9100L);
	}*/

//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0 or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T:unsigned)(const T that) {
		return compare(this.digits, that.digits);
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
/*		assert(unsigned(5) < unsigned(6));
		assert(unsigned(5) < 6);
		assert(unsigned(-3) > unsigned(-10));
		assert(unsigned(195) >= unsigned(195));
		assert(unsigned(195) >= 195);*/
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

	private const uint opIndex(const uint i) {
		return digits[i];
	}

	private void opIndexAssign(T)(const uint i, const T that)
			if (isIntegral!T) {
		digits[i] = that;
	}

//	private const uint opIndexUnary(uint i) {
//		return opUnaryords[i];
//	}
//
//	private const uint opIndexOpAssign( uint i) {
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
			return negate();
		} else static if (op == "++") {
			return add(this, unsigned(1));
		} else static if (op == "--") {
			return sub(this, unsigned(1));
		} else static if (op == "~") {
			return complement();
		}
	}

	public const unsigned plus() {
		return unsigned(this.digits);
	}

	public const unsigned complement()() {
		unsigned w;
		for (int i = 0; i < N; i++)
			w.digits[i] = ~digits[i];
		return w;
	}

	public const unsigned negate()() {
		unsigned w = this.complement;
		return ++w;
	}

	public const unsigned sqr() {
		// special cases
		if (this == ZERO) return ZERO;
		if (this == ONE)  return ONE;

		unsigned x = this;
		uint[2*N] w;
		for (uint i = 0; i < N; i++) {
			ulong inner = w[2*i]
					+ cast(ulong)(x[i]) * cast(ulong)(x[i]);
			ulong carry = high(inner);
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

/*	unittest {	// opUnary
		unsigned op1 = 4;
		import std.stdio;
//		assert(+op1 == op1);
//		assert( -op1 == unsigned(-4));
//		assert( -(-op1) == unsigned(4));
		assert(++op1 == unsigned(5));
//		assert(--op1 == unsigned(3));
		op1 = unsigned(0x000011111100UL);
//		assert(~op1 == 0xFFFFFFFFEEEEEEFFUL);
//		assert(op1.negate == 0xFFFFFFFFEEEEEF00UL);

	}*/

//--------------------------------
// binary operations
//--------------------------------

	private const unsigned opBinary(string op, T:unsigned)(const T that)
	{
		static if (op == "+") {
			return add(this, that);
		} else static if (op == "-") {
			return sub(this, that);
		} else static if (op == "*") {
			return mul(this, that);
		} else static if (op == "/") {
			return div(this, that);
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
//writefln("op1/op2 = %s", op1/op2);
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

	public const unsigned add(const unsigned x, const unsigned y) {
        return unsigned(addDigits(x.digits, y.digits));
	}

	public const unsigned sub(const unsigned x, const unsigned y) {
		return unsigned(subDigits(x.digits, y.digits));
	}

	public const unsigned mul(const unsigned x, const unsigned y) {
		// special cases
		if (x == ZERO || y == ZERO) return ZERO;
		if (y == ONE) return x;
		if (x == ONE) return y;

		uint[] w = mulDigits(x.digits, y.digits);
		return unsigned(w[0..N-1]);
	}

	public const unsigned div(const unsigned a, const unsigned b) {

		uint n = numDigits(a.digits);
		if (n == 0) return ZERO;
		uint t = numDigits(b.digits);
		if (t == 0) return ZERO; // TODO: should throw
		if (b == ONE) return a;

		return unsigned(divDigits(a.digits, b.digits));
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

		uint[2*N] w;
		for (uint i = 0; i < N; i++) {
			ulong inner = w[2*i]
					+ cast(ulong)(x[i]) * cast(ulong)(x[i]);
			ulong carry = high(inner);
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

private uint low(const ulong pr)
    { return pr & 0xFFFFFFFFUL; }

private uint high(const ulong pr)
    { return (pr & 0xFFFFFFFF00000000UL) >> 32; }

private ulong pack(uint hi, uint lo) {
	ulong pr = (cast(ulong) hi) << 32;
	pr |= lo;
	return pr;
}

// shifts by whole digits (not bits)
private uint[] scale(uint[] array, int n) {
	uint[] shifted = array.dup;
	if (n > 0) {
		shifted = new uint[n] ~ shifted;
	}
	return shifted;
}
// shifts by whole digits (not bits)
private uint[] padRight(uint[] array, int n) {
	return new uint[n] ~ array;
}

/*unittest {
	writeln("digitShift...");
	uint[] input, output;
	input = [ 1, 2, 3 ];
	output = digitShift(input, 0);
	input = [ 1, 2, 3 ];
	output = digitShift(input, 2);
	output = digitShift(input, -2);
	writeln("test missing");
}*/

private uint[] bitShift(uint[] array, int n) {
	return array;
}

private uint[] shift(uint[] array, int n) {
	bool sign = false;
	if (n < 0) {
		n = -n;
		sign = true;
	}
	int digits = n / uint.sizeof;
	int bits = n % uint.sizeof;
	if (sign) {
		digits = -digits;
		bits = -bits;
	}
	scale(array, digits);
	bitShift(array, bits);
	return array;
}

//--------------------------------
// array operations
//--------------------------------

	/// Returns the number of digits in the array.
	/// Trailing zero digits are not counted.
	/// If all digits are zero, returns length = 0.
	private int numDigits(const uint[] digits) {
		int count;
		for (count = digits.length; count > 0; count--) {
			if (digits[count-1]) break;
		}
		return count;
	}

/*	unittest {
		uint[] array;
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
	/// Returns -1, 0, or 1 if the first argument is, respectively,
	/// smaller than, equal to or larger than the second.
	private int compare(const uint[] a, const uint[] b) {

		// if lengths differ...
//writefln("unsigned(a) = %s", unsigned(a));
		uint na = numDigits(a);
//writefln("na = %s", na);
		uint nb = numDigits(b);
//writefln("unsigned(b) = %s", unsigned(b));
		if (na < nb) return -1;
//writefln("nb = %s", nb);
		if (na > nb) return +1;

		// same length; return the first difference
		for (int i = nb-1; i >= 0; i--) {
			if (a[i] < b[i]) return -1;
			if (a[i] > b[i]) return +1;
		}
		// no differences; return 0
		return 0;
	}

	/// Compares two arrays of digits.
	/// Returns -1, 0, or 1 if the second argument is, respectively,
	/// smaller than, equal to or larger than the first.
	private int compare(const uint[] a, const uint k) {
		uint[] b = [ k ];
		return compare(a,b);
	}

/*	unittest {
		writeln("compare...");
		uint[] a, b;
		a = [4, 3, 2, 0 ];
		b = [4, 3, 2];
		int c = compare(a, b);
		writeln("test missing");
	}*/

//--------------------------------
// addition and subtraction
//--------------------------------

	/// Returns the sum of the two arrays.
	private uint[] addDigits(const uint[] x, const uint[] y) {
		uint nx = numDigits(x);
		uint ny = numDigits(y);
		if (nx >= ny) return addDigits(x, nx, y, ny);
		else return addDigits(y, ny, x, nx);
	}

	/// Returns the sum of the two arrays with lengths specified.
	/// Precondition: nx >= ny
	private uint[] addDigits(
			const uint[] x, const uint nx, const uint[] y, const uint ny) {

		assert(nx >= ny);
		uint[] sum = new uint[nx + 1];
		uint carry = 0;
		ulong temp = 0;
		uint i = 0;
		while (i < ny) {
			temp = cast(ulong)x[i] + cast(ulong)y[i] + carry;
			sum[i] = low(temp);
			carry = high(temp);
			i++;
		}
		while (carry && i < nx) {
			temp = cast(ulong)x[i] + carry;
			sum[i] = low(temp);
			carry = high(temp);
			i++;
		}
		while (i < nx) {
			sum[i] = x[i];
			i++;
		}
		if (carry == 1) {
			sum[i] = carry;
		}
		return sum;
	}

	/// Returns the sum of the array and a single uint.
	private static uint[] addDigits(const uint[] x, const uint y) {
		return addDigits(x, numDigits(x), y);
	}

	/// Returns the sum of the array and a single uint.
	private static uint[] addDigits(const uint[] x, uint nx, const uint y) {
		uint[] sum = new uint[nx + 1];
		ulong temp = x[0] + y;
		sum[0] = low(temp);
		uint carry = high(temp);
		uint i = 0;
		while (carry && i < nx) {
			temp = cast(ulong)x[i] + carry;
			sum[i] = low(temp);
			carry = high(temp);
			i++;
		}
		while (i < nx) {
			sum[i] = x[i];
			i++;
		}
		if (carry == 1) {
			sum[i] = carry;
		}
		return sum;
	}

	// Subtracts one array from another.
	// Precondition: x >= y.
	private uint[] subDigits(const uint[] x, const uint[] y) {
		uint nx = numDigits(x);
		uint ny = numDigits(y);
		return subDigits(x, nx, y, ny);
	}

	// Subtracts one array from another.
	// precondition: x >= y.
	private uint[] subDigits(
		const uint[] x, const uint nx, const uint[] y, const uint ny) {

  		uint[] diff = new uint[nx];
		uint borrow = 0;
		uint base = 0;
		uint i = 0;
		while (i < ny) {
			if (x[i] >= y[i] + borrow) {
				diff[i] = x[i] - y[i] - borrow;
				borrow = 0;
			}
			else {
				diff[i] = (base - y[i]) + x[i] - borrow;
				borrow = 1;
			}
			i++;
		}
		while (borrow && i < nx) {
			if (x[i] >= borrow) {
				diff[i] = x[i] - borrow;
				borrow = 0;
			}
			else {
				diff[i] = (base - borrow) + x[i];
				borrow = 1;
			}
			i++;
		}
		while (i < nx) {
			diff[i] = x[i];
			i++;
		}
		// if (borrow == 1) { diff is negative }
		assert(!borrow);
		return diff;
	}

//--------------------------------
// multiplication and squaring
//--------------------------------

	// Returns the product of the two arrays.
	private uint[] mulDigits(const uint[] x, const uint[] y) {
		uint n = numDigits(x);
		uint t = numDigits(y);
		uint[] w = new uint[n + t + 1];
		w[] = 0;
		for (uint i = 0; i < t; i++) {
			ulong carry = 0;
			for (uint j = 0; j < n; j++) {
				ulong inner = carry + w[i+j]
					+ cast(ulong)(x[j]) * cast(ulong)(y[i]);
				carry = high(inner);
				w[i+j] = low(inner);
			}
			w[i+n] = low(carry);
		// if (n >= N && carry > 1) { overflow }
		}
		return w;
	}

	/// Multiplies an array of digits by a single uint
	private uint[] mulDigits(const uint[] x, const uint k) {
		int m = numDigits(x);
		uint[] w = new uint[m+1];
		ulong carry = 0;
		for (int i = 0; i < m; i++) {
			ulong temp = cast(long)k * x[i] + carry;
			w[i] = low(temp);
			carry = high(temp);
		}
		w[m] = low(carry);
		// if carry != 0 then overflow
		return w;
	}

	// Returns the square of the argument.
	public uint[] sqr(const uint[] x) {
		uint n = numDigits(x);
		uint[] sqrx = new uint[2*n];
		for (uint i = 0; i < n; i++) {
			ulong inner = sqrx[2*i]	+ cast(ulong)x[i] * cast(ulong)x[i];
			ulong carry = high(inner);
			sqrx[2*i] = low(inner);
			for (uint j = i+1; j < n; j++) {
				inner = carry + sqrx[i+j] + 2 * cast(ulong)x[j] * cast(ulong)x[i];
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
	private uint[] divDigits(const uint[] a, const uint[] b) {
		return divDigits(a, numDigits(a), b, numDigits(b));
	}

	/// Returns the quotient of the first array divided by the second.
	private uint[] divDigits(
		const uint[] a, const uint na, const uint[] b, const uint nb) {

		if (nb == 1) return divDigits(a, na, b[0]);
        if (nb == 0) throw new Exception("division by zero");

		uint[] x = a[0..na].dup;
		uint[] y = b[0..nb].dup;
		// normalize the operands
		uint f = divDigits([0u, 1u], y[nb-1])[0];
		if (f != 1) {
			x = mulDigits(x, f);
			y = mulDigits(y, f);
		}
		uint[] q = new uint[na-nb+1];
		uint[] ys = scale(y, na-nb);
		while (compare(x,ys) > 0) {
			q[na-nb]++;
			x = subDigits(x, ys);
		}
		for (int i = na-1; i >= nb; i--) {
			int ix = i-nb;
			if (x[i] == y[nb-1]) {
				q[ix] = uint.max;
			}
			else {
				q[ix] = divDigits(x[i-1..i+1], y[nb-1])[0];
			}
			uint[] yq = mulDigits(y[nb-2..nb], q[ix]);
			while ((compare(yq, x[i-2..i+1])) > 0) {
				q[ix]--;
				yq = subDigits(yq, y[nb-2..nb]);
			}
			uint[] yb = scale(y, i-nb);
			uint[] xs = mulDigits(yb, q[ix]);
			if (compare(x, xs) < 0) {
				q[ix]--;
				xs = subDigits(xs, yb);
			}
			x = subDigits(x, xs);
		}
		return q;
	}

	/// Divides an array of digits by a single uint
	private uint[] divDigits(const uint[] x, const uint k) {
		int m = numDigits(x);
		return divDigits(x, m, k);
	}

	/// Divides an array of digits by a single uint
	private uint[] divDigits(const uint[] x, const uint nx, const uint k) {
		int m = numDigits(x);
		uint[] q = x[0..m].dup;
		uint[] remainder;
		ulong carry = 0;
		for (int i = m-1; i >= 0; i--) {
			ulong temp = carry * unsigned.BASE + x[i];
			q[i] = low(temp / k);
			carry = temp % k;
		}
		return q;
	}

unittest {
	write("divDigits...");
	uint[] input, output;
	uint k;
	input = [28, 20, 48, 76];
	output = divDigits(input, 2);
//writefln("output = %s", output);
//writefln("unsigned(output) = %s", unsigned(output));
	input = random(4);
//writefln("input = %s", input);
writefln("unsigned(input) = %s", unsigned(input));
	k = randomDigit;
writefln("k = %X", k);
	output = divDigits(input, k);
writefln("unsigned(output) = %s", unsigned(output));
//writefln("output = %s", output);
	uint[] ka = [ k ];
	uint[] m = mulDigits(output, ka);
	uint r = modDigit(input, k);
writefln("r = %X", r);
writefln("unsigned(m) = %s", unsigned(m));
writefln("unsigned( ) = %s", unsigned(addDigits(m, r)));

	writeln("test  ----- missing");
}

	// Minefield, Algorithm 5: Remainder
	private uint modDigit(uint[] x, uint k) {
		int m = numDigits(x);
		uint[] quotient = x[0..m];
		uint[] remainder;
		ulong carry = 0;
		for (int i = m-1; i >= 0; i--) {
			ulong temp = carry * unsigned.BASE + x[i];
//			x[i] = cast(uint)temp / k;
			carry = temp % k;
		}
		return cast(uint)carry;
	}

//--------------------------------
// logical operations
//--------------------------------

	private uint[] andDigits(const uint[] a, const uint[] b) {
		uint na = numDigits(a);
		uint nb = numDigits(b);
		if (nb > na) {
		}
		else if (na > nb) {
		}
		uint[] and = new uint[nb];
		for (int i = 0; i < nb; i++) {
			and[i] = a[i] & b[i];
		}
		return and[];

	}

//--------------------------------
// random numbers
//--------------------------------

	private uint[] random(uint n) {
		uint[] rand = new uint[n];
		for (int i = 0; i <n; i++) {
			rand[i] = randomDigit;
		}
	    return rand;
	}

	private uint randomDigit() {
		return std.random.uniform(0, uint.max);
	}

unittest {
	writeln("random digits...");
	uint[] r = random(4);
writefln("unsigned(r) = %s", unsigned(r));
	uint[] s = random(4);
writefln("unsigned(s) = %s", unsigned(s));
writefln("compare(r,s) = %s", compare(r,s));
	uint[] t;
	if (compare(r,s) > 0) {
		t = subDigits(r,s);
writefln("t == r - s = %s", unsigned(t));
writefln("r ?= t - s = %s", unsigned(addDigits(t,s)));
	}
	else {
		t = addDigits(r,s);
writefln("t == r + s = %s", unsigned(t));
writefln("s ?= t - r = %s", unsigned(subDigits(t,r)));
	}
   	uint[] x = random(2);
	uint[] y = random(2);
	uint[] z = mulDigits(x,y);
writefln("unsigned(x) = %s", unsigned(x));
writefln("unsigned(y) = %s", unsigned(y));
writefln("unsigned(z) = %s", unsigned(z));

	uint[] w = divDigits(z,y);
writefln("unsigned(w) = %s", unsigned(w));
writefln("unsigned(x) = %s", unsigned(x));
//	uint[] k = random(1);
//	z = mulDigits(x,k[0..1]);
//writefln("unsigned(k) = %s", unsigned(k));
//writefln("unsigned(z) = %s", unsigned(z));

//	uint[] rt = random(1);
//writefln("unsigned(rt) = %s", unsigned(rt));
//	uint[] px = mulDigits(rt,rt);
//writefln("unsigned(px) = %s", unsigned(px));
//	rt = sqr(rt);
//writefln("unsigned(rt) = %s", unsigned(rt));
	writeln("passed");
}

unittest {
	writeln("===================");
	writeln("unsigned........end");
	writeln("===================");
}

