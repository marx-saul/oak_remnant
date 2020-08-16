module ast.template_;

import token;
import ast.astnode;
import ast.symbol;
import ast.expression;
import ast.type;
import visitor.visitor;

final class TemplateInstance : Symbol {
	Token[][] params;

	TemplateDeclaration decl;	/// template declaration 
	/// parsed parameters
	Symbol[] syms;
	Expression[] exps;
	Type[] tps;

	this(Identifier id, Token[][] params) {
		super(SYMKind.instance, id);
		this.params = params;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TemplateDeclaration : Symbol {
	this(Identifier id) {
		super(SYMKind.template_, id);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}