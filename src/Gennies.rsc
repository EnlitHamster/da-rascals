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

loc mock = |project://mock/|;
loc src = mock + "src";
int codelineCounter = 0;
int unitCounter = 0;
int fileCounter = 0;

list[str] possibleComments = ["\t// such comment", "\t/* very multiline comment */"];
// ..................................................................MOCK PROJECT FUNCTIONS.................................................................. //
void setup() {
	loc mockProject =  |project://mock|;
	mkDirectory(mockProject);
	mkDirectory(src);
	setupProjectSettings(mock);
	mock = mockProject;
	src = mock + "src";
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

void clearSrc() {
	genCommentFile(0);
	genCodeFile(0, 0, 0);
	genDuplicationFile(-1);
}

// ..................................................................GENERATE COMMENT FILE .................................................................. //
void genCommentFile(int n) {
	commentsLoc = src + "comments.java";
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

str genComments(int n) {
	str comments = "";
	int r = 0;
	if (n == 1) return possibleComments[arbInt(2)] + eof();
	int cur = 0;
	while (cur < n) {
		<comment, inc> = selectComment(cur, n);
		comments += comment;
		cur += inc;
	}
	return comments;
}

tuple[str, int] selectComment(int cur, int n) {
	comment = "";
	int inc = 1;
	r = arbInt(4);
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

str makeMulti(int len) {
	if (len == 0) return "";
	println("length of multi: <len>");
	multi = "\t/*";
	for (_ <- [0..len-1]) {
		multi += eof() + "\t *";
	}
	return multi + eof() + "\t */" +eof();
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
void genCodeFile(int lineCount, int unitSize, int fileCount) {
	loc codeFile = src + "code<fileCount>.java";
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

str genUnits(int totalUnitCount, int unitSize) {
	units = "";
	for (_ <- [0 .. totalUnitCount]) {
		units += genUnit(unitSize);
	}
	return units;
}

str genUnit(int unitSize) {
	unit = "\tvoid unit<unitCounter>() {" + eof();;
	unitCounter += 1;
	unit += genCodeLines(unitSize-1);
	unit += "\t}" +eof();
	return unit;
}

str genCodeLines(int n) {
	code = "";
	for (_ <- [0 .. n]) {
		code += "\tint i_<codelineCounter> = 0;" +eof();
		codelineCounter += 1;
	}
	return code;
}

// ..................................................................GENERATE DUPLICATION FILE .................................................................. //
void genDuplicationFile(int percentage){
	loc dupFile = src + "duplication.java";
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

str genDuplicateLines(int dupCount) {
	duplicateLines = "";
	code = genCodeLines(1);
	for (_ <- [0 .. dupCount]) {
		duplicateLines += code;
	}
	return duplicateLines;
}

