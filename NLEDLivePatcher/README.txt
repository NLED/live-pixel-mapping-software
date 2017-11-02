MIT License

Copyright (c) 2017 Northern Lights Electronic Design, LLC
 
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
 Date Updated: October 31, 2017 
 Software Version:  1c
 Webpage: www.NLEDShop.com/nledlivepatcher
 Written in Processing v3.6  - www.Processing.org
 
 //============================================================================================================
 
 - Allows odd-shaped, dynamically patched(mapped) LED matrices to be controlled from third-party software apps without patch support.
 - Supports RGB, RGBW, and single color LED matrices. Non RGB may require code modifications
 - Supports NLED serial protocol and gLEDiator serial protocol(flag in configuration files)
 (gLEDiator serial protocol adds a single byte with a value of 1 to the end of the packet to indicate a start)
 - Customizable using Processing 3
 
 Intro:
 Wanted a simple way to apply pixel patch/map files to third-party matrix software data streams that operate over serial ports. This 
 app is designed to be used with com0com or similar virtual serial port drivers. The transmission software(such as gLEDiator)
 transmits the square/rectangular matrix data over a virtual serial port into the Live Patcher app. The app reads a configuration
 file and loads the appropriate patch file. The patch file tells the app how to re-organize the received data streams to work with
 odd shaped LED matrices. Once re-organized the data can be sent out any serial port, commonly a FTDI adapter connected to a NLED 
 Pixel Controller(several models). But the re-organized data could also be sent to a Ardunio or customized controller for conversion
 to the pixel protocol.
 
 Now supports File Recording Mode, rips the serial port output from other software sources and writes the values to a text file.
 
 Configurations:
 See ReadMe for details on the configuration files
 
 
 Max Output FPS / Throttling:
 Controllers can only receive and handle data up to a certain frames/packets per second. Limitations depend on controller specs and/or output pixel
 chipset. Experimenting may be required to find the maximum frame rate for your project. Try to set the config MAXFPS to 0 to start, and if the receiving
 LED matrix does not function or flickers/glitches/artifacts you may need to enable output throttling. Start high and try lower values until it works.
 
 
 Usage:  Read Setup-Instructions.txt in the folder for full information on software usage
 - Create a patch/map file using NLED Matrix Patcher.
 - Make a Live Patcher configuration file for the matrix, set the width, height, patch file name, etc. See examples.
 - Install com0com or another virtual serial port. Requires in and out ports.
 - Setup your transmission software(gLEDiator) for same size matrix. 
 - Setup the Output Mode protocol and selected COM port with the correct Baud rate.
 - In software, select the transmission serial port and set the baud rates to match what you set in the configuration file.
     - Note: To use Record to File Mode, use the string FILERECORD for the name of the output port.
 - Launch the Live Patcher app, if enabled the preview will display the patch/map file graphically.
 - The circle in the upper left corner indicates if things are running, if they are not recheck all your settings and configurations.
 - When the application is running, use the hotkeys to interact. All other settings requires software restart.
 
 Future Upgrades:
 - Add TCP/UDP usage, with cross overs(Serial to TCP, TCP to Serial)
 - Add ArtNet compatibility
 - GUI software settings
 - Color Ordering - GRB, BRG, etc - for now do it through the transmission software
 
 
 Hotkeys:
   P key, toggles run/pause the output transmission or record to file.
   R key, in File Recorder mode, it will restart the recorder and create a new text file to write to.
 
 
Revisions 1b to 1c:
   - Added data to preview area to make it an actual preview
   - Added Record to file mode, that allows the patched/mapped serial stream to be saved to a text file
       - Mostly for use with NLED Aurora Control's File Play sequence mode. But would have other uses.
   - Added Pause/Run hotkey, "p", stops/plays output transmission
   - Forced preivew pixel grid to fill the window space, sizes dynamically
 
 
 Revisions 1a to 1b:
   - Added MAXFPS in config
   - Added max output FPS throttling code
   - Cleaned up the code
 
============================================================================================================
 
 Read Setup-Instructions.txt for more information on software usage
 
============================================================================================================
 
Configuration Files:

First is the StringID, these don't matter but are expected
Then a single TAB (\t), No spaces!
Then the data, either string, boolean or integer 

The input and output serial port entries should be the string name of the serial port
	on windows systems they can be found in the Device Manager, commonly COM1 - COM99
	When com0com installs it will get assigned COM port names that will not change
	
	On Linux systems the serial port name might be "/dev/ttyS0" or similar, that is what should be used for the entry.
	
Example:
 
PATCH	patches/round-matrix-22x22-patch-v4.txt
INCOM#	COM28
OUTCOM#	COM9
INBAUD	1000000
OUTBAUD	1000000
PREVIEW	false
AUTOSZ	false
GLEDIAT	true
AURORA	true
WIDTH	22
HEIGHT	22
ORIEN	0
OUTFPS	0

PATCH	path to patch file, starting in base directory
INCOM#	string name of the input serial port, varies from OS to OS
OUTCOM#	string name of the output serial port, varies from OS to OS - For File Record Mode use FILERECORD instead of a serial port name
INBAUD	Input baud rate integer, no commas
OUTBAUD	Output baud rate integer, no commas
PREVIEW	Enable Preview - either true or false
AUTOSZ	Auto size the matrix or use the width/height values below - true or false
GLEDIAT	Enable gLEDiator protocol or use straight through(NLED protocol)
AURORA	Enable NLED USB Live Control Protocol Compatibility
WIDTH	Width of the LED matrix, set value only if AUTOSZ = false
HEIGHT	Height of the LED matrix, set value only if AUTOSZ = false
ORIEN	Orientation of the data, only 0(horiz) or 1(vertacle) for now, adjust transmission software settings to fine tune
OUTFPS	Maximum output frame rate. 0 is auto, same as input FPS. Greater than 0 is the max FPS