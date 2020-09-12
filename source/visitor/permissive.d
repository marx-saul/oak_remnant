/**
 * visitor/permissive.d
 * Defines PermissiveVisitor that do not forces one to implement all visit method.
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
	override void visit(LetDeclaration) {}
	override void visit(TypedefDeclaration) {}
	override void visit(ImportDeclaration) {}
	override void visit(AliasImportDeclaration) {}
	override void visit(BindedImportDeclaration) {}

    /* expression.d */    override void visit(Expression) {}
    override void visit(BinaryExpression) {}
	override void visit(AssExpression) {}
	override void visit(BinaryAssExpression) {}
	override void visit(AddAssExpression) {}
	override void visit(SubAssExpression) {}
	override void visit(CatAssExpression) {}
	override void visit(MulAssExpression) {}
	override void visit(DivAssExpression) {}
	override void visit(ModAssExpression) {}
	override void visit(PowAssExpression) {}
	override void visit(BitAndAssExpression) {}
	override void visit(BitXorAssExpression) {}
	override void visit(BitOrAssExpression) {}
    override void visit(PipelineExpression) {}
    override void visit(AppExpression) {}
    override void visit(OrExpression) {}
    override void visit(XorExpression) {}
    override void visit(AndExpression) {}
    override void visit(BitOrExpression) {}
    override void visit(BitXorExpression) {}
    override void visit(BitAndExpression) {}
    override void visit(EqExpression) {}
    override void visit(NeqExpression) {}
    override void visit(LsExpression) {}
    override void visit(LeqExpression) {}
    override void visit(GtExpression) {}
    override void visit(GeqExpression) {}
    override void visit(NisExpression) {}
    override void visit(InExpression) {}
    override void visit(NinExpression) {}
    override void visit(AddExpression) {}
    override void visit(SubExpression) {}
    override void visit(CatExpression) {}
    override void visit(MulExpression) {}
    override void visit(DivExpression) {}
    override void visit(ModExpression) {}
    override void visit(LShiftExpression) {}
    override void visit(RShiftExpression) {}
    override void visit(LogicalShiftExpression) {}
    override void visit(PowExpression) {}
    override void visit(ApplyExpression) {}
    override void visit(CompositionExpression) {}
    override void visit(DotExpression) {}
    override void visit(UnaryExpression) {}
    override void visit(MinusExpression) {}
    override void visit(NotExpression) {}
    override void visit(RefofExpression) {}
    override void visit(DerefExpression) {}
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
	
	/* func.d */
	override void visit(FuncArgument) {}
	override void visit(FuncDeclaration) {}
	
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
	override void visit(IdentifierType) {}
    override void visit(InstanceType) {}
	override void visit(StructType) {}
	
	/* typeid_.d */
    override void visit(Typeid) {}
}