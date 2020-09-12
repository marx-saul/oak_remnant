/**
 * semantic/scope_.d
 * The scope structure of symbols.
 * Symbol lookup and access are implemented here.
 */
module semantic.scope_;

import message;
import ast.ast;
import semantic.semantic;
import message;
/+
enum SCP : ulong {
	inlambda = 1UL,
}

enum AccessOpt : ulong {
	ignoreVisibility = 1UL,
}
+/

/// The scope class
final class Scope {
	Scope enclosing;					/// Lexically enclosing scope
	ScopeSymbol scsym;					/// corresponding scope-symbol
	
	this (Scope enclosing, ScopeSymbol scsym) {
		this.enclosing = enclosing, this.scsym = scsym;
	}
	/*this (ScopeSymbol scsym) {
		this.scsym = scsym;
	}*/
	
	/// Get the root module
	inout(Module) rootModule() inout const @property {
		if (_rootModule)
			return cast(inout) _rootModule;
		// go up the scope until reaching the module scope
		for (auto sc = cast(Scope) this; sc && sc.scsym; sc = sc.enclosing) {
			if (auto mdl = sc.scsym.isModule)
				return cast(inout) (cast(Module)_rootModule = cast(Module) mdl);
		}
		assert(0);
	}
	private Module _rootModule;			/// the result of rootModule()
	
	/// Get the function declaration we are in
	inout(FuncDeclaration) funcDeclaration() inout const @property {
		if (func_set)
			return cast(inout) _func;
		// go up the scope until reaching the func scope
		auto sc = cast(Scope) this;
		while (sc && sc.scsym) {
			sc = sc.enclosing;
			if (auto fd = scsym.isFuncDeclaration()) {
				cast(bool) func_set = true;
				cast(FuncDeclaration) _func = cast(FuncDeclaration) fd;
				return cast(inout) _func;
			}
		}
		return null;
	}
	private FuncDeclaration _func;		/// the result of funcDeclaration()
	private bool func_set = false;			/// whether func is set
	
	/**
	 * Search for an identifier, starting from this scope, going up the scopes and symbol declaration.
	 * This does not look outside the module. That is done in 'lookup'
	 * Returns: null if not found, symbol if found
	 */
	inout(Symbol) search(string name) inout const {
		//semlog("Scope.search(string) search for ", name, " in ", scsym.recoverString());
		
		// go up scopes
		for (auto sc = cast(Scope)this; sc; sc = sc.enclosing) {
			assert(sc !is sc.enclosing);
			assert(sc.scsym);
			if (auto sym = sc.scsym.table[name])
				return cast(inout) sym;
		}
		return null;
	}
	
	/**
	 * Privides a complete symbol lookup 
	 * Params:
	 *     name = the string of the symbol
	 *     root = the root pacakge
	 */
	Symbol[] lookup(string name, Package root) {
		// declared within this module
		if (auto sym = search(name)) {
			return [sym];
		}
		
		auto mdls = getImportedModules(root);
		
		bool[Symbol] symbolset;
		foreach (mdl; mdls) {
			foreach (sym; access(mdl, name, root)) symbolset[sym] = true;
		}
		
		return symbolset.keys;
	}
	// go up the scopes and get all imported modules
	private Module[] getImportedModules(Package root) {
		if (_importedModules) return _importedModules;
		
		// go up scopes
		for (auto sc = cast(Scope)this; sc; sc = sc.enclosing) {
			assert(sc !is sc.enclosing);
			assert(sc.scsym);
			sc.scsym.foreachSymbol((Symbol s) {
				if (auto imd = s.isImportDeclaration) {
					if (imd.isAliasImportDeclaration || imd.isBindedImportDeclaration)
						return;
					else if (auto mdl = imd.getModule(root)) _importedModules ~= mdl;
				}
			});
		}
		return _importedModules;
	}
	private Module[] _importedModules = null;
	
	/**
	 * Access the member of a scope symbol from this scope.
	 * Params:
	 *     scsym = the scope-symbol in which we will find the member
	 *     name = the name of the member
	 *     root = the root package
	 */
	Symbol[] access(ScopeSymbol scsym, string name, Package root) {
		if (auto sym = scsym.getMember(name)) {
			auto prlv = sym.prlv;
			with (PRLV)
			final switch (prlv) {
			case private_:
				// belong to the same module
				if (this.rootModule is scsym.semsc.rootModule) return [sym];
				else return [];
			
			case package_:
				// this scope belongs to the same pkg with 'withinPkg'
				auto withinPkg = scsym.semsc.rootModule.parent;
				for (auto pkg = this.rootModule.parent; pkg; pkg = pkg.parent) {
					assert(pkg !is pkg.parent);
					if (withinPkg is pkg) return [sym];
				}
				return [];
			
			case undefined:
			case public_:
			case export_:
				return [sym];
			
			case protected_:
				assert(0, "Access to protected symbols are not implemented.");
				
			case package_specified:
				assert(0, "Protection level \x1b[46mpackage(...)\x1b[0m with packages specified has not been implemented.");
			}
		}
		
		// search for symbol from public import
		if (auto mdl = scsym.isModule) {
			if (mdl.insearch) return [];
			else mdl.insearch = true;
		}
		
		bool[Symbol] symbolset;
		Module[] publicImportedModules;
		scsym.foreachSymbol((Symbol s) {
			if (auto imd = s.isImportDeclaration) {
				if (imd.isAliasImportDeclaration || imd.isBindedImportDeclaration)
					return;
				else if (imd.prlv != PRLV.private_) {
					if (auto mdl = imd.getModule(root)) publicImportedModules ~= mdl;
				}
			}
		});
		foreach (mdl; publicImportedModules) {
			if (mdl.syntax_error) continue;
			foreach (sym; scsym.semsc.access(mdl, name, root))
				symbolset[sym] = true;
		}
		
		// search for symbol from public import
		if (auto mdl = scsym.isModule) {
			mdl.insearch = false;
		}
		
		return symbolset.keys;
	}
	
	/**
	 * From the sequence of identifiers foo.bar.baz. ... , find the longest imported module that matches foo.bar.baz. ...
	 * 
	 */
	inout(ImportDeclaration) accessImportedModule(Symbol[] syms) inout const {
		string[] idents;
		foreach (sym; syms) {
			if (sym && sym.kind == SYMKind.unsolved) {
				idents ~= sym.id.name;
			}
		}
		return accessImportedModule(idents);
	}
	
	inout(ImportDeclaration) accessImportedModule(string[] idents) inout const
	in {
		assert(idents.length > 0);
	}
	do {
		ImportTree[] trees;
		for (auto sc = cast(Scope)this; sc; sc = sc.enclosing) {
			assert(sc !is sc.enclosing);
			auto tree = sc.scsym.import_tree;
			if (auto subtree = idents[0] in tree.children) trees ~= *subtree;
		}
		
		foreach (name; idents[1..$]) {
			ImportTree[] newtrees;
			foreach (tree; trees) {
				if (auto newtree = name in tree.children) newtrees ~= *newtree;
			}
			if (newtrees.length == 0) break;
			else trees = newtrees;
		}
		
		if (trees.length == 0) return null;
		else return cast(inout) trees[0].decl;
	}
}
/+
/**
 * Look for symbol from 'modules', and find all symbols
 * 
 */
private Symbol[] symbolLookup(string name, Module[] modules) inout const {
	return null;
}
+/
