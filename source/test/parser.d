module test.parser;

import std.stdio;
import parser, ast.ast_tostring;

unittest {
	writeln("##### parser unittest #####");
	
	{
		auto parser = new Parser!string(`
		v.x
		`);
		auto node = parser.parseExpression();
		node.to_string().writeln;
		writeln();
	}
	/+
	{
		auto parser = new Parser!string(`{
		let a = 10, msg: string, c: bool = true,;
		func add:int x:int y:int { return x+y; }
		func fact:uint x:uint =
			when x == 0 : 1 else x * fact(x-1);
		if a > b : return; else writeln;
		typedef MyInt = int;
		struct MyStruct {
			let a:int32;
			func succ:int32 = a+1;
			func pred:int32 _:unit = a-1;
		};
		while true : do {} while true;
		foreach i; 0 .. 10 : writeln i^^j&&k||l;
		}`);
		auto node = parser.parseStatement();
		node.to_string().writeln;
	}
	+/
	{
		auto parser = new Parser!string(`
		module main;
		
		import std.stdio, myfoo = foo.bar.baz.qux, quux.xyzzy : corge = grault, garply;
		
		func main {
			writeln app add (vector3 3.2 4.8 --1.2) ((vector3 0.8 1.5 2.3));
		}
		`);
		auto node = parser.parse();
		node.to_string().writeln;
		writeln();
	}
	
}
