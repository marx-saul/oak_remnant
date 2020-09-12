module ast.file_system;

import lexer : isCharacterStream;

enum FileKind {
	unknown,
	oak,
	directory,
}

abstract class FileSymbol
{
	FileKind kind;
	string name;
	FileSymbol parent;
	FileSymbol[string] children;
}

/// a file module
abstract class ModuleFile(Range) : FileSymbol
	if (isCharacterStream!Range)
{
	Range content;
}

/// a directory
abstract class Directory(Range) : FileSymbol {}