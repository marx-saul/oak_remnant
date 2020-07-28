module lexer;

import std.ascii, std.array;
import std.conv: to;
import std.algorithm: among;
import std.meta: aliasSeqOf;
import std.range: isInputRange;
import std.traits: ReturnType;
import message;

/**
 * The location of a token.
 */
struct Location {
	size_t line_num;
	size_t index_num;
	string path;
}

immutable EOF = cast(dchar) -1;
immutable BR  = cast(dchar) '\n';
/// Wrapper for the lexer.
private class CharacterPusher(Range)
	if (isInputRange!(Range) && is(ReturnType!((Range r) => r.front) : immutable dchar))
{
	private Range character_source;
	private dchar front_character;
	private immutable(dchar)[] following_characters;

	protected size_t line_num;
	protected size_t index_num;

	///
	this (Range r) {
		character_source = r;
		front_character = r.empty ? EOF : r.front;
		if (front_character == BR) line_num = 2;
		else line_num = 1;
		index_num = 1;
	}

	/// Returns: the current character
	immutable(dchar) character() const @property {
		return cast(immutable) front_character;
	}

	/// Get rid of one character.
	void nextChar() {
		if (following_characters.length == 0) {
			if (!character_source.empty)
				character_source.popFront();

			if (!character_source.empty)
				front_character = character_source.front;
			else
				front_character = EOF;
		}
		else {
			front_character = following_characters[0];
			following_characters = following_characters[1..$];
		}
		// line and index count
		if (front_character == BR) ++line_num, index_num = 1;
		else ++index_num;
	}

	/// Returns: k-th next character
	immutable(dchar) lookahead(size_t k=1) {
		if (k == 0) return front_character;
		while (k > following_characters.length) {
			if (!character_source.empty)
				character_source.popFront();

			if (!character_source.empty)
				following_characters ~= character_source.front;
			else
				following_characters ~= EOF;
		}
		return following_characters[k-1];
	}
}

/**
 * Enum of the types of all tokens.
 * TokenKind.apply does not appear in oak source codes, it is used for function application.
 */
enum TokenKind : ubyte {
	error = 0,
	identifier,		integer,		real_number,	string_literal,
	true_,			false_,			null_,
	this_,			super_,			any,
	int32,			uint32,			int64,			uint64,
	real32,			real64,
	bool_,			unit,			string_,		char_,
	module_,		import_,		let,			func,
	struct_,		union_,			class_,			interface_,
	template_,		mixin_,
	immut,			const_,			inout_,			ref_,
	private_,		protected_,		package_,		public_,		export_,
	abstract_,	  override_,	  final_,		 static_,
	deprecated_,
	//safe,		   trusted,		system,	   pure_,		  throwable,
	typeid_,		typeof_,
	if_,			else_,
	for_,		   while_,		 foreach_,		foreach_reverse_,
	do_,			break_,		 continue_,		return_,
	goto_,		  assert_,		as,
	ass, add_ass, sub_ass, cat_ass, mul_ass, div_ass, mod_ass, pow_ass, and_ass, xor_ass, or_ass, // = += -= ++= /= %= ^^= &= ^= |=
	match,
	pipeline,	// =>
	app,		// app
	or,			// or  ||
	and,		// and &&
	bit_or,		// |
	bit_xor,	// ^
	bit_and,	// &
	eq, neq, ls, gt, leq, geq, in_, nin, is_, nis,		// == != < > in !in is !is
	lshift, rshift, logical_shift,	// << >> >>>
	add, sub, cat,	// + - ++
	mul, div, mod,	// * / %
	minus, not, ref_of, deref,	// -- ~ # !
	pow,				// ^^
	apply,  			// function application
	indexing, dotdot,   // ![ ]  ..
	composition,		// @
	dot,				// .
	new_,				// new
	question,			// template instanciation ?
	global,				// _.
	lparen, rparen, lbracket, rbracket, lbrace, rbrace, // ( ) [ ] { }
	dollar, lambda,	 // $ \
	semicolon,	  colon,		  comma,		  right_arrow, // ; : , ->

	end_of_file,
}

immutable string[TokenKind.max+1] token_dictionary = [
	TokenKind.identifier: "identifier", TokenKind.integer: "integer", TokenKind.real_number: "real number", TokenKind.string_literal: "string literal",
	TokenKind.true_: "true",			TokenKind.false_: "false",			TokenKind.null_: "null",
	TokenKind.this_: "this",			TokenKind.super_: "super",			TokenKind.any: "_",
	TokenKind.int32: "int32",			TokenKind.uint32: "uint32",			TokenKind.int64: "int64",			TokenKind.uint64: "uint64",
	TokenKind.real32: "real32",			TokenKind.real64: "real64",
	TokenKind.bool_: "bool",			TokenKind.unit: "unite",			TokenKind.string_: "string",		TokenKind.char_: "char",
	TokenKind.module_: "module",		TokenKind.import_: "import",		TokenKind.let: "let",				TokenKind.func: "func",
	TokenKind.struct_: "struct",		TokenKind.union_:"union",			TokenKind.class_: "class",			TokenKind.interface_: "interface",
	TokenKind.template_: "template",	TokenKind.mixin_: "mixin",
	TokenKind.immut: "immut",			TokenKind.const_: "const",			TokenKind.inout_: "inout",			TokenKind.ref_: "ref",
	TokenKind.private_: "private",		TokenKind.protected_: "protected",	TokenKind.package_: "package",		TokenKind.public_: "public",			TokenKind.export_: "export",
	TokenKind.abstract_: "abstract",	TokenKind.override_: "override_",	TokenKind.final_: "final",			TokenKind.static_: "static",
	TokenKind.deprecated_: "deprecated",
	//safe,		   trusted,		system,	   pure_,		  throwable,
	TokenKind.typeid_: "typeid",		TokenKind.typeof_: "typeof",
	TokenKind.if_: "if",				TokenKind.else_: "else",
	TokenKind.for_: "for",				TokenKind.while_: "while",			TokenKind.foreach_: "foreach",		TokenKind.foreach_reverse_: "foreach_reverse",
	TokenKind.do_: "do",				TokenKind.break_: "break",			TokenKind.continue_: "continue",	TokenKind.return_: "return",
	TokenKind.goto_: "goto",			TokenKind.assert_: "assert",		TokenKind.as: "as",
	TokenKind.ass: "=",      TokenKind.add_ass: "+=", TokenKind.sub_ass: "-=", TokenKind.cat_ass:"++=",
	TokenKind.mul_ass: "*=", TokenKind.div_ass: "/=", TokenKind.mod_ass: "%=", TokenKind.pow_ass: "^^=",
	TokenKind.and_ass: "&=", TokenKind.xor_ass: "^=", TokenKind.or_ass: "|=",
	TokenKind.match: "match",
	TokenKind.pipeline: "=>", TokenKind.app: "app", TokenKind.and: "&&", TokenKind.bit_or: "|", TokenKind.bit_xor: "^", TokenKind.bit_and: "&",
	TokenKind.eq: "==", TokenKind.neq: "!=", TokenKind.ls: "<", TokenKind.gt: ">", TokenKind.leq: "<=",
	TokenKind.geq: ">=", TokenKind.in_: "in", TokenKind.nin: "!in", TokenKind.is_: "is", TokenKind.nis: "!is",
	TokenKind.lshift: "<<", TokenKind.rshift: ">>", TokenKind.logical_shift: ">>>",
	TokenKind.add: "+", TokenKind.sub: "-", TokenKind.cat: "++", TokenKind.mul: "*", TokenKind.div: "/", TokenKind.mod: "%",
	TokenKind.minus: "--", TokenKind.not: "~", TokenKind.ref_of: "#", TokenKind.deref: "!",
	TokenKind.pow: "^^", TokenKind.apply: "", TokenKind.indexing: "![", TokenKind.dotdot: "..",
	TokenKind.composition: "@", TokenKind.dot: ".", TokenKind.new_: "new", TokenKind.question: "?", TokenKind.global: "_.",
	TokenKind.lparen: "(", TokenKind.rparen: ")", TokenKind.lbracket: "[", TokenKind.rbracket: "]", TokenKind.lbrace: "{", TokenKind.rbrace: "}",
	TokenKind.dollar: "$", TokenKind.lambda: "\\",
	TokenKind.semicolon: ";", TokenKind.colon: ":", TokenKind.comma: ",", TokenKind.right_arrow: "->",
	TokenKind.end_of_file: "EOF",
];

/**
 * 
 */
struct Token {
	Location loc;
	TokenKind kind;
	string str;
}

/**
 * Interface for lexers.
 */
interface LexerInterface {
	Token token() @property inout;
	Token lookahead(size_t k = 1);
}

/**
 *
 */
class Lexer(Range)
	if (isInputRange!(Range) && is(ReturnType!((Range r) => r.front) : immutable dchar))
{
	private alias CP = CharacterPusher!Range;
	private CP source;
	private immutable bool allow_2_underbars;

	private Token _token;
	protected Token token() @property inout { return _token; }
	private Token[] following_tokens;

	/// Get rid of one token.
	protected void nextToken() {
		if (following_tokens.length == 0) _nextToken();
		else {
			_token = following_tokens[0];
			following_tokens = following_tokens[1..$];
		}
	}
	/// Get k-th next token.
	protected Token lookahead(size_t k=1) {
		if (k == 0) return _token;
		immutable front_token = _token;		// save
		while (k > following_tokens.length) {
			_nextToken();
			following_tokens ~= _token;
		}
		_token = front_token;		// back
		return following_tokens[k-1];
	}

	/// Create lexer. If a2u is false, it yields error when encountering __id.
	public this (Range r, bool a2u = true) {
		source = new CP(r);
		_nextToken();
		allow_2_underbars = a2u;
	}

	private void nextChar() { source.nextChar(); }

	/// Lexing. Get the next token.
	private void _nextToken() {
		// ignore spaces and comment
		while (true) {
			// spaces
			while (isWhite(source.character) && source.character != EOF)
				nextChar();

			// not a comment
			if (source.character != '/') break;

			// one line comment
			if (source.lookahead() == '/') {
				nextChar();	 // get rid of /
				nextChar();	 // get rid of /
				while (!source.character.among!(BR, EOF))
					nextChar();
			}
			// multiple line comment
			else if (source.lookahead() == '*') {
				nextChar();	 // get rid of /
				nextChar();	 // get rid of *
				while (!(source.character == '*' && source.lookahead() == '/') && source.character != EOF)
					nextChar();
				if (source.character == EOF) { error(Location(source.line_num, source.index_num), "corresponding */ not found"); }
				nextChar();	 // get rid of *
				nextChar();	 // get rid of /
			}
			// nested comment
			else if (source.lookahead() == '+') {
				nextChar(); // get rid of /
				nextChar(); // get rid of +
				size_t comment_depth = 1;
				while (comment_depth > 0 && source.character != EOF) {
					auto c_c = source.character, n_c = source.lookahead;
					if	  (c_c == '+' && n_c == '/') {
						--comment_depth;
						nextChar();	 // get rid of +
						nextChar();	 // get rid of /
					}
					else if (c_c == '/' && n_c == '+') {
						++comment_depth;
						nextChar();	 // get rid of /
						nextChar();	 // get rid of +
					}
					else nextChar();
				}
			}
			else break;
		}

		_token.loc.line_num  = source.line_num;
		_token.loc.index_num = source.index_num;

		immutable(dchar)[] str;
		// identifier of reserved words
		with (TokenKind)
		if (source.character.isAlpha() || source.character == '_') {
			while (source.character.isAlphaNum() || source.character == '_') {
				str ~= source.character;
				nextChar();
			}
			switch (str) {
				case "true":			_token.kind = true_;			break;
				case "false":			_token.kind = false_;			break;
				case "null":			_token.kind = null_;			break;
				case "this":			_token.kind = this_;			break;
				case "super":			_token.kind = super_;			break;
				case "_":				_token.kind = any;				break;
				case "int32":			_token.kind = int32;			break;
				case "uint32":			_token.kind = uint32;			break;
				case "int64":			_token.kind = int64;			break;
				case "uint64":			_token.kind = uint64;			break;
				case "real32":			_token.kind = real32;			break;
				case "real64":			_token.kind = real64;			break;
				case "bool":			_token.kind = bool_;			break;
				case "unit":			_token.kind = unit;				break;
				case "string":			_token.kind = string_;			break;
				case "char":			_token.kind = char_;			break;
				case "struct":			_token.kind = struct_;			break;
				case "union":			_token.kind = union_;			break;
				case "class":			_token.kind = class_;			break;
				case "interface":		_token.kind = interface_;		break;
				case "template":		_token.kind = template_;		break;
				case "mixin":			_token.kind = mixin_;			break;
				case "immut":			_token.kind = immut;			break;
				case "const":			_token.kind = const_;			break;
				case "inout":			_token.kind = inout_;			break;
				case "ref":				_token.kind = ref_;				break;
				case "private":			_token.kind = private_;			break;
				case "protected":		_token.kind = protected_;		break;
				case "package":			_token.kind = package_;			break;
				case "public":			_token.kind = public_;			break;
				case "export":			_token.kind = export_;			break;
				case "abstract":		_token.kind = abstract_;		break;
				case "override":		_token.kind = override_;		break;
				case "final":			_token.kind = final_;			break;
				case "static":			_token.kind = static_;			break;
				case "deprecated":		_token.kind = deprecated_;		break;
				case "typeid":			_token.kind = typeid_;			break;
				case "typeof":			_token.kind = typeof_;			break;
				case "if":				_token.kind = if_;				break;
				case "else":			_token.kind = else_;			break;
				case "for":				_token.kind = for_;				break;
				case "while":		   _token.kind = while_;		  break;
				case "foreach":		 _token.kind = foreach_;		break;
				case "foreach_reverse": _token.kind = foreach_reverse_;break;
				case "do":			  _token.kind = do_;			 break;
				case "break":		   _token.kind = break_;		  break;
				case "continue":		_token.kind = continue_;	   break;
				case "return":		  _token.kind = return_;		 break;
				case "goto":			_token.kind = goto_;		   break;
				case "assert":		  _token.kind = assert_;		 break;
				case "match":		   _token.kind = match;		   break;
				case "app":			 _token.kind = app;			 break;
				case "or":			  _token.kind = or;			  break;
				case "and":			 _token.kind = and;			 break;
				case "not":			 _token.kind = not;			 break;
				case "in":			  _token.kind = in_;			 break;
				case "is":			  _token.kind = is_;			 break;
				default:				_token.kind = identifier;	  break;
			}
			if (!allow_2_underbars && str.length >= 2 && str[0] == '_' && str[1] == '_') {
				message.error(_token.loc, "An identifier starting with two underbars ",str.to!string, " is not allowed. '__' is  rewritten to '_0_'.");
				str = "_0_" ~ str[2..$];
			}
			// ._
			if (str == "_" && source.character == '.') {
				nextChar();		// get rid 
				_token.kind = global;
				str = "._";
			}
		}
		// hexical
		else if (source.character == '0' && source.lookahead.among!('x', 'X')) {
			// hexical
			str ~= ['0', source.lookahead];
			nextChar();
			nextChar();
			while (source.character.among!(aliasSeqOf!"0123456789abcdefABCDEF_")) {
				str ~= source.character;
				nextChar();
			}
			// real number
			if (
				source.character == '.'
				// 0x1.; --> 0x1. ;
				// 0x1..2 --> 0x1 .. 2
				// 0x3.repeat --> 0x3 . repeat
				// 0x3._abc ---> 0x3 . _abc
				&& source.lookahead().among!(aliasSeqOf!"._") == 0
				&& !( source.lookahead().isAlpha() && !source.character.among!(aliasSeqOf!"abcdefABCEDF") )
			) {
				nextChar();
				str ~= '.';
				_token.kind = real_number;
				while (source.character.among!(aliasSeqOf!"0123456789abcdefABCDEF_")) {
					str ~= source.character;
					nextChar();
				}
			}
			else {
				_token.kind = integer;
			}
		}
		// binary
		else if (source.character == '0' && source.lookahead.among!('b', 'B')) {
			str ~= ['0', source.lookahead];
			nextChar();
			nextChar();
			while (source.character.among!(aliasSeqOf!"01_")) {
				str ~= source.character;
				nextChar();
			}
			// real number
			if (
				source.character == '.'
				&& source.lookahead().among!(aliasSeqOf!"._") == 0
				&& !( source.character.isAlpha() )
			) {
				nextChar();
				str ~= '.';
				_token.kind = real_number;
				while (source.character.among!(aliasSeqOf!"01_")) {
					str ~= source.character;
					nextChar();
				}
			}
			else {
				_token.kind = integer;
			}
		}
		// 10
		else if (source.character.isDigit()) {
			while (source.character.among!(aliasSeqOf!"0123456789_")) {
				str ~= source.character;
				nextChar();
			}
			// real number
			if (
					source.character == '.'
				&& source.lookahead().among!(aliasSeqOf!"._") == 0
				&& !source.lookahead().isAlpha()
			) {
				nextChar();
				str ~= '.';
				_token.kind = real_number;
				while (source.character.among!(aliasSeqOf!"0123456789_")) {
					str ~= source.character;
					nextChar();
				}
			}
			else {
				_token.kind = integer;
			}
		}
		// strings
		else if (source.character == '"') {
			_token.kind = string_literal;
			nextChar(); // get rid of "
			while (!source.character.among!('"', EOF)) {
				if (source.character == '\\') {
					nextChar();	 // get rid of \
					switch (source.character) {
						case '\\':str ~= '\\'; break;
						case '"': str ~= '"';  break;
						case '0': str ~= '\0'; break;
						case 'a': str ~= '\a'; break;
						case 'b': str ~= '\b'; break;
						case 'f': str ~= '\f'; break;
						case 'n': str ~= '\n'; break;
						case 'r': str ~= '\r'; break;
						case 't': str ~= '\t'; break;
						case 'v': str ~= '\v'; break;
						// invalid escape sequence
						default:
							message.error(Location(source.line_num, source.index_num), "Invalid escape sequence \\",
								source.character == EOF ? "EOF" : source.character.to!string);
							break;
					}
					nextChar();	 // get rid of the escape sequence
				}
				str ~= source.character;
				nextChar();
			}
			nextChar();
		}
		// symbols
		else if (source.character == '!') {
			nextChar();	 // get rid of !
			auto c = source.character;
			if	  (c == '=') {
				nextChar();	 // get rid of =
				_token.kind = neq;
				str = "!=";
			}
			else if (c == '[') {
				nextChar();	 // get rid of [
				_token.kind = indexing;
				str = "![";
			}
			else {
				_token.kind = deref;
				str = "!";
			}
		}
		else if (source.character == '#') {
			nextChar();	 // get rid of #
			_token.kind = ref_of;
			str = "#";
		}
		else if (source.character == '$') {
			nextChar();	 // get rid of $
			_token.kind = dollar;
			str = "$";
		}
		else if (source.character == '%') {
			nextChar();	 // get rid of %
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = mod_ass;
				str = "%=";
			}
			else {
				_token.kind = mod;
				str = "%";
			}
		}
		else if (source.character == '&') {
			nextChar();	 // get rid of &
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = and_ass;
				str = "&=";
			}
			else if (source.character == '&') {
				nextChar();	 // get rid of &
				_token.kind = and;
				str = "&&";
			}
			else {
				_token.kind = bit_and;
				str = "&";
			}
		}
		else if (source.character == '|') {
			nextChar();	 // get rid of %
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = or_ass;
				str = "|=";
			}
			else if (source.character == '|') {
				nextChar();	 // get rid of |
				_token.kind = or;
				str = "||";
			}
			else {
				_token.kind = bit_or;
				str = "|";
			}
		}
		else if (source.character == '^') {
			nextChar();	 // get rid of ^
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = xor_ass;
				str = "^=";
			}
			else if (source.character == '^') {
				nextChar();	 // get rid of ^
				if (source.character == '=') {
					nextChar();
					_token.kind = pow_ass;
					str = "^^=";
				}
				else {
					_token.kind = pow;
					str = "^^";
				}
			}
			else {
				_token.kind = bit_xor;
				str = "^";
			}
		}
		else if (source.character == '~') {
			nextChar();	 // get rid of ~
			if (
				source.character == 'i'
			 && source.lookahead(1) == 's'
			 && !(source.lookahead(2).isAlphaNum() || source.lookahead(2) == '_')
			) {
				nextChar();	 // get rid of i
				nextChar();	 // get rid of s
				_token.kind = nis;
				str = "~is";
			}
			else if (
				source.character == 'i'
			 && source.lookahead(1) == 'n'
			 && !(source.lookahead(2).isAlphaNum() || source.lookahead(2) == '_')
			) {
				nextChar();	 // get rid of i
				nextChar();	 // get rid of n
				_token.kind = nin;
				str = "~in";
			}
			else {
				_token.kind = not;
				str = "~";
			}
		}
		else if (source.character == '(') {
			nextChar();	 // get rid of (
			_token.kind = lparen;
			str = "(";
		}
		else if (source.character == ')') {
			nextChar();	 // get rid of )
			_token.kind = rparen;
			str = ")";
		}
		else if (source.character == '{') {
			nextChar();	 // get rid of {
			_token.kind = lbrace;
			str = "{";
		}
		else if (source.character == '}') {
			nextChar();	 // get rid of }
			_token.kind = rparen;
			str = "}";
		}
		else if (source.character == '[') {
			nextChar();	 // get rid of [
			_token.kind = lbracket;
			str = "[";
		}
		else if (source.character == ']') {
			nextChar();	 // get rid of ]
			_token.kind = rbracket;
			str = "]";
		}
		else if (source.character == '*') {
			nextChar();	 // get rid of *
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = mul_ass;
				str = "*=";
			}
			else {
				_token.kind = mul;
				str = "*";
			}
		}
		else if (source.character == '+') {
			nextChar();	 // get rid of +
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = add_ass;
				str = "+=";
			}
			else if (source.character == '+') {
				nextChar();	 // get rid of +
				if (source.character == '=') {
					nextChar();	 // get rid of =
					_token.kind = cat_ass;
					str = "++=";
				}
				else {
					_token.kind = cat;
					str = "++";
				}
			}
			else {
				_token.kind = add;
				str = "+";
			}
		}
		else if (source.character == '/') {
			nextChar();	 // get rid of /
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = div_ass;
				str = "/=";
			}
			else {
				_token.kind = div;
				str = "/";
			}
		}
		else if (source.character == '-') {
			nextChar();	 // get rid of -
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = sub_ass;
				str = "-=";
			}
			else if (source.character == '-') {
				nextChar();	 // get rid of -
				_token.kind = minus;
				str = "--";
			}
			else if (source.character == '>') {
				nextChar();	 // get rid of >
				_token.kind = right_arrow;
				str = "->";
			}
			else {
				_token.kind = sub;
				str = "-";
			}
		}
		else if (source.character == ',') {
			nextChar();	 // get rid of ,
			_token.kind = comma;
			str = ",";
		}
		else if (source.character == '.') {
			nextChar();	 // get rid of .
			if (source.character == '.') {
				nextChar();	 // get rid of .
				_token.kind = dotdot;
				str = "..";
			}
			else {
				_token.kind = dot;
				str = ".";
			}
		}
		else if (source.character == ':') {
			nextChar();	 // get rid of :
			_token.kind = colon;
			str = ":";
		}
		else if (source.character == ';') {
			nextChar();	 // get rid of ;
			_token.kind = semicolon;
			str = ";";
		}
		else if (source.character == '<') {
			nextChar();	 // get rid <
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = leq;
				str = "<=";
			}
			else if (source.character == '<') {
				nextChar();	 // get rid of <
				_token.kind = rshift;
				str = "<<";
			}
			else {
				_token.kind = ls;
				str = "<";
			}
		}
		else if (source.character == '>') {
			nextChar();	 // get rid >
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = geq;
				str = ">=";
			}
			else if (source.character == '>') {
				nextChar();	 // get rid of <
				if (source.character == '>') {
					_token.kind = logical_shift;
					str = ">>>";
				}
				else {
					_token.kind = lshift;
					str = "<<";
				}
			}
			else {
				_token.kind = gt;
				str = ">";
			}
		}
		else if (source.character == '=') {
			nextChar();	 // get rid of =
			if (source.character == '=') {
				nextChar();	 // get rid of =
				_token.kind = eq;
				str = "==";
			}
			if (source.character == '>') {
				nextChar();	 // get rid of >
				_token.kind = pipeline;
				str = "=>";
			}
			else {
				_token.kind = ass;
				str = "=";
			}
		}
		else if (source.character == '@') {
			nextChar();	 // get rid of @
			_token.kind = composition;
			str = "@";
		}
		else if (source.character == '\\') {
			nextChar();	 // get rid of \
			_token.kind = lambda;
			str = "\\";
		}
		else if (source.character == '?') {
			nextChar();	 // get rid of ?
			_token.kind = question;
			str = "?";
		}
		else if (source.character == EOF) {
			_token.kind = end_of_file;
			str = "EOF";
		}
		else {
			message.error(Location(source.line_num, source.index_num), "Invalid token : ", source.character.to!string);
			nextChar();
		}

		_token.str = str.to!string;
	}
}

/+
unittest {
	import std.stdio;
	auto lx = new Lexer!(string)(`
	/*/ comment /*/
	/+/ /++/ +/
	id /*01234 009_124*/ 0xFFf 0x0.aF_f
	=+=-=*=/=%=++=$=^=|=~~^^^^==>&&&|||&&
	~in ~is ~in3_set ~is_odd![3..$ 4 ..
	`);
	writeln("lexer");
	while (lx._token.kind != TokenKind.end_of_file) {
		writeln(lx._token.kind, "\t", lx._token.str, "\t//\t", lx._token.loc.line_num, ":", lx._token.loc.index_num);
		writeln(lx.lookahead(1).str, " ", lx.lookahead(2).str);
		lx.nextToken();
	}
}
+/
