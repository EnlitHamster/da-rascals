module Volume

// Project imports
import Utility;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

//---------------
// 1 - LOC METRIC
//---------------

@doc {
	.Synopsis
	The function calculates distinctly the LOC metric, the number of empty lines, the number of comment lines
	and the total lines of the file.
}
tuple[int, int, int, int] countLines(loc fileLoc, bool print) {
	int ctr = 0;
	int empty = 0;
	int comment = 0;
	int al = 0;
	bool inCom = false;
	
	for (line <- (readFileLines(fileLoc))) {
		al += 1;
		if (!inCom) {
			if ((/^\s*$/ := line)) {
				empty += 1;
				if (print) println("EMPTY :: <line>");
			} else if ((/^\s*\/\/.*/ := line) || (/\/\*.*?\*\// := line)) {
				comment += 1;
				if (print) println("COMMENT :: <line>");
			} else {
				// handle multiline
				if (/^\s*\/\*.*/ := line) {
					inCom = true;
					comment += 1;
					if (print) println("COMMENT :: <line>");
					continue;
				}
				ctr += 1;
				if (print) println("CODE :: <line>");
			}
		} else {
			comment += 1;
			if (print) println("COMMENT :: <line>");
			end = contains(line, "*/");
			if (end) {
				inCom = false;
			}
		}		
	}
	return <ctr, empty, comment, al>;
}

@doc {
	.Synopsis
	The function calculates how many Lines Of Code (LOC) the files are made of. 
}
int countLinesFiles(list[loc] fileLocs, bool print) {
	int ctr = 0;
	int empty = 0;
	int comment = 0;
	int al = 0;
	for (fileLoc <- fileLocs) {
		<c, e, com, a> = countLines(fileLoc, print);
		ctr += c;
		empty += e;
		comment += com;
		al += a;
	}
	println("<ctr>, <empty>, <comment>");
	println("<ctr + empty + comment> == <al>");
	return ctr;	
}

//----------------------
// 2 - MM RANKING METRIC
//----------------------

@doc {
	.Synopsis
	The function depends on the LOC generated by <<countLinesFiles>> which is then ranked against custom values.
}
int getLocRank(int locs, int top, int midtop, int mid, int midbot) {
	if (locs < top) return 2;
	else if (locs < midtop) return 1;
	else if (locs < mid) return 0;
	else if (locs < midbot) return -1;
	else return -2;
}

@doc {
	.Synopsis
	The function depends on the LOC generated by <<countLinesFiles>> which is then ranked against a
	known database of LOC averages, from the SPR LLC function point to man months table.
}
int getLocRank(int locs) {
	return getLocRank(locs, 66000, 246000, 665000, 1310000);
}