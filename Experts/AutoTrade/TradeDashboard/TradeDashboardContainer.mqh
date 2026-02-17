#include "TDTablePositions.mqh"
#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIPanel.mqh>

uint   lastUIUpdate         = 0;

string g_ObjInfomationName  = "G_OBJ_INFOMATION_NAME";
string g_ObjBtnBuyName      = "G_OBJ_BTN_BUY_NAME";
string g_ObjBtnSellName     = "G_OBJ_BTN_SELL_NAME";
string g_ObjBtnCloseAllName = "G_OBJ_BTN_CLOSE_ALL_NAME";
string g_ObjStatusName      = "G_OBJ_STATUS_NAME";

class ContainerListener {
 public:
   virtual void onIsMinimizedPanelChange(bool _isMinimized) = 0;
   virtual void onCheckedTrailingStopChange(bool newValue)  = 0;
};

class PanelContainerListener : public UIPanelListener {
 public:
   ContainerListener *m_container;
   virtual void       onIsMinimizedChange(bool _isMinimized) override {
      if(m_container) {
         m_container.onIsMinimizedPanelChange(_isMinimized);
      }
   };
   void SetContainer(ContainerListener *container) { m_container = container; };
};

class CheckboxTrailingStopListener : public UICheckboxListener {
 public:
   ContainerListener *m_container;
   virtual void       onCheckedChange(bool newValue) override {
      if(m_container) {
         m_container.onCheckedTrailingStopChange(newValue);
      }
   };
   void SetContainer(ContainerListener *container) { m_container = container; };
};

class TradeDashboardContainer : public ContainerListener {
 public:
   PanelContainerListener       m_panelContainerListener;
   CheckboxTrailingStopListener m_checkboxTrailingStopListener;

   UIPanel                      m_uiPanelContainer;
   TDTablePositions             m_tdTablePositions;

   long                         m_chartId; // ID của chart
   int                          m_x;
   int                          m_y;
   int                          m_width;
   int                          m_height;

   double                       m_lotSizeDefault;
   int                          m_slPointsDefault;
   int                          m_tpPointsDefault;
   int                          m_tsStartPointsDefault;
   int                          m_tsStepPointsDefault;
   int                          m_tsDistancePointsDefault;

   UIInputNumber                m_ipLotSize;
   UIInputNumber                m_ipStopLossPoints;
   UIInputNumber                m_ipTakeProfitPoints;

   UICheckbox                   m_cbTrailingStopEnable;
   bool                         m_enableTrailingStop;

   UIInputNumber                m_ipTrailingStopStart;
   UIInputNumber                m_ipTrailingStopStep;
   UIInputNumber                m_ipTrailingStopDistance;

   color                        m_clrBtnBuyBg;
   color                        m_clrBtnBuyBorder;
   color                        m_clrBtnSellBg;
   color                        m_clrBtnSellBorder;
   color                        m_clrBtnCloseAllBg;
   color                        m_clrBtnCloseAllBorder;

   bool                         Create(long chartId, int x, int y, int width, int height) {
      m_chartId = chartId;
      m_x       = x;
      m_y       = y;
      m_width   = width;
      m_height  = height;

      m_panelContainerListener.SetContainer(&this);
      m_checkboxTrailingStopListener.SetContainer(&this);

      PanelContainerInitialization();
      m_tdTablePositions
         .Initialization(m_chartId, m_x, m_y + m_uiPanelContainer.GetHeaderHeight() + 20, 6, 9);

      PanelContainerStartDrawContainer();
      m_tdTablePositions.StartDrawContent();

      PanelContainerStartDrawContent();

      string tableObjNameList[];
      int    countObjName = m_tdTablePositions.GetObjectNameList(tableObjNameList);
      for(int i = 0; i < countObjName; i++) {
         AddObjectName(tableObjNameList[i]);
      }

      m_enableTrailingStop = true; // set mặc định là true, để có thể set được dòng dưới
      SetEnableTrailingStop(false);

      RefreshData();
      return true;
   }

   virtual void onIsMinimizedPanelChange(bool _isMinimized) override {
      m_tdTablePositions.SetIsMinimized(_isMinimized);
   }

   virtual void onCheckedTrailingStopChange(bool newValue) override {
      SetEnableTrailingStop(newValue);
   }

   void SetEnableTrailingStop(bool enableTrailingStop) {
      if(enableTrailingStop != m_enableTrailingStop) {
         m_enableTrailingStop = enableTrailingStop;
         m_cbTrailingStopEnable.SetValue(m_enableTrailingStop);
         if(m_enableTrailingStop) {
            m_ipTrailingStopStart.SetDisabled(false);
            m_ipTrailingStopStep.SetDisabled(false);
            m_ipTrailingStopDistance.SetDisabled(false);
         } else {
            m_ipTrailingStopStart.SetDisabled(true);
            m_ipTrailingStopStep.SetDisabled(true);
            m_ipTrailingStopDistance.SetDisabled(true);
         }
      }
   }

   void SetLotSizeDefault(double lotSizeDefault) {
      m_lotSizeDefault = lotSizeDefault;
      m_ipLotSize.SetValue(m_lotSizeDefault);
   }

   void SetStopLossPointsDefault(int slPointsDefault) {
      m_slPointsDefault = slPointsDefault;
      m_ipStopLossPoints.SetValue(m_slPointsDefault);
   }
   void SetTakeProfitPointsDefault(int tpPointsDefault) {
      m_tpPointsDefault = tpPointsDefault;
      m_ipTakeProfitPoints.SetValue(m_tpPointsDefault);
   }
   void SetTrailingStopStartPointsDefault(int tsStartPointsDefault) {
      m_tsStartPointsDefault = tsStartPointsDefault;
      m_ipTrailingStopStart.SetValue(m_tsStartPointsDefault);
   }
   void SetTrailingStopStepPointsDefault(int tsStepPointsDefault) {
      m_tsStepPointsDefault = tsStepPointsDefault;
      m_ipTrailingStopStep.SetValue(m_tsStepPointsDefault);
   }
   void SetTrailingStopDistancePointsDefault(int tsDistancePointsDefault) {
      m_tsDistancePointsDefault = tsDistancePointsDefault;
      m_ipTrailingStopDistance.SetValue(m_tsDistancePointsDefault);
   }

   void PanelContainerInitialization() {
      // clang-format off
      m_clrBtnBuyBg        = C'0,128,0';       // Green
      m_clrBtnBuyBorder    = C'0,180,0';
      m_clrBtnSellBg       = C'220,20,60';     // Crimson
      m_clrBtnSellBorder   = C'255,60,100';
      m_clrBtnCloseAllBg   = C'255,140,0';     // Dark Orange
      m_clrBtnCloseAllBorder = C'255,180,80';
      // clang-format on

      m_uiPanelContainer
         .Initialization(m_chartId, "TradingPanel", m_x, m_y, m_width, m_height, true);
      m_uiPanelContainer.SetHeaderTitle("Trade Dashboard");
   }

   void PanelContainerStartDrawContainer() { m_uiPanelContainer.StartDrawContainer(); }

   bool PanelContainerStartDrawContent() {
      int yOffsetPanel = m_uiPanelContainer.GetHeaderHeight();

      uiCommon.CreateLabel(m_chartId, g_ObjInfomationName, "Thông báo: ...", 8, clrLimeGreen);
      m_uiPanelContainer.AddPanelChild(g_ObjInfomationName, 10, yOffsetPanel + 4);
      yOffsetPanel = yOffsetPanel + 20;

      yOffsetPanel = yOffsetPanel + m_tdTablePositions.GetHeight() + 10;

      // Tạo ô nhập Lot Size
      m_ipLotSize.Initialization(
         0,
         "InputLotSize",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipLotSize.SetLabel("Lot Size:", clrWhite);
      m_ipLotSize.SetValue(m_lotSizeDefault);
      m_ipLotSize.SetStep(0.01);
      m_ipLotSize.SetDigits(2);
      m_ipLotSize.SetMinValue(0.00);
      m_ipLotSize.StartDrawContent();
      string ipLotSizeObjNameList[];
      m_ipLotSize.GetObjectNameList(ipLotSizeObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipLotSizeObjNameList);

      // Tạo ô nhập StopLoss Points
      m_ipStopLossPoints.Initialization(
         0,
         "InputSlPoints",
         m_x + (m_width - 10) / 3 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipStopLossPoints.SetLabel("Stop Loss (Points):", clrWhite);
      m_ipStopLossPoints.SetValue(m_slPointsDefault);
      m_ipStopLossPoints.SetStep(100);
      m_ipStopLossPoints.SetDigits(0);
      m_ipStopLossPoints.SetMinValue(0);
      m_ipStopLossPoints.StartDrawContent();
      string ipSlPointsObjNameList[];
      m_ipStopLossPoints.GetObjectNameList(ipSlPointsObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipSlPointsObjNameList);

      // Tạo ô nhập TakeProfit Points
      m_ipTakeProfitPoints.Initialization(
         0,
         "InputTpPoints",
         m_x + 2 * (m_width - 10) / 3 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipTakeProfitPoints.SetLabel("Take Profit (Points):", clrWhite);
      m_ipTakeProfitPoints.SetValue(m_tpPointsDefault);
      m_ipTakeProfitPoints.SetStep(100);
      m_ipTakeProfitPoints.SetDigits(0);
      m_ipTakeProfitPoints.SetMinValue(0);
      m_ipTakeProfitPoints.StartDrawContent();
      string ipTpPointsObjNameList[];
      m_ipTakeProfitPoints.GetObjectNameList(ipTpPointsObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipTpPointsObjNameList);

      yOffsetPanel = yOffsetPanel + 60;

      // Tạo checkbox Enable Trailing Stop
      m_cbTrailingStopEnable.Initialization(
         0,
         "CheckboxTrailingStopEnable",
         m_x + 10,
         m_y + yOffsetPanel,
         "Trailing Stop Settings:",
         10
      );
      m_cbTrailingStopEnable.StartDrawContent();
      m_cbTrailingStopEnable.SetValue(true);
      m_cbTrailingStopEnable.SetListener(&m_checkboxTrailingStopListener);
      string cbTrailingStopEnableObjNameList[];
      m_cbTrailingStopEnable.GetObjectNameList(cbTrailingStopEnableObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(cbTrailingStopEnableObjNameList);

      yOffsetPanel = yOffsetPanel + 20;

      // Tạo ô nhập Trailing Stop Start
      m_ipTrailingStopStart.Initialization(
         0,
         "InputTrailingStopStart",
         m_x + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipTrailingStopStart.SetLabel("TS Start (Points):", clrWhite);
      m_ipTrailingStopStart.SetValue(m_tsStartPointsDefault);
      m_ipTrailingStopStart.SetStep(10);
      m_ipTrailingStopStart.SetDigits(0);
      m_ipTrailingStopStart.SetMinValue(0);
      m_ipTrailingStopStart.StartDrawContent();
      string ipTSStartObjNameList[];
      m_ipTrailingStopStart.GetObjectNameList(ipTSStartObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipTSStartObjNameList);

      // Tạo ô nhập Trailing Stop Step
      m_ipTrailingStopStep.Initialization(
         0,
         "InputTrailingStopStep",
         m_x + (m_width - 10) / 3 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipTrailingStopStep.SetLabel("TS Step (Points):", clrWhite);
      m_ipTrailingStopStep.SetValue(m_tsStepPointsDefault);
      m_ipTrailingStopStep.SetStep(10);
      m_ipTrailingStopStep.SetDigits(0);
      m_ipTrailingStopStep.SetMinValue(0);
      m_ipTrailingStopStep.StartDrawContent();
      string ipTSStepObjNameList[];
      m_ipTrailingStopStep.GetObjectNameList(ipTSStepObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipTSStepObjNameList);

      // Tạo ô nhập Trailing Stop Distance
      m_ipTrailingStopDistance.Initialization(
         0,
         "InputTrailingStopDistance",
         m_x + 2 * (m_width - 10) / 3 + 10,
         m_y + yOffsetPanel,
         (m_width - 10) / 3 - 10,
         45
      );
      m_ipTrailingStopDistance.SetLabel("TS Distance (Points):", clrWhite);
      m_ipTrailingStopDistance.SetValue(m_tsDistancePointsDefault);
      m_ipTrailingStopDistance.SetStep(10);
      m_ipTrailingStopDistance.SetDigits(0);
      m_ipTrailingStopDistance.SetMinValue(0);
      m_ipTrailingStopDistance.StartDrawContent();
      string ipTSDistanceObjNameList[];
      m_ipTrailingStopDistance.GetObjectNameList(ipTSDistanceObjNameList);
      m_uiPanelContainer.AddPanelChildNameList(ipTSDistanceObjNameList);

      yOffsetPanel = yOffsetPanel + 65;
      // Tạo nút BUY
      uiCommon.CreateButton(m_chartId, g_ObjBtnBuyName, "BUY", m_width / 2 - 20, 35);
      uiCommon.setTextColor(m_chartId, g_ObjBtnBuyName, clrWhite);
      uiCommon.setBackgroundColor(m_chartId, g_ObjBtnBuyName, m_clrBtnBuyBg);
      uiCommon.setBorderColor(m_chartId, g_ObjBtnBuyName, m_clrBtnBuyBorder);
      uiCommon.setZOrder(m_chartId, g_ObjBtnBuyName, 100);
      m_uiPanelContainer.AddPanelChild(g_ObjBtnBuyName, 10, yOffsetPanel);

      // Tạo nút SELL
      uiCommon.CreateButton(m_chartId, g_ObjBtnSellName, "SELL", m_width / 2 - 20, 35);
      uiCommon.setTextColor(m_chartId, g_ObjBtnSellName, clrWhite);
      uiCommon.setBackgroundColor(m_chartId, g_ObjBtnSellName, m_clrBtnSellBg);
      uiCommon.setBorderColor(m_chartId, g_ObjBtnSellName, m_clrBtnSellBorder);
      uiCommon.setZOrder(m_chartId, g_ObjBtnSellName, 100);
      m_uiPanelContainer.AddPanelChild(g_ObjBtnSellName, m_width / 2 + 10, yOffsetPanel);

      yOffsetPanel = yOffsetPanel + 60;

      // Tạo nút Close All
      uiCommon
         .CreateButton(m_chartId, g_ObjBtnCloseAllName, "Close All Position", m_width - 20, 35);
      uiCommon.setTextColor(m_chartId, g_ObjBtnCloseAllName, clrWhite);
      uiCommon
         .setBackgroundColor(m_chartId, g_ObjBtnCloseAllName, m_clrBtnCloseAllBg); // Dark Orange
      uiCommon.setBorderColor(m_chartId, g_ObjBtnCloseAllName, m_clrBtnCloseAllBorder);
      uiCommon.setZOrder(m_chartId, g_ObjBtnCloseAllName, 100);
      m_uiPanelContainer.AddPanelChild(g_ObjBtnCloseAllName, 10, yOffsetPanel);
      yOffsetPanel = yOffsetPanel + 40;

      // Tạo label hiển thị status
      uiCommon.CreateLabel(m_chartId, g_ObjStatusName, " ", 8, clrOrangeRed);
      m_uiPanelContainer.AddPanelChild(g_ObjStatusName, 10, yOffsetPanel);

      m_uiPanelContainer.PanelRefreshPosition();
      return true;
   }

   void AddObjectName(string objName) { m_uiPanelContainer.AddPanelChildName(objName); }

   void ExecuteBuy() {
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
         string msg = StringFormat("BUY thành công: %.5f", ask);
         ObjectSetString(m_chartId, g_ObjStatusName, OBJPROP_TEXT, msg);
         ObjectSetInteger(m_chartId, g_ObjStatusName, OBJPROP_COLOR, clrLimeGreen);
      } else {
         Print("✗ Lỗi khi đặt lệnh BUY: ", GetLastError());
         uiCommon.setText(m_chartId, g_ObjStatusName, "Lỗi: Không thể BUY");
         uiCommon.setTextColor(m_chartId, g_ObjStatusName, clrOrangeRed);
      }
      m_tdTablePositions.RefreshTicketPositionsData();
   }

   //+------------------------------------------------------------------+
   //| Thực hiện lệnh SELL                                               |
   //+------------------------------------------------------------------+
   void ExecuteSell() {
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
         string msg = StringFormat("SELL thành công: %.5f", bid);
         ObjectSetString(m_chartId, g_ObjStatusName, OBJPROP_TEXT, msg);
         ObjectSetInteger(m_chartId, g_ObjStatusName, OBJPROP_COLOR, clrOrange);
      } else {
         Print("✗ Lỗi khi đặt lệnh SELL: ", GetLastError());
         uiCommon.setText(m_chartId, g_ObjStatusName, "Lỗi: Không thể SELL");
         uiCommon.setTextColor(m_chartId, g_ObjStatusName, clrOrangeRed);
      }
      m_tdTablePositions.RefreshTicketPositionsData();
   }

   void ExcuteCloseAllPositions() {
      uiCommon.setText(m_chartId, g_ObjStatusName, "Đang đóng tất cả lệnh...");
      uiCommon.setTextColor(m_chartId, g_ObjStatusName, clrOrange);
      m_uiPanelContainer.StartRedrawChart();
      int total  = PositionsTotal();
      int closed = 0;

      for(int i = total - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0) {
            if(cTrade.PositionClose(ticket))
               closed++;
         }
      }

      uiCommon.setText(m_chartId, g_ObjStatusName, "Đã đóng " + IntegerToString(closed) + " lệnh");
      uiCommon.setTextColor(m_chartId, g_ObjStatusName, clrGreen);
      m_uiPanelContainer.StartRedrawChart();
   }

   void StartProcessTrailingStop();
   void RefreshData();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterRefresh();
   void OnMQLTesterEvent();
};

void TradeDashboardContainer::RefreshData() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   uiCommon.setText(m_chartId, g_ObjBtnBuyName, "BUY: " + DoubleToString(ask, _Digits));
   uiCommon.setText(m_chartId, g_ObjBtnSellName, "SELL: " + DoubleToString(bid, _Digits));

   m_tdTablePositions.RefreshTicketPositionsData();
}

void TradeDashboardContainer::StartProcessTrailingStop() {
   int totalPositions = PositionsTotal();
   for(int i = 0; i < totalPositions; i++) {
      if(!g_positionList[i].enableTrailingStop) {
         continue;
      }
      if(!PositionSelectByTicket(g_positionList[i].ticket)) {
         continue;
      }

      string symbol           = PositionGetString(POSITION_SYMBOL);
      double priceOpen        = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl               = PositionGetDouble(POSITION_SL);
      double tp               = PositionGetDouble(POSITION_TP);

      double tsStartPoints    = g_positionList[i].trailingStopStartPoints;
      double tsStepPoints     = g_positionList[i].trailingStopStepPoints;
      double tsDistancePoints = g_positionList[i].trailingStopDistancePoints;

      double POINT            = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if(g_positionList[i].type == POSITION_TYPE_BUY) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if((bid - priceOpen) >= tsStartPoints * POINT) {
            double newStopLoss = priceOpen + (tsStartPoints - tsDistancePoints) * POINT;
            if(sl < newStopLoss || sl == 0) {
               cTrade.PositionModify(g_positionList[i].ticket, newStopLoss, tp);
               g_positionList[i].trailingStopStartPoints += tsStepPoints;
            }
         }
      } else if(g_positionList[i].type == POSITION_TYPE_SELL) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if((priceOpen - ask) >= tsStartPoints * POINT) {
            double newStopLoss = priceOpen - (tsStartPoints - tsDistancePoints) * POINT;
            if(sl > newStopLoss || sl == 0) {
               cTrade.PositionModify(g_positionList[i].ticket, newStopLoss, tp);
               g_positionList[i].trailingStopStartPoints += tsStepPoints;
            }
         }
      }
   }
}

void TradeDashboardContainer::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_uiPanelContainer.OnChartEvent(id, lparam, dparam, sparam);
   m_tdTablePositions.OnChartEvent(id, lparam, dparam, sparam);
   m_ipLotSize.OnChartEvent(id, lparam, dparam, sparam);
   m_ipStopLossPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTakeProfitPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_cbTrailingStopEnable.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopStart.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopStep.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTrailingStopDistance.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      // Xử lý click nút Buy
      if(sparam == g_ObjBtnBuyName) {
         ExecuteBuy();
         ObjectSetInteger(m_chartId, g_ObjBtnBuyName, OBJPROP_STATE, false);
      }
      // Xử lý click nút Sell
      else if(sparam == g_ObjBtnSellName) {
         ExecuteSell();
         ObjectSetInteger(m_chartId, g_ObjBtnSellName, OBJPROP_STATE, false);
      }
      // Xử lý click nút Close All
      else if(sparam == g_ObjBtnCloseAllName) {
         ExcuteCloseAllPositions();
         ObjectSetInteger(m_chartId, g_ObjBtnCloseAllName, OBJPROP_STATE, false);
      }
      m_uiPanelContainer.StartRedrawChart();
   }
}

void TradeDashboardContainer::OnMQLTesterRefresh() {
   RefreshData();
   StartProcessTrailingStop();
   m_tdTablePositions.RefreshTicketPositionsData();
}

void TradeDashboardContainer::OnMQLTesterEvent() {
   m_uiPanelContainer.OnMQLTesterEvent();
   m_tdTablePositions.OnMQLTesterEvent();
   m_ipLotSize.OnMQLTesterEvent();
   m_ipStopLossPoints.OnMQLTesterEvent();
   m_ipTakeProfitPoints.OnMQLTesterEvent();
   m_cbTrailingStopEnable.OnMQLTesterEvent();
   m_ipTrailingStopStart.OnMQLTesterEvent();
   m_ipTrailingStopStep.OnMQLTesterEvent();
   m_ipTrailingStopDistance.OnMQLTesterEvent();

   bool btnBuyState = uiCommon.getState(m_chartId, g_ObjBtnBuyName);
   if(btnBuyState == true) {
      ExecuteBuy();
      ObjectSetInteger(m_chartId, g_ObjBtnBuyName, OBJPROP_STATE, false);
   }

   bool btnSellState = uiCommon.getState(m_chartId, g_ObjBtnSellName);
   if(btnSellState == true) {
      ExecuteSell();
      ObjectSetInteger(m_chartId, g_ObjBtnSellName, OBJPROP_STATE, false);
   }

   bool btnCloseAllState = uiCommon.getState(m_chartId, g_ObjBtnCloseAllName);
   if(btnCloseAllState == true) {
      ExcuteCloseAllPositions();
      ObjectSetInteger(m_chartId, g_ObjBtnCloseAllName, OBJPROP_STATE, false);
   }
}
