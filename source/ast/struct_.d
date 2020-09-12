module ast.struct_;

import token: Location;
import ast.astnode;
import ast.aggregate;
import ast.attribute;
import ast.symbol;
import visitor.visitor;

final class StructDeclaration : AggregateDeclaration {
    this(Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Symbol[] members) {
        super(SYMKind.struct_, attrbs, prlv, stc, id, members);
    }
    override void accept(Visitor v) {
        v.visit(this);
    }
}
