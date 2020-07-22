module lexer;

import std.ascii, std.array;
import std.conv: to;
import std.algorithm: among;
import std.meta: aliasSeqOf;
import std.range: isInputRange;
import std.traits: ReturnType;
import message;

struct Location {
    size_t line_num;
    size_t index_num;
    string[] path;
}

immutable EOF = cast(dchar) -1;
immutable BR  = cast(dchar) '\n';
class CharacterPusher(Range)
    if (isInputRange!(Range) && is(ReturnType!((Range r) => r.front) : immutable dchar))
{
    private Range character_source;
    private dchar front_character;
    private immutable(dchar)[] following_characters;

    protected size_t line_num;
    protected size_t index_num;

    this (Range r) {
        character_source = r;
        front_character = r.empty ? EOF : r.front;
        if (front_character == BR) line_num = 2;
        else line_num = 1;
        index_num = 1;
    }

    immutable(dchar) character() const @property {
        return cast(immutable) front_character;
    }

    // eat one character
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

    immutable(dchar) lookahead(size_t k=1) {
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

enum TokenType : ubyte {
    error,
    identifier,     integer,        real_number,    string_literal,
    true_,          false_,         null_,
    this_,          super_,         any,
    int32,          uint32,         int64,          uint64,
    real32,         real64,
    bool_,          unit,           string_,        char_,
    module_,        import_,        let,            func,
    struct_,        union_,         class_,         interface_,
    template_,      mixin_,
    immut,          const_,         inout_,         ref_,
    private_,       protected_,     package_,       public_,        export_,
    abstract_,      override_,      final_,         static_,
    deprecated_,
    //safe,           trusted,        system,       pure_,          throwable,
    typeid_,        typeof_,
    if_,            else_,
    for_,           while_,         foreach_,       foreach_reverse_,
    do_,            break_,         continue_,      return_,
    goto_,          assert_,
    ass, add_ass, sub_ass, cat_ass, mul_ass, div_ass, mod_ass, pow_ass, and_ass, xor_ass, or_ass, // = += -= ++= /= %= ^^= &= ^= |=
    match,
    pipeline,   // =>
    app,        // app
    or,         // or  ||
    and,        // and &&
    bit_or,     // |
    bit_xor,    // ^
    bit_and,    // &
    eq, neq, ls, gt, leq, geq, in_, nin, is_, nis,  // == != < > in !in is !is
    lshift, rshift, logical_shift,  // << >> >>>
    add, sub, cat,  // + - ++
    mul, div, mod,  // * / %
    minus, bit_not, not, ref_of, deref, // --   ~ not   #   !
    pow,    // ^^
    apply,  // function application
    indexing, dotdot,   // ![ ]  ..
    composition,        // @
    dot,                // .
    ti_type, ti_expr,   // template instanciation :: :;
    lparen, rparen, lbracket, rbracket, lbrace, rbrace, // ( ) [ ] { }
    dollar, lambda,     // $ \
    semicolon,      colon,          comma,          right_arrow, // ; : , ->

    end_of_file,
}

struct Token {
    Location loc;
    TokenType tt;
    string str;
}

class Lexer(Range)
    if (isInputRange!(Range) && is(ReturnType!((Range r) => r.front) : immutable dchar))
{
    private alias CP = CharacterPusher!Range;
    private CP source;
    private immutable bool allow_2_underbars;

    Token token;

    this (Range r, bool a2u = true) {
        source = new CP(r);
        nextToken();
        allow_2_underbars = a2u;
    }

    void nextChar() { source.nextChar(); }

    // get the next token.
    void nextToken() {
        // ignore spaces and comment
        while (true) {
            // spaces
            while (isWhite(source.character) && source.character != EOF)
                nextChar();

            // not a comment
            if (source.character != '/') break;

            // one line comment
            if (source.lookahead() == '/') {
                nextChar();     // get rid of /
                nextChar();     // get rid of /
                while (!source.character.among!(BR, EOF))
                    nextChar();
            }
            // multiple line comment
            else if (source.lookahead() == '*') {
                nextChar();     // get rid of /
                nextChar();     // get rid of *
                while (!(source.character == '*' && source.lookahead() == '/') && source.character != EOF)
                    nextChar();
                if (source.character == EOF) { error("corresponding */ not found"); }
                nextChar();     // get rid of *
                nextChar();     // get rid of /
            }
            // nested comment
            else if (source.lookahead() == '+') {
                nextChar(); // get rid of /
                nextChar(); // get rid of +
                size_t comment_depth = 1;
                while (comment_depth > 0 && source.character != EOF) {
                    auto c_c = source.character, n_c = source.lookahead;
                    if      (c_c == '+' && n_c == '/') {
                        --comment_depth;
                        nextChar();     // get rid of +
                        nextChar();     // get rid of /
                    }
                    else if (c_c == '/' && n_c == '+') {
                        ++comment_depth;
                        nextChar();     // get rid of /
                        nextChar();     // get rid of +
                    }
                    else nextChar();
                }
            }
            else break;
        }

        token.loc.line_num  = source.line_num;
        token.loc.index_num = source.index_num;

        immutable(dchar)[] str;
        // identifier of reserved words
        with (TokenType)
        if (source.character.isAlpha() || source.character == '_') {
            while (source.character.isAlphaNum() || source.character == '_') {
                str ~= source.character;
                nextChar();
            }
            switch (str) {
                case "true":            token.tt = true_;           break;
                case "false":           token.tt = false_;          break;
                case "null":            token.tt = null_;           break;
                case "this":            token.tt = this_;           break;
                case "super":           token.tt = super_;          break;
                case "_":               token.tt = any;             break;
                case "int32":           token.tt = int32;           break;
                case "uint32":          token.tt = uint32;          break;
                case "int64":           token.tt = int64;           break;
                case "uint64":          token.tt = uint64;          break;
                case "real32":          token.tt = real32;          break;
                case "real64":          token.tt = real64;          break;
                case "bool":            token.tt = bool_;           break;
                case "unit":            token.tt = unit;            break;
                case "string":          token.tt = string_;         break;
                case "char":            token.tt = char_;           break;
                case "struct":          token.tt = struct_;         break;
                case "union":           token.tt = union_;          break;
                case "class":           token.tt = class_;          break;
                case "interface":       token.tt = interface_;      break;
                case "template":        token.tt = template_;       break;
                case "mixin":           token.tt = mixin_;          break;
                case "immut":           token.tt = immut;           break;
                case "const":           token.tt = const_;          break;
                case "inout":           token.tt = inout_;          break;
                case "ref":             token.tt = ref_;            break;
                case "private":         token.tt = private_;        break;
                case "protected":       token.tt = protected_;      break;
                case "package":         token.tt = package_;        break;
                case "public":          token.tt = public_;         break;
                case "export":          token.tt = export_;         break;
                case "abstract":        token.tt = abstract_;       break;
                case "override":        token.tt = override_;       break;
                case "final":           token.tt = final_;          break;
                case "static":          token.tt = static_;         break;
                case "deprecated":      token.tt = deprecated_;     break;
                case "typeid":          token.tt = typeid_;         break;
                case "typeof":          token.tt = typeof_;         break;
                case "if":              token.tt = if_;             break;
                case "else":            token.tt = else_;           break;
                case "for":             token.tt = for_;            break;
                case "while":           token.tt = while_;          break;
                case "foreach":         token.tt = foreach_;        break;
                case "foreach_reverse": token.tt = foreach_reverse_;break;
                case "do":              token.tt = do_;             break;
                case "break":           token.tt = break_;          break;
                case "continue":        token.tt = continue_;       break;
                case "return":          token.tt = return_;         break;
                case "goto":            token.tt = goto_;           break;
                case "assert":          token.tt = assert_;         break;
                case "match":           token.tt = match;           break;
                case "app":             token.tt = app;             break;
                case "or":              token.tt = or;              break;
                case "and":             token.tt = and;             break;
                case "not":             token.tt = not;             break;
                case "in":              token.tt = in_;             break;
                case "is":              token.tt = is_;             break;
                default:                token.tt = identifier;      break;
            }
            if (!allow_2_underbars && str.length >= 2 && str[0] == '_' && str[1] == '_') {
                message.error("An identifier starting with two underbars ", str.to!string, " is not allowed. '__' is  rewritten to '_0_'.");
                str = "_0_" ~ str[2..$];
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
                token.tt = real_number;
                while (source.character.among!(aliasSeqOf!"0123456789abcdefABCDEF_")) {
                    str ~= source.character;
                    nextChar();
                }
            }
            else {
                token.tt = integer;
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
                token.tt = real_number;
                while (source.character.among!(aliasSeqOf!"01_")) {
                    str ~= source.character;
                    nextChar();
                }
            }
            else {
                token.tt = integer;
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
                token.tt = real_number;
                while (source.character.among!(aliasSeqOf!"0123456789_")) {
                    str ~= source.character;
                    nextChar();
                }
            }
            else {
                token.tt = integer;
            }
        }
        // strings
        else if (source.character == '"') {
            token.tt = string_literal;
            nextChar(); // get rid of "
            while (!source.character.among!('"', EOF)) {
                if (source.character == '\\') {
                    nextChar();     // get rid of \
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
                            message.error("Invalid escape sequence \\",
                                source.character == EOF ? "EOF" : source.character.to!string);
                            break;
                    }
                    nextChar();     // get rid of the escape sequence
                }
                str ~= source.character;
                nextChar();
            }
            nextChar();
        }
        // symbols
        else if (source.character == '!') {
            nextChar();     // get rid of !
            auto c = source.character;
            if      (c == '=') {
                nextChar();     // get rid of =
                token.tt = neq;
                str = "!=";
            }
            else if (c == '[') {
                nextChar();     // get rid of [
                token.tt = indexing;
                str = "![";
            }
            else {
                token.tt = deref;
                str = "!";
            }
        }
        else if (source.character == '#') {
            nextChar();     // get rid of #
            token.tt = ref_of;
            str = "#";
        }
        else if (source.character == '$') {
            nextChar();     // get rid of $
            token.tt = dollar;
            str = "$";
        }
        else if (source.character == '%') {
            nextChar();     // get rid of %
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = mod_ass;
                str = "%=";
            }
            else {
                token.tt = mod;
                str = "%";
            }
        }
        else if (source.character == '&') {
            nextChar();     // get rid of &
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = and_ass;
                str = "&=";
            }
            else if (source.character == '&') {
                nextChar();     // get rid of &
                token.tt = and;
                str = "&&";
            }
            else {
                token.tt = bit_and;
                str = "&";
            }
        }
        else if (source.character == '|') {
            nextChar();     // get rid of %
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = or_ass;
                str = "|=";
            }
            else if (source.character == '|') {
                nextChar();     // get rid of |
                token.tt = or;
                str = "||";
            }
            else {
                token.tt = bit_or;
                str = "|";
            }
        }
        else if (source.character == '^') {
            nextChar();     // get rid of ^
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = xor_ass;
                str = "^=";
            }
            else if (source.character == '^') {
                nextChar();     // get rid of ^
                if (source.character == '=') {
                    nextChar();
                    token.tt = pow_ass;
                    str = "^^=";
                }
                else {
                    token.tt = pow;
                    str = "^^";
                }
            }
            else {
                token.tt = bit_xor;
                str = "^";
            }
        }
        else if (source.character == '~') {
            nextChar();     // get rid of ~
            if (
                source.character == 'i'
             && source.lookahead(1) == 's'
             && !(source.lookahead(2).isAlphaNum() || source.lookahead(2) == '_')
            ) {
                nextChar();     // get rid of i
                nextChar();     // get rid of s
                token.tt = nis;
                str = "~is";
            }
            else if (
                source.character == 'i'
             && source.lookahead(1) == 'n'
             && !(source.lookahead(2).isAlphaNum() || source.lookahead(2) == '_')
            ) {
                nextChar();     // get rid of i
                nextChar();     // get rid of n
                token.tt = nin;
                str = "~in";
            }
            else {
                token.tt = not;
                str = "~";
            }
        }
        else if (source.character == '(') {
            nextChar();     // get rid of (
            token.tt = lparen;
            str = "(";
        }
        else if (source.character == ')') {
            nextChar();     // get rid of )
            token.tt = rparen;
            str = ")";
        }
        else if (source.character == '{') {
            nextChar();     // get rid of {
            token.tt = lbrace;
            str = "{";
        }
        else if (source.character == '}') {
            nextChar();     // get rid of }
            token.tt = rparen;
            str = "}";
        }
        else if (source.character == '[') {
            nextChar();     // get rid of [
            token.tt = lbracket;
            str = "[";
        }
        else if (source.character == ']') {
            nextChar();     // get rid of ]
            token.tt = rbracket;
            str = "]";
        }
        else if (source.character == '*') {
            nextChar();     // get rid of *
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = mul_ass;
                str = "*=";
            }
            else {
                token.tt = mul;
                str = "*";
            }
        }
        else if (source.character == '+') {
            nextChar();     // get rid of +
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = add_ass;
                str = "+=";
            }
            else if (source.character == '+') {
                nextChar();     // get rid of +
                if (source.character == '=') {
                    nextChar();     // get rid of =
                    token.tt = cat_ass;
                    str = "++=";
                }
                else {
                    token.tt = cat;
                    str = "++";
                }
            }
            else {
                token.tt = add;
                str = "+";
            }
        }
        else if (source.character == '/') {
            nextChar();     // get rid of /
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = div_ass;
                str = "/=";
            }
            else {
                token.tt = div;
                str = "/";
            }
        }
        else if (source.character == '-') {
            nextChar();     // get rid of -
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = sub_ass;
                str = "-=";
            }
            else if (source.character == '-') {
                nextChar();     // get rid of -
                token.tt = minus;
                str = "--";
            }
            else if (source.character == '>') {
                nextChar();     // get rid of >
                token.tt = right_arrow;
                str = "->";
            }
            else {
                token.tt = sub;
                str = "-";
            }
        }
        else if (source.character == ',') {
            nextChar();     // get rid of ,
            token.tt = comma;
            str = ",";
        }
        else if (source.character == '.') {
            nextChar();     // get rid of .
            if (source.character == '.') {
                nextChar();     // get rid of .
                token.tt = dotdot;
                str = "..";
            }
            else {
                token.tt = dot;
                str = ".";
            }
        }
        else if (source.character == ':') {
            nextChar();     // get rid of :
            if (source.character == ':') {
                nextChar();     // get rid of :
                token.tt = ti_type;
                str = "::";
            }
            else if (source.character == ';') {
                nextChar();     // get rid of ;
                token.tt = ti_expr;
                str = ":;";
            }
            else {
                token.tt = colon;
                str = ":";
            }
        }
        else if (source.character == ';') {
            nextChar();     // get rid of ;
            token.tt = colon;
            str = ":";
        }
        else if (source.character == '<') {
            nextChar();     // get rid <
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = leq;
                str = "<=";
            }
            else if (source.character == '<') {
                nextChar();     // get rid of <
                token.tt = rshift;
                str = "<<";
            }
            else {
                token.tt = ls;
                str = "<";
            }
        }
        else if (source.character == '>') {
            nextChar();     // get rid >
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = geq;
                str = ">=";
            }
            else if (source.character == '>') {
                nextChar();     // get rid of <
                if (source.character == '>') {
                    token.tt = logical_shift;
                    str = ">>>";
                }
                else {
                    token.tt = lshift;
                    str = "<<";
                }
            }
            else {
                token.tt = gt;
                str = "<";
            }
        }
        else if (source.character == '=') {
            nextChar();     // get rid of =
            if (source.character == '=') {
                nextChar();     // get rid of =
                token.tt = eq;
                str = "==";
            }
            if (source.character == '>') {
                nextChar();     // get rid of >
                token.tt = pipeline;
                str = "=>";
            }
            else {
                token.tt = ass;
                str = "=";
            }
        }
        else if (source.character == '@') {
            nextChar();     // get rid of @
            token.tt = composition;
            str = "@";
        }
        else if (source.character == '\\') {
            nextChar();     // get rid of \
            token.tt = lambda;
            str = "\\";
        }
        else if (source.character == EOF) {
            token.tt = end_of_file;
            str = "EOF";
        }
        else {
            message.error("Invalid token : ", source.character.to!string);
            nextChar();
        }

        token.str = str.to!string;
    }
}

unittest {
    import std.stdio;
    auto lx = new Lexer!(string)(`
    /*/ comment /*/
    /+/ /++/ +/
    id /*01234 009_124*/ 0xFFf 0x0.aF_f
    =+=-=*=/=%=++=$=^=|=~~^^^^==>&&&|||&&
    ~in ~is ~in3_set ~is_odd![3..$ 4 ..
    `);
    while (lx.token.tt != TokenType.end_of_file) {
        writeln(lx.token.tt, "\t", lx.token.str, "\t//\t", lx.token.loc.line_num, ":", lx.token.loc.index_num);
        lx.nextToken();
    }
}
