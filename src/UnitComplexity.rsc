module UnitComplexity

// Project imports
import Utility;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public str LOW_RISK = "low";
public str MID_RISK = "medium";
public str HIGH_RISK = "high";
public str VERY_HIGH_RISK = "very high";

int getCyclomaticComplexity(Statement stmt, bool expHndl) {
	// Starts from 1 for 1 path's necessary
	int pi = 1;
	// CC for exception handling
	int piExp = 0;
	visit (stmt) {
		// Conditional statements yield +1
		case \foreach(_,_,_): pi += 1;
		case \for(_,_,_,_): pi += 1;
		case \for(_,_,_): pi += 1;
		case \if(_,_): pi += 1;
		case \if(_,_,_): pi += 1;
		case \do(_,_): pi += 1;
		case \while(_,_): pi += 1;
		case \conditional(_,_,_): pi += 1;
		// Each case of the switch is +1
		case \case(_): pi += 1;
		case \defaultCase(): pi += 1;
		// Each logical clause yields +1
		case \infix(_,"||",_): pi += 1;
		case \infix(_,"&&",_): pi += 1;
		// Each exception handling stmt yields +1
		case \throw(_): piExp += 1;
		case \catch(_,_): piExp += 1;
		case \try(_,_,_): piExp += 1;
	}
	
	if (expHndl) return pi + piExp;
	else return pi;
}

int getCyclomaticComplexity(Statement stmt, list[Expression] exps, bool expHndl) {
	return (expHndl ? size(exps) : 0) + getCyclomaticComplexity(stmt,expHndl);
} 

list[int] calcAllCC(list[Declaration] asts, bool expHndl) {
	list[int] CCs = [];
	visit (asts) {
		case \method(_,_,_,exps,impl): CCs += getCyclomaticComplexity(impl,exps,expHndl);
		case \constructor(_,_,exps,impl): CCs += getCyclomaticComplexity(impl,exps,expHndl);
	}
	return CCs;
}

map[str, int] rankCCsRisk(list[int] ccs, int low, int mid, int high) {
	map[str, int] risks = (	LOW_RISK:0, 
							MID_RISK:0, 
							HIGH_RISK:0, 
							VERY_HIGH_RISK: 0 );
	for (cc <- ccs) {
		if (cc <= low) risks[LOW_RISK] += 1;
		else if (cc <= mid) risks[MID_RISK] += 1;
		else if (cc <= high) risks[HIGH_RISK] += 1;
		else risks[VERY_HIGH_RISK] += 1;
	}
	return risks;
}

map[str,int] rankCCsRisk(list[int] ccs) {
	return rankCCsRisk(ccs, 10, 20, 50);
}

public alias RiskRank = tuple[int mid, int high, int vhigh];

bool checkRiskRank(int mid, int high, int vhigh, RiskRank rank) {
	return mid <= rank.mid && high <= rank.high && vhigh <= rank.vhigh;
}

int rankComplexity(map[str,int] ranks, RiskRank top, RiskRank midtop, RiskRank mid, RiskRank midbot, bool print) {
	int total = ranks[LOW_RISK] + ranks[MID_RISK] + ranks[HIGH_RISK] + ranks[VERY_HIGH_RISK];
	int lowRisk = ranks[LOW_RISK] * 100 / total;
	int midRisk = ranks[MID_RISK] * 100 / total;
	int highRisk = ranks[HIGH_RISK] * 100 / total;
	int vhighRisk = ranks[VERY_HIGH_RISK] * 100 / total;
	
	//if (print) println("Total: <total>\nLow Risk: <lowRisk>\nMedium Risk: <midRisk>\nHigh Risk: <highRisk>\nVery High Risk: <vhighRisk>");
	
	if (checkRiskRank(midRisk, highRisk, vhighRisk, top)) {
		if (print) println("Complexity Risk Ranking: ++");
	 	return 2;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, midtop)) {
		if (print) println("Complexity Risk Ranking: +");
		return 1;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, mid)) {
		if (print) println("Complexity Risk Ranking: o");
		return 0;
	} else if (checkRiskRank(midRisk, highRisk, vhighRisk, midbot)) {
		if (print) println("Complexity Risk Ranking: -");
		return -1;
	} else {
		if (print) println("Complexity Risk Ranking: --");
		return -2;
	}
}

int rankComplexity(map[str,int] ranks, bool print) {
	return rankComplexity( ranks,
						   <25, 00, 00>,
						   <30, 05, 00>,
						   <40, 10, 00>,
						   <50, 15, 05>,
						   print );
}