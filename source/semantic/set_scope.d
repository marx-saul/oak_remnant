/**
 * semantic/set_scope.d
 * Set scopes for symbols. Do not look into function bodies.
 */
module semantic.set_scope;

import message;
import ast.ast;
import visitor.general;
import semantic.scope_;

/**
 * Recursively set scopes of a module.
 * Do not look into function bodies.
 */

void setScope(ScopeSymbol ss, Scope enclosing=null) {
	// null or alreay set
	if (!ss || ss.semsc) return;
	scope ssv = new SetScopeVisitor(enclosing);
	ss.accept(ssv);
}
/**********************************************
 */
final class SetScopeVisitor : GeneralVisitor {
	alias visit = GeneralVisitor.visit;
	
	Scope enclosing;
	
	/// calling both constructor and visit(Module) result in error
	this (Scope enclosing=null) {
		import std.stdio;
		this.enclosing = enclosing;
	}
	
	override void visit(Symbol sym) {
		//semlog("SetScopeVisitor.visit(Symbol) ", typeid(sym), " ", sym.id.name);
		sym.semsc = enclosing;
	}
	override void visit(FuncArgument sym) { assert(0); }
	override void visit(LetDeclaration ld) {
		for (auto cur = ld; cur; cur = cur.next)
			this.visit(cast(Symbol) cur);
	}
	override void visit(TypedefDeclaration sym) {
		this.visit(cast(Symbol) sym);
	}
	
	// scope symbol
	override void visit(ScopeSymbol scopesym) {
		//semlog("SetScopeVisitor.visit(ScopeSymbol) ", typeid(scopesym), " ", scopesym.id.name);
		// create a new scope
		auto sc = new Scope(this.enclosing, scopesym);
		// set scope
		scopesym.semsc = sc;
		
		// new enclosing scope
		auto tmp_enclosing = enclosing;		// remember
		this.enclosing = sc;				// new enclosing
	
		// recusively set 
		foreach (sym; scopesym.members) {
			if (sym) sym.accept(this);
		}
		
		this.enclosing = tmp_enclosing;		// recover
	}
	
	override void visit(FuncDeclaration fd) {
		auto fsc = new Scope(this.enclosing, fd);
		fd.semsc = fsc;
	}
	
}