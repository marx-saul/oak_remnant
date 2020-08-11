module type;

import message;
import token;
import ast;
import semantic_time_visitor;
import semantic;

private alias Vis = SemanticTimeVisitor;

enum TPKind {
	error,
	
	int32,
	uint32,
	int64,
	uint64,
	real32,
	real64,
	unit,
	bool_,
	string_,
	char_,
	
	func,	   // Type -> Type
	prop,	   // unit -> Type which can be called without an argument, defined by func f;int32 { return 10; }
	ptr,		// # Type
	//ref_,	   // ref Type
	array,	  // [ Type ]
	aarray,	 // [ Type : Type ]
	tuple,	  // ( Type, Type, ... )
	typedef,  // <A> for typedef A = B;
	//tempinst
	
	struct_,	// <S> for struct S {...}
	//union_,
	//class_,
}

alias TPSIZE = int;
enum TPSIZEInvalid = -1;

enum Sizeok {
	undefined,		  /// size has not been calculated yet
	inprocess,		  /// size is being calculated 
	done,			   /// size has been calculated
}

abstract class Type : ASTNode {
	TPKind kind;		/// Kind of the type.
	Sizeok sizeok;	  /// Cycle detection of the size
	
	/**
	 */
	this (TPKind kind) {
		this.kind = kind;
	}
	
	/**
	 * Return the bytes of the values of type.
	 */
	TPSIZE size() @property;
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ErrorType : Type {
	string error_msg;
	
	this (string error_msg="") {
		super(kind);
		this.error_msg = error_msg;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return TPSIZEInvalid;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class BuiltInType : Type {
	this (TPKind kind) {
		super(kind);
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		with (TPKind)
		switch (kind) {
			case int32:	 return 4;
			case uint32:	return 4;
			case int64:	 return 8;
			case uint64:	return 8;
			case real32:	return 4;
			case real64:	return 8;
			case unit:	  return 4;
			case bool_:	 return 4;
			case string_:   return 8;
			case char_:	 return 4;
			default:		assert(0);
		}
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class FuncType : Type {
	Type ran;
	Type dom;
	
	this (Type ran, Type dom) {
		super(TPKind.func);
		this.ran = ran, this.dom = dom;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return 16u;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class PropType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.prop);
		this.tp = tp;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return 16u;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class PtrType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.ptr);
		this.tp = tp;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return 8u;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class ArrayType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.array);
		this.tp = tp;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return 16u;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class AArrayType : Type {
	Type key;
	Type value;
	
	this (Type key, Type value) {
		super(TPKind.aarray);
		this.key = key, this.value = value;
		sizeok = Sizeok.done;
	}
	
	override TPSIZE size() @property {
		return 8u;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class TupleType : Type {
	Type[] tps;
	
	this (Type[] tps) {
		super(TPKind.tuple);
		this.tps = tps;
	}
	
	TPSIZE _size;		   // remember the size
	override TPSIZE size() @property {
		if (sizeok == Sizeok.done) return _size;
		
		TPSIZE _size;
		foreach (tp; tps) {
			assert(tp);
			if (tp.size != TPSIZEInvalid)
				_size += tp.size;
		}
		sizeok = Sizeok.done;
		return _size;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

class SymbolType : Type {
	Symbol sym;				 // corresponding symbol
	
	this (TPKind kind, Symbol sym) {
		super(kind);
		this.sym = sym;
	}
	
	override TPSIZE size() @property {
		assert(0);
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

/// An identifier type defined by typedef
final class TypedefType : SymbolType {
	/// return the TypedefDeclaration of this symbol
	TypedefDeclaration td() @property {
		return cast(TypedefDeclaration) sym;
	}
	
	this (Symbol sym) {
		super(TPKind.typedef, sym);
	}
	
	/** Get the type the identifier represents.
	 * e.g.
	 *	 module aaa;
	 *	 typedef foo = bar;
	 *	 typedef bar = int32;
	 * <aaa.foo>.resolve = <int32>
	 */
	public Type resolve() {
		// Cycle detected
		if (is_resolving) {
			message.error(sym.loc, "Circular typedef resolving of ", sym.recoverString());
			kind = TPKind.error;
			return this;
		}
		if (_resolve) return _resolve;
		
		// start resolving
		is_resolving = true;
			
		assert(td);
		auto one_step = td.tp;
		assert(one_step);
		// resolve
		if (one_step.kind == TPKind.typedef)
			_resolve = (cast(TypedefType) one_step).resolve();
		else
			_resolve = one_step;
		assert(_resolve);
		
		// end resolving
		is_resolving = false;
		
		return _resolve;
	}
	private Type _resolve;
	private bool is_resolving = false;  /// Cycle detection
	
	
	private TPSIZE _size;	 // remember size
	override TPSIZE size() @property {
		// for now
		assert(td);
		
		if (sizeok == Sizeok.done) return _size;
		// circular reference detected
		if (sizeok == Sizeok.inprocess) {
			message.error(sym.loc, "Circular reference was detected: ", sym.recoverString());
			this.kind = TPKind.error;
			this.sizeok = Sizeok.done;
			return _size = TPSIZEInvalid;
		}
		
		// start calculating
		sizeok = Sizeok.inprocess;
		_size = td.tp.size();
		// done
		sizeok = Sizeok.done;
		return _size;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

final class StructType : SymbolType {
	import struct_;
	StructDeclaration sd;
	
	this (Symbol sym) {
		super(TPKind.struct_, sym);
	}
	
	override TPSIZE size() @property {
		assert(sd);
		return sd.structSize;
	}
	
	override void accept(Vis v) {
		v.visit(this);
	}
}

/+
final class ClassType : Type {
	ClassInfo ci;
	this (ClassInfo ci) {
		super(TP.class_);
		this.ci = ci;
	}
	
	override uint size() @property {
		return 8u;
	}
	
	override accept(Vis v) {
		v.visit(this);
	}
}
+/
