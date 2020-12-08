module Duplicate

// Project imports
import Utility;
import LineAnalysis;
import Snippet;
import TheTokening;

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
public alias MapBlocks = map[str key, list[Block] blks];
public alias KSnippets = list[tuple[str key, Snippet code]]; // Keyed Snippets
public alias MapSnippets = map[str key, list[Snippet] snps];

private map[str, str] whiteSpaces = (" ":"", "\t":"");

MapBlocks mapBlocks(list[KSnippets] ksnps, int step, str sep) {
	MapBlocks blocks = ();
	for (snps <- ksnps) { // -- O(#files) = O(n)
		int len = size(snps);
		// -- O(#lines in nth file) = O(m)
		if (len > step - 1) { // If the file size is less than step, it is obvious there cannot be any duplicate code.
			for (i <- [0..len-step+1]) {
				// step-line block of code
				KSnippets roughBlk = slice(snps, i, step);
				// mapping on escaped block
				str key = roughBlk[0].key;
				Block block = [roughBlk[0].code];
				for (j <- [1..step]) { // -- O(step)
					key += sep + roughBlk[j].key;
					block += roughBlk[j].code;
				}
				if (key in blocks) blocks[key] += [block];
				else blocks[key] = [block];
			}
		}
	} // O(n * 5/3 * m(n) * step) = O(k * 10) approx O(k) linear 
	  // n * m(n) = k, where k is the number of lines in the project
	return blocks;
}

MapBlocks mapBlocksType2(list[loc] fileLocs, int threshold) {
	list[KSnippets] ksnps = [];
	for (fLoc <- fileLocs) {
		list[Token] tokens = normalize(tokenize(reconnect(reconstruct(parse(readFileSnippets(fLoc))))));
		ksnps += [kSnipTokens(tokens)];
	}
	return mapBlocks(ksnps, threshold, " ");
}

KSnippets kSnipTokens(list[Token] tokens) {
	return [<k, <k, l>> | <k, l> <- tokens];
}

MapBlocks mapBlocksType1(list[loc] fileLocs, int threshold, bool skipBrkts) {
	list[KSnippets] ksnps = [];
	for (fLoc <- fileLocs) {
		KSnippets snps = filterSnippets(readFileSnippets(fLoc), skipBrkts);
		snps = escapeKeys(snps);
		ksnps += [snps];
	}
	return mapBlocks(ksnps, threshold, eof());
}

KSnippets filterSnippets(list[Snippet] snps, bool skipBrkts) {
	KSnippets filtered = [];
	bool inCom = false;
	for (snp <- snps) {
		if (!(/^\s*$/ := snp.block)) {
			tuple[str code, bool inCom] filteredLine = removeInlineComments(snp.block, inCom);
			line = escape(filteredLine.code, whiteSpaces);
		
			if ((!skipBrkts || line != "}") && line != "") filtered += <filteredLine.code, snp>; 
			
			inCom = filteredLine.inCom;
		}		
	}
	return filtered;
}

KSnippets escapeVariables(KSnippets ksnps) {
	KSnippets escaped = [];
}

KSnippets escapeKeys(KSnippets ksnps) {
	KSnippets escaped = [];
	for (<key, code> <- ksnps) {
		key = escape(key, whiteSpaces);
		escaped += <key, code>;
	}
	return escaped;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(list[loc] files, bool print, bool skipBrkts) {
	MapBlocks blocks = mapBlocksType1(files, 6, skipBrkts);
	MapBlocks dupBlocks = ();
	
	set[Snippet] dupSnps = {};
	for (key <- blocks) {
		if (size(blocks[key]) > 1)  {
			dupBlocks[key] = blocks[key];
			for (block <- blocks[key])
				dupSnps += toSet(block);
		}
	}
	
	if (print) {
		MapSnippets clusters = clusterizator(dupSnps, dupBlocks);
		for (key <- clusters) {
			println("The following locations contain duplicate code:");
			for (snp <- clusters[key]) println(snp.src);
		}
	}
	
	return size(dupSnps);
}

int getDuplicationRank(real dp, bool print) {
	return scoreRank(dp, 0.03, 0.05, 0.1, 0.2, print);
}

private list[Snippet] extender(MapSnippets clusters, list[Block] blocks, bool forward) {
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

private list[Block] extendMost(MapSnippets clusters, list[Block] blocks, bool forward) {
	list[Block] dupBlocks = blocks;
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

private MapSnippets clusterizator(set[Snippet] uniqueSnippets, MapBlocks duplicates) {
	MapSnippets dupClusters = ();
	MapSnippets clusters = fileCluster(uniqueSnippets);
	for (key <- duplicates) {
		list[Block] blocks = extendMost(clusters, extendMost(clusters, duplicates[key], false), true);
		list[Snippet] snps = [];
		for (block <- blocks) snps += mergeSnippets(block, true);
		str kBlock = escape(snps[0].block, (" ": "", "\t": ""));
		if (kBlock notin dupClusters) dupClusters[kBlock] = snps;
	}
	
	return dupClusters;
}

private MapSnippets fileCluster(set[Snippet] snippets) {
	MapSnippets cluster = ();
	for (snp <- snippets) {
		if (snp.src.uri in cluster) {
			cluster[snp.src.uri] += snp;
		} else {
			cluster[snp.src.uri] = [snp];
		}
	}
	return cluster;
}