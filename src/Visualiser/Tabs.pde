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
    text("Unit Complexity", 20, 80);
    text("Unit Size", 20, 100);
    text("Duplicated code", 20, 120);
    
    textAlign(CENTER);
    
    text(toScore(rankLOC), width/2, 60);
    text(toScore(exceptions.isChecked() ? ranksUC[1] : ranksUC[0]), width/2, 80);
    text(toScore(rankUS), width/2, 100);
    text(toScore(rankDUP), width/2, 120);
    
    textAlign(RIGHT);
    textFont(font, 12);
    
    text(linesOfCode[0], width - 20, 60);
    text(printPercs(exceptions.isChecked() ? percRiskUCE : percRiskUCNE), width - 20, 80);
    text(printPercs(percRiskUS), width - 20, 100);
    text(duplicateLines, width - 20, 120);
  }
  
  private String printPercs(float[] percs) {
    String sPercs = String.format("%4.2f%c", percs[0], '%');
    for (int i = 1; i < percs.length; i++) sPercs += String.format(" / %4.2f%c", percs[i], '%');
    return sPercs;
  }
}
