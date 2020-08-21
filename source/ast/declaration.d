module ast.declaration;

import token: Location;
import semantic.scope_;
import ast.expression;
import ast.module_;
import ast.statement;
import ast.symbol;
import ast.type;
import visitor.visitor;

final class FuncArgument : Symbol {
	Type tp;				/// the argument of the type
	FuncDeclaration fd;		/// to which function this argument belongs
	
	this (Identifier id, Type tp) {
		super (SYMKind.arg, id);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class FuncDeclaration : ScopeSymbol {
	Type rettp;						/// return type of this function
	FuncArgument[] args;			/// identifiers of arguments
	BlockStatement body;			/// function body
	
	SymbolTable args_table;			/// table of arguments, converted from `this.args`
	bool need_context;				/// does this function need a context pointer
	
	this (Identifier id, Type rettp, FuncArgument[] args, BlockStatement body) {
		super (SYMKind.func, id, []);
		this.rettp = rettp, this.args = args, this.body = body;
		this.args_table = new SymbolTable;
		//assert(rettp, "Auto type inference of the return type of functions are not supported yet : " ~ this.recoverString());
	}
	
	/// whether this function is a prop-func
	public pure nothrow @safe @nogc @property isLazyFunc() {
		return args.length == 0;
	}
	
	/**
	 * Returns : the type of the function.
	 */
	public Type thisType() @property {
		if (_thisType) return _thisType;
		
		// property type
		if (args.length == 0) return _thisType = new LazyType(rettp);
		
		_thisType = rettp;
		foreach_reverse (arg; args) {
			_thisType = new FuncType(arg.tp, _thisType);
		}
		return _thisType;
	}
	private Type _thisType;	 // remember the type
	
	/// search for an identifier, arguments and symbol declared in the function body
	override inout(Symbol) hasMember(string name) inout const {
		// currently do not look into the function body
	
		// arguments
		if (auto arg = args_table[name]) return arg;
		// function body
		//else if 
		// not found
		else return null;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LetDeclaration : Symbol {
	Type tp;
	Expression exp;
	LetDeclaration next;	/// <Linked list> next declaration
	
	this (Identifier id, Type tp, Expression exp, LetDeclaration next=null) {
		super(SYMKind.var, id);
		this.tp = tp, this.exp = exp, this.next = next;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TypedefDeclaration : Symbol {
	Type tp;
	
	this (Identifier id, Type tp) {
		super(SYMKind.typedef, id);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

// import (foo = ) bar.baz;
class ImportDeclaration : Symbol {
	string[] names;		/// symbols of the module or package ["bar", "baz"]
	bool is_replaced;	/// is there `foo = ``
	inout(BindedImportDeclaration) isBinded() inout const @property @nogc {
		return null;
	}
	Package module_;			/// the module
	ImportDeclaration next;		/// Linked list
	
	/**
	 * Params:
	 *     replace = the replacing identifier of this import declaration if designated, the first identifier of the module name if not
	 *     names = the identifiers of module. foo.bar.baz <=> ["foo", "bar", "baz"]
	 */
	this (Identifier id, string[] names, bool is_replaced=false) {
		super(SYMKind.import_, id);
		this.names = names, this.is_replaced=is_replaced;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

// import foo.bar : baz = qux, quux, corge, ...
final class BindedImportDeclaration : ImportDeclaration {
	Identifier[] imports;		/// the symbols in the module	
	Identifier[] bindings;		/// renamed identifiers of the symbols
	override inout(BindedImportDeclaration) isBinded() inout const @property @nogc {
		return cast(inout BindedImportDeclaration) this;
	}
	
	this (Identifier id, string[] names, Identifier[] imports, Identifier[] bindings) {
		super(id, names, false);
		this.imports = imports, this.bindings = bindings;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}