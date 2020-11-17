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
import Exception;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

int NUMTESTS = 100;

int setNumTests(int new) {
	if (new < 1) throw IllegalArgument();
	NUMTESTS = new;
	return NUMTESTS;
}

@doc {
	.Synopsis
	Check whether the LOC metric is correct, by randomly generating sets of files with an amount of lines across the set.
}
test bool checkLOC() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated codefiles to see whether LOC calculation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		int lines = arbInt(4000) + 200;	
		int unitSize = arbInt(91) +10;
		int fileCount = arbInt(10) + 1;
		genCodeFiles(lines, unitSize, fileCount);
		allConform = allConform && countLinesFiles(getFiles(getMock()), false, true)[0] == lines;
	}
	clearSrc();
	return allConform;
}

@doc {
	.Synopsis
	Check whether the comment counting, and skipping in terms of LOC holds, by randomly generating files with all types of comments.
}
test bool checkComment() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated commentFiles to see whether comment counting holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		int comments = arbInt(1000) + 100;	
		genCommentFile(comments);
		LineCount counts = countLinesFiles(getFiles(getMock()), false, true);
		allConform = allConform && counts[2] == comments && counts[0] == 1;
	}
	clearSrc();
	return allConform;
}

@doc {
	.Synopsis
	Check whether the unit size metric is calculated correctly, by randomly generating files with set unit size.
}
test bool checkUnitSize() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated codefile with random unitsizes to see whether unit size evaluation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		int lines = arbInt(1000) + 1000;	
		int unitSize = arbInt(91) +10;
		int fileCount = arbInt(10) + 1;
		genCodeFiles(lines, unitSize, fileCount);
		list[int] unitSizes = getUnitsLoc(getASS(getMock()));
		list[int] noDups = dup(unitSizes);
		allConform = allConform && noDups[0] == unitSize && size(noDups) == 1;
	}
	clearSrc();
	return allConform;
}

@doc {
	.Synopsis
	Check whether the cyclomatic complexity metric is calculated correctly, by randomly generating files with complex structures.
}
test bool checkComplexity() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated files with complexity structures to see whether cyclomatic complexity evaluation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		int cc = arbInt(200) + 100;	
		genComplexFile(cc);
		list[CC] found = calcAllCC(getASS(getMock()));
		println("<cc>, <found>");
		allConform = allConform && (found[0][0] + found[0][1]) == cc;
	}
	clearSrc();
	return allConform;
}

@doc {
	.Synopsis
	Check whether the duplication metric is calculated correctly, by randomly generating files with random but known amount of duplication.
}
test bool checkDuplication() {
	if (!getSetup()) setup();
	allConform = true;
	println("testing <NUMTESTS> random combinations of generated files with a set percentage of duplication to see whether the duplication calculation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		int dupPercent = arbInt(100) + 1;	
		genDuplicationFile(dupPercent);
		int dupLoc = getDuplicateLines(getMock(), false, true);
		if (dupPercent <= 6) {
			allConform = allConform && (dupLoc == 0);
		} else {
			if (dupPercent != dupLoc) return false;
			allConform = allConform && (dupPercent == dupLoc);
		}
	}
	clearSrc();
	return allConform;
}