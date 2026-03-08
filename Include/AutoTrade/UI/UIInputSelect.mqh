//+------------------------------------------------------------------+
//|                                                UIInputSelect.mqh |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 06.03.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#ifndef __UI_INPUT_SELECT_MQH__
#define __UI_INPUT_SELECT_MQH__

#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"

#include <AutoTrade/UI/UIDefines.mqh>

struct UIInputSelectOption {
   string label;
   double value;
};

class UIInputSelect {
 private:
   UIInputListener    *m_listener;        // Pointer to the input listener
   FOnChange           m_callback;        // Callback function for value changes
   void               *m_context;         // Context for the callback function

   long                m_chartId;         // Chart ID for the input control
   string              m_name;
   int                 m_x, m_y, m_width; // Position and size of the input control
   int                 m_fontSize;        // Font size for the input control
   double              m_value;           // Current value of the input control
   string              m_labelText;
   bool                m_isDisabled;
   bool                m_isShowOptions;
   int                 m_zOrderBase; // Z-order base for drawing objects of this control

   UIInputSelectOption m_options[];  // Array of options for the select input

   string              m_objLabelName;
   string              m_objBtnCurrentTextName;
   string              m_objBtnArrowName;

   color               m_labelTextColor;
   color               m_clrIpBg;
   color               m_clrIpBorder;
   color               m_clrIpText;
   color               m_clrIpArrowBg;
   color               m_clrOptionHover;
   color               m_clrOptionSelected;

 public:
   UIInputSelect() {}
   ~UIInputSelect() { DestroyDraw(); }
   void DestroyDraw() {
      string objNameList[];
      int    countObject = GetObjectNameList(objNameList);
      for(int i = 0; i < countObject; i++) {
         ObjectDelete(m_chartId, objNameList[i]);
      }
   }

   void SetListener(UIInputListener *listener) { m_listener = listener; }
   void SetCallback(void *context, FOnChange callback) {
      m_context  = context;
      m_callback = callback;
   }

   void Initialize(long chartId, string name) {
      m_chartId               = chartId;
      m_name                  = name;

      m_fontSize              = 10;
      m_value                 = 0;
      m_labelText             = "";
      m_isDisabled            = false;
      m_isShowOptions         = false;
      m_zOrderBase            = 0;

      m_objLabelName          = "Obj_" + m_name + "_Label";
      m_objBtnCurrentTextName = "Obj_" + m_name + "_BtnCurrentText";
      m_objBtnArrowName       = "Obj_" + m_name + "_BtnArrow";

      // clang-format off
      m_labelTextColor        = clrBlack;
      m_clrIpBg               = C'245,245,245';
      m_clrIpBorder           = C'160,160,160';
      m_clrIpText             = C'30,30,30';
      m_clrIpArrowBg          = C'210,215,220';
      m_clrOptionHover        = C'210,230,255';
      m_clrOptionSelected     = C'210,215,220';
      // clang-format on
   };

   string GetOptionObjectName(int index) {
      if(index < 0 || index >= ArraySize(m_options)) {
         return "";
      }
      return "Obj_" + m_name + "_Option_" + IntegerToString(index);
   }

   int GetObjectNameList(string &objNameList[]) {
      int count        = 0;
      int optionsCount = ArraySize(m_options);

      ArrayResize(objNameList, 3 + optionsCount);
      objNameList[count++] = m_objLabelName;
      objNameList[count++] = m_objBtnCurrentTextName;
      objNameList[count++] = m_objBtnArrowName;

      for(int i = 0; i < optionsCount; i++) {
         objNameList[count++] = GetOptionObjectName(i);
      }
      return count;
   }

   void SetFontSize(int size) { m_fontSize = size; }
   void SetValue(double value) { m_value = value; }
   void SetDisabled(bool isDisabled) { m_isDisabled = isDisabled; }
   void SetLabel(string labelText, color labelTextColor = clrNONE) {
      m_labelText = labelText;
      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
      }
   }
   void SetZOrderBase(int zOrder) { m_zOrderBase = zOrder; }

   bool UpdateValue(double newValue) {
      if(m_value == newValue)
         return true;

      bool success = false;
      for(int i = 0; i < ArraySize(m_options); i++) {
         string currentObjName = GetOptionObjectName(i);
         if(m_options[i].value == newValue) {
            ObjectSetString(m_chartId, m_objBtnCurrentTextName, OBJPROP_TEXT, m_options[i].label);
            ObjectSetInteger(m_chartId, currentObjName, OBJPROP_BGCOLOR, m_clrOptionSelected);
            success = true;
         } else {
            ObjectSetInteger(m_chartId, currentObjName, OBJPROP_BGCOLOR, m_clrIpBg);
         }
      }
      if(success) {
         m_value = newValue;
      }
      return success;
   }

   void OnChangeValue() {
      if(m_listener != NULL) {
         m_listener.onChangeValue(m_value);
      }
      if(m_callback != NULL) {
         m_callback(m_context, UI_EVENT_CHANGE_VALUE, m_value);
      }
   }

   void AddOption(double value, string label) {
      int optionCount = ArraySize(m_options);
      ArrayResize(m_options, optionCount + 1);
      m_options[optionCount].label = label;
      m_options[optionCount].value = value;
   }

   void RemoveOption(int index) {
      for(int i = index; i < ArraySize(m_options) - 1; i++) {
         m_options[i] = m_options[i + 1];
      }
      ArrayResize(m_options, ArraySize(m_options) - 1);
   }

   void StartDraw(int x, int y, int width, int fontSize);
   void StartRedraw();
   void ShowOptions();
   void HideOptions();
   void ClickBtnCurrentText();
   void ClickBtnArrow();
   void ClickBtnOption(int index);
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void UIInputSelect::StartDraw(int x, int y, int width, int fontSize) {
   m_x                  = x;
   m_y                  = y;
   m_width              = width;
   m_fontSize           = fontSize;

   double rateSize      = 2.2;

   int    selectedIndex = -1;
   string currentText   = "Select";
   for(int i = 0; i < ArraySize(m_options); i++) {
      if(m_options[i].value == m_value) {
         selectedIndex = i;
         currentText   = m_options[i].label;
         break;
      }
   }

   int yOffset = 0;
   // Create label object
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
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_COLOR, m_labelTextColor);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, m_objLabelName, OBJPROP_ZORDER, m_zOrderBase + 0);

      yOffset += (int)(m_fontSize * 1.8); // Đặt cách label một khoảng theo chiều dọc
   }

   // Create button object for the select input
   if(!ObjectCreate(m_chartId, m_objBtnCurrentTextName, OBJ_BUTTON, 0, 0, 0)) {
      Print("Failed to create button object: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_YDISTANCE, (int)(m_y + yOffset));
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_XSIZE, m_width - m_fontSize * 2);

   ObjectSetInteger(
      m_chartId,
      m_objBtnCurrentTextName,
      OBJPROP_YSIZE,
      (int)(m_fontSize * rateSize)
   );
   ObjectSetString(m_chartId, m_objBtnCurrentTextName, OBJPROP_TEXT, currentText);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_COLOR, m_clrIpText);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_BORDER_COLOR, m_clrIpBorder);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_BGCOLOR, m_clrIpBg);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_ZORDER, m_zOrderBase + 0);

   // Create button objects for arrow, display in the right of the select button
   if(!ObjectCreate(m_chartId, m_objBtnArrowName, OBJ_BUTTON, 0, 0, 0)) {
      Print("Failed to create button object for arrow: ", GetLastError());
      return;
   }
   ObjectSetInteger(
      m_chartId,
      m_objBtnArrowName,
      OBJPROP_XDISTANCE,
      m_x + m_width - m_fontSize * 2
   );
   ObjectSetInteger(
      m_chartId,
      m_objBtnArrowName,
      OBJPROP_YDISTANCE,
      (int)(m_y + yOffset)
   ); // Đặt cùng hàng với nút select
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_XSIZE, (int)(m_fontSize * 2));
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_YSIZE, (int)(m_fontSize * rateSize));
   ObjectSetString(m_chartId, m_objBtnArrowName, OBJPROP_TEXT, m_isShowOptions ? "▲" : "▼");
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_FONTSIZE, (int)(m_fontSize * 0.8));
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_COLOR, m_clrIpText);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_BORDER_COLOR, m_clrIpBorder);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_BGCOLOR, m_clrIpArrowBg);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_ZORDER, m_zOrderBase + 0);

   yOffset += (int)(m_fontSize * rateSize); // Đặt cách nút select một khoảng theo chiều dọc

   // Draw options
   for(int i = 0; i < ArraySize(m_options); i++) {
      string optionObjName = GetOptionObjectName(i);
      if(!ObjectCreate(m_chartId, optionObjName, OBJ_BUTTON, 0, 0, 0)) {
         Print("Failed to create button object for option: ", GetLastError());
         return;
      }
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(
         m_chartId,
         optionObjName,
         OBJPROP_YDISTANCE,
         (int)(m_y + yOffset + i * m_fontSize * rateSize)
      );
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_YSIZE, (int)(m_fontSize * rateSize));
      ObjectSetString(m_chartId, optionObjName, OBJPROP_TEXT, m_options[i].label);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_FONTSIZE, m_fontSize);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_COLOR, m_clrIpText);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_BORDER_COLOR, m_clrIpBorder);
      ObjectSetInteger(
         m_chartId,
         optionObjName,
         OBJPROP_BGCOLOR,
         i == selectedIndex ? m_clrOptionSelected : m_clrIpBg
      );
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(
         m_chartId,
         optionObjName,
         OBJPROP_ZORDER,
         m_zOrderBase + 10
      ); // Đặt z-order cao hơn để hiển thị trên nút
      ObjectSetInteger(
         m_chartId,
         optionObjName,
         OBJPROP_TIMEFRAMES,
         m_isShowOptions ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
      );
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_ZORDER, m_zOrderBase + 10000);
   }
}

void UIInputSelect::StartRedraw() {
   DestroyDraw(); // Xóa các đối tượng cũ trước khi vẽ lại
   StartDraw(m_x, m_y, m_width, m_fontSize); // Vẽ lại với cùng vị trí và kích thước
}

void UIInputSelect::ShowOptions() {
   m_isShowOptions = true;
   ObjectSetString(m_chartId, m_objBtnArrowName, OBJPROP_TEXT, "▲");
   for(int i = 0; i < ArraySize(m_options); i++) {
      string optionObjName = GetOptionObjectName(i);
      ObjectSetInteger(m_chartId, optionObjName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   ChartRedraw(m_chartId);
}

void UIInputSelect::HideOptions() {
   if(m_isShowOptions) {
      m_isShowOptions = false;
      ObjectSetString(m_chartId, m_objBtnArrowName, OBJPROP_TEXT, "▼");
      for(int i = 0; i < ArraySize(m_options); i++) {
         string optionObjName = GetOptionObjectName(i);
         ObjectSetInteger(m_chartId, optionObjName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
      }
      ChartRedraw(m_chartId);
   }
}

void UIInputSelect::ClickBtnCurrentText() {
   ObjectSetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_STATE, false);
   if(!m_isShowOptions) {
      ShowOptions();
   } else {
      HideOptions();
   }
}

void UIInputSelect::ClickBtnArrow() {
   ObjectSetInteger(m_chartId, m_objBtnArrowName, OBJPROP_STATE, false);
   if(!m_isShowOptions) {
      ShowOptions();
   } else {
      HideOptions();
   }
}

void UIInputSelect::ClickBtnOption(int index) {
   string selectedoptionObjName = GetOptionObjectName(index);
   ObjectSetInteger(m_chartId, selectedoptionObjName, OBJPROP_STATE, false);
   if(index < 0 || index >= ArraySize(m_options)) {
      return;
   }
   m_value = m_options[index].value;
   ObjectSetString(m_chartId, m_objBtnCurrentTextName, OBJPROP_TEXT, m_options[index].label);

   for(int i = 0; i < ArraySize(m_options); i++) {
      string currentObjName = GetOptionObjectName(i);
      if(m_options[i].value == m_value) {
         ObjectSetInteger(m_chartId, selectedoptionObjName, OBJPROP_BGCOLOR, m_clrOptionSelected);
      } else {
         ObjectSetInteger(m_chartId, currentObjName, OBJPROP_BGCOLOR, m_clrIpBg);
      }
   }

   HideOptions();   // Ẩn options sau khi chọn
   ChartRedraw(m_chartId);
   OnChangeValue(); // Gọi sự kiện thay đổi giá trị
}

void UIInputSelect::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_objBtnCurrentTextName) {
         ClickBtnCurrentText();
         return;
      }
      if(sparam == m_objBtnArrowName) {
         ClickBtnArrow();
         return;
      }
      for(int i = 0; i < ArraySize(m_options); i++) {
         if(sparam == GetOptionObjectName(i)) {
            ClickBtnOption(i);
            return;
         }
      }
      HideOptions(); // Ẩn options khi click ra ngoài
   }
}

void UIInputSelect::OnMQLTesterEvent() {
   if(ObjectGetInteger(m_chartId, m_objBtnCurrentTextName, OBJPROP_STATE)) {
      ClickBtnCurrentText();
   }
   if(ObjectGetInteger(m_chartId, m_objBtnArrowName, OBJPROP_STATE)) {
      ClickBtnArrow();
   }
   for(int i = 0; i < ArraySize(m_options); i++) {
      if(ObjectGetInteger(m_chartId, GetOptionObjectName(i), OBJPROP_STATE)) {
         ClickBtnOption(i);
         break;
      }
   }
}

#endif // __UI_INPUT_SELECT_MQH__