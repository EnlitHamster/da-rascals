module Duplicate

// Project imports
import Utility;
import Volume;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
import DateTime;
import Snippet;

import util::Math;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

@doc {
	.Synopsis
	Get all the files from the project, without any whitespace as one huge list of snippets
	.Params
	fileLocs :: list of filelocations
	skip :: Whether or not to skip codelines that consists of  a closing curly bracket, as this could be considered to not be a valid codeline" 
}
tuple[list[Snippet], int] getHugeList(list[loc] fileLocs, bool skip) {
	list[Snippet] codeSnippets = [];
	bool inCom = false;
	int len = 0;
	for (fileLoc <- toSet(fileLocs)) {
		for (snip <- (readFileSnippets(fileLoc))) {
			line = escape(snip.block, (" ": "", "\t": ""));
			if (inCom) {
				end = contains(line, "*/");
				if (end) {
					inCom = false;
				}
				continue;
			}
			accend = skip && line == "}" ;
			if ((/^\s*$/ := line) || (/^\s*\/\/.*/ := line) || (/\/\*.*?\*\// := line || accend)) {
				continue;
			}
			if (/^\s*\/\*.*/ := line) {
				inCom = true;
				continue;
			}
			snip.block = line;
			codeSnippets += snip;
			len += 1;
		}
		// Add a file delimiter to eliminate making codeblocks from seperate files.
		Snippet delim = <"-0-0-0-", fileLoc>;
		for (_ <- [0..5]) {
			codeSnippets += delim;	
		}
	}
	return <codeSnippets, len>;
}

@doc {
	.Synopsis
	Create a map with blocks of 6 lines as keys, with ocurrences as 
}
map[list[str], tuple[int, list[loc]]] createMap(list[Snippet] snippets, int len) {
	list[str] blockList = [];
	map[list[str], tuple[int, list[loc]]] blockCounts = ();
	for (int i <- [0 .. len-5]) {
		blockList = [snippets[n].block | n <- [i .. (i+6)]];
		if (blockList in blockCounts) {
			blockCounts[blockList] = addBlockList(blockCounts[blockList], snippets[i].src);
		} else {
			blockCounts[blockList] = <1, [snippets[i].src]>;
		}
	}
	return blockCounts;
}

@doc {
	.Synopsis
	Add a duplicate block to the dictionary by counting it and adding the location to the list.
}
tuple[int, list[loc]] addBlockList(tuple[int, list[loc]] prev, loc new) {
	return <prev[0]+1, prev[1] + new>;
} 

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(loc projectLoc, bool skip, bool print) {
	list[loc] files = getFiles(projectLoc);
	tuple[list[Snippet], int] huge = getHugeList(files, skip);
	blockCounts = createMap(huge[0], huge[1]);
	
	list[str] lines = [];
	for(bc <- blockCounts) {
		if (blockCounts[bc][0] >1 &&  "-0-0-0-" notin bc) {
			for(line <- bc) {
				lines += line;
			}
		}
	}
	
	unique = toSet(lines);

	if (print) {
		printDuplicateLocs(blockCounts);
	}
	return size(unique);
	//println(size(toSet(lines)));
	//println(toSet([bc | bc <- blockCounts, blockCounts[bc][0] > 1, "-0-0-0-" notin bc]));
	//return size(toSet([bc | bc <- blockCounts, blockCounts[bc][0] > 1, "-0-0-0-" notin bc]));
}

@doc {
	.Synopsis
	Print the locations where duplicated codeblocks of 6 or more lines have been found.
}
void printDuplicateLocs(map[list[str], tuple[int, list[loc]]] blockCounts) {
	uniqueBlocks = toSet([ub | ub <- blockCounts]);
	for (bc <- uniqueBlocks) {
		if (blockCounts[bc][0] > 1) {
			if ("-0-0-0-" notin bc) {
				println("The following locations contain duplicate code: ");
				for (loci <- blockCounts[bc][1]) {
					println(loci);
				}
				println();
			}
		}
	}
}

// Duplication (D): += 6,   (D/LOC) = duplication%
@doc {
	.Synopsis
	Get the percentage of duplication in a project.
}
real getDuplicationPercentage(loc projectLoc, bool skip, bool print) {
	real dups = toReal(getDuplicateLines(projectLoc, skip, print));
	real lines = toReal(countLinesFiles(getFiles(projectLoc), print));
	println("<dups>, <lines>");
	return  dups / lines; 
}
/* duplication(%) :  rank
		(0-3)	:	++
		(3-5)	:	+
		(5-10)	:	o
		(10-20)	:	-
		(20-100):	--  
					
*/

@doc {
	.Synopsis
	Get the rank for the duplication of the project.
}
int getDuplicationRank(real dp, bool print) {
	return scoreRank(dp, 0.03, 0.05, 0.1, 0.2, print);
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
	result = getDuplicationPercentage(projectLoc, false, false);
	println(now());
	println(result);
	getDuplicationRank(result, true);
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

//@doc {
//	.Synopsis
//	Get  the number of duplicated lines using the get duplicate blocks function
//}
//int DERPgetDuplicateLines(loc projectLoc) {
//	list[loc] files = getFiles(projectLoc);
//	tuple[list[str], int] huge = getHugeList(files); //<lines, len> = huge;
//	return (6 * DERPgetDuplicateBlocks(huge[0], huge[1]));
//}

//list[str] linurs = ["1",  "2",  "3",  "4",  "5",  "6",  "7",  "1",	 "2",  "3",  "4", "5",	 "6", "0",	"1", "2",  "3",  "4", "5", "6"];
//
//void testDup() {
//	println(createMap(linurs, size(linurs)));
//}

