/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */

/* Copyright Paul D. Anderson 2009 - 2012.
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 *  http://www.boost.org/LICENSE_1_0.txt)
 */

module decimal.context;

import std.array: replicate;
import std.bigint;
import std.string: format;
import std.stdio;

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.......begin");
	writeln("===================");
}

//--------------------------
// Radix
//--------------------------

immutable int radix = 10;

//--------------------------
// DecimalContext struct
//--------------------------

/// Available rounding modes.
public enum Rounding {
    HALF_EVEN,
    HALF_DOWN,
    HALF_UP,
    DOWN,
    UP,
    FLOOR,
    CEILING,
}

/// Context for decimal mathematic operations
public struct DecimalContext {

	/// length of the coefficient in (decimal) digits
	immutable uint precision;
	/// maximum value of the adjusted exponent
	immutable int eMax;
	/// smallest normalized exponent
	immutable int eMin;
	/// smallest non-normalized exponent
	immutable int eTiny;
	/// rounding mode
	immutable Rounding rounding;
	/// max coefficient
//	immutable BigInt maxCoefficient;

	/// constructs a context with the specified parameters
	public this(immutable uint precision, immutable int eMax, immutable Rounding rounding) {
		this.precision = precision;
		this.eMax = eMax;
		this.eMin = 1 - eMax;
		this.eTiny = eMin - precision + 1;
		this.rounding = rounding;
//		BigInt mant = 1;
//		this.maxCoefficient = mant; //mant^^precision - 1;
	}

	/// Returns a copy of the context with a new precision
	public DecimalContext setPrecision(immutable uint precision) {
		return DecimalContext(precision, this.eMax, this.rounding);
	}

	/// Returns a copy of the context with a new exponent limit
	public DecimalContext setMaxExponent(immutable int eMax) {
		return DecimalContext(this.precision, eMax, this.rounding);
	}
	/// Returns a copy of the context with a new rounding mode
	public DecimalContext setRounding(immutable Rounding rounding) {
		return DecimalContext(this.precision, this.eMax, rounding);
	}

	// TODO: is there a way to make this const w/in a context?
	// TODO: This is only used by BigDecimal -- maybe should move it there?
	// TODO: The mantissa is 10^^(precision - 1), so probably don't need
	//			to implement as a string.
	// Returns the maximum representable normal value in the current context.
	const string maxString() {
		string cstr = "9." ~ replicate("9", precision - 1)
					~ "E" ~ format("%d", eMax);
		return cstr;
	}
};
// end struct DecimalContext


//--------------------------
// Context flags and trap-enablers
//--------------------------

/// Exceptional conditions.
/// The larger the value, the higher the precedence
public enum : ubyte
{
	INVALID_OPERATION  = 0x80,
	DIVISION_BY_ZERO   = 0x40,
	OVERFLOW           = 0x20,
	SUBNORMAL          = 0x10,
	INEXACT            = 0x08,
	ROUNDED            = 0x04,
	UNDERFLOW          = 0x02,
	CLAMPED            = 0x01
}

class DecimalException: object.Exception {
	this(string msg, string file = __FILE__,
		uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class ClampedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class DivByZeroException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class InexactException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class InvalidOperationException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class OverflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class UnderflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class RoundedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

class SubnormalException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

public struct ContextFlags {

	private static ubyte flags;
	private static ubyte traps;

	/// Sets or resets the specified context flag(s).
	void setFlags(const ubyte flags, const bool value = true) {
		if (value) {
			ubyte saved = this.flags;
			this.flags |= flags;
			ubyte changed = saved ^ flags;
			checkFlags(changed);
			// TODO: if this flag is trapped an exception should be thrown.
		} else {
			this.flags &= !flags;
		}
	}

	// Checks the state of the flags. If a flag is set and its
	// trap-enabler is set, an exception is thrown.
	 void checkFlags(const ubyte flags) {
		if (flags & INVALID_OPERATION && traps & INVALID_OPERATION) {
			throw new InvalidOperationException("INVALID_OPERATION");
		}
		if (flags & DIVISION_BY_ZERO && traps & DIVISION_BY_ZERO) {
			throw new DivByZeroException("DIVISION_BY_ZERO");
		}
		if (flags & OVERFLOW && traps & OVERFLOW) {
			throw new OverflowException("OVERFLOW");
		}
		if (flags & SUBNORMAL && traps & SUBNORMAL) {
			throw new SubnormalException("SUBNORMAL");
		}
		if (flags & INEXACT && traps & INEXACT) {
			throw new InexactException("INEXACT");
		}
		if (flags & ROUNDED && traps & ROUNDED) {
			throw new RoundedException("ROUNDED");
		}
		if (flags & UNDERFLOW && traps & UNDERFLOW) {
			throw new UnderflowException("UNDERFLOW");
		}
		if (flags & CLAMPED && traps & CLAMPED) {
			throw new ClampedException("CLAMPED");
		}
	}

	/// Gets the value of the specified context flag.
	 bool getFlag(const ubyte flag) {
		return (this.flags & flag) == flag;
	}

	/// Returns a snapshot of the context flags.
	 ubyte getFlags() {
		return flags;
	}

	/// Clears all the context flags.
	void clearFlags() {
		flags = 0;
	}

	/// Sets or resets the specified trap(s).
	void setTrap(const ubyte traps, const bool value = true) {
		if (value) {
			this.traps |= traps;
		} else {
			this.traps &= !traps;
		}
	}

	/// Returns the value of the specified trap.
	 bool getTrap(const ubyte trap) {
		return (this.traps & trap) == trap;
	}

	/// Returns a snapshot of traps.
	public ubyte getTraps() {
		return traps;
	}

	/// Clears all the traps.
	void clearTraps() {
		traps = 0;
	}

};

static DecimalContext testContext = DecimalContext(9, 99, Rounding.HALF_EVEN);
static DecimalContext basicContext = DecimalContext(9, 999, Rounding.HALF_UP);
static DecimalContext extendedContext = DecimalContext(99, 9999, Rounding.HALF_EVEN);

static ContextFlags contextFlags;

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.........end");
	writeln("===================");
}

