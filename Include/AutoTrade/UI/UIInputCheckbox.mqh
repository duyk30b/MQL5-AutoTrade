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

class UIInputCheckboxListener {
 public:
   virtual void onChangeValue(bool newValue) = 0;
};

class UIInputCheckbox {
 private:
   UIInputCheckboxListener *m_listener;
   FOnChange                m_callback;
   void                    *m_context;        // lưu pointer đến object chủ

   long                     m_chartId;        // ID của chart
   string                   m_name;           // Tên unique cho control
   int                      m_x;              // Vị trí X
   int                      m_y;              // Vị trí Y
   int                      m_fontSize;       // Kích thước font chữ label
   bool                     m_value;          // Giá trị hiện tại (true/false)
   string                   m_labelText;      // Text label (nếu có)
   int                      m_zOrderBase;

   color                    m_labelTextColor; // Màu label
   color                    m_normalBoxColor; // Màu dấu check
   color                    m_checkBoxColor;  // Màu dấu check

   string                   m_labelName;
   string                   m_btnBoxName;

 public:
   UIInputCheckbox() {}
   ~UIInputCheckbox() { Destroy(); }

   bool GetValue() const { return m_value; }

   void SetListener(UIInputCheckboxListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_context  = ctx;
   }

   void Initialize(long chartId, string name) {
      m_chartId        = chartId;
      m_name           = name;

      m_fontSize       = 10;

      m_labelTextColor = clrWhite;
      m_normalBoxColor = clrWhite;
      m_checkBoxColor  = clrLightBlue;

      // Tạo tên object dựa trên tên control để đảm bảo uniqueness
      m_labelName  = "Obj_" + name + "_Label";
      m_btnBoxName = "Obj_" + name + "_Box";
   }

   int GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 2);
      objNameList[0] = m_labelName;
      objNameList[1] = m_btnBoxName;
      return 2;
   }

   void SetValue(bool value) { m_value = value; };
   void SetLabel(string text, color labelTextColor = clrNONE) {
      m_labelText = text;
      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
      }
   }
   void SetFontSize(int fontSize) { m_fontSize = fontSize; }
   void SetZOrderBase(int zOrder) { m_zOrderBase = zOrder; }

   void UpdateValue(bool value) {
      if(m_value != value) {
         m_value = value;
         if(m_value) {
            ObjectSetString(m_chartId, m_btnBoxName, OBJPROP_TEXT, "þ");
            ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_COLOR, m_checkBoxColor);
            ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_BORDER_COLOR, m_checkBoxColor);
         } else {
            ObjectSetString(m_chartId, m_btnBoxName, OBJPROP_TEXT, "");
            ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_COLOR, m_normalBoxColor);
            ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_BORDER_COLOR, m_normalBoxColor);
         }
      }
   };
   void UpdateLabel(string text, color labelTextColor = clrNONE) {
      m_labelText = text;
      ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);

      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
         ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextColor);
      }
   }

   void OnChangeValue() {
      int valueInt = m_value ? 1 : 0;
      if(m_listener != NULL) {
         m_listener.onChangeValue(valueInt);
      }
      if(m_callback != NULL) {
         m_callback(m_context, UI_EVENT_CHANGE_VALUE, valueInt);
      }
   }

   void Destroy() {
      ObjectDelete(m_chartId, m_labelName);
      ObjectDelete(m_chartId, m_btnBoxName);
   }

   void StartDraw(int x, int y, int fontSize = 10);
   void ClickBtnCheckbox();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void UIInputCheckbox::StartDraw(int x, int y, int fontSize) {
   m_x        = x;
   m_y        = y;
   m_fontSize = fontSize;

   // Create button
   ObjectCreate(m_chartId, m_btnBoxName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_XSIZE, m_fontSize + 4);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_YSIZE, m_fontSize + 4);

   ObjectSetString(m_chartId, m_btnBoxName, OBJPROP_FONT, "Wingdings");
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_FONTSIZE, m_fontSize + 4);
   ObjectSetString(m_chartId, m_btnBoxName, OBJPROP_TEXT, m_value ? "þ" : "");
   ObjectSetInteger(
      m_chartId,
      m_btnBoxName,
      OBJPROP_COLOR,
      m_value ? m_checkBoxColor : m_normalBoxColor
   );
   ObjectSetInteger(
      m_chartId,
      m_btnBoxName,
      OBJPROP_BORDER_COLOR,
      m_value ? m_checkBoxColor : m_normalBoxColor
   );
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_BGCOLOR, clrNONE);

   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_ZORDER, m_zOrderBase);

   // Create label
   ObjectCreate(m_chartId, m_labelName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_XDISTANCE, m_x + m_fontSize + 4 + 4);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_YDISTANCE, m_y);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextColor);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ZORDER, m_zOrderBase);
}

void UIInputCheckbox::ClickBtnCheckbox() {
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_STATE, false);
   UpdateValue(!m_value);
   OnChangeValue();
}

void UIInputCheckbox::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_btnBoxName || sparam == m_labelName) {
         ClickBtnCheckbox();
      }
   }
}

void UIInputCheckbox::OnMQLTesterEvent() {
   if(ObjectGetInteger(m_chartId, m_btnBoxName, OBJPROP_STATE)) {
      ClickBtnCheckbox();
   }
}

#endif
