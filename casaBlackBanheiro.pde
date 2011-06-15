import processing.serial.*;

// number of squares on the wall...
static final int NUM_SQS = 6;

// for state-machine based implementation
// has blocking play state...
static final int STATE_START  = 0;
static final int STATE_LISTEN = 1;
static final int STATE_PLAY   = 2;
int myState;

// for keeping track of squares and their brightness
int playingNum;
int fadeLevel;
// might also need :
// int[NUM_SQS] sqX, sqY;
// int[NUM_SQS] sqH, sqW;

// Images of squares to be updated
PImage[] mySquares = new PImage[NUM_SQS];
// Serial connection
Serial mySerial = null;

void setup() {
  size(380, 260);
  background(0, 0, 0);
  println(Serial.list());

  playingNum = -1;
  // while outside the playing state, this is always -255 
  // which means (waiting to fade to black)
  fadeLevel = -255;

  // draw some white squares
  for (int i=0; i<NUM_SQS; i++) {
    PImage t = createImage(100, 100, ARGB);
    for (int j=0; j<t.width; j++)
      for (int k=0; k<t.height; k++)
        t.set(j, k, color(255, 255, 255, 255));
    mySquares[i] = t;
    image(t, (i%3)*120+20, (i/3)*120+20);
  }

  mySerial = new Serial(this, (String)Serial.list()[0], 9600);
  myState = STATE_START;
}

void draw() {
  // state machine !!

  // start state : wait for start signal from other side
  //               request data
  //               wait
  if (myState == STATE_START) {
    // if there's stuff on serial
    if (mySerial.available() > 0) {
      int myRead = mySerial.read();
      // got start signal
      if (myRead == 'A') {
        // clear buf
        mySerial.clear();
        // request data (first request)
        mySerial.write('A');
        // update state
        myState = STATE_LISTEN;
        System.out.println("started listening");
      }
      // got something, but didn't get start signal... keep waiting
      else {
        myState = STATE_START;
      }
    }
    // nothing on serial... keep waiting
    else {
      myState = STATE_START;
    }
  }

  // listen state : play default audio/visual
  //                wait for data from the other side
  else if (myState == STATE_LISTEN) {
    // if there's stuff on serial
    if (mySerial.available() > 0) {
      int myRead = mySerial.read();
      // read number into a variable
      // READ IT HERE! and check if it's a number!!
      playingNum = myRead;
      System.out.println("Got Go From: "+myRead);
      delay(800);
      // clear serial buffer
      mySerial.clear();
      // play what you just got
      myState = STATE_PLAY;
    }
    // else, keep playing default stuff (try not to block)
    else {
      // play default a/v stuff
      // MIGHT have to play an audio, or text, otherwise just stay here
      // stay here
      myState = STATE_LISTEN;
    }
  }

  // play state : fade out lights
  //              play a/v 
  //              fade in lights
  else if (myState == STATE_PLAY) {
    // while playing, keep playing

    // pick what to do based on light level
    // level == 0      : have faded out all the way, play a/v
    // level > 255     : have faded back in, go back to listen
    // 0 < level < 255 : fading... keep fading

    // have turned off all but the chosen square
    // play a/v
    if (fadeLevel == 0) {
      // play sound/video
      // PLAY IT HERE (probably block???)
      System.out.println("playing. blocked.");
      delay(2000);
      // when done, start brightening up the lights
      fadeLevel = 1;
    }
    // have turned up all of the lights. ready to leave
    else if (fadeLevel > 255) {
      System.out.println("done processing");
      // clear buf
      mySerial.clear();
      // request data
      mySerial.write('A');
      // go back to listen
      myState = STATE_LISTEN;
      // reset the fade level to -255
      // (always -255 while outside the play state, meaning "ready to fade out")
      fadeLevel = -255;
    }
    // while fading... keep fading...
    else {
      // update the fade level
      // a hack to detect when it has finished turning down all the way.
      // (if it crosses the 0, going from negative -> positive)
      // has to happen before drawing in order to get all-black squares
      boolean lt0 = (fadeLevel<0);
      fadeLevel += 15;
      if (lt0 && (fadeLevel>0)) {
        fadeLevel = 0;
      }

      // only update the background when we are changing/creating an image
      background(0, 0, 0);
      // redraw all squares with fade levels, but keep the selected one white
      for (int i=0; i<NUM_SQS; i++) {
        PImage t = mySquares[i];
        // change the fade in all squares, except the one that's playing
        setAlpha(t, (i==playingNum)?255:abs(fadeLevel));
        image(t, (i%3)*120+20, (i/3)*120+20);
      }
    }
  } // STATE_PLAY
} // draw()

// stupid function.
void setAlpha(PImage img, int a) {
  for (int i=0; i<img.height; i++) {
    for (int j=0; j<img.width; j++) {
      img.set(i, j, color(255, 255, 255, a));
    }
  }
}

