# da-rascals

## Installation

in the Releases you will find the binaries for the visualization tools (Processing 3 visualizer and Unity Clone visualizer). Follow the instructions in the release log on how to install the two tools. You will need to have Java 8 or higher to run the Processing tool. To run the Rascal code, clone the repo locally and open it with an Eclipse/Rascal IDE. For how to setup that, follow this link: https://www.rascal-mpl.org/start/. It is highly recommended to output the files from Rascal to an `Input` folder inside the root folder of the visualization tool. To generate the files of a project, use `printBundle(loc projectLoc, loc outputFolder, int threshold1, int threshold2, str fileName)` where
- `projectLoc` is the location in form `|project://<projectName>|` inside Eclipse;
- `ouptutFolder` is the folder in your system where you want to output the files. Following the recommendations, it will look something like `|file:///path/to/root/Input|`;
- `threshold1` the threshold in lines for detection of Type I clones;
- `threshold2` the threshold in tokens for detection of Type II clones;
- `fileName` the base name of the file. This is entirely at your discrestion, although we recommend using the name of the project you are generating.

### Report

A complete report on the design can be found at this link: https://www.overleaf.com/project/5f984600c8055a0001b2f7c7.

A PDF file is included in the repo, check that too.

### Interesting readings

candidates for other metrics: https://en.wikipedia.org/wiki/Software_package_metrics

paper proposing complexity metrics: https://www.researchgate.net/publication/254570205_A_Coupling-Complexity_Metric_Suite_for_Predicting_Software_Quality

coupling analysis in OOP: https://www.researchgate.net/publication/3779938_Coupling_metrics_for_object-oriented_design
