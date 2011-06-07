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

import std.container;

//--------------------------
// DecimalContext struct
//--------------------------

/**
 * Enumeration of available rounding modes.
 */
public enum Rounding {
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

    private ubyte traps;
    private ubyte flags;
    Rounding mode = Rounding.HALF_EVEN;
    uint precision = 9;

    const DecimalContext dup() {
        DecimalContext copy;
        copy.traps = traps;
        copy.flags = flags;
        copy.mode = mode;
        copy.precision = precision;
        return copy;
    }

    /// smallest normalized exponent
    int eMin = -98;

    /// largest normalized exponent
    int eMax = 99;

    /// smallest non-normalized exponent
    const int eTiny() {
        return eMin - (precision - 1);
    }

    /// Sets (or resets?) the specified context flag(s).
    void setFlag(const ubyte flags, const bool value = true) {
        if (value) {
            this.flags |= flags;
            // TODO: if this flag is trapped an exception should be thrown.
        }
        // TODO: can the user reset single flags?
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
        mode = Rounding.HALF_UP;
    }

    void setExtended(uint precision) {
        clearFlags;
        clearTraps;
        this.precision = precision;
        mode = Rounding.HALF_EVEN;
    }

};    // end struct DecimalContext

// default context
public immutable DecimalContext DEFAULT_CONTEXT = DecimalContext();

//  stack
public struct Stack(T) {

    private    T[] stack;

    @property bool isEmpty() {
        return stack.length == 0;
    }
    @property ref T top() {
        return stack[$ - 1];
    }
    void push(T value) {
        stack ~= value;
    }
    T pop() {
        T value = top;
        stack.length = stack.length - 1;
        return value;
    }
}

//--------------------------
// End of DecimalContext struct
//--------------------------

