public class Button {
  
  private int x, y, width, height;
  private String text;
  private color bg;
  private color border;
  private color textColor;
  
  public Button(int x, int y, int width, int height, String text) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.text = text;
    this.bg = color(255,255,255);
    this.border = color(0,0,0);
  }
  
  public void setActive() {bg = color(230,230,230);}
  public void setInactive() {bg = color(255,255,255);}
  public boolean hover() {return mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height;}
  
  public void draw() {
    if (hover()) fill(color(245,245,245));
    else fill(bg);
    stroke(border);
    rect(x, y, width, height);
    
    fill(textColor);
    noStroke();
    textFont(font, 12);
    textAlign(CENTER);
    text(text, x + width/2, y + height/2 + 6);
  }
  
}
