//+------------------------------------------------------------------+
//|                       TDM_TrailingStop.mqh                       |
//| Trailing Stop Algorithm: Tự kéo SL theo giá                      |
//+------------------------------------------------------------------+
#ifndef TDM_TRAILING_STOP_MQH
#define TDM_TRAILING_STOP_MQH

#include "TDM_Constants.mqh"
#include "TDM_Memory.mqh"

// Forward declarations (defined in TradeDashboardView.mqh)
void DrawTrailingStopLine(ulong ticket, double price);
void UpdateInfo(bool forceUpdate);

// =================================================================================
// === THUẬT TOÁN TRAILING STOP ===
// =================================================================================
void ProcessTrailingStop()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   double bid = tick.bid;
   double ask = tick.ask;
   long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDist = stopsLevel * _Point;
   double safeStepPoints = 20 * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      long posMagic = PositionGetInteger(POSITION_MAGIC);
      if(posMagic != MagicNumber)
        {
         if(posMagic == 0 && !ManageManualTrades)
            continue;
         if(posMagic != 0)
            continue;
        }

      int my_ts_start = 0, my_ts_dist = 0;
      bool is_active = false;
      if(!GetTradeMemory(ticket, my_ts_start, my_ts_dist, is_active))
        {
         if(posMagic == 0 && ManageManualTrades)
           {
            SaveTradeMemory(ticket, currentMainTS_Start, currentMainTS_Dist);
            my_ts_start = currentMainTS_Start;
            my_ts_dist = currentMainTS_Dist;
           }
         else
            continue;
        }

      if(my_ts_start <= 0 || my_ts_dist <= 0)
         continue;

      long posType = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);

      double startOffset = my_ts_start * _Point;
      double distOffset = my_ts_dist * _Point;

      if(distOffset < minStopDist)
         distOffset = minStopDist;

      if(posType == POSITION_TYPE_BUY)
        {
         if(bid - openPrice >= startOffset)
           {
            double newSL = NormalizePrice(bid - distOffset);
            if(currentSL == 0 || newSL > currentSL)
              {
               if(currentSL == 0 || (newSL - currentSL) >= safeStepPoints)
                 {
                  if(trade.PositionModify(ticket, newSL, currentTP))
                    {
                     DrawTrailingStopLine(ticket, newSL);
                     if(!is_active)
                       {
                        MarkTSActive(ticket);
                        UpdateInfo(true);
                       }
                    }
                  else
                     Print("❌ LỖI KÉO TS LỆNH BUY #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
                 }
              }
           }
        }
      else
         if(posType == POSITION_TYPE_SELL)
           {
            if(openPrice - ask >= startOffset)
              {
               double newSL = NormalizePrice(ask + distOffset);
               if(currentSL == 0 || newSL < currentSL)
                 {
                  if(currentSL == 0 || (currentSL - newSL) >= safeStepPoints)
                    {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                       {
                        DrawTrailingStopLine(ticket, newSL);
                        if(!is_active)
                          {
                           MarkTSActive(ticket);
                           UpdateInfo(true);
                          }
                       }
                     else
                        Print("❌ LỖI KÉO TS LỆNH SELL #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
                    }
                 }
              }
           }
     }
  }

#endif
