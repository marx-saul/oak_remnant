module struct_;

import token: Location;
import astnode;
import symbol;
import visitor;
import aggregate;

final class StructDeclaration : AggregateDeclaration {
    this(Identifier id, ASTNode[] decls) {
        super(SYMKind.struct_, id, decls);
    }
    override void accept(Visitor v) {
        v.visit(this);
    }
}
