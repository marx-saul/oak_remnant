module symbol;

import token;
import ast;
import scope_;
import visitor;
import semantic;

/// Struct for identifiers
struct Identifier {
	string name;		/// string of the identifier
	Location loc;		/// the location of the identifier
	bool is_global;		/// true iff the identifier is accessed globally (i.e. _.foo)
}

/// Kind of symbols
enum SYMKind {
	unsolved,			/// unsolved symbol
	var,				/// defined by `let x:T = E;`
	arg,				/// function argument
	func,				/// defined by `func f ...`
	typedef,			/// defined by typedef T = S;
	struct_,			/// defined by struct S { ... }
	template_,
	instance,
	module_,			/// modules
}

/// Symbol class
class Symbol : ASTNode {
	SYMKind kind;									/// kind of this identifier
	Identifier id;									/// identifier
	Location loc() @property { return id.loc; }		/// location
	Symbol parent;									/// if this = <aa.bb.cc> then parent = <aa.bb>
	
	PASS pass = PASS.init;							/// semantic pass that is currently run on this symbol
	Scope semsc;									/// used for semantic analysis
	
	this (SYMKind kind, Identifier id) {
		this.kind = kind, this.id = id;
	}
	this (SYMKind kind, string name, Location loc=Location.init) {
		this(kind, Identifier(name, loc));
	}
	
	/// string of this identifier
	string thisString() inout const {
		if (id.is_global)
			return "_." ~ id.name;
		else
			return id.name;
	}
	/// whole string of this symbol
	final string recoverString() inout const {
		if (parent)
			return parent.recoverString() ~ "." ~ thisString();
		else if (id.is_global)
			return "_." ~ thisString();
		else
			return thisString();
	}

	/// Get the top symbol.
	final inout(Symbol) topSymbol() @property inout const {
		Symbol result = cast(Symbol) this;
		while (result.parent !is null) {
			assert(result !is result.parent);
			result = result.parent;
		}
		return cast(inout)result;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}


/// Symbol that introduces scopes
class ScopeSymbol : Symbol {
	this (SYMKind kind, Identifier id) {
		super(kind, id);
	}
	this (SYMKind kind, string name, Location loc=Location.init) {
		super(kind, Identifier(name, loc));
	}
	
	Symbol isDeclared(string name) {
		assert(0);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}


/// Symbol table
class SymbolTable {
	/// store all identifiers and their declarations
	private Symbol[string] dictionary;
	
	/// add a symbol.
	/// Returns: false iff the name collides.
	bool add(Symbol sym) {
		assert(sym);
		if (sym.id.name in dictionary) {
			return false;
		}
		dictionary[sym.id.name] = sym;
		return true;
	}
	
	/// get the symbol.
	/// Returns: null if the name has not been declared.
	Symbol get(string name) {
		auto p = name in dictionary;
		return p ? *p : null;
	}
}
