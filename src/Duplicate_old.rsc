module Duplicate_old

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

public alias Block = list[Snippet];

map[str, list[Block]] mapBlocks(list[loc] fileLocs, bool skip) {
	map[str, list[Block]] blocks = ();
	for (fLoc <- toSet(fileLocs)) {
		list[Snippet] snps = filterSnippets(readFileSnippets(fLoc), skip);
		int len = size(snps);
		if (len > 5) { // If the file size is less than 5, it is obvious there cannot be any duplicate code.
			for (i <- [0..len-5]) {
				// 6-line block of code
				Block block = slice(snps, i, 6);
				// mapping on escaped block
				str key = escape(block[0].block, (" ": "", "\t": ""));
				for (snp <- block) key += eof() + escape(snp.block, (" ": "", "\t": ""));
				if (key in blocks) blocks[key] += [block];
				else blocks[key] = [block];
			}
		}
	}
	return blocks;
}

// TODO: add checks for inline comments
// TODO: filter returns a list of <str, Snippet> where str contains only the code
//		 of the line, without any inline comments if there are any.
private list[Snippet] filterSnippets(list[Snippet] snps, bool skip) {
	list[Snippet] filtered = [];
	bool inCom = false;
	for (snp <- snps) {
		line = escape(snp.block, (" ": "", "\t": ""));
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
		filtered += snp;
	}
	return filtered;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(loc projectLoc, bool skip, bool print) {
	println(now());
	list[loc] files = getFiles(projectLoc);
	map[str, list[Block]] blocks = mapBlocks(files, skip);
	map[str, list[Block]] dupBlocks = ();
	
	set[Snippet] dupSnps = {};
	for (key <- blocks) {
		if (size(blocks[key]) > 1)  {
			dupBlocks[key] = blocks[key];
			for (block <- blocks[key])
				dupSnps += toSet(block);
		}
	}
	
//	if (print) {
//		FileClusters fileClusters = fileCluster(dupSnps);		
//		list[Snippet] snpClusters = [];
//		for (fCluster <- fileClusters) {
//			snpClusters += snippetCluster(fileClusters[fCluster]);
//		}
		
//		map[str block, list[loc] locs] duplicates = ();
//		for (snp <- snpClusters) {
//			str key = escape(snp.block, (" ": "", "\t": ""));
//			if (key in duplicates) {
//				duplicates[key] += snp.src;
//			} else {
//				duplicates[key] = [snp.src];
//			}
//		}
	
//		if (print) printDuplicates(duplicates);
//		println(now());
//		return countLines(snpClusters);
	if (print) {
		map[str, list[Snippet]] clusters = clusterizator(dupSnps, dupBlocks);
		for (key <- clusters) {
			println("The following locations contain duplicate code:");
			for (snp <- clusters[key]) println(snp.src);
		}
	}
	
	println(now());
	return size(dupSnps);
}

private list[Snippet] extender(FileClusters clusters, list[Block] blocks, bool forward) {
	list[Snippet] nextStep = [];
	for (snippets <- blocks) {
		Snippet pivot = forward ? last(snippets) : head(snippets);
		int obj = forward ? pivot.src.end.line + 1 : pivot.src.begin.line - 1;
		bool found = false;
		for (snp <- clusters[pivot.src.uri]) {
			if (snp.src.begin.line == obj) {
				nextStep += snp;
				found = true;
				break;
			}
		}
		// The line was not found, the blocks cannot be extended further
		if (!found) return [];
	}
	return nextStep;
}

private list[Block] extendMost(FileClusters clusters, list[Block] blocks, bool forward) {
	list[list[Snippet]] dupBlocks = blocks;
	list[Snippet] nextStep = extender(clusters, dupBlocks, forward);
	while (nextStep != []) {
		for (i <- [0..size(blocks)]) {
			if (forward) dupBlocks[i] = dupBlocks[i] + nextStep[i];
			else dupBlocks[i] = nextStep[i] + dupBlocks[i];
		}
		nextStep = extender(clusters, dupBlocks, forward);
	}
	return dupBlocks;
}

private map[str, list[Snippet]] clusterizator(set[Snippet] uniqueSnippets, map[str, list[Block]] duplicates) {
	map[str, list[Snippet]] dupClusters = ();
	FileClusters clusters = fileCluster(uniqueSnippets);
	for (key <- duplicates) {
		list[Block] blocks = extendMost(clusters, extendMost(clusters, duplicates[key], false), true);
		list[Snippet] snps = [];
		for (block <- blocks) snps += mergeSnippets(block);
		str kBlock = escape(snps[0].block, (" ": "", "\t": ""));
		if (kBlock notin dupClusters) dupClusters[kBlock] = snps;
	}
	
	return dupClusters;
}

private int countLines(snpClusters) {
	int lns = 0;
	for (snp <- snpClusters) lns += (snp.src.end.line - snp.src.begin.line) + 1;
	return lns;
}

private alias FileClusters = map[str file, list[Snippet] snps]; 

private FileClusters fileCluster(set[Snippet] snippets) {
	FileClusters cluster = ();
	for (snp <- snippets) {
		if (snp.src.uri in cluster) {
			cluster[snp.src.uri] += snp;
		} else {
			cluster[snp.src.uri] = [snp];
		}
	}
	return cluster;
}

private bool isSeq(Snippet s1, Snippet s2) {
	return s1.src.end.line + 1 == s2.src.begin.line;
}

private list[Snippet] snippetCluster(list[Snippet] snps) {
	list[Snippet] clusters = [];
	snps = sortSnippets(snps);	
	Snippet cluster = snps[0];
	for (i <- [1 .. size(snps)]) {
		if (isSeq(cluster, snps[i])) {
			cluster = mergeSnippets([cluster, snps[i]]);
		} else {
			clusters += cluster;
			cluster = snps[i];
		}
	}
	clusters += cluster;
	return clusters;
}

void printDuplicates(map[str block, list[loc] locs] dups) {
	for (b <- dups) {
		println("The following locations contain duplicate code:");
		for (l <- dups[b]) println(l);
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
	if (print) println("<dups>, <lines>");
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

