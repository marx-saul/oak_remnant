/**
 * ast/symbol.d
 * defines Symbol, SymbolScope classes and SymbolTable class.
 */
module ast.symbol;

import message;
import token;
import ast.ast;
import semantic.scope_;
import visitor.visitor;
import semantic.semantic;

/// Struct for identifiers
struct Identifier {
	string name;		/// string of the identifier
	Location loc;		/// the location of the identifier
	bool is_global;		/// true iff the identifier is accessed globally (i.e. _.foo)
}

/// Kind of symbols
enum SYMKind {
	unsolved,			/// unsolved symbol
	var,				/// variables : defined by `let x:T = E;`
	arg,				/// function argument
	func,				/// function : defined by `func f ...`
	typedef,			/// typedef-ed type : defined by typedef T = S;
	struct_,			/// struct : defined by struct S { ... }
	union_,
	class_,
	interface_,
	template_,			/// template : defined by template T { ... }
	instance,			/// T!(...)
	module_,			/// modules
	package_,			/// packages
	
	mixin_,
	template_mixin,
	staticif,
	version_,
	debug_,
}

/// Symbol class
class Symbol : ASTNode {
	SYMKind kind;									/// kind of this identifier
	Identifier id;									/// identifier
	Location loc() @property { return id.loc; }		/// location
	
	PASS pass = PASS.init;							/// semantic pass that is currently run on this symbol
	Scope semsc;									/// the scope this symbol belongs to or this symbol generates(when it is a scope-symbol)
	Symbol parent;									/// parent symbol.
	
	this (SYMKind kind, Identifier id) {
		this.kind = kind, this.id = id;
	}
	this (SYMKind kind, string name, Location loc=Location.init) {
		this(kind, Identifier(name, loc));
	}
	
	final string recoverString() inout const {
		auto sym = cast(Symbol) this;
		string result;
		
		while (sym.parent) {
			result = "." ~ sym.id.name ~ result;
			sym = sym.parent;
		}
		result = sym.id.name ~ result;
		if (sym.id.is_global) result = "_." ~ result;
		
		return result;
	}
	
	// enclosing scope of this symbol
	final inout(Scope) enclosing() inout const @property {
		with (SYMKind)
		switch (kind) {
			case unsolved:
			case var:
			case arg:
			case typedef:
				return cast(inout) semsc;
			default:
				assert(semsc);
				return cast(inout) semsc.enclosing;
		}
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}


/// Symbol that introduces scopes
class ScopeSymbol : Symbol {
	Symbol[] members;		/// symbols declared in this scope symbol
	SymbolTable table;		/// the table of `members`
	
	this (SYMKind kind, Identifier id, Symbol[] members) {
		super(kind, id);
		this.members = members;
		this.table = new SymbolTable;
		setSymbols(members);
	}
	
	private void setSymbols(Symbol[] mems) {
		import std: among, to;
		foreach (mem; mems) {
			/*
			 * ignore declarations of the form
			 * mixin(...)
			 * mixin Foo!(...)
			 * static if {...} else {...}
			 * version(...) {...}
			 * debug(...) {...}
			 */
			with (SYMKind)
			if (!mem || mem.kind.among!(mixin_, template_mixin, staticif, version_, debug_,)) continue;
			
			// add a symbol
			auto flag = table.add(mem);
			// same identifier appeared multiple time
			if (!flag) {
				auto sym = table[mem.id.name];
				assert(sym);
				message.error(mem.loc, "identifier \x1b[46m", mem.id.name, "\x1b[0m has already been declared in line:",
					sym.id.loc.line_num.to!string, ", index:", sym.id.loc.index_num.to!string, ".");
			}
		}
	}
	
	/**
	 * Search for the symbol declared in this scope.
	 * Returns:
	 *     the symbol if declared, null if not.
	 */
	inout(Symbol) hasMember(string name) inout const {
		return table[name];
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
	inout(Symbol) opIndex(string name) inout const {
		auto p = name in dictionary;
		return cast(inout) (p ? *p : null);
	}
	
}
