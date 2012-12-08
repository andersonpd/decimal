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

import std.bigint;

import decimal.arithmetic;
import decimal.context;
import decimal.decimal;

unittest {
	writeln("===================");
	writeln("math........testing");
	writeln("===================");
}

//--------------------------------
// ROUNDING
//--------------------------------

/// Rounds the argument to an integer using the specified context.
public Decimal round(const Decimal arg,
		const DecimalContext context) {
	Decimal value = roundToIntegralExact(arg, context);
	return value;
}

/// Rounds the argument to an integer using the specified rounding mode.
public Decimal round(const Decimal arg,
		const Rounding rounding = Rounding.HALF_EVEN) {
	if (getContext.rounding == rounding) {
		return round(arg, getContext);
	}
	else {
		pushContext(rounding);
		Decimal value = round(arg, getContext);
		popContext;
		return value;
	}
}

/// Rounds the argument to the nearest integer. If the argument is exactly
/// half-way between two integers the even integer is returned.
public Decimal rint(const Decimal arg) {
	return round(arg, Rounding.HALF_EVEN);
}

/// Returns the nearest integer less than or equal to the argument.
/// Rounds toward negative infinity.
public Decimal floor(const Decimal arg) {
	return round(arg, Rounding.FLOOR);
}

/// Returns the nearest integer greater than or equal to the argument.
/// Rounds toward positive infinity.
public Decimal ceil(const Decimal arg) {
	return round(arg, Rounding.CEILING);
}

/// Returns the truncated argument.
/// Rounds toward zero.
public Decimal trunc(const Decimal arg) {
	return round(arg, Rounding.DOWN);
}

/// Returns the nearest int value. If the value is greater (less) than
/// the maximum (minimum) int value the maximum (minimum) value is returned.
/// The value is rounded based on the specified rounding mode. The default
/// mode is half-even.
public int toInt(const Decimal arg,
		const Rounding rounding = Rounding.HALF_EVEN) {
	if (arg.isNaN) return 0;
	if (arg.isInfinite) return arg.isNegative ? int.min : int.max;
	return toBigInt(arg, rounding).toInt;
}

/// Returns the nearest long value. If the value is greater (less) than
/// the maximum (minimum) long value the maximum (minimum) value is returned.
/// The value is rounded based on the specified rounding mode. The default
/// mode is half-even.
public long toLong(const Decimal arg,
		const Rounding rounding = Rounding.HALF_EVEN) {
	if (arg.isNaN) return 0;
	if (arg.isInfinite) return arg.isNegative ? long.min : long.max;
	return toBigInt(arg, rounding).toLong;
}

/// Returns the nearest BigInt value.
/// The value is rounded based on the specified rounding mode. The default
/// mode is half-even.
public BigInt toBigInt(const Decimal arg,
		const Rounding rounding = Rounding.HALF_EVEN) {
	if (arg.isNaN) return BigInt(0);
	if (arg.isInfinite) {
		return arg.isNegative ? Decimal.min.coefficient : Decimal.max.coefficient;
	}
	if (arg.exponent != 0) {
		return round(arg, rounding).coefficient;
	}
	return arg.coefficient;
}

unittest {	// rounding
	Decimal num;
	num = Decimal("2.1");
	assert(rint(num)  == Decimal("2"));
	assert(floor(num) == Decimal("2"));
	assert(ceil(num)  == Decimal("3"));
	assert(trunc(num) == Decimal("2"));
	num = Decimal("2.5");
	assert(rint(num)  == Decimal("2"));
	assert(floor(num) == Decimal("2"));
	assert(ceil(num)  == Decimal("3"));
	assert(trunc(num) == Decimal("2"));
	num = Decimal("3.5");
	assert(rint(num)  == Decimal("4"));
	assert(floor(num) == Decimal("3"));
	assert(ceil(num)  == Decimal("4"));
	assert(trunc(num) == Decimal("3"));
	num = Decimal("2.9");
	assert(rint(num)  == Decimal("3"));
	assert(floor(num) == Decimal("2"));
	assert(ceil(num)  == Decimal("3"));
	assert(trunc(num) == Decimal("2"));
	num = Decimal("-2.1");
	assert(rint(num)  == Decimal("-2"));
	assert(floor(num) == Decimal("-3"));
	assert(ceil(num)  == Decimal("-2"));
	assert(trunc(num) == Decimal("-2"));
	num = Decimal("-2.9");
	assert(rint(num)  == Decimal("-3"));
	assert(floor(num) == Decimal("-3"));
	assert(ceil(num)  == Decimal("-2"));
	assert(trunc(num) == Decimal("-2"));
}

//--------------------------------
// CONSTANTS
//--------------------------------

/// Template that initializes a constant value from a string.
mixin template Constant(alias str) {
	Decimal value(){
		static bool initialized = false;
		static Decimal val;
		if (!initialized) {
			int n = str.length;
			val = Decimal(false, BigInt(str), 1-n, n);
			initialized = true;
		}
		return val;
	}
}

public Decimal E() {
	mixin Constant!("27182818284590452353602874713526624977572470936999"
					"5957496696762772407663035354759457138217852516643");
	return value();
}

public Decimal LG_10() {
	mixin Constant!("33219280948873623478703194294893901758648313930245"
					"8061205475639581593477660862521585013974335937016");
	return value();
}

public Decimal LG_E() {
	mixin Constant!("14426950408889634073599246810018921374266459541529"
					"8593413544940693110921918118507988552662289350634");
	return value();
}

public Decimal LOG_E() {
	mixin Constant!("43429448190325182765112891891660508229439700580366"
					"6566114453783165864649208870774729224949338431748");
	return value();
}

public Decimal LOG_2() {
	mixin Constant!("030102999566398119521373889472449302676818988146210"
					"8541310427461127108189274424509486927252118186172");
	return value;
}

public Decimal LN2() {
	mixin Constant!("069314718055994530941723212145817656807550013436025"
					"5254120680009493393621969694715605863326996418688");
	return value;
}

public Decimal LN10() {
	mixin Constant!("23025850929940456840179914546843642076011014886287"
					"7297603332790096757260967735248023599720508959820");
	return value;
}

public Decimal PI() {
	mixin Constant!("31415926535897932384626433832795028841971693993751"
					"0582097494459230781640628620899862803482534211707");
	return value;
}

public Decimal PI_2() {
	mixin Constant!("15707963267948966192313216916397514420985846996875"
					"5291048747229615390820314310449931401741267105853");
	return value;
}

public Decimal PI_4() {
	mixin Constant!("078539816339744830961566084581987572104929234984377"
					"6455243736148076954101571552249657008706335529267");
	return value;
}

public Decimal INV_PI() {
	mixin Constant!("031830988618379067153776752674502872406891929148091"
					"2897495334688117793595268453070180227605532506172");
	return value;
}

public Decimal INV_2PI() {
	mixin Constant!("015915494309189533576888376337251436203445964574045"
					"6448747667344058896797634226535090113802766253086");
	return value;
}

public Decimal INV2_SQRTPI() {
	mixin Constant!("11283791670955125738961589031215451716881012586579"
					"9771368817144342128493688298682897348732040421473");
	return value;
}

public Decimal SQRT2() {
	mixin Constant!("14142135623730950488016887242096980785696718753769"
					"4807317667973799073247846210703885038753432764157");
	return value;
}

public Decimal SQRT1_2() {
	mixin Constant!("070710678118654752440084436210484903928483593768847"
					"4036588339868995366239231053519425193767163820786");
	return value;
}

unittest {
	writeln("mixin...");
writefln("E     = %s", E);
writefln("LN2   = %s", LN2());
writefln("LN10  = %s", LN10);
writefln("LOG_E = %s", LOG_E);
writefln("LOG_2 = %s", LOG_2);
writefln("LG_E  = %s", LG_E);
writefln("SQRT2 = %s", SQRT2());
writefln("LG_10 = %s", LG_10);
writefln("LOG_2 = %s", LOG_2);
	writeln("test missing");
}

unittest {	// E
	assert(E.digits == 99);
	assert(numDigits(E.coefficient) == 99);
}

/// Returns the value of e at the specified precision.
public Decimal e(uint precision) {
	static int lastPrecision = 0;
	static Decimal value;
	if (precision != lastPrecision) {
		pushContext(precision);
		value = e();
		popContext();
		lastPrecision = precision;
	}
	return value;
}

/// Returns the value of e at the current precision.
public Decimal e() {
	static int lastPrecision = 0;
	static Decimal value;
	int precision = getContext.precision;
	if (precision != lastPrecision) {
		if (precision > 99) {
			value = e0();
		}
		else {
			value = roundToPrecision(E);
		}
		lastPrecision = precision;
	}
	return value;
}

/// Calculates and returns the value of e at the current precision.
private Decimal e0() {
	long n = 1;
//	Decimal fact = 1;
	Decimal term = 1;
	Decimal sum  = 1;
	while (term > Decimal.epsilon) {
		sum += term;
//		n++;
		// TODOD: should be able to write "term /= ++n;"
		term = term / ++n;
//		fact = fact * n;
//		term = Decimal(1.0)/fact;
	}
	return sum;
}

unittest {
	write("e.............");
writeln;
writefln("E      = %s", E);
writefln("e      = %s", e(35));
	pushContext(199);
	getContext.maxExpo = 250;
writefln("e0()  = %s", e0());
	popContext;
writefln("e(5)  = %s", e(5));
	writeln("test missing");
}

public Decimal sqr(const Decimal x) {
	return decimal.arithmetic.sqr(x);
}

unittest {
	write("sqr............");
	writeln("test missing");
}

unittest {	// PI
	assert(PI.digits == 99);
	assert(numDigits(PI.coefficient) == 99);
}

/// Returns the value of pi to the specified precision.
public Decimal pi(uint precision) {
	static int lastPrecision = 0;
	static Decimal value;
	if (precision != lastPrecision) {
		pushContext(precision);
		value = pi();
		popContext();
		lastPrecision = precision;
	}
	return value;
}

/// Returns the value of pi to the current precision.
public Decimal pi() {
	static int lastPrecision = 0;
	static Decimal value;
	int precision = getContext.precision;
	if (precision != lastPrecision) {
		if (precision > 99) {
			value = pi0();
		}
		else {
			value = roundToPrecision(PI, getContext);
		}
		lastPrecision = precision;
	}
	return value;
}

/// Calculates the value of pi to the current precision.
public Decimal pi0() {
	const Decimal one = Decimal(1);
	const Decimal two = Decimal(2L);
	const Decimal four = Decimal(4L);
	Decimal a = one.dup;
	Decimal b = a / sqrt(two); // TODO: use sqrt2 constant
	Decimal t = one/four;
	Decimal x = one.dup;
	while (a != b) {
		Decimal y = a;    // save the value of a
		a = (a + b)/two;     // arithmetic mean
		b = sqrt(b * y);       // geometric mean
		t -= x * (sqr(a) - sqr(b));  // weighted sum of the difference of the means
		// TODO: x = 2;
		x = x * 2;
	}
	Decimal result = sqr(a+b)/(four*t);
	return result;
}

unittest {
	write("pi.............");
writeln;
writefln("PI      = %s", PI);
writefln("pi      = %s", pi);
writefln("pi(25)  = %s", pi(25));
	writeln("test missing");
}

private bool odd(int n) {
	return std.math.abs(n % 2) != 0;
}

unittest {	// odd
	assert(odd(3));
	assert(!odd(8));
}

public Decimal sqrt(const Decimal arg, uint precision) {
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
public Decimal sqrt(const Decimal x) {
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
//writefln("i = %s", i);
	return r;
}

unittest {
	write("sqrt...........");
writeln;
writefln("sqrt(2, 29)     = %s", sqrt(Decimal(2), 29));
writefln("sqrt(200, 29)   = %s", sqrt(Decimal(200), 29));
writefln("sqrt(25, 29)    = %s", sqrt(Decimal(25), 29));
writefln("sqrt(2E-5, 29)  = %s", sqrt(Decimal(2E-5), 29));
writefln("sqrt(1E-15, 29) = %s", sqrt(Decimal(1E-15), 29));
writefln("sqrt(1E-16, 29) = %s", sqrt(Decimal(1E-16), 29));
	writeln("test missing");
}

public Decimal reciprocalA(const Decimal x) {
	return Decimal(1)/x;
}

public Decimal reciprocal(const Decimal a) {
	// TODO: need to set flags, etc.
	if (a.isNaN) return Decimal.nan;
	if (a.isZero) {
		contextFlags.setFlags(DIVISION_BY_ZERO);
		return Decimal.infinity(a.sign);
	}
	if (a.isInfinite) return Decimal.zero(a.sign);
	// TODO: need to fix opEquals: if (a.abs == 1)...
	Decimal r = copyAbs(a);
	if (r == Decimal(1)) return a.dup;

	pushContext(getContext.precision+2);
	Decimal xOld = Decimal(1, -ilogb(a)-1);  	// FIXTHIS: need pow2 like pow10?
	Decimal xNew;// = xOld;
	Decimal ek = 1 - xOld * a;
//	while (xNew != xOld) { //ek > Decimal.epsilon) {
//	while (ek > Decimal.epsilon) {
	for (int i = 0; i < 10; i++) {
//		ek = 1 - xOld * a;
		xNew = xOld *(2 - a*xOld);
		if (xNew == xOld) break;
		xOld = xNew;
	}
	popContext;
	return reduce(roundToPrecision(xNew));
}

public Decimal reciprocal(const Decimal x, uint precision) {
	pushContext(precision);
	Decimal value = reciprocal(x);
	popContext();
	return value;
}

unittest {
	writeln("reciprocal...");
writefln("reciprocalA(Decimal(2.5)) = %s", reciprocalA(Decimal(2.5)));
writefln("reciprocal(Decimal(2.5)) = %s", reciprocal(Decimal(2.5)));
writefln("reciprocalA(Decimal(250)) = %s", reciprocalA(Decimal(250)));
writefln("reciprocal(Decimal(250)) = %s", reciprocal(Decimal(250)));
writefln("reciprocalA(Decimal(.025)) = %s", reciprocalA(Decimal(".025")));
writefln("reciprocal(Decimal(.025)) = %s", reciprocal(Decimal(".025")));
	writeln("test missing");
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
    return a * sqrt(one + sqr(b));
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

public Decimal exp(const Decimal arg, const uint precision) {
	pushContext(precision);
	Decimal value = exp(arg);
	popContext();
	return value;
}

/// Decimal version of std.math function.
/// Required by General Decimal Arithmetic Specification
public Decimal exp(const Decimal x) {
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
public Decimal exp2(Decimal arg) {
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
public Decimal expm1(Decimal arg) {
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
public Decimal log(const Decimal arg) {
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
public Decimal log1p(Decimal arg) {
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
public Decimal log10(Decimal arg) {
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
public Decimal log2(Decimal arg) {
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
public Decimal pow(Decimal op1, Decimal op2) {
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
public Decimal power(Decimal op1, Decimal op2) {
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


// Returns the argument reduced to 0 <= pi/4 and sets the octant.
private Decimal reducedAngle(const Decimal x, out int octant) {
	Decimal x2 = 4*x/pi;
	Decimal ki = trunc(x2);
	int k2 = trunc(x2).coefficient.toInt;
	if (k2 < 0) k2 = 1 - k2;
	Decimal red = pi/4 * (x2 - k2);
	octant = k2 % 8;
	return red;
}

unittest {
	writeln("range reduction...");
/*	Decimal deg = Decimal("180")/pi;
	int octant;
	for (int x = 0; x <= 720; x += 35) {
		Decimal xr = x/deg;
		Decimal y = reducedAngle(xr, octant);
		Decimal yd = y*deg;
		writefln("   x = %s, y = %s, octant = %s", x, rint(yd), octant);
		y = reducedAngleOld(xr, octant);
		yd = y*deg;
		writefln("-- x = %s, y = %s, octant = %s", x, rint(yd), octant);
	}*/
	writeln("passed");
}

/// Decimal version of std.math function.
public Decimal sin(const Decimal x) {
	int octant;
	Decimal rx = reducedAngle(x, octant);
	switch(octant) {
		case 0: return( sin0( rx));
		case 1: return( cos0(-rx));
		case 2: return( cos0( rx));
		case 3: return( sin0(-rx));
		case 4: return(-sin0( rx));
		case 5: return(-cos0(-rx));
		case 6: return(-cos0( rx));
		case 7: return(-sin0(-rx));
		default: return Decimal.nan;
	}
}

/// Decimal version of std.math function.
public Decimal sin(const Decimal arg, uint precision) {
	pushContext(precision);
	Decimal value = sin(arg);
	popContext();
	return value;
}

/// Decimal version of std.math function.
public Decimal sin0(const Decimal x) {
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

unittest {
	write("sin..........");
	writeln;
	writeln("sin(1) = 0.84147098480789650665250232163029899962256306079837");
	pushContext(50);
	writefln("sin0(1) = %s", sin0(Decimal(1)));
//	Decimal test = Decimal(10,22);
//	writefln("sin(10^^22) = %s", sin(test));
	Decimal test = Decimal("22000.12345");
	writeln("sin(22) = -0.008851309290403875921690256815772332463289203951");
	writefln("sin(22) = %s", sin(test));
/*
//	popContext();
	writefln("sin(101.23456789) = %s", sin(Decimal("101.23456789"), 25));
	writefln("sin(pi + 1.0) = %s", sin(pi(25) + Decimal("1.0"),25));

	writeln("..failed");*/
}

/// Decimal version of std.math function.
public Decimal cos(const Decimal x) {
	int octant;
	Decimal y = reducedAngle(x, octant);
	switch(octant) {
		case 0: return(cos0(y));
		case 1: return(sin0(-y));
		case 2: return(-sin0(y));
		case 3: return(-cos0(-y));
		case 4: return(-cos0(y));
		case 5: return(-sin0(-y));
		case 6: return(sin0(y));
		case 7: return(cos0(-y));
		default: return Decimal.nan;
	}
}

/// Decimal version of std.math function.
public Decimal cos(const Decimal x, uint precision) {
	pushContext(precision);
	Decimal value = cos(x);
	popContext();
	return value;
}

/// Decimal version of std.math function.
public Decimal cos0(const Decimal x) {
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

unittest {
	write("cos..........");
	writeln;
	writeln("cos(1) = 0.54030230586813971740093660744297660373231042061792");
	pushContext(50);
	writefln("cos(1) = %s", cos0(Decimal(1)));
	popContext();
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
public Decimal tan(Decimal x) {
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
public Decimal asin(Decimal arg) {
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
public Decimal acos(Decimal arg) {
	Decimal result;
	return result;
}

unittest {
	write("acos.........");
	writeln("..failed");
}


/// Decimal version of std.math function.
// TODO: only valid if x < 1.0; convergence very slow if x ~ 1.0;
public Decimal atan(Decimal x) {
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
public Decimal atan2(Decimal y, Decimal x) {
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
public Decimal sinh(Decimal x) {
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
public Decimal cosh(Decimal x) {
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
public Decimal tanh(Decimal x) {
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
public Decimal asinh(Decimal arg) {
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
public Decimal acosh(Decimal arg) {
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
public Decimal atanh(Decimal arg) {
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
public Decimal ln(Decimal op1) {
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



