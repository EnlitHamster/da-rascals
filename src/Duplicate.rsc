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

public alias ISnippet = tuple[int pos, Snippet snp];
public alias KSnippet = tuple[str key, ISnippet code]; // Keyed Snippet

public alias KLKey = tuple[str src, int begin]; // Location based Keyed snippet
public alias MapSnippets = map[str key, list[ISnippet] snps];
public alias MapKLSnippets = map[str key, map[int pos, ISnippet snp] isnps]; // Mapped snippets keyed by the location and beginning line of each block of the duplicate class

public alias Block = list[ISnippet];
public alias KBlock = list[KSnippet];
public alias MapBlocks = map[str key, list[Block] blks];

private map[str, str] whiteSpaces = (" ":"", "\t":"");

MapBlocks mapBlocks(list[list[KSnippet]] ksnps, int step, str sep) {
	MapBlocks blocks = ();
	int _len = size(ksnps);
	int _i = 1;
	for (snps <- ksnps) { // -- O(#files) = O(n)
		print("Mapping block <_i>/<_len>...");
		_i += 1;
		int len = size(snps);
		// -- O(#lines in nth file) = O(m)
		if (len > step) { // If the file size is less than step, it is obvious there cannot be any duplicate code.
			for (i <- [0..len-step]) {
				// step-line block of code
				list[KSnippet] roughBlk = slice(snps, i, step);
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
		println(" Done.");
	} // O(n * 5/3 * m(n) * step) = O(k * 10) approx O(k) linear 
	  // n * m(n) = k, where k is the number of lines in the project
	return blocks;
}

// step = threshold - error
// distance = 2 * error
private list[KBlock] mapKBlocks(list[list[KSnippet]] ksnps, int step, int distance, str sep) {
	list[KBlock] kBlocks = [];
	for (snps <- ksnps) {
		int len = size(snps);
		if (len > step) {
			for (i <- [0..len-step]) {
				list[KSnippet] roughBlk = slice(snps, i, step);
				KBlock kBlk = [roughBlk[0].code];
				for (j <- [1..step])
					kBlk += roughBlk[j].code;
				kBlocks += kBlk;
				
				int upperBound = min(len - (i + step), distance);
				for (j <- [0..upperBound]) {
					kBlk += snps[i + step + j].code;
					kBlocks += kBlk;
				}
			}
		}
	}
	
	return kBlocks;
}

private int editDistance(list[str] strt, list[str] obj) {

	return -1;
}

MapBlocks mapBlocks(list[list[KSnippet]] ksnps, int step, int distance, str sep) {
	list[KBlock] kBlocks = mapKBlocks(ksnps, step, distance, sep);
	
	list[set[KBlock]] mappedBlocks = [];
	for (kBlk1 <- kBlocks) {
		set[KBlock] cloneClass = {kBlk1};
		
		
		
		if (size(cloneClass) > 1)
			mappedBlocks += cloneClass;
	}
}

MapBlocks mapBlocksType2(list[list[Token]] tokens, int threshold) {
	list[list[KSnippet]] ksnps = [];
	for (token <- tokens) 
		ksnps += [kSnipTokens(token)];
	return mapBlocks(ksnps, threshold, " ");
}

MapBlocks mapBlocksType2(list[loc] fileLocs, int threshold, bool strict) {
	list[list[KSnippet]] ksnps = [];
	int _len = size(fileLocs);
	int _i = 1;
	for (fLoc <- fileLocs) {
		print("Tokening file <_i>/<_len>...");
		_i += 1;
		list[Token] tokens = tokenizer(readFileSnippets(fLoc), strict);
		ksnps += [kSnipTokens(tokens)];
		println(" Done.");
	}
	return mapBlocks(ksnps, threshold, " ");
}

MapBlocks mapBlocksType1(list[loc] fileLocs, int threshold, bool skipBrkts) {
	list[list[KSnippet]] ksnps = [];
	for (fLoc <- fileLocs) {
		list[KSnippet] snps = filterSnippets(readFileSnippets(fLoc), skipBrkts);
		ksnps += [escapeKeys(snps)];
	}
	return mapBlocks(ksnps, threshold, eof());
}

list[KSnippet] kSnipTokens(list[Token] tokens) {
	list[KSnippet] ksnps = [];
	for (i <- [0..size(tokens)]) {
		k = tokens[i].block;
		l = tokens[i].src;
		ksnps += <k, <i, <k, l>>>;
	}
	return ksnps;
}

list[KSnippet] filterSnippets(list[Snippet] snps, bool skipBrkts) {
	list[KSnippet] filtered = [];
	bool inCom = false;
	int i = 0;
	for (snp <- snps) {
		if (!(/^\s*$/ := snp.block)) {
			tuple[str code, bool inCom] filteredLine = removeInlineComments(snp.block, inCom);
			line = escape(filteredLine.code, whiteSpaces);
		
			if ((!skipBrkts || line != "}") && line != "") {
				filtered += <line, <i, <filteredLine.code, snp.src>>>;
				i += 1;
			} 
			
			inCom = filteredLine.inCom;
		}		
	}
		
	return filtered;
}

list[KSnippet] escapeKeys(list[KSnippet] ksnps) {
	list[KSnippet] escaped = [];
	for (ksnp <- ksnps) {
		filteredKey = escape(ksnp.key, whiteSpaces);
		escaped += <filteredKey, <ksnp.code.pos, <ksnp.code.snp.block, ksnp.code.snp.src>>>;
	}
	return escaped;
}

tuple[MapSnippets, int] getClones(list[loc] files, int clnType, int threshold, bool skipBrkts, bool strict) {
	MapBlocks blocks = ();
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};
	
	println("Mapping snippets...");
	blocks = typeSel(files, clnType, threshold, skipBrkts, strict);
	
	println("Generating duplication blocks...");
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	println("Clusterizing blocks...");
	MapSnippets clones = clusterizator(dupBlocks);
	
	return <clones, size(dupSnps)>;
}

tuple[MapSnippets, int] getClonesType2(list[list[Token]] tokens, int threshold) {
	set[ISnippet] dupSnps = {};
	MapBlocks dupBlocks = ();
	
	<dupBlocks, dupSnps> = genDupBlocks(mapBlocksType2(tokens, threshold));
	MapSnippets clones = clusterizator(dupBlocks);
	
	return <clones, size(dupSnps)>;
}

num avgCloneLength(MapSnippets clones, bool strict) {
	int nVals = 0;
	num sum = 0.0;
	for (key <- clones) {
		for (isnp <- clones[key]) {
			list[str] tokens = tokenizer(isnp.snp.block, strict);
			sum += size(tokens);
			nVals += 1;
		}
	}
	return sum / nVals;
}

tuple[MapBlocks, set[ISnippet]] genDupBlocks(MapBlocks blocks) {
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};

	for (key <- blocks) {
		if (size(blocks[key]) > 1)  {
			dupBlocks[key] = blocks[key];
			for (block <- blocks[key])
				dupSnps += toSet(block);
		}
	}
	
	return <dupBlocks, dupSnps>;
}

private MapBlocks typeSel(list[loc] files, int typ, int threshold, bool skipBrkts, bool strict) {
	MapBlocks res = (); 
	
	if (typ == 1) 
		res = mapBlocksType1(files, threshold, skipBrkts);
	else if (typ == 2)
		res = mapBlocksType2(files, threshold, strict);
	else
		error("Computable clone types: [1,2]");
	
	return res;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(list[loc] files, int typ, int threshold, bool print, bool skipBrkts, bool strict) {
	MapBlocks blocks = ();
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};
	
	blocks = typeSel(files, typ, threshold, skipBrkts, strict);
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	
	if (print) {
		MapSnippets clusters = clusterizator(dupBlocks);
		for (key <- clusters) {
			println("The following locations contain duplicate code:");
			for (isnp <- clusters[key]) println(isnp.snp.src);
		}
	}
	
	return size(dupSnps);
}

int getDuplicationRank(real dp, bool print) {
	return scoreRank(dp, 0.03, 0.05, 0.1, 0.2, print);
}

private list[ISnippet] extender(MapKLSnippets clusters, list[Block] blocks, bool forward) {
	list[ISnippet] nextStep = [];
	str extenderKey = "";
	for (snippets <- blocks) {
		ISnippet pivot = forward ? last(snippets) : head(snippets);
		int obj = forward ? pivot.pos + 1 : pivot.pos - 1;
		str file = pivot.snp.src.uri;
		
		// The snippet cannot be extended
		if (obj notin clusters[file])
			return [];
				
		str key = escape(clusters[file][obj].snp.block, whiteSpaces);
		
		// First snippet sets the key used to check if the extending is possible
		if (extenderKey == "")			
			extenderKey = key;	
		// Following snippets check if the key is the same, to guarantee same code extension
	 	else if (extenderKey != key)
	 		return [];
		
		nextStep += clusters[file][obj];
	}
	
	return nextStep;
}

private list[Block] extendMost(MapKLSnippets clusters, list[Block] blocks, bool forward) {
	list[Block] dupBlocks = blocks;
	list[ISnippet] nextStep = extender(clusters, dupBlocks, forward);
	while (nextStep != []) {
		for (i <- [0..size(blocks)]) {
			if (forward) dupBlocks[i] = dupBlocks[i] + nextStep[i];
			else dupBlocks[i] = nextStep[i] + dupBlocks[i];
		}
		nextStep = extender(clusters, dupBlocks, forward);
	}
	return dupBlocks;
}

private MapSnippets clusterizator(MapBlocks duplicates) {
	MapSnippets dupClusters = ();
	MapBlocks fixedDups = fixOverlaps(duplicates);
	MapKLSnippets clusters = dupClusterizator(fixedDups);
	int _len = size(fixedDups);
	int _i = 1;
	
	for (key <- fixedDups) {
		print("Clustering class <_i>/<_len>..."); 
		_i += 1;
		list[Block] blocks = extendMost(clusters, extendMost(clusters, fixedDups[key], false), true);
		list[ISnippet] snps = [];
		for (block <- blocks) {
			list[Snippet] bSnps = [];
			for (isnp <- block) bSnps += isnp.snp; 
			snps += <block[0].pos, mergeSnippets(bSnps, true)>;
		}
		str kBlock = escape(snps[0].snp.block, whiteSpaces);
		if (kBlock notin dupClusters) dupClusters[kBlock] = snps;
		println(" Done.");
	}
	
	return dupClusters;
}

// QUICK 'N' DIRTY SOLUTIONS LLC
private MapBlocks fixOverlaps(MapBlocks blocks) {
	MapBlocks fixedBlocks = ();
	int _len = size(blocks);
	int _i = 1;

	for (key <- blocks) {
		print("Checking overlaps <_i>/<_len>...");
		_i += 1;
		list[list[Block]] overlaps = [];		
		for (block <- blocks[key]) {
			bool done = false;
			int objUp = block[0].pos - 1;
			int objDown = block[0].pos + 1;
			list[Block] olBlock = [block];
			while (!done) {
				done = true;
				for (block2 <- blocks[key]) {
					if (block2[0].pos == objUp) {
						olBlock += [block2];
						objUp -= 1;
						done = false;
					} else if (block2[0].pos == objDown) {
						olBlock += [block2];
						objDown += 1;
						done = false;
					}
				}
			}
			overlaps += [olBlock];
		}
		
		int pivot = size(overlaps[0]);
		bool overlapCheck = true;
		int i = 1;
		while (overlapCheck && i < size(overlaps)) {
			if (size(overlaps[i]) != pivot)
				overlapCheck = false;
			i += 1;
		}
		
		if (overlapCheck) {
			list[Block] newCloneClassBlocks = [];
			for (olBlock <- overlaps)
				newCloneClassBlocks += [mergeBlocks(olBlock)];
			
			newCloneClassBlocks = toList(toSet(newCloneClassBlocks));
			str pivotKey = blocksKey(newCloneClassBlocks[0]);
			bool keyCheck = true;
			int k = 1;
			while (keyCheck && k < size(newCloneClassBlocks)) {
				if (pivotKey != blocksKey(newCloneClassBlocks[k]))
					keyCheck = false;
				k += 1;
			} // It Just Works - Hodd Toward
			
			if (keyCheck) {
				if (pivotKey in fixedBlocks) 
					fixedBlocks[pivotKey] += newCloneClassBlocks;
				else
					fixedBlocks[pivotKey] = newCloneClassBlocks;
				println(" Fixed.");
			} else {
				if (key in fixedBlocks) 
					fixedBlocks[key] += blocks[key];
				else
					fixedBlocks[key] = blocks[key];
				println(" Done.");
			}
		} else {
			if (key in fixedBlocks) 
				fixedBlocks[key] += blocks[key];
			else
				fixedBlocks[key] = blocks[key];
			println(" Done.");
		}
	}
	
	return fixedBlocks;
}

private Block mergeBlocks(list[Block] blocks) {
	set[ISnippet] snips = {};
	for (block <- blocks)
		for (snip <- block)
			snips += snip;
	return sort(toList(snips), bool(ISnippet a, ISnippet b) {return a.pos < b.pos;});
}

private str blocksKey(Block block) {
	str key = escape(block[0].snp.block, whiteSpaces);
	for (isnp <- block[1..])
		key += "<eof()><escape(isnp.snp.block, whiteSpaces)>";
	return key;
}

private MapKLSnippets dupClusterizator(MapBlocks duplicates) {
	MapKLSnippets lsnps = ();
	int _len = size(duplicates);
	int _i = 1;
	for (key <- duplicates) {
		print("Block duplicate clusterizer <_i>/<_len>...");
		_i += 1;
		list[Block] blocks = duplicates[key];
		for (i <- [0..size(blocks[0])]) {
			for (block <- blocks) {
				ISnippet is = block[i];
				str file = is.snp.src.uri;
				int pos = is.pos;
				if (file notin lsnps)
					lsnps[file] = ();
				
				if (pos notin lsnps[file])
					lsnps[file][pos] = is;
			}
		}
		println(" Done.");
	}
	return lsnps;
}