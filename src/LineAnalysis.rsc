module LineAnalysis

// Rascal base imports
import IO;
import String;
import List;

import util::Math;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

tuple[str, bool] removeInlineComments(str code, bool inCom) {
	list[str] codeComm = split("//", code);
	if (size(codeComm) <= 0) return <"", false>; // The line is an entire single line comment
	
	str final = replaceAll(codeComm[0], "/*/", "/*");
	int iOpen = inCom ? 0 : findFirst(final, "/*");
	int iClse = findFirst(final, "*/");
	
	if (iOpen < 0) return <final, false>;
	else if (iClse < 0) return <substring(final, 0, iOpen), true>;
	
	do {
		str lhs = substring(final, 0, iOpen);
		str rhs = substring(final, iClse + 2, size(final));
		final = lhs + rhs;
		
		iOpen = findFirst(final, "/*");
		iClse = findFirst(final, "*/");
	} while (iOpen >= 0 && iClse >= 0);
	
	if (iOpen >= 0 && iClse < 0) return <substring(final, 0, iOpen), true>;
	else return <final, false>;
}

public alias LineCount = tuple[int code, int empty, int comment, int total];

@doc{
	.Synopsis
	Lines with both code and comments are counted as code lines
}
LineCount countLines(loc fileLoc, bool skipBrkts) {
	int code = 0;
	int empty = 0;
	int comment = 0;
	int total = 0;
	
	bool inCom = false;
	
	for (line <- readFileLines(fileLoc)) {
		total += 1;
		tuple[str code, bool inCom] filteredLine = removeInlineComments(line, inCom);
		
		if (/^\s*$/ := line) { 
			if (!inCom) empty += 1;
			else comment += 1;
		} else {
			if (skipBrkts && /^\s*}\s*$/ := filteredLine.code) empty += 1;
			else if (/^\s*$/ := filteredLine.code) comment += 1;
			else code += 1;
		}
			
		inCom = filteredLine.inCom;
	}
	return <code, empty, comment, total>;
}