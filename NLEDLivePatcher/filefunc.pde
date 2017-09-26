 //<>// //<>// //<>//
void LoadConfigFile()
{
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

  PatchedChannels = PixelAmount * 3;
  TotalChannels = TotalPixels * 3; 

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

  OpenCOMPorts();
} //end LoadConfigFile()

//===============================================================================================================

void OpenCOMPorts()
{
  println(Serial.list()); //list COM ports

  try {
    InputPort.stop();
    InputPort.dispose();   
    OutputPort.stop();
    OutputPort.dispose();
  }
  catch(Exception e) {
  } 

  try 
  {
    OutputPortNumber = OpenPort(OutputPortName);
    OutputPort = new Serial(this, Serial.list()[OutputPortNumber], OutputBaudRate);
    println("Opened Output Port: "+OutputPortName);
  }
  catch(Exception e)
  {
    println("Could Not Open Output COM Port: "+OutputPortName);
    OutputPortName = "NONE";
  }

  try 
  {
    InputPortNumber = OpenPort(InputPortName);
    InputPort = new Serial(this, Serial.list()[InputPortNumber], InputBaudRate);
    println("Opened Input Port: "+InputPortName);
  }
  catch(Exception e)
  {
    println("Could Not Open Input COM Port: "+InputPortName);
    InputPortName = "NONE";
  }

  //set to trigger serialEvent every X bytes received after data has been framed, run serialEvent for single bytes
} //end func()

//================================================================================================================

int OpenPort(String NameID) //returns Serial.list() ID number
{
  println("OpenCOMPort()");

  int x = 0;

  try
  {
    for (x =0; x != Serial.list().length; x++) 
    {
      if (NameID.equals(Serial.list()[x]))
      {  
        return x; //return port ID if matches string
      }
    }
  }
  catch(Exception e)
  {
    println("Could Not Open COM Port "+Serial.list()[x]+"as specified");
  }
  return 1000; //return out of bounds
} //end func

//================================================================================================================