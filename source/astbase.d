module astbase;

import std.typecons;
import parse_time_visitor;
import lexer;

alias Vis = ParseTimeVisitor;

abstract class ASTNode {
	bool is_error;
	Location loc;
	this (Location loc) {
		this.loc = loc;
	}
	void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** Helpers ************** */
struct Identifier {
	Location loc;
	string name;
	bool is_global;	 // global access _.id
}

/* ************** Expressions ************** */
abstract class Expression : ASTNode {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BinaryExpression : Expression {
	TokenKind op;
	Expression left, right;
	this(Location loc, TokenKind op, Expression left, Expression right) {
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
	this(Location loc, TokenKind op, Expression exp) {
		super(loc);
		this.op = op, this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class IndexingExpression : Expression {
	Expression arr;
	Expression[] inds;
	this(Location loc, Expression arr, Expression[] inds) {
		super(loc);
		this.arr = arr, this.inds = inds;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class SlicingExpression : Expression {
	Expression arr;
	Expression[] froms;
	Expression[] tos;
	this(Location loc, Expression arr, Expression[] froms, Expression[] tos) {
		super(loc);
		this.arr = arr, this.froms = froms, this.tos = tos;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class AscribeExpression : Expression {
	Expression exp;
	Type type;
	
	this(Location loc, Expression exp, Type type) {
		super(loc);
		this.exp = exp, this.type = type;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class IntegerExpression : Expression {
	string str;

	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class RealNumberExpression : Expression {
	string str;

	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class StringExpression : Expression {
	string str;
	this(Location loc, string str) {
		super(loc);
		this.str = str;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class IdentifierExpression : Expression {
	Identifier id;
	this(Location loc, string name, bool is_global=false) {
		super(loc);
		this.id.loc = loc, this.id.name = name, this.id.is_global = is_global;
	}
	this(Location loc, Identifier id) {
		super(loc);
		this.id = id;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class AnyExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class FalseExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class TrueExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class NullExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class ThisExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class SuperExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class DollarExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class UnitExpression : Expression {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TupleExpression : Expression {
	Expression[] ents;
	this(Location loc, Expression[] ents) {
		super(loc);
		this.ents = ents;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class NewExpression : Expression {
	Type type;
	Expression[] args;
	this(Location loc, Type type, Expression[] args) {
		super(loc);
		this.type = type, this.args = args;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ArrayExpression : Expression {
	Expression[] elems;
	this(Location loc, Expression[] elems) {
		super(loc);
		this.elems = elems;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class AssocArrayExpression : Expression {
	string[] keys;
	Expression[] values;
	this(Location loc, string[] keys, Expression[] values) {
		super(loc);
		this.keys = keys, this.values = values;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BuiltInTypePropertyExpression : Expression {
	TokenKind type;
	string str;
	this(Location loc, TokenKind type, string str) {
		super(loc);
		this.type = type, this.str = str;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TemplateInstanceExpression : Expression {
	TemplateInstance node;
	this(TemplateInstance node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TypeidExpression : Expression {
	Typeid node;
	this(Typeid node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class MixinExpression : Expression {
	Mixin node;
	this(Mixin node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** Types ************** */
abstract class Type : ASTNode {
	this(Location loc) {
		super(loc);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class FunctionType : Type {
	Type ran, dom;
	this(Location loc, Type ran, Type dom) {
		super(loc);
		this.ran = ran, this.dom = dom;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class PointerType : Type {
	Type type;
	this(Location loc, Type type) {
		super(loc);
		this.type = type;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

// int32, bool, string,
final class BuiltInType : Type {
	TokenKind kind;
	this(Location loc, TokenKind kind) {
		super(loc);
		this.kind = kind;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TupleType : Type {
	Type[] ents;
	this(Location loc, Type[] ents) {
		super(loc);
		this.ents = ents;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ArrayType : Type {
	Type elem;
	this(Location loc, Type elem) {
		super(loc);
		this.elem = elem;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class AssocArrayType : Type {
	Type key, value;
	this(Location loc, Type key, Type value) {
		super(loc);
		this.key = key, this.value = value;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** TemplateInstance ************** */
final class TemplateInstance : ASTNode {
	Identifier id;
	ASTNode[] params;
	this(Location loc, string name, ASTNode[] params) {
		super(loc);
		this.id.loc = loc, this.id.name = name, this.params = params;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** Mixin ************** */
final class Mixin : ASTNode {
	Expression exp;
	this(Location loc, Expression exp) {
		super(loc);
		this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** Typeid ************** */
final class Typeid : ASTNode {
	Token[] tokens;
	this(Location loc) {
		super(loc);
		//this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* ************** To String ************** */
final class ToStringVisitor : ParseTimeVisitor {
	string result;
	
	override void visit(ASTNode) { assert(0); }

	/* Expressions */
	override void visit(BinaryExpression exp) {
		result ~= "(";
		if (exp.left)  exp. left.accept(this);
		if (exp.op == TokenKind.apply) result ~= " ";
		else result ~= " " ~ token_dictionary[exp.op] ~ " ";
		if (exp.right) exp.right.accept(this);
		result ~= ")";
	}
	override void visit(UnaryExpression exp) {
		result ~= token_dictionary[exp.op];
		result ~= "(";
		if (exp.exp) exp.exp.accept(this);
		result ~= ")";
	}
	override void visit(IndexingExpression exp) { assert(0); }
	override void visit(SlicingExpression exp)  { assert(0); }
	override void visit(AscribeExpression exp) {
		result ~= "(";
		if (exp.exp) exp.exp.accept(this);
		result ~= " as ";
		if (exp.type) exp.type.accept(this);
		result ~= ")";
	}
	override void visit(IntegerExpression exp) {
		result ~= exp.str;
	}
	override void visit(RealNumberExpression exp) {
		result ~= exp.str;
	}
	override void visit(StringExpression exp) {
		result ~= "`" ~ exp.str ~ "`";
	}
	override void visit(IdentifierExpression exp) {
		if (exp.id.is_global) result ~= "_.";
		result ~= exp.id.name;
	}
	override void visit(AnyExpression) {
		result ~= "_";
	}
	override void visit(FalseExpression) {
		result ~= "false";
	}
	override void visit(TrueExpression) {
		result ~= "true";
	}
	override void visit(NullExpression) {
		result ~= "null";
	}
	override void visit(ThisExpression) {
		result ~= "this";
	}
	override void visit(SuperExpression) {
		result ~= "super";
	}
	override void visit(DollarExpression) {
		result ~= "$";
	}
	override void visit(UnitExpression) {
		result ~= "()";
	}
	override void visit(TupleExpression exp) {
		result ~= "(";
		foreach (e; exp.ents) {
			if (e) e.accept(this);
			result ~= ", ";
		}
		result = result[0 .. $-2];
		result ~= ")";
	}
	override void visit(NewExpression exp) {
		result ~= "new ";
		if (exp.type) exp.type.accept(this);
	}
	override void visit(ArrayExpression exp) {
		result ~= "[";
		foreach (e; exp.elems) {
			if (e) e.accept(this);
			result ~= ", ";
		}
		result = result[0 .. $ > 2 ? $-2 : $];
		result ~= "]";
	}
	override void visit(AssocArrayExpression exp) {
		result ~= "[";
		foreach (i; 0 .. exp.keys.length) {
			result ~= exp.keys[i];
			result ~= ": ";
			if (exp.values[i]) exp.values[i].accept(this);
			result ~= ", ";
		}
		result = result[0 .. $ > 2 ? $-2 : $];
		result ~= "]";
	}
	override void visit(BuiltInTypePropertyExpression exp) {
		result ~= token_dictionary[exp.type];
		result ~= ".";
		result ~= exp.str;
	}
	override void visit(TemplateInstanceExpression exp) {
		if (exp.node) exp.node.accept(this);
	}
	override void visit(TypeidExpression exp) {
		if (exp.node) exp.node.accept(this);
	}
	override void visit(MixinExpression exp) {
		if (exp.node) exp.node.accept(this);
	}

	/* Types */
	override void visit(Type type) { assert(0); }
	override void visit(FunctionType type) {
		result ~= "(";
		if (type.ran) type.ran.accept(this);
		result ~= " -> ";
		if (type.dom) type.dom.accept(this);
		result ~= ")";
	}
	override void visit(PointerType type) {
		result ~= "#(";
		if (type.type) type.type.accept(this);
		result ~= ")";
	}
	override void visit(BuiltInType type) {
		result ~= token_dictionary[type.kind];
	}
	override void visit(TupleType type) {
		result ~= "(";
		foreach (t; type.ents) {
			if (t) t.accept(this);
			result ~= ", ";
		}
		result = result[0 .. $-2];
		result ~= ")";
	}
	override void visit(ArrayType type) {
		result ~= "[";
		if (type.elem) type.elem.accept(this);
		result ~= "]";
	}
	override void visit(AssocArrayType type) {
		result ~= "[";
		if (type.key)   type.  key.accept(this);
		result ~= " : ";
		if (type.value) type.value.accept(this);
		result ~= "]";
	}

	/* TemplateInstance */
	override void visit(TemplateInstance ti) {
		result ~= "TemplateInstance";
	}
	/* Mixin */
	override void visit(Mixin m) {
		result ~= "Mixin";
	}
	/* Typeid */
	override void visit(Typeid t) {
		result ~= "Typeid";
	}
}

string to_string(ASTNode node) {
	if (node is null) return "";
	auto vis = new ToStringVisitor;
	node.accept(vis);
	return vis.result;
}
