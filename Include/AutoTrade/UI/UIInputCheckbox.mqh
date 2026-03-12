//+------------------------------------------------------------------+
//|                                                   UIInputCheckbox.mqh |
//|                               Copyright 2026, UIInputCheckbox Library |
//|                                                 https://mql5.com |
//| 16.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#ifndef UI_CHECKBOX_MQH
#define UI_CHECKBOX_MQH

#property copyright "Copyright 2026, UIInputCheckbox Library"
#property link "https://mql5.com"
#property version "1.00"

#include <AutoTrade/UI/UIDefines.mqh>

class UIInputCheckbox {
 private:
   UIListener *m_listener;
   FOnChange   m_callback;
   void       *m_parent;     // lưu pointer đến object chủ

   long        m_chartId;    // ID của chart
   string      m_name;       // Tên unique cho control
   int         m_x;          // Vị trí X
   int         m_y;          // Vị trí Y
   int         m_fontSize;   // Kích thước font chữ label

   bool        m_checked;    // Giá trị hiện tại (true/false)
   string      m_labelText;  // Text label (nếu có)
   bool        m_isDisabled; // Có đang ở trạng thái disabled không
   int         m_zOrderBase;

   color       m_clrNormal;
   color       m_clrDisable;
   color       m_clrChecked;

   string      m_labelName;
   string      m_objBtnBoxName;

 public:
   UIInputCheckbox() {}
   ~UIInputCheckbox() { DeleteAllObject(); }

   bool GetValue() const { return m_checked; }

   void SetListener(UIListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_parent   = ctx;
   }

   void Initialize(long chartId, string name) {
      m_chartId    = chartId;
      m_name       = name;

      m_fontSize   = 10;

      m_clrNormal  = clrWhite;
      m_clrDisable = clrWhite + 0xadadad;
      m_clrChecked = clrLightBlue;

      // Tạo tên object dựa trên tên control để đảm bảo uniqueness
      m_labelName     = "Obj_" + name + "_Label";
      m_objBtnBoxName = "Obj_" + name + "_Box";
   }

   int GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 2);
      objNameList[0] = m_labelName;
      objNameList[1] = m_objBtnBoxName;
      return 2;
   }

   void SetValue(bool checked) { m_checked = checked; };
   void SetLabel(string text) { m_labelText = text; }
   void SetDisabled(bool isDisabled) { m_isDisabled = isDisabled; }
   void SetFontSize(int fontSize) { m_fontSize = fontSize; }
   void SetZOrderBase(int zOrder) { m_zOrderBase = zOrder; }

   void RefreshColor() {
      ObjectSetString(m_chartId, m_objBtnBoxName, OBJPROP_TEXT, m_checked ? "þ" : "");
      if(m_isDisabled) {
         ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_clrDisable);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BGCOLOR, m_clrDisable);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_COLOR, m_clrDisable);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BORDER_COLOR, m_clrDisable);
      } else if(m_checked) {
         ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_clrChecked);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BGCOLOR, clrNONE);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_COLOR, m_clrChecked);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BORDER_COLOR, m_clrChecked);
      } else {
         ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_clrNormal);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BGCOLOR, clrNONE);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_COLOR, m_clrNormal);
         ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BORDER_COLOR, m_clrNormal);
      }
   }

   void UpdateValue(bool value) {
      if(m_checked != value) {
         m_checked = value;
         RefreshColor();
      }
   };
   void UpdateLabel(string text) {
      m_labelText = text;
      ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);
   }

   void UpdateDisabled(bool isDisabled) {
      m_isDisabled = isDisabled;
      RefreshColor();
   }

   void EmitValue() {
      int valueInt = m_checked ? 1 : 0;
      if(m_listener != NULL) {
         m_listener.listen(&this, UI_EVENT_CHANGE_VALUE, m_checked);
      }
      if(m_callback != NULL) {
         m_callback(m_parent, UI_EVENT_CHANGE_VALUE, valueInt);
      }
   }

   void DeleteAllObject() {
      ObjectDelete(m_chartId, m_labelName);
      ObjectDelete(m_chartId, m_objBtnBoxName);
   }

   void StartDraw(int x, int y, int fontSize = 10);
   void ClickBtnCheckbox();
   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();
};

void UIInputCheckbox::StartDraw(int x, int y, int fontSize) {
   m_x           = x;
   m_y           = y;
   m_fontSize    = fontSize;

   color clrInit = m_clrNormal;
   if(m_isDisabled) {
      clrInit = m_clrDisable;
   } else if(m_checked) {
      clrInit = m_clrChecked;
   }

   // Create button
   if(!ObjectCreate(m_chartId, m_objBtnBoxName, OBJ_BUTTON, 0, 0, 0)) {
      Print("Failed to create button: ", m_objBtnBoxName, " Error: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_XSIZE, m_fontSize + 4);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_YSIZE, m_fontSize + 4);

   ObjectSetString(m_chartId, m_objBtnBoxName, OBJPROP_FONT, "Wingdings");
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_FONTSIZE, m_fontSize + 4);
   ObjectSetString(m_chartId, m_objBtnBoxName, OBJPROP_TEXT, m_checked ? "þ" : "");
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_COLOR, clrInit);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BORDER_COLOR, clrInit);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BGCOLOR, clrNONE);

   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_ZORDER, m_zOrderBase);

   // Create label
   if(!ObjectCreate(m_chartId, m_labelName, OBJ_LABEL, 0, 0, 0)) {
      Print("Failed to create label: ", m_labelName, " Error: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_XDISTANCE, m_x + m_fontSize + 4 + 4);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_YDISTANCE, m_y);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, clrInit);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ZORDER, m_zOrderBase);
}

void UIInputCheckbox::ClickBtnCheckbox() {
   ObjectSetInteger(m_chartId, m_objBtnBoxName, OBJPROP_STATE, false);
   if(!m_isDisabled) {
      UpdateValue(!m_checked);
      EmitValue();
   }
}

void UIInputCheckbox::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_objBtnBoxName || sparam == m_labelName) {
         ClickBtnCheckbox();
      }
   }
}

void UIInputCheckbox::OnStrategyTesterEvent() {
   if(ObjectGetInteger(m_chartId, m_objBtnBoxName, OBJPROP_STATE)) {
      ClickBtnCheckbox();
   }
}

#endif
