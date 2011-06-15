import processing.serial.*;

Serial mySerial = null;

// for first draft...
boolean hasStarted = false;
boolean needData = true;

int fooCounter = 0;   // for testing

// for state-machine based implementation
static final int STATE_START  = 0;
static final int STATE_LISTEN = 1;
static final int STATE_PLAY   = 2;

int myState;

void setup() {
  size(10, 10);
  println(Serial.list());

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
    //System.out.println("LISTEN");
    // if there's stuff on serial
    if (mySerial.available() > 0) {
      int myRead = mySerial.read();
      // read number into a variable
      // READ IT HERE!
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
      // PLAY SOMETHING HERERERE
      myState = STATE_LISTEN;
    }
  }

  // play state : play new a/v based on variable read from serial
  else if (myState == STATE_PLAY) {
    //System.out.println("PLAY");
    // while playing, keep playing
    if (fooCounter < 20) {
      // keep playing stuff based on variable read from Serial
      System.out.println("processing: "+int(20-fooCounter));
      fooCounter++;
    }
    // done playing
    else {
      fooCounter = 0;
      System.out.println("done processing");
      // clear buf
      mySerial.clear();
      // request data
      mySerial.write('A');
      // go back to listen
      myState = STATE_LISTEN;
    }
  }
  
  
  
}

void draw1() {

  // if we need data and there's stuff on the serial port
  // check to see if it's the begining of the communication
  // or if it's data
  if (needData == true) {
    // check to see if there's stuff on serial
    if (mySerial.available() > 0) {
      int myRead = mySerial.read();
      // read a start signal
      if (hasStarted == false) {
        if (myRead == 'A') {
          mySerial.clear();
          hasStarted = true;
          mySerial.write('A');
          System.out.println("started! listening!");
        }
      }
      // read data
      else {
        System.out.println("got go from: "+myRead);
        mySerial.clear();
        delay(1000);
        // process it, do stuff, probably don't want to be asking for data 
        needData = false;
      }
    }
    // nothing on serial, but I need data
    else {
      // sends a lot of these...
      mySerial.write('A');
    }
  }
  // don't need data, probably because I'm processing some stuff
  else {
    if (fooCounter > 20) {
      System.out.println("done processing. need data");
      needData = true;
      mySerial.clear();
      fooCounter = 0;
      // show default image, play default sound
    }
    else {
      System.out.println(int(20-fooCounter)+" processing....");
      // show image/spot
      // play audio
      // (try not to block...)
      fooCounter++;
    }
  }
}

