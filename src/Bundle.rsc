module Bundle

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate_new;
import Snippet;

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
private alias Bundle = tuple[ int LOC,
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
							  int rankDUP ];

private Bundle bundle(loc projectLoc, bool print) {
	// Saving the project files/ASTs as they are used by all metric calculators
	list[loc] projectFiles = getFiles(projectLoc);
	list[Declaration] asts = getASS(projectLoc);
	
	// VOLUME
	if (print) println("=== VOLUME LOGS");
	
	int LOC = countLinesFiles(projectFiles, print);
	int rankLOC = getLocRank(LOC, print);
	
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
	
	int duplicates = getDuplicateLines(projectLoc, print);
	int rankDUP = getDuplicationRank(toReal(duplicates) / toReal(LOC), print);
	
	// Output
	return <LOC, rankLOC, CCs, riskCCsNoExp, riskCCsExp, rankUCNoExp, rankUCExp, unitSizes, riskUnitSizes, rankUS, duplicates, rankDUP>;
}

str parseScore(int rank) {
	if (rank == 2) return "++";
	else if (rank == 1) return "+";
	else if (rank == 0) return "o";
	else if (rank == -1) return "-";
	else return "--";
}

void printBundle(loc projectLoc, bool print) {
	Bundle bundle = bundle(projectLoc, print);

	str LOC = parseScore(bundle.rankLOC);
	str UCE = parseScore(bundle.rankUCE);
	str UCNE = parseScore(bundle.rankUCNE);
	str US = parseScore(bundle.rankUS);
	str DUP = parseScore(bundle.rankDUP);
	
	int totalCCsE = bundle.riskCCsE[LOW_RISK] + bundle.riskCCsE[MID_RISK] + bundle.riskCCsE[HIGH_RISK] + bundle.riskCCsE[VERY_HIGH_RISK];
	int totalCCsNE = bundle.riskCCsNE[LOW_RISK] + bundle.riskCCsNE[MID_RISK] + bundle.riskCCsNE[HIGH_RISK] + bundle.riskCCsNE[VERY_HIGH_RISK];
	int totalUS = bundle.riskUS[LOW_RISK] + bundle.riskUS[MID_RISK] + bundle.riskUS[HIGH_RISK] + bundle.riskUS[VERY_HIGH_RISK];

	println("=== SOURCE-LEVEL METRICS");
	println("LOC metric: <LOC>");
	println("\> <bundle.LOC> lines of code");
	println("UC metric (with|without exception handling): <UCE> | <UCNE>");
	println("\> <bundle.riskCCsE[LOW_RISK]> | <bundle.riskCCsNE[LOW_RISK]> low risk units (<toReal(bundle.riskCCsE[LOW_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[LOW_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[MID_RISK]> | <bundle.riskCCsNE[MID_RISK]> medium risk units (<toReal(bundle.riskCCsE[MID_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[MID_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[HIGH_RISK]> | <bundle.riskCCsNE[HIGH_RISK]> high risk units (<toReal(bundle.riskCCsE[HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("\> <bundle.riskCCsE[VERY_HIGH_RISK]> | <bundle.riskCCsNE[VERY_HIGH_RISK]> very high risk units (<toReal(bundle.riskCCsE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsE)>% | <toReal(bundle.riskCCsNE[VERY_HIGH_RISK]) * 100 / toReal(totalCCsNE)>%)");
	println("US metric: <US>");
	println("\> <bundle.riskUS[LOW_RISK]> low risk units (<toReal(bundle.riskUS[LOW_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[MID_RISK]> medium risk units (<toReal(bundle.riskUS[MID_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[HIGH_RISK]> high risk units (<toReal(bundle.riskUS[HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("\> <bundle.riskUS[VERY_HIGH_RISK]> very high risk units (<toReal(bundle.riskUS[VERY_HIGH_RISK]) * 100 / toReal(totalUS)>%)");
	println("DUP metric: <DUP>");
	println("\> <bundle.DUP> duplicate lines");
	println("\> <toReal(bundle.DUP) * 100 / toReal(bundle.LOC)>% ratio of duplicates");
	
	real analysability = (toReal(bundle.rankLOC) + toReal(bundle.rankDUP) + toReal(bundle.rankUS)) / 3.0;
	real changeabilityNE = (toReal(bundle.rankUCNE) + toReal(bundle.rankDUP)) / 2.0;
	real changeabilityE = (toReal(bundle.rankUCE) + toReal(bundle.rankDUP)) / 2.0;
	real testabilityNE = (toReal(bundle.rankUCNE) + toReal(bundle.rankUS)) / 2.0;
	real testabilityE = (toReal(bundle.rankUCE) + toReal(bundle.rankUS)) / 2.0;
	
	real overallNE = (analysability + changeabilityNE + testabilityNE) / 3.0;
	real overallE = (analysability + changeabilityE + testabilityE) / 3.0;
	
	str AN = parseScore(round(analysability));
	str CHNE = parseScore(round(changeabilityNE));
	str CHE = parseScore(round(changeabilityE));
	str TSNE = parseScore(round(testabilityNE));
	str TSE = parseScore(round(testabilityE));
	str OVNE = parseScore(round(overallNE));
	str OVE = parseScore(round(overallE));
	
	println();
	println("=== SYSTEM-LEVEL METRICS (with|without exception handling)");
	println("Analysability:\t<AN>\t|\t<AN>");
	println("Changeability:\t<CHE>\t|\t<CHNE>");
	println("Testability:\t<TSE>\t|\t<TSNE>");
	println();
	println("Overall:\t<OVE>\t|\t<OVNE>");
}