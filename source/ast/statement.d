module ast.statement;

import token;
import ast.astnode;
import ast.expression;
import ast.type;
import ast.symbol;
import ast.mixin_;
import visitor.visitor;

enum STMT {
	declaration,
	expression,
	ifelse,
	while_,
	dowhile,
	for_,
	foreach_,
	foreach_reverse_,
	break_,
	continue_,
	goto_,
	return_,
	label,
	block,
	mixin_,
}

abstract class Statement : ASTNode {
	Location loc;
	STMT kind;
	this (Location loc, STMT kind) {
		this.loc = loc, this.kind = kind;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DeclarationStatement : Statement {
	Symbol sym;
	this (Symbol sym) {
		assert(sym);
		super(sym.id.loc, STMT.declaration);
		this.sym = sym;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ExpressionStatement : Statement {
	Expression exp;
	this (Location loc, Expression exp) {
		super(loc, STMT.expression);
		this.exp = exp;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IfElseStatement : Statement {
	Expression cond;
	Statement if_body;
	Statement else_body;
	
	this (Location loc, Expression cond, Statement if_body, Statement else_body) {
		super(loc, STMT.ifelse);
		this.cond = cond, this.if_body = if_body, this.else_body = else_body;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class WhileStatement : Statement {
	Expression cond;
	Statement body;

	this (Location loc, Expression cond, Statement body) {
		super(loc, STMT.while_);
		this.cond = cond, this.body = body;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DoWhileStatement : Statement {
	Statement body;
	Expression cond;

	this (Location loc, Statement body, Expression cond) {
		super(loc, STMT.dowhile);
		this.body = body, this.cond = cond;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ForStatement : Statement {
	Statement init;
	Expression test;
	Expression exec;
	Statement body;

	this (Location loc, Statement init, Expression test, Expression exec, Statement body) {
		super(loc, STMT.for_);
		this.init = init, this.test = test, this.exec = exec; this.body = body;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ForeachStatement : Statement {
	string[] vars;
	Type[] types;
	Expression exp;
	Expression exp2;
	Statement body;

	this (Location loc, string[] vars, Type[] types, Expression exp, Expression exp2, Statement body) {
		super(loc, STMT.foreach_);
		this.vars = vars, this.types = types, this.exp = exp, this.exp2 = exp2, this.body = body;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ForeachReverseStatement : Statement {
	string[] vars;
	Type[] types;
	Expression exp;
	Expression exp2;
	Statement body;

	this (Location loc, string[] vars, Type[] types, Expression exp, Expression exp2, Statement body) {
		super(loc, STMT.foreach_reverse_);
		this.vars = vars, this.types = types, this.exp = exp, this.exp2 = exp2, this.body = body;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BreakStatement : Statement {
	string label;

	this (Location loc, string label="") {
		super(loc, STMT.break_);
		this.label = label;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ContinueStatement : Statement {
	string label;

	this (Location loc, string label="") {
		super(loc, STMT.continue_);
		this.label = label;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class GotoStatement : Statement {
	string label;

	this (Location loc, string label) {
		super(loc, STMT.goto_);
		this.label = label;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ReturnStatement : Statement {
	Expression exp;

	this (Location loc, Expression exp=null) {
		super(loc, STMT.return_);
		this.exp = exp;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LabelStatement : Statement {
	string label;

	this (Location loc, string label) {
		super(loc, STMT.label);
		this.label = label;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BlockStatement : Statement {
	Statement[] stmts;

	this(Location loc, Statement[] stmts) {
		super(loc, STMT.block);
		this.stmts = stmts;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class MixinStatement : Statement {
	Mixin node;

	this(Mixin node) {
		super(node.loc, STMT.mixin_);
		this.node = node;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}
