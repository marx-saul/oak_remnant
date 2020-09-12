module test.type;

import std.stdio;
import parser, ast.ast_tostring, semantic.set_scope, semantic.type, semantic.symbolsem;

unittest {
	writeln("##### typedef unittest #####");
	/+
	{
		auto parser = new Parser!string(`
		module main;
		
		import foo, foo.bar.baz, qux = quux.corge, grault.garply, grault.garply.waldo, fred.plugh : xyzzy, thud;
		
		let x: int32;
		let msg: string = "hello world";
		
		struct Vector3 {
			let x: real32;
			let y: real32;
			let z: real32;
		}
		typedef Vec3 = Vector3;
		
		struct MyStr {
			let i: int64;
			struct Inner {
				func succ:uint64 = i+1;
				let i: uint64;
				struct InnerInner {
					func pred:int64 = MyStr.i-1;
				}
			}
		}
		
		func vector3:Vector3 x:real32 y:real32 z:real32 {
			let result: Vector3;
			result.x = x;
			result.y = y;
			result.z = z;
			return result;
		}
		
		func add:Vector3 v:Vector3 w:Vector3 {
			func inner:unit _:unit {}
			let result: Vector3;
			result.x = v.x + w.x;
			result.y = v.y + w.y;
			result.z = v.z + w.z;
			return result;
		}
		
		func main {
			writeln app add (vector3 3.2 4.8 --1.2) ((vector3 0.8 1.5 2.3));
		}
		`);
		
		auto mod = parser.parse();
		
		// set scope
		setScope(mod);
		assert(mod.semsc);
		writeln();
		
		// symbol sem
		symbolSem(mod);
		
	}
	+/
}