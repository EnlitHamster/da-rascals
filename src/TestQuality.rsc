module TestQuality

// Project imports
import Utility;
import LineAnalysis;

import IO;
import List;

import util::Math;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

list[loc] getAsserts(list[Declaration] asts) {
	list[Declaration] methods = [];
	visit (asts) {
		case m: \method(_,_,_,_,_): methods += m;
	}

	list[loc] asserters = [];
	for (met: \method(_,_,_,_,impl) <- methods)
		visit (impl) {
			case ass: \assert(_): asserters += met.src;
			case ass: \assert(_,_): asserters += met.src;
		}
	return asserters;
}

tuple[int,int] getTestQualityMetric(list[loc] asserts, bool print, bool skipBrkts) {
	int total = 0;
	for (ass <- asserts) total += countLines(ass, skipBrkts).code;
	return <scoreRank(-toReal(size(asserts))/toReal(total), -0.189, -0.100, -0.072, -0.015, print), total>;
}