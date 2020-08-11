module statement;

import token;
import ast;
import semantic_time_visitor;
import scope_;

abstract class Statement : ASTNode {
    Scope semsc;                        /// used for semantic analysis
}
