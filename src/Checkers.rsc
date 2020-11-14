module Checkers

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate_new;
import Snippet;
import LineAnalysis;
import Gennies;

// Rascal base imports
import Set;
import List;
import Map;
import IO;
import String;
import util::Math;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

int NUMTESTS = 100;

test bool checkLOC() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated codefiles to see whether LOC calculation holds:");
	for (_ <- [0 .. 100]) {
		clearSrc();
		int lines = arbInt(1000) + 100;	
		int unitSize = arbInt(91) +10;
		int fileCount = arbInt(10) + 1;
		genCodeFiles(lines, unitSize, fileCount);
		allConform = allConform && countLinesFiles(getFiles(getMock()), false, true)[0] == lines;
	}
	clearSrc();
	return allConform;
}