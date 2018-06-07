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

	if(line.canFind(commentClose))
	{
		return MultiLineCommentType.Close;
	}

	return MultiLineCommentType.None;
}

bool isSingleLineComment(const string line)
{
	immutable string singleLineComment = "//";

	if(line.startsWith(singleLineComment))
	{
		return true;
	}

	return false;
}

struct Scanner
{
	void scanFile(const DirEntry entry)
	{
		immutable string fileExtension = entry.name.baseName.extension.removeChars(".");

		if(fileExtension == "d")
		{
			immutable string name = buildNormalizedPath(entry.name);
			immutable string text = readText(name).ifThrown!UTFException("");
			immutable auto lines = text.lineSplitter().array;
			//lines.each!writeln;

			bool inCommentBlock;

			foreach(rawLine; lines)
			{
				immutable string line = rawLine.strip.chompPrefix("\t");

				if(!line.empty)
				{
					if(isSingleLineComment(line))
					{
					}
					else if(auto commentType = isMultiLineComment(line))
					{
						if(commentType == MultiLineCommentType.Open)
						{
							inCommentBlock = true;
						}

						if(commentType == MultiLineCommentType.Close)
						{
							inCommentBlock = false;
						}

						if(commentType == MultiLineCommentType.OpenAndClose)
						{
						}
					}
					else if(inCommentBlock)
					{
					}
					else
					{
					}
				}
			}
		}

	}

	void scanFiles()
	{
		getcwd.dirEntries(SpanMode.depth)
			.filter!(a => (!isHiddenFileOrDir(a) && a.isFile))
			.each!(entry => scanFile(entry));
	}
}
