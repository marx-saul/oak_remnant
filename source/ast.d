module ast;

import semantic_time_visitor;

abstract class ASTNode {
    void accept(SemanticTimeVisitor);
}

public import
    symbol,
    type,
    aggregate,
    struct_,
    declaration,
    expression
    ;
