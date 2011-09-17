PImage effectImage;
PImage sourcePattern;
import ddf.minim.analysis.*;
import ddf.minim.*;
import hypermedia.net.*;


// Globals
int ledsPerStrip = 157;
int bytesPerLed = 3;
int bytesPerStrip = ledsPerStrip * bytesPerLed;
int numStripsPerPacket = 16;
int numStripsPerSystem = 128;
int bufSize = bytesPerStrip * numStripsPerPacket + 4 + 4;  // Strip data (471*16) + 8 byte UDP header)+ 4 bytes type + 4 bytes seq.
byte[] buf = new byte[bufSize];

String[]ipaddr = {"192.168.1.177",    // stripctrl0 remote IP address
                  "192.168.1.178",    // stripctrl1
                  "192.168.1.179",    // stripctrl2
                  "192.168.1.180",    // stripctrl3
                  "192.168.1.181",    // stripctrl4
                  "192.168.1.182",    // stripctrl5
                  "192.168.1.183",    // stripctrl6
                  "192.168.1.184"};   // stripctrl7
int destPort        = 6000;       // the destination port
int srcPort         = 6000;       // the source port
int pps             = 30;         // Packets per second
long seq;                         // tx packet sequence number
long timeStamp      = 10;         // Timestamp for effect length 60 s.
long elapsedSecs    = 0;
int effectIdx       = 0;
int numEffects      = 3;
int effectLength    = 20;         // time of each effect in seconds
int frameCnt        = pps;        // Counts down frames in a second
byte r = 0;
byte g = (byte)0xFF;
byte b = (byte)0xFF;

UDP udp;  // define the UDP object


// create global objects and variables
Minim minim;

AudioPlayer in;
BeatDetect beat;
FFT fft;
int[] fftHold = new int[32];
float[] fftSmooth = new float[32];

ArrayList Drops;


void setup() {
  
  // initialize Minim object
  minim = new Minim(this);

  // select audio source, comment for sample song or recording source
  //in = minim.getLineIn(Minim.STEREO, 1024);
  //in = minim.loadFile("Gosprom_-_12_-_San_Francisco.mp3",1024); // Creative Commons
  in = minim.loadFile("CeNestPasBon.mp3",1024); // Creative Commons
  //in = minim.loadFile("ChemicalBeats.mp3",1024); // Creative Commons
  //in = minim.loadFile("deadmau5.mp3",1024); // Creative Commons
  in.loop();

  beat = new BeatDetect(in.bufferSize(), in.sampleRate());  
  beat.setSensitivity(300);
  beat.detectMode(BeatDetect.FREQ_ENERGY);
 
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.window(FFT.HAMMING);
  fft.logAverages(120,4); // 32 bands
  
  udp = new UDP( this, srcPort );  // create a new datagram connection on port 6000
  //udp. log( true );            // <-- print out the connection activity
  print("UDP Buffer Size: ");
  println(UDP.BUFFER_SIZE);
  udp. listen( true );           // and wait for incoming message
  
  size(ledsPerStrip, numStripsPerSystem);  
  frameRate(pps);
 
   timeStamp      = effectLength;    // Timestamp for effect length
   elapsedSecs    = 0;
   effectIdx      = 0;
   frameCnt       = pps;        // Counts down frames in a second
   seq            = 1;          // seq # starts at 1
   
   for(int i= 0; i < bufSize; i++) { 
     buf[i] = (byte)0xFF;
   }  // set pattern in buf
 
  sourcePattern = loadImage("spiral1.png");
  
  Drops = new ArrayList();
}


void draw () {
  
  if (--frameCnt == 0) {
    frameCnt = pps;
    if(++elapsedSecs > timeStamp) {
      elapsedSecs =0;
      if(++effectIdx == numEffects) {
        effectIdx = 0;
      }
    } 
  }
  
  
  
  switch(effectIdx) {
    case 0:
      effect_spinImage();
      break;
    case 1:
      effect_drops();
      break;
    case 2:
    default:
      effect_spectrum();
      break;
  }
  
  sendImage();
    
}

void sendImage() {
  loadPixels();
  
  int ipidx = 0;     // index into array of IP addresses for strip controllers

  for(int lineidx = 0; lineidx < numStripsPerSystem; lineidx += numStripsPerPacket)
  {
    int pixelIdx = ledsPerStrip * lineidx;
  
    for(int i= 8; i < bytesPerStrip * numStripsPerPacket + 8 - 1; i += 3) {
      color curPixel = pixels[pixelIdx];
      buf[i] = (byte) blue(curPixel);    // Blue
      buf[i+1] = (byte) green(curPixel);  // Green
      buf[i+2] = (byte) red(curPixel);  // Red
    
      pixelIdx++;
    }  // set pattern in buf
     // Put a type 0 in the first long to signify this is a Strip Data packet
    buf[0] = 0;  
    buf[1] = 0;
    buf[2] = 0;
    buf[3] = 0;
  
    // put a sequence # in the next 4 bytes of buf (little endien)
    buf[4] = (byte)(seq & 0xFF);
    buf[5] = (byte)((seq & 0xFF00) >> 8);
    buf[6] = (byte)((seq & 0xFF0000) >> 16);
    buf[7] = (byte)((seq & 0xFF000000) >> 24);
    udp. send(buf, ipaddr[ipidx++], destPort );    // the message to send
  }
  seq++;  
}

// draw grid in lower half
void drawGrid() {
  stroke(127);
  strokeWeight(1);
  for (int i = 1; i < 16; i++) {
   line(i*20,160,i*20,319);
  }
  for (int i = 0; i < 8; i++) {
   line(0,i*20+160,319,i*20+160);
  } 
}



// --- EFFECT ---
// Raindrops
// Generates expanding droplets on isKick detection
//int dropWallSize = 30;
int dropWallSize = 35;
int dropHue = 0;
void effect_drops() {

  beat.detect(in.mix);
  
  background(0);

  if ( beat.isKick() ) {
    Drops.add(new drop1(int(random(19,299)),int(random(19,139)),dropHue));
    dropHue += 4;
    if (dropHue > 100) dropHue -= 100;
  }
  
  for (int i = Drops.size() - 1; i >= 0; i--) {
    drop1 drop = (drop1) Drops.get(i);
    drop.update();
    if (drop.done()) Drops.remove(i); 
  }
  
}

// Class for Raindrops effect
class drop1 {
  
  int xpos, ypos, dropcolor, dropSize;
  boolean finished;
  
  drop1 (int x, int y, int c) {
    xpos = x;
    ypos = y;
    dropcolor = c;
    finished = false;
  }
  
  void update() {
    if (!finished) {
      colorMode(HSB, 100);
      noFill();
      strokeWeight(dropWallSize); 
      stroke(dropcolor,100,100);
      ellipse(xpos,ypos,dropSize,dropSize);
      if (dropSize < 550) {
        dropSize += 15;
      } else {
        finished = true;
      }
      colorMode(RGB, 255);
    }
  }
  
  boolean done() {
    return finished;
  }
}


// --- EFFECT ---
// Spin image
// Rotates an image and bounces back on isKick
color ledColor;
int rotDegrees = 0;
void effect_spinImage() {

  beat.detect(in.mix);  
  
  int imageSize = 400;
  background(0);
  pushMatrix();
  translate(width/2,height/4);

  rotDegrees += 10;
  if (beat.isKick()) rotDegrees -= 36;
  if (rotDegrees > 359) rotDegrees -= 360;
  if (rotDegrees < 0) rotDegrees += 360;

  rotate(radians(rotDegrees));
  
  image(sourcePattern,-(imageSize/2),-(imageSize/2),imageSize,imageSize);
  popMatrix();
  
}

// --- EFFECT ---
// Spectrum
// Draws an FFT with peak hold
void effect_spectrum() {
 background(0);
  
 fft.forward(in.mix);
 
  noStroke();
    // draw the linear averages
  int w = int(width/fft.avgSize());
  int h;
  
  for(int i = 0; i < fft.avgSize(); i++)
  {
    fftSmooth[i] = 0.3 * fftSmooth[i] + 0.7 * fft.getAvg(i);
    
    //h = int(log(fftSmooth[i]*3)*30);
    h = int(log(fftSmooth[i]*3)*10);
    if (fftHold[i] < h) {
      fftHold[i] = h;
    }
    
    rectMode(CORNERS);
    //This gives the bar color on the basis of height
    fill(255*h/80,0,255-255*h/80);
    //This is the amplitude bar
    // North side
    rect(i*w*2, 0, i*w*2 + w*2, h);
    // South side
    rect(i*w*2, height - h, i*w*2 + w*2, height);
    // This is the color green for the peak bar
    fill(0,255,0);
    // This is the peak bar
    // North side
    rect(i*w*2, fftHold[i] - 1, i*w*2 + w*2, fftHold[i]+2);
    // South side
    rect(i*w*2, height-fftHold[i] -2, i*w*2 + w*2, height - fftHold[i]+1);


    //fftHold[i] = fftHold[i] - 4;
    fftHold[i] = fftHold[i] - 2;
    if (fftHold[i] < 0) fftHold[i] = 0;
  }
  
}




void stop()
{
  // always close Minim audio classes when you are finished with them
  in.close();
  //song.close();
  // always stop Minim before exiting
  minim.stop();
  // this closes the sketch
  super.stop();
}

