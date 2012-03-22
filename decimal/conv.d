/// A D programming language implementation of the
/// General Decimal Arithmetic Specification,
/// Version 1.70, (25 March 2009).
/// (http://www.speleotrove.com/decimal/decarith.pdf)
///
/// License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
/// Authors: Paul D. Anderson

/// Copyright Paul D. Anderson 2009 - 2012.
/// Distributed under the Boost Software License, Version 1.0.
/// (See accompanying file LICENSE_1_0.txt or copy at
/// http://www.boost.org/LICENSE_1_0.txt)

module decimal.conv;

import std.array: insertInPlace;
import std.bigint;
import std.bitmanip;
import std.conv;
import std.string;

//import decimal.context;
import decimal.dec32;
import decimal.dec64;
import decimal.dec128;
import decimal.decimal;
import decimal.utils;

unittest {
	writeln("===================");
	writeln("conv..........begin");
	writeln("===================");
}

//--------------------------------
//  conversions
//--------------------------------

/// to!string(BigInt).
T to(T: string)(const BigInt num) {
	string outbuff = "";
	void sink(const(char)[] s) {
		outbuff ~= s;
	}
	num.toString(&sink, "%d");
	return outbuff;
}

/// to!string(int).
T to(T: string)(const long n) {
	return format("%d", n);
}

/// Converts a decimal number to another decimal type
public T toDecimal(T, U)(const U num) if (isDecimal!T && isBigDecimal!U) {
		static if (is(typeof(num) == T)) {
		return num.dup;
	}
	return T(num);
}

/// Converts a decimal number to another decimal type
public T toDecimal(T, U)(const U num) if (isDecimal!T && isFixedDecimal!U) {
	static if (is(typeof(num) == T)) {
		return num.dup;
	}
	bool sign = num.sign;
	if (num.isFinite) {
		return T(sign, num.coefficient, num.exponent);
	} else if (num.isInfinite) {
		return T.infinity(sign);
	} else if (num.isSignaling) {
		return T.snan(num.payload);
	} else if (num.isQuiet) {
		return T.nan(num.payload);
	}
	return T.nan;
}

unittest {
	write("toDecimal...");
	BigDecimal big;
	Dec32 expect, actual;
	big = BigDecimal(12345E-8);
	expect = Dec32(12345E-8);
	actual = toDecimal!(Dec32,BigDecimal)(big);
	assertEqual(expect, actual);
	assertEqual(typeid(typeof(expect)), typeid(typeof(actual)));
	Dec64 rexpect, ractual;
	big = BigDecimal(12345E-8);
	rexpect = Dec64(12345E-8);
	ractual = toDecimal!(Dec64,BigDecimal)(big);
	assertEqual(rexpect, ractual);
	assertEqual(typeid(typeof(rexpect)), typeid(typeof(ractual)));
	Dec64 d64 = Dec64(12345E-8);
	expect = Dec32(12345E-8);
	actual = toDecimal!(Dec32,Dec64)(d64);
	assertEqual(expect, actual);
	assertEqual(typeid(typeof(rexpect)), typeid(typeof(ractual)));
	writeln("passed");
}

/// Converts any decimal to a big decimal
public BigDecimal toBigDecimal(T)(const T num) if (isDecimal!T) {
	static if (is(typeof(num) == BigDecimal)) {
		return num.dup;
	}
	bool sign = num.sign;
	if (num.isFinite) {
		auto mant = num.coefficient;
		int  expo = num.exponent;
		return BigDecimal(sign, mant, expo);
	} else if (num.isInfinite) {
		return BigDecimal.infinity(sign);
	} else if (num.isSignaling) {
		return BigDecimal.snan(num.payload);
	} else if (num.isQuiet) {
		return BigDecimal.nan(num.payload);
	}
	return BigDecimal.nan;
}

unittest {
	Dec32 small;
	BigDecimal big;
	small = 5;
	big = toBigDecimal!Dec32(small);
	assertTrue(big.toString == small.toString);
}

/// Returns true if T is a decimal type.
public template isDecimal(T) {
enum bool isDecimal = is(T: Dec32) || is(T: Dec64) || is(T: Dec128) || is(T: BigDecimal);
}

/// Returns true if T is an arbitrary-precision decimal type.
public template isBigDecimal(T) {
enum bool isBigDecimal = is(T: BigDecimal);
}

/// Returns true if T is a fixed-precision decimal type.
public template isFixedDecimal(T) {
enum bool isFixedDecimal = is(T: Dec32) || is(T: Dec64) || is(T: Dec128);
}

unittest {
	assertTrue(isFixedDecimal!Dec32);
	assertTrue(!isFixedDecimal!BigDecimal);
	assertTrue(isDecimal!Dec32);
	assertTrue(isDecimal!BigDecimal);
	assertTrue(!isBigDecimal!Dec32);
	assertTrue(isBigDecimal!BigDecimal);
}

/// Converts a decimal number to a scientific string representation.
public string sciForm(T)(const T num) if (isDecimal!T) {
	return stdForm!T(num, false);
};  // end sciForm()

unittest {
	write("sciForm...");
	writeln("test missing");
}

/// Converts a decimal number to an engineering string representation.
public string engForm(T)(const T num) if (isDecimal!T) {
	return stdForm!T(num, true);
}  // end engForm()

unittest {
	write("engForm...");
	writeln("test missing");
}

/// string representation of special values
private string toSpecialString(T)(const T num,
		bool shortForm = false, bool lower = false, bool upper = false)
		if (isDecimal!T) {
	string str = "";
	if (num.isInfinite) {
		str = shortForm ? "Inf" : "Infinity";
		if (lower) str = toLower(str);
		else if (upper) str = toUpper(str);
		return num.isSigned ? "-" ~ str : str;
	}
	if (num.isNaN) {
		str = !shortForm && num.isSignaling ? "sNaN" : "NaN";
		if (num.payload) {
			str ~= to!string(num.payload);
		}
		if (lower) str = toLower(str);
		else if (upper) str = toUpper(str);
		return num.isSigned ? "-" ~ str : str;
	}
	return str;
}

unittest {
	write("toSpecialString...");
	BigDecimal num;
	string expect, actual;
	num = BigDecimal("inf");
	actual = toSpecialString(num);
	expect = "Infinity";
	assertEqual(expect, actual);
	actual = toSpecialString(num, true);
	expect = "Inf";
	assertEqual(expect, actual);
	writeln("passed");
}

/// Converts a decimal number to a string in decimal format (xxx.xxx)
private string decimalForm(T)
	(const T num, const int precision = 0) if (isDecimal!T) {

	// finite numbers
	auto mant = num.coefficient;
	auto expo = num.exponent;
	auto sign = num.isSigned;
	// convert the coefficient to a string
	string temp = to!string(mant);
	char[] cstr = temp.dup;
	if (expo >= 0) {
		if (expo > 0) {
			// add zeros up to the decimal point
			cstr ~= replicate("0", expo);
		}
		if (precision) {
			// add zeros trailing the decimal point
			cstr ~= "." ~ replicate("0", precision);
		}
	}
	else { // (expo < 0)
		int point = -expo;
//		if (point > precision) {
			// rounding required: for 32/64 use ulong version
			// for big and 128: TBD.
		// if coefficient is too small, pad with zeros on the left
		if (point > cstr.length) {
			cstr = rightJustify(cstr, point, '0');
		}
		// if no chars precede the decimal point, prefix a zero
		if (point == cstr.length) {
			cstr = "0." ~ cstr;
		}
		// otherwise insert a decimal point
		else {
			insertInPlace(cstr, cstr.length - point, ".");
		}
		// if result is less than precision, add zeros
		if (point < precision) {
			cstr ~= replicate("0", precision - point);
		}
	}
	return sign ? ("-" ~ cstr).idup : cstr.idup;
}

unittest {
	write("decimalForm...");
	Dec32 num;
	string expect, actual;
	num = Dec32(125);
	expect = "125.000";
	actual = decimalForm(num, 3);
	assertEqual(expect, actual);
	num = Dec32(125E5);
	expect = "12500000";
	actual = decimalForm(num);
	assertEqual(expect, actual);
	num = Dec32(1.25);
	expect = "1.25";
	actual = decimalForm(num);
	assertEqual(expect, actual);
	num = Dec32(125E-5);
	expect = "0.001250";
	actual = decimalForm(num, 6);
	assertEqual(expect, actual);
	writeln("passed");
}

/// Converts a decimal number to exponential notation.
private string exponentForm(T)(const T num, const bool lowerCase = false,
	const bool padExpo = false) if (isDecimal!T) {

	auto mant = num.coefficient;
	auto expo = num.exponent;
	auto sign = num.isSigned;
	string temp = to!string(mant);
	char[] cstr = temp.dup;
	int adjx = expo + cstr.length - 1;
	if (cstr.length > 1) {
		insertInPlace(cstr, 1, ".");
	}
	string xstr = to!string(std.math.abs(adjx));
	if (padExpo && xstr.length < 2) {
		xstr = prefix(xstr, "0");
	}
	xstr = adjx < 0 ? "-" ~ xstr : "+" ~ xstr;
	string expoChar = lowerCase ? "e" : "E";
	string str = (cstr ~ expoChar ~ xstr).idup;
	return sign ? "-" ~ str : str;
}  // end exponentForm

unittest {
	write("exponentForm...");
	Dec32 num;
	string expect, actual;
	num = Dec32(125);
	expect = "1.25E+2";
	actual = exponentForm(num);
	assertEqual(expect, actual);
	expect = "1.25e+02";
	actual = exponentForm(num, true, true);
	assertEqual(expect, actual);
	num = Dec32(125E5);
	expect = "1.25E+7";
	actual = exponentForm(num);
	assertEqual(expect, actual);
	num = Dec32(1.25);
	expect = "1.25E+0";
	actual = exponentForm(num);
	assertEqual(expect, actual);
	num = Dec32(125E-5);
	expect = "1.25E-3";
	actual = exponentForm(num);
	assertEqual(expect, actual);
	writeln("passed");
}

/// Converts a decimal number to one of two (three, counting decimal form)
/// standard string representations.
private string stdForm(T)(const T num,
		bool engineering = false) if (isDecimal!T) {

	// special values
	if (num.isSpecial) {
		return toSpecialString!T(num);
	}

	// finite numbers
	auto mant = num.coefficient;
	auto expo = num.exponent;
	auto sign = num.isSigned;

	string temp = to!string(mant);
	char[] cstr = temp.dup;
	int clen = cstr.length;
	int adjx = expo + clen - 1;
	// if exponent is small, don't use exponential notation
	if (expo <= 0 && adjx >= -6) {
		return decimalForm!T(num);
	}
	if (!engineering) {
		return exponentForm!T(num, false, false);
	}
	// use exponential notation
	if (num.isZero) {
		adjx += 2;
	}
	int mod = adjx % 3;
	// the % operator rounds down; we need it to round to floor.
	if (mod < 0) {
		mod = -(mod + 3);
	}
	int dot = std.math.abs(mod) + 1;
	adjx = adjx - dot + 1;
	if (num.isZero) {
		dot = 1;
		clen = 3 - std.math.abs(mod);
		cstr.length = 0;
		for(int i = 0; i < clen; i++) {
			cstr ~= '0';
		}
	}
	while(dot > clen) {
		cstr ~= '0';
		clen++;
	}
	if (clen > dot) {
		insertInPlace(cstr, dot, ".");
	}
	string str = cstr.idup;
	if (adjx != 0) {
		string xstr = to!string(adjx);
		if (adjx > 0) {
			xstr = '+' ~ xstr;
		}
		str = str ~ "E" ~ xstr;
	}
	return sign ? "-" ~ str : str;
}  // end stdForm

unittest {
	Dec32 num = Dec32(123); //(false, 123, 0);
	assertTrue(sciForm!Dec32(num) == "123");
	assertTrue(num.toAbstract() == "[0,123,0]");
	num = Dec32(-123, 0);
	assertTrue(sciForm!Dec32(num) == "-123");
	assertTrue(num.toAbstract() == "[1,123,0]");
	num = Dec32(123, 1);
	assertTrue(sciForm!Dec32(num) == "1.23E+3");
	assertTrue(num.toAbstract() == "[0,123,1]");
	num = Dec32(123, 3);
	assertTrue(sciForm!Dec32(num) == "1.23E+5");
	assertTrue(num.toAbstract() == "[0,123,3]");
	num = Dec32(123, -1);
	assertTrue(sciForm!Dec32(num) == "12.3");
	assertTrue(num.toAbstract() == "[0,123,-1]");
	num = Dec32("inf");
	assertTrue(sciForm!Dec32(num) == "Infinity");
	assertTrue(num.toAbstract() == "[0,inf]");
	string str = "1.23E+3";
	BigDecimal dec = BigDecimal(str);
	assertTrue(engForm!BigDecimal(dec) == str);
	str = "123E+3";
	dec = BigDecimal(str);
	assertTrue(engForm!BigDecimal(dec) == str);
	str = "12.3E-9";
	dec = BigDecimal(str);
	assertTrue(engForm!BigDecimal(dec) == str);
	str = "-123E-12";
	dec = BigDecimal(str);
	assertTrue(engForm!BigDecimal(dec) == str);
}

public string toString(T)(const T num, string fmt) {
	return "surprise!";
}

/// toString(num, width, precision, expo)
public string toString(T)(const T num, const char formatChar,
	const int precision, const int width,
	const bool exponential) if (isDecimal!T) {

	bool lowerCase = std.uni.isLower(formatChar);
	bool upperCase = std.uni.isUpper(formatChar);

	// special values
	if (num.isSpecial) {
		return toSpecialString!T(num, false, lowerCase, upperCase);
	}

	string str;
	switch (formatChar) {
		case "": str = toSciString(num);
			break;
		case "E":
		case "e":
			str = exponentForm(num, precision, lowerCase, true);
			break;
		case "F":
		case "f":
			str = decimalForm(num, precision);
			break;
		case "G":
		case "g":
			str = exponentForm(num, lowerCase, true);
			break;
		default: str = toSciString(num);
			break;
	}

	// finite numbers
	auto mant = num.coefficient;
	auto expo = num.exponent;
	auto sign = num.isSigned;

	string temp = to!string(mant);
	char[] cstr = temp.dup;
	int clen = cstr.length;
	int adjx = expo + clen - 1;

	string str = exponentForm(num);
	return sign ? "-" ~ str : str;

	// placeholder
	return num.toExact;
}

/// Converts a decimal number to exponential notation.
//private string exponentForm(T)
//		(const string mant, const int expo,
//		const bool lowerCase = false, const bool padExpo = false)
//		if (isDecimal!T) {
//
//	char[] cstr = mant.dup;
//	int adjx = expo + cstr.length - 1;
//	// use exponential notation
//	if (cstr.length > 1) {
//		insertInPlace(cstr, 1, ".");
//	}
//	string xstr = to!string(std.math.abs(adjx));
//	if (padExpo && xstr.length < 2) {
//		xstr = prefix(xstr, "0");
//	}
//	xstr = adjx < 0 ? "-" ~ xstr : "+" ~ xstr;
//	string expoChar = lowerCase ? "e" : "E";
//	string str = (cstr ~ expoChar ~ xstr).idup;
//	return str;
//}  // end exponentForm

private string prefix(string str, string prefixChar) {
	if (prefixChar == "") return str;
	return prefixChar ~ str;
}

unittest {
	write("prefix....");
	string str, expect, actual;
	str = "100.54";
	expect = "100.54";
	actual = prefix(str, "");
	assertEqual(expect, actual);
	assert(expect is actual);
	expect = "-100.54";
	actual = prefix(str, "-");
	assertEqual(expect, actual);
	expect = " 100.54";
	actual = prefix(str, " ");
	assertEqual(expect, actual);
	expect = "+100.54";
	actual = prefix(str, "+");
	assertEqual(expect, actual);
	writeln("passed");
}

private string toWidth(string str, const int minWidth, const char fillChar = ' ') {
	if (str.length >= std.math.abs(minWidth)) return str;
	bool toLeft = false;
	int width = minWidth;
	if (width < 0) {
		toLeft = true;
		width = -width;
	}
	if (toLeft) {
		return leftJustify!string(str, width, fillChar);
	}
	return rightJustify!string(str, width, fillChar);
}

unittest {
	write("toWidth...");
	string str, expect, actual;
	str = "10E+05";
	expect = "  10E+05";
	actual = toWidth(str, 8);
	assertEqual(expect, actual);
	expect = "10E+05  ";
	actual = toWidth(str, -8);
	assertEqual(expect, actual);
	expect = "0010E+05";
	actual = toWidth(str, 8, '0');
	assertEqual(expect, actual);
	writeln("passed");
}

// (V)TODO: Doesn't work yet, returns scientific string.
/// Converts a BigDecimal number to a string representation.
public string writeTo(T) (const T num, const string fmt = "") if (isDecimal!T) {
	auto mant = num.coefficient;
	int  expo = num.exponent;
	bool signed = num.isSigned;
	// string representation of special values
	if (num.isSpecial) {
		string str;
		if (num.isInfinite) {
			str = "Infinity";
		} else if (num.isSignaling) {
			str = "sNaN";
		} else {
			str = "NaN";
		}
		// add payload to NaN, if present
		if (num.isNaN && num.payload != 0) {
			str ~= to!string(num.payload);
		}
		// add sign, if present
		return signed ? "-" ~ str : str;
	}
	// string representation of finite numbers
	string temp = to!string(mant);
	char[] cstr = temp.dup;
	int clen = cstr.length;
	int adjx = expo + clen - 1;
	// if exponent is small, don't use exponential notation
	if (expo <= 0 && adjx >= -6) {
		// if exponent is not zero, insert a decimal point
		if (expo != 0) {
			int point = std.math.abs(expo);
			// if coefficient is too small, pad with zeroes
			if (point > clen) {
				cstr = rightJustify(cstr, point, '0');
				clen = cstr.length;
			}
			// if no chars precede the decimal point, prefix a zero
			if (point == clen) {
				cstr = "0." ~ cstr;
			}
			// otherwise insert a decimal point
			else {
				insertInPlace(cstr, cstr.length - point, ".");
			}
		}
		return signed ? ("-" ~ cstr).idup : cstr.idup;
	}
	if (engineering) {
		// use exponential notation
		if (num.isZero) {
			adjx += 2;
		}
		int mod = adjx % 3;
		// the % operator rounds down; we need it to round to floor.
		if (mod < 0) {
			mod = -(mod + 3);
		}
		int dot = std.math.abs(mod) + 1;
		adjx = adjx - dot + 1;
		if (num.isZero) {
			dot = 1;
			clen = 3 - std.math.abs(mod);
			cstr.length = 0;
			for(int i = 0; i < clen; i++) {
				cstr ~= '0';
			}
		}
		while(dot > clen) {
			cstr ~= '0';
			clen++;
		}
		if (clen > dot) {
			insertInPlace(cstr, dot, ".");
		}
		string str = cstr.idup;
		if (adjx != 0) {
			string xstr = to!string(adjx);
			if (adjx > 0) {
				xstr = '+' ~ xstr;
			}
			str = str ~ "E" ~ xstr;
		}
		return signed ? "-" ~ str : str;
	} else {
		// use exponential notation
		if (clen > 1) {
			insertInPlace(cstr, 1, ".");
		}
		string xstr = to!string(adjx);
		if (adjx >= 0) {
			xstr = "+" ~ xstr;
		}
		string str = (cstr ~ "E" ~ xstr).idup;
		return signed ? "-" ~ str : str;
	}
};  // end writeTo

unittest {
	write("writeTo...");
	writeln("test missing");
}

/// Converts a string into a BigDecimal.
public BigDecimal toNumber(const string inStr) {
	BigDecimal num;
	BigDecimal NAN = BigDecimal.nan;
	bool sign = false;
	// strip, copy, tolower
	char[] str = strip(inStr).dup;
	toLowerInPlace(str);
	// get sign, if any
	if (startsWith(str, "-")) {
		sign = true;
		str = str[1..$];
	} else if (startsWith(str, "+")) {
		str = str[1..$];
	}
	// check for NaN
	if (startsWith(str, "nan")) {
		num = NAN;
		num.sign = sign;
		// if no payload, return
		if (str == "nan") {
			return num;
		}
		// set payload
		str = str[3..$];
		// payload has a max length of 6 digits
		if (str.length > 6) return NAN;
		// ensure string is all digits
		foreach(char c; str) {
			if (!isDigit(c)) {
				return NAN;
			}
		}
		// convert string to number
		uint payload = std.conv.to!uint(str);
		// check for overflow
		if (payload > ushort.max) {
			return NAN;
		}
		num.payload = cast(ushort)payload;
		return num;
	};
	// check for sNaN
	if (startsWith(str, "snan")) {
		num = BigDecimal.snan;
		num.sign = sign;
		if (str == "snan") {
			num.payload = 0;
			return num;
		}
		// set payload
		str = str[4..$];
		// payload has a max length of 6 digits
		if (str.length > 6) return NAN;
		// ensure string is all digits
		foreach(char c; str) {
			if (!isDigit(c)) {
				return NAN;
			}
		}
		// convert string to payload
		uint payload = std.conv.to!uint(str);
		// check for overflow
		if (payload > ushort.max) {
			return NAN;
		}
		num.payload = cast(ushort)payload;
		return num;
	};
	// check for infinity
	if (str == "inf" || str == "infinity") {
		num = BigDecimal.infinity(sign);
		return num;
	};
	// at this point, num must be finite
	num = BigDecimal.zero(sign);
	// check for exponent
	int pos = indexOf(str, 'e');
	if (pos > 0) {
		// if it's just a trailing 'e', return NaN
		if (pos == str.length - 1) {
			return NAN;
		}
		// split the string into coefficient and exponent
		char[] xstr = str[pos + 1..$];
		str = str[0..pos];
		// assume exponent is positive
		bool xneg = false;
		// check for minus sign
		if (startsWith(xstr, "-")) {
			xneg = true;
			xstr = xstr[1..$];
		}
		// check for plus sign
		else if (startsWith(xstr, "+")) {
			xstr = xstr[1..$];
		}
		// ensure it's not now empty
		if (xstr.length < 1) {
			return NAN;
		}
		// ensure exponent is all digits
		foreach(char c; xstr) {
			if (!isDigit(c)) {
				return NAN;
			}
		}
		// trim leading zeros
		while(xstr[0] == '0' && xstr.length > 1) {
			xstr = xstr[1..$];
		}
		// make sure it will fit into an int
		if (xstr.length > 10) {
			return NAN;
		}
		if (xstr.length == 10) {
			// try to convert it to a long (should work) and
			// then see if the long value is too big (or small)
			long lex = std.conv.to!long(xstr);
			if ((xneg && (-lex < int.min)) || lex > int.max) {
				return NAN;
			}
			num.exponent = cast(int) lex;
		} else {
			// everything should be copacetic at this point
			num.exponent = std.conv.to!int(xstr);
		}
		if (xneg) {
			num.exponent = -num.exponent;
		}
	} else {
		num.exponent = 0;
	}
	// remove trailing decimal point
	if (endsWith(str, ".")) {
		str = str[0..$ -1];
	}
	// strip leading zeros
	while(str[0] == '0' && str.length > 1) {
		str = str[1..$];
	}
	// remove internal decimal point
	int point = indexOf(str, '.');
	if (point >= 0) {
		// excise the point and adjust the exponent
		str = str[0..point] ~ str[point + 1..$];
		int diff = str.length - point;
		num.exponent = num.exponent - diff;
	}
	// ensure string is not empty
	if (str.length < 1) {
		return NAN;
	}
	// ensure string is all digits
	foreach(char c; str) {
		if (!isDigit(c)) {
			return NAN;
		}
	}
	// convert coefficient string to BigInt
	num.coefficient = BigInt(str.idup);
	num.digits = decimal.rounding.numDigits(num.coefficient);
	return num;
}

unittest {
	BigDecimal f = BigDecimal("1.0");
	assertTrue(f.toString() == "1.0");
	f = BigDecimal(".1");
	assertTrue(f.toString() == "0.1");
	f = BigDecimal("-123");
	assertTrue(f.toString() == "-123");
	f = BigDecimal("1.23E3");
	assertTrue(f.toString() == "1.23E+3");
	f = BigDecimal("1.23E-3");
	assertTrue(f.toString() == "0.00123");
}

/// Returns an abstract string representation of a number.
/// The abstract representation is described in the specification. (p. 9-12)
public string toAbstract(T)(const T num) if (isDecimal!T) {
	if (num.isFinite) {
		return format("[%d,%s,%d]", num.sign ? 1 : 0,
		              to!string(num.coefficient), num.exponent);
	}
	if (num.isInfinite) {
		return format("[%d,%s]", num.sign ? 1 : 0, "inf");
	}
	if (num.isQuiet) {
		if (num.payload) {
			return format("[%d,%s%d]", num.sign ? 1 : 0, "qNaN", num.payload);
		}
		return format("[%d,%s]", num.sign ? 1 : 0, "qNaN");
	}
	if (num.isSignaling) {
		if (num.payload) {
			return format("[%d,%s%d]", num.sign ? 1 : 0, "sNaN", num.payload);
		}
		return format("[%d,%s]", num.sign ? 1 : 0, "sNaN");
	}
	return "[0,qNAN]";
}

unittest {
	write("toAbstract...");
	writeln("test missing");
}

// (V)TODO: Does exact representation really return a round-trip value?
/// Returns a full, exact representation of a number. Similar to toAbstract,
/// but it provides a valid string that can be converted back into a number.
public string toExact(T)(const T num) if (isDecimal!T) {
	if (num.isFinite) {
		return format("%s%sE%s%02d", num.sign ? "-" : "+",
		              to!string(num.coefficient),
		              num.exponent < 0 ? "-" : "+", num.exponent);
	}
	if (num.isInfinite) {
		return format("%s%s", num.sign ? "-" : "+", "Infinity");
	}
	if (num.isQuiet) {
		if (num.payload) {
			return format("%s%s%d", num.sign ? "-" : "+", "NaN", num.payload);
		}
		return format("%s%s", num.sign ? "-" : "+", "NaN");
	}
	if (num.isSignaling) {
		if (num.payload) {
			return format("%s%s%d", num.sign ? "-" : "+", "sNaN", num.payload);
		}
		return format("%s%s", num.sign ? "-" : "+", "sNaN");
	}
	return "+NaN";
}

unittest {
	write("toExact...");
	writeln("test missing");
}

unittest {
	writeln("===================");
	writeln("conv............end");
	writeln("===================");
}


