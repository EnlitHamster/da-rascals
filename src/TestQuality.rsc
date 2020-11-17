module TestQuality

// Project imports
import Utility;
import LineAnalysis;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

list[loc] getAsserts(list[Declaration] asts) {
	list[loc] asserters = [];
	visit (asts) {
		case ass: \assert(_): asserters += ass.src;
		case ass: \assert(_,_): asserters += ass.src;
	}
	return asserters;
}