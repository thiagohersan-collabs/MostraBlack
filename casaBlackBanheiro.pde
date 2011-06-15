/*
 * Sketch for reading sensor data, fading lights and playing an audio.
 *
 * Has complicated serial communication: requests data, and waits for answers...
 */


import processing.serial.*;

// number of squares on the wall...
static final int NUM_SQS = 6;

// for state-machine based implementation
static final int STATE_START  = 0;
static final int STATE_LISTEN = 1;
static final int STATE_FADE   = 2;
static final int STATE_PLAY   = 3;
int myState;

// for simulating an audio file
static final int audioLen = 40;
int audio = audioLen;

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
  // while listening, this is always -255 
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
        // request data (first request)
        mySerial.write('A');
        // make sure other side has a delay before
        // it sends stuff so this side can clear buf
        mySerial.clear();
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
  //                invariant : there's a standing request for data while in this state
  else if (myState == STATE_LISTEN) {
    // if there's stuff on serial
    if (mySerial.available() > 0) {
      //println("listen: "+mySerial.available());
      int myRead = mySerial.read();
      // read number into a variable
      // READ IT HERE! and check if it's a number!!
      playingNum = myRead;
      System.out.println("Got Go From: "+myRead);
      // clear serial buffer
      mySerial.clear();
      // play what you just got
      myState = STATE_FADE;
    }
    // else, keep playing default stuff and listening
    else {
      // play default a/v stuff
      // MIGHT have to play an audio, or text, otherwise just stay here
      // stay here
      myState = STATE_LISTEN;
    }
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
      // clear buff
      mySerial.clear();
      // request data for a stop signal
      mySerial.write('A');
      // next state
      myState = STATE_PLAY;
    }
    // have turned up all of the lights. ready to leave
    else if (fadeLevel > 255) {
      System.out.println("done with fade in");
      // reset the fade level to -255
      // (always -255 while listening, meaning "ready to fade out")
      fadeLevel = -255;
      // already requested in play...
      // clear buf
      mySerial.clear();
      // request data
      // possible that there's already a request in arduino buffer
      // but this is safer than requesting data before fading back in
      mySerial.write('A');
      // go back to listen
      myState = STATE_LISTEN;
    }
    // while fading... keep fading...
    else {
      // update the fade level
      // a hack to detect when it has finished turning down all the way.
      // (if it crosses the 0, going from negative -> positive)
      // has to happen before drawing in order to get all-black squares
      boolean lt0 = (fadeLevel<0);
      fadeLevel += 25;
      if (lt0 && (fadeLevel>0)) {
        fadeLevel = 0;
      }

      // Draw the squares! (could be a function)
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
  } // STATE_FADE

  // play state : play audio/video (non-blocking?!)
  //              listen for stop signal
  //              invariant : there's a standing request for data while in this state
  else if (myState == STATE_PLAY) {
    // if not playing anything, start audio
    if (audio == audioLen) {
      System.out.println("start Playing");
      // start playing audio
      audio--;
    }
    // if at the end of the audio, stop audio and go back to fade
    else if (audio == 0) {
      System.out.println("done Playing: "+mySerial.available());
      // done playing, reset my variable
      audio = audioLen;
      // go back to fade state for fade in
      myState = STATE_FADE;
    }
    // while playing, keep playing and listening for stop requests
    else {
      // if there's stuff on serial, check if it's the same number that we're playing
      if (mySerial.available() > 0) {
        //println("play: "+mySerial.available());
        // if it's the same number that is playing, stop audio
        int t = mySerial.read();
        if ( t == playingNum ) {
          System.out.println("STOP Playing");
          // stop audio
          audio = 0;
        }
        // got a different number
        else {
          // keep playing
          audio--;
        }
        // regardless of number, request new data
        // (either a STOP signal, or a signal for LISTEN state)
        // clear serial buffer
        mySerial.clear();
        // send new request for PLAY state
        mySerial.write('A');
      }
      // nothing on serial... keep playing
      // if it never gets a stop request, arduino will
      // have 2 requests on buffer when we go back to LISTEN
      // (it's ok. safer than sending a LISTEN request from here, before fade in)
      else {
        audio--;
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

