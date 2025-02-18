module Bundle

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate;
import Snippet;
import LineAnalysis;
import Coupling;
import TestQuality;
import TheTokening;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;

import util::Math;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

private alias CloneClass = list[tuple[str pkg, loc src]];

// Used to pass data from bundling to output
private alias Bundle = tuple[ LineCount LOCNB,
							  LineCount LOCB,
							  TokenCount TLOC,
							  int rankLOCNB,
							  int rankLOCB,
							  list[CC] CCs,
							  map[str,int] riskCCsNE,
							  map[str,int] riskCCsE,
							  int rankUCNE,
							  int rankUCE,
							  list[int] US,
							  map[str,int] riskUS,
							  int rankUS,
							  int DUPNB,
							  int DUPB,
							  int DUP2,
							  int DUP25,
							  CloneStats statsDUPNB,
							  CloneStats statsDUPB,
							  CloneStats statsDUP2,
							  CloneStats statsDUP25,
							  int rankDUPNB,
							  int rankDUPB,
							  int asserts,
							  int aLOCNB,
							  int aLOCB,
							  int rankASSNB,
							  int rankASSB,
							  real ANNB,
							  real ANB,
							  real CHNENB,
							  real CHNEB,
							  real CHENB,
							  real CHEB,
							  real STNB,
							  real STB,
							  real TSNENB,
							  real TSNEB,
							  real TSENB,
							  real TSEB,
							  real OVNENB,
							  real OVNEB,
							  real OVENB,
							  real OVEB,
							  MapSnippets clones1NB,
							  MapSnippets clones1B,
							  MapSnippets clones2,
							  MapSnippets clones25 ];

public alias CloneStats = tuple[int cloneClasses, int biggestClone, int biggestClass, int cloneInsts];

CloneStats getClonesStats(MapSnippets clones) {
	int cloneClasses = 0;
	int biggestClone = 0;
	int biggestClass = 0;
	int cloneInsts = 0;

	int _len = size(clones);
	int _i = 1;

	for (key <- clones) {
		print("Harvesting clone stats <_i>/<_len>...");
		_i += 1;
		cloneClasses += 1;
		int nClones = 0;
		for (isnp <- clones[key]) {
			nClones += 1;
			int len = isnp.snp.src.end.line - isnp.snp.src.begin.line + 1;
			if (len > biggestClone)
				biggestClone = len;
		}
		if (nClones > biggestClass)
			biggestClass = nClones;
		cloneInsts += nClones;
		println(" Done.");
	}
	
	return <cloneClasses, biggestClone, biggestClass, cloneInsts>;
}

Bundle bundle(loc projectLoc, bool prnt, int thresholdType1Clones, int thresholdType2Clones, int skipBrkts, int strict) {
	// Saving the project files/ASTs as they are used by all metric calculators
	list[loc] projectFiles = getFiles(projectLoc);
	list[Declaration] asts = getASS(projectFiles);
	
	// VOLUME
	if (prnt) println("=== VOLUME LOGS");
	
	LineCount LOCNB = NLC();
	LineCount LOCB = NLC();
	int rankLOCNB = -1;
	int rankLOCB = -1;
	
	if (skipBrkts % 2 == 0) {
		LOCNB = countLinesFiles(projectFiles, prnt, true);
		rankLOCNB = getLocRank(LOCNB.code, prnt);
	}
	
	if (skipBrkts > 0) {
		LOCB = countLinesFiles(projectFiles, prnt, false);
		rankLOCB = getLocRank(LOCB.code, prnt);
	}
	
	// UNIT COMPLEXITY
	if (prnt) println("=== UNIT COMPLEXITY LOGS");
	
	list[CC] CCs = calcAllCC(asts);
	
	map[str,int] riskCCsNoExp = rankCCsRisk(CCs, false);
	map[str,int] riskCCsExp = rankCCsRisk(CCs, true);
	
	int rankUCNoExp = rankComplexity(riskCCsNoExp, prnt);
	int rankUCExp = rankComplexity(riskCCsExp, prnt);
	
	// UNIT SIZE
	if (prnt) println("=== UNIT SIZE LOGS");
	
	list[int] unitSizes = getUnitsLoc(asts);
	map[str,int] riskUnitSizes = rankSizeRisk(unitSizes);
	int rankUS = rankUnitSize(riskUnitSizes, prnt);
	
	// DUPLICATES
	if (prnt) println("=== DUPLICATES LOGS");
	
	int duplicatesNB = -1;
	int duplicatesB = -1;
	int rankDUPNB = -1;
	int rankDUPB = -1;
	
	CloneStats stats1NB = <-1,-1,-1,-1>;
	CloneStats stats1B = <-1,-1,-1,-1>;
	
	MapSnippets clones1NB = ();
	MapSnippets clones1B = ();
	
	if (skipBrkts % 2 == 0) {
		<clones1NB, duplicatesNB> = getClones(projectFiles, 1, thresholdType1Clones, true, false);
		rankDUPNB = getDuplicationRank(toReal(duplicatesNB) / toReal(LOCNB.code), prnt);
		stats1NB = getClonesStats(clones1NB);
	}
	
	if (skipBrkts > 0) {
		<clones1B, duplicatesB> = getClones(projectFiles, 1, thresholdType1Clones, false, false);
		rankDUPB = getDuplicationRank(toReal(duplicatesB) / toReal(LOCB.code), prnt);
		stats1B = getClonesStats(clones1B);
	}
	
	MapSnippets clones2 = ();
	MapSnippets clones25 = ();
	int duplicates2 = -1;
	int duplicates25 = -1;
	CloneStats stats2 = <-1,-1,-1,-1>;
	CloneStats stats25 = <-1,-1,-1,-1>;
	TokenCount tknStats = <-1,-1,-1,-1>;
	
	if (strict % 2 == 0) {
		list[list[Token]] tokens = [];
		int _len = size(projectFiles);
		int _i = 1;
		for (fLoc <- projectFiles) {
			print("Tokening file <_i>/<_len>...");
			_i += 1;
			tokens += [tokenizer(readFileSnippets(fLoc), true)];
			println(" Done.");
		}
		<clones2, duplicates2> = getClonesType2(tokens, thresholdType2Clones);
		stats2 = getClonesStats(clones2);
		tknStats = getTokenStats(tokens);
	}
	
	if (strict > 0) {
		list[list[Token]] tokens = [];
		int _len = size(projectFiles);
		int _i = 1;
		for (fLoc <- projectFiles) {
			print("Tokening file <_i>/<_len>...");
			_i += 1;
			tokens += [tokenizer(readFileSnippets(fLoc), false)];
			println(" Done.");
		}
		<clones25, duplicates25> = getClonesType2(tokens, thresholdType2Clones);
		stats25 = getClonesStats(clones25);
		if (strict == 1)
			tknStats = getTokenStats(tokens);
	}
	
	// TEST QUALITY
	if (prnt) println("=== TEST LOGS");
	
	list[loc] asserts = getAsserts(asts);
	int aLOCNB = -1;
	int aLOCB = -1;
	int rankASSNB = -1;
	int rankASSB = -1;
	
	if (skipBrkts % 2 == 0) <rankASSNB, aLOCNB> = getTestQualityMetric(asserts, prnt, true);
	if (skipBrkts > 0) <rankASSB, aLOCB> = getTestQualityMetric(asserts, prnt, false);
	
	// SYSTEM-LEVEL
	
	real ANNB = (toReal(rankLOCNB) + toReal(rankDUPNB) + toReal(rankUS) + toReal(rankASSNB)) / 4.0;
	real ANB = (toReal(rankLOCB) + toReal(rankDUPB) + toReal(rankUS) + toReal(rankASSB)) / 4.0;
	real CHNENB = (toReal(rankUCNoExp) + toReal(rankDUPNB)) / 2.0;
	real CHNEB = (toReal(rankUCNoExp) + toReal(rankDUPB)) / 2.0;
	real CHENB = (toReal(rankUCExp) + toReal(rankDUPNB)) / 2.0;
	real CHEB = (toReal(rankUCExp) + toReal(rankDUPB)) / 2.0;
	real STNB = toReal(rankASSNB);
	real STB = toReal(rankASSB);
	real TSNENB = (toReal(rankUCNoExp) + toReal(rankUS) + toReal(rankASSNB)) / 3.0;
	real TSNEB = (toReal(rankUCNoExp) + toReal(rankUS) + toReal(rankASSB)) / 3.0;
	real TSENB = (toReal(rankUCExp) + toReal(rankUS) + toReal(rankASSNB)) / 3.0;
	real TSEB = (toReal(rankUCExp) + toReal(rankUS) + toReal(rankASSB)) / 3.0;
	
	real OVNENB = (ANNB + CHNENB + STNB + TSNENB) / 4.0;
	real OVNEB = (ANB + CHNEB + STB + TSNEB) / 4.0;
	real OVENB = (ANNB + CHENB + STNB + TSENB) / 4.0;
	real OVEB = (ANB + CHEB + STB + TSEB) / 4.0;
	
	// Output
	return <LOCNB, LOCB, tknStats, rankLOCNB, rankLOCB, CCs, riskCCsNoExp, riskCCsExp, rankUCNoExp, rankUCExp, unitSizes, riskUnitSizes, 
			rankUS, duplicatesNB, duplicatesB, duplicates2, duplicates25, stats1NB, stats1B, stats2, stats25, rankDUPNB, rankDUPB, size(asserts), 
			aLOCNB, aLOCB, rankASSNB, rankASSB, ANNB, ANB, CHNENB, CHNEB, CHENB, CHEB, STNB, STB, TSNENB, TSNEB, TSENB, TSEB, OVNENB, OVNEB, 
			OVENB, OVEB, clones1NB, clones1B, clones2, clones25>;
}

void printAllBundles(loc outputFolder, int threshold1, int threshold2) {
	println("=== Testing codebase");
	printBundle(|project://testing|, outputFolder, threshold1, threshold2, "db_testing");
	println("=== SmallSql codebase");
	printBundle(|project://smallsql0.21_src|, outputFolder, threshold1, threshold2, "db_smallsql");
	println("=== HSqlDB codebase");
	printBundle(|project://hsqldb-2.3.1|, outputFolder, threshold1, threshold2, "db_hsqldb");
}

void printBundle(loc projectLoc, loc outputFolder, int threshold1, int threshold2, str fileName) {
	println("Generating bundle...");
	Bundle bundle = bundle(projectLoc, false, threshold1, threshold2, 2, 2);
	println("Processing lists...");
	list[int] CCsNE = [];
	list[int] CCsE = [];
	for (<pi,piExp> <- bundle.CCs) {
		CCsNE += pi;
		CCsE += (pi + piExp);
	}
	
	// tuple[int cloneClasses, int biggestClone, int biggestClass, int cloneInsts];
	println("Dumping data...");
	loc outputFile = outputFolder + "<fileName>.metrics";
	writeFile( outputFile, 
			   "<bundle.TLOC.ids>,<bundle.TLOC.literals>,<bundle.TLOC.methods>,<bundle.TLOC.total>" + eof(),
			   "<bundle.DUP2>,<bundle.statsDUP2.cloneClasses>,<bundle.statsDUP2.biggestClone>,<bundle.statsDUP2.biggestClass>,<bundle.statsDUP2.cloneInsts>" + eof(),
			   "<bundle.DUP25>,<bundle.statsDUP25.cloneClasses>,<bundle.statsDUP25.biggestClone>,<bundle.statsDUP25.biggestClass>,<bundle.statsDUP25.cloneInsts>" + eof(),
			   "<listToStr(CCsNE)>" + eof(),
			   "<listToStr(CCsE)>" + eof(),
			   "<bundle.riskCCsNE[LOW_RISK]>,<bundle.riskCCsNE[MID_RISK]>,<bundle.riskCCsNE[HIGH_RISK]>,<bundle.riskCCsNE[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.riskCCsE[LOW_RISK]>,<bundle.riskCCsE[MID_RISK]>,<bundle.riskCCsE[HIGH_RISK]>,<bundle.riskCCsE[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.rankUCNE>,<bundle.rankUCE>" + eof(),
			   "<listToStr(bundle.US)>" + eof(), 
			   "<bundle.riskUS[LOW_RISK]>,<bundle.riskUS[MID_RISK]>,<bundle.riskUS[HIGH_RISK]>,<bundle.riskUS[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.rankUS>" + eof(),
			   "<bundle.LOCNB.code>,<bundle.LOCNB.empty>,<bundle.LOCNB.comment>,<bundle.LOCNB.total>" + eof(),
			   "<bundle.LOCB.code>,<bundle.LOCB.empty>,<bundle.LOCB.comment>,<bundle.LOCB.total>" + eof(),
		       "<bundle.rankLOCNB>,<bundle.rankLOCB>" + eof(),
		       "<bundle.DUPNB>,<bundle.statsDUPNB.cloneClasses>,<bundle.statsDUPNB.biggestClone>,<bundle.statsDUPNB.biggestClass>,<bundle.statsDUPNB.cloneInsts>" + eof(),
		       "<bundle.DUPB>,<bundle.statsDUPB.cloneClasses>,<bundle.statsDUPB.biggestClone>,<bundle.statsDUPB.biggestClass>,<bundle.statsDUPB.cloneInsts>" + eof(),
			   "<bundle.rankDUPNB>,<bundle.rankDUPB>" + eof(),
			   "<round(bundle.ANNB)>,<round(bundle.CHNENB)>,<round(bundle.CHENB)>,<round(bundle.STNB)>,<round(bundle.TSNENB)>,<round(bundle.TSENB)>,<round(bundle.OVNENB)>,<round(bundle.OVENB)>" + eof(),
			   "<round(bundle.ANB)>,<round(bundle.CHNEB)>,<round(bundle.CHEB)>,<round(bundle.STNB)>,<round(bundle.TSNEB)>,<round(bundle.TSEB)>,<round(bundle.OVNEB)>,<round(bundle.OVEB)>" + eof(),
			   "<bundle.asserts>" + eof(),
			   "<bundle.aLOCNB>,<bundle.aLOCB>" + eof(),
			   "<bundle.rankASSNB>,<bundle.rankASSB>" );
	print("File generated: ");
	println(outputFile);
	
	map[str, list[str]] fileLines = mapFiles(getFiles(projectLoc));
	printCouplingGraphs(getASS(projectLoc), outputFolder + "<fileName>");
	println("Generating Type I clones - Without brackets");
	printClones(fileLines, bundle.clones1NB, bundle.DUPNB, outputFolder + "<fileName>_1nb.clones");
	println("Generating Type I clones - With brackets");
	printClones(fileLines, bundle.clones1B, bundle.DUPB, outputFolder + "<fileName>_1b.clones");
	println("Generating Type II clones");
	printClones(fileLines, bundle.clones2, bundle.DUP2, outputFolder + "<fileName>_2.clones");
	println("Generating Type II.5 clones");
	printClones(fileLines, bundle.clones25, bundle.DUP25, outputFolder + "<fileName>_2.5.clones");
}

str parseScore(int rank) {
	if (rank == 2) return "++";
	else if (rank == 1) return "+";
	else if (rank == 0) return "o";
	else if (rank == -1) return "-";
	else return "--";
}

void printBundle(loc projectLoc, int threshold1, int threshold2, bool print, bool skipBrkts, bool strict) {
	Bundle bundle = bundle(projectLoc, print, threshold1, threshold2, skipBrkts ? 0 : 1, strict ? 0 : 1);
	
	LineCount bLOC = skipBrkts ? bundle.LOCNB : bundle.LOCB;
	int bDUP = skipBrkts ? bundle.DUPNB : bundle.DUPB;
	CloneStats stats1 = skipBrkts ? bundle.statsDUPNB : bundle.statsDUPB;
	
	str LOC = parseScore(skipBrkts ? bundle.rankLOCNB : bundle.rankLOCB);
	str UCE = parseScore(bundle.rankUCE);
	str UCNE = parseScore(bundle.rankUCNE);
	str US = parseScore(bundle.rankUS);
	str DUP = parseScore(skipBrkts ? bundle.rankDUPNB : bundle.rankDUPB);
	str ASS = parseScore(skipBrkts ? bundle.rankASSNB : bundle.rankASSB);
	
	int totalCCsE = max(1, bundle.riskCCsE[LOW_RISK] + bundle.riskCCsE[MID_RISK] + bundle.riskCCsE[HIGH_RISK] + bundle.riskCCsE[VERY_HIGH_RISK]);
	int totalCCsNE = max(1, bundle.riskCCsNE[LOW_RISK] + bundle.riskCCsNE[MID_RISK] + bundle.riskCCsNE[HIGH_RISK] + bundle.riskCCsNE[VERY_HIGH_RISK]);
	int totalUS = max(1, bundle.riskUS[LOW_RISK] + bundle.riskUS[MID_RISK] + bundle.riskUS[HIGH_RISK] + bundle.riskUS[VERY_HIGH_RISK]);
	
	CouplingGraphs graphs = genCouplingGraphs(getASS(projectLoc));

	println("=== SOURCE-LEVEL METRICS");
	println("LOC metric: <LOC>");
	println("\> <bLOC.code> lines of code\t(<toReal(bLOC.code) * 100 / toReal(bLOC.total)>%)");
	println("\> <bundle.TLOC.total> number of tokens");
	println("\nUNIT COMPLEXITY metric (with|without exception handling): <UCE> | <UCNE>");
	println("\> <bundle.riskCCsE[LOW_RISK]> | <bundle.riskCCsNE[LOW_RISK]> low risk units\t(<toReal(bundle.riskCCsE[LOW_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[LOW_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[MID_RISK]> | <bundle.riskCCsNE[MID_RISK]> medium risk units\t(<toReal(bundle.riskCCsE[MID_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[MID_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[HIGH_RISK]> | <bundle.riskCCsNE[HIGH_RISK]> high risk units\t(<toReal(bundle.riskCCsE[HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[VERY_HIGH_RISK]> | <bundle.riskCCsNE[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskCCsE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\nUNIT SIZE metric: <US>");
	println("\> <bundle.riskUS[LOW_RISK]> low risk units\t\t(<toReal(bundle.riskUS[LOW_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[MID_RISK]> medium risk units\t\t(<toReal(bundle.riskUS[MID_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[HIGH_RISK]> high risk units\t\t(<toReal(bundle.riskUS[HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskUS[VERY_HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("\nDUPLICATION metric: <DUP>");
	println("\> <bDUP> type 1 duplicate lines");
	println("\> <bundle.DUP2> type 2 duplicate tokens");
	println("\> <toReal(bDUP) * 100 / toReal(bLOC.code)>% ratio of duplicates of type 1");
	println("\> <toReal(bundle.DUP2) * 100 / toReal(bundle.TLOC.total)>% ratio of duplicates of type 2");
	println("\> type 1: <stats1.cloneClasses> clone classes and <stats1.cloneInsts> clones");
	println("\> type 1: biggest class: <stats1.biggestClass> instances and biggest clone: <stats1.biggestClone> lines");
	println("\> type 2: <bundle.statsDUP2.cloneClasses> clone classes and <bundle.statsDUP2.cloneInsts> clones");
	println("\> type 2: biggest class: <bundle.statsDUP2.biggestClass> instances and biggest clone: <bundle.statsDUP2.biggestClone> tokens");
	println("\nTEST DENSITY metric: <ASS>");
	println("\> <bundle.asserts> number of assertions / <skipBrkts ? bundle.aLOCNB : bundle.aLOCB> test LOC");
	println("COUPLING metrics:");
	println("! These are just proofs of concept");
	println("! The thresholds are still being benchmarked");
	printCouplingGraph(graphs.intra, "intra-project direct coupling");
	printCouplingGraph(graphs.inter, "inter-project direct coupling");
	printCouplingGraph(graphs.intraVisited, "intra-project coupling");
	printCouplingGraph(graphs.cbo, "CbO coupling");
	printCouplingGraph(graphs.fanin, "Fan-in coupling");
	
	str AN = parseScore(round(skipBrkts ? bundle.ANNB : bundle.ANB));
	str CHNE = parseScore(round(skipBrkts ? bundle.CHNENB : bundle.CHNEB));
	str CHE = parseScore(round(skipBrkts ? bundle.CHENB : bundle.CHEB));
	str TSNE = parseScore(round(skipBrkts ? bundle.TSNENB : bundle.TSNEB));
	str TSE = parseScore(round(skipBrkts ? bundle.TSENB : bundle.TSEB));
	str ST = parseScore(round(skipBrkts ? bundle.STNB : bundle.STB));
	str OVNE = parseScore(round(skipBrkts ? bundle.OVNENB : bundle.OVNEB));
	str OVE = parseScore(round(skipBrkts ? bundle.OVENB : bundle.OVEB));
	
	println();
	println("=== SYSTEM-LEVEL METRICS (with|without exception handling)");
	println("Analysability:\t<AN>\t|\t<AN>");
	println("Changeability:\t<CHE>\t|\t<CHNE>");
	println("Stability:\t<ST>\t|\t<ST>");
	println("Testability:\t<TSE>\t|\t<TSNE>");
	println();
	println("Overall:\t<OVE>\t|\t<OVNE>");
}

private void printCouplingGraph(CouplingGraph cg, str name) {
	list[int] cpls = [];
   		for (loc cls <- cg)
   			cpls += size(cg[cls]);
   			
	ranks = rankFanInRisk(cpls);

	int total = ranks[LOW_RISK] + ranks[MID_RISK] + ranks[HIGH_RISK] + ranks[VERY_HIGH_RISK];
	println("\> <name> COUPLING GRAPH");
	println("\> <ranks[LOW_RISK]> low risk units\t\t(<toReal(ranks[LOW_RISK]) * 100 / toReal(total)>%)");
	println("\> <ranks[MID_RISK]> medium risk units\t\t(<toReal(ranks[MID_RISK]) * 100 / toReal(total)>%)");
	println("\> <ranks[HIGH_RISK]> high risk units\t\t(<toReal(ranks[HIGH_RISK]) * 100 / toReal(total)>%)");
	println("\> <ranks[VERY_HIGH_RISK]> very high risk units\t(<toReal(ranks[VERY_HIGH_RISK]) * 100 / toReal(total)>%)");
}

void printCouplingGraphs(list[Declaration] asts, loc outputFile) {
	println("Generating coupling graphs...");
	CouplingGraphs graphs = genCouplingGraphs(asts);
	println("Writing intra-coupling base graph...");
	printCouplingGraph(graphs.intra, toLocation(outputFile.uri + "_intra_base.graph"));
	println("Writing inter-coupling base graph...");
	printCouplingGraph(graphs.inter, toLocation(outputFile.uri + "_inter_base.graph"));
	println("Writing intra-coupling visited graph...");
	printCouplingGraph(graphs.intraVisited, toLocation(outputFile.uri + "_intra.graph"));
	println("Writing CbO graph...");
	printCouplingGraph(graphs.cbo, toLocation(outputFile.uri + "_cbo.graph"));
	println("Writing fan-in graph...");
	printCouplingGraph(graphs.fanin, toLocation(outputFile.uri + "_fanin.graph"));
}

private void printCouplingGraph(CouplingGraph cg, loc outputFile) {
	str lines = "";
	
	println("Processing graph...");
	for (loc clss <- cg) {
		lines += declToClass(clss) + ":";
		Couplings cpls = cg[clss];
		if (size(cpls) > 0) {
			for (cpl <- cpls) lines += cpl + ",";
		}
		lines = replaceLast(lines, ",", "") + eof();
	}
	println("Dumping data...");
	if (lines != "") lines = replaceLast(lines, eof(), "");
	writeFile(outputFile, lines);
	
	print("File generated: ");
	println(outputFile);
}

void printClones(list[loc] files, loc outputFile, int typ, int threshold, bool skipBrkts, bool strict) {
	MapSnippets clnSnps = ();
	num total = 0.0;
	
	println("Generating clones...");
	<clnSnps, total> = getClones(files, typ, threshold, skipBrkts, strict);
	map[str, list[str]] fileLines = mapFiles(files);
	
	printClones(fileLines, clnSnps, total, outputFile);
}

void printClones(map[str, list[str]] fileLines, MapSnippets clnSnps, num total, loc outputFile) {
	list[CloneClass] clones = [];
	
	println("Generating clone classes...");
	clones = getCloneClasses(clnSnps);
	
	str output = "";
	println("Generating output...");
	for (cloneClass <- clones) {
		for (clone <- cloneClass)
			output += ("<clone.pkg>^<clone.src>^<escapeCode(fileLines[clone.src.uri], clone.src)>" + eof());
		output += eof();
	}
	
	writeFile(outputFile, output);	
	
	print("File generated: ");
	println(outputFile);
}

private map[str, list[str]] mapFiles(list[loc] files) {
	println("Mapping file lines...");
	map[str, list[str]] mFiles = ();
	int _len = size(files);
	int _i = 1;
	for (file <- files) {
		print("Mapping file lines <_i>/<_len>...");
		_i += 1;
		if (file.uri notin mFiles)
			mFiles[file.uri] = readFileLines(file);
		println(" Done.");
	}
	return mFiles;
}

private list[CloneClass] getCloneClasses(MapSnippets clnSnps) {
	list[CloneClass] clones = [];
	for (clnCls <- clnSnps) {
		CloneClass cloneClass = [];
		for (isnp <- clnSnps[clnCls]) {
			str pkg = getPkg(isnp.snp);
			cloneClass += <pkg, isnp.snp.src>;
		}
		clones += [cloneClass];
	}
	return clones;
}

private str escapeCode(list[str] lines, loc src) {
	int last = size(lines);
	str code = intercalate(eof(), lines[src.begin.line..src.end.line+1]);
	
	str before = "";
	str after = "";
	
	if (src.begin.line > 0)
		before = intercalate(eof(), lines[max(src.begin.line - 5, 0)..src.begin.line]);
	
	if (src.end.line < last)
		after = intercalate(eof(), lines[src.end.line+1..min(src.end.line + 6, last)]);
		
	map[str, str] replaces = (
		"\t": "\\t",
		"\r": "\\r",
		"\n": "\\n"
	);
		
	return "<replace(before, replaces)>^<replace(code, replaces)>^<replace(after, replaces)>";
}

str getPkg(Snippet snp) {
	str cls = declToClass(snp.src);
	if (!contains(cls, "."))
		return "default";
	else
		return cls[..findLast(cls, ".")];
}