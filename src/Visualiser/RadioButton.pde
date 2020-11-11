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
