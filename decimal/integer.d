// Written in the D programming language

/**
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt or copy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

module decimal.integer;

import std.conv;

public struct Int {

	private static const N = 2;

//--------------------------------
// structure
//--------------------------------

	private int[N] data =  [0];

	private static const long BASE = 2L^^32;

	@property
	public Int init() {
		return ZERO;
	}

	@property
	public Int max() {
		return MAX;
	}

	@property
	public Int min() {
		return MIN;
	}

//--------------------------------
// construction
//--------------------------------

	public this(int value) {
		data[0] = value;
	}

	public this(long value) {
		data[0] = cast(int)(value % BASE) ;
	}

	unittest {	// construction
		Int num = Int(7503);
		assert(num.data[0] == 7503);
		assert(num.data[0] != 7502);
	}

//--------------------------------
// copy
//--------------------------------

	/// Copy constructor.
	public this(const Int that) {
		this.data[0] = that.data[0];
	}

	/// Returns a copy of the number.
	public const Int dup() {
		return Int(this);
	}

	/// Returns the absolute value of the number.
	public const Int abs() {
		return Int(std.math.abs(this.data[0]));
	}

	unittest {	// copy
		Int num = Int(-9305);
		assert(Int(num) == num);
		assert(num.dup == num);
		assert(num.abs == Int(9305));
//		assert(abs(num) == Int(9305));
	}

//--------------------------------
// constants
//--------------------------------

	public static Int ZERO = Int(0);
	public static Int ONE  = Int(1);
	public static Int TWO  = Int(2);
	public static Int FIVE = Int(5);
	public static Int TEN  = Int(10);
	public static Int MAX = Int(int.max);
	public static Int MIN = Int(int.min);

	unittest {	// constants
		Int num = FIVE;
		assert(num == Int(5));
	}

//--------------------------------
// conversion
//--------------------------------

	/// Returns a string representation.
	public const string toString() {
		return std.conv.to!string(data[0]);
	}

	/// Returns an integer representation.
	public const int toInt() {
		return data[0];
	}

	/// Returns a long representation.
	public const long toLong() {
		return data[0];
	}

	unittest {	// conversion
		assert(Int(-156).toString == "-156");
		assert(Int(8754).toInt == 8754);
		assert(Int(-9100).toLong == -9100L);
	}

//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0 or 1, if this number is, respectively,
	/// less than, equal to or greater than the argument.
	private const int opCmp(T:Int)(const T that) {
		if (this.data[0] < that.data[0]) return -1;
		if (this.data[0] > that.data[0]) return 1;
		return 0;
	}

	 ///Returns true if the number is equal to the argument.
	private const bool opEquals(T:Int)(const T that) {
		return this.data[0] == that.data[0];
	}

	unittest { // comparison
		assert(Int(5) < Int(6));
		assert(Int(-3) > Int(-10));
		assert(Int(195) >= Int(195));
	}

	public static Int max(const Int arg1, const Int arg2) {
		if (arg1 < arg2) return arg2;
		return arg1;
	}

	public static Int min(const Int arg1, const Int arg2) {
		if (arg1 > arg2) return arg2;
		return arg1;
	}

//--------------------------------
// assignment
//--------------------------------

	/// Assigns an Int (copies that to this).
	private void opAssign(T:Int)(const T that) {
		this.data[0] = that.data[0];
	}

	/// Assigns an Int (copies that to this).
	private void opAssign(T:int)(const T that) {
		this.data[0] = that;
	}

	private ref Int opOpAssign(string op, T:Int) (T that) {
		this = opBinary!op(that);
		return this;
	}

//--------------------------------
// unary operations
//--------------------------------

	private const Int opUnary(string op)() {
		static if (op == "+") {
			return plus!Int();
		} else static if (op == "-") {
			return minus!Int();
		} else static if (op == "++") {
			return add!Int(this, Int(1));
		} else static if (op == "--") {
			return sub!Int(this, Int(1));
		}
	}

	public const Int plus(T:Int)() {
		return Int(+this.data[0]);
	}

	public const Int minus(T:Int)() {
		return Int(-this.data[0]);
	}

	unittest {	// opUnary
		Int op1 = 4;
		import std.stdio;
		assert( +op1 == op1);
		assert( -op1 == Int(-4));
		assert( -(-op1) == Int(4));
writeln("op1 = ", op1);
op1++;
writeln("op1 = ", op1);
		assert(++op1 == Int(5));
writeln("op1 = ", op1++);
		assert(--op1 == Int(3));
	}

//--------------------------------
// binary operations
//--------------------------------

	private const T opBinary(string op, T:Int)(const T that)
	{
		static if (op == "+") {
			return add!Int(this, that);
		} else static if (op == "-") {
			return sub!Int(this, that);
		} else static if (op == "*") {
			return mul!Int(this, that);
		} else static if (op == "/") {
			return div!Int(this, that);
		} else static if (op == "%") {
			return mod!Int(this, that);
		} else static if (op == "^^") {
			return pow!Int(this, that);
		} else static if (op == "&") {
			return and!Int(this, that);
		} else static if (op == "|") {
			return or!Int(this, that);
		} else static if (op == "^") {
			return xor!Int(this, that);
		} else static if (op == "<<") {
			return shl!Int(this, that);
		} else static if (op == ">>") {
			return shr!Int(this, that);
		}
	}

	private const T opUnary(string op, T:Int)(const int n)
	{
		static if (op == "<<")
			return shl!Int(this, n);
		else static if (op == ">>")
			return shr!Int(this, n);
	}

	unittest {	// opBinary
		Int op1, op2;
		op1 = 4; op2 = 8;
		assert(op1 + op2 == Int(12));
		assert(op1 - op2 == Int(-4));
		assert(op1 * op2 == Int(32));
		op1 = 5; op2 = 2;
		assert(op1 / op2 == Int(2));
		assert(op1 % op2 == Int(1));
		assert(op1 ^^ op2 == Int(25));
		op1 = 10101; op2 = 10001;
		assert((op1 & op2) == Int(10001));
		assert((op1 | op2) == Int(10101));
		assert((op1 ^ op2) == Int(100));
		op2 = 2;
		assert(op1 << op2 == Int(40404));
		assert(op1 >> op2 == Int(2525));
	}

	public const Int add(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] + arg2.data[0]);
	}

	public const Int sub(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] - arg2.data[0]);
	}

	public const Int mul(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] * arg2.data[0]);
	}

	public const Int div(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] / arg2.data[0]);
	}

	public const Int mod(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] % arg2.data[0]);
	}

	public const Int pow(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] ^^ arg2.data[0]);
	}

	public const Int and(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] & arg2.data[0]);
	}

	public const Int or(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] | arg2.data[0]);
	}

	public const Int xor(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] ^ arg2.data[0]);
	}

	public const Int shl(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] << arg2.data[0]);
	}

	public const Int shr(T:Int)(const T arg1, const T arg2) {
		return Int(arg1.data[0] >> arg2.data[0]);
	}


}
