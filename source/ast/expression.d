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

abstract class BinaryExpression : Expression {
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

final class AssExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.ass, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

abstract class BinaryAssExpression : BinaryExpression {
	this (Location loc, TokenKind op, Expression left, Expression right) {
		super(loc, op, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AddAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.add, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class SubAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.sub, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class CatAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.cat, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class MulAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.mul, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DivAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.div, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ModAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.mod, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class PowAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.pow, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BitAndAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_and, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BitXorAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_xor, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BitOrAssExpression : BinaryAssExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_or, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class PipelineExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.pipeline, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AppExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.app, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class OrExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.or, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class XorExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.xor, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AndExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.and, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}
final class BitOrExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_or, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BitXorExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_xor, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BitAndExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.bit_and, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class EqExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.eq, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class NeqExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.neq, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LsExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.ls, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LeqExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.leq, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class GtExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.gt, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class GeqExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.geq, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IsExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.is_, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class NisExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.nis, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class InExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.in_, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class NinExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.nin, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AddExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.add, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class SubExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.sub, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class CatExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.cat, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class MulExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.mul, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DivExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.div, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ModExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.mod, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LShiftExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.lshift, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class RShiftExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.rshift, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LogicalShiftExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.logical_shift, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class PowExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.pow, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ApplyExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.apply, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class CompositionExpression : BinaryExpression {
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.composition, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DotExpression : BinaryExpression {
	bool isUFCS = false;
	this (Location loc, Expression left, Expression right) {
		super(loc, TokenKind.dot, left, right);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

abstract class UnaryExpression : Expression {
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

final class MinusExpression : UnaryExpression {
	this (Location loc, Expression exp) {
		super(loc, TokenKind.minus, exp);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class NotExpression : UnaryExpression {
	this (Location loc, Expression exp) {
		super(loc, TokenKind.not, exp);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class RefofExpression : UnaryExpression {
	this (Location loc, Expression exp) {
		super(loc, TokenKind.ref_of, exp);
	}
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class DerefExpression : UnaryExpression {
	this (Location loc, Expression exp) {
		super(loc, TokenKind.deref, exp);
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
	import ast.func, ast.statement;

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
