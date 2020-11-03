module Utility

import IO;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public str LOW_RISK = "low";
public str MID_RISK = "medium";
public str HIGH_RISK = "high";
public str VERY_HIGH_RISK = "very high";

public alias RiskRank = tuple[int mid, int high, int vhigh];

map[str, int] rankRisk(list[int] metrics, int low, int mid, int high) {
	map[str, int] risks = (	LOW_RISK:0, 
							MID_RISK:0, 
							HIGH_RISK:0, 
							VERY_HIGH_RISK: 0 );
							
	for (metric <- metrics) {
		if 		(metric <= low) 	risks[LOW_RISK] += 1;
		else if (metric <= mid) 	risks[MID_RISK] += 1;
		else if (metric <= high) 	risks[HIGH_RISK] += 1;
		else 						risks[VERY_HIGH_RISK] += 1;
	}
	return risks;
}

bool checkRiskRank(int mid, int high, int vhigh, RiskRank rank) {
	return mid <= rank.mid 
		&& high <= rank.high 
		&& vhigh <= rank.vhigh;
}

int scoreRank(map[str,int] ranks, RiskRank top, RiskRank midtop, RiskRank mid, RiskRank midbot, bool print) {
	int total = ranks[LOW_RISK] + ranks[MID_RISK] + ranks[HIGH_RISK] + ranks[VERY_HIGH_RISK];
	
	int lowRisk 	= ranks[LOW_RISK] * 100 / total;
	int midRisk 	= ranks[MID_RISK] * 100 / total;
	int highRisk 	= ranks[HIGH_RISK] * 100 / total;
	int vhighRisk 	= ranks[VERY_HIGH_RISK] * 100 / total;
	
	if (checkRiskRank(midRisk, highRisk, vhighRisk, top)) {
		if (print) println("Risk Ranking: ++");
	 	return 2;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, midtop)) {
		if (print) println("Risk Ranking: +");
		return 1;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, mid)) {
		if (print) println("Risk Ranking: o");
		return 0;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, midbot)) {
		if (print) println("Risk Ranking: -");
		return -1;
	} else {
		if (print) println("Risk Ranking: --");
		return -2;
	}
}

//@doc {
//	Get the AST from all the files in the project.
//}
//list[Declaration] getASTs (loc projectLoc) {
// 	M3 model = createM3FromEclipseProject(projectLoc);
// 	list[Declaration] asts = [];
// 	for (m <- model.containment, m[0].scheme == "java+compilationUnit") {
// 		asts += createAstFromFile(m[0],true);
// 	}
//	return asts;
//}

@doc{
	.Synopsis
	Get a list of all file locations in the project.
}
list[loc] getFiles (loc projectLoc) {
 	M3 model = createM3FromEclipseProject(projectLoc);
 	list[loc] fileLocs = [];
 	for (m <- model.containment, m[0].scheme == "java+compilationUnit") {
 		fileLocs += m[0];
	}
	return fileLocs;
}

@doc {
	Get the AST from all the files in the project.
}
list[Declaration] getASS (loc projectLoc) {
 	list[Declaration] asts = [];
 	for (file <- getFiles(projectLoc)) {
 		asts += createAstFromFile(file,true);
 	}
	return asts;
}