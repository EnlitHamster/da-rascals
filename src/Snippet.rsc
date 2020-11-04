module Snippet

// Project imports
import Utility;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
import DateTime;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

@javaClass{internal.Snippet}
private java str eof();

@doc{
	.Synopsis
	Data type that is used instead of normal str to parse input files.
	
	.Description
	<<Snippet>> is a more sophisticated way of interpreting code files which keeps
	track not only of the content of the code itself but also where it is located
	in the file.
	
	This allows for easy access to the actual code block and more sophisticated
	comparison between code (i.e. avoid that same code in different spots is deemed
	equal). 
}
public alias Snippet = tuple[str block, loc src];

@doc{
	.Synopsis
	Creates a single Snippet from a list of Snippets.
}
public Snippet mergeSnippets(list[Snippet] snippets) {
	str block = snippets[0].block;
	for (snippet <- tail(snippets)) {
		block += eof() + snippet.block;
	}
	
	int sz = size(snippets);
	int offset = snippets[0].src.offset;
	int len = snippets[sz-1].src.offset - snippets[0].src.offset + snippets[sz-1].src.length;
	tuple[int,int] begin = snippets[0].src.begin;
	tuple[int,int] end = snippets[sz-1].src.end;
	
	println(offset);
	println(len);
	println(begin);
	println(end);
	
	return <block, snippets[0].src(offset,len,begin,end)>;
}

@doc{
	.Synopsis
	Less strict version of equals which considers two snippets equal iff their blocks are the same.
}
public bool softEquals(Snippet s1, Snippet s2) {
	return s1.block == s2.block;
}

@doc{
	.Synopsis
	Parses a file similarly to <<readFileLines>> but returns a list of Snippets rather than Strings.
}
public list[Snippet] readFileSnippets(loc fileLoc) {
	list[Snippet] snippets = [];
	list[str] fileContent = readFileLines(fileLoc);
	int offset = 0; // Char offset from the beginning of the file
	int ln = 0; // Line counter
	int eofSize = size(eof()); // System-dependant EOF chars length. To be added to the offset after every line.
	for (line <- fileContent) {
		int len = size(line); // Length of the line
		// The begin and end tuples are based on the char length and not on the length of
		// Tabulation Chars (like IDEs) as this is IDE and platform independant. It is the
		// Char offset from the beginning of the line.
		snippets += <line, fileLoc(offset, len, <ln, 0>, <ln, len>)>;
		offset += len + eofSize;
		ln += 1;
	}
	return snippets;
}