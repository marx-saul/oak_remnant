module ast.declaration;

import token: Location;
import semantic.scope_;
import ast.symbol;
import ast.type;
import ast.expression;
import ast.statement;
import visitor.visitor;

class FuncArgument : Symbol {
	Type tp;				/// the argument of the type
	FuncDeclaration fd;
	
	this (Identifier id, Type tp) {
		super (SYMKind.arg, id);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

class FuncDeclaration : ScopeSymbol {
	Type rettp;						/// return type of this function
	FuncArgument[] args;			/// identifiers of arguments
	BlockStatement body;			/// function body
	
	SymbolTable args_table;			/// table of arguments, converted from `this.args`
	
	this (Identifier id, Type rettp, FuncArgument[] args, BlockStatement body) {
		super (SYMKind.func, id, []);
		this.rettp = rettp, this.args = args, this.body = body;
		
		// set argument table
		this.args_table = new SymbolTable;
		foreach (arg; args) {
			assert(arg);
			args_table.add(arg);
		}
		
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

class LetDeclaration : Symbol {
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

class TypedefDeclaration : Symbol {
	Type tp;
	
	this (Identifier id, Type tp) {
		super(SYMKind.typedef, id);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

/+
final class LetDeclaration : Statement {
	Location[] idlocs;
	string[] names;
	Type[] types;
	Expression[] inits;
	this (Location loc, Location[] idlocs, string[] names, Type[] types, Expression[] inits) {
		super(loc);
		this.idlocs = idlocs, this.names = names, this.types = types, this.inits = inits;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class FuncDeclaration : Statement {
	Location idloc;
	string name;
	Type ret_type;
	Location[] arglocs;
	string[] args;
	Type[] argtps;
	Statement body;
	this (Location loc, Location idloc, string name, Type ret_type, 
		Location[] arglocs, string[] args, Type[] argtps, Statement body) {
		super(loc);
		this.idloc = idloc, this.name = name, this.ret_type = ret_type,
		this.arglocs = arglocs, this.args = args, this.argtps = argtps, this.body = body;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

class AggregateDeclaration : Statement {
	string name;
	ASTNode[] mems;
	this (Location loc, string name, ASTNode[] mems) {
		super(loc);
		this.name = name, this.mems = mems;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class StructDeclaration : AggregateDeclaration {
	this (Location loc, string name, ASTNode[] mems) {
		super(loc, name, mems);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TypedefDeclaration : Statement {
	string name;
	Type type;
	this (Location loc, string name, Type type) {
		super(loc);
		this.name = name, this.type = type;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
 +/