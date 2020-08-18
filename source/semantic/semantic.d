module semantic.semantic;

import token: Location;
import ast.ast: ASTNode;
import visitor.visitor;

enum PASS1 {
	init,			/// semantic pass has not been called
	inprocess,		/// in process
	done,			/// semantic pass is done
}
