/**
 * A D programming language implementation of the
 * General Decimal Arithmetic Specification,
 * Version 1.70, (25 March 2009).
 * (http://www.speleotrove.com/decimal/decarith.pdf)
 *
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: Paul D. Anderson
 */
/*			Copyright Paul D. Anderson 2009 - 2012.
 * Distributed under the Boost Software License, Version 1.0.
 *	  (See accompanying file LICENSE_1_0.txt or copy at
 *			http://www.boost.org/LICENSE_1_0.txt)
 */

module decimal.utils;

import std.stdio;

bool assertEqual(T)(T expected, T actual,
		string file = __FILE__, int line = __LINE__ ) {
	if (expected == actual) {
		return true;
	}
	writeln("failed at ", std.path.basename(file), "(", line, "):",
	        " expected \"", expected, "\"",
	        " but found \"", actual, "\".");
	return false;
}

bool assertStringEqual(T)(T expected, T actual,
		string file = __FILE__, int line = __LINE__ ) {
	if (expected.toString == actual.toString) {
		return true;
	}
	writeln("failed at ", std.path.basename(file), "(", line, "):",
	        " expected \"", expected, "\"",
	        " but found \"", actual, "\".");
	return false;
}

/*bool assertEqual(T)(T expected, T actual,
		string file = __FILE__, int line = __LINE__ ) {
	if (expected == actual) {
		return true;
	}
	writeln("failed at ", std.path.basename(file), "(", line, "):",
	        " expected \"", expected, "\"",
	        " but found \"", actual, "\".");
	return false;
}*/

bool assertNotEqual(T)(T unexpected, T actual,
		string file = __FILE__, int line = __LINE__ ) {
	if (unexpected == actual) {
		writeln("failed at ", std.path.basename(file), "(", line, "):",
	        	" \"", unexpected, "\" is equal to \"", actual, "\".");
		return false;
	}
	return true;
}

bool assertTrue(bool actual, string file = __FILE__, int line = __LINE__ ) {
	return assertEqual(true, actual, file, line);
}

bool assertFalse(bool actual, string file = __FILE__, int line = __LINE__ ) {
	return assertEqual(false, actual, file, line);
}

