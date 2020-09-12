module test.whole;

// test the whole phase
unittest {
	import std.stdio;
	import ast.ast_tostring, ast.module_, semantic.set_scope, semantic.symbolsem;
	writeln("##### whole unittest #####");
	
	scope root = Package.createRoot();
	
	auto main = Module.parse(`
		module main;
		
		import pkg.foo;
		import circ.baz;
		
		struct MySmain {
			import public pkg.bar, pkg.foo;
			func yyy {}
		}
		
		func main {}
	`, "main.oak", root);
	symbolSem(main);
	
	auto pkg_foo = Module.parse(`
		module pkg.foo;
		
		let aaa : int32;
		let bbb : int32;
		let private static ccc : int32;
		let package ddd : int32;
	`, "pkg/foo.oak", root);
	symbolSem(pkg_foo);
	
	auto pkg_bar = Module.parse(`
		module pkg.bar;
		
		let xxx : int32;
		let yyy : int32;
		let aaa : int32;
		let ccc : int32;
		let public ddd : int32;
	`, "pkg/bar.oak", root);
	symbolSem(pkg_bar);
	
	auto circ_baz = Module.parse(`
		module circ.baz;
		import public circ.qux;
		let baz1 : int32;
		let baz2 : int32;
		let baz3 : int32;
		let not_conflict : int32;
	`, "circ/baz.oak", root);
	symbolSem(circ_baz);
	
	auto circ_qux = Module.parse(`
		module circ.qux;
		import public circ.quux;
		let qux1 : int32;
		let qux2 : int32;
		let qux3 : int32;
		let not_conflict : int32;
		let conflict : int32;
	`, "circ/qux.oak", root);
	symbolSem(circ_qux);
	
	auto circ_quux = Module.parse(`
		module circ.quux;
		import public circ.baz;
		let quux1 : int32;
		let quux2 : int32;
		let quux3 : int32;
		let conflict : int32;
	`, "circ/quux.oak", root);
	symbolSem(circ_quux);
	
	{
		scope main_main = main.semsc.lookup("main", root)[0].isScopeSymbol;
		scope main_MySmain = main.semsc.lookup("MySmain", root)[0].isScopeSymbol;
		writeln(main_MySmain.semsc.rootModule);
		
		// access 'main.MySmain.xxx' from the scope of the function 'main.main'
		{
			write("main.MySmain.xxx : ");
			scope syms = main_main.semsc.access(main_MySmain, "xxx", root);
			writeln("found ", syms.length, " ", syms[0].loc);
		}
		// access 'main.MySmain.yyy' from the scope of the function 'main.main'
		{
			write("main.MySmain.yyy : ");
			scope syms = main_main.semsc.access(main_MySmain, "yyy", root);
			writeln("found ", syms.length, " ", syms[0].loc);
		}
		// access 'main.MySmain.aaa' from the scope of the function 'main.main'
		{
			write("main.MySmain.aaa : ");
			scope syms = main_main.semsc.access(main_MySmain, "aaa", root);
			writeln("found ", syms.length, " ", syms[0].loc, ", ", syms[1].loc);
		}
		// access 'main.MySmain.bbb' from the scope of the function 'main.main'
		{
			write("main.MySmain.bbb : ");
			scope syms = main_main.semsc.access(main_MySmain, "bbb", root);
			writeln("found ", syms.length, " ", syms[0].loc);
		}
		// access 'main.MySmain.ccc' from the scope of the function 'main.main'
		{
			write("main.MySmain.ccc : ");
			scope syms = main_main.semsc.access(main_MySmain, "ccc", root);
			writeln("found ", syms.length, " ", syms[0].loc);
		}
		// access 'main.MySmain.ddd' from the scope of the function 'main.main'
		{
			write("main.MySmain.ddd : ");
			scope syms = main_main.semsc.access(main_MySmain, "ddd", root);
			writeln("found ", syms.length, " ", syms[0].loc);
		}
	}
	
	// lookup "aaa" from the scope 'main'
	{
		write("lookup \"aaa\" from 'main' ");
		scope syms = main.semsc.lookup("aaa", root);
		writeln("found ", syms.length, " ", syms[0].loc);
	}
	// lookup "ccc" from the scope 'main'
	{
		write("lookup \"ccc\" from 'main' ");
		scope syms = main.semsc.lookup("ccc", root);
		writeln("found ", syms.length);
	}
	// lookup "ddd" from the scope 'main'
	{
		write("lookup \"ddd\" from 'main' ");
		scope syms = main.semsc.lookup("ddd", root);
		writeln("found ", syms.length);
	}
	// lookup "quux1" from the scope 'main'
	{
		write("lookup \"quux1\" from 'main' ");
		scope syms = main.semsc.lookup("quux1", root);
		writeln("found ", syms.length, " ", syms[0].loc);
	}
	// lookup "not_found" from the scope 'main'
	{
		write("lookup \"not_found\" from 'main' ");
		scope syms = main.semsc.lookup("not_found", root);
		writeln("found ", syms.length);
	}
	// lookup "not_conflict" from the scope 'main'
	{
		write("lookup \"not_conflict\" from 'main' ");
		scope syms = main.semsc.lookup("not_conflict", root);
		writeln("found ", syms.length, " ", syms[0].loc);
	}
	// lookup "conflict" from the scope 'main'
	{
		write("lookup \"conflict\" from 'main' ");
		scope syms = main.semsc.lookup("conflict", root);
		writeln("found ", syms.length);
	}
}