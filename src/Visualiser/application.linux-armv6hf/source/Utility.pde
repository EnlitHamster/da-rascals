import java.util.Random;
import java.util.Arrays;

static final int MIN_X = 519;
static final int MIN_Y = 120;

color[] colors4 = {
  color(127,255,0),
  color(255,255,0),
  color(255,127,0),
  color(255,0,0)
};

color[] colorsLOC = {
  color(127,127,255),
  color(127,127,127),
  color(0,255,166)
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

float avg(int[] vals) {
  int sum = 0;
  for (int i : vals) sum += i;
  return (float) sum / (float) vals.length;
}

float sum(float[] vals) {
  float sum = 0.0;
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
