module ast.module_;

import token: Location;
import ast.astnode;
import ast.symbol;
import visitor.visitor;

final class Module : ScopeSymbol {
	string[] names;					/// full name of this module
	Package parent;					/// parent package
	SymbolTable symbols;			/// symbol table of declared symbols
	bool syntax_error = false;		/// does this module contain any syntax errors
    
	/**
	 * Params:
	 *     loc : Location of the top module token
	 *     names : ["aaa", "bbb", "ccc"] of module aaa.bbb.ccc;
	 *     decls : declared symbols
	 */
	this (Location loc, string[] names, Symbol[] members) {
		if (names.length > 0)
			super(SYMKind.module_, Identifier(names[$-1], loc), members);
        else
			// currently.
			super(SYMKind.module_, Identifier(loc.path, loc), members);
        
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

final class Package : ScopeSymbol {
	Package parent;		// parent package
	SymbolTable children;	// symbol table of descendant modules and packages 
	
	this (Location loc, string name, Symbol[] members) {
		super(SYMKind.package_, Identifier(name, loc), members);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}