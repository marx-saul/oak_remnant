module ast.func;

import token: Location;
import semantic.scope_;
import ast.attribute;
import ast.expression;
import ast.module_;
import ast.statement;
import ast.symbol;
import ast.type;
import visitor.visitor;


final class FuncArgument : Symbol {
	Type tp;				/// the argument of the type
	FuncDeclaration fd;		/// to which function this argument belongs
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Type tp) {
		super (SYMKind.arg, attrbs, prlv, stc, id);
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
	
	//SymbolTable args_table;			/// table of arguments, converted from `this.args`
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Type rettp, FuncArgument[] args, BlockStatement body) {
		super (SYMKind.func, attrbs, prlv, stc, id, []);
		this.rettp = rettp, this.args = args, this.body = body;
	}
	
	/// whether this function is a prop-func
	public pure nothrow @safe @nogc @property isLazyFunc() {
		return args.length == 0;
	}
	
	/**
	 * Returns : the type of the function.
	 */
	public Type getType() @property {
		if (_type) return _type;
		
		// property type
		if (args.length == 0) return _type = new LazyType(rettp);
		
		_type = rettp;
		foreach_reverse (arg; args) {
			_type = new FuncType(arg.tp, _type);
		}
		return _type;
	}
	private Type _type;	 // remember the type
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}