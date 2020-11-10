public class RadioButton {
  
  int x, y, dimensions;
  boolean checked;
  
  public RadioButton(int x, int y, int dim) {
    this.x = x;
    this.y = y;
    this.dimensions = dim;;
    this.checked = false;
  }
  
  public void check() {checked = !checked;}
  public boolean isChecked() {return checked;}
  public boolean hover() {return mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height;}
  
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
  }
  
}
