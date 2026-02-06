//v3.0
//#include <DanyInclude\\D_IsNewbar.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar() {
//--- remember the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

//--- if it is the first call of the function
   if(last_time==0) {
      //--- set time and exit
      last_time=lastbar_time;
      return(true);
   }

//--- if the time is different
   if(last_time!=lastbar_time) {
      //--- memorize time and return true
      last_time=lastbar_time;
      return(true);
   }
//--- if we pass to this line then the bar is not new, return false
   return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBarMultiTF(ENUM_TIMEFRAMES iTimeFrame) {
   if(iTimeFrame == PERIOD_CURRENT) iTimeFrame = Period();
   ENUM_TIMEFRAMES periodTable[21]= {PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,
                                     PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30
                                     ,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,
                                     PERIOD_D1,PERIOD_W1,PERIOD_MN1
                                    } ;
//--- remember the time of opening of the last bar in the static variable
   static datetime last_time[21];
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),iTimeFrame,SERIES_LASTBAR_DATE);

//--- get iTIme in Table
   int pos = 0;
   for(int i=0; i<21; i++) {
      if(iTimeFrame == periodTable[i]) {pos=i; break;}
   }
   

//--- if it is the first call of the function
   if(last_time[pos]==0) {
      //--- set time and exit
      last_time[pos]=lastbar_time;
      return(true);
   }

//--- if the time is different
   if(last_time[pos]!=lastbar_time) {
      //--- memorize time and return true
      last_time[pos]=lastbar_time;
      return(true);
   }
//--- if we pass to this line then the bar is not new, return false
   return(false);
}
//+------------------------------------------------------------------+
