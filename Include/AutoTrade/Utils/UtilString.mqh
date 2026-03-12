#ifndef __UTIL_STRING_MQH__
#define __UTIL_STRING_MQH__

class UtilString {
 public:
   // Hàm lấy value từ string encode dạng: key1=value1;key2=value2;...
   static string GetValueFromEncodedString(string encodedString, string key) {
      string searchKey = key + "=";
      int    startPos  = StringFind(encodedString, searchKey);
      if(startPos == -1) {
         return "";                       // Không tìm thấy key
      }
      startPos   += StringLen(searchKey); // Vị trí bắt đầu của value
      int endPos  = StringFind(encodedString, ";", startPos);
      if(endPos == -1) {
         endPos = StringLen(encodedString); // Nếu không có dấu ; thì lấy đến hết chuỗi
      }
      return StringSubstr(encodedString, startPos, endPos - startPos);
   }
};

#endif // __UTIL_STRING_MQH__