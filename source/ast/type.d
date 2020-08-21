module ast.type;

import message;
import token;
import ast.astnode;
import ast.symbol;
import visitor.visitor;
import semantic.semantic;
import std.algorithm: among;

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
	
	func,		// Type -> Type
	lazy_,	 	// unit -> Type which can be called without an argument, defined by func f;int32 { return 10; }
	ptr,		// # Type
	//ref_,		// ref Type
	array,		// [ Type ]
	aarray,		// [ Type : Type ]
	tuple,		// ( Type, Type, ... )
	
	unsolved,	// unsolved symbol type
	typedef,	// <A> for typedef A = B;
	//tempinst
	struct_,	// <S> for struct S {...}
	//union_,
	//class_,
}

TPKind toTPKind(TokenKind x) {
	with (TokenKind)
	switch (x) {
		case int32:				return TPKind.int32;
		case uint32:			return TPKind.uint32;
		case int64:				return TPKind.int64;
		case uint64:			return TPKind.uint64;
		case real32:			return TPKind.real32;
		case real64:			return TPKind.real64;
		case unit:				return TPKind.unit;
		case bool_:				return TPKind.bool_;
		case string_:			return TPKind.string_;
		case char_:				return TPKind.char_;
		default:
			assert(0, token_dictionary[x]);
	}
}
/+
alias TPSIZE = int;
enum TPSIZEInvalid = -1;

enum Sizeok {
	undefined,				/// size has not been calculated yet
	inprocess,				/// size is being calculated 
	done,					/// size has been calculated
}
+/
abstract class Type : ASTNode {
	TPKind kind;			/// Kind of the type.
	bool parenthesized;		/// is this type parenthesized
	Type resolved;			/// typedef type removed form. see also semantic/typedef.d
	
	/**
	 */
	this (TPKind kind) {
		this.kind = kind;
	}
	
	final inout const @nogc @property {
		inout(ErrorType)				isErrorType()			{ return kind == TPKind.error 		? cast(inout(typeof(return)))this : null; }
		inout(BuiltInType)				isBuiltInType()			{
			with (TPKind)
			return kind.among!(
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
			) ? cast(inout(typeof(return)))this : null;
		}
		inout(FuncType)					isFuncType()			{ return kind == TPKind.func 		? cast(inout(typeof(return)))this : null; }
		inout(LazyType)					isLazyType()			{ return kind == TPKind.lazy_ 		? cast(inout(typeof(return)))this : null; }
		inout(PtrType)					isPtrType()				{ return kind == TPKind.ptr 		? cast(inout(typeof(return)))this : null; }
		inout(ArrayType)				isArrayType()			{ return kind == TPKind.array 		? cast(inout(typeof(return)))this : null; }
		inout(AArrayType)				isAArrayType()			{ return kind == TPKind.aarray		? cast(inout(typeof(return)))this : null; }
		inout(TupleType)				isTupleType()			{ return kind == TPKind.tuple 		? cast(inout(typeof(return)))this : null; }
		inout(SymbolType)				isSymbolType()			{
			with (TPKind)
			return kind.among!(
				unsolved,
				typedef,
				struct_,
			) ? cast(inout(typeof(return)))this : null;
		}
		inout(TypedefType)				isTypedefType()			{ return kind == TPKind.typedef		? cast(inout(typeof(return)))this : null; } 
		inout(StructType)				isStructType()			{ return kind == TPKind.struct_		? cast(inout(typeof(return)))this : null; }
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ErrorType : Type {
	string error_msg;
	
	this (string error_msg="") {
		super(kind);
		this.error_msg = error_msg;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class BuiltInType : Type {
	this (TPKind kind) {
		super(kind);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class FuncType : Type {
	Type ran;
	Type dom;
	
	this (Type ran, Type dom) {
		super(TPKind.func);
		this.ran = ran, this.dom = dom;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class LazyType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.lazy_);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class PtrType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.ptr);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class ArrayType : Type {
	Type tp;
	
	this (Type tp) {
		super(TPKind.array);
		this.tp = tp;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class AArrayType : Type {
	Type key;
	Type value;
	
	this (Type key, Type value) {
		super(TPKind.aarray);
		this.key = key, this.value = value;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class TupleType : Type {
	Type[] tps;
	
	this (Type[] tps) {
		super(TPKind.tuple);
		this.tps = tps;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

class SymbolType : Type {
	Identifier[] ids;			/// identifiers `foo.bar.baz` <-> ["foo", "bar", "baz"]
	
	Symbol _sym;					/// corresponding symbol declaration
	import semantic.scope_;
	Scope semsc;				/// the scope this type belong to
	
	this (TPKind kind, Identifier[] ids) {
		super(kind);
		this.ids = ids;
	}
	
	this (TPKind kind, Symbol _sym) {
		super(kind);
		this._sym = _sym;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

/// An identifier type defined by typedef
final class TypedefType : SymbolType {
	import ast.declaration;
	inout(TypedefDeclaration) sym() @nogc inout const @property {
		return cast(inout) sym.isTypedefDeclaration;
	}
	
	this (Identifier[] ids, Symbol _sym) {
		super(TPKind.typedef, ids);
		this._sym = _sym;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class StructType : SymbolType {
	import ast.struct_;
	inout(StructDeclaration) sym() @nogc inout const @property {
		return cast(inout) _sym.isStructDeclaration;
	}
	
	this (Identifier[] ids, Symbol _sym) {
		super(TPKind.typedef, ids);
		this._sym = _sym;
	}
	
	override void accept(Visitor v) {
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
