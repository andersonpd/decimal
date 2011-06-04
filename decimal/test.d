module decimal.test;

import decimal.context: INVALID_OPERATION;
import decimal.digits;
import decimal.decimal;
import decimal.arithmetic;
import decimal.math;
import std.bigint;
import std.stdio: write, writeln;
import std.string;

alias Decimal.context.precision precision;

//--------------------------------
// unit test methods
//--------------------------------

template Test(T) {
	bool isEqual(T)(T actual, T expected, string label, string message = "") {
		bool equal = (expected == actual);
		if (!equal) {
			writeln("Test ", label, ": Expected [", expected, "] but found [", actual, "]. ", message);
		}
		return equal;
	}
}


//--------------------------------
// unit tests
//--------------------------------

unittest {
	writeln();
	writeln("-------------------");
	writeln("testing......digits");
	writeln("-------------------");
	writeln();
}

unittest {
	bool passed = true;
	long n = 12345;
	Test!(long).isEqual(lastDigit(n), 5, "digits 1");
	Test!(long).isEqual(numDigits(n), 5, "digits 2");
	Test!(long).isEqual(firstDigit(n), 1, "digits 3");
	Test!(long).isEqual(firstDigit(n), 8, "digits 4");
	BigInt big = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678905");
	Test!(long).isEqual(lastDigit(big), 5, "digits 5");
	Test!(long).isEqual(numDigits(big), 101, "digits 6");
	Test!(long).isEqual(numDigits(big), 22, "digits 7");
	Test!(long).isEqual(firstDigit(n), 1, "digits 8");
//	assert(lastDigit(big) == 5);
//	assert(numDigits(big) == 101);
//	assert(firstDigit(big) == 1);
	writeln("Digits tested");
}

unittest {
	writeln();
	writeln("-------------------");
	writeln("testing.....Decimal");
	writeln("-------------------");
	writeln();
}

unittest {
	write("construction.");
//	writeln("I can still write");
	Decimal f = Decimal(1234L, 567);
//	writeln("f = ", f.toAbstract);
//	Test!(string).isEqual("1.234E+570", f.toString, "Con 1");
//	assert(f.toString() == "1.234E+570");
	f = Decimal(1234, 567);
//	writeln("f = ", f.toAbstract);
//	writeln("I can still write");
	assert(f.toString() == "1.234E+570");
	f = Decimal(1234L);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "1234");
	f = Decimal(123400L);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "123400");
	f = Decimal(1234L);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "1234");
	f = Decimal(1234, 0, 9);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "1234.00000");
	f = Decimal(1234, 1, 9);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "12340.0000");
	f = Decimal(12, 1, 9);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "120.000000");
	f = Decimal(int.max, -4, 9);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "214748.365");
	f = Decimal(int.max, -4);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "214748.3647");
	f = Decimal(1234567, -2, 5);
//	writeln("f = ", f.toAbstract);
	assert(f.toString() == "12346");
	writeln("passed");
}

unittest {
	write("invalid......");
	Decimal dcm;
	Decimal expd;
	Decimal actual;

	dcm = "sNaN123";
	expd = "NaN123";
	actual = abs(dcm);
	assert(actual.isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	assert(actual.toAbstract == expd.toAbstract);
	dcm = "NaN123";
	actual = abs(dcm);
	assert(actual.isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	assert(actual.toAbstract == expd.toAbstract);

	dcm = "sNaN123";
	expd = "NaN123";
	actual = -dcm;
	assert(actual.isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	assert(actual.toAbstract == expd.toAbstract);
	dcm = "NaN123";
	actual = -dcm;
	assert(actual.isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	assert(actual.toAbstract == expd.toAbstract);
	writeln("passed");
}

unittest {
	write("equals.......");
	Decimal op1;
	Decimal op2;
	op1 = "NaN";
	op2 = "NaN";
	assert(op1 != op2);
	op1 = "inf";
	op2 = "inf";
	assert(op1 == op2);
	op2 = "-inf";
	assert(op1 != op2);
	op1 = "-inf";
	assert(op1 == op2);
	op2 = "NaN";
	assert(op1 != op2);
	op1 = 0;
	assert(op1 != op2);
	op2 = 0;
	assert(op1 == op2);
	writeln("passed");
}

/*unittest{
	write("overflow.....");
	Decimal dec = Decimal(123, 99);
	assert(overflow(dec));
	dec = Decimal(12, 99);
	assert(overflow(dec));
	dec = Decimal(1, 99);
	assert(!overflow(dec));
	dec = Decimal(9, 99);
	assert(!overflow(dec));
	writeln("passed");
}*/

unittest {
	writeln("-------------------");
	write("to-number....");
	Decimal f;
	string str = "0";
	f = str;
	assert(f.toString() == str);
	assert(f.toAbstract() == "[0,0,0]");
	str = "0.00";
	f = str;
	assert(f.toString() == str);
	assert(f.toAbstract() == "[0,0,-2]");
	str = "0.0";
	f = str;
	assert(f.toString() == str);
	assert(f.toAbstract() == "[0,0,-1]");
	f = "0.";
	assert(f.toString() == "0");
	assert(f.toAbstract() == "[0,0,0]");
	f = ".0";
	assert(f.toString() == "0.0");
	assert(f.toAbstract() == "[0,0,-1]");
	str = "1.0";
	f = str;
	assert(f.toString() == str);
	assert(f.toAbstract() == "[0,10,-1]");
	str = "1.";
	f = str;
	assert(f.toString() == "1");
	assert(f.toAbstract() == "[0,1,0]");
	str = ".1";
	f = str;
	assert(f.toString() == "0.1");
	assert(f.toAbstract() == "[0,1,-1]");
	f = Decimal("123");
	assert(f.toString() == "123");
	f = Decimal("-123");
	assert(f.toString() == "-123");
	f = Decimal("1.23E3");
	assert(f.toString() == "1.23E+3");
	f = Decimal("1.23E");
	assert(f.toString() == "NaN");
	f = Decimal("1.23E-");
	assert(f.toString() == "NaN");
	f = Decimal("1.23E+");
	assert(f.toString() == "NaN");
	f = Decimal("1.23E+3");
	assert(f.toString() == "1.23E+3");
	f = Decimal("1.23E3B");
	assert(f.toString() == "NaN");
	f = Decimal("12.3E+007");
	assert(f.toString() == "1.23E+8");
	f = Decimal("12.3E+70000000000");
	assert(f.toString() == "NaN");
	f = Decimal("12.3E+7000000000");
	assert(f.toString() == "NaN");
	f = Decimal("12.3E+700000000");
	assert(f.toString() == "1.23E+700000001");
	f = Decimal("12.3E-700000000");
	assert(f.toString() == "1.23E-699999999");
	// NOTE: since there will still be adjustments -- maybe limit to 99999999?
	f = Decimal("12.0");
	assert(f.toString() == "12.0");
	f = Decimal("12.3");
	assert(f.toString() == "12.3");
	f = Decimal("1.23E-3");
	assert(f.toString() == "0.00123");
	f = Decimal("0.00123");
	assert(f.toString() == "0.00123");
	f = Decimal("-1.23E-12");
	assert(f.toString() == "-1.23E-12");
	f = Decimal("-0");
	assert(f.toString() == "-0");
	f = Decimal("inf");
	assert(f.toString() == "Infinity");
	f = Decimal("NaN");
	assert(f.toString() == "NaN");
	f = Decimal("-NaN");
	assert(f.toString() == "-NaN");
	f = Decimal("sNaN");
	assert(f.toString() == "sNaN");
	f = Decimal("Fred");
	assert(f.toString() == "NaN");
	writeln("passed");
}

unittest {
	write("to-sci-str...");
	Decimal dec = Decimal(123); //(false, 123, 0);
//	writeln("dec = ", dec);
//	writeln("dec = ", dec.toAbstract);
	assert(dec.toString() == "123");
	assert(dec.toString() == "123");
	assert(dec.toAbstract() == "[0,123,0]");
	dec = Decimal(-123, 0);
	assert(dec.toString() == "-123");
	assert(dec.toAbstract() == "[1,123,0]");
	dec = Decimal(123, 1);
	assert(dec.toString() == "1.23E+3");
	assert(dec.toAbstract() == "[0,123,1]");
	dec = Decimal(123, 3);
	assert(dec.toString() == "1.23E+5");
	assert(dec.toAbstract() == "[0,123,3]");
	dec = Decimal(123, -1);
	assert(dec.toString() == "12.3");
	assert(dec.toAbstract() == "[0,123,-1]");
	dec = Decimal(123, -5);
	assert(dec.toString() == "0.00123");
	assert(dec.toAbstract() == "[0,123,-5]");
	dec = Decimal(123, -10);
	assert(dec.toString() == "1.23E-8");
	assert(dec.toAbstract() == "[0,123,-10]");
	dec = Decimal(-123, -12);
	assert(dec.toString() == "-1.23E-10");
	assert(dec.toAbstract() == "[1,123,-12]");
	dec = Decimal(0, 0);
	assert(dec.toString() == "0");
	assert(dec.toAbstract() == "[0,0,0]");
	dec = Decimal(0, -2);
	assert(dec.toString() == "0.00");
	assert(dec.toAbstract() == "[0,0,-2]");
	dec = Decimal(0, 2);
	assert(dec.toString() == "0E+2");
	assert(dec.toAbstract() == "[0,0,2]");
	dec = -Decimal(0, 0);
	assert(dec.toString() == "-0");
	assert(dec.toAbstract() == "[1,0,0]");
	dec = Decimal(5, -6);
	assert(dec.toString() == "0.000005");
	assert(dec.toAbstract() == "[0,5,-6]");
	dec = Decimal(50,-7);
	assert(dec.toString() == "0.0000050");
	assert(dec.toAbstract() == "[0,50,-7]");
	dec = Decimal(5, -7);
	assert(dec.toString() == "5E-7");
	assert(dec.toAbstract() == "[0,5,-7]");
	dec = Decimal("inf");
	assert(dec.toString() == "Infinity");
	assert(dec.toAbstract() == "[0,inf]");
	dec = Decimal(true, "inf");
	assert(dec.toString() == "-Infinity");
	assert(dec.toAbstract() == "[1,inf]");
	dec = Decimal(false, "NaN");
	assert(dec.toString() == "NaN");
	assert(dec.toAbstract() == "[0,qNaN]");
	dec = Decimal(false, "NaN", 123);
	assert(dec.toString() == "NaN123");
	assert(dec.toAbstract() == "[0,qNaN,123]");
	dec = Decimal(true, "sNaN");
	assert(dec.toString() == "-sNaN");
	assert(dec.toAbstract() == "[1,sNaN]");
	writeln("passed");
}

unittest {
	// TODO: add rounding tests
	writeln("-------------------");
	write("abs..........");
	Decimal dcm;
	Decimal expd;
	dcm = "sNaN";
	assert(abs(dcm).isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	dcm = "NaN";
	assert(abs(dcm).isQuiet);
	assert(context.getFlag(INVALID_OPERATION));
	dcm = "Inf";
	expd = "Inf";
	assert(abs(dcm) == expd);
	dcm = "-Inf";
	expd = "Inf";
	assert(abs(dcm) == expd);
	dcm = "0";
	expd = "0";
	assert(abs(dcm) == expd);
	dcm = "-0";
	expd = "0";
	assert(abs(dcm) == expd);
	dcm = "2.1";
//	writeln("dcm.toAbstract = ", dcm.toAbstract);
//	writeln("dcm.digits = ", dcm.digits);
	expd = "2.1";
//	writeln("expd.toAbstract = ", expd.toAbstract);
//	writeln("expd.digits = ", expd.digits);
//	writeln("abs(dcm).toAbstract = ", abs(dcm).toAbstract);
//	writeln("abs(dcm).digits = ", abs(dcm).digits);
	assert(abs(dcm) == expd);
	dcm = -100;
	expd = 100;
	assert(abs(dcm) == expd);
	dcm = 101.5;
	expd = 101.5;
	assert(abs(dcm) == expd);
	dcm = -101.5;
	assert(abs(dcm) == expd);
	writeln("passed");
}

// TODO: these tests need to be cleaned up to rely less on strings
// and to check the NaN, Inf combinations better.
unittest {
	write("add/subtract.");
	Decimal dcm1 = Decimal("12");
	Decimal dcm2 = Decimal("7.00");
	Decimal sum = add(dcm1, dcm2);
	assert(sum.toString() == "19.00");
	dcm1 = Decimal("1E+2");
	dcm2 = Decimal("1E+4");
	sum = add(dcm1, dcm2);
	assert(sum.toString() == "1.01E+4");
	dcm1 = Decimal("1.3");
	dcm2 = Decimal("1.07");
	sum = subtract(dcm1, dcm2);
	assert(sum.toString() == "0.23");
	dcm2 = Decimal("1.30");
	sum = subtract(dcm1, dcm2);
	assert(sum.toString() == "0.00");
	dcm2 = Decimal("2.07");
	sum = subtract(dcm1, dcm2);
	assert(sum.toString() == "-0.77");
	dcm1 = "Inf";
	dcm2 = 1;
	sum = add(dcm1, dcm2);
	assert(sum.toString() == "Infinity");
	dcm1 = "NaN";
	dcm2 = 1;
	sum = add(dcm1, dcm2);
	assert(sum.isQuiet);
	dcm2 = "Infinity";
	sum = add(dcm1, dcm2);
	assert(sum.isQuiet);
	dcm1 = 1;
	sum = subtract(dcm1, dcm2);
	assert(sum.toString() == "-Infinity");
	dcm1 = "-0";
	dcm2 = 0;
	sum = subtract(dcm1, dcm2);
	assert(sum.toString() == "-0");
	writeln("passed");
}

unittest {
	write("compare......");
	Decimal op1;
	Decimal op2;
	int result;
	op1 = "2.1";
	op2 = "3";
	result = compare(op1, op2);
	assert(result == -1);
	op1 = "2.1";
	op2 = "2.1";
	result = compare(op1, op2);
	assert(result == 0);
	op1 = "2.1";
	op2 = "2.10";
	result = compare(op1, op2);
	assert(result == 0);
	op1 = "3";
	op2 = "2.1";
	result = compare(op1, op2);
	assert(result == 1);
	op1 = "2.1";
	op2 = "-3";
	result = compare(op1, op2);
	assert(result == 1);
	op1 = "-3";
	op2 = "2.1";
	result = compare(op1, op2);
	assert(result == -1);
	op1 = -3;
	op2 = -4;
	result = compare(op1, op2);
	assert(result == 1);
	op1 = -300;
	op2 = -4;
	result = compare(op1, op2);
	assert(result == -1);
	op1 = 3;
	op2 = Decimal.max;
	result = compare(op1, op2);
	assert(result == -1);
	op1 = -3;
	op2 = copyNegate(Decimal.max);
	result = compare(op1, op2);
	assert(result == 1);

	writeln("passed");
}

unittest {
	write("divide.......");
	Decimal dcm1, dcm2;
	Decimal expd;
	dcm1 = 1;
	dcm2 = 3;
	// TODO: why are some of these divide?
	context.precision = 9;
	Decimal quotient = divide(dcm1, dcm2);
	expd = "0.333333333";
//	writeln("quotient = ", quotient);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = 2;
	dcm2 = 3;
	quotient = divide(dcm1, dcm2);
	expd = "0.666666667";
//	assert(false);
	assert(quotient == expd);
	dcm1 = 5;
	dcm2 = 2;
	quotient = divide(dcm1, dcm2);
	expd = "2.5";
//	writeln("expd = ", expd, " = ", expd.toAbstract);
//	writeln("quotient = ", quotient, " = ", quotient.toAbstract);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = 1;
	dcm2 = 10;
	expd = 0.1;
	quotient = divide(dcm1, dcm2);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = "8.00";
	dcm2 = 2;
	expd = "4.00";
	quotient = divide(dcm1, dcm2);
//	writeln("expd = ", expd, " = ", expd.toAbstract);
//	writeln("quotient = ", quotient, " = ", quotient.toAbstract);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = "2.400";
	dcm2 = "2.0";
	expd = "1.20";
	quotient = divide(dcm1, dcm2);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = 1000;
	dcm2 = 100;
	expd = 10;
	quotient = divide(dcm1, dcm2);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm2 = 1;
	quotient = divide(dcm1, dcm2);
	expd = 1000;
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	dcm1 = "2.40E+6";
	dcm2 = 2;
	expd = "1.20E+6";
	quotient = divide(dcm1, dcm2);
	assert(quotient == expd);
	assert(quotient.toString() == expd.toString());
	writeln("passed");
}

unittest {
	write("div-int......");
	Decimal dividend;
	Decimal divisor;
	Decimal quotient;
	Decimal expd;
	dividend = 2;
	divisor = 3;
	quotient = divideInteger(dividend, divisor);
	expd = 0;
	assert(quotient == expd);
	dividend = 10;
	quotient = divideInteger(dividend, divisor);
	expd = 3;
	assert(quotient == expd);
	dividend = 1;
	divisor = "0.3";
	quotient = divideInteger(dividend, divisor);
	assert(quotient == expd);
	writeln("passed");
}

unittest {
	write("fma..........");
	Decimal op1;
	Decimal op2;
	Decimal op3;
	Decimal result;
	op1 = 3;
	op2 = 5;
	op3 = 7;
	result = (fma(op1, op2, op3));
	assert(result == Decimal(22));
	op1 = 3;
	op2 = -5;
	op3 = 7;
	result = (fma(op1, op2, op3));
	assert(result == Decimal(-8));
	op1 = "888565290";
	op2 = "1557.96930";
	op3 = "-86087.7578";
	result = (fma(op1, op2, op3));
	assert(result == Decimal("1.38435736E+12"));
	writeln("passed");
}

unittest {
	write("max..........");
	Decimal op1;
	Decimal op2;
	op1 = 3;
	op2 = 2;
	assert(max(op1, op2) == op1);
	op1 = -10;
	op2 = 3;
	assert(max(op1, op2) == op2);
	op1 = "1.0";
	op2 = "1";
	assert(max(op1, op2) == op2);
	op1 = "7";
	op2 = "NaN";
	assert(max(op1, op2) == op1);
	writeln("passed");
}

unittest {
	write("min..........");
	Decimal op1;
	Decimal op2;
	op1 = 3;
	op2 = 2;
	assert(min(op1, op2) == op2);
	op1 = -10;
	op2 = 3;
	assert(min(op1, op2) == op1);
	op1 = "1.0";
	op2 = "1";
	assert(min(op1, op2) == op1);
	op1 = "7";
	op2 = "NaN";
	assert(min(op1, op2) == op1);
	writeln("passed");
}

unittest {
	write("minus/plus...");
	// NOTE: result should equal 0+this or 0-this
	Decimal zero = Decimal(0);
	Decimal dcm;
	Decimal expd;
	dcm = "1.3";
	expd = zero + dcm;
	assert(+dcm == expd);
	dcm = "-1.3";
	expd = zero + dcm;
	assert(+dcm == expd);
	dcm = "1.3";
	expd = zero - dcm;
	assert(-dcm == expd);
	dcm = "-1.3";
	expd = zero - dcm;
	assert(-dcm == expd);
	// TODO: add tests that check flags.
	writeln("passed");
}

unittest {
	write("multiply.....");
	Decimal op1, op2, result;
	op1 = Decimal("1.20");
	op2 = 3;
	result = op1 * op2;
	assert(result.toString() == "3.60");
	op1 = 7;
	result = op1 * op2;
	assert(result.toString() == "21");
	op1 = Decimal("0.9");
	op2 = Decimal("0.8");
	result = op1 * op2;
	assert(result.toString() == "0.72");
	op1 = Decimal("0.9");
	op2 = Decimal("-0.0");
	result = op1 * op2;
	assert(result.toString() == "-0.00");
	op1 = Decimal(654321);
	op2 = Decimal(654321);
	result = op1 * op2;
	assert(result.toString() == "4.28135971E+11");
	op1 = -1;
	op2 = "Infinity";
	result = op1 * op2;
	assert(result.toString() == "-Infinity");
	op1 = -1;
	op2 = 0;
	result = op1 * op2;
	assert(result.toString() == "-0");
	writeln("passed");
}

unittest {
	write("next-plus....");
	pushPrecision;
	int savedMin = context.eMin;
	int savedMax = context.eMax;
	context.eMax = 999;
	context.eMin = -999;
	Decimal dcm;
	Decimal expd;
	dcm = 1;
	expd = "1.00000001";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	dcm = 10;
	expd = "10.0000001";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	dcm = 1E5;
	expd = "100000.001";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	dcm = 1E8;
	expd = "100000001";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	// num digits exceeds precision...
	dcm = "1234567891";
	expd = "1.23456790E9";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	// result < tiny
	dcm = "-1E-1007";
	expd = "-0E-1007";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	dcm = "-1.00000003";
	expd = "-1.00000002";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	dcm = "-Infinity";
	expd = "-9.99999999E+999";
//	writeln("expd = ", expd);
	assert(nextPlus(dcm) == expd);
	popPrecision;
	context.eMin = savedMin;
	context.eMax = savedMax;
	writeln("passed");
}

unittest {
	write("next-minus...");
	int savedMin = context.eMin;
	int savedMax = context.eMax;
	context.eMin = -999;
	context.eMax = 999;
	Decimal dcm;
	Decimal expd;
	dcm = 1;
	expd = "0.999999999";
	assert(nextMinus(dcm) == expd);
	dcm = "1E-1007";
	expd = "0E-1007";
	assert(nextMinus(dcm) == expd);
	dcm = "-1.00000003";
	expd = "-1.00000004";
	assert(nextMinus(dcm) == expd);
	dcm = "Infinity";
	expd = "9.99999999E+999";
//	writeln("dcm = ", dcm);
//	writeln("expd = ", expd);
//	writeln("nextMinus(dcm) = ", nextMinus(dcm));
	assert(nextMinus(dcm) == expd);
	context.eMin = savedMin;
	context.eMax = savedMax;
	writeln("passed");
}

unittest {
	write("next-toward..");
	Decimal dcm1, dcm2;
	Decimal expd;
	dcm1 = 1;
	dcm2 = 2;
	expd = "1.00000001";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = "-1E-1007";
	dcm2 = 1;
	expd = "-0E-1007";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = "-1.00000003";
	dcm2 = 0;
	expd = "-1.00000002";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = 1;
	dcm2 = 0;
	expd = "0.999999999";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = "1E-1007";
	dcm2 = -100;
	expd = "0E-1007";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = "-1.00000003";
	dcm2 = -10;
	expd = "-1.00000004";
	assert(nextToward(dcm1,dcm2) == expd);
	dcm1 = "0.00";
	dcm2 = "-0.0000";
	expd = "-0.00";
	assert(nextToward(dcm1,dcm2) == expd);
	writeln("passed");
}

unittest {
	write("quantize.....");
	Decimal op1;
	Decimal op2;
	Decimal result;
	Decimal expd;
	string str;
	op1 = "2.17";
	op2 = "0.001";
	expd = "2.170";
	result = quantize(op1, op2);
//	writeln("op1 = ", op1);
//	writeln("op2 = ", op2);
//	writeln("expd = ", expd);
//	writeln("qresult = ", result);
	assert(result == expd);
	op1 = "2.17";
	op2 = "0.01";
	expd = "2.17";
	result = quantize(op1, op2);
	assert(result == expd);
	op1 = "2.17";
	op2 = "0.1";
	expd = "2.2";
	result = quantize(op1, op2);
	assert(result == expd);
	op1 = "2.17";
	op2 = "1e+0";
	expd = "2";
	result = quantize(op1, op2);
	assert(result == expd);
	op1 = "2.17";
	op2 = "1e+1";
	expd = "0E+1";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "-Inf";
	op2 = "Infinity";
	expd = "-Infinity";
	result = quantize(op1, op2);
	assert(result == expd);
	op1 = "2";
	op2 = "Infinity";
	expd = "NaN";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "-0.1";
	op2 = "1";
	expd = "-0";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "-0";
	op2 = "1e+5";
	expd = "-0E+5";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "+35236450.6";
	op2 = "1e-2";
	expd = "NaN";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "-35236450.6";
	op2 = "1e-2";
	expd = "NaN";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "217";
	op2 = "1e-1";
	expd = "217.0";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "217";
	op2 = "1e+0";
	expd = "217";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "217";
	op2 = "1e+1";
	expd = "2.2E+2";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	op1 = "217";
	op2 = "1e+2";
	expd = "2E+2";
	result = quantize(op1, op2);
	assert(result.toString() == expd.toString());
	assert(result == expd);
	writeln("passed");
}

unittest {
	write("reduce.......");
	Decimal dec;
	Decimal red;
	string str;
	dec = "2.1";
	str = "2.1";
	red = reduce(dec);
	assert(red.toString() == str);
	dec = "-2.0";
	str = "-2";
	red = reduce(dec);
	assert(red.toString() == str);
	dec = "1.200";
	str = "1.2";
	red = reduce(dec);
	assert(red.toString() == str);
	dec = "-120";
	str = "-1.2E+2";
	red = reduce(dec);
	assert(red.toString() == str);
	dec = "120.00";
	str = "1.2E+2";
	red = reduce(dec);
	assert(red.toString() == str);
	writeln("passed");
}

unittest {
	write("remainder....");
	Decimal dividend;
	Decimal divisor;
	Decimal quotient;
	Decimal expected;
	dividend = "2.1";
	divisor = 3;
	quotient = remainder(dividend, divisor);
	expected = "2.1";
	assert(quotient == expected);
	dividend = 10;
	quotient = remainder(dividend, divisor);
	expected = 1;
	assert(quotient == expected);
	dividend = -10;
	quotient = remainder(dividend, divisor);
	expected = -1;
	assert(quotient == expected);
	dividend = 10.2;
	divisor = 1;
	quotient = remainder(dividend, divisor);
	expected = "0.2";
	assert(quotient == expected);
	dividend = 10;
	divisor = 0.3;
	quotient = remainder(dividend, divisor);
	expected = "0.1";
	assert(quotient == expected);
	dividend = 3.6;
	divisor = 1.3;
	quotient = remainder(dividend, divisor);
	expected = "1.0";
	assert(quotient == expected);
	writeln("passed");
}

unittest {
	write("rnd-int-ex...");
	Decimal dec;
	Decimal expd;
	Decimal actual;
	dec = 2.1;
	expd = 2;
	actual = roundToIntegralExact(dec);
	assert(actual == expd);
	dec = 100;
	expd = 100;
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "100.0";
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "101.5";
	expd = 102;
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "-101.5";
	expd = -102;
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "10E+5";
	expd = "1.0E+6";
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "7.89E+77";
	expd = "7.89E+77";
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	dec = "-Inf";
	expd = "-Infinity";
	assert(roundToIntegralExact(dec) == expd);
	assert(roundToIntegralExact(dec).toString() == expd.toString());
	writeln("passed");
}

unittest {
	writeln("-------------");
	write("and..........");
	writeln("..failed");
}

unittest {
	write("canonical....");
	writeln("..failed");
}

unittest {
	write("class........");
	Decimal dcm;
	dcm = "Infinity";
	assert(classify(dcm) == "+Infinity");
	dcm = "1E-10";
	assert(classify(dcm) == "+Normal");
	dcm = "2.50";
	assert(classify(dcm) == "+Normal");
	dcm = "0.1E-99";
	assert(classify(dcm) == "+Subnormal");
	dcm = "0";
	assert(classify(dcm) == "+Zero");
	dcm = "-0";
	assert(classify(dcm) == "-Zero");
	dcm = "-0.1E-99";
	assert(classify(dcm) == "-Subnormal");
	dcm = "-1E-10";
	assert(classify(dcm) == "-Normal");
	dcm = "-2.50";
	assert(classify(dcm) == "-Normal");
	dcm = "-Infinity";
	assert(classify(dcm) == "-Infinity");
	dcm = "NaN";
	assert(classify(dcm) == "NaN");
	dcm = "-NaN";
	assert(classify(dcm) == "NaN");
	dcm = "sNaN";
	assert(classify(dcm) == "sNaN");
	writeln("passed");
}

unittest {
	write("comp-total...");
	Decimal op1;
	Decimal op2;
	int result;
	op1 = "12.73";
	op2 = "127.9";
	result = compareTotal(op1, op2);
	assert(result == -1);
	op1 = "-127";
	op2 = "12";
	result = compareTotal(op1, op2);
	assert(result == -1);
	op1 = "12.30";
	op2 = "12.3";
	result = compareTotal(op1, op2);
	assert(result == -1);
	op1 = "12.30";
	op2 = "12.30";
	result = compareTotal(op1, op2);
	assert(result == 0);
	op1 = "12.3";
	op2 = "12.300";
	result = compareTotal(op1, op2);
	assert(result == 1);
	op1 = "12.3";
	op2 = "NaN";
	result = compareTotal(op1, op2);
	assert(result == -1);
	writeln("passed");
}

// TODO: these should actually be compare-total assertions
// This is probably true of other unit tests as well
unittest {
	write("copy.........");
	Decimal dcm;
	Decimal expd;
	dcm  = "2.1";
	expd = "2.1";
	assert(copy(dcm) == expd);
	dcm  = "-1.00";
	expd = "-1.00";
	assert(copy(dcm) == expd);
	writeln("passed");

	dcm  = "2.1";
	expd = "2.1";
	write("copy-abs.....");
	assert(copyAbs(dcm) == expd);
	dcm  = "-1.00";
	expd = "1.00";
	assert(copyAbs(dcm) == expd);
	writeln("passed");

	dcm  = "101.5";
	expd = "-101.5";
	write("copy-negate..");
	assert(copyNegate(dcm) == expd);
	Decimal dcm1;
	Decimal dcm2;
	dcm1 = "1.50";
	dcm2 = "7.33";
	expd = "1.50";
	writeln("passed");

	write("copy-sign....");
	assert(copySign(dcm1, dcm2) == expd);
	dcm1 = "-1.50";
	dcm2 = "7.33";
	expd = "1.50";
	assert(copySign(dcm1, dcm2) == expd);
	dcm1 = "1.50";
	dcm2 = "-7.33";
	expd = "-1.50";
	assert(copySign(dcm1, dcm2) == expd);
	dcm1 = "-1.50";
	dcm2 = "-7.33";
	expd = "-1.50";
	assert(copySign(dcm1, dcm2) == expd);
	writeln("passed");
}

unittest {
	write("invert.......");
	writeln("..failed");
}

/*unittest {
	Decimal dcm;
	write("is-canonical.");
	dcm = Decimal("2.50");
	assert(isCanonical(dcm));
	writeln("passed");

	write("is-finite....");
	dcm = Decimal("2.50");
	assert(isFinite(dcm));
	dcm = Decimal("-0.3");
	assert(isFinite(dcm));
	dcm = 0;
	assert(isFinite(dcm));
	dcm = Decimal("Inf");
	assert(!isFinite(dcm));
	dcm = Decimal("-Inf");
	assert(!isFinite(dcm));
	dcm = Decimal("NaN");
	assert(!isFinite(dcm));
	writeln("passed");

	write("is-infinite..");
	dcm = Decimal("2.50");
	assert(!isInfinite(dcm));
	dcm = Decimal("-Inf");
	assert(isInfinite(dcm));
	dcm = Decimal("NaN");
	assert(!isInfinite(dcm));
	writeln("passed");

	write("is-NaN.......");
	dcm = Decimal("2.50");
	assert(!isNaN(dcm));
	dcm = Decimal("NaN");
	assert(isNaN(dcm));
	dcm = Decimal("-sNaN");
	assert(isNaN(dcm));
	writeln("passed");

	write("is-normal....");
	dcm = Decimal("2.50");
	assert(isNormal(dcm));
	dcm = Decimal("0.1E-99");
	assert(!isNormal(dcm));
	dcm = Decimal("0.00");
	assert(!isNormal(dcm));
	dcm = Decimal("-Inf");
	assert(!isNormal(dcm));
	dcm = Decimal("NaN");
	assert(!isNormal(dcm));
	writeln("passed");

	write("is-quiet.....");
	dcm = Decimal("2.50");
	assert(!isQuiet(dcm));
	dcm = Decimal("NaN");
	assert(isQuiet(dcm));
	dcm = Decimal("sNaN");
	assert(!isQuiet(dcm));
	writeln("passed");

	write("is-signaling.");
	dcm = Decimal("2.50");
	assert(!isSignaling(dcm));
	dcm = Decimal("NaN");
	assert(!isSignaling(dcm));
	dcm = Decimal("sNaN");
	assert(isSignaling(dcm));
	writeln("passed");

	write("is-signed....");
	dcm = Decimal("2.50");
	assert(!isSigned(dcm));
	dcm = Decimal("-12");
	assert(isSigned(dcm));
	dcm = Decimal("-0");
	assert(isSigned(dcm));
	writeln("passed");

	write("is-subnormal.");
	dcm = Decimal("2.50");
	assert(!isSubnormal(dcm));
	dcm = Decimal("0.1E-99");
	assert(isSubnormal(dcm));
	dcm = Decimal("0.00");
	assert(!isSubnormal(dcm));
	dcm = Decimal("-Inf");
	assert(!isSubnormal(dcm));
	dcm = Decimal("NaN");
	assert(!isSubnormal(dcm));
	writeln("passed");

	write("is-zero......");
	dcm = Decimal("0");
	assert(isZero(dcm));
	dcm = Decimal("2.50");
	assert(!isZero(dcm));
	dcm = Decimal("-0E+2");
	assert(isZero(dcm));
	writeln("passed");

}*/

unittest {
	write("or...........");
	writeln("..failed");
}

unittest {
	write("radix........");
	assert(radix() == 10);
	writeln("passed");
}

unittest {
	write("rotate.......");
	writeln("..failed");
}

unittest {
	write("same-quantum.");
	Decimal op1;
	Decimal op2;
	op1 = "2.17";
	op2 = "0.001";
	assert(!sameQuantum(op1, op2));
	op2 = "0.01";
	assert(sameQuantum(op1, op2));
	op2 = "0.1";
	assert(!sameQuantum(op1, op2));
	op2 = "1";
	assert(!sameQuantum(op1, op2));
	op1 = "Inf";
	op2 = "Inf";
	assert(sameQuantum(op1, op2));
	op1 = "NaN";
	op2 = "NaN";
	assert(sameQuantum(op1, op2));
	writeln("passed");
}

unittest {
	write("shift........");
	Decimal num = 34;
	int digits = 8;
	Decimal act = shift(num, digits);
	writeln("act = ", act);
	num = 12;
	digits = 9;
	act = shift(num, digits);
	writeln("act = ", act);
	num = 123456789;
	digits = -2;
	act = shift(num, digits);
	writeln("act = ", act);
	digits = 0;
	act = shift(num, digits);
	writeln("act = ", act);
	digits = 2;
	act = shift(num, digits);
	writeln("act = ", act);
	writeln("..failed");
}

unittest {
	write("xor..........");
	writeln("..failed");
}

unittest {
	writeln("-------------");
	write("round........");
	Decimal before = Decimal(9999);
	Decimal after = before;
	pushPrecision;
	context.precision = 3;
	round(after);
	assert(after.toString() == "1.00E+5");
	before = Decimal(1234567890);
	after = before;
	context.precision = 3;
	round(after);
	assert(after.toString() == "1.23E+9");
	after = before;
	context.precision = 4;
	round(after);
	assert(after.toString() == "1.235E+9");
	after = before;
	context.precision = 5;
	round(after);
	assert(after.toString() == "1.2346E+9");
	after = before;
	context.precision = 6;
	round(after);
	assert(after.toString() == "1.23457E+9");
	after = before;
	context.precision = 7;
	round(after);
	assert(after.toString() == "1.234568E+9");
	after = before;
	context.precision = 8;
	round(after);
	assert(after.toString() == "1.2345679E+9");
	before = "1235";
	after = before;
	context.precision = 3;
	round(after);
	assert(after.toAbstract() == "[0,124,1]");
	before = "12359";
	after = before;
	context.precision = 3;
	round(after);
	assert(after.toAbstract() == "[0,124,2]");
	before = "1245";
	after = before;
	context.precision = 3;
	round(after);
	assert(after.toAbstract() == "[0,124,1]");
	before = "12459";
	after = before;
	context.precision = 3;
	round(after);
	assert(after.toAbstract() == "[0,125,2]");
	popPrecision;
	writeln("passed");
}

unittest {
	writeln("-------------");
	write("exp..........");
	writeln("..failed");
}

unittest {
	write("ln...........");
	writeln("..failed");
}

unittest {
	write("log10........");
	writeln("..failed");
}

unittest {
	write("power........");
	writeln("..failed");
}

unittest {
	write("logb.........");
	writeln("..failed");
}

unittest {
	writeln();
	writeln("-------------------");
	writeln("Decimal......tested");
	writeln("-------------------");
	writeln();
	int a = 5;
}

