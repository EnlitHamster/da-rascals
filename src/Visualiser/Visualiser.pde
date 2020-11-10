import java.util.Map;
import java.util.HashMap;

color[] colors4 = {
  color(127,255,0),
  color(255,255,0),
  color(255,127,0),
  color(255,0,0)
};

color[] colorsLOC = {
  color(127,127,255),
  color(127,127,127),
  color(127,255,127)
};

PFont font;

int[] linesOfCode;
int rankLOC;
int[] riskUCNE;
int[] riskUCE;
int[] ranksUC;
int[] riskUS;
int rankUS;
int duplicateLines;
int rankDUP;
// 0 -> ANALISABILITY
// 1 -> CHANGEABILITY WITHOUT EXCEPTION HANDLING
// 2 -> CHANGEABILITY WITH EXCEPTION HANDLING
// 3 -> TESTABILITY WITHOUT EXCPETION HANDLING
// 4 -> TESTABILITY WITH EXCEPTION HANDLING
// 5 -> OVERALL WITHOUT EXCEPTION HANDLING
// 6 -> OVERALL WITH EXCEPTION HANDLING
int[] scores;

float[] percLOC;
float[] percRiskUCNE;
float[] percRiskUCE;
float[] percRiskUS;
float percDuplicateLines;

Map<Button, Tab> tabs;
Button activeButton;

Button piesButton, scoresButton;
RadioButton exceptions;

void setup() {
  size(460, 600); 
  
  String[] database = loadStrings("db.metrics");
  
  linesOfCode = int(split(database[0], ','));
  rankLOC = int(database[1]);
  riskUCNE = int(split(database[2], ','));
  riskUCE = int(split(database[3], ','));
  ranksUC = int(split(database[4], ','));
  riskUS = int(split(database[5], ','));
  rankUS = int(database[6]);
  duplicateLines = int(database[7]);
  rankDUP = int(database[8]);
  scores = int(split(database[9], ','));
  
  int totalUCNE = sum(riskUCNE);
  int totalUCE = sum(riskUCE);
  int totalUS = sum(riskUS);
  
  percLOC = new float[linesOfCode.length - 1];
  percRiskUCNE = new float[riskUCNE.length];
  percRiskUCE = new float[riskUCE.length];
  percRiskUS = new float[riskUS.length];
  
  for (int i = 0; i < linesOfCode.length - 1; i++) percLOC[i] = (float) linesOfCode[i] / (float) linesOfCode[3];
  for (int i = 0; i < riskUCNE.length; i++) percRiskUCNE[i] = (float) riskUCNE[i] / (float) totalUCNE;
  for (int i = 0; i < riskUCE.length; i++) percRiskUCE[i] = (float) riskUCE[i] / (float) totalUCE;
  for (int i = 0; i < riskUS.length; i++) percRiskUS[i] = (float) riskUS[i] / (float) totalUS;
  
  font = createFont("Arial", 16, true);
  noStroke();
  
  piesButton = new Button(0, 0, 80, 20, "Pie charts");
  scoresButton = new Button(80, 0, 80, 20, "Scores");
  
  piesButton.setActive();
  
  tabs = new HashMap<Button, Tab>();
  tabs.put(piesButton, new PiesTab());
  tabs.put(scoresButton, new ScoresTab());
  activeButton = piesButton;
  
  tabs.get(activeButton).setup();
  
  exceptions = new RadioButton(20, height - 40, 20);
}

void draw() {    
  background(255);
  tabs.get(activeButton).draw();
  piesButton.draw();
  scoresButton.draw();
  exceptions.draw();
  
  textFont(font, 16);
  fill(0);
  textAlign(LEFT);
  text("Consider Exceptions", 60, height - 22);
}

void activate(Button btn) {
  activeButton.setInactive();
  activeButton = btn;
  activeButton.setActive();
  tabs.get(activeButton).setup();
}

void mousePressed() {
  if (piesButton.hover() && activeButton != piesButton) activate(piesButton);
  else if (scoresButton.hover() && activeButton != scoresButton) activate(scoresButton);
  else if (exceptions.hover()) exceptions.check();
}
