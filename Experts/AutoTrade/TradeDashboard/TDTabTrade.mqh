#include "TDTablePositions.mqh"
#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>

class TDTabTradeListener {
 public:
   virtual void onCheckedTrailingStopChange(bool newValue) = 0;
};

class CheckboxTrailingStopListener : public UICheckboxListener {
 public:
   TDTabTradeListener *m_container;
   virtual void        onChangeValue(bool newValue) override {
      if(m_container) {
         m_container.onCheckedTrailingStopChange(newValue);
      }
   };
   void SetContainer(TDTabTradeListener *container) { m_container = container; };
};

class TDTabTrade : public TDTabTradeListener {
 public:
   TDTablePositions             m_tdTablePositions;
   CheckboxTrailingStopListener m_checkboxTrailingStopListener;

   int                          m_x;
   int                          m_y;
   int                          m_width;
   int                          m_height;

   int                          m_slPoints;
   int                          m_tpPoints;
   int                          m_tsStartPoints;
   int                          m_tsStepPoints;
   int                          m_tsDistancePoints;

   UIInputNumber                m_ipLotSize;
   UIInputNumber                m_ipStopLossPoints;
   UIInputNumber                m_ipTakeProfitPoints;

   UICheckbox                   m_cbTrailingStopEnable;
   bool                         m_enableTrailingStop;

   UIInputNumber                m_ipTrailingStopStart;
   UIInputNumber                m_ipTrailingStopStep;
   UIInputNumber                m_ipTrailingStopDistance;

   string                       m_ObjBtnBuyName;
   string                       m_ObjBtnSellName;
   string                       m_ObjBtnCloseAllName;
   string                       m_ObjStatusName;

   color                        m_clrBtnBuyBg;
   color                        m_clrBtnBuyBorder;
   color                        m_clrBtnSellBg;
   color                        m_clrBtnSellBorder;
   color                        m_clrBtnCloseAllBg;
   color                        m_clrBtnCloseAllBorder;

   virtual void                 onCheckedTrailingStopChange(bool newValue) override {
      SetEnableTrailingStop(newValue);
   }

   void Initialization() {
      m_cbTrailingStopEnable.SetListener(&m_checkboxTrailingStopListener);
      m_checkboxTrailingStopListener.SetContainer(&this);

      m_ipLotSize.setCallback(&this, TDTabTrade::OnChangeLotSize);
      m_ipStopLossPoints.setCallback(&this, TDTabTrade::OnChangeStopLossPoints);

      m_ObjBtnBuyName      = "M_ObjBtnBuyName";
      m_ObjBtnSellName     = "M_ObjBtnSellName";
      m_ObjBtnCloseAllName = "M_ObjBtnCloseAllName";
      m_ObjStatusName      = "M_ObjStatusName";

      // clang-format off
      m_clrBtnBuyBg        = C'0,128,0';       // Green
      m_clrBtnBuyBorder    = C'0,180,0';
      m_clrBtnSellBg       = C'220,20,60';     // Crimson
      m_clrBtnSellBorder   = C'255,60,100';
      m_clrBtnCloseAllBg   = C'255,140,0';     // Dark Orange
      m_clrBtnCloseAllBorder = C'255,180,80';
      // clang-format on

      m_enableTrailingStop = true;

      m_tdTablePositions.Initialization();
      m_ipLotSize.Initialization(g_chartId, "InputLotSize");
      m_ipStopLossPoints.Initialization(g_chartId, "InputStopLossPoints");
      m_ipTakeProfitPoints.Initialization(g_chartId, "InputTakeProfitPoints");
      m_cbTrailingStopEnable.Initialization(g_chartId, "CheckboxTrailingStopEnable");
      m_ipTrailingStopStart.Initialization(g_chartId, "InputTrailingStopStart");
      m_ipTrailingStopStep.Initialization(g_chartId, "InputTrailingStopStep");
      m_ipTrailingStopDistance.Initialization(g_chartId, "InputTrailingStopDistance");
   }

   static void OnChangeStopLossPoints(void *context, UI_EVENT_TYPE type, double newStopLossPoints) {
      TDTabTrade *self = (TDTabTrade *)context;
      if(type == UI_EVENT_CHANGE_VALUE) {
         double lotSize = 0;
         if(g_volumeType == VOLUME_TYPE_INPUT) {
            lotSize = self.m_ipLotSize.GetValue();
         } else if(g_volumeType == VOLUME_TYPE_MONEY) {
            lotSize = CalculateVolumeWithRiskMoney(g_volumeValue, newStopLossPoints, _Symbol);
            self.m_ipLotSize.UpdateValue(lotSize);
         } else if(g_volumeType == VOLUME_TYPE_PERCENT_BALANCE) {
            lotSize
               = CalculateVolumeWithRiskPercentBalance(g_volumeValue, newStopLossPoints, _Symbol);
            self.m_ipLotSize.UpdateValue(lotSize);
         } else if(g_volumeType == VOLUME_TYPE_PERCENT_EQUITY) {
            lotSize
               = CalculateVolumeWithRiskPercentEquity(g_volumeValue, newStopLossPoints, _Symbol);
            self.m_ipLotSize.UpdateValue(lotSize);
         }
      }
   }

   static void OnChangeLotSize(void *context, UI_EVENT_TYPE type, double newLotSize) {
      TDTabTrade *self = (TDTabTrade *)context;
      if(type == UI_EVENT_CHANGE_VALUE) {
         // double stopLossPrice = 0;
         // if(g_volumeType == VOLUME_TYPE_INPUT) {
         //    stopLossPrice = self.m_ipStopLossPoints.GetValue();
         // } else if(g_volumeType == VOLUME_TYPE_MONEY) {
         //    stopLossPrice = CalculateStopLossWithRiskMoney(g_volumeValue, newLotSize, _Symbol);
         //    double stopLossPoints
         //       = MathFloor(stopLossPrice / SymbolInfoDouble(_Symbol, SYMBOL_POINT));
         //    self.m_ipStopLossPoints.UpdateValue(stopLossPoints);

         // } else if(g_volumeType == VOLUME_TYPE_PERCENT_BALANCE) {
         //    stopLossPrice = CalculateStopLossWithRiskPercent(g_volumeValue, newLotSize, _Symbol);
         //    double stopLossPoints
         //       = MathFloor(stopLossPrice / SymbolInfoDouble(_Symbol, SYMBOL_POINT));
         //    self.m_ipStopLossPoints.UpdateValue(stopLossPoints);
         // }
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      string tableObjNameList[];
      int    tableObjCount = m_tdTablePositions.GetObjectNameList(tableObjNameList);

      string ipLotSizeObjNameList[];
      int    ipLotSizeObjCount = m_ipLotSize.GetObjectNameList(ipLotSizeObjNameList);

      string ipSlPointsObjNameList[];
      int    ipSlPointsObjCount = m_ipStopLossPoints.GetObjectNameList(ipSlPointsObjNameList);

      string ipTpPointsObjNameList[];
      int    ipTpPointsObjCount = m_ipTakeProfitPoints.GetObjectNameList(ipTpPointsObjNameList);

      string cbTrailingStopEnableObjNameList[];
      int    cbTrailingStopEnableObjCount
         = m_cbTrailingStopEnable.GetObjectNameList(cbTrailingStopEnableObjNameList);

      string ipTrailingStopStartObjNameList[];
      int    ipTrailingStopStartObjCount
         = m_ipTrailingStopStart.GetObjectNameList(ipTrailingStopStartObjNameList);

      string ipTrailingStopStepObjNameList[];
      int    ipTrailingStopStepObjCount
         = m_ipTrailingStopStep.GetObjectNameList(ipTrailingStopStepObjNameList);

      string ipTrailingStopDistanceObjNameList[];
      int    ipTrailingStopDistanceObjCount
         = m_ipTrailingStopDistance.GetObjectNameList(ipTrailingStopDistanceObjNameList);

      ArrayResize(
         objNameList,
         tableObjCount + ipLotSizeObjCount + ipSlPointsObjCount + ipTpPointsObjCount
            + cbTrailingStopEnableObjCount + ipTrailingStopStartObjCount
            + ipTrailingStopStepObjCount + ipTrailingStopDistanceObjCount + 4
      );
      int count = 0;
      for(int i = 0; i < tableObjCount; i++)
         objNameList[count++] = tableObjNameList[i];
      for(int i = 0; i < ipLotSizeObjCount; i++)
         objNameList[count++] = ipLotSizeObjNameList[i];
      for(int i = 0; i < ipSlPointsObjCount; i++)
         objNameList[count++] = ipSlPointsObjNameList[i];
      for(int i = 0; i < ipTpPointsObjCount; i++)
         objNameList[count++] = ipTpPointsObjNameList[i];
      for(int i = 0; i < cbTrailingStopEnableObjCount; i++)
         objNameList[count++] = cbTrailingStopEnableObjNameList[i];
      for(int i = 0; i < ipTrailingStopStartObjCount; i++)
         objNameList[count++] = ipTrailingStopStartObjNameList[i];
      for(int i = 0; i < ipTrailingStopStepObjCount; i++)
         objNameList[count++] = ipTrailingStopStepObjNameList[i];
      for(int i = 0; i < ipTrailingStopDistanceObjCount; i++)
         objNameList[count++] = ipTrailingStopDistanceObjNameList[i];

      objNameList[count++] = m_ObjBtnBuyName;
      objNameList[count++] = m_ObjBtnSellName;
      objNameList[count++] = m_ObjBtnCloseAllName;
      objNameList[count++] = m_ObjStatusName;
      return count;
   }

   void SetStopLossPoints(int slPoints) {
      m_slPoints = slPoints;
      m_ipStopLossPoints.UpdateValue(m_slPoints);
   }
   void SetTakeProfitPoints(int tpPoints) {
      m_tpPoints = tpPoints;
      m_ipTakeProfitPoints.UpdateValue(m_tpPoints);
   }
   void SetTrailingStopStartPoints(int tsStartPoints) {
      m_tsStartPoints = tsStartPoints;
      m_ipTrailingStopStart.UpdateValue(m_tsStartPoints);
   }
   void SetTrailingStopStepPoints(int tsStepPoints) {
      m_tsStepPoints = tsStepPoints;
      m_ipTrailingStopStep.UpdateValue(m_tsStepPoints);
   }
   void SetTrailingStopDistancePoints(int tsDistancePoints) {
      m_tsDistancePoints = tsDistancePoints;
      m_ipTrailingStopDistance.UpdateValue(m_tsDistancePoints);
   }
   void SetEnableTrailingStop(bool enableTrailingStop) {
      if(enableTrailingStop != m_enableTrailingStop) {
         m_enableTrailingStop = enableTrailingStop;
         m_cbTrailingStopEnable.UpdateValue(m_enableTrailingStop);
         if(m_enableTrailingStop) {
            m_ipTrailingStopStart.UpdateDisabled(false);
            m_ipTrailingStopStep.UpdateDisabled(false);
            m_ipTrailingStopDistance.UpdateDisabled(false);
         } else {
            m_ipTrailingStopStart.UpdateDisabled(true);
            m_ipTrailingStopStep.UpdateDisabled(true);
            m_ipTrailingStopDistance.UpdateDisabled(true);
         }
      }
   }

   void StartDraw(int x, int y, int width, int height);
   void TabShow(bool isShow);
   void DestroyDraw();

   void ClickBtnBuy();
   void ClickBtnSell();
   void ClickBtnCloseAllPosition();
   void RefreshData();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void TDTabTrade::StartDraw(int x, int y, int width, int height) {
   m_x      = x;
   m_y      = y;
   m_width  = width;
   m_height = height;

   m_tdTablePositions.StartDraw(m_x, m_y);
   int yOffsetPanel = m_tdTablePositions.GetHeight();

   // Tạo ô nhập Lot Size
   m_ipLotSize.SetLabel("Lot Size:", clrWhite);
   m_ipLotSize.SetValue(0.1);
   m_ipLotSize.SetStep(0.01);
   m_ipLotSize.SetDigits(2);
   m_ipLotSize.SetMinValue(0.00);
   m_ipLotSize.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập StopLoss Points
   m_ipStopLossPoints.SetLabel("Stop Loss (Points):", clrWhite);
   m_ipStopLossPoints.SetValue(m_slPoints);
   m_ipStopLossPoints.SetStep(100);
   m_ipStopLossPoints.SetDigits(0);
   m_ipStopLossPoints.SetMinValue(0);
   m_ipStopLossPoints
      .StartDraw(m_x + (m_width - 10) / 3 + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập TakeProfit Points
   m_ipTakeProfitPoints.SetLabel("Take Profit (Points):", clrWhite);
   m_ipTakeProfitPoints.SetValue(m_tpPoints);
   m_ipTakeProfitPoints.SetStep(100);
   m_ipTakeProfitPoints.SetDigits(0);
   m_ipTakeProfitPoints.SetMinValue(0);
   m_ipTakeProfitPoints.StartDraw(
      m_x + 2 * (m_width - 10) / 3 + 10,
      m_y + yOffsetPanel,
      (m_width - 10) / 3 - 10,
      45
   );

   yOffsetPanel = yOffsetPanel + 60;

   // Tạo checkbox Enable Trailing Stop
   m_cbTrailingStopEnable
      .StartDraw(m_x + 10, m_y + yOffsetPanel, m_enableTrailingStop, "Trailing Stop Settings:", 10);

   yOffsetPanel = yOffsetPanel + 20;

   // Tạo ô nhập Trailing Stop Start
   m_ipTrailingStopStart.SetLabel("TS Start (Points):", clrWhite);
   m_ipTrailingStopStart.SetValue(m_tsStartPoints);
   m_ipTrailingStopStart.SetStep(10);
   m_ipTrailingStopStart.SetDigits(0);
   m_ipTrailingStopStart.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipTrailingStopStart.UpdateDisabled(false);
   } else {
      m_ipTrailingStopStart.UpdateDisabled(true);
   }
   m_ipTrailingStopStart.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập Trailing Stop Step
   m_ipTrailingStopStep.SetLabel("TS Step (Points):", clrWhite);
   m_ipTrailingStopStep.SetValue(m_tsStepPoints);
   m_ipTrailingStopStep.SetStep(10);
   m_ipTrailingStopStep.SetDigits(0);
   m_ipTrailingStopStep.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipTrailingStopStep.UpdateDisabled(false);
   } else {
      m_ipTrailingStopStep.UpdateDisabled(true);
   }
   m_ipTrailingStopStep
      .StartDraw(m_x + (m_width - 10) / 3 + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập Trailing Stop Distance

   m_ipTrailingStopDistance.SetLabel("TS Distance (Points):", clrWhite);
   m_ipTrailingStopDistance.SetValue(m_tsDistancePoints);
   m_ipTrailingStopDistance.SetStep(10);
   m_ipTrailingStopDistance.SetDigits(0);
   m_ipTrailingStopDistance.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipTrailingStopDistance.UpdateDisabled(false);
   } else {
      m_ipTrailingStopDistance.UpdateDisabled(true);
   }
   m_ipTrailingStopDistance.StartDraw(
      m_x + 2 * (m_width - 10) / 3 + 10,
      m_y + yOffsetPanel,
      (m_width - 10) / 3 - 10,
      45
   );

   yOffsetPanel = yOffsetPanel + 65;
   // Tạo nút BUY
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnBuyName,
      "BUY",
      m_x + 10,
      m_y + yOffsetPanel,
      (m_width - 30) / 2,
      35
   );
   uiCommon.setTextColor(g_chartId, m_ObjBtnBuyName, clrWhite);
   uiCommon.setBackgroundColor(g_chartId, m_ObjBtnBuyName, m_clrBtnBuyBg);
   uiCommon.setBorderColor(g_chartId, m_ObjBtnBuyName, m_clrBtnBuyBorder);
   uiCommon.setZOrder(g_chartId, m_ObjBtnBuyName, 100);

   // Tạo nút SELL
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnSellName,
      "SELL",
      m_x + m_width / 2 + 5,
      m_y + yOffsetPanel,
      (m_width - 30) / 2,
      35
   );
   uiCommon.setTextColor(g_chartId, m_ObjBtnSellName, clrWhite);
   uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSellName, m_clrBtnSellBg);
   uiCommon.setBorderColor(g_chartId, m_ObjBtnSellName, m_clrBtnSellBorder);
   uiCommon.setZOrder(g_chartId, m_ObjBtnSellName, 100);

   yOffsetPanel = yOffsetPanel + 60;

   // Tạo nút Close All
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnCloseAllName,
      "Close All Position",
      m_x + 10,
      m_y + yOffsetPanel,
      m_width - 20,
      35
   );
   uiCommon.setTextColor(g_chartId, m_ObjBtnCloseAllName, clrWhite);
   uiCommon.setBackgroundColor(g_chartId, m_ObjBtnCloseAllName, m_clrBtnCloseAllBg); // Dark Orange
   uiCommon.setBorderColor(g_chartId, m_ObjBtnCloseAllName, m_clrBtnCloseAllBorder);
   uiCommon.setZOrder(g_chartId, m_ObjBtnCloseAllName, 100);
   yOffsetPanel = yOffsetPanel + 40;

   // Tạo label hiển thị status
   uiCommon
      .CreateLabel(g_chartId, m_ObjStatusName, " ", m_x + 8, m_y + yOffsetPanel, 8, clrOrangeRed);
}

void TDTabTrade::TabShow(bool isShow) {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      uiCommon.setShow(g_chartId, objNameList[i], isShow);
   }
}

void TDTabTrade::DestroyDraw() {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      ObjectDelete(g_chartId, objNameList[i]);
   }
}

void TDTabTrade::RefreshData() {
   // double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   SymbolInfoTick(_Symbol, Tick);
   double bid = Tick.bid;
   double ask = Tick.ask;

   uiCommon.setText(g_chartId, m_ObjBtnBuyName, "BUY: " + DoubleToString(ask, _Digits));
   uiCommon.setText(g_chartId, m_ObjBtnSellName, "SELL: " + DoubleToString(bid, _Digits));

   m_tdTablePositions.RefreshTicketPositionsData();

   double stopLossPoints = m_ipStopLossPoints.GetValue();
   double lotSize        = 0;
   if(g_volumeType == VOLUME_TYPE_INPUT) {
      m_ipLotSize.UpdateDisabled(false);
   } else if(g_volumeType == VOLUME_TYPE_MONEY) {
      m_ipLotSize.UpdateDisabled(true);
      lotSize = CalculateVolumeWithRiskMoney(g_volumeValue, stopLossPoints, _Symbol);
      m_ipLotSize.UpdateValue(lotSize);
   } else if(g_volumeType == VOLUME_TYPE_PERCENT_BALANCE) {
      m_ipLotSize.UpdateDisabled(true);
      lotSize = CalculateVolumeWithRiskPercentBalance(g_volumeValue, stopLossPoints, _Symbol);
      m_ipLotSize.UpdateValue(lotSize);
   } else if(g_volumeType == VOLUME_TYPE_PERCENT_EQUITY) {
      m_ipLotSize.UpdateDisabled(true);
      lotSize = CalculateVolumeWithRiskPercentEquity(g_volumeValue, stopLossPoints, _Symbol);
      m_ipLotSize.UpdateValue(lotSize);
   }
}

void TDTabTrade::ClickBtnBuy() {
   ObjectSetInteger(g_chartId, m_ObjBtnBuyName, OBJPROP_STATE, false);

   double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double lotSize  = m_ipLotSize.GetValue();
   double slPoints = m_ipStopLossPoints.GetValue();
   double tpPoints = m_ipTakeProfitPoints.GetValue();

   double sl       = slPoints == 0 ? 0 : ask - slPoints * _Point;
   double tp       = tpPoints == 0 ? 0 : ask + tpPoints * _Point;

   if(cTrade.Buy(lotSize, _Symbol, ask, sl, tp, "Buy by Panel")) {
      int size = ArraySize(g_positionList);
      ArrayResize(g_positionList, size + 1);
      g_positionList[size].ticket                     = PositionGetTicket(PositionsTotal() - 1);
      g_positionList[size].symbol                     = _Symbol;
      g_positionList[size].type                       = POSITION_TYPE_BUY;
      g_positionList[size].enableTrailingStop         = m_enableTrailingStop;
      g_positionList[size].trailingStopStepPoints     = m_ipTrailingStopStep.GetValue();
      g_positionList[size].trailingStopStartPoints    = m_ipTrailingStopStart.GetValue();
      g_positionList[size].trailingStopDistancePoints = m_ipTrailingStopDistance.GetValue();

      Print("✓ Lệnh BUY đã được đặt thành công!");
      Print("Giá: ", ask, " | Lot: ", lotSize);

      // Hiển thị thông báo
      string msg = StringFormat("BUY success: %.5f", ask);
      ObjectSetString(g_chartId, m_ObjStatusName, OBJPROP_TEXT, msg);
      ObjectSetInteger(g_chartId, m_ObjStatusName, OBJPROP_COLOR, clrLimeGreen);
   } else {
      Print("✗ Lỗi khi đặt lệnh BUY: ", GetLastError());
      uiCommon.setText(g_chartId, m_ObjStatusName, "ERROR: Cannot BUY");
      uiCommon.setTextColor(g_chartId, m_ObjStatusName, clrOrangeRed);
   }
   m_tdTablePositions.RefreshTicketPositionsData();
}

void TDTabTrade::ClickBtnSell() {
   ObjectSetInteger(g_chartId, m_ObjBtnSellName, OBJPROP_STATE, false);

   double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double lotSize  = m_ipLotSize.GetValue();
   double slPoints = m_ipStopLossPoints.GetValue();
   double tpPoints = m_ipTakeProfitPoints.GetValue();

   double sl       = slPoints == 0 ? 0 : bid + slPoints * _Point;
   double tp       = tpPoints == 0 ? 0 : bid - tpPoints * _Point;

   if(cTrade.Sell(lotSize, _Symbol, bid, sl, tp, "Sell by Panel")) {
      int size = ArraySize(g_positionList);
      ArrayResize(g_positionList, size + 1);
      g_positionList[size].ticket                     = PositionGetTicket(PositionsTotal() - 1);
      g_positionList[size].symbol                     = _Symbol;
      g_positionList[size].type                       = POSITION_TYPE_SELL;
      g_positionList[size].enableTrailingStop         = m_enableTrailingStop;
      g_positionList[size].trailingStopStepPoints     = m_ipTrailingStopStep.GetValue();
      g_positionList[size].trailingStopStartPoints    = m_ipTrailingStopStart.GetValue();
      g_positionList[size].trailingStopDistancePoints = m_ipTrailingStopDistance.GetValue();

      Print("✓ Lệnh SELL đã được đặt thành công!");
      Print("Giá: ", bid, " | Lot: ", lotSize);

      // Hiển thị thông báo
      string msg = StringFormat("SELL success: %.5f", bid);
      ObjectSetString(g_chartId, m_ObjStatusName, OBJPROP_TEXT, msg);
      ObjectSetInteger(g_chartId, m_ObjStatusName, OBJPROP_COLOR, clrOrange);
   } else {
      Print("✗ Lỗi khi đặt lệnh SELL: ", GetLastError());
      uiCommon.setText(g_chartId, m_ObjStatusName, "ERROR: Cannot SELL");
      uiCommon.setTextColor(g_chartId, m_ObjStatusName, clrOrangeRed);
   }
   m_tdTablePositions.RefreshTicketPositionsData();
}

void TDTabTrade::ClickBtnCloseAllPosition() {
   ObjectSetInteger(g_chartId, m_ObjBtnCloseAllName, OBJPROP_STATE, false);
   uiCommon.setText(g_chartId, m_ObjStatusName, "Closing all positions...");
   uiCommon.setTextColor(g_chartId, m_ObjStatusName, clrOrange);
   int total  = PositionsTotal();
   int closed = 0;

   for(int i = total - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0) {
         if(cTrade.PositionClose(ticket))
            closed++;
      }
   }

   uiCommon.setText(g_chartId, m_ObjStatusName, "Closed " + IntegerToString(closed) + " positions");
   uiCommon.setTextColor(g_chartId, m_ObjStatusName, clrGreen);

   m_tdTablePositions.RefreshTicketPositionsData();
}

void TDTabTrade::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_tdTablePositions.OnChartEvent(id, lparam, dparam, sparam);
   m_ipLotSize.OnChartEvent(id, lparam, dparam, sparam);
   m_ipStopLossPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTakeProfitPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_cbTrailingStopEnable.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopStart.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopStep.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopDistance.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnBuyName) {
         ClickBtnBuy();
      } else if(sparam == m_ObjBtnSellName) {
         ClickBtnSell();
      } else if(sparam == m_ObjBtnCloseAllName) {
         ClickBtnCloseAllPosition();
      }
   }
}

void TDTabTrade::OnMQLTesterEvent() {
   m_tdTablePositions.OnMQLTesterEvent();
   m_ipLotSize.OnMQLTesterEvent();
   m_ipStopLossPoints.OnMQLTesterEvent();
   m_ipTakeProfitPoints.OnMQLTesterEvent();
   m_cbTrailingStopEnable.OnMQLTesterEvent();
   m_ipTrailingStopStart.OnMQLTesterEvent();
   m_ipTrailingStopStep.OnMQLTesterEvent();
   m_ipTrailingStopDistance.OnMQLTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnBuyName)) {
      ClickBtnBuy();
   }

   if(uiCommon.getState(g_chartId, m_ObjBtnSellName)) {
      ClickBtnSell();
   }

   if(uiCommon.getState(g_chartId, m_ObjBtnCloseAllName)) {
      ClickBtnCloseAllPosition();
   }
}
