
import processing.serial.*;

///////////////////////////////////////Import Arduino Libraries//////////////////
import cc.arduino.*;
import org.firmata.*;////Firmata is crucial for com between arduino and processing
//////////////////////////////////////Import Math Libraries/////////////////////
/////////////////////////You don't need all of them////////////////////////////
///////////////////////////////////IMPORT OpenCV Core LIBRARIES/////////////////////////////
//////////////////////////////////and some graphics and UI req./////////////////////////////
import gab.opencv.*;
import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.core.Point;
import org.opencv.core.Scalar;
import org.opencv.core.CvType;
import org.opencv.imgproc.Imgproc;
import processing.video.*;
import ddf.minim.*;
import ddf.minim.ugens.*;
import java.awt.Rectangle;
import processing.serial.*;  
import controlP5.*;
////////////////////////////////DECLARE VARIABLES//////////////////
//Arduino arduinoPort;//uncomment if arduino is connected
Capture video;
//Declare audio variables:
Minim       minim;
AudioOutput out;
Oscil       wave;
//Declare OpenCV
OpenCV opencv;
PImage src, colorFilteredImage, sat, Va1, Va2;
Range range1, range2, range3, range4, range5, range6;
ControlP5 scroll1, scroll2, scroll3, scroll4, scroll5, scroll6, cp5, cp6, cp7, cp8, cp9;
int max1, min1, max2, min2, max3, min3, max4, min4, max5, min5, max6, min6, dh, ball = 0, hand;
float kp = 0.007, ki = 0.036, kd = 0.003, error, previousError, integral, correction, pOut, iOut, dOut;
ArrayList<Contour> contours1, contours2;
int sliderValue=0, DH, counter = 0;
String val;
boolean firstContact = false, altTrackVideo = false;
int n=1; 
int i=1;
Arduino arduino;
//Necessary?
int[] values = { Arduino.LOW, Arduino.LOW, Arduino.LOW, Arduino.LOW, 
  Arduino.LOW, Arduino.LOW, Arduino.LOW, Arduino.LOW, Arduino.LOW, 
  Arduino.LOW, Arduino.LOW, Arduino.LOW, Arduino.LOW, Arduino.LOW };


///////////////////////////////////////ARDUINO VARIABLES//////////////////////////////////////////



////////////////////////////////SETUP//////////////////
void setup() {
  //connect arduino
  println(Arduino.list());

  // Modify this line, by changing the "0" to the index of the serial
  // port corresponding to your Arduino board (as it appears in the list
  // printed by the line above).
  arduino = new Arduino(this, Arduino.list()[0], 57600);

  // Alternatively, use the name of the serial port corresponding to your
  // Arduino (in double-quotes), as in the following line.
  //arduino = new Arduino(this, "/dev/tty.usbmodem621", 57600);

  // Set the Arduino digital pins as outputs.
  for (int i = 0; i <= 13; i++)
    arduino.pinMode(i, Arduino.OUTPUT);

  //String[] cameras = Capture.list();

  //Change video source
  //video = new Capture(this, 640, 480);//Access your webcam by default
  video = new Capture(this, 640, 480, "name=Microsoft LifeCam Rear,size=640x480,fps=30",30);

  minim = new Minim(this);

  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();

  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave = new Oscil( 440, 0.5f, Waves.SINE );
  // patch the Oscil to the output
  wave.patch( out );

  ////////////////////////////Iniate Serial Com with arduino and define pins as below/////////////////////
  //arduinoPort = new Arduino(this, "COM3", 57600);
  //arduinoPort.pinMode(11, Arduino.OUTPUT);    // Pin 11 conected a IN4
  video.start();
  opencv = new OpenCV(this, 640, 480);
  surface.setSize(2*opencv.width, 480+80);
  background(#005250);
  contours1 = new ArrayList<Contour>();
  contours2 = new ArrayList<Contour>();
  opencv.useColor(HSB);
  /////////////////UI Setup/////////////////////////////
  scroll1= new ControlP5(this);
  scroll2= new ControlP5(this);
  scroll3= new ControlP5(this);
  cp5=new ControlP5(this);
  cp5.addSlider("slidervalue").setPosition(900, 485).setRange(0, 255);
  cp6=new ControlP5(this);
  cp6.addSlider("Height").setPosition(900, 500).setRange(0, 450);
  cp7=new ControlP5(this);
  cp7.addSlider("KP").setPosition(900, 515).setRange(0, 3);
  cp8=new ControlP5(this);
  cp8.addSlider("KI").setPosition(900, 530).setRange(0, 1);
  cp9=new ControlP5(this);
  cp9.addSlider("KD").setPosition(900, 545).setRange(0, 1);
  range1= scroll1.addRange("Min H, Range H, Max H")
    .setBroadcast(false)   .setPosition(100/4, 485)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
  range2= scroll1.addRange("Min S, Range S, Max S")
    .setBroadcast(false)   .setPosition(100/4, 510)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
  range3= scroll1.addRange("Min V, Range V, Max V")
    .setBroadcast(false)   .setPosition(100/4, 535)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
  //second pair of sliders
  range4= scroll1.addRange("Control H")
    .setBroadcast(false)   .setPosition(2000/4, 485)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
  range5= scroll1.addRange("Control S")
    .setBroadcast(false)   .setPosition(2000/4, 510)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
  range6= scroll1.addRange("Control V")
    .setBroadcast(false)   .setPosition(2000/4, 535)
    .setSize(320, 20)       .setHandleSize(10)
    .setRange(0, 255)       .setRangeValues(50, 100)
    .setBroadcast(true);
}
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////DRAW MAIN FUNCTION///////////////////////////
///////////////////similar to void loop() in arduino/////////////////////////
void draw() {
  // Read last captured frame
  if (video.available()) {
    video.read();
  }
  // <2> Load the new frame of our movie in to OpenCV
  opencv.loadImage(video);

  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();

  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);

  // <4> Copy the Hue channel of our image into 
  //     the gray channel, which we process.
  opencv.setGray(opencv.getH().clone());

  // <5> Filter the image based on the HSV range set by our control event function 
  opencv.inRange(min1, max1);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  colorFilteredImage = opencv.getSnapshot();
  opencv.setGray(opencv.getS().clone());
  opencv.inRange(min2, max2);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  opencv.diff(colorFilteredImage);
  opencv.threshold(sliderValue);
  opencv.invert();
  sat = opencv.getSnapshot();
  opencv.setGray(opencv.getV().clone());
  opencv.inRange(min3, max3);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  opencv.diff(sat);
  opencv.threshold(sliderValue);
  opencv.invert();
  Va1 = opencv.getSnapshot();
  // <7> Find contours in our range image.
  //     Passing 'true' sorts them by descending area.
  contours1 = opencv.findContours(true, true);
  // <8> Display background images


  //redo for hand --------------
  opencv.useColor(HSB);

  // <4> Copy the Hue channel of our image into 
  //     the gray channel, which we process.
  opencv.setGray(opencv.getH().clone());

  // <5> Filter the image based on the HSV range set by our control event function 
  opencv.inRange(min4, max4);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  colorFilteredImage = opencv.getSnapshot();
  opencv.setGray(opencv.getS().clone());
  opencv.inRange(min5, max5);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  opencv.diff(colorFilteredImage);
  opencv.threshold(sliderValue);
  opencv.invert();
  sat = opencv.getSnapshot();
  opencv.setGray(opencv.getV().clone());
  opencv.inRange(min6, max6);
  opencv.blur(12);
  opencv.threshold(50);
  opencv.dilate();
  opencv.erode();
  opencv.diff(sat);
  opencv.threshold(sliderValue);
  opencv.invert();

  Va2 = opencv.getSnapshot();
  // <7> Find contours in our range image.
  //     Passing 'true' sorts them by descending area.
  contours2 = opencv.findContours(true, true);
  // <8> Display background images
  image(src, 0, 0);
  if (altTrackVideo) {
    image(Va2, src.width, 0);
  } else {
    image(Va1, src.width, 0);
  }
  // <9> Check to make sure we've found any contours
  if (contours1.size() > 0) {
    // <9> Get the first contour, which will be the largest one
    Contour biggestContour1 = contours1.get(0);

    // <10> Find the bounding box of the largest contour,
    //      and hence our object.
    Rectangle r = biggestContour1.getBoundingBox();

    // <11> Draw the bounding box of our object
    noFill(); 
    strokeWeight(2); 
    stroke(255, 0, 0);
    rect(r.x, r.y, r.width, r.height);

    // <12> Draw a dot in the middle of the bounding box, on the object.
    noStroke(); 
    fill(255, 0, 0);
    ellipse(r.x + r.width/2, r.y + r.height/2, 30, 30);
    ball = src.height - r.y;
    //output X,Y coordinates in pixels every 10 frames
    /*
    if(n==10){
     print("X=");
     println(r.x);
     print("Y=");
     println(r.y);
     print("Z=");
     println(kp);
     n=0;
     }
     n=n+1;
     */
    counter = 0;
  } else if (counter > 100) {
    ball = 0;

  }

  if (contours2.size() > 0) {
    // <9> Get the first contour, which will be the largest one
    Contour biggestContour2 = contours2.get(0);

    // <10> Find the bounding box of the largest contour,
    //      and hence our object.
    Rectangle r = biggestContour2.getBoundingBox();

    // <11> Draw the bounding box of our object
    noFill(); 
    strokeWeight(2); 
    stroke(0, 0, 255);
    rect(r.x, r.y, r.width, r.height);

    // <12> Draw a dot in the middle of the bounding box, on the object.
    noStroke(); 
    fill(0, 0, 255);
    ellipse(r.x + r.width/2, r.y + r.height/2, 30, 30);
    hand = src.height - r.y;
  }
  //////////////Arduno code////////////////////////// <- This is where the magic happens
  //ball = indicated in red. controlled on left
  //hand = indicated in blue. controlled on right
  out.close();
  //wave.setFrequency((ball) + 200);


  error = hand - ball;
  pOut = kp * error;
  integral += error; //fps
  if(integral > 1000){
    integral = 1000;
  }
   if(integral < -1000){
    integral = -1000;
  }
  iOut = ki * integral;
  dOut = kd * (error - previousError);
  correction = pOut + iOut + dOut;
  if (correction > 255) {
    correction = 255;
  } else if (correction < 0) {
    correction = 0;
  }

  arduino.analogWrite(8, (int)correction);
  counter++;
  println(correction);
  previousError = error;
} 
//////////////A very Simple UI////////////////////
////////////////SLIDER BARS//////////////////////
void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("Min H, Range H, Max H")) {
    min1= int(theControlEvent.getController().getArrayValue(0));
    max1= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = false;
  }
  if (theControlEvent.isFrom("Min S, Range S, Max S")) {
    min2= int(theControlEvent.getController().getArrayValue(0));
    max2= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = false;
  }
  if (theControlEvent.isFrom("Min V, Range V, Max V")) {
    min3= int(theControlEvent.getController().getArrayValue(0));
    max3= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = false;
  }
  if (theControlEvent.isFrom("Control H")) {
    min4= int(theControlEvent.getController().getArrayValue(0));
    max4= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = true;
  }
  if (theControlEvent.isFrom("Control S")) {
    min5= int(theControlEvent.getController().getArrayValue(0));
    max5= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = true;
  }
  if (theControlEvent.isFrom("Control V")) {
    min6= int(theControlEvent.getController().getArrayValue(0));
    max6= int(theControlEvent.getController().getArrayValue(1));
    altTrackVideo = true;
  }
  if (theControlEvent.isFrom("Height")) {
    dh= int(theControlEvent.getController().getValue());
  }
  if (theControlEvent.isFrom("KP")) {
    kp= theControlEvent.getController().getValue();
  }
  if (theControlEvent.isFrom("KI")) {
    ki= theControlEvent.getController().getValue();
  }
  if (theControlEvent.isFrom("KD")) {
    kd= theControlEvent.getController().getValue();
  }
}
