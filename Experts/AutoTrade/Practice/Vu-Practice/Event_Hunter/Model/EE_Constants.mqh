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
input double   InpLotSize       = 0.01; // Lot size
input double   InpSL_Percent    = 2.0;  // Stop Loss (% từ giá vào lệnh)
input double   InpRate_TP_SL    = 2.0;  // TP = SL × tỉ lệ này
input int      InpCloseMinute   = 60;   // Đóng sau N phút nếu chưa hit TP/SL (0 = không dùng)

input string   _inp3            = "=== BẢO VỆ VÀO LỆNH ===";
input int      InpMaxSpread     = 30;   // Spread tối đa cho phép vào lệnh (points, 0 = không giới hạn)
input double   InpMaxGapPercent = 20.0; // Bỏ qua nếu giá đã chạy quá X% khoảng TP từ lúc tin ra (0 = không giới hạn)

input string   _inp4            = "=== CÀI ĐẶT ===";
input int      InpMagicNumber   = 20250315; // Magic number
input int      InpSlippage      = 10;       // Slippage (points)

//====================================================================
// STRUCT
//====================================================================
struct EventRecord
  {
   datetime         event_time;
   string           currency;
   string           title;
   double           actual;
   double           forecast;
   bool             processed;
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

double      g_lastEventPrice = 0.0; // Giá tại thời điểm tin ra (để kiểm tra Gap)

// Runtime params – chỉnh qua Panel mà không cần mở F7 (Read-only Inp* không gán được lúc runtime)
double      g_LotSize    = 0.01;
double      g_SL_Percent = 2.0;
double      g_Rate_TP_SL = 2.0;

#endif
