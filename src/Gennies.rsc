module Gennies

// Project imports
import Utility;
import Volume;
import UnitComplexity;
import UnitSize;
import Duplicate_new;
import Snippet;
import LineAnalysis;

// Rascal base imports
import Set;
import List;
import Map;

import IO;
import String;
import Exception;

import util::Math;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

loc MOCK = |project://mock/|;
loc SRC = MOCK + "src";
int CODELINECOUNTER = 0;
int UNITCOUNTER = 0;
int FILECOUNT = 0;

list[str] possibleComments = ["\t// such comment", "\t/* very multiline comment */"];
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
	genCommentFile(0);
	genCodeFiles(0, 0, FILECOUNT);
	FILECOUNT = 0;
	genDuplicationFile(-1);
}

// ..................................................................GENERATE COMMENT FILE .................................................................. //
@doc {
	.Synopsis
	Generate a file with n comments in the mock project containing all kinds of comments.
}
void genCommentFile(int n) {
	commentsLoc = SRC + "comments.java";
	println(commentsLoc);
	if (n == 0) {
		writeFile(commentsLoc, "");	
	} else {
		writeFile(commentsLoc, 
				"class comments {"+eof(),
				"<genComments(n)>",
				"}");
		println(commentsLoc);
	}
}

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
	println("length of multi: <len>");
	multi = "\t/*";
	for (_ <- [0..len-1]) {
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
	println("length of JavaDoc: <len>");
	doc = "\t/**";
	for (_ <- [0..len-1]) {
		doc += eof() + "\t *";
	}
	return doc + eof() + "\t **/" +eof();
}

// ..................................................................GENERATE CODE FILE .................................................................. //
@doc {
	.Synopsis
	Generate "fileCount" files dividing "lineCount" lines of code across all files, with units conform "unitSize".
}
void genCodeFiles(int lineCount, int unitSize, int fileCount) {
	int linesPerFile = lineCount / fileCount;
	int leftover = lineCount - linesPerFile * fileCount;
	FILECOUNT = max(fileCount, FILECOUNT);
	genCodeFile(linesPerFile + leftover, unitSize, 0);
	for (fileCounter <- [1 .. fileCount]) {
		genCodeFile(linesPerFile, unitSize, fileCounter);
	}
}
@doc {
	.Synopsis
	Generate a codefile with lineCount
}
void genCodeFile(int lineCount, int unitSize, int fileCounter) {
	loc codeFile = SRC + "code<fileCounter>.java";
	println(codeFile);
	if (lineCount == 0) {
		writeFile(codeFile, "");
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

// ..................................................................GENERATE DUPLICATION FILE .................................................................. //
@doc {
	.Synopsis
	Generate a duplication file that complies with the percentage given.
}
void genDuplicationFile(int percentage){
	loc dupFile = SRC + "duplication.java";
	println(dupFile);
	if (percentage == -1) {
		writeFile(dupFile, "");
	} else {
		percentage = percentage % 100;
		writeFile(dupFile,
			"class duplication {" +eof(),
			"<genDuplicateLines(percentage)>" +eof(),
			"<genCodeLines(100 - percentage)>" +eof(),
			"} ");
	}
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

