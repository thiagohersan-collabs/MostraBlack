/*
 * Sketch for reading sensor data, fading lights and playing an audio.
 *
 * Simplified serial communication : Arduino sends data everytime a sensor is fired.
 *                                   Just have to clear buf before going to a state
 *                                   that reads it, and then read the very last value ...
 *
 */

import processing.serial.*;
import processing.opengl.*;
import ddf.minim.*;

// number of squares on the wall...
static final int NUM_SQS = 10;

// font size
static final int FONTSIZE = 16;

// for reading input file
BufferedReader reader;
String readerLine;

// for state-machine based implementation
static final int STATE_START  = 0;
static final int STATE_LISTEN = 1;
static final int STATE_FADE   = 2;
static final int STATE_PLAY   = 3;
int myState;

// for keeping track of squares and their brightness
int playingNum;
int fadeLevel;

intOct[]   quadPos = new intOct[NUM_SQS];

//int txtIndex = -1;

// text to be displayed with each sound
//String[] theTxt = new String[NUM_SQS];

// Images of squares to be updated
PGraphics   myQuads = null;

// Serial connection
Serial mySerial = null;
// font
//PFont font;
// sound file streams
Minim minim;
AudioPlayer[] myAudio = new AudioPlayer[NUM_SQS];

void setup() {
  size(1024, 768, P2D);
  smooth();
  background(0, 0, 0);
  println(Serial.list());

  // audio lib
  minim = new Minim(this);

  // not playing any audio
  playingNum = -1;
  // while listening, this is always -255 
  // which means waiting to fade to black
  fadeLevel = -255;

  // fill position and dimension arrays
  //    for the light squares and text squares

  ///////////////
  // for QUADS
  // fill position and dimension arrays
  //    for the light squares and text squares
  reader = createReader("casaBlackQuadPositions.txt");    

  // read position from file...
  for (int i=0; i< NUM_SQS; i++) {
    try {
      readerLine = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      readerLine = null;
    }

    String[] pieces = split(readerLine, TAB);
    quadPos[i] = new intOct(int(pieces[0]), int(pieces[1]), int(pieces[2]), int(pieces[3]), int(pieces[4]), int(pieces[5]), int(pieces[6]), int(pieces[7]));
  }


  myQuads = createGraphics(width, height, P2D);
  hint(DISABLE_OPENGL_ERROR_REPORT);

  myQuads.beginDraw();
  myQuads.background(0, 0, 0, 255);
  //myQuads.fill(#99182c);
  myQuads.fill(#ff0000);
  myQuads.smooth();
  for (int i=0; i<NUM_SQS; i++) {
    myQuads.quad(quadPos[i].getX(0), quadPos[i].getY(0), quadPos[i].getX(1), quadPos[i].getY(1), quadPos[i].getX(2), quadPos[i].getY(2), quadPos[i].getX(3), quadPos[i].getY(3));
  }
  myQuads.endDraw();

  // init audio
  for (int i=0; i<NUM_SQS; i++) {
    // audio streams
    myAudio[i] = minim.loadFile("file"+i+".aif");
  }

  image(myQuads, 0, 0);

  // initial state
  myState = STATE_START;

  // setup serial port
  mySerial = new Serial(this, (String)Serial.list()[0], 19200);
  mySerial.bufferUntil('\n');
}


void serialEvent(Serial p) {
  int myRead = p.read();
  if (myRead == 'A') {
    mySerial.write('A');
    // update state
    myState = STATE_LISTEN;
    System.out.println("started listening");
    p.clear();
  }
  else if (myState == STATE_LISTEN) {
    if ((myRead > -1)&&(myRead < NUM_SQS)) {
      playingNum = myRead;
      // setup audio player
      // paranoid. this should already be at 0
      myAudio[playingNum].rewind();
      // play what you just got
      myState = STATE_FADE;
      println("got go from: "+ playingNum);
      p.clear();
    }
    else {
      myState = STATE_LISTEN;
      System.out.println("Read a number out of bounds...  "+myRead+"  . Problem in serial com (??)");
    }
  }
  else if (myState == STATE_PLAY) {
    if ( myRead == playingNum ) {
      System.out.println("STOP Playing");
      // stop audio
      myAudio[playingNum].pause();
      p.clear();
      //playingNum = myRead;
    }
  }
}

void draw() {
  // state machine !!

  // start state : wait for start signal from other side
  //               request data
  //               wait
  if (myState == STATE_START) {
    delay(10);
    // wait for the start signal from arduino
  }

  // listen state : play default audio/visual
  //                wait for data from the other side
  //                invariant : the serial buf is clear when we come in the first time
  else if (myState == STATE_LISTEN) {
    delay(10);
    // listen for arduino and wait for a go signal...
  }

  // fade state : fade out lights
  //              request data
  //              go to next state
  //              fade in lights
  //              go to next state
  else if (myState == STATE_FADE) {
    // pick what to do based on light level
    // level == 0      : have faded out all the way, play a/v
    // level > 255     : have faded back in, go back to listen
    // 0 < level < 255 : fading... keep fading

    // have turned off all but the chosen square
    // go play audio/video
    if (fadeLevel == 0) {
      System.out.println("done with fade out");
      // setup the fade in
      fadeLevel = 1;
      // next state
      myState = STATE_PLAY;
      // last thing we do here : clear buff
      if (mySerial != null) {
        mySerial.clear();
      }
    }
    // have turned up all of the lights. ready to leave
    else if (fadeLevel > 255) {
      System.out.println("done with fade in");
      // reset the fade level to -255
      // (always -255 while listening, meaning "ready to fade out")
      fadeLevel = -255;
      // go back to listen
      myState = STATE_LISTEN;
      // last thing we do here : clear buf
      if (mySerial != null) {
        mySerial.clear();
      }
    }
    // while fading... keep fading...
    else {
      // update the fade level
      // a hack to detect when it has finished turning down all the way.
      // (if it crosses the 0, going from negative -> positive)
      // has to happen before drawing in order to get all-black squares
      boolean lt0 = (fadeLevel<0);
      fadeLevel += 10;
      if (lt0 && (fadeLevel>0)) {
        fadeLevel = 0;
      }

      // Draw the squares! (could be a function)
      // only update the background when we are changing/creating an image
      background(0, 0, 0);
      // redraw all squares with fade levels, but keep the selected one white
      /*
      for (int i=0; i<NUM_SQS; i++) {
       PImage t = mySquares[i];
       // change the fade in all squares, except the one that's playing
       setAlpha(t, (i==playingNum)?255:abs(fadeLevel));
       image(t, sqPos[i].getX(), sqPos[i].getY());
       }
       */
      myQuads.beginDraw();
      myQuads.smooth();
      myQuads.background(0, 0, 0, 255);
      //myQuads.fill(#99182c);
      //myQuads.fill(255,0,0);
      myQuads.fill(255, 255, 255, 255);
      myQuads.quad(quadPos[playingNum].getX(0), quadPos[playingNum].getY(0), quadPos[playingNum].getX(1), quadPos[playingNum].getY(1), quadPos[playingNum].getX(2), quadPos[playingNum].getY(2), quadPos[playingNum].getX(3), quadPos[playingNum].getY(3));

      for (int i=0; i<NUM_SQS; i++) {
        // alpha!!!
        myQuads.fill(#99182c, abs(fadeLevel));
        myQuads.quad(quadPos[i].getX(0), quadPos[i].getY(0), quadPos[i].getX(1), quadPos[i].getY(1), quadPos[i].getX(2), quadPos[i].getY(2), quadPos[i].getX(3), quadPos[i].getY(3));
      }
      myQuads.endDraw();
      image(myQuads, 0, 0);
    }
  } // STATE_FADE

  // play state : play audio/video (non-blocking?!)
  //              listen for stop signal
  //              invariant : the serial buf was cleared before we got here the first time
  else if (myState == STATE_PLAY) {
    // if not playing anything, check if it has to play or has played
    if (myAudio[playingNum].isPlaying() == false) {
      // if position is 0, then it hasn't started playing...
      // play sound
      if (myAudio[playingNum].position() == 0) {
        System.out.println("start Playing");
        // start sound
        myAudio[playingNum].play();
      }
      // else, it stopped for some other reason (stop or end of file)
      // rewind and go back to fade
      else {
        // reset the player
        myAudio[playingNum].rewind();
        // go back to fade state for fade in
        myState = STATE_FADE;
        // for smoothing the fade back
        delay(500);
      }
    }

    // while playing, keep playing and listening for stop requests
    else {
      // serial event listener takes care of this...
    }
  } // STATE_PLAY
} // draw()

// stop function for cleaning up stuff
public void stop() {
  for (int i=0; i<NUM_SQS; i++)
    myAudio[i].close();
  minim.stop();
  super.stop();
}

// stupid function for fading squares...
void setAlpha(PImage img, int a) {
  for (int i=0; i<img.width; i++) {
    for (int j=0; j<img.height; j++) {
      img.set(i, j, color(255, 255, 255, a));
    }
  }
}

///////////////////////////
// helper classes for keeping 2 floats together
////////////////////////////
public class floatTuple {
  private float x, y, sum;

  public floatTuple(float x, float y) {
    this.x = x;
    this.y = y;
    this.sum = x+y;
  }

  public float getX() { 
    return x;
  }
  public float getY() { 
    return y;
  }
  public float getSum() { 
    return sum;
  }
}

/////////////////////////////////
public class intTuple {
  private int x, y;

  public intTuple(int x, int y) {
    this.x = x;
    this.y = y;
  }

  public int getX() { 
    return x;
  }
  public int getY() { 
    return y;
  }
}


public class intOct {
  private int x[], y[];

  public intOct(int x0, int y0, int x1, int y1, int x2, int y2, int x3, int y3) {
    x = new int[4];
    y = new int[4];

    x[0] = x0;
    y[0] = y0;
    x[1] = x1;
    y[1] = y1;
    x[2] = x2;
    y[2] = y2;
    x[3] = x3;
    y[3] = y3;
  }

  int getX(int i) {
    return x[i];
  }
  int getY(int i) {
    return y[i];
  }
}

void keyReleased() {
  println(key);
  for (int i=0; i<NUM_SQS; i++) {
    if ((key-'0') == i) {
      playingNum = i;
      System.out.println("Got Go From: "+i);
      // setup audio player
      // paranoid. this should already be at 0
      myAudio[playingNum].rewind();
      // play what you just got
      myState = STATE_FADE;
    }
  }
}

