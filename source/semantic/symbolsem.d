module semantic.symbolsem;

import message;
import ast.ast;
import semantic.scope_;
import semantic.set_scope;
import semantic.semantic;
import visitor.general;
import std.algorithm: among;

/**
 * Set the symbol table recursively for each scope-symbols.
 * This includes expanding static if-else and mixin declarations if needed
 */
void symbolSem(ScopeSymbol sym) {
	if (!sym || sym.sempass == PASS.done) return;
	setScope(sym);
	scope ssv = new SymbolSemVisitor;
	sym.accept(ssv);
}

/*********************************************
 */
final class SymbolSemVisitor : GeneralVisitor {
	alias visit = GeneralVisitor.visit;
	
	private ScopeSymbol scopesym;
	/// table to push symbols in
	private SymbolTable table() @property {
		return scopesym ? scopesym.table : null;
	}
	
	private void register(Identifier id, Symbol sym, bool ignoreError=false) {
		assert(table);
		
		// already exist
		if (auto col = table[id.name]) {
			if (!ignoreError)
				message.error(
					id.loc,
					"Multiple declaration of \x1b[46m", id.name, "\x1b[0m, ",
					"already appeared in ", col.toString()
				);
		}
		else {
			table[id.name] = sym;	// push this symbol
		}
	}
	
	override void visit(Symbol sym) {
		if (sym.sempass == PASS.done) return;
		if (!table) return;
		//semlog("SymbolSemVisitor.visit(Symbol) ", typeid(sym), " ", sym.id.name);
		
		register(sym.id, sym);
		
		sym.sempass = PASS.done;
	}
	
	override void visit(ScopeSymbol sym) {
		if (sym.sempass == PASS.done) { return; }
		// cycle detected
		if (sym.sempass == PASS.inprocess) {
			message.error(sym.id.loc, "Circular reference to \x1b[1m", sym.id.name, "\x1b[0m.");
			return;
		}
		semlog("SymbolSemVisitor.visit(ScopeSymbol) ", typeid(sym), " ", sym.id.name);
		
		/* ********************************************************************* */
		visit(cast(Symbol) sym);	// push this symbol
		sym.sempass = PASS.inprocess;
		
		const tmp_scopesym = scopesym;		// save
		scopesym = sym;			// one step deeper
		
		bool need_redo = false;		// whether there is any of mixin, static if-else, template mixin, version, debug, declaration
		// push members to the symbol table
		foreach (s; sym.members) {
			assert(s);
			if (s.sempass == PASS.done) continue;
			
			// in the first process do not expand mixin, static if-else, template mixin, version, debug
			with (SYMKind)
			if (s.kind.among!(mixin_, staticif, template_mixin, version_, debug_)) {
				need_redo = true;
			}
			else {
				s.accept(this);		// recursive call
			}
		}
		
		// expand mixin, static if-else, template mixin, version, debug;
		if (need_redo) {
			
		}
		
		scopesym = cast(ScopeSymbol)tmp_scopesym;			// recover
	}
	
	override void visit(FuncArgument) { assert(0); }
	
	// do not look inside function body
	override void visit(FuncDeclaration sym) {
		visit(cast(Symbol) sym);
	}
	
	override void visit(LetDeclaration ld) {
		if (ld.sempass == PASS.done) { return; }
		//semlog("SymbolSemVisitor.visit(LetDeclaration) ", ld.id.name);
		
		// register each identifiers
		for (auto node = ld; node; node = node.next) {
			assert(node !is node.next);
			visit(cast(Symbol) node);
		}
		
		ld.sempass = PASS.done;
	}
	
	override void visit(ImportDeclaration imd) {
		if (imd.sempass == PASS.done) { return; }
		//semlog("SymbolSemVisitor.visit(ImportDeclaration) ", imd.id.name);
		
		scopesym.import_tree.push(imd);
		register(imd.id, imd, true);
		imd.sempass = PASS.done;
		
		if (imd.next) imd.next.accept(this);
	}
	
	override void visit(AliasImportDeclaration aimd) {
		if (aimd.sempass == PASS.done) { return; }
		//semlog("SymbolSemVisitor.visit(AliasImportDeclaration) ", aimd.id.name);
		
		register(aimd.id, aimd);
		aimd.sempass = PASS.done;
		
		if (aimd.next) aimd.next.accept(this);
	}
	
	override void visit(BindedImportDeclaration bimd) {
		if (bimd.sempass == PASS.done) { return; }
		//semlog("SymbolSemVisitor.visit(BindedImportDeclaration) ", bimd.id.name);
		
		register(bimd.id, bimd);
		bimd.sempass = PASS.done;
		
		if (bimd.next) bimd.next.accept(this);
	}
}