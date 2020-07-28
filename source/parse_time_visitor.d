module parse_time_visitor;

import astbase;

/** 
 * Visitor class for astbase.
 */
abstract class ParseTimeVisitor {
	void visit(ASTNode);

	/* Expressions */
	void visit(BinaryExpression);
	void visit(UnaryExpression);
	void visit(IndexingExpression);
	void visit(SlicingExpression);
	void visit(AscribeExpression);
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
	void visit(MixinExpression);

	/* Types */
	void visit(Type);
	void visit(FunctionType);
	void visit(PointerType);
	void visit(BuiltInType);
	void visit(TupleType);
	void visit(ArrayType);
	void visit(AssocArrayType);

	/* TemplateInstance */
	void visit(TemplateInstance);
	/* Mixin */
	void visit(Mixin);
	/* Typeid */
	void visit(Typeid);
}
