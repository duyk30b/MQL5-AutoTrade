//+------------------------------------------------------------------+
//|                                                   UICheckbox.mqh |
//|                               Copyright 2026, UICheckbox Library |
//|                                                 https://mql5.com |
//| 16.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#ifndef UI_CHECKBOX_MQH
#define UI_CHECKBOX_MQH

#property copyright "Copyright 2026, UICheckbox Library"
#property link "https://mql5.com"
#property version "1.00"

#include <AutoTrade/UI/UIDefines.mqh>

class UICheckboxListener {
 public:
   virtual void onChangeValue(bool newValue) = 0;
};

class UICheckbox {
 private:
   UICheckboxListener *m_listener;
   FOnChange           m_callback;
   void               *m_context;        // lưu pointer đến object chủ

   long                m_chartId;        // ID của chart
   string              m_name;           // Tên unique cho control
   int                 m_x;              // Vị trí X
   int                 m_y;              // Vị trí Y
   int                 m_size;           // Kích thước checkbox (chiều rộng và chiều cao)
   int                 m_fontSize;       // Kích thước font chữ label
   bool                m_value;          // Giá trị hiện tại (true/false)
   string              m_labelText;      // Text label (nếu có)

   color               m_labelTextColor; // Màu label
   color               m_normalBoxColor; // Màu dấu check
   color               m_checkBoxColor;  // Màu dấu check

   string              m_labelName;
   string              m_btnBoxName;

 public:
   UICheckbox() {}
   ~UICheckbox() { Destroy(); }

   bool GetValue() const { return m_value; }

   void SetListener(UICheckboxListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_context  = ctx;
   }

   void Initialization(long chartId, string name) {
      m_chartId        = chartId;
      m_name           = name;

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

   void OnChangeValue(double value) {
      if(m_listener != NULL) {
         m_listener.onChangeValue(m_value);
      }
      if(m_callback != NULL) {
         m_callback(m_context, UI_EVENT_CHANGE_VALUE, m_value);
      }
   }

   void Destroy() {
      ObjectDelete(m_chartId, m_labelName);
      ObjectDelete(m_chartId, m_btnBoxName);
   }

   void StartDraw(int x, int y, bool value, string labelText, int fontSize = 10);
   void ClickBtnCheckbox();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void UICheckbox::StartDraw(int x, int y, bool value, string labelText, int fontSize = 10) {
   m_x         = x;
   m_y         = y;
   m_size      = fontSize + 4; // Kích thước checkbox dựa trên font size để đảm bảo cân đối
   m_value     = value;
   m_labelText = labelText;
   m_fontSize  = fontSize;

   // Create button
   ObjectCreate(m_chartId, m_btnBoxName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_XSIZE, m_size);
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_YSIZE, m_size);

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
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_ZORDER, 100);

   // Create label
   ObjectCreate(m_chartId, m_labelName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_XDISTANCE, m_x + m_size + 5);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_YDISTANCE, m_y);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);
   ObjectSetString(m_chartId, m_labelName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextColor);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ZORDER, 102);
}

void UICheckbox::ClickBtnCheckbox() {
   ObjectSetInteger(m_chartId, m_btnBoxName, OBJPROP_STATE, false);
   UpdateValue(!m_value);
   OnChangeValue(m_value);
}

void UICheckbox::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_btnBoxName || sparam == m_labelName) {
         ClickBtnCheckbox();
      }
   }
}

void UICheckbox::OnMQLTesterEvent() {
   bool btnSettingState = ObjectGetInteger(m_chartId, m_btnBoxName, OBJPROP_STATE);
   if(btnSettingState) {
      ClickBtnCheckbox();
   }
}

#endif
