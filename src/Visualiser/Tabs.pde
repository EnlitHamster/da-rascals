import java.util.Set;
import java.util.HashSet;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

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
    vizSize(460, 630); 
  }
  
  public void draw() {  
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
    
    pieChart(width/4, 180, exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE, colors4);
    pieChart(width/4, 440, activeBundle.percRiskUS, colors4);
    pieChart(3*width/4, 180, activeBundle.percLOC, colorsLOC); 
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
    text(activeBundle.clonesType1 + String.format(" (%4.2f%c)", (float) activeBundle.clonesType1 * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 100);
    text(activeBundle.clonesType1 + String.format(" (%4.2f%c)", (float) activeBundle.asserts * 100 / (float) activeBundle.testLOC, '%'), width - 20, 300);
    
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
//               DATA
//-------------------

class DataTab extends Tab {
  
  Button openCloneViz;
  String file;
  
  public DataTab(String file) {this.file = file;}
  
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
    vizSize(520, 490);
    openCloneViz = new Button(20, 380, 160, 20, "Open clones visualizer");
  }
  
  public void draw() {
    openCloneViz.draw();
    
    fill(0);
    textFont(fontBd, 12); 
    textAlign(LEFT);
    
    int descWidth = 160;
    int dataWidth = width - (descWidth + 40);
    
    text("Line count", 20, 60);
    text("Token count", 20, 100);
    text("Cyclomatic complexity", 20, 140);
    text("Unit Size", 20, 220);
    text("Clones", 20, 300);
    text("Asserts", 20, 340);
    text("Lines of test", 20, 360);
    
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
    
    text("type 1", descWidth + dataWidth/4, 300);
    text("type 2", descWidth + 3*dataWidth/4, 300);
    
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
    
    text(CC[(int) (lenCC * 0.05)], descWidth + dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.35)], descWidth + 3*dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.65)], descWidth + 5*dataWidth/8, 200);
    text(CC[(int) (lenCC * 0.95)], descWidth + 7*dataWidth/8, 200);
    
    text(min(activeBundle.USs), descWidth + dataWidth/8, 240);
    text(max(activeBundle.USs), descWidth + 3*dataWidth/8, 240);
    text(avg(activeBundle.USs), descWidth + 5*dataWidth/8, 240);
    text(activeBundle.USs[lenUS / 2], descWidth + 7*dataWidth/8, 240);
    
    text(activeBundle.USs[(int) (lenUS * 0.05)], descWidth + dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.35)], descWidth + 3*dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.65)], descWidth + 5*dataWidth/8, 280);
    text(activeBundle.USs[(int) (lenUS * 0.95)], descWidth + 7*dataWidth/8, 280);
    
    text(activeBundle.clonesType1, descWidth + dataWidth/4, 320);
    text(activeBundle.clonesType2, descWidth + 3*dataWidth/4, 320);
    
    text(activeBundle.asserts, descWidth + dataWidth/2, 340);
    text(activeBundle.testLOC, descWidth + dataWidth/2, 360);
  }
  
  // C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\
  void mousePressed() {
    if (openCloneViz.hover()) {
      try {
        Path src1 = Paths.get(file + (brackets.isChecked() ? "_1b.clones" : "_1nb.clones"));
        Path src2 = Paths.get(file + "_2.clones");
        Path obj1 = Paths.get("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation_Data\\type1.txt");
        Path obj2 = Paths.get("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation_Data\\type2.txt");
        
        Files.copy(src1, obj1, StandardCopyOption.REPLACE_EXISTING);
        Files.copy(src2, obj2, StandardCopyOption.REPLACE_EXISTING);
        
        File file = new File("C:\\Users\\sandr\\Documents\\University\\SE\\Series1\\src\\Visualiser\\Clone Visualisation.exe");
        Runtime.getRuntime().exec(file.getAbsolutePath());
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }
  
  // From https://www.geeksforgeeks.org/copy-file-using-filestreams-java/#:~:text=We%20can%20copy%20a%20file,and%20FileOutputStream%20classes%20in%20Java.&text=The%20main%20logic%20of%20copying,file%20associated%20with%20FileOutputStream%20variable.
  void copy(String src, String obj) {
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
  
  public void setup() {
    vizSize(520, 660);
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
  
  private Button generateIntra, generateInter, generateIntraV, generateCbO, generateFanIn, generateAll;
  
  private String baseFile;
  
  GraphTab(String bf) {baseFile = bf;}
  
  void setup() {
    vizSize(500, 300);
    
    generateIntra = new Button(width/4 - 80, 80, 160, 20, "Direct intra-coupling");
    generateInter = new Button(width*3/4 - 80, 80, 160, 20, "Direct inter-coupling");
    generateIntraV = new Button(width/4 - 80, 110, 160, 20, "Intra-coupling");
    generateCbO = new Button(width*3/4 - 80, 110, 160, 20, "Coupling between Objects");
    generateFanIn = new Button(width/4 - 80, 140, 160, 20, "Fan In");
    generateAll = new Button(width*3/4 - 80, 140, 160, 20, "Generate All");
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
