//---
datetime TimeDebug = D'2021.12.30 12:30';
if(TimeCurrent() == TimeDebug)
  {
   Print("debugHere" , TimeDebug);
   int debugint = 0;
  }
//---
datetime TimeDebug = D'2021.12.30 12:30';
if(iTime(_Symbol , _Period , 1) == TimeDebug)
  {
   Print("debugHere" , TimeDebug);
   int debugint = 0;
  }
//---
void stopTimeToDebug()
   {
      datetime TimeDebug = D'1980.07.19 12:30:27';
      if(TimeCurrent() >= TimeDebug)
        {
         int debug =0;
        }
   }  