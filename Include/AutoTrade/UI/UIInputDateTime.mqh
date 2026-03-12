//+------------------------------------------------------------------+
//|                                              UIInputDateTime.mqh   |
//+------------------------------------------------------------------+
//|                                              UIInputDateTime.mqh   |
//+------------------------------------------------------------------+
#ifndef UI_INPUT_DATE_TIME_MQH
#define UI_INPUT_DATE_TIME_MQH

#property copyright "UIInputDateTime Library"
#property version "1.00"

#include <AutoTrade/UI/UIDefines.mqh>

//+------------------------------------------------------------------+
//| Class UIInputDateTime                                              |
//+------------------------------------------------------------------+

class UIInputDateTime {
 private:
   UIListener *m_listener;
   FOnChange   m_callback;
   void       *m_parent;     // lưu pointer đến object chủ

   long        m_chartId;    // ID của chart
   string      m_name;       // Tên unique cho control
   int         m_x;          // Vị trí X
   int         m_y;          // Vị trí Y
   int         m_width;      // Chiều rộng input
   int         m_fontSize;   // Kích thước font
   string      m_valueString;
   string      m_labelText;  // Text label (nếu có)
   int         m_zOrderBase; // Z-order base for drawing objects of this control
   bool        m_isDisabled;
   bool        m_isTester;   // Có đang chạy ở môi trường tester không

   // Màu sắc
   color m_clrLabelText;  // Màu label
   color m_clrBorder;     // Màu border
   color m_clrBackground; // Màu background

   // Tên các object
   string m_objInputName;
   string m_objLabelName;

 public:
   UIInputDateTime() {}
   ~UIInputDateTime() { DeleteAllObject(); }

   void Initialize(long chartId, string name) {
      m_chartId     = chartId;
      m_name        = name;
      m_fontSize    = 10;
      m_valueString = "";
      m_labelText   = "";
      m_zOrderBase  = 0;
      m_isDisabled  = false;

      if((bool)MQLInfoInteger(MQL_TESTER) || (bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
         m_isTester = true;
      } else {
         m_isTester = false;
      }

      m_clrLabelText  = clrWhite;
      m_clrBackground = clrWhite;
      m_clrBorder     = clrDarkGray;

      // Tạo tên các object
      m_objLabelName = "Obj_" + m_name + "_Label";
      m_objInputName = "Obj_" + m_name + "_Input";
   }

   void SetListener(UIListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_parent   = ctx;
   }

   void EmitValue() {
      datetime valueTime = StringToTime(m_valueString);
      if(m_listener != NULL) {
         m_listener.listen(&this, UI_EVENT_CHANGE_VALUE, valueTime);
      }
      if(m_callback != NULL) {
         m_callback(m_parent, UI_EVENT_CHANGE_VALUE, valueTime);
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 2);
      objNameList[0] = m_objLabelName;
      objNameList[1] = m_objInputName;
      return 2;
   }

   void DeleteAllObject() {
      string objNameList[];
      int    countObject = GetObjectNameList(objNameList);
      for(int i = 0; i < countObject; i++) {
         ObjectDelete(m_chartId, objNameList[i]);
      }
   }

   // Getters
   string   GetValueString() { return m_valueString; }
   datetime GetValueTime() { return StringToTime(m_valueString); }

   // Setters
   void SetWidth(int width) { m_width = width; }
   void SetLabel(string text, color labelTextColor = clrNONE) {
      m_labelText = text;
      if(labelTextColor != clrNONE) {
         m_clrLabelText = labelTextColor;
      }
   }
   void SetFontSize(int size) { m_fontSize = size; }
   void SetValueString(string value) { m_valueString = value; }
   void SetValueTime(datetime value) { m_valueString = TimeToString(value); }
   void SetZOrderBase(int zOrderBase) { m_zOrderBase = zOrderBase; }
   void SetDisabled(bool isDisabled) { m_isDisabled = isDisabled; }
   void SetBackgroundColor(color clr) { m_clrBackground = clr; }
   void SetBorderColor(color clr) { m_clrBorder = clr; }

   void UpdateValueString(string value) {
      if(value != m_valueString) {
         m_valueString = value;
         ObjectSetString(m_chartId, m_objInputName, OBJPROP_TEXT, m_valueString);
      }
   }
   void UpdateValueTime(datetime value) {
      string valueString = TimeToString(value);
      if(valueString != m_valueString) {
         m_valueString = valueString;
         ObjectSetString(m_chartId, m_objInputName, OBJPROP_TEXT, m_valueString);
      }
   }

   void UpdateDisabled(bool isDisabled) {
      m_isDisabled = isDisabled;
      ObjectSetInteger(
         m_chartId,
         m_objInputName,
         OBJPROP_READONLY,
         m_isTester || m_isDisabled
      ); // Nếu đang ở tester hoặc bị disable thì input readonly

      if(m_isDisabled) {
         ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_COLOR, clrDarkGray);
      } else {
         ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_COLOR, clrBlack);
      }
   }

   void UpdateLabel(string text, color clrLabelText = clrNONE) {
      m_labelText = text;
      ObjectSetString(m_chartId, m_objLabelName, OBJPROP_TEXT, m_labelText);

      if(clrLabelText != clrNONE) {
         m_clrLabelText = clrLabelText;
         ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_COLOR, m_clrLabelText);
      }
   }

   void StartDraw(int x, int y, int width, int height);
   void HandleChangeInputValue();
   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();
};

void UIInputDateTime::StartDraw(int x, int y, int width, int fontSize) {
   m_x             = x;
   m_y             = y;
   m_width         = width;
   m_fontSize      = fontSize;

   double rateSize = 2.2;

   int    yOffset  = 0;
   if(m_labelText != "") {
      if(!ObjectCreate(m_chartId, m_objLabelName, OBJ_LABEL, 0, 0, 0)) {
         Print("Failed to create label object: ", GetLastError());
         return;
      }
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(m_chartId, m_objLabelName, OBJPROP_TEXT, m_labelText);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_FONTSIZE, m_fontSize);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_COLOR, m_clrLabelText);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_ZORDER, m_zOrderBase + 0);

      yOffset += (int)(m_fontSize * 1.8);
   }

   // Create input object
   if(!ObjectCreate(m_chartId, m_objInputName, OBJ_EDIT, 0, 0, 0)) {
      Print("Failed to create input: ", m_objInputName, " Error: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_ALIGN, ALIGN_LEFT);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_YDISTANCE, m_y + yOffset);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_XSIZE, m_width);
   ObjectSetString(m_chartId, m_objInputName, OBJPROP_TEXT, m_valueString);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_READONLY, m_isTester || m_isDisabled);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_YSIZE, (int)(m_fontSize * rateSize));
   ObjectSetString(m_chartId, m_objInputName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_BGCOLOR, m_clrBackground);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_BORDER_COLOR, m_clrBorder);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_objInputName, OBJPROP_HIDDEN, true);
}

void UIInputDateTime::HandleChangeInputValue() {
   string text = ObjectGetString(m_chartId, m_objInputName, OBJPROP_TEXT);
   SetValueString(text);
}

void UIInputDateTime::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   // Xử lý khi user nhập tay vào input
   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      if(sparam == m_objInputName) {
         HandleChangeInputValue();
      }
   }
}

void UIInputDateTime::OnStrategyTesterEvent() {
   // Không có sự kiện nào đặc biệt cần xử lý trong tester cho control này
}

#endif // UI_INPUT_DATE_TIME_MQH
