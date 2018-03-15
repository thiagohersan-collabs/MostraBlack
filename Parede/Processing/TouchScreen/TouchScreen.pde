import processing.opengl.*;

import oscP5.*;
import netP5.*;

import java.io.*;
import java.net.*;


//////////////////
static final int SMALLFONT  = 20;
static final int MEDIUMFONT = 24;
static final int LARGEFONT  = 32;

// text box dimension
static final int   NUMLINES = 4;
static final float BOXWIDTH = 0.8;  // percent of width

float boxX, boxW, textY;

PFont myFontL, myFontM, myFontS;
floatTuple adS, adM, adL; // tuples for ascent and descent info

///////////////////

static final int OSCPORT = 7777;
// network mask
static final String IPCODE = "NEWIP::";
// address for the phone!
static final String REMOTEADDR = "192.168.1.199";

NetAddress remoteAddress;

/////////////////////////
String theMessage = null;
int messageCnt;

///////////
PImage grLogo;

//////
static final String OQF = new String("O Que Faz De Uma Casa Um Lar?");

void setup() {
  size(1440, 900, OPENGL);
  println("HP Starting");

  hint(ENABLE_NATIVE_FONTS);

  remoteAddress = new NetAddress(REMOTEADDR, OSCPORT);

  // the message to be displayed
  theMessage = new String("");
  messageCnt = 140;

  // some constant stuff
  boxX = (1-BOXWIDTH)/2*width;
  boxW = BOXWIDTH*width;
  textY = height/4;

  String[] fontList = PFont.list();
  //println(fontList);
  // futura = 228 - 231
  myFontL = createFont(fontList[228], LARGEFONT, true);
  myFontM = createFont(fontList[228], MEDIUMFONT, true);
  myFontS = createFont(fontList[228], SMALLFONT, true);

  textFont(myFontS, SMALLFONT);
  textSize(SMALLFONT);
  adS = new floatTuple(textAscent(), textDescent());

  textFont(myFontM, MEDIUMFONT);
  textSize(MEDIUMFONT);
  adM = new floatTuple(textAscent(), textDescent());

  textFont(myFontL, LARGEFONT);
  textSize(LARGEFONT);
  adL = new floatTuple(textAscent(), textDescent());

  // load image
  grLogo = loadImage("estudio-gutorequena.png");
  //smooth();

  println("HP Ready");
}

// draw a text input box and a send button
void draw() {
  background(0);

  // draw logo
  image(grLogo, width-205, height-205, 200, 200);

  // first line of text
  textAlign(CENTER, BASELINE);
  textFont(myFontL, LARGEFONT);
  fill(255);
  text(OQF.toUpperCase(), 0, textY, width-1, adL.getSum());

  // second line of text
  textAlign(CENTER, BASELINE);
  textFont(myFontM, MEDIUMFONT);
  fill(255);
  //text("Escreva a sua resposta e aperte enter", 0, textY+adL.getSum(), width-1, adM.getSum());

  // text box
  stroke(128);
  fill(128);
  rect(boxX, textY+adL.getSum()*2, boxW, adM.getSum()*NUMLINES);

  stroke(128);
  fill(255);
  rect(boxX-1, textY+adL.getSum()*2-1, boxW, adM.getSum()*NUMLINES);

  // the message
  textAlign(LEFT, TOP);
  textFont(myFontS, SMALLFONT);
  fill(0);
  text(theMessage.toUpperCase(), boxX+1, textY+adL.getSum()*2+1, boxW-2, (adS.getSum()+8)*NUMLINES-1);

  // counter
  textAlign(LEFT, TOP);
  textFont(myFontS, SMALLFONT);
  fill(255);
  text(String.valueOf(messageCnt), boxW, textY+adL.getSum()*2+adS.getSum()*(NUMLINES+1));
}

void keyReleased() {
  // only deal with non-coded keys
  //   things that can be displayed
  if (key != CODED) {
    // on enter, send message and clear box
    if ((key == ENTER) || (key == RETURN)) {
      OscMessage myMsg = null;

      if (theMessage.startsWith(IPCODE)) {
        theMessage = theMessage.replaceAll(IPCODE, "");
        myMsg = new OscMessage("/ip");
      }
      else {
        // send osc message here
        myMsg = new OscMessage("/hp");
      }
      println("HP sending: "+theMessage);
      myMsg.add(theMessage); // add string to msg

      // no need to have an osc server, 
      // if I'm only sending messages... send with flush
      OscP5.flush(myMsg, remoteAddress);

      theMessage = new String("");
      messageCnt = 140;
    }
    // on backspace, clear last char
    else if (key == BACKSPACE) {
      if (theMessage.length() > 0) {
        theMessage = theMessage.substring(0, theMessage.length()-1);
        messageCnt++;
      }
    }
    // on delete, clear string
    else if (key == DELETE) {
      theMessage = new String("");
      messageCnt = 140;
    }
    // on key, add key to string
    else {
      if (theMessage.length() < 140) {
        theMessage = theMessage.toString()+(String.valueOf(key));
        messageCnt--;
      }
    }
  }
}

///////////////////////////
// helper class for keeping 2 floats together
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

