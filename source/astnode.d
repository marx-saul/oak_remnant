module astnode;

import visitor;

/// ASTNode class, the root object of every AST node.
abstract class ASTNode {
	/// accept method for the visitor
	void accept(Visitor);
}
