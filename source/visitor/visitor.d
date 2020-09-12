module visitor.visitor;

import ast.ast;

/// visitor class for ASTs.
abstract class Visitor {
	/* astnode.d */
    void visit(ASTNode);
	
    /* aggregate.d */
    void visit(AggregateDeclaration);

	/* declaration.d */
	void visit(LetDeclaration);
	void visit(TypedefDeclaration);
	void visit(ImportDeclaration);
	void visit(AliasImportDeclaration);
	void visit(BindedImportDeclaration);

    /* expression.d */
    void visit(Expression);
    void visit(BinaryExpression);
	void visit(AssExpression);
	void visit(BinaryAssExpression);
	void visit(AddAssExpression);
	void visit(SubAssExpression);
	void visit(CatAssExpression);
	void visit(MulAssExpression);
	void visit(DivAssExpression);
	void visit(ModAssExpression);
	void visit(PowAssExpression);
	void visit(BitAndAssExpression);
	void visit(BitXorAssExpression);
	void visit(BitOrAssExpression);
    void visit(PipelineExpression);
    void visit(AppExpression);
    void visit(OrExpression);
    void visit(XorExpression);
    void visit(AndExpression);
    void visit(BitOrExpression);
    void visit(BitXorExpression);
    void visit(BitAndExpression);
    void visit(EqExpression);
    void visit(NeqExpression);
    void visit(LsExpression);
    void visit(LeqExpression);
    void visit(GtExpression);
    void visit(GeqExpression);
    void visit(NisExpression);
    void visit(InExpression);
    void visit(NinExpression);
    void visit(AddExpression);
    void visit(SubExpression);
    void visit(CatExpression);
    void visit(MulExpression);
    void visit(DivExpression);
    void visit(ModExpression);
    void visit(LShiftExpression);
    void visit(RShiftExpression);
    void visit(LogicalShiftExpression);
    void visit(PowExpression);
    void visit(ApplyExpression);
    void visit(CompositionExpression);
    void visit(DotExpression);
    void visit(UnaryExpression);
    void visit(MinusExpression);
    void visit(NotExpression);
    void visit(RefofExpression);
    void visit(DerefExpression);
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
    void visit(AArrayExpression);
    void visit(BuiltInTypePropertyExpression);
    void visit(TemplateInstanceExpression);
    void visit(TypeidExpression);
	void visit(MixinExpression);
	
	/* func.d */
	void visit(FuncArgument);
	void visit(FuncDeclaration);

	/* mixin_.d */
	void visit(Mixin);

	/* module_.d */
	void visit(Module);
	void visit(Package);

    /* statement.d */
	void visit(Statement);
	void visit(DeclarationStatement);
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

	/* struct_.d */
	void visit(StructDeclaration);

	/* symbol.d */
	void visit(Symbol);
	void visit(ScopeSymbol);

    /* template_.d */
    void visit(TemplateInstance);
	void visit(TemplateDeclaration);

    /* type.d */
    void visit(Type);
    void visit(ErrorType);
    void visit(BuiltInType);
    void visit(FuncType);
    void visit(LazyType);
    void visit(PtrType);
    void visit(ArrayType);
    void visit(AArrayType);
    void visit(TupleType);
	void visit(SymbolType);
	void visit(IdentifierType);
    void visit(InstanceType);
	void visit(StructType);
    //void visit(MixinType);
	
	/* typeid_.d */
    void visit(Typeid);
}

