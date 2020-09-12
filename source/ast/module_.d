/**
 * ast/module.d
 * The modules and packages.
 */
module ast.module_;

import message;
import token: Location;
import ast.astnode;
import ast.attribute;
import ast.symbol;
import parser;
import visitor.visitor;

class Package : ScopeSymbol {
	Package parent;		/// parent package
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Symbol[] members=[]) {
		super(SYMKind.package_, attrbs, prlv, stc, id, members);
	}
	
	this (Identifier id) {
		this([], PRLV.undefined, STC.undefined, id);
		this.kind = SYMKind.package_;
	}
	
	private this() {
		super(SYMKind.package_, [], PRLV.undefined, STC.undefined, Identifier.init);
	}
	/// create the root package
	static Package createRoot() {
		return new Package;
	}
	
	/**
	 * Get the directory
	 */
	string getDirectory() inout const @property pure {
		return parent.getDirectory ~ "/" ~ this.id.name;
	}
	
	/**
	 * Push a package to the root package.
	 * Params:
	 *     pkg = the package to push
	 *     names = the package's symbol (foo.bar.baz)
	 * Returns:
	 *     false if error
	 */
	bool push(Package pkg, const(string)[] names) {
		assert(!this.parent);
		if (pkg is null) return true;
		
		if (auto mdl = pkg.isModule) {
			// module 'package.oak'
			if (mdl.is_package) {
				names ~= ["package"];
			}
		}
		
		bool is_new_pkg = false;
		auto bottom = this;
		foreach (i, name; names[0 .. $-1]) {
			// already exist
			if (auto sym = bottom.table[name]) {
				// module under module
				if (sym.isModule) {
					import global;
					message.error(Location.init,
						"Module/Package \x1b[1m" ~ dotcat(names) ~ "\x1b[0m conflicts with the module",
						"\x1b[1m" ~ dotcat(names[0 .. i+1]) ~ "\x1b[0m."
					);
					return false;
				}
				else bottom = sym.isPackage;
				import std: to;
				assert(bottom, sym.id.name ~ " : " ~ typeid(sym).toString() ~ " kind = " ~ sym.kind.to!string);
			}
			// first encounter to the package
			else {
				is_new_pkg = true;
				auto nextpkg = new Package(Identifier(name, Location.init));
				nextpkg.parent = bottom;
				bottom.table[name] = nextpkg;
				bottom = nextpkg;
			}
		}
		
		// the package to which `pkg` belongs already exist
		if (!is_new_pkg) {
			// same package/module already exist
			if (auto exist = bottom.table[names[$-1]]) {
				auto pkg_exist = exist.isPackage();
				assert (pkg_exist);
				// two entries on the same symbol
				if (exist !is pkg) {
					import global : dotcat;
					message.error(Location.init,
						"Module/Package conflict : \x1b[1m" ~ dotcat(names) ~ "\x1b[0m\n",
						"\t", pkg_exist.getDirectory(), "\n\t", pkg.getDirectory()
					);
					return false;
				}
				// same entry
				else {
					return true;
				}
			}
		}
		
		bottom.table[names[$-1]] = pkg;
		pkg.parent = bottom;
		return true;
	}
	
	bool push(Module mdl) {
		if (mdl is null) return true;
		if (mdl.names.length > 0) {
			string[] names;
			foreach (ident; mdl.names) names ~= ident.name;
			return push(mdl, names);
		}
		else return push(mdl, [mdl.id.name]);
	}
	
	/**
	 * Get the module from the root package.
	 * Params:
	 *     idents = the whole module symbol
	 *     parse_new = if the module does not exist in the tree, find the module and parse it
	 */
	Module getModule(const Identifier[] idents, bool parse_new=false)
	in {
		assert(idents.length > 0);
		assert(!this.parent);			// can only be called from the root package
	}
	do {
		Package pkg = this;
		foreach (i, ident; idents) {
			auto nextsym = pkg.table[ident.name];
			// not found
			if (!nextsym) {
				pkg = null;
				break;
			}
			auto nextpkg = nextsym.isPackage;
			assert(nextpkg);
			pkg = nextpkg;
		}
		
		// already exist
		if (pkg) {
			// it was a module
			if (auto mdl = pkg.isModule) return mdl;
			// it was a package
			else if (auto pkgsym = pkg.table["package"]) {
				// return 'package.oak' module
				if (auto pkgmdl = pkgsym.isModule) return pkgmdl;
				// error, it is a package and no 'package.oak' module
				// TO DO : return the parsed package.oak module
				else return null;
			}
			else return null;
		}
		// first encounter to the symbol
		// TO DO : return the parsed module
		else {
			import global : dotcat;
			message.error(idents[0].loc, "Module \x1b[1m", dotcat(idents), "\x1b[0m was not found.");
			return null;
		}
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class Module : Package {
	string filepath;				/// the file path
	Identifier[] names;				/// module declaration
	bool syntax_error = false;		/// does this module contain any syntax errors
    bool is_package = false;		/// is this module .../package.oak
	bool insearch = false;			/// avoid circular symbol look up due to `public import`
	/**
	 * Params:
	 *     loc : Location of the top module token
	 *     names : ["aaa", "bbb", "ccc"] of module aaa.bbb.ccc;
	 *     members : declared symbols
	 */
	static size_t modnum = 0;
	this (string filepath, Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier[] names, Symbol[] members) {
		super(attrbs, prlv, stc, names[$-1], members);
		this.kind = SYMKind.module_;
		this.filepath = filepath, this.names = names;
	}
    /**
	 * Params:
	 *     source = the Range of the source code
	 *     filepath = the path of this module
	 *     root = root package
	 * Returns:
	 *     resulting module
	 */
	static Module parse(Range)(Range source, string filepath, Package root) {
		Module result;
		// parse
		{
			scope parser = new Parser!Range(source, filepath);
			result = parser.parseModule();
			result.syntax_error = parser.is_error;
			if (result.syntax_error) return result;
		}
		
		// set scope
		{
			import semantic.set_scope : setScope;
			setScope(result);
		}
		
		// push the module
		root.push(result);
		
		return result;
	}
	
	override string getDirectory() inout const @property pure {
		return filepath;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}