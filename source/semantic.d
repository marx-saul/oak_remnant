module semantic;

import token: Location;
import ast: ASTNode;
import semantic_time_visitor;

enum PASS {
	none,
	//context,
	//contextdone,
	semantic,
	semanticdone,
}
