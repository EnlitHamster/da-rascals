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

private int(bool, loc) fObjD = int(bool fwd, loc pos) {return -1;};
private bool(int, loc) fValD = bool(int obj, loc pos) {return false;};

private int(bool, loc) fObj1 = int(bool fwd, loc pos) {return fwd ? pos.end.line + 1 : pos.begin.line - 1;};
private bool(int, loc) fVal1 = bool(int obj, loc pos) {return pos.begin.line == obj;};

private int(bool, loc) fObj2 = int(bool fwd, loc pos) {return fwd ? pos.end.column + 1 : pos.begin.column - 1;};
private bool(int, loc) fVal2 = bool(int obj, loc pos) {return pos.begin.column == obj;};

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

// TODO: Should the method prototype be considered as well?
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

KSnippets escapeKeys(KSnippets ksnps) {
	KSnippets escaped = [];
	for (<key, code> <- ksnps) {
		key = escape(key, whiteSpaces);
		escaped += <key, code>;
	}
	return escaped;
}

MapSnippets getClones(list[loc] files, int clnType, int threshold, bool skipBrkts) {
	MapBlocks blocks = ();
	MapBlocks dupBlocks = ();
	set[Snippet] dupSnps = {};
	
	int(bool, loc) fObj = fObjD;
	bool(int, loc) fVal = fValD;
	
	if (clnType == 1) {
		blocks = mapBlocksType1(files, threshold, skipBrkts);
		fObj = fObj1;
		fVal = fVal1;
	} else if (clnType == 2) {
		blocks = mapBlocksType2(files, threshold);
		fObj = fObj2;
		fVal = fVal2;
	} else
		error("Clone types: [1,2]");
	
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	MapSnippets clones = clusterizator(dupSnps, dupBlocks, fObj, fVal);
	for (key <- clones)
		clones[key] = toList(toSet(clones[key]));
	
	return clones;
}

tuple[MapBlocks, set[Snippet]] genDupBlocks(MapBlocks blocks) {
	MapBlocks dupBlocks = ();
	set[Snippet] dupSnps = {};

	for (key <- blocks) {
		if (size(blocks[key]) > 1)  {
			dupBlocks[key] = blocks[key];
			for (block <- blocks[key])
				dupSnps += toSet(block);
		}
	}
	
	return <dupBlocks, dupSnps>;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(list[loc] files, bool print, bool skipBrkts) {
	MapBlocks blocks = mapBlocksType1(files, 6, skipBrkts);
	MapBlocks dupBlocks = ();
	set[Snippet] dupSnps = {};
	
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	
	if (print) {
		MapSnippets clusters = clusterizator(dupSnps, dupBlocks, fObj1, fVal1);
		for (key <- clusters) {
			println("The following locations with key<eof()><key><eof()>contain duplicate code:");
			for (snp <- clusters[key]) println("<snp.src>:<snp.block>");
		}
	}
	
	return size(dupSnps);
}

int getDuplicationRank(real dp, bool print) {
	return scoreRank(dp, 0.03, 0.05, 0.1, 0.2, print);
}

private list[Snippet] extender(MapSnippets clusters, list[Block] blocks, bool forward, int(bool, loc) fObj, bool(int, loc) fVal) {
	list[Snippet] nextStep = [];
	for (snippets <- blocks) {
		Snippet pivot = forward ? last(snippets) : head(snippets);
		int obj = fObj(forward, pivot.src);
		bool found = false;
		for (snp <- clusters[pivot.src.uri]) {
			if (fVal(obj, snp.src)) {
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

private list[Block] extendMost(MapSnippets clusters, list[Block] blocks, bool forward, int(bool, loc) fObj, bool(int, loc) fVal) {
	list[Block] dupBlocks = blocks;
	list[Snippet] nextStep = extender(clusters, dupBlocks, forward, fObj, fVal);
	while (nextStep != []) {
		for (i <- [0..size(blocks)]) {
			if (forward) dupBlocks[i] = dupBlocks[i] + nextStep[i];
			else dupBlocks[i] = nextStep[i] + dupBlocks[i];
		}
		nextStep = extender(clusters, dupBlocks, forward, fObj, fVal);
	}
	return dupBlocks;
}

private MapSnippets clusterizator(set[Snippet] uniqueSnippets, MapBlocks duplicates, int(bool, loc) fObj, bool(int, loc) fVal) {
	MapSnippets dupClusters = ();
	MapSnippets clusters = fileCluster(uniqueSnippets);
	for (key <- duplicates) {
		list[Block] blocks = extendMost(clusters, extendMost(clusters, duplicates[key], false, fObj, fVal), true, fObj, fVal);
		list[Snippet] snps = [];
		for (block <- blocks) snps += mergeSnippets(block, true);
		str kBlock = escape(snps[0].block, whiteSpaces);
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