#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIPanel.mqh>

class PopupPositionListener {
 public:
   virtual void onIsMinimizedPanelChange(bool _isMinimized) = 0;
   virtual void onCheckedTrailingStopChange(bool newValue)  = 0;
};

class PopupPositionPanelListener : public UIPanelListener {
 public:
   PopupPositionListener *m_popup;
   virtual void           onIsMinimizedChange(bool _isMinimized) override {
      if(m_popup) {
         m_popup.onIsMinimizedPanelChange(_isMinimized);
      }
   };
   void SetPopupPosition(PopupPositionListener *popup) { m_popup = popup; };
};

class PopupCheckboxTrailingStopListener : public UICheckboxListener {
 public:
   PopupPositionListener *m_popup;
   virtual void           onCheckedChange(bool newValue) override {
      if(m_popup) {
         m_popup.onCheckedTrailingStopChange(newValue);
      }
   };
   void SetPopupPosition(PopupPositionListener *popup) { m_popup = popup; };
};

class TDPopupPosition : public PopupPositionListener {
 public:
   PopupPositionPanelListener        m_popupPanelListener;
   PopupCheckboxTrailingStopListener m_popupCheckboxTSListener;

   long                              m_chartId;
   bool                              m_isShow;
   ulong                             m_ticketId;
   int                               m_x;
   int                               m_y;
   int                               m_width;
   int                               m_height;

   double                            m_openPrice;
   double                            m_Point;
   ENUM_POSITION_TYPE                m_type;

   UIPanel                           m_uiPanelPopup;

   UIInputNumber                     m_ipTakeProfitPoints;
   UIInputNumber                     m_ipTakeProfitPrice;
   UIInputNumber                     m_ipStopLossPoints;
   UIInputNumber                     m_ipStopLossPrice;

   UICheckbox                        m_cbTrailingStopEnable;
   bool                              m_enableTrailingStop;

   UIInputNumber                     m_ipTSStartPoints;
   UIInputNumber                     m_ipTSStartPrice;
   UIInputNumber                     m_ipTSStepPoints;
   UIInputNumber                     m_ipTSStepPrice;
   UIInputNumber                     m_ipTSDistancePoints;
   UIInputNumber                     m_ipTSDistancePrice;

   string                            m_ObjInfoLabelName;
   string                            m_ObjBtnSubmitName;
   string                            m_ObjBtnCancelName;

   color                             clrBtnSubmitBg;
   color                             clrBtnSubmitBorder;
   color                             clrBtnCancelBg;
   color                             clrBtnCancelBorder;

   void Create(long chartId, int x, int y, int width, int height, bool isShow) {
      m_chartId = chartId;
      m_isShow  = isShow;
      m_x       = x;
      m_y       = y;
      m_width   = width;
      m_height  = height;

      m_popupPanelListener.SetPopupPosition(&this);
      m_popupCheckboxTSListener.SetPopupPosition(&this);

      m_ipStopLossPoints.setCallback(&this, TDPopupPosition::OnChangeStopLossPoints);
      m_ipStopLossPrice.setCallback(&this, TDPopupPosition::OnChangeStopLossPrice);
      m_ipTakeProfitPoints.setCallback(&this, TDPopupPosition::OnChangeTakeProfitPoints);
      m_ipTakeProfitPrice.setCallback(&this, TDPopupPosition::OnChangeTakeProfitPrice);
      m_ipTSStartPoints.setCallback(&this, TDPopupPosition::OnChangeTSStartPoints);
      m_ipTSStartPrice.setCallback(&this, TDPopupPosition::OnChangeTSStartPrice);
      m_ipTSStepPoints.setCallback(&this, TDPopupPosition::OnChangeTSStepPoints);
      m_ipTSStepPrice.setCallback(&this, TDPopupPosition::OnChangeTSStepPrice);
      m_ipTSDistancePoints.setCallback(&this, TDPopupPosition::OnChangeTSDistancePoints);
      m_ipTSDistancePrice.setCallback(&this, TDPopupPosition::OnChangeTSDistancePrice);

      m_ObjInfoLabelName = "PP_OBJ_INFO_LABEL_NAME";
      m_ObjBtnSubmitName = "PP_OBJ_BTN_SUBMIT_NAME";
      m_ObjBtnCancelName = "PP_OBJ_BTN_CANCEL_NAME";

      Initialization();
      m_uiPanelPopup.StartDrawContainer();
      StartDrawPanelContent();
   }

   void SetEnableTrailingStop(bool enableTrailingStop) {
      m_enableTrailingStop = enableTrailingStop;
      if(m_enableTrailingStop) {
         m_ipTSStartPoints.SetDisabled(false);
         m_ipTSStartPrice.SetDisabled(false);
         m_ipTSStepPoints.SetDisabled(false);
         m_ipTSStepPrice.SetDisabled(false);
         m_ipTSDistancePoints.SetDisabled(false);
         m_ipTSDistancePrice.SetDisabled(false);
      } else {
         m_ipTSStartPoints.SetDisabled(true);
         m_ipTSStartPrice.SetDisabled(true);
         m_ipTSStepPoints.SetDisabled(true);
         m_ipTSStepPrice.SetDisabled(true);
         m_ipTSDistancePoints.SetDisabled(true);
         m_ipTSDistancePrice.SetDisabled(true);
      }
   }

   virtual void onIsMinimizedPanelChange(bool _isMinimized) override {
      Print("•>[TDPopupPosition.mqh:90]: _isMinimized: ", _isMinimized);
   }

   virtual void onCheckedTrailingStopChange(bool newValue) override {
      SetEnableTrailingStop(newValue);
   }

   // phải là hàm static để có thể truyền vào callback của UIInputNumber
   static void OnChangeStopLossPoints(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double stopLossPrice = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            stopLossPrice = self.m_openPrice - value * self.m_Point;
         } else {
            stopLossPrice = self.m_openPrice + value * self.m_Point;
         }
         self.m_ipStopLossPrice.SetValue(stopLossPrice);
      }
   }

   static void OnChangeTakeProfitPoints(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double takeProfitPrice = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            takeProfitPrice = self.m_openPrice + value * self.m_Point;
         } else {
            takeProfitPrice = self.m_openPrice - value * self.m_Point;
         }
         self.m_ipTakeProfitPrice.SetValue(takeProfitPrice);
      }
   }

   static void OnChangeStopLossPrice(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double stopLossPoints = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            stopLossPoints = (self.m_openPrice - value) / self.m_Point;
         } else {
            stopLossPoints = (value - self.m_openPrice) / self.m_Point;
         }
         self.m_ipStopLossPoints.SetValue(NormalizeDouble(stopLossPoints, 0));
      }
   }

   static void OnChangeTakeProfitPrice(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double takeProfitPoints = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            takeProfitPoints = (value - self.m_openPrice) / self.m_Point;
         } else {
            takeProfitPoints = (self.m_openPrice - value) / self.m_Point;
         }
         self.m_ipTakeProfitPoints.SetValue(NormalizeDouble(takeProfitPoints, 0));
      }
   }

   static void OnChangeTSStartPoints(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsStartPrice = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            tsStartPrice = self.m_openPrice + value * self.m_Point;
         } else {
            tsStartPrice = self.m_openPrice - value * self.m_Point;
         }
         self.m_ipTSStartPrice.SetValue(tsStartPrice);
      }
   }

   static void OnChangeTSStartPrice(void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsStartPoints = 0;
         if(self.m_type == POSITION_TYPE_BUY) {
            tsStartPoints = (value - self.m_openPrice) / self.m_Point;
         } else {
            tsStartPoints = (self.m_openPrice - value) / self.m_Point;
         }
         self.m_ipTSStartPoints.SetValue(NormalizeDouble(tsStartPoints, 0));
      }
   }

   static void OnChangeTSStepPoints(void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsStepPrice = value * self.m_Point;
         self.m_ipTSStepPrice.SetValue(tsStepPrice);
      }
   }

   static void OnChangeTSStepPrice(void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsStepPoints = value / self.m_Point;
         self.m_ipTSStepPoints.SetValue(NormalizeDouble(tsStepPoints, 0));
      }
   }

   static void OnChangeTSDistancePoints(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsDistancePrice = value * self.m_Point;
         self.m_ipTSDistancePrice.SetValue(tsDistancePrice);
      }
   }

   static void OnChangeTSDistancePrice(
      void *context, UI_INPUT_NUMBER_CHANGE_TYPE type, double value
   ) {
      TDPopupPosition *self = (TDPopupPosition *)context;
      if(type == UI_INPUT_NUMBER_CHANGE_VALUE) {
         double tsDistancePoints = value / self.m_Point;
         self.m_ipTSDistancePoints.SetValue(NormalizeDouble(tsDistancePoints, 0));
      }
   }

   void Initialization() {
      // clang-format off
      clrBtnSubmitBg        = C'0,128,0';       // Green
      clrBtnSubmitBorder    = C'0,180,0';
      clrBtnCancelBg       = C'220,20,60';     // Crimson
      clrBtnCancelBorder   = C'255,60,100';
      // clang-format on

      m_uiPanelPopup.Initialization(0, "ModifyTicket", m_x, m_y, m_width, m_height, false);
      m_uiPanelPopup.SetHeaderTitle("Modify Ticket");
   }

   void StartDrawContainer() { m_uiPanelPopup.StartDrawContainer(); }

   void StartRedrawChart() { m_uiPanelPopup.StartRedrawChart(); }

   void StartDrawPanelContent() {
      // Tạo ô nhập Stop Loss
      int yOffsetPanel = m_uiPanelPopup.GetHeaderHeight();

      uiCommon.CreateLabel(m_chartId, m_ObjInfoLabelName, "Ticket: ...", 10, clrLimeGreen);
      m_uiPanelPopup.AddPanelChild(m_ObjInfoLabelName, 10, yOffsetPanel + 8);
      yOffsetPanel = yOffsetPanel + 30;

      // Create Input StopLoss Points
      m_ipStopLossPoints.Initialization(
         m_chartId,
         "StopLossPoints",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipStopLossPoints.SetLabel("Stop Loss (Points):", clrWhite);
      m_ipStopLossPoints.SetStep(10);
      m_ipStopLossPoints.SetDigits(0);
      m_ipStopLossPoints.SetMinValue(0);
      m_ipStopLossPoints.StartDrawContent();
      m_ipStopLossPoints.SetValue(0);
      string ipSlPointsObjNameList[];
      m_ipStopLossPoints.GetObjectNameList(ipSlPointsObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipSlPointsObjNameList);

      // Create Input StopLoss Price
      m_ipStopLossPrice.Initialization(
         m_chartId,
         "StopLossPrice",
         m_x + (m_width - 10) / 2 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipStopLossPrice.SetLabel("Stop Loss (Price):", clrWhite);
      m_ipStopLossPrice.SetStep(0.0001);
      m_ipStopLossPrice.SetDigits(_Digits);
      m_ipStopLossPrice.SetMinValue(0);
      m_ipStopLossPrice.StartDrawContent();
      m_ipStopLossPrice.SetValue(0);
      string ipSlValueObjNameList[];
      m_ipStopLossPrice.GetObjectNameList(ipSlValueObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipSlValueObjNameList);

      yOffsetPanel += 55;

      // Create Input TakeProfit Points
      m_ipTakeProfitPoints.Initialization(
         m_chartId,
         "TakeProfitPoints",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTakeProfitPoints.SetLabel("Take Profit (Points):", clrWhite);
      m_ipTakeProfitPoints.SetStep(10);
      m_ipTakeProfitPoints.SetDigits(0);
      m_ipTakeProfitPoints.SetMinValue(0);
      m_ipTakeProfitPoints.StartDrawContent();
      m_ipTakeProfitPoints.SetValue(0);
      string ipTpPointsObjNameList[];
      m_ipTakeProfitPoints.GetObjectNameList(ipTpPointsObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTpPointsObjNameList);

      // Create Input TakeProfit Price
      m_ipTakeProfitPrice.Initialization(
         m_chartId,
         "TakeProfitPrice",
         m_x + (m_width - 10) / 2 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTakeProfitPrice.SetLabel("Take Profit (Price):", clrWhite);
      m_ipTakeProfitPrice.SetStep(0.0001);
      m_ipTakeProfitPrice.SetDigits(_Digits);
      m_ipTakeProfitPrice.SetMinValue(0);
      m_ipTakeProfitPrice.StartDrawContent();
      m_ipTakeProfitPrice.SetValue(0);
      string ipTpValueObjNameList[];
      m_ipTakeProfitPrice.GetObjectNameList(ipTpValueObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTpValueObjNameList);
      yOffsetPanel = yOffsetPanel + 60;

      // Tạo checkbox Trailing Stop
      m_cbTrailingStopEnable.Initialization(
         m_chartId,
         "TrailingStopEnable",
         m_x + 10,
         m_y + yOffsetPanel,
         "Trailing Stop Settings:",
         10
      );
      m_cbTrailingStopEnable.StartDrawContent();
      m_cbTrailingStopEnable.SetValue(true);
      m_cbTrailingStopEnable.SetListener(&m_popupCheckboxTSListener);
      string cbTrailingStopEnableObjNameList[];
      m_cbTrailingStopEnable.GetObjectNameList(cbTrailingStopEnableObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(cbTrailingStopEnableObjNameList);

      yOffsetPanel = yOffsetPanel + 20;

      // Create Input Trailing Stop Start Points
      m_ipTSStartPoints.Initialization(
         m_chartId,
         "TSStartPoints",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSStartPoints.SetLabel("TS Start (Points):", clrWhite);
      m_ipTSStartPoints.SetStep(10);
      m_ipTSStartPoints.SetDigits(0);
      m_ipTSStartPoints.SetMinValue(0);
      m_ipTSStartPoints.StartDrawContent();
      m_ipTSStartPoints.SetValue(0);
      string ipTSStartPointsObjNameList[];
      m_ipTSStartPoints.GetObjectNameList(ipTSStartPointsObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSStartPointsObjNameList);

      // Create Input Trailing Stop Start Price
      m_ipTSStartPrice.Initialization(
         m_chartId,
         "TSStartPrice",
         m_x + (m_width - 10) / 2 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSStartPrice.SetLabel("TS Start (Price):", clrWhite);
      m_ipTSStartPrice.SetStep(0.0001);
      m_ipTSStartPrice.SetDigits(_Digits);
      m_ipTSStartPrice.SetMinValue(0);
      m_ipTSStartPrice.StartDrawContent();
      m_ipTSStartPrice.SetValue(0);
      string ipTSStartPriceObjNameList[];
      m_ipTSStartPrice.GetObjectNameList(ipTSStartPriceObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSStartPriceObjNameList);

      yOffsetPanel += 55;

      // Create Input Trailing Stop Step Points
      m_ipTSStepPoints.Initialization(
         m_chartId,
         "TSStepPoints",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSStepPoints.SetLabel("TS Step (Points):", clrWhite);
      m_ipTSStepPoints.SetStep(10);
      m_ipTSStepPoints.SetDigits(0);
      m_ipTSStepPoints.SetMinValue(0);
      m_ipTSStepPoints.StartDrawContent();
      m_ipTSStepPoints.SetValue(0);
      string ipTSStepPointsObjNameList[];
      m_ipTSStepPoints.GetObjectNameList(ipTSStepPointsObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSStepPointsObjNameList);

      // Create Input Trailing Stop Step Price
      m_ipTSStepPrice.Initialization(
         m_chartId,
         "TSStepPrice",
         m_x + (m_width - 10) / 2 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSStepPrice.SetLabel("TS Step (Price):", clrWhite);
      m_ipTSStepPrice.SetStep(0.0001);
      m_ipTSStepPrice.SetDigits(_Digits);
      m_ipTSStepPrice.SetMinValue(0);
      m_ipTSStepPrice.StartDrawContent();
      m_ipTSStepPrice.SetValue(0);
      string ipTSStepPriceObjNameList[];
      m_ipTSStepPrice.GetObjectNameList(ipTSStepPriceObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSStepPriceObjNameList);

      yOffsetPanel += 55;
      // Create Input Trailing Stop Distance Points
      m_ipTSDistancePoints.Initialization(
         m_chartId,
         "TSDistancePoints",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSDistancePoints.SetLabel("TS Distance (Points):", clrWhite);
      m_ipTSDistancePoints.SetStep(10);
      m_ipTSDistancePoints.SetDigits(0);
      m_ipTSDistancePoints.SetMinValue(0);
      m_ipTSDistancePoints.StartDrawContent();
      m_ipTSDistancePoints.SetValue(0);
      string ipTSDistancePointsObjNameList[];
      m_ipTSDistancePoints.GetObjectNameList(ipTSDistancePointsObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSDistancePointsObjNameList);

      // Create Input Trailing Stop Distance Price
      m_ipTSDistancePrice.Initialization(
         m_chartId,
         "TSDistancePrice",
         m_x + (m_width - 10) / 2 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 2 - 10,
         45
      );
      m_ipTSDistancePrice.SetLabel("TS Distance (Price):", clrWhite);
      m_ipTSDistancePrice.SetStep(0.0001);
      m_ipTSDistancePrice.SetDigits(_Digits);
      m_ipTSDistancePrice.SetMinValue(0);
      m_ipTSDistancePrice.StartDrawContent();
      m_ipTSDistancePrice.SetValue(0);
      string ipTSDistancePriceObjNameList[];
      m_ipTSDistancePrice.GetObjectNameList(ipTSDistancePriceObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTSDistancePriceObjNameList);
      yOffsetPanel += 65;

      // Tạo nút Submit
      uiCommon.CreateButton(0, m_ObjBtnSubmitName, "SAVE", 80, 35);
      uiCommon.setTextColor(0, m_ObjBtnSubmitName, clrWhite);
      uiCommon.setBackgroundColor(0, m_ObjBtnSubmitName, clrBtnSubmitBg);
      uiCommon.setBorderColor(0, m_ObjBtnSubmitName, clrBtnSubmitBorder);
      uiCommon.setZOrder(0, m_ObjBtnSubmitName, 100);
      m_uiPanelPopup.AddPanelChild(m_ObjBtnSubmitName, m_width / 2 + 5, yOffsetPanel);

      // Tạo nút Cancel
      uiCommon.CreateButton(0, m_ObjBtnCancelName, "CANCEL", 80, 35);
      uiCommon.setTextColor(0, m_ObjBtnCancelName, clrWhite);
      uiCommon.setBackgroundColor(0, m_ObjBtnCancelName, clrBtnCancelBg);
      uiCommon.setBorderColor(0, m_ObjBtnCancelName, clrBtnCancelBorder);
      uiCommon.setZOrder(0, m_ObjBtnCancelName, 100);
      m_uiPanelPopup.AddPanelChild(m_ObjBtnCancelName, m_width / 2 - 5 - 80, yOffsetPanel);

      m_uiPanelPopup.PanelRefreshPosition();
   }

   void setShow(bool show) { m_isShow = show; }

   void openPopup(ulong ticketId) {
      m_isShow   = true;
      m_ticketId = ticketId;
      m_uiPanelPopup.setShow(true);
      if(!PositionSelectByTicket(ticketId)) {
         return;
      }
      string symbol          = PositionGetString(POSITION_SYMBOL);
      double volume          = PositionGetDouble(POSITION_VOLUME);
      m_type                 = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      m_openPrice            = PositionGetDouble(POSITION_PRICE_OPEN);
      m_Point                = SymbolInfoDouble(symbol, SYMBOL_POINT);

      double profit          = PositionGetDouble(POSITION_PROFIT);
      double stopLostPrice   = PositionGetDouble(POSITION_SL);
      double takeProfitPrice = PositionGetDouble(POSITION_TP);
      string infoText        = StringFormat(
         "Ticket: %I64u | %s | %s | %.2f",
         ticketId,
         symbol,
         (m_type == POSITION_TYPE_BUY) ? "BUY" : "SELL",
         volume
      );
      uiCommon.setText(0, m_ObjInfoLabelName, infoText);

      bool   enableTrailingStop = false;
      double stopLossPoints     = 0;
      double takeProfitPoints   = 0;
      double tsStartPoints      = 0;
      double tsStepPoints       = 0;
      double tsDistancePoints   = 0;
      double tsStartPrice       = 0;
      double tsStepPrice        = 0;
      double tsDistancePrice    = 0;
      if(m_type == POSITION_TYPE_BUY) {
         stopLossPoints   = (m_openPrice - stopLostPrice) / _Point;
         takeProfitPoints = (takeProfitPrice - m_openPrice) / _Point;
      } else {
         stopLossPoints   = (stopLostPrice - m_openPrice) / _Point;
         takeProfitPoints = (m_openPrice - takeProfitPrice) / _Point;
      }

      for(int i = 0; i < ArraySize(g_positionList); i++) {
         if(g_positionList[i].ticket == ticketId) {
            enableTrailingStop = g_positionList[i].enableTrailingStop;
            tsStartPoints      = g_positionList[i].trailingStopStartPoints;
            tsStepPoints       = g_positionList[i].trailingStopStepPoints;
            tsDistancePoints   = g_positionList[i].trailingStopDistancePoints;
            if(m_type == POSITION_TYPE_BUY) {
               tsStartPrice    = m_openPrice + tsStartPoints * _Point;
               tsStepPrice     = tsStepPoints * _Point;
               tsDistancePrice = tsDistancePoints * _Point;
            } else {
               tsStartPrice    = m_openPrice - tsStartPoints * _Point;
               tsStepPrice     = tsStepPoints * _Point;
               tsDistancePrice = tsDistancePoints * _Point;
            }
         }
      }

      m_ipStopLossPoints.SetValue(stopLossPoints);
      m_ipStopLossPrice.SetValue(stopLostPrice);
      m_ipTakeProfitPoints.SetValue(takeProfitPoints);
      m_ipTakeProfitPrice.SetValue(takeProfitPrice);
      m_cbTrailingStopEnable.SetValue(enableTrailingStop);
      m_ipTSStartPoints.SetValue(tsStartPoints);
      m_ipTSStartPrice.SetValue(tsStartPrice);
      m_ipTSStepPoints.SetValue(tsStepPoints);
      m_ipTSStepPrice.SetValue(tsStepPrice);
      m_ipTSDistancePoints.SetValue(tsDistancePoints);
      m_ipTSDistancePrice.SetValue(tsDistancePrice);

      SetEnableTrailingStop(enableTrailingStop);
   }

   void HandleClickSubmit() {
      double sl = m_ipStopLossPrice.GetValue();
      double tp = m_ipTakeProfitPrice.GetValue();

      if(!cTrade.PositionModify(m_ticketId, sl, tp)) {
         Print("Lỗi gửi lệnh sửa vị trí: ", GetLastError());
      } else {
         Print("Lệnh sửa vị trí thành công. Ticket: ", m_ticketId);
      }

      // Đóng popup sau khi xử lý
      m_isShow = false;
      m_uiPanelPopup.Close();
   }

   void HandleClickCancel() {
      m_isShow = false;
      m_uiPanelPopup.Close();
   }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      m_uiPanelPopup.OnChartEvent(id, lparam, dparam, sparam);
      m_ipStopLossPoints.OnChartEvent(id, lparam, dparam, sparam);
      m_ipStopLossPrice.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTakeProfitPoints.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTakeProfitPrice.OnChartEvent(id, lparam, dparam, sparam);
      m_cbTrailingStopEnable.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSStartPoints.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSStartPrice.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSStepPoints.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSStepPrice.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSDistancePoints.OnChartEvent(id, lparam, dparam, sparam);
      m_ipTSDistancePrice.OnChartEvent(id, lparam, dparam, sparam);

      if(id == CHARTEVENT_OBJECT_CLICK) {
         // Xử lý click nút Submit
         if(sparam == m_ObjBtnSubmitName) {
            uiCommon.setState(0, m_ObjBtnSubmitName, false);
            HandleClickSubmit();
         }
         // Xử lý click nút Sell
         else if(sparam == m_ObjBtnCancelName) {
            uiCommon.setState(0, m_ObjBtnCancelName, false);
            HandleClickCancel();
         }
      }

      return true;
   }

   void OnMQLTesterEvent() {
      m_uiPanelPopup.OnMQLTesterEvent();
      m_ipStopLossPoints.OnMQLTesterEvent();
      m_ipStopLossPrice.OnMQLTesterEvent();
      m_ipTakeProfitPoints.OnMQLTesterEvent();
      m_ipTakeProfitPrice.OnMQLTesterEvent();
      m_cbTrailingStopEnable.OnMQLTesterEvent();
      m_ipTSStartPoints.OnMQLTesterEvent();
      m_ipTSStartPrice.OnMQLTesterEvent();
      m_ipTSStepPoints.OnMQLTesterEvent();
      m_ipTSStepPrice.OnMQLTesterEvent();
      m_ipTSDistancePoints.OnMQLTesterEvent();
      m_ipTSDistancePrice.OnMQLTesterEvent();
   }

   void OnMQLTesterRefresh() {}
};
