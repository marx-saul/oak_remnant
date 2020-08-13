module typeid_;

import token;
import astnode;
import expression;
import type;
import visitor;

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
