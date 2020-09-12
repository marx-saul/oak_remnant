module global;

import ast.symbol : Identifier;

private string _root_path;			// the root path of the source code folder
private string[] _library_paths;	// paths that the compiler look into 

public string root_path() @property {
	return _root_path;
}

public string[] library_paths() @property {
	return _library_paths;
}

/// "/foo/bar/baz.oak -> baz"
pure string getFileName(string path) {
	string result;
	string extended;
	foreach_reverse (ch; path) {
		if (ch == '/') break;
		extended = ch ~ extended;
	}
	foreach (ch; extended) {
		if (ch == '.') break;
		result ~= ch;
	}
	return result;
}


pure string toPath(string[] names) {
	return "";
}

/// ["foo", "bar", "baz"] -> "foo.bar.baz"
pure auto dotcat(inout string[] names) {
	if (names.length == 0) return "";
	string result = names[0];
	foreach (name; names[1..$]) result ~= "." ~ name;
	return result;
}

pure auto dotcat(inout Identifier[] idents) {
	if (idents.length == 0) return "";
	string result = idents[0].name;
	foreach (ident; idents[1..$]) result ~= "." ~ ident.name;
	return result;
}

/// "foo.bar.baz" -> ["foo", "bar", "baz"]
pure string[] dotsep(inout string name) {
	import std: split, to;
	return name.split('.').to!(string[]);
}