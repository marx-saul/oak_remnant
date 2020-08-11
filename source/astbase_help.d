/**
 * astbase_help.d
 * Helper functions for astbase.ASTNode.
 *
 * *recovering the source code from astbase.ASTNode
 * *propagating parsing errors.
 */
module astbase_help;

import token, lexer, astbase, parse_time_visitor;

/* ************** To String ************** */
final class ToStringVisitor : ParseTimeVisitor {
	string result;
	
	override void visit(ASTNode) { assert(0); }
	
	/* Module */
	override void visit(Module mod) {
		if (mod.modname.length > 0) {
			result ~= "module ";
			foreach (name; mod.modname) {
				result ~= name ~ ".";
			}
			result.length -= 1;
			result ~= ";\n";
		}
		foreach (decl; mod.decls) {
			if (decl) decl.accept(this);
			result ~= "\n";
		}
	}
	
	/* Expression */
	override void visit(Expression exp) { assert(0); }
	override void visit(BinaryExpression exp) {
		result ~= "(";
		if (exp.left)  exp. left.accept(this);
		if (exp.op == TokenKind.apply) result ~= " ";
		else result ~= " " ~ token_dictionary[exp.op] ~ " ";
		if (exp.right) exp.right.accept(this);
		result ~= ")";
	}
	override void visit(UnaryExpression exp) {
		result ~= token_dictionary[exp.op];
		result ~= "(";
		if (exp.exp) exp.exp.accept(this);
		result ~= ")";
	}
	override void visit(IndexingExpression exp) { assert(0); }
	override void visit(SlicingExpression exp)  { assert(0); }
	override void visit(AscribeExpression exp) {
		result ~= "(";
		if (exp.exp) exp.exp.accept(this);
		result ~= " as ";
		if (exp.type) exp.type.accept(this);
		result ~= ")";
	}
	override void visit(WhenElseExpression exp) {
		result ~= "(";
		result ~= "when ";
		if (exp.cond)     exp.cond.accept(this);
		result ~= ": ";
		if (exp.when_exp)   exp.when_exp.accept(this);
		result ~= " else ";
		if (exp.else_exp) exp.else_exp.accept(this);
		result ~= ")";
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
		if (exp.is_global) result ~= "_.";
		result ~= exp.name;
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
	override void visit(AssocArrayExpression exp) {
		result ~= "[";
		foreach (i; 0 .. exp.keys.length) {
			result ~= exp.keys[i];
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
	override void visit(BlockExpression) {
		result ~= "{BlockExpression}";
	}
	override void visit(MixinExpression exp) {
		if (exp.node) exp.node.accept(this);
	}

	/* Types */
	override void visit(Type type) { assert(0); }
	override void visit(FunctionType type) {
		result ~= "(";
		if (type.ran) type.ran.accept(this);
		result ~= " -> ";
		if (type.dom) type.dom.accept(this);
		result ~= ")";
	}
	override void visit(PointerType type) {
		result ~= "#(";
		if (type.type) type.type.accept(this);
		result ~= ")";
	}
	override void visit(BuiltInType type) {
		result ~= token_dictionary[type.kind];
	}
	override void visit(ArrayType type) {
		result ~= "[";
		if (type.elem) type.elem.accept(this);
		result ~= "]";
	}
	override void visit(AssocArrayType type) {
		result ~= "[";
		if (type.key)   type.  key.accept(this);
		result ~= " : ";
		if (type.value) type.value.accept(this);
		result ~= "]";
	}
	override void visit(TupleType type) {
		result ~= "(";
		foreach (t; type.ents) {
			if (t) t.accept(this);
			result ~= ", ";
		}
		result.length -= 2;
		result ~= ")";
	}
	override void visit(SymbolType type) {
		foreach (t; type.types) {
			if (t) t.accept(this);
			result ~= ".";
		}
		result.length -= 1;
	}
	override void visit(IdentifierType type) {
		if (type.is_global) result ~= "_.";
		result ~= type.name;
	}
	override void visit(TemplateInstanceType type) {
		if (type.node) type.node.accept(this);
	}
	override void visit(MixinType type) {
		if (type.node) type.node.accept(this);
	}
	
	/* Statement */
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
	
	/* Declaration */
	override void visit(LetDeclaration ld) {
		result ~= "let ";
		foreach (i; 0 .. ld.names.length) {
			auto name = ld.names[i], type = ld.types[i], init = ld.inits[i];
			result ~= name;
			if (type) {
				result ~= ": ";
				type.accept(this);
			}
			if (init) {
				result ~= " = ";
				init.accept(this);
			}
			result ~= ", ";
		}
		result.length -= 2;
		result ~= ";";
	}
	override void visit(FuncDeclaration fd) {
		result ~= "func " ~ fd.name;
		if (fd.ret_type) {
			result ~= ": ";
			fd.ret_type.accept(this);
		}
		result ~= " ";
		foreach (i; 0 .. fd.args.length) {
			auto arg = fd.args[i], type = fd.argtps[i];
			result ~= arg;
			if (type) {
				result ~= ": ";
				type.accept(this);
			}
			result ~= " ";
		}
		result ~= "\n";
		if (fd.body) fd.body.accept(this);
	}
	override void visit(AggregateDeclaration) { assert(0); }
	override void visit(StructDeclaration sd) {
		result ~= "struct " ~ sd.name ~ " {\n";
		foreach (decl; sd.mems) {
			if (decl) {
				decl.accept(this);
				result ~= "\n";
			}
		}
		result ~= "}";
	}
	override void visit(TypedefDeclaration td) {
		result ~= "typedef " ~ td.name ~ " = ";
		if (td.type) td.type.accept(this);
		result ~= ";";
	}
	
	/* TemplateInstance */
	override void visit(TemplateInstance ti) {
		result ~= "TemplateInstance";
	}
	/* Mixin */
	override void visit(Mixin m) {
		result ~= "Mixin";
	}
	/* Typeid */
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
