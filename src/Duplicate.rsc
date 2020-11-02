module Duplicate

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

@doc {
	.Synopsis
	Get all the files from the project, without any whitespace as one huge string
}
str hugeFile(list[loc] fileLocs) {
	str conc = "";
	for (fileLoc <- fileLocs) {
		r = readFile(fileLoc);
		r = escape(r, (" ": "", "\t": ""));
		//println(r);
		conc += r;
	}
	return conc;
}