int SIZEX;
int SIZEY;
int globalState = 4;
//4 = bar
//3 = bar-to-line switch phase 1
//2 = bar-to-line switch phase 2
//1 = - unused
//0 = - unused
//-1 = line-to-bar phase 3
//-2 = line-to-bar phase 2
//-3 = line-to-bar phase 1
//-4 = line
float oldWidth, oldHeight, fontSize = 12;
float NUM_Y_LABELS = 8;
float DATA_X_START = 100;
float DATA_X_END = 700;
float DATA_Y_START = 50;
float DATA_Y_END = 500;
float CHART_BUFFER = 0.18f;
float LABEL_Y = 550;
float LABEL_X = 10;
float TRANS_TIME = 100f;
float min, max;
boolean resizeFlag = false;

String xlabel, ylabel;
float xlx, xly;
float ylx, yly;

PFont f;
Table tab;
ArrayList<Drawable> components = new ArrayList<Drawable>();
ArrayList<Range> ranges = new ArrayList<Range>();

Button button = new Button(690, 10, 100, 50);

void setup() {
  surface.setResizable(true);
  
  SIZEX = 800;
  SIZEY = 600;
  size(800, 600);
  oldWidth = width;
  oldHeight = height;
  xlx = width/2;
  xly = height - 10;
  ylx = 20;
  yly = 50;
  f = createFont("Arial_Bold",12,true);
  textFont(f,fontSize);
  readInData();
  components.add(button);
  ranges.add(button);
}

void draw() {
  if(globalState == 2) {
    for(int i = 0; i < components.size() - 1; i++) {
      if(components.get(i) instanceof Bar && components.get(i+1) instanceof Bar) {
        Line newLine = new Line((Bar)components.get(i), (Bar)components.get(i+1));
        ranges.add(newLine);
        newLine.setState(3);
        components.remove(i);
        components.add(i, newLine);
      } else if(components.get(i) instanceof Bar) {
        Line newLine = new Line((Bar)components.get(i), null);
        ranges.add(newLine);
        components.remove(i);
        components.add(i, newLine);
      }
    }
    for(int i = 0; i < components.size(); i++) {
      if(components.get(i) instanceof Bar) {
        components.remove(i);
        i--;
      }
    }
  }
  if(globalState == -2) {
    for(int i = 0; i < components.size(); i++) {
      if(components.get(i) instanceof Line) {
        Line l = (Line)components.get(i);
        if(!l.b1.isLast) {
          ranges.remove(l);
          components.remove(i);
          i--;
        }
        
      }
      if(i >= 0 && components.get(i) instanceof Bar) {
        ranges.remove((Range)components.get(i));
        components.remove(i);
      }
    }
    //Had to do it this strange way due to a bug where the resize wasnt getting passed down
    //  properly to the Bars when i wasnt just recreating them all
    readInData();
    for(int i = 0; i < components.size(); i++) {
      components.get(i).setState(-1);
    }
    globalState = -1;
  }
  background(100, 100, 100);
  for(Drawable d : components) {
    d.drawShape();
  }
  for(int i = 0; i < NUM_Y_LABELS; i++) {
    text(lerp(min, max, i/NUM_Y_LABELS), LABEL_X, DATA_Y_END - i*((DATA_Y_END - 50)/NUM_Y_LABELS));
  }
  fill(0, 0, 0);
  text(xlabel, xlx, xly);
  text(ylabel, ylx, yly);
  fill(250, 250, 250);
  resizeFlag = false;
  if(width != oldWidth || height != oldHeight) {
    resizeFlag = true;
    for(int i = 0; i < components.size(); i++) {
      components.get(i).resizeSelf(oldWidth, oldHeight, width, height);
    }
    fontSize *= (width + height)/(oldWidth + oldHeight);
    textFont(f,fontSize);
    LABEL_X *= width/oldWidth;
    LABEL_Y *= height/oldHeight;
    DATA_X_START *= width/oldWidth;
    DATA_X_END *= width/oldWidth;
    DATA_Y_START *= height/oldHeight;
    DATA_Y_END *= height/oldHeight;
    xlx *= width/oldWidth;
    xly *= height/oldHeight;
    ylx *= width/oldWidth;
    yly *= height/oldHeight;
    
  }
  oldWidth = width;
  oldHeight = height;
}

void mouseReleased() {
  for(int i = 0; i < ranges.size(); i++) {
    ranges.get(i).mouseClick(mouseX, mouseY);
  }
}

void mouseMoved() {
  for(int i = 0; i < ranges.size(); i++) {
    ranges.get(i).mouseMove(mouseX, mouseY);
  }
}

void switchState() {
  if(globalState == 4) {
    globalState = 3;
    for(int i = 0; i < components.size(); i++) {
      components.get(i).setState(1);
    }
  }
  if(globalState == -4) {
    globalState = -3;
    for(int i = 0; i < components.size(); i++) {
      components.get(i).setState(1);
    }
  }
}

void readInData() {
  tab = loadTable("data.csv", "header");
  Table tab2 = loadTable("data.csv");
  Bar[] bars = new Bar[tab.getRowCount()];
  TableRow labels = tab2.getRow(0);
  String col1 = labels.getString(0);
  String col2 = labels.getString(1);
  xlabel = col1;
  ylabel = col2;
  print(col1 + " " + col2);
  int i = 0;
  float curX = 100;
  float xinterval = (width - DATA_X_START)/tab.getRowCount();
  max = tab.getRow(0).getFloat(col2);
  min = max;
  for(TableRow row : tab.rows()) {
    bars[i] = new Bar(row.getString(col1), row.getFloat(col2), curX, 10);
    if(bars[i].getVal() > max) {
        max = bars[i].getVal();
    }
    if(bars[i].getVal() < min) {
        min = bars[i].getVal();
    }
    curX += xinterval;
    i++;
  }
  min -= Math.abs(min - max)*CHART_BUFFER;
  max += Math.abs(min - max)*CHART_BUFFER;
  for(Bar b : bars) {
    b.setY(DATA_Y_START + lerp(0, DATA_Y_END - DATA_Y_START, 1 - Math.abs(b.getVal() - min)/Math.abs(max - min)));
    b.setHeight(DATA_Y_END - b.getY());
    components.add(b);
    ranges.add(b);
  }
}

interface Drawable {
  void drawShape();
  void setState(int s);
  void resizeSelf(float ow, float oh, float nw, float nh);
}

class Bar implements Drawable, Range {
  
  String label;
  float val, xpos, ypos, wid, hei, ttx, tty;
  float origWidth, origHeight;
  boolean isLast = false, tooltip = false, alreadyUpdated = false;
  int state = 0;
  //1 = transitioning into line
  //0 = stable bar
  //-1 = transitioning back into bar
 
  public Bar(String l, float v, float x, float w) {
    label = l;
    val = v;
    xpos = x;
    wid = w;
    origWidth = w;
  }
 
  public Bar(String l, float v, float x, float y, float w, float h) {
    label = l;
    val = v;
    xpos = x;
    ypos = y;
    wid = w;
    origWidth = w;
    hei = h;
    origHeight = h;
  }
  
  void setState(int s) {
    state = s;
    if(state == -1) {
      hei = 0;
    }
  }
  
  int getState() {
    return state;
  }
  
  void makeLast() {
    isLast = true;
  }
  
  boolean isLast() {
    return isLast;
  }
  
  void setY(float y) {
    ypos = y;
  }
  
  void setHeight(float h) {
    hei = h;
    origHeight = h;
  }
  
  String getLabel() {
    return label;
  }
  
  float getHeight() {
    return hei;
  }
  
  float getVal() {
    return val;
  }
  
  float getX() {
    return xpos;
  }
  
  float getY() {
    return ypos;
  }
  
  void drawShape() {
    update();
    rect(xpos, ypos, wid, hei);
    text(label, xpos, LABEL_Y);
    if(tooltip) {
      fill(0, 0, 0);
      text("(" + label + "," + val + ")", ttx, tty);
      fill(250, 250, 250);
    }
  }
  
  void update() {
    alreadyUpdated = false;
    if(state == 1 && !resizeFlag) {
      hei -= origHeight/TRANS_TIME;
      if(hei <= 0) {
        hei = 0;
        state = 0;
        globalState = 2;
      }
    }
    if(state == -1 && !resizeFlag) {
      hei += origHeight/TRANS_TIME;
      if(hei >= origHeight) {
        hei = origHeight;
        state = 0;
        globalState = 4;
      }
    }
  }
  
  void mouseClick(float mx, float my) {}
  
  void mouseMove(float mx, float my) {
    ttx = mx - 40;
    tty = my - 10;
    if(mx > xpos && mx < xpos + wid && my > ypos && my < ypos + hei) {
      tooltip = true;
    } else {
      tooltip = false;
    }
  }
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    if(!alreadyUpdated) {
      xpos *= nw/ow;
      ypos *= nh/oh;
      wid *= nw/ow;
      hei *= nh/oh;
      origHeight *= nh/oh;
      alreadyUpdated = true;
    }
    
  }
}

interface Range {
  void mouseMove(float x, float y);
  void mouseClick(float x, float y);
}

class Button implements Range, Drawable {
  float x, y, wid, hei;
  
  public Button(float xx, float yy, float w, float h) {
    x = xx;
    y = yy;
    wid = w;
    hei = h;
  }
  
  void mouseMove(float xx, float yy) {
    
  }
  
  void mouseClick(float xx, float yy) {
    if(xx > x && xx < x + wid && yy > y && yy < y + hei) {
      switchState();
    }
  }
  
  void drawShape() {
    rect(x, y, wid, hei);
  }
  
  void setState(int s){}
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    x *= nw/ow;
    y *= nh/oh;
    wid *= nw/ow;
    hei *= nh/oh;
  }
}

class Line implements Drawable, Range {
  Bar b1, b2;
  
  String l1, l2;
  float x1, x2, y1, y2, ttx, tty;
  float scale = 1;
  boolean isLast;
  int state = 0, tooltip = 0;
  //3 bar into line phase 1
  //2 bar into line phase 2
  //1 line into bar transition
  //0 stable
  
  public Line(Bar b11, Bar b22) {
    b1 = b11;
    b2 = b22;
    x1 = b1.getX();
    y1 = b1.getY();
    l1 = b1.getLabel();
    if(b2 != null) {
      x2 = b2.getX();
      y2 = b2.getY();
      l2 = b2.getLabel();
    } else {
      isLast = true;
    }
  }
  
  void makeLast() {
    isLast = true;
  }
  
  void setState(int s) {
    state = s;
  }
  
  int getState() {
    return state;
  }
  
  Bar getB1() {
    return b1;
  }
  
  Bar getB2() {
    return b2;
  }
  
  void mouseClick(float mx, float my) {}
  
  void mouseMove(float mx, float my) {
    ttx = mx - 40;
    tty = my - 10;
    if(Math.sqrt((mx - x1)*(mx - x1) + (my - y1)*(my - y1)) < 10) {
      tooltip = 1;
    } else if(Math.sqrt((mx - x2)*(mx - x2) + (my - y2)*(my - y2)) < 10){
      tooltip = 2;
    } else {
      tooltip = 0;
    }
  }
  
  void drawShape() {
    update();
    if(isLast) {
      text(l1, x1, LABEL_Y);
      ellipse(x1, y1, 10, 10);
    } else {
      line(x1, y1, lerp(x1, x2, scale), lerp(y1, y2, scale));
      ellipse(x1, y1, 10, 10);
      ellipse(x2, y2, 10, 10);
      text(l1, x1, LABEL_Y);
      text(l2, x2, LABEL_Y);
    }
    
    if(tooltip != 0) {
      if(tooltip == 1) {
        fill(0, 0, 0);
        text("(" + l1 + "," + b1.getVal() + ")", ttx, tty);
        fill(250, 250, 250);
      } else {
        fill(0, 0, 0);
        text("(" + l2 + "," + b2.getVal() + ")", ttx, tty);
        fill(250, 250, 250);
      }
      
    }
    
  }
  
  void update() {
    if(state == 3) {
      state = 2;
      scale = 0;
    }
    if(state == 2) {
      scale += 1.0f/TRANS_TIME;
      if(scale > 1) {
        scale = 1;
        state = 0;
        globalState = -4;
      }
    }
    if(state == 1) {
      scale -= 1.0f/TRANS_TIME;
      if(scale < 0) {
        globalState = -2;
        state = -1; //dead
      }
    }
  }
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    x1 *= nw/ow;
    y1 *= nh/oh;
    x2 *= nw/ow;
    y2 *= nh/oh;
    b1.resizeSelf(ow, oh, nw, nh);
    if(b2 != null) {
      b2.resizeSelf(ow, oh, nw, nh);
    }
  }
}