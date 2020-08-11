/** 
 * parse_time_visitor.d
 * Visitor class for astbase.ASTNode
 */
module parse_time_visitor;

import astbase;

abstract class ParseTimeVisitor {
	void visit(ASTNode);
	
	/* Module */
	void visit(Module);

	/* Expression */
	void visit(Expression);
	void visit(BinaryExpression);
	void visit(UnaryExpression);
	void visit(IndexingExpression);
	void visit(SlicingExpression);
	void visit(AscribeExpression);
	void visit(WhenElseExpression);
	void visit(IntegerExpression);
	void visit(RealNumberExpression);
	void visit(StringExpression);
	void visit(IdentifierExpression);
	void visit(AnyExpression);
	void visit(FalseExpression);
	void visit(TrueExpression);
	void visit(NullExpression);
	void visit(ThisExpression);
	void visit(SuperExpression);
	void visit(DollarExpression);
	void visit(UnitExpression);
	void visit(TupleExpression);
	void visit(NewExpression);
	void visit(ArrayExpression);
	void visit(AssocArrayExpression);
	void visit(BuiltInTypePropertyExpression);
	void visit(TemplateInstanceExpression);
	void visit(TypeidExpression);
	void visit(BlockExpression);
	void visit(MixinExpression);

	/* Type */
	void visit(Type);
	void visit(FunctionType);
	void visit(PointerType);
	void visit(BuiltInType);
	void visit(ArrayType);
	void visit(AssocArrayType);
	void visit(TupleType);
	void visit(SymbolType);
	void visit(IdentifierType);
	void visit(TemplateInstanceType);
	void visit(MixinType);
	
	/* Statement */
	void visit(ExpressionStatement);
	void visit(IfElseStatement);
	void visit(WhileStatement);
	void visit(DoWhileStatement);
	void visit(ForStatement);
	void visit(ForeachStatement);
	void visit(ForeachReverseStatement);
	void visit(BreakStatement);
	void visit(ContinueStatement);
	void visit(GotoStatement);
	void visit(ReturnStatement);
	void visit(LabelStatement);
	void visit(BlockStatement);
	void visit(MixinStatement);
	
	/* Declaration */
	void visit(LetDeclaration);
	void visit(FuncDeclaration);
	void visit(AggregateDeclaration);
	void visit(StructDeclaration);
	void visit(TypedefDeclaration);
	
	/* TemplateInstance */
	void visit(TemplateInstance);
	/* Mixin */
	void visit(Mixin);
	/* Typeid */
	void visit(Typeid);
}
