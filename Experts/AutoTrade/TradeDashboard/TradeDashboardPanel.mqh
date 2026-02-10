#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIPanel.mqh>

UIPanel uiPanel;

string  g_ObjStatusName      = "G_OBJ_STATUS_NAME";
string  g_ObjBtnBuyName      = "G_OBJ_BTN_BUY_NAME";
string  g_ObjBtnSellName     = "G_OBJ_BTN_SELL_NAME";
string  g_ObjBtnCloseAllName = "G_OBJ_BTN_CLOSE_ALL_NAME";
string  g_ObjLblVolumeName   = "G_OBJ_LABEL_VOLUME_NAME";
string  g_ObjLblSlName       = "G_OBJ_LABEL_SL_NAME";
string  g_ObjLblTpName       = "G_OBJ_LABEL_TP_NAME";
string  g_ObjEdtVolumeName   = "G_OBJ_EDT_VOLUME_NAME";
string  g_ObjEdtSlName       = "G_OBJ_EDT_SL_NAME";
string  g_ObjEdtTpName       = "G_OBJ_EDT_TP_NAME";

class TradeDashboardPanel {
 public:
   color  clrBtnBuyBg;
   color  clrBtnBuyBorder;
   color  clrBtnSellBg;
   color  clrBtnSellBorder;
   color  clrBtnCloseAllBg;
   color  clrBtnCloseAllBorder;
   double lotSizeDefault;
   int    slPointsDefault;
   int    tpPointsDefault;
   bool   Create() {
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

      if(!uiPanel.Initialization(0, "TradingPanel", panelX, panelY, panelWidth, panelHeight)) {
         Print("Không thể tạo panel!");
         return false;
      }
      uiPanel.SetHeaderTitle("Trade Dashboard");
      CreatePanelContent();
      uiPanel.PanelRedrawChart();
      return true;
   }

   bool CreatePanelContent() {
      uiCommon.CreateLabel(0, g_ObjStatusName, "Chờ dữ liệu...", 8, clrLimeGreen);
      uiPanel.AddPanelChild(g_ObjStatusName, 10, 40);

      // Tạo ô nhập Lot Size
      uiCommon.CreateLabel(0, g_ObjLblVolumeName, "Lot Size:", 8, clrWhite);
      uiPanel.AddPanelChild(g_ObjLblVolumeName, 10, 225);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtVolumeName,
         (panelWidth - 10) / 3 - 10,
         22,
         DoubleToString(lotSizeDefault, 2)
      );
      uiPanel.AddPanelChild(g_ObjEdtVolumeName, 10, 240);

      // Tạo ô nhập Stop Loss
      uiCommon.CreateLabel(0, g_ObjLblSlName, "Stop Loss (SL):", 8, clrWhite);
      uiPanel.AddPanelChild(g_ObjLblSlName, (panelWidth - 10) / 3 + 10, 225);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtSlName,
         (panelWidth - 10) / 3 - 10,
         22,
         IntegerToString(slPointsDefault)
      );
      uiPanel.AddPanelChild(g_ObjEdtSlName, (panelWidth - 10) / 3 + 10, 240);

      // Tạo ô nhập Take Profit
      uiCommon.CreateLabel(0, g_ObjLblTpName, "Take Profit (TP):", 8, clrWhite);
      uiPanel.AddPanelChild(g_ObjLblTpName, 2 * (panelWidth - 10) / 3 + 10, 225);
      uiCommon.CreateEdit(
         0,
         g_ObjEdtTpName,
         (panelWidth - 10) / 3 - 10,
         22,
         IntegerToString(tpPointsDefault)
      );
      uiPanel.AddPanelChild(g_ObjEdtTpName, 2 * (panelWidth - 10) / 3 + 10, 240);

      // Tạo nút BUY
      uiCommon.CreateButton(0, g_ObjBtnBuyName, "BUY", panelWidth / 2 - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnBuyName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnBuyName, clrBtnBuyBg);
      uiCommon.setBorderColor(0, g_ObjBtnBuyName, clrBtnBuyBorder);
      uiCommon.setZOrder(0, g_ObjBtnBuyName, 100);
      uiPanel.AddPanelChild(g_ObjBtnBuyName, 10, 280);

      // Tạo nút SELL
      uiCommon.CreateButton(0, g_ObjBtnSellName, "SELL", panelWidth / 2 - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnSellName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnSellName, clrBtnSellBg);
      uiCommon.setBorderColor(0, g_ObjBtnSellName, clrBtnSellBorder);
      uiCommon.setZOrder(0, g_ObjBtnSellName, 100);
      uiPanel.AddPanelChild(g_ObjBtnSellName, panelWidth / 2 + 10, 280);

      // Tạo nút Close All
      uiCommon.CreateButton(0, g_ObjBtnCloseAllName, "Close All Position", panelWidth - 20, 35);
      uiCommon.setTextColor(0, g_ObjBtnCloseAllName, clrWhite);
      uiCommon.setBackgroundColor(0, g_ObjBtnCloseAllName, clrBtnCloseAllBg); // Dark Orange
      uiCommon.setBorderColor(0, g_ObjBtnCloseAllName, clrBtnCloseAllBorder);
      uiCommon.setZOrder(0, g_ObjBtnCloseAllName, 100);
      uiPanel.AddPanelChild(g_ObjBtnCloseAllName, 10, panelHeight - 40);

      // Tạo label hiển thị status
      uiCommon.CreateLabel(0, g_ObjStatusName, " ", 8, clrOrangeRed);
      uiPanel.AddPanelChild(g_ObjStatusName, 10, panelHeight);

      uiPanel.PanelRefreshPosition(panelX, panelY);
      return true;
   }

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

   void RefreshData() {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      uiCommon.setText(0, g_ObjBtnBuyName, "BUY: " + DoubleToString(ask, _Digits));
      uiCommon.setText(0, g_ObjBtnSellName, "SELL: " + DoubleToString(bid, _Digits));

      uiPanel.PanelRedrawChart();
   }

   void ExcuteCloseAllPositions() {
      uiCommon.setText(0, g_ObjStatusName, "Đang đóng tất cả lệnh...");
      uiCommon.setTextColor(0, g_ObjStatusName, clrOrange);
      uiPanel.PanelRedrawChart();
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
      uiPanel.PanelRedrawChart();
   }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      uiPanel.OnChartEvent(id, lparam, dparam, sparam);

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
         uiPanel.PanelRedrawChart();
      }

      return true;
   }
};
