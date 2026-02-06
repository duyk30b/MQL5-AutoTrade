//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ConvertTimeToInt(ENUM_TIMEFRAMES timeframe) {

   if(timeframe ==PERIOD_CURRENT)      return 0;
   if(timeframe ==PERIOD_M1)           return 1;
   if(timeframe ==PERIOD_M2)           return 2;
   if(timeframe ==PERIOD_M3)           return 3;
   if(timeframe ==PERIOD_M4)           return 4;
   if(timeframe ==PERIOD_M5)           return 5;
   if(timeframe ==PERIOD_M6)           return 6;
   if(timeframe ==PERIOD_M10)          return 10;
   if(timeframe ==PERIOD_M12)          return 12;
   if(timeframe ==PERIOD_M15)          return 15;
   if(timeframe ==PERIOD_M20)          return 20;
   if(timeframe ==PERIOD_M30)          return 30;
   if(timeframe ==PERIOD_H1)           return 60;
   if(timeframe ==PERIOD_H2)           return 120;
   if(timeframe ==PERIOD_H3)           return 180;
   if(timeframe ==PERIOD_H4)           return 240;
   if(timeframe ==PERIOD_H6)           return 360;
   if(timeframe ==PERIOD_H8)           return 480;
   if(timeframe ==PERIOD_H12)          return 720;
   if(timeframe ==PERIOD_D1)           return 1440;
   if(timeframe ==PERIOD_W1)           return 10080;
   if(timeframe ==PERIOD_MN1)          return 43200;

   return 0;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
