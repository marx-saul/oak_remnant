module ast.mixin_;

import token;
import ast.astnode;
import ast.expression;
import visitor.visitor;

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