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
		case Declaration decl: \method(_,_,_,_,_): uSize += countLines(decl.src, false).code - 1;
		case Declaration decl: \constructor(_,_,_,_): uSize += countLines(decl.src, false).code - 1;
	}
	return uSize;
}

map[str,int] rankSizeRisk(list[int] sizes) {
	return rankRisk(sizes, 24, 31, 48);
}

int rankUnitSize(map[str,int] risks, bool print) {
	return scoreRank( risks,
					  <0.123, 0.061, 0.008>,
					  <0.276, 0.161, 0.070>,
					  <0.354, 0.250, 0.140>,
					  <0.540, 0.430, 0.242>,
					  print );
}