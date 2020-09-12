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
	this (Range range, string filepath="tmp.oak", bool a2u=true) {
		super(range, filepath, a2u);
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
		import global;
		auto loc = token.loc;
		
		PRLV prlv;
		StorageClass stc;
		Attribution[] attrbs;
		
		Identifier[] modname;
		if (token.kind == TokenKind.module_) {
			nextToken();	// get rid of module
			attrbs = parseAttributionList(prlv, stc);
			
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
		
		if (modname.length > 0) return new Module(this.filepath, attrbs, prlv, stc, modname, mems);
		else return new Module(this.filepath, attrbs, prlv, stc, [Identifier(global.getFileName(this.filepath), loc)], mems);
	}
	
	Identifier[] parseModuleName() {
		Identifier[] result;
		
		if (token.kind == TokenKind.identifier) {
			result ~= Identifier(token.str, token.loc);
			nextToken();
		}
		else {
			return result;
		}
		
		while (token.kind == TokenKind.dot) {
			nextToken();	// get rid of .
			if (token.kind == TokenKind.identifier) {
				result ~= Identifier(token.str, token.loc);
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
			switch (kind) {
				case ass:		e0 = new       AssExpression(loc, e0, e1);		break;
				case add_ass:	e0 = new    AddAssExpression(loc, e0, e1);		break;
				case sub_ass:	e0 = new    SubAssExpression(loc, e0, e1);		break;
				case cat_ass:	e0 = new    CatAssExpression(loc, e0, e1);		break;
				case mul_ass:	e0 = new    MulAssExpression(loc, e0, e1);		break;
				case div_ass:	e0 = new    DivAssExpression(loc, e0, e1);		break;
				case mod_ass:	e0 = new    ModAssExpression(loc, e0, e1);		break;
				case pow_ass:	e0 = new    PowAssExpression(loc, e0, e1);		break;
				case and_ass:	e0 = new BitAndAssExpression(loc, e0, e1);		break;
				case xor_ass:	e0 = new BitXorAssExpression(loc, e0, e1);		break;
				case or_ass:	e0 = new BitOrAssExpression(loc, e0, e1);		break;
				default: assert(0);
			}
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
			e0 = new PipelineExpression(loc, e0, e1);
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
			e0 = new AppExpression(loc, e0, e1);
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
			e0 = new OrExpression(loc, e0, e1);
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
			e0 = new XorExpression(loc, e0, e1);
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
			e0 = new AndExpression(loc, e0, e1);
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
			e0 = new BitOrExpression(loc, e0, e1);
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
			e0 = new BitXorExpression(loc, e0, e1);
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
			e0 = new BitAndExpression(loc, e0, e1);
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
			switch (kind) {
				case ls:	e0 = new LsExpression(loc, e0, e1);		break;
				case leq:	e0 = new LeqExpression(loc, e0, e1);	break;
				case gt:	e0 = new GtExpression(loc, e0, e1);		break;
				case geq:	e0 = new GeqExpression(loc, e0, e1);	break;
				case eq:	e0 = new EqExpression(loc, e0, e1);		break;
				case neq:	e0 = new NeqExpression(loc, e0, e1);	break;
				case in_:	e0 = new InExpression(loc, e0, e1);		break;
				case nin:	e0 = new NinExpression(loc, e0, e1);	break;
				case is_:	e0 = new IsExpression(loc, e0, e1);		break;
				case nis:	e0 = new NisExpression(loc, e0, e1);	break;
				default: assert(0);
			}
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
			switch (kind) {
				case lshift:			e0 = new LShiftExpression(loc, e0, e1);				break;
				case rshift:			e0 = new RShiftExpression(loc, e0, e1);				break;
				case logical_shift:		e0 = new LogicalShiftExpression(loc, e0, e1);		break;
				default: assert(0);
			}
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
			switch (kind) {
				case add:	e0 = new AddExpression(loc, e0, e1);	break;
				case sub:	e0 = new SubExpression(loc, e0, e1);	break;
				case cat:	e0 = new CatExpression(loc, e0, e1);	break;
				default: assert(0);
			}
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
			switch (kind) {
				case mul:	e0 = new MulExpression(loc, e0, e1);	break;
				case div:	e0 = new DivExpression(loc, e0, e1);	break;
				case mod:	e0 = new ModExpression(loc, e0, e1);	break;
				default: assert(0);
			}
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
			e0 = new PowExpression(loc, e0, e1);
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
			e0 = new ApplyExpression(Location.init, e0, e1);
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
			switch (kind) {
				case minus:		return new MinusExpression(loc, parseUnaryExpression());
				case not:		return new NotExpression(loc, parseUnaryExpression());
				case ref_of:	return new RefofExpression(loc, parseUnaryExpression());
				case deref:		return new DerefExpression(loc, parseUnaryExpression());
				default: assert(0);
			}
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
			e0 = new CompositionExpression(loc, e0, e1);
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
				e0 = new DotExpression(loc, e0, e1);
			}
			else if (token.kind == new_) {
				auto e1 = parseNewExpression();
				e0 = new DotExpression(loc, e0, e1);
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
		case literal:
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
	//		literal Type
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
		case TokenKind.global:
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
	SymbolType parseSymbolType(bool allow_global=true) {
		bool is_global;
		SymbolType result;
		
		if (token.kind == TokenKind.global) {
			is_global = true;
			nextToken();	// get rid of _.
		}
		
		if (token.kind != TokenKind.identifier) {
			this.error(token.loc, "An identifier was expected, not \x1b[46m", token.str, "\x1b[0m.");
			return null;
		}
		
		// template instance
		if (lookahead(1).kind == TokenKind.temp_inst) {
			assert(0, "template instance has not been implemented");
		}
		else {
			result = new IdentifierType(Identifier(token.str, token.loc));
			nextToken();	// get rid of id
		}
		
		if (token.kind == TokenKind.dot) {
			nextToken();	// get rid of .
			auto next = parseSymbolType(false);
			result.next = next;
		}
		
		return result;
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
			case colon:				return parseLabelStatement();
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
				colon,			if_,
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
	//		: identifier
	LabelStatement parseLabelStatement() {
		auto loc = token.loc;
		check(TokenKind.colon);
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
	//		let AttributionList_opt LetDeclBodies ,_opt ;
	//	LetDeclBodies:
	//		LetDeclBody
	//		LetDeclBody , LetDeclBodies
	//	LetDeclBody:
	//		identifier = Expression
	//		identifier : Type
	//		identifier : Type = Expression
	LetDeclaration parseLetDeclaration() {
		nextToken();	// get rid of let
		PRLV prlv;
		StorageClass stc;
		auto attrbs = parseAttributionList(prlv, stc);
		
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
			return new LetDeclaration(attrbs, prlv, stc, id, tp, exp);
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
	//		func AttributionList_opt identifier (: Type)_opt FunctionArgumentList_opt BlockStatement
	//		func AttributionList_opt identifeir (: Type)_opt FunctionArgumentList_opt = Expression ;
	//	FunctionArgumentList:
	//		FunctionArgument
	//		FunctionArgument FunctionArgumentList
	//	FunctionArgument:
	//		identifier (: Type)_opt
	//		_ (: Type)_opt
	FuncDeclaration parseFuncDeclaration() {
		auto loc = token.loc;
		nextToken();	// get rid of func
		
		PRLV prlv;
		StorageClass stc;
		auto attrbs = parseAttributionList(prlv, stc);
		
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
			args ~= new FuncArgument([], PRLV.undefined, STC.undefined, arg_id, type);
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
		
		auto result = new FuncDeclaration(attrbs, prlv, stc, id, ret_type, args, body);
		return result;
	}
	
	//	StructDeclaration:
	//		struct AttributionList_opt identifier { StructBodyList }
	//	StructBodyList:
	//		StructBody
	//		StructBody StructBodyList
	//	StructBody:
	//		Declaration
	StructDeclaration parseStructDeclaration() {
		auto loc = token.loc;
		nextToken();	// get rid of struct
		
		PRLV prlv;
		StorageClass stc;
		auto attrbs = parseAttributionList(prlv, stc);
		
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
		
		return new StructDeclaration(attrbs, prlv, stc, id, mems);
	}
	
	//	Typedef:
	//		AttributionList_opt typedef identifier =_opt Type ;
	TypedefDeclaration parseTypedefDeclaration() {
		bool is_error = false;
		auto loc = token.loc;
		Identifier id;
		nextToken();	// get rid of typedef
		
		PRLV prlv;
		StorageClass stc;
		auto attrbs = parseAttributionList(prlv, stc);
		
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
		return new TypedefDeclaration(attrbs, prlv, stc, id, type);
	}
	
	//	Import:
	//		import AttributionList_opt ImportBodies ,_opt ;
	//		import AttributionList_opt (ImportBodies ,)_opt ImportBody : Identifiers ,_opt ;
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
		
		PRLV prlv;
		StorageClass stc;
		auto attrbs = parseAttributionList(prlv, stc);
		
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
				return new AliasImportDeclaration(attrbs, prlv, stc, replace, modname);
			}
			// ModuleName
			// BindedImports
			else {
				Identifier id = Identifier(token.str, token.loc);
				auto modname = parseModuleName();
				Identifier[] ids1, ids2;
				
				// BindedImports
				if (token.kind == TokenKind.colon) {
					nextToken();	// get rid of :
					
					while (token.kind == TokenKind.identifier) {
						// 'id1' = 'id2'
						// 'id1'
						Identifier id1 = Identifier(token.str, token.loc);
						Identifier id2;
						nextToken();	// get rid of id1
						if (token.kind == TokenKind.ass) {
							nextToken();	// get rid of =
							if (token.kind == TokenKind.identifier) {
								id2 = Identifier(token.str, token.loc);
								nextToken();	// get rid of identifier
							}
							else {
								this.error(token.loc, "An identifier was expected after \x1b[46=\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
								id2 = id1;
							}
						}
						else {
							id2 = id1;
						}
						ids1 ~= id1, ids2 ~= id2;
						if (token.kind == TokenKind.comma)
							nextToken();	// get rid of ,
					}
					
					if (ids1.length == 0) {
						this.error(token.loc, "An identifier was expected after \x1b[46:\x1b[0m, not \x1b[46m", token.str, "\x1b[0m");
						return null;
					}
					//import std.stdio; writeln("here\n", ids1, "\n", ids2);
					ImportDeclaration result = new BindedImportDeclaration(attrbs, prlv, stc, modname, ids1[0], ids2[0]);
					auto bottom = result;
					foreach (i; 1 .. ids1.length) {
						bottom = bottom.next = new BindedImportDeclaration(attrbs, prlv, stc, modname, ids1[i], ids2[i]);
					}
					
					return result;
				}
				else
					return new ImportDeclaration(attrbs, prlv, stc, modname);
			}
		}
		
		ImportDeclaration result;
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
	
	/* Attribution */
	//	AttributionList:
	//		Attribution AttributionList
	//		Attribution
	//	Attribution:
	//		ProtectionLevel
	//		Deprecation
	// //	Extern
	//		AtAttribution
	//		immut
	//		const
	//		inout
	//		shared
	//		lazy
	//		ref
	//		return
	//		throwable
	//		pure
	//		ctfe
	//		final
	//		abstract
	//		override
	//		static
	
	// allow empty
	Attribution[] parseAttributionList(out PRLV prlv, out StorageClass stc) {
		Attribution[] result;
		with (TokenKind)
		loop: while (true) {
			switch (token.kind) {
			case private_:
			case package_:
			case public_:
			case export_:
			case protected_:
				result ~= parseProtectionLevel(prlv);
				break;
			
			//case deprecated_:
			//case extern_:
			//case composition:
			
			case immut:
			case const_:
			case inout_:
			case shared_:
			case lazy_:
			case ref_:
			case return_:
			case throwable:
			case pure_:
			case final_:
			case abstract_:
			case override_:
			case static_:
				stc |= TokenKindToSTC[token.kind];
				nextToken();
				break;
			
			default: break loop;
			}
		}
		return result;
	}
	
	//	ProtectionLevel:
	//		private
	//		package
	//		package ( ModuleNames ,_opt )
	//		public
	//		export
	//		protected
	
	Attribution[] parseProtectionLevel(ref PRLV prlv) {
		if (prlv != PRLV.undefined) {
			this.error(token.loc, "Protection level confliction : \x1b[46m", token.str, "\x1b[0m.");
		}
		with (TokenKind)
		switch (token.kind) {
			case private_:
				prlv = PRLV.private_;
				nextToken();
				break;
			
			case package_:
				if (lookahead(1).kind == lparen) {
					prlv = PRLV.package_specified;
					nextToken();	// get rid of package
					nextToken();	// get rid of (
					auto pkgname = parseModuleName();
					check(rparen);
					return [new PackageSpecifiedAttribution(pkgname)];
				}
				else {
					prlv = PRLV.package_;
					nextToken();
				}
				break;
			
			case public_:
				prlv = PRLV.public_;
				nextToken();
				break;
				
			case export_:
				prlv = PRLV.export_;
				nextToken();
				break;
			
			case protected_:
				prlv = PRLV.protected_;
				nextToken();
				break;
			
			default:
				assert(0);
		}
		
		return [];
	}
	//
	//	Deprecation:
	//		deprecated
	//		deprecated ( Expressions ,_opt )
	//
	//	AtAttribution:
	//		@ safe
	//		@ trusted
	//		@ system
	//		@ disable
	//		UserDefinedAttribution
	//
	//	UserDefinedAttribution:
	//		@ ( Expressions ,_opt )
}

