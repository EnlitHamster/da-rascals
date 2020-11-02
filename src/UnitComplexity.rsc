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

map[str,int] rankCCsRisk(list[int] ccs) {
	return rankRisk(ccs, 10, 20, 50);
}

int rankComplexity(map[str,int] ranks, bool print) {
	return scoreRank( ranks,
					  <25, 00, 00>,
					  <30, 05, 00>,
					  <40, 10, 00>,
					  <50, 15, 05>,
					  print );
}