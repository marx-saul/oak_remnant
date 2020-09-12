/**
 * semantic/type.d
 * Get the type whose every subsequent types do not have a symbol type defined by typedef T = S.
 * e.g.
 *    struct MyStr{}
 *    typedef T = MyStr;
 *    typedef S = T -> int32;
 *    typedef R = ([T], S, [S : unit]);
 *    `R[]`.rawtp() = `([MyStr], MyStr -> int32, [MyStr -> int32 : unit])`
 */
module semantic.type;

import message;
import ast.ast;
import semantic.scope_;
import semantic.semantic;
import visitor.general;


Type resolveType(Type tp, Scope sc) {
	if (!tp) return null;
	if (!tp.resolved) {
		scope rtv = new ResolveTypeVisitor(sc);
		tp.accept(rtv);
	}
	return tp.resolved;
} 

final class ResolveTypeVisitor : GeneralVisitor {
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
		tp.is_resolved = true;
	}
    override void visit(BuiltInType tp) {
		tp.resolved = tp;
		tp.is_resolved = true;
	}
    override void visit(FuncType tp) {
		if (!tp.ran) tp.ran = new ErrorType();
		if (!tp.dom) tp.dom = new ErrorType();
		tp.ran.accept(this);
		tp.dom.accept(this);
		tp.resolved = new FuncType(tp.ran.resolved, tp.dom.resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
    override void visit(LazyType tp) {
		if (!tp.tp) tp.tp = new ErrorType();
		tp.tp.accept(this);
		tp.resolved = new LazyType(tp.tp.resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
    override void visit(PtrType tp) {
		if (!tp.tp) tp.tp = new ErrorType();
		tp.tp.accept(this);
		tp.resolved = new PtrType(tp.tp.resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
    override void visit(ArrayType tp) {
		if (!tp.tp) tp.tp = new ErrorType();
		tp.tp.accept(this);
		tp.resolved = new ArrayType(tp.tp.resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
    override void visit(AArrayType tp) {
		if (!tp.key) tp.key = new ErrorType();
		if (!tp.value) tp.value = new ErrorType();
		tp.key.accept(this);
		tp.value.accept(this);
		tp.resolved = new AArrayType(tp.key.resolved, tp.value.resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
    override void visit(TupleType tp) {
		Type[] resolved;
		foreach (eachtp; tp.tps) {
			if (!eachtp) eachtp = new ErrorType();
			eachtp.accept(this);
			resolved ~= eachtp.resolved;
		}
		tp.resolved = new TupleType(resolved);
		tp.resolved.parenthesized = tp.parenthesized;
		tp.resolved.is_resolved = true;
	}
	override void visit(SymbolType tp) {
		/+// already done
		if (tp.resloved) return;
		
		// start resolving
		assert(tp.syms.length > 0);
		assert(tp.syms[0]);
		auto result = sc.search(tp.syms[0].id.name);
		foreach (sym; tp.syms[1..$]) {
			assert(sym);
			if (!result) break;
			// do not look inside function declarations
			if (result.isFuncDeclaration) {
				result = null;
				break;
			}
			// one step inside
			result = result.hasMember(sym.id.name);
		}
		// invalid symbol
		if (!result) {
			message.error(tp.syms[0].id.loc, "Symbol \x1b[46m" ~ syms[0].id.name ~ "\x1b[0m was not found.");
			
		}
		
		_sym = result;
		+/
	}
    override void visit(StructType) {}
}