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

public alias CC = tuple[int pi, int piExp];

CC getCyclomaticComplexity(Statement stmt) {
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
		// Each case of the switch is +1
		case \case(_): pi += 1;
		// Each logical clause yields +1
		case \infix(_,"||",_): pi += 1;
		case \infix(_,"&&",_): pi += 1;
		case \conditional(_,_,_): pi += 1;
		// Each exception handling stmt yields +1
		case \catch(_,_): piExp += 1;
	}
	
	return <pi, piExp>;
}

CC getCyclomaticComplexity(Statement stmt, list[Expression] exps) {
	CC cc = getCyclomaticComplexity(stmt);
	return <cc.pi, size(exps) + cc.piExp>;
} 

list[CC] calcAllCC(list[Declaration] asts) {
	list[CC] CCs = [];
	visit (asts) {
		case \method(_,_,_,exps,impl): CCs += getCyclomaticComplexity(impl,exps);
		case \constructor(_,_,exps,impl): CCs += getCyclomaticComplexity(impl,exps);
	}
	return CCs;
}

map[str,int] rankCCsRisk(list[CC] ccs, bool expHndl) {
	list[int] rankCCs = [];
	for (cc <- ccs) rankCCs += expHndl ? (cc.pi + cc.piExp) : cc.pi;
	return rankRisk(rankCCs, 10, 20, 50);
}

int rankComplexity(map[str,int] ranks, bool print) {
	return scoreRank( ranks,
					  <0.25, 0.00, 0.00>,
					  <0.30, 0.05, 0.00>,
					  <0.40, 0.10, 0.00>,
					  <0.50, 0.15, 0.05>,
					  print );
}