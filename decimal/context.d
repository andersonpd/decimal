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

module decimal.context;

import std.array:
replicate;
import std.string:
format;
import std.stdio;

unittest {
	import std.stdio;
	writeln("-------------------");
	writeln("context.......begin");
	writeln("-------------------");
}

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


/// Exceptional conditions.
public enum :
ubyte {
	CLAMPED            = 0x01,
	DIVISION_BY_ZERO   = 0x02,
	INEXACT            = 0x04,
	INVALID_OPERATION  = 0x08,
	OVERFLOW           = 0x10,
	ROUNDED            = 0x20,
	SUBNORMAL          = 0x40,
	UNDERFLOW          = 0x80
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

bool assertEqual(T)(T expected, T actual,
                    string file = __FILE__, int line = __LINE__ ) {
	if (expected == actual) {
		return true;
	}
	writeln("failed at ", std.path.basename(file), "(", line, "):",
	        " expected \"", expected, "\"",
	        " but found \"", actual, "\".");
	return false;
}

bool assertTrue(bool actual, string file = __FILE__, int line = __LINE__ ) {
	return assertEqual(true, actual, file, line);
}

bool assertFalse(bool actual, string file = __FILE__, int line = __LINE__ ) {
	return assertEqual(false, actual, file, line);
}



/// Context for decimal mathematic operations
public struct DecimalContext {

	/// exceptional condition signals
	private static ubyte flags = 0;
	/// exceptional condition trap enablers
	private static ubyte traps = 0;

	/// length of coefficient in (decimal) digits
	immutable uint precision;
	/// maximum value of the adjusted exponent
	immutable int eMax;
	/// smallest normalized exponent
	immutable int eMin;
	/// smallest non-normalized exponent
	immutable int eTiny;
	/// rounding mode
	immutable Rounding rounding;

	/// constructs a context with the specified parameters
	public this(immutable uint precision, immutable int eMax, immutable Rounding rounding) {
		this.precision = precision;
		this.eMax = eMax;
		this.eMin = 1 - eMax;
		this.eTiny = eMin - precision + 1;
		this.rounding = rounding;
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

	// TODO: These should be listed in priority order
	// TODO: It may be more meaningful to have the setFlags routine
	//	pass the line & file. Depends on how stack trace looks
	const void checkFlags(const ubyte flags) {
		if (flags & CLAMPED && traps & CLAMPED) {
			throw new ClampedException("CLAMPED");
		}
		if (flags & DIVISION_BY_ZERO && traps & DIVISION_BY_ZERO) {
			throw new DivByZeroException("DIVISION_BY_ZERO");
		}
		if (flags & INEXACT && traps & INEXACT) {
			throw new InexactException("INEXACT");
		}
		if (flags & INVALID_OPERATION && traps & INVALID_OPERATION) {
			throw new InvalidOperationException("INVALID_OPERATION");
		}
		if (flags & OVERFLOW && traps & OVERFLOW) {
			throw new OverflowException("OVERFLOW");
		}
		if (flags & ROUNDED && traps & ROUNDED) {
			throw new RoundedException("ROUNDED");
		}
		if (flags & SUBNORMAL && traps & SUBNORMAL) {
			throw new SubnormalException("SUBNORMAL");
		}
		if (flags & UNDERFLOW && traps & UNDERFLOW) {
			throw new UnderflowException("UNDERFLOW");
		}
	}

	/// Gets the value of the specified context flag.
	const bool getFlag(const ubyte flag) {
		return (this.flags & flag) == flag;
	}

	/// Returns a snapshot of the context flags.
	const ubyte getFlags() {
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
	const bool getTrap(const ubyte trap) {
		return (this.traps & trap) == trap;
	}

	/// Returns a snapshot of traps.
	const ubyte getTraps() {
		return traps;
	}

	/// Clears all the traps.
	void clearTraps() {
		traps = 0;
	}

};
// end struct DecimalContext

static DecimalContext testContext = DecimalContext(9, 99, Rounding.HALF_EVEN);
static DecimalContext basicContext = DecimalContext(9, 999, Rounding.HALF_UP);
static DecimalContext extendedContext = DecimalContext(99, 999, Rounding.HALF_EVEN);

unittest {
	import std.stdio;
	writeln("-------------------");
	writeln("context.........end");
	writeln("-------------------");
}

