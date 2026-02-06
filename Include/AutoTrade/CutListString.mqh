//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ListStringToListTF(string InputString, ENUM_TIMEFRAMES &OutPutTF[]) {
   ushort u_sep = StringGetCharacter(",",0);
   string OutPutString[];
   int k = StringSplit(InputString, u_sep, OutPutString);
   ArrayResize(OutPutTF, k, k);
   for(int i=0; i<k; i++) {
      StringTrimLeft(OutPutString[i]);
      StringTrimRight(OutPutString[i]);
      StringToUpper(OutPutString[i]);
      OutPutTF[i] = ConvertStringToTime(OutPutString[i]);
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CutListSting(string InputString, string &OutPutString[]) {
   ushort u_sep = StringGetCharacter(",",0);
   int k = StringSplit(InputString, u_sep, OutPutString);
   for(int i=0; i<ArraySize(OutPutString); i++) {
      StringTrimLeft(OutPutString[i]);
      StringTrimRight(OutPutString[i]);
      StringToUpper(OutPutString[i]);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES ConvertStringToTime(string Input) {
   StringTrimLeft(Input);
   StringTrimRight(Input);
   StringToUpper(Input);

   if(Input == "M1" || Input==" M1") {
      return(PERIOD_M1);
   }
   if(Input == "M2" || Input==" M2") {
      return(PERIOD_M2);
   }
   if(Input == "M3" || Input==" M3") {
      return(PERIOD_M3);
   }
   if(Input == "M4" || Input==" M4") {
      return(PERIOD_M4);
   }
   if(Input == "M5" || Input==" M5") {
      return(PERIOD_M5);
   }
   if(Input == "M6" || Input==" M6") {
      return(PERIOD_M6);
   }
   if(Input == "M10" || Input==" M10") {
      return(PERIOD_M10);
   }
   if(Input == "M12" || Input==" M12") {
      return(PERIOD_M12);
   }
   if(Input == "M15" || Input==" M15") {
      return(PERIOD_M15);
   }
   if(Input == "M20" || Input==" M20") {
      return(PERIOD_M20);
   }
   if(Input == "M30" || Input==" M30") {
      return(PERIOD_M30);
   }
   if(Input == "H1" || Input==" H1") {
      return(PERIOD_H1);
   }
   if(Input == "H2" || Input==" H2") {
      return(PERIOD_H2);
   }
   if(Input == "H3" || Input==" H3") {
      return(PERIOD_H3);
   }
   if(Input == "H4" || Input==" H4") {
      return(PERIOD_H4);
   }
   if(Input == "H6" || Input==" H6") {
      return(PERIOD_H6);
   }
   if(Input == "H8" || Input==" H8") {
      return(PERIOD_H8);
   }
   if(Input == "H12" || Input==" H12") {
      return(PERIOD_H12);
   }
   if(Input == "D1" || Input==" D1") {
      return(PERIOD_D1);
   }
   if(Input == "W1" || Input==" W1") {
      return(PERIOD_W1);
   }
   if(Input == "MN1" || Input==" MN1") {
      return(PERIOD_MN1);
   }
   return(Period());
}
//+------------------------------------------------------------------+
