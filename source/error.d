module message;

import std.stdio;

void error(string[] msgs...) {
	foreach (msg; msgs) {
		write(msg);
	}
	writeln();
}
