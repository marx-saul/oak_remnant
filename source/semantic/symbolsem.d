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
		
		const tmp_scopesym = scopesym;		// save
		scopesym = sym;			// one step deeper
		
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
		
		scopesym = cast(ScopeSymbol)tmp_scopesym;			// recover
	}
	
	// do not look inside function body
	override void visit(FuncDeclaration sym) {
		// set function arguments
		//foreach (arg; sym.args) {
		//	assert(arg);
		//	sym.args_table[arg.id.name] = arg;
		//}
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
			// import foo = bar.baz;
			if (node.is_replaced)
				visit(cast(Symbol) node);
			// import foo.bar.baz
			else {
				scopesym.import_tree.push(node);
				if (auto sym = scopesym.table[node.id.name]) {
					if (!sym.isImportDeclaration) visit(cast(Symbol) node);	// to yield error message
				}
			}
		}
		
		imd.pass1 = PASS1.done;
	}
	
	override void visit(BindedImportDeclaration bimd) {
		if (bimd.pass1 == PASS1.done) { return; }
		semlog("SymbolSemVisitor.visit(BindedImportDeclaration) ", bimd.id.name);
		
		foreach (i; 0 .. bimd.imports.length) {
			if (bimd.bindings[i].name.length > 0) register(bimd.bindings[i], bimd);
			else register(bimd.imports[i], bimd);
		}
		
		bimd.pass1 = PASS1.done;
	}
}