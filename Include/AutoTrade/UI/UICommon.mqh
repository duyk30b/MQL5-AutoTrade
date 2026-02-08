//+------------------------------------------------------------------+
//|      UICommon.mqh  | | Thư viện tạo object trên chart            |
//+------------------------------------------------------------------+
#property copyright "UICommon Library"
#property link ""
#property version "1.00"

//+------------------------------------------------------------------+
//|         Lớp UICommon                                             |
//+------------------------------------------------------------------+

class UICommon {
 public:
   bool CreateLabel(
      const long   chartId,
      const string name,
      const string text,
      int          fontSize   = 8,
      color        textColor  = clrBlack,
      string       fontFamily = "Arial"
   ) {
      if(ObjectFind(chartId, name) >= 0)
         ObjectDelete(chartId, name);
      if(!ObjectCreate(chartId, name, OBJ_LABEL, 0, 0, 0))
         return false;

      ObjectSetInteger(chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);

      ObjectSetString(chartId, name, OBJPROP_TEXT, text);
      ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(chartId, name, OBJPROP_FONT, fontFamily);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, textColor);

      ObjectSetInteger(chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);

      return true;
   }

   bool CreateButton(
      const long   chartId,
      const string name,
      const string text,
      int          width           = 100,
      int          height          = 35,
      color        textColor       = clrBlack,
      color        backgroundColor = clrSilver,
      color        borderColor     = clrSilver
   ) {
      if(ObjectFind(chartId, name) >= 0)
         ObjectDelete(chartId, name);
      if(!ObjectCreate(chartId, name, OBJ_BUTTON, 0, 0, 0))
         return false;

      ObjectSetInteger(chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(chartId, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(chartId, name, OBJPROP_YSIZE, height);

      ObjectSetString(chartId, name, OBJPROP_TEXT, text);
      ObjectSetString(chartId, name, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(chartId, name, OBJPROP_BGCOLOR, backgroundColor);
      ObjectSetInteger(chartId, name, OBJPROP_BORDER_COLOR, borderColor);

      ObjectSetInteger(chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(chartId, name, OBJPROP_STATE, false);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);

      return true;
   }

   void setPosition(long chartId, string name, int x, int y) {
      ObjectSetInteger(chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chartId, name, OBJPROP_YDISTANCE, y);
   }
   void setSize(long chartId, string name, int width, int height) {
      ObjectSetInteger(chartId, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(chartId, name, OBJPROP_YSIZE, height);
   }
   void setText(long chartId, string name, string text) {
      ObjectSetString(chartId, name, OBJPROP_TEXT, text);
   }
   void setFontSize(long chartId, string name, int fontSize) {
      ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE, fontSize);
   }
   void setFontFamily(long chartId, string name, string fontFamily = "Arial Bold") {
      ObjectSetString(chartId, name, OBJPROP_FONT, fontFamily);
   }
   void setTextColor(long chartId, string name, color textColor) {
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, textColor);
   }
   void setBackgroundColor(long chartId, string name, color backgroundColor) {
      ObjectSetInteger(chartId, name, OBJPROP_BGCOLOR, backgroundColor);
   }
   void setBorderColor(long chartId, string name, color borderColor) {
      ObjectSetInteger(chartId, name, OBJPROP_BORDER_COLOR, borderColor);
   }
   void setZOrder(long chartId, string name, int zOrder) {
      ObjectSetInteger(chartId, name, OBJPROP_ZORDER, zOrder);
   }

   void setState(long chartId, string name, bool state) {
      ObjectSetInteger(chartId, name, OBJPROP_STATE, state);
   }
   bool getState(long chartId, string name) {
      return (bool)ObjectGetInteger(chartId, name, OBJPROP_STATE);
   }
};