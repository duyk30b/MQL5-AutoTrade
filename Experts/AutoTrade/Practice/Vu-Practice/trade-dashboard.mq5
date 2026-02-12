   //+------------------------------------------------------------------+
   //|                         Trade Dashboard v3.5                     |
   //|           Dual Mode: Real (Event) + Backtest (OnTick)            |
   //+------------------------------------------------------------------+
   #property copyright "Trade Dashboard"
   #property version   "3.5"
   #property strict

   #include <Trade/Trade.mqh>

   // === INPUT PARAMETERS ===
   input double LotSize = 0.1;
   input int StopLossPoints = 500;
   input int TakeProfitPoints = 1000;
   input int MagicNumber = 123456;
   input int UIUpdateSeconds = 1;

   // === BIẾN GLOBAL ===
   CTrade trade;
   bool panelCreated = false;
   datetime lastUIUpdate = 0;
   int lastPositionsCount = -1;

   // === BIẾN CHO POPUP ===
   bool   popupActive = false;
   ulong  editTicket  = 0;
   string edtSL       = "edtPopupSL";
   string edtSLPts    = "edtPopupSLPts";
   string edtTP       = "edtPopupTP";
   string edtTPPts    = "edtPopupTPPts";
   string lblPopup    = "lblPopupTitle";
   string btnConfirm  = "btnPopupConfirm";
   string btnCancel   = "btnPopupCancel";

   // === MẢNG UI ===
   string UI[] = {"panelBG","panelHeader","lblTitle","lblMode","lblInfo","lblProfit","edtSL","edtTP",
                  "lblSL","lblTP","lblRR","btnBuy","btnSell"};

   // --- KHAI BÁO NGUYÊN MẪU HÀM ---
   void CreatePanel();
   void UpdateInfo(bool forceUpdate);
   void ScanButtonsBacktest();
   void OpenBuy();
   void OpenSell();
   void ProcessPopupConfirm();
   void CloseModifyPopup();
   void ShowEditDialog(ulong ticket);
   void CloseTicketPosition(ulong ticket);
   bool ModifySingleTicket(ulong ticket, double newSL, double newTP);
   void UpdatePnLText();
   void DeleteAllPositionObjects();

   // --- CÁC HÀM TIỆN ÍCH UI (Z-ORDER CAO) ---
   void CreateLabel(string name, int x, int y, string text, color clr, int fontSize, int zOrder=100) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }

   void CreateButton(string name, int x, int y, int w, int h, string text, color bgClr, int fontSize, int zOrder=100) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }

   void CreateEdit(string name, int x, int y, int w, int h, string text, int zOrder=100) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }

   void CreateRect(string name, int x, int y, int w, int h, color clr, int zorder) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
   }

   // --- LOGIC SỐ HỌC ---
   double NormalizePrice(double price) {
      return NormalizeDouble(price, _Digits);
   }

   double NormalizeLot(double lot) {
      double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      lot = MathRound(lot / step) * step;
      if(lot < min_lot) lot = min_lot;
      if(lot > max_lot) lot = max_lot;
      return lot;
   }

   // --- LOGIC CHÍNH ---

   int OnInit() {
      trade.SetExpertMagicNumber(MagicNumber);
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
      
      if(!MQLInfoInteger(MQL_OPTIMIZATION)) {
         CreatePanel();
         UpdateInfo(true);
      }

      if(UIUpdateSeconds > 0) EventSetTimer(UIUpdateSeconds);
      lastUIUpdate = TimeCurrent();
      
      Print("✓ Dashboard v3.5 Ready (Dual Mode)");
      return INIT_SUCCEEDED;
   }

   void OnDeinit(const int reason) {
      EventKillTimer();
      for(int i = 0; i < ArraySize(UI); i++) ObjectDelete(0, UI[i]);
      DeleteAllPositionObjects();
      CloseModifyPopup();
   }

   // === XỬ LÝ ONTICK (DÀNH RIÊNG CHO BACKTEST) ===
   void OnTick() {
      // Nếu là Backtest -> Dùng cơ chế Quét Nút (Polling)
      if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE)) {
         ScanButtonsBacktest(); 
         UpdateInfo(false); 
         ChartRedraw();
      }
      
      // Nếu là Real -> OnTick không làm gì về UI, để OnChartEvent lo
   }

   // === HÀM QUÉT NÚT (Chỉ chạy trong Backtest) ===
   void ScanButtonsBacktest() {
      // Safety Check: Chỉ cho phép chạy hàm này trong Backtest
      if(!MQLInfoInteger(MQL_TESTER)) return;

      // 1. Check Nút Chính
      if(ObjectGetInteger(0, "btnBuy", OBJPROP_STATE) == 1) {
         ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false);
         OpenBuy();
         return; 
      }
      if(ObjectGetInteger(0, "btnSell", OBJPROP_STATE) == 1) {
         ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false);
         OpenSell();
         return;
      }
      
      // 2. Check Nút Popup
      if(popupActive) {
         if(ObjectGetInteger(0, btnConfirm, OBJPROP_STATE) == 1) {
            ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false);
            ProcessPopupConfirm();
            return; 
         }
         if(ObjectGetInteger(0, btnCancel, OBJPROP_STATE) == 1) {
            ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false);
            CloseModifyPopup();
            return; 
         }
      }
      
      // 3. Check Nút List (Edit / Close)
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

         string btnEdit = "Pos_Edit_" + IntegerToString(ticket);
         string btnClose = "Pos_Close_" + IntegerToString(ticket);

         if(ObjectFind(0, btnEdit) >= 0 && ObjectGetInteger(0, btnEdit, OBJPROP_STATE) == 1) {
            ObjectSetInteger(0, btnEdit, OBJPROP_STATE, false); 
            ShowEditDialog(ticket);
            return;
         }

         if(ObjectFind(0, btnClose) >= 0 && ObjectGetInteger(0, btnClose, OBJPROP_STATE) == 1) {
            ObjectSetInteger(0, btnClose, OBJPROP_STATE, false);
            CloseTicketPosition(ticket);
            return;
         }
      }
   }

   void OnTimer() {
      // Trong Real, dùng Timer để update UI cho mượt và nhẹ
      if(!MQLInfoInteger(MQL_TESTER)) {
         if(UIUpdateSeconds > 0 && TimeCurrent() - lastUIUpdate >= UIUpdateSeconds) {
            UpdateInfo(true);
            lastUIUpdate = TimeCurrent();
         }
      }
   }

   void OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& req,const MqlTradeResult& res) {
      UpdateInfo(true);
   }

   // === XỬ LÝ CHART EVENT (DÀNH CHO REAL TRADE) ===
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      // Nếu là Backtest -> Thoát ngay (để OnTick xử lý, tránh xung đột)
      if(MQLInfoInteger(MQL_TESTER)) return;

      // --- LOGIC REAL TIME (Sử dụng Event chuẩn) ---
      if(id == CHARTEVENT_KEYDOWN) {
         if(lparam == 66) OpenBuy();
         else if(lparam == 83) OpenSell();
         ChartRedraw();
      }
      else if(id == CHARTEVENT_OBJECT_CLICK && sparam != "") {
         // 1. Popup
         if(sparam == btnConfirm) {
            ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false);
            ProcessPopupConfirm();
         }
         else if(sparam == btnCancel) {
            ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false);
            CloseModifyPopup();
         }
         // 2. Main Buttons
         else if(sparam == "btnBuy") {
            ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false);
            OpenBuy();
         }
         else if(sparam == "btnSell") {
            ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false);
            OpenSell();
         }
         // 3. List Buttons
         else if(StringFind(sparam, "Pos_Close_") == 0) {
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 10)); 
            CloseTicketPosition(ticket);
         }
         else if(StringFind(sparam, "Pos_Edit_") == 0) {
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 9));
            ShowEditDialog(ticket);
         }
         ChartRedraw();
      }
   }

   // === LOGIC THỰC THI (ĐÃ MỞ KHÓA REAL) ===

   void OpenBuy() {
      int sl_points = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
      int tp_points = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
      if(sl_points <= 0) sl_points = StopLossPoints;
      if(tp_points <= 0) tp_points = TakeProfitPoints;
      int min_stop = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      if(sl_points < min_stop + 10) sl_points = min_stop + 10;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick)) return;
      double ask = NormalizePrice(tick.ask);
      double sl_price = NormalizePrice(ask - sl_points * _Point);
      double tp_price = NormalizePrice(ask + tp_points * _Point);
      double lot = NormalizeLot(LotSize);
      
      if(trade.Buy(lot, _Symbol, ask, sl_price, tp_price, "Buy Dashboard")) {
         Print("✓ Buy thành công");
         UpdateInfo(true);
      }
   }

   void OpenSell() {
      int sl_points = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
      int tp_points = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
      if(sl_points <= 0) sl_points = StopLossPoints;
      if(tp_points <= 0) tp_points = TakeProfitPoints;
      int min_stop = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      if(sl_points < min_stop + 10) sl_points = min_stop + 10;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick)) return;
      double bid = NormalizePrice(tick.bid);
      double sl_price = NormalizePrice(bid + sl_points * _Point);
      double tp_price = NormalizePrice(bid - tp_points * _Point);
      double lot = NormalizeLot(LotSize);
      
      if(trade.Sell(lot, _Symbol, bid, sl_price, tp_price, "Sell Dashboard")) {
         Print("✓ Sell thành công");
         UpdateInfo(true);
      }
   }

   void CloseTicketPosition(ulong ticket) {
      if(trade.PositionClose(ticket)) {
         Print("✓ Đã đóng lệnh #", ticket);
         UpdateInfo(true); 
      }
   }

 // Sửa lại hàm này để trả về true/false và in lỗi
bool ModifySingleTicket(ulong ticket, double newSL, double newTP) {
   if(!PositionSelectByTicket(ticket)) return false;
   
   // In ra thông số đang cố gắng gửi đi để kiểm tra
   Print("Dashboard đang thử sửa Ticket #", ticket, 
         " | SL Mới: ", DoubleToString(newSL, _Digits), 
         " | TP Mới: ", DoubleToString(newTP, _Digits));

   if(trade.PositionModify(ticket, newSL, newTP)) {
      Print("✓ Đã sửa lệnh #", ticket, " thành công!");
      UpdateInfo(true);
      return true;
   } else {
      // QUAN TRỌNG: In ra lỗi nếu thất bại
      Print("❌ LỖI SỬA LỆNH #", ticket, 
            ". Mã lỗi: ", trade.ResultRetcode(), 
            " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

 void ProcessPopupConfirm() {
   // 1. Đọc giá trị từ ô nhập liệu GIÁ (Lưu ý: Phải nhập vào ô Price, không phải ô Points)
   string strSL = ObjectGetString(0, edtSL, OBJPROP_TEXT);
   string strTP = ObjectGetString(0, edtTP, OBJPROP_TEXT);
   
   double newSL = StringToDouble(strSL);
   double newTP = StringToDouble(strTP);
   
   // 2. Gọi hàm sửa lệnh và kiểm tra kết quả
   bool result = ModifySingleTicket(editTicket, newSL, newTP);
   
   // 3. Chỉ đóng Popup nếu sửa thành công
   if(result == true) {
      CloseModifyPopup();
   } else {
      Alert("Sửa lệnh thất bại! Xem tab Journal để biết chi tiết.");
   }
}

   // === CÁC HÀM UI ===

   void CreatePanel() {
      if(panelCreated) return;
      int x = 10, y = 20, w = 280, h = 300;
      
      CreateRect("panelBG", x-5, y-5, w+10, h+10, C'25,25,40', 0);
      CreateRect("panelHeader", x, y, w, 35, C'50,50,100', 0);
      CreateLabel("lblTitle", x+80, y+5, "TRADE DASHBOARD", clrWhite, 11);
      y += 35;
      
      // Hiển thị chế độ hiện tại
      string mode = MQLInfoInteger(MQL_TESTER) ? "MODE: BACKTEST" : "MODE: REAL TRADE";
      color modeClr = MQLInfoInteger(MQL_TESTER) ? C'200,200,255' : clrLime;
      CreateLabel("lblMode", x+10, y, mode, modeClr, 8);
      
      y += 18;
      CreateLabel("lblInfo", x+10, y, "Positions: 0", clrWhite, 8);
      CreateLabel("lblProfit", x+140, y, "P&L: 0.00", clrYellow, 8);
      y += 20;
      CreateLabel("lblSL", x+10, y, "SL (pts):", clrWhite, 8);
      CreateEdit("edtSL", x+70, y-2, 50, 18, IntegerToString(StopLossPoints));
      CreateLabel("lblRR", x+130, y, "RR: 0.00", clrLime, 8);
      y += 22;
      CreateLabel("lblTP", x+10, y, "TP (pts):", clrWhite, 8);
      CreateEdit("edtTP", x+70, y-2, 50, 18, IntegerToString(TakeProfitPoints));
      y += 25;
      
      CreateButton("btnBuy", x+10, y, 120, 32, "BUY", clrGreen, 11);
      CreateButton("btnSell", x+140, y, 120, 32, "SELL", clrRed, 11);
      
      panelCreated = true;
      ChartRedraw();
   }

   void UpdateInfo(bool forceUpdate) {
      int currentPositions = PositionsTotal();
      if(!forceUpdate && currentPositions == lastPositionsCount) {
         UpdatePnLText(); 
         return;
      }
      lastPositionsCount = currentPositions;
      
      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "Pos_") == 0) ObjectDelete(0, name);
      }
      
      int cnt = 0;
      double profit = 0;
      int yPos = 180;
      
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         
         cnt++;
         profit += PositionGetDouble(POSITION_PROFIT);
         
         string posText = StringFormat("#%I64u | %s | %.2f",
                                       ticket,
                                       PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                       PositionGetDouble(POSITION_VOLUME));
         string posText2 = StringFormat("P/L: %.2f", PositionGetDouble(POSITION_PROFIT));
         
         string lblName = "Pos_Label_" + IntegerToString(ticket);
         CreateLabel(lblName, 20, yPos, posText + " | " + posText2, clrWhite, 8);
         
         string closeName = "Pos_Close_" + IntegerToString(ticket);
         CreateButton(closeName, 220, yPos-2, 35, 18, "X", clrRed, 8);
         
         string editName = "Pos_Edit_" + IntegerToString(ticket);
         CreateButton(editName, 260, yPos-2, 35, 18, "E", clrOrange, 8);
         
         yPos += 25;
      }
      UpdatePnLText();
   }

   void UpdatePnLText() {
      double profit = 0;
      int cnt = 0;
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            profit += PositionGetDouble(POSITION_PROFIT);
            cnt++;
         }
      }
      color clr = (profit >= 0) ? clrLime : clrRed;
      if(ObjectFind(0, "lblProfit") >= 0) {
         ObjectSetInteger(0, "lblProfit", OBJPROP_COLOR, clr);
         ObjectSetString(0, "lblInfo", OBJPROP_TEXT, StringFormat("Positions: %d", cnt));
         ObjectSetString(0, "lblProfit", OBJPROP_TEXT, StringFormat("P&L: %.2f", profit));
      }
   }

   void ShowEditDialog(ulong ticket) {
      if(!PositionSelectByTicket(ticket)) return;
      editTicket = ticket;
      
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      
      double slPoints = (sl == 0) ? 0 : MathAbs(open - sl) / _Point;
      double tpPoints = (tp == 0) ? 0 : MathAbs(open - tp) / _Point;
      
      popupActive = true;
      int x = 320, y = 180, w = 340, h = 180;
      int zBG = 150, zItem = 200;

      CreateRect("popupBG", x-8, y-8, w+16, h+16, C'200,200,200', zBG);
      ObjectSetInteger(0, "popupBG", OBJPROP_BORDER_TYPE, BORDER_RAISED);

      CreateLabel(lblPopup, x+10, y+10, "Sửa lệnh #" + IntegerToString(ticket), clrBlack, 11, zItem);
      CreateLabel("lblSLTitle", x+10, y+35, "Stop Loss:", clrBlack, 9, zItem);
      CreateEdit(edtSL, x+80, y+30, 100, 22, DoubleToString(sl, _Digits), zItem);
      CreateEdit(edtSLPts, x+190, y+30, 60, 22, DoubleToString(slPoints, 0), zItem);
      CreateLabel("lblSLPts", x+255, y+35, "points", clrBlack, 9, zItem);

      CreateLabel("lblTPTitle", x+10, y+65, "Take Profit:", clrBlack, 9, zItem);
      CreateEdit(edtTP, x+80, y+60, 100, 22, DoubleToString(tp, _Digits), zItem);
      CreateEdit(edtTPPts, x+190, y+60, 60, 22, DoubleToString(tpPoints, 0), zItem);
      CreateLabel("lblTPPts", x+255, y+65, "points", clrBlack, 9, zItem);

      CreateButton(btnConfirm, x+20, y+110, 140, 30, "XÁC NHẬN", clrGreen, 10, zItem);
      CreateButton(btnCancel, x+180, y+110, 140, 30, "HỦY", clrRed, 10, zItem);

      ChartRedraw();
   }

   void CloseModifyPopup() {
      ObjectDelete(0, "popupBG");
      ObjectDelete(0, lblPopup);
      ObjectDelete(0, edtSL);
      ObjectDelete(0, edtSLPts);
      ObjectDelete(0, edtTP);
      ObjectDelete(0, edtTPPts);
      ObjectDelete(0, "lblSLTitle");
      ObjectDelete(0, "lblSLPts");
      ObjectDelete(0, "lblTPTitle");
      ObjectDelete(0, "lblTPPts");
      ObjectDelete(0, btnConfirm);
      ObjectDelete(0, btnCancel);
      popupActive = false;
      editTicket = 0;
      ChartRedraw();
   }

   void DeleteAllPositionObjects() {
      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "Pos_") == 0) ObjectDelete(0, name);
      }
      ChartRedraw();
   }
   //+------------------------------------------------------------------+