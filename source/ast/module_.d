module ast.module_;

import token: Location;
import ast.astnode;
import ast.symbol;
import visitor.visitor;

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

class Package : ScopeSymbol {
	Package parent;		// parent package
	
	this (Location loc, string name, Symbol[] members) {
		super(SYMKind.package_, Identifier(name, loc), members);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class Module : Package {
	string[] names;					/// full name of this module
	bool syntax_error = false;		/// does this module contain any syntax errors
	string path;					/// path to this file "/.../pack/mod.oak"
    bool is_package = false;		/// is this module /.../package.oak
	
	/**
	 * Params:
	 *     loc : Location of the top module token
	 *     names : ["aaa", "bbb", "ccc"] of module aaa.bbb.ccc;
	 *     members : declared symbols
	 */
	this (Location loc, string[] names, Symbol[] members) {
		if (names.length > 0) {
			super(loc, names[$-1], members);
		}
        else {
			// currently.
			super(loc, getFileName(loc.path), members);
		}
        
		this.kind = SYMKind.module_;
		this.names = names;
	}
    /**
	 * Params:
	 *     source = the range of the source code
	 *     filepath = the path of this module
	 * Returns:
	 *     resulting module
	 */
	static Module parse(Range)(Range source, string filepath) {
		auto parser = new Parser!Range(source);
		auto result = parser.parseModule();
		result.syntax_error = parser.is_error;
		return result;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}