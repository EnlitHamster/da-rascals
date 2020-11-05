module Bundle

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate;
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

private Bundle bundle(loc projectLoc) {
	// Saving the project files/ASTs as they are used by all metric calculators
	list[loc] projectFiles = getFiles(projectLoc);
	list[Declaration] asts = getASS(projectLoc);
	
	// VOLUME
	int LOC = countLinesFiles(projectFiles, false);
	int rankLOC = getLocRank(LOC, false);
	
	// UNIT COMPLEXITY
	list[CC] CCs = calcAllCC(asts);
	
	map[str,int] riskCCsNoExp = rankCCsRisk(CCs, false);
	map[str,int] riskCCsExp = rankCCsRisk(CCs, true);
	
	int rankUCNoExp = rankComplexity(riskCCsNoExp, false);
	int rankUCExp = rankComplexity(riskCCsExp, false);
	
	// UNIT SIZE
	list[int] unitSizes = getUnitsLoc(asts);
	map[str,int] riskUnitSizes = rankSizeRisk(unitSizes);
	int rankUS = rankUnitSize(riskUnitSizes, false);
	
	// DUPLICATES
	int duplicates = getDuplicateLines(projectLoc, false, false);
	int rankDUP = getDuplicationRank(toReal(duplicates) / toReal(LOC), false);
	
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

void printBundle(loc projectLoc) {
	Bundle bundle = bundle(projectLoc);

	str LOC = parseScore(bundle.rankLOC);
	str UCE = parseScore(bundle.rankUCE);
	str UCNE = parseScore(bundle.rankUCNE);
	str US = parseScore(bundle.rankUS);
	str DUP = parseScore(bundle.rankDUP);

	println("+++ Code-level Metrics");
	println("LOC metric: <LOC>");
	println("\> <bundle.LOC> lines of code");
	println("UC metric (with|without exception handling): <UCNE> | <UCE>");
	println("\> <bundle.riskCCsNE[LOW_RISK]> | <bundle.riskCCsE[LOW_RISK]> low risk units");
	println("\> <bundle.riskCCsNE[MID_RISK]> | <bundle.riskCCsE[MID_RISK]> medium risk units");
	println("\> <bundle.riskCCsNE[HIGH_RISK]> | <bundle.riskCCsE[HIGH_RISK]> high risk units");
	println("\> <bundle.riskCCsNE[VERY_HIGH_RISK]> | <bundle.riskCCsE[VERY_HIGH_RISK]> very high risk units");
	println("US metric: <US>");
	println("\> <bundle.riskUS[LOW_RISK]> low risk units");
	println("\> <bundle.riskUS[MID_RISK]> medium risk units");
	println("\> <bundle.riskUS[HIGH_RISK]> high risk units");
	println("\> <bundle.riskUS[VERY_HIGH_RISK]> very high risk units");
	println("DUP metric: <DUP>");
	println("\> <bundle.DUP> duplicate lines");
	println("\> <toReal(bundle.DUP) * 100 / toReal(bundle.LOC)>% ratio of duplicates");
	
	real analysability = (toReal(bundle.rankLOC) + toReal(bundle.rankDUP) + toReal(bundle.rankUS)) / 3.0;
	real changeabilityNE = (toReal(bundle.rankUCNE) + toReal(bundle.rankDUP)) / 2.0;
	real changeabilityE = (toReal(bundle.rankUCE) + toReal(bundle.rankDUP)) / 2.0;
	real testabilityNE = (toReal(bundle.rankUCNE) + toReal(bundle.rankUS)) / 2.0;
	real testabilityE = (toReal(bundle.rankUCE) + toReal(bundle.rankUS)) / 2.0;
}