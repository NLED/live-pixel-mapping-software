 //<>//
//================================================================================================================

void LoadConfigFile()
{
  println("LoadConfigFile() with "+SelectedFile);
  String[] lines = loadStrings(SelectedFile); //divides the lines  
  String[] WorkString = new String[10]; //used to divide the lines into tab
  int MinX=10000;
  int MinY=10000;
  int MaxX=0;
  int MaxY=0;

  WorkString = split(lines[1], '\t'); //first line is a comment, ignore

  patchFilePath = WorkString[1];
  WorkString = split(lines[2], '\t'); //split line into 
  InputPortName = WorkString[1];
  WorkString = split(lines[3], '\t'); //split line into 
  OutputPortName = WorkString[1];
  WorkString = split(lines[4], '\t'); //split line into 
  InputBaudRate = int(WorkString[1]);
  WorkString = split(lines[5], '\t'); //split line into 
  OutputBaudRate = int(WorkString[1]);
  WorkString = split(lines[6], '\t'); //split line into 
  EnablePreview = boolean(WorkString[1]);
  WorkString = split(lines[7], '\t'); //split line into 
  AutoSizeEnable = boolean(WorkString[1]);
  WorkString = split(lines[8], '\t'); //split line into 
  GlediatorProtocol = boolean(WorkString[1]);
  WorkString = split(lines[9], '\t'); //split line into 
  AuroraLiveMode = boolean(WorkString[1]); 
  WorkString = split(lines[10], '\t'); //split line into 
  MatrixWidth = int(WorkString[1]); 
  WorkString = split(lines[11], '\t'); //split line into 
  MatrixHeight = int(WorkString[1]);
  WorkString = split(lines[12], '\t'); //split line into 
  OrientationVar = int(WorkString[1]);
  WorkString = split(lines[13], '\t'); //split line into 
  MaxOutputFPS = int(WorkString[1]);

  if(OutputPortName.equals("FILERECORD"))
  {
    RecordToFileMode = true; //sets it to record output values to file instead of sending out COM port
  }
  else RecordToFileMode = false; //should already be false...

  //load patch file
  lines = loadStrings(patchFilePath);
  WorkString = split(lines[0], '\t'); //split line into values
  PixelAmount = int(trim(WorkString[0]));

  println("Using Patch File: "+patchFilePath);
  println("Loaded: "+InputPortName+" :"+OutputPortName+" : "+InputBaudRate+" : "+OutputBaudRate+" : "+EnablePreview);

  //load patch file
  for (int i=1; i != lines.length; i++)
  {
    WorkString = split(lines[i], '\t'); //split line into values
    if (int(WorkString[0]) > MaxX) MaxX = int(WorkString[0]);
    if (int(WorkString[0]) < MinX) MinX = int(WorkString[0]);

    if (int(WorkString[1]) > MaxY) MaxY = int(WorkString[1]);
    if (int(WorkString[1]) < MinY) MinY = int(WorkString[1]);
  } //end for

  int Xdifference = MaxX - MinX;
  int Ydifference = MaxY - MinY;
  println("Differences: "+Xdifference+" : "+Ydifference);

  if (AutoSizeEnable == true) //calc with patch file sizes or user set matrix size
  {
    TotalPixels = (Xdifference+1) * (Ydifference+1); //calculates total channels if rectangular based on patch file
    MatrixWidth = (Xdifference+1);
    MatrixHeight = (Ydifference+1);
    println("AutoSizeEnable is true W: "+MatrixWidth+"  H: "+MatrixHeight);
  } 
  else
  {
    TotalPixels = MatrixWidth * MatrixHeight; //calculates total channels if rectangular based on user settings   
    println("AutoSizeEnable is false W: "+MatrixWidth+"  H: "+MatrixHeight);
  }

  PatchedChannels = PixelAmount * 3; //3 is for RGB pixels
  TotalChannels = TotalPixels * 3;  //3 is for RGB pixels

  println("PixelAmount: "+PixelAmount+"   PatchedChannels: "+PatchedChannels+"    TotalChannels: "+TotalChannels);

  PatchCoordX = new int[PixelAmount]; //resize the patch arrays based on PatchedChannels
  PatchCoordY = new int[PixelAmount];

  if (GlediatorProtocol == true) StorageArray = new byte[TotalChannels+1];
  else StorageArray = new byte[TotalChannels];

  TransmissionArray = new byte[PatchedChannels];

  //file created was incremented method channel numbers
  for (int i=0; i != PixelAmount; i++)
  {
    WorkString = split(lines[i+1], '\t');      
    PatchCoordX[i] = int(WorkString[0]) - MinX;
    PatchCoordY[i] = int(WorkString[1]) - MinY;
  } //end for


//Prepare GUI variables

if(MatrixWidth > MatrixHeight) pixelRectSize = (width - (cPrevOffsetX*2)) / MatrixWidth;
else  pixelRectSize = ((height-cPrevOffsetY) - (cPrevOffsetX*2)) / MatrixHeight;



  OpenCOMPorts();
} //end LoadConfigFile()

//================================================================================================================

void FileRecoderAddFrame()
{
  //Takes the received packet, and writes all the values as single comma delimeted line
  //Doubt this is the most efficent way to do it
  try 
  {
    fw = new FileWriter(SessionFileName, true); // true means: "append"
    bw = new BufferedWriter(fw);
    for (int i = 0; i != PatchedChannels; i++)
    {
      bw.write(str(TransmissionArray[i] & 0xFF)+","); //the & 0xFF converts the signed byte to unsigned so it can be converted to a string
    }
    bw.newLine(); //add a new line for the next packet / frame.
  } 
  catch (IOException e) 
  {
    // Report problem or handle it

  }
  finally
  {
    if (bw != null)
    {
      try { 
        bw.close();
      } 
      catch (IOException e) {
      }
    }
  }
}

//================================================================================================================