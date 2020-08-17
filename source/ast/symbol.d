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
	var,				/// variables : defined by `let x:T = E;`			correspond to ast.declaration.LetDeclaration
	arg,				/// function argument								correspond to ast.declaration.FuncArgument
	func,				/// function : defined by `func f ...`				correspond to ast.declaration.FuncDeclaration
	typedef,			/// typedef-ed type : defined by typedef T = S;		correspond to ast.declaration.TypedefDeclaration
	struct_,			/// struct : defined by struct S { ... }			correspond to ast.struct_.StructDeclaration
	union_,				/// union : defined by union U { ... }
	class_,				/// class : defined by class C { ... }
	interface_,			/// interface : defined by interface I { ... }
	template_,			/// template : defined by template T { ... }
	instance,			/// template instance : T!(...)
	module_,			/// modules
	package_,			/// packages
	ctor,				/// constructor : defined by this ...
	dector,				/// deconstructor : defined by ~this ...
	mixin_,				/// mixin declaration : defined by mixin( ... );
	template_mixin,		/// template mixin declaration : defined by mixin Foo!(...)
	staticif,			/// static if declaration : defined by static if { ... } else { ... }
	version_,			/// version declaration : defined by version(...) { ... }
	debug_,				/// debug declaration : defined by debug(...) { ... }
}

/// Symbol class
class Symbol : ASTNode {
	SYMKind kind;									/// kind of this identifier
	Identifier id;									/// identifier
	Location loc() @property { return id.loc; }		/// location
	
	PASS pass = PASS.init;							/// semantic pass that is currently run on this symbol
	Scope semsc;									/// the scope this symbol belongs to or this symbol generates(when it is a scope-symbol)
	
	this (SYMKind kind, Identifier id) {
		this.kind = kind, this.id = id;
	}
	this (SYMKind kind, string name, Location loc=Location.init) {
		this(kind, Identifier(name, loc));
	}
	
	/// Get the full string of this symbol.
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
	
	/// enclosing scope of this symbol
	/// must call setScope() before calling this
	final inout(Scope) enclosing() inout const @property {
		assert(semsc);
		/*
		if (!semsc) {
			import semantic.set_scope;
			setScope(this);
		}
		*/
		with (SYMKind)
		final switch (kind) {
			// not scope-symbols
			case unsolved:
			case var:
			case arg:
			case typedef:
			case mixin_:
			case template_mixin:
			case staticif:
			case version_:
			case debug_:
				return cast(inout) semsc;
			// scope-symbols
			case func:
			case struct_:
			case union_:
			case class_:
			case interface_:
			case template_:
			case instance:
			case module_:
			case package_:
			case ctor:
			case dector:
				assert(semsc);
				return cast(inout) semsc.enclosing;
		}
	}
	
	/// Returns lexical parent symbol
	final inout(Symbol) parent() inout const @property {
		if (auto enc = this.enclosing()) return enc.scsym;
		else return null;
	}
	
	// Returns the symbol 
	//final inout(Symbol) parent2() inout const @property {
		
	//}
	final inout const @nogc @property {
		inout(FuncArgument)				isFuncArgument()			{ return kind == SYMKind.arg 		? cast(inout(typeof(return)))this : null; }
		inout(FuncDeclaration)			isFuncDeclaration()			{ return kind == SYMKind.func 		? cast(inout(typeof(return)))this : null; }
		inout(TypedefDeclaration)		isTypedefDeclaration()		{ return kind == SYMKind.typedef 	? cast(inout(typeof(return)))this : null; }
		inout(StructDeclaration)		isStructDeclaration()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		//inout(UnionDeclaration)			isUnionDeclaration()		{ return kind == SYMKind.union_		? cast(inout(typeof(return)))this : null; }
		//inout(ClassDeclaration)			isClassDeclaration()		{ return kind == SYMKind.class_		? cast(inout(typeof(return)))this : null; }
		//inout(InterfaceDeclaration)		isInterfaceDeclaration()	{ return kind == SYMKind.interface_	? cast(inout(typeof(return)))this : null; }inout(StructDeclaration)		isStructDeclaration()		{ return kind == SYMKind.struct_	? cast(inout StructDeclaration)this : null; }
		inout(TemplateDeclaration)		isTemplateDeclaration()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		inout(TemplateInstance)			isTemplateInstance()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		inout(Module)					isModule()					{ return kind == SYMKind.module_	? cast(inout(typeof(return)))this : null; }
		inout(Package)					isPackage()					{ return kind == SYMKind.package_	? cast(inout(typeof(return)))this : null; }
		
		inout(ScopeSymbol)				isScopeSymbol()				{
			import std.algorithm: among;
			with (SYMKind)
			return kind.among!(
				func,
				struct_,
				union_,
				class_,
				interface_,
				template_,
				instance,
				module_,
				package_,
				ctor,
				dector,
			) != 0 ? cast(inout(typeof(return)))this : null;
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
			 * this ... { ... }
			 * ~this ... { ... }
			 * mixin(...)
			 * mixin Foo!(...)
			 * static if {...} else {...}
			 * version(...) {...}
			 * debug(...) {...}
			 */
			with (SYMKind)
			if (!mem || mem.kind.among!(ctor, dector, mixin_, template_mixin, staticif, version_, debug_,)) continue;
			
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
