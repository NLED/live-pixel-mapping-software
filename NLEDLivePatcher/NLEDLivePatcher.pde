/* 
MIT License

Copyright (c) 2016 Northern Lights Electronic Design, LLC
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 
 Original Author: Jeffrey Nygaard
 Company: Northern Lights Electronic Design, LLC
 Contact: JNygaard@NLEDShop.com
 Date Updated: October 9, 2016 
 Software Version:  1b
 Webpage: www.NLEDShop.com/nledlivepatcher
 Written in Processing v3.2.1  - www.Processing.org
 
 //============================================================================================================
 
 - Allows odd-shaped, dynamically patched(mapped) LED matrices to be controlled from third-party software apps without patch support.
 - Supports RGB, RGBW, and single color LED matrices.
 - Supports NLED serial protocol and gLEDiator serial protocol(flag in configuration files)
 (gLEDiator serial protocol adds a single byte with a value of 1 to the end of the packet to indicate a start)
 - Customizable using Processing 3
 
 Intro:
 Wanted a simple way to apply patch files to third-party matrix software data streams that operate over serial ports. This 
 app is designed to be used with com0com or similar virtual serial port drivers. The transmission software(such as gLEDiator)
 transmits the square/rectangular matrix data over a virtual serial port into the Live Patcher app. The app reads a configuration
 file and loads the appropriate patch file. The patch file tells the app how to re-organize the received data streams to work with
 odd shaped LED matrices. Once re-organized the data can be sent out any serial port, commonly a FTDI adapter connected to a NLED 
 Pixel Controller(several models). But the re-organized data could also be sent to a Ardunio or customized controller for conversion
 to the pixel protocol.
 
 Configurations:
 See ReadMe for details on the configuration files
 
 Max Output FPS / Throttling:
   Controllers can only receive and handle data up to a certain frames/packets per second. Limitations depend on controller specs and/or output pixel
   chipset. Experimenting may be required to find the maximum frame rate for your project. Try to set the config MAXFPS to 0 to start, and if the receiving
   LED matrix does not function or flickers/glitches/artifacts you may need to enable output throttling. Start high and try lower values until it works.
 
 Usage:  Read Setup-Instructions.txt in the folder for full information on software usage
 - Create a patch file using NLED Matrix Patcher.
 - Make a Live Patcher configuration file for the matrix, set the width, height, patch file name, etc.
 - Setup your transmission software(gLEDiator) for same size matrix.
 - In software, select the transmission serial port and set the baud rates to match what you set in the configuration file.
 - Launch the Live Patcher app, if enabled the preview will display the patch file graphically.
 - The circle in the upper left corner indicates if things are running, if they are not recheck all your settings and configurations.
 
 
 Future Upgrades:
 - Add TCP/UDP usage, with cross overs(Serial to TCP, TCP to Serial)
 - Add ArtNet compatibility
 - Add data to preview area to make it an actual preview
 - GUI software settings
 - Color Ordering - GRB, BRG, etc
 
 Revisions 1a to 1b:
   - Added MAXFPS in config
   - Added max output FPS throttling code
   - Cleaned up the code
 */

import processing.serial.*;

//objects
Serial InputPort;  
Serial OutputPort;

//Constants
final int cPrevOffsetX = 10;
final int cPrevOffsetY = 70;
final int cGridSize = 10;

//Arrays
int[] PatchCoordX = new int[1];
int[] PatchCoordY = new int[1];
byte[] TransmissionArray = new byte[1];
byte[] StorageArray = new byte[1];

//Patch Variables
int PatchedChannels = 0;
int TotalChannels = 0;
int PixelAmount = 0;
int TotalPixels = 0;

//Software Variables
int OutputPortNumber = 0; //ID number in serial.list()....
int InputPortNumber = 0; //ID number in serial.list()....

int HoldMiliSec = 0;
int tempTime = 0;

int calcOffset = 0;
boolean DataFramed = false;
boolean ThrottledTransmission = false;

int resetVal = 0;
int zz = 0;

String SelectedFile = "/config/config-1.txt"; //the file path in config.ini is what points to the user config file in /config

//Config File Variables - in order
String patchFilePath = "";
String OutputPortName = "";
String InputPortName = "";
int InputBaudRate = 19200;
int OutputBaudRate = 19200;
boolean EnablePreview = false; //Toggle Preview display
boolean AutoSizeEnable = false; //Enables automatic calulation of matrix size, rather than user inputed Wdith,Height
boolean GlediatorProtocol = false;
boolean AuroraLiveMode = false;
int MatrixWidth = 0;
int MatrixHeight = 0;
int OrientationVar = 0;
int MaxOutputFPS = 0;
//end config file variables

//========================================================

void setup() 
{
  size(400, 400);

  PImage titlebaricon = loadImage("favicon.gif");
  surface.setIcon(titlebaricon);
  surface.setTitle("NLED Live Matrix Patcher - v.1a - Northern Lights Electronic Design, LLC");
  surface.setResizable(true);

  String[] lines = loadStrings("config.txt"); //divides the lines  
  SelectedFile = split(lines[1], '\t')[0]; //This surprisingly works to load the second line from "config.txt"

  LoadConfigFile(); //load file with SelectedFile and open serial ports

 if(AuroraLiveMode == true) //open Live Mode Connection if using Aurora firmware
  {
  try {
  OutputPort.write("N"); 
  OutputPort.write("L");  
  OutputPort.write("E");   
  OutputPort.write("D");  
  OutputPort.write("1");   
  OutputPort.write("1");      
  delay(5);
  OutputPort.write("n"); 
  OutputPort.write("l");  
  OutputPort.write("e");   
  OutputPort.write("d");  
  OutputPort.write("9");   
  OutputPort.write("9");
  delay(5);  
  OutputPort.write(60);  //Live Mode Command
  OutputPort.write(1);   //Enable Live Mode
  OutputPort.write(0); 
  println("Aurora Live Control PatchedChannels: "+PatchedChannels);
  OutputPort.write((PatchedChannels >> 8) & 0xFF); //MSB
  OutputPort.write(PatchedChannels & 0xFF);     //LSB
   delay(5);  
  }
  catch(Exception e) { println("No COM Port open to send NLED Aurora Live Control CMD to"); }
 }

  //If the output framerate is throttled it does a draw() loop, otherwise redraws only when required
  if(MaxOutputFPS == 0) noLoop(); //only draws once....
  else frameRate(MaxOutputFPS);

} //end setup()

//================================================================================================================

void draw() 
{
  //used as a timer to throttle the output frame rate. If the software is transmitting data faster than can be sent to the controller and utilized, this allows
     // a lower framerate to be used for the output device. Setting the OUTFPS to 0, will send data out soon as its recieved. If the value is larger than 0, it throttles
 if(ThrottledTransmission == true) 
 {
 ThrottledTransmission = false;  //clear flag
 thread("threadOutput"); //Thread output for faster handling
 if (EnablePreview == true)  println("sent");
 }
 //End Throttling
 
  //display and update preview as it comes in
  background(200, 200, 200);
  fill(0);
  noStroke();
  text("Input Port "+InputPortName+" at "+InputBaudRate+" baud.\nOutput Port "+OutputPortName+" at "+OutputBaudRate+" baud.", 35, 15);
  text("Input Channels: "+TotalChannels+"     Patched Channels: "+PatchedChannels, 5, 45);
  text("Patch File: "+patchFilePath, 5, 60);

  //draws status indicating circle
  resetVal++;
  fill(0, 255, 0);
  if (resetVal < 5)
  {
    fill(255, 0, 0);
  } 
  else if (resetVal == 20)
  {
    resetVal = 0;
  }
  ellipse(15, 15, 20, 20);
  //end status circle

  if (EnablePreview == true)
  {
    for (int i = 0; i != PixelAmount; i++)
    {
      strokeWeight(1);
      stroke(255);
      fill(0);
      rect(cPrevOffsetX+(cGridSize*PatchCoordX[i]), cPrevOffsetY+(cGridSize*PatchCoordY[i]), cGridSize, cGridSize);
    }
  } 
  else 
  {
    fill(0);
    text("PREVIEW DISABLED\nNO INDICATOR USAGE\nPress Spacebar to toggle", 100, 100);
  }
 //end draw stuff
} //end draw()

//================================================================================================================

void serialEvent(Serial RXPort) 
{
  tempTime = (millis() - HoldMiliSec); //keeps track of time since last packet in milliseconds
  HoldMiliSec= millis();  

  //Should ensure data is framed by time, once its "framed" it sets the buffer() function
  //  When the software starts it doesn't know where the beginning of the data is, so this frames it using time
  if (DataFramed == false)
  {
    println("NOT FRAMED: "+tempTime+"   "+InputPort.readChar());    
    if (tempTime > 30) //if FPS higher than 30, may not frame data correctly
    {
      resetVal++;
      if (resetVal > 2) //reduced from 10 to 2
      {
        resetVal = 0;
        DataFramed = true;

        if (GlediatorProtocol == true) InputPort.buffer(TotalChannels+1); //now set the port to buffer
        else InputPort.buffer(TotalChannels);

        println("DataFramed Flag Set");
      }
    }
    InputPort.clear(); //otherwise dump data, its not framed yet
    return;
  } //end framing if()
//========== END PACKET FRAMING ======================

  if (EnablePreview == true) println("Received Packet: "+tempTime+"   "+InputPort.available());
  
  StorageArray = InputPort.readBytes(StorageArray.length); //read from Input, .length already initialized
  
  
// Some Debug stuff
//  for(int z = 0; z != PatchedChannels; z++)    TransmissionArray[z] = StorageArray[z];  //Straight fill, no patch applied

//StorageArray[PatchedChannels-1] = 0;
//StorageArray[PatchedChannels-2] = 0;
//StorageArray[PatchedChannels-3] = 0;

  //fill transmission array with patched data
  zz = 0; //counter  
  for (int z = 0; z != PixelAmount; z++) 
  {
    //  println(MatrixHeight+"  :  "+(PatchCoordX[z]+1)+"  :  "+(PatchCoordY[z]+1));

    //Should be able to adjust the orientation in transmission software, just select 0 or 1 for horiz or vertical orientation
    if (OrientationVar == 0) calcOffset = (((PatchCoordX[z]+1) * MatrixHeight)-(PatchCoordY[z]+1)) * 3;  //0 - works with "VL-BL"   
    else calcOffset = (((PatchCoordY[z]+1) * MatrixWidth)-(PatchCoordX[z]+1)) * 3;  //1 - vertical
    //calcOffset = (((MatrixHeight-(PatchCoordX[z]+1)) * MatrixHeight)+(PatchCoordY[z]+1)) * 3;  //2 - Another Horiz Method  

    TransmissionArray[zz] = StorageArray[calcOffset]; //Fill TransmissionArray with patched data bytes
    TransmissionArray[zz+1] = StorageArray[calcOffset+1];
    TransmissionArray[zz+2] = StorageArray[calcOffset+2];
    zz+=3;
  }

  if(MaxOutputFPS == 0) thread("threadOutput"); //Thread output for faster handling
  else ThrottledTransmission = true; //or set flag and do in draw() which is used as a timer
 
  if (EnablePreview == true) redraw(); //redraw indicator mostly if enabled 
} //end serialEvent()

//================================================================================================================

void threadOutput() //threaded function for quicker handling
{
  OutputPort.write(TransmissionArray);  //Send out on Output
}

//================================================================================================================

void keyPressed()
{
  println("Key Pressed: "+key);

  if (key == 32)
  {
    EnablePreview =! EnablePreview; 
    redraw();
  }
} //end keyPressed()