module ast.typeid_;

import token;
import ast.astnode;
import ast.expression;
import ast.type;
import visitor.visitor;

final class Typeid : ASTNode {
	Location loc;
	Token[] tokens;
	Expression exp;
	Type tp;

	this(Location loc) {
		this.loc = loc;
		//this.exp = exp;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}
