/**
 * astbase.d
 * Defines ASTs generated from the parser.
 */
module astbase;

import std.typecons;
import parse_time_visitor;
import token, lexer;

alias Vis = ParseTimeVisitor;

abstract class ASTNode {
	Location loc;
	this (Location loc) {
		this.loc = loc;
	}
	void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** Module **************************** */
final class Module : ASTNode {
	string[] modname;
	ASTNode[] decls;
	this(Location loc, string[] modname, ASTNode[] decls) {
		super(loc);
		this.modname = modname, this.decls = decls;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** Expressions **************************** */
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

final class WhenElseExpression : Expression {
	Expression cond;
	Expression when_exp;
	Expression else_exp;
	
	this (Location loc, Expression cond, Expression when_exp, Expression else_exp) {
		super(loc);
		this.cond = cond, this.when_exp = when_exp, this.else_exp = else_exp;
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
	string name;
	bool is_global;
	this(Location loc, string name, bool is_global=false) {
		super(loc);
		this.name = name, this.is_global = is_global;
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

final class LambdaExpression : Expression {
	Type ret_type;
	Location[] arglocs;
	string[] args;
	Type[] types;
	Statement body;
	this(Location loc, Type ret_type, Location[] arglocs, string[] args, Type[] types, Statement body) {
		super(loc);
		this.ret_type = ret_type, this.arglocs = arglocs, this.args = args, this.types = types, this.body = body;
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

final class BlockExpression : Expression {
	Statement[] stmts;
	Expression exp;
	this(Location loc, Statement[] stmts, Expression exp) {
		super(loc);
		this.stmts = stmts;
		this.exp = exp;
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

/* **************************** Types **************************** */
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

// int32, bool, string, etc.
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

final class SymbolType : Type {
	Type[] types;	// IdentifierType or TemplateInstanceType
	this(Location loc, Type[] types, bool is_global=false) {
		super(loc);
		this.types = types;
		// set is_global
		if (types.length > 0 && types[0] !is null) {
			if (typeid(types[0]) == typeid(IdentifierType)) {
				auto t0 = cast(IdentifierType) types[0];
				t0.is_global = is_global;
			}
			else if (typeid(types[0]) == typeid(TemplateInstanceType)) {
				auto t0 = cast(TemplateInstanceType) types[0];
				if (t0.node) t0.node.is_global = is_global;
			}
			else assert(0);
		}
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class IdentifierType : Type {
	string name;
	bool is_global;
	this(Location loc, string name, bool is_global=false) {
		super(loc);
		this.name = name, this.is_global = is_global;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TemplateInstanceType : Type {
	TemplateInstance node;
	this(TemplateInstance node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class MixinType : Type {
	Mixin node;
	this(Mixin node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** Statements **************************** */
alias Statement = ASTNode;

final class ExpressionStatement : Statement {
	Expression exp;
	this (Location loc, Expression exp) {
		super(loc);
		this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class IfElseStatement : Statement {
	Expression cond;
	Statement if_body;
	Statement else_body;
	
	this (Location loc, Expression cond, Statement if_body, Statement else_body) {
		super(loc);
		this.cond = cond, this.if_body = if_body, this.else_body = else_body;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class WhileStatement : Statement {
	Expression cond;
	Statement body;
	this (Location loc, Expression cond, Statement body) {
		super(loc);
		this.cond = cond, this.body = body;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class DoWhileStatement : Statement {
	Statement body;
	Expression cond;
	this (Location loc, Statement body, Expression cond) {
		super(loc);
		this.body = body, this.cond = cond;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ForStatement : Statement {
	Statement init;
	Expression test;
	Expression exec;
	Statement body;
	this (Location loc, Statement init, Expression test, Expression exec, Statement body) {
		super(loc);
		this.init = init, this.test = test, this.exec = exec; this.body = body;
	}
	override void accept(Vis v) {
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
		super(loc);
		this.vars = vars, this.types = types, this.exp = exp, this.exp2 = exp2, this.body = body;
	}
	override void accept(Vis v) {
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
		super(loc);
		this.vars = vars, this.types = types, this.exp = exp, this.exp2 = exp2, this.body = body;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BreakStatement : Statement {
	string label;
	this (Location loc, string label="") {
		super(loc);
		this.label = label;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ContinueStatement : Statement {
	string label;
	this (Location loc, string label="") {
		super(loc);
		this.label = label;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class GotoStatement : Statement {
	string label;
	this (Location loc, string label) {
		super(loc);
		this.label = label;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ReturnStatement : Statement {
	Expression exp;
	this (Location loc, Expression exp=null) {
		super(loc);
		this.exp = exp;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class LabelStatement : Statement {
	string label;
	this (Location loc, string label) {
		super(loc);
		this.label = label;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BlockStatement : Statement {
	Statement[] stmts;
	this(Location loc, Statement[] stmts) {
		super(loc);
		this.stmts = stmts;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class MixinStatement : Statement {
	Mixin node;
	this(Mixin node) {
		super(node.loc);
		this.node = node;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** Declaration *************************** */
final class LetDeclaration : Statement {
	Location[] idlocs;
	string[] names;
	Type[] types;
	Expression[] inits;
	this (Location loc, Location[] idlocs, string[] names, Type[] types, Expression[] inits) {
		super(loc);
		this.idlocs = idlocs, this.names = names, this.types = types, this.inits = inits;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class FuncDeclaration : Statement {
	Location idloc;
	string name;
	Type ret_type;
	Location[] arglocs;
	string[] args;
	Type[] argtps;
	Statement body;
	this (Location loc, Location idloc, string name, Type ret_type, 
		Location[] arglocs, string[] args, Type[] argtps, Statement body) {
		super(loc);
		this.idloc = idloc, this.name = name, this.ret_type = ret_type,
		this.arglocs = arglocs, this.args = args, this.argtps = argtps, this.body = body;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

class AggregateDeclaration : Statement {
	string name;
	ASTNode[] mems;
	this (Location loc, string name, ASTNode[] mems) {
		super(loc);
		this.name = name, this.mems = mems;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}
final class StructDeclaration : AggregateDeclaration {
	this (Location loc, string name, ASTNode[] mems) {
		super(loc, name, mems);
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TypedefDeclaration : Statement {
	string name;
	Type type;
	this (Location loc, string name, Type type) {
		super(loc);
		this.name = name, this.type = type;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** TemplateInstance **************************** */
final class TemplateInstance : ASTNode {
	Location idloc;
	string name;
	Token[][] params;
	bool is_global;
	this(Location loc, Location idloc, string name, Token[][] params, bool is_global=false) {
		super(loc);
		this.idloc = idloc, this.name = name, this.params = params, this.is_global = is_global;
	}
	override void accept(Vis v) {
		v.visit(this);
	}
}

/* **************************** Mixin **************************** */
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

/* **************************** Typeid **************************** */
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
