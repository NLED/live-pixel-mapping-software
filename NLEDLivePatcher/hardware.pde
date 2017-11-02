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
    
   if(OutputPortName.equals("FILERECORD"))
  {
    OutputPortName = "RECORD";
  }
  else OutputPortName = "NONE";
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