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

//    public BigDecimal HALF;
//    private static immutable  BigDecimal ONE = BigDecimal.ONE;

/*    static {
        HALF = BigDecimal("0.5");
    }*/

/**
 * Returns the value of e to the default precision.
 */
BigDecimal e() {
	BigDecimal result;
	return result;
}

unittest {
	write("e..............");
	writeln("test missing");
}

/**
 * Returns the value of e to the specified precision.
 */
BigDecimal e(uint precision) {
	BigDecimal result;
	return result;
}

unittest {
	write("e..............");
	writeln("test missing");
}

/**
 * Returns the value of pi to the default precision.
 */
/*    BigDecimal pi() {
        BigDecimal ONE = ONE;
        writeln("ONE = ", ONE);
        BigDecimal TWO = BigDecimal(2);
        writeln("TWO  = ", TWO);
        BigDecimal HALF = BigDecimal(0.5);
        writeln("HALF = ", HALF);
        BigDecimal x = sqrt(TWO);
        writeln("x = sqrt(2) = ", x);
        BigDecimal y = sqrt(x);
        writeln("y = sqrt(x) = ", y);
        BigDecimal p = TWO + x;
        writeln("p = 2 + x = ", p);
        x = y;
        int i = 0;
        while (true) {
            writeln("i = ", i);
            x = HALF * (x + ONE/x);
            writeln("x = ", x);
            writeln("y = ", y);
//            writeln("step 1");
            // (M)TODO: if x == y then this division never ends.
            // Check the division routine for this case.
            BigDecimal np;
            if (x == y) {
              np = p;
            }
            else {
            np = p * ((x + ONE)/(y + ONE));
            }
//            writeln("step 2");
            writeln("np = ", np);
            if (p == np) return p;
//            writeln("step 3");
            p = np;
//            writeln("step 4");
            BigDecimal xx = sqrt(x);
            x = xx;
//            writeln("step 5");
//            writeln("x = ", x);
            BigDecimal oox = ONE/x;
//            writeln("ONE/x = ", oox);
//            writeln ("x + ONE/x = ", x + oox);
//            BigDecimal t1 = oox + x;
//            writeln("t1 = ", t1);
//            BigDecimal t1 = x + oox; // ONE + oox; //x + x; // + ONE/x;
            writeln("step 6");
//            BigDecimal t2 = (y  * x) + ONE; ///x; //ONE / (y + ONE);
//            y = ONE/x + y * x;
            writeln("step 7");
            y = (ONE/x + y * x) / (y + ONE); //t1 / t2;
            writeln("step 8");
            i++;
//            break;
        }
        return p;
    }
*/

BigDecimal pi() {
	return pi (bigContext.precision);
}

unittest {
	write("pi.............");
	writeln("test missing");
}
/*    unittest {
        write("pi....");
        writeln("pi = ", pi());
    }*/

BigDecimal sqr(const BigDecimal x) {
	return x * x;
}

unittest {
	write("sqr............");
	writeln("test missing");
}

/**
 * Returns the value of pi to the specified precision.
 */
BigDecimal pi(uint precision) {
	uint savedPrecision = bigContext.precision;
	precision += 2;
//	bigContext.precision = precision;
	const BigDecimal ONE = BigDecimal(1L);
	const BigDecimal TWO = BigDecimal(2L);
	BigDecimal epsilon = ONE / std.math.pow(10L, precision);
	BigDecimal a = ONE.dup;
	BigDecimal b = ONE/sqrt(TWO, precision);
	BigDecimal t = BigDecimal("0.25");
	BigDecimal x = ONE.dup;
	int i = 0;
	while ((a -b) > epsilon && i < 10) {
		BigDecimal y = a;        // save the value of a
		a = (a + b)/TWO;    // arithmetic mean
		b = sqrt(b*y, precision);        // geometric means
		t -= x*(a*a - b*b);    // weighted sum of the difference of the means
		x = x * 2;
		i++;
	}
	BigDecimal result = a*a/t;
	round(result, bigContext);
//	bigContext.precision = savedPrecision;
	return result;
}

unittest {
	write("pi.............");
	writeln("test missing");
}

/**
 * Returns the square root of the argument to the current precision.
 */
BigDecimal sqrt(const BigDecimal arg) {
	return sqrt(arg, bigContext.precision);
}

unittest {
	write("sqrt...........");
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
	writeln("test missing");
}

BigDecimal sqrt(const long arg, uint precision) {
	return sqrt(BigDecimal(arg), precision);
}

unittest {
	write("sqrt...........");
	writeln("test missing");
}

BigDecimal sqrt(const long arg) {
	return sqrt(BigDecimal(arg));
}

unittest {
	write("sqrt...........");
	writeln("test missing");
}

/**
 * Returns the square root of the argument to the specified precision.
 * Uses Newton's method. The starting value should be close to the result
 * to speed convergence and to avoid unstable operation.
 */
BigDecimal sqrt(const BigDecimal arg, uint precision) {
	// check for negative numbers.
	if (arg.isNegative) {
		return BigDecimal.nan;
	}
	uint savedPrecision = bigContext.precision;
	precision += 2;
//        writeln("precision = ", precision);

//	bigContext.precision = precision;
//        write("sqrt(", arg, ") = ");
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
	BigDecimal xp;
	int i = 0;
	while(i < 2000) {
		xp = x;
		x = HALF * (x + (arg/x));
		if (x == xp) break;
		i++;
	}
//        writeln(xp);
	round(xp, bigContext);
	precision = savedPrecision;
	return xp;
}

unittest {
	write("sqrt...........");
	writeln("test missing");
}

//--------------------------------
//
// EXPONENTIAL AND LOGARITHMIC FUNCTIONS
//
//--------------------------------

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
//            write("sum = ", sum);
//            write(", term = ", term, ", 1/n = ", ONE/n, ", term/n =", term/n);
		term *= y2;
		newSum = sum + (term/n);
//            writeln(", newSum = ", newSum);
		if (sum == newSum) {
			return sum * 2;
		}
		sum = newSum;
	}
}

unittest {
	write("log............");
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
BigDecimal sin(BigDecimal arg) {
	BigDecimal result;
	return result;
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


