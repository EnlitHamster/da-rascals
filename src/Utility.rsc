module Utility

// Rascal base imports
import IO;
import String;
import List;

import util::Math;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public str LOW_RISK = "low";
public str MID_RISK = "medium";
public str HIGH_RISK = "high";
public str VERY_HIGH_RISK = "very high";

public alias RiskRank = tuple[num mid, num high, num vhigh];

map[str, int] rankRisk(list[num] metrics, num low, num mid, num high) {
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

bool checkRiskRank(num mid, num high, num vhigh, RiskRank rank) {
	return mid <= rank.mid 
		&& high <= rank.high 
		&& vhigh <= rank.vhigh;
}

int scoreRank(map[str,num] ranks, RiskRank top, RiskRank midtop, RiskRank mid, RiskRank midbot, bool print) {
	real total = toReal(ranks[LOW_RISK] + ranks[MID_RISK] + ranks[HIGH_RISK] + ranks[VERY_HIGH_RISK]);
	
	if (total == 0) return 2;
	
	real lowRisk 	= ranks[LOW_RISK] / total;
	real midRisk 	= ranks[MID_RISK] / total;
	real highRisk 	= ranks[HIGH_RISK] / total;
	real vhighRisk 	= ranks[VERY_HIGH_RISK] / total;
	
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

@doc {
	.Synopsis
	The function depends on the LOC generated by <<countLinesFiles>> which is then ranked against custom values.
}
int scoreRank(num metric, num top, num midtop, num mid, num midbot, bool print) {
	if (metric <= top) {
		if (print) println("Ranking: ++");
		return 2;
	} else if (metric <= midtop) {
		if (print) println("Ranking: +");
		return 1;
	} else if (metric <= mid) {
		if (print) println("Ranking: o");
		return 0;
	} else if (metric <= midbot) {
		if (print) println("Ranking: -");
		return -1;
	} else {
		if (print) println("Ranking: --");
		return -2;
	}
}

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
list[Declaration] getASS (list[loc] files) {
 	list[Declaration] asts = [];
 	for (file <- files) {
 		asts += createAstFromFile(file,true);
 	}
	return asts;
}

list[Declaration] getASS(loc projectLoc) {
	return getASS(getFiles(projectLoc));
}

tuple[str,bool] removeInlineComments(str code) {
	// This is to avoid situations like /*/ where this is not a closed comment.
	str final = replaceAll(code, "/*/", "/*");
	
	// Checks whether the lines leaves an open comment
	bool opensCom = (findLast(final, "/*") > findLast(final, "*/"));

	// Checking for */ (multiline comment closer)
	if (contains(final, "*/")) {
		list[str] codes = split("*/", final);
		// taking only odd indexes as even would be comments
		final = "";
		for (i <- [0..size(codes)]) if (i % 2 == 1) final += codes[i];
	}
	
	println(final);
	
	// Checking for /* (multiline comment opener)
	if (contains(final, "/*")) {
		list[str] codes = split("/*", final);
		// taking only even indexes as odd would be comments
		final = "";
		for (i <- [0..size(codes)]) if (i % 2 == 0) final += codes[i];
	}
	
	println(final);
	
	return <split("//", final)[0],opensCom>; // Only the leftmost side can be code;
}

void printMap(map[&a, &b] mappy) {
	println("==================================MAP==================================");
	for(key <- mappy) {
		println("<key> : <mappy[key]>\n");
	}
	println("=======================================================================");
}


str listToStr(list[int] lst) {
	str s = toString(lst[0]);
	for (i <- [1..size(lst)]) s += "," + toString(lst[i]);
	return s;
}