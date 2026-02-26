//+------------------------------------------------------------------+
//|                                                   UIInputRadio.mqh |
//|                               Copyright 2026, UIInputRadio Library |
//|                                                 https://mql5.com |
//| 16.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#ifndef UI_INPUT_RADIO_MQH
#define UI_INPUT_RADIO_MQH

#property copyright "Copyright 2026, UIInputRadio Library"
#property link "https://mql5.com"
#property version "1.00"

#include <AutoTrade/UI/UIDefines.mqh>

class UIInputRadioListener {
 public:
   virtual void onChangeChecked(double checked) = 0;
};

class UIInputRadio {
 private:
   UIInputRadioListener *m_listener;
   FOnChange             m_callback;
   void                 *m_context;      // lưu pointer đến object chủ

   long                  m_chartId;      // ID của chart
   string                m_name;         // Tên unique cho control
   int                   m_x;            // Vị trí X
   int                   m_y;            // Vị trí Y
   int                   m_fontSize;     // Kích thước font chữ label
   int                   m_value;        // Giá trị hiện tại
   bool                  m_checked;      // Trạng thái checked của radio button
   string                m_label;        // Text label (nếu có)

   color                 m_normalColor;  // Màu normal
   color                 m_checkedColor; // Màu dấu check

   string                m_labelName;
   string                m_btnRadioName;

 public:
   UIInputRadio() {}
   ~UIInputRadio() { Destroy(); }

   void SetListener(UIInputRadioListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_context  = ctx;
   }

   void Initialization(long chartId, string name) {
      m_chartId      = chartId;
      m_name         = name;

      m_fontSize     = 10;
      m_label        = "";

      m_normalColor  = clrWhite;
      m_checkedColor = clrWhite;

      // Tạo tên object dựa trên tên control để đảm bảo uniqueness
      m_labelName    = "Obj_" + name + "_Label";
      m_btnRadioName = "Obj_" + name + "_Radio";
   }
   int GetValue() const { return m_value; }
   int GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 2);
      objNameList[0] = m_labelName;
      objNameList[1] = m_btnRadioName;
      return 2;
   }

   void SetValue(int value) { m_value = value; };
   void SetChecked(bool checked) { m_checked = checked; };
   void SetLabel(string label) { m_label = label; }

   void UpdateChecked(bool checked) {
      if(m_checked != checked) {
         m_checked = checked;
         if(m_checked) {
            ObjectSetString(m_chartId, m_btnRadioName, OBJPROP_TEXT, "l");
            ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_COLOR, m_checkedColor);
            ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_BORDER_COLOR, m_checkedColor);
         } else {
            ObjectSetString(m_chartId, m_btnRadioName, OBJPROP_TEXT, "");
            ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_COLOR, m_normalColor);
            ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_BORDER_COLOR, m_normalColor);
         }
      }
   };

   void OnChangeChecked() {
      if(m_listener != NULL) {
         m_listener.onChangeChecked(m_value);
      }
      if(m_callback != NULL) {
         if(m_checked) {
            m_callback(m_context, UI_EVENT_CHANGE_VALUE, m_value);
         } else {
            m_callback(m_context, UI_EVENT_CHANGE_VALUE, -1);
         }
      }
   }

   void Destroy() {
      string objNameList[];
      int    countObject = GetObjectNameList(objNameList);
      for(int i = 0; i < countObject; i++) {
         ObjectDelete(m_chartId, objNameList[i]);
      }
   }

   void StartDraw(int x, int y, string label, int fontSize = 10) {
      m_x        = x;
      m_y        = y;
      m_label    = label;
      m_fontSize = fontSize;

      // Create button
      ObjectCreate(m_chartId, m_btnRadioName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_YDISTANCE, m_y + m_fontSize / 8);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_XSIZE, m_fontSize + 4);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_YSIZE, m_fontSize + 4);

      ObjectSetString(m_chartId, m_btnRadioName, OBJPROP_FONT, "Wingdings");
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_FONTSIZE, m_fontSize + 2);
      ObjectSetString(m_chartId, m_btnRadioName, OBJPROP_TEXT, m_checked ? "l" : "");
      ObjectSetInteger(
         m_chartId,
         m_btnRadioName,
         OBJPROP_COLOR,
         m_checked ? m_checkedColor : m_normalColor
      );
      ObjectSetInteger(
         m_chartId,
         m_btnRadioName,
         OBJPROP_BORDER_COLOR,
         m_checked ? m_checkedColor : m_normalColor
      );
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_BGCOLOR, clrNONE);

      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_ZORDER, 100);

      // Create label
      ObjectCreate(m_chartId, m_labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(
         m_chartId,
         m_labelName,
         OBJPROP_XDISTANCE,
         m_x + m_fontSize + 4 + m_fontSize / 2
      );
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_YDISTANCE, m_y);
      ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_label);
      ObjectSetString(m_chartId, m_labelName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_FONTSIZE, m_fontSize);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_normalColor);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_HIDDEN, false);
      ObjectSetInteger(m_chartId, m_labelName, OBJPROP_ZORDER, 102);
   };
   void ClickBtnRadio() {
      ObjectSetInteger(m_chartId, m_btnRadioName, OBJPROP_STATE, false);
      UpdateChecked(!m_checked);
      OnChangeChecked();
   };
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      if(id == CHARTEVENT_OBJECT_CLICK) {
         if(sparam == m_btnRadioName || sparam == m_labelName) {
            ClickBtnRadio();
         }
      }
   };
   void OnMQLTesterEvent() {
      bool btnSettingState = ObjectGetInteger(m_chartId, m_btnRadioName, OBJPROP_STATE);
      if(btnSettingState) {
         ClickBtnRadio();
      }
   };
};

class UIInputRadioGroup {
 public:
   FOnChange     m_callback;
   void         *m_context;       // lưu pointer đến object chủ
   UIInputRadio *m_ipRadioList[]; // Danh sách các inputRadio trong nhóm
   int           m_value;

   void          SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_context  = ctx;
   }
   int  GetValue() const { return m_value; }
   void SetValue(int value) { m_value = value; };
   int  GetObjectNameList(string &objNameList[]) {
      int totalObj = 0;
      for(int i = 0; i < ArraySize(m_ipRadioList); i++) {
         string radioObjNameList[];
         int    radioObjCount = m_ipRadioList[i].GetObjectNameList(radioObjNameList);
         ArrayResize(objNameList, totalObj + radioObjCount);
         for(int j = 0; j < radioObjCount; j++) {
            objNameList[totalObj++] = radioObjNameList[j];
         }
      }
      return totalObj;
   }

   void UpdateValue(int value) {
      m_value = value;
      for(int i = 0; i < ArraySize(m_ipRadioList); i++) {
         if(m_ipRadioList[i].GetValue() != m_value) {
            m_ipRadioList[i].UpdateChecked(false);
         } else {
            m_ipRadioList[i].UpdateChecked(true);
         }
      }
      ChartRedraw(ChartID());
   };

   void AddInputRadio(UIInputRadio *inputRadio) {
      ArrayResize(m_ipRadioList, ArraySize(m_ipRadioList) + 1);
      m_ipRadioList[ArraySize(m_ipRadioList) - 1] = inputRadio;
      inputRadio.SetCallback(&this, OnChangeChecked);
   }

   static void OnChangeChecked(void *context, UI_EVENT_TYPE type, double value) {
      UIInputRadioGroup *group = (UIInputRadioGroup *)context;

      if(type == UI_EVENT_CHANGE_VALUE) {
         group.m_value = (int)value;
         for(int i = 0; i < ArraySize(group.m_ipRadioList); i++) {
            if(group.m_ipRadioList[i].GetValue() == group.m_value) {
               group.m_ipRadioList[i].UpdateChecked(true);
            } else {
               group.m_ipRadioList[i].UpdateChecked(false);
            }
         }
         if(group.m_callback != NULL) {
            group.m_callback(group.m_context, type, value);
         }
      }
   }

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      if(id == CHARTEVENT_OBJECT_CLICK) {
         for(int i = 0; i < ArraySize(m_ipRadioList); i++) {
            m_ipRadioList[i].OnChartEvent(id, lparam, dparam, sparam);
         }
      }
   };
   void OnMQLTesterEvent() {
      for(int i = 0; i < ArraySize(m_ipRadioList); i++) {
         m_ipRadioList[i].OnMQLTesterEvent();
      }
   }
};
#endif
