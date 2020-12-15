import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Map; 
import java.util.HashMap; 
import java.util.Optional; 
import java.io.File; 
import java.awt.GraphicsDevice; 
import java.awt.GraphicsEnvironment; 
import java.util.Set; 
import java.util.HashSet; 
import java.io.File; 
import java.io.FileInputStream; 
import java.io.FileOutputStream; 
import java.nio.file.Files; 
import java.nio.file.Paths; 
import java.nio.file.Path; 
import java.nio.file.StandardCopyOption; 
import java.util.Random; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Visualiser extends PApplet {










PFont font, fontIt, fontBd;

// NOT CONSIDERING BRACKETS
Bundle brkts, noBrkts, activeBundle;

Map<Button, Tab> tabs;
Button activeButton;

Button piesButton, scoresButton, dataButton, distribsButton, graphButton, changeDB;
RadioButton exceptions, brackets;

boolean run;

public void setup() {
  try {println(new File(".").getCanonicalPath());} catch (IOException ignored) {}
  selectDB();
}

public void draw() {    
  if (run) {
    background(255);
    tabs.get(activeButton).draw();
    piesButton.draw();
    scoresButton.draw();
    dataButton.draw();
    distribsButton.draw();
    graphButton.draw();
    exceptions.draw();
    brackets.draw();
    changeDB.draw();
  }
}

public void activate(Button btn) {
  run = false;
  noLoop();
  activeButton.setInactive();
  activeButton = btn;
  activeButton.setActive();
  tabs.get(activeButton).setup();
  center();
  
  changeDB.update(width - 120, 0);
  exceptions.update(20, height - 70);
  brackets.update(20, height - 40);
  loop();
  run = true;
}

public void mousePressed() {
  tabs.get(activeButton).mousePressed();
  if (piesButton.hover() && activeButton != piesButton) activate(piesButton);
  if (scoresButton.hover() && activeButton != scoresButton) activate(scoresButton);
  if (dataButton.hover() && activeButton != dataButton) activate(dataButton);
  if (distribsButton.hover() && activeButton != distribsButton) activate(distribsButton);
  if (graphButton.hover() && activeButton != graphButton) activate(graphButton);
  if (exceptions.hover()) exceptions.check();
  if (brackets.hover()) {
    brackets.check();
    if (brackets.isChecked()) activeBundle = brkts; else activeBundle = noBrkts;
  }
  if (changeDB.hover()) selectDB();
}

public void mouseMoved() {
  tabs.get(activeButton).mouseMoved();
}

public void mouseDragged() {
  tabs.get(activeButton).mouseDragged();
}

public void mouseReleased() {
  tabs.get(activeButton).mouseReleased();
}

public void selectDB() {
  run = false;
  noLoop();
  selectInput("Select a metrics file", "fileSelected");
}

public void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    System.exit(-1);
  } else {
    Optional<String> extension = getFileExtension(selection.getName());
    if (extension.isPresent() && extension.get().equalsIgnoreCase("metrics")) processInput(selection.getAbsolutePath());
    else { 
      println("File must be a .metrics file"); 
      System.exit(-1);
    }
  }
}

public void processInput(String dbFile) {
  String[] database = loadStrings(dbFile);
  
  brkts = new Bundle(database, false);
  noBrkts = new Bundle(database, true);
  activeBundle = noBrkts;
  
  font = createFont("Arial", 16, true);
  fontIt = createFont("Arial Italic", 16, true);
  fontBd = createFont("Arial Bold", 16, true);
  noStroke();
  
  piesButton = new Button(-1, 0, 80, 20, "Pie charts");
  scoresButton = new Button(79, 0, 80, 20, "Scores");
  dataButton = new Button(159, 0, 80, 20, "Data");
  distribsButton = new Button(239, 0, 80, 20, "Distributions");
  graphButton = new Button(319, 0, 80, 20, "Graphs");
  
  tabs = new HashMap<Button, Tab>();
  tabs.put(piesButton, new PiesTab());
  tabs.put(scoresButton, new ScoresTab());
  tabs.put(dataButton, new DataTab(dbFile.substring(0, dbFile.lastIndexOf('.'))));
  tabs.put(distribsButton, new DistribsTab());
  tabs.put(graphButton, new GraphTab(dbFile.substring(0, dbFile.lastIndexOf('.'))));
  activeButton = piesButton;
  
  piesButton.setActive();
  
  tabs.get(activeButton).setup();
  center();
  
  changeDB = new Button(width - 120, 0, 120, 20, "Open file");
  exceptions = new RadioButton(20, height - 70, 20, "Consider Exception Handling");
  brackets = new RadioButton(20, height - 40, 20, "Consider lines with closing brackets");
  
  loop();
  run = true;
}

public void vizSize(int x, int y) {
  surface.setSize(max(x - 1, MIN_X), max(y, MIN_Y)); 
}
public interface AbstractButton {
  public void draw();
  public void update(int x, int y);
  public boolean hover();
}
/** 
 * This is the communication protocol with the RAscal MEtrics tool.
 * Change this ONLY if you know how the saving protocol on RAMEt side
 * works.
 */

public class Bundle {
  final int[] linesOfCode;
  final int[] nTokens;
  final int rankLOC;
  final int[] CCsNE;
  final int[] CCsE;
  final int[] riskUCNE;
  final int[] riskUCE;
  final int[] ranksUC;
  final int[] USs;
  final int[] riskUS;
  final int rankUS;
  // 0 -> NUMBER OF DUPLICATE UNITS (LINES/TOKENS)
  // 1 -> NUMBER OF CLONE CLASSES
  // 2 -> BIGGEST CLONE
  // 3 -> BIGGEST CLASS
  // 4 -> NUMBER OF CLONES
  final int[] clonesType1;
  final int[] clonesType2;
  final int[] clonesType25;
  final int rankDUP;
  final int asserts;
  final int testLOC;
  final int rankTQ;
  // 0 -> ANALISABILITY
  // 1 -> CHANGEABILITY WITHOUT EXCEPTION HANDLING
  // 2 -> CHANGEABILITY WITH EXCEPTION HANDLING
  // 3 -> STABILITY
  // 4 -> TESTABILITY WITHOUT EXCPETION HANDLING
  // 5 -> TESTABILITY WITH EXCEPTION HANDLING
  // 6 -> OVERALL WITHOUT EXCEPTION HANDLING
  // 7 -> OVERALL WITH EXCEPTION HANDLING
  final int[] scores;
  
  final float[] percLOC;
  final float[] percRiskUCNE;
  final float[] percRiskUCE;
  final float[] percRiskUS;
  
  public Bundle(String[] database, boolean skipBrkts) {
      nTokens = PApplet.parseInt(split(database[0], ','));
      clonesType2 = PApplet.parseInt(split(database[1], ','));
      clonesType25 = PApplet.parseInt(split(database[2], ','));
      CCsNE = sort(PApplet.parseInt(split(database[3], ',')));
      CCsE = sort(PApplet.parseInt(split(database[4], ',')));
      riskUCNE = PApplet.parseInt(split(database[5], ','));
      riskUCE = PApplet.parseInt(split(database[6], ','));
      ranksUC = PApplet.parseInt(split(database[7], ','));
      USs = sort(PApplet.parseInt(split(database[8], ',')));
      riskUS = PApplet.parseInt(split(database[9], ','));
      rankUS = PApplet.parseInt(database[10]);
      linesOfCode = PApplet.parseInt(split(database[skipBrkts ? 11 : 12], ','));
      rankLOC = PApplet.parseInt(split(database[13], ',')[skipBrkts ? 0 : 1]);
      clonesType1 = PApplet.parseInt(split(database[skipBrkts ? 14 : 15], ','));
      rankDUP = PApplet.parseInt(split(database[16], ',')[skipBrkts ? 0 : 1]);
      scores = PApplet.parseInt(split(database[skipBrkts ? 17 : 18], ','));
      asserts = PApplet.parseInt(database[19]);
      testLOC = PApplet.parseInt(split(database[20], ',')[skipBrkts ? 0 : 1]);
      rankTQ = PApplet.parseInt(split(database[21], ',')[skipBrkts ? 0 : 1]);
      
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
  }
}
public class Button implements AbstractButton {
  
  private int x, y, w, h;
  private String text;
  private int bg;
  private int border;
  private int textColor;
  
  public Button(int x, int y, int w, int h, String text) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.text = text;
    this.bg = color(255,255,255);
    this.border = color(0,0,0);
  }
  
  public void setText(String text) {this.text = text;}
  public void setActive() {bg = color(230,230,230);}
  public void setInactive() {bg = color(255,255,255);}
  public boolean hover() {return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;}
  
  public void draw() {
    if (hover()) fill(color(245,245,245));
    else fill(bg);
    stroke(border);
    rect(x, y, w, h);
    
    fill(textColor);
    noStroke();
    textFont(font, 12);
    textAlign(CENTER);
    text(text, x + w/2, y + h/2 + 6);
  }
  
  public void update(int x, int y) {
     this.x = x;
     this.y = y;
  }
  
}
public class RadioButton {
  
  int x, y, dimensions;
  boolean checked;
  String text;
  
  public RadioButton(int x, int y, int dim, String text) {
    this.x = x;
    this.y = y;
    this.dimensions = dim;
    this.checked = false;
    this.text = text;
  }
  
  public void check() {checked = !checked;}
  public boolean isChecked() {return checked;}
  public boolean hover() {return mouseX >= x && mouseX <= x + dimensions && mouseY >= y && mouseY <= y + dimensions;}
  
  public void draw() {
    if (hover()) fill(color(245,245,245));
    else fill(color(255,255,255));
    stroke(0);
    rect(x, y, dimensions, dimensions);
    
    if (checked) {
      fill(0);
      textFont(font, dimensions - 4);
      textAlign(CENTER);
      text("X", x + dimensions/2, y + dimensions - 3);
    }
    
    textFont(font, 16);
    fill(0);
    textAlign(LEFT);
    text(text, x + dimensions + 20, y + dimensions/2 + 8);
  }
  
  public void update(int x, int y) {
     this.x = x;
     this.y = y;
  }
  
}












abstract class Tab {
  abstract public void setup();
  abstract public void draw();
  public void mousePressed() {}
  public void mouseMoved() {}
  public void mouseDragged() {}
  public void mouseReleased() {}
}

//-------------------
//               PIES
//-------------------

class PiesTab extends Tab {
  
  RadioButton anaMode;
  boolean save_check;
  
  public PiesTab() {save_check = false;}
  
  public void setup() {
    vizSize(460, 660); 
    anaMode = new RadioButton(20, height - 100, 20, "Ana safe mode");
    if (save_check) anaMode.check();
  }
  
  public void draw() {
    anaMode.draw();
    
    fill(0);
    textFont(font, 20);
    textAlign(CENTER);
    int left = width/2 + 10;
    
    text("Unit Complexity", width/4, 60);
    text("Unit Size", width/4, 320);
    text("Lines of code", 3*width/4, 60);
    text("Legend", 3*width/4, 320);
    
    textAlign(LEFT);
    textFont(font, 16);
    
    text("Low risk elements", left + 30, 356);
    text("Medium risk elements", left + 30, 386);
    text("High risk elements", left + 30, 416);
    text("Very high risk elements", left + 30, 446);
    text("Lines of code", left + 30, 476);
    text("Empty lines", left + 30, 506);
    text("Comment lines", left + 30, 536);
    
    noStroke();
    
    fill(colors4[0]);    rect(left, 340, 20, 20);
    fill(colors4[1]);    rect(left, 370, 20, 20);
    fill(colors4[2]);    rect(left, 400, 20, 20);
    fill(colors4[3]);    rect(left, 430, 20, 20);
    fill(colorsLOC[0]);  rect(left, 460, 20, 20);
    fill(colorsLOC[1]);  rect(left, 490, 20, 20);
    fill(colorsLOC[2]);  rect(left, 520, 20, 20);    
    
    if (anaMode.isChecked()) {
      float[] risks = exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE;
      makeBlock(width/4 - 100, 80, 200, 200, risks, sum(risks), colors4);
      makeBlock(width/4 - 100, 340, 200, 200, activeBundle.percRiskUS, sum(activeBundle.percRiskUS), colors4); 
      makeBlock(3*width/4 - 100, 80, 200, 200, activeBundle.percLOC, sum(activeBundle.percLOC), colorsLOC);
    } else {
      pieChart(width/4, 180, exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE, colors4);
      pieChart(width/4, 440, activeBundle.percRiskUS, colors4);
      pieChart(3*width/4, 180, activeBundle.percLOC, colorsLOC); 
    }
  }

  private void pieChart(int x, int y, float[] data, int[] colors) {
    float lastAngle = 0;
    for (int i = 0; i < data.length; i++) {
      fill(colors[i]);
      float angle = radians(p2d(data[i]));
      arc(x, y, 200, 200, lastAngle, lastAngle + angle);
      lastAngle += angle;
    }
  }
  
  public void mousePressed() {
    if (anaMode.hover()) {
      save_check = !save_check;
      anaMode.check(); 
    }
  }
  
}

//-------------------
//             SCORES
//-------------------

class ScoresTab extends Tab {
  
  public void setup() {
    vizSize(600, 660); 
  } 
  
  public void draw() {
    fill(0);
    textFont(font, 16); 
    textAlign(LEFT);
    
    text("Lines of Code", 20, 60);
    text("Duplicated code", 20, 100);
    text("Unit Complexity", 20, 180);
    text("Unit Size", 20, 240);
    text("Assertion Density", 20, 300);
    
    textAlign(CENTER);
    
    text(toScore(activeBundle.rankLOC), width/2, 60);
    text(toScore(activeBundle.rankDUP), width/2, 100);
    text(toScore(exceptions.isChecked() ? activeBundle.ranksUC[1] : activeBundle.ranksUC[0]), width/2, 180);
    text(toScore(activeBundle.rankUS), width/2, 240);
    text(toScore(activeBundle.rankTQ), width/2, 300);
    
    textFont(font, 12);
    textAlign(RIGHT);
    
    text(activeBundle.linesOfCode[0] + String.format(" (%4.2f%c)", (float) activeBundle.linesOfCode[0] * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 60);
    text(activeBundle.clonesType1 + String.format(" (%4.2f%c)", (float) activeBundle.clonesType1[0] * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 100);
    text(activeBundle.clonesType1 + String.format(" (%4.2f%c)", (float) activeBundle.asserts * 100 / (float) activeBundle.testLOC, '%'), width - 20, 300);
    
    printPercs(exceptions.isChecked() ? activeBundle.riskUCE : activeBundle.riskUCNE, exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE, 180);
    printPercs(activeBundle.riskUS, activeBundle.percRiskUS, 240);
    
    printHeader(140);
    String [][] mapping = createMapping();
    printMap(mapping, 80, 380);
  }
  
  public String[][] createMapping() {
    String[][] mapping = new String[7][7];
    mapping = addX(mapping);
    mapping = addLabels(mapping);
    mapping = addRankings(mapping);
    return mapping;
  }
  
  public String[][] addLabels(String[][] mapping) {
    mapping[2][0] = "analysabilty";
    mapping[3][0] = "changeabilty";
    mapping[4][0] = "stability";
    mapping[5][0] = "testability";
    mapping[6][0] = "overall";
    
    mapping[0][1] = "Volume";
    mapping[0][2] = "Complexity";
    mapping[0][3] = "Duplication";
    mapping[0][4] = "Unit Size";
    mapping[0][5] = "Test Quality";
    return mapping;
  }
  
  public String[][] addRankings(String[][] mapping) {
    int offset = exceptions.isChecked()? 1 : 0;
    mapping[2][6] = toScore(activeBundle.scores[0]);
    mapping[3][6] = toScore(activeBundle.scores[1+offset]);
    mapping[4][6] = toScore(activeBundle.scores[3]);
    mapping[5][6] = toScore(activeBundle.scores[4+offset]);
    mapping[6][6] = toScore(activeBundle.scores[6+offset]);
    
    mapping[1][1] = toScore(activeBundle.rankLOC);
    mapping[1][2] = toScore(activeBundle.ranksUC[offset]);
    mapping[1][3] = toScore(activeBundle.rankDUP);
    mapping[1][4] = toScore(activeBundle.rankUS);
    mapping[1][5] = toScore(activeBundle.rankTQ);
    return mapping;
  }
  
  public String[][] addX(String[][] mapping) {
    int xs[][] = {{2,1}, {2,3}, {2,4}, {2,5}, {3,2}, {3,3}, {4,5}, {5,2}, {5,4}, {5,5}};
    for(int []xy : xs) {
      mapping[xy[0]][xy[1]] = "x";
    }
    return mapping;
  }
  
  public void printMap(String[][] mapping, int x, int y) {
    int xoff = 80;
    int yoff = 20;
    
    for (int i = 0; i < mapping.length; i++) {
      for (int j = 0; j < mapping[0].length; j++) {
        if (mapping[i][j] != null) {
          if (j == 0) {
            textAlign(RIGHT);
            text(mapping[i][j], x + 40, y+ i*yoff);
          } else if (j == (mapping[0].length)-1) {
            textAlign(LEFT);
            text(mapping[i][j], x + j*xoff - 40, y+ i*yoff);
          }
          else {
            textAlign(CENTER);
            text(mapping[i][j], x + j*xoff, y+ i*yoff);
          }
        }
      }
    }
    printLines(x, y, xoff, yoff);
  }
  
  public void printLines(int x, int y, int xoff, int yoff) {
    stroke(0);
    line(x+60, y+1*yoff+5, x+5.7f*xoff, y+1*yoff+5); 
    line(x+5.3f*xoff, y+1*yoff+5, x+5.3f*xoff, y+6.3f*yoff); 
    line(x+60, y+5*yoff+5, x+5.7f*xoff, y+5*yoff+5);
  }
  
  private void printPercs(int[] stats, float[] percs, int height) {
    int start = width/2 + 20;
    int area = width - 20 - start;
    int step = area/4;
    
    for (int i = 0; i < 4; i++) {
      text(stats[i], start + step*(i+1), height);
      text(String.format("%4.2f%c", percs[i]*100, '%'), start + step*(i+1), height + 20); 
    }
  }
  
  private void printHeader(int height) {
    int start = width/2 + 20;
    int area = width - 20 - start;
    int step = area/4;
    String[] texts = {"LOW", "MID", "HIGH", "VERY\nHIGH"};
    
    for (int i = 0; i < 4; i++) text(texts[i], start + step*(i+1), height);
  }
  
}

//-------------------
//               DATA
//-------------------

class DataTab extends Tab {
  
  Button openCloneViz;
  RadioButton strict;
  String file;
  boolean save_check;
  
  public DataTab(String file) {
    this.file = file;
    save_check = false;
  }
  
  private void printStatHeads(int descWidth, int dataWidth, int h) {
    textFont(fontIt, 12);
    
    text("min", descWidth + dataWidth/8, h);
    text("max", descWidth + 3*dataWidth/8, h);
    text("mean", descWidth + 5*dataWidth/8, h);
    text("median", descWidth + 7*dataWidth/8, h);
    
    float wP = textWidth("P");
    
    textSize(10);
    
    float w1 = textWidth("5");
    float w2 = textWidth("35");
    float w3 = textWidth("65");
    float w4 = textWidth("95");
    
    text("5", descWidth + dataWidth/8 + wP/2, h+42);
    text("35", descWidth + 3*dataWidth/8 + wP/2, h+42);
    text("65", descWidth + 5*dataWidth/8 + wP/2, h+42);
    text("95", descWidth + 7*dataWidth/8 + wP/2, h+42);
    
    textSize(12);
    
    text("P", descWidth + dataWidth/8 - w1/2, h+40);
    text("P", descWidth + 3*dataWidth/8 - w2/2, h+40);
    text("P", descWidth + 5*dataWidth/8 - w3/2, h+40);
    text("P", descWidth + 7*dataWidth/8 - w4/2, h+40);    
  }
  
  public void setup () {
    vizSize(520, 530);
    openCloneViz = new Button(20, 400, 160, 20, "Open clones visualizer");
    strict = new RadioButton(20, height - 100, 20, "Strict Type II clones");
    if (save_check) strict.check();
  }
  
  public void draw() {
    openCloneViz.draw();
    strict.draw();
    
    fill(0);
    textFont(fontBd, 12); 
    textAlign(LEFT);
    
    int descWidth = 160;
    int dataWidth = width - (descWidth + 40);
    
    text("Line count", 20, 60);
    text("Token count", 20, 100);
    text("Cyclomatic complexity", 20, 140);
    text("Unit Size", 20, 220);
    text("Clones Type I", 20, 320);
    text("Clones Type II", 20, 340);
    text("Asserts", 20, 360);
    text("Lines of test", 20, 380);
    
    textAlign(CENTER);
    textFont(fontIt, 12);
    
    text("code", descWidth + dataWidth/8, 60);
    text("empty", descWidth + 3*dataWidth/8, 60);
    text("commnet", descWidth + 5*dataWidth/8, 60);
    text("total", descWidth + 7*dataWidth/8, 60);
    
    text("IDs", descWidth + dataWidth/8, 100);
    text("LITERALs", descWidth + 3*dataWidth/8, 100);
    text("METHODs", descWidth + 5*dataWidth/8, 100);
    text("total", descWidth + 7*dataWidth/8, 100);
    
    printStatHeads(descWidth, dataWidth, 140);
    printStatHeads(descWidth, dataWidth, 220);
    
    text("#units", descWidth + dataWidth/10, 300);
    text("#clones", descWidth + 3*dataWidth/10, 300);
    text("#classes", descWidth + 5*dataWidth/10, 300);
    text("max clone", descWidth + 7*dataWidth/10, 300);
    text("max class", descWidth + 9*dataWidth/10, 300);
    
    textFont(font, 12); 
    
    int[] CC = exceptions.isChecked() ? activeBundle.CCsE : activeBundle.CCsNE;
    int lenCC = CC.length;
    int lenUS = activeBundle.USs.length;
    
    text(activeBundle.linesOfCode[0], descWidth + dataWidth/8, 80);
    text(activeBundle.linesOfCode[1], descWidth + 3*dataWidth/8, 80);
    text(activeBundle.linesOfCode[2], descWidth + 5*dataWidth/8, 80);
    text(activeBundle.linesOfCode[3], descWidth + 7*dataWidth/8, 80);
    
    text(activeBundle.nTokens[0], descWidth + dataWidth/8, 120);
    text(activeBundle.nTokens[1], descWidth + 3*dataWidth/8, 120);
    text(activeBundle.nTokens[2], descWidth + 5*dataWidth/8, 120);
    text(activeBundle.nTokens[3], descWidth + 7*dataWidth/8, 120);
    
    text(min(CC), descWidth + dataWidth/8, 160);
    text(max(CC), descWidth + 3*dataWidth/8, 160);
    text(avg(CC), descWidth + 5*dataWidth/8, 160);
    text(CC[lenCC / 2], descWidth + 7*dataWidth/8, 160);
    
    text(CC[(int) (lenCC * 0.05f)], descWidth + dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.35f)], descWidth + 3*dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.65f)], descWidth + 5*dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.95f)], descWidth + 7*dataWidth/8, 200);
    
    text(min(activeBundle.USs), descWidth + dataWidth/8, 240);
    text(max(activeBundle.USs), descWidth + 3*dataWidth/8, 240);
    text(avg(activeBundle.USs), descWidth + 5*dataWidth/8, 240);
    text(activeBundle.USs[lenUS / 2], descWidth + 7*dataWidth/8, 240);
    
    text(activeBundle.USs[(int) (lenUS * 0.05f)], descWidth + dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.35f)], descWidth + 3*dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.65f)], descWidth + 5*dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.95f)], descWidth + 7*dataWidth/8, 280);
    
    text(activeBundle.clonesType1[0], descWidth + dataWidth/10, 320);
    text(activeBundle.clonesType1[4], descWidth + 3*dataWidth/10, 320);
    text(activeBundle.clonesType1[1], descWidth + 5*dataWidth/10, 320);
    text(activeBundle.clonesType1[2], descWidth + 7*dataWidth/10, 320);
    text(activeBundle.clonesType1[3], descWidth + 9*dataWidth/10, 320);
    
    if (strict.isChecked()) {
      text(activeBundle.clonesType2[0], descWidth + dataWidth/10, 340);
      text(activeBundle.clonesType2[4], descWidth + 3*dataWidth/10, 340);
      text(activeBundle.clonesType2[1], descWidth + 5*dataWidth/10, 340);
      text(activeBundle.clonesType2[2], descWidth + 7*dataWidth/10, 340);
      text(activeBundle.clonesType2[3], descWidth + 9*dataWidth/10, 340);
    } else {
      text(activeBundle.clonesType25[0], descWidth + dataWidth/10, 340);
      text(activeBundle.clonesType25[4], descWidth + 3*dataWidth/10, 340);
      text(activeBundle.clonesType25[1], descWidth + 5*dataWidth/10, 340);
      text(activeBundle.clonesType25[2], descWidth + 7*dataWidth/10, 340);
      text(activeBundle.clonesType25[3], descWidth + 9*dataWidth/10, 340);
    }
    
    text(activeBundle.asserts, descWidth + dataWidth/2, 360);
    text(activeBundle.testLOC, descWidth + dataWidth/2, 380);
  }
  
  // C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\
  public void mousePressed() {
    if (strict.hover()) {
      save_check = !save_check; 
      strict.check();
    }
    
    if (openCloneViz.hover()) {
      try {
        Path src1 = Paths.get(file + (brackets.isChecked() ? "_1b.clones" : "_1nb.clones"));
        Path src2 = Paths.get(file + (strict.isChecked() ? "_2.clones" : "_2.5.clones"));
        Path obj1 = Paths.get("..\\Clone Visualisation_Data\\type1.txt");
        Path obj2 = Paths.get("..\\Clone Visualisation_Data\\type2.txt");
        //Path obj1 = Paths.get("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation_Data\\type1.txt");
        //Path obj2 = Paths.get("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation_Data\\type2.txt");
        
        Files.copy(src1, obj1, StandardCopyOption.REPLACE_EXISTING);
        Files.copy(src2, obj2, StandardCopyOption.REPLACE_EXISTING);
        
        File file = new File("..\\Clone Visualisation.exe");
        //File file = new File("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation.exe");
        Runtime.getRuntime().exec(file.getAbsolutePath());
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }
  
  // From https://www.geeksforgeeks.org/copy-file-using-filestreams-java/#:~:text=We%20can%20copy%20a%20file,and%20FileOutputStream%20classes%20in%20Java.&text=The%20main%20logic%20of%20copying,file%20associated%20with%20FileOutputStream%20variable.
  public void copy(String src, String obj) {
    FileInputStream fis = null; 
    FileOutputStream fos = null;
    try {
      fis = new FileInputStream(src);
      fos = new FileOutputStream(obj);
      int b; 
      while  ((b=fis.read()) != -1) 
        fos.write(b); 
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      if (fis != null) try {fis.close();} catch(IOException e1) {e1.printStackTrace();}
      if (fos != null) try {fos.close();} catch(IOException e1) {e1.printStackTrace();}
    }
  }
  
}

//-------------------
//      DISTRIBUTIONS
//-------------------

class DistribsTab extends Tab {
  
  RadioButton logaritmic;
  boolean save_check;
  
  public DistribsTab() {
    save_check = false;
  }
  
  public void setup() {
    vizSize(520, 660);
    logaritmic = new RadioButton(20, height - 100, 20, "Logaritmic distributions");
    if (save_check) logaritmic.check();
  }
  
  public void draw() {
    logaritmic.draw();
    
    textFont(font, 20);
    textAlign(CENTER, BOTTOM);
    fill(0);
    
    text("Distribution of Cyclomatic Complexity", width/2, 60);
    text("Distribution of Unit Sizes", width/2, 310);
    
    plotIsto(exceptions.isChecked() ? activeBundle.CCsE : activeBundle.CCsNE, 10, 20, 70, width-60, 200, logaritmic.isChecked());
    plotIsto(activeBundle.USs, 10, 20, 320, width-60, 200, logaritmic.isChecked());
  }
  
  public void mousePressed() {
    if (logaritmic.hover()) {
      save_check = !save_check;
      logaritmic.check();
    }
  }
  
  public int distributionMagnitude(int[] data) {
    return (int) (Math.log10(data.length) + 1);
  }
  
}

//-------------------
//              GRAPH
//-------------------

// 3rd experiment
class GraphTab extends Tab {
  
  private Button generateIntra, generateInter, generateIntraV, generateCbO, generateFanIn, generateAll;
  
  private String baseFile;
  
  GraphTab(String bf) {
    baseFile = bf;
  }
  
  public void setup() {
    vizSize(500, 300);
    generateIntra = new Button(width/4 - 80, 80, 160, 20, "Direct intra-coupling");
    generateInter = new Button(width*3/4 - 80, 80, 160, 20, "Direct inter-coupling");
    generateIntraV = new Button(width/4 - 80, 110, 160, 20, "Intra-coupling");
    generateCbO = new Button(width*3/4 - 80, 110, 160, 20, "Coupling between Objects");
    generateFanIn = new Button(width/4 - 80, 140, 160, 20, "Fan In");
    generateAll = new Button(width*3/4 - 80, 140, 160, 20, "Generate All");
  }
  
  public void draw() {
    generateIntra.draw();
    generateInter.draw();
    generateIntraV.draw();
    generateCbO.draw();
    generateFanIn.draw();
    generateAll.draw();
    
    textAlign(LEFT,TOP);
    fill(0);
    textFont(font, 16);
    text("Generate graphs", 20, 40);
    textFont(font, 10);
    text("All generated graphs are saved as .dot files in the folder /Visualizer/Output/ of this application", 20, 185);
  }
  
  public void mousePressed() {
    if (generateIntra.hover()) generateGraph("_intra_base", false);
    if (generateInter.hover()) generateGraph("_inter_base", true);
    if (generateIntraV.hover()) generateGraph("_intra", false);
    if (generateCbO.hover()) generateGraph("_cbo", true);
    if (generateFanIn.hover()) generateGraph("_fanin", true);
    if (generateAll.hover()) {
      generateGraph("_intra_base", false);
      generateGraph("_inter_base", true);
      generateGraph("_intra", false);
      generateGraph("_cbo", true);
      generateGraph("_fanin", true);
    }
  }
  
  private void generateGraph(String ext, boolean out) {
    File f = new File(baseFile);
    String fileName = f.getName() + ext;
    
    String file = f.getParent() + "\\" + fileName + ".graph";
    String outputFile = "Output\\" + fileName + ".dot";
    
    String[] lines = loadStrings(file);
    
    Map<String, String[]> couplings = new HashMap<String, String[]>();
    for(String line : lines) {
      String[] data = line.split(":");
      if (data.length == 2) couplings.put(data[0], data[1].split(","));
      else couplings.put(data[0], new String[] {});
    }
    
    PrintWriter output = createWriter(outputFile);
    output.println("// online environment: https://dreampuf.github.io/GraphvizOnline");
    output.println("// we highly recomend for readability reasons you use the \"Circo\" engine\n");
    output.println("digraph G {\n");
    
    for (String node : couplings.keySet()) {
      String[] cpls = couplings.get(node);
      String name = nodeName(node);
      output.println("// --- Inner Class: " + node + " ---\n");
      output.println(name + " [label=\"" + node + "\\ncouplings: " + cpls.length + "\",fillcolor=white,color=blue]\n");
      if (out) {
        output.println("// --- Phantom couplings of: " + node + " ---\n");
        for (String phtm : cpls)
          if (!couplings.containsKey(phtm)) output.println(nodeName(phtm) + "_" + name + "[label=\"" + phtm + "\",fillcolor=white,color=black]");
        output.println();
      }
    }
      
    output.println("// --- Edges ---\n");
    
    for (String node1 : couplings.keySet()) {
      for (String node2 : couplings.get(node1)) {
        String name1 = nodeName(node1);
        if (couplings.containsKey(node2))
          output.println(name1 + " -> " + nodeName(node2) + " [fillcolor=blue]");
        else 
          output.println(name1 + " -> " + nodeName(node2) + "_" + name1 + " [fillcolor=black]");
      }
    }
    
    output.println("\n}");
    output.flush();
    output.close();
  }
    
  private String nodeName(String node) {
    return node.replace(".", "").replace("(", "").replace(")", "").replace("$", "");
  }
  
}

// 2nd experiment
/*
class GraphTab extends Tab {
 
  DirectedGraph graph;
  
  private int width = 680, height = 740;
  private boolean stable = false;
  
  void setup() {
    surface.setSize(width, height); 
  }
  
  void draw() {
    if (!stable) stable = graph.reflow();
    graph.draw();
  }
  
  public void generateGraph(String file) {
    graph = new DirectedGraph();
    String[] lines = loadStrings(file);
    
    Map<String, String[]> couplings = new HashMap<String, String[]>();
    for(String line : lines) {
      println(line);
      String[] data = line.split(":");
      if (data.length == 2) couplings.put(data[0], data[1].split(","));
      else couplings.put(data[0], new String[] {});
    }
    
    // Node generation
    Map<String, Node> nodeMap = new HashMap<String, Node>();
    for (String cls : couplings.keySet()) {
      Node node = new Node( cls + ": " + couplings.get(cls).length, 
                            (int) random(60, width - 60), 
                            (int) random(60, height - 130)
                          );
      nodeMap.put(cls, node);
      graph.addNode(node);
    }
    
    for (String node1 : couplings.keySet())
      for (String node2 : couplings.get(node1))
        graph.linkNodes(nodeMap.get(node1), nodeMap.get(node2));
        
    graph.setFlowAlgorithm(new ForceDirectedFlowAlgorithm());
  }
  
}*/

// Old Graph Tab
/*
class GraphTab extends Tab {
  
  private int width = 620, height = 720;
  
  private boolean draw = true;
  
  Button switchButton;
  
  public void setup() {
    surface.setSize(width, height);
    switchButton = new Button(20, height - 100, 80, 20, "Stop");
  }
  
  public void draw() {
    background(255);
  }
  
  public void mouseMoved() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseMovedAt(mouseX, mouseY);
  }
  
  public void mousePressed() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMousePressedAt(mouseX, mouseY);
    if (switchButton.hover()) {
      draw = !draw;
      if (draw) switchButton.setText("Stop");
      else switchButton.setText("Start");
    }
  }
  
  public void mouseDragged() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseDraggedTo(mouseX, mouseY);
  }
  
  public void mouseReleased() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseReleased();
  }
  
  public void generateGraph(String file) {
    graph = new ForceDirectedGraph();
    String[] lines = loadStrings(file);
    
    Map<String, String[]> couplings = new HashMap<String, String[]>();
    for(String line : lines) {
      println(line);
      String[] data = line.split(":");
      if (data.length == 2) couplings.put(data[0], data[1].split(","));
      else couplings.put(data[0], new String[] {});
    }
      
    for (String node : couplings.keySet()) {
      graph.add(new Node(node, 1));
      for (String cpl : couplings.get(node))
        if (!couplings.containsKey(cpl)) 
          graph.add(phantomNode(cpl, node));
    }
    
    graph.set(60.0f, 60.0f, (float) width - 120, (float) (height - 190));
    graph.initializeNodeLocations();
    
    for (String id1 : couplings.keySet())
      for (String id2 : couplings.get(id1))
        if (couplings.containsKey(id2))
          graph.addEdge(id1, id2, graph.getNodeWith(id1).getDiameter() + graph.getNodeWith(id2).getDiameter() + 5);
        else {
          String phantomId2 = getPhantomId(id2, id1);
          println(phantomId2);
          graph.addEdge(id1, phantomId2, graph.getNodeWith(id1).getDiameter() + graph.getNodeWith(phantomId2).getDiameter() + 2);
        }
  }
  
}*/
// By Felix Menard from https://www.openprocessing.org/sketch/24927

public void drawRect(int x1,int y1,int w1, int h1, float value, float total, int clr){
  stroke(1);
  fill(clr);
  rect(x1, y1, w1, h1); //we draw a rectangle    
  fill(1);
  String myPcntStr ;
  int myPcnt = PApplet.parseInt(round ((value / total) *100)) ;
  
  float myPcntDecimal = PApplet.parseInt(round ((value / total) *1000)) ;
  myPcntDecimal = myPcntDecimal/10;
  
  if (myPcntDecimal > 10) //bigger than 10%, we round it up.
    myPcntStr = str(myPcnt) + "%";
  else 
    myPcntStr = str(myPcntDecimal) + "%";
  
  // Rotation fix by Sandro Massa
  if (myPcntDecimal > 0.0f) {
    float wPcnt = textWidth(myPcntStr);
    float hPcnt = textAscent() + textDescent();
    fill(color(0,0,0));
    if (h1 > w1) {
      pushMatrix();
      translate(x1+(w1/2)-hPcnt/4, y1+(h1/2)-wPcnt/2);
      rotate(HALF_PI);
      text(myPcntStr, 0, 0);
      popMatrix();
    } else text(myPcntStr, x1+(w1/2)-10, y1+(h1/2)+5);
  }
}

////////////////////////////////////////////////////////
///   FIND GOOD SPLIT NUMBER - advantagous block aspect ratio.
////////////////////////////////////////////////////////
public int getPerfectSplitNumber(float[] numbers, int blockW, int blockH){
  // This is where well'll need to calculate the possibilities
  // We'll need to calculate the average ratios of created blocks.
  // For now we just try with TWO for the sake of the new functionn...
  
  //Let's just split in either one or two to start...
  
  float valueA = numbers[0];//our biggest value
  float valueB = 0.0f;//value B will correspond to the sum of all remmaining objects in array
  for( int i=1; i < numbers.length; i++ )
    valueB += numbers[i];
  
  float ratio = valueA / (valueB + valueA);
  
  int heightA, widthA;
  if(blockW >= blockH){
    heightA = blockH;
    widthA  = floor(blockW * ratio);
  }else {
    heightA = floor(blockH * ratio);
    widthA  = blockW;
  }
  
  float ratioWH = PApplet.parseFloat(widthA) / PApplet.parseFloat(heightA) ;
  float ratioHW = PApplet.parseFloat(heightA) / PApplet.parseFloat(widthA);
  float diff;
  
  if(widthA >= heightA) // Larger rect //ratio = largeur sur hauteur,
  //we should spit vertically...
    diff = 1 - ratioHW ;
  else //taller rectangle ratio
    diff = 1- ratioWH;
  
  if((diff > 0.5f) && (numbers.length >= 3)) //this is a bit elongated (bigger than 2:1 ratio)
    return 2; //TEMPORARY !!!!
  else //it's a quite good ratio! we don't touch it OR, it's the last one, sorry, no choice.
    return 1;
  
  //diff is the difference (between 0...1) to the square ratio.
  // 0 mean we have a square (don't touch, it's beautifull!)
  // 0.9 mean we have a very long rectangle.
}

////////////////////////////////////////////////////////
///   MAKE BLOCK
////////////////////////////////////////////////////////
public void makeBlock(int refX, int refY, int blockW, int blockH, float[] numbers, float total, int[] clrs){
  // We sort the received array.
  ///////////////////////////////////////////////////////////////
  numbers = reverse(sort(numbers));// we sort the array from biggest to smallest value.
  
  //First we need to asses the optimal number of item to be used for block A
  // How do we do that?
  int nbItemsInABlock = getPerfectSplitNumber(numbers, blockW, blockH); //return the numbers of elements that should be taken for A block. 
   
  float valueA = 0;//the biggest value
  float valueB = 0;//value B will correspond to the sum of all remmaining objects in array
  float[] numbersA = { }; //in the loop, we'll populate these two out of our main array.
  float[] numbersB = { }; 
  int[] colorsA = { };
  int[] colorsB = { };
   
  for( int i=0; i < numbers.length; i++ ) {
    if(i < nbItemsInABlock){//item has to be placed in A array...
      numbersA = append(numbersA, numbers[i]);
      colorsA = append(colorsA, clrs[i]);
      //we populate our new array of values, we'll send it recursivly...
      valueA += numbers[i];
    }else{
      numbersB = append(numbersB, numbers[i]);
      colorsB = append(colorsB, clrs[i]); 
      //we populate our new array of values, we'll send it recursivly...
      valueB += numbers[i];
    }
  }
  float ratio = valueA / (valueB + valueA);
  
  //now we split the block in two according to the right ratio...
  
  /////////////// WE SET THE X, Y, WIDTH, AND HEIGHT VALUES FOR BOTH RECTANGLES.
  
  int xA, yA, heightA, widthA, xB ,yB, heightB, widthB;
  if(blockW > blockH){ //si plus large que haut...
    //we split vertically; so height will stay the same...
    xA = refX;
    yA = refY;// we draw the square in top right corner, so same value.
    heightA = blockH;
    widthA  = floor(blockW * ratio);
    
    xB = refX + widthA;
    yB = refY;
    heightB = blockH;
    widthB = blockW - widthA; //the remaining portion of the width...
  }else{//tall rectangle, we split horizontally.
    xA = refX;
    yA = refY;// we draw the square in top right corner, so same value.
    heightA = floor(blockH * ratio);
    widthA  = blockW;
    
    xB = refX;
    yB = refY+ heightA;
    heightB = blockH - heightA;
    widthB = blockW; //the remaining portion of the width...
  }
  
  /////////////// END OF Block maths.
  
  // if the ratio of the A block is too small (elongated rectangle)
  // we take an extra value for the A sqare, don't draw it, then send the 2 element 
  // it represents to this function (treat it recusvily as if it was a B block).
  // We dont care about the ratio of B block because they are divided after...
  
  // We add the block A to the display List
  // for now, we just draw the thing, let's convert to OOP later...
  
  if(numbersA.length >= 2) //this mean there is still stuff in this arary...
    makeBlock(xA, yA, widthA, heightA, numbersA, total, colorsA);
  else
  //if it's done, we add the B to display list, and that's it for recussivity, we return to main level... 
  // the main function will then deal with all the data...
    drawRect(xA, yA, widthA, heightA, valueA, total, colorsA[0]);
  
  if(numbersB.length >= 2) //this mean there is still stuff in this arary...
    makeBlock(xB, yB, widthB, heightB, numbersB, total, colorsB);
  else
  //if it's done, we add the B to display list, and that's it for recussivity, we return to main level... 
  // the main function will then deal with all the data...
    drawRect(xB, yB, widthB, heightB, valueB, total, colorsB[0]);
  
  //If it represent more than one value, we send the block B to be split again (recursivly)
}



static final int MIN_X = 519;
static final int MIN_Y = 120;

int[] colors4 = {
  color(127,255,0),
  color(255,255,0),
  color(255,127,0),
  color(255,0,0)
};

int[] colorsLOC = {
  color(127,127,255),
  color(127,127,127),
  color(0,255,166)
};

public int sum(int[] a) {
  int s = 0;
  for (int i = 0; i < a.length; i++) s += a[i];
  return s;
}

public float p2d(float p) {
  return 360 * p;
}
  
public String toScore(int s) {
  switch (s) {
    case 2: return "++";
    case 1: return "+";
    case 0: return "o";
    case -1: return "-";
    default: return "--";
  }
}

// From https://www.baeldung.com/java-file-extension
public Optional<String> getFileExtension(String filename) {
  if (filename.contains(".")) return Optional.of(filename.substring(filename.lastIndexOf(".") + 1));
  else return Optional.empty();
}

private void plotIsto(int[] data, int bands, int x, int y, int w, int h, boolean log) {
  if (log) plotIstoLog(data, bands, x, y, w, h);
  else plotIstoLinear(data, bands, x, y, w, h);
}

private void plotIstoLinear(int[] data, int bands, int x, int y, int w, int h) {
  Arrays.sort(data);
  
  int min = data[0];
  int max = data[data.length - 1];
  
  //float stepB = (float) (max - min) / (float) bands; // -- Linear plotting
  float stepB = (float) (max - min) / 2.0f; // -- Logaritmic plotting
  
  float stepHpx = (float) (w-20) / (float) bands;
  float stepVpx = (float) (h-40) / (float) 4;
  
  int[] bandVlms = new int[bands];
  for (int i = 0; i < bands; i++) bandVlms[i] = 0;
  
  int iData = 0, iBand = 0;
  int maxBandHeight = 0;
  while (iData < data.length && iBand < bands) {
     if (data[iData] > min + (iBand + 1)*stepB) {
       if (bandVlms[iBand] > maxBandHeight) maxBandHeight = bandVlms[iBand];
       iBand++;
     }
     bandVlms[iBand]++;
     iData++;
  }
  if (bandVlms[iBand] > maxBandHeight) maxBandHeight = bandVlms[iBand];
  
  float stepV = maxBandHeight / 4;
  
  stroke(0);
  fill(0);
  textFont(font, 12);
  
  line(x+20, y, x+20, y+h-40);
  line(x+20, y+h-40, x+w, y+h-40);
  
  textAlign(RIGHT);
  for (int i = 0; i <= 4; i++) { 
    line(x+20, y+h-40-i*stepVpx, x+18, y+h-40-i*stepVpx); 
    text(Integer.toString((int) (i*stepV)), x+16, y+h-40-i*stepVpx+6);
  }
  
  textAlign(CENTER,TOP);
  for (int i = 0; i <= bands; i++) {
    line(x+20+i*stepHpx, y+h-40, x+20+i*stepHpx, y+h-38); 
    text(Integer.toString(min + (int) (i*stepB)), x+20+i*stepHpx, y+h-36);
  }
  
  for (int i = 0; i < bands; i++) {
    fill(150);
    rect(x+20+i*stepHpx,y+h-40,stepHpx,-calcHeight(bandVlms[i], maxBandHeight, h-40));
    fill(0);
    text("(" + Integer.toString(bandVlms[i]) + ")", x+20+i*stepHpx+(stepHpx / 2), y+h-16);
  }
}

private void plotIstoLog(int[] data, int bands, int x, int y, int w, int h) {
  Arrays.sort(data);
  
  int min = data[0];
  int max = data[data.length - 1];
  
  //float stepB = (float) (max - min) / (float) bands; // -- Linear plotting
  float[] stepsB = new float[bands]; // -- Logaritmic plotting
  
  int candidateBand;
  float bound = max - min;
  for (candidateBand = bands-1; candidateBand > 0 && bound >= 1; candidateBand--, bound /= 2) stepsB[candidateBand] = bound;
  
  if (candidateBand > 0) {
    float[] newSteps = new float[bands - candidateBand];
    for (int i = 1; i < bands - candidateBand; i++) newSteps[i] = stepsB[i + candidateBand];
    stepsB = newSteps;
    bands -= candidateBand;
  }
  
  stepsB[0] = stepsB[1];
  
  float stepHpx = (float) (w-20) / (float) bands;
  float stepVpx = (float) (h-40) / (float) 4;
  
  int[] bandVlms = new int[bands];
  for (int i = 0; i < bands; i++) bandVlms[i] = 0;
  
  int iData = 0, iBand = 0;
  int maxBandHeight = 0;
  int upperBound = min + (int) stepsB[iBand];
  while (iData < data.length && iBand < bands) {
     if (data[iData] > upperBound) {
       if (bandVlms[iBand] > maxBandHeight) maxBandHeight = bandVlms[iBand];
       iBand++;
       if (iBand == bands - 1) upperBound = max;
       else upperBound += stepsB[iBand];
     }
     bandVlms[iBand]++;
     iData++;
  }
  if (bandVlms[iBand] > maxBandHeight) maxBandHeight = bandVlms[iBand];
  
  float stepV = maxBandHeight / 4;
  
  stroke(0);
  fill(0);
  textFont(font, 12);
  
  line(x+20, y, x+20, y+h-40);
  line(x+20, y+h-40, x+w, y+h-40);
  
  textAlign(RIGHT);
  for (int i = 0; i <= 4; i++) { 
    line(x+20, y+h-40-i*stepVpx, x+18, y+h-40-i*stepVpx); 
    text(Integer.toString((int) (i*stepV)), x+16, y+h-40-i*stepVpx+6);
  }
  
  textAlign(CENTER,TOP);
  int val = min;
  for (int i = 0; i <= bands; i++) {
    line(x+20+i*stepHpx, y+h-40, x+20+i*stepHpx, y+h-38); 
    text(Integer.toString(val), x+20+i*stepHpx, y+h-36);
    if (i < bands) val += stepsB[i];
  }
  
  for (int i = 0; i < bands; i++) {
    fill(150);
    rect(x+20+i*stepHpx,y+h-40,stepHpx,-calcHeight(bandVlms[i], maxBandHeight, h-40));
    fill(0);
    text("(" + Integer.toString(bandVlms[i]) + ")", x+20+i*stepHpx+(stepHpx / 2), y+h-16);
  }
}

private int calcHeight(int count, int maxHeight, int h) {
  return count * h / maxHeight;
}

private void center() {
  GraphicsDevice gd = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice();
  surface.setLocation((gd.getDisplayMode().getWidth() - width) / 2, (gd.getDisplayMode().getHeight() - height) / 2);
}

public float avg(int[] vals) {
  int sum = 0;
  for (int i : vals) sum += i;
  return (float) sum / (float) vals.length;
}

public float sum(float[] vals) {
  float sum = 0.0f;
  for (float f : vals) sum += f;
  return sum;
}

/**
 * Simmple graph layout system
 * http://processingjs.nihongoresources.com/graphs
 * This code is in the public domain
 *

// =============================================
//      Some universal helper functions
// =============================================

// universal helper function: get the angle (in radians) for a particular dx/dy
float getDirection(double dx, double dy) {
  // quadrant offsets
  double d1 = 0.0;
  double d2 = PI/2.0;
  double d3 = PI;
  double d4 = 3.0*PI/2.0;
  // compute angle basd on dx and dy values
  double angle = 0;
  float adx = abs((float)dx);
  float ady = abs((float)dy);
  // Vertical lines are one of two angles
  if(dx==0) { angle = (dy>=0? d2 : d4); }
  // Horizontal lines are also one of two angles
  else if(dy==0) { angle = (dx>=0? d1 : d3); }
  // The rest requires trigonometry (note: two use dx/dy and two use dy/dx!)
  else if(dx>0 && dy>0) { angle = d1 + atan(ady/adx); }    // direction: X+, Y+
  else if(dx<0 && dy>0) { angle = d2 + atan(adx/ady); }    // direction: X-, Y+
  else if(dx<0 && dy<0) { angle = d3 + atan(ady/adx); }    // direction: X-, Y-
  else if(dx>0 && dy<0) { angle = d4 + atan(adx/ady); }    // direction: X+, Y-
  // return directionality in positive radians
  return (float)(angle + 2*PI)%(2*PI); }

// universal helper function: rotate a coordinate over (0,0) by [angle] radians
int[] rotateCoordinate(float x, float y, float angle) {
  int[] rc = {0,0};
  rc[0] = (int)(x*cos(angle) - y*sin(angle));
  rc[1] = (int)(x*sin(angle) + y*cos(angle));
  return rc; }

// universal helper function for Processing.js - 1.1 does not support ArrayList.addAll yet
void addAll(ArrayList a, ArrayList b) { for(Object o: b) { a.add(o); }}*/
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Visualiser" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
