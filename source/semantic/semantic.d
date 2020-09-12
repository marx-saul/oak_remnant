module semantic.semantic;

import token: Location;
import ast.ast: ASTNode;
import visitor.visitor;

// general pass
enum PASS : ubyte {
	init = 0,			/// semantic procedure has not been called
	inprocess = 10,		/// semantic procedure is in process
	done = 20,			/// semantic procedure is done
}

public import
	semantic.expression,
	semantic.scope_,
	semantic.set_scope,
	semantic.symbolsem,
	semantic.type
	;