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
