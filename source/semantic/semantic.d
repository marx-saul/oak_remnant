module semantic.semantic;

import token: Location;
import ast.ast: ASTNode;
import visitor.visitor;

enum PASS {
	none,
	//context,
	//contextdone,
	semantic,
	semanticdone,
}
