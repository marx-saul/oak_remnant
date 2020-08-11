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
	write("\x1b[1m", loc.path, "(", loc.line_num, ":", loc.index_num, "):\x1b[0m ");
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
	write("\x1b[1m", loc.path, "(", loc.line_num, ":", loc.index_num, "):\x1b[0m ");
	write("\x1b[33mWarning:\x1b[0m ");
	show_message(msgs);
}

private void show_message(string[] msgs...) {
	foreach (msg; msgs) {
		write(msg);
	}
	writeln();
}
