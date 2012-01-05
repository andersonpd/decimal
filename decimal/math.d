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

module decimal.math;

import decimal.decimal;
import decimal.context;
//import decimal.digits;
import decimal.rounding;
import decimal.arithmetic;
//import std.math;

unittest {
	writeln("---------------------");
	writeln("math..........testing");
	writeln("---------------------");
}

//--------------------------------
// CONSTANTS
//--------------------------------

//    public Decimal HALF;
//    private static immutable  Decimal ONE = Decimal.ONE;

/*    static {
        HALF = Decimal("0.5");
    }*/

/**
 * Returns the value of e to the default precision.
 */
Decimal e() {
	Decimal result;
	return result;
}

unittest {
	write("e..............");
	writeln("test missing");
}

/**
 * Returns the value of e to the specified precision.
 */
Decimal e(uint precision) {
	Decimal result;
	return result;
}

unittest {
	write("e..............");
	writeln("test missing");
}

/**
 * Returns the value of pi to the default precision.
 */
/*    Decimal pi() {
        Decimal ONE = ONE;
        writeln("ONE = ", ONE);
        Decimal TWO = Decimal(2);
        writeln("TWO  = ", TWO);
        Decimal HALF = Decimal(0.5);
        writeln("HALF = ", HALF);
        Decimal x = sqrt(TWO);
        writeln("x = sqrt(2) = ", x);
        Decimal y = sqrt(x);
        writeln("y = sqrt(x) = ", y);
        Decimal p = TWO + x;
        writeln("p = 2 + x = ", p);
        x = y;
        int i = 0;
        while (true) {
            writeln("i = ", i);
            x = HALF * (x + ONE/x);
            writeln("x = ", x);
            writeln("y = ", y);
//            writeln("step 1");
            // NOTE: if x == y then this division never ends.
            // Check the division routine for this case.
            Decimal np;
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
            Decimal xx = sqrt(x);
            x = xx;
//            writeln("step 5");
//            writeln("x = ", x);
            Decimal oox = ONE/x;
//            writeln("ONE/x = ", oox);
//            writeln ("x + ONE/x = ", x + oox);
//            Decimal t1 = oox + x;
//            writeln("t1 = ", t1);
//            Decimal t1 = x + oox; // ONE + oox; //x + x; // + ONE/x;
            writeln("step 6");
//            Decimal t2 = (y  * x) + ONE; ///x; //ONE / (y + ONE);
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

Decimal pi() {
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

Decimal sqr(const Decimal x) {
	return x * x;
}

unittest {
	write("sqr............");
	writeln("test missing");
}

/**
 * Returns the value of pi to the specified precision.
 */
Decimal pi(uint precision) {
	uint savedPrecision = bigContext.precision;
	precision += 2;
	bigContext.precision = precision;
	const Decimal ONE = Decimal(1L);
	const Decimal TWO = Decimal(2L);
	Decimal epsilon = ONE / std.math.pow(10L, precision);
	Decimal a = ONE.dup;
	Decimal b = ONE/sqrt(TWO, precision);
	Decimal t = Decimal("0.25");
	Decimal x = ONE.dup;
	int i = 0;
	while ((a -b) > epsilon && i < 10) {
		Decimal y = a;        // save the value of a
		a = (a + b)/TWO;    // arithmetic mean
		b = sqrt(b*y, precision);        // geometric means
		t -= x*(a*a - b*b);    // weighted sum of the difference of the means
		x *= 2;
		i++;
	}
	Decimal result = a*a/t;
	round(result, bigContext);
	bigContext.precision = savedPrecision;
	return result;
}

unittest {
	write("pi.............");
	writeln("test missing");
}

/**
 * Returns the square root of the argument to the current precision.
 */
Decimal sqrt(const Decimal arg) {
	return sqrt(arg, bigContext.precision);
}

unittest {
	write("sqrt...........");
	writeln("test missing");
}

/*    unittest {
        write("sqrt.....");
        Decimal dcm = Decimal(4);
        assert(sqrt(dcm) == Decimal(2));
        writeln("sqrt(2) = ", sqrt(Decimal(2)));
        dcm = Decimal(125348);
        writeln("sqrt of ", dcm);
        //assert(sqrt(dcm) == Decimal(2));
        writeln("sqrt(125348) = 354.045 = ", sqrt(dcm));
    }*/

private bool odd(int n) {
	return std.math.abs(n % 2) != 0;
}

unittest {
	write("odd............");
	writeln("test missing");
}

Decimal sqrt(const long arg, uint precision) {
	return sqrt(Decimal(arg), precision);
}

unittest {
	write("sqrt...........");
	writeln("test missing");
}

Decimal sqrt(const long arg) {
	return sqrt(Decimal(arg));
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
Decimal sqrt(const Decimal arg, uint precision) {
	// NOTE: check for negative numbers.
	if (arg.isNegative) {
		return Decimal.nan;
	}
	uint savedPrecision = bigContext.precision;
	precision += 2;
//        writeln("precision = ", precision);

	bigContext.precision = precision;
//        write("sqrt(", arg, ") = ");
	const Decimal HALF = Decimal(0.5);
	const Decimal ONE = Decimal(1);
	Decimal x = HALF*(arg + ONE);
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
			x = Decimal(2, n);
		} else {
			uint n = (d - 2)/2;
			x = Decimal(6, n);
		}
	} else if (arg < ONE) {
		int expo = arg.exponent;
		int digs = arg.getDigits;
		int d = -expo;
		int n = (d + 1)/2;
		if (odd(d)) {
			x = Decimal(6, -n);
		} else {
			x = Decimal(2, -n);
		}
	}
	Decimal xp;
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
 * Decimal version of std.math function.
 * Required by General Decimal Arithmetic Specification
 *
 */
Decimal exp(const Decimal arg) {
	Decimal x2 = arg*arg;
	const Decimal ONE = Decimal(1);
	Decimal f = ONE.dup;
	Decimal t1 = ONE.dup;
	Decimal t2 = arg.dup;
	Decimal sum = t1 + t2;
	for (long n = 3; true; n += 2) {
		t1 = t2*arg*n;
		t2 = t2*x2;
		f = f*n*(n-1);
		Decimal newSum = sum + (t1 + t2)/f;
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
 * Decimal version of std.math function.
 * 2^x
 */
Decimal exp2(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("exp2...........");
	writeln("test missing");
}

/**
 * Decimal version of std.math function.
 * exp(x) - 1
 */
Decimal expm1(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("expm1..........");
	writeln("test missing");
}

/**
 * Decimal version of std.math function.
 * Required by General Decimal Arithmetic Specification
 *
 */
Decimal log(const Decimal arg) {
	Decimal y = (arg - 1)/(arg + 1);
	Decimal y2 = y*y;
	Decimal term = y; //ONE;
	Decimal sum  = y; //ONE;
	Decimal newSum;
	for (long n = 3; ; n+=2) {
//            write("sum = ", sum);
//            write(", term = ", term, ", 1/n = ", ONE/n, ", term/n =", term/n);
		term *= y2;
		newSum = sum + (term/n);
//            writeln(", newSum = ", newSum);
		if (sum == newSum) {
			return 2 * sum;
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
 * Decimal version of std.math function.
 */
Decimal log1p(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("log1p..........");
	writeln("test missing");
}

/**
 * Decimal version of std.math.log10.
 * Required by General Decimal Arithmetic Specification
 *
 */
Decimal log10(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("log10..........");
	writeln("test missing");
}

/**
 * Decimal version of std.math.log2.
 * Required by General Decimal Arithmetic Specification
 */
Decimal log2(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("log2...........");
	writeln("test missing");
}

/**
 * Decimal version of std.math.pow.
 * Required by General Decimal Arithmetic Specification
 */
Decimal pow(Decimal op1, Decimal op2) {
	Decimal result;
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
Decimal power(Decimal op1, Decimal op2) {
	Decimal result;
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
 * Decimal version of std.math function.
 *
 */
Decimal sin(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("sin..........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal cos(Decimal arg) {
	Decimal result;
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
Decimal[] sincos(Decimal arg) {
	Decimal[] result;
	return result;
}

unittest {
	write("sincos.......");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal tan(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("tan..........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal asin(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("asin.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal acos(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("acos.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal atan(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("atan.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal atan2(Decimal y, Decimal x) {
	Decimal result;
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
 * Decimal version of std.math function.
 *
 */
Decimal sinh(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("sinh.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal cosh(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("cosh.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal tanh(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("tanh.........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal asinh(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("asinh........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal acosh(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("acosh........");
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal atanh(Decimal arg) {
	Decimal result;
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
 * TODO: implement
 */
Decimal ln(Decimal op1) {
	Decimal result;
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


