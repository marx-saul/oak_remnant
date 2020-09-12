module ast.type;

import message;
import token;
import ast.astnode;
import ast.symbol;
import ast.template_;
import visitor.visitor;
import semantic.semantic;
import std.algorithm: among;

enum TPKind {
	error,	/// error type
	
	int32,		/// int32 : BuiltInType
	uint32,		/// uint32 : BuiltInType
	int64,		/// int64 : BuiltInType
	uint64,		/// uint64 : BuiltInType
	real32,		/// real32 : BuiltInType
	real64,		/// real64 : BuiltInType
	unit,		/// unit : BuiltInType
	bool_,		/// bool : BuiltInType
	string_,	/// string : BuiltInType
	char_,		/// char : BuiltInType
	
	func,		/// Type -> Type : FuncType
	lazy_,	 	/// unit -> Type which can be called without an argument, defined by func f;int32 { return 10; } : LazyType
	ptr,		/// # Type : PtrType
	//ref_,		/// ref Type : RefType
	array,		/// [ Type ] : ArrayType
	aarray,		/// [ Type : Type ] : AArrayType
	tuple,		/// ( Type, Type, ... ) : TupleType
	
	identifier,	/// IdentifierType
	instance,	/// InstanceType
	
	unsolved,	/// SymbolType
	
	typedef,	/// <A> for typedef A = B; : TypedefType
	struct_,	/// <S> for struct S {...} : StructType
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
	bool is_resolved = false;	/// is this resolved
	PASS ressem = PASS.init;	/// see semantic.type
	/**
	 */
	this (TPKind kind) {
		this.kind = kind;
	}
	
	final inout const @nogc @property {
		//inout(ErrorType)				isErrorType()			{ return kind == TPKind.error 		? cast(inout(typeof(return)))this : null; }
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
				identifier,
				instance,
			) != 0 ? cast(inout(typeof(return)))this : null;
		}
		inout(IdentifierType)			isIdentifierType()		{ return kind == TPKind.identifier	? cast(inout(typeof(return)))this : null; }
		inout(InstanceType)				isInstanceType()		{ return kind == TPKind.instance	? cast(inout(typeof(return)))this : null; }
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

abstract class SymbolType : Type {
	SymbolType next;			/// linked list of identifier type and instance type
	Symbol sym;						/// corresponding symbol declaration before alias, typedef resolution
	
	this () {
		super(TPKind.unsolved);
	}
	private this (TPKind kind) {
		super(kind);
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class IdentifierType : SymbolType {
	Identifier id;					/// identifier
	
	this (Identifier id) {
		super(TPKind.identifier);
		this.id = id;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class InstanceType : SymbolType {
	TemplateInstance instance;		/// template instance
	
	this (TemplateInstance instance) {
		super(TPKind.instance);
		this.instance = instance;
	}
	
	override void accept(Visitor v) {
		v.visit(this);
	}
}

final class StructType : Type {
	import ast.struct_;
	StructDeclaration sym;
	
	this (StructDeclaration sym) {
		super(TPKind.struct_);
		this.sym = sym;
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
