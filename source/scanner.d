module scanner;

import std.algorithm, std.path, std.file;
import std.stdio, std.exception, std.array;
import std.utf, std.stdio, std.string;
import std.regex, std.uni, std.conv;

enum MultiLineCommentType
{
	None,
	Open,
	Close,
	OpenAndClose
}

MultiLineCommentType isMultiLineComment(const string line)
{
	immutable string commentOpen = "/*";
	immutable string commentClose = "*/";

	if(line.startsWith(commentOpen) && line.canFind(commentClose))
	{
		return MultiLineCommentType.OpenAndClose;
	}

	if(line.startsWith(commentOpen))
	{
		return MultiLineCommentType.Open;
	}

	if(line.startsWith(commentClose))
	{
		return MultiLineCommentType.Close;
	}

	return MultiLineCommentType.None;
}

/**
	Just a comment block for testing.
	This is some continued text

	Params:
		foo = this is some bar text.
		bar = this is some foo text.

	Returns:
		This can't return anything.
*/
string testFunc(string foo, string bar)
{
	return string.init;
}

struct Scanner
{

	string createFuncStr(const string line)
	{
		auto r = regex(r"(\w+)[(](.*)[)]");
		auto output = appender!string;

		auto matches = matchFirst(line, r);
		immutable string funcName = matches[1];
		immutable string funcArgs = matches[2];
		immutable string funcNameCapitalized = funcName[0].toUpper.to!string ~ funcName[1..$];
		auto funcArgsSplit = funcArgs.splitter(",");
		string argNameTemp;


		output.put("function ");
		output.put(funcNameCapitalized);
		output.put("(");

		foreach(arg; funcArgsSplit)
		{
			auto argSplit = arg.splitter(" ").array;
			string argName = argSplit[argSplit.length - 1] ~ ", ";

			argNameTemp ~= argName;
		}

		if(argNameTemp.length > 0)
		{
			output.put(argNameTemp[0..$ - 2]); //FIXME: Doesn't take no arguments or one into account.
		}

		output.put(")\nend");

		return output.data;
	}

	// This is a very naive algorithm that is hard coded in some areas but works for my particular commenting style.
	void scanFile(const DirEntry entry)
	{
		immutable string fileExtension = entry.name.baseName.extension;

		if(fileExtension == ".d")
		{
			immutable string name = buildNormalizedPath(entry.name);
			immutable string text = readText(name).ifThrown!UTFException("");
			immutable auto lines = text.lineSplitter().array;
			auto output = appender!string;

			bool inCommentBlock, inParamsDoc, inFunctionDoc;

			foreach(i, rawLine; lines)
			{
				string line = rawLine.strip.chompPrefix("\t");

				if(!line.empty)
				{
					if(auto commentType = isMultiLineComment(line))
					{
						if(commentType == MultiLineCommentType.Open)
						{
							output.put("--[[--\n");
							inCommentBlock = true;
						}

						if(commentType == MultiLineCommentType.Close)
						{
							output.put("--]]\n");
							inCommentBlock = false;
							output.put(createFuncStr(lines[i + 1]));
							output.put("\n");
						}
					}
					else if(inCommentBlock)
					{
						string description = lines[i];

						if(!description.canFind(":") && !inParamsDoc && !inFunctionDoc)
						{
							output.put(description ~= "\n");
						}

						if(line.canFind("Params:"))
						{
							inParamsDoc = true;
						}

						if(line.canFind("Return:"))
						{
							inFunctionDoc = true;
						}

						if(inParamsDoc && !line.canFind("Returns:"))
						{
							if(!line.canFind("Params:"))
							{
								string finalParamStr = "\t@param " ~ line ~ "\n";
								output.put(finalParamStr);
							}
						}

						if(inFunctionDoc && !line.canFind("Params:"))
						{
							if(!line.canFind("Returns:"))
							{
								string finalParamStr = "\t@return " ~ line ~ "\n";
								output.put(finalParamStr);
							}
						}

						if(line.canFind("Returns:"))
						{
							inFunctionDoc = true;
							inParamsDoc = false;
						}
					}
					else
					{
					}
				}
			}
			writeln(output.data);
		}

	}

	void scanFiles()
	{
		getcwd.dirEntries("*.d", SpanMode.depth)
			.each!(entry => scanFile(entry));
	}
}
