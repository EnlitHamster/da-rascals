module Checkers

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate;
import Snippet;
import LineAnalysis;
import Gennies;

// Rascal base imports
import Set;
import List;
import IO;
import String;
import util::Math;
import Exception;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;

int NUMTESTS = 100;

// Open the mock project src dir for a cool show during tests :)

@doc {
	.Synopsis
	Set the number of random checks done per test.
}
int setNumTests(int new) {
	if (new < 1) throw IllegalArgument();
	NUMTESTS = new;
	return NUMTESTS;
}

test bool checkClones() {
	if (!getSetup()) setup();
	bool allConform = true;
	//int typ = 1;
	list[loc] cloneClassFiles = [];
	int classCount;
	int clonePerClass;
	int threshold;
	int foundClassCount;
	int foundCloneInstances;
	for (typ <- [1.. 3]) {
		println("testing <NUMTESTS> random combinations of generated clone class files  to see whether clone detection of type <typ> holds");
		for (_ <- [0 .. NUMTESTS]) {
			clearSrc(); clearSrc();
			classCount= arbInt(9) +1;
		 	clonePerClass = arbInt(10) + 10;
	 		threshold = arbInt(21) + 5;
	 		 if (typ == 2) {
	 			threshold  = 4 * classCount * 2;
	 			clonePerClass = 2;
	 		}
		 	
		 	cloneClassFiles = genCloneClassFiles(classCount, clonePerClass, typ, threshold);
		 	list[loc] filurs = getFiles(getMock());

		 	tuple[MapSnippets, int] gottenClones = getClones(cloneClassFiles, typ, threshold, false);
		 	MapSnippets clones = gottenClones[0];
		 	int count = gottenClones[1];
			foundClassCount = 0;
			foundCloneInstances = 0;
			for (key <- clones) {
				foundClassCount += 1;
				foundCloneInstances += size(clones[key]);
			}
			allConform = allConform && foundClassCount == classCount && foundCloneInstances == (classCount * clonePerClass);
			if (!allConform) break;
		}
		if (allConform) {
			clearSrc();
		} else {
			println("Threshold: <threshold>,");
			println("Generated <classCount> classe(s) and found <foundClassCount> classe(s)");
			println("Generated <classCount * clonePerClass> clone(s) and found <foundCloneInstances> clone(s)");
			println("Generated file(s): <cloneClassFiles>");
			return allConform;
		}
	}
	clearSrc();
	return allConform;
}

@doc {
	.Synopsis
	Check whether the LOC metric is correct, by randomly generating sets of files with an amount of lines across the set.
}
test bool checkLOC() {
	if (!getSetup()) setup();
	allConform = true;
	int LOC;
	int lines;
	list[loc] codeFilesLocs;
	println("testing <NUMTESTS> random combinations of generated codefiles to see whether LOC calculation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc(); clearSrc();
		lines = arbInt(4000) + 200;	
		int unitSize = arbInt(91) +10;
		int fileCount = arbInt(10) + 1;
		codeFilesLocs = genCodeFiles(lines, unitSize, fileCount);
		LOC = countLinesFiles(getFiles(getMock()), false, true)[0];
		allConform = allConform && LOC  == lines;
		if (!allConform) break;
	}
	if (allConform) {
		clearSrc();
	} else {
		println("Generated <lines> lines of code but calculated <LOC> LOC");
		println("Generated file(s): <codeFilesLocs>");
	}
	return allConform;
}

@doc {
	.Synopsis
	Check whether the comment counting, and skipping in terms of LOC holds, by randomly generating files with all types of comments.
}
test bool checkComment() {
	if (!getSetup()) setup();
	allConform = true;
	int comments;
	loc comFile;
	LineCount counts;
	println("testing <NUMTESTS> random combinations of generated commentFiles to see whether comment counting holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc(); clearSrc();
		comments = arbInt(1000) + 100;	
		comFile = genCommentFile(comments);
		counts = countLinesFiles(getFiles(getMock()), false, true);
		allConform = allConform && counts[2] == comments && counts[0] == 1;
		if (!allConform) break;
	}
	if (allConform) {
		clearSrc();
	} else {
		println("Generated <comments> lines of different comments but calculated <counts[2]> comments");
		println("Found LOC should be equal to one: LOC = <counts[0]>");
		println("Generated file: <comFile>");
	}	
	return allConform;
}

@doc {
	.Synopsis
	Check whether the unit size metric is calculated correctly, by randomly generating files with set unit size.
}
test bool checkUnitSize() {
	if (!getSetup()) setup();
	allConform = true;
	int unitSize;
	list[loc] codeFilesLocs;
	list[int] noDups;
	println("testing <NUMTESTS> random combinations of generated codefiles with random unitsizes to see whether unit size evaluation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc(); clearSrc();
		int lines = arbInt(1000) + 1000;	
		unitSize = arbInt(91) +10;
		int fileCount = arbInt(10) + 1;
		codeFilesLocs = genCodeFiles(lines, unitSize, fileCount);
		list[int] unitSizes = getUnitsLoc(getASS(getMock()));
		noDups = dup(unitSizes);
		allConform = allConform && noDups[0] == unitSize && size(noDups) == 1;
		if (!allConform) break;
	}
	if (allConform) {
		clearSrc();
	} else {
		println("\nGenerated units of size <unitSize> and calculated <noDups[0]> unit size");
		println(noDups);
		println("Generated file(s): <codeFilesLocs>\n");
	}
	return allConform;
}

@doc {
	.Synopsis
	Check whether the cyclomatic complexity metric is calculated correctly, by randomly generating files with complex structures.
}
test bool checkComplexity() {
	if (!getSetup()) setup();
	allConform = true;
	loc compFile;
	int cc = 0;
	list[CC] found = [];
	println("testing <NUMTESTS> random combinations of generated files with complexity structures to see whether cyclomatic complexity evaluation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc(); clearSrc();
		cc = arbInt(200) + 100;	
		compFile = genComplexFile(cc);
		found = calcAllCC(getASS(getMock()));
		while (found == [] || found == [<1,0>]) { // sometimes eclipse struggles with reading in the file so keep trying to access it till it works
			found = calcAllCC(getASS(getMock()));
		}
		allConform = allConform && (found[0][0] + found[0][1]) == cc;
		if (!allConform) break;
	}
	if (allConform) {
		clearSrc();
	} else {
		println("\nGenerated structures with <cc> complexity and calculated <found[0][0]+found[0][1]> CC");
		println("Generated file: <compFile>\n");
	}
	return allConform;
}

@doc {
	.Synopsis
	Check whether the duplication metric is calculated correctly, by randomly generating files with random but known amount of duplication.
}
test bool checkDuplication() {
	if (!getSetup()) setup();
	allConform = true;
	int dupPercent;
	loc dupFile;
	int dupLoc;
	println("testing <NUMTESTS> random combinations of generated files with a set percentage of duplication to see whether the duplication calculation holds:");
	for (_ <- [0 .. NUMTESTS]) {
		clearSrc();
		dupPercent = arbInt(100) + 1;	
		dupFile = genDuplicationFile(dupPercent);
		//list[loc] files, int typ, int threshold, bool print, bool skipBrkts		
		dupLoc = getDuplicateLines(getFiles(getMock()), 1, 6, false, true);
		if (dupPercent <= 6) {
			allConform = allConform && (dupLoc == 0);
		} else {
			if (dupPercent != dupLoc) return false;
			allConform = allConform && (dupPercent == dupLoc);
		}
		if (!allConform) break;
	}
	if (allConform) {
		clearSrc();
	} else {
		println("\nGenerated <dupPercent> duplicated LOC and found <dupLoc> duplicated LOC");
		println("Generated file: <dupFile>\n");
	}	
	return allConform;
}