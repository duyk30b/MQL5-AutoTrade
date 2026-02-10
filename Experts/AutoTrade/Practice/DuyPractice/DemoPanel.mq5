//+------------------------------------------------------------------+
//|        TradingPanelDemo.mq5  | EA Demo sử dụng UIPanel   |
//+------------------------------------------------------------------+
#property copyright "Trading Panel Demo"
#property link ""
#property version "1.00"

#include <AutoTrade/UI/UICommon.mqh>
#include <AutoTrade/UI/UIPanel.mqh>
#include <Trade/Trade.mqh>

//--- Global variables
CTrade       cTrade;
UIPanel      uiPanel;
UICommon     uiCommon;

input ulong  MagicNumber  = 20260206;
input int    Slippage     = 5;
input double InputLotSize = 0.1; // Lot size

int          panelX       = 20;
int          panelY       = 30;

// Tên các objects
string g_objPrice       = "Panel_Price";
string g_objStatus      = "Panel_Status";
string g_objBtnBuy      = "Panel_BtnBuy";
string g_objBtnSell     = "Panel_BtnSell";
string g_objBtnCloseAll = "Panel_BtnCloseAllPosition";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CreateUIControls()) {
      Print("Không thể tạo controls!");
      return INIT_FAILED;
   }
   RefreshData();
   cTrade.SetExpertMagicNumber(MagicNumber);
   cTrade.SetDeviationInPoints(Slippage);
   Print("====== EA khởi tạo thành công, MagicNumber = ", MagicNumber, " =====");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   uiPanel.PanelDestroy();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {
   if((bool)MQLInfoInteger(MQL_TESTER) && (bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
      ProcessOnMQLTester();
   }

   RefreshData();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   // Xử lý sự kiện của panel
   uiPanel.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      // Xử lý click nút Buy
      if(sparam == g_objBtnBuy) {
         ExecuteBuy();
         ObjectSetInteger(0, g_objBtnBuy, OBJPROP_STATE, false);
      }
      // Xử lý click nút Sell
      else if(sparam == g_objBtnSell) {
         ExecuteSell();
         ObjectSetInteger(0, g_objBtnSell, OBJPROP_STATE, false);
      }
      // Xử lý click nút Close All
      else if(sparam == g_objBtnCloseAll) {
         ExcuteCloseAllPositions();
         ObjectSetInteger(0, g_objBtnCloseAll, OBJPROP_STATE, false);
      }
      // Xử lý click nút sửa
      else if(StringFind(sparam, "EditPos_") == 0) {
         ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 8));
         ShowEditDialog(ticket);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      // Xử lý click nút đóng
      else if(StringFind(sparam, "ClosePos_") == 0) {
         ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 9));
         CloseTicketPosition(ticket);
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      uiPanel.PanelRedrawChart();
   }
}

//+------------------------------------------------------------------+
//| Tạo các controls trong panel                                     |
//+------------------------------------------------------------------+
bool CreateUIControls() {
   // Tạo panel
   int panelWidth  = 300;
   int panelHeight = 400;
   if(!uiPanel.Create(0, "TradingPanel", panelX, panelY, panelWidth, panelHeight)) {
      Print("Không thể tạo panel!");
      return false;
   }
   uiPanel.SetHeaderTitle("Trading Panel");

   // Tạo label hiển thị giá
   uiCommon.CreateLabel(0, g_objPrice, "Chờ dữ liệu...", 8, clrLimeGreen);
   uiPanel.AddPanelChild(g_objPrice, 10, 40);

   // Tạo nút BUY
   uiCommon.CreateButton(0, g_objBtnBuy, "BUY", 135, 35);
   // clang-format off
   uiCommon.setTextColor(0, g_objBtnBuy, clrWhite);
   uiCommon.setBackgroundColor(0, g_objBtnBuy, C'0,128,0');
   uiCommon.setBorderColor(0, g_objBtnBuy,  C'0,180,0');
   uiCommon.setZOrder(0, g_objBtnBuy, 100);
   // clang-format on
   uiPanel.AddPanelChild(g_objBtnBuy, 10, 60);

   // Tạo nút SELL
   uiCommon.CreateButton(0, g_objBtnSell, "SELL", 135, 35);
   // clang-format off
   uiCommon.setTextColor(0, g_objBtnSell, clrWhite);
   uiCommon.setBackgroundColor(0, g_objBtnSell, C'220,20,60');
   uiCommon.setBorderColor(0, g_objBtnSell,  C'255,60,100');
      uiCommon.setZOrder(0, g_objBtnSell, 100);
   // clang-format on
   uiPanel.AddPanelChild(g_objBtnSell, 155, 60);

   // Tạo nút Close All
   uiCommon.CreateButton(0, g_objBtnCloseAll, "Close All Position", 280, 35);
   // clang-format off
   uiCommon.setTextColor(0, g_objBtnCloseAll, clrWhite);
   uiCommon.setBackgroundColor(0, g_objBtnCloseAll, C'255,140,0');   // Dark Orange
   uiCommon.setBorderColor(0, g_objBtnCloseAll,    C'255,180,80');
   // clang-format on

   uiPanel.AddPanelChild(g_objBtnCloseAll, 10, panelHeight - 40);

   // Tạo label hiển thị status
   uiCommon.CreateLabel(0, g_objStatus, " ", 8, clrOrangeRed);
   uiPanel.AddPanelChild(g_objStatus, 10, panelHeight);

   uiPanel.PanelRefreshPosition(panelX, panelY);
   uiPanel.PanelRedrawChart();
   return true;
}

void RefreshData() {
   double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   string priceText = StringFormat("Bid: %.5f | Ask: %.5f", bid, ask);

   if(ObjectFind(0, g_objPrice) >= 0) {
      uiCommon.setText(0, g_objPrice, priceText);
   }
   UpdatePositionsList();
   uiPanel.PanelRedrawChart();
}

void UpdatePositionsList() {
   int totalPositions = PositionsTotal();
   int yPos           = panelY + 120;

   // Header
   ObjectCreate(0, "PosHeader", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "PosHeader", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "PosHeader", OBJPROP_YDISTANCE, yPos - 20);
   ObjectSetInteger(0, "PosHeader", OBJPROP_COLOR, clrWhite);
   ObjectSetString(
      0,
      "PosHeader",
      OBJPROP_TEXT,
      "Positions (" + IntegerToString(totalPositions) + ")"
   );
   ObjectSetString(0, "PosHeader", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "PosHeader", OBJPROP_FONTSIZE, 9);

   for(int i = 0; i < totalPositions && i < 10; i++) {
      ulong ticket = PositionGetTicket(i);

      ObjectDelete(0, "PosLabel_" + IntegerToString(ticket));
      ObjectDelete(0, "EditPos_" + IntegerToString(ticket));
      ObjectDelete(0, "ClosePos_" + IntegerToString(ticket));

      if(ticket > 0) {
         string symbol    = PositionGetString(POSITION_SYMBOL);
         long   type      = PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit    = PositionGetDouble(POSITION_PROFIT);
         double sl        = PositionGetDouble(POSITION_SL);
         double tp        = PositionGetDouble(POSITION_TP);
         double volume    = PositionGetDouble(POSITION_VOLUME);

         string typeStr   = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         // clang-format off
         color  profitColor = (profit >= 0) ? C'80,200,140' // xanh ngọc – dễ chịu hơn clrGreen
                                            : C'220,90,90'; // đỏ trầm – không chói
         // clang-format on
         // Thông tin position
         string posInfo
            = StringFormat("%s %.2f | %.5f | P: %.2f", typeStr, volume, openPrice, profit);

         if(sl > 0)
            posInfo += " | SL:" + DoubleToString(sl, _Digits);
         if(tp > 0)
            posInfo += " | TP:" + DoubleToString(tp, _Digits);

         ObjectCreate(0, "PosLabel_" + IntegerToString(ticket), OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_XDISTANCE, panelX + 10);
         ObjectSetInteger(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_COLOR, profitColor);
         ObjectSetString(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_TEXT, posInfo);
         ObjectSetString(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_FONT, "Consolas");
         ObjectSetInteger(0, "PosLabel_" + IntegerToString(ticket), OBJPROP_FONTSIZE, 8);

         // Nút Edit
         ObjectCreate(0, "EditPos_" + IntegerToString(ticket), OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_XDISTANCE, panelX + 210);
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_YDISTANCE, yPos - 2);
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_XSIZE, 35);
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_YSIZE, 18);
         ObjectSetString(0, "EditPos_" + IntegerToString(ticket), OBJPROP_TEXT, "Edit");
         // clang-format off
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_COLOR, C'40,40,40');
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_BGCOLOR, C'240,200,90');
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_BORDER_COLOR, C'255,220,140');
         // clang-format on
         ObjectSetInteger(0, "EditPos_" + IntegerToString(ticket), OBJPROP_FONTSIZE, 8);

         // Nút Close
         ObjectCreate(0, "ClosePos_" + IntegerToString(ticket), OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(
            0,
            "ClosePos_" + IntegerToString(ticket),
            OBJPROP_XDISTANCE,
            panelX + 250
         );
         ObjectSetInteger(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_YDISTANCE, yPos - 2);
         ObjectSetInteger(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_XSIZE, 35);
         ObjectSetInteger(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_YSIZE, 18);
         ObjectSetString(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_TEXT, "X");
         // clang-format off
         ObjectSetInteger(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(
            0,
            "ClosePos_" + IntegerToString(ticket),
            OBJPROP_BGCOLOR,
            C'170,50,50'
         ); // đỏ trầm
         ObjectSetInteger(
            0,
            "ClosePos_" + IntegerToString(ticket),
            OBJPROP_BORDER_COLOR,
            C'220,90,90'
         );
         // clang-format on
         ObjectSetInteger(0, "ClosePos_" + IntegerToString(ticket), OBJPROP_FONTSIZE, 8);

         yPos += 25;
      }
   }
}

void CloseTicketPosition(ulong ticket) {
   if(cTrade.PositionClose(ticket)) {
      uiCommon.setText(0, g_objStatus, "Đã đóng lệnh #" + IntegerToString(ticket));
      uiCommon.setTextColor(0, g_objStatus, clrGreen);
   } else {
      uiCommon.setText(0, g_objStatus, "Đã đóng lệnh #" + IntegerToString(GetLastError()));
      uiCommon.setTextColor(0, g_objStatus, clrRed);
   }
}

void ShowEditDialog(ulong ticket) {
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);

   // Trong MT5, bạn cần tạo input dialog hoặc sử dụng external input
   // Đây là ví dụ đơn giản với giá trị cố định
   uiCommon.setText(
      0,
      g_objStatus,
      "Chọn lệnh #" + IntegerToString(ticket) + " để sửa SL/TP trong Properties"
   );
   uiCommon.setTextColor(0, g_objStatus, clrBlue);
}

//+------------------------------------------------------------------+
//| Thực hiện lệnh BUY                                                |
//+------------------------------------------------------------------+
void ExecuteBuy() {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl  = 0; // Có thể thêm Stop Loss
   double tp  = 0; // Có thể thêm Take Profit

   if(cTrade.Buy(InputLotSize, _Symbol, ask, sl, tp, "Buy từ Panel")) {
      Print("✓ Lệnh BUY đã được đặt thành công!");
      Print("Giá: ", ask, " | Lot: ", InputLotSize);

      // Hiển thị thông báo
      string msg = StringFormat("BUY thành công: %.5f", ask);
      ObjectSetString(0, g_objStatus, OBJPROP_TEXT, msg);
      ObjectSetInteger(0, g_objStatus, OBJPROP_COLOR, clrLimeGreen);
   } else {
      Print("✗ Lỗi khi đặt lệnh BUY: ", GetLastError());
      uiCommon.setText(0, g_objStatus, "Lỗi: Không thể BUY");
      uiCommon.setTextColor(0, g_objStatus, clrOrangeRed);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Thực hiện lệnh SELL                                               |
//+------------------------------------------------------------------+
void ExecuteSell() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl  = 0; // Có thể thêm Stop Loss
   double tp  = 0; // Có thể thêm Take Profit

   if(cTrade.Sell(InputLotSize, _Symbol, bid, sl, tp, "Sell từ Panel")) {
      Print("✓ Lệnh SELL đã được đặt thành công!");
      Print("Giá: ", bid, " | Lot: ", InputLotSize);

      // Hiển thị thông báo
      string msg = StringFormat("SELL thành công: %.5f", bid);
      ObjectSetString(0, g_objStatus, OBJPROP_TEXT, msg);
      ObjectSetInteger(0, g_objStatus, OBJPROP_COLOR, clrOrange);
   } else {
      Print("✗ Lỗi khi đặt lệnh SELL: ", GetLastError());
      uiCommon.setText(0, g_objStatus, "Lỗi: Không thể SELL");
      uiCommon.setTextColor(0, g_objStatus, clrOrangeRed);
   }
   ChartRedraw();
}

void ExcuteCloseAllPositions() {
   uiCommon.setText(0, g_objStatus, "Đang đóng tất cả lệnh...");
   uiCommon.setTextColor(0, g_objStatus, clrOrange);
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

   uiCommon.setText(0, g_objStatus, "Đã đóng " + IntegerToString(closed) + " lệnh");
   uiCommon.setTextColor(0, g_objStatus, clrGreen);
   uiPanel.PanelRedrawChart();
}

void ProcessOnMQLTester() {
   bool btnBuyState = uiCommon.getState(0, g_objBtnBuy);
   Print("•>[DemoPanel.mq5:372]: btnBuyState: ", btnBuyState);
   if(btnBuyState == true) {
      /* code */
      Print("•>[DemoPanel.mq5:375]: btnBuyState: ", btnBuyState);
   }
   bool btnSellState = uiCommon.getState(0, g_objBtnSell);
   if(btnSellState == true) {
      /* code */
      Print("•>[DemoPanel.mq5:380]: btnSellState: ", btnSellState);
   }
}
