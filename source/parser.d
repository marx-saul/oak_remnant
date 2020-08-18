/**
 * parser.d
 * Defines the parser class, converting the source file to ASTBase.
 */
module parser;

import message;
import token, lexer;
import ast.ast;
import std.algorithm;
import std.conv: to;

final class Parser(Range) : Lexer!Range {
	/// Create parser.
	this (Range range, bool a2u=true) {
		super(range, a2u);
	}

	/// Check if the current token is the designated one, and throw it away.
	/// If not, throw away all the token until it reaches the expected token or EOF.
	private void check(TokenKind kind) {
		auto loc = token.loc;
		if (token.kind == kind) {
			nextToken();
			return;
		}
		// error
		auto err_kind = token.kind;
		do {
			nextToken();
		} while(token.kind != kind && token.kind != TokenKind.end_of_file);
		import std.conv: to;
		error(loc, token_dictionary[kind], " was expected, not ", token_dictionary[err_kind]);
	}
	
	private bool _is_error;
	/// Whether there was a syntax error
	public  bool is_error() @property {
		return _is_error;
	}
	private static immutable error_max = 10;
	private void error(Location loc, string[] msgs...) {
		message.error(loc, msgs);
		_is_error = true;
	}
	
	/* ******************************************************************************************************** */
	/// parsing function
	public alias parse = parseModule;
	
	/* ************************ Module ************************ */
	//	Module:
	//		ModuleDeclaration_opt ModuleBodies
	//	ModuleDeclaration:
	//		module ModuleName ;
	//	ModuleName:
	//		identifier
	//		identifier . ModuleName
	//	ModuleBodies:
	//		ModuleBody ModuleBodies
	//		ModuleBody
	//	ModuleBody:
	//		Declaration
	Module parseModule() {
		auto loc = token.loc;
		
		string[] modname;
		if (token.kind == TokenKind.module_) {
			nextToken();	// get rid of module
			modname = parseModuleName();
			if (modname.length == 0) {
				this.error(token.loc, "An identifier was expected after \x1b[46mmodule\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
			}
			check(TokenKind.semicolon);
		}
		
		Symbol[] mems;
		while (isFirstOfDeclaration) {
			mems ~= parseDeclaration();
		}
		
		check(TokenKind.end_of_file);
		
		return new Module(loc, modname, mems);
	}
	
	string[] parseModuleName() {
		string[] result;
		
		if (token.kind == TokenKind.identifier) {
			result ~= token.str;
			nextToken();
		}
		else {
			return result;
		}
		
		while (token.kind == TokenKind.dot) {
			nextToken();	// get rid of .
			if (token.kind == TokenKind.identifier) {
				result ~= token.str;
				nextToken();	// get rid of identifier
			}
			else {
				this.error(token.loc, "An identifier was expected after \x1b[46m.\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
			}
		}
		return result;
	}
	
	/* ************************ Expression ************************ */
	//	Expression:
	//		IfElseExpression
	Expression parseExpression() {
		return parseWhenElseExpression();
	}
	//	WhenElseExpression:
	//		AssignExpression
	//		when Expression : Expression else IfElseExpression
	Expression parseWhenElseExpression() {
		if (token.kind == TokenKind.when) {
			auto loc = token.loc;
			nextToken();	// get rid of if
			auto cond = parseExpression();
			check(TokenKind.colon);
			auto when_exp = parseExpression();
			check(TokenKind.else_);
			auto else_exp = parseWhenElseExpression();
			return new WhenElseExpression(loc, cond, when_exp, else_exp);
		}
		else return parseAssignExpression();
	}
	
	//	AssignExpression:
	//		PipelineExpression
	//		PipelineExpression = AssignExpression
	Expression parseAssignExpression() {
		auto e0 = parsePipelineExpression();
		with (TokenKind)
		if (token.kind.among!(ass, add_ass, sub_ass, cat_ass, mul_ass, div_ass, mod_ass, pow_ass, and_ass, xor_ass, or_ass)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of = += -= ++= /= %= ^^= &= ^= |=
			auto e1 = parseAssignExpression();
			e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		return e0;
	}
	//	PipelineExpression:
	//		AppExpression
	//		PipelineExpression => AppExpression
	Expression parsePipelineExpression() {
		auto e0 = parseAppExpression();
		while (token.kind == TokenKind.pipeline) {
			auto loc = token.loc;
			nextToken();	// get rid of |>
			auto e1 = parseAppExpression();
			e0 = new BinaryExpression(loc, TokenKind.pipeline, e0, e1);
		}
		return e0;
	}
	//	AppExpression:
	//		OrExpression
	//		OrExpression app AppExpression
	Expression parseAppExpression() {
		auto e0 = parseOrExpression();
		if (token.kind == TokenKind.app) {
			auto loc = token.loc;
			nextToken();	// get rid of app
			auto e1 = parseAppExpression();
			e0 = new BinaryExpression(loc, TokenKind.app, e0, e1);
		}
		return e0;
	}
	//	OrExpression:
	//		XorExpression
	//		OrExpression || XorExpression
	Expression parseOrExpression() {
		auto e0 = parseXorExpression();
		while (token.kind == TokenKind.or) {
			auto loc = token.loc;
			nextToken();	// get rid of ||
			auto e1 = parseXorExpression();
			e0 = new BinaryExpression(loc, TokenKind.or, e0, e1);
		}
		return e0;
	}
	//	XorExpression:
	//		AndExpression
	//		XorExpression ^^ AndExpression
	Expression parseXorExpression() {
		auto e0 = parseAndExpression();
		while (token.kind == TokenKind.xor) {
			auto loc = token.loc;
			nextToken();	// get rid of ^^
			auto e1 = parseAndExpression();
			e0 = new BinaryExpression(loc, TokenKind.xor, e0, e1);
		}
		return e0;
	}
	//	AndExpression:
	//		BitOrExpression
	//		AndExpression && BitOrExpression
	Expression parseAndExpression() {
		auto e0 = parseBitOrExpression();
		while (token.kind == TokenKind.and) {
			auto loc = token.loc;
			nextToken();	// get rid of |
			auto e1 = parseBitOrExpression();
			e0 = new BinaryExpression(loc, TokenKind.and, e0, e1);
		}
		return e0;
	}
	//	BitOrExpression:
	//		BitXorExpression
	//		BitOrExpression | BitXorExpression
	Expression parseBitOrExpression() {
		auto e0 = parseBitXorExpression();
		while (token.kind == TokenKind.bit_or) {
			auto loc = token.loc;
			nextToken();	// get rid of |
			auto e1 = parseBitXorExpression();
			e0 = new BinaryExpression(loc, TokenKind.bit_or, e0, e1);
		}
		return e0;
	}
	//	BitXorExpression:
	//		BitAndExpression
	//		BitXorExpression ^ BitAndExpression
	Expression parseBitXorExpression() {
		auto e0 = parseBitAndExpression();
		while (token.kind == TokenKind.bit_xor) {
			auto loc = token.loc;
			nextToken();	// get rid of ^
			auto e1 = parseBitAndExpression();
			e0 = new BinaryExpression(loc, TokenKind.bit_xor, e0, e1);
		}
		return e0;
	}
	//	BitAndExpression:
	//		CmpExpression
	//		BitAndExpression & CmpExpression
	Expression parseBitAndExpression() {
		auto e0 = parseCmpExpression();
		while (token.kind == TokenKind.bit_and) {
			auto loc = token.loc;
			nextToken();	// get rid of &
			auto e1 = parseCmpExpression();
			e0 = new BinaryExpression(loc, TokenKind.bit_and, e0, e1);
		}
		return e0;
	}
	//	CmpExpression:
	//		ShiftExpression
	//		ShiftExpression  <  ShiftExpression
	//		ShiftExpression  <= ShiftExpression
	//		ShiftExpression  >  ShiftExpression
	//		ShiftExpression  >= ShiftExpression
	//		ShiftExpression  == ShiftExpression
	//		ShiftExpression  != ShiftExpression
	//		ShiftExpression  in ShiftExpression
	//		ShiftExpression !in ShiftExpression
	//		ShiftExpression  is ShiftExpression
	//		ShiftExpression !is ShiftExpression
	Expression parseCmpExpression() {
		auto e0 = parseShiftExpression();
		with (TokenKind)
		if (token.kind.among!(ls, leq, gt, geq, eq, neq, in_, nin, is_, nis)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of < <= > >= in !in is !is
			auto e1 = parseShiftExpression();
			e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		return e0;
	}
	//	ShiftExpression:
	//		ShiftExpression  << AddExpression
	//		ShiftExpression  >> AddExpression
	//		ShiftExpression >>> AddExpression
	Expression parseShiftExpression() {
		auto e0 = parseAddExpression();
		with (TokenKind)
		while (token.kind.among!(lshift, rshift, logical_shift)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of << >> >>>
			auto e1 = parseAddExpression();
			e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		return e0;
	}
	//	AddExpression:
	//		AddExpression  + MulExpression
	//		AddExpression  - MulExpression
	//		AddExpression ++ MulExpression
	Expression parseAddExpression() {
		auto e0 = parseMulExpression();
		with (TokenKind)
		while (token.kind.among!(add, sub, cat)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of + - ++
			auto e1 = parseMulExpression();
			e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		return e0;
	}
	//	MulExpression:
	//		MulExpression * PowExpression
	//		MulExpression / PowExpression
	//		MulExpression % PowExpression
	Expression parseMulExpression() {
		auto e0 = parsePowExpression();
		with (TokenKind)
		while (token.kind.among!(mul, div, mod)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of * / %
			auto e1 = parsePowExpression();
			e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		return e0;
	}
	//	PowExpression:
	//		ApplyExpression
	//		ApplyExpression ** PowExpression
	Expression parsePowExpression() {
		auto e0 = parseApplyExpression();
		if (token.kind == TokenKind.pow) {
			auto loc = token.loc;
			nextToken();	// get rid of pow
			auto e1 = parsePowExpression();
			e0 = new BinaryExpression(loc, TokenKind.pow, e0, e1);
		}
		return e0;
	}
	//	ApplyExpression:
	//		UnaryExpression
	//		ApplyExpression UnaryExpression
	Expression parseApplyExpression() {
		auto e0 = parseUnaryExpression();
		while (isFirstOfExpression) {
			auto e1 = parseUnaryExpression();
			e0 = new BinaryExpression(Location.init, TokenKind.apply, e0, e1);
		}
		return e0;
	}
	//	UnaryExpression:
	//		IndexingExpression
	//		-- UnaryExpression
	//		 ~ UnaryExpression
	//		 # UnaryExpression
	//		 ! UnaryExpression
	Expression parseUnaryExpression() {
		with (TokenKind)
		if (token.kind.among!(minus, not, ref_of, deref)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of -- ~ # !
			return new UnaryExpression(loc, kind, parseUnaryExpression());
		}
		else return parseIndexingExpression();
	}
	//	IndexingExpression:
	//		CompositionExpression
	//		IndexingExpression ![ Expressions ]
	//		IndexingExpression ![ Slicings ]
	Expression parseIndexingExpression() {
		auto e0 = parseCompositionExpression();
		/+
		with (TokenKind)
		while (token.kind.among!(mul, div, mod)) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of * / %
			auto e1 = parsePowExpression();
			auto e0 = new BinaryExpression(loc, kind, e0, e1);
		}
		+/
		return e0;
	}
	//	CompositionExpression:
	//		AscribeExpression
	//		CompositionExpression @ AscribeExpression
	Expression parseCompositionExpression() {
		auto e0 = parseAscribeExpression();
		while (token.kind == TokenKind.composition) {
			auto kind = token.kind;
			auto loc = token.loc;
			nextToken();	// get rid of @
			auto e1 = parseAscribeExpression();
			e0 = new BinaryExpression(loc, TokenKind.composition, e0, e1);
		}
		return e0;
	}
	//	AscribeExpression:
	//		DotExpression
	//		AscribeExpressino as Type
	Expression parseAscribeExpression() {
		auto e0 = parseDotExpression();
		while (token.kind == TokenKind.as) {
			auto loc = token.loc;
			nextToken();	// get rid of as
			auto t1 = parseType();
			e0 = new AscribeExpression(loc, e0, t1);
		}
		return e0;
	}
	//	DotExpression:
	//		PrimaryExpression
	//		DotExpression . Identifier
	// //	DotExpression . TemplateInstance
	//		DotExpression . NewExpression
	Expression parseDotExpression() {
		auto e0 = parsePrimaryExpression();
		with (TokenKind)
		while (token.kind == dot) {
			auto loc = token.loc;
			nextToken();	// get rid of .
			
			// throw away invalid tokens until reaching one of identifier, new_, end_of_file
			if (!token.kind.among(identifier, new_)) {
				this.error(token.loc, "An identifier or \x1b[46mnew\x1b[0m expected after \x1b[46m.\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
				// skip
				do {
					nextToken();
				} while (!token.kind.among(identifier, new_, end_of_file));
				// reached EOF
				if (token.kind == end_of_file) {
					break;
				}
			}
			// DotExpression . TemplateInstance
			if (token.kind == identifier && lookahead(1).kind == temp_inst) {
				assert(0, "TemplateInstance has not been implemented.");
			}
			// DotExpression . Identifier
			else if (token.kind == identifier) {
				auto e1 = new IdentifierExpression(Identifier(token.str, loc));
				nextToken();	// get rid of identifier
				e0 = new BinaryExpression(loc, TokenKind.dot, e0, e1);
			}
			else if (token.kind == new_) {
				auto e1 = parseNewExpression();
				e0 = new BinaryExpression(loc, TokenKind.dot, e0, e1);
			}
		}
		return e0;
	}
	//	PrimaryExpression:
	//		integer
	//		real_number
	//		string_literal
	//		identifier
	//		_. identifier
	// //	TemplateInstance
	// //	_. TemplateInstance
	//		_
	//		false
	//		true
	//		null
	//		this
	//		super
	//		$
	//		NewExpression
	// 		LambdaExpression
	// //	StructLiteral
	//		TupleExpression
	//		ArrayLiteral
	//		AssocArrayLiteral
	//		BasicType . Identifier
	//		Typeof . Identifier
	// //	Typeid
	//		mixin ( Expression )
	Expression parsePrimaryExpression() {
		bool is_global = false;
		with (TokenKind)
		switch (token.kind) {
		case integer:
			auto e0 = new IntegerExpression(token.loc, token.str);
			nextToken();
			return e0;
			
		case real_number:
			auto e0 = new RealNumberExpression(token.loc, token.str);
			nextToken();
			return e0;
			
		case string_literal:
			auto e0 = new StringExpression(token.loc, token.str);
			nextToken();
			return e0;
		
		case global:
			nextToken();
			is_global = true;
			goto case;
		case identifier:
			// TemplateInstance
			if (lookahead(1).kind == temp_inst) {
				assert(0, "TemplateInstance has not been implemented.");
			}
			else {
				auto e0 = new IdentifierExpression(Identifier(token.str, token.loc));
				nextToken();
				e0.id.is_global = is_global;
				return e0;
			}
			
		case any:
			auto e0 = new AnyExpression(token.loc);
			nextToken();
			return e0;
		case false_:
			auto e0 = new FalseExpression(token.loc);
			nextToken();
			return e0;
		case true_:
			auto e0 = new TrueExpression(token.loc);
			nextToken();
			return e0;
		case null_:
			auto e0 = new NullExpression(token.loc);
			nextToken();
			return e0;
		case this_:
			auto e0 = new ThisExpression(token.loc);
			nextToken();
			return e0;
		case super_:
			auto e0 = new SuperExpression(token.loc);
			nextToken();
			return e0;
		case dollar:
			auto e0 = new DollarExpression(token.loc);
			nextToken();
			return e0;
			
		case new_:
			return parseNewExpression();
		
		case lambda:
			return parseLambdaExpression();
		//case struct_:
			
		case lparen:
			return parseTupleExpression();
			
		case lbracket:
			assert(0, "(Assoc)ArrayExpression has not been implemented.");
			//return parseArrayExpression();
		
		case ebrace:
			assert(0, "e{ ... } has not been implemented.");
			//return parseBlockExpression();
			
		case int32: case uint32: case int64: case uint64: case real32: case real64:
		case bool_: case unit:   case string_: case char_:
			auto loc = token.loc;
			auto basic_type = token.kind;
			nextToken();
			check(dot);
			if (token.kind == identifier) {
				auto str = token.str;
				nextToken();
				return new BuiltInTypePropertyExpression(loc, basic_type, str);
			}
			else {
				this.error(loc,
					"An identifier is expected after \x1b[46m", token_dictionary[basic_type], ".\x1b[0m , not \x1b[46m",
					token.str, "\x1b[0m");
				nextToken();
				auto e0 = new BuiltInTypePropertyExpression(loc, basic_type, "");
				return e0;
			}
			
		//case typeof_:
		/+case typeid_:
			auto loc = token.loc;
			nextToken();
			check(lparen);
			auto e1 = parseExpression();
			check(rparen);
			return new TypeidExpression(loc, e1);
		+/
		case mixin_:
			auto loc = token.loc;
			nextToken();
			check(lparen);
			auto e1 = parseExpression();
			check(rparen);
			return new MixinExpression(new Mixin(loc, e1));
		
		default:
			this.error(token.loc, "A primary expression expected, not \x1b[46m", token.str, "\x1b[0m.");
			nextToken();
			return null;
		}
	}
	private pure bool isFirstOfExpression(TokenKind x) @property {
		with (TokenKind)
		return x.among!(
				integer,
				real_number,
				string_literal,
				identifier,
				true_,
				false_,
				null_,
				this_,
				super_,
				any,
				dollar,
				when,
				// match,
				minus,
				not,
				ref_of,
				deref,
				lambda,
				new_,
				global,
				// parenthesis
				lparen,
				lbracket,
				//ebrace,
				// basic types
				int32,
				uint32,
				int64,
				uint64,
				real32,
				real64,
				bool_,
				unit,
				string_,
				char_,
			) != 0;
	}
	private bool isFirstOfExpression() @property {
		return isFirstOfExpression(token.kind);
	}
	//	NewExpression:
	//		new Type
	NewExpression parseNewExpression() {
		auto loc = token.loc;
		nextToken();	// get rid of new
		return new NewExpression(loc, null, null);
	}
	//	LambdaExpresison:
	//		\ (: Type)_opt FunctionArguments_opt = PrimaryExpression
	//		\ (: Type)_opt FunctionArguments_opt BlockExpression
	LambdaExpression parseLambdaExpression() {
		/+
		auto loc = token.loc;
		nextToken();	// get rid of \
		
		Type ret_type;
		if (token.kind == TokenKind.colon) {
			nextToken();	// get rid of :
			ret_type = parseType();
		}
		
		Location[] arglocs;
		string[] args;
		Type[] types;
		with (TokenKind)
		while (token.kind.among!(identifier, any)) {
			auto argloc = token.loc;
			string arg = token.str;
			Type type;
			nextToken();	// get rid of identifier
			if (token.kind == colon) {
				nextToken();	// get rid of :
				type = parseType();
			}
			if (arg == "_" && !type) {
				this.error(argloc, "A type expected after \x1b[46m_\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
			}
			else {
				arglocs ~= argloc;
				args ~= arg;
				types ~= type;
			}
		}
		
		Statement body;
		with (TokenKind)
		if (token.kind == lbrace) {
			body = parseBlockStatement();
		}
		else if (token.kind == ass) {
			auto assloc = token.loc;
			nextToken();
			auto exp = parseExpression();
			check(semicolon);
			body = new BlockStatement(assloc, [new ReturnStatement(assloc, exp)]);
		}
		
		auto result = new LambdaExpression(loc, ret_type, arglocs, args, types, body);
		return result;
		+/
		assert(0, "lambda expression has not been implemented yet");
	}
	//	TupleExpression:
	//		( )
	//		( Expressions )
	//		( Expressions , )
	Expression parseTupleExpression() {
		auto loc = token.loc;
		nextToken();	// get rid of (
		// ( )
		if (token.kind == TokenKind.rparen) {
			nextToken();	// get rid of )
			return new UnitExpression(loc);
		}
		auto exps = [parseExpression()];
		// Expressions
		// Expressions ,
		while (token.kind == TokenKind.comma) {
			nextToken();	// get rid of ,
			if (token.kind == TokenKind.rparen) break;
			exps ~= parseExpression();
		}
		check(TokenKind.rparen);
		if (exps.length == 1) {
			if (exps[0]) exps[0].parenthesized = true;
			return exps[0];
		}
		else {
			return new TupleExpression(loc, exps);
		}
	}
	
	/* ************************ Type ************************ */
	//	Type:
	//		FunctionType
	Type parseType() {
		return parseFunctionType();
	}
	//	FunctionType:
	//		PointerType
	//		PointerType -> FunctionType
	Type parseFunctionType() {
		auto t0 = parsePointerType();
		if (token.kind == TokenKind.right_arrow) {
			nextToken();	// get rid of ->
			auto t1 = parseFunctionType();
			t0 = new FuncType(t0, t1);
		}
		return t0;
	}
	//	PointerType:
	//		PrimaryType
	//		# PointerType
	Type parsePointerType() {
		if (token.kind == TokenKind.ref_of) {
			nextToken();	// get rid of #
			auto t1 = parsePointerType();
			return new PtrType(t1);
		}
		else {
			return parsePrimaryType();
		}
	}
	//	PrimaryType:
	//		BuiltInType
	//		ArrayType
	//		AssocArrayType
	//		SymbolType
	//		TupleType
	// //	Typeof
	// //	Mixin
	Type parsePrimaryType() {
		with (TokenKind)
		switch (token.kind) {
		case int32: case uint32: case int64: case uint64: case real32: case real64:
		case bool_: case unit: case string_: case char_:
			auto t0 = new BuiltInType(token.kind.toTPKind());
			nextToken();
			return t0;
		case lbracket:
			return parseArrayType();
		case identifier:
			return parseSymbolType();
		case lparen:
			return parseTupleType();
		//case typeof_:
		//case mixin_:
		default:
			this.error(token.loc, "A type is expected, not \x1b[46m", token.str, "\x1b[0m.");
			nextToken();
			return null;
		}
	}
	
	//	ArrayType:
	//		[ Type ]
	//	AssocArrayType:
	//		[ Type : Type ]
	Type parseArrayType() {
		nextToken();	// get rid of [
		auto t1 = parseType();
		if (token.kind == TokenKind.colon) {
			nextToken();	// get rid of :
			auto t2 = parseType();
			check(TokenKind.rbracket);
			return new AArrayType(t1, t2);
		}
		else {
			check(TokenKind.rbracket);
			return new ArrayType(t1);
		}
	}
	
	//	SymbolType:
	//		identifier
	//		_. identifier
	//		TemplateInstance
	//		_. TemplateInstance
	//		SymbolType . identifier
	//		SymbolType . TemplateInstance
	SymbolType parseSymbolType() {
		bool is_global;
		if (token.kind == TokenKind.global) {
			is_global = true;
			nextToken();
		}
		
		Identifier[] ids;
		if (token.kind == TokenKind.identifier) {
			ids ~= Identifier(token.str, token.loc);
			nextToken();	// get rid of identifier
		}
		else {
			this.error(token.loc, "An identifier was expected, not \x1b[46m", token.str, "\x1b[0m.");
			return null;
		}
		while (token.kind == TokenKind.dot) {
			nextToken();	// get rid of .
			if (token.kind == TokenKind.identifier) {
				ids ~= Identifier(token.str, token.loc);
				nextToken();	// get rid of identifier
			}
			else {
				this.error(token.loc, "An identifier was expected, not \x1b[46m", token.str, "\x1b[0m.");
				return null;
			}
		}
		
		return new SymbolType(TPKind.unsolved, ids);
	}
	
	//	TupleType:
	//		( Types )
	//		( Types , )
	//	Types:
	//		Type
	//		Types , Type
	Type parseTupleType() {
		nextToken();	// get rid of (
		auto ts = [parseType()];
		with (TokenKind)
		while (token.kind == comma) {
			nextToken();	// get rid of ,
			if (token.kind == rparen) break;
			ts ~= parseType();
		}
		check(TokenKind.rparen);
		if (ts.length == 1) {
			if (ts[0]) ts[0].parenthesized = true;
			return ts[0];
		}
		else {
			return new TupleType(ts);
		}
	}
	
	/* ************************ Statement ************************ */
	Statement parseStatement() {
		with (TokenKind)
		// ExpressionStatement
		if (isFirstOfExpression) {
			return parseExpressionStatement();
		}
		// Declaration
		else if (isFirstOfDeclaration) {
			auto decl = parseDeclaration();
			return new DeclarationStatement(decl);
		}
		else
		switch (token.kind) {
			case mul:				return parseLabelStatement();
			case if_:				return parseIfElseStatement();
			case while_:			return parseWhileStatement();
			case do_:				return parseDoWhileStatement();
			case for_:				return parseForStatement();
			case foreach_:
			case foreach_reverse_:	return parseForeachStatement(token.kind == foreach_reverse_);
			case break_:			return parseBreakStatement();
			case continue_:			return parseContinueStatement();
			case goto_:				return parseGotoStatement();
			case return_:			return parseReturnStatement();
			case lbrace:			return parseBlockStatement();
			default:
				this.error(token.loc, "A statement was expected, not \x1b[46m", token.str, "\x1b[0m.");
				return null;
		}
	}
	private pure bool isFirstOfStatement(TokenKind x) @property {
		with (TokenKind)
		return
			   isFirstOfExpression(x)
			|| isFirstOfDeclaration(x)
			|| x.among!(
				mul,			if_,
				while_,			for_,			foreach_,		foreach_reverse_,
				break_,			continue_,		goto_,			return_,
				identifier,		lbrace,
			) != 0;
	}
	private bool isFirstOfStatement() @property {
		return isFirstOfStatement(token.kind);
	}
	//	ExpressionStatement:
	//		Expression ;
	ExpressionStatement parseExpressionStatement() {
		auto loc = token.loc;
		auto exp = parseExpression();
		check(TokenKind.semicolon);
		return new ExpressionStatement(loc, exp);
	}
	//	IfElseStatement:
	//		if Expression : Statement else Statement
	//		if Expression : Statement
	//		if Expression BlockStatement else Statement
	//		if Expression BlockStatement
	IfElseStatement parseIfElseStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of if
		auto cond = parseExpression();
		Statement if_body;
		Statement else_body;
		if (token.kind == TokenKind.colon) {
			nextToken();	// get rid of :
			if_body = parseStatement();
		}
		else if (token.kind == TokenKind.lbrace) {
			if_body = parseBlockStatement();
		}
		else {
			this.error(loc, "\x1b[46m:\x1b[0m or \x1b[46m{ ... }\x1b[0m expected after \x1b[46m:\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
		}
		
		if (token.kind == TokenKind.else_) {
			nextToken();	// get rid of else
			else_body = parseStatement();
		}
		return new IfElseStatement(loc, cond, if_body, else_body);
	}
	//	WhileStatement:
	//		while Expression : Statement
	WhileStatement parseWhileStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of while
		auto cond = parseExpression();
		check(TokenKind.colon);
		auto body = parseStatement();
		return new WhileStatement(loc, cond, body);
	}
	// DoWhileStatement:
	//		do Statement while Expression ;
	DoWhileStatement parseDoWhileStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of do
		auto body = parseStatement();
		check(TokenKind.while_);
		auto exp = parseExpression();
		check(TokenKind.semicolon);
		return new DoWhileStatement(loc, body, exp);
	}
	//	ForStatement:
	//		for Statement Expression ; Expression : Statement
	ForStatement parseForStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of for
		auto init = parseStatement();
		auto test = parseExpression();
		check(TokenKind.semicolon);
		auto exec = parseExpression();
		check(TokenKind.colon);
		auto body = parseStatement();
		return new ForStatement(loc, init, test, exec, body);
	}
	//	ForeachStatement:
	//		foreach ForeachArguments_opt ; Expression               : Statement
	//		foreach ForeachArguments_opt ; Expression .. Expression : Statement
	//	ForeachArguments:
	//		ForeachArgument , ForeachArguments
	//		ForeachArgument
	//	ForeachArgument:
	//		identifier
	//		identifier : Type
	//		_
	//		_ : Type
	//	ForeachReverseStatement:
	//		foreach_reverse ForeachArguments_opt ; Expression               : Statement
	//		foreach_reverse ForeachArguments_opt ; Expression .. Expression : Statement
	Statement parseForeachStatement(bool is_reverse = false) {
		auto loc = token.loc;
		nextToken();	// get rid of foreach
		string[] arg_names;
		Type[] arg_types;
		with (TokenKind)
		while (token.kind.among!(identifier, any)) {
			auto str = token.str;
			nextToken();	// get rid of identifier _
			Type tp;
			if (token.kind == colon) {
				nextToken();	// get rid of :
				tp = parseType();
			}
			arg_names ~= str;
			arg_types ~= tp;
		}
		check(TokenKind.semicolon);
		auto exp = parseExpression();
		Expression exp2;
		if (token.kind == TokenKind.dotdot) {
			nextToken();	// get rid of ..
			exp2 = parseExpression();
		}
		check(TokenKind.colon);
		auto body = parseStatement();
		if (is_reverse) return new ForeachReverseStatement(loc, arg_names, arg_types, exp, exp2, body);
		else return new ForeachStatement(loc, arg_names, arg_types, exp, exp2, body);
	}
	//	BreakStatement:
	//		break ;
	//		break identifier ;
	BreakStatement parseBreakStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of break
		string str;
		if (token.kind == TokenKind.identifier) {
			str = token.str;
			nextToken();	// get rid of identifier
		}
		check(TokenKind.semicolon);
		return new BreakStatement(loc, str);
	}
	//	ContinueStatement:
	//		continue ;
	//		continue identifier ;
	ContinueStatement parseContinueStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of continue
		string str;
		if (token.kind == TokenKind.identifier) {
			str = token.str;
			nextToken();	// get rid of identifier
		}
		check(TokenKind.semicolon);
		return new ContinueStatement(loc, str);
	}
	//	GotoStatement:
	//		goto identifier ;
	GotoStatement parseGotoStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of goto
		string str;
		if (token.kind == TokenKind.identifier) {
			str = token.str;
			nextToken();	// get rid of identifier
		}
		else {
			this.error(loc, "A label was expected, not \x1b[46m", token.str, "\x1b[0m.");
		}
		check(TokenKind.semicolon);
		return new GotoStatement(loc, str);
	}
	//	ReturnStatement:
	//		return ;
	//		return Expression ;
	ReturnStatement parseReturnStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of return
		Expression exp;
		if (token.kind != TokenKind.semicolon) {
			exp = parseExpression();
		}
		check(TokenKind.semicolon);
		return new ReturnStatement(loc, exp);
	}
	//	LabelStatement:
	//		* identifier
	LabelStatement parseLabelStatement() {
		auto loc = token.loc;
		check(TokenKind.mul);
		auto str = token.str;
		if (token.kind == TokenKind.identifier) {
			nextToken();	// get rid of identifier
			return new LabelStatement(loc, str);
		}
		else {
			this.error(loc, "An identifier for label declaration was expected, not \x1b[46m", token.str, "\x1b[0m.");
			return null;
		}
	}
	//	BlockStatement:
	//		{ }
	//		{ StatementList }
	//	StatementList:
	//		Statement
	//		Statement StatementList
	BlockStatement parseBlockStatement() {
		auto loc = token.loc;
		nextToken();	// get rid of {
		Statement[] stmts;
		while (isFirstOfStatement) {
			stmts ~= parseStatement();
			// invalid statement
			if (!stmts[$-1]) break;
		}
		check(TokenKind.rbrace);
		return new BlockStatement(loc, stmts);
	}
	
	/* Declaration */
	//	Declaration:
	//		LetDeclaration
	//		FuncDeclaration
	//		StructDeclaration
	//		TypedefDeclaration
	Symbol parseDeclaration() {
		with (TokenKind)
		switch (token.kind) {
		case let:
			return parseLetDeclaration();
		case func:
			return parseFuncDeclaration();
		case struct_:
			return parseStructDeclaration();
		case typedef:
			return parseTypedefDeclaration();
		case import_:
			return parseImportDeclaration();
		default:
			this.error(token.loc, "A declaration was expected, not \x1b[46m", token.str, "\x1b[0m.");
			return null;
		}
	}
	private pure bool isFirstOfDeclaration(TokenKind x) @property {
		with (TokenKind)
		return
			x.among!(
				let,
				func,
				struct_,
				typedef,
				import_,
			) != 0;
	}
	private bool isFirstOfDeclaration() @property {
		return isFirstOfDeclaration(token.kind);
	}
	
	//	LetDeclaration:
	//		let LetDeclBodies ;
	//		let LetDeclBodies , ;
	//	LetDeclBodies:
	//		LetDeclBody
	//		LetDeclBody , LetDeclBodies
	//	LetDeclBody:
	//		identifier = Expression
	//		identifier : Type
	//		identifier : Type = Expression
	LetDeclaration parseLetDeclaration() {
		nextToken();	// get rid of let
		
		LetDeclaration parse_one() {
			auto id = Identifier(token.str, token.loc);
			nextToken();	// get rid of identifier
			Type tp;
			Expression exp;
			if (token.kind == TokenKind.colon) {
				nextToken();	// get rid of :
				tp = parseType();
			}
			if (token.kind == TokenKind.ass) {
				nextToken();
				exp = parseExpression();
			}
			return new LetDeclaration(id, tp, exp);
		}
		
		LetDeclaration result;
		if (token.kind == TokenKind.identifier) {
			result = parse_one();
			if (token.kind == TokenKind.comma) nextToken();
		}
		else {
			this.error(token.loc, "An identifier was expected after \x1b[46mlet\x1b[0m, not", "\x1b[46m", token.str, "\x1b[0m");
		}
		LetDeclaration bottom_ld = result;
		with (TokenKind)
		while (token.kind == identifier) {
			auto newld = parse_one;
			bottom_ld.next = newld;
			bottom_ld = newld;
			if (token.kind == comma) nextToken();
			if (token.kind == semicolon) break;
		}
		
		check(TokenKind.semicolon);
		return result;
	}
	
	//	FuncDeclaration:
	//		func identifier (: Type)_opt FunctionArgumentList_opt BlockStatement
	//		func identifeir (: Type)_opt FunctionArgumentList_opt = Expression ;
	//	FunctionArgumentList:
	//		FunctionArgument
	//		FunctionArgument FunctionArgumentList
	//	FunctionArgument:
	//		identifier (: Type)_opt
	//		_ (: Type)_opt
	FuncDeclaration parseFuncDeclaration() {
		auto loc = token.loc;
		nextToken();	// get rid of func
		
		Identifier id;
		if (token.kind != TokenKind.identifier) {
			this.error(loc, "An identifier expected after \x1b[46mfunc\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
		}
		else {
			id = Identifier(token.str, token.loc);
			nextToken();	// get rid of identifier
		}
		
		Type ret_type;
		if (token.kind == TokenKind.colon) {
			nextToken();	// get rid of :
			ret_type = parseType();
		}
		//else ret_type = new BuiltInType(TPKind.unit);
		
		FuncArgument[] args;
		with (TokenKind)
		while (token.kind.among!(identifier, any)) {
			auto arg_id = Identifier(token.str, token.loc);
			Type type;
			nextToken();	// get rid of identifier
			if (token.kind == colon) {
				nextToken();	// get rid of :
				type = parseType();
			}
			args ~= new FuncArgument(arg_id, type);
		}
		
		BlockStatement body;
		with (TokenKind)
		if (token.kind == lbrace) {
			body = parseBlockStatement();
		}
		else if (token.kind == ass) {
			auto assloc = token.loc;
			nextToken();
			auto exp = parseExpression();
			check(semicolon);
			body = new BlockStatement(assloc, [new ReturnStatement(assloc, exp)]);
		}
		
		auto result = new FuncDeclaration(id, ret_type, args, body);
		return result;
	}
	
	//	StructDeclaration:
	//		struct identifier { StructBodyList }
	//	StructBodyList:
	//		StructBody
	//		StructBody StructBodyList
	//	StructBody:
	//		Declaration
	StructDeclaration parseStructDeclaration() {
		auto loc = token.loc;
		nextToken();	// get rid of struct
		
		Identifier id;
		if (token.kind != TokenKind.identifier) {
			this.error(loc,"An identifier expected after \x1b[46mstruct\x1b[0m, not \x1b[46m", token.str, "\x1b[0m.");
		}
		else{
			id = Identifier(token.str, token.loc);
		}
		nextToken();	// get rid of identifier
		
		check(TokenKind.lbrace);
		
		Symbol[] mems;
		while (isFirstOfDeclaration) {
			mems ~= parseDeclaration();
		}
		
		check(TokenKind.rbrace);
		
		return new StructDeclaration(id, mems);
	}
	
	//	Typedef:
	//		typedef identifier =_opt Type ;
	TypedefDeclaration parseTypedefDeclaration() {
		bool is_error = false;
		auto loc = token.loc;
		Identifier id;
		nextToken();	// get rid of typedef
		if (token.kind != TokenKind.identifier) {
			this.error(loc, "An identifier expected after \x1b[46mfunc\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
			is_error = true;
		}
		else {
			id = Identifier(token.str, token.loc);
			nextToken();	// get rid of identifier
		}
		if (token.kind == TokenKind.ass) nextToken();	// get rid of =
		auto type = parseType();
		check(TokenKind.semicolon);
		return new TypedefDeclaration(id, type);
	}
	
	//	Import:
	//		import ImportBodies ,_opt ;
	//		import (ImportBodies ,)_opt ImportBody : Identifiers ,_opt ;
	//	ImportBodies:
	//		identifier = ModuleName , ImportBodies
	//		ModuleName , ImportBodies
	//		identifier
	//		ModuleName
	//		BindedImports
	//	BindedImports:
	//		ModuleName : BindedImportsBodies
	//	BindedImportsBodies:
	//		BindedImportsBody , BindedImportsBodies
	//		BindedImportsBody
	//	BindedImportsBody:
	//		identifier
	//		identifier = identifier
	ImportDeclaration parseImportDeclaration() {
		nextToken();	// get rid of import
		ImportDeclaration result;
		
		ImportDeclaration parse_one() {
			// identifier = Modulename
			if (lookahead(1).kind == TokenKind.ass) {
				Identifier replace = Identifier(token.str, token.loc);
				nextToken();	// get rid of identifier
				nextToken();	// get rid of =
				auto modname = parseModuleName();
				if (modname.length == 0) {
					this.error(token.loc, "An identifier was expected after \x1b[46mimport foo =\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
					return null;
				}
				return new ImportDeclaration(replace, modname, true);
			}
			// ModuleName
			// BindedImports
			else {
				Identifier id = Identifier(token.str, token.loc);
				auto modname = parseModuleName();
				
				// BindedImports
				if (token.kind == TokenKind.colon) {
					nextToken();	// get rid of :
					
					Identifier[] imports;
					Identifier[] bindings;
					while (token.kind == TokenKind.identifier) {
						
						// identifier = identifier
						if (lookahead(1).kind == TokenKind.ass) {
							auto binding = Identifier(token.str, token.loc);
							nextToken();	// get rid of identifier
							nextToken();	// get rid of =
							if (token.kind != TokenKind.identifier) {
								this.error(token.loc, "An identifier was expected after \x1b[46mimport foo.bar : baz = \x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
							}
							else {
								bindings ~= binding;
								imports ~= Identifier(token.str, token.loc);
								nextToken();	// get rid of identifier
							}
						}
						else {
						// identifier
							bindings ~= Identifier.init;
							imports ~= Identifier(token.str, token.loc);
							nextToken();	// get rid of identifier
						}
						if (token.kind == TokenKind.comma) nextToken();
					}
					if (imports.length == 0)
						this.error(token.loc, "An identifier was expected after \x1b[46mimport foo.bar : \x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
					return new BindedImportDeclaration(id, modname, imports, bindings);
				}
				else
					return new ImportDeclaration(id, modname);
			}
		}
		
		result = parse_one();
		if (!result) {
			check(TokenKind.semicolon);
			return null;
		}
		
		if (token.kind == TokenKind.comma) nextToken();
		
		auto bottom = result;
		while (token.kind == TokenKind.identifier) {
			auto newimp = parse_one();
			// link
			if (newimp) {
				bottom.next = newimp;
				bottom = newimp;
			}
			if (token.kind == TokenKind.comma) nextToken();
		}
		check(TokenKind.semicolon);
		
		return result;
	}
}

