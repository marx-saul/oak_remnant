module expression;

import token;
import ast;
import semantic_time_visitor;

private alias Vis = SemanticTimeVisitor;

abstract class Expression : ASTNode {
	Location loc;
	Type tp;
	this (Location loc) {
		this.loc = loc;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BinaryExpression : Expression {
	TokenKind op;
	Expression left;
	Expression right;
	this (Location loc, TokenKind op, Expression left, Expression right) {
		super(loc);
		this.op = op, this.left = left, this.right = right;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class UnaryExpression : Expression {
	TokenKind op;
	Expression exp;
	this (Location loc, TokenKind op, Expression exp) {
		super(loc);
		this.op = op, this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class FalseExpression : Expression {
	this (Location loc) {
		super(loc);
		this.tp = new BuiltInType(TPKind.bool_);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TrueExpression : Expression {
	this (Location loc) {
		super(loc);
		this.tp = new BuiltInType(TPKind.bool_);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
