#ifndef __UTIL_NUMBER_MQH__
#define __UTIL_NUMBER_MQH__

class UtilNumber {
 public:
   static string FormatNumber(double value, int digits) {
      string strValue = DoubleToString(value, digits);
      int    dotPos   = StringFind(strValue, ".");
      string integerPart, decimalPart;

      if(dotPos >= 0) {
         integerPart = StringSubstr(strValue, 0, dotPos);
         decimalPart = StringSubstr(strValue, dotPos);
      } else {
         integerPart = strValue;
         decimalPart = "";
      }

      string formattedInteger;
      int    count = 0;
      for(int i = StringLen(integerPart) - 1; i >= 0; i--) {
         formattedInteger = StringSubstr(integerPart, i, 1) + formattedInteger;
         count++;
         if(count == 3 && i != 0) {
            formattedInteger = "," + formattedInteger;
            count            = 0;
         }
      }

      return formattedInteger + decimalPart;
   };

   static double RoundToDigits(double value, int digits) {
      double factor = MathPow(10.0, digits);
      return MathRound(value * factor) / factor;
   }
};

#endif // __UTIL_NUMBER_MQH__