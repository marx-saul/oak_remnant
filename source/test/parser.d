module test.parser;

import std.stdio;
import parser, astbase_help;

unittest {
	writeln("##### parser unittest #####");
	
	{
		auto parser = new Parser!string(`
		v.x
		`);
		auto node = parser.parseExpression();
		node.to_string().writeln;
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
		
		let x: int32;
		let msg: string = "hello world";
		
		struct Vector3 {
			let x: real32;
			let y: real32;
			let z: real32;
		}
		
		func vector3:Vector3 x:real32 y:real32 z:real32 {
			let result: Vector3;
			result.x = x;
			result.y = y;
			result.z = z;
			return result;
		}
		
		func add:Vector3 v:Vector3 w:Vector3 {
			let result: Vector3;
			result.x = v.x + w.x;
			result.y = v.y + w.y;
			result.z = v.z + w.z;
			return result;
		}
		
		func main {
			writeln app add (vector3 3.2 4.8 -1.2) ((vector3 0.8 1.5 2.3));
		}
		`);
		auto node = parser.parse();
		node.to_string().writeln;
	}
	
}
