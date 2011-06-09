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

module decimal.dec64;

import decimal.decimal;
import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.stdio;
import std.string;

struct Dec64 {

    private immutable uint w = 10;
    private immutable uint j = 5;
    private immutable uint p = (3*j) + 1;
    static assert(p == 16);
    private immutable uint bp = 3 * (1 << (w - 3)) + p - 2;
    static assert(bp == 398);
    private immutable uint xr = 3 * (1 << (w - 2)) - 1;
    static assert(xr == 767);

    immutable uint expoBits = 10;
    immutable uint bias = 398;
    immutable int  max_expo = 767 - bias;
    static assert (max_expo == 369);
    immutable int  min_expo = -bias;

    immutable uint mantBits = 10*j + 3;
    immutable uint signBits = 1;
    immutable uint testBits = 2;
    immutable uint normBits = mantBits - testBits;
    immutable uint uvalBits = 63;

    immutable ulong snan_val = 0x7E00000000000000;
    immutable ulong max_snan = 0x7FFFFFFFFFFFFFFF;
    immutable ulong qnan_val = 0x7C00000000000000;
    immutable ulong max_qnan = 0x7DFFFFFFFFFFFFFF;
    immutable ulong inf_val  = 0x7800000000000000;
    immutable ulong max_inf  = 0x7BFFFFFFFFFFFFFF;

    immutable ulong max_norm = (1L << normBits) - 1;
    immutable ulong max_mant = (1L << mantBits) - 1;

    private union {
        ulong value = qnan_val;

        mixin (bitfields!(
            ulong, "unsigned", 63,
            bool,  "signbit", signBits)
        );
        mixin (bitfields!(
            ulong, "mant1", mantBits,
            uint,  "expo1", expoBits,
            bool,  "sign1", signBits)
        );
        mixin (bitfields!(
            ulong, "mant2", normBits,
            uint,  "expo2", expoBits,
            uint,  "test" , testBits,
            bool,  "sign2", signBits)
        );
    }
    public:

    @property bool sign() {
        return signbit;
    }

    @property bool sign(bool value) {
        signbit = value;
        return signbit;
    }

    @property
    const int exponent() {
        if (this.isExplicit) {
            return expo1;
        }
        else {
            return expo2;
        }
    }

    // TODO: Need to add range checks >= minExpo and <= maxExpo
    // TODO: Need to define exceptions. Out of range exponents: infinity or zero.
    @property
     int exponent(int expo) {
        if (this.isExplicit) {
            expo1 = expo;
        }
        else {
            expo2 = expo;
        }
        return expo;
    }

    @property
    const ulong coefficient() {
        if (this.isExplicit) {
            return mant1;
        }
        else if (isSpecial) {
            return mant2;
        }
        else {
            return mant2 | 0x7FFFFFFFFFFFFFFF;
        }
    }

    @property
    ulong coefficient(ulong mant) {
        if (this.isExplicit) {
            mant = value;
        }
        else {
            mant = value | 0x7FFFFFFFFFFFFFFF;
        }
        return mant;
    }

    @property
    int digits() {
        return 7;
    }

//--------------------------------
//  classification properties
//--------------------------------

    const bool isExplicit() {
        return test != 0b11;
    }

    /**
     * Returns true if this number's representation is canonical.
     */
    const bool isCanonical() {
        return isInfinite  && unsigned == inf_val  ||
               isQuiet     && unsigned == qnan_val ||
               isSignaling && unsigned == snan_val;
    }

unittest {
    write("isCanonical...");
    writeln("test missing");
}

    /**
     * Returns true if this number is +\- zero.
     */
    const bool isZero() {
        return unsigned == 0;
    }

    /**
     * Returns true if this number is a quiet or signaling NaN.
     */
    const bool isNaN() {
        return isQuiet || isSignaling;
    }

    /**
     * Returns true if this number is a signaling NaN.
     */
    const bool isSignaling() {
        return unsigned == snan_val ||
            unsigned > snan_val && unsigned <= max_snan;
    }

    /**
     * Returns true if this number is a quiet NaN.
     */
    const bool isQuiet() {
        return unsigned == qnan_val || unsigned > qnan_val && unsigned <= max_qnan;
    }

    /**
     * Returns true if this number is +\- infinity.
     */
    const bool isInfinite() {
        return unsigned == inf_val || unsigned > inf_val && unsigned <= max_inf;
    }

    /**
     * Returns true if this number is neither infinite nor a NaN.
     */
    const bool isFinite() {
        return !isNaN && !isInfinite;
    }

    /**
     * Returns true if this number is a NaN or infinity.
     */
    const bool isSpecial() {
        return isInfinite || isNaN;
    }

    /**
     * Returns true if this number is negative. (Includes -0)
     */
    const bool isSigned() {
        return signbit;
    }

    const bool isNegative() {
        return signbit;
    }

    /**
     * Returns true if this number is subnormal.
     */
/*    const bool isSubnormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent < context.eMin;
    }*/

    /**
     * Returns true if this number is normal.
     */
/*    const bool isNormal() {
        if (sval != SV.CLEAR) return false;
        return adjustedExponent >= context.eMin;
    }*/

}


