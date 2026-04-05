//+------------------------------------------------------------------+
//|                       EE_Constants.mqh                           |
//| Input parameters, struct EventRecord, biến toàn cục              |
//+------------------------------------------------------------------+
#ifndef EE_CONSTANTS_MQH
#define EE_CONSTANTS_MQH

#include <Trade/Trade.mqh>

//====================================================================
// INPUTS
//====================================================================
input string   _inp1               = "=== TÍN HIỆU ===";
input string   InpEventTitle       = "Core CPI m/m";  // Tên sự kiện (tìm theo chuỗi chứa)
input string   InpNewsFile         = "news_data.csv"; // File CSV (trong Common/Files/)
input bool     InpFilterByCurrency = true; // true=chỉ trade khi currency khớp symbol | false=trade mọi cặp tiền

input string   _inp2            = "=== QUẢN LÝ LỆNH ===";
input double   InpSL_Percent    = 2.0;  // Stop Loss (% từ giá vào lệnh)
input double   InpRate_TP_SL    = 2.0;  // TP = SL × tỉ lệ này
input int      InpCloseMinute   = 60;   // Đóng sau N phút nếu chưa hit TP/SL (0 = không dùng)

input string   _inp_ms          = "=== MULTI-SYMBOL & RISK MANAGER ===";
input bool     inp_multi_symbol = true;                           // true = trade trên nhiều symbol | false = chỉ chart hiện tại
input string   inp_symbol_array = "EURUSD,GBPUSD,USDJPY,AUDCAD"; // Danh sách symbol, phân cách bằng dấu ","
input double   inp_risk_percent = 1;    // % risk trên equity nếu hit SL (0 = tắt, dùng inp_lot)
input double   inp_lot          = 0.01; // Lot cố định khi inp_risk_percent = 0

input string   _inp4            = "=== CÀI ĐẶT ===";
input int      InpMagicNumber   = 20250315; // Magic number
input int      InpSlippage      = 10;       // Slippage (points)

input string   _inp5            = "=== MARTINGALE ===";
input bool     InpMartingale    = false;    // true = bật Martingale sau mỗi lệnh thua
input double   InpMgMultiplier  = 2.0;     // Hệ số nhân lot sau khi thua (VD: 2.0 = x2)
input int      InpMgMaxLevel    = 4;        // Số cấp Martingale tối đa (0 = không giới hạn)

//====================================================================
// STRUCT
//====================================================================
struct EventRecord
  {
   datetime          event_time;
   string            currency;
   string            title;
   double            actual;
   double            forecast;
   bool              processed;
  };

//====================================================================
// GLOBALS
//====================================================================
CTrade      trade;

EventRecord g_events[];
bool        g_eventsLoaded   = false;
int         g_nextEventIdx   = 0;   // Tối ưu: skip events đã qua khi Backtest/Optimize

ulong       g_processedIds[200];    // Real chart: track IDs đã xử lý để tránh double-open
int         g_processedCount = 0;

// Runtime params – chỉnh qua Panel mà không cần mở F7 (Read-only Inp* không gán được lúc runtime)
double      g_LotSize    = 0.01;
double      g_SL_Percent = 2.0;
double      g_Rate_TP_SL = 2.0;

// Multi-symbol
string      g_symbols[];        // Array symbols đã parse từ inp_symbol_array
int         g_symbolCount = 0;  // Số lượng symbols
int         g_symHandles[];     // iMA handles ép tester load tick data cho secondary symbols

// Martingale – tracking in-memory per symbol, O(1), không cần HistorySelect
#define MG_SYM_MAX 8
string   g_mgSymbols[MG_SYM_MAX];
double   g_mgNextLot[MG_SYM_MAX]; // 0 = dùng baseLot
int      g_mgCount = 0;

// Gọi từ OnTradeTransaction khi lệnh đóng (TP/SL hit hoặc timeout)
void MgOnClose(string symb, double lotUsed, double profit)
  {
   if(!InpMartingale) return;
   // Tìm hoặc tạo slot
   int idx = -1;
   for(int i = 0; i < g_mgCount; i++)
      if(g_mgSymbols[i] == symb) { idx = i; break; }
   if(idx < 0)
     {
      if(g_mgCount >= MG_SYM_MAX) return;
      idx = g_mgCount++;
      g_mgSymbols[idx] = symb;
      g_mgNextLot[idx] = 0;
     }
   if(profit >= 0)
      g_mgNextLot[idx] = 0;   // Thắng/hòa → reset
   else
      g_mgNextLot[idx] = lotUsed * InpMgMultiplier;  // Thua → lưu lot × multiplier
  }

// Trả về lot tiếp theo: O(1), không HistorySelect
double GetMgLot(double baseLot, string symb)
  {
   if(!InpMartingale) return baseLot;
   for(int i = 0; i < g_mgCount; i++)
      if(g_mgSymbols[i] == symb && g_mgNextLot[i] > 0)
        {
         double lot = g_mgNextLot[i];
         // Cap tối đa: baseLot × multiplier^maxLevel (dùng baseLot thực tế, không dùng g_LotSize)
         if(InpMgMaxLevel > 0)
            lot = MathMin(lot, baseLot * MathPow(InpMgMultiplier, InpMgMaxLevel));
         return lot;
        }
   return baseLot;
  }

// Duplicate news filter – chống nhồi lệnh do CSV trùng dữ liệu
#define DUPNEWS_MAX    10       // Số tin lưu tối đa
#define DUPNEWS_SECS   60      // Khoảng thời gian chống trùng (giây)
string      g_dupKeys[DUPNEWS_MAX];
datetime    g_dupTimes[DUPNEWS_MAX];
int         g_dupHead = 0;     // circular buffer pointer

bool IsDuplicateNews(string key)
  {
   datetime now = TimeCurrent();
   for(int i = 0; i < DUPNEWS_MAX; i++)
     {
      if(g_dupKeys[i] == key && now - g_dupTimes[i] < DUPNEWS_SECS)
         return true;
     }
   // Lưu vào vị trí tiếp theo trong circular buffer
   g_dupKeys[g_dupHead]  = key;
   g_dupTimes[g_dupHead] = now;
   g_dupHead = (g_dupHead + 1) % DUPNEWS_MAX;
   return false;
  }

#endif
//+------------------------------------------------------------------+
