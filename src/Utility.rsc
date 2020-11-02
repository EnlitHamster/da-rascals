module Utility

import IO;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

list[Declaration] getASTs (loc projectLoc) {
 	M3 model = createM3FromEclipseProject(projectLoc);
 	list[Declaration] asts = [];
 	for (m <- model.containment, m[0].scheme == "java+compilationUnit"){
 		asts += createAstFromFile(m[0],true);
 		//println(readFile(m[1]));
 	}
	return asts;
}

list[loc] getFiles (loc projectLoc) {
 	M3 model = createM3FromEclipseProject(projectLoc);
 	list[loc] fileLocs = [];
 	for (m <- model.containment, m[0].scheme == "java+compilationUnit"){
 		fileLocs += m[1];
 		//println(m[1]);
 	}
	return fileLocs;
}