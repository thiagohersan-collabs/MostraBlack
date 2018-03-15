import processing.opengl.*;


PImage foo;
int x[] = new int[4];
int y[] = new int[4];

int cnt;

void setup() {
  size(1024, 796, OPENGL);
  foo = loadImage("pMDF.jpg");
  for(int i=0; i<4; i++) {
    x[i] = -1;
    y[i] = -1;
  }
  cnt = 0;
}

void draw() {
  background(0);
  image(foo, 0, 0, 800, 600);
  frameRate(20);
}

void mouseReleased() {
  x[cnt] = (int)mouseX;
  y[cnt] = (int)mouseY;

  cnt++;
  
  if(cnt == 4) {
    cnt = 0;
    for(int i=0; i<4; i++) {
      print(x[i]+"\t"+y[i]+"\t");
    }
    println();
  }

}

