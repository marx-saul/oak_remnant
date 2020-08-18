/**
 * token.d
 * Define tokens.
 */
module token;

/**
 * The location of a token.
 */
struct Location {
    size_t line_num;
    size_t index_num;
    string path;
	
	string toString() {
		import std.conv: to;
		return "\x1b[1m" ~ path ~ "(" ~ line_num.to!string ~ ":" ~ index_num.to!string ~ ")\x1b[0m";
	}
}

/**
 * Enum of the types of all tokens.
 * TokenKind.apply does not appear in oak source codes, it is used for function application.
 */
enum TokenKind : ubyte {
    error = 0,
    identifier,
    integer,
    real_number,
    string_literal,
    true_,
    false_,
    null_,
    this_,
    super_,
    any,
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
    module_,
    import_,
    let,
    func,
    typedef,
    struct_,
    union_,
    class_,
    interface_,
    template_,
    mixin_,
    immut,
    const_,
    inout_,
    ref_,
    private_,
    protected_,
    package_,
    public_,
    export_,
    abstract_,
    override_,
    final_,
    static_,
    deprecated_,
    //safe,		   trusted,		system,	   pure_,		  throwable,
    typeid_,	
    typeof_,
    if_,
    else_,
    for_,
    while_,
    foreach_,
    foreach_reverse_,
    do_,
    break_,
    continue_,
    return_,
    goto_,
    assert_,
    as,
    when,
    ass,            // =
    add_ass,        // +=
    sub_ass,        // -=
    cat_ass,        // ++=
    mul_ass,        // *=
    div_ass,        // /=
    mod_ass,        // %=
    pow_ass,        // **=
    and_ass,        // &=
    xor_ass,        // ^=
    or_ass,         // |=
    match,
    pipeline,	    // =>
    app,		    // app
    or,			    // or  ||
    xor,		    // xor ^^
    and,		    // and &&
    bit_or,		    // |
    bit_xor,	    // ^
    bit_and,	    // &
    eq,             // ==
    neq,            // !=
    ls,             // <
    gt,             // >
    leq,            // <=
    geq,            // >=
    in_,            // in
    nin,            // !in
    is_,            // is
    nis,		    // !is
    lshift,         // <<
    rshift,         // >>
    logical_shift,  // >>>
    add, sub, cat,	// + - ++
    mul, div, mod,	// * / %
    minus,          // --
    not,            // ~
    ref_of,         // #
    deref,          // !
    pow,			// **
    apply,  		// function application
    indexing,       // ![
    dotdot,         // ..
    composition,	// @
    dot,			// .
    new_,
    temp_inst,		// template instanciation ?
    global,			// _.
    lparen,         // (
    rparen,         // )
    lbracket,       // [
    rbracket,       // ]
    lbrace,         // {
    rbrace,         // }
    ebrace,			// e{
    dollar,         // $
    lambda,         // \
    semicolon,      // ;
    colon,          // :
    comma,          // ,
    right_arrow,    // ->

    end_of_file,
}

immutable string[TokenKind.max+1] token_dictionary = [
    TokenKind.identifier: "identifier",
    TokenKind.integer: "integer",
    TokenKind.real_number: "real number",
    TokenKind.string_literal: "string literal",
    TokenKind.true_: "true",
    TokenKind.false_: "false",
    TokenKind.null_: "null",
    TokenKind.this_: "this",
    TokenKind.super_: "super",
    TokenKind.any: "_",
    TokenKind.int32: "int32",
    TokenKind.uint32: "uint32",
    TokenKind.int64: "int64",
    TokenKind.uint64: "uint64",
    TokenKind.real32: "real32",
    TokenKind.real64: "real64",
    TokenKind.bool_: "bool",
    TokenKind.unit: "unit",
    TokenKind.string_: "string",
    TokenKind.char_: "char",
    TokenKind.module_: "module",
    TokenKind.import_: "import",
    TokenKind.let: "let",
    TokenKind.func: "func",
    TokenKind.typedef: "typedef",
    TokenKind.struct_: "struct",
    TokenKind.union_:"union",
    TokenKind.class_: "class",
    TokenKind.interface_: "interface",
    TokenKind.template_: "template",
    TokenKind.mixin_: "mixin",
    TokenKind.immut: "immut",
    TokenKind.const_: "const",
    TokenKind.inout_: "inout",
    TokenKind.ref_: "ref",
    TokenKind.private_: "private",
    TokenKind.protected_: "protected",
    TokenKind.package_: "package",
    TokenKind.public_: "public",
    TokenKind.export_: "export",
    TokenKind.abstract_: "abstract",
    TokenKind.override_: "override_",
    TokenKind.final_: "final",
    TokenKind.static_: "static",
    TokenKind.deprecated_: "deprecated",
    //safe,		   trusted,		system,	   pure_,		  throwable,
    TokenKind.typeid_: "typeid",
    TokenKind.typeof_: "typeof",
    TokenKind.if_: "if",
    TokenKind.else_: "else",
    TokenKind.for_:                 "for",
    TokenKind.while_:               "while",
    TokenKind.foreach_:             "foreach",
    TokenKind.foreach_reverse_:     "foreach_reverse",
    TokenKind.do_:                  "do",
    TokenKind.break_:               "break",
    TokenKind.continue_:            "continue",
    TokenKind.return_:              "return",
    TokenKind.goto_:                "goto",
    TokenKind.assert_:              "assert",
    TokenKind.as:                   "as",
    TokenKind.when:                 "when",
    TokenKind.ass: "=",
    TokenKind.add_ass: "+=",
    TokenKind.sub_ass: "-=",
    TokenKind.cat_ass:"++=",
    TokenKind.mul_ass: "*=",
    TokenKind.div_ass: "/=",
    TokenKind.mod_ass: "%=",
    TokenKind.pow_ass: "**=",
    TokenKind.and_ass: "&=",
    TokenKind.xor_ass: "^=",
    TokenKind.or_ass: "|=",
    TokenKind.match: "match",
    TokenKind.pipeline: "=>",
    TokenKind.app: "app",
    TokenKind.and: "&&",
    TokenKind.xor: "^^",
    TokenKind.or: "||",
    TokenKind.bit_or: "|",
    TokenKind.bit_xor: "^",
    TokenKind.bit_and: "&",
    TokenKind.eq: "==",
    TokenKind.neq: "!=", TokenKind.ls: "<", TokenKind.gt: ">", TokenKind.leq: "<=",
    TokenKind.geq: ">=", TokenKind.in_: "in", TokenKind.nin: "!in", TokenKind.is_: "is", TokenKind.nis: "!is",
    TokenKind.lshift: "<<", TokenKind.rshift: ">>", TokenKind.logical_shift: ">>>",
    TokenKind.add: "+", TokenKind.sub: "-", TokenKind.cat: "++", TokenKind.mul: "*", TokenKind.div: "/", TokenKind.mod: "%",
    TokenKind.minus: "--", TokenKind.not: "~", TokenKind.ref_of: "#", TokenKind.deref: "!",
    TokenKind.pow: "**", TokenKind.apply: "", TokenKind.indexing: "![", TokenKind.dotdot: "..",
    TokenKind.composition: "@", TokenKind.dot: ".", TokenKind.new_: "new", TokenKind.temp_inst: "?", TokenKind.global: "_.",
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
