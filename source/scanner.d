module scanner;

import std.algorithm, std.path, std.file;
import std.stdio, std.exception, std.array;
import std.utf, std.stdio, std.string;

import dstringutils;

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
struct Scanner
{
	// This is a very naive algorithm that is hard coded in some areas but works for my particular commenting style.
	void scanFile(const DirEntry entry)
	{
		immutable string fileExtension = entry.name.baseName.extension.removeChars(".");

		if(fileExtension == "d")
		{
			immutable string name = buildNormalizedPath(entry.name);
			immutable string text = readText(name).ifThrown!UTFException("");
			immutable auto lines = text.lineSplitter().array;
			auto output = appender!string;

			bool inCommentBlock, params, inFunctionDoc;

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
						}
					}
					else if(inCommentBlock)
					{
						string description = lines[i];

						if(!description.canFind(":") && !params && !inFunctionDoc)
						{
							output.put(description ~= "\n");
						}

						if(line.canFind("Params:"))
						{
							params = true;
						}

						if(line.canFind("Return:"))
						{
							inFunctionDoc = true;
						}

						if(params == true && !line.canFind("Returns:"))
						{
							if(!line.canFind("Params:"))
							{
								string finalParamStr = "@param " ~ line ~ "\n";
								output.put(finalParamStr);
							}
						}

						if(inFunctionDoc && !line.canFind("Params:"))
						{
							if(!line.canFind("Params:"))
							{
								string finalParamStr = "\t@return " ~ line ~ "\n";
								output.put(finalParamStr);
							}
						}

						if(line.canFind("Returns:"))
						{
							inFunctionDoc = true;
							params = false;
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
