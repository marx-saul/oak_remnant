module semantic.scope_;

import ast.ast;

enum SCKind {
	//module_,	/// module
	struct_,	/// struct declaration
	//union_,
	//class_,
	//interface_,
	//staticif,
}

enum SCP : ulong {
	inlambda = 1UL,
}

final class Scope {
	Scope enclosing;					/// Lexically enclosing scope
	ScopeSymbol scsym;					/// corresponding scope-symbol
	Module module_;						/// the module we are in
	FuncDeclaration func;				/// the function declaration we are in
	
	this (Scope enclosing, ScopeSymbol scsym) {
		this.enclosing = enclosing;
		this(scsym);
	}
	this (ScopeSymbol scsym) {
		this.scsym = scsym;
	}
	
	/// search for an identifier
	/// Returns: null if not found, symbol if found
	Symbol search(Identifier id) inout const {
		auto sc = cast(Scope)this;
		while (sc) {
			assert(sc !is sc.enclosing);
			sc = sc.enclosing;
		}
		return null;
	}
}
