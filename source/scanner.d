module scanner;

import std.algorithm, std.path, std.file;
import std.stdio, std.exception, std.array;
import std.utf, std.stdio, std.string;

import dstringutils;

bool isHiddenFileOrDir(DirEntry entry)
{
	auto dirParts = entry.name.pathSplitter;

	foreach(dirPart; dirParts)
	{
		if(dirPart.startsWith("."))
		{
			return true;
		}
	}

	return false;
}

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
	Creates a todo file using the fileExt parameter in the filename.
	@param fileExt The file extension to use for the todo file.
	@return A file handle to the created todo file and the constructed todo filename string.
*/
struct Scanner
{
	void parseLine(const string line){}
	void scanFile(const DirEntry entry)
	{
		immutable string fileExtension = entry.name.baseName.extension.removeChars(".");

		if(fileExtension == "d")
		{
			immutable string name = buildNormalizedPath(entry.name);
			immutable string text = readText(name).ifThrown!UTFException("");
			immutable auto lines = text.lineSplitter().array;
			auto output = appender!string;

			bool inCommentBlock;

			foreach(rawLine; lines)
			{
				immutable string line = rawLine.strip.chompPrefix("\t");

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

						if(commentType == MultiLineCommentType.OpenAndClose)
						{
						}
					}
					else if(inCommentBlock)
					{
						parseLine(line);
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
		getcwd.dirEntries(SpanMode.depth)
			.filter!(a => (!isHiddenFileOrDir(a) && a.isFile))
			.each!(entry => scanFile(entry));
	}
}
