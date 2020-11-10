module Bundle

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate_new;
import Snippet;
import LineAnalysis;

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
private alias Bundle = tuple[ LineCount LOC,
							  int rankLOC,
							  list[CC] CCs,
							  map[str,int] riskCCsNE,
							  map[str,int] riskCCsE,
							  int rankUCNE,
							  int rankUCE,
							  list[int] US,
							  map[str,int] riskUS,
							  int rankUS,
							  int DUP,
							  int rankDUP,
							  real AN,
							  real CHNE,
							  real CHE,
							  real TSNE,
							  real TSE,
							  real OVNE,
							  real OVE ];

private Bundle bundle(loc projectLoc, bool print, bool skipBrkts) {
	// Saving the project files/ASTs as they are used by all metric calculators
	list[loc] projectFiles = getFiles(projectLoc);
	list[Declaration] asts = getASS(projectLoc);
	
	// VOLUME
	if (print) println("=== VOLUME LOGS");
	
	LineCount LOC = countLinesFiles(projectFiles, print, skipBrkts);
	int rankLOC = getLocRank(LOC.code, print);
	
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
	
	int duplicates = getDuplicateLines(projectLoc, print, skipBrkts);
	int rankDUP = getDuplicationRank(toReal(duplicates) / toReal(LOC.code), print);
	
	// SYSTEM-LEVEL
	
	real AN = (toReal(rankLOC) + toReal(rankDUP) + toReal(rankUS)) / 3.0;
	real CHNE = (toReal(rankUCNoExp) + toReal(rankDUP)) / 2.0;
	real CHE = (toReal(rankUCExp) + toReal(rankDUP)) / 2.0;
	real TSNE = (toReal(rankUCNoExp) + toReal(rankUS)) / 2.0;
	real TSE = (toReal(rankUCExp) + toReal(rankUS)) / 2.0;
	
	real OVNE = (AN + CHNE + TSNE) / 3.0;
	real OVE = (AN + CHE + TSE) / 3.0;
	
	// Output
	return <LOC, rankLOC, CCs, riskCCsNoExp, riskCCsExp, rankUCNoExp, rankUCExp, unitSizes, riskUnitSizes, rankUS, duplicates, rankDUP, AN, CHNE, CHE, TSNE, TSE, OVNE, OVE>;
}

// private alias Bundle = tuple[ LineCount LOC,
//							  int rankLOC,
//							  list[CC] CCs,
//							  map[str,int] riskCCsNE,
//							  map[str,int] riskCCsE,
//							  int rankUCNE,
//							  int rankUCE,
//							  list[int] US,
//							  map[str,int] riskUS,
//							  int rankUS,
//							  int DUP,
//							  int rankDUP,
//							  real AN,
//							  real CHNE,
//							  real CHE,
//							  real TSNE,
//							  real TSE,
//							  real OVNE,
//							  real OVE ];

void printBundle(loc projectLoc, loc outputFolder, str fileName, bool print, bool skipBrkts) {
	Bundle bundle = bundle(projectLoc, print, skipBrkts);
	loc outputFile = outputFolder + "<fileName>.metrics";
	writeFile( outputFile, 
			   "<bundle.LOC.code>,<bundle.LOC.empty>,<bundle.LOC.comment>,<bundle.LOC.total>" + eof(),
		       "<bundle.rankLOC>" + eof(),
			   "<bundle.riskCCsNE[LOW_RISK]>,<bundle.riskCCsNE[MID_RISK]>,<bundle.riskCCsNE[HIGH_RISK]>,<bundle.riskCCsNE[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.riskCCsE[LOW_RISK]>,<bundle.riskCCsE[MID_RISK]>,<bundle.riskCCsE[HIGH_RISK]>,<bundle.riskCCsE[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.rankUCNE>,<bundle.rankUCE>" + eof(),
			   "<bundle.riskUS[LOW_RISK]>,<bundle.riskUS[MID_RISK]>,<bundle.riskUS[HIGH_RISK]>,<bundle.riskUS[VERY_HIGH_RISK]>" + eof(),
			   "<bundle.rankUS>" + eof(),
			   "<bundle.DUP>" + eof(),
			   "<bundle.rankDUP>" + eof(),
			   "<round(bundle.AN)>,<round(bundle.CHNE)>,<round(bundle.CHE)>,<round(bundle.TSNE)>,<round(bundle.TSE)>,<round(bundle.OVNE)>,<round(bundle.OVE)>" );
	println(outputFile);
}

str parseScore(int rank) {
	if (rank == 2) return "++";
	else if (rank == 1) return "+";
	else if (rank == 0) return "o";
	else if (rank == -1) return "-";
	else return "--";
}

void printBundle(loc projectLoc, bool print, bool skipBrkts) {
	Bundle bundle = bundle(projectLoc, print, skipBrkts);

	str LOC = parseScore(bundle.rankLOC);
	str UCE = parseScore(bundle.rankUCE);
	str UCNE = parseScore(bundle.rankUCNE);
	str US = parseScore(bundle.rankUS);
	str DUP = parseScore(bundle.rankDUP);
	
	int totalCCsE = max(1, bundle.riskCCsE[LOW_RISK] + bundle.riskCCsE[MID_RISK] + bundle.riskCCsE[HIGH_RISK] + bundle.riskCCsE[VERY_HIGH_RISK]);
	int totalCCsNE = max(1, bundle.riskCCsNE[LOW_RISK] + bundle.riskCCsNE[MID_RISK] + bundle.riskCCsNE[HIGH_RISK] + bundle.riskCCsNE[VERY_HIGH_RISK]);
	int totalUS = max(1, bundle.riskUS[LOW_RISK] + bundle.riskUS[MID_RISK] + bundle.riskUS[HIGH_RISK] + bundle.riskUS[VERY_HIGH_RISK]);

	println("=== SOURCE-LEVEL METRICS");
	println("LOC metric: <LOC>");
	println("\> <bundle.LOC.code> lines of code\t(<toReal(bundle.LOC.code) * 100 / toReal(bundle.LOC.total)>%)");
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
	println("\> <bundle.DUP> duplicate lines");
	println("\> <toReal(bundle.DUP) * 100 / toReal(bundle.LOC.code)>% ratio of duplicates");
	
	str AN = parseScore(round(bundle.AN));
	str CHNE = parseScore(round(bundle.CHNE));
	str CHE = parseScore(round(bundle.CHE));
	str TSNE = parseScore(round(bundle.TSNE));
	str TSE = parseScore(round(bundle.TSE));
	str OVNE = parseScore(round(bundle.OVNE));
	str OVE = parseScore(round(bundle.OVE));
	
	println();
	println("=== SYSTEM-LEVEL METRICS (with|without exception handling)");
	println("Analysability:\t<AN>\t|\t<AN>");
	println("Changeability:\t<CHE>\t|\t<CHNE>");
	println("Testability:\t<TSE>\t|\t<TSNE>");
	println();
	println("Overall:\t<OVE>\t|\t<OVNE>");
}