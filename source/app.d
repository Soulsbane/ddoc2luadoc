import std.stdio;
import std.file;

import scanner;

void main(string[] args)
{
	const string[] arguments = args[1..$];
	Scanner scanner;

	if(arguments.length == 0)
	{
		scanner.scanFiles();
	}
	else if(arguments.length == 1)
	{
		immutable string pattern = arguments[0];
		scanner.scanFiles(pattern);
	}
	else if(arguments.length == 2)
	{
		immutable string input;
		immutable string output;

		if(input.exists)
		{
			scanner.scanFiles();
		}
	}
	else
	{
		writeln("An input and output file name must be supplied!");
		writeln("Usage: ddoc2luadoc input.d output.lua");
	}
}
