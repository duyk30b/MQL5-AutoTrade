//+------------------------------------------------------------------+
//|                     EE_SignalEngine.mqh                          |
//| Phát hiện tín hiệu BUY/SELL từ sự kiện kinh tế                  |
//| Backtest/Optimize → quét mảng CSV | Real Chart → MQL5 Calendar  |
//+------------------------------------------------------------------+
#ifndef EE_SIGNAL_ENGINE_MQH
#define EE_SIGNAL_ENGINE_MQH

#include "EE_EventModel.mqh"
#include "EE_TradeExecution.mqh"

//--------------------------------------------------------------------
// Backtest / Optimization
// g_nextEventIdx đảm bảo chỉ duyệt events chưa qua → không O(n×ticks)
//--------------------------------------------------------------------
void ProcessBacktestEvents()
  {
   static datetime lastScan = 0;
   datetime now = TimeCurrent();
   if(now - lastScan < 300) return; // kiểm tra 5 phút / lần
   lastScan = now;
   int total = ArraySize(g_events);

   for(int i = g_nextEventIdx; i < total; i++)
     {
      if(g_events[i].event_time > now)
         break; // Đã sort → break khi gặp event tương lai

      if(!g_events[i].processed)
        {
         g_events[i].processed = true;

         int    dir    = (g_events[i].actual > g_events[i].forecast) ? 1 : -1;
         string reason = g_events[i].currency + " " + g_events[i].title
                         + "  A=" + DoubleToString(g_events[i].actual,   2)
                         + "  F=" + DoubleToString(g_events[i].forecast, 2);

         // Chống trùng lệnh: bỏ qua nếu cùng tin + cùng hướng trong vòng 60 giây
         string dupKey = g_events[i].currency + g_events[i].title
                         + DoubleToString(g_events[i].actual, 4)
                         + DoubleToString(g_events[i].forecast, 4);
         if(IsDuplicateNews(dupKey))
           {
            g_nextEventIdx = i + 1;
            continue;
           }

         if(inp_multi_symbol && g_symbolCount > 0)
           {
            for(int s = 0; s < g_symbolCount; s++)
              {
               string symb = g_symbols[s];
               if(InpFilterByCurrency && !IsCurrencyRelevantForSymbol(g_events[i].currency, symb))
                  continue;
               OpenTrade(dir, reason, symb);
              }
           }
         else
           {
            // Single symbol: chạy trên chart hiện tại
            if(!InpFilterByCurrency || IsCurrencyRelevant(g_events[i].currency))
               OpenTrade(dir, reason);
           }
        }
      g_nextEventIdx = i + 1; // Không cần quét lại events này ở tick tiếp theo
     }
  }

//--------------------------------------------------------------------
// Real Chart - MQL5 Economic Calendar
// Quét mỗi 30 giây | Bỏ qua IDs đã xử lý để tránh double-open
//--------------------------------------------------------------------
void ProcessCalendarEvents()
// Quét mỗi 30 giây | Bỏ qua IDs đã xử lý để tránh double-open
  {
   static datetime lastScan = 0;
   datetime now = TimeCurrent();
   if(now - lastScan < 30)
      return;
   lastScan = now;

   datetime from = now - 5 * 60; // Quét 5 phút gần nhất
   MqlCalendarValue values[];
   if(CalendarValueHistory(values, from, now) <= 0)
      return;

   for(int i = 0; i < ArraySize(values); i++)
     {
      if(values[i].actual_value   == LONG_MIN)
         continue; // chưa có actual
      if(values[i].forecast_value == LONG_MIN)
         continue; // không có forecast
      if(values[i].actual_value   == values[i].forecast_value)
         continue;
      if(IsIdProcessed(values[i].id))
         continue;

      MqlCalendarEvent   ev;
      MqlCalendarCountry ct;
      if(!CalendarEventById(values[i].event_id, ev))
         continue;
      if(!CalendarCountryById(ev.country_id, ct))
         continue;
      if(StringFind(ev.name, InpEventTitle) < 0)
         continue;

      MarkIdProcessed(values[i].id);

      double actual   = values[i].actual_value   / MathPow(10.0, ev.digits);
      double forecast = values[i].forecast_value / MathPow(10.0, ev.digits);
      int    dir      = (actual > forecast) ? 1 : -1;
      string reason   = ct.currency + " " + ev.name
                        + "  A=" + DoubleToString(actual, (int)ev.digits)
                        + "  F=" + DoubleToString(forecast, (int)ev.digits);

      // Chống trùng lệnh: bỏ qua nếu cùng tin + cùng hướng trong vòng 60 giây
      string dupKey = ct.currency + ev.name
                      + DoubleToString(actual, (int)ev.digits)
                      + DoubleToString(forecast, (int)ev.digits);
      if(IsDuplicateNews(dupKey))
         continue;

      if(inp_multi_symbol && g_symbolCount > 0)
        {
         for(int s = 0; s < g_symbolCount; s++)
           {
            string symb = g_symbols[s];
            if(InpFilterByCurrency && !IsCurrencyRelevantForSymbol(ct.currency, symb))
               continue;
            OpenTrade(dir, reason, symb);
           }
        }
      else
        {
         // Single symbol: chạy trên chart hiện tại
         if(InpFilterByCurrency && !IsCurrencyRelevant(ct.currency))
            continue;
         OpenTrade(dir, reason);
        }
     }
  }

#endif
//+------------------------------------------------------------------+
