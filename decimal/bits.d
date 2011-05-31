// Written in the D programming language.

/**

Filename: decimal.d

Description: Provides structs for IEEE-754r decimal numbers.

Authors: Paul D. Anderson

Date: 2008.09.12

License: Public Domain

*/

/*
	TODO:
		1. Complete implementation of decimal32.
		2. Convert decimal32 implementation to a template
		3. Instantiate as decimal32, decimal64, decimal128

	Testing:
		1. Convert local test routines to unittests.
		2. Evaluate test coverage -- cover any missing areas.

	Complete implementation:
		1. Complete functions for packing and unpacking of coefficients
		2. Complete toString functions
		3. Complete constructors and/or opCall() for creation.
		4. Using above, test for correct creation and display.
		5. Further progress depends on implementation of BigFloat.
		6. Conversion to/from BigFloats (including appropriate precision).
		7. Implement math functions by calls to BigFloat.

*/

module decimal;

import std.bitmanip;
import std.intrinsic;
import std.stdio;
import std.string;

import bcd;
/*import bigfloat;*/
//import bigext;
import dpd;
// import decimal.decfloat;

/*	enum DecimalType {
		DECIMAL32,
		DECIMAL64,
		DECIMAL128
	};*/


/*	interface DecimalNumber {
		int getExponent();
		ubyte[] getCoefficient();
		bool getSign();
		ubyte getCombi();
		ushort getExpo();
		ushort[] getBCD(); // want 10 bit packed;

	}	// end interface DecimalNumber;*/

/*	BigFloat toBigFloat(DecimalNumber dec) {
	      return new BigFloat();
	}

	// function template
	BigFloat toBF(T) (T t) {
		bool sign = t.getSign();
		return new BigFloat();
	}*/

struct decimal32 {

	static const  {
		uint SIGN_SIZE  = 1;
		uint COMBI_SIZE = 5;
		uint EXPO_SIZE   = 6;
		uint COEFF_SIZE  = 20;
		uint NUMBER_SIZE =
			SIGN_SIZE + COMBI_SIZE + EXPO_SIZE + COEFF_SIZE;

		ubyte COMBI_NAN    = 0b11111;
		ubyte COMBI_INF    = 0b11110;
		ubyte COMBI_BITS12 = 0b11000;
		ubyte COMBI_BITS34 = 0b00110;

		ubyte EXPO_MSB = 0b100000;
		int EXPO_LENGTH = EXPO_SIZE + 2;
		int EXPO_LIMIT = 3 << EXPO_LENGTH - 1;
		// int EXPO_LIMIT = 191;
		int EXPO_ZERO = 0;
		int EXPO_BIAS = 101;
		int EXPO_MAX  = 96;
		int EXPO_MIN  = -95;

		uint COEF_DPDS = COEFF_SIZE / 10;
		uint COEF_DIGITS = 3 * COEF_DPDS + 1;

		uint COMBI_A = 30;
		uint COMBI_B = 29;
		uint COMBI_C = 28;
		uint COMBI_D = 27;
		uint COMBI_E = 26;

	}

	union {
		uint value;
//		ubyte[4] bytes;
	 	mixin(bitfields!(
			uint,	"coef", COEFF_SIZE,
        	ubyte,	"expo",	EXPO_SIZE,
        	ubyte,	"combi", COMBI_SIZE,
        	bool,	"sign",	1));
	}

	bool getSign() {
		return sign;
	}

/*	PackedShort[] getPackedDigits() {
		PackedShort[] packed;
		packed.length = COEF_DPDS;
		uint copy = coef;
		foreach (PackedShort dpd; packed) {
			dpd = PackedShort(0x3FF & copy);
			copy >>= 10;
		}
		return packed;
	}*/

	ubyte[] getDigits() {
		ubyte[] digits;
		digits.length = COEF_DIGITS;
/*		PackedShort[] packed = getPackedDigits;
		uint index = 0;
		digits[index++] = getFirstDigit;
		foreach(PackedShort dpd; packed) {
			foreach(ubyte digit; dpd.toDigits()) {
				digits[index++] = digit;
			}
		}		*/
		return digits;
	}

	void setDigits(ubyte[] digits) {

	}

	void setDigits(ushort[] words) {

	}

	uint getExpoBits() {
		if (combiEncrypted) {
			return (combi & COMBI_BITS34) >> 1;
		} else {
			return (combi & COMBI_BITS12) >> 3;
		}
	}

	void setExpoBits(uint exponent) {
		assert(exponent < 3);
		uint copy = combi;
		if (combiEncrypted) {
			switch (exponent) {
				case 0:
					btr(&copy, 1);
					btr(&copy, 2);
					break;
				case 1:
					bts(&copy, 1);
					btr(&copy, 2);
					break;
				case 2:
					btr(&copy, 1);
					bts(&copy, 2);
					break;
			}
		}
		else {
			switch (exponent) {
				case 0:
					btr(&copy, 3);
					btr(&copy, 4);
					break;
				case 1:
					bts(&copy, 3);
					btr(&copy, 4);
					break;
				case 2:
					btr(&copy, 3);
					bts(&copy, 4);
					break;
			}
		}
		combi = copy;
	}

	uint getBiasedExponent() {
		return expo | (getExpoBits << EXPO_SIZE);
	}

	int getExponent() {
		return getBiasedExponent - EXPO_BIAS;
	}

	void setExponent(int exponent) {
		assert(exponent >= EXPO_MIN);
		expo = exponent + EXPO_BIAS;
		setExpoBits(exponent >> EXPO_SIZE);
	}

	void setCoefficient(ulong coefficient) {

	}

	void shiftExpoBits(ref uint copy, bool right) {
		if (right) {
			for (int i = 0; i < 2; i++) {
				bts(&copy, i + 3) ? bts(&copy, i + 1) : btr(&copy, i + 1);
			}
		}
		else {
			for (int i = 0; i < 2; i++) {
				bt(&copy, i + 1) ? bts(&copy, i + 3) : btr(&copy, i + 3);
			}
		}
	}

	void setFirstDigit(uint msd) {
		assert(msd < 10);
		uint copy = combi;
		if (msd > 7) {
			if (!combiEncrypted) {
				shiftExpoBits(copy, true);
			}
			msd == 8 ? btr(&copy, 0) : bts(&copy, 0);
		}
		else {
			if (combiEncrypted) {
				shiftExpoBits(copy, false);
			}
			for (int i = 0; i < 3; i++) {
				bt(&msd, i) ? bts(&copy, i) : btr(&copy, i);
			}
		}
		combi = copy;
	}

	ubyte getFirstDigit() {
		if (combiEncrypted) {
			return (combi & 1) ? 9 : 8;
		}
		else {
			return (combi & 0b111);
		}
	}

	bool combiEncrypted() {
		return combi >= 24; // 24 == 0b11000
	}

	bool isNaN() {
		return combi == COMBI_NAN;
	}

	bool isSignalingNaN() {
		return isNaN() && (expo & EXPO_MSB != 0);
	}

	bool isNegative() {
		return sign;
	}

	bool isPositive() {
		return !sign;
	}

	byte signValue() {
		return sign ? 1 : -1;
	}

	bool isInfinity() {
		return combi == COMBI_INF;
	}

	void opAssign(int n) {

	}


/*	BigFloat toFloat() {
		return toBF!(decimal32)(this);
	}*/

//	float toFloat();
//	double toDouble();
/*	real toReal();

	long toLong();*/

	string toHex() {
		return format("0x%08X", value);
	}

	string toBinary() {
		return format("0b%032b", value);
	}

	string getDigitsString() {
		char[] digits;
		digits.length = COEF_DIGITS;
		foreach (int i, ubyte digit; getDigits()) {
			digits[i] = cast(char)(digit + '0');
		}
		return cast(string)digits;
	}

	string toScientific() {
		return format("%s0.%sE%d",
			sign ? "" : "-", getDigitsString, getExponent);
	}

	static decimal32 create_decimal32() {
		return decimal32();
	}

	static decimal32 toDecimal(bool sign, ulong coefficient, int exponent) {
		auto number = decimal32();
		number.sign = sign;
		number.setExponent(exponent);
		return number;
	}

	static decimal32 toDecimal(string str) {
		return decimal32();
	}

}	// end struct decimal32

//	static invariant decimal32 DEC32_ZERO;
//	static invariant decimal32 DEC32_POS_INFINITY;
//	static invariant decimal32 DEC32_NEG_INFINITY;
//	static invariant decimal32 DEC32_NAN;
//	static invariant decimal32 DEC32_SIGNALING_NAN;

	void main() {
/*		decimal32 d = decimal32.toDecimal(false, 0, 0);
		writefln("d = %s", d.toScientific);
		writefln("d = 0x%08X [%032b]", d.value, d.value);*/

/*		PackedInt[] packed = pack("123456789");
		foreach (int i, PackedInt pint; packed) {
			writefln("packed[%d] = [%032b]", i, pint.num);
		}
		packed = pack("12345678901000");
		foreach (int i, PackedInt pint; packed) {
			writefln("packed[%d] = [%032b]", i, pint.num);
		}*/

//		testBCD;
//		testBigInts;
/*		uint c = uint.max;
		writefln("c = 0x%08X [%032b]", c, c);
		c = 0;
		writefln("c = 0x%08X [%032b]", c, c);
		bts(&c, 3);
		writefln("c = 0x%08X [%032b]", c, c);
		auto d = decimal32();
		writefln("d = 0x%08X [%032b]", d.value, d.value);
		bts(cast(uint*)&d, 28);
		writefln("d = 0x%08X [%032b]", d.value, d.value);
		d.sign = false;
		writefln("d = 0x%08X [%032b]", d.value, d.value);*/
/*		d.sign = true;
		writefln("d = 0x%08X [%032b]", d.value, d.value);*/
/*		d.combi = 0xFF;
		writefln("d = 0x%08X [%032b]", d.value, d.value);
		d.combi = 0x01;
		writefln("d = 0x%08X [%032b]", d.value, d.value);
		d.combi = c;
		writefln("d = 0x%08X [%032b]", d.value, d.value);
		for (int i = 0; i < 10; i++) {
			d.combi = (i % 2 == 1) ? 0b11010 : 0b00100;
			d.setFirstDigit(i);
			writefln("%d. msd = %d; d = 0x%08X [%05b]", i, d.getFirstDigit(), d.value, d.combi);
		}
		for (int i = 9; i >= 0; i--) {
			d.combi = (i % 2 == 0) ? 0b11010 : 0b00100;
			d.setFirstDigit(i);
			writefln("%d. msd = %d; d = 0x%08X [%05b]", i, d.getFirstDigit(), d.value, d.combi);
		}*/
/*		auto number = decimal32();
		writefln("number = %s", number.toScientific());
		writefln("decimal32 = %d", number.sizeof);
		writefln("decimal32 = %s", number.toHex());
		writefln("decimal32 = %s", number.toBinary());
//		writefln("decimal32 = %r", number.value);
		BigFloat bf = new BigFloat();
		writefln("BigFloat = ", bf.sizeof);
		writefln("BigFLoat = ", bf.getSign());*/
	}



