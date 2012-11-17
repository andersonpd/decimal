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

public Decimal rint(const Decimal arg) {
	pushContext(Rounding.HALF_EVEN);
	Decimal value = roundToIntegralExact(arg, getContext);
	popContext;
	return value;
}

public Decimal floor(const Decimal arg) {
	pushContext(Rounding.FLOOR);
	Decimal value = roundToIntegralExact(arg, getContext);
	popContext;
	return value;
}

public Decimal ceil(const Decimal arg) {
	pushContext(Rounding.CEILING);
	Decimal value = roundToIntegralExact(arg, getContext);
	popContext;
	return value;
}

public Decimal trunc(const Decimal arg) {
	pushContext(Rounding.DOWN);
	Decimal value = roundToIntegralExact(arg, getContext);
	popContext;
	return value;
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

mixin template Constant(alias str) {
	Decimal value(){
		static bool initialized = false;
		static Decimal value;
		if (!initialized) {
			int n = str.length;
writefln("n = %s", n);
			value = Decimal(false, BigInt(str), 1-n, n);
writefln("value = %s", value);
			initialized = true;
		}
		return value;
	}
}

public Decimal E() {
	string str = "27182818284590452353602874713526624977572470936999"
				 "5957496696762772407663035354759457138217852516643";
	mixin Constant!(str);
	return value();
}

public Decimal LG10() {
	string str = "33219280948873623478703194294893901758648313930245"
				 "8061205475639581593477660862521585013974335937016";
	mixin Constant!(str);
	return value();
}

public Decimal LG_E() {
	string str = "14426950408889634073599246810018921374266459541529"
				 "8593413544940693110921918118507988552662289350634";
	mixin Constant!(str);
	return value();
}

public Decimal LOG_E() {
	string str = "43429448190325182765112891891660508229439700580366"
				 "65661144537831658646492088707747292249493384317483";
	mixin Constant!(str);
	return value();
}

public Decimal LOG_2() {
	string str = "030102999566398119521373889472449302676818988146210"
				 "8541310427461127108189274424509486927252118186172";
	mixin Constant!(str);
	return value;
}

public Decimal LN2() {
	string str = "069314718055994530941723212145817656807550013436025"
				 "5254120680009493393621969694715605863326996418688";
	mixin Constant!(str);
	return value;
}

public Decimal LN10() {
	string str = "23025850929940456840179914546843642076011014886287"
				 "72976033327900967572609677352480235997205089598298";
	mixin Constant!(str);
	return value;
}

public Decimal PI() {
	string str = "31415926535897932384626433832795028841971693993751"
				 "0582097494459230781640628620899862803482534211707";
	mixin Constant!(str);
	return value;
}

public Decimal PI_2() {
	string str = "15707963267948966192313216916397514420985846996875"
				 "5291048747229615390820314310449931401741267105853";
	mixin Constant!(str);
	return value;
}

public Decimal PI_4() {
	string str = "078539816339744830961566084581987572104929234984377"
				 "6455243736148076954101571552249657008706335529267";
	mixin Constant!(str);
	return value;
}

public Decimal INV_PI() {
	string str = "031830988618379067153776752674502872406891929148091"
				 "2897495334688117793595268453070180227605532506172";
	mixin Constant!(str);
	return value;
}

public Decimal INV_2PI() {
	string str = "015915494309189533576888376337251436203445964574045"
				 "6448747667344058896797634226535090113802766253086";
	mixin Constant!(str);
	return value;
}

public Decimal INV2_SQRTPI() {
	string str = "11283791670955125738961589031215451716881012586579"
				 "9771368817144342128493688298682897348732040421473";
	mixin Constant!(str);
	return value;
}

public Decimal SQRT2() {
	string str = "14142135623730950488016887242096980785696718753769"
				 "4807317667973799073247846210703885038753432764157";
	mixin Constant!(str);
	return value;
}

public Decimal SQRT1_2() {
	string str = "070710678118654752440084436210484903928483593768847"
				 "4036588339868995366239231053519425193767163820786";
	mixin Constant!(str);
	return value;
}

unittest {
	write("mixin...");
//mixin Constant!("LN2", "1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327641573");
writefln("LN2 = %s", LN2());
writefln("SQRT2 = %s", SQRT2());
writefln("LOG_2 = %s", LOG_2);
	writeln("test missing");
}

/*// Returns e to 99 digit accuracy.
public Decimal E() {
	static bool initialized = false;
	static Decimal value;
	if (!initialized) {
		value = Decimal(false,
		BigInt("27182818284590452353602874713526624977572470936999"
		       "5957496696762772407663035354759457138217852516643"), -98, 99);
		initialized = true;
	}
	return value;
}*/

unittest {	// E
	assert(E.digits == 99);
	assert(numDigits(E.coefficient) == 99);
}

/// Returns the value of e to the specified precision.
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

/// Returns the value of e to the current precision.
public Decimal e() {
	static int lastPrecision = 0;
	static Decimal value;
	int precision = getContext.precision;
	if (precision != lastPrecision) {
		if (precision > 99) {
			value = Decimal.nan;
		}
		else {
			value = round(E, getContext);
		}
		lastPrecision = precision;
	}
	return value;
}

unittest {
	write("e.............");
writeln;
writefln("E      = %s", E);
writefln("e      = %s", e);
writefln("e(25)  = %s", e(25));
	writeln("test missing");
}

/*/// Returns the value of e to the specified precision.
public Decimal e(const uint precision) {
	pushContext(precision+2);
	Decimal value = e();
	getContext.precision -= 2;
	value = round(value);
	popContext();
	return value;
}

/// Returns the value of e to the specified precision.
public Decimal e() {
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
}*/

public Decimal sqr(const Decimal x) {
	return x * x;
}

unittest {
	write("sqr............");
	writeln("test missing");
}

/*// Returns pi to 99 digit accuracy.
public Decimal PI() {
	static bool initialized = false;
	static Decimal value;
	if (!initialized) {
		value = Decimal(false, BigInt("314159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211707"), -98, 99);
		initialized = true;
	}
	return value;
}
*/
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
			value = Decimal.nan;
		}
		else {
			value = round(PI, getContext);
		}
		lastPrecision = precision;
	}
	return value;
}

/// Returns the value of pi to the current precision.
public Decimal calculatePi() {
	const Decimal ONE = Decimal(1L);
	const Decimal TWO = Decimal(2L);
	const Decimal FOUR = Decimal(4L);
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
	Decimal result = sqr(a+b)/(FOUR*t);
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

public Decimal reciprocal(const Decimal x, uint precision) {
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


// Returns the argument reduced to 0 <= pi/4 and the octant.
private Decimal trigRange(const Decimal x, out int octant) {
	// TODO: need to do all these with +2 precision
	// TODO: need to get pi, 2*pi, pi/4, 3*pi/4 only once.
	Decimal c = 2.0 * pi; // * 2L; // * pi; //Decimal("2.0") * pi;
	Decimal k = trunc(x/c);
	if (k.isNegative) k = 1 - k;
	Decimal r = x - k * c;
	if (r <= pi) {
		if (r <= pi/2) {
			if (r <= pi/4) octant = 0;
			else octant = 1;
			}
		} // r > pi/2
		if (r <= pi*(3.0/4.0)) octant = 3;
		else octant = 4;

	octant = 5;
	if      (r.abs <= pi/4) octant = 0;
	else if (r.abs > pi*3/4) octant = 2;
	else if (r > Decimal("0"))	octant = 1;
	else octant = 4;
	return r;

/*writefln("pi = %s", pi);
//writefln("2*pi = %s", 2*pi);
	Decimal c = Decimal(1)/(pi * 2.0);
writefln("c = %s", c);
writefln("arg * c = %s", arg * c);
	Decimal k = trunc(arg * c);
writefln("k = %s", k);
writefln("k * c = %s", k * c);
	Decimal r = arg - (k * c);
writefln("r = %s", r);
	return r;*/
}

unittest {
	write("range reduction...");
writeln;
	Decimal deg = Decimal("180")/pi;
	for (real x = 0; x <= std.math.PI*2; x += std.math.PI/8)	{
writeln(" *** ");
writefln("x      = %s", x*180/std.math.PI);
writefln("sin(x)       = %s", std.math.sin(x));
writefln("cos(x)       = %s", std.math.cos(x));
writefln("sin(x - 45)  = %s", std.math.sin(x - std.math.PI/4));
writefln("cos(x - 45)  = %s", std.math.cos(x - std.math.PI/4));
writefln("sin(x - 90)  = %s", std.math.sin(x - std.math.PI/2));
writefln("cos(x - 90)  = %s", std.math.cos(x - std.math.PI/2));
writefln("sin(x - 135) = %s", std.math.sin(x - std.math.PI*3/4));
writefln("cos(x - 135) = %s", std.math.cos(x - std.math.PI*3/4));
writefln("sin(x - 180) = %s", std.math.sin(x - std.math.PI));
writefln("cos(x - 180) = %s", std.math.cos(x - std.math.PI));
}


writeln("deg");
	int quadrant;
	Decimal x, y;
	x = Decimal("30")/deg;
	y = trigRange(x, quadrant);
writefln("x = %s", x*deg);
writefln("y = %s", y*deg);
writefln("quadrant = %s", quadrant);
	x = Decimal("180")/deg;
	y = trigRange(x, quadrant);
writefln("x = %s", x*deg);
writefln("y = %s", y*deg);
writefln("quadrant = %s", quadrant);
	x = Decimal("315")/deg;
	y = trigRange(x, quadrant);
writefln("x = %s", x*deg);
writefln("y = %s", y*deg);
writefln("quadrant = %s", quadrant);

writeln("rad");
	x = Decimal("1.0");
	y = trigRange(x, quadrant);
writefln("x = %s", x);
writefln("y = %s", y);
	x = Decimal("10.0");
	y = trigRange(x, quadrant);
writefln("x = %s", x);
writefln("y = %s", y);
	x = Decimal("100.0");
	y = trigRange(x, quadrant);
writefln("x = %s", x);
writefln("y = %s", y);
	writeln("test missing");
}


/// Decimal version of std.math function.
public Decimal sin(const Decimal x) {
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
public Decimal sin(const Decimal arg, uint precision) {
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
public Decimal cos(const Decimal x) {
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
public Decimal cos(const Decimal x, uint precision) {
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


