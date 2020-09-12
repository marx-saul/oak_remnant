module test.set_scope;


unittest {
	import std.stdio;
	import parser, ast.ast_tostring, semantic.set_scope, semantic.symbolsem;
	writeln("##### set_scope unittest #####");
	
	{
		auto _parser = new Parser!string(`
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
			writeln app add (3.2, 4.8, --1.2) as Vector3 (0.8, 1.5, 2.3) as Vector3;
		}
		`);
		
		auto mod = _parser.parse();
		
		// set scope
		setScope(mod);
		assert(mod.semsc);
		writeln();
		symbolSem(mod);
		
		void search(string name) {
			auto sym = mod.semsc.search(name);
			if (sym is null) {
				writeln(name, " : NOT FOUND");
			}
			else {
				writeln(name, " : ", sym.id.loc);
			}
		}
		
		search("MyStr");
		search("foo");
		search("xyzzy");
		search("qux");
		search("quux");
		search("fred");
		
		{
			auto sym = mod.semsc.accessImportedModule(["grault", "garply", "waldo", "aaaa"]);
			if (sym is null) {
				writeln("NOT FOUND");
			}
			else {
				writeln("FOUND ", sym.modname.length);
			}
			writeln();
		}
		{
			auto sym = mod.semsc.accessImportedModule(["grault", "garply", "aaaa"]);
			if (sym is null) {
				writeln("NOT FOUND");
			}
			else {
				writeln("FOUND ", sym.modname.length);
			}
			writeln();
		}
		{
			auto sym = mod.semsc.accessImportedModule(["fred", "plugh"]);
			if (sym is null) {
				writeln("NOT FOUND");
			}
			else {
				writeln("FOUND ", sym.modname.length);
			}
			writeln();
		}/+
		{
			size_t num;
			auto sym = mod.semsc.access(["MyStr", "Inner", "InnerInner"], num);
			if (sym is null) {
				writeln("NOT FOUND");
			}
			else {
				writeln("FOUND ", num);
			}
			writeln();
		}
		+/
	}	
}
