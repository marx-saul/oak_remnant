module ast.attribute;

import token;
import ast.expression;
import ast.module_;
import ast.symbol;

enum PRLV : ubyte {
	undefined,
	private_,
	package_,
	package_specified,
	public_,
	export_,
	protected_,
}

enum STC : ulong {
	undefined		= 0,
	// type qualifier
	immut			= 1UL >> 1,
	const_			= 1UL >> 2,
	inout_			= 1UL >> 3,
	shared_			= 1UL >> 4,
	lazy_			= 1UL >> 5,
	ref_			= 1UL >> 6,
	out_			= 1UL >> 7,
	scope_			= 1UL >> 8,
	return_			= 1UL >> 9,
	
	// function property
	throwable		= 1UL >> 10,
	pure_			= 1UL >> 11,
	ctfe			= 1UL >> 12,
	system			= 1UL >> 13,
	trusted			= 1UL >> 14,
	safe			= 1UL >> 15,
	disable			= 1UL >> 16,
	
	final_			= 1UL >> 17,
	abstract_		= 1UL >> 18,
	override_		= 1UL >> 19,
	
	static_			= 1UL >> 20,
	deprecated_		= 1UL >> 21,
	extern_			= 1UL >> 22,	
}

alias StorageClass = ulong;

static immutable STC[ubyte.max] TokenKindToSTC = [
	TokenKind.immut:		STC.immut,
	TokenKind.const_:		STC.const_,
	TokenKind.inout_:		STC.inout_,
	TokenKind.shared_:		STC.shared_,
	TokenKind.lazy_:		STC.lazy_,
	TokenKind.ref_:			STC.ref_,
	TokenKind.out_:			STC.out_,
	TokenKind.scope_:		STC.scope_,
	TokenKind.return_:		STC.return_,
	TokenKind.throwable:	STC.throwable,
	TokenKind.pure_:		STC.pure_,
	TokenKind.final_:		STC.final_,
	TokenKind.abstract_:	STC.abstract_,
	TokenKind.override_:	STC.override_,
	TokenKind.static_:		STC.static_,
	TokenKind.deprecated_:	STC.deprecated_,
	TokenKind.extern_:		STC.extern_,
];

/// the root of attribution class
abstract class Attribution {
	inout const @nogc @property {
		/+
		inout(STCAttribution) isSTC() { return null; }
		inout(ProtAttribution) isProt() { return null; }
		+/
		inout(PackageSpecifiedAttribution) isPkgSpec() { return null; }
		inout(DeprecationAttribution) isDeprecation() { return null; }
		inout(UserDefinedAttribution) isUDA() { return null; }
	}
}
/+
/// representing StorageClass
final class STCAttribution : Attribution {
	StorageClass stc;
	this (StorageClass stc) {
		this.stc = stc;
	}
	override inout(STCAttribution) isSTC() inout const @nogc @property { return cast(inout) this; }
}

/// private/package/public/export/protected
final class ProtAttribution : Attribution {
	PRLV prlv;
	this (PRLV prlv) {
		this.prlv = prlv;
	}
	override inout(ProtAttribution) isProt() inout const @nogc @property { return cast(inout) this; }
}
+/
/// package(...)
final class PackageSpecifiedAttribution : Attribution {
	Identifier[] pkgname;
	Package _pkg = null;
	Package pkg(Package root) @property {
		if (_pkg) return _pkg;
		else assert(0);
	}
	this (Identifier[] pkgname) {
		this.pkgname = pkgname;
	}
	override inout(PackageSpecifiedAttribution) isPkgSpec() inout const @nogc @property { return cast(inout) this; }
}

/// deprecated("...")
final class DeprecationAttribution : Attribution {
	Expression exp;		// deprecation message
	this (Expression exp) {
		this.exp = exp;
	}
	override inout(DeprecationAttribution) isDeprecation() inout const @nogc @property { return cast(inout) this; }
}

/// @(...)
final class UserDefinedAttribution  : Attribution {
	Expression[] exps;
	this (Expression[] exps) {
		this.exps = exps;
	}
	override inout(UserDefinedAttribution) isUDA() inout const @nogc @property { return cast(inout) this; }
}