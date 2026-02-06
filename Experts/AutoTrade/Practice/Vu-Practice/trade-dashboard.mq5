//+------------------------------------------------------------------+
//|                           Trade Dashboard v2.0                     |
//|                  Optimized for Speed & Clean Code                  |
//+------------------------------------------------------------------+
// Ghi chú: Đây là EA giao dịch bán tay với hỗ trợ tự động
// Tính năng: Buy/Sell với SL+TP, Modify vị thế, Auto mode (RSI+MA)
// Hotkeys: B=Buy, S=Sell, 1=ModSL, 2=ModTP, 3=ModBoth, A=Toggle Auto

#property copyright "Trade Dashboard"
#property version   "2.0"
#property strict

#include <Trade/Trade.mqh>  // Thư viện giao dịch MT5 chính thức

// === INPUT PARAMETERS - Người dùng có thể thay đổi trong Properties ===
input double LotSize = 0.1;           // Kích thước lệnh (lot)
input int StopLossPoints = 500;       // Stop Loss mặc định (điểm)
input int TakeProfitPoints = 1000;    // Take Profit mặc định (điểm)
input int MagicNumber = 123456;       // Magic Number để quản lý lệnh
input bool AutoTradeEnabled = false;  // Bật/tắt chế độ tự động khi khởi động
input int RSI_Period = 14;            // Chu kỳ RSI (14 là chuẩn)
input int MA_Fast = 10;               // Chu kỳ MA nhanh
input int MA_Slow = 20;               // Chu kỳ MA chậm
input int UiUpdateMs = 250;           // Chu ky cap nhat UI (ms)

// === BIẾN GLOBAL - Được sử dụng xuyên suốt chương trình ===
CTrade trade;                    // Đối tượng giao dịch (từ Trade.mqh)
bool panelCreated;               // Cờ kiểm tra panel đã được tạo chưa
int handleRSI, handleMA_Fast, handleMA_Slow;  // Handle (tham chiếu) đến indicator
bool isAutoMode;                 // Cờ chế độ tự động
datetime lastBar;                // Thời gian nến cuối cùng (để chỉ trade 1 lần/nến)

// === MẢNG UI OBJECTS - Danh sách các đối tượng giao diện ===
string UI[] = {"panelBG","panelHeader","lblTitle","lblMode","lblInfo","lblProfit","edtSL","edtTP",
               "lblSL","lblTP","lblRR","btnBuy","btnSell","btnModSL","btnModTP","btnModBoth","btnAuto"};

int OnInit()
{
   // Ghi magic number vào CTrade để tất cả lệnh có magic này
   trade.SetExpertMagicNumber(MagicNumber);
   
   // Cho phép chart nhận sự kiện chuột (để bấm nút)
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   
   // Chỉ tạo UI nếu không phải Optimization Mode
   if(!MQLInfoInteger(MQL_OPTIMIZATION)) CreatePanel();

   if(UiUpdateMs > 0) EventSetMillisecondTimer(UiUpdateMs);
   
   // Khởi tạo 3 indicator cho auto trading
   handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   handleMA_Fast = iMA(_Symbol, PERIOD_CURRENT, MA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Slow = iMA(_Symbol, PERIOD_CURRENT, MA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   isAutoMode = AutoTradeEnabled;
   
   Print("✓ Dashboard v2.0 Ready | Hotkeys: B/S/1/2/3/A");
   return INIT_SUCCEEDED;
}

// === CLEANUP - Gọi khi EA bị unload ===
void OnDeinit(const int reason)
{
   EventKillTimer();
   // Loop qua mảng UI và xóa tất cả objects
   for(int i = 0; i < ArraySize(UI); i++) ObjectDelete(0, UI[i]);
}

// === TICK - Gọi mỗi khi có tick mới ===
void OnTick()
{
   if(isAutoMode) CheckAutoSignals();  // Kiểm tra tín hiệu auto nếu bật
}

void OnTimer()
{
   UpdateInfo();
}

void OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& req,const MqlTradeResult& res)
{
   UpdateInfo();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // === XỬ LÝ HOTKEYS (làm việc ở mọi nơi) ===
   if(id == CHARTEVENT_KEYDOWN)
   {
      // lparam = ASCII code của phím bấm
      if(lparam == 66) OpenBuy();                    // B = 66
      else if(lparam == 83) OpenSell();              // S = 83
      else if(lparam == 49) ModifyStopLoss();        // 1 = 49
      else if(lparam == 50) ModifyTakeProfit();      // 2 = 50
      else if(lparam == 51) ModifyBoth();            // 3 = 51
      else if(lparam == 65) ToggleAutoMode();        // A = 65
      ChartRedraw();
   }
   // === XỬ LÝ CLICK NÚT (không work trong Strategy Tester) ===
   else if(id == CHARTEVENT_OBJECT_CLICK && sparam != "")
   {
      if(sparam == "btnBuy") OpenBuy();
      else if(sparam == "btnSell") OpenSell();
      else if(sparam == "btnModSL") ModifyStopLoss();
      else if(sparam == "btnModTP") ModifyTakeProfit();
      else if(sparam == "btnModBoth") ModifyBoth();
      else if(sparam == "btnAuto") ToggleAutoMode();
      ChartRedraw();
   }
}

void CreatePanel()
{
   // === TẠO GIAO DIỆN DASHBOARD ===
   if(panelCreated) return;  // Nếu đã tạo thì bỏ qua
   
   int x = 10, y = 20, w = 280, h = 420;  // Vị trí và kích thước panel
   // ✓ Nền đen xám + border trắng
   CreateRect("panelBG", x-5, y-5, w+10, h+10, C'25,25,40', 0);
   // ✓ Header xanh nước biển
   CreateRect("panelHeader", x, y, w, 35, C'50,50,100', 0);
   CreateLabel("lblTitle", x+80, y+5, "TRADE DASHBOARD", clrWhite, 11);
   y += 35;
   
   // === THÔNG TIN CHỨNG CHỉ VÀ CHỈ THỊ ===
   CreateLabel("lblMode", x+10, y, "EURUSD H1 | Manual", C'200,200,255', 8);
   y += 18;
   // Hiện số position + tổng P&L
   CreateLabel("lblInfo", x+10, y, "Positions: 0", clrWhite, 8);
   CreateLabel("lblProfit", x+140, y, "P&L: 0.00", clrYellow, 8);
   y += 20;
   
   // === NHẬP STOPLOSS (chặn lỗ) ===
   CreateLabel("lblSL", x+10, y, "SL (pts):", clrWhite, 8);
   CreateEdit("edtSL", x+70, y-2, 50, 18, IntegerToString(StopLossPoints));
   // Hiện Risk/Reward Ratio = TP/SL
   CreateLabel("lblRR", x+130, y, "RR: 0.00", clrLime, 8);
   y += 22;
   
   // === NHẬP TAKEPROFIT (lấy lợi) ===
   CreateLabel("lblTP", x+10, y, "TP (pts):", clrWhite, 8);
   CreateEdit("edtTP", x+70, y-2, 50, 18, IntegerToString(TakeProfitPoints));
   y += 25;
   
   // === NÚT MUA/BÁN ===
   CreateButton("btnBuy", x+10, y, 120, 32, "BUY", clrGreen, 11);
   CreateButton("btnSell", x+140, y, 120, 32, "SELL", clrRed, 11);
   y += 38;
   
   // === NÚT MODIFY (cập nhật SL/TP) ===
   CreateButton("btnModSL", x+10, y, 55, 22, "ModSL", clrOrange, 9);
   CreateButton("btnModTP", x+75, y, 55, 22, "ModTP", clrOrange, 9);
   CreateButton("btnModBoth", x+140, y, 110, 22, "Modify", clrDodgerBlue, 9);
   y += 28;
   
   // === NÚT AUTO TRADING ===
   // Hiện "🤖 AUTO: ON" nếu auto mode bật, ngược lại "👆 MANUAL"
   CreateButton("btnAuto", x+10, y, 240, 24, isAutoMode ? "🤖 AUTO: ON" : "👆 MANUAL", 
                isAutoMode ? clrLime : clrGray, 9);
   
   panelCreated = true;
   ChartRedraw();
}

void CreateRect(string name, int x, int y, int w, int h, color clr, int zorder)
{
   // === TẠO HÌNH CHỮ NHẬT (dùng làm nền, border) ===
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);       // Lề trái
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);       // Lề trên
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);           // Chiều rộng
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);           // Chiều cao
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);       // Màu nền
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);         // Nằm phía sau đồ thị
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);     // Thứ tự hiển thị
}

void CreateLabel(string name, int x, int y, string txt, color clr, int size)
{
   // === TẠO NHÃN VĂN BẢN (hiển thị thông tin, tên trường) ===
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);       // Lề trái
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);       // Lề trên
   ObjectSetString(0, name, OBJPROP_TEXT, txt);           // Nội dung text
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);         // Màu chữ
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);     // Cỡ chữ
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 5);          // Hiển thị phía trước
}

void CreateButton(string name, int x, int y, int w, int h, string txt, color clr, int size)
{
   // === TẠO NÚT BẤM (BUY, SELL, Modify, ...) ===
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);       // Lề trái
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);       // Lề trên
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);           // Chiều rộng
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);           // Chiều cao
   ObjectSetString(0, name, OBJPROP_TEXT, txt);           // Nội dung text trên nút
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);    // Màu chữ (trắng)
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);       // Màu nền nút
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);     // Cỡ chữ
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);   // Cho phép bấm
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);         // Hiển thị phía trước
}

void CreateEdit(string name, int x, int y, int w, int h, string txt)
{
   // === TẠO HỘP NHẬP LIỆU (dùng nhập SL, TP) ===
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);       // Lề trái
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);       // Lề trên
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);           // Chiều rộng
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);           // Chiều cao
   ObjectSetString(0, name, OBJPROP_TEXT, txt);           // Giá trị ban đầu
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);    // Màu chữ (đen)
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);  // Màu nền (trắng)
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);         // Hiển thị phía trước
}

//+------------------------------------------------------------------+
//| Update info label                                                 |
//+------------------------------------------------------------------+
void UpdateInfo()
{
   // === CẬP NHẬT THÔNG TIN TRÊN PANEL ===
   // Đếm số lệnh mở + tính tổng P&L
   int cnt = 0;
   double profit = 0;
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         cnt++;
         profit += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   // ✓ Nếu P&L >= 0 hiển thị xanh (lãi), ngược lại đỏ (lỗ)
   color clr = (profit >= 0) ? clrLime : clrRed;
   ObjectSetInteger(0, "lblProfit", OBJPROP_COLOR, clr);
   // ✓ Cập nhật thông tin vị thế + lợi/lỗ
   ObjectSetString(0, "lblInfo", OBJPROP_TEXT, StringFormat("Positions: %d | P&L: %.2f", cnt, profit));
   ObjectSetString(0, "lblProfit", OBJPROP_TEXT, StringFormat("Profit: %.2f", profit));
   
   // ✓ Tính Risk/Reward Ratio = TP / SL
   int sl = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
   int tp = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
   ObjectSetString(0, "lblRR", OBJPROP_TEXT, StringFormat("RR: %.2f", (sl > 0 && tp > 0) ? (double)tp/sl : 0));
}

void OpenBuy()
{
   // === MỞ LỆNH MUA ===
   // 1. Lấy SL/TP từ ô nhập liệu, nếu rỗng dùng giá trị mặc định
   int sl = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
   int tp = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
   if(sl <= 0) sl = StopLossPoints;  // Nếu không nhập SL thì dùng giá trị Input
   if(tp <= 0) tp = TakeProfitPoints; // Nếu không nhập TP thì dùng giá trị Input
   
   // 2. Lấy giá ASK hiện tại (giá bán)
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   // 3. Tính giá SL = Ask - SL (points), Giá TP = Ask + TP (points)
   trade.Buy(LotSize, _Symbol, tick.ask, tick.ask - sl*_Point, tick.ask + tp*_Point, "Buy");
}

void OpenSell()
{
   // === MỞ LỆNH BÁN ===
   // 1. Lấy SL/TP từ ô nhập liệu, nếu rỗng dùng giá trị mặc định
   int sl = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
   int tp = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
   if(sl <= 0) sl = StopLossPoints;  // Nếu không nhập SL thì dùng giá trị Input
   if(tp <= 0) tp = TakeProfitPoints; // Nếu không nhập TP thì dùng giá trị Input
   
   // 2. Lấy giá BID hiện tại (giá mua)
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   // 3. Tính giá SL = Bid + SL (points), Giá TP = Bid - TP (points)
   trade.Sell(LotSize, _Symbol, tick.bid, tick.bid + sl*_Point, tick.bid - tp*_Point, "Sell");
}

void ModifyStopLoss()
{
   // === CẬP NHẬT STOPLOSS CHO TẤT CẢ LỆNH ===
   int sl = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
   if(sl <= 0) return;  // Nếu SL = 0 hoặc âm thì bỏ qua
   
   // Duyệt tất cả position từ cuối về đầu (an toàn hơn)
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);  // Giá mở lệnh
         double tp = PositionGetDouble(POSITION_TP);            // TP hiện tại
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         // ✓ BUY: newSL = Open - SL, SELL: newSL = Open + SL
         double newSL = (type == POSITION_TYPE_BUY) ? open - sl*_Point : open + sl*_Point;
         trade.PositionModify(PositionGetInteger(POSITION_TICKET), newSL, tp);
      }
   }
}

void ModifyTakeProfit()
{
   // === CẬP NHẬT TAKEPROFIT CHO TẤT CẢ LỆNH ===
   int tp = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
   if(tp <= 0) return;  // Nếu TP = 0 hoặc âm thì bỏ qua
   
   // Duyệt tất cả position từ cuối về đầu (an toàn hơn)
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);  // Giá mở lệnh
         double sl = PositionGetDouble(POSITION_SL);            // SL hiện tại
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         // ✓ BUY: newTP = Open + TP, SELL: newTP = Open - TP
         double newTP = (type == POSITION_TYPE_BUY) ? open + tp*_Point : open - tp*_Point;
         trade.PositionModify(PositionGetInteger(POSITION_TICKET), sl, newTP);
      }
   }
}

void ModifyBoth()
{
   // === CẬP NHẬT CẢ STOPLOSS VÀ TAKEPROFIT ===
   int sl = (int)StringToInteger(ObjectGetString(0, "edtSL", OBJPROP_TEXT));
   int tp = (int)StringToInteger(ObjectGetString(0, "edtTP", OBJPROP_TEXT));
   
   // Duyệt tất cả position từ cuối về đầu (an toàn hơn)
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);  // Giá mở lệnh
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         // ✓ Tính newSL và newTP dựa vào loại lệnh (BUY/SELL)
         double newSL = (type == POSITION_TYPE_BUY) ? open - sl*_Point : open + sl*_Point;
         double newTP = (type == POSITION_TYPE_BUY) ? open + tp*_Point : open - tp*_Point;
         trade.PositionModify(PositionGetInteger(POSITION_TICKET), newSL, newTP);
      }
   }
}

void CheckAutoSignals()
{
   // === KIỂM TRA TÍN HIỆU GIAO DỊCH TỰ ĐỘNG ===
   // Chỉ kiểm tra khi có candle mới (1 lần mỗi candle)
   datetime curBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(curBar == lastBar) return;  // Nếu candle cũ thì bỏ qua
   lastBar = curBar;
   
   // Lấy giá trị hiện tại và giá trị candle trước của các chỉ báo
   double rsi[1], maf[1], mas[1], rsi_p[1], maf_p[1], mas_p[1];
   // RSI(14) buffer 0
   if(CopyBuffer(handleRSI, 0, 1, 1, rsi) < 1 || CopyBuffer(handleRSI, 0, 2, 1, rsi_p) < 1) return;
   // MA Fast(10) buffer 0
   if(CopyBuffer(handleMA_Fast, 0, 1, 1, maf) < 1 || CopyBuffer(handleMA_Fast, 0, 2, 1, maf_p) < 1) return;
   // MA Slow(20) buffer 0
   if(CopyBuffer(handleMA_Slow, 0, 1, 1, mas) < 1 || CopyBuffer(handleMA_Slow, 0, 2, 1, mas_p) < 1) return;
   
   // ✓ Kiểm tra xem đã có position nào open rồi không
   bool pos_exists = false;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         pos_exists = true;
         break;
      }
   }
   
   // ✓ Nếu chưa có position, kiểm tra tín hiệu giao dịch:
   //   BUY: MA Fast vượt lên trên MA Slow (golden cross) + RSI > 50 (xu hướng up)
   //   SELL: MA Fast rơi xuống dưới MA Slow (death cross) + RSI < 50 (xu hướng down)
   if(!pos_exists)
   {
      if(maf_p[0] <= mas_p[0] && maf[0] > mas[0] && rsi[0] > 50) OpenBuy();   // Golden Cross
      else if(maf_p[0] >= mas_p[0] && maf[0] < mas[0] && rsi[0] < 50) OpenSell();  // Death Cross
   }
}

void ToggleAutoMode()
{
   // === BẬT/TẮT CHỢ GIAO DỊCH TỰ ĐỘNG ===
   isAutoMode = !isAutoMode;
   // ✓ Đổi màu nút: Xanh nếu ON, Xám nếu OFF
   color clr = isAutoMode ? clrLime : clrGray;
   string txt = isAutoMode ? "🤖 AUTO: ON" : "👆 MANUAL";
   ObjectSetInteger(0, "btnAuto", OBJPROP_BGCOLOR, clr);
   ObjectSetString(0, "btnAuto", OBJPROP_TEXT, txt);
   Print(isAutoMode ? "✅ AUTO MODE" : "⭕ MANUAL MODE");
   ChartRedraw();
}


