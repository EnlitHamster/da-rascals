module TestQuality

// Project imports
import Utility;
import LineAnalysis;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

int getAssertcount(list[Declaration] asts) {
	int assertCount = 0;
	visit (asts) {
		case \assert(_): assertCount += 1;
		case \assert(_,_): assertCount += 1;
	}
	return assertCount;
}