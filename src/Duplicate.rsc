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
public alias MapKLSnippets = map[KLKey, ISnippet]; // Mapped snippets keyed by the location and beginning line of each block of the duplicate class 

public alias Block = list[ISnippet];
public alias KBlock = list[KSnippet];
public alias MapBlocks = map[str key, list[Block] blks];

private map[str, str] whiteSpaces = (" ":"", "\t":"");

MapBlocks mapBlocks(list[list[KSnippet]] ksnps, int step, str sep) {
	MapBlocks blocks = ();
	for (snps <- ksnps) { // -- O(#files) = O(n)
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

MapBlocks mapBlocksType2(list[loc] fileLocs, int threshold) {
	list[list[KSnippet]] ksnps = [];
	for (fLoc <- fileLocs) {
		list[Token] tokens = tokenizer(readFileSnippets(fLoc));
		ksnps += [kSnipTokens(tokens)];
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
				filtered += <filteredLine.code, <i, snp>>;
				i += 1;
			} 
			
			inCom = filteredLine.inCom;
		}		
	}
	return filtered;
}

list[KSnippet] escapeKeys(list[KSnippet] ksnps) {
	list[KSnippet] escaped = [];
	for (<key, <i ,<key, code>>> <- ksnps) {
		filteredKey = escape(key, whiteSpaces);
		escaped += <filteredKey, <i, <key, code>>>;
	}
	return escaped;
}

tuple[MapSnippets, int] getClones(list[loc] files, int clnType, int threshold, bool skipBrkts) {
	MapBlocks blocks = ();
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};
	
	blocks = typeSel(files, clnType, threshold, skipBrkts);
	
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	MapSnippets clones = clusterizator(dupBlocks);
	
	return <clones, size(dupSnps)>;
}

int getClonesType2(list[list[Token]] tokens, int threshold) {
	set[ISnippet] dupSnps = {};
	<_, dupSnps> = genDupBlocks(mapBlocksType2(tokens, threshold));
	return size(dupSnps);
}

num avgCloneLength(MapSnippets clones) {
	int nVals = 0;
	num sum = 0.0;
	for (key <- clones) {
		for (isnp <- clones[key]) {
			list[str] tokens = tokenizer(isnp.snp.block);
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

private MapBlocks typeSel(list[loc] files, int typ, int threshold, bool skipBrkts) {
	MapBlocks res = (); 
	
	if (typ == 1) 
		res = mapBlocksType1(files, threshold, skipBrkts);
	else if (typ == 2)
		res = mapBlocksType2(files, threshold);
	else
		error("Computable clone types: [1,2]");
	
	return res;
}

@doc {
	.Synopsis
	Get the number of duplicated lines in a project.
}
int getDuplicateLines(list[loc] files, int typ, int threshold, bool print, bool skipBrkts) {
	MapBlocks blocks = ();
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};
	
	blocks = typeSel(files, typ, threshold, skipBrkts);
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

void tester() {
	MapBlocks blocks = mapBlocksType1(getFiles(|project://smallsql0.21_src|), 6, false);
	MapBlocks dupBlocks = ();
	set[ISnippet] dupSnps = {};
	
	<dupBlocks, dupSnps> = genDupBlocks(blocks);
	MapSnippets clusters = clusterizator(dupBlocks);
	
	MapKLSnippets lClusters = dupClusterizator(dupBlocks);
	for (lKey <- lClusters) 
		println(lKey);
	
	str output = "";
	for (key <- clusters) {
		output += "<key>:<eof()>";
		for (b <- clusters[key])
			output += "-\t<b><eof()>";
		output += "<eof()><eof()>";
	}
			
	writeFile(|file:///C:/Users/sandr/Documents/University/SE/Series1/Dump/test_error.txt|, output);
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
		KLKey klk = <pivot.snp.src.uri, obj>;
		
		// The snippet cannot be extended
		if (klk notin clusters) return []; 
		
		str key = escape(clusters[klk].snp.block, whiteSpaces);
		
		// First snippet sets the key used to check if the extending is possible
		if (extenderKey == "")			
			extenderKey = key;	
		// Following snippets check if the key is the same, to guarantee same code extension
	 	else if (extenderKey != key)	
	 		return [];
		
		nextStep += clusters[klk];
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
	MapKLSnippets clusters = dupClusterizator(duplicates);
	for (key <- duplicates) {
		list[Block] blocks = extendMost(clusters, extendMost(clusters, duplicates[key], false), true);
		list[ISnippet] snps = [];
		for (block <- blocks) {
			list[Snippet] bSnps = [];
			for (isnp <- block) bSnps += isnp.snp; 
			snps += <block[0].pos, mergeSnippets(bSnps, true)>;
		}
		str kBlock = escape(snps[0].snp.block, whiteSpaces);
		if (kBlock notin dupClusters) dupClusters[kBlock] = snps;
	}
	
	return dupClusters;
}

private MapKLSnippets dupClusterizator(MapBlocks duplicates) {
	MapKLSnippets lsnps = ();
	for (key <- duplicates) {
		list[Block] blocks = duplicates[key];
		for (i <- [0..size(blocks[0])]) {
			for (block <- blocks) {
				ISnippet is = block[i];
				KLKey kls = <is.snp.src.uri, is.pos>;
				lsnps[kls] = is;
			}
		}
	}
	return lsnps;
}