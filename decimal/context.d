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

module decimal.context;

import std.array: replicate;
import std.string: format;

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.......begin");
	writeln("===================");
}

//--------------------------
// Pre-defined decimal contexts
//--------------------------

/// The context used in examples of operations in the specification.
//immutable static DecimalContext TEST_CONTEXT = DecimalContext(9, 99, Rounding.HALF_EVEN);

/// The context used in examples of operations in the specification.
static DecimalContext testContext = DecimalContext(9, 99, Rounding.HALF_EVEN);

/// The basic default context. In addition the inexact, rounded and subnormal
/// trap-enablers should set to 0; all others should be set to 1 (that is,
/// the other conditions are treated as errors)
/// General Decimal Arithmetic Specification, p. 16.
immutable static DecimalContext BASIC_CONTEXT =
		DecimalContext(9, 999, Rounding.HALF_UP);

/// An extended default context. No trap-enablers should be set.
immutable static DecimalContext EXTENDED_CONTEXT =
	DecimalContext(999, 9999, Rounding.HALF_EVEN);

//--------------------------
// DecimalContext struct
//--------------------------

/// The available rounding modes. For cumulative operations use the
/// HALF_EVEN mode to prevent accumulation of errors. Otherwise the
/// HALF_UP and HALF_DOWN modes are satisfactory. The UP, DOWN, FLOOR,
/// and CEILING modes are also useful for some operations.
/// General Decimal Arithmetic Specification, p. 13-14.
public enum Rounding {
    HALF_EVEN,
    HALF_DOWN,
    HALF_UP,
    DOWN,
    UP,
    FLOOR,
    CEILING,
}

/// The available flags and trap-enablers.
/// The larger value have higher precedence.
/// If more than one flag is set by an operation and traps are enabled,
/// the flag with higher precedence will throw its exception.
/// General Decimal Arithmetic Specification, p. 15.
public enum : ubyte {
	INVALID_OPERATION  = 0x80,
	DIVISION_BY_ZERO   = 0x40,
	OVERFLOW           = 0x20,
	SUBNORMAL          = 0x10,
	INEXACT            = 0x08,
	ROUNDED            = 0x04,
	UNDERFLOW          = 0x02,
	CLAMPED            = 0x01
}

/// Arithmetic context for decimal operations.
/// "The user-selectable parameters and rules
/// which govern the results of arithmetic operations",
/// General Decimal Arithmetic Specification, p. 13-14.
public struct DecimalContext {

	/// Maximum length of the coefficient in (decimal) digits.
	public uint precision;
	/// Maximum value of the adjusted exponent.
	public int maxExpo;
	/// Smallest normalized exponent.
	public int minExpo;
	/// Smallest non-normalized exponent.
	public int tinyExpo;
	/// Rounding mode.
	public Rounding rounding;

	/// Constructs a context with the specified parameters.
	public this(const uint precision, const int maxExpo,
			const Rounding rounding) {
		this.precision = precision;
		this.maxExpo = maxExpo;
		this.minExpo = 1 - maxExpo;
		this.tinyExpo = minExpo - precision + 1;
		this.rounding = rounding;
	}

/*	@property
	public uint precision() {
		return precision;
	}*/

	/// Returns a copy of the context with a new precision.
	public const DecimalContext setPrecision(immutable uint precision) {
		return DecimalContext(precision, this.maxExpo, this.rounding);
	}

	/// Returns a copy of the context with a new maximum exponent.
	public const DecimalContext setMaxExponent(immutable int maxExpo) {
		return DecimalContext(this.precision, maxExpo, this.rounding);
	}
	/// Returns a copy of the context with a new rounding mode.
	public const DecimalContext setRounding(immutable Rounding rounding) {
		return DecimalContext(this.precision, this.maxExpo, rounding);
	}

	// (X)TODO: is there a way to make this const w/in a context?
	// (X)TODO: This is only used by BigDecimal -- maybe should move it there?
	// (X)TODO: The mantissa is 10^^(precision - 1), so probably don't need
	//			to implement as a string.
	// Returns the maximum representable normal value in the current context.
	const string maxString() {
		string cstr = "9." ~ replicate("9", precision - 1)
					~ "E" ~ format("%d", maxExpo);
		return cstr;
	}
};
// end struct DecimalContext


//--------------------------
// Context flags and trap-enablers
//--------------------------

/// The base class for all decimal arithmetic exceptions.
class DecimalException: object.Exception {
	this(string msg, string file = __FILE__,
		uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when the exponent of a result has been altered or constrained
/// in order to fit the constraints of a specific concrete representation.
/// General Decimal Arithmetic Specification, p. 15.
class ClampedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a non-zero dividend is divided by zero.
/// General Decimal Arithmetic Specification, p. 15.
class DivByZeroException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is not exact (one or more non-zero coefficient
/// digits were discarded during rounding).
/// General Decimal Arithmetic Specification, p. 15.
class InexactException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result would be undefined or impossible.
/// General Decimal Arithmetic Specification, p. 15.
class InvalidOperationException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when the exponent of a result is too large to be represented.
/// General Decimal Arithmetic Specification, p. 15.
class OverflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result has been rounded (that is, some zero or non-zero
/// coefficient digits were discarded).
/// General Decimal Arithmetic Specification, p. 15.
class RoundedException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is subnormal (its adjusted exponent is less
/// than the minimum exponent) before any rounding.
/// General Decimal Arithmetic Specification, p. 15.
class SubnormalException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// Raised when a result is both subnormal and inexact.
/// General Decimal Arithmetic Specification, p. 15.
class UnderflowException: DecimalException {
	this(string msg, string file = __FILE__,
	     uint line = cast(uint)__LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
};

/// "The exceptional conditions are grouped into signals,
/// which can be controlled individually.
/// The context contains a flag (which is either 0 or 1)
/// and a trap-enabler (which also is either 0 or 1) for each signal.
/// For each of the signals, the corresponding flag is
/// set to 1 when the signal occurs.
/// It is only reset to 0 by explicit user action."
/// General Decimal Arithmetic Specification, p. 15.
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
			// (X)TODO: if this flag is trapped an exception should be thrown.
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

// this is the single instance of the context flags
static ContextFlags contextFlags;

unittest {
	import std.stdio;
	writeln("===================");
	writeln("context.........end");
	writeln("===================");
}

