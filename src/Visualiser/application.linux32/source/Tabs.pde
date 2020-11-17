import java.util.Set;
import java.util.HashSet;

import java.io.File;

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

  private void pieChart(int x, int y, float[] data, color[] colors) {
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
  
  String[][] createMapping() {
    String[][] mapping = new String[7][7];
    mapping = addX(mapping);
    mapping = addLabels(mapping);
    mapping = addRankings(mapping);
    return mapping;
  }
  
  String[][] addLabels(String[][] mapping) {
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
  
  String[][] addRankings(String[][] mapping) {
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
  
  String[][] addX(String[][] mapping) {
    int xs[][] = {{2,1}, {2,3}, {2,4}, {2,5}, {3,2}, {3,3}, {4,5}, {5,2}, {5,4}, {5,5}};
    for(int []xy : xs) {
      mapping[xy[0]][xy[1]] = "x";
    }
    return mapping;
  }
  
  void printMap(String[][] mapping, int x, int y) {
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
  
  void printLines(int x, int y, int xoff, int yoff) {
    stroke(0);
    line(x+60, y+1*yoff+5, x+5.7*xoff, y+1*yoff+5); 
    line(x+5.3*xoff, y+1*yoff+5, x+5.3*xoff, y+6.3*yoff); 
    line(x+60, y+5*yoff+5, x+5.7*xoff, y+5*yoff+5);
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
  
  int distributionMagnitude(int[] data) {
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
  
  void setup() {
    surface.setSize(sWidth, sHeight);
    generateIntra = new Button(sWidth/4 - 80, 80, 160, 20, "Direct intra-coupling");
    generateInter = new Button(sWidth*3/4 - 80, 80, 160, 20, "Direct inter-coupling");
    generateIntraV = new Button(sWidth/4 - 80, 110, 160, 20, "Intra-coupling");
    generateCbO = new Button(sWidth*3/4 - 80, 110, 160, 20, "Coupling between Objects");
    generateFanIn = new Button(sWidth/4 - 80, 140, 160, 20, "Fan In");
    generateAll = new Button(sWidth*3/4 - 80, 140, 160, 20, "Generate All");
  }
  
  void draw() {
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
  
  void mousePressed() {
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
