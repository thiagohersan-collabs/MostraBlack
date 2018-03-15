/* 
 * Sketch for reading sensor data and passing it off to Processing.
 * Simplified : always pass off data when sensors are above threshhold.
 *              It's up to processing to clear its buffer to get the right
 *              data.
 *
 *              Also... keep track of sensor release. Important for interaction.
 */

#define DEBUG 0

#define NUM_OF_SENSORS 10
#define NUM_OF_READINGS 20

#define TOUCH_THRESH_UP 250
#define TOUCH_THRESH_DOWN 200
#define  DIST_THRESH 300

int     sensors [NUM_OF_SENSORS] = {
  A0,A1,A2,A3,A4,A5,A6,A7,A8,A9};//,A10,A11};
boolean isTouch [NUM_OF_SENSORS] = {
  true,true,true,true,true,true,true,true,true,true};//,true,true};
//int sensors [NUM_OF_SENSORS] = {A0,A1,A2,A3,A4,A5};
unsigned long baseVals[NUM_OF_SENSORS];
unsigned long baseValSums[NUM_OF_SENSORS];

// some counters
int i,j,k, cnt;

// some value holders
unsigned int sVal;
unsigned int maxv[NUM_OF_SENSORS];
unsigned int outv[NUM_OF_SENSORS];
unsigned int oldv[NUM_OF_SENSORS];



// which sensor is active, -1 if none
int isPlaying;


// setup : initialize array of baseline values
//         initialize the isPlaying variable
//         open serial port and wait for communication
void setup() {

  // begin serial communication
  Serial.begin(19200);

  // clear base array
  for(i=0; i<NUM_OF_SENSORS; i++) {
    baseVals[i] = 0;
    maxv[i] = 0;
    outv[i] = 0;
  }


  // read some values into baseline array
  /*
  for(k=0; k<4; k++) {
   for(j=0; j<NUM_OF_READINGS; j++) {
   for(i=0; i<NUM_OF_SENSORS; i++) {
   unsigned int t = analogRead(sensors[i]);
   if(t > baseVals[i]) {
   baseVals[i] = t;
   }
   delay(10);
   }
   }
   // add to average
   for(i=0; i<NUM_OF_SENSORS; i++) {
   baseValSums[i] += baseVals[i];
   baseVals[i] = 0;
   }    
   }
   */

  // take average of the readings
  /*
  for(i=0; i<NUM_OF_SENSORS; i++) {
   baseVals[i] = baseValSums[i]/4 - 30;
   }
   */

  // default value (none)
  isPlaying = -1;

  // counter...
  cnt = 0;


  if(DEBUG) {
    for(i=0; i<NUM_OF_SENSORS; i++) {
      Serial.print(i);
      Serial.print(": ");
      Serial.println(baseVals[i]);   
    }
    delay(1000);
  }

  // this is blocking: keeps sending start signal
  // until the other side hears it and sends the first request

  if(!DEBUG) {
    while(Serial.available() <= 0) {
      Serial.print('A', BYTE);
      Serial.print('\n',BYTE);
      delay(500);
    }
    // to ensure that we clear buf on other side after sending request
    delay(500);
    Serial.flush();
  }

}

// loop : read values from sensors
//        if one is above threshold, send data to serial.
//        only send more data once last activated sensor is released
//
void loop() {
  // check current sensor values only if it's not playing anything
  for(i=0; (i<NUM_OF_SENSORS)&&(isPlaying == -1); i++) {
    // if above the threshold for this sensor
    //   check if it's a touch sensor, or a distance sensor...
    if(isTouch[i] && (outv[i] > TOUCH_THRESH_UP)) {
      // send the number of the sensor that fired
      if(!DEBUG) {
        Serial.print(i, BYTE);
        Serial.print('\n', BYTE);  
      }
      if(DEBUG)
        Serial.println(i);
      // keep track of which one fired
      isPlaying = i;
      // break; (actually kind of redundant since previous line should break;)
      i = NUM_OF_SENSORS;
    }
  }

  // if there was a fired sensor, check to see if it has been released
  if(isPlaying != -1) {
    // if sensor was "released"
    if(isTouch[isPlaying] && (outv[isPlaying] < TOUCH_THRESH_DOWN)) {
      // this will enable a stop signal to be sent
      isPlaying = -1;
    }
  }

  // read sensors...
  for(i=0; i<NUM_OF_SENSORS; i++) {
    sVal = analogRead(i);
    delay(2);

    // if distance sensor, always update
    if(!isTouch[i]) {
      maxv[i] = sVal;
    }
    // for touch, only when val > maxVal
    else if(sVal > maxv[i]) {
      maxv[i] = sVal; 
    }

  }

  // update the delayed filtered values...
  cnt++;
  for(i=0; i<NUM_OF_SENSORS; i++) {
    // for distance sensor, always update
    if(!isTouch[i]) {
      outv[i] = maxv[i];
      maxv[i] = 0;
    }
    // if touch, only after NUM_OF_READINGS
    // if a touch sensor, only update after NUM_OF_READINGS
    else if(cnt >= NUM_OF_READINGS) {
      // low pass filter
      //    if values are similar, let it pass....
      if(abs(oldv[i]-maxv[i]) < 50) {
        outv[i] = maxv[i];
      }
      // else, values are diferent, block...
      else{
        outv[i] = outv[i];
      }
      // keep oldv for next iteration
      oldv[i] = maxv[i];
      // clear maxv
      maxv[i] = 0;
    }
  }

  // update counter
  if(cnt >= NUM_OF_READINGS) {
    cnt = 0;
  }

}

// The code on the other side has to:
//   - read from serial, and check if it gets an 'A'
//   - clear its buffer
//   - request data by sending anything to here
//   - listen for any sensor number
//   - do stuff if it gets a number
//   - request data again by sending anything to here
















