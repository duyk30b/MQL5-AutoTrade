//+------------------------------------------------------------------+
//|   count decima after point of a double                          |
//+------------------------------------------------------------------+
int CountDigits(double val, int maxPrecision = 8) {
   int digits = 0;
   while(NormalizeDouble(val,digits) != NormalizeDouble(val, maxPrecision))
      digits++;
   return digits;
}

//+------------------------------------------------------------------+
//|    round lot to volume step                                      |
//+------------------------------------------------------------------+
double RoundLotStep(double &lot) {
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minlot = SymbolInfoDouble(_Symbol , SYMBOL_VOLUME_MIN);
// get digit of lotstep
   int digits = 0;
   while(NormalizeDouble(lotstep,digits) != NormalizeDouble(lotstep, 8))
      digits++;
   lot = NormalizeDouble(lot, digits);
   if(lot < minlot) lot = minlot;
   return lot;
}
//+------------------------------------------------------------------+
