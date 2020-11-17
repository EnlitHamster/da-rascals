module Coupling

// Project imports
import Utility;
import Snippet;

// Rascal base imports
import Set;
import List;
import Map;
import String;
 
import IO;
 
// M3 imports
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

map[str,int] rankFanInRisk(list[int] cpls) {
	return rankRisk(cpls, 10, 22, 56);
}

public alias Imports = map[loc,set[str]];
public alias Classes = map[str,loc];
public alias Couplings = set[str];
public alias CouplingGraph = map[loc,Couplings];
public alias CouplingGraphs = tuple[CouplingGraph inter, CouplingGraph intra, CouplingGraph interVisited, CouplingGraph intraVisited];

public CouplingGraph fanInGraph(list[Declaration] asts) {
	set[Declaration] classes;
	Imports imports;
	<classes, imports> = getClasses(asts);
	Classes clsMap = genClasses(classes);
	CouplingGraph cg = genCouplingGraph(asts, classes, imports, clsMap, true);
	
	CouplingGraph fanInGraph = ();
	for (loc cls <- cg) {
		fanInGraph[cls] = {};
		str sCls = declToClass(cls);
		for (loc cls1 <- cg)
			if (sCls in cg[cls1]) fanInGraph[cls] += declToClass(cls1);
	}
	return fanInGraph;
}

private CouplingGraph cleanCouplingGraph(CouplingGraph cg, Classes clsMap) {
	CouplingGraph clean = ();
	for (key <- cg) {
		clean[key] = {};
		for (cpl <- cg[key])
			if (cpl in clsMap) clean[key] += cpl;
	}
	return clean;
}

public CouplingGraphs genCouplingGraphs(list[Declaration] asts) {
	set[Declaration] classes;
	Imports imports;
	<classes, imports> = getClasses(asts);
	Classes clsMap = genClasses(classes);
	CouplingGraph cg = genCouplingGraph(asts, classes, imports, clsMap, false);
	CouplingGraph clean = cleanCouplingGraph(cg, clsMap);
	
	bool updated = true;
	CouplingGraph cgV = cg;
	while (updated) <updated, cgV> = visitCouplingGraph(cgV, clsMap);
	CouplingGraph cleanV = cleanCouplingGraph(cgV, clsMap);
	
	return <cg, clean, cgV, cleanV>;
}

public CouplingGraph innerCouplingGraph(list[Declaration] asts, bool vst) {
	set[Declaration] classes;
	Imports imports;
	<classes, imports> = getClasses(asts);
	Classes clsMap = genClasses(classes);
	CouplingGraph cg = genCouplingGraph(asts, classes, imports, clsMap, vst);
	CouplingGraph clean = cleanCouplingGraph(cg, clsMap);
	return clean;
}

public CouplingGraph genCouplingGraph(list[Declaration] asts, bool vst) {
	set[Declaration] classes;
	Imports imports;
	<classes, imports> = getClasses(asts);
	Classes clsMap = genClasses(classes);
	return genCouplingGraph(asts, classes, imports, clsMap, vst);
}

public CouplingGraph genCouplingGraph(list[Declaration] asts, set[Declaration] classes, Imports imports, Classes clsMap, bool vst) {
	CouplingGraph graph = initCouplingGraph(classes, clsMap, imports);
	bool updated = vst;
	while (updated) <updated, graph> = visitCouplingGraph(graph, clsMap);
	return graph;
}

Classes genClasses(set[Declaration] classes) {
	Classes cMap = ();
	for (cls <- classes) cMap[declToClass(cls.decl)] = cls.decl;
	return cMap;
}

Imports addImports(Imports imports, Declaration cu, list[Declaration] is) {
	Imports imps = imports;
	visit (is) {
		case Declaration i: \import(name): if (i.modifiers ? && \onDemand() in i.modifiers) {
			loc key = toLocation(cu.src.uri);
			if (key in imports) imps[key] += name;
			else imps[key] = {name};
		}
	}
	return imps;
}

tuple[set[Declaration], Imports] getClasses(list[Declaration] asts) {
	set[Declaration] classes = {};
	Imports imports = ();
	visit (asts) {
		case Declaration cu: \compilationUnit(is,_): imports = addImports(imports, cu, is);
		case Declaration cu: \compilationUnit(_,is,_): imports = addImports(imports, cu, is);
		case Declaration cls: \class(_,_,_,_): classes += cls;
	}
	return <classes, imports>;
}

// Interesting for coupling:
// - newObject
// - newArray
// - cast
// - simpleName
// - methodCall

str addClass(loc decl, loc src, Classes classes, Imports imports) {
	str class = declToClass(decl);
	if (contains(class, ".")) return class; // Checking if the packaging was reconstructable
	set[str] clssNames = domain(classes);
	
	// The reconstruction was unsuccessful. We only try to reconstruct ourselves only for internal classes,
	// as access to libraries is not guaranteed, and our measure considers only intra-project Coupling.
	
	// First we try by using the package of the class and adding the name of the missing class
	// Potentially this reconstruction failed due to the class being in the same package.
	int begin = findFirst(src.path, "src")+3;
	int end = findLast(src.path, "/");
	if (begin < end) {
		str candidatePkgClass = pathToClass(src.path[begin..end]) + "." + class;
		if (candidatePkgClass in clssNames) return candidatePkgClass;
	}
	
	// Another potential cause of failed reconstruction is the usage of onDemand imports. Before continuing
	// on a potentially computation heavy work, we first check if there are candidates that we can use.
	set[str] potentialCandidates = {};
	for (cls <- clssNames) if (contains(cls, class)) potentialCandidates += cls;
	
	if (size(potentialCandidates) == 0) return class; // We return the class name as it is still a coupling.
	
	loc key = toLocation(src.uri);
	potentialCandidates = {};
	if (key in imports)
		for (pkg <- imports[key])
			for (pCndt <- potentialCandidates)
				if (pCndt == pkg + "." + class) potentialCandidates += pCndt;
	if (size(potentialCandidates) == 1) return toList(potentialCandidates)[0];
	
	// No candidate found, return the class name.
	return class;
}

// Coupling Graphs will work on classes themselves
CouplingGraph initCouplingGraph(set[Declaration] classes, Classes knownClss, Imports imports) {
	CouplingGraph cg = ();
	for (cls <- classes) {
		loc key = cls.decl;
		Couplings cpls = {};
		visit (cls) {
			case Expression e: \newArray(_,_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \newArray(_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \newObject(_,_,_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \newObject(_,_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \newObject(_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \cast(_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \methodCall(_,_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \methodCall(_,_,_,_): cpls += addClass(e.decl, e.src, knownClss, imports);
			case Expression e: \simpleName(_): cpls += addClass(e.decl, e.src, knownClss, imports);
		}
		cg[key] = cpls - {UNKNOWN, declToClass(key)};
	}
	return cg;
}

tuple[bool,CouplingGraph] visitCouplingGraph(CouplingGraph graph, Classes clsMap) {
	CouplingGraph cg = graph;
	bool updated = false;
	for (key <- graph) {
		for(cpl <- graph[key]) {
			if (cpl in clsMap) {
				Couplings newCandidates = graph[clsMap[cpl]] - declToClass(key);
				for (cndt <- newCandidates) {
					if (cndt notin cg[key]) {
						updated = true;
						cg[key] += cndt;
					}
				}
			}
		}
	}
	return <updated, cg>;
}