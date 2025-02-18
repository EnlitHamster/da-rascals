import java.util.Map;
import java.util.HashMap;
import java.util.Optional;

import java.io.File;

import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;

PFont font, fontIt, fontBd;

// NOT CONSIDERING BRACKETS
Bundle brkts, noBrkts, activeBundle;

Map<Button, Tab> tabs;
Button activeButton;

Button piesButton, scoresButton, dataButton, distribsButton, graphButton, changeDB;
RadioButton exceptions, brackets;

boolean run;

void setup() {
  try {println(new File(".").getCanonicalPath());} catch (IOException ignored) {}
  selectDB();
}

void draw() {    
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

void activate(Button btn) {
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

void mousePressed() {
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

void mouseMoved() {
  tabs.get(activeButton).mouseMoved();
}

void mouseDragged() {
  tabs.get(activeButton).mouseDragged();
}

void mouseReleased() {
  tabs.get(activeButton).mouseReleased();
}

void selectDB() {
  run = false;
  noLoop();
  selectInput("Select a metrics file", "fileSelected");
}

void fileSelected(File selection) {
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

void processInput(String dbFile) {
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

void vizSize(int x, int y) {
  surface.setSize(max(x - 1, MIN_X), max(y, MIN_Y)); 
}
