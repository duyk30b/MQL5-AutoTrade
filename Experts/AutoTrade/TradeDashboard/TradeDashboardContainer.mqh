#include "TDTablePositions.mqh"
#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIPanel.mqh>

UIPanel          uiPanelContainer;
TDTablePositions tdTablePositions;

uint             lastUIUpdate         = 0;

string           g_ObjInfomationName  = "G_OBJ_INFOMATION_NAME";
string           g_ObjBtnBuyName      = "G_OBJ_BTN_BUY_NAME";
string           g_ObjBtnSellName     = "G_OBJ_BTN_SELL_NAME";
string           g_ObjBtnCloseAllName = "G_OBJ_BTN_CLOSE_ALL_NAME";
string           g_ObjLblVolumeName   = "G_OBJ_LABEL_VOLUME_NAME";
string           g_ObjLblSlName       = "G_OBJ_LABEL_SL_NAME";
string           g_ObjLblTpName       = "G_OBJ_LABEL_TP_NAME";
string           g_ObjEdtVolumeName   = "G_OBJ_EDT_VOLUME_NAME";
string           g_ObjEdtSlName       = "G_OBJ_EDT_SL_NAME";
string           g_ObjEdtTpName       = "G_OBJ_EDT_TP_NAME";
string           g_ObjStatusName      = "G_OBJ_STATUS_NAME";

class TradeDashboardContainer {
 public:
   int    m_x;
   int    m_y;
   int    m_width;
   int    m_height;

   color  clrBtnBuyBg;
   color  clrBtnBuyBorder;
   color  clrBtnSellBg;
   color  clrBtnSellBorder;
   color  clrBtnCloseAllBg;
   color  clrBtnCloseAllBorder;
   double lotSizeDefault;
   int    slPointsDefault;
   int    tpPointsDefault;
   bool   Create(int _x, int _y, int _width, int _height) {
      m_x      = _x;
      m_y      = _y;
      m_width  = _width;
      m_height = _height;

      PanelContainerInitialization();
      tdTablePositions.Initialization(m_x, m_y + uiPanelContainer.GetHeaderHeight() + 20, 6, 9);

      PanelContainerStartDrawContainer();
      tdTablePositions.StartDrawContent();

      PanelContainerStartDrawContent();

      string tableObjNameList[];
      int    countObjName = tdTablePositions.GetObjectNameList(tableObjNameList);
      for(int i = 0; i < countObjName; i++) {
         AddObjectName(tableObjNameList[i]);
      }

      RefreshData();
      return true;
   }

   virtual void onChangePage(int newPage) {
      Print("•>[TradeDashboardContainer.mqh:63]: newPage: ", newPage);
      RefreshData();
   }

   void RefreshDataByTimer() { tdTablePositions.RefreshTicketPositionsData(); }
   void RefreshDataByTick() {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      uiCommon.setText(0, g_ObjBtnBuyName, "BUY: " + DoubleToString(ask, _Digits));
      uiCommon.setText(0, g_ObjBtnSellName, "SELL: " + DoubleToString(bid, _Digits));

      uiPanelContainer.StartRedrawChart();
   }

   void RefreshData() {
      tdTablePositions.RefreshTicketPositionsData();

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      uiCommon.setText(0, g_ObjBtnBuyName, "BUY: " + DoubleToString(ask, _Digits));
      uiCommon.setText(0, g_ObjBtnSellName, "SELL: " + DoubleToString(bid, _Digits));

      uiPanelContainer.StartRedrawChart();
   }

   bool PanelContainerInitialization() {
      // clang-format off
      clrBtnBuyBg        = C'0,128,0';       // Green
      clrBtnBuyBorder    = C'0,180,0';
      clrBtnSellBg       = C'220,20,60';     // Crimson
      clrBtnSellBorder   = C'255,60,100';
      clrBtnCloseAllBg   = C'255,140,0';     // Dark Orange
      clrBtnCloseAllBorder = C'255,180,80';
      // clang-format on

      lotSizeDefault  = 0.1;
      slPointsDefault = 500;
      tpPointsDefault = 1000;

      uiPanelContainer.Initialization(0, "TradingPanel", m_x, m_y, m_width, m_height);
      uiPanelContainer.SetHeaderTitle("Trade Dashboard");
      return true;
   }

   void PanelContainerStartDrawContainer() { uiPanelContainer.StartDrawContainer(); }

   bool PanelContainerStartDrawContent() {
      int yPos = uiPanelContainer.GetHeaderHeight();

      uiCommon.CreateLabel(0, g_ObjInfomationName, "Thông báo: ...", 8, clrLimeGreen);
      uiPanelContainer.AddPanelChild(g_ObjInfomationName, 10, yPos + 4);
      yPos = yPos + 20;

      // Thêm chiều cao của bảng
      yPos = yPos + tdTablePositions.GetHeight() + 10;

      // Tạo ô nhập Lot Size
      uiCommon.CreateLabel(0, g_ObjLblVolumeName, "Lot Size:", 8, clrWhite);
      uiPanelContainer.AddPanelChild(g_ObjLblVolumeName, 10, yPos);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtVolumeName,
         (m_width - 10) / 3 - 10,
         22,
         DoubleToString(lotSizeDefault, 2)
      );
      uiPanelContainer.AddPanelChild(g_ObjEdtVolumeName, 10, yPos + 15);

      // Tạo ô nhập Stop Loss
      uiCommon.CreateLabel(0, g_ObjLblSlName, "Stop Loss (Points):", 8, clrWhite);
      uiPanelContainer.AddPanelChild(g_ObjLblSlName, (m_width - 10) / 3 + 10, yPos);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtSlName,
         (m_width - 10) / 3 - 10,
         22,
         IntegerToString(slPointsDefault)
      );
      uiPanelContainer.AddPanelChild(g_ObjEdtSlName, (m_width - 10) / 3 + 10, yPos + 15);

      // Tạo ô nhập Take Profit
      uiCommon.CreateLabel(0, g_ObjLblTpName, "Take Profit (Points):", 8, clrWhite);
      uiPanelContainer.AddPanelChild(g_ObjLblTpName, 2 * (m_width - 10) / 3 + 10, yPos);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtTpName,
         (m_width - 10) / 3 - 10,
         22,
         IntegerToString(tpPointsDefault)
      );
      uiPanelContainer.AddPanelChild(g_ObjEdtTpName, 2 * (m_width - 10) / 3 + 10, yPos + 15);

      yPos = yPos + 15 + 30;

      // Tạo nút BUY
      uiCommon.CreateButton(0, g_ObjBtnBuyName, "BUY", m_width / 2 - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnBuyName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnBuyName, clrBtnBuyBg);
      uiCommon.setBorderColor(0, g_ObjBtnBuyName, clrBtnBuyBorder);
      uiCommon.setZOrder(0, g_ObjBtnBuyName, 100);
      uiPanelContainer.AddPanelChild(g_ObjBtnBuyName, 10, yPos);

      // Tạo nút SELL
      uiCommon.CreateButton(0, g_ObjBtnSellName, "SELL", m_width / 2 - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnSellName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnSellName, clrBtnSellBg);
      uiCommon.setBorderColor(0, g_ObjBtnSellName, clrBtnSellBorder);
      uiCommon.setZOrder(0, g_ObjBtnSellName, 100);
      uiPanelContainer.AddPanelChild(g_ObjBtnSellName, m_width / 2 + 10, yPos);

      yPos = yPos + 60;

      // Tạo nút Close All
      uiCommon.CreateButton(0, g_ObjBtnCloseAllName, "Close All Position", m_width - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnCloseAllName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnCloseAllName, clrBtnCloseAllBg); // Dark Orange
      uiCommon.setBorderColor(0, g_ObjBtnCloseAllName, clrBtnCloseAllBorder);
      uiCommon.setZOrder(0, g_ObjBtnCloseAllName, 100);
      uiPanelContainer.AddPanelChild(g_ObjBtnCloseAllName, 10, yPos);
      yPos = yPos + 40;

      // Tạo label hiển thị status
      uiCommon.CreateLabel(0, g_ObjStatusName, " ", 8, clrOrangeRed);
      uiPanelContainer.AddPanelChild(g_ObjStatusName, 10, yPos);

      uiPanelContainer.PanelRefreshPosition();
      return true;
   }

   void AddObjectName(string objName) { uiPanelContainer.AddPanelChildName(objName); }

   void ExecuteBuy() {
      double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double lotSize  = StringToDouble(ObjectGetString(0, g_ObjEdtVolumeName, OBJPROP_TEXT));
      int    slPoints = (int)StringToInteger(ObjectGetString(0, g_ObjEdtSlName, OBJPROP_TEXT));
      int    tpPoints = (int)StringToInteger(ObjectGetString(0, g_ObjEdtTpName, OBJPROP_TEXT));
      if(slPoints < 0)
         slPoints = slPointsDefault; // Nếu không nhập SL thì dùng giá trị Input
      if(tpPoints < 0)
         tpPoints = tpPointsDefault; // Nếu không nhập TP thì dùng giá trị Input
      double sl = slPoints == 0 ? 0 : ask - slPoints * _Point;
      double tp = tpPoints == 0 ? 0 : ask + tpPoints * _Point;

      if(cTrade.Buy(lotSize, _Symbol, ask, sl, tp, "Buy từ Panel")) {
         Print("✓ Lệnh BUY đã được đặt thành công!");
         Print("Giá: ", ask, " | Lot: ", lotSize);

         // Hiển thị thông báo
         string msg = StringFormat("BUY thành công: %.5f", ask);
         ObjectSetString(0, g_ObjStatusName, OBJPROP_TEXT, msg);
         ObjectSetInteger(0, g_ObjStatusName, OBJPROP_COLOR, clrLimeGreen);
      } else {
         Print("✗ Lỗi khi đặt lệnh BUY: ", GetLastError());
         uiCommon.setText(0, g_ObjStatusName, "Lỗi: Không thể BUY");
         uiCommon.setTextColor(0, g_ObjStatusName, clrOrangeRed);
      }

      ChartRedraw();
   }

   //+------------------------------------------------------------------+
   //| Thực hiện lệnh SELL                                               |
   //+------------------------------------------------------------------+
   void ExecuteSell() {
      double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double lotSize  = StringToDouble(ObjectGetString(0, g_ObjEdtVolumeName, OBJPROP_TEXT));
      int    slPoints = (int)StringToInteger(ObjectGetString(0, g_ObjEdtSlName, OBJPROP_TEXT));
      int    tpPoints = (int)StringToInteger(ObjectGetString(0, g_ObjEdtTpName, OBJPROP_TEXT));
      if(slPoints < 0)
         slPoints = slPointsDefault; // Nếu không nhập SL thì dùng giá trị Input
      if(tpPoints < 0)
         tpPoints = tpPointsDefault; // Nếu không nhập TP thì dùng giá trị Input

      double sl = slPoints == 0 ? 0 : bid + slPoints * _Point;
      double tp = tpPoints == 0 ? 0 : bid - tpPoints * _Point;

      if(cTrade.Sell(lotSize, _Symbol, bid, sl, tp, "Sell từ Panel")) {
         Print("✓ Lệnh SELL đã được đặt thành công!");
         Print("Giá: ", bid, " | Lot: ", lotSize);

         // Hiển thị thông báo
         string msg = StringFormat("SELL thành công: %.5f", bid);
         ObjectSetString(0, g_ObjStatusName, OBJPROP_TEXT, msg);
         ObjectSetInteger(0, g_ObjStatusName, OBJPROP_COLOR, clrOrange);
      } else {
         Print("✗ Lỗi khi đặt lệnh SELL: ", GetLastError());
         uiCommon.setText(0, g_ObjStatusName, "Lỗi: Không thể SELL");
         uiCommon.setTextColor(0, g_ObjStatusName, clrOrangeRed);
      }
      ChartRedraw();
   }

   void ExcuteCloseAllPositions() {
      uiCommon.setText(0, g_ObjStatusName, "Đang đóng tất cả lệnh...");
      uiCommon.setTextColor(0, g_ObjStatusName, clrOrange);
      uiPanelContainer.StartRedrawChart();
      int total  = PositionsTotal();
      int closed = 0;

      for(int i = total - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0) {
            if(cTrade.PositionClose(ticket))
               closed++;
         }
      }

      uiCommon.setText(0, g_ObjStatusName, "Đã đóng " + IntegerToString(closed) + " lệnh");
      uiCommon.setTextColor(0, g_ObjStatusName, clrGreen);
      uiPanelContainer.StartRedrawChart();
   }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      uiPanelContainer.OnChartEvent(id, lparam, dparam, sparam);
      tdTablePositions.OnChartEvent(id, lparam, dparam, sparam);

      if(id == CHARTEVENT_OBJECT_CLICK) {
         // Xử lý click nút Buy
         if(sparam == g_ObjBtnBuyName) {
            ExecuteBuy();
            ObjectSetInteger(0, g_ObjBtnBuyName, OBJPROP_STATE, false);
         }
         // Xử lý click nút Sell
         else if(sparam == g_ObjBtnSellName) {
            ExecuteSell();
            ObjectSetInteger(0, g_ObjBtnSellName, OBJPROP_STATE, false);
         }
         // Xử lý click nút Close All
         else if(sparam == g_ObjBtnCloseAllName) {
            ExcuteCloseAllPositions();
            ObjectSetInteger(0, g_ObjBtnCloseAllName, OBJPROP_STATE, false);
         }
         uiPanelContainer.StartRedrawChart();
      }

      return true;
   }

   void ProcessOnMQLTester() {
      if((GetTickCount() - lastUIUpdate) < 500) {
         return;
      }
      lastUIUpdate = GetTickCount();

      uiPanelContainer.ProcessOnMQLTester();
      tdTablePositions.ProcessOnMQLTester();

      RefreshData();
      tdTablePositions.RefreshTicketPositionsData();

      bool btnBuyState = uiCommon.getState(0, g_ObjBtnBuyName);
      if(btnBuyState == true) {
         ExecuteBuy();
         ObjectSetInteger(0, g_ObjBtnBuyName, OBJPROP_STATE, false);
      }

      bool btnSellState = uiCommon.getState(0, g_ObjBtnSellName);
      if(btnSellState == true) {
         ExecuteSell();
         ObjectSetInteger(0, g_ObjBtnSellName, OBJPROP_STATE, false);
      }

      bool btnCloseAllState = uiCommon.getState(0, g_ObjBtnCloseAllName);
      if(btnCloseAllState == true) {
         ExcuteCloseAllPositions();
         ObjectSetInteger(0, g_ObjBtnCloseAllName, OBJPROP_STATE, false);
      }
   }
};
