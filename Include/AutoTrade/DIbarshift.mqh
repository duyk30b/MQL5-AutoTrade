//+------------------------------------------------------------------+
int DuongIBarShift(int i, ENUM_TIMEFRAMES inpTimeframe, ENUM_TIMEFRAMES outTimeframe) {
   int a = ConvertTimeToInt(inpTimeframe);
   int b = ConvertTimeToInt(outTimeframe);
   int c = b/a;
   int res = i/c;

   return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ConvertTimeToInt(ENUM_TIMEFRAMES timeframe) {
   if(timeframe == PERIOD_CURRENT) timeframe = Period(); 
   
   if(timeframe ==PERIOD_M1) {
      return 1;
   }
   if(timeframe ==PERIOD_M5) {
      return 5;
   }
   if(timeframe ==PERIOD_M15) {
      return 15;
   }
   if(timeframe ==PERIOD_M30) {
      return 30;
   }
   if(timeframe ==PERIOD_H1) {
      return 60;
   }
   if(timeframe ==PERIOD_H4) {
      return 240;
   }
   if(timeframe ==PERIOD_D1) {
      return 1440;
   }
   if(timeframe ==PERIOD_W1) {
      return 10080 ;
   }
   if(timeframe ==PERIOD_MN1) {
      return 43200;
   }
   return(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
