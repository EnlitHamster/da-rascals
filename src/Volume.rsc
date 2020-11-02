module Volume

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

tuple[int, int, int, int] countLines(loc fileLoc, bool print) {
	int ctr = 0;
	int empty = 0;
	int comment = 0;
	int al = 0;
	bool inCom = false;
	
	for (line <- (readFileLines(fileLoc))) {
		al += 1;
		if (!inCom) {
			if ((/^\s*$/ := line)) {
				empty += 1;
				println("EMPTY :: <line>");
			} else if ((/^\s*\/\/.*/ := line) || (/\/\*.*?\*\// := line)) {
				comment += 1;
				if (print) println("COMMENT :: <line>");
			} else {
				// handle multiline
				if (/^\s*\/\*.*/ := line) {
					inCom = true;
					comment += 1;
					if (print) println("COMMENT :: <line>");
					continue;
				}
				ctr += 1;
				if (print) println("CODE :: <line>");
			}
		} else {
			comment += 1;
			if (print) println("COMMENT :: <line>");
			end = contains(line, "*/");
			if (end) {
				inCom = false;
			}
		}		
	}
	return <ctr, empty, comment, al>;
}

int countLinesFiles(list[loc] fileLocs, bool print) {
	int ctr = 0;
	int empty = 0;
	int comment = 0;
	int al = 0;
	for (fileLoc <- fileLocs) {
		<c, e, com, a> = countLines(fileLoc, print);
		ctr += c;
		empty += e;
		comment += com;
		al += a;
	}
	println("<ctr>, <empty>, <comment>");
	println("<ctr + empty + comment> == <al>");
	return ctr;	
}