module Duplicate

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

@doc {
	.Synopsis
	Get all the files from the project, without any whitespace as one huge string
}
tuple[list[str], int] getHugeList(list[loc] fileLocs) {
	list[str] conc = [];
	bool inCom = false;
	int len = 0;
	for (fileLoc <- fileLocs) {
		for (line <- (readFileLines(fileLoc))) {
			line = escape(line, (" ": "", "\t": ""));
			if (inCom) {
				end = contains(line, "*/");
				if (end) {
					inCom = false;
				}
				continue;
			}
			accend = startsWith(line, "}");
			if ((/^\s*$/ := line) || (/^\s*\/\/.*/ := line) || (/\/\*.*?\*\// := line) || accend) {
				continue;
			}
			if (/^\s*\/\*.*/ := line) {
				inCom = true;
				continue;
			}
			//println(line);
			conc += line;
			len += 1;
		}
	}
	return <conc, len>;
}

@doc {
	.Synopsis
	Create a map with blocks of 6 lines as keys, with ocurrences as 
}
map[list[str], int] createMap(list[str] lines, int len) {
	list[str] block = [];
	map[list[str], int] blockCounts = ();
	for (int i <- [0 .. len-5]) {
		block = [lines[n] | n <- [i .. (i+6)]];
		blockCounts[block]?0 += 1;
	}
	return blockCounts;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLineCount(loc projectLoc) {
	list[loc] files = getFiles(projectLoc);
	tuple[list[str], int] huge = getHugeList(files);
	blockCounts = createMap(huge[0], huge[1]);
	return 6* sum([blockCounts[bc] | bc <- blockCounts, blockCounts[bc] > 1]);
}

// Duplication (D): += 6,   (D/LOC) = duplication%
/* duplication (%) 
		(0-3)	:	++
		(3-5)	:	+
		(5-10)	:	o
		(10-20)	:	-
		(20-100):	--  
					
*/

list[str] linurs = ["1",  "2",  "3",  "4",  "5",  "6",  "7",  "1",	 "2",  "3",  "4", "5",	 "6", "0",	"1", "2",  "3",  "4", "5", "6"];

void testDup() {
	println(createMap(linurs, size(linurs)));
}

loc small = |project://smallsql0.21_src|;
loc whole = |project://hsqldb-2.3.1|;

void testDups(str project) {
	loc projectLoc = small;
	
	if (project == "whole") {
		projectLoc = whole;
	}
	
	println(projectLoc);
	println(now());
	result = getDuplicateLineCount(projectLoc);
	println(now());
	println(result);
}

@doc{
	.Synopsis
	Get the number of duplicated blocks of 6 lines in the list of lines with length len.
	
	.Description
	Blocks of length 6 (hardcoded for efficiency) are taken from the list of lines, and are checked against the rest of the lines in the list for duplication.
}
int DERPgetDuplicateBlocks(list[str] lines, int len) {
	int star = 0;
	int block_count = 0;
	list[list[str]] blocks =[];
	while (star+6 < len) {
			list[str] block = [lines[i] | i <- [star .. (star+6)]];
			star += 1;
			
			if (block in blocks) {
				continue;
			}
			//println(block);
			
			for(int i <- [star ..  len-5]) {
				//println("<lines[i]>, <block[0]>");
				//println("<lines[i]>, <lines[i+1]>, <lines[i+2]>, <lines[i+3]>, <lines[i+4]>, <lines[i+5]>");
				
				if ((lines[i] != block[0]) ||  (lines[i+1] != block[1]) ||  (lines[i+2] != block[2]) || (lines[i+3] != block[3]) ||  (lines[i+4] != block[4]) ||  (lines[i+5] != block[5])) {
					continue;
				}
				
				if (block notin blocks) {
					//println("NEW! Duplicate block found");
					//println(block);
					//println();
					blocks = push(block, blocks);
					block_count += 2;	
				} else {
					//println("Duplicate block found");
					//println(block);
					//println();
					block_count += 1;
				}
				
			}
	}
	return block_count;
}

@doc {
	.Synopsis
	Get  the number of duplicated lines using the get duplicate blocks function
}
int DERPgetDuplicateLines(loc projectLoc) {
	list[loc] files = getFiles(projectLoc);
	tuple[list[str], int] huge = getHugeList(files); //<lines, len> = huge;
	return (6 * getDuplicateBlocks(huge[0], huge[1]));
}

