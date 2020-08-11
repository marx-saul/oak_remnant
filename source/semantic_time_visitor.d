/** 
 * semantic_time_visitor.d
 * Visitor class for ast.ASTNode
 */
module semantic_time_visitor;

import ast;

/**
 * General semantic-time visitor for ast
 */
abstract class SemanticTimeVisitor {
	void visit(ASTNode);
	
	void visit(Expression);
	void visit(BinaryExpression);
	
	void visit(Type);
	void visit(ErrorType);
	void visit(BuiltInType);
	void visit(FuncType);
	void visit(PropType);
	void visit(PtrType);
	void visit(ArrayType);
	void visit(AArrayType);
	void visit(TupleType);
	void visit(SymbolType);
	void visit(TypedefType);
	void visit(StructType);
	
	void visit(AggregateDeclaration);
	void visit(StructDeclaration);
	void visit(TypedefDeclaration);
}

/**
 * Permissive semantic-time visitor that does not forces one to override all visit members.
 */
class PermissiveVisitor : SemanticTimeVisitor {
	override void visit(ASTNode) {}
	
	override void visit(Expression) {}
	override void visit(BinaryExpression) {}
	
	override void visit(Type) {}
	override void visit(ErrorType) {}
	override void visit(BuiltInType) {}
	override void visit(FuncType) {}
	override void visit(PropType) {}
	override void visit(PtrType) {}
	override void visit(ArrayType) {}
	override void visit(AArrayType) {}
	override void visit(TupleType) {}
	override void visit(SymbolType) {}
	override void visit(TypedefType) {}
	override void visit(StructType) {}
	
	override void visit(AggregateDeclaration) {}
	override void visit(StructDeclaration) {}
	override void visit(TypedefDeclaration) {}
}
