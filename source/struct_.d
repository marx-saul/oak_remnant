module struct_;

import token: Location;
import ast;
import semantic_time_visitor;
import aggregate;

private alias Vis = SemanticTimeVisitor;

final class StructDeclaration : AggregateDeclaration {
    this(string name, Location loc) {
        super(SYMKind.struct_, name, loc);
    }
    override void accept(Vis v) {
        v.visit(this);
    }
}
