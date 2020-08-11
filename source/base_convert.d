/**
 * base_convert.d
 * from astbase to ast
 */
module base_convert;

import astbase, ast;
import token;
import parse_time_visitor;

class ConvertVisitor : ParseTimeVisitor {
	override void visit(astbase.ASTNode) {
		assert(0);
	}
	
	override void visit(astbase.Module) {
		assert(0);
	}

	/* Expression */
	override void visit(astbase.Expression) {
		assert(0);
	}
	override void visit(astbase.BinaryExpression) {
		assert(0);
	}
	override void visit(astbase.UnaryExpression) { assert(0); }
	override void visit(astbase.IndexingExpression) { assert(0); }
	override void visit(astbase.SlicingExpression) { assert(0); }
	override void visit(astbase.AscribeExpression) { assert(0); }
	override void visit(astbase.WhenElseExpression) { assert(0); }
	override void visit(astbase.IntegerExpression) { assert(0); }
	override void visit(astbase.RealNumberExpression) { assert(0); }
	override void visit(astbase.StringExpression) { assert(0); }
	override void visit(astbase.IdentifierExpression) { assert(0); }
	override void visit(astbase.AnyExpression) { assert(0); }
	override void visit(astbase.FalseExpression) { assert(0); }
	override void visit(astbase.TrueExpression) { assert(0); }
	override void visit(astbase.NullExpression) { assert(0); }
	override void visit(astbase.ThisExpression) { assert(0); }
	override void visit(astbase.SuperExpression) { assert(0); }
	override void visit(astbase.DollarExpression) { assert(0); }
	override void visit(astbase.UnitExpression) { assert(0); }
	override void visit(astbase.TupleExpression) { assert(0); }
	override void visit(astbase.NewExpression) { assert(0); }
	override void visit(astbase.ArrayExpression) { assert(0); }
	override void visit(astbase.AssocArrayExpression) { assert(0); }
	override void visit(astbase.BuiltInTypePropertyExpression) { assert(0); }
	override void visit(astbase.TemplateInstanceExpression) { assert(0); }
	override void visit(astbase.TypeidExpression) { assert(0); }
	override void visit(astbase.BlockExpression) { assert(0); }
	override void visit(astbase.MixinExpression) { assert(0); }

	/* Type */
	override void visit(astbase.Type) { assert(0); }
	override void visit(astbase.FunctionType) { assert(0); }
	override void visit(astbase.PointerType) { assert(0); }
	override void visit(astbase.BuiltInType) { assert(0); }
	override void visit(astbase.ArrayType) { assert(0); }
	override void visit(astbase.AssocArrayType) { assert(0); }
	override void visit(astbase.TupleType) { assert(0); }
	override void visit(astbase.SymbolType) { assert(0); }
	override void visit(astbase.IdentifierType) { assert(0); }
	override void visit(astbase.TemplateInstanceType) { assert(0); }
	override void visit(astbase.MixinType) { assert(0); }
	
	/* Statement */
	override void visit(astbase.ExpressionStatement) { assert(0); }
	override void visit(astbase.IfElseStatement) { assert(0); }
	override void visit(astbase.WhileStatement) { assert(0); }
	override void visit(astbase.DoWhileStatement) { assert(0); }
	override void visit(astbase.ForStatement) { assert(0); }
	override void visit(astbase.ForeachStatement) { assert(0); }
	override void visit(astbase.ForeachReverseStatement) { assert(0); }
	override void visit(astbase.BreakStatement) { assert(0); }
	override void visit(astbase.ContinueStatement) { assert(0); }
	override void visit(astbase.GotoStatement) { assert(0); }
	override void visit(astbase.ReturnStatement) { assert(0); }
	override void visit(astbase.LabelStatement) { assert(0); }
	override void visit(astbase.BlockStatement) { assert(0); }
	override void visit(astbase.MixinStatement) { assert(0); }
	
	/* Declaration */
	override void visit(astbase.LetDeclaration) { assert(0); }
	override void visit(astbase.FuncDeclaration) { assert(0); }
	override void visit(astbase.AggregateDeclaration) { assert(0); }
	override void visit(astbase.StructDeclaration) { assert(0); }
	override void visit(astbase.TypedefDeclaration) { assert(0); }
	
	/* TemplateInstance */
	override void visit(astbase.TemplateInstance) { assert(0); }
	/* Mixin */
	override void visit(astbase.Mixin) { assert(0); }
	/* Typeid */
	override void visit(astbase.Typeid) { assert(0); }
}
