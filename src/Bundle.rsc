module Bundle

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate_new;
import Snippet;
import LineAnalysis;
import Coupling;
import TestQuality;

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

// Used to pass data from bundling to output
private alias Bundle = tuple[ LineCount LOCNB,
							  LineCount LOCB,
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
							  int rankDUPNB,
							  int rankDUPB,
							  int asserts,
							  int aLOCNB,
							  int aLOCB,
							  int ASSNB,
							  int ASSB,
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
							  real OVEB ];

Bundle bundle(loc projectLoc, bool print, int skipBrkts) {
	// Saving the project files/ASTs as they are used by all metric calculators
	list[loc] projectFiles = getFiles(projectLoc);
	list[Declaration] asts = getASS(projectFiles);
	
	// VOLUME
	if (print) println("=== VOLUME LOGS");
	
	LineCount LOCNB = NLC();
	LineCount LOCB = NLC();
	int rankLOCNB = -1;
	int rankLOCB = -1;
	
	if (skipBrkts % 2 == 0) {
		LOCNB = countLinesFiles(projectFiles, print, true);
		rankLOCNB = getLocRank(LOCNB.code, print);
	}
	
	if (skipBrkts > 0) {
		LOCB = countLinesFiles(projectFiles, print, false);
		rankLOCB = getLocRank(LOCB.code, print);
	}
	
	// UNIT COMPLEXITY
	if (print) println("=== UNIT COMPLEXITY LOGS");
	
	list[CC] CCs = calcAllCC(asts);
	
	map[str,int] riskCCsNoExp = rankCCsRisk(CCs, false);
	map[str,int] riskCCsExp = rankCCsRisk(CCs, true);
	
	int rankUCNoExp = rankComplexity(riskCCsNoExp, print);
	int rankUCExp = rankComplexity(riskCCsExp, print);
	
	// UNIT SIZE
	if (print) println("=== UNIT SIZE LOGS");
	
	list[int] unitSizes = getUnitsLoc(asts);
	map[str,int] riskUnitSizes = rankSizeRisk(unitSizes);
	int rankUS = rankUnitSize(riskUnitSizes, print);
	
	// DUPLICATES
	if (print) println("=== DUPLICATES LOGS");
	
	int duplicatesNB = -1;
	int duplicatesB = -1;
	int rankDUPNB = -1;
	int rankDUPB = -1;
	
	if (skipBrkts % 2 == 0) {
		duplicatesNB = getDuplicateLines(projectFiles, print, true);
		rankDUPNB = getDuplicationRank(toReal(duplicatesNB) / toReal(LOCNB.code), print);
	}
	
	if (skipBrkts > 0) {
		duplicatesB = getDuplicateLines(projectFiles, print, false);
		rankDUPB = getDuplicationRank(toReal(duplicatesB) / toReal(LOCB.code), print);
	}
	
	// TEST QUALITY
	list[loc] asserts = getAsserts(asts);
	int aLOCNB = -1;
	int aLOCB = -1;
	int rankASSNB = -1;
	int rankASSB = -1;
	
	if (skipBrkts % 2 == 0) <rankASSNB, aLOCNB> = getTestQualityMetric(asserts, print, true);
	if (skipBrkts > 0) <rankASSB, aLOCB> = getTestQualityMetric(asserts, print, false);
	
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
	return <LOCNB, LOCB, rankLOCNB, rankLOCB, CCs, riskCCsNoExp, riskCCsExp, rankUCNoExp, rankUCExp, unitSizes, riskUnitSizes, 
			rankUS, duplicatesNB, duplicatesB, rankDUPNB, rankDUPB, size(asserts), aLOCNB, aLOCB, rankASSNB, rankASSB, ANNB, 
			ANB, CHNENB, CHNEB, CHENB, CHEB, STNB, STB, TSNENB, TSNEB, TSENB, TSEB, OVNENB, OVNEB, OVENB, OVEB>;
}

void printBundle(loc projectLoc, loc outputFolder, str fileName) {
	println("Generating bundle...");
	Bundle bundle = bundle(projectLoc, false, 2);
	println("Processing lists...");
	list[int] CCsNE = [];
	list[int] CCsE = [];
	for (<pi,piExp> <- bundle.CCs) {
		CCsNE += pi;
		CCsE += (pi + piExp);
	}
	
	println("Dumping data...");
	loc outputFile = outputFolder + "<fileName>.metrics";
	writeFile( outputFile, 
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
			   "<bundle.DUPNB>,<bundle.DUPB>" + eof(),
			   "<bundle.rankDUPNB>,<bundle.rankDUPB>" + eof(),
			   "<round(bundle.ANNB)>,<round(bundle.CHNENB)>,<round(bundle.CHENB)>,<round(bundle.STNB)>,<round(bundle.TSNENB)>,<round(bundle.TSENB)>,<round(bundle.OVNENB)>,<round(bundle.OVENB)>" + eof(),
			   "<round(bundle.ANB)>,<round(bundle.CHNEB)>,<round(bundle.CHEB)>,<round(bundle.STNB)>,<round(bundle.TSNEB)>,<round(bundle.TSEB)>,<round(bundle.OVNEB)>,<round(bundle.OVEB)>" + eof(),
			   "<bundle.asserts>,<bundle.aLOCNB>,<bundle.aLOCB>,,<bundle.ASSNB>,<bundle.ASSB>" );
	print("File generated: ");
	println(outputFile);
	
	printCouplingGraphs(getASS(projectLoc), outputFolder + "<fileName>");
}

str parseScore(int rank) {
	if (rank == 2) return "++";
	else if (rank == 1) return "+";
	else if (rank == 0) return "o";
	else if (rank == -1) return "-";
	else return "--";
}

void printBundle(loc projectLoc, bool print, bool skipBrkts) {
	Bundle bundle = bundle(projectLoc, print, skipBrkts ? 0 : 1);
	
	LineCount bLOC = skipBrkts ? bundle.LOCNB : bundle.LOCB;
	int bDUP = skipBrkts ? bundle.DUPNB : bundle.DUPB;
	
	str LOC = parseScore(skipBrkts ? bundle.rankLOCNB : bundle.rankLOCB);
	str UCE = parseScore(bundle.rankUCE);
	str UCNE = parseScore(bundle.rankUCNE);
	str US = parseScore(bundle.rankUS);
	str DUP = parseScore(skipBrkts ? bundle.rankDUPNB : bundle.rankDUPB);
	str ASS = parseScore(skipBrkts ? bundle.ASSNB : bundle.ASSB);
	
	int totalCCsE = max(1, bundle.riskCCsE[LOW_RISK] + bundle.riskCCsE[MID_RISK] + bundle.riskCCsE[HIGH_RISK] + bundle.riskCCsE[VERY_HIGH_RISK]);
	int totalCCsNE = max(1, bundle.riskCCsNE[LOW_RISK] + bundle.riskCCsNE[MID_RISK] + bundle.riskCCsNE[HIGH_RISK] + bundle.riskCCsNE[VERY_HIGH_RISK]);
	int totalUS = max(1, bundle.riskUS[LOW_RISK] + bundle.riskUS[MID_RISK] + bundle.riskUS[HIGH_RISK] + bundle.riskUS[VERY_HIGH_RISK]);
	
	CouplingGraphs graphs = genCouplingGraphs(getASS(projectLoc));

	println("=== SOURCE-LEVEL METRICS");
	println("LOC metric: <LOC>");
	println("\> <bLOC.code> lines of code\t(<toReal(bLOC.code) * 100 / toReal(bLOC.total)>%)");
	println("UNIT COMPLEXITY metric (with|without exception handling): <UCE> | <UCNE>");
	println("\> <bundle.riskCCsE[LOW_RISK]> | <bundle.riskCCsNE[LOW_RISK]> low risk units\t(<toReal(bundle.riskCCsE[LOW_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[LOW_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[MID_RISK]> | <bundle.riskCCsNE[MID_RISK]> medium risk units\t(<toReal(bundle.riskCCsE[MID_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[MID_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[HIGH_RISK]> | <bundle.riskCCsNE[HIGH_RISK]> high risk units\t(<toReal(bundle.riskCCsE[HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[VERY_HIGH_RISK]> | <bundle.riskCCsNE[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskCCsE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("UNIT SIZE metric: <US>");
	println("\> <bundle.riskUS[LOW_RISK]> low risk units\t\t(<toReal(bundle.riskUS[LOW_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[MID_RISK]> medium risk units\t\t(<toReal(bundle.riskUS[MID_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[HIGH_RISK]> high risk units\t\t(<toReal(bundle.riskUS[HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskUS[VERY_HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("DUPLICATION metric: <DUP>");
	println("\> <bDUP> duplicate lines");
	println("\> <toReal(bDUP) * 100 / toReal(bLOC.code)>% ratio of duplicates");
	println("TEST DENSITY metric: <ASS>");
	println("\> <bundle.asserts> number of assertions / <skipBrkts ? bundle.aLOCNB : bundle.aLOCB> test LOC");
	println("COUPLING metrics:");
	println("! There are just proofs of concept");
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
	printCouplingGraph(graphs.fanIn, toLocation(outputFile.uri + "_fanin.graph"));
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