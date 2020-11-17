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
							  real ANNB,
							  real ANB,
							  real CHNENB,
							  real CHNEB,
							  real CHENB,
							  real CHEB,
							  real TSNE,
							  real TSE,
							  real OVNENB,
							  real OVNEB,
							  real OVENB,
							  real OVEB ];

private Bundle bundle(loc projectLoc, bool print, int skipBrkts) {
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
	
	// SYSTEM-LEVEL
	
	real ANNB = (toReal(rankLOCNB) + toReal(rankDUPNB) + toReal(rankUS)) / 3.0;
	real ANB = (toReal(rankLOCB) + toReal(rankDUPB) + toReal(rankUS)) / 3.0;
	real CHNENB = (toReal(rankUCNoExp) + toReal(rankDUPNB)) / 2.0;
	real CHNEB = (toReal(rankUCNoExp) + toReal(rankDUPB)) / 2.0;
	real CHENB = (toReal(rankUCExp) + toReal(rankDUPNB)) / 2.0;
	real CHEB = (toReal(rankUCExp) + toReal(rankDUPB)) / 2.0;
	real TSNE = (toReal(rankUCNoExp) + toReal(rankUS)) / 2.0;
	real TSE = (toReal(rankUCExp) + toReal(rankUS)) / 2.0;
	
	real OVNENB = (ANNB + CHNENB + TSNE) / 3.0;
	real OVNEB = (ANB + CHNEB + TSNE) / 3.0;
	real OVENB = (ANNB + CHENB + TSE) / 3.0;
	real OVEB = (ANB + CHEB + TSE) / 3.0;
	
	// Output
	return <LOCNB, LOCB, rankLOCNB, rankLOCB, CCs, riskCCsNoExp, riskCCsExp, rankUCNoExp, rankUCExp, unitSizes, riskUnitSizes, 
			rankUS, duplicatesNB, duplicatesB, rankDUPNB, rankDUPB, ANNB, ANB, CHNENB, CHNEB, CHENB, CHEB, TSNE, TSE, OVNENB,
			OVNEB, OVENB, OVEB>;
}

//private alias Bundle = tuple[ LineCount LOCNB,
//							  LineCount LOCB,
//							  int rankLOCNB,
//							  int rankLOCB,
//							  list[CC] CCs,
//							  map[str,int] riskCCsNE,
//							  map[str,int] riskCCsE,
//							  int rankUCNE,
//							  int rankUCE,
//							  list[int] US,
//							  map[str,int] riskUS,
//							  int rankUS,
//							  int DUPNB,
//							  int DUPB,
//							  int rankDUPNB,
//							  int rankDUPB,
//							  real ANNB,
//							  real ANB,
//							  real CHNENB,
//							  real CHNEB,
//							  real CHENB,
//							  real CHEB,
//							  real TSNE,
//							  real TSE,
//							  real OVNENB,
//							  real OVNEB,
//							  real OVENB,
//							  real OVEB ];

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
			   "<round(bundle.ANNB)>,<round(bundle.CHNENB)>,<round(bundle.CHENB)>,<round(bundle.TSNE)>,<round(bundle.TSE)>,<round(bundle.OVNENB)>,<round(bundle.OVENB)>" + eof(),
			   "<round(bundle.ANB)>,<round(bundle.CHNEB)>,<round(bundle.CHEB)>,<round(bundle.TSNE)>,<round(bundle.TSE)>,<round(bundle.OVNEB)>,<round(bundle.OVEB)>" );
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
	
	int totalCCsE = max(1, bundle.riskCCsE[LOW_RISK] + bundle.riskCCsE[MID_RISK] + bundle.riskCCsE[HIGH_RISK] + bundle.riskCCsE[VERY_HIGH_RISK]);
	int totalCCsNE = max(1, bundle.riskCCsNE[LOW_RISK] + bundle.riskCCsNE[MID_RISK] + bundle.riskCCsNE[HIGH_RISK] + bundle.riskCCsNE[VERY_HIGH_RISK]);
	int totalUS = max(1, bundle.riskUS[LOW_RISK] + bundle.riskUS[MID_RISK] + bundle.riskUS[HIGH_RISK] + bundle.riskUS[VERY_HIGH_RISK]);

	println("=== SOURCE-LEVEL METRICS");
	println("LOC metric: <LOC>");
	println("\> <bLOC.code> lines of code\t(<toReal(bLOC.code) * 100 / toReal(bLOC.total)>%)");
	println("UC metric (with|without exception handling): <UCE> | <UCNE>");
	println("\> <bundle.riskCCsE[LOW_RISK]> | <bundle.riskCCsNE[LOW_RISK]> low risk units\t(<toReal(bundle.riskCCsE[LOW_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[LOW_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[MID_RISK]> | <bundle.riskCCsNE[MID_RISK]> medium risk units\t(<toReal(bundle.riskCCsE[MID_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[MID_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[HIGH_RISK]> | <bundle.riskCCsNE[HIGH_RISK]> high risk units\t(<toReal(bundle.riskCCsE[HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[VERY_HIGH_RISK]> | <bundle.riskCCsNE[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskCCsE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("US metric: <US>");
	println("\> <bundle.riskUS[LOW_RISK]> low risk units\t\t(<toReal(bundle.riskUS[LOW_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[MID_RISK]> medium risk units\t\t(<toReal(bundle.riskUS[MID_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[HIGH_RISK]> high risk units\t\t(<toReal(bundle.riskUS[HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[VERY_HIGH_RISK]> very high risk units\t(<toReal(bundle.riskUS[VERY_HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("DUP metric: <DUP>");
	println("\> <bDUP> duplicate lines");
	println("\> <toReal(bDUP) * 100 / toReal(bLOC.code)>% ratio of duplicates");
	println("COUPLING metrics");
	//printCouplingGraphs(getASS(projectLoc));
	
	str AN = parseScore(round(skipBrkts ? bundle.ANNB : bundle.ANB));
	str CHNE = parseScore(round(skipBrkts ? bundle.CHNENB : bundle.CHNEB));
	str CHE = parseScore(round(skipBrkts ? bundle.CHENB : bundle.CHEB));
	str TSNE = parseScore(round(bundle.TSNE));
	str TSE = parseScore(round(bundle.TSE));
	str OVNE = parseScore(round(skipBrkts ? bundle.OVNENB : bundle.OVNEB));
	str OVE = parseScore(round(skipBrkts ? bundle.OVENB : bundle.OVEB));
	
	println();
	println("=== SYSTEM-LEVEL METRICS (with|without exception handling)");
	println("Analysability:\t<AN>\t|\t<AN>");
	println("Changeability:\t<CHE>\t|\t<CHNE>");
	println("Testability:\t<TSE>\t|\t<TSNE>");
	println();
	println("Overall:\t<OVE>\t|\t<OVNE>");
}

void printCouplingGraphs(list[Declaration] asts) {
	CouplingGraphs graphs = genCouplingGraphs(asts);
	//TODO: Print rankings
}

void printCouplingGraphs(list[Declaration] asts, loc outputFile) {
	println("Generating coupling graphs...");
	CouplingGraphs graphs = genCouplingGraphs(asts);
	println("Writing inter-coupling base graph...");
	printCouplingGraph(graphs.inter, toLocation(outputFile.uri + "_inter_base.graph"));
	println("Writing intra-coupling base graph...");
	printCouplingGraph(graphs.intra, toLocation(outputFile.uri + "_intra_base.graph"));
	println("Writing inter-coupling visited graph...");
	printCouplingGraph(graphs.interVisited, toLocation(outputFile.uri + "_inter_visited.graph"));
	println("Writing intra-coupling visited graph...");
	printCouplingGraph(graphs.intraVisited, toLocation(outputFile.uri + "_intra_visited.graph"));
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