module ast.expression;

import token;
import ast.astnode;
import ast.symbol;
import ast.type;
import visitor.visitor;

abstract class Expression : ASTNode {
	Location loc;				/// the location of this expression
	bool parenthesized;			/// whether this expression is parenthesized
	
	Type tp;					/// type of this expression
	
	this (Location loc) {
		this.loc = loc;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BinaryExpression : Expression {
	TokenKind op;				/// kind of operator
	Expression left;			/// left hand side
	Expression right;			/// right hand side
	
	this(Location loc, TokenKind op, Expression left, Expression right) {
		super(loc);
		this.op = op, this.left = left, this.right = right;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class UnaryExpression : Expression {
	TokenKind op;				/// kind of operator
	Expression exp;				/// subsequent expression
	this(Location loc, TokenKind op, Expression exp) {
		super(loc);
		this.op = op, this.exp = exp;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IndexingExpression : Expression {
	Expression arr;				/// indexed expression
	Expression[] inds;			/// indices
	
	this(Location loc, Expression arr, Expression[] inds) {
		super(loc);
		this.arr = arr, this.inds = inds;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class SlicingExpression : Expression {
	Expression arr;				/// sliced expression
	Expression[] froms;			/// from .. to
	Expression[] tos;			/// from .. to
	
	this(Location loc, Expression arr, Expression[] froms, Expression[] tos) {
		super(loc);
		this.arr = arr, this.froms = froms, this.tos = tos;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AscribeExpression : Expression {
	Expression exp;				/// expression
	Type astp;					/// ascribed type
	
	this(Location loc, Expression exp, Type astp) {
		super(loc);
		this.exp = exp, this.astp = astp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class WhenElseExpression : Expression {
	Expression cond;				/// condition
	Expression when_exp;			/// when part
	Expression else_exp;			/// else part
	
	this (Location loc, Expression cond, Expression when_exp, Expression else_exp) {
		super(loc);
		this.cond = cond, this.when_exp = when_exp, this.else_exp = else_exp;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IntegerExpression : Expression {
	string str;						/// the string of this integer literal

	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class RealNumberExpression : Expression {
	string str;						/// the string of this real number literal

	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class StringExpression : Expression {
	string str;						/// the string literal it self, if the token is "hello", then str is "hello", not "\"hello\""
	
	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IdentifierExpression : Expression {
	Identifier id;					/// identifier of the 
	
	this(Identifier id) {
		super(id.loc);
		this.id = id;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class AnyExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class FalseExpression : Expression {
	this(Location loc) {
		super(loc);
		this.tp = new BuiltInType(TPKind.bool_);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class TrueExpression : Expression {
	this(Location loc) {
		super(loc);
		this.tp = new BuiltInType(TPKind.bool_);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class NullExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class ThisExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class SuperExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class DollarExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class UnitExpression : Expression {
	this(Location loc) {
		super(loc);
		this.tp = new BuiltInType(TPKind.unit);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TupleExpression : Expression {
	Expression[] ents;		/// entries
	
	this(Location loc, Expression[] ents) {
		super(loc);
		this.ents = ents;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class NewExpression : Expression {
	Type type;				/// subsequent type
	Expression[] args;		/// arguments of the new expression
	
	this(Location loc, Type type, Expression[] args) {
		super(loc);
		this.type = type, this.args = args;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LambdaExpression : Expression {
	import ast.declaration, ast.statement;

	Type ret_type;			/// return type
	FuncArgument args;		/// function arguments
	Statement body;			/// body
	
	this(Location loc, Type ret_type, FuncArgument args, Statement body) {
		super(loc);
		this.ret_type = ret_type, this.args = args, this.body = body;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ArrayExpression : Expression {
	Expression[] elems;		/// elements
	
	this(Location loc, Expression[] elems) {
		super(loc);
		this.elems = elems;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AArrayExpression : Expression {
	Expression[] keys;			/// keys
	Expression[] values;		/// values
	
	this(Location loc, Expression[] keys, Expression[] values) {
		super(loc);
		this.keys = keys, this.values = values;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BuiltInTypePropertyExpression : Expression {
	TokenKind type;		/// basic type
	string str;			/// property
	
	this(Location loc, TokenKind type, string str) {
		super(loc);
		this.type = type, this.str = str;
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TemplateInstanceExpression : Expression {
	import ast.template_;
	TemplateInstance node;		/// template instance
	
	this(TemplateInstance node) {
		super(node.loc);
		this.node = node;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TypeidExpression : Expression {
	import ast.typeid_;
	Typeid node;				/// typeid 
	
	this(Typeid node) {
		super(node.loc);
		this.node = node;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class MixinExpression : Expression {
	import ast.mixin_;
	Mixin node;					/// mixin
	
	this(Mixin node) {
		super(node.loc);
		this.node = node;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}
