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

import std.math: LOG2;
import std.array: replicate;
import std.string: format;

//--------------------------
// DecimalContext struct
//--------------------------

/**
 * Enumeration of available rounding modes.
 */
public enum RoundingMode {
    HALF_EVEN,
    HALF_DOWN,
    HALF_UP,
    DOWN,
    UP,
    FLOOR,
    CEILING,
}

/**
 * Enumeration of available signals.
 */
public enum : ubyte {
      CLAMPED           = 0x01,
      DIVISION_BY_ZERO  = 0x02,
      INEXACT           = 0x04,
      INVALID_OPERATION = 0x08,
      OVERFLOW          = 0x10,
      ROUNDED           = 0x20,
      SUBNORMAL         = 0x40,
      UNDERFLOW         = 0x80
}

/**
 * Context for decimal mathematic operations
 */
public struct DecimalContext {

    private static ubyte traps = 0;
    private static ubyte flags = 0;

    // TODO: make these private and add properties(?)
    RoundingMode rounding = RoundingMode.HALF_EVEN;
    uint precision = 9;
    int eMax =  99;     // largest normalized exponent

    public const DecimalContext dup() {
        DecimalContext copy;
        copy.rounding = rounding;
        copy.precision = precision;
        copy.eMax = eMax;
        return copy;
    }

    /// smallest normalized exponent
    @property
    const int eMin() {
        return 1 - eMax;
    }

    /// smallest non-normalized exponent
    @property
    const int eTiny() {
        return eMin - (precision - 1);
    }

    /// Returns the number of binary digits in this context.
    @property
    const uint mant_dig() {
        return cast(int)(precision/LOG2);
    }

    /// Returns the smallest binary exponent.
    @property
    const int min_exp() {
        return cast(int)(eMin/LOG2);
    }

    /// Returns the largest binary exponent.
    @property
    const int max_exp() {
        return cast(int)(eMax/LOG2);
    }

    // Returns the maximum representable normal value in the current context.
    // TODO: this is a fairly expensive operation. Can it be fixed?
    const string maxString() {
        string cstr = "9." ~ replicate("9", precision-1)
            ~ "E" ~ format("%d", eMax);
        return cstr;
    }

    /// Sets or resets the specified context flag(s).
    void setFlag(const ubyte flags, const bool value = true) {
        if (value) {
            this.flags |= flags;
            // TODO: if this flag is trapped an exception should be thrown.
        }
        else {
            this.flags &= !flags;
        }
    }

    /// Gets the value of the specified context flag.
    const bool getFlag(const ubyte flag) {
        return (this.flags & flag) == flag;
    }

    /// Clears all the context flags.
    void clearFlags() {
        flags = 0;
    }

    /// Sets or resets the specified context trap(s).
    void setTrap(const ubyte traps, const bool value = true) {
        if (value) {
            this.traps |= traps;
        }
        else {
            this.traps &= !traps;
        }
    }

    /// Gets the value of the specified context trap.
    const bool getTrap(const ubyte trap) {
        return (this.traps & trap) == trap;
    }

    /// Clears all the context traps.
    void clearTraps() {
        traps = 0;
    }

    void setBasic() {
        clearFlags;
        setFlag(!(INEXACT | ROUNDED | SUBNORMAL));
        precision = 9;
        rounding = RoundingMode.HALF_UP;
    }

    void setExtended(uint precision) {
        clearFlags;
        clearTraps;
        this.precision = precision;
        rounding = RoundingMode.HALF_EVEN;
    }

};    // end struct DecimalContext

//  stack
public struct ContextStack {

    private DecimalContext[] stack;

    @property
    bool isEmpty() {
        return stack.length == 0;
    }

    @property
    ref DecimalContext top() {
        return stack[$ - 1];
    }

    void push(DecimalContext value) {
        stack ~= value;
    }

    DecimalContext pop() {
        DecimalContext value = top;
        stack.length = stack.length - 1;
        return value;
    }
}

private static ContextStack contextStack;

public static void pushContext(DecimalContext context) {
     contextStack.push(context);
}

public static DecimalContext popContext() {
    return contextStack.pop;
}


//--------------------------
// End of DecimalContext struct
//--------------------------

