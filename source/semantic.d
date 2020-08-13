module semantic;

import token: Location;
import ast: ASTNode;
import visitor;

enum PASS {
	none,
	//context,
	//contextdone,
	semantic,
	semanticdone,
}
