// Written in the D programming language

/**
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt or copy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

module decimal.integer;

import std.conv;
import std.stdio;
import std.traits;

// TODO: move this to conversion module
import std.bigint;

unittest {
	writeln("===================");
	writeln("unsigned......begin");
	writeln("===================");
}

alias Unsigned!128 uint128;
alias Unsigned!192 uint192;
alias Unsigned!256 uint256;

uint128 ten28 = uint128(10);

public enum Overflow {
	ROLLOVER,
	SATURATE,
	THROW
};

public static const ulong BASE = 1UL << 32;

public struct Unsigned(int Z) {

//--------------------------------
// structure
//--------------------------------

//	private static const uint DIGITS = B / 32;
//	private static const bool EXTRAS = B % 32;
	private static const uint N = Z/32;

	// digits are right to left:
	// lowest uint = uint[0]; highest uint = uint[N-1]
	private uint[N] digits = 1;

	@property
	public static Unsigned!Z init() {
		return ZERO;
	}

	@property
	public static Unsigned!Z max() {
		return MAX;
	}

	@property
	public static Unsigned!Z min() {
		return MIN;
	}

//--------------------------------
// construction
//--------------------------------

	public this(const ulong value) {
	 	digits[0] = high(value);
	 	digits[1] = low(value);
	}

	public this(const ulong higher, const ulong lower) {
	 	digits[0] = high(higher);
	 	digits[1] = high(lower);
	 	digits[2] = low(higher);
	 	digits[3] = low(lower);
	}

/*	public this(const ulong[] list ...) {
		uint length = list.length >= N/2 ? N/2 : list.length;
		for (int i = 0; i  < length; i++) {
			digits[2*i]   = low(list[i]);
			digits[2*i+1] = high(list[i]);
		}
	}*/

	private this(const uint[] array) {
		uint length = array.length >= N ? N : array.length;
		for (int i = 0; i < length; i++)
			digits[i] = array[i];
	}

	unittest {	// construction
		uint128 num = uint128(7503UL, 12);
		num = uint128(7503UL);
		assert(num.digits[0] == 7503);
		assert(num.digits[0] != 7502);
		num = uint128(2^^16);
		num = uint128(uint.max);
		num = uint128(cast(ulong)uint.max + 1);
		assert(num.digits[0] == 0);
		assert(num.digits[1] == 1);
		num.digits[0] = 16;
		num.digits[1] = 32;
	}

//--------------------------------
// copy
//--------------------------------

	/// Copy constructor.
	public this(const Unsigned!Z that) {
		this.digits = that.digits;
	}

	/// Returns a copy of the number.
	public const Unsigned!Z dup() {
		return Unsigned!Z(this);
	}

	unittest {	// copy
		uint128 num = uint128(9305);
		assert(uint128(num) == num);
		assert(num.dup == num);
//		assert(num.abs == uint128(9305));
//		assert(abs(num) == uint128(9305));
	}

//--------------------------------
// constants
//--------------------------------

	public const Unsigned!Z ZERO = Unsigned!Z(0);
	public static Unsigned!Z ONE  = Unsigned!Z(1);
	public static Unsigned!Z TWO  = Unsigned!Z(2);
	public static Unsigned!Z FIVE = Unsigned!Z(5);
	public static Unsigned!Z TEN  = Unsigned!Z(10);
	// TODO: value of MAX & MIN
	public const Unsigned!Z MAX = Unsigned!Z([uint.max, uint.max, uint.max, uint.max]);
	public static Unsigned!Z MIN = Unsigned!Z(0);

//--------------------------------
// classification
//--------------------------------

	public const bool isZero() {
		return numDigits(this.digits) == 0;
	}

//--------------------------------
// conversion
//--------------------------------

	/// Converts to a string.
	public const string toString() {
		char[] str;
		uint[] from = digits.dup;
		uint n = numDigits(from);
		if (n == 0) return "0";
		while (n > 0) {
			uint mod;
			char[1] ch;
			from = divmodDigit(from, n, 10, mod);
			std.string.sformat(ch, "%d", mod);
			str = ch ~ str;
			n = numDigits(from);
		}
		return str.idup;
	}

	unittest // toString
	{
		uint128 a;
		a = uint128([11UL]);
		assert(a.toString == "11");
		a = uint128(1234567890123);
		assert(a.toString == "1234567890123");
		a = uint128(0x4872EACF123346FF);
		assert(a.toString == "5220493093160306431");
	}

	/// Converts to a string.
	public const string toHexString() {
		char[] str;
		int length = numDigits(digits);
		if (length == 0) {
			return ("0x_00000000");
		}
		for (int i = 0; i < length; i++) {
			str = std.string.format("_%08X", digits[i]) ~ str;
		}
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

	/// Converts to a big integer.
	public const BigInt toBigInt() {
		BigInt big = BigInt(0);
		foreach (uint n; digits) {
			big = big * BASE + n;
		}
		return big;
	}

	unittest {	// conversion
		assert(uint128(156).toHexString == "0x_0000009C");
		assert(uint128(8754).toInt == 8754);
		assert(uint128(9100).toLong == 9100L);
	}

//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0, or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T:Unsigned!Z)(const T that) {
		return compare(this.digits, that.digits);
	}

	/// Returns -1, 0, or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T)(const T that) if (isIntegral!T) {
		return opCmp(Unsigned!Z(that));
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T:Unsigned!Z)(const T that) {
		return this.digits == that.digits;
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T)(const T that) if (isIntegral!T) {
		return opEquals(Unsigned!Z(that));
	}

	unittest { // comparison
		assert(uint128(5) < uint128(6));
		assert(uint128(5) < 6);
		assert(uint128(3) < uint128(10));
		assert(uint128(195) >= uint128(195));
		assert(uint128(195) >= 195);
	}

	public static Unsigned!Z max(const Unsigned!Z arg1, const Unsigned!Z arg2) {
		if (arg1 < arg2) return arg2;
		return arg1;
	}

	public static Unsigned!Z min(const Unsigned!Z arg1, const Unsigned!Z arg2) {
		if (arg1 > arg2) return arg2;
		return arg1;
	}

//--------------------------------
// assignment
//--------------------------------

	private const uint opIndex(const uint i) {
		return digits[i];
	}

	private void opIndexAssign(T)(const uint i, const T that) if (isIntegral!T) {
		digits[i] = that;
	}

	/// Assigns an Unsigned!Z integer (copies that to this).
	private void opAssign(T:Unsigned!Z)(const T that) {
		this.digits = that.digits;
	}

	/// Assigns an Unsigned!Z integral value
	private void opAssign(T)(const T that) if (isIntegral!T) {
		opAssign(Unsigned!Z(that));
	}

	private ref Unsigned!Z opOpAssign(string op, T:Unsigned!Z) (T that) {
		this = opBinary!op(that);
		return this;
	}

	/// Assigns an Unsigned!Z (copies that to this).
	private ref Unsigned!Z opOpAssign(T)
			(string op, const T that) if (isIntegral!T) {
		opOpAssign(Unsigned!Z(that));
	}

//--------------------------------
// unary operations
//--------------------------------

	private const Unsigned!Z opUnary(string op)() {
		static if (op == "+") {
			return plus();
		} else static if (op == "-") {
			return negate();
		} else static if (op == "++") {
			return add(this, Unsigned!Z(1));
		} else static if (op == "--") {
			return sub(this, Unsigned!Z(1));
		} else static if (op == "~") {
			return complement();
		}
	}

	public const Unsigned!Z plus() {
		return Unsigned!Z(this.digits);
	}

	public const Unsigned!Z complement()() {
		Unsigned!Z w;
		for (int i = 0; i < N; i++)
			w.digits[i] = ~digits[i];
		return w;
	}

	public const Unsigned!Z negate()() {
		Unsigned!Z w = this.complement;
		return ++w;
	}

	unittest {	// opUnary
		uint128 op1 = 4;
		import std.stdio;
//		assert(+op1 == op1);
//		assert( -op1 == uint128(-4));
//		assert( -(-op1) == uint128(4));
		assert(++op1 == uint128(5));
//		assert(--op1 == uint128(3));
		op1 = uint128(0x000011111100UL);
//		assert(~op1 == 0xFFFFFFFFEEEEEEFFUL);
//		assert(op1.negate == 0xFFFFFFFFEEEEEF00UL);

	}

//--------------------------------
// binary operations
//--------------------------------

	private const Unsigned!Z opBinary(string op, T:Unsigned!Z)(const T that)
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

	private const Unsigned!Z opBinary(string op, T)(const T that) if (isIntegral!T) {
		return opBinary!(op, Unsigned!Z)(Unsigned!Z(that));
	}

/*	unittest {	// opBinary
		uint128 op1, op2;
		op1 = 4; op2 = 8;
		assert(op1 + op2 == 12);
		op1 = 4; int iop = 8;
		assert(op1 + iop == 12);
		assert(op2 - op1 == uint128(4));
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
		op1 = 4; op2 = uint128([0,1]);
		assert(op1 + op2 == 0x100000004);

	}*/

	public const Unsigned!Z add(const Unsigned!Z x, const Unsigned!Z y) {
        return Unsigned!Z(addDigits(x.digits, y.digits));
	}

	public const Unsigned!Z sub(const Unsigned!Z x, const Unsigned!Z y) {
		return Unsigned!Z(subDigits(x.digits, y.digits));
	}

	public const Unsigned!Z mul(const Unsigned!Z x, const Unsigned!Z y) {
		// special cases
		if (x == ZERO || y == ZERO) return ZERO;
		if (y == ONE) return x;
		if (x == ONE) return y;

		uint[] w = mulDigits(x.digits, y.digits);
		return Unsigned!Z(w[0..N-1]);
	}

	public const Unsigned!Z div(const Unsigned!Z x, const Unsigned!Z y) {
		return Unsigned!Z(divDigits(x.digits, y.digits));
	}

	public const Unsigned!Z mod(const Unsigned!Z x, const Unsigned!Z y) {
		return Unsigned!Z(modDigits(x.digits, y.digits));
	}

	public const Unsigned!Z pow(const Unsigned!Z x, const Unsigned!Z y) {
		return Unsigned!Z(powDigits(x.digits, y.toInt));
	}

	public const Unsigned!Z pow(const Unsigned!Z x, const uint n) {
		return Unsigned!Z(powDigits(x.digits, n));
	}

	public const Unsigned!Z and(const Unsigned!Z x, const Unsigned!Z y) {
		Unsigned!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] & y[i]);
		return result;
	}

	public const Unsigned!Z or(const Unsigned!Z x, const Unsigned!Z y) {
		Unsigned!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] | y[i]);
		return result;
	}

	public const Unsigned!Z xor(const Unsigned!Z x, const Unsigned!Z y) {
		Unsigned!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] ^ y[i]);
		return result;
	}

	public const Unsigned!Z shl(const Unsigned!Z x, const Unsigned!Z y) {
		return shl(x, y.toInt);
	}

	public const Unsigned!Z shl(const Unsigned!Z x, const uint n) {
		int digits = n / 32;
		int bits = n % 32;
		uint [] array = x.digits.dup;
		shlDigits(array, digits);
		shlBits(array, bits);
		return Unsigned!Z(array);
	}

	public const Unsigned!Z shr(const Unsigned!Z x, const Unsigned!Z y) {
		return shr(x, y.toInt);
	}

	public const Unsigned!Z shr(const Unsigned!Z x, const uint n) {
		int digits = n / 32;
		int bits = n % 32;
		uint [] array = x.digits.dup;
		shrDigits(array, digits);
		shrBits(array, bits);
		return Unsigned!Z(array);
	}

}	// end Unsigned

//============================================================================//

/+ public struct Signed(int Z) {

//--------------------------------
// structure
//--------------------------------

//	private static const uint DIGITS = B / 32;
//	private static const bool EXTRAS = B % 32;
	private static const uint N = Z/32;

	// digits are right to left:
	// lowest uint = uint[0]; highest uint = uint[N-1]
	private uint[N] digits = 0;

	@property
	public static Signed!Z init() {
		return ZERO;
	}

	@property
	public static Signed!Z max() {
		return MAX;
	}

	@property
	public static Signed!Z min() {
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

	unittest {	// construction
		Signed!Z num = Signed!Z(7503UL);
		assert(num.digits[0] == 7503);
		assert(num.digits[0] != 7502);
		num = Signed!Z(2^^16);
		num = Signed!Z(uint.max);
		num = Signed!Z(cast(ulong)uint.max + 1);
		assert(num.digits[0] == 0);
		assert(num.digits[1] == 1);
		num.digits[0] = 16;
		num.digits[1] = 32;
	}

//--------------------------------
// copy
//--------------------------------

	/// Copy constructor.
	public this(const Signed!Z that) {
		this.digits = that.digits;
	}

	/// Returns a copy of the number.
	public const Signed!Z dup() {
		return Signed!Z(this);
	}

	unittest {	// copy
		Signed!Z num = Signed!Z(9305);
		assert(Signed!Z(num) == num);
		assert(num.dup == num);
//		assert(num.abs == Signed!Z(9305));
//		assert(abs(num) == Signed!Z(9305));
	}

//--------------------------------
// constants
//--------------------------------

	public const Signed!Z ZERO = Signed!Z(0);
	public static Signed!Z ONE  = Signed!Z(1);
	public static Signed!Z TWO  = Signed!Z(2);
	public static Signed!Z FIVE = Signed!Z(5);
	public static Signed!Z TEN  = Signed!Z(10);
	// TODO: value of MAX & MIN
	public const Signed!Z MAX = Signed!Z([uint.max, uint.max, uint.max, uint.max]);
	public static Signed!Z MIN = Signed!Z(0);

//--------------------------------
// classification
//--------------------------------

	public const bool isZero() {
		return numDigits(this.digits) == 0;
	}

//--------------------------------
// conversion
//--------------------------------

	/// Converts to a string.
	public const string toString() {
		char[] str;
		uint[] from = digits.dup;
		uint n = numDigits(from);
		if (n == 0) return "0";
		while (n > 0) {
			uint mod;
			char[1] ch;
			from = divmodDigit(from, n, 10, mod);
			std.string.sformat(ch, "%d", mod);
			str = ch ~ str;
			n = numDigits(from);
		}
		return str.idup;
	}

	unittest // toString
	{
		Signed!Z a;
		a = Signed!Z([11]);
		assert(a.toString == "11");
		a = Signed!Z(1234567890123);
		assert(a.toString == "1234567890123");
		a = Signed!Z(0x4872EACF123346FF);
		assert(a.toString == "5220493093160306431");
	}

	/// Converts to a string.
	public const string toHexString() {
		char[] str;
		int length = numDigits(digits);
		if (length == 0) {
			return ("0x_00000000");
		}
		for (int i = 0; i < length; i++) {
			str = std.string.format("_%08X", digits[i]) ~ str;
		}
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
		assert(Signed!Z(156).toHexString == "0x_0000009C");
		assert(Signed!Z(8754).toInt == 8754);
		assert(Signed!Z(9100).toLong == 9100L);
	}

//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0, or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T:Signed!Z)(const T that) {
		return compare(this.digits, that.digits);
	}

	/// Returns -1, 0, or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T)(const T that) if (isIntegral!T) {
		return opCmp(Signed!Z(that));
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T:Signed!Z)(const T that) {
		return this.digits == that.digits;
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T)(const T that) if (isIntegral!T) {
		return opEquals(Signed!Z(that));
	}

	unittest { // comparison
		assert(Signed!Z(5) < Signed!Z(6));
		assert(Signed!Z(5) < 6);
		assert(Signed!Z(3) < Signed!Z(10));
		assert(Signed!Z(195) >= Signed!Z(195));
		assert(Signed!Z(195) >= 195);
	}

	public static Signed!Z max(const Signed!Z arg1, const Signed!Z arg2) {
		if (arg1 < arg2) return arg2;
		return arg1;
	}

	public static Signed!Z min(const Signed!Z arg1, const Signed!Z arg2) {
		if (arg1 > arg2) return arg2;
		return arg1;
	}

//--------------------------------
// assignment
//--------------------------------

	private const uint opIndex(const uint i) {
		return digits[i];
	}

	private void opIndexAssign(T)(const uint i, const T that) if (isIntegral!T) {
		digits[i] = that;
	}

	/// Assigns an Signed!Z integer (copies that to this).
	private void opAssign(T:Signed!Z)(const T that) {
		this.digits = that.digits;
	}

	/// Assigns an Signed!Z integral value
	private void opAssign(T)(const T that) if (isIntegral!T) {
		opAssign(Signed!Z(that));
	}

	private ref Signed!Z opOpAssign(string op, T:Signed!Z) (T that) {
		this = opBinary!op(that);
		return this;
	}

	/// Assigns an Signed!Z (copies that to this).
	private ref Signed!Z opOpAssign(T)
			(string op, const T that) if (isIntegral!T) {
		opOpAssign(Signed!Z(that));
	}

//--------------------------------
// unary operations
//--------------------------------

	private const Signed!Z opUnary(string op)() {
		static if (op == "+") {
			return plus();
		} else static if (op == "-") {
			return negate();
		} else static if (op == "++") {
			return add(this, Signed!Z(1));
		} else static if (op == "--") {
			return sub(this, Signed!Z(1));
		} else static if (op == "~") {
			return complement();
		}
	}

	public const Signed!Z plus() {
		return Signed!Z(this.digits);
	}

	public const Signed!Z complement()() {
		Signed!Z w;
		for (int i = 0; i < N; i++)
			w.digits[i] = ~digits[i];
		return w;
	}

	public const Signed!Z negate()() {
		Signed!Z w = this.complement;
		return ++w;
	}

	unittest {	// opUnary
		Signed!Z op1 = 4;
		import std.stdio;
//		assert(+op1 == op1);
//		assert( -op1 == Signed!Z(-4));
//		assert( -(-op1) == Signed!Z(4));
		assert(++op1 == Signed!Z(5));
//		assert(--op1 == Signed!Z(3));
		op1 = Signed!Z(0x000011111100UL);
//		assert(~op1 == 0xFFFFFFFFEEEEEEFFUL);
//		assert(op1.negate == 0xFFFFFFFFEEEEEF00UL);

	}

//--------------------------------
// binary operations
//--------------------------------

	private const Signed!Z opBinary(string op, T:Signed!Z)(const T that)
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

	private const Signed!Z opBinary(string op, T)(const T that) if (isIntegral!T) {
		return opBinary!(op, Signed!Z)(Signed!Z(that));
	}

/*	unittest {	// opBinary
		Signed!Z op1, op2;
		op1 = 4; op2 = 8;
		assert(op1 + op2 == 12);
		op1 = 4; int iop = 8;
		assert(op1 + iop == 12);
		assert(op2 - op1 == Signed!Z(4));
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
		op1 = 4; op2 = Signed!Z([0,1]);
		assert(op1 + op2 == 0x100000004);

	}*/

	public const Signed!Z add(const Signed!Z x, const Signed!Z y) {
        return Signed!Z(addDigits(x.digits, y.digits));
	}

	public const Signed!Z sub(const Signed!Z x, const Signed!Z y) {
		return Signed!Z(subDigits(x.digits, y.digits));
	}

	public const Signed!Z mul(const Signed!Z x, const Signed!Z y) {
		// special cases
		if (x == ZERO || y == ZERO) return ZERO;
		if (y == ONE) return x;
		if (x == ONE) return y;

		uint[] w = mulDigits(x.digits, y.digits);
		return Signed!Z(w[0..N-1]);
	}

	public const Signed!Z div(const Signed!Z x, const Signed!Z y) {
		return Signed!Z(divDigits(x.digits, y.digits));
	}

	public const Signed!Z mod(const Signed!Z x, const Signed!Z y) {
		return Signed!Z(modDigits(x.digits, y.digits));
	}

	public const Signed!Z pow(const Signed!Z x, const Signed!Z y) {
		return Signed!Z(powDigits(x.digits, y.toInt));
	}

	public const Signed!Z pow(const Signed!Z x, const uint n) {
		return Signed!Z(powDigits(x.digits, n));
	}

	public const Signed!Z and(const Signed!Z x, const Signed!Z y) {
		Signed!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] & y[i]);
		return result;
	}

	public const Signed!Z or(const Signed!Z x, const Signed!Z y) {
		Signed!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] | y[i]);
		return result;
	}

	public const Signed!Z xor(const Signed!Z x, const Signed!Z y) {
		Signed!Z result;
		for (int i = 0; i < N; i++)
			result[i] = (x[i] ^ y[i]);
		return result;
	}

	public const Signed!Z shl(const Signed!Z x, const Signed!Z y) {
		return shl(x, y.toInt);
	}

	public const Signed!Z shl(const Signed!Z x, const uint n) {
		int digits = n / 32;
		int bits = n % 32;
		uint [] array = x.digits.dup;
		shlDigits(array, digits);
		shlBits(array, bits);
		return Signed!Z(array);
	}

	public const Signed!Z shr(const Signed!Z x, const Signed!Z y) {
		return shr(x, y.toInt);
	}

	public const Signed!Z shr(const Signed!Z x, const uint n) {
		int digits = n / 32;
		int bits = n % 32;
		uint [] array = x.digits.dup;
		shrDigits(array, digits);
		shrBits(array, bits);
		return Signed!Z(array);
	}

}	// end Signed
+/
//--------------------------------
// digit pack/unpack methods
//--------------------------------

private uint low(const ulong packed)
    { return packed & 0xFFFFFFFFUL; }

private uint high(const ulong packed)
    { return (packed & 0xFFFFFFFF00000000UL) >> 32; }

private ulong pack(uint hi, uint lo) {
	ulong packed = (cast(ulong) hi) << 32;
	packed |= lo;
	return packed;
}

//--------------------------------
// Unsigned!Z operations
//--------------------------------

	/// Returns the absolute value of the number.
	/// No effect on Unsigned!Z numbers -- just copies.
	public Unsigned!Z abs(Z)(const Unsigned!Z arg) {
		return arg.dup;
	}

//================================
// array operations
//================================

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

	unittest {
		uint[] array;
		array = [ 1, 2, 3, 5 ];
		assert(numDigits(array) == 4);
		array = [ 1, 2, 3, 0 ];
		assert(numDigits(array) == 3);
		array = [ 1, 0, 0, 0, 0 ];
		assert(numDigits(array) == 1);
		array = [ 0, 0, 0, 0, 0 ];
		assert(numDigits(array) == 0);
	}

	// shifts by whole digits (not bits)
	private uint[] shlDigits(const uint[] array, int n) {
		uint[] shifted = array.dup;
		if (n > 0) {
			shifted = new uint[n] ~ shifted;
		}
		return shifted;
	}

	// shifts by bits
	private uint[] shlBits(const uint[] x, int n) {
		uint nx = numDigits(x);
		uint[] shifted = new uint[nx + 1];
		uint shout, shin;
		for (uint i = 0; i < nx; i++) {
			ulong temp = x[i];
			temp <<= n;
			shout = high(temp);
			shifted[i] = low(temp) | shin;
			shin = shout;
		}
		shifted[nx] = shin;
		return shifted;
	}

	// shifts by bits
	private uint[] shrBits(const uint[] x, int n) {
		uint nx = numDigits(x);
		uint[] shifted = new uint[nx];
		uint shout, shin;
		for (uint i = 0; i < nx; i++) {
			ulong temp = x[i];
			temp >>= n;
			shout = high(temp);
			shifted[i] = low(temp) | shin;
			shin = shout;
		}
		return shifted;
	}

	// shifts by whole digits (not bits)
	private uint[] shrDigits(const uint[] x, int n) {
		if (n >= x.length) {
			return [0];
		}
		if (n > 0) {
			return x[n..$].dup;
		}
		return x.dup;
	}

	unittest {
		uint[] array, shifted;
		array = [ 1, 2, 3, 5 ];
		shifted = shlDigits(array, 1);
		assert(shifted == [0, 1, 2, 3, 5]);
		assert(compare(array, shifted) < 0);
		shifted = shrDigits(shifted, 1);
		assert(compare(array, shifted) == 0);
		shifted = shlBits(array, 1);
		assert(shifted == [2, 4, 6, 10, 0]);
		shifted = shrBits(shifted, 1);
		assert(shifted == array);
		array = [ 1, 2, 3, 0 ];
		shifted = shrDigits(array, 1);
		assert(shifted == [2, 3, 0]);
		assert(compare(array, shifted) > 0);
		array = random(4);
		shifted = shlBits(array, 4);
		assert(compare(shifted, mulDigit(array, 16)) == 0);
	}

	private bool isZero(const uint[] a) {
		return numDigits(a) == 0;
	}

	private bool isOdd(const uint[] a) {
		return a[0] & 1;
	}

	private bool isEven(const uint[] a) {
		return !isOdd(a);
	}

unittest {
	uint[] a = [7];
	assert(isOdd(a));
	a = [7, 3, 0];
	assert(isOdd(a));
	a = [0, 0, 0];
	assert(isEven(a));
	a = [0, 0, 15];
	assert(isEven(a));
	a = [64, 0, 15];
	assert(isEven(a));
	a = [64, 0, 0];
	assert(isEven(a));
	a = [63, 0, 0];
	assert(isOdd(a));
}


//--------------------------------
// comparison
//--------------------------------

	/// Compares two arrays of digits.
	/// Returns -1, 0, or 1 if the first argument is, respectively,
	/// smaller than, equal to or larger than the second.
	private int compare(const uint[] a, const uint[] b) {
		return compare(a, numDigits(a), b, numDigits(b));
	}

	/// Compares two arrays of digits.
	/// Returns -1, 0, or 1 if the first argument is, respectively,
	/// smaller than, equal to or larger than the second.
	private int compare(const uint[] a, uint na, const uint[] b, uint nb) {

		// if lengths differ just compare lengths
		if (na < nb) return -1;
		if (na > nb) return +1;

		// same length; return the first difference
		for (int i = nb-1; i >= 0; i--) {
			if (a[i] < b[i]) return -1;
			if (a[i] > b[i]) return +1;
		}
		// no differences; return 0
		return 0;
	}

	/// Compares an array of digits to a single digit.
	/// Returns -1, 0, or 1 if the second argument is, respectively,
	/// smaller than, equal to or larger than the first.
	private int compare(const uint[] a, const uint k) {
		if (numDigits(a) > 1) return +1;
		if (a[0] < k) return -1;
		if (a[0] > k) return +1;
		return 0;
	}

	unittest {
		uint[] a, b;
		int c;
		a = [5];
		b = [6];
		assert(compare(a, b) < 0);
		a = [4, 3, 2, 0 ];
		b = [4, 3, 2];
		assert(compare(a, b) == 0);
		b = [4, 3, 2, 1];
		assert(compare(a, b) < 0);
		a = [5, 3, 2, 1 ];
		assert(compare(a, b) > 0);
	}

//--------------------------------
// addition and subtraction
//--------------------------------

	/// Returns the sum of the two arrays.
	private uint[] addDigits(const uint[] x, const uint[] y) {
		uint nx = numDigits(x);
		if (nx == 0) return y.dup;
		uint ny = numDigits(y);
		if (ny == 0) return x.dup;
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

	/// Returns the sum of the array and a single digit.
	private static uint[] addDigit(const uint[] x, const uint y) {
		return addDigit(x, numDigits(x), y);
	}

	/// Returns the sum of the array and a single digit.
	private static uint[] addDigit(const uint[] x, uint nx, const uint y) {
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
// multiplication, squaring, exponentiation
//--------------------------------

	// Returns the product of the two arrays.
	private uint[] mulDigits(const uint[] x, const uint[] y) {
		uint nx = numDigits(x);
		uint ny = numDigits(y);
		return mulDigits(x, nx, y, ny);
	}

	// Returns the product of the two arrays.
	private uint[] mulDigits(const uint[] x, uint nx, const uint[] y, uint ny) {
		uint[] p = new uint[nx + ny + 1];
		p[] = 0;
		for (uint i = 0; i < ny; i++) {
			ulong carry = 0;
			for (uint j = 0; j < nx; j++) {
				ulong temp = carry + p[i+j]
					+ cast(ulong)(x[j]) * cast(ulong)(y[i]);
				carry = high(temp);
				p[i+j] = low(temp);
			}
			p[i+nx] = low(carry);
		// if (nx >= N && carry > 1) { overflow }
		}
		return p;
	}

	/// Multiplies an array of digits by a single digit
	private uint[] mulDigit(const uint[] x, const uint k) {
		int nx = numDigits(x);
		return mulDigit(x, nx, k);
	}

	/// Multiplies an array of digits by a single digit
	private uint[] mulDigit(const uint[] x, uint nx, const uint k) {
		uint[] p = new uint[nx+1];
		ulong carry = 0;
		for (int i = 0; i < nx; i++) {
			ulong temp = cast(long)k * x[i] + carry;
			p[i] = low(temp);
			carry = high(temp);
		}
		p[nx] = low(carry);
		assert(high(carry) == 0);// if carry != 0 then overflow
		return p;
	}

	private ulong longMul(const uint x, const uint y) {
		return cast(ulong)x * cast(ulong)y;
	}

	// Returns the number of significant digits in the input array.
	/// Copies the significant digits in the input array to the output array.
	private uint copyDigits(const uint[] x, out uint[] y) {
		uint nx = numDigits(x);
		y = x[0..nx].dup;
		return nx;
	}

	// Returns the square of the argument.
	public uint[] sqrDigits(const uint[] x) {
		uint nx = numDigits(x);
		uint[] sqrx = new uint[2*nx];
		ulong overflow = 0;
		for (uint i = 0; i < nx; i++) {
			ulong inner = sqrx[2*i]	+ longMul(x[i], x[i]) + overflow;
			ulong carry = high(inner);
			sqrx[2*i] = low(inner);
			for (uint j = i+1; j < nx; j++) {
				ulong temp = longMul(x[j], x[i]);
				overflow = temp & 0x8000_0000_0000_0000 ? 0x010000_0000 : 0;
				inner = carry + sqrx[i+j] + (temp << 1);
				carry = high(inner);
				sqrx[i+j] = low(inner);
			}
			sqrx[i+nx] = low(carry);
		assert(high(carry) == 0);// if (carry >1) { overflow }
		}
		return sqrx;
	}

	unittest {
		uint[] d = [0xF4DEF769, 0x941F2754];
		d = sqrDigits(d);
		string expect = "0x_55B40944_C7C01ADE_DF5C24BA_3137C911";
		assert(Unsigned!128(d).toHexString() == expect);
	}

	// returns the argument raised to the specified power.
	public uint[] powDigits(const uint[] base, uint expo) {
		if (expo == 0) return [1];
		if (expo == 1) return base.dup;
		if (expo == 2) return sqrDigits(base);
		uint[] a = [1];
		uint[] s = base.dup;
		while (expo > 0) {
			if (expo & 1) a = mulDigits(a, s);
			expo /= 2;
			if (expo > 0) s = sqrDigits(s);
		}
		return a;
	}

	// greatest common denominator
	public uint[] gcdDigits(const uint[] xin, const uint[] yin) {
		uint[] x, y;
		uint nx = copyDigits(xin, x);
		uint ny = copyDigits(yin, y);
		if (nx == 0 && ny == 0) return [1];
		if (nx == 0) return y;
		if (ny == 0) return x;
		if (compare(x, nx, y, ny) == 0) return x;
		uint[] g = [1];

		while (isEven(x) && isEven(y)) {
			x = shrBits(x, 1);
			y = shrBits(y, 1);
			g = shlBits(g, 1);
		}
		while (!isZero(x)) {
			while (isEven(x)) {
				x = shrBits(x, 1);
			}
			while (isEven(y)) {
				y = shrBits(y, 1);
			}
			if (compare(x,y) >= 0) {
				uint [] t = subDigits(x,y);
				x = shrBits(t, 1);
			}
			else {
				uint[] t = subDigits(y,x);
				y = shrBits(t, 1);
			}
		}
		return mulDigits(g, y);
	}

	// greatest common denominator
	public uint[] xgcdDigits(const uint[] xin, const uint[] yin) {
		uint[] x, y;
		uint nx = copyDigits(xin, x);
		uint ny = copyDigits(yin, y);
		if (nx == 0 && ny == 0) return [1];
		if (nx == 0) return y;
		if (ny == 0) return x;
		if (compare(x, nx, y, ny) == 0) return x;
		uint[] g = [1];
		uint[] u, v, A, B, C, D;
		while (isEven(x) && isEven(y)) {
			x = shrBits(x, 1);
			y = shrBits(y, 1);
			g = shlBits(g, 1);
		}
		u = x;
		v = y;
		A = [1];
		B = [0];
		C = [0];
		D = [1];
		while (!isZero(x)) {
			while (isEven(u)) {
				u = shrBits(u, 1);
				if (A == B && isEven(A)) {
					A = shrBits(A,1);
					B = shrBits(B,1);
				}
				else {
					A = shrBits(addDigits(A, y),1);
					// NOTE: Won't this throw?
					B = shrBits(subDigits(B, x),1);
				}
			}
			while (isEven(v)) {
				v = shrBits(v, 1);
				if (C == D && isEven(C)) {
					C = shrBits(C,1);
					D = shrBits(D,1);
				}
				else {
					C = shrBits(addDigits(C, y),1);
					// NOTE: Won't this throw?
					D = shrBits(subDigits(D, x),1);
				}
			}
			if (compare(u,v) >= 0) {
				u = subDigits(u,v);
				A = subDigits(A,C);
				B = subDigits(B,D);
			}
			else {
				v = subDigits(v,u);
				C = subDigits(C,A);
				D = subDigits(D,B);
			}
		}

		return mulDigits(g, v);
	}

	unittest {
		uint[] b = [0xC2BA7913U]; //random(1);
		uint e = 4;
		uint[] p = powDigits(b, e);
		uint[] t = [1];
		for (int i = 0; i < e; i++) {
			t = mulDigits(t, b);
		}
		assert(compare(p,t) == 0);

		uint[] x, y, g;
		x = [174]; //random(1);;
		y = [36]; //random(1);
		g = gcdDigits(x,y);
		assert(compare(g, [6]) == 0);
//		g = xgcdDigits(x,y);
//writefln("g = %s", g);

	}

	unittest {
		for (int j = 0; j < 10; j++) {
			uint[] b = random(1);
			uint e = 7;
			uint[] p = powDigits(b, e);
			uint[] t = [1];
			for (int i = 0; i < e; i++) {
				t = mulDigits(t, b);
			}
		assert(compare(p,t) == 0);
		}
	}

//--------------------------------
// division and modulus
//--------------------------------

	/// Returns the quotient of the first array divided by the second.
	private uint[] divmodDigits(const uint[] xin, const uint[] yin, out uint[] mod) {
		// mutable copies
		uint[] x, y;
		uint nx = copyDigits(xin, x);
		uint ny = copyDigits(yin, y);
        if (ny == 0) throw new Exception("division by zero");
		// special cases
		if (nx == 0)  {
			mod = [0];
			return [0];
		}
		if (ny == 1) {
			return divmodDigit(x, nx, y[0], mod[0]);
		}
		return divmodDigits(x, numDigits(x), y, numDigits(y), mod);
	}

	/// Returns the quotient of the first array divided by the second.
	/// Preconditions: y != 0
	private uint[] divmodDigits(
			ref uint[] x, uint nx, ref uint[] y, uint ny, out uint[] mod) {

		// normalize the operands
		uint f = divDigit([0u, 1u], y[ny-1])[0];
		if (f != 1) {
			x = mulDigit(x, nx, f);
			nx = numDigits(x);
			y = mulDigit(y, ny, f);
			ny = numDigits(y);
		}

		uint[] q = new uint[nx-ny+1];
		uint[] ys = shlDigits(y, nx-ny);
		while (compare(x,ys) > 0) {
			q[nx-ny]++;
			x = subDigits(x, ys);
		}
		for (uint i = nx-1; i >= ny; i--) {
			uint ix = i-ny;
			if (x[i] == y[ny-1]) {
				q[ix] = uint.max;
			}
			else {
				q[ix] = divDigit(x[i-1..i+1], 2U, y[ny-1])[0];
			}
			uint[] yq = mulDigit(y[ny-2..ny], 2U, q[ix]);
			while ((compare(yq, x[i-2..i+1])) > 0) {
				q[ix]--;
				yq = subDigits(yq, y[ny-2..ny]);
			}
			uint[] yb = shlDigits(y, i-ny);
			uint[] xs = mulDigit(yb, i, q[ix]);
			if (compare(x, xs) < 0) {
				q[ix]--;
				xs = subDigits(xs, yb);
			}
			x = subDigits(x, xs);
		}
		mod = f == 1 ? x : divDigit(x, f);
		return q;
	}

	/// Divides an array of digits by a single digit
	private uint[] divmodDigit(const uint[] x, uint n, uint k, out uint mod) {
		if (n == 0) {
			mod = 0;
			return [0];
		}
		if (k == 1) {
			mod = 0;
			return x.dup;
		}
		if (k == 0) throw new Exception("division by zero");
		uint[] q = x.dup;
		ulong carry = 0;
		for (int i = n-1; i >= 0; i--) {
			ulong temp = carry * BASE + x[i];
			q[i] = low(temp / k);
			carry = temp % k;
		}
		mod = cast(uint)carry;
		return q;
	}

	/// Returns the quotient of the first array divided by the second.
	private uint[] divDigits(const uint[] xin, const uint[] yin) {
		// mutable copies
		uint[] x, y, mod;
		uint nx = copyDigits(xin, x);
		uint ny = copyDigits(yin, y);
		// special cases
		if (nx == 0) return [0];
        if (ny == 0) throw new Exception("division by zero");
		if (ny == 1) return divDigit(x, nx, y[0]);
		// divide arrays
		return divmodDigits(x, nx, y, ny, mod);
	}

	/// Returns the quotient of the first array divided by the second.
	private uint[] divDigits(ref uint[] x, uint nx, ref uint[] y, uint ny) {
		uint [] mod;
		return divmodDigits(x, nx, y, ny, mod);
	}

	/// Divides an array of digits by a single digit
	private uint[] divDigit(const uint[] x, uint k) {
		return divDigit(x, numDigits(x), k);
	}

	/// Divides an array of digits by a single digit
	private uint[] divDigit(const uint[] x, uint n, uint k) {
		if (n == 0) return [0];
		if (k == 1) return x.dup;
		if (k == 0) throw new Exception("division by zero");
		uint[] q = x.dup;
		ulong carry = 0;
		for (int i = n-1; i >= 0; i--) {
			ulong temp = carry * BASE + x[i];
			q[i] = low(temp / k);
			carry = temp % k;
		}
		return q;
	}

	/// Returns the quotient of the first array divided by the second.
	private uint[] modDigits(const uint[] xin, const uint[] yin) {
		// mutable copies
		uint[] x, y, mod;
		uint nx = copyDigits(xin, x);
		uint ny = copyDigits(yin, y);
		// special cases
		if (nx == 0) return [0];
        if (ny == 0) throw new Exception("division by zero");
		if (ny == 1) return [modDigit(x, nx, y[0])];
		// divide arrays
		divmodDigits(x, nx, y, ny, mod);
		return mod;
	}

	/// Returns the quotient of the first array divided by the second.
	private uint[] modDigits(ref uint[] x, uint nx, ref uint[] y, uint ny) {
		uint [] mod;
		divmodDigits(x, nx, y, ny, mod);
		return mod;
	}

	/// Divides an array of digits by a single digit and returns the remainder.
	private uint modDigit(const uint[] x, uint k) {
		return modDigit(x, numDigits(x), k);
	}

	/// Divides an array of digits by a single digit and returns the remainder.
	private uint modDigit(const uint[] x, uint n, const uint k) {
		ulong carry = 0;
		for (int i = n-1; i >= 0; i--) {
			ulong temp = carry * BASE + x[i];
			carry = temp % k;
		}
		return cast(uint)carry;
	}

unittest {
	uint[] input, output;
	uint k;
	input = [28, 20, 48, 76];
	output = divDigit(input, 2);
//writefln("output = %s", output);
//writefln("Unsigned!Z(output) = %s", Unsigned!Z(output));
	input = random(4);
//writefln("input = %s", input);
//writefln("Unsigned!Z(input) = %s", Unsigned!Z(input));
	k = randomDigit;
//writefln("k = %X", k);
	output = divDigit(input, k);
//writefln("Unsigned!Z(output) = %s", Unsigned!Z(output));
//writefln("output = %s", output);
	uint[] ka = [ k ];
	uint[] m = mulDigits(output, ka);
	uint r = modDigit(input, k);
//writefln("r = %X", r);
//writefln("Unsigned!Z(m) = %s", Unsigned!Z(m));
//writefln("Unsigned!Z( ) = %s", Unsigned!Z(addDigit(m, r)));
}

//--------------------------------
// logical operations
//--------------------------------

	/// Returns the logical and of the two arrays.
	/// precondition: a and b must have the same length
	private uint[] andDigits(const uint[] a, const uint[] b) {
		assert(a.length == b.length);
		uint[] and = new uint[a.length];
		for (int i = 0; i < a.length; i++) {
			and[i] = a[i] & b[i];
		}
		return and[];
	}

	/// Returns the logical or of the two arrays.
	/// precondition: a and b must have the same length
	private uint[] orDigits(const uint[] a, const uint[] b) {
		assert(a.length == b.length);
		uint[] or = new uint[a.length];
		for (int i = 0; i < a.length; i++) {
			or[i] = a[i] | b[i];
		}
		return or[];
	}

	/// Returns the logical xor of the two arrays.
	/// precondition: a and b must have the same length
	private uint[] xorDigits(const uint[] a, const uint[] b) {
		assert(a.length == b.length);
		uint[] xor = new uint[a.length];
		for (int i = 0; i < a.length; i++) {
			xor[i] = a[i] ^ b[i];
		}
		return xor[];
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
/*writefln*/("Unsigned!Z(r) = %s", Unsigned!128(r));
	uint[] s = random(4);
//writefln("Unsigned!Z(s) = %s", Unsigned!Z(s));
//writefln("compare(r,s) = %s", compare(r,s));
	uint[] t;
	if (compare(r,s) > 0) {
		t = subDigits(r,s);
//writefln("t == r - s = %s", Unsigned!Z(t));
//writefln("r ?= t - s = %s", Unsigned!Z(addDigits(t,s)));
	}
	else {
		t = addDigits(r,s);
//writefln("t == r + s = %s", Unsigned!Z(t));
//writefln("s ?= t - r = %s", Unsigned!Z(subDigits(t,r)));
	}
   	uint[] x = random(2);
	uint[] y = random(2);
	uint[] z = mulDigits(x,y);
//writefln("Unsigned!Z(x) = %s", Unsigned!Z(x));
//writefln("Unsigned!Z(y) = %s", Unsigned!Z(y));
//writefln("Unsigned!Z(z) = %s", Unsigned!Z(z));

	uint[] w = divDigits(z,y);
//writefln("Unsigned!Z(w) = %s", Unsigned!Z(w));
//writefln("Unsigned!Z(x) = %s", Unsigned!Z(x));
//	uint[] k = random(1);
//	z = mulDigits(x,k[0..1]);
//writefln("Unsigned!Z(k) = %s", Unsigned!Z(k));
//writefln("Unsigned!Z(z) = %s", Unsigned!Z(z));

//	uint[] rt = random(1);
//writefln("Unsigned!Z(rt) = %s", Unsigned!Z(rt));
//	uint[] px = mulDigits(rt,rt);
//writefln("Unsigned!Z(px) = %s", Unsigned!Z(px));
//	rt = sqrDigits(rt);
//writefln("Unsigned!Z(rt) = %s", Unsigned!Z(rt));
	writeln("passed");
}

unittest {
	writeln("===================");
	writeln("unsigned........end");
	writeln("===================");
}

