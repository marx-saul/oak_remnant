module parser;

import lexer;
import astbase;
import parse_time_visitor;
import message;
import std.algorithm;
import std.conv: to;

unittest {
	import std.stdio;
	writeln("##### parser unittest #####");
	auto parser = new Parser!string(`
	_.a = b = 1 => 2.3 => "strs" app (12, 24) app (42) (f, g)
	//a app b app f g
	`);
	auto node = parser.parseExpression();
	node.to_string().writeln;
}

final class Parser(Range) : Lexer!Range {
	/// Create parser.
	this (Range range, bool a2u=true) {
		super(range, a2u);
	}

	/// Check if the current token is the designated one, and throw it away.
	/// If not, throw away all the token until it reaches it or EOF.
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
	
	private void error(Location loc, string[] msgs...) {
		message.error(loc, msgs);
	}
	
	/+
	private size_t[] lookahead_nums;
	private string[] error_msgs;
	/**
	 * For resoliving grmmars's ambiguity.
	 * When this function is called, every parse*** functions begin to parse without eating any tokens.
	 * Error messages are stored in error_msgs.
	 */
	private void expect() {
		lookahead_nums ~= 0;
	}
	/**
	 * Stop expecting.
	 * Returns: the number of tokens parser consumped.
	 */
	private size_t decide() {
		auto result = lookahead_nums[0];
		lookahead_nums.length -= 1;
		return result;
	}
	/**
	 * Get rid of one token.
	 */
	override private void nextToken() {
		if (lookahead_nums.length > 0) {
			++lookahead_nums[$-1];
		}
		else {
			super.nextToken();
		}
	}
	/**
	 * Get the current token.
	 */
	override private Token token() @property inout {
		if (lookahead_nums.length > 0) {
			return super.lookahead(lookahead_nums[$-1]);
		}
		else {
			return super.token;
		}
	}
	/**
	 * Get the k-th next token.
	 */
	override private Token lookahead(size_t k = 1) {
		if (lookahead_nums.length > 0) {
			return super.lookahead(lookahead_nums[$-1]+k);
		}
		else {
			return super.lookahead(k);
		}
	}
	
	/**
	 * Display error message. If this.expect has been called, it only push error message to this.error_msgs.
	 */
	private void error(Location loc, string[] msgs...) {
		if (lookahead_nums.length > 0) {
			import std.conv: to;
			string result;
			result ~= "\x1b[1m" ~ loc.path ~ "(" ~ loc.line_num.to!string ~ ":" ~ loc.index_num.to!string ~ "):\x1b[0m ";
			result ~= "\x1b[32mError:\x1b[0m ";
			foreach (msg; msgs) {
				result ~= msg;
			}
			result ~= "\n";
		}
		else {
			import std.stdio;
			write("\x1b[1m", loc.path, "(", loc.line_num, ":", loc.index_num, "):\x1b[0m ");
			write("\x1b[32mError:\x1b[0m ");
			foreach (msg; msgs) {
				write(msg);
			}
			writeln();
		}
	}
	+/
	
	/* ******************************************************************************************************** */
	protected:
	//	Expression:
	//		AssignExpression
	Expression parseExpression() {
		return parseAssignExpression();
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
	//		PipelineExpression |> AppExpression
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
	//		AndExpression
	//		OrExpression || AndExpression
	Expression parseOrExpression() {
		auto e0 = parseAndExpression();
		while (token.kind == TokenKind.or) {
			auto loc = token.loc;
			nextToken();	// get rid of ||
			auto e1 = parseAndExpression();
			e0 = new BinaryExpression(loc, TokenKind.or, e0, e1);
		}
		return e0;
	}
	//	AndExpression:
	//		BitOrExpression
	//		AndExpression || BitOrExpression
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
	//		BitCmpExpression
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
	//		ShiftExpression  <  ShiftExpression
	//		ShiftExpression  <= ShiftExpression
	//		ShiftExpression  >  ShiftExpression
	//		ShiftExpression  >= ShiftExpression
	//		ShiftExpression  in ShiftExpression
	//		ShiftExpression !in ShiftExpression
	//		ShiftExpression  is ShiftExpression
	//		ShiftExpression !is ShiftExpression
	Expression parseCmpExpression() {
		auto e0 = parseShiftExpression();
		with (TokenKind)
		if (token.kind.among!(ls, leq, gt, geq, in_, nin, is_, nis)) {
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
	//		AppExpression
	//		AppExpression ^^ PowExpression
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
					e0.is_error = true;
					break;
				}
			}
			// DotExpression . TemplateInstance
			if (token.kind == identifier && lookahead(1).kind == question) {
				assert(0, "TemplateInstance has not been implemented.");
			}
			// DotExpression . Identifier
			else if (token.kind == identifier) {
				auto e1 = new IdentifierExpression(loc, token.str);
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
	// //	LambdaExpression
	// //	StructLiteral
	//		( )
	//		( Expression )
	//		( Expressions )
	//		( Expressions , )
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
			goto case;
		case identifier:
			// TemplateInstance
			if (lookahead(1).kind == question) {
				assert(0, "TemplateInstance has not been implemented.");
			}
			else {
				auto e0 = new IdentifierExpression(token.loc, token.str);
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
		
		//case lambda:
		//case struct_:
			
		case lparen:
			return parseTupleExpression();
			
		case lbracket:
			assert(0, "(Assoc)ArrayExpression has not been implemented.");
			//return parseArrayExpression();
			
		case int32: case uint32: case int64: case uint64: case real32: case real64:
		case bool_: case unit:   case string_: case char_:
			auto loc = token.loc;
			auto basic_type = token.kind;
			check(dot);
			if (token.kind == identifier) {
				auto str = token.str;
				nextToken();
				return new BuiltInTypePropertyExpression(loc, basic_type, str);
			}
			else {
				this.error(loc,
					"An identifier expected after \x1b[46m", token_dictionary[basic_type], ".\x1b[0m , not \x1b[46m",
					token.str, "\x1b[0m");
				nextToken();
				auto e0 = new BuiltInTypePropertyExpression(loc, basic_type, "");
				e0.is_error = true;
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
				// literals
				integer,		real_number,	string_literal,		identifier,
				true_,			false_,			null_,
				this_,			super_,			any,			dollar,
				// 
				if_,			// match,
				// unary operators
				minus,			not,			ref_of,			deref,
				// 
				lambda,			new_,			global,
				// parenthesis
				lparen, 		lbracket,		lbrace,
				// basic types
				int32,			uint32,			int64,			uint64,
				real32,			real64,
				bool_,			unit,			string_,		char_,
			) != 0;
	}
	private bool isFirstOfExpression() @property {
		return isFirstOfExpression(token.kind);
	}
	NewExpression parseNewExpression() {
		auto loc = token.loc;
		nextToken();	// get rid of new
		return new NewExpression(loc, null, null);
	}
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
			return exps[0];
		}
		else {
			return new TupleExpression(loc, exps);
		}
	}
	
	Type parseType() {
		nextToken();
		return null;
	}
	
}

