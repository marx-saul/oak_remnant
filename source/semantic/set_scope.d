/**
 * semantic/set_scope.d
 * Set scopes for symbols. Do not look into function bodies.
 */
module semantic.set_scope;

import message;
import ast.ast;
import visitor.permissive;
import semantic.scope_;

/**
 * Recursively set scopes of a module.
 * Do not look into function bodies.
 */
void setScope(Module mod) {
	if (!mod) return;
	scope ssv = new SetScopeVisitor(mod);
	mod.accept(ssv);
}

void setScope(ScopeSymbol ss, Module root_mod=null, Scope enclosing=null) {
	if (ss) return;
	assert(ss.kind != SYMKind.module_);
	scope ssv = new SetScopeVisitor(root_mod, enclosing);
	ss.accept(ssv);
}
/**
 */
class SetScopeVisitor : PermissiveVisitor {
	alias visit = PermissiveVisitor.visit;
	
	Module root_mod;
	Scope enclosing;
	
	/// calling both constructor and visit(Module) result in error
	this (Module root_mod, Scope enclosing=null) {
		this.root_mod = root_mod;
		this.enclosing = enclosing;
	}
	
	override void visit(Symbol sym) {
		log("SetScopeVisitor.visit(Symbol) ", typeid(sym), " ", sym.id.name);
		sym.semsc = enclosing;
	}
	override void visit(FuncDeclaration fd) {
		log("SetScopeVisitor.visit(FuncDeclaration) ", typeid(fd), " ", fd.id.name);
		auto fsc = new Scope(fd);
		fsc.func = fd;
		fsc.module_ = this.root_mod;
		fsc.enclosing = this.enclosing;
		fd.semsc = fsc;
		
		// arguments
		foreach (arg; fd.args) {
			if (arg)
				arg.semsc = fsc;
		}
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
		log("SetScopeVisitor.visit(ScopeSymbol) ", typeid(scopesym), " ", scopesym.id.name);
		// create a new scope
		auto sc = new Scope(scopesym);
		sc.scsym = scopesym;
		sc.module_ = this.root_mod;
		sc.enclosing = this.enclosing;
		
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
	override void visit(Module mod) {
		assert(root_mod is mod);
		this.visit(cast(ScopeSymbol) mod);
	}
	override void visit(AggregateDeclaration sym) { assert(0); }
	override void visit(StructDeclaration sym) {
		this.visit(cast(ScopeSymbol) sym);
	}
	
}