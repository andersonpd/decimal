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

/*
 * TODO:
 *
 * Need to point out the two-step nature here -- encoding/decoding and
 * packing/unpacking.
     Encode --> ushort[] to ushort[]
        Encoding converts arrays of small numbers (< 1000) to encoded arrays
    Decode --> ushort[] to ushort[]
    Pack --> ushort[] to uint[]
        Packs encoded arrrays (ushort[]) into uint[] arrays
    Unpack -- uint[] to ushort[]
 *
 * Need to be able to convert to/from uint, ulong and BigInts
 *
 */

module dpd;

import std.bigint: Digit, BigInt;
import std.bitmanip;
import std.conv;
import std.stdio;

import bcd;
//import bigfloat;

    /**************************/
    /*    encoding functions
    /**************************/

    /// Converts an unsigned integer (ushort) value to
    /// a 3-digit densely packed decimal packet. Only the
    /// last three digits of the input value are encoded.
    ushort encode(ushort bin) {
        if (bin >= 1000) {
            bin %= 1000;
        }
        return toDpd[bin];
    }

    unittest {
        assert(encode(0)    == 0);
        assert(encode(9)    == 9);
        assert(encode(10)   == 16);
        assert(encode(19)   == 25);
        assert(encode(99)   == 95);
        assert(encode(999)  == 255);
        assert(encode(500)  == 640);
        assert(encode(1500) == 640);
    }

    /// Converts an unsigned integer (uint) value to
    /// a pair of 3-digit densely packed decimal packets.
    /// Only the last six (decimal) digits of the input value are encoded.
    ushort[] encodeInt(uint bin) {
        if (bin > 1000000) {
            bin %= 1000000;
        }
        ushort[] dpd = new ushort[](2);
        dpd[0] = toDpd[bin/1000];
        dpd[1] = toDpd[bin%1000];
        return dpd;
    }

    unittest {
        static ushort exp[2] = [1, 0];
        assert(encodeInt(1000) == exp);
        exp = [1, 9];
        assert(encodeInt(1009) == exp);
        exp = [2, 16];
        assert(encodeInt(2010) == exp);
        exp = [3, 25];
        assert(encodeInt(3019) == exp);
        exp = [9, 255];
        assert(encodeInt(9999) == exp);
        exp = [95, 255];
        assert(encodeInt(99999) == exp);
        exp = [255, 255];
        assert(encodeInt(999999) == exp);
        exp = [640, 0];
        assert(encodeInt(500000) == exp);
        exp = [640, 0];
        assert(encodeInt(1500000) == exp);
    }

    ///
    /// Converts an unsigned long integer (ulong) value to
    /// an array of four 3-digit densely packed decimal packets.
    /// Only the last 12 digits of the input value are encoded.
    ushort[] encodeLong(ulong bin) {
        ushort[] dpd = new ushort[](4);
        ulong divisor = 1_000_000_000_000;
        ushort packet;
        for (int i = 3; i >= 0; i--) {
            packet = bin / divisor;
            dpd[i] = toDpd[packet];
            bin -= packet * divisor;
            divisor /= 1000;
        }
        dpd[0] = toDpd[bin];
        return dpd;
        return dpd;
    }

    unittest {
/*        assert(encode(1000000) == ??? (look this up)};
        assert(encode(1000009) == ??? (look this up)};
        assert(encode(2000010) == ??? (look this up)};
        assert(encode(3000019) == ??? (look this up)};
        assert(encode(9999999) == ??? (look this up)};
        assert(encode(99999999) == ??? (look this up)};
        assert(encode(999999999) == ??? (look this up)};
        assert(encode(9999999999) == ??? (look this up)};
        assert(encode(99999999999) == ??? (look this up)};
        assert(encode(999999999999) == ??? (look this up)};
        assert(encode(1500000000) == ??? (look this up)};
        assert(encode(1500000000000) == ??? (look this up)};*/
    }

    ///
    /// Converts an string representation of an unsigned integer value to
    /// an array of (3-digit) densely packed decimal packets.
    ushort[] encode(string str) {
        // TODO: see how to prevent this double reverse.
        // NOTE: reverse is a pretty efficient operation --
        //        the alternative is prefixing which isn't...
         char[] digits = str.dup.reverse;
        // if string length is not a multiple of 3, pad with zeros
        uint pad = str.length % 3;
        if (pad != 0) {
            digits.length = str.length + 3 - pad;
            for (int i = str.length; i < digits.length; i++) {
                digits[i] = '0';
            }
        }
        digits.reverse;
        ushort[] encoded = new ushort[](digits.length / 3);
        uint index = 0;
        foreach(ref ushort packet; encoded) {
            packet = encode(to!(ushort)(digits[index..index+3]));
            index += 3;
        }
        return encoded;
    }

    unittest {
        static ushort exp[] = [0];
        assert(encode("0") == exp);
        exp = [9];
        assert(encode("9") == exp);
        exp = [16];
        assert(encode("10") == exp);
        exp = [25];
        assert(encode("19") == exp);
        exp = [95];
        assert(encode("99") == exp);
        exp = [255];
        assert(encode("999") == exp);
        exp = [640];
        assert(encode("500") == exp);
        exp = [1, 640];
        assert(encode("1500") == exp);
    }

    ///
    /// Converts a BigInt value to
    /// an array of (3-digit) densely packed decimal packets.
    /// The sign of the BigInt is ignored.
    ushort[] encode(BigInt big) {
        if (big < 0) {
            big = -big;
        }
        uint len = encodedLength(big);
        ushort[] encoded = new ushort[](len);
        return encode(big, encoded);
    }

    unittest {
        static ushort exp[] = [0];
        assert(encode(BigInt(0)) == exp);
        exp = [9];
        assert(encode(BigInt(9)) == exp);
        exp = [16];
        assert(encode(BigInt(10)) == exp);
        exp = [25];
        assert(encode(BigInt(19)) == exp);
        exp = [95];
        assert(encode(BigInt(99)) == exp);
        exp = [255];
        assert(encode(BigInt(999)) == exp);
        exp = [640];
        assert(encode(BigInt(500)) == exp);
        exp = [1, 640];
        assert(encode(BigInt(1500)) == exp);
        exp = [21, 0, 0, 0, 0];
        assert(encode(BigInt(15000000000000)) == exp);
        exp = [308, 743, 30, 163, 598, 975, 18, 453, 888, 141, 308, 743, 30];
        assert(encode(BigInt("234567890123456789012345678901234567890")) == exp);
    }

    /// Converts a **NON_NEGATIVE** BigInt value to
    /// an array of (3-digit) densely packed decimal packets.
    /// and returns it in the specified array. The array
    /// must be long enough to hold the encoded value.
    ushort[] encode(BigInt big, ref ushort[] encoded) {
        static const uint divisor = 1000;
        uint packet;
        uint index = encoded.length - 1;
        while (big != 0 && index >= 0) {
            (big % divisor).castTo(packet);
            encoded[index--] = encode(packet);
            big /= divisor;
        }
        return encoded;
    }

    /// Returns the length of an array required to
    /// hold the specified number of decimal digits.
    uint encodedLength(uint digits) {
        uint a = digits / 3;
        uint b = digits % 3;
        uint c = b == 0 ? 0 : 1;
        return (a + c);
    }

    /// Returns the length of an array required to
    /// hold the specified BigInt value when encoded.
    uint encodedLength(BigInt big) {
        return encodedLength(decimalDigits(big));
    }

    /**************************/
    /*    decoding functions
    /**************************/

    ///
    /// Converts a 3-digit densely-packed decimal packet
    /// to an unsigned short (ushort) integer value.
    ushort decode(ushort dpd) {
        return toBin[dpd];
    }

    /// Returns the length of the array required to
    /// hold the specified array of DPD packets when decoded.
    uint decodedLength(ushort[] encoded) {
        return encoded.length / 3 + encoded.length % 3;
    }

    ///
    /// Converts the array of 3-digit densely-packed decimal packets
    /// to an array of unsigned short (ushort) integer values.
    ushort[] decode(ushort[] encoded) {
        uint len = decodedLength(encoded);
        ushort[] decoded = new ushort[](len);
        return decode(encoded, decoded);
    }

    /// Converts the array of 3-digit densely-packed decimal packets
    /// to an array of unsigned short (ushort) integer values,
    /// and returns the result in the specified array.
    ushort[] decode(ushort[] encoded, ref ushort[] decoded) {
        // decode into array
        foreach (int i, ushort packet; encoded) {
            decoded[i] = decode(packet);
        }
        return decoded;
    }

    /// Converts an array of 3-digit densely-packed decimal packets
    /// to an unsigned integer (uint) value.
    /// The input array must be two elements long.
    uint toInt(ushort[] encoded) {
//        TODO: implement
        return 0;
    }

    /// Converts an array of 3-digit densely-packed decimal packets
    /// to an unsigned long integer (ulong) value.
    /// The input array must be four elements long.
    ulong toLong(ushort[] encoded) {
//        TODO: implement
        return 0L;
    }

    /// Converts an array of 3-digit densely-packed decimal packets
    /// to a BigInt value.
    BigInt toBigInt(ushort[] encoded) {
        ushort[] decoded = decode(encoded);
        BigInt bin = BigInt(cast(uint)decoded[0]);
        for (int i = 1; i < decoded.length; i++) {
            bin = bin * 1000 + cast(uint)encoded[i];
        }
        return bin;
    }

    /**************************/
    /*    packing functions
    /**************************/

    /// Converts an unsigned 32-bit integer (uint) value to
    /// a 20-bit densely-packed decimal representation.
    /// Only the lower six (decimal) digits of the input value are
    /// converted.
    uint packInt(uint bin) {
        uint packed;
        if (bin > 1000000) {
            bin %= 1000000;
        }
        packed = toDpd[bin/1000] << 10;
        packed |= toDpd[bin%1000];
        return packed;
    }

    unittest {
        assert(packInt(0)      == 0);
        assert(packInt(1)      == 1);
        assert(packInt(999)    == 255);
        assert(packInt(1000)   == 1024);
        assert(packInt(1009)   == 1033);
        assert(packInt(2010)   == 2064);
        assert(packInt(3019)   == 3097);
        assert(packInt(9999)   == 9471);
        assert(packInt(99999)  == 97535);
        assert(packInt(999999) == 261375);
        assert(packInt(500000) == 655360);
        assert(packInt(1500000)== 655360);
    }

    /// Converts an unsigned long integer (ulong) value to
    /// a 40 bit densely-packed decimal representation.
    /// Only the lower twelve digits of the input value are
    /// converted.
    ulong packLong(ulong bin) {
        ulong dpd;
        // TODO: is this right??
        ulong divisor = 1_000_000_000_000;
        ushort packet;
        for (int i = 0; i < 3; i++) {
            packet = bin / divisor;
            dpd |= toDpd[packet];
            dpd <<= 10;
            bin -= packet * divisor;
            divisor /= 1000;
        }
        dpd |= toDpd[bin];
        return dpd;
    }

    uint[] pack(ushort[] encoded) {
        uint[] packed;
        packed.length = packedLength(encoded);
        return pack(encoded, packed);
    }

    uint[] pack(ushort[] encoded, ref uint[] packed) {
        assert(encoded.length > 0 && packed.length >= packedLength(encoded));
        uint shift = 0;
        uint index = packed.length - 1;
        packed[index] = 0;
        foreach (ushort packet; encoded) {
            packed[index] |= packet << shift;
            shift += 10;
            if (shift > 32) {
                shift -= 32;
                index -= 1;
                packed[index] = packet >> 10 - shift;
            }
        }
        return packed;
    }

    unittest {
        ushort[] encoded;
        uint[] packed;
        uint[] expected;
/*        assert(pack(encoded, packed) == expected);*/
        encoded = [1];
        packed.length = 1;
        expected = [1];
        assert(pack(encoded, packed) == expected);
        encoded = [1, 1];
        packed.length = 1;
        expected = [1025];
        assert(pack(encoded, packed) == expected);
        encoded = [1, 1, 1];
        packed.length = 1;
        expected = [1049601];
        assert(pack(encoded, packed) == expected);
        encoded = [1, 1, 1, 1];
        packed.length = 2;
        expected = [0, 1074791425];
        pack(encoded,packed);
        assert(pack(encoded, packed) == expected);
        encoded = [999, 999];
        packed.length = 1;
        expected = [1023975];
        pack(encoded,packed);
        assert(pack(encoded, packed) == expected);
        encoded = [1, 1, 1, 1, 1];
        packed.length = 2;
        expected = [256, 1074791425];
        pack(encoded,packed);
        assert(pack(encoded, packed) == expected);
        encoded = [999, 999, 999];
        packed.length = 1;
        expected = [1048551399];
        pack(encoded,packed);
        assert(pack(encoded, packed) == expected);
        encoded = [999, 999, 999, 999];
        packed.length = 2;
        expected = [249, 4269776871u];
        pack(encoded,packed);
        assert(pack(encoded, packed) == expected);
    }

    ///
    uint[] pack(string str) {
        return pack(encode(str));
    }

    ///
    uint[] pack(BigInt big) {
        return pack(encode(big));
    }

    ///
    uint packedLength(BigInt big) {
        return packedLength(decimalDigits(big));
    }

    ///
    uint packedLength(ushort[] encoded) {
        return packedLength(encoded.length * 3);
    }

    ///
    uint packedLength(uint digits) {
        uint packets = digits / 3;
        if (digits % 3 != 0) {
            packets++;
        }
        uint bits = packets * 10;
        uint words = bits / 32;
        if (bits % 32 != 0) {
            words++;
        }
        return words;
    }

    /**************************/
    /*    unpacking functions
    /**************************/

    ///
    ushort[] unpack(uint[] packed) {
        ushort[] unpacked;
        unpacked.length = unpackedLength(packed);
        uint index = packed.length - 1;
        uint shift = 0;
        foreach_reverse (ref ushort packet; unpacked) {
            packet = (packed[index] >> shift) & 0x3FF;
//            writefln("packet = ", packet);
            shift += 10;
            if (shift > 32) {
                shift -= 32;
                index -= 1;
                packet |= (packed[index] & 0x3FF) << shift;
            }
        }
        index = 0;
        while (unpacked[index] == 0) {
            index ++;
        }
        if (index != 0) {
            return unpacked[index..$];
        }
        return unpacked;
    }

    unittest {
        uint[] packed;
        ushort[] expected;
        packed = [1];
        expected = [1];
        assert(expected == unpack(packed));
        packed = [1025];
        expected = [1, 1];
        assert(expected == unpack(packed));
        packed = [1049601];
        expected = [1, 1, 1];
        assert(expected == unpack(packed));
        packed = [0, 1074791425];
        expected = [1, 1, 1, 1];
        assert(expected == unpack(packed));
        packed = [256, 1074791425];
        expected = [1, 1, 1, 1, 1];
//        writefln(unpack(packed));
        assert(expected == unpack(packed));
    }

    BigInt toBigInt(uint[] packed) {
        ushort[] unpacked = unpack(packed);
        ushort[] decoded = decode(unpack(packed));
        auto big = BigInt(0);
        foreach (ushort packet; decoded) {
            big *= 10;
            big += cast(int)packet;
        }
        return big;
    }

    ///
    uint unpackedLength(uint[] packed) {
        uint bits = 32 * packed.length;
        return bits / 10;
    }

    /**************************/
    /*    private section
    /**************************/

private:

    /*******************************/
    /*    static build of lookup table
    /*******************************/

    static ushort[1000] toDpd;
    static ushort[1024] toBin;

    static this() {
        for (ushort bin = 0; bin < 1000; bin ++) {
            ushort dpd = toDPD(bin);
            toDpd[bin] = dpd;
            toBin[dpd] = bin;
        }
    }

    struct DPD {

        union {
            ushort value;
            mixin(bitfields!(
                bool, "y", 1,
                bool, "x", 1,
                bool, "w", 1,
                bool, "v", 1,
                bool, "u", 1,
                bool, "t", 1,
                bool, "s", 1,
                bool, "r", 1,
                bool, "q", 1,
                bool, "p", 1,
                ubyte, "", 6)
            );
        }

        this(ushort n) {
            value = n;
        }
    }

    struct BCD {

        union {
            Bcd4 bcd;
            mixin(bitfields!(
                bool, "m", 1,
                bool, "k", 1,
                bool, "j", 1,
                bool, "i", 1,
                bool, "h", 1,
                bool, "g", 1,
                bool, "f", 1,
                bool, "e", 1,
                bool, "d", 1,
                bool, "c", 1,
                bool, "b", 1,
                bool, "a", 1,
                ubyte, "", 4)
            );
        }

        this(ushort n) {
            bcd  = n;
        }

        ushort toBinary() {
            return bcd.toBinary;
        }

    }

    ushort toDPD(ushort n) {

        BCD bcd = BCD(n);

        bool a = bcd.a;
        bool b = bcd.b;
        bool c = bcd.c;
        bool d = bcd.d;
        bool e = bcd.e;
        bool f = bcd.f;
        bool g = bcd.g;
        bool h = bcd.h;
        bool i = bcd.i;
        bool j = bcd.j;
        bool k = bcd.k;
        bool m = bcd.m;

        DPD dpd;
        dpd.p = b | (a & j) | (a & f & i);
        dpd.q = c | (a & k) | (a & g & i);
        dpd.r = d;
        dpd.s = (f & (!a | !i)) | (!a & e & j) | (e & i);
        dpd.t = g | (!a & e & k) | (a & i);
        dpd.u = h;
        dpd.v = a | e | i;
        dpd.w = a | (e & i) | (!e & j);
        dpd.x = e | (a & i) | (!a & k);
        dpd.y = m;

        return dpd.value;
    }

    ushort toShort(ushort n) {

        DPD dpd;
        dpd.value = n;

        bool p = dpd.p;
        bool q = dpd.q;
        bool r = dpd.r;
        bool s = dpd.s;
        bool t = dpd.t;
        bool u = dpd.u;
        bool v = dpd.v;
        bool w = dpd.w;
        bool x = dpd.x;
        bool y = dpd.y;

        BCD bcd;
        bcd.a = (v & w) & (!s | t | !x);
        bcd.b = p & (!v | !w | (s & !t & x));
        bcd.c = q & (!v | !w | (s & !t & x));
        bcd.d = r;
        bcd.e = v & ((!w & x) | (!t & x) | (s & x));
        bcd.f = (s & (!v | !x)) | (p & !s & t & v & w & x);
        bcd.g = (t & (!v | !x)) | (q & !s & t & w);
        bcd.h = u;
        bcd.i = v & ((!w & !x) | (w & x & (s | t)));
        bcd.j = (!v & w) | (s & v & !w & x) | (p & w & (!x | (!s & !t)));
        bcd.k = (!v & x) | (t & !w & x) | (q & v & w & (!x | (!s & !t)));
        bcd.m = y;

        return bcd.toBinary;
    }

    /**************************/
    /*    unittest section
    /**************************/

    /*

        3. Add some spot checks -- 0, 9, 999, etc.
        4. Print out the table.
        5. Maybe lose the BCD stuff and just provide the table.

        */

    unittest {
        for (ushort i = 0; i < 1000; i++) {
            ushort dpd = toDPD(i);
//            if (i % 10 == 0) writefln();
//            writef("%03d=%03d ", i, dpd);
            // check value limit
            assert(dpd < 1024);
            // check two-way conversion
            ushort copy = toShort(dpd);
            assert(i == copy);
        };
        // check no duplicates
        foreach(int i, ushort dpd1; toDpd) {
            foreach (int j, ushort dpd2; toDpd) {
                if (i != j) {
                    assert(dpd1 != dpd2);
                }
            }
        }
    }


