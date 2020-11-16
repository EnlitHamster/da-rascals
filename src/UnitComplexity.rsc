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

// From various sources we found different ways of computing Cyclomatic Complexity of Java Code.
// Due to this, we believe there is no one way of doing so. Even with McCabe's approach, there is
// no real consensus, mostly due to how to treat break and continue statements. Here we lay the case
// for NOT considering them, as we take at heart the definition of the metric itself; that is:
//
//		a quantitative measure of the number of linearly independent 
//		paths through a program's source code.
//
// Even though some sources consider them as cases for increasing the Cyclomatic Complexity, we find 
// his not to be true. For us, continue and break statements do not create new linearly independent 
// paths, as they involve no evaluation and no branching. Similarly some suggest the return statements
// that are not the last one, yield an increase of the Cyclomatic Complexity. Again, we do not support
// this thesis as these do not add linearly independent paths for the same reasons as per continue and
// break.

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