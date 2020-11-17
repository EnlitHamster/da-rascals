module internal::Benchmarks

// Project imports
import Utility;
import Coupling;

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

void benchmarkCoupling(loc dumpFolder) {
	list[loc] projects = [
		|project://androidannotations-develop|,
		|project://antlr4|, 
		|project://arthas|, 
		|project://cas-master|,
		|project://CNTK-master|,
		|project://dagli-master|,
		|project://dropwizard-master|,
		|project://elasticsearch-analysis-ik-master|,
		|project://elasticsearch-master|,
		|project://ExoPlayer-release-v2|,
		|project://fastjson-master|,
		|project://flatbuffers-master|,
		|project://flink-master|,
		|project://generator-jhipster-main|,
		|project://glide-transformations-main|,
		|project://guava-master|,
		|project://HikariCP-dev|,
		|project://hsqldb-2.3.1|,
		|project://ip2region-master|,
		|project://jadx-master|,
		|project://JCSprout-master|,
		|project://jenkins-master|,
		|project://jib-master|,
		|project://jsoup-master|,
		|project://keycloak-master|,
		|project://leakcanary-main|,
		|project://logger-master|,
		|project://MaterialViewPager-master|,
		|project://mockito-release-3.x|,
		|project://mockserver-master|,
		|project://MPAndroidChart-master|,
		|project://mybatis-3-master|,
		|project://okhttp-master|,
		|project://PermissionDispatcher-master|,
		|project://pulsar-master|,
		|project://realm-java-master|,
		|project://redisson-master|,
		|project://retrofit-master|,
		|project://RxJava-3.x|,
		|project://selenium-trunk|,
		|project://smallsql0.21_src|,
		|project://spark-master|,
		|project://spring-framework-master|,
		|project://thingsboard-master|,
		|project://uCrop-develop|,
		|project://ValLang|,
		|project://vert.x-master|,
		|project://webmagic-master|,
		|project://xxl-job-master|,
		|project://zxing-master|
   	];
   
   	list[map[str,int]] rankings = [];
   	for (proj <- projects) {
   		println("=== PROJECT <proj>");
   		print("Generating ASTS... ");
   		list[Declaration] asts = getASS(proj);
   		print("Done.\nGenerating coupling graph... ");
   		CouplingGraph fanInGraph = fanInGraph(asts);
   		print("Done.\nGenerating fan-ins... ");
   		
   		list[int] fanIns = [];
   		for (loc cls <- fanInGraph)
   			fanIns += size(fanInGraph[cls]);
   			
		ranks = rankFanInRisk(fanIns);
		rankings += ranks;
		print("Done.\nDumping on file... ");
		writeFile(dumpFolder + "<proj.uri[findLast(proj.uri, "/")..]>.txt", ranks);
   	}
   	
   	list[int] low = [];
   	list[int] mid = [];
   	list[int] hig = [];
   	list[int] vhg = [];
   	
   	for (map[str,int] rank <- rankings) {
   		low += rank[LOW_RISK];
   		mid += rank[MID_RISK];
   		hig += rank[HIGH_RISK];
   		vhg += rank[VERY_HIGH_RISK];
   	}
   	
   	sort(low);
   	sort(mid);
   	sort(hig);
   	sort(vhg);
   	
   	int n = size(projects);
   	int p05 = 0.05 * n;
   	int p35 = 0.35 * n;
   	int p65 = 0.65 * n;
   	int p95 = 0.95 * n;
   	
   	println("\n=== PERCENTILES");
   	println("++ thresholds: <low[p05]>/<mid[p05]>/<hig[p05]>/<vhg[p05]>");
   	println("+ thresholds: <low[p35]>/<mid[p35]>/<hig[p35]>/<vhg[p35]>");
   	println("o thresholds: <low[p65]>/<mid[p65]>/<hig[p65]>/<vhg[p65]>");
   	println("- thresholds: <low[p95]>/<mid[p95]>/<hig[p95]>/<vhg[p95]>");
}