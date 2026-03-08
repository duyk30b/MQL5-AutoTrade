//+------------------------------------------------------------------+
//|      UICommon.mqh  | | Thư viện tạo object trên chart            |
//+------------------------------------------------------------------+
#ifndef UI_COMMON_MQH
#define UI_COMMON_MQH

#property copyright "UICommon Library"
#property link ""
#property version "1.00"

//+------------------------------------------------------------------+
//|         Lớp UICommon                                             |
//+------------------------------------------------------------------+

class UICommon {
 public:
   void CreateRectangleLabel(
      const long chartId, string name, int x, int y, int width, int height, color borderBoxColor
   ) {
      // Hình chữ nhật có thể set border
      ObjectCreate(chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chartId, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(chartId, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(chartId, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(chartId, name, OBJPROP_BGCOLOR, clrNONE);
      ObjectSetInteger(chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, borderBoxColor);
      ObjectSetInteger(chartId, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);
   }

   bool CreateLabel(
      const long   chartId,
      const string name,
      const string text,
      int          x,
      int          y,
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
      ObjectSetInteger(chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chartId, name, OBJPROP_YDISTANCE, y);

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
      int          x,
      int          y,
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
      ObjectSetInteger(chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chartId, name, OBJPROP_YDISTANCE, y);

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

   void CreateEdit(long chartId, string name, int w, int h, string txt, int fontSize = 12) {
      ObjectCreate(chartId, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(chartId, name, OBJPROP_XSIZE, w);          // Chiều rộng
      ObjectSetInteger(chartId, name, OBJPROP_YSIZE, h);          // Chiều cao
      ObjectSetString(chartId, name, OBJPROP_TEXT, txt);          // Giá trị ban đầu
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, clrBlack);   // Màu chữ (đen)
      ObjectSetInteger(chartId, name, OBJPROP_BGCOLOR, clrWhite); // Màu nền (trắng)
      ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(chartId, name, OBJPROP_ZORDER, 20);        // Hiển thị phía trước
   }

   bool getState(long chartId, string name) {
      return (bool)ObjectGetInteger(chartId, name, OBJPROP_STATE);
   }
   string getText(long chartId, string name) {
      return ObjectGetString(chartId, name, OBJPROP_TEXT);
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
   void setTextAlign(long chartId, string name, ENUM_ALIGN_MODE alignMode) {
      ObjectSetInteger(chartId, name, OBJPROP_ALIGN, alignMode);
   }
   void setState(long chartId, string name, bool state) {
      ObjectSetInteger(chartId, name, OBJPROP_STATE, state);
   }
   void setShow(long chartId, string name, bool isShow) {
      ObjectSetInteger(
         chartId,
         name,
         OBJPROP_TIMEFRAMES,
         isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
      );
   }
   void CreateHorizontalLine(long chartId, string name, double price) {
      ObjectCreate(chartId, name, OBJ_HLINE, 0, 0, 0);
      ObjectSetDouble(chartId, name, OBJPROP_PRICE, price);
   }
   void setLineColor(long chartId, string name, color lineColor) {
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, lineColor);
   }
   void setLineStyle(long chartId, string name, ENUM_LINE_STYLE lineStyle) {
      ObjectSetInteger(chartId, name, OBJPROP_STYLE, lineStyle);
   }
   void setLineWidth(long chartId, string name, int lineWidth) {
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, lineWidth);
   }
   void setLinePrice(long chartId, string name, double price) {
      ObjectSetDouble(chartId, name, OBJPROP_PRICE, price);
   }
};
#endif // UI_COMMON_MQH