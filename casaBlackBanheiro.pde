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
static final int NUM_SQS = 6;

// for state-machine based implementation
static final int STATE_START  = 0;
static final int STATE_LISTEN = 1;
static final int STATE_FADE   = 2;
static final int STATE_PLAY   = 3;
int myState;

// for keeping track of squares and their brightness
int playingNum;
int fadeLevel;
// might also need :
// Tuple[] sqPos  = new Tuple[NUM_SQS];
// Tuple[] sqDim  = new Tuple[NUM_SQS];
// Tuple[] txtPos = new Tuple[NUM_SQS];
// Tuple[] txtDim = new Tuple[NUM_SQS];


// Images of squares to be updated
PImage[] mySquares = new PImage[NUM_SQS];
// Serial connection
Serial mySerial = null;
// font
PFont font;
// sound file streams
Minim minim;
AudioPlayer[] myAudio = new AudioPlayer[NUM_SQS];

void setup() {
  size(380, 260, OPENGL);
  background(0, 0, 0);
  println(Serial.list());

  // audio lib
  minim = new Minim(this);

  // not playing any audio
  playingNum = -1;
  // while listening, this is always -255 
  // which means waiting to fade to black
  fadeLevel = -255;

  // draw some white squares
  for (int i=0; i<NUM_SQS; i++) {
    PImage t = createImage(100, 100, ARGB);
    for (int j=0; j<t.width; j++)
      for (int k=0; k<t.height; k++)
        t.set(j, k, color(255, 255, 255, 255));
    mySquares[i] = t;
    image(t, (i%3)*120+20, (i/3)*120+20);
    // audio streams
    myAudio[i] = minim.loadFile("file"+i+".aiff");
  }

  // setup serial port
  mySerial = new Serial(this, (String)Serial.list()[0], 9600);
  // setup font
  font = loadFont("Courier10PitchBT-Bold-48.vlw");
  textFont(font, 16);
  fill(255, 255, 255);
  // initial state
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
        // send start signal
        mySerial.write('A');
        // update state
        myState = STATE_LISTEN;
        System.out.println("started listening");
        // very last thing before going to LISTEN
        mySerial.clear();
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
  //                invariant : the serial buf is clear when we come in the first time
  else if (myState == STATE_LISTEN) {
    // assume buf was cleared before we got here
    // if there's stuff on serial, it's new
    if (mySerial.available() > 0) {
      int myRead = mySerial.last();
      // read number into a variable
      // READ IT HERE! and check if it's a number!!
      playingNum = myRead;
      System.out.println("Got Go From: "+myRead);
      // setup audio player
      // paranoid. this should already be at 0
      myAudio[playingNum].rewind();
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
      // next state
      myState = STATE_PLAY;
      // last thing we do here : clear buff
      mySerial.clear();
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
      mySerial.clear();
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
  //              invariant : the serial buf was cleared before we got here the first time
  else if (myState == STATE_PLAY) {
    // if not playing anything, check if it has to play or has played
    if (myAudio[playingNum].isPlaying() == false) {
      // if position is 0, then it hasn't started playing...
      // play sound
      if(myAudio[playingNum].position() == 0) {
        System.out.println("start Playing");
        // start sound
        myAudio[playingNum].play();
        // show text...
        fill(255, 255, 255);
        text((playingNum+": blah blablalhabl ajhakjhdkj ak kdajh dakj d akhd jsd h"), 
        (playingNum%3)*120+20, (1-(playingNum/3))*120+20, 100, 100);
      }
      // else, it stopped for some other reason (stop or end of file)
      // rewind and go back to fade
      else {
        // reset the player
        myAudio[playingNum].rewind();
        // go back to fade state for fade in
        myState = STATE_FADE;
        // erase text...
        fill(0, 0, 0, 128);
        rect((playingNum%3)*120+20, (1-(playingNum/3))*120+20, 100, 100);
        delay(500);
      }
    }

    // while playing, keep playing and listening for stop requests
    else {
      // if there's stuff on serial, it's new
      if (mySerial.available() > 0) {
        // if it's the same number that is playing, stop audio
        if ( mySerial.last() == playingNum ) {
          System.out.println("STOP Playing");
          // stop audio
          myAudio[playingNum].pause();
        }
        // got a different number
        else {
          // keep playing
          myState = STATE_PLAY;
        }
      }
      // nothing on serial... keep playing
      else {
        // keep playing
        myState = STATE_PLAY;
      }
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
  for (int i=0; i<img.height; i++) {
    for (int j=0; j<img.width; j++) {
      img.set(i, j, color(255, 255, 255, a));
    }
  }
}

// stupid class for keeping x,y info
public class Tuple {
  public int x, y;
}

