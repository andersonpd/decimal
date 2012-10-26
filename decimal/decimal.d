// Written in the D programming language

/**
 *	A D programming language implementation of the
 *	General Decimal Arithmetic Specification,
 *	Version 1.70, (25 March 2009).
 *	http://www.speleotrove.com/decimal/decarith.pdf)
 *
 *	Copyright Paul D. Anderson 2009 - 2012.
 *	Distributed under the Boost Software License, Version 1.0.
 *	(See accompanying file LICENSE_1_0.txt or copy at
 *	http://www.boost.org/LICENSE_1_0.txt)
**/

// (B)TODO: write some test cases for flag setting. test the add/sub/mul/div functions

// (B)TODO: to/from real or double (float) values needs definition and implementation.

module decimal.decimal;

import std.bigint;
import std.conv;
import std.array: replicate;
import std.ascii: isDigit;
import std.exception: assumeUnique;
import std.math: PI, LOG2;
import std.stdio: write, writeln;
import std.stdio: writefln;
import std.string;

import decimal.context;
import decimal.rounding;
import decimal.arithmetic;
import decimal.test;
import decimal.integer;

alias Decimal.context bigContext;
alias Decimal.pushContext pushContext;
alias Decimal.popContext popContext;

// special values for NaN, Inf, etc.
private static enum SV {NONE, INF, QNAN, SNAN};

//public static DecimalContext context =
//	DecimalContext(9, 99, Rounding.HALF_EVEN);

///
/// A struct representing an arbitrary-precision floating-point number.
///
/// The implementation follows the General Decimal Arithmetic
/// Specification, Version 1.70 (25 Mar 2009),
/// http://www.speleotrove.com/decimal.
/// This specification conforms with IEEE standard 754-2008.
///
struct Decimal {

	public static DecimalContext context =
		DecimalContext(9, 99, Rounding.HALF_EVEN);

	private static ContextStack contextStack;

	private SV sval = SV.QNAN;		// special values: default value is quiet NaN
	private bool signed = false;	// true if the value is negative, false otherwise.
	private int expo = 0;			// the exponent of the Decimal value
	private BigInt mant;			// the coefficient of the Decimal value
	package int digits; 			// the number of decimal digits in this number.
									// (unless the number is a special value)

private:

// common decimal "numbers"
	immutable Decimal NAN	  = Decimal(SV.QNAN);
	immutable Decimal SNAN	  = Decimal(SV.SNAN);
	immutable Decimal INFINITY = Decimal(SV.INF);
	immutable Decimal NEG_INF  = Decimal(SV.INF, true);
	immutable Decimal ZERO	  = Decimal(SV.NONE);
	immutable Decimal NEG_ZERO = Decimal(SV.NONE, true);

	immutable BigInt BIG_ZERO = cast(immutable)BigInt(0);
	immutable BigInt BIG_ONE  = cast(immutable)BigInt(1);
	immutable BigInt BIG_TWO  = cast(immutable)BigInt(2);

//	static Decimal DONE = Decimal(BIG_ONE);
//	static immutable Decimal TWO  = cast(immutable)Decimal(2);
//	static immutable Decimal FIVE = cast(immutable)Decimal(5);
//	static immutable Decimal TEN  = cast(immutable)Decimal(10);

unittest {
	Decimal num;
	num = NAN;
	assertTrue(num.toString == "NaN");
	num = SNAN;
	assertTrue(num.toString == "sNaN");
//	writeln("Decimal(SV.QNAN).toAbstract = ", NAN.toAbstract);
	num = NEG_ZERO;
	assertEqual("-0", num.toString);
}

public:

//--------------------------------
// construction
//--------------------------------

	///
	/// Constructs a new number given a special value and an optional sign.
	///
	public this(const SV sv, const bool sign = false) {
		this.signed = sign;
		this.sval = sv;
	}

	unittest {
		Decimal num = Decimal(SV.INF, true);
		assertTrue(num.toSciString == "-Infinity");
		assertTrue(num.toAbstract() == "[1,inf]");
	}

	/// Creates a Decimal from a boolean value.
	public this(const bool value)
	{
		this = zero;
        if (value) {
        	coefficient = 1;
        }
	}

	/// Constructs a number from a sign, a BigInt coefficient and
	/// an optional(?) integer exponent.
	/// The sign of the number is the value of the sign parameter,
	/// regardless of the sign of the coefficient.
	/// The intial precision of the number is deduced from the number of decimal
	/// digits in the coefficient.
	this(const bool sign, const BigInt coefficient, const int exponent = 0) {
		BigInt big = abs(coefficient);
		this = zero();
		this.signed = sign;
		this.mant = big;
		this.expo = exponent;
        // (B)TODO: If we specify the number of digits this can be CTFE.
        // The numDigits call is not CTFE.
		this.digits = numDigits(this.mant);
	}

	unittest {
		Decimal num;
		num = Decimal(true, BigInt(7254), 94);
		assertTrue(num.toString == "-7.254E+97");
	}

	/// Constructs a Decimal from a BigInt coefficient and an
	/// optional integer exponent. The sign of the number is the sign
	/// of the coefficient. The initial precision is determined by the number
	/// of digits in the coefficient.
	this(const BigInt coefficient, const int exponent = 0) {
		BigInt big = mutable(coefficient);
		bool sign = decimal.rounding.sgn(big) < 0;
		this(sign, big, exponent);
	};

	unittest {
		Decimal num;
		num = Decimal(BigInt(7254), 94);
		assertTrue(num.toString == "7.254E+97");
		num = Decimal(BigInt(-7254));
		assertTrue(num.toString == "-7254");
	}

	// long constructors:

	/// Constructs a number from a sign, a long integer coefficient and
	/// an integer exponent.
	this(const bool sign, const long coefficient, const int exponent) {
		this(sign, BigInt(coefficient), exponent);
	}

	/// Constructs a number from an long coefficient
	/// and an optional integer exponent.
	this(const long coefficient, const int exponent) {
		this(BigInt(coefficient), exponent);
	}

	/// Constructs a number from an long coefficient
	/// and an optional integer exponent.
	this(const long coefficient) {
		this(BigInt(coefficient), 0);
	}

	// uint128 constructors:

	/// Constructs a number from a sign, a uint128 integer coefficient and
	/// an integer exponent.
	this(const bool sign, const uint128 coefficient, const int exponent) {
		this(sign, coefficient.toBigInt(), exponent);
	}

	/// Constructs a number from an uint128 coefficient
	/// and an optional integer exponent.
	this(const uint128 coefficient, const int exponent) {
		this(coefficient.toBigInt(), exponent);
	}

	/// Constructs a number from an uint128 coefficient
	/// and an optional integer exponent.
	this(const uint128 coefficient) {
		this(coefficient.toBigInt(), 0);
	}

	// string constructors:

// (B)TODO: this(str): add tests for just over/under int.max, int.min
	// construct from string representation
	this(const string str) {
		this = decimal.conv.toNumber(str);
	};


	// floating point constructors:

	///
	/// Constructs a number from a real value.
	///
	this(const real r) {
		string str = format("%.*G", cast(int)context.precision, r);
//writefln("r = %s", r);
//writefln("str = %s", str);
		this(str);
//writefln("this = %s", this);
	}

	// copy constructor
	this(const Decimal that) {
		this.signed = that.signed;
		this.sval	= that.sval;
		this.digits = that.digits;
		this.expo	= that.expo;
		this.mant	= cast(BigInt) that.mant;
	};

	/// dup property
	const Decimal dup() {
		return Decimal(this);
	}

//--------------------------------
// assignment
//--------------------------------

	/// Assigns a Decimal (makes a copy)
	void opAssign(T:Decimal)(const T that) {
		this.signed = that.signed;
		this.sval	= that.sval;
		this.digits = that.digits;
		this.expo	= that.expo;
		this.mant	= cast(BigInt) that.mant;
	}

	///    Assigns a floating point value.
	void opAssign(T:BigInt)(const T that) {
		this = Decimal(that);
	}

	///    Assigns a floating point value.
	void opAssign(T:long)(const T that) {
		this = Decimal(that);
	}

	///    Assigns a floating point value.
	void opAssign(T:real)(const T that) {
		this = Decimal(that);
	}

	void opAssign(T)(const T that) if (isDecimal!T) {
		this = decimal.conv.toBigDecimal!T(that);
	}


//--------------------------------
// string representations
//--------------------------------

	///
	/// Converts a number to an abstract string representation.
	///
	public const string toAbstract() {
		return decimal.conv.toAbstract!Decimal(this);
	}

// READY: toSciString.
///
/// Converts a Decimal to a string representation.
///
const string toSciString() {
	return decimal.conv.sciForm!Decimal(this);
};

// READY: toEngString.
///
/// Converts a Decimal to an engineering string representation.
///
const string toEngString() {
   return decimal.conv.engForm!Decimal(this);
};

///
/// Converts a number to its string representation.
///
const string toString() {
	return decimal.conv.sciForm!Decimal(this);
};

//--------------------------------
// member properties
//--------------------------------

	/// Returns the exponent of this number
	@property
	const int exponent() {
		return this.expo;
	}

	@property
	int exponent(int expo) {
		this.expo = expo;
		return this.expo;
	}

	@property
	const BigInt coefficient() {
		return cast(BigInt)this.mant;
	}

	@property
	BigInt coefficient(BigInt mant) {
		this.mant = mant;
		return this.mant;
	}

	@property
	BigInt coefficient(long mant) {
		this.mant = BigInt(mant);
		return this.mant;
	}

	@property
	const ushort payload() {
		if (this.isNaN) {
			return cast(ushort)(this.mant.toLong);
		}
		return 0;
	}

	@property
	ushort payload(const ushort value) {
		if (this.isNaN) {
			this.mant = BigInt(value);
			return value;
		}
		return 0;
	}

	const string toExact() {
		return decimal.conv.toExact!Decimal(this);
	}


	/// Returns the adjusted exponent of this number
	@property const int adjustedExponent() {
		return expo + digits - 1;
	}

	/// Returns the number of decimal digits in the coefficient of this number
	const int getDigits() {
		return this.digits;
	}

	@property const bool sign() {
		return signed;
	}

	@property bool sign(bool value) {
		signed = value;
		return signed;
	}

//--------------------------------
// floating point properties
//--------------------------------

	/// Returns the default value for this type (NaN)
	static Decimal init() {
		return NAN.dup;
	}

	/// Returns NaN
	static Decimal nan(ushort payload = 0) {
		if (payload) {
			Decimal dec = NAN.dup;
			dec.payload = payload;
			return dec;
		}
		return NAN.dup;
	}

	/// Returns signaling NaN
	static Decimal snan(ushort payload = 0) {
		if (payload) {
			Decimal dec = SNAN.dup;
			dec.payload = payload;
			return dec;
		}
		return SNAN.dup;
	}

	/// Returns infinity.
	static Decimal infinity(bool signed = false) {
		return signed ? NEG_INF.dup : INFINITY.dup;
	}

	/// Returns zero.
	static Decimal zero(bool signed = false) {
		return signed ? NEG_ZERO.dup : ZERO.dup;
	}

	/// Returns the maximum number of decimal digits in this context.
	static uint precision(const DecimalContext context = this.context) {
		return context.precision;
	}

	/// Returns the maximum number of decimal digits in this context.
	static uint dig(const DecimalContext context = this.context) {
		return context.precision;
	}

	/// Returns the number of binary digits in this context.
	static int mant_dig(const DecimalContext context = this.context) {
		return cast(int)(context.precision/LOG2);
	}

	static int min_exp(const DecimalContext context = this.context) {
		return cast(int)(context.minExpo);
	}

	static int max_exp(const DecimalContext context = this.context) {
		return cast (int)(context.maxExpo);
	}

//	// (B)TODO: is there a way to make this const w/in a context?
//	// (B)TODO: This is only used by Decimal -- maybe should move it there?
//	// (B)TODO: The mantissa is 10^^(precision - 1), so probably don't need
//	//			to implement as a string.
//	// Returns the maximum representable normal value in the current context.
//	const string maxString() {
//		string cstr = "9." ~ replicate("9", precision - 1)
//					~ "E" ~ format("%d", maxExpo);
//		return cstr;
//	}


	// Returns the maximum representable normal value in the current context.
	// (B)TODO: this is a fairly expensive operation. Can it be fixed?
	static Decimal max(const DecimalContext context = this.context) {
		return Decimal(context.maxString);
	}

	// Returns the maximum representable normal value in the current context.
	// (B)TODO: this is a fairly expensive operation. Can it be fixed?
	// (B)TODO: is this needed?
	static Decimal max(const bool sign,
			const DecimalContext context = this.context) {
		Decimal result = Decimal(context.maxString);
		return sign ? -result : result;
	}

//	/// Returns the minimum representable normal value in this context.
//	static Decimal min_normal(const DecimalContext context = this.context) {
//		return Decimal(1, context.minExpo);
//	}

	/// Returns the minimum representable subnormal value in this context.
	static Decimal min(const DecimalContext context = this.context) {
		return Decimal(1, context.tinyExpo);
	}

	/// Returns the smallest available increment to 1.0 in this context
	static Decimal epsilon(const DecimalContext context = this.context) {
		return Decimal(1, -context.precision);
	}

	static int min_10_exp(const DecimalContext context = this.context) {
		return context.minExpo;
	}

	static int max_10_exp(const DecimalContext context = this.context) {
		return context.maxExpo;
	}

	static DecimalContext pushContext(const DecimalContext context) {
		contextStack.push(Decimal.context);
		Decimal.context = context;
		return context;
	}

	static DecimalContext pushContext() {
		return pushContext(Decimal.context);
	}

	static DecimalContext pushContext(uint precision) {
		DecimalContext context = Decimal.context;
		context.precision = precision;
		return pushContext(context);
	}

	static DecimalContext popContext() {
//writefln("Decimal.context.precision = %s", Decimal.context.precision);
		Decimal.context = contextStack.pop();
//writefln("Decimal.context.precision = %s", Decimal.context.precision);
		return Decimal.context;
	}

	/// Returns the radix (10)
	immutable int radix = 10;

//--------------------------------
//	classification properties
//--------------------------------

	/// Returns true if this number's representation is canonical (always true).
	const bool isCanonical() {
		return true;
	}

	/// Returns the canonical form of the number.
	const Decimal canonical() {
		return this.dup;
	}


	/// Returns true if this number is + or - zero.
	const bool isZero() {
		return isFinite && coefficient == 0;
	}


	/// Returns true if this number is a quiet or signaling NaN.
	const bool isNaN() {
		return this.sval == SV.QNAN || this.sval == SV.SNAN;
	}


	/// Returns true if this number is a signaling NaN.
	const bool isSignaling() {
		return this.sval == SV.SNAN;
	}


	/// Returns true if this number is a quiet NaN.
	const bool isQuiet() {
		return this.sval == SV.QNAN;
	}

	/// Returns true if this number is + or - infinity.
	const bool isInfinite() {
		return this.sval == SV.INF;
	}

	/// Returns true if this number is not an infinity or a NaN.
	const bool isFinite() {
		return sval != SV.INF
			&& sval != SV.QNAN
			&& sval != SV.SNAN;
	}


	/// Returns true if this number is a NaN or infinity.
	const bool isSpecial() {
		return sval == SV.INF
			|| sval == SV.QNAN
			|| sval == SV.SNAN;
	}

	/// Returns true if this number is negative. (Includes -0)
	const bool isSigned() {
		return this.signed;
	}

	/// Returns true if this number is negative. (Includes -0)
	const bool isNegative() {
		return this.signed;
	}

	/// Returns true if this number is subnormal.
	const bool isSubnormal(const DecimalContext context = this.context) {
		if (!isFinite) return false;
		return adjustedExponent < context.minExpo;
	}

	/// Returns true if this number is normal.
	const bool isNormal(const DecimalContext context = this.context) {
		if (isFinite && !isZero) {
			return adjustedExponent >= context.minExpo;
		}
		return false;
	}


	/// Returns true if this number is integral;
	/// that is, if its fractional part is zero.
	 const bool isIntegral() {
	 	// (B)TODO: need to take trailing zeros into account
		return expo >= 0;
	 }

	/// Returns true if this number represents a logical true value.
	/// Any number other than zero or NaN returns true.
	/// NaN is false, infinity is true.
	const bool isTrue() {
		return !isNaN || isInfinite || coefficient != 0;
	}

	/// Returns true if this number represents a logical false value.
	/// Zero and NaN return true.
	/// Any other number (e.g., infinity) returns false;
	const bool isFalse() {
		return isNaN || (isFinite && coefficient == 0);
	}


	const bool isZeroCoefficient() {
		return !isSpecial && coefficient == 0;
	}


//--------------------------------
// comparison
//--------------------------------

	/// Returns -1, 0 or 1, if this number is less than, equal to,
	/// or greater than the argument, respectively.
	const int opCmp(const Decimal that) {
		return decimal.arithmetic.compare!Decimal(this, that, context);
	}

	/// Returns true if this number is equal to the argument.
	/// Finite numbers are equal if they are numerically equal
	/// to the current precision.
	/// Infinities are equal if they have the same sign.
	/// Zeros are equal regardless of sign.
	/// A NaN is not equal to any number, not even to another NaN.
	/// A number is not even equal to itself (this != this) if it is a NaN.
	const bool opEquals (ref const Decimal that) {
		return equals!Decimal(this, that, context);
	}

//--------------------------------
// unary arithmetic operators
//--------------------------------


	/// Returns the result of performing the specified
	/// unary operation on this number.
	const Decimal opUnary(string op)()
	{
		static if (op == "+") {
			return plus!Decimal(this, context);
		}
		else static if (op == "-") {
			return minus!Decimal(this, context);
		}
		else static if (op == "++") {
			return add!Decimal(this, Decimal(1), context);
		}
		else static if (op == "--") {
			return sub!Decimal(this, Decimal(1), context);
		}
	}

//--------------------------------
//	binary arithmetic operators
//--------------------------------

	/// Returns the result of performing the specified
	/// binary operation on this number and the argument.
	const Decimal opBinary(string op, T:Decimal)(const T arg)
	{
		static if (op == "+") {
			return add!Decimal(this, arg, context);
		}
		else static if (op == "-") {
			return sub!Decimal(this, arg, context);
		}
		else static if (op == "*") {
			return mul!Decimal(this, arg, context);
		}
		else static if (op == "/") {
			return div!Decimal(this, arg, context);
		}
		else static if (op == "%") {
			return rem!Decimal(this, arg, context);
		}
		else static if (op == "&") {
			return and!Decimal(this, arg, context);
		}
		else static if (op == "|") {
			return or!Decimal(this, arg, context);
		}
		else static if (op == "^") {
			return xor!Decimal(this, arg, context);
		}
	}

	/// Returns true if the type T is promotable to a decimal type.
	private template isPromotable(T) {
		enum bool isPromotable = is(T:ulong) || is(T:real);
	}

	/// Returns the result of performing the specified
	/// binary operation on this number and the argument.
	const Decimal opBinary(string op, T)(const T arg) if (isPromotable!T)	{
		return opBinary!(op,Decimal)(Decimal(arg));
	}

//-----------------------------
// operator assignment
//-----------------------------

	/// Performs the specified binary operation on this number
	/// and the argument then assigns the result to this number.
	ref Decimal opOpAssign(string op) (Decimal arg) {
		this = opBinary!op(arg);
		return this;
	}

//-----------------------------
// nextUp, nextDown, nextAfter
//-----------------------------

	/// Returns the smallest representable number that is larger than
	/// this number.
	const Decimal nextUp() {
		return nextPlus!Decimal(this, context);
	}

	/// Returns the largest representable number that is smaller than
	/// this number.
	const Decimal nextDown() {
		return nextMinus!Decimal(this, context);
	}

	/// Returns the representable number that is closest to the
	/// this number (but not this number) in the
	/// direction toward the argument.
	const Decimal nextAfter(const Decimal arg) {
		return nextToward!Decimal(this, arg, context);
	}

	// (B)TODO: move this outside the struct
	/// Returns a BigInt value of ten raised to the specified power.
	public static BigInt pow10(int n) {
		BigInt num = 1;
		return shiftLeft(num, n, context.precision);
	}

	/// Returns a copy of the context with a new precision.
	public static DecimalContext setPrecision(const uint precision) {
		return DecimalContext(precision, context.maxExpo, context.rounding);
	}

/*	/// Returns a copy of the context with a new exponent limit.
	public static DecimalContext setMaxExponent(const int maxExpo) {
		return DecimalContext(context.precision, maxExpo, context.rounding);
	}
	/// Returns a copy of the context with a new rounding mode.
	public static DecimalContext setRounding(const Rounding rounding) {
		return DecimalContext(context.precision, context.maxExpo, rounding);
	}*/

}	 // end struct Decimal

// context
private struct ContextStack {
	private:
		DecimalContext[] stack = []; // = [ context ];
		uint capacity = 0;
		uint count = 0;

	public void push(DecimalContext context) {
		if (capacity == 0) {
			capacity = 4;
			stack.length = capacity;
		}
		count++;
		if (count >= capacity) {
			capacity *= 2;
			stack.length = capacity;
		}
		stack[count-1] = context;
	}

	public DecimalContext pop() {
		if (count == 0) {
			// throw? push();
		}
		if (count == 1) {
			return stack[0];
		}
		else {
			count--;
			return stack[count-1];
		}
	}

} // end struct ContextStack

// (B)TODO: is it possible to use stringOf to improve the test asserts?

//-----------------------------
// unittests
//-----------------------------

unittest {
	writeln("===================");
	writeln("decimal.......begin");
	writeln("===================");
}

unittest {	// ctor(string)
	Decimal num;
	string str;
	num = Decimal(1, 12334, -5);
	str = "-0.12334";
	assertTrue(num.toString == str);
	num = Decimal(-23456, 10);
	str = "-2.3456E+14";
	assertTrue(num.toString == str);
	num = Decimal(234568901234);
	str = "234568901234";
	assertTrue(num.toString == str);
	num = Decimal("123.457E+29");
	str = "1.23457E+31";
	assertTrue(num.toString == str);
	num = std.math.E;
	str = "2.71828183";
	assertEqual!string(str, num.toString);
	num = std.math.LOG2;
	Decimal copy = Decimal(num);
	assertTrue(compareTotal!Decimal(num, copy) == 0);
}

unittest {
	Decimal num = Decimal(std.math.PI);
	Decimal copy = num.dup;
	assertTrue(num == copy);
}

unittest {	// opAssign
	import decimal.dec32;

	Decimal num;
	string str;
	num = Decimal(1, 245, 8);
	str = "-2.45E+10";
	assertTrue(num.toString == str);
	num = long.max;
	str = "9223372036854775807";
	assertTrue(num.toString == str);
	num = real.max;
	str = "1.1897315E+4932";
	assertEqual!string(str, num.toString);
	num = Dec32.max;
	str = "9.999999E+96";
	assertTrue(num.toString == str);
	num = BigInt("123456098420234978023480");
	str = "123456098420234978023480";
	assertTrue(num.toString == str);
}
unittest {	// toAbstract
	Decimal num;
	string str;
	num = Decimal("-inf");
	str = "[1,inf]";
	assertTrue(num.toAbstract == str);
	num = Decimal("nan");
	str = "[0,qNaN]";
	assertTrue(num.toAbstract == str);
	num = Decimal("snan1234");
	str = "[0,sNaN1234]";
	assertTrue(num.toAbstract == str);
}

unittest {
	Decimal num;
	string str;
	num = Decimal(200000, 71);
	str = "2.00000E+76";
	assertTrue(num.toString == str);
}

unittest {
	Decimal big = -123.45E12;
	assertEqual!int(10, big.exponent);
	assertEqual!BigInt(BigInt(12345), big.coefficient);
//		assertTrue(big.coefficient == 12345);
	assertTrue(big.sign);
	big.coefficient = 23456;
	big.exponent = 12;
	big.sign = false;
	assertEqual!Decimal(Decimal(234.56E14),big);
	big = Decimal.nan;
	assertTrue(big.payload == 0);
	big = Decimal.snan(1250);
	assertTrue(big.payload == 1250);
}

unittest {
	Decimal num;
	assertTrue(num.toExact == "+NaN");
	num = +9999999E+90;
	assertEqual!string("+9999999E+90", num.toExact);
	num = 1;
	assertTrue(num.toExact == "+1E+00");
	num = Decimal.infinity(true);
	assertTrue(num.toExact == "-Infinity");
}
unittest {
	Decimal num = Decimal("2.50");
	assertTrue(num.isCanonical);
	Decimal copy = num.canonical;
	assertTrue(compareTotal(num, copy) == 0);
}

unittest {
	Decimal num;
	num = Decimal("0");
	assertTrue(num.isZero);
	num = Decimal("2.50");
	assertTrue(!num.isZero);
	num = Decimal("-0E+2");
	assertTrue(num.isZero);
}
unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isNaN);
	num = Decimal("NaN");
	assertTrue(num.isNaN);
	num = Decimal("-sNaN");
	assertTrue(num.isNaN);
}
unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isSignaling);
	num = Decimal("NaN");
	assertTrue(!num.isSignaling);
	num = Decimal("sNaN");
	assertTrue(num.isSignaling);
}
unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isQuiet);
	num = Decimal("NaN");
	assertTrue(num.isQuiet);
	num = Decimal("sNaN");
	assertTrue(!num.isQuiet);
}

unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isInfinite);
	num = Decimal("-Inf");
	assertTrue(num.isInfinite);
	num = Decimal("NaN");
	assertTrue(!num.isInfinite);
}

unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(num.isFinite);
	num = Decimal("-0.3");
	assertTrue(num.isFinite);
	num = 0;
	assertTrue(num.isFinite);
	num = Decimal("Inf");
	assertTrue(!num.isFinite);
	num = Decimal("-Inf");
	assertTrue(!num.isFinite);
	num = Decimal("NaN");
	assertTrue(!num.isFinite);
}

unittest {
	Decimal num;
	num = Decimal.infinity(true);
	assertTrue(num.isSpecial);
	num = Decimal.snan(1234);
	assertTrue(num.isSpecial);
	num = 12378.34;
	assertTrue(!num.isSpecial);
}

unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isSigned);
	num = Decimal("-12");
	assertTrue(num.isSigned);
	num = Decimal("-0");
	assertTrue(num.isSigned);
}

unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isNegative);
	num = Decimal("-12");
	assertTrue(num.isNegative);
	num = Decimal("-0");
	assertTrue(num.isNegative);
}

unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(!num.isSubnormal);
	num = Decimal("0.1E-99");
	assertTrue(num.isSubnormal);
	num = Decimal("0.00");
	assertTrue(!num.isSubnormal);
	num = Decimal("-Inf");
	assertTrue(!num.isSubnormal);
	num = Decimal("NaN");
	assertTrue(!num.isSubnormal);
}
unittest {
	Decimal num;
	num = Decimal("2.50");
	assertTrue(num.isNormal);
	num = Decimal("0.1E-99");
	assertTrue(!num.isNormal);
	num = Decimal("0.00");
	assertTrue(!num.isNormal);
	num = Decimal("-Inf");
	assertTrue(!num.isNormal);
	num = Decimal("NaN");
	assertTrue(!num.isNormal);
}

unittest {	// isIntegral
	Decimal num;
	num = 12345;
	assertTrue(num.isIntegral);
	num = BigInt("123456098420234978023480");
	assertTrue(num.isIntegral);
	num = 1.5;
	assertTrue(!num.isIntegral);
	num = 1.5E+1;
	assertTrue(num.isIntegral);
	num = 0;
	assertTrue(num.isIntegral);
}

unittest {
	write("isTrue...");
	writeln("test missing");
}

unittest {
	write("isFalse...");
	writeln("test missing");
}

unittest {	// isZeroCoefficient
	Decimal num;
	num = 0;
	assertTrue(num.isZeroCoefficient);
	num = BigInt("-0");
	assertTrue(num.isZeroCoefficient);
	num = Decimal("0E+4");
	assertTrue(num.isZeroCoefficient);
	num = 12345;
	assertFalse(num.isZeroCoefficient);
	num = 1.5;
	assertFalse(num.isZeroCoefficient);
	num = Decimal.NAN;
	assertFalse(num.isZeroCoefficient);
	num = Decimal.INFINITY;
	assertFalse(num.isZeroCoefficient);
}

unittest {	// opCmp
	Decimal num1, num2;
	num1 = 105;
	num2 = 10.543;
	assertTrue(num1 > num2);
	assertTrue(num2 < num1);
	num1 = 10.543;
	assertTrue(num1 >= num2);
	assertTrue(num2 <= num1);
}
unittest {	// opEquals
	Decimal num1, num2;
	num1 = 105;
	num2 = 10.543;
	assertTrue(num1 != num2);
	num1 = 10.543;
	assertTrue(num1 == num2);
}
unittest {	// opUnary
	Decimal num, actual, expect;
	num = 134;
	expect = num;
	actual = +num;
	assertEqual!Decimal(expect, actual);
	num = 134.02;
	expect = -134.02;
	actual = -num;
	assertEqual!Decimal(expect, actual);
	num = 134;
	expect = 135;
	actual = ++num;
	assertEqual!Decimal(expect, actual);
	num = 1.00E8;
	expect = num - 1;
	actual = --num;
	assertEqual!Decimal(expect, actual);
	num = 1.00E8;
	expect = num;
	actual = num--;
	assertEqual!Decimal(expect, actual);
	num = Decimal(9999999, 90);
	expect = num;
	actual = num++;
	assertEqual!Decimal(expect, actual);
	num = 12.35;
	expect = 11.35;
	actual = --num;
	assertEqual!Decimal(expect, actual);
}

unittest {
	Decimal num = Decimal(591.3);
	Decimal result = num * 5;
	assertTrue(result == Decimal(2956.5));
}

unittest {
	write("isPromotable...");
	writeln("test missing");
}

unittest {	// opBinary
	Decimal op1, op2, actual, expect;
	op1 = 4;
	op2 = 8;
	actual = op1 + op2;
	expect = 12;
	assertEqual!Decimal(expect, actual);
	actual = op1 - op2;
	expect = -4;
	assertEqual!Decimal(expect, actual);
	actual = op1 * op2;
	expect = 32;
	assertEqual!Decimal(expect, actual);
	op1 = 5;
	op2 = 2;
	actual = op1 / op2;
	expect = 2.5;
	assertEqual!Decimal(expect, actual);
	op1 = 10;
	op2 = 3;
	actual = op1 % op2;
	expect = 1;
	assertEqual!Decimal(expect, actual);
}

unittest {	// opOpAssign
	Decimal op1, op2, actual, expect;
	op1 = 23.56;
	op2 = -2.07;
	op1 += op2;
	expect = 21.49;
	actual = op1;
	assertEqual!Decimal(expect, actual);
	op1 *= op2;
	expect = -44.4843;
	actual = op1;
	assertEqual!Decimal(expect, actual);
}

unittest {
	Decimal big, expect;
	big = 123.45;
	assertTrue(big.nextUp == Decimal(123.450001));
	big = 123.45;
	assertTrue(big.nextDown == Decimal(123.449999));
	big = 123.45;
	expect = big.nextUp;
	assertTrue(big.nextAfter(Decimal(123.46)) == expect);
	big = 123.45;
	expect = big.nextDown;
	assertTrue(big.nextAfter(Decimal(123.44)) == expect);
}

/*unittest {	// pow10
	assertTrue(pow10(3) == 1000);
}*/

unittest {
	writeln("===================");
	writeln("decimal.........end");
	writeln("===================");
}

