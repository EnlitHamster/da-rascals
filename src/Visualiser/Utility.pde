import java.util.Random;
import java.util.Arrays;

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

int sum(int[] a) {
  int s = 0;
  for (int i = 0; i < a.length; i++) s += a[i];
  return s;
}

float p2d(float p) {
  return 360 * p;
}
  
String toScore(int s) {
  switch (s) {
    case 2: return "++";
    case 1: return "+";
    case 0: return "o";
    case -1: return "-";
    default: return "--";
  }
}

// From https://www.baeldung.com/java-file-extension
Optional<String> getFileExtension(String filename) {
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
  float stepB = (float) (max - min) / 2.0; // -- Logaritmic plotting
  
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
