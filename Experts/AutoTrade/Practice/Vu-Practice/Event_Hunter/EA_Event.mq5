//+------------------------------------------------------------------+
//|                         EA_Event.mq5                             |
//| Trade vào tin tức: BUY khi actual > forecast, SELL ngược lại    |
//|                                                                  |
//| Real Chart → MQL5 Economic Calendar (online, tự động)           |
//| Backtest   → File CSV từ Common\Files\ (offline, đọc 1 lần)     |
//|                                                                  |
//| Cách tạo file CSV cho Backtest:                                  |     
//|   Chạy Scripts\DumpNewsCalendar.mq5 trên Real Chart             |
//|   → Tự tạo Common\Files\news_data.csv                           |
//|                                                                  |
//| Điều kiện BUY : actual > forecast + title chứa InpEventTitle    |
//| Điều kiện SELL: actual < forecast + title chứa InpEventTitle    |
//| SL = % giá vào | TP = SL × InpRate_TP_SL                        |
//| Tự đóng lệnh sau InpCloseMinute nếu chưa hit TP/SL              |
//+------------------------------------------------------------------+
#property tester_file "news_data.csv"   // Shipper: MT5 tự copy file vào từng Agent khi Optimize
#property copyright "Event Hunter EA"
#property version   "1.0"
#property strict

#include "Model/EE_Constants.mqh"      // inputs + struct EventRecord + globals
#include "Model/EE_EventModel.mqh"     // CSV loading, currency check, sort, dedup
#include "Model/EE_TradeExecution.mqh" // OpenTrade, ManagePosition, GetMyPositionTicket
#include "Model/EE_SignalEngine.mqh"   // ProcessBacktestEvents, ProcessCalendarEvents
#include "EE_PanelView.mqh"            // UI panel: Next Target / Risk / Filters

//====================================================================
// INIT / DEINIT / TICK
//====================================================================
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

// Khởi runtime params từ inp_* (input là read-only, g_* có thể điều chỉnh qua Panel)
   g_LotSize    = inp_lot;       // g_LotSize có thể chỉnh qua Panel ±Lot
   g_SL_Percent = InpSL_Percent;
   g_Rate_TP_SL = InpRate_TP_SL;

// Multi-symbol: parse danh sách symbol
   if(inp_multi_symbol)
     {
      ParseSymbolArray();
      // Tạo iMA handle cho mỗi secondary symbol → ép MT5 Tester load tick data
      ArrayResize(g_symHandles, g_symbolCount);
      for(int s = 0; s < g_symbolCount; s++)
         g_symHandles[s] = iMA(g_symbols[s], _Period, 1, 0, MODE_SMA, PRICE_CLOSE);
     }

   if(MQLInfoInteger(MQL_TESTER))
      LoadEventsFromFile();

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      DrawEEPanel();         // Vẽ ngay khi gắn EA, không đợi tick
      EventSetTimer(1);      // Cập nhật panel mỗi giây ngay cả khi không có tick
      Print("✓ EA_Event khởi động | Symbol=", _Symbol,
            "  Event='", InpEventTitle, "'"
            "  SL=", g_SL_Percent, "%"
            "  TP=", g_Rate_TP_SL, "×SL"
            "  CloseAfter=", InpCloseMinute, " phút");
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Giải phóng iMA handles dùng cho multi-symbol tester
   for(int s = 0; s < ArraySize(g_symHandles); s++)
      if(g_symHandles[s] != INVALID_HANDLE)
         IndicatorRelease(g_symHandles[s]);

   EventKillTimer();
   DeleteEEPanel();
   ArrayFree(g_events);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   PanelChartEvent(id, sparam);
  }

//+------------------------------------------------------------------+
//| Theo dõi lệnh TP/SL hit → cập nhật Martingale                   |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
// Real Chart: cập nhật panel mỗi giây (đếm ngược, spread)
   if(!MQLInfoInteger(MQL_TESTER))
      DrawEEPanel();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() // Chạy mỗi tick – throttle 5 phút/tick nằm trong ProcessBacktestEvents; IsDuplicateNews chống quét trùng sự kiện
  {
   bool isVisual = MQLInfoInteger(MQL_VISUAL_MODE) != 0;

// Backtest Visual: poll nút thủ công (OnChartEvent không hoạt động trong backtest)
   if(isVisual)
      PanelScanButtons();

// Manage positions: single hoặc tất cả symbols trong danh sách
   if(inp_multi_symbol && g_symbolCount > 0)
     {
      for(int s = 0; s < g_symbolCount; s++)
         ManagePosition(g_symbols[s]);
     }
   else
      ManagePosition();

   if(MQLInfoInteger(MQL_TESTER))
      ProcessBacktestEvents();
   else
      ProcessCalendarEvents();

// Vẽ panel: chỉ Real Chart hoặc Backtest Visual (bỏ qua Optimize và Backtest thường)
   if(!MQLInfoInteger(MQL_TESTER) || isVisual)
      DrawEEPanel();
  }
//+------------------------------------------------------------------+
