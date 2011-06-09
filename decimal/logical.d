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
module decimal.logical;

import decimal.decimal;
import decimal.context;
import decimal.digits;
import decimal.arithmetic;


/**
 * isLogical.
 */
bool isLogical(const Decimal num) {
    return false;
}

unittest {
    write("isLogical...");
    writeln("test missing");
}


/**
 * Decimal version of and.
 * Required by General Decimal Arithmetic Specification
 */
Decimal and(Decimal op1, Decimal op2) {
    Decimal result;
    return result;
}

unittest {
    write("and...");
    writeln("test missing");
}

/**
 * Decimal version of invert.
 * Required by General Decimal Arithmetic Specification
 */
Decimal invert(Decimal op1) {
    Decimal result;
    return result;
}

unittest {
    write("invert...");
    writeln("test missing");
}

/**
 * Decimal version of or.
 * Required by General Decimal Arithmetic Specification
 */
Decimal or(Decimal op1, Decimal op2) {
    Decimal result;
    return result;
}

unittest {
    write("or...");
    writeln("test missing");
}

/**
 * Decimal version of xor.
 * Required by General Decimal Arithmetic Specification
 */
Decimal xor(Decimal op1, Decimal op2) {
    Decimal result;
    return result;
}

unittest {
    write("xor...");
    writeln("test missing");
}


