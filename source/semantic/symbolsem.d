module semantic.symbolsem;

import message;
import ast.ast;
import semantic.scope_;
import semantic.semantic;
import visitor.general;
import std.algorithm: among;

/**
 * Set the symbol table recursively for each scope-symbols,
 * but do not look inside function body.
 */
void symbolSem(ScopeSymbol sym) {
	if (!sym || sym.pass1 == PASS1.done) { return; }
	auto ssv = new SymbolSemVisitor;
	sym.accept(ssv);
}

/*********************************************
 */
final class SymbolSemVisitor : GeneralVisitor {
	alias visit = GeneralVisitor.visit;
	
	private SymbolTable table;		/// table to push symbols in
	
	private void register(Identifier id, Symbol sym) {
		assert(table);
		
		// already exist
		if (auto col = table[id.name]) {
			message.error(id.loc,
				"Multiple declaration of \x1b[46m", id.name, "\x1b[0m, ",
				"already appeared in ", col.toString());
		}
		else {
			table[id.name] = sym;	// push this symbol
		}
	}
	
	override void visit(Symbol sym) {
		if (sym.pass1 == PASS1.done) return;
		if (!table) return;
		semlog("SymbolSemVisitor.visit(Symbol) ", typeid(sym), " ", sym.id.name);
		
		register(sym.id, sym);
		
		
		sym.pass1 = PASS1.done;
	}
	
	override void visit(ScopeSymbol sym) {
		if (sym.pass1 == PASS1.done) { return; }
		// cycle detected
		if (sym.pass1 == PASS1.inprocess) {
			message.error(sym.id.loc, "Circular reference to \x1b[1m", sym.id.name, "\x1b[0m.");
			return;
		}
		semlog("SymbolSemVisitor.visit(ScopeSymbol) ", typeid(sym), " ", sym.id.name);
		
		/* ********************************************************************* */
		visit(cast(Symbol) sym);	// push this symbol
		sym.pass1 = PASS1.inprocess;
		
		auto tmp_table = table;		// save
		table = sym.table;			// one step deeper
		
		bool need_redo = false;		// whether there is any of mixin, static if-else, template mixin, version, debug, declaration
		// push members to the symbol table
		foreach (s; sym.members) {
			assert(s);
			if (s.pass1 == PASS1.done) continue;
			
			// in the first process do not expand mixin, static if-else, template mixin, version, debug
			with (SYMKind)
			if (s.kind.among!(mixin_, staticif, template_mixin, version_, debug_)) {
				need_redo = true;
			}
			else {
				s.accept(this);		// recursive call
			}
		}
		
		// expand mixin, stati if-else, template mixin, version, debug;
		if (need_redo) {
			
		}
		
		table = tmp_table;			// recover
	}
	
	// do not look inside function body
	override void visit(FuncDeclaration sym) {
		visit(cast(Symbol) sym);
	}
	
	override void visit(FuncArgument) { assert(0); }
	
	override void visit(LetDeclaration ld) {
		if (ld.pass1 == PASS1.done) { return; }
		semlog("SymbolSemVisitor.visit(LetDeclaration) ", ld.id.name);
		
		// register each identifiers
		for (auto node = ld; node; node = node.next) {
			assert(node !is node.next);
			visit(cast(Symbol) node);
		}
		
		ld.pass1 = PASS1.done;
	}
	
	override void visit(ImportDeclaration imd) {
		if (imd.pass1 == PASS1.done) { return; }
		semlog("SymbolSemVisitor.visit(ImportDeclaration) ", typeid(imd), " ", imd.id.name);
		
		for (auto node = imd; node; node = node.next) {
			assert(node !is node.next);
			// binded
			if (node.isBinded()) {
				node.accept(this);
				assert(!node.next);
				break;
			}
			// not binded
			else {
				visit(cast(Symbol) node);
			}
		}
		
		imd.pass1 = PASS1.done;
	}
	
	override void visit(BindedImportDeclaration bimd) {
		if (bimd.pass1 == PASS1.done) { return; }
		semlog("SymbolSemVisitor.visit(BindedImportDeclaration) ", bimd.id.name);
		
		foreach (i; 0 .. bimd.imports.length) {
			//if (bimd.bindings[i].length > 0)
		}
		
		bimd.pass1 = PASS1.done;
	}
}