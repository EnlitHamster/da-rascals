module Utility

import IO;

// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

//@doc {
//	Get the AST from all the files in the project.
//}
//list[Declaration] getASTs (loc projectLoc) {
// 	M3 model = createM3FromEclipseProject(projectLoc);
// 	list[Declaration] asts = [];
// 	for (m <- model.containment, m[0].scheme == "java+compilationUnit") {
// 		asts += createAstFromFile(m[0],true);
// 	}
//	return asts;
//}

@doc{
	.Synopsis
	Get a list of all file locations in the project.
}
list[loc] getFiles (loc projectLoc) {
 	M3 model = createM3FromEclipseProject(projectLoc);
 	list[loc] fileLocs = [];
 	for (m <- model.containment, m[0].scheme == "java+compilationUnit") {
 		fileLocs += m[0];
	}
	return fileLocs;
}

@doc {
	Get the AST from all the files in the project.
}
list[Declaration] getASS (loc projectLoc) {
 	list[Declaration] asts = [];
 	for (file <- getFiles(projectLoc)) {
 		asts += createAstFromFile(file,true);
 	}
	return asts;
}