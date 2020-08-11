module declaration;

import token: Location;
import ast;
import semantic_time_visitor;
import scope_;

private alias Vis = SemanticTimeVisitor;

class FuncArgument : Symbol {
	Type tp;				/// the argument of the type
	FuncDeclaration fd;
	
	this (Location loc, string name, Type tp) {
		super (SYMKind.arg, name, loc);
		this.tp = tp;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

class FuncDeclaration : Symbol {
	Type rettp;						/// return type of this function
	FuncArgument[] args;			/// identifiers of arguments
	//BlockStatement body;			/// function body
	
	SymbolTable args_table;			/// table of arguments, converted from `this.args`
	
	this (Location loc, string name, Type rettp, FuncArgument[] args) {
		super (SYMKind.func, name, loc);
		this.rettp = rettp, this.args = args;
		// set argument table
		foreach (arg; args) {
			args_table.add(arg);
		}
		
		assert(rettp, "Auto type inference of the return type of functions are not supported yet.");
	}
	
	/// whether this function is a prop-func
	public pure nothrow @safe @nogc @property isPropFunc() {
		return args.length == 0;
	}
	
	/**
	 * Returns : the type of the function.
	 */
	public Type thisType() @property {
		if (_thisType) return _thisType;
		
		// property type
		if (args.length == 0) return _thisType = new PropType(rettp);
		
		_thisType = rettp;
		foreach_reverse (arg; args) {
			_thisType = new FuncType(arg.tp, _thisType);
		}
		return _thisType;
	}
	private Type _thisType;	 // remember the type
	
	/// search for an identifier in this function scope.
	/// Returns: null if the identifier was not declared in the scope
	public Symbol isDeclared(Identifier id) {
		if (auto result_sym = args_table.get(id.name))
			return result_sym;
		else return null;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

class TypedefDeclaration : Symbol {
	Location loc;
	string name;
	Type tp;
	
	this(Location loc, string name, Type tp) {
		super(SYMKind.typedef, name, loc);
		this.tp = tp;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}
