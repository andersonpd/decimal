﻿/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 *
 * by Paul D. Anderson
 *
 * Boost Software License - Version 1.0 - August 17th, 2003
 *
 * Permission is hereby granted, free of charge, to any person or organization
 * obtaining a copy of the software and accompanying documentation covered by
 * this license (the "Software") to use, reproduce, display, distribute,
 * execute, and transmit the Software, and to prepare derivative works of the
 * Software, and to permit third-parties to whom the Software is furnished to
 * do so, all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated by
 * a source language processor.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 * FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
**/

module decimal.math;

import decimal.decimal;
import decimal.context;
import decimal.digits;
import decimal.arithmetic;
//import std.math;

public:

    //--------------------------------
    //
    // CONSTANTS
    //
    //--------------------------------

//	public Decimal HALF;
//	private static immutable  Decimal ONE = Decimal.ONE;

/*	static {
		HALF = Decimal("0.5");
	}*/

    /**
     * Returns the value of e to the default precision.
     */
    Decimal e() {
        Decimal result;
        return result;
    }

    /**
     * Returns the value of e to the specified precision.
     */
    Decimal e(uint precision) {
        Decimal result;
        return result;
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
//			writeln("step 1");
			// NOTE: if x == y then this division never ends.
			// Check the division routine for this case.
			Decimal np;
			if (x == y) {
			  np = p;
			}
			else {
			np = p * ((x + ONE)/(y + ONE));
			}
//			writeln("step 2");
			writeln("np = ", np);
			if (p == np) return p;
//			writeln("step 3");
			p = np;
//			writeln("step 4");
			Decimal xx = sqrt(x);
			x = xx;
//			writeln("step 5");
//			writeln("x = ", x);
			Decimal oox = ONE/x;
//			writeln("ONE/x = ", oox);
//			writeln ("x + ONE/x = ", x + oox);
//			Decimal t1 = oox + x;
//			writeln("t1 = ", t1);
//			Decimal t1 = x + oox; // ONE + oox; //x + x; // + ONE/x;
			writeln("step 6");
//			Decimal t2 = (y  * x) + ONE; ///x; //ONE / (y + ONE);
//			y = ONE/x + y * x;
			writeln("step 7");
			y = (ONE/x + y * x) / (y + ONE); //t1 / t2;
			writeln("step 8");
			i++;
//			break;
		}
        return p;
    }
*/

	Decimal pi() {
		return pi (context.precision);
	}

/*	unittest {
		write("pi....");
		writeln("pi = ", pi());
	}*/

	Decimal sqr(const Decimal x) {
		return x * x;
	}
    /**
     * Returns the value of pi to the specified precision.
     */
    Decimal pi(uint precision) {
		uint savedPrecision = context.precision;
		precision += 2;
		context.precision = precision;
		const Decimal ONE = Decimal(1);
		const Decimal TWO = Decimal(2);
		Decimal epsilon = ONE / std.math.pow(10L, precision);
		Decimal a = ONE.dup;
		Decimal b = ONE/sqrt(TWO, precision);
		Decimal t = Decimal("0.25");
		Decimal x = ONE.dup;
		int i = 0;
		while ((a -b) > epsilon && i < 10) {
			Decimal y = a;		// save the value of a
			a = (a + b)/TWO;	// arithmetic mean
			b = sqrt(b*y, precision);		// geometric means
			t -= x*(a*a - b*b);	// weighted sum of the difference of the means
			x *= 2;
			i++;
		}
        Decimal result = a*a/t;
		round(result, context);
		context.precision = savedPrecision;
		return result;
    }

    /**
     * Returns the square root of the argument to the current precision.
     */
    Decimal sqrt(const Decimal arg) {
		return sqrt(arg, context.precision);
    }


/*	unittest {
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

    Decimal sqrt(const long arg, uint precision) {
		return sqrt(Decimal(arg), precision);
	}

    Decimal sqrt(const long arg) {
		return sqrt(Decimal(arg));
	}

    /**
     * Returns the square root of the argument to the specified precision.
	 * Uses Newton's method. The starting value should be close to the result
	 * to speed convergence and to avoid unstable operation.
     */
    Decimal sqrt(const Decimal arg, uint precision) {
		// NOTE: check for negative numbers.
		if (arg.isNegative) {
			return Decimal.NaN.dup;
		}
		uint savedPrecision = context.precision;
		precision += 2;
//		writeln("precision = ", precision);

		context.precision = precision;
//		write("sqrt(", arg, ") = ");
		const Decimal HALF = Decimal(0.5);
		const Decimal ONE = Decimal(1);
		Decimal x = HALF*(arg + ONE);
		if (arg > ONE) {
			int expo = arg.exponent;
			uint digs = arg.getDigits;
			uint d;
			if (expo > 0) {
				d = digs + expo;
			}
			else {
				d = digs - expo;
			}
			if (odd(d)) {
				uint n = (d - 1)/2;
				x = Decimal(2, n);
			}
			else {
				uint n = (d - 2)/2;
				x = Decimal(6, n);
			}
		}
		else if (arg < ONE) {
			int expo = arg.exponent;
			int digs = arg.getDigits;
			int d = -expo;
			int n = (d + 1)/2;
			if (odd(d)) {
				x = Decimal(6, -n);
			}
			else {
				x = Decimal(2, -n);
			}
		}
		Decimal xp;
		int i = 0;
		while(i < 2000){
			xp = x;
			x = HALF * (x + (arg/x));
			if (x == xp) break;
			i++;
		}
//		writeln(xp);
		round(xp, context);
		precision = savedPrecision;
        return xp;
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

    /**
     * Decimal version of std.math function.
     * 2^x
     */
    Decimal exp2(Decimal arg) {
        Decimal result;
        return result;
    }

    /**
     * Decimal version of std.math function.
     * exp(x) - 1
     */
    Decimal expm1(Decimal arg) {
        Decimal result;
        return result;
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
//			write("sum = ", sum);
//			write(", term = ", term, ", 1/n = ", ONE/n, ", term/n =", term/n);
			term *= y2;
			newSum = sum + (term/n);
//			writeln(", newSum = ", newSum);
			if (sum == newSum) {
				return 2 * sum;
			}
			sum = newSum;
		}
    }

    /**
     * Decimal version of std.math function.
     * log(1 + x)
     */
    Decimal log1p(Decimal arg) {
        Decimal result;
        return result;
    }

    /**
     * Decimal version of std.math function.
     * Required by General Decimal Arithmetic Specification
     *
     */
    Decimal log10(Decimal arg) {
        Decimal result;
        return result;
    }

    /*** Decimal version of std.math function.
     * Required by General Decimal Arithmetic Specification
     *
     */
    Decimal log2(Decimal arg) {
        Decimal result;
        return result;
    }

    /**
     * Decimal version of std.math function.
     * Required by General Decimal Arithmetic Specification
     *
     */
    Decimal pow(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

/*	unittest {
		write("exp..........");
		Decimal dcm = Decimal(1);
		//assert(exp(dcm) == Decimal(2));

		writeln("exp(1) = ", exp(Decimal(1)));
		write("exp2.........");
		writeln("..failed");

		write("expm1........");
		writeln("..failed");

		write("log..........");
		writeln("..failed");

		write("log1p........");
		writeln("..failed");

		write("log10........");
		writeln("..failed");

		write("log2.........");
		writeln("..failed");

		write("pow..........");
		writeln("..failed");
	}*/

/+
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
		write("acosh.......");
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
		write("atanh.......");
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
    Decimal compare(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal compareSignal(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal compareTotal(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal divideInteger(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal fma(Decimal op1, Decimal op2, Decimal op3) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal ln(Decimal op1) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal log10(Decimal op1) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal max(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal maxMagnitude(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal min(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal minMagnitude(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal nextMinus(Decimal op1) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal nextPlus(Decimal op1) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal nextToward(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal power(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal remainder(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal remainderNear(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * NOTE: performs both round-to-integral-exact and
     * round-to-integral-value
     *
     * TODO: implement
     */
    Decimal rint(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

// logical operations

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal and(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal or(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal xor(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }

    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal invert(Decimal op1) {
        Decimal result;
        return result;
    }


    /**
     * part of spec
     *
     * TODO: implement
     */
    Decimal compareTotal(Decimal op1, Decimal op2) {
        Decimal result;
        return result;
    }
+/


