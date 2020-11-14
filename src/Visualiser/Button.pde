public class Button implements AbstractButton {
  
  private int x, y, w, h;
  private String text;
  private color bg;
  private color border;
  private color textColor;
  
  public Button(int x, int y, int w, int h, String text) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.text = text;
    this.bg = color(255,255,255);
    this.border = color(0,0,0);
  }
  
  public void setActive() {bg = color(230,230,230);}
  public void setInactive() {bg = color(255,255,255);}
  public boolean hover() {return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;}
  
  public void draw() {
    if (hover()) fill(color(245,245,245));
    else fill(bg);
    stroke(border);
    rect(x, y, w, h);
    
    fill(textColor);
    noStroke();
    textFont(font, 12);
    textAlign(CENTER);
    text(text, x + w/2, y + h/2 + 6);
  }
  
  public void update(int x, int y) {
     this.x = x;
     this.y = y;
  }
  
}
