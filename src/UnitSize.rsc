module UnitSize

// Project imports
import Utility;
import LineAnalysis;

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

list[int] getUnitsLoc(list[Declaration] asts) {
	list[int] uSize = [];
	visit (asts) {
		// The -1 is due to the fact that the prototype is included as well.
		case Declaration decl: \method(_,_,_,_,_): uSize += countLines(decl.src, false)[0] - 1;
		case Declaration decl: \constructor(_,_,_,_): uSize += countLines(decl.src, false)[0] - 1;
	}
	return uSize;
}

map[str,int] rankSizeRisk(list[int] sizes) {
	return rankRisk(sizes, 30, 65, 100);
}

int rankUnitSize(map[str,int] risks, bool print) {
	return scoreRank( risks,
					  <20, 03, 00>,
					  <30, 05, 00>,
					  <40, 10, 03>,
					  <50, 20, 05>,
					  print );
}