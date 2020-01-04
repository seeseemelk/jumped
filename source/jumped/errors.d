module jumped.errors;

import std.array;

/// Prints a message to the terminal during cocmpilation.
template PrintCompileMessage(string title, string message)
{
	static immutable border = "==========";
	static immutable titleLine = border ~ " " ~ title ~ " " ~ border;
	pragma(msg, titleLine);
	pragma(msg, title ~ ": " ~ message);
	pragma(msg, "=".replicate(titleLine.length));
	static immutable PrintCompileMessage = message;
}

/// Prints an error message to the terminal during compilation.
template PrintCompileError(string message)
{
	alias PrintCompilerError = PrintCompileMessage!("Error", message);
}
