module ast.aggregate;

import token;
import ast.ast;
import visitor.visitor;
import semantic.scope_;

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
	
	/// Get the type of the designated field
	Type getType(string name) {
		auto p = name in tp_set;
		if (!p) return *p;
		else return null;
	}
}

alias TPSIZE = uint;
enum InvalidTPSIZE = ~(0u);

/**
 * declaration of aggreagete types.
 * struct, union, class, interface
 */
abstract class AggregateDeclaration : ScopeSymbol {
	Location loc;
	
	/// fields extracted from `decls`
	Fields fields;
	
	TPSIZE structSize;
	TPSIZE unionSize;
	
	this (SYMKind kind, Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Symbol[] members) {
		super(kind, attrbs, prlv, stc, id, members);
		// currently
		this.fields = new Fields;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
