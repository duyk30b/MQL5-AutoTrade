//+------------------------------------------------------------------+
//|                         Trade Dashboard v4.6                     |
//| Feature: Visual Color Highlight for Active Trailing Stop Trades  |
//+------------------------------------------------------------------+
#property copyright "Trade Dashboard"
#property version   "4.6"
#property strict

#include <Trade/Trade.mqh>

// === INPUT PARAMETERS ===
input double LotSize = 0.1;
input int    StopLossPoints = 500;
input int    TakeProfitPoints = 1000;
input int    MagicNumber = 123456;
input int    UIUpdateSeconds = 1;
input int    ButtonStepPoints = 50; 

input string _ts = "=== TRAILING STOP SETTINGS ===";
input int    TrailingStartPoints = 1000;  
input int    TrailingDistPoints  = 400;   

// === BỘ NHỚ ĐỘC LẬP CHO TỪNG LỆNH ===
struct TradeSettings {
   ulong ticket;
   int ts_start;
   int ts_dist;
   bool ts_active; 
};
TradeSettings tsMemory[]; 

// === BIẾN GLOBAL ===
CTrade trade;
bool panelCreated = false;
datetime lastUIUpdate = 0;
int lastPositionsCount = -1;

int currentMainSL = 0; 
int currentMainTP = 0;
double currentMainLot = 0.1; 
int currentMainTS_Start = 1000; 
int currentMainTS_Dist = 400;   

string btnMainSL_Sub = "btnMainSL_Sub", btnMainSL_Add = "btnMainSL_Add";
string btnMainTP_Sub = "btnMainTP_Sub", btnMainTP_Add = "btnMainTP_Add";
string btnMainLot_Sub = "btnMainLot_Sub", btnMainLot_Add = "btnMainLot_Add";
string btnMainTSStart_Sub = "btnMainTSStart_Sub", btnMainTSStart_Add = "btnMainTSStart_Add";
string btnMainTSDist_Sub = "btnMainTSDist_Sub", btnMainTSDist_Add = "btnMainTSDist_Add";

bool   popupActive = false;
ulong  editTicket  = 0;
double popupCurrentSL = 0; 
double popupCurrentTP = 0; 
int    popupCurrentTS_Start = 0; 
int    popupCurrentTS_Dist = 0;  

string lblPopup      = "lblPopupTitle";
string bgPopup       = "popupBG";
string txtSLVal      = "txtPopupSLVal", txtTPVal = "txtPopupTPVal"; 
string txtTSStartVal = "txtPopupTSStartVal", txtTSDistVal = "txtPopupTSDistVal"; 
string btnConfirm    = "btnPopupConfirm", btnCancel = "btnPopupCancel";
string btnSL_Sub     = "btnPopupSL_Sub", btnSL_Add = "btnPopupSL_Add"; 
string btnTP_Sub     = "btnPopupTP_Sub", btnTP_Add = "btnPopupTP_Add"; 
string btnTSStart_Sub = "btnPopupTSStart_Sub", btnTSStart_Add = "btnPopupTSStart_Add"; 
string btnTSDist_Sub = "btnPopupTSDist_Sub", btnTSDist_Add = "btnPopupTSDist_Add"; 

string UI[] = {"panelBG","panelHeader","lblTitle","lblMode","lblInfo","lblProfit",
               "edtSL","edtTP","edtLot","edtTSStart","edtTSDist",
               "lblSL","lblTP","lblLot","lblRR","lblTSStart","lblTSDist","btnBuy","btnSell",
               "btnMainSL_Sub", "btnMainSL_Add", "btnMainTP_Sub", "btnMainTP_Add", "btnMainLot_Sub", "btnMainLot_Add",
               "btnMainTSStart_Sub", "btnMainTSStart_Add", "btnMainTSDist_Sub", "btnMainTSDist_Add"};

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
void AdjustPopupValue(string type, int direction); 
void UpdatePopupDisplay(); 
void AdjustMainPanelValue(string type, int direction); 
void ProcessTrailingStop(); 
void DrawTrailingStopLine(ulong ticket, double price);
void CleanUpTrailingLines();
void RegisterNewTrades(); 
void SaveTradeMemory(ulong t, int start, int dist);
bool GetTradeMemory(ulong t, int &start, int &dist, bool &active);
void MarkTSActive(ulong t);

// --- CÁC HÀM TIỆN ÍCH UI ---
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize, int zOrder=100) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder); ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}
void CreateButton(string name, int x, int y, int w, int h, string text, color bgClr, int fontSize, int zOrder=100) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder); ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}
void CreateEdit(string name, int x, int y, int w, int h, string text, int zOrder=100, bool readOnly=false) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_BGCOLOR, readOnly ? C'220,220,220' : clrWhite);
   ObjectSetInteger(0, name, OBJPROP_COLOR, readOnly ? clrDimGray : clrBlack); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_READONLY, readOnly); ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}
void CreateRect(string name, int x, int y, int w, int h, color clr, int zorder) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr); ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

// --- LOGIC SỐ HỌC ---
double NormalizePrice(double price) { return NormalizeDouble(price, _Digits); }
double NormalizeLot(double lot) {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lot = MathRound(lot / step) * step;
   if(lot < min_lot) lot = min_lot;
   if(lot > max_lot) lot = max_lot;
   return lot;
}

// --- HỆ THỐNG QUẢN LÝ BỘ NHỚ LỆNH ---
void SaveTradeMemory(ulong t, int start, int dist) {
   for(int i=0; i<ArraySize(tsMemory); i++) {
      if(tsMemory[i].ticket == t) { 
         tsMemory[i].ts_start = start; tsMemory[i].ts_dist = dist; return;
      }
   }
   int size = ArraySize(tsMemory); ArrayResize(tsMemory, size+1);
   tsMemory[size].ticket = t; tsMemory[size].ts_start = start; tsMemory[size].ts_dist = dist;
   tsMemory[size].ts_active = false; 
}

bool GetTradeMemory(ulong t, int &start, int &dist, bool &active) {
   for(int i=0; i<ArraySize(tsMemory); i++) {
      if(tsMemory[i].ticket == t) {
         start = tsMemory[i].ts_start; dist = tsMemory[i].ts_dist; active = tsMemory[i].ts_active; return true;
      }
   }
   return false;
}

void MarkTSActive(ulong t) {
   for(int i=0; i<ArraySize(tsMemory); i++) {
      if(tsMemory[i].ticket == t) { tsMemory[i].ts_active = true; return; }
   }
}

void RegisterNewTrades() {
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         int s, d; bool a;
         if(!GetTradeMemory(ticket, s, d, a)) SaveTradeMemory(ticket, currentMainTS_Start, currentMainTS_Dist);
      }
   }
}

// --- LOGIC CHÍNH ---
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   
   currentMainSL = StopLossPoints; currentMainTP = TakeProfitPoints; currentMainLot = NormalizeLot(LotSize); 
   currentMainTS_Start = TrailingStartPoints; currentMainTS_Dist = TrailingDistPoints;   
   
   if(!MQLInfoInteger(MQL_OPTIMIZATION)) { CreatePanel(); UpdateInfo(true); }
   if(UIUpdateSeconds > 0) EventSetTimer(UIUpdateSeconds);
   lastUIUpdate = TimeCurrent();
   
   Print("✓ Dashboard v4.6 (Visual TS Color Update) Ready");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   EventKillTimer();
   for(int i = 0; i < ArraySize(UI); i++) ObjectDelete(0, UI[i]);
   DeleteAllPositionObjects();
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) { string name = ObjectName(0, i); if(StringFind(name, "TS_Line_") == 0) ObjectDelete(0, name); }
   CloseModifyPopup();
}

void OnTick() {
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE)) {
      ScanButtonsBacktest(); UpdateInfo(false); ChartRedraw(); 
   }
   ProcessTrailingStop();
}

// === THUẬT TOÁN TRAILING STOP ===
void ProcessTrailingStop() {
   double safeStepPoints = 1 * _Point; 

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

      int my_ts_start = 0, my_ts_dist = 0; bool is_active = false;
      if(!GetTradeMemory(ticket, my_ts_start, my_ts_dist, is_active)) continue;
      if(my_ts_start <= 0 || my_ts_dist <= 0) continue;

      long posType = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double startOffset = my_ts_start * _Point;
      double distOffset = my_ts_dist * _Point;

      if(posType == POSITION_TYPE_BUY) {
         if(bid - openPrice >= startOffset) {
            double newSL = NormalizePrice(bid - distOffset);
            if(currentSL == 0 || newSL > currentSL) {
               if(currentSL == 0 || (newSL - currentSL) >= safeStepPoints) {
                  if(trade.PositionModify(ticket, newSL, currentTP)) {
                     DrawTrailingStopLine(ticket, newSL);
                     if(!is_active) { MarkTSActive(ticket); UpdateInfo(true); } // Update màn hình đổi màu ngay!
                  }
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL) {
         if(openPrice - ask >= startOffset) {
            double newSL = NormalizePrice(ask + distOffset);
            if(currentSL == 0 || newSL < currentSL) {
               if(currentSL == 0 || (currentSL - newSL) >= safeStepPoints) {
                  if(trade.PositionModify(ticket, newSL, currentTP)) {
                     DrawTrailingStopLine(ticket, newSL);
                     if(!is_active) { MarkTSActive(ticket); UpdateInfo(true); } // Update màn hình đổi màu ngay!
                  }
               }
            }
         }
      }
   }
}

void DrawTrailingStopLine(ulong ticket, double price) {
   string lineName = "TS_Line_" + IntegerToString(ticket);
   if(ObjectFind(0, lineName) < 0) {
      ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrMagenta); ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_SOLID); 
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2); ObjectSetString(0, lineName, OBJPROP_TEXT, " Trailing Stop #" + IntegerToString(ticket));
      ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true); ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, lineName, OBJPROP_BACK, false); 
   } else ObjectSetDouble(0, lineName, OBJPROP_PRICE, price);
   ChartRedraw();
}

void CleanUpTrailingLines() {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, "TS_Line_") == 0) {
         ulong ticket = (ulong)StringToInteger(StringSubstr(name, 8));
         if(!PositionSelectByTicket(ticket)) ObjectDelete(0, name); 
      }
   }
   
   // --- THÊM ĐOẠN NÀY ĐỂ DỌN RÁC BỘ NHỚ ---
   for(int i = ArraySize(tsMemory) - 1; i >= 0; i--) {
      if(!PositionSelectByTicket(tsMemory[i].ticket)) {
         ArrayRemove(tsMemory, i, 1); // Xé bỏ hồ sơ của lệnh đã đóng!
      }
   }
}

// === XỬ LÝ SỰ KIỆN CLICK CHUỘT ===
void ScanButtonsBacktest() {
   if(!MQLInfoInteger(MQL_TESTER)) return;

   if(ObjectGetInteger(0, "btnBuy", OBJPROP_STATE) == 1) { ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false); OpenBuy(); return; }
   if(ObjectGetInteger(0, "btnSell", OBJPROP_STATE) == 1) { ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false); OpenSell(); return; }
   
   if(!popupActive) {
      if(ObjectGetInteger(0, btnMainSL_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainSL_Sub, OBJPROP_STATE, false); AdjustMainPanelValue("SL", -1); return; }
      if(ObjectGetInteger(0, btnMainSL_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainSL_Add, OBJPROP_STATE, false); AdjustMainPanelValue("SL", 1); return; }
      if(ObjectGetInteger(0, btnMainTP_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTP_Sub, OBJPROP_STATE, false); AdjustMainPanelValue("TP", -1); return; }
      if(ObjectGetInteger(0, btnMainTP_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTP_Add, OBJPROP_STATE, false); AdjustMainPanelValue("TP", 1); return; }
      if(ObjectGetInteger(0, btnMainLot_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainLot_Sub, OBJPROP_STATE, false); AdjustMainPanelValue("LOT", -1); return; }
      if(ObjectGetInteger(0, btnMainLot_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainLot_Add, OBJPROP_STATE, false); AdjustMainPanelValue("LOT", 1); return; }
      
      if(ObjectGetInteger(0, btnMainTSStart_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTSStart_Sub, OBJPROP_STATE, false); AdjustMainPanelValue("TS_START", -1); return; }
      if(ObjectGetInteger(0, btnMainTSStart_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTSStart_Add, OBJPROP_STATE, false); AdjustMainPanelValue("TS_START", 1); return; }
      if(ObjectGetInteger(0, btnMainTSDist_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTSDist_Sub, OBJPROP_STATE, false); AdjustMainPanelValue("TS_DIST", -1); return; }
      if(ObjectGetInteger(0, btnMainTSDist_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnMainTSDist_Add, OBJPROP_STATE, false); AdjustMainPanelValue("TS_DIST", 1); return; }
   }
   
   if(popupActive) {
      if(ObjectGetInteger(0, btnConfirm, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false); ProcessPopupConfirm(); return; }
      if(ObjectGetInteger(0, btnCancel, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false); CloseModifyPopup(); return; } 
      if(ObjectGetInteger(0, btnSL_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnSL_Sub, OBJPROP_STATE, false); AdjustPopupValue("SL", -1); return; }
      if(ObjectGetInteger(0, btnSL_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnSL_Add, OBJPROP_STATE, false); AdjustPopupValue("SL", 1); return; }
      if(ObjectGetInteger(0, btnTP_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTP_Sub, OBJPROP_STATE, false); AdjustPopupValue("TP", -1); return; }
      if(ObjectGetInteger(0, btnTP_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTP_Add, OBJPROP_STATE, false); AdjustPopupValue("TP", 1); return; }
      
      if(ObjectFind(0, btnTSStart_Sub) >= 0 && ObjectGetInteger(0, btnTSStart_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTSStart_Sub, OBJPROP_STATE, false); AdjustPopupValue("TS_START", -1); return; }
      if(ObjectFind(0, btnTSStart_Add) >= 0 && ObjectGetInteger(0, btnTSStart_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTSStart_Add, OBJPROP_STATE, false); AdjustPopupValue("TS_START", 1); return; }
      if(ObjectFind(0, btnTSDist_Sub) >= 0 && ObjectGetInteger(0, btnTSDist_Sub, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTSDist_Sub, OBJPROP_STATE, false); AdjustPopupValue("TS_DIST", -1); return; }
      if(ObjectFind(0, btnTSDist_Add) >= 0 && ObjectGetInteger(0, btnTSDist_Add, OBJPROP_STATE) == 1) { ObjectSetInteger(0, btnTSDist_Add, OBJPROP_STATE, false); AdjustPopupValue("TS_DIST", 1); return; }
   }
   
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

      if(ObjectFind(0, "Pos_Edit_"+IntegerToString(ticket)) >= 0 && ObjectGetInteger(0, "Pos_Edit_"+IntegerToString(ticket), OBJPROP_STATE) == 1) {
         ObjectSetInteger(0, "Pos_Edit_"+IntegerToString(ticket), OBJPROP_STATE, false); ShowEditDialog(ticket); return; }
      if(ObjectFind(0, "Pos_Close_"+IntegerToString(ticket)) >= 0 && ObjectGetInteger(0, "Pos_Close_"+IntegerToString(ticket), OBJPROP_STATE) == 1) {
         ObjectSetInteger(0, "Pos_Close_"+IntegerToString(ticket), OBJPROP_STATE, false); CloseTicketPosition(ticket); return; }
   }
}

void OnTimer() {
   if(!MQLInfoInteger(MQL_TESTER)) { if(UIUpdateSeconds > 0 && TimeCurrent() - lastUIUpdate >= UIUpdateSeconds) { UpdateInfo(true); lastUIUpdate = TimeCurrent(); } }
}

void OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& req,const MqlTradeResult& res) { UpdateInfo(true); }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(MQLInfoInteger(MQL_TESTER)) return;

   if(id == CHARTEVENT_KEYDOWN) { if(lparam == 66) OpenBuy(); else if(lparam == 83) OpenSell(); ChartRedraw(); }
   else if(id == CHARTEVENT_OBJECT_CLICK && sparam != "") {
      if(sparam == btnConfirm) { ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false); ProcessPopupConfirm(); }
      else if(sparam == btnCancel) { ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false); CloseModifyPopup(); }
      
      else if(sparam == btnMainSL_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("SL", -1); }
      else if(sparam == btnMainSL_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("SL", 1); }
      else if(sparam == btnMainTP_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TP", -1); }
      else if(sparam == btnMainTP_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TP", 1); }
      else if(sparam == btnMainLot_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("LOT", -1); }
      else if(sparam == btnMainLot_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("LOT", 1); }
      
      else if(sparam == btnMainTSStart_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TS_START", -1); }
      else if(sparam == btnMainTSStart_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TS_START", 1); }
      else if(sparam == btnMainTSDist_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TS_DIST", -1); }
      else if(sparam == btnMainTSDist_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustMainPanelValue("TS_DIST", 1); }
      
      else if(sparam == btnSL_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("SL", -1); }
      else if(sparam == btnSL_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("SL", 1); }
      else if(sparam == btnTP_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TP", -1); }
      else if(sparam == btnTP_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TP", 1); }
      else if(sparam == btnTSStart_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TS_START", -1); }
      else if(sparam == btnTSStart_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TS_START", 1); }
      else if(sparam == btnTSDist_Sub) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TS_DIST", -1); }
      else if(sparam == btnTSDist_Add) { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); AdjustPopupValue("TS_DIST", 1); }
      
      else if(sparam == "btnBuy") { ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false); OpenBuy(); }
      else if(sparam == "btnSell") { ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false); OpenSell(); }
      else if(StringFind(sparam, "Pos_Close_") == 0) {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 10)); CloseTicketPosition(ticket);
      }
      else if(StringFind(sparam, "Pos_Edit_") == 0) {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 9)); ShowEditDialog(ticket);
      }
      ChartRedraw();
   }
}

// === LOGIC THỰC THI GIAO DỊCH ===
void OpenBuy() {
   double ask = NormalizePrice(SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   double sl = (currentMainSL == 0) ? 0 : NormalizePrice(ask - currentMainSL * _Point);
   double tp = (currentMainTP == 0) ? 0 : NormalizePrice(ask + currentMainTP * _Point);
   if(trade.Buy(currentMainLot, _Symbol, ask, sl, tp, "Buy Dashboard")) { UpdateInfo(true); }
}

void OpenSell() {
   double bid = NormalizePrice(SymbolInfoDouble(_Symbol, SYMBOL_BID));
   double sl = (currentMainSL == 0) ? 0 : NormalizePrice(bid + currentMainSL * _Point);
   double tp = (currentMainTP == 0) ? 0 : NormalizePrice(bid - currentMainTP * _Point);
   if(trade.Sell(currentMainLot, _Symbol, bid, sl, tp, "Sell Dashboard")) { UpdateInfo(true); }
}

void CloseTicketPosition(ulong ticket) { if(trade.PositionClose(ticket)) { Print("✓ Đã đóng lệnh #", ticket); UpdateInfo(true); } }
bool ModifySingleTicket(ulong ticket, double newSL, double newTP) {
   if(!PositionSelectByTicket(ticket)) return false;
   if(trade.PositionModify(ticket, newSL, newTP)) { Print("✓ Đã sửa lệnh #", ticket); UpdateInfo(true); return true;
   } else { Print("❌ Lỗi sửa lệnh #", ticket); return false; }
}

// === TĂNG GIẢM MAIN PANEL ===
void AdjustMainPanelValue(string type, int direction) {
   int step = ButtonStepPoints;
   if(type == "SL") { currentMainSL += (direction * step); if(currentMainSL < 0) currentMainSL = 0; ObjectSetString(0, "edtSL", OBJPROP_TEXT, IntegerToString(currentMainSL)); }
   else if(type == "TP") { currentMainTP += (direction * step); if(currentMainTP < 0) currentMainTP = 0; ObjectSetString(0, "edtTP", OBJPROP_TEXT, IntegerToString(currentMainTP)); }
   else if(type == "LOT") {
      double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP), minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      currentMainLot += (direction * volStep); if(currentMainLot < minLot) currentMainLot = minLot; if(currentMainLot > maxLot) currentMainLot = maxLot;
      ObjectSetString(0, "edtLot", OBJPROP_TEXT, DoubleToString(currentMainLot, 2));
   }
   else if(type == "TS_START") { currentMainTS_Start += (direction * step); if(currentMainTS_Start < 0) currentMainTS_Start = 0; ObjectSetString(0, "edtTSStart", OBJPROP_TEXT, IntegerToString(currentMainTS_Start)); }
   else if(type == "TS_DIST") { currentMainTS_Dist += (direction * step); if(currentMainTS_Dist < 0) currentMainTS_Dist = 0; ObjectSetString(0, "edtTSDist", OBJPROP_TEXT, IntegerToString(currentMainTS_Dist)); }
   ChartRedraw();
}

// === POPUP EDIT HIỂN THỊ HỒ SƠ CÁ NHÂN ===
void ShowEditDialog(ulong ticket) {
   if(popupActive && editTicket == ticket) return; 
   if(!PositionSelectByTicket(ticket)) return;
   
   editTicket = ticket;
   popupCurrentSL = PositionGetDouble(POSITION_SL); 
   popupCurrentTP = PositionGetDouble(POSITION_TP);
   
   bool is_ts_active = false;
   if(!GetTradeMemory(ticket, popupCurrentTS_Start, popupCurrentTS_Dist, is_ts_active)) {
      popupCurrentTS_Start = 0; popupCurrentTS_Dist = 0; 
   }
   
   popupActive = true;
   int x = 320, y = 180, w = 360, h = 250, zBG = 150, zItem = 200; 

   CreateRect(bgPopup, x-8, y-8, w+16, h+16, C'200,200,200', zBG); ObjectSetInteger(0, bgPopup, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   CreateLabel(lblPopup, x+10, y+10, "Sửa lệnh #" + IntegerToString(ticket), clrBlack, 11, zItem);
   
   CreateLabel("lblSLTitle", x+20, y+40, "Stop Loss:", clrBlack, 9, zItem);
   CreateButton(btnSL_Sub, x+90, y+38, 30, 22, "-", clrRed, 12, zItem); CreateEdit(txtSLVal, x+125, y+38, 80, 22, "", zItem, true); CreateButton(btnSL_Add, x+210, y+38, 30, 22, "+", clrGreen, 12, zItem);
   
   CreateLabel("lblTPTitle", x+20, y+75, "Take Profit:", clrBlack, 9, zItem);
   CreateButton(btnTP_Sub, x+90, y+73, 30, 22, "-", clrRed, 12, zItem); CreateEdit(txtTPVal, x+125, y+73, 80, 22, "", zItem, true); CreateButton(btnTP_Add, x+210, y+73, 30, 22, "+", clrGreen, 12, zItem);
   
   if(is_ts_active) {
      CreateLabel("lblTSStartTitle", x+20, y+110, "T.Start (LOCKED):", clrRed, 9, zItem);
      CreateEdit(txtTSStartVal, x+125, y+108, 80, 22, IntegerToString(popupCurrentTS_Start), zItem, true);
      
      CreateLabel("lblTSDistTitle", x+20, y+145, "T.Dist (LOCKED):", clrRed, 9, zItem);
      CreateEdit(txtTSDistVal, x+125, y+143, 80, 22, IntegerToString(popupCurrentTS_Dist), zItem, true);
   } else {
      CreateLabel("lblTSStartTitle", x+20, y+110, "T.Start (pts):", clrNavy, 9, zItem);
      CreateButton(btnTSStart_Sub, x+90, y+108, 30, 22, "-", clrRed, 12, zItem); 
      CreateEdit(txtTSStartVal, x+125, y+108, 80, 22, "", zItem, true); 
      CreateButton(btnTSStart_Add, x+210, y+108, 30, 22, "+", clrGreen, 12, zItem);
      
      CreateLabel("lblTSDistTitle", x+20, y+145, "T.Dist (pts):", clrNavy, 9, zItem);
      CreateButton(btnTSDist_Sub, x+90, y+143, 30, 22, "-", clrRed, 12, zItem); 
      CreateEdit(txtTSDistVal, x+125, y+143, 80, 22, "", zItem, true); 
      CreateButton(btnTSDist_Add, x+210, y+143, 30, 22, "+", clrGreen, 12, zItem);
   }

   CreateButton(btnConfirm, x+30, y+190, 140, 35, "XÁC NHẬN", clrGreen, 10, zItem); CreateButton(btnCancel, x+190, y+190, 140, 35, "HỦY BỎ", clrRed, 10, zItem);

   UpdatePopupDisplay(); ChartRedraw();
}

void AdjustPopupValue(string type, int direction) {
   bool is_active = false; int dummy1, dummy2;
   GetTradeMemory(editTicket, dummy1, dummy2, is_active);

   if(type == "TS_START") {
      if(is_active) return; 
      popupCurrentTS_Start += (direction * ButtonStepPoints); if(popupCurrentTS_Start < 0) popupCurrentTS_Start = 0;
   }
   else if(type == "TS_DIST") {
      if(is_active) return; 
      popupCurrentTS_Dist += (direction * ButtonStepPoints); if(popupCurrentTS_Dist < 0) popupCurrentTS_Dist = 0;
   }
   
   double step = ButtonStepPoints * _Point;
   long posType = PositionGetInteger(POSITION_TYPE); 
   if(type == "SL") {
      if(popupCurrentSL == 0) {
         double open = 0; if(PositionSelectByTicket(editTicket)) open = PositionGetDouble(POSITION_PRICE_OPEN);
         popupCurrentSL = (posType == POSITION_TYPE_BUY) ? (open - step) : (open + step);
      } else popupCurrentSL += (posType == POSITION_TYPE_BUY ? -1 : 1) * (direction * step); 
      popupCurrentSL = NormalizePrice(popupCurrentSL);
   }
   else if(type == "TP") {
      if(popupCurrentTP == 0) {
         double open = 0; if(PositionSelectByTicket(editTicket)) open = PositionGetDouble(POSITION_PRICE_OPEN);
         popupCurrentTP = (posType == POSITION_TYPE_BUY) ? (open + step) : (open - step);
      } else popupCurrentTP += (posType == POSITION_TYPE_BUY ? 1 : -1) * (direction * step); 
      popupCurrentTP = NormalizePrice(popupCurrentTP);
   }
   UpdatePopupDisplay();
}

void UpdatePopupDisplay() {
   ObjectSetString(0, txtSLVal, OBJPROP_TEXT, (popupCurrentSL == 0) ? "0.0000" : DoubleToString(popupCurrentSL, _Digits));
   ObjectSetString(0, txtTPVal, OBJPROP_TEXT, (popupCurrentTP == 0) ? "0.0000" : DoubleToString(popupCurrentTP, _Digits));
   ObjectSetString(0, txtTSStartVal, OBJPROP_TEXT, IntegerToString(popupCurrentTS_Start));
   ObjectSetString(0, txtTSDistVal, OBJPROP_TEXT, IntegerToString(popupCurrentTS_Dist));
   ChartRedraw();
}

void ProcessPopupConfirm() {
   ModifySingleTicket(editTicket, popupCurrentSL, popupCurrentTP);
   SaveTradeMemory(editTicket, popupCurrentTS_Start, popupCurrentTS_Dist);
   CloseModifyPopup();
}

void CloseModifyPopup() {
   ObjectDelete(0, bgPopup); ObjectDelete(0, lblPopup); 
   ObjectDelete(0, "lblSLTitle"); ObjectDelete(0, btnSL_Sub); ObjectDelete(0, txtSLVal); ObjectDelete(0, btnSL_Add);
   ObjectDelete(0, "lblTPTitle"); ObjectDelete(0, btnTP_Sub); ObjectDelete(0, txtTPVal); ObjectDelete(0, btnTP_Add); 
   ObjectDelete(0, "lblTSStartTitle"); ObjectDelete(0, btnTSStart_Sub); ObjectDelete(0, txtTSStartVal); ObjectDelete(0, btnTSStart_Add);
   ObjectDelete(0, "lblTSDistTitle"); ObjectDelete(0, btnTSDist_Sub); ObjectDelete(0, txtTSDistVal); ObjectDelete(0, btnTSDist_Add);
   ObjectDelete(0, btnConfirm); ObjectDelete(0, btnCancel);
   popupActive = false; editTicket = 0; ChartRedraw();
}

// === TẠO VÀ CẬP NHẬT PANEL CHÍNH ===
void CreatePanel() {
   if(panelCreated) return;
   int x = 10, y = 20, w = 280, h = 360; 
   CreateRect("panelBG", x-5, y-5, w+10, h+10, C'25,25,40', 0); CreateRect("panelHeader", x, y, w, 35, C'50,50,100', 0);
   CreateLabel("lblTitle", x+80, y+5, "TRADE DASHBOARD", clrWhite, 11); y += 35;
   string mode = MQLInfoInteger(MQL_TESTER) ? "MODE: BACKTEST" : "MODE: REAL TRADE"; color modeClr = MQLInfoInteger(MQL_TESTER) ? C'200,200,255' : clrLime;
   CreateLabel("lblMode", x+10, y, mode, modeClr, 8); y += 18;
   CreateLabel("lblInfo", x+10, y, "Positions: 0", clrWhite, 8); CreateLabel("lblProfit", x+140, y, "P&L: 0.00", clrYellow, 8);
   
   y += 20; CreateLabel("lblSL", x+10, y, "SL (pts):", clrWhite, 8); CreateButton(btnMainSL_Sub, x+60, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtSL", x+82, y-2, 45, 18, IntegerToString(currentMainSL), 100, true); CreateButton(btnMainSL_Add, x+129, y-2, 20, 18, "+", clrGreen, 10);
   CreateLabel("lblRR", x+155, y, "RR: 0.00", clrLime, 8);
   
   y += 22; CreateLabel("lblTP", x+10, y, "TP (pts):", clrWhite, 8); CreateButton(btnMainTP_Sub, x+60, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTP", x+82, y-2, 45, 18, IntegerToString(currentMainTP), 100, true); CreateButton(btnMainTP_Add, x+129, y-2, 20, 18, "+", clrGreen, 10);
   
   y += 22; CreateLabel("lblLot", x+10, y, "Lot:", clrWhite, 8); CreateButton(btnMainLot_Sub, x+60, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtLot", x+82, y-2, 45, 18, DoubleToString(currentMainLot, 2), 100, true); CreateButton(btnMainLot_Add, x+129, y-2, 20, 18, "+", clrGreen, 10);
   
   y += 22; CreateLabel("lblTSStart", x+10, y, "T.Start:", clrWhite, 8); CreateButton(btnMainTSStart_Sub, x+60, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTSStart", x+82, y-2, 45, 18, IntegerToString(currentMainTS_Start), 100, true); CreateButton(btnMainTSStart_Add, x+129, y-2, 20, 18, "+", clrGreen, 10);
   
   y += 22; CreateLabel("lblTSDist", x+10, y, "T.Dist:", clrWhite, 8); CreateButton(btnMainTSDist_Sub, x+60, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTSDist", x+82, y-2, 45, 18, IntegerToString(currentMainTS_Dist), 100, true); CreateButton(btnMainTSDist_Add, x+129, y-2, 20, 18, "+", clrGreen, 10);
   
   y += 25; CreateButton("btnBuy", x+10, y, 120, 32, "BUY", clrGreen, 11); CreateButton("btnSell", x+140, y, 120, 32, "SELL", clrRed, 11);
   panelCreated = true; ChartRedraw();
}

// === CẬP NHẬT GIAO DIỆN (NÂNG CẤP ĐỔI MÀU CHỮ) ===
void UpdateInfo(bool forceUpdate) {
   RegisterNewTrades(); 

   int currentPositions = PositionsTotal();
   bool layoutChanged = (currentPositions != lastPositionsCount);
   if(!forceUpdate && !layoutChanged) { UpdatePnLText(); return; }
   lastPositionsCount = currentPositions;
   
   if(layoutChanged) { DeleteAllPositionObjects(); CleanUpTrailingLines(); }
   
   int cnt = 0, yPos = 250; double profit = 0;
   
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      cnt++; profit += PositionGetDouble(POSITION_PROFIT);
      string posText = StringFormat("#%I64u | %s | %.2f", ticket, PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL", PositionGetDouble(POSITION_VOLUME));
      string posText2 = StringFormat("P/L: %.2f", PositionGetDouble(POSITION_PROFIT));
      string lblName = "Pos_Label_" + IntegerToString(ticket);
      
      // Lấy trạng thái Active của TS
      int dummy1, dummy2; bool is_ts_active = false;
      GetTradeMemory(ticket, dummy1, dummy2, is_ts_active);
      
      // [FIX MÀU MỚI] Đổi màu chữ nếu TS đã chạy!
      color lblColor = is_ts_active ? clrMagenta : clrWhite;
      
      if(layoutChanged) {
         CreateLabel(lblName, 20, yPos, posText + " | " + posText2, lblColor, 8);
         CreateButton("Pos_Close_" + IntegerToString(ticket), 220, yPos-2, 35, 18, "X", clrRed, 8);
         CreateButton("Pos_Edit_" + IntegerToString(ticket), 260, yPos-2, 35, 18, "E", clrOrange, 8);
      } else { 
         ObjectSetString(0, lblName, OBJPROP_TEXT, posText + " | " + posText2); 
         ObjectSetInteger(0, lblName, OBJPROP_COLOR, lblColor); // Cập nhật màu động
      }
      yPos += 25;
   }
   UpdatePnLText();
}

void UpdatePnLText() {
   double profit = 0; int cnt = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) { profit += PositionGetDouble(POSITION_PROFIT); cnt++; }
   }
   color clr = (profit >= 0) ? clrLime : clrRed;
   if(ObjectFind(0, "lblProfit") >= 0) { ObjectSetInteger(0, "lblProfit", OBJPROP_COLOR, clr); ObjectSetString(0, "lblInfo", OBJPROP_TEXT, StringFormat("Positions: %d", cnt)); ObjectSetString(0, "lblProfit", OBJPROP_TEXT, StringFormat("P&L: %.2f", profit)); }
}

void DeleteAllPositionObjects() {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) { string name = ObjectName(0, i); if(StringFind(name, "Pos_") == 0) ObjectDelete(0, name); }
}
//+------------------------------------------------------------------+