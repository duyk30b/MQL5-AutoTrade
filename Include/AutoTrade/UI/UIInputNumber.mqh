//+------------------------------------------------------------------+
//|                                              UIInputNumber.mqh   |
//+------------------------------------------------------------------+
#ifndef UI_INPUT_NUMBER_MQH
#define UI_INPUT_NUMBER_MQH

#property copyright "UIInputNumber Library"
#property version "1.00"

#include <AutoTrade/UI/UIDefines.mqh>

//+------------------------------------------------------------------+
//| Class UIInputNumber                                              |
//+------------------------------------------------------------------+

class UIInputNumberListener {
 public:
   virtual void onChangeValue(double newValue) = 0;
};

class UIInputNumber {
 private:
   UIInputNumberListener *m_listener;
   FOnChange              m_callback;
   void                  *m_context;   // lưu pointer đến object chủ

   long                   m_chartId;   // ID của chart
   string                 m_name;      // Tên unique cho control
   int                    m_x;         // Vị trí X
   int                    m_y;         // Vị trí Y
   int                    m_width;     // Chiều rộng input
   int                    m_height;    // Chiều cao
   int                    m_fontSize;  // Kích thước font
   double                 m_value;     // Giá trị hiện tại
   string                 m_labelText; // Text label (nếu có)
   double                 m_step;      // Bước nhảy
   int                    m_digits;    // Số chữ số thập phân
   double                 m_minValue;  // Giá trị min
   double                 m_maxValue;  // Giá trị max
   double                 m_stepSetting;
   int                    m_digitsSetting;

   bool                   m_isDisabled;
   bool                   m_isTester;    // Có đang chạy ở môi trường tester không

   bool                   m_isOpenPopup; // Có hiển thị popup setting không

   // Kích thước các thành phần
   int m_labelHeight;
   int m_inputHeight;
   int m_buttonWidth;
   int m_inputWidth;

   // Màu sắc
   color m_labelTextColor;  // Màu label
   color m_buttonTextColor; // Màu button
   color m_buttonBgColor;   // Màu button
   color m_borderColor;     // Màu button

   // Tên các object
   string m_btnMinusName;
   string m_inputName;
   string m_btnPlusName;
   string m_btnSettingName;
   string m_labelName;

   string m_popupBgName;
   string m_popupHeaderName;
   string m_popupTitleName;
   string m_popupLabelStepName;
   string m_popupInputStepName;
   string m_popupBtnIncreaseStepName;
   string m_popupBtnDecreaseStepName;
   string m_popupLabelDigitsName;
   string m_popupInputDigitsName;
   string m_popupBtnIncreaseDigitsName;
   string m_popupBtnDecreaseDigitsName;
   string m_popupBtnOkName;
   string m_popupBtnCancelName;

 public:
   UIInputNumber() {}
   ~UIInputNumber() { Destroy(); }

   void SetListener(UIInputNumberListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_context  = ctx;
   }

   void Initialization(long chartId, string name) {
      m_chartId     = chartId;
      m_name        = name;
      m_fontSize    = 10;
      m_value       = 0;
      m_labelText   = "";
      m_step        = 1.0;
      m_digits      = 2;
      m_minValue    = -DBL_MAX;
      m_maxValue    = DBL_MAX;
      m_isDisabled  = false;
      m_isOpenPopup = false;

      if((bool)MQLInfoInteger(MQL_TESTER) || (bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
         m_isTester = true;
      } else {
         m_isTester = false;
      }

      m_labelTextColor  = clrBlack;
      m_buttonTextColor = clrBlack;
      m_buttonBgColor   = clrLightGray;
      m_borderColor     = clrDarkGray;

      // Tạo tên các object
      m_labelName                  = "Obj_" + m_name + "_Label";
      m_btnMinusName               = "Obj_" + m_name + "_BtnMinus";
      m_inputName                  = "Obj_" + m_name + "_Input";
      m_btnPlusName                = "Obj_" + m_name + "_BtnPlus";
      m_btnSettingName             = "Obj_" + m_name + "_BtnSetting";

      m_popupBgName                = "Obj_" + m_name + "_PopupBG";
      m_popupHeaderName            = "Obj_" + m_name + "_PopupHeader";
      m_popupTitleName             = "Obj_" + m_name + "_PopupTitle";
      m_popupLabelStepName         = "Obj_" + m_name + "_PopupLabelStep";
      m_popupInputStepName         = "Obj_" + m_name + "_PopupInputStep";
      m_popupBtnIncreaseStepName   = "Obj_" + m_name + "_PopupBtnIncreaseStep";
      m_popupBtnDecreaseStepName   = "Obj_" + m_name + "_PopupBtnDecreaseStep";
      m_popupLabelDigitsName       = "Obj_" + m_name + "_PopupLabelDigits";
      m_popupInputDigitsName       = "Obj_" + m_name + "_PopupInputDigits";
      m_popupBtnIncreaseDigitsName = "Obj_" + m_name + "_PopupBtnIncreaseDigits";
      m_popupBtnDecreaseDigitsName = "Obj_" + m_name + "_PopupBtnDecreaseDigits";
      m_popupBtnOkName             = "Obj_" + m_name + "_PopupBtnOk";
      m_popupBtnCancelName         = "Obj_" + m_name + "_PopupBtnCancel";
   }

   // Getters
   int    GetWidth() { return m_width; }
   int    GetHeight() { return m_height; }
   double GetValue() { return m_value; }
   double GetStep() { return m_step; }
   double GetDigits() { return m_digits; }
   string GetName() { return m_name; }
   int    GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 5);
      objNameList[0] = m_labelName;
      objNameList[1] = m_btnMinusName;
      objNameList[2] = m_inputName;
      objNameList[3] = m_btnPlusName;
      objNameList[4] = m_btnSettingName;
      return 5;
   }

   // Setters
   void SetWidth(int width) { m_width = width; }
   void SetHeight(int height) { m_height = height; }
   void SetLabel(string text, color labelTextColor = clrNONE) {
      m_labelText = text;
      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
      }
   }
   void SetFontSize(int size) { m_fontSize = size; }
   void SetValue(double value) { m_value = value; }
   void SetDisabled(bool isDisabled) { m_isDisabled = isDisabled; }
   void SetStep(double step) { m_step = step; }
   void SetMinValue(double min) { m_minValue = min; }
   void SetMaxValue(double max) { m_maxValue = max; }
   void SetDigits(int digits) { m_digits = digits; }
   void SetButtonWidth(int width) { m_buttonWidth = width; }
   void SetButtonTextColor(color clr) { m_buttonTextColor = clr; }
   void SetButtonBgColor(color clr) { m_buttonBgColor = clr; }
   void SetBorderColor(color clr) { m_borderColor = clr; }
   void SetStepSetting(double stepSetting) {
      m_stepSetting  = stepSetting;
      int digitsStep = 0;
      if(m_stepSetting > 0) {
         digitsStep = (int)MathRound(-MathLog10(m_stepSetting));
         // Nếu value >= 1 thì không cần chữ số thập phân
         if(digitsStep < 0)
            digitsStep = 0;
      }

      ObjectSetString(
         m_chartId,
         m_popupInputStepName,
         OBJPROP_TEXT,
         DoubleToString(m_stepSetting, digitsStep)
      );
   }

   void SetDigitsSetting(int digitsSetting) {
      if(digitsSetting < 0) {
         m_digitsSetting = 0;
      } else if(digitsSetting > 10) {
         m_digitsSetting = 10;
      } else {
         m_digitsSetting = digitsSetting;
      }

      ObjectSetString(
         m_chartId,
         m_popupInputDigitsName,
         OBJPROP_TEXT,
         IntegerToString(m_digitsSetting)
      );
   }

   void UpdateValue(double value) {
      if(value != m_value) {
         if(value < m_minValue)
            m_value = m_minValue;
         else if(value > m_maxValue)
            m_value = m_maxValue;
         else
            m_value = NormalizeDouble(value, m_digits);
         string text = DoubleToString(m_value, m_digits);
         ObjectSetString(m_chartId, m_inputName, OBJPROP_TEXT, text);
      }
   }

   void UpdateDisabled(bool isDisabled) {
      m_isDisabled = isDisabled;
      ObjectSetInteger(
         m_chartId,
         m_inputName,
         OBJPROP_READONLY,
         m_isTester || m_isDisabled
      ); // Nếu đang ở tester hoặc bị disable thì input readonly

      if(m_isDisabled) {
         ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_inputName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_COLOR, clrDarkGray);
      } else {
         ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_COLOR, m_buttonTextColor);
         ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_COLOR, m_buttonTextColor);
         ObjectSetInteger(m_chartId, m_inputName, OBJPROP_COLOR, clrBlack);
         ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_COLOR, m_buttonTextColor);
      }
   }

   void UpdateLabel(string text, color labelTextColor = clrNONE) {
      m_labelText = text;
      ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);

      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
         ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextColor);
      }
   }

   void OnChangeValue() {
      if(m_listener != NULL) {
         m_listener.onChangeValue(m_value);
      }
      if(m_callback != NULL) {
         m_callback(m_context, UI_EVENT_CHANGE_VALUE, m_value);
      }
   }

   // Xóa control
   void Destroy() {
      ObjectDelete(m_chartId, m_btnMinusName);
      ObjectDelete(m_chartId, m_inputName);
      ObjectDelete(m_chartId, m_btnPlusName);
      ObjectDelete(m_chartId, m_btnSettingName);
      ObjectDelete(m_chartId, m_labelName);
      ObjectDelete(m_chartId, m_popupBgName);
      ObjectDelete(m_chartId, m_popupHeaderName);
      ObjectDelete(m_chartId, m_popupTitleName);
      ObjectDelete(m_chartId, m_popupLabelStepName);
      ObjectDelete(m_chartId, m_popupInputStepName);
      ObjectDelete(m_chartId, m_popupBtnIncreaseStepName);
      ObjectDelete(m_chartId, m_popupBtnDecreaseStepName);
      ObjectDelete(m_chartId, m_popupLabelDigitsName);
      ObjectDelete(m_chartId, m_popupInputDigitsName);
      ObjectDelete(m_chartId, m_popupBtnIncreaseDigitsName);
      ObjectDelete(m_chartId, m_popupBtnDecreaseDigitsName);
      ObjectDelete(m_chartId, m_popupBtnOkName);
      ObjectDelete(m_chartId, m_popupBtnCancelName);
   }
   void InputRedrawChart() { ChartRedraw(m_chartId); }

   void StartDraw(int x, int y, int width, int height);

   void StartOpenPopup();
   void StartClosePopup();

   // Xử lý sự kiện click
   void ClickBtnMinus();
   void ClickBtnPlus();
   void ClickBtnSetting();
   void ClickPopupBtnStepIncrease();
   void ClickPopupBtnStepDecrease();
   void ClickPopupBtnDigitsIncrease();
   void ClickPopupBtnDigitsDecrease();
   void ClickPopupBtnOk();
   void ClickPopupBtnCancel();

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();

 private:
   void CreateButton(string name, int x, int y, int width, int height, string text);
   void CreateLabel(string name, int x, int y, string text);
   void CreateInput(string name, int x, int y, int width, int height);
   void CreateRectangle(string name, int x, int y, int width, int height, color bgColor);

   void StartDrawPopupSetting();
};

void UIInputNumber::StartDraw(int x, int y, int width, int height) {
   m_x              = x;
   m_y              = y;
   m_width          = width;
   m_height         = height;
   m_labelHeight    = 18;
   m_inputHeight    = height - m_labelHeight;
   m_buttonWidth    = 30;
   m_inputWidth     = width - 2 * m_buttonWidth;

   int xOffsetPanel = m_x;
   int yOffsetPanel = m_y;

   // Create button setting (⚙)
   CreateButton(m_btnSettingName, xOffsetPanel, yOffsetPanel + 3, 10, 10, "[≡]");
   ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_FONTSIZE, 8);

   // Create label
   CreateLabel(m_labelName, xOffsetPanel + 15, yOffsetPanel, m_labelText);
   yOffsetPanel += m_labelHeight;

   // Create button giảm (-)
   CreateButton(m_btnMinusName, xOffsetPanel, yOffsetPanel, m_buttonWidth, m_inputHeight, "-");
   xOffsetPanel += m_buttonWidth;

   // Create ô input
   CreateInput(m_inputName, xOffsetPanel, yOffsetPanel, m_inputWidth, m_inputHeight);
   ObjectSetInteger(m_chartId, m_inputName, OBJPROP_READONLY, m_isTester || m_isDisabled);

   ObjectSetString(m_chartId, m_inputName, OBJPROP_TEXT, DoubleToString(m_value, m_digits));
   xOffsetPanel += m_inputWidth;

   // Create button tăng (+)
   CreateButton(m_btnPlusName, xOffsetPanel, yOffsetPanel, m_buttonWidth, m_inputHeight, "+");

   StartDrawPopupSetting();
   StartClosePopup();
}

void UIInputNumber::CreateButton(string name, int x, int y, int width, int height, string text) {
   ObjectCreate(m_chartId, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);

   ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
   ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, m_buttonTextColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, m_buttonBgColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_COLOR, m_borderColor);

   ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, name, OBJPROP_ZORDER, 100);
}

void UIInputNumber::CreateLabel(string name, int x, int y, string text) {
   ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
   ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, m_labelTextColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
}

void UIInputNumber::CreateInput(string name, int x, int y, int width, int height) {
   ObjectCreate(m_chartId, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);
   ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_COLOR, m_borderColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
}

void UIInputNumber::CreateRectangle(
   string name, int x, int y, int width, int height, color bgColor
) {
   ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_COLOR, clrDarkGray);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
}

void UIInputNumber::StartDrawPopupSetting() {
   int popupWidth      = 220;
   int popupHeight     = 230;
   int popupX          = m_x;
   int inputPopupWidth = 120;
   // Mặc định hiển thị popup ở trên input, nếu không đủ chỗ thì hiển thị ở dưới
   int popupY = m_y - popupHeight;
   if(popupY < 10) {
      popupY = m_y + m_height + 2;
   }

   int xPos = popupX + (popupWidth - m_buttonWidth * 2 - inputPopupWidth) / 2;

   // POPUP: Tạo background
   CreateRectangle(m_popupBgName, popupX, popupY, popupWidth, popupHeight, clrWhiteSmoke);
   ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_ZORDER, 1000);

   // POPUP: Create header
   CreateRectangle(m_popupHeaderName, popupX, popupY, popupWidth, 30, clrLightGray);
   ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_ZORDER, 1001);

   // POPUP: Create title
   CreateLabel(m_popupTitleName, xPos, popupY + 6, m_labelText);
   ObjectCreate(m_chartId, m_popupTitleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_ZORDER, 1002);

   // POPUP: Create label digits
   CreateLabel(m_popupLabelDigitsName, xPos, popupY + 45, "Setting Digits:");
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_ZORDER, 1002);

   // POPUP: Create button digits giảm (-)
   CreateButton(m_popupBtnDecreaseDigitsName, xPos, popupY + 65, m_buttonWidth, m_inputHeight, "-");
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_ZORDER, 1002);

   // POPUP: Create ô input digits
   CreateInput(
      m_popupInputDigitsName,
      xPos + m_buttonWidth,
      popupY + 65,
      inputPopupWidth,
      m_inputHeight
   );
   ObjectSetInteger(
      m_chartId,
      m_popupInputDigitsName,
      OBJPROP_READONLY,
      m_isTester || m_isDisabled
   );
   ObjectSetString(
      m_chartId,
      m_popupInputDigitsName,
      OBJPROP_TEXT,
      IntegerToString(m_digitsSetting)
   );
   ObjectSetInteger(m_chartId, m_popupInputDigitsName, OBJPROP_ZORDER, 1002);

   // POPUP: Create button digits tăng (+)
   CreateButton(
      m_popupBtnIncreaseDigitsName,
      xPos + m_buttonWidth + inputPopupWidth,
      popupY + 65,
      m_buttonWidth,
      m_inputHeight,
      "+"
   );
   ObjectCreate(m_chartId, m_popupBtnIncreaseDigitsName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(
      m_chartId,
      m_popupBtnIncreaseDigitsName,
      OBJPROP_XDISTANCE,
      xPos + m_buttonWidth + inputPopupWidth
   );
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_ZORDER, 1002);

   // POPUP: Create label step
   CreateLabel(m_popupLabelStepName, xPos, popupY + 110, "Setting Step:");
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_ZORDER, 1002);
   // POPUP: Create button step giảm (-)
   CreateButton(m_popupBtnDecreaseStepName, xPos, popupY + 130, m_buttonWidth, m_inputHeight, "-");
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_ZORDER, 1002);

   // POPUP: Create ô input step
   CreateInput(
      m_popupInputStepName,
      xPos + m_buttonWidth,
      popupY + 130,
      inputPopupWidth,
      m_inputHeight
   );
   ObjectSetInteger(
      m_chartId,
      m_popupInputDigitsName,
      OBJPROP_READONLY,
      m_isTester || m_isDisabled
   );
   ObjectSetInteger(m_chartId, m_popupInputStepName, OBJPROP_ZORDER, 1002);

   // POPUP: Create button step tăng (+)
   CreateButton(
      m_popupBtnIncreaseStepName,
      xPos + m_buttonWidth + inputPopupWidth,
      popupY + 130,
      m_buttonWidth,
      m_inputHeight,
      "+"
   );
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_ZORDER, 1002);

   int btnProcessWidth = (inputPopupWidth + m_buttonWidth * 2) / 2 - 5;

   // POPUP: Create button Cancel
   // Chú ý: Đặt button Cancel trước để nó nằm bên trái button OK, tạo cảm giác cân đối hơn khi hiển
   // thị popup
   CreateButton(
      m_popupBtnCancelName,
      xPos,
      popupY + popupHeight - 40,
      btnProcessWidth,
      25,
      "Cancel"
   );
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_BGCOLOR, clrRed);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_ZORDER, 1002);

   // POPUP: Create button OK
   CreateButton(
      m_popupBtnOkName,
      xPos + btnProcessWidth + 10,
      popupY + popupHeight - 40,
      btnProcessWidth,
      25,
      "OK"
   );
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_ZORDER, 1002);
}

void UIInputNumber::StartOpenPopup() {
   ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupInputStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupInputDigitsName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

void UIInputNumber::StartClosePopup() {
   ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupInputStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupInputDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
}

void UIInputNumber::ClickBtnSetting() {
   ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_STATE, false);
   if(!m_isDisabled) {
      m_isOpenPopup = !m_isOpenPopup;
      if(m_isOpenPopup) {
         StartOpenPopup();
      } else {
         StartClosePopup();
      }
      SetStepSetting(m_step);
      SetDigitsSetting(m_digits);
      InputRedrawChart();
   }
}

void UIInputNumber::ClickBtnMinus() {
   if(!m_isDisabled) {
      UpdateValue(m_value - m_step);
      OnChangeValue();
      ChartRedraw();
   }
   Sleep(100);
   ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickBtnPlus() {
   if(!m_isDisabled) {
      UpdateValue(m_value + m_step);
      OnChangeValue();
      ChartRedraw();
   }
   Sleep(100);
   ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnDigitsIncrease() {
   SetDigitsSetting(m_digitsSetting + 1);
   InputRedrawChart();
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnDigitsDecrease() {
   SetDigitsSetting(m_digitsSetting - 1);
   InputRedrawChart();
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnStepIncrease() {
   SetStepSetting(m_stepSetting * 10);
   InputRedrawChart();
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_STATE, false);
}
void UIInputNumber::ClickPopupBtnStepDecrease() {
   int oldPower = (int)MathRound(MathLog10(m_stepSetting));
   SetStepSetting(MathPow(10, oldPower - 1));
   InputRedrawChart();
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_STATE, false);
}
void UIInputNumber::ClickPopupBtnOk() {
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_STATE, false);
   SetStep(m_stepSetting);
   SetDigits(m_digitsSetting);
   StartClosePopup();
   InputRedrawChart();
}
void UIInputNumber::ClickPopupBtnCancel() {
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_STATE, false);
   StartClosePopup();
   InputRedrawChart();
}

void UIInputNumber::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_btnSettingName) {
         ClickBtnSetting();
      }
      if(sparam == m_btnMinusName) {
         ClickBtnMinus();
      }
      if(sparam == m_btnPlusName) {
         ClickBtnPlus();
      }

      if(sparam == m_popupBtnIncreaseDigitsName) {
         ClickPopupBtnDigitsIncrease();
      }
      if(sparam == m_popupBtnDecreaseDigitsName) {
         ClickPopupBtnDigitsDecrease();
      }

      if(sparam == m_popupBtnIncreaseStepName) {
         ClickPopupBtnStepIncrease();
      }
      if(sparam == m_popupBtnDecreaseStepName) {
         ClickPopupBtnStepDecrease();
      }

      if(sparam == m_popupBtnOkName) {
         ClickPopupBtnOk();
      }
      if(sparam == m_popupBtnCancelName) {
         ClickPopupBtnCancel();
      }
   }

   // Xử lý khi user nhập tay vào input
   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      if(sparam == m_inputName) {
         string text     = ObjectGetString(m_chartId, m_inputName, OBJPROP_TEXT);
         double newValue = StringToDouble(text);
         SetValue(newValue);
         OnChangeValue();
      }
   }
}

void UIInputNumber::OnMQLTesterEvent() {
   bool btnSettingState = ObjectGetInteger(m_chartId, m_btnSettingName, OBJPROP_STATE);
   if(btnSettingState) {
      ClickBtnSetting();
   }
   bool btnMinusState = ObjectGetInteger(m_chartId, m_btnMinusName, OBJPROP_STATE);
   if(btnMinusState) {
      ClickBtnMinus();
   }
   bool btnPlusState = ObjectGetInteger(m_chartId, m_btnPlusName, OBJPROP_STATE);
   if(btnPlusState) {
      ClickBtnPlus();
   }

   bool btnIncreaseDigitsState
      = ObjectGetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_STATE);
   if(btnIncreaseDigitsState) {
      ClickPopupBtnDigitsIncrease();
   }
   bool btnDecreaseDigitsState
      = ObjectGetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_STATE);
   if(btnDecreaseDigitsState) {
      ClickPopupBtnDigitsDecrease();
   }

   bool btnIncreaseState = ObjectGetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_STATE);
   if(btnIncreaseState) {
      ClickPopupBtnStepIncrease();
   }
   bool btnDecreaseState = ObjectGetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_STATE);
   if(btnDecreaseState) {
      ClickPopupBtnStepDecrease();
   }
   bool btnOkState = ObjectGetInteger(m_chartId, m_popupBtnOkName, OBJPROP_STATE);
   if(btnOkState) {
      ClickPopupBtnOk();
   }
   bool btnCancelState = ObjectGetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_STATE);
   if(btnCancelState) {
      ClickPopupBtnCancel();
   }
}

#endif // UI_INPUT_NUMBER_MQH
