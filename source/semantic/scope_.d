module semantic.scope_;

import message;
import ast.ast;

enum SCKind {
	//module_,	/// module
	struct_,	/// struct declaration
	//union_,
	//class_,
	//interface_,
	//staticif,
}

enum SCP : ulong {
	inlambda = 1UL,
}

enum AccessOpt : ulong {
	ignoreVisibility = 1UL,
	
}

final class Scope {
	Scope enclosing;					/// Lexically enclosing scope
	ScopeSymbol scsym;					/// corresponding scope-symbol
	
	this (Scope enclosing, ScopeSymbol scsym) {
		this.enclosing = enclosing;
		this(scsym);
	}
	this (ScopeSymbol scsym) {
		this.scsym = scsym;
	}
	
	/// Get the root module
	inout(Module) rootModule() inout const @property {
		if (_rootModule)
			return cast(inout) _rootModule;
		// go up the scope until reaching the module scope
		auto sc = cast(Scope) this;
		while (sc && sc.scsym) {
			sc = sc.enclosing;
			if (auto mod = scsym.isModule())
				return cast(inout) (cast(Module)_rootModule = cast(Module) mod);
		}
		return null;
	}
	private Module _rootModule;
	
	/// Get the root module
	inout(FuncDeclaration) func() inout const @property {
		if (_func)
			return cast(inout) _func;
		// go up the scope until reaching the func scope
		auto sc = cast(Scope) this;
		while (sc && sc.scsym) {
			assert(sc !is sc.enclosing);
			sc = sc.enclosing;
			
			if (auto fd = scsym.isFuncDeclaration())
				return cast(inout) (cast(FuncDeclaration) _func = cast(FuncDeclaration) fd);
		}
		return null;
	}
	private FuncDeclaration _func;
	
	
	/**
	 * Search for an identifier, starting from this scope, going up the scopes and symbol declaration
	 * Returns: null if not found, symbol if found
	 */
	inout(Symbol) search(string name) inout const {
		semlog("Scope.search(string) search for ", name, " in ", scsym.recoverString());
		auto sc = cast(Scope)this;
		
		while (sc) {
			assert(sc !is sc.enclosing);
			assert(scsym);
			
			if (auto sym = scsym.hasMember(name))
				return sym;
			
			sc = sc.enclosing;
		}
		return null;
	}
	/+
	/**
	 * Access the symbol `foo.bar.baz` from the current scope.
	 * Do not go out of the root module to resolve symbol (that is done in lookup(string[])).
	 * Params:
	 *     names = the symbol of the form foo.bar.baz
	 */
	 inout(Symbol) access(string[] names) inout const {
		semlog("Scope.access(string[]) access ", names, " in ", scsym.recoverString());
		 assert(names.length > 0);
		 
		 // to access foo.bar.baz, first search foo
		 auto sym = cast(Symbol) this.search(names[0]);
		 
		 foreach (name; names[1..$]) {
			 // not found
			 if (!sym) return null;
			 // do not look inside function body
			 if (sym.isFuncDeclaration()) return null;
			 // one step inside
			 if (auto scopesym = sym.isScopeSymbol()) {
				 sym = scopesym.hasMember(name);
			 }
		 }
		 return cast(inout) sym;
	 }
	 +/
	 /**
	  * From foo.bar.baz. ..., search for import xxx.yyy.zzz. ... such that matches the longest.
	  * This must be used after that from search(string) names[0] is known to be a name of a package or a module
	  */
	 inout(ImportDeclaration) accessImportedModule(string[] names) inout const {
		semlog("Scope.accessImportedModule(string[]) search for ", names, " in ", scsym.recoverString());
		
		ImportDeclaration result;
		
		auto sc = cast(Scope)this;
		while (sc) {
			assert(sc !is sc.enclosing);
			assert(sc.scsym);
			
			// access
			auto decl = sc.scsym.import_tree.access(names);
			if (decl) {
				// to the longest
				if (!result || result.names.length < decl.names.length)
					result = cast(ImportDeclaration) decl;
			}
			
			sc = sc.enclosing;
		}
		assert(!result || !result.is_replaced);
		return cast(inout) result;
	 }
	 
	 inout(Symbol) lookup(string name) inout const {
		 if (auto ac = search(name)) {
			 return ac;
		 }
		 return null;
	 }
}
