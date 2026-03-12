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

class UIInputNumber {
 private:
   UIListener *m_listener;
   FOnChange   m_callback;
   void       *m_parent;    // lưu pointer đến object chủ

   long        m_chartId;   // ID của chart
   string      m_name;      // Tên unique cho control
   int         m_x;         // Vị trí X
   int         m_y;         // Vị trí Y
   int         m_width;     // Chiều rộng input
   int         m_fontSize;  // Kích thước font
   double      m_value;     // Giá trị hiện tại
   string      m_labelText; // Text label (nếu có)
   double      m_step;      // Bước nhảy
   int         m_digits;    // Số chữ số thập phân
   double      m_minValue;  // Giá trị min
   double      m_maxValue;  // Giá trị max
   double      m_stepSetting;
   int         m_digitsSetting;

   bool        m_isDisabled;
   bool        m_isTester;    // Có đang chạy ở môi trường tester không

   bool        m_isOpenPopup; // Có hiển thị popup setting không

   // Kích thước các thành phần

   // Màu sắc
   color m_labelTextColor;        // Màu label
   color m_labelTextDisableColor; // Màu label khi disable
   color m_buttonTextColor;       // Màu button
   color m_buttonBgColor;         // Màu button
   color m_borderColor;           // Màu button

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
   ~UIInputNumber() { DeleteAllObject(); }

   void Initialize(long chartId, string name) {
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

      m_labelTextColor        = clrWhite;
      m_labelTextDisableColor = clrWhite + 0x00333333;
      m_buttonTextColor       = clrBlack;
      m_buttonBgColor         = clrLightGray;
      m_borderColor           = clrDarkGray;

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

   void SetListener(UIListener *listener) { m_listener = listener; }
   void SetCallback(void *parent, FOnChange callback) {
      m_parent   = parent;
      m_callback = callback;
   }

   void EmitValue() {
      if(m_listener != NULL) {
         m_listener.listen(&this, UI_EVENT_CHANGE_VALUE, m_value);
      }
      if(m_callback != NULL) {
         m_callback(m_parent, UI_EVENT_CHANGE_VALUE, m_value);
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      ArrayResize(objNameList, 18);
      objNameList[0]  = m_labelName;
      objNameList[1]  = m_btnMinusName;
      objNameList[2]  = m_inputName;
      objNameList[3]  = m_btnPlusName;
      objNameList[4]  = m_btnSettingName;
      objNameList[5]  = m_popupBgName;
      objNameList[6]  = m_popupHeaderName;
      objNameList[7]  = m_popupTitleName;
      objNameList[8]  = m_popupLabelStepName;
      objNameList[9]  = m_popupInputStepName;
      objNameList[10] = m_popupBtnIncreaseStepName;
      objNameList[11] = m_popupBtnDecreaseStepName;
      objNameList[12] = m_popupLabelDigitsName;
      objNameList[13] = m_popupInputDigitsName;
      objNameList[14] = m_popupBtnIncreaseDigitsName;
      objNameList[15] = m_popupBtnDecreaseDigitsName;
      objNameList[16] = m_popupBtnOkName;
      objNameList[17] = m_popupBtnCancelName;
      return 18;
   }

   void DeleteAllObject() {
      string objNameList[];
      int    countObject = GetObjectNameList(objNameList);
      for(int i = 0; i < countObject; i++) {
         ObjectDelete(m_chartId, objNameList[i]);
      }
   }

   int GetWidth() { return m_width; }
   int GetHeight() {
      int labelHeight = (int)(m_fontSize * g_labelHeightRate);
      int inputHeight = (int)(m_fontSize * g_inputHeightRate);
      return labelHeight + inputHeight;
   }

   double GetValue() { return m_value; }
   double GetStep() { return m_step; }
   double GetDigits() { return m_digits; }
   string GetName() { return m_name; }

   void   SetWidth(int width) { m_width = width; }
   void   SetLabel(
        string text, color labelTextColor = clrNONE, color labelTextDisableColor = clrNONE
     ) {
      m_labelText = text;
      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
      }
      if(labelTextDisableColor != clrNONE) {
         m_labelTextDisableColor = labelTextDisableColor;
      }
   }
   void SetFontSize(int size) { m_fontSize = size; }
   void SetValue(double value) { m_value = value; }
   void SetDisabled(bool isDisabled) { m_isDisabled = isDisabled; }
   void SetStep(double step) { m_step = step; }
   void SetMinValue(double min) { m_minValue = min; }
   void SetMaxValue(double max) { m_maxValue = max; }
   void SetDigits(int digits) { m_digits = digits; }
   void SetButtonTextColor(color clr) { m_buttonTextColor = clr; }
   void SetButtonBgColor(color clr) { m_buttonBgColor = clr; }
   void SetBorderColor(color clr) { m_borderColor = clr; }

   void UpdateStepSetting(double stepSetting) {
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
   void UpdateDigitsSetting(int digitsSetting) {
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
         ObjectSetInteger(m_chartId, m_inputName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_COLOR, clrDarkGray);
         ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_COLOR, clrDarkGray);
      } else {
         ObjectSetInteger(m_chartId, m_inputName, OBJPROP_COLOR, clrBlack);
         ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_COLOR, m_buttonTextColor);
         ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_COLOR, m_buttonTextColor);
         ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_COLOR, m_buttonTextColor);
      }
   }
   void UpdateLabel(
      string text, color labelTextColor = clrNONE, color labelTextDisableColor = clrNONE
   ) {
      m_labelText = text;
      ObjectSetString(m_chartId, m_labelName, OBJPROP_TEXT, m_labelText);

      if(labelTextColor != clrNONE) {
         m_labelTextColor = labelTextColor;
         if(!m_isDisabled) {
            ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextColor);
         }
      }
      if(labelTextDisableColor != clrNONE) {
         m_labelTextDisableColor = labelTextDisableColor;
         if(m_isDisabled) {
            ObjectSetInteger(m_chartId, m_labelName, OBJPROP_COLOR, m_labelTextDisableColor);
         }
      }
   }

   void StartDraw(int x, int y, int width, int height);

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

   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();

 private:
   void CreateButton(string name, int x, int y, int width, int height, string text);
   void CreateLabel(string name, int x, int y, string text);
   void CreateInput(string name, int x, int y, int width, int height);
   void CreateRectangle(string name, int x, int y, int width, int height, color bgColor);

   void StartOpenPopupSetting();
   void StartClosePopupSetting();
};

void UIInputNumber::StartDraw(int x, int y, int width, int fontSize) {
   m_x         = x;
   m_y         = y;
   m_width     = width;
   m_fontSize  = fontSize;

   int yOffset = m_y;

   int labelHeight = (int)(m_fontSize * g_labelHeightRate); // Chiều cao label dựa trên font size
   int buttonSize = (int)(m_fontSize * g_inputHeightRate); // Kích thước button dựa trên font size
   int inputWidth = width - 2 * buttonSize;
   int inputHeight = (int)(m_fontSize * g_inputHeightRate); // Chiều cao input dựa trên font size

   // Create button setting (⚙)
   CreateButton(
      m_btnSettingName,
      m_x,
      (int)(yOffset + m_fontSize * 0.3),
      m_fontSize,
      m_fontSize,
      "[≡]"
   );
   ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_FONTSIZE, (int)(m_fontSize * 0.8));

   // Create label
   CreateLabel(m_labelName, m_x + (int)(m_fontSize * 1.5), yOffset, m_labelText);
   yOffset += labelHeight;

   // Create button giảm (-)
   CreateButton(m_btnMinusName, m_x, yOffset, buttonSize, buttonSize, "-");

   // Create ô input
   CreateInput(m_inputName, m_x + buttonSize, yOffset, inputWidth, inputHeight);
   ObjectSetInteger(m_chartId, m_inputName, OBJPROP_READONLY, m_isTester || m_isDisabled);
   ObjectSetString(m_chartId, m_inputName, OBJPROP_TEXT, DoubleToString(m_value, m_digits));

   // Create button tăng (+)
   CreateButton(m_btnPlusName, m_x + buttonSize + inputWidth, yOffset, buttonSize, buttonSize, "+");
}

void UIInputNumber::CreateButton(string name, int x, int y, int width, int height, string text) {
   if(!ObjectCreate(m_chartId, name, OBJ_BUTTON, 0, 0, 0)) {
      Print("Failed to create button: ", name, " Error: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);

   ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
   ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, m_isDisabled ? clrDarkGray : m_buttonTextColor);
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
   if(!ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0)) {
      Print("Failed to create label: ", name, " Error: ", GetLastError());
      return;
   }
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
   if(!ObjectCreate(m_chartId, name, OBJ_EDIT, 0, 0, 0)) {
      Print("Failed to create input: ", name, " Error: ", GetLastError());
      return;
   }
   ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);
   ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, m_isDisabled ? clrDarkGray : clrBlack);
   ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_COLOR, m_borderColor);
   ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, m_inputName, OBJPROP_READONLY, m_isTester || m_isDisabled);
}

void UIInputNumber::CreateRectangle(
   string name, int x, int y, int width, int height, color bgColor
) {
   if(!ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      Print("Failed to create rectangle: ", name, " Error: ", GetLastError());
      return;
   }
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

void UIInputNumber::StartOpenPopupSetting() {
   int popupWidth  = 200;
   int popupHeight = 210;
   int popupX      = m_x;

   // Mặc định hiển thị popup ở trên input, nếu không đủ chỗ thì hiển thị ở dưới
   int popupY = m_y - popupHeight;
   if(popupY < 10) {
      popupY = m_y + GetHeight() + 2;
   }

   int buttonSize = (int)(m_fontSize * g_inputHeightRate); // Kích thước button dựa trên font size
   int inputHeight = (int)(m_fontSize * g_inputHeightRate); // Chiều cao input dựa trên font size
   int inputWidth = 110;
   int labelHeight = (int)(m_fontSize * g_labelHeightRate); // Chiều cao label dựa trên font size

   int padding = (popupWidth - inputWidth - buttonSize * 2) / 2;
   int xOffset = popupX + padding;
   int yOffset = popupY;

   // POPUP: Tạo background
   CreateRectangle(m_popupBgName, popupX, popupY, popupWidth, popupHeight, clrWhiteSmoke);
   ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_ZORDER, 1000);

   // POPUP: Create header
   CreateRectangle(m_popupHeaderName, popupX, popupY, popupWidth, 30, clrLightGray);
   ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_ZORDER, 1001);

   // POPUP: Create title
   CreateLabel(m_popupTitleName, popupX + padding, popupY + 6, m_labelText);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_ZORDER, 1002);
   yOffset = popupY + 45;

   // POPUP: Create label digits
   CreateLabel(m_popupLabelDigitsName, xOffset, yOffset, "Setting Digits:");
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_ZORDER, 1002);
   yOffset += labelHeight;

   // POPUP: Create button digits giảm (-)
   CreateButton(m_popupBtnDecreaseDigitsName, xOffset, yOffset, buttonSize, buttonSize, "-");
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_ZORDER, 1002);

   // POPUP: Create ô input digits
   CreateInput(m_popupInputDigitsName, xOffset + buttonSize, yOffset, inputWidth, inputHeight);
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
      xOffset + buttonSize + inputWidth,
      yOffset,
      buttonSize,
      buttonSize,
      "+"
   );
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_ZORDER, 1002);

   yOffset += 40;

   // POPUP: Create label step
   CreateLabel(m_popupLabelStepName, xOffset, yOffset, "Setting Step:");
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_ZORDER, 1002);
   yOffset += labelHeight;

   // POPUP: Create button step giảm (-)
   CreateButton(m_popupBtnDecreaseStepName, xOffset, yOffset, buttonSize, buttonSize, "-");
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_ZORDER, 1002);

   // POPUP: Create ô input step
   CreateInput(m_popupInputStepName, xOffset + buttonSize, yOffset, inputWidth, inputHeight);
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
      xOffset + buttonSize + inputWidth,
      yOffset,
      buttonSize,
      buttonSize,
      "+"
   );
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_ZORDER, 1002);

   int btnProcessWidth = (inputWidth + buttonSize * 2) / 2 - 5;

   // POPUP: Create button Cancel
   CreateButton(
      m_popupBtnCancelName,
      xOffset,
      popupY + popupHeight - 45,
      btnProcessWidth,
      25,
      "CANCEL"
   );
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_BGCOLOR, clrRed);
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_ZORDER, 1002);

   // POPUP: Create button OK
   CreateButton(
      m_popupBtnOkName,
      xOffset + btnProcessWidth + 10,
      popupY + popupHeight - 45,
      btnProcessWidth,
      25,
      "OK"
   );
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_ZORDER, 1002);
}

void UIInputNumber::StartClosePopupSetting() {
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
   ObjectDelete(m_chartId, m_popupBtnCancelName);
   ObjectDelete(m_chartId, m_popupBtnOkName);
}

// void UIInputNumber::StartShowPopup() {
//    ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupInputStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_TIMEFRAMES,
//    OBJ_ALL_PERIODS); ObjectSetInteger(m_chartId, m_popupInputDigitsName, OBJPROP_TIMEFRAMES,
//    OBJ_ALL_PERIODS); ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName,
//    OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); ObjectSetInteger(m_chartId, m_popupBtnCancelName,
//    OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); ObjectSetInteger(m_chartId, m_popupBtnOkName,
//    OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
// }

// void UIInputNumber::StartHideSetting() {
//    ObjectSetInteger(m_chartId, m_popupBgName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupHeaderName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupTitleName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupLabelStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupInputStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupLabelDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupInputDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//    ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
// }

void UIInputNumber::ClickBtnSetting() {
   ObjectSetInteger(m_chartId, m_btnSettingName, OBJPROP_STATE, false);
   if(!m_isDisabled) {
      m_isOpenPopup = !m_isOpenPopup;
      if(m_isOpenPopup) {
         StartOpenPopupSetting();
      } else {
         StartClosePopupSetting();
      }
      UpdateStepSetting(m_step);
      UpdateDigitsSetting(m_digits);
      ChartRedraw(m_chartId);
   }
}

void UIInputNumber::ClickBtnMinus() {
   if(!m_isDisabled) {
      UpdateValue(m_value - m_step);
      EmitValue();
      ChartRedraw();
   }
   Sleep(100);
   ObjectSetInteger(m_chartId, m_btnMinusName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickBtnPlus() {
   if(!m_isDisabled) {
      UpdateValue(m_value + m_step);
      EmitValue();
      ChartRedraw();
   }
   Sleep(100);
   ObjectSetInteger(m_chartId, m_btnPlusName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnDigitsIncrease() {
   UpdateDigitsSetting(m_digitsSetting + 1);
   ChartRedraw(m_chartId);
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseDigitsName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnDigitsDecrease() {
   UpdateDigitsSetting(m_digitsSetting - 1);
   ChartRedraw(m_chartId);
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseDigitsName, OBJPROP_STATE, false);
}

void UIInputNumber::ClickPopupBtnStepIncrease() {
   UpdateStepSetting(m_stepSetting * 10);
   ChartRedraw(m_chartId);
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnIncreaseStepName, OBJPROP_STATE, false);
}
void UIInputNumber::ClickPopupBtnStepDecrease() {
   int oldPower = (int)MathRound(MathLog10(m_stepSetting));
   UpdateStepSetting(MathPow(10, oldPower - 1));
   ChartRedraw(m_chartId);
   Sleep(100);
   ObjectSetInteger(m_chartId, m_popupBtnDecreaseStepName, OBJPROP_STATE, false);
}
void UIInputNumber::ClickPopupBtnOk() {
   ObjectSetInteger(m_chartId, m_popupBtnOkName, OBJPROP_STATE, false);
   SetStep(m_stepSetting);
   SetDigits(m_digitsSetting);
   StartClosePopupSetting();
   ChartRedraw(m_chartId);
}
void UIInputNumber::ClickPopupBtnCancel() {
   ObjectSetInteger(m_chartId, m_popupBtnCancelName, OBJPROP_STATE, false);
   StartClosePopupSetting();
   ChartRedraw(m_chartId);
}

void UIInputNumber::OnRealtimeEvent(
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
         EmitValue();
      }
   }
}

void UIInputNumber::OnStrategyTesterEvent() {
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
