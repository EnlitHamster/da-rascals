module time

import IO;
import DateTime;
import List;
import util::Math;

import Utility;
import Volume;
import Duplicate;

@doc {
	.Synopsis
	Measure the time it takes to calculate the duplicated lines in project, n times, also print average.
}
void timeNruns(loc project, int runs) {
	println(project);
	bool print = false;
	bool skip = true;
	
	list[loc] filers = getFiles(project);
	
	println("\t#files = <size(filers)>");
	println("\tLOC = <countLinesFiles(filers, false, true)[0]>");
	println("Timing of <runs> runs ");
		
	int result = 0;
	starter = now();
	for (_ <- [0..runs]) {
		result = getDuplicateLines(filers,  print, skip);
	}
	end = now();
	Duration total = createDuration(starter, end);
	
	println("\ttotal = <toSec(total)> seconds");
	println("\taverage = <toSec(total)/runs> seconds");
	
	println(result);	
}

void timeDup(list[loc] files) {
	srt = now();
	getDuplicateLines(files, 1, 6, true, false);
	end = now();
	println(createDuration(srt, end));
}

@doc {
	.Synopsis
	Convert the duration d to the equavalent amount in seconds.
}
real toSec(Duration d) {
	return (d.years*31557600) + (d.months*2629746) + (d.days*86400) +(d.hours* 3600) + (d.minutes * 60) + d.seconds + (toReal(d.milliseconds) / 1000);
}