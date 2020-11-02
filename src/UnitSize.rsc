module UnitSize

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

list[int] getUnitsLoc(list[Declaration] asts) {
	list[int] uSize = [];
	visit (asts) {
		case Declarations decl: \method(_,_,_,_,_): uSize += decl.end.line - decl.begin.line;
		case Declarations decl: \constructor(_,_,_,_): uSize += decl.end.line - decl.begin.line;
	}
}
