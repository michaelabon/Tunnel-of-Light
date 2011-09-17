import hypermedia.net.*;
import codeanticode.gsvideo.*;

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

UDP udp;  // define the UDP object
	
GSMovie myMovie;

void setup() {
  
  size(ledsPerStrip, numStripsPerSystem);
  
  udp = new UDP( this, srcPort );  // create a new datagram connection on port 6000
 
  print("UDP Buffer Size: ");
  println(UDP.BUFFER_SIZE);
  
  frameRate(pps);
 
  seq = 1;                      // seq # starts at 1
  
  for(int i= 0; i < bufSize; i++) { 
    buf[i] = (byte)0xFF;
  }  // set pattern in buf
  
  //myMovie = new GSMovie(this, "Isotropic labs animation#1.mov"); //451x380
  //myMovie = new GSMovie(this, "tubular fullness_1.mov");
  //myMovie = new GSMovie(this, "tubular fullness_2.mov");
  myMovie = new GSMovie(this, "tubular fullness_3.mov");
  //myMovie = new GSMovie(this, "tubular fullness_4.mov");
  //myMovie = new GSMovie(this, "tubular fullness.mov");
  //myMovie = new GSMovie(this, "blip_automatic_Camera2_2.mov");
  myMovie.loop();
}

void draw() {

  image(myMovie, 0, 0, ledsPerStrip, numStripsPerSystem);
  
  sendImage();   // Send out the current frame
}

// Called every time a new frame is available to read
void movieEvent(GSMovie m) {
  m.read();
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

