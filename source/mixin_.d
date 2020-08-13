module mixin_;

import token;
import astnode;
import expression;
import visitor;

final class Mixin : ASTNode {
	Location loc;
	Expression exp;

	this(Location loc, Expression exp) {
		this.loc = loc, this.exp = exp;
	}

	override void accept(Visitor v) {
		v.visit(this);
	}
}