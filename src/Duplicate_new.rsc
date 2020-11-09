module Duplicate_new

// Project imports
import Utility;
import LineAnalysis;
import Snippet;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
import DateTime;

import util::Math;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public alias Block = list[Snippet];
private map[str, str] whiteSpaces = (" ":"", "\t":"");

map[str, list[Block]] mapBlocks(list[loc] fileLocs) {
	map[str, list[Block]] blocks = ();
	for (fLoc <- toSet(fileLocs)) {
		list[tuple[str, Snippet]] snps = filterSnippets(readFileSnippets(fLoc));
		int len = size(snps);
		if (len > 5) { // If the file size is less than 5, it is obvious there cannot be any duplicate code.
			for (i <- [0..len-5]) {
				// 6-line block of code
				list[tuple[str key, Snippet code]] roughBlk = slice(snps, i, 6);
				// mapping on escaped block
				str key = roughBlk[0].key;
				Block block = [roughBlk[0].code];
				for (j <- [1..6]) {
					key += eof() + roughBlk[j].key;
					block += roughBlk[j].code;
				}
				if (key in blocks) blocks[key] += [block];
				else blocks[key] = [block];
			}
		}
	}
	return blocks;
}

list[tuple[str, Snippet]] filterSnippets(list[Snippet] snps) {
	list[tuple[str, Snippet]] filtered = [];
	bool inCom = false;
	for (snp <- snps) {
		if (!(/^\s*$/ := snp.block)) {
			tuple[str code, bool inCom] filteredLine = removeInlineComments(snp.block, inCom);
			line = escape(filteredLine.code, whiteSpaces);
		
			if (line != "}" && line != "") filtered += <line, snp>; 
			
			inCom = filteredLine.inCom;
		}		
	}
	return filtered;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(loc projectLoc, bool print) {
	if (print) println(now());
	list[loc] files = getFiles(projectLoc);
	map[str, list[Block]] blocks = mapBlocks(files);
	map[str, list[Block]] dupBlocks = ();
	
	set[Snippet] dupSnps = {};
	for (key <- blocks) {
		if (size(blocks[key]) > 1)  {
			dupBlocks[key] = blocks[key];
			for (block <- blocks[key])
				dupSnps += toSet(block);
		}
	}
	
	if (print) {
		map[str, list[Snippet]] clusters = clusterizator(dupSnps, dupBlocks);
		for (key <- clusters) {
			println("The following locations contain duplicate code:");
			for (snp <- clusters[key]) println(snp.src);
		}
	}
	
	if (print) println(now());
	return size(dupSnps);
}

int getDuplicationRank(real dp, bool print) {
	return scoreRank(dp, 0.03, 0.05, 0.1, 0.2, print);
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