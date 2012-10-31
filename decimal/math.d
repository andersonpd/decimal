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

unittest {
	writeln("===================");
	writeln("math........testing");
	writeln("===================");
}

//--------------------------------
// CONSTANTS
//--------------------------------

/*const Decimal ONE = Decimal(1);*/

/**
 * Returns the value of e to the specified precision.
 */
Decimal e(const uint precision) {
	pushContext(precision+2);
	Decimal value = e();
	bigContext.precision -= 2;
	round(value);
	popContext();
	return value;
}

/**
 * Returns the value of e to the current precision.
 */
Decimal e() {
	Decimal x = 1;
	int n = 1;
	Decimal fact = 1;
	Decimal sum = 1;
	Decimal term = 1;
	while (term > Decimal.epsilon) {
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
	for (int i = 10; i < 25; i++) {
		writefln("e(%d) = %s", i, e(i));
	}
	writeln("test missing");
}

Decimal sqr(const Decimal x) {
	return x * x;
}

unittest {
	write("sqr............");
	writeln("test missing");
}

// Returns the value of pi to the specified precision.
Decimal pi(uint precision) {
	pushContext(precision); // plus two guard digits?
	Decimal value = pi();
	popContext();
	return value;
}

/**
 * Returns the value of pi to the current precision.
 * TODO: AGM version -- use less expensive?
 * TODO: pre-computed string;
 */
Decimal pi() {
	const Decimal ONE = Decimal(1L);
	const Decimal TWO = Decimal(2L);
	Decimal a = ONE.dup;
	Decimal b = a/sqrt(TWO);
	Decimal t = Decimal("0.25");
	Decimal x = ONE.dup;
	int i = 0;
	while (a != b) {
		Decimal y = a;    // save the value of a
		a = (a + b)/TWO;     // arithmetic mean
		b = sqrt(b*y);       // geometric mean
		t -= x*(a*a - b*b);  // weighted sum of the difference of the means
		x = x * 2;
		i++;
	}
	Decimal result = a*a/t;
	return result;
}

string PI_STR = "3.141592653589793238462695";

Decimal spi(uint precision) {
	pushContext(precision);
	string spi = PI_STR[0..precision+2];
	Decimal dpi = Decimal(spi);
	round(dpi, bigContext);
	popContext();
	return dpi;

}
unittest {
	write("pi.............");
writeln;
writefln("pi     = %s", pi);
writefln("pi(25) = %s", pi(25));
writefln("pis(15) = %s", spi(14));
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
writefln("odd(3) = %s", odd(3));
	writeln("test missing");
}

Decimal sqrt(const Decimal arg, uint precision) {
	pushContext(precision);
	Decimal value = sqrt(arg);
	popContext();
	return value;
}


/// Returns the square root of the argument to the specified precision.
/// Uses Newton's method. The starting value should be close to the result
/// to speed convergence and to avoid unstable operation.
/// TODO: better to compute (1/sqrt(arg)) * arg?
/// TODO: the precision can be adjusted as the computation proceeds
Decimal sqrt(const Decimal x) {
	// check for negative numbers.
	if (x.isNaN || x.isNegative) return Decimal.nan;
	if (x.isInfinite) return Decimal.infinity;

	// all this stuff is just an estimate of the square root
	Decimal rest;
	const Decimal one = Decimal(1);
	if (x > one) {
		int expo = x.exponent;
		uint digs = x.getDigits;
		uint d;
		if (expo > 0) {
			d = digs + expo;
		} else {
			d = digs - expo;
		}
		if (odd(d)) {
			uint n = (d - 1)/2;
			rest = Decimal(2, n);
		} else {
			uint n = (d - 2)/2;
			rest = Decimal(6, n);
		}
	} else if (x < one) {
		int expo = x.exponent;
		int digs = x.getDigits;
		int d = -expo;
		int n = (d + 1)/2;
		if (odd(d)) {
			rest = Decimal(6, -n);
		} else {
			rest = Decimal(2, -n);
		}
	}
	else {
		return one.dup;
	}
//writefln("x = %s", x);
//writefln("rest = %s", rest);
	// down to here!
	const Decimal half = Decimal("0.5");
	Decimal r = rest;
	Decimal rp;
	int i = 0;
	while(i < 100) {
		rp = r;
		r = half * ( r + x/r);
		if (r == rp) break;
		i++;
	}
writefln("i = %s", i);
	return r;
}

unittest {
	write("sqrt...........");
writeln;
writefln("sqrt(2, 29) = %s", sqrt(Decimal(2), 29));
writefln("sqrt(2, 29) = %s", sqrt(Decimal(200), 29));
writefln("sqrt(2, 29) = %s", sqrt(Decimal(25), 29));
writefln("sqrt(2, 29) = %s", sqrt(Decimal(2E-5), 29));
writefln("sqrt(2, 29) = %s", sqrt(Decimal(1E-15), 29));
writefln("sqrt(2, 29) = %s", sqrt(Decimal(1E-16), 29));
	writeln("test missing");
}

public Decimal reciprocal(const Decimal x) {
	// TODO: implement reciprocal
	return Decimal.nan;
}

Decimal reciprocal(const Decimal x, uint precision) {
	pushContext(precision);
	Decimal value = reciprocal(x);
	popContext();
	return value;
}

/// Decimal version of std.math function
public Decimal hypot(const Decimal x, const Decimal y)
{
	// check for NaNs, infinite and zero operands
	if (x.isNaN) return Decimal.nan;
	if (x.isInfinite || y.isInfinite) return Decimal.infinity();
    if (x.isZero) return y.dup;
	if (y.isZero) return x.dup;

    const Decimal one = Decimal(1);
	Decimal a = copyAbs(x);
    Decimal b = copyAbs(y);
	if (a < b) {
		//swap operands
		Decimal t = a;
		a = b;
		b = t;
	}
    b /= a;
    return a * sqrt(one + (b * b));
}

unittest {
	write("hypot...");
/*	Decimal x = 3;
	Decimal y = 4;
	Decimal expect = 5;
	Decimal actual = hypot(x,y);
	decimal.test.assertEqual(expect, actual);*/
	writeln("test passed");
}

//--------------------------------
//
// EXPONENTIAL AND LOGARITHMIC FUNCTIONS
//
//--------------------------------

Decimal exp(const Decimal arg, const uint precision) {
	pushContext(precision);
	Decimal value = exp(arg);
	popContext();
	return value;
}

/// Decimal version of std.math function.
/// Required by General Decimal Arithmetic Specification
Decimal exp(const Decimal x) {
	Decimal sqrx = x*x;
	long n = 1;
	Decimal fact = 1;
	Decimal t1 = 1;
	Decimal t2 = x.dup;
	Decimal term = t1 + t2;
	Decimal sum = term;
	while (term > Decimal.epsilon) {
		n += 2;
		t1 = t2*x*n;
		t2 = t2*sqrx;
		fact = fact*n*(n-1);
		term = (t1 + t2)/fact;
		sum += term;
	}
	return sum;
}

unittest {
	write("exp............");
writeln;
	Decimal one = Decimal(1);
writefln("exp(1) = %s", exp(one));
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
	Decimal one = Decimal(1);
writefln("log(exp(one)) = %s", log(exp(one)));
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
// TRIGONOMETRIC FUNCTIONS
//--------------------------------


/// Decimal version of std.math function.
Decimal sin(const Decimal x) {
	Decimal sum = 0;
	int n = 1;
	Decimal powx = x.dup;
	Decimal sqrx = x * x;
	Decimal fact = 1;
	Decimal term = powx;
	while (term.abs > Decimal.epsilon) {
		sum += term;
		n += 2;
		powx = -powx * sqrx;
		fact = fact * (n*(n-1));
		term = powx/fact;
	}
	return sum;
}

/// Decimal version of std.math function.
Decimal sin(const Decimal arg, uint precision) {
	pushContext(precision);
	Decimal value = sin(arg);
	popContext();
	return value;
}

unittest {
	write("sin..........");
	// sin(1.0) = 0.84147098480789650665250232163029899962256306079837
	writeln;
	writefln("sin(1.0) = %s", sin(Decimal("1.0")));

	writeln("..failed");
}

/// Decimal version of std.math function.
Decimal cos(const Decimal x) {
	Decimal sum = 0;
	int n = 0;
	Decimal powx = 1;
	Decimal sqrx = x * x;
	Decimal fact = 1;
	Decimal term = powx;
	while (term.abs > Decimal.epsilon) {
		sum += term;
		n += 2;
		powx = -powx * sqrx;
		fact = fact * (n*(n-1));
		term = powx/fact;
	}
	return sum;
}

/// Decimal version of std.math function.
Decimal cos(const Decimal x, uint precision) {
	pushContext(precision);
	Decimal value = cos(x);
	popContext();
	return value;
}

unittest {
	write("cos..........");
	// cos(1.0) = 0.54030230586813971740093660744297660373231042061792
	writeln;
	writefln("cos(1.0) = %s", cos(Decimal("1.0")));
	writeln("..failed");
}

/**
 * Replaces std.math function expi
 *
 */
public void sincos(Decimal x, out Decimal sine, out Decimal cosine) {
	Decimal[2] result;

	Decimal csum, cterm, cx;
	Decimal ssum, sterm, sx;
	Decimal sqrx = x*x;
	long n = 2;
	Decimal fact = 1;
	cx = 1;	cterm = cx;	csum = cterm;
	sx = x.dup;	sterm = sx;	ssum = sterm;
	while (sterm.abs > Decimal.epsilon/* && n < 10*/) {
		cx = -sx;
		fact = fact * n++;
		cterm = cx/fact;
		csum = csum + cterm;
		sx = -sx*sqrx;
		fact = fact  * n++;
		sterm = sx/fact;
		ssum = ssum + sterm;
	}
    sine = ssum;
	cosine = csum;
}

unittest {
	write("sincos.......");
	Decimal sine;
	Decimal cosine;
	sincos(Decimal("1.0"), sine, cosine);
writeln;
writefln("sine = %s", sine);
writefln("cosine = %s", cosine);
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal tan(Decimal x) {
	Decimal sine;
	Decimal cosine;
	sincos(x, sine, cosine);
	return sine/cosine;
}

unittest {
	write("tan..........");
	// tan(1.0) = 1.5574077246549022305069748074583601730872507723815
writefln("tan(1.0) = %s", tan(Decimal("1.0")));

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


/// Decimal version of std.math function.
// TODO: only valid if x < 1.0; convergence very slow if x ~ 1.0;
Decimal atan(Decimal x) {
	Decimal sum = 0;
	Decimal powx = x.dup;
	Decimal sqrx = x * x;
	Decimal dvsr = 1;
	Decimal term = powx;
	while (term.abs > Decimal.epsilon && dvsr < Decimal(50)) {
		sum += term;
		powx = -powx * sqrx;
		dvsr = dvsr + 2; //dvsr * (n*(n-1));
		term = powx/dvsr;
	}
	return sum;
}

unittest {
	write("atan.........");
	// arctan(1.0) = 0.7853981633974483096156608458198757210492923498438
	// arctan(0.1) = 0.099668652491162038065120043484057532623410224914551
writefln("atan(0.1)) = %s", atan(Decimal("0.1")));
	// arctan(0.9) = 0.73281510178650655085164089541649445891380310058594
writefln("atan(0.9)) = %s", atan(Decimal("0.9")));
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

/// Decimal version of std.math function.
Decimal sinh(Decimal x) {
	long n = 1;
	Decimal sum = 0;
	Decimal powx = x.dup;
	Decimal sqrx = x * x;
	Decimal fact = n;
	Decimal term = powx;
	while (term.abs > Decimal.epsilon) {
		sum += term;
		n += 2;
		fact = fact * (n*(n-1));
		powx = powx * sqrx;
		term = powx/fact;
	}
	return sum;
}

unittest {
	write("sinh.........");
	// sinh(1.0) = 1.1752011936438014568823818505956008151557179813341
writefln("sinh(1.0) = %s", sinh(Decimal("1.0")));
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal cosh(Decimal x) {
	long n = 0;
	Decimal sum = 0;
	Decimal powx = 1;
	Decimal sqrx = x * x;
	Decimal fact = 1;
	Decimal term = powx;
	while (term.abs > Decimal.epsilon) {
		sum += term;
		n += 2;
		fact = fact * (n*(n-1));
		powx = powx * sqrx;
		term = powx/fact;
	}
	return sum;
}

unittest {
	write("cosh.........");
	// cosh(1.0) = 1.5430806348152437784779056207570616826015291123659
writefln("cosh(1.0) = %s", cosh(Decimal("1.0")));
	writeln("..failed");
}

/**
 * Decimal version of std.math function.
 *
 */
Decimal tanh(Decimal x) {
	return cosh(x)/sinh(x);
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
 * (M)TODO: implement
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
	writeln("===================");
	writeln("math.......finished");
	writeln("===================");
	writeln();
}


