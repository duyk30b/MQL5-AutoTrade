//+------------------------------------------------------------------+
//|                      EE_EventModel.mqh                           |
//| Đọc CSV (backtest), helpers: currency check, sort, dedup IDs    |
//+------------------------------------------------------------------+
#ifndef EE_EVENT_MODEL_MQH
#define EE_EVENT_MODEL_MQH

#include "EE_Constants.mqh"

//--------------------------------------------------------------------
// Kiểm tra currency có liên quan đến symbol đang chạy
//--------------------------------------------------------------------
bool IsCurrencyRelevant(string cur)
// Kiểm tra nếu currency trùng với base hoặc quote của symbol
  {
   string base  = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string quote = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   if(StringLen(base)  < 3) base  = StringSubstr(_Symbol, 0, 3);
   if(StringLen(quote) < 3) quote = StringSubstr(_Symbol, 3, 3);
   StringToUpper(cur); StringToUpper(base); StringToUpper(quote);
   return (cur == base || cur == quote);
  }

//--------------------------------------------------------------------
// Parse double an toàn từ chuỗi CSV
//--------------------------------------------------------------------
double SafeParseDouble(string s)
// Trả về EMPTY_VALUE nếu không parse được(xóa khoảng trắng, bỏ header, hoặc actual=forecast)
  {
   StringTrimLeft(s); StringTrimRight(s);
   if(StringLen(s) == 0) return EMPTY_VALUE;
   return StringToDouble(s);
  }

//--------------------------------------------------------------------
// Sắp xếp events theo thời gian (insertion sort)
// → Cho phép dùng g_nextEventIdx để skip O(1)
//--------------------------------------------------------------------
void SortEventsByTime()
// Insertion sort đơn giản vì thường đã gần như sorted (theo thời gian trong file CSV)
  {
   int n = ArraySize(g_events);
   for(int i = 1; i < n; i++)
     {
      EventRecord key = g_events[i];
      int j = i - 1;
      while(j >= 0 && g_events[j].event_time > key.event_time)
        {
         g_events[j + 1] = g_events[j];
         j--;
        }
      g_events[j + 1] = key;
     }
  }

//--------------------------------------------------------------------
// Track event ID đã xử lý (real chart - tránh double-open)
//--------------------------------------------------------------------
bool IsIdProcessed(ulong id)
  {
   for(int i = 0; i < g_processedCount; i++)
      if(g_processedIds[i] == id) return true;
   return false;
  }

void MarkIdProcessed(ulong id)
  {
   if(g_processedCount >= 200)
     {
      // Shift bỏ nửa đầu khi đầy
      for(int i = 0; i < 100; i++)
         g_processedIds[i] = g_processedIds[i + 100];
      g_processedCount = 100;
     }
   g_processedIds[g_processedCount++] = id;
  }

//--------------------------------------------------------------------
// Load sự kiện từ CSV (Backtest & Optimization)
// Format CSV: THOI GIAN;TIEN TE;MUC DO;SU KIEN;THAT SU;DU BAO
// File nằm tại: Common\Files\<InpNewsFile>
//--------------------------------------------------------------------
void LoadEventsFromFile()
  {
   if(g_eventsLoaded) return;
   g_eventsLoaded = true;
   ArrayResize(g_events, 0);
   g_nextEventIdx = 0;

   int handle = FileOpen(InpNewsFile, FILE_READ|FILE_CSV|FILE_ANSI, ';'); // Bỏ FILE_COMMON: Agent đọc bản local trong sandbox
   if(handle == INVALID_HANDLE)
     {
      if(!MQLInfoInteger(MQL_OPTIMIZATION))
         Print("⚠️ EA_Event: Không tìm thấy '", InpNewsFile, "' trong Common/Files/");
      return;
     }

   int count        = 0;
   int skipCurrency = 0;
   int skipTitle    = 0;
   int skipValue    = 0;
   int totalRows    = 0;
   string firstCurrencySeen = "";   // debug: tiền tệ đầu tiên trong file
   string firstTitleSeen    = "";   // debug: tên event đầu tiên khớp currency

   while(!FileIsEnding(handle))
     {
      string dtStr     = FileReadString(handle); // cột 1: thời gian
      string cur       = FileReadString(handle); // cột 2: tiền tệ
      FileReadString(handle);                    // cột 3: mức độ (bỏ qua)
      string evTitle   = FileReadString(handle); // cột 4: tên sự kiện
      string actualS   = FileReadString(handle); // cột 5: actual
      string forecastS = FileReadString(handle); // cột 6: forecast

      if(StringLen(dtStr) < 10) continue;
      datetime t = StringToTime(dtStr);
      if(t == 0) continue; // bỏ header

      totalRows++;
      StringTrimLeft(cur);     StringTrimRight(cur);
      StringTrimLeft(evTitle); StringTrimRight(evTitle);
      if(StringLen(firstCurrencySeen) == 0) firstCurrencySeen = cur;

      if(InpFilterByCurrency && !IsCurrencyRelevant(cur)) { skipCurrency++; continue; }
      if(StringLen(firstTitleSeen) == 0) firstTitleSeen = evTitle;
      if(StringFind(evTitle, InpEventTitle) < 0) { skipTitle++;    continue; }

      double actual   = SafeParseDouble(actualS);
      double forecast = SafeParseDouble(forecastS);
      if(actual == EMPTY_VALUE || forecast == EMPTY_VALUE || actual == forecast)
        { skipValue++; continue; }

      ArrayResize(g_events, count + 1);
      g_events[count].event_time = t;
      g_events[count].currency   = cur;
      g_events[count].title      = evTitle;
      g_events[count].actual     = actual;
      g_events[count].forecast   = forecast;
      g_events[count].processed  = false;
      count++;
     }
   FileClose(handle);

   SortEventsByTime();

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      Print("✓ EA_Event: Load ", count, " sự kiện '", InpEventTitle,
            "' từ '", InpNewsFile, "'");
      Print("  Thống kê CSV: tổng=", totalRows,
            "  bỏ(currency)=", skipCurrency,
            "  bỏ(title)=", skipTitle,
            "  bỏ(value)=", skipValue);
      if(totalRows > 0)
         Print("  Currency đầu tiên trong file: '", firstCurrencySeen, "'");
      if(skipCurrency < totalRows && StringLen(firstTitleSeen) > 0)
         Print("  Tên event đầu tiên khớp currency: '", firstTitleSeen, "'  (đang tìm: '", InpEventTitle, "')");
     }
  }

#endif
