module ast.declaration;

import token: Location;
import semantic.scope_;
import ast.attribute;
import ast.expression;
import ast.module_;
import ast.statement;
import ast.symbol;
import ast.type;
import visitor.visitor;

final class LetDeclaration : Symbol {
	Type tp;
	Expression exp;
	LetDeclaration next;	/// <Linked list> next declaration
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Type tp, Expression exp, LetDeclaration next=null) {
		super(SYMKind.var, attrbs, prlv, stc, id);
		this.tp = tp, this.exp = exp, this.next = next;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TypedefDeclaration : Symbol {
	Type tp;
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier id, Type tp) {
		super(SYMKind.typedef, attrbs, prlv, stc, id);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

// import (foo = ) bar.baz;
class ImportDeclaration : Symbol {
	Identifier[] modname;		/// symbols of the module or package ["bar", "baz"]
	ImportDeclaration next;		/// Linked list
	
	inout(AliasImportDeclaration)  isAliasImportDeclaration()  inout const @property { return null; }
	inout(BindedImportDeclaration) isBindedImportDeclaration() inout const @property { return null; }
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier[] modname) {
		if (prlv == PRLV.undefined) prlv = PRLV.private_;
		super(SYMKind.import_, attrbs, prlv, stc, modname[0]);
		this.modname = modname;
	}
	
	/// Returns the corresponding module
	inout(Module) getModule(Package root) inout const {
		if (module_set) return cast(inout) _module;
		else {
			cast(bool) module_set = true;
			cast(Module) _module = root.getModule(modname);
			return cast(inout) _module;
		}
	}
	private Module _module;					/// the result of getModule
	private bool module_set = false;		/// whether _module_ is set
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AliasImportDeclaration : ImportDeclaration {
	override inout(AliasImportDeclaration)  isAliasImportDeclaration()  inout const @property { return null; }
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier replace, Identifier[] modname) {
		super(attrbs, prlv, stc, modname);
		this.id = replace;
		this.modname = modname;
		this.prlv = PRLV.private_;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

// import foo.bar : baz = qux, quux, corge, ...
final class BindedImportDeclaration : ImportDeclaration {
	Identifier binded;		/// import 'modname' : 'id' = 'binded'
	
	override inout(BindedImportDeclaration) isBindedImportDeclaration() inout const @property { return null; }
	
	this (Attribution[] attrbs, PRLV prlv, StorageClass stc, Identifier[] modname, Identifier id, Identifier binded) {
		super(attrbs, prlv, stc, modname);
		this.id = id;
		this.binded = binded;
		this.prlv = PRLV.private_;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}