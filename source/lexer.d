/**
 * lexer.d
 * Lexing the source code.
 */
module lexer;

import std.ascii, std.array;
import std.conv: to;
import std.algorithm: among;
import std.meta: aliasSeqOf;
import std.range: isInputRange;
import std.traits: ReturnType;
import message;
import token;

immutable EOF = cast(dchar) -1;
immutable BR  = cast(dchar) '\n';

enum isCharacterStream(T) = isInputRange!(T) && is(ReturnType!((T t) => t.front) : immutable dchar);

interface CharacterStream {
	immutable(dchar) character() const @property;
	void nextChar();
	immutable(dchar) lookahead(size_t k=1);
}

/// Wrapper for the lexer.
private class CharacterPusher(Range)
	if (isCharacterStream!Range)
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
	
	protected string filepath;

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

	/**
	 * Params:
	 *     r = the source range
	 *     path to the file
	 *     a2u = when it is false, it yields error when encountering __id.
	 */
	public this (Range r, string filepath, bool a2u = true) {
		source = new CP(r);
		_nextToken();
		this.filepath = _token.loc.path = filepath;
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
				case "module":			_token.kind = module_;			break;
				case "import":			_token.kind = import_;			break;
				case "let":				_token.kind = let;				break;
				case "func":			_token.kind = func;				break;
				case "typedef":			_token.kind = typedef;			break;
				case "struct":			_token.kind = struct_;			break;
				case "union":			_token.kind = union_;			break;
				case "class":			_token.kind = class_;			break;
				case "interface":		_token.kind = interface_;		break;
				case "template":		_token.kind = template_;		break;
				case "mixin":			_token.kind = mixin_;			break;
				case "immut":			_token.kind = immut;			break;
				case "const":			_token.kind = const_;			break;
				case "inout":			_token.kind = inout_;			break;
				case "shared":			_token.kind = shared_;			break;
				case "lazy":			_token.kind = lazy_;			break;
				case "ref":				_token.kind = ref_;				break;
				case "out":				_token.kind = out_;				break;
				case "scope":			_token.kind = scope_;			break;
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
				case "extern":			_token.kind = extern_;			break;
				case "pure":			_token.kind = pure_;			break;
				case "throwable":		_token.kind = throwable;		break;
				case "typeid":			_token.kind = typeid_;			break;
				case "typeof":			_token.kind = typeof_;			break;
				case "if":				_token.kind = if_;				break;
				case "else":			_token.kind = else_;			break;
				case "for":				_token.kind = for_;				break;
				case "while":			_token.kind = while_;			break;
				case "foreach":			_token.kind = foreach_;			break;
				case "foreach_reverse":	_token.kind = foreach_reverse_;	break;
				case "do":				_token.kind = do_;				break;
				case "break":			_token.kind = break_;			break;
				case "continue":		_token.kind = continue_;		break;
				case "return":			_token.kind = return_;			break;
				case "goto":			_token.kind = goto_;			break;
				case "assert":			_token.kind = assert_;			break;
				case "as":				_token.kind = as;				break;
				case "when":			_token.kind = when;				break;
				case "match":			_token.kind = match;			break;
				case "app":				_token.kind = app;				break;
				case "or":				_token.kind = or;				break;
				case "xor":				_token.kind = xor;				break;
				case "and":				_token.kind = and;				break;
				case "not":				_token.kind = not;				break;
				case "in":				_token.kind = in_;				break;
				case "is":				_token.kind = is_;				break;
				case "new":				_token.kind = new_;				break;
				case "literal":			_token.kind = literal;			break;
				default:				_token.kind = identifier;		break;
			}
			if (!allow_2_underbars && str.length >= 2 && str[0] == '_' && str[1] == '_') {
				message.error(_token.loc, "An identifier starting with two underbars ",str.to!string, " is not allowed. '__' is  rewritten to '_0_'.");
				str = "_0_" ~ str[2..$];
			}
			// ._
			if (str == "_" && source.character == '.') {
				nextChar();		// get rid of .
				_token.kind = global;
				str = "_.";
			}
			else if (str == "e" && source.character == '{') {
				nextChar();		// get rid of {
				_token.kind = ebrace;
				str = "e{";
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
				_token.kind = xor;
				str = "^^";
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
			_token.kind = rbrace;
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
			else if (source.character == '*') {
				nextChar();	 // get rid of *
				if (source.character == '=') {
					nextChar();
					_token.kind = pow_ass;
					str = "**=";
				}
				else {
					_token.kind = pow;
					str = "**";
				}
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
			else if (source.character == '>') {
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
			_token.kind = temp_inst;
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
