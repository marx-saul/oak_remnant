module scope_;

import ast;

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

class Scope {
	SCKind kind;						/// Kind of the scope
	ASTNode body;						/// Corresponding ASTNode of this scope
	Scope enclosing;					/// Lexically enclosing scope
	//Module module_;					/// The module we are in
	
	//inout @property Module isModule() { return kind == SCKind.func ? cast(typeof(return)) this.body : null; }
	inout @property StructDeclaration 	isStructDeclaration() 	{ return kind == SCKind.struct_ ? cast(typeof(return)) this.body : null; }
	inout @property ScopeSymbol 		isScopeSymbol() {
		import std.algorithm : among;
		with (SCKind)
		return kind.among!(
			struct_,
		) != 0 ? cast(typeof(return)) this.body : null;
	}
	
	/// search an identifier
	Symbol search(Identifier id) {
		if (id.is_global) { assert(0); }
		
		// go up the scope
		for (auto sc = this; sc; sc = sc.enclosing) {
			assert (sc !is sc.enclosing);
			
			
			// searching
			if (auto scs = isScopeSymbol()) {
				if (auto result_sym = scs.isDeclared(id.name))
					return result_sym;
				else continue;
			}
		}
		return null;
	}
}
