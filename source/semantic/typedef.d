/**
 * semantic/typedef.d
 * Get the type whose every subsequent types do not have a symbol type defined by typedef T = S.
 * e.g.
 *    struct MyStr{}
 *    typedef T = MyStr;
 *    typedef S = T -> int32;
 *    typedef R = ([T], S, [S : unit]);
 *    `R[]`.rawtp() = `([MyStr], MyStr -> int32, [MyStr -> int32 : unit])`
 */
module semantic.typedef;

import message;
import ast.ast;
import semantic.scope_;
import semantic.semantic;
import visitor.general;


Type resolveTypedef(Type tp, Scope sc) {
	if (!tp) return null;
	if (!tp.resolved) {
		scope rtv = new ResolveTypedefVisitor(sc);
		tp.accept(rtv);
	}
	return tp.resolved;
} 

final class ResolveTypedefVisitor : GeneralVisitor {
	alias visit = GeneralVisitor.visit;
	
	Scope sc;
	
	this (Scope sc) {
		this.sc = sc;
	}
	
	override void visit(ASTNode x) {
		assert(0, typeid(x).toString());
	}
	
	override void visit(Type tp) {
		assert(0, typeid(tp).toString());
	}
	
    override void visit(ErrorType tp) {
		tp.resolved = tp;
	}
    override void visit(BuiltInType tp) {
		tp.resolved = tp;
	}
    override void visit(FuncType tp) {
		if (tp.ran) tp.ran.accept(this);
		if (tp.dom) tp.dom.accept(this);
		tp.resolved = new FuncType(tp.ran ? tp.ran.resolved : null, tp.dom ? tp.dom.resolved : null);
	}
    override void visit(LazyType tp) {
		if (tp.tp) tp.tp.accept(this);
		tp.resolved = new LazyType(tp.tp ? tp.tp.resolved : null);
	}
    override void visit(PtrType tp) {
		if (tp.tp) tp.tp.accept(this);
		tp.resolved = new PtrType(tp.tp ? tp.tp.resolved : null);
	}
    override void visit(ArrayType tp) {
		if (tp.tp) tp.tp.accept(this);
		tp.resolved = new ArrayType(tp.tp ? tp.tp.resolved : null);
	}
    override void visit(AArrayType tp) {
		if (tp.key) tp.key.accept(this);
		if (tp.value) tp.value.accept(this);
		tp.resolved = new AArrayType(tp.key ? tp.key.resolved : null, tp.value ? tp.value.resolved : null);
	}
    override void visit(TupleType tp) {
		Type[] resolved;
	}
	override void visit(SymbolType) {}
    override void visit(StructType) {}
    override void visit(TypedefType) {}
}