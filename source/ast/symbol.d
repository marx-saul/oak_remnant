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
	import_,			/// import declarations : import foo.bar.baz. ... ;	correspond to ast.declaration.ImportDeclaration
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
	
	PRLV prlv;										/// protection level
	StorageClass stc;								/// storage class
	Attribution[] attrbs;							/// attributions
	
	PASS sempass = PASS.init;						/// see semantic.symbolsem
	Scope semsc;									/// the scope this symbol belongs to or this symbol generates(when it is a scope-symbol)
	
	/+this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id) {
		this (SYMKind.unsolved, attrbs, prlv, stc, id);
	}+/
	
	this (SYMKind kind, Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id) {
		this.kind = kind,
		this.attrbs = attrbs;
		if (prlv == PRLV.undefined) prlv = PRLV.public_;
		this.prlv = prlv, this.stc = stc,
		this.id = id;
	}
	
	/// Get the full string of this symbol.
	final string recoverString() inout const {
		auto sym = cast(Symbol) this;
		string result;
		
		while (sym.parent) {
			result = "." ~ sym.thisString() ~ result;
			sym = sym.parent;
		}
		result = sym.id.name ~ result;
		if (sym.id.is_global) result = "_." ~ result;
		
		return result;
	}
	
	string thisString() inout const {
		return this.id.name;
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
			case import_:
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
		inout(LetDeclaration)			isLetDeclaration()			{ return kind == SYMKind.var 		? cast(inout(typeof(return)))this : null; }
		inout(FuncArgument)				isFuncArgument()			{ return kind == SYMKind.arg 		? cast(inout(typeof(return)))this : null; }
		inout(FuncDeclaration)			isFuncDeclaration()			{ return kind == SYMKind.func 		? cast(inout(typeof(return)))this : null; }
		inout(TypedefDeclaration)		isTypedefDeclaration()		{ return kind == SYMKind.typedef 	? cast(inout(typeof(return)))this : null; }
		inout(ImportDeclaration)		isImportDeclaration()		{ return kind == SYMKind.import_ 	? cast(inout(typeof(return)))this : null; }
		inout(StructDeclaration)		isStructDeclaration()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		//inout(UnionDeclaration)			isUnionDeclaration()		{ return kind == SYMKind.union_		? cast(inout(typeof(return)))this : null; }
		//inout(ClassDeclaration)			isClassDeclaration()		{ return kind == SYMKind.class_		? cast(inout(typeof(return)))this : null; }
		//inout(InterfaceDeclaration)		isInterfaceDeclaration()	{ return kind == SYMKind.interface_	? cast(inout(typeof(return)))this : null; }inout(StructDeclaration)		isStructDeclaration()		{ return kind == SYMKind.struct_	? cast(inout StructDeclaration)this : null; }
		inout(TemplateDeclaration)		isTemplateDeclaration()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		inout(TemplateInstance)			isTemplateInstance()		{ return kind == SYMKind.struct_	? cast(inout(typeof(return)))this : null; }
		inout(Module)					isModule()					{ return kind == SYMKind.module_	? cast(inout(typeof(return)))this : null; }
		inout(Package)					isPackage()					{ return kind == SYMKind.package_ || kind == SYMKind.module_	? cast(inout(typeof(return)))this : null; }
		
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
	ImportTree import_tree;	/// for searching imported modules
	
	this (SYMKind kind, Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Symbol[] members=[]) {
		super(kind, attrbs, prlv, stc, id);
		this.members = members;
		this.table = new SymbolTable;
		this.import_tree = new ImportTree;
	}
	
	/**
	 * Refer to the symbol table. Do not consider symbol-semantic
	 * Do not look inside the module
	 */
	inout(Symbol) hasMember(string name) inout const {
		return table[name];
	}
	
	/**
	 * Search for the symbol as a member of this symbol. If symbol-semantic pass (pass1) has not been run, do it.
	 * Do not look into the modules imported within the symbol.
	 * Do not consider the access level
	 * Returns:
	 *     the symbol if the identifier is a member, null if not.
	 */
	Symbol getMember(string name) {
		if (sempass == PASS.init) {
			import semantic.symbolsem;
			symbolSem(this);
		}
		return table[name];
	}
	
	/**
	 * Apply the function for each member of this symbol.
	 * Params:
	 *     dg = the function to apply
	 */
	void foreachSymbol(void delegate(Symbol) dg) {
		if (sempass == PASS.init) {
			import semantic.symbolsem;
			symbolSem(this);
		}
		
		foreach (sym; this.table.dictionary.byValue) {
			if (auto imd = sym.isImportDeclaration) {
				for (; imd; imd = imd.next) {
					assert(imd !is imd.next);
					dg(imd);
				}
			}
			else if (auto ld = sym.isLetDeclaration) {
				for (; ld; ld = ld.next) {
					assert(ld !is ld.next);
					dg(ld);
				}
			}
			else {
				dg(sym);
			}
		}
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

/// Symbol table that every symbol is a class instance of SYM
class SpecifiedSymbolTable(SYM)
	if(is(SYM : Symbol))
{
	/// store all identifiers and their declarations
	private SYM[string] dictionary;
	
	/+
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
	+/
	
	/**
	 * Get the symbol.
	 * Returns: null if the name has not been declared.
	 */
	inout(SYM) opIndex(string name) inout const {
		auto p = name in dictionary;
		return cast(inout) (p ? *p : null);
	}
	
	/**
	 * Regisiter the symbol with the string indicated.
	 * Multiple registration are considered to be bugs.
	 */
	ref SYM opIndexAssign(SYM sym, string name) {
		assert(sym && !this.opIndex(name));
		return dictionary[name] = sym;
	}
	
	auto everyMember() @property {
		return dictionary.keys;
	}
}

alias SymbolTable = SpecifiedSymbolTable!Symbol;

/**
 * The class for searching imported modules.
 * For exmple, if foo.bar, foo.bar.baz, qux and quux.corge are imported, the tree is
 * [ foo:[bar:[baz]], qux, quux:[corge] ]
 */
class ImportTree {
	ImportTree[string] children;
	ImportDeclaration decl;
	
	/// Push an import declaration
	/// Returns: false if same module pushed
	bool push(ImportDeclaration imd) {
		if (!imd) return true;
		auto tree = this;
		foreach (id; imd.modname) {
			auto ptr = id.name in tree.children;
			if (!ptr) ptr = &(tree.children[id.name] = new ImportTree);
			tree = *ptr;
		}
		if (!tree.decl) { tree.decl = imd; return true; }
		else { return false; }
	}
}
