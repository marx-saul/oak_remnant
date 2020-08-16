/**
 * ast_tostring.d
 * Helper functions for astbase.ASTNode.
 *
 * *recovering the source code from astbase.ASTNode
 * *propagating parsing errors.
 */
module ast.ast_tostring;

import token, lexer, ast.ast, visitor.visitor;

/* ************** To String ************** */
final class ToStringVisitor : Visitor {
	string result;		/// the result is stored here
	//private depth;		/// depth of { }
	
	/* astnode.d */
	override void visit(ASTNode) { assert(0); }
	
	/* aggregate.d */
	override void visit(AggregateDeclaration agd) {
		with (SYMKind)
		switch (agd.kind) {
			case struct_:			result ~= "struct ";			break;
			case union_:			result ~= "union ";				break;
			case class_:			result ~= "class ";				break;
			case interface_:		result ~= "interface ";			break;
			default: assert(0);
		}
		result ~= agd.id.name ~ " {\n";
		foreach (member; agd.members) {
			if (member) member.accept(this);
			result ~= "\n";
		}
		result ~= "}";
	}

	/* module_.d */
	override void visit(Module mod) {
		if (mod.names.length > 0) {
			result ~= "module ";
			foreach (name; mod.names) {
				result ~= name ~ ".";
			}
			result.length -= 1;
			result ~= ";\n";
		}
		foreach (member; mod.members) {
			if (member) member.accept(this);
			result ~= "\n";
		}
	}
	override void visit(Package) { assert(0); }

	/* declaration.d */
	override void visit(FuncArgument arg) {
		result ~= arg.id.name;
		if (arg.tp) {
			result ~= ":";
			arg.tp.accept(this);
		}
	}
	override void visit(FuncDeclaration fd) {
		result ~= "func ";
		result ~= fd.id.name ~ " ";
		if (fd.args)
			foreach (arg; fd.args) {
				if (arg) arg.accept(this);
				result ~= " ";
			}
		if (fd.body) fd.body.accept(this);
	}
	override void visit(LetDeclaration ld) {
		result ~= "let ";
		for (auto node = ld; node; node = node.next) {
			assert(node !is node.next);
			result ~= node.id.name;
			if (node.tp) {
				result ~= ":";
				node.tp.accept(this);
			}
			if (node.exp) {
				result ~= " = ";
				node.exp.accept(this);
			}
			result ~= ", ";
		}
		result.length -= 2;
		result ~= ";";
	}
	override void visit(TypedefDeclaration td) {
		result ~= "typedef " ~ td.id.name;
		result ~= " = ";
		if (td.tp) td.tp.accept(this);
	}
	
	/* expression.d */
	override void visit(Expression exp) { assert(0); }
	override void visit(BinaryExpression exp) {
		if (exp.parenthesized) result ~= "(";
		scope(exit) if (exp.parenthesized) result ~= ")";
		if (exp.left)  exp. left.accept(this);
		if (exp.op == TokenKind.apply) result ~= " ";
		else result ~= " " ~ token_dictionary[exp.op] ~ " ";
		if (exp.right) exp.right.accept(this);
	}
	override void visit(UnaryExpression exp) {
		if (exp.parenthesized) result ~= "(";
		scope(exit) if (exp.parenthesized) result ~= ")";
		result ~= token_dictionary[exp.op];
		if (exp.exp) exp.exp.accept(this);
	}
	override void visit(IndexingExpression exp) { assert(0); }
	override void visit(SlicingExpression exp)  { assert(0); }
	override void visit(AscribeExpression exp) {
		if (exp.parenthesized) result ~= "(";
		scope(exit) if (exp.parenthesized) result ~= ")";
		if (exp.exp) exp.exp.accept(this);
		result ~= " as ";
		if (exp.tp) exp.tp.accept(this);
	}
	override void visit(WhenElseExpression exp) {
		if (exp.parenthesized) result ~= "(";
		scope(exit) if (exp.parenthesized) result ~= ")";
		result ~= "when ";
		if (exp.cond)     exp.cond.accept(this);
		result ~= ": ";
		if (exp.when_exp)   exp.when_exp.accept(this);
		result ~= " else ";
		if (exp.else_exp) exp.else_exp.accept(this);
	}
	override void visit(IntegerExpression exp) {
		result ~= exp.str;
	}
	override void visit(RealNumberExpression exp) {
		result ~= exp.str;
	}
	override void visit(StringExpression exp) {
		result ~= "`" ~ exp.str ~ "`";
	}
	override void visit(IdentifierExpression exp) {
		if (exp.id.is_global) result ~= "_.";
		result ~= exp.id.name;
	}
	override void visit(AnyExpression) {
		result ~= "_";
	}
	override void visit(FalseExpression) {
		result ~= "false";
	}
	override void visit(TrueExpression) {
		result ~= "true";
	}
	override void visit(NullExpression) {
		result ~= "null";
	}
	override void visit(ThisExpression) {
		result ~= "this";
	}
	override void visit(SuperExpression) {
		result ~= "super";
	}
	override void visit(DollarExpression) {
		result ~= "$";
	}
	override void visit(UnitExpression) {
		result ~= "()";
	}
	override void visit(TupleExpression exp) {
		result ~= "(";
		foreach (e; exp.ents) {
			if (e) e.accept(this);
			result ~= ", ";
		}
		result = result[0 .. $-2];
		result ~= ")";
	}
	override void visit(NewExpression exp) {
		result ~= "new ";
		if (exp.type) exp.type.accept(this);
	}
	override void visit(ArrayExpression exp) {
		result ~= "[";
		foreach (e; exp.elems) {
			if (e) e.accept(this);
			result ~= ", ";
		}
		result = result[0 .. $ > 2 ? $-2 : $];
		result ~= "]";
	}
	override void visit(AArrayExpression exp) {
		result ~= "[";
		foreach (i; 0 .. exp.keys.length) {
			if (exp.keys[i]) exp.values[i].accept(this);
			result ~= ": ";
			if (exp.values[i]) exp.values[i].accept(this);
			result ~= ", ";
		}
		result = result[0 .. $ > 2 ? $-2 : $];
		result ~= "]";
	}
	override void visit(BuiltInTypePropertyExpression exp) {
		result ~= token_dictionary[exp.type];
		result ~= ".";
		result ~= exp.str;
	}
	override void visit(TemplateInstanceExpression exp) {
		if (exp.node) exp.node.accept(this);
	}
	override void visit(TypeidExpression exp) {
		if (exp.node) exp.node.accept(this);
	}
	override void visit(MixinExpression exp) {
		if (exp.node) exp.node.accept(this);
	}

	/* mixin_.d */
	override void visit(Mixin m) {
		result ~= "Mixin";
	}

	/* statement.d */
	override void visit(Statement) { assert(0); }
	override void visit(DeclarationStatement ds) {
		if (ds.sym) ds.sym.accept(this);
	}
	override void visit(ExpressionStatement st) {
		if (st.exp) st.exp.accept(this);
		result ~= ";";
	}
	override void visit(IfElseStatement st) {
		result ~= "if ";
		if (st.cond) st.cond.accept(this);
		result ~= ":\n";
		if (st.if_body) st.if_body.accept(this);
		result ~= "\nelse\n";
		if (st.else_body) st.else_body.accept(this);
	}
	override void visit(WhileStatement st) {
		result ~= "while ";
		if (st.cond) st.cond.accept(this);
		result ~= ":\n";
		if (st.body) st.body.accept(this);
	}
	override void visit(DoWhileStatement st) {
		result ~= "do ";
		if (st.body) st.body.accept(this);
		result ~= " while ";
		if (st.cond) st.cond.accept(this);
	}
	override void visit(ForStatement st) {
		result ~= "for ";
		if (st.init) st.init.accept(this);
		result ~= " ";
		if (st.test) st.test.accept(this);
		result ~= " ; ";
		if (st.exec) st.exec.accept(this);
		result ~= ":\n";
		if (st.body) st.body.accept(this);
	}
	override void visit(ForeachStatement st) {
		result ~= "foreach ";
		foreach (i; 0 .. st.vars.length) {
			auto var = st.vars[i];
			auto type = st.types[i];
			result ~= var;
			if (type) {
				result ~= ":";
				type.accept(this);
			}
			result ~= ", ";
		}
		result.length -= 2;
		result ~= "; ";
		if (st.exp) st.exp.accept(this);
		if (st.exp2) {
			result ~= "..";
			st.exp2.accept(this);
		}
		result ~= ":\n";
		if (st.body) st.body.accept(this);
	}
	override void visit(ForeachReverseStatement st) {
		result ~= "foreach_reverse ";
		foreach (i; 0 .. st.vars.length) {
			auto var = st.vars[i];
			auto type = st.types[i];
			result ~= var;
			if (type) {
				result ~= ":";
				type.accept(this);
			}
			result ~= ", ";
		}
		result.length -= 2;
		result ~= "; ";
		if (st.exp) st.exp.accept(this);
		if (st.exp2) {
			result ~= "..";
			st.exp2.accept(this);
		}
		result ~= ":\n";
		if (st.body) st.body.accept(this);
	}
	override void visit(BreakStatement st) {
		result ~= "break";
		if (st.label.length > 0) result ~= " " ~ st.label;
		result ~= ";";
	}
	override void visit(ContinueStatement st) {
		result ~= "continue";
		if (st.label.length > 0) result ~= " " ~ st.label;
		result ~= ";";
	}
	override void visit(GotoStatement st) {
		result ~= "goto " ~ st.label ~ ";";
	}
	override void visit(ReturnStatement st) {
		result ~= "return";
		if (st.exp) {
			result ~= " ";
			st.exp.accept(this);
		}
		result ~= ";";
	}
	override void visit(LabelStatement st) {
		result ~= st.label ~ ":";
	}
	override void visit(BlockStatement st) {
		static uint depth;
		import std : repeat, to, array;
		result ~= '\t'.repeat(depth).array.to!string ~ "{\n";
		++depth;
		foreach (s; st.stmts) {
			if (s) {
				result ~= '\t'.repeat(depth).array.to!string;
				s.accept(this);
				result ~= '\n';
			}
		}
		--depth;
		result ~= '\t'.repeat(depth).array.to!string ~ "}";
	}
	override void visit(MixinStatement st) { result ~= "MixinStatement"; }
	
	/* struct_ */
	override void visit(StructDeclaration sd) {
		this.visit(cast(AggregateDeclaration) sd);
	}

	/* symbol.d */
	override void visit(Symbol sym) {
		assert(0);
	}
	override void visit(ScopeSymbol sym) {
		assert(0);
	}

	/* template_.d */
	override void visit(TemplateInstance ti) {
		result ~= "TemplateInstance";
	}
	override void visit(TemplateDeclaration td) {
		assert(0);
	}

	/* type.d */
	override void visit(Type type) { assert(0); }
	override void visit(ErrorType type) { assert(0); }
	override void visit(FuncType type) {
		if (type.parenthesized) result ~= "(";
		scope(exit) if (type.parenthesized) result ~= ")";
		if (type.ran) type.ran.accept(this);
		result ~= " -> ";
		if (type.dom) type.dom.accept(this);
	}
	override void visit(LazyType type) {
		if (type.parenthesized) result ~= "(";
		scope(exit) if (type.parenthesized) result ~= ")";
		result ~= "lazy";
		if (type.tp) type.tp.accept(this);
	}
	override void visit(PtrType type) {
		if (type.parenthesized) result ~= "(";
		scope(exit) if (type.parenthesized) result ~= ")";
		result ~= "#";
		if (type.tp) type.tp.accept(this);
		result ~= "";
	}
	override void visit(BuiltInType type) {
		result ~= token_dictionary[type.kind];
	}
	override void visit(ArrayType type) {
		if (type.parenthesized) result ~= "(";
		scope(exit) if (type.parenthesized) result ~= ")";
		result ~= "[";
		if (type.tp) type.tp.accept(this);
		result ~= "]";
	}
	override void visit(AArrayType type) {
		if (type.parenthesized) result ~= "(";
		scope(exit) if (type.parenthesized) result ~= ")";
		result ~= "[";
		if (type.key)   type.  key.accept(this);
		result ~= " : ";
		if (type.value) type.value.accept(this);
		result ~= "]";
	}
	override void visit(TupleType type) {
		result ~= "(";
		foreach (t; type.tps) {
			if (t) t.accept(this);
			result ~= ", ";
		}
		result.length -= 2;
		result ~= ")";
	}
	override void visit(SymbolType type) {
		if (type.ids.length == 0) return;
		if (type.ids[0].is_global) result ~= "_.";
		result ~= type.ids[0].name;
		foreach (id; type.ids[1..$]) {
			result ~= ".";
			result ~= id.name;
		}
	}
	override void visit(StructType type) {
		this.visit(cast(SymbolType) type);
	}
	override void visit(TypedefType type) {
		this.visit(cast(SymbolType) type);
	}
	/*override void visit(TemplateInstanceType type) {
		if (type.node) type.node.accept(this);
	}*/
	/*override void visit(MixinType type) {
		if (type.node) type.node.accept(this);
	}*/
	
	/* typeid_.d */
	override void visit(Typeid t) {
		result ~= "Typeid";
	}
}

string to_string(ASTNode node) {
	if (node is null) return "";
	auto vis = new ToStringVisitor;
	node.accept(vis);
	return vis.result;
}
