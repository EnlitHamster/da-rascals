import java.util.Set;
import java.util.HashSet;

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
    surface.setSize(520, 600); 
  } 
  
  public void draw() {
    fill(0);
    textFont(font, 16); 
    textAlign(LEFT);
    
    text("Lines of Code", 20, 60);
    text("Duplicated code", 20, 100);
    text("Unit Complexity", 20, 180);
    text("Unit Size", 20, 240);
    
    textAlign(CENTER);
    
    text(toScore(activeBundle.rankLOC), width/2, 60);
    text(toScore(activeBundle.rankDUP), width/2, 100);
    text(toScore(exceptions.isChecked() ? activeBundle.ranksUC[1] : activeBundle.ranksUC[0]), width/2, 180);
    text(toScore(activeBundle.rankUS), width/2, 240);
    
    textFont(font, 12);
    textAlign(RIGHT);
    
    text(activeBundle.linesOfCode[0] + String.format(" (%4.2f%c)", (float) activeBundle.linesOfCode[0] * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 60);
    text(activeBundle.duplicateLines + String.format(" (%4.2f%c)", (float) activeBundle.duplicateLines * 100 / (float) activeBundle.linesOfCode[3], '%'), width - 20, 100);
    
    printPercs(exceptions.isChecked() ? activeBundle.riskUCE : activeBundle.riskUCNE, exceptions.isChecked() ? activeBundle.percRiskUCE : activeBundle.percRiskUCNE, 180);
    printPercs(activeBundle.riskUS, activeBundle.percRiskUS, 240);
    
    printHeader(140);
    String [][] mapping = createMapping();
    printMap(mapping, 80, 340);
  }
  
  String[][] createMapping() {
    String[][] mapping = new String[6][6];
    mapping = addX(mapping);
    mapping = addLabels(mapping);
    mapping = addRankings(mapping);
    return mapping;
  }
  
  String[][] addLabels(String[][] mapping) {
    mapping[2][0] = "analysabilty";
    mapping[3][0] = "changeabilty";
    mapping[4][0] = "testability";
    mapping[5][0] = "overall";
    
    mapping[0][1] = "Volume";
    mapping[0][2] = "Complexity";
    mapping[0][3] = "Duplication";
    mapping[0][4] = "Unit Size";
    return mapping;
  }
  
  String[][] addRankings(String[][] mapping) {
    int offset = 0;
    if (exceptions.isChecked()) {
      offset = 1;
    }
    mapping[2][5] = toScore(activeBundle.scores[0]);
    mapping[3][5] = toScore(activeBundle.scores[1+offset]);
    mapping[4][5] = toScore(activeBundle.scores[3+offset]);
    mapping[5][5] = toScore(activeBundle.scores[5+offset]);
    
    mapping[1][1] = toScore(activeBundle.rankLOC);
    mapping[1][2] = toScore(exceptions.isChecked() ? activeBundle.ranksUC[1] : activeBundle.ranksUC[0]);
    mapping[1][3] = toScore(activeBundle.rankDUP);
    mapping[1][4] = toScore(activeBundle.rankUS);
    return mapping;
  }
  
  String[][] addX(String[][] mapping) {
    int xs[][] = {{2,1}, {2,3}, {2,4}, {3,2}, {3,3}, {5,2}, {5,4}};
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
    line(x+60, y+1*yoff+5, x+4.7*xoff, y+1*yoff+5); 
    line(x+4.3*xoff, y+1*yoff+5, x+4.3*xoff, y+5.3*yoff); 
    line(x+60, y+4*yoff+5, x+4.7*xoff, y+4*yoff+5);
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

class GraphTab extends Tab {
  
  ForceDirectedGraph graph;
  
  private int sWidth = 600, sHeight = 710;
  
  public void setup() {
    surface.setSize(sWidth, sHeight);
    generateGraph();
    //graph.dumpInformation();
  }
  
  public void draw() {
    background(255);
    graph.draw();
  }
  
  public void mouseMoved() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseMovedAt(mouseX, mouseY);
  }
  
  public void mousePressed() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMousePressedAt(mouseX, mouseY);
  }
  
  public void mouseDragged() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseDraggedTo(mouseX, mouseY);
  }
  
  public void mouseReleased() {
    if (graph.isIntersectingWith(mouseX, mouseY)) graph.onMouseReleased();
  }
  
  private void generateGraph() {
    graph = new ForceDirectedGraph();
    String[] lines = loadStrings("example.graph");
    
    Map<String, String[]> couplings = new HashMap<String, String[]>();
    for(String line : lines) {
      String[] data = line.split(":");
      couplings.put(data[0], data[1].split(","));
    }
    
    Set<String> nodes = new HashSet(couplings.keySet());
    for (String[] cpls : couplings.values())
      for (String cpl : cpls) nodes.add(cpl);
      
    for (String node : nodes) {
      int size = couplings.containsKey(node) ? couplings.get(node).length : 0;
      graph.add(new Node(node, size+1));
    }
    
    graph.set(0.0f, 0.0f, (float) sWidth, (float) (sHeight - 110));
    graph.initializeNodeLocations();
    
    for (String node : couplings.keySet()) println(node);
    
    for (String id1 : couplings.keySet())
      for (String id2 : couplings.get(id1)) {
        if (couplings.containsKey(id1) && couplings.containsKey(id2)) {
          println(id1 + " " + id2);
          graph.addEdge(id1, id2, graph.getNodeWith(id1).getDiameter() + graph.getNodeWith(id2).getDiameter() + 30);
        } else
          graph.addEdge(id1, id2, graph.getNodeWith(id1).getDiameter() + graph.getNodeWith(id2).getDiameter());
      }
  }
  
}
