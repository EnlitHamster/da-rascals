module Gennies

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate;
import Snippet;
import LineAnalysis;

import Set;
import List;
import IO;
import util::Math;
import String;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;


loc MOCK = |project://mock/|;
loc SRC = MOCK + "src";
int CODELINECOUNTER = 0;
int UNITCOUNTER = 0;
int CODEFILECOUNT = 0;

int CLONECLASSFILECOUNT = 0;

bool getSetup() {
	return isDirectory(MOCK);
}

loc getMock() {
	return MOCK;
}

// ..................................................................MOCK PROJECT FUNCTIONS.................................................................. //
@doc {
	.Synopsis
	Create a mock project, set the settings for it to be a proper java project and set the global locations.
}
void setup() {
	loc mockProject =  |project://mock|;
	mkDirectory(mockProject);
	MOCK = mockProject;
	SRC = MOCK + "src";
	mkDirectory(SRC);
	setupProjectSettings(MOCK);
}

@docs {
	.Synopsis
	Set the .project settings of the mock project for it to be recognised as a java project.
}
void setupProjectSettings(loc projectLoc) {
	loc settings = projectLoc + ".project";
	try {
		writeFile(settings, "");
	} catch: 1+1;
	appendToFile( settings,
				"\<?xml version=\"1.0\" encoding=\"UTF-8\"?\>" +eof(),
				"\<projectDescription\>"+eof(),
				"\<name\>mock\</name\>"+eof(),
				"\<comment\> \</comment\>"+eof(),
				"\<projects\>"+eof(),
				"\</projects\>"+eof(),
				"\<buildSpec\>"+eof(),
				"\<buildCommand\>"+eof(),
				"\<name\>org.eclipse.jdt.core.javabuilder\</name\>"+eof(),
				"\<arguments\>"+eof(),
				"\</arguments\>"+eof(),
				"\</buildCommand\>"+eof(),
				"\</buildSpec\>"+eof(),
				"\<natures\>"+eof(),
				"\<nature\>org.eclipse.jdt.core.javanature\</nature\>"+eof(),
				"\</natures\>"+eof(),
				"\</projectDescription\>"+eof());
}

@doc {
	.Synopsis
	Clear all the .java files in the mock project.
}
void clearSrc() {
	genCloneClassFiles(CLONECLASSFILECOUNT, 0, 0, 0);
	genCodeFiles(0, 0, CODEFILECOUNT);
	genCommentFile(0);
	genDuplicationFile(-1);
	genComplexFile(0);
	CODEFILECOUNT = 0;
	CODELINECOUNTER = 0;
	UNITCOUNTER = 0;
}

// ..................................................................GENERATE CLONECLASS FILES .................................................................. //
@doc{
	.Synopsis 
	Generate classCount distinct clone classes each contained in their own file, for each class generate clonesPerClass
	Clones of type typ and with a size large enough to fulfil the threshold.
}
list[loc] genCloneClassFiles(int classesCount, int clonesPerClass,  int typ, int threshold) {
	CLONECLASSFILECOUNT = max(classesCount, CLONECLASSFILECOUNT);
	list[loc] cloneClassFiles = [];
	if (classesCount == 0) {
		for (classid <- [0 .. classesCount + 100]) {
			genClass(0, classid, typ, threshold);
		}
		return cloneClassFiles;
	}
	
	for (classid <- [0 .. classesCount]) {
		cloneClassFiles += genClass(clonesPerClass, classid, typ, threshold);
	}
	
	
	return cloneClassFiles;
}

@doc {
	.Synopsis
	Generate a clone class file with id=classid, containing cloneCount clones of type typ large enough for threshold.
}
loc genClass(int cloneCount, int classid, int typ, int threshold) {
	loc classFile = SRC + "cloneclass<classid>.java";
	if (cloneCount == 0) {
		remove(classFile);
	} else {
		writeFile(classFile, 
						"class CloneClass<classid>{" + eof(), 
						"<genClones(cloneCount, classid, typ, threshold)>" + eof(),
						"}");
	}
	return classFile;
}

@doc {
	Generate cloneCount clones of type typ satisfying the threshold.
}
str genClones(int cloneCount, int classid, int typ, int threshold) {
	str clones = "";
	str codeLine = genCodeLines(1);
	for(cloneid <- [0 .. cloneCount]) {
		clones += genClone(cloneid, classid, typ, threshold, codeLine);
	}
	return clones;
}

list[str] delimeters = ["abstract", "protected", "final", "native", "transient", "private", "public", "volatile","synchronized"];
	

@doc{
	.Synopsis
	Generate a clone for class classid of type typ satisfying the threshold.
}
str genClone(int cloneid, int classid, int typ, int threshold, str codeLine) {
	str clone = "";
	
	int lines = threshold;
	if (typ == 2) {
		lines /= (4 + classid*2);
		codeLine = replaceAll(codeLine, eof(), "");
		codeLine = replaceAll(codeLine, ";", "");
		for(_ <- [0 .. classid]) {
			codeLine += " + 1";
		}
		codeLine += ";" + eof();
	}
	if (lines * (4 + classid *2) < threshold) {
		lines += 1;
	}
	
	for(_ <- [0 .. lines]) {
			clone += codeLine;
	}

	str delim = genCodeLines(1);
	if (typ == 2) delim = delimeters[classid];
	return clone + delim + eof();
}



// ..................................................................GENERATE CODE FILE .................................................................. //
@doc {
	.Synopsis
	Generate "fileCount" files dividing "lineCount" lines of code across all files, with units conform "unitSize".
}
list[loc] genCodeFiles(int lineCount, int unitSize, int fileCount) {
	CODEFILECOUNT = max(fileCount, CODEFILECOUNT);
	list[loc] codeFiles = [];
	if (lineCount == 0) {
		for (fileCounter <- [0 .. fileCount + 100]) {
			genCodeFile(0, unitSize, fileCounter);
		}
		return codeFiles;
	}
	int linesPerFile = lineCount / fileCount;
	int leftover = lineCount - linesPerFile * fileCount;
	codeFiles += genCodeFile(linesPerFile + leftover, unitSize, 0);
	for (fileCounter <- [1 .. fileCount]) {
		codeFiles += genCodeFile(linesPerFile, unitSize, fileCounter);
	}
	return codeFiles;
}

@doc {
	.Synopsis
	Generate a codefile with lineCount
}
loc genCodeFile(int lineCount, int unitSize, int fileCounter) {
	loc codeFile = SRC + "code<fileCounter>.java";
	//println(codeFile);
	if (lineCount == 0) {
		remove(codeFile);
	} else {
		lineCount -= 1;
		totalUnitCount = lineCount / unitSize;
		leftover = lineCount - (totalUnitCount * unitSize);
		writeFile(codeFile,
			"class code<fileCounter>{" +eof(),
			"<genCodeLines(leftover)>" +eof(),
			"<genUnits(totalUnitCount, unitSize)>" +eof(),
			"} ");
	}
	return codeFile;
}

@doc {
	.Synopsis
	Generate "totalUnitCount" unique functions of length "unitSize".
}
str genUnits(int totalUnitCount, int unitSize) {
	units = "";
	for (_ <- [0 .. totalUnitCount]) {
		units += genUnit(unitSize);
	}
	return units;
}

@doc {
	.Synopsis
	Generate a unit of length "unitSize".
}
str genUnit(int unitSize) {
	unit = "\tvoid unit<UNITCOUNTER>() {" + eof();;
	UNITCOUNTER += 1;
	unit += genCodeLines(unitSize-1);
	unit += "\t}" +eof();
	return unit;
}

@doc {
	.Synopsis
	Generate n unique codelines.
}
str genCodeLines(int n) {
	code = "";
	for (_ <- [0 .. n]) {
		code += "\tint i_<CODELINECOUNTER> = 0;" +eof();
		CODELINECOUNTER += 1;
	}
	return code;
}

// ..................................................................GENERATE COMMENT FILES .................................................................. //
@doc {
	.Synopsis
	Generate a file with n comments in the mock project containing all kinds of comments.
}
loc genCommentFile(int n) {
	commentFile = SRC + "comments.java";
	//println(commentFile);
	if (n == 0) {
		remove(commentFile);	
	} else {
		writeFile(commentFile, 
				"class comments {"+eof(),
				"<genComments(n)>",
				"}");
	}
	return commentFile;
}

list[str] possibleComments = ["\t// such comment", "\t/* very multiline comment */"];

@doc {
	.Synopsis
	Generate a string of n lines of comments, containing all kinds of comments, randomly picked.
}
str genComments(int n) {
	str comments = "";
	if (n == 1) return possibleComments[arbInt(2)] + eof();
	int cur = 0;
	while (cur < n) {
		<comment, inc> = selectComment(cur, n);
		comments += comment;
		cur += inc;
	}
	return comments;
}

@doc {
	.Synopsis
	Randomly select a type of comment to be returned and added to the file.
}
tuple[str, int] selectComment(int cur, int n) {
	str comment = "";
	int inc = 1;
	int r = arbInt(4);
	if (r > 1) {
		len = arbInt(n-cur) + 1;
		inc = len;
		if (r == 2) {
			comment = makeMulti(len);
		} else if (r == 3) {
			comment = makeDoc(len);
		} 
	} else {
		comment = possibleComments[r] +eof();
	}
	return <comment, inc>;
}

@doc {
	.Synopsis
	Generate a multiline comment of length n.
}
str makeMulti(int len) {
	if (len == 0) return "";
	if (len == 1) return "\t/* multi of length 1 */" +eof();
	//println("length of multi: <len>");
	multi = "\t/*";
	for (_ <- [0..len-2]) {
		multi += eof() + "\t *";
	}
	return multi + eof() + "\t */" +eof();
}

@doc {
	.Synopsis
	Generate a JavaDoc comment of length n.
}
str makeDoc(int len) {
	if (len == 0) return "";
	if (len == 1) return "\t/** JavaDoc of length 1 **/" +eof();
	//println("length of JavaDoc: <len>");
	doc = "\t/**";
	for (_ <- [0..len-2]) {
		doc += eof() + "\t *";
	}
	return doc + eof() + "\t **/" +eof();
}

// ..................................................................GENERATE DUPLICATION FILE .................................................................. //
@doc {
	.Synopsis
	Generate a duplication file that complies with the percentage given.
}
loc genDuplicationFile(int percentage){
	loc dupFile = SRC + "duplication.java";
	if (percentage == -1) {
		remove(dupFile);
	} else {
		percentage = percentage % 101;
		writeFile(dupFile,
			"class duplication {" +eof(),
			"<genDuplicateLines(percentage)>" +eof(),
			"<genCodeLines(100 - percentage-1)>",
			"} ");
	}
	return dupFile;
}

@doc {
	.Synopsis
	Generate "dupCount" duplicate lines of code.
}
str genDuplicateLines(int dupCount) {
	duplicateLines = "";
	code = genCodeLines(1);
	for (_ <- [0 .. dupCount]) {
		duplicateLines += code;
	}
	return duplicateLines;
}

// ..................................................................GENERATE CYCLOMATIC COMPLEXITY FILE .................................................................. //
loc genComplexFile(int cc) {
	loc cycloFile = SRC + "complex.java";
	if (cc == 0) {
		remove(cycloFile);
	} else {
		writeFile(cycloFile,
			"class cyclomaticComplexity {" +eof(),
			"\tvoid cyclo () {" + eof(),
			"<genComplexLines(cc-1)>",
			"\t} " +eof(),
			"} ");
	}
	return cycloFile;
}

list[str] ones = ["for(;;) {}", "int[] vars;" +eof()+"\tfor(int var:vars) {}", "if(true) {}", "do{} while(true);", "while(true) {}"]; 
list[str] twos = ["try{} catch (IOException e) {} catch (RuntimeException e) {} finally {}", "if(true || false) {}", "if(true && false) {}"];
list[str] trees = ["switch(1) {case 1: break; case 2:  break; case 3:  break; default: int x = 0;}", "if(true && false || true) {}"];

str genComplexLines(int cc) {
	complex = "";
	int choice = 0;
	while (cc > 0) {
		choice = min(cc, (arbInt(3)+1));
		complex += choose(choice);
		cc -= choice;
	}
	return complex;
}

str choose(int choice) {
	if (choice == 1) {
		return "\t" + ones[arbInt(size(ones))] + eof();
	} else if (choice == 2) {
		return "\t" +twos[arbInt(size(twos))] + eof();
	} else {
		return "\t" + trees[arbInt(size(trees))] +eof();
	}
}

