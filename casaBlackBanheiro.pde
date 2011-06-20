/*
 * Sketch for reading sensor data, fading lights and playing an audio.
 *
 * Simplified serial communication : Arduino sends data everytime a sensor is fired.
 *                                   Just have to clear buf before going to a state
 *                                   that reads it, and then read the very last value ...
 *
 */

/*
 *  Ordem:
 *    [0] : Alexandre
 *    [1] : Caco
 *    [2] : Esmeralda
 *    [3] : Facundo
 *    [4] : Mauricio
 *    [5] : Paula
 *    [6] : Val
 *
 */

import processing.serial.*;
import processing.opengl.*;
import ddf.minim.*;

// number of squares on the wall...
static final int NUM_SQS = 12;

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

// for light square position and dimension
intTuple[] sqPos  = new intTuple[NUM_SQS];
intTuple[] sqDim  = new intTuple[NUM_SQS];
intOct[]   quadPos = new intOct[NUM_SQS];

int txtIndex = -1;

// text to be displayed with each sound
String[] theTxt = new String[NUM_SQS];

// Images of squares to be updated
PImage[]    mySquares = new PImage[NUM_SQS];
PGraphics   myQuads = null;

// Serial connection
Serial mySerial = null;
// font
PFont font;
// sound file streams
Minim minim;
AudioPlayer[] myAudio = new AudioPlayer[NUM_SQS];

void setup() {
  size(1024, 768, OPENGL);
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
  reader = createReader("casaBlackSquarePositions.txt");    

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
    //println(int(pieces[0])+" "+int(pieces[1]));

    intTuple itSP = new intTuple(int(pieces[0]), int(pieces[1]));
    intTuple itSD = new intTuple(int(pieces[2]), int(pieces[3]));

    sqPos[i] = itSP;
    sqDim[i] = itSD;
  }

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
    //println(int(pieces[0])+" "+int(pieces[1]));

    quadPos[i] = new intOct(int(pieces[0]), int(pieces[1]), int(pieces[2]), int(pieces[3]), int(pieces[4]), int(pieces[5]), int(pieces[6]), int(pieces[7]));
  }




  // for the text....
  txtIndex = 9;

  String s = new String("Bom, para mim é muito mais um sentimento do que um lugar, ou um lugar físico mesmo. Você pode se sentir no seu lar fora da sua casa , você pode ter este sentimento na casa da sua mãe , na casa de um amigo, onde você chega e quer tirar o sapato, e fica a vontade, deita na cama, mesmo ela não sendo sua fisicamente.  Então, para mim, o sentimento de lar não é físico.\n\nE também por outro lado, é um lugar onde você quer chegar no final do dia, um  lugar onde você quer passar momentos exclusivos e privados, um lugar onde você pode fazer de tudo, e este é o sentimento mais completo de lar.");
  theTxt[0] = s;  

  s = new String("Bom, a gente é quem transforma uma casa num  lar. não  é ?\n\nUma casa é um espaço físico qualquer, e a gente preenche este espaço físico aos poucos, inclusive, né ? com objetos que nos tragam conforto, com objetos que nos remetam a lembranças.\n\nO lar tem que ser essencialmente um lugar de conforto. Um lugar que te traga conforto, um lugar de descanso não só físico como mental e espiritual,  e um lugar de renovação também, um lugar de limpeza, de fortificação  e de renovação. Então, para isso a gente preenche a nossa casa com coisas,  com objetos que nos propiciem este tipo de sensação, com pessoas que nos propiciem este tipo de sensação, com bichos de estimação que nos propiciem este tipo de sensação . Então, acho que em última análise, o que transforma uma casa em um lar somos nós, projetando  nessa casa,  ocupando essa casa com objetos, pessoas, seres, lembranças que nos tragam conforto e que nos religuem com a nossa essência, para que o lar seja este lugar especial e único onde você tem o mais profundo descanso e encontro consigo próprio, para que você possa se renovar e sair do seu lar para enfrentar oque tiver que enfrentar.");
  theTxt[1] = s;

  s = new String("O que faz de uma casa um lar, na minha opinião, primeiro vem o casamento, com amor , no meu caso que fui casada por quarenta anos , aí vem os filhos desejados, então este lar fica mais perfeito, porque estes filhos vêm, ‘é’ cuidado com muito carinho de pai e mãe , começam a crescer, começam a falar, começam a caminhar, a mãe manda pra escola, a mãe cuida das comidinhas do dia-a-dia com o maior carinho.\n\nEu, para mim, um lar é tudo o que eu quero, com meus filhos ao redor de mim, hoje estão casados, tenho oito netos, meu neto mais velho tem dezoito, o mais novo tem nove, e eu acho que a minha vida é...\n\nHoje eu sou viúva, espero um dia encontrar um casamento de novo. Para mim, o casamento é maravilhoso, e meu lar então para mim, é só isso mesmo, amor, muito amor , harmonia, cada vez que o marido chega, que os filhos chegam, abraços, te amo.\n\nPara mim, o lar é este, e do dia-a-dia que eu trabalho contente, feliz com meus patrões com meus amigos que ‘é’ vocês aqui, nossa, amo vocês.\n\nEntão, tá certo, no mais,  não tem muito mais não, além de muito amor, acho que não tem mais nada num lar a não ser isso, é isso ai, perfeito, meu lar eu acho perfeito.");
  theTxt[2] = s;

  s = new String("Então, o que transforma para mim uma casa num lar é quando você consegue decodificar dentro de um espaço, de uma linha arquitetônica, ou mesmo de um design de interior, você consegue interpretar a personalidade da pessoa que ocupa aquele espaço.\n\nPara mim, não existe certo ou errado quando você fala de arquitetura, ou mesmo de design de interior, ou mesmo de design; Existe sim, uma projeção da personalidade da pessoa que ocupa aquele espaço, nas suas paredes, no seu mobiliário, na sua arquitetura.\n\nQuando você consegue entrar dentro de um determinado ambiente e ler a pessoa que ocupa aquele espaço, eu acho que sim , você esta entrando no domínio de um lar e não numa casa qualquer. A casa não tem personalidade, o lar, ele espelha exatamente a personalidade do habitante dele, ele é uma cristalização, uma explosão da personalidade da pessoa que frequenta aquele espaço, em objetos, em linhas , em arquitetura e em design.");
  theTxt[3] = s;

  s = new String("ALMA –O que faz de uma casa um lar é ela ter ou não alma, ela ter gente morando dentro dela, ela ter vida, ela ser um ser vivo, ter cachorro dentro de casa também é uma coisa que faz de uma casa um lar.");
  theTxt[4] = s;

  s = new String("Bom, o que faz a casa da gente virar um lar eu acho que é decoração, acho que a decoração é muito importante, os objetos que você vai escolhendo pra aquela casa, do jeitinho como você vai fazendo a sua casa ficar, e acho que é a energia, a sua energia, a energia das pessoas que frequentam sua casa,  acho que é  um conjunto de coisas , acho que muito a decoração, muito o jeito que você  dá  pra sua casa, as cores, os objetos e a tua energia também.");
  theTxt[5] = s;

  s = new String("Hello... Para mim o que faz da casa um lar, além do aconchego, uma boa adega, um lugar predileto, um bom tapete para você se jogar no chão, uma tv grande para você assistir um filme, ai gente, hello, tantas coisas....");
  theTxt[6] = s;


  for (int i=7; i<NUM_SQS; i++) {
    s = new String(i+": ");
    for (int j=0; j<i; j++) {
      s = s.concat(String.valueOf(i));
    }
    theTxt[i] = s;
  }


  myQuads = createGraphics(width, height, P2D);
  hint(DISABLE_OPENGL_ERROR_REPORT);

  myQuads.beginDraw();
  myQuads.background(0, 0, 0, 255);
  myQuads.fill(#99182c);
  //myQuads.fill(255,0,0);
  for (int i=0; i<NUM_SQS; i++) {
    myQuads.quad(quadPos[i].getX(0), quadPos[i].getY(0), quadPos[i].getX(1), quadPos[i].getY(1), quadPos[i].getX(2), quadPos[i].getY(2), quadPos[i].getX(3), quadPos[i].getY(3));
  }
  myQuads.endDraw();

  // draw some white squares
  for (int i=0; i<NUM_SQS; i++) {
    PImage t = createImage(sqDim[i].getX(), sqDim[i].getY(), ARGB);
    for (int j=0; j<t.width; j++)
      for (int k=0; k<t.height; k++)
        t.set(j, k, color(255, 255, 255, 255));
    mySquares[i] = t;
    image(t, sqPos[i].getX(), sqPos[i].getY());

    image(myQuads, 0, 0);


    // audio streams
    myAudio[i] = minim.loadFile("file"+i+".aif");
  }

  // setup serial port
  //mySerial = new Serial(this, (String)Serial.list()[0], 9600);

  // setup font
  String[] fontList = PFont.list();
  //println(fontList);
  // futura 228 - 231
  font = createFont(fontList[228], FONTSIZE, true);
  textFont(font, FONTSIZE);
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
    if ((mySerial != null) && (mySerial.available() > 0)) {
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
    if ((mySerial != null)&&(mySerial.available() > 0)) {
      int myRead = mySerial.last();
      // read number into a variable
      // READ IT HERE! and check if it's a number!!
      if ((myRead > -1) && (myRead < NUM_SQS)) {
        // check if it got the text square number, do nothing
        if (myRead == txtIndex) {
          // redundant
          System.out.println("Got the text index from arduino... hmmm....");
          myState = STATE_LISTEN;
        }
        // not the text square index, do stuff
        else {
          playingNum = myRead;
          System.out.println("Got Go From: "+myRead);
          // setup audio player
          // paranoid. this should already be at 0
          myAudio[playingNum].rewind();
          // play what you just got
          myState = STATE_FADE;
        }
      }
      // number < 0 OR number > NUM_SQS
      else {
        myState = STATE_LISTEN;
        System.out.println("Read a number out of bounds...  "+myState+"  . Problem in serial com (??)");
      }
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
        image(t, sqPos[i].getX(), sqPos[i].getY());
      }

      myQuads.beginDraw();
      myQuads.background(0, 0, 0, 255);
      myQuads.fill(#99182c);
      //myQuads.fill(255,0,0);
      for (int i=0; i<NUM_SQS; i++) {
        // alpha!!!
        myQuads.fill(#99182c, (i==playingNum)?255:abs(fadeLevel));
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
        // show text...
        fill(255, 255, 255);
        text(theTxt[playingNum], sqPos[txtIndex].getX(), sqPos[txtIndex].getY(), 
        sqDim[txtIndex].getX(), sqDim[txtIndex].getY());
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
        rect(sqPos[txtIndex].getX(), sqPos[txtIndex].getY(), 
        sqDim[txtIndex].getX(), sqDim[txtIndex].getY());
        // for smoothing the fade back
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

