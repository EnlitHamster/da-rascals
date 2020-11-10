abstract class Tab {
  abstract public void setup();
  abstract public void draw();
}

//-------------------
//               PIES
//-------------------

class PiesTab extends Tab {
  
  public void setup() {
    surface.setSize(460, 600); 
  }
  
  public void draw() {  
    fill(0);
    textFont(font, 20);
    textAlign(CENTER);
    
    text("Unit Complexity", 120, 60);
    text("Unit Size", 120, 320);
    text("Lines of code", 340, 60);
    
    noStroke();
    
    pieChart(120, 180, exceptions.isChecked() ? percRiskUCE : percRiskUCNE, colors4);
    pieChart(120, 440, percRiskUS, colors4);
    pieChart(340, 180, percLOC, colorsLOC); 
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
    
    text(toScore(rankLOC), width/2, 60);
    text(toScore(rankDUP), width/2, 100);
    text(toScore(exceptions.isChecked() ? ranksUC[1] : ranksUC[0]), width/2, 180);
    text(toScore(rankUS), width/2, 240);
    
    textFont(font, 12);
    textAlign(RIGHT);
    
    text(linesOfCode[0] + String.format(" (%4.2f%c)", (float) linesOfCode[0] / (float) linesOfCode[3], '%'), width - 20, 60);
    text(duplicateLines + String.format(" (%4.2f%c)", (float) duplicateLines / (float) linesOfCode[3], '%'), width - 20, 100);
    
    printPercs(exceptions.isChecked() ? riskUCE : riskUCNE, exceptions.isChecked() ? percRiskUCE : percRiskUCNE, 180);
    printPercs(riskUS, percRiskUS, 240);
    
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
    mapping[4][0] = "stabilty";
    mapping[5][0] = "testability";
    
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
    mapping[2][5] = toScore(scores[0]);
    mapping[3][5] = toScore(scores[1+offset]);
    mapping[4][5] = toScore(scores[3+offset]);
    mapping[5][5] = toScore(scores[5+offset]);
    
    mapping[1][1] = toScore(rankLOC);
    mapping[1][2] = toScore(exceptions.isChecked() ? ranksUC[1] : ranksUC[0]);
    mapping[1][3] = toScore(rankDUP);
    mapping[1][4] = toScore(rankUS);
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
    line(x+60, y+1*yoff+5, x+4.3*xoff, y+1*yoff+5); 
    line(x+4.2*xoff, y+1*yoff+5, x+4.2*xoff, y+1*yoff+5); 
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
