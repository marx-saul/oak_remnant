/**
 * message.d
 * Yields error messages.
 */
module message;

import token: Location;
import std.stdio;

/**
 * Display error message.
 * Params:
 * 		loc  = the location of the error
 * 		msgs = error messages
 */
void error(Location loc, string[] msgs...) {
	write(loc.toString(), ": ");
	write("\x1b[31mError:\x1b[0m ");
	show_message(msgs);
}
/**
 * Display Warning message.
 * Params:
 * 		loc  = the location of the warning
 * 		msgs = warning messages
 */
void warning(Location loc, string[] msgs...) {
	write(loc.toString(), ": ");
	write("\x1b[33mWarning:\x1b[0m ");
	show_message(msgs);
}

private void show_message(string[] msgs...) {
	foreach (msg; msgs) {
		write(msg);
	}
	writeln();
}

/**
 * Display currently called function for debugging.
 */
void semlog(T...)(T args) {
	if (leave_log) writeln(args);
}
private auto leave_log = true; // currently