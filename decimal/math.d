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

module decimal.math;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;
import decimal.rounding;

unittest {
	writeln("---------------------");
	writeln("math..........testing");
	writeln("---------------------");
}

//--------------------------------
// CONSTANTS
//--------------------------------

/**
 * Returns the value of e to the specified precision.
 */
BigDecimal e(const uint precision) {
	pushContext(precision);
	BigDecimal value = e();
	popContext();
	return value;
}

/**
 * Returns the value of e to the current precision.
 */
BigDecimal e() {
	BigDecimal x = 1;
	int n = 1;
	BigDecimal fact = 1;
	BigDecimal sum = 1;
	BigDecimal term = 1;
//writefln("BigDecimal.epsilon = %s", BigDecimal.epsilon);
	while (term > BigDecimal.epsilon) {
		sum += term;
		n++;
		fact = fact * n;
		term = x/fact;
	}
	return sum;
}

unittest {
	write("e..............");
writeln();
	for (int i = 10; i < 15; i++) {
		writefln("e(%d) = %s", i, e(i));
	}
	writeln("test missing");
}

BigDecimal sqr(const BigDecimal x) {
	return x * x;
}

unittest {
	write("sqr............");
	writeln("test missing");
}

// Returns the value of pi to the specified precision.
BigDecimal pi(uint precision) {
	pushContext(precision); // plus two guard digits?
	BigDecimal value = pi();
	popContext();
	return value;
}

/**
 * Returns the value of pi to the current precision.
 * TODO: AGM version -- use less expensive?
 * TODO: pre-computed string;
 */
BigDecimal pi() {
	const BigDecimal ONE = BigDecimal(1L);
	const BigDecimal TWO = BigDecimal(2L);
	BigDecimal a = 1; //ONE.dup;
	BigDecimal b = a/sqrt(TWO);
	BigDecimal t = BigDecimal("0.25");
	BigDecimal x = 1; //ONE.dup;
	int i = 0;
	while (a != b) {
		BigDecimal y = a;    // save the value of a
		a = (a + b)/TWO;     // arithmetic mean
		b = sqrt(b*y);       // geometric mean
		t -= x*(a*a - b*b);  // weighted sum of the difference of the means
		x = x * 2;
		i++;
	}
	BigDecimal result = a*a/t;
	return result;
}

unittest {
	write("pi.............");
writeln;
writefln("pi     = %s", pi);
writefln("pi(25) = %s", pi(25));
	writeln("test missing");
}

/*    unittest {
        write("sqrt.....");
        BigDecimal dcm = BigDecimal(4);
        assert(sqrt(dcm) == BigDecimal(2));
        writeln("sqrt(2) = ", sqrt(BigDecimal(2)));
        dcm = BigDecimal(125348);
        writeln("sqrt of ", dcm);
        //assert(sqrt(dcm) == BigDecimal(2));
        writeln("sqrt(125348) = 354.045 = ", sqrt(dcm));
    }*/

private bool odd(int n) {
	return std.math.abs(n % 2) != 0;
}

unittest {
	write("odd............");
writefln("odd(3) = %s", odd(3));
	writeln("test missing");
}

BigDecimal sqrt(const BigDecimal arg, uint precision) {
	pushContext(precision);
	BigDecimal value = sqrt(arg);
	popContext();
	return value;
}

/**
 * Returns the square root of the argument to the specified precision.
 * Uses Newton's method. The starting value should be close to the result
 * to speed convergence and to avoid unstable operation.
 * TODO: better to compute (1/sqrt(arg)) * arg?
 */
BigDecimal sqrt(const BigDecimal arg) {
	// check for negative numbers.
	if (arg.isNegative) {
		return BigDecimal.nan;
	}
	const BigDecimal HALF = BigDecimal(0.5);
	const BigDecimal ONE = BigDecimal(1);
	BigDecimal x = HALF*(arg + ONE);
	if (arg > ONE) {
		int expo = arg.exponent;
		uint digs = arg.getDigits;
		uint d;
		if (expo > 0) {
			d = digs + expo;
		} else {
			d = digs - expo;
		}
		if (odd(d)) {
			uint n = (d - 1)/2;
			x = BigDecimal(2, n);
		} else {
			uint n = (d - 2)/2;
			x = BigDecimal(6, n);
		}
	} else if (arg < ONE) {
		int expo = arg.exponent;
		int digs = arg.getDigits;
		int d = -expo;
		int n = (d + 1)/2;
		if (odd(d)) {
			x = BigDecimal(6, -n);
		} else {
			x = BigDecimal(2, -n);
		}
	}
//	BigDecimal x = BigDecimal(std.math.sqrt(arg));
	BigDecimal xp;
	int i = 0;
	while(i < 100) {
		xp = x;
		x = HALF * (x + (arg/x));
		if (x == xp) break;
		i++;
	}
	return xp;
}

unittest {
	write("sqrt...........");
writeln;
writefln("sqrt(2, 29) = %s", sqrt(BigDecimal(2), 29));
	writeln("test missing");
}

//--------------------------------
//
// EXPONENTIAL AND LOGARITHMIC FUNCTIONS
//
//--------------------------------

BigDecimal exp(const BigDecimal arg, const uint precision) {
	pushContext(precision);
	BigDecimal value = exp(arg);
	popContext();
	return value;
}

/**
 * BigDecimal version of std.math function.
 * Required by General Decimal Arithmetic Specification
 *
 */
BigDecimal exp(const BigDecimal arg) {
	BigDecimal x2 = arg*arg;
	const BigDecimal ONE = BigDecimal(1);
	BigDecimal f = ONE.dup;
	BigDecimal t1 = ONE.dup;
	BigDecimal t2 = arg.dup;
	BigDecimal sum = t1 + t2;
	for (long n = 3; true; n += 2) {
		t1 = t2*arg*n;
		t2 = t2*x2;
		f = f*n*(n-1);
		BigDecimal newSum = sum + (t1 + t2)/f;
		if (sum == newSum) {
			break;
		}
		sum = newSum;
	}
	return sum;
}

unittest {
	write("exp............");
writeln;
	BigDecimal one = BigDecimal(1);
writefln("exp(1) = %s", exp(one));
	writeln("test missing");
}

/**
 * BigDecimal version of std.math function.
 * 2^x
 */
BigDecimal exp2(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("exp2...........");
	writeln("test missing");
}

/**
 * BigDecimal version of std.math function.
 * exp(x) - 1
 */
BigDecimal expm1(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("expm1..........");
	writeln("test missing");
}

/**
 * BigDecimal version of std.math function.
 * Required by General Decimal Arithmetic Specification
 *
 */
BigDecimal log(const BigDecimal arg) {
	BigDecimal y = (arg - 1)/(arg + 1);
	BigDecimal y2 = y*y;
	BigDecimal term = y; //ONE;
	BigDecimal sum  = y; //ONE;
	BigDecimal newSum;
	for (long n = 3; ; n+=2) {
		term *= y2;
		newSum = sum + (term/n);
		if (sum == newSum) {
			return sum * 2;
		}
		sum = newSum;
	}
}

unittest {
	write("log............");
writeln;
	BigDecimal one = BigDecimal(1);
writefln("log(exp(one)) = %s", log(exp(one)));
	writeln("test missing");
}

/**
 * log1p (== log(1 + x)).
 * BigDecimal version of std.math function.
 */
BigDecimal log1p(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("log1p..........");
	writeln("test missing");
}

/**
 * BigDecimal version of std.math.log10.
 * Required by General Decimal Arithmetic Specification
 *
 */
BigDecimal log10(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("log10..........");
	writeln("test missing");
}

/**
 * BigDecimal version of std.math.log2.
 * Required by General Decimal Arithmetic Specification
 */
BigDecimal log2(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("log2...........");
	writeln("test missing");
}

/**
 * BigDecimal version of std.math.pow.
 * Required by General Decimal Arithmetic Specification
 */
BigDecimal pow(BigDecimal op1, BigDecimal op2) {
	BigDecimal result;
	return result;
}

unittest {
	write("pow............");
	writeln("test missing");
}

/**
 * power.
 * Required by General Decimal Arithmetic Specification
 */
BigDecimal power(BigDecimal op1, BigDecimal op2) {
	BigDecimal result;
	return result;
}

unittest {
	write("power..........");
	writeln("test missing");
}


//--------------------------------
//
// TRIGONOMETRIC FUNCTIONS
//
//--------------------------------

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal sin(const BigDecimal arg) {
	BigDecimal sum = 0;
	return sum;
}
/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal sin(const BigDecimal arg, uint precision) {
	pushContext(precision);
	BigDecimal value = sin(arg);
	popContext();
	return value;
}

unittest {
	write("sin..........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal cos(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("cos..........");
	writeln("..failed");
}

/**
 * Replaces std.math function expi
 *
 */
BigDecimal[] sincos(BigDecimal arg) {
	BigDecimal[] result;
	return result;
}

unittest {
	write("sincos.......");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal tan(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("tan..........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal asin(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("asin.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal acos(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("acos.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal atan(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("atan.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal atan2(BigDecimal y, BigDecimal x) {
	BigDecimal result;
	return result;
}

unittest {
	write("atan2........");
	writeln("..failed");
}

//--------------------------------
//
// HYPERBOLIC TRIGONOMETRIC FUNCTIONS
//
//--------------------------------

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal sinh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("sinh.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal cosh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("cosh.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal tanh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("tanh.........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal asinh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("asinh........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal acosh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("acosh........");
	writeln("..failed");
}

/**
 * BigDecimal version of std.math function.
 *
 */
BigDecimal atanh(BigDecimal arg) {
	BigDecimal result;
	return result;
}

unittest {
	write("atanh........");
	writeln("..failed");
}

//--------------------------------
//
// General Decimal Arithmetic Specification Functions
//
//--------------------------------

/**
 * part of spec
 *
 * (M)TODO: implement
 */
BigDecimal ln(BigDecimal op1) {
	BigDecimal result;
	return result;
}

unittest {
	write("ln.............");
	writeln("test missing");
}

unittest {
	writeln("---------------------");
	writeln("math.........finished");
	writeln("---------------------");
	writeln();
}


