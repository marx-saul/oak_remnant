module aggregate;

import token;
import ast;
import semantic_time_visitor;
import scope_;

/**
 * Fields of the aggregate type. 
 */
class Fields {
	private Type[string]	tp_set;	 // the types of the fields
	private ASTNode[string] bd_set;	 // the initializers of the fields
	
	/// Add a field.
	/// Returns: false iff the name collides.
	bool add(string name, Type tp, ASTNode bd) {
		if (name in tp_set) return false;
		tp_set[name] = tp;
		bd_set[name] = bd;
		return true;
	}
	
	/// Get the type of the 
	Type getType(string mem) {
		auto p = mem in tp_set;
		if (!p) return *p;
		else return null;
	}
}

abstract class AggregateDeclaration : ScopeSymbol {
	Location loc;
	
	/// declarations of symbols
	ASTNode[] decls;
	/// fields extracted from `decls`
	Fields fields;
	
	TPSIZE structSize;
	TPSIZE unionSize;
	
	this (SYMKind kind, string name, Location loc) {
		super(kind, name, loc);
		this.fields = new Fields;
	}
	
	
}
