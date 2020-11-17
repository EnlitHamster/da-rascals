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










PFont font;

// NOT CONSIDERING BRACKETS
Bundle brkts, noBrkts, activeBundle;

Map<Button, Tab> tabs;
Button activeButton;

Button piesButton, scoresButton, distribsButton, graphButton, changeDB;
RadioButton exceptions, brackets;

boolean run;

public void setup() {
  selectDB();
}

public void draw() {    
  if (run) {
    background(255);
    tabs.get(activeButton).draw();
    piesButton.draw();
    scoresButton.draw();
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
  noStroke();
  
  piesButton = new Button(0, 0, 80, 20, "Pie charts");
  scoresButton = new Button(80, 0, 80, 20, "Scores");
  distribsButton = new Button(160, 0, 80, 20, "Distributions");
  graphButton = new Button(240, 0, 80, 20, "Graphs");
  
  tabs = new HashMap<Button, Tab>();
  tabs.put(piesButton, new PiesTab());
  tabs.put(scoresButton, new ScoresTab());
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
  final int rankLOC;
  final int[] CCsNE;
  final int[] CCsE;
  final int[] riskUCNE;
  final int[] riskUCE;
  final int[] ranksUC;
  final int[] USs;
  final int[] riskUS;
  final int rankUS;
  final int duplicateLines;
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
      CCsNE = PApplet.parseInt(split(database[0], ','));
      CCsE = PApplet.parseInt(split(database[1], ','));
      riskUCNE = PApplet.parseInt(split(database[2], ','));
      riskUCE = PApplet.parseInt(split(database[3], ','));
      ranksUC = PApplet.parseInt(split(database[4], ','));
      USs = PApplet.parseInt(split(database[5], ','));
      riskUS = PApplet.parseInt(split(database[6], ','));
      rankUS = PApplet.parseInt(database[7]);
      linesOfCode = PApplet.parseInt(split(database[skipBrkts ? 8 : 9], ','));
      rankLOC = PApplet.parseInt(split(database[10], ',')[skipBrkts ? 0 : 1]);
      duplicateLines = PApplet.parseInt(split(database[11], ',')[skipBrkts ? 0 : 1]);
      rankDUP = PApplet.parseInt(split(database[12], ',')[skipBrkts ? 0 : 1]);
      scores = PApplet.parseInt(split(database[skipBrkts ? 13 : 14], ','));
      asserts = PApplet.parseInt(database[15]);
      testLOC = PApplet.parseInt(split(database[16], ',')[skipBrkts ? 0 : 1]);
      rankTQ = PApplet.parseInt(split(database[17], ',')[skipBrkts ? 0 : 1]);
      
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
  
  public void setup() {
    surface.setSize(460, 630); 
  }
  
  public void draw() {  
    fill(0);
    textFont(font, 20);
    textAlign(CENTER);
    
    text("Unit Complexity", 120, 60);
    text("Unit Size", 120, 320);
    text("Lines of code", 340, 60);
    text("Legend", 340, 320);
    
    textAlign(LEFT);
    textFont(font, 16);
    
    text("Low risk elements", 270, 356);
    text("Medium risk elements", 270, 386);
    text("High risk elements", 270, 416);
    text("Very high risk elements", 270, 446);
    text("Lines of code", 270, 476);
    text("Empty lines", 270, 506);
    text("Comment lines", 270, 536);
    
    noStroke();
    
    fill(colors4[0]);    rect(240, 340, 20, 20);
    fill(colors4[1]);    rect(240, 370, 20, 20);
    fill(colors4[2]);    rect(240, 400, 20, 20);
    fill(colors4[3]);    rect(240, 430, 20, 20);
    fill(colorsLOC[0]);  rect(240, 460, 20, 20);
    fill(colorsLOC[1]);  rect(240, 490, 20, 20);
    fill(colorsLOC[2]);  rect(240, 520, 20, 20);    
    
    pieChart(120, 180, exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE, colors4);
    pieChart(120, 440, activeBundle.percRiskUS, colors4);
    pieChart(340, 180, activeBundle.percLOC, colorsLOC); 
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
  
}

//-------------------
//             SCORES
//-------------------

class ScoresTab extends Tab {
  
  public void setup() {
    surface.setSize(600, 660); 
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
    text(activeBundle.duplicateLines + String.format(" (%4.2f%c)", (float) activeBundle.duplicateLines * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 100);
    text(activeBundle.duplicateLines + String.format(" (%4.2f%c)", (float) activeBundle.asserts * 100 / (float) activeBundle.testLOC, '%'), width - 20, 300);
    
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
//      DISTRIBUTIONS
//-------------------

class DistribsTab extends Tab {
  
  RadioButton logaritmic;
  
  public void setup() {
    surface.setSize(520, 660);
    logaritmic = new RadioButton(20, height - 100, 20, "Logaritmic distributions");
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
    if (logaritmic.hover()) logaritmic.check();
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
  
  private int sWidth = 500, sHeight = 300;
  
  private Button generateIntra, generateInter, generateIntraV, generateCbO, generateFanIn, generateAll;
  
  private String baseFile;
  
  GraphTab(String bf) {baseFile = bf;}
  
  public void setup() {
    surface.setSize(sWidth, sHeight);
    generateIntra = new Button(sWidth/4 - 80, 80, 160, 20, "Direct intra-coupling");
    generateInter = new Button(sWidth*3/4 - 80, 80, 160, 20, "Direct inter-coupling");
    generateIntraV = new Button(sWidth/4 - 80, 110, 160, 20, "Intra-coupling");
    generateCbO = new Button(sWidth*3/4 - 80, 110, 160, 20, "Coupling between Objects");
    generateFanIn = new Button(sWidth/4 - 80, 140, 160, 20, "Fan In");
    generateAll = new Button(sWidth*3/4 - 80, 140, 160, 20, "Generate All");
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
  
  private int sWidth = 680, sHeight = 740;
  private boolean stable = false;
  
  void setup() {
    surface.setSize(sWidth, sHeight); 
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
                            (int) random(60, sWidth - 60), 
                            (int) random(60, sHeight - 130)
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
  
  private int sWidth = 620, sHeight = 720;
  
  private boolean draw = true;
  
  Button switchButton;
  
  public void setup() {
    surface.setSize(sWidth, sHeight);
    switchButton = new Button(20, sHeight - 100, 80, 20, "Stop");
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
    
    graph.set(60.0f, 60.0f, (float) sWidth - 120, (float) (sHeight - 190));
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



int[] colors4 = {
  color(127,255,0),
  color(255,255,0),
  color(255,127,0),
  color(255,0,0)
};

int[] colorsLOC = {
  color(127,127,255),
  color(127,127,127),
  color(127,255,127)
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
