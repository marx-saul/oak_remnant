/**
 * visitor/permissive.d
 * defines PermissiveVisitor that do not forces one to implement all visit method
 */
module visitor.permissive;

import visitor.visitor;
import ast.ast;

class PermissiveVisitor : Visitor {
	/* astnode.d */
    override void visit(ASTNode) {}
	
    /* aggregate.d */
    override void visit(AggregateDeclaration) {}

	/* declaration.d */
	override void visit(FuncArgument) {}
	override void visit(FuncDeclaration) {}
	override void visit(LetDeclaration) {}
	override void visit(TypedefDeclaration) {}

    /* expression.d */
    override void visit(Expression) {}
    override void visit(BinaryExpression) {}
    override void visit(UnaryExpression) {}
    override void visit(IndexingExpression) {}
    override void visit(SlicingExpression) {}
    override void visit(AscribeExpression) {}
    override void visit(WhenElseExpression) {}
    override void visit(IntegerExpression) {}
    override void visit(RealNumberExpression) {}
    override void visit(StringExpression) {}
    override void visit(IdentifierExpression) {}
    override void visit(AnyExpression) {}
    override void visit(FalseExpression) {}
    override void visit(TrueExpression) {}
    override void visit(NullExpression) {}
    override void visit(ThisExpression) {}
    override void visit(SuperExpression) {}
    override void visit(DollarExpression) {}
    override void visit(UnitExpression) {}
    override void visit(TupleExpression) {}
    override void visit(NewExpression) {}
    override void visit(ArrayExpression) {}
    override void visit(AArrayExpression) {}
    override void visit(BuiltInTypePropertyExpression) {}
    override void visit(TemplateInstanceExpression) {}
    override void visit(TypeidExpression) {}
	override void visit(MixinExpression) {}

	/* mixin_.d */
	override void visit(Mixin) {}

	/* module_.d */
	override void visit(Module) {}
	override void visit(Package) {}

    /* statement.d */
	override void visit(Statement) {}
	override void visit(DeclarationStatement) {}
    override void visit(ExpressionStatement) {}
    override void visit(IfElseStatement) {}
    override void visit(WhileStatement) {}
    override void visit(DoWhileStatement) {}
    override void visit(ForStatement) {}
    override void visit(ForeachStatement) {}
    override void visit(ForeachReverseStatement) {}
    override void visit(BreakStatement) {}
    override void visit(ContinueStatement) {}
    override void visit(GotoStatement) {}
    override void visit(ReturnStatement) {}
    override void visit(LabelStatement) {}
    override void visit(BlockStatement) {}
    override void visit(MixinStatement) {}

	/* struct_.d */
	override void visit(StructDeclaration) {}

	/* symbol.d */
	override void visit(Symbol) {}
	override void visit(ScopeSymbol) {}

    /* template_.d */
    override void visit(TemplateInstance) {}
	override void visit(TemplateDeclaration) {}

    /* type.d */
    override void visit(Type) {}
    override void visit(ErrorType) {}
    override void visit(BuiltInType) {}
    override void visit(FuncType) {}
    override void visit(LazyType) {}
    override void visit(PtrType) {}
    override void visit(ArrayType) {}
    override void visit(AArrayType) {}
    override void visit(TupleType) {}
	override void visit(SymbolType) {}
    override void visit(StructType) {}
    override void visit(TypedefType) {}
    //override void visit(MixinType) {}
	
	/* typeid_.d */
    override void visit(Typeid) {}
}