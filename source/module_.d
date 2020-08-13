module module_;

import token: Location;
import astnode;
import symbol;
import visitor;

final class Module : ScopeSymbol {
    string[] modname;
    ASTNode[] decls;
    
    this (Location loc, string[] modname, ASTNode[] decls) {
        if (modname.length > 0)
            super(SYMKind.module_, Identifier(modname[$-1], loc));
        else
            // currently.
            super(SYMKind.module_, Identifier(loc.path, loc));
        
        this.modname = modname, this.decls = decls;
    }
    
    override void accept(Visitor v) {
        v.visit(this);
    }
    
}