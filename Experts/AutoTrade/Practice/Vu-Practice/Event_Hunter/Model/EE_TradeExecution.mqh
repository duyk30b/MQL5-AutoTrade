//+------------------------------------------------------------------+
//|                   EE_TradeExecution.mqh                          |
//| Mở lệnh (tính SL/TP), đóng vị thế sau N phút                   |
//+------------------------------------------------------------------+
#ifndef EE_TRADE_EXECUTION_MQH
#define EE_TRADE_EXECUTION_MQH

#include "EE_Constants.mqh"

//--------------------------------------------------------------------
// Tìm vị thế đang mở của EA (theo magic + symbol)
//--------------------------------------------------------------------
ulong GetMyPositionTicket()
// Duyệt qua tất cả vị thế mở, tìm vị thế có symbol và magic number khớp với EA
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)  == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == InpMagicNumber)
         return t;
     }
   return 0;
  }

//--------------------------------------------------------------------
// Mở lệnh: direction > 0 → BUY, < 0 → SELL
// SL = InpSL_Percent% từ giá vào | TP = SL × InpRate_TP_SL
//--------------------------------------------------------------------
void OpenTrade(int direction, string reason)
// Mở lệnh: direction > 0 → BUY, < 0 → SELL | SL = InpSL_Percent% từ giá vào | TP = SL × InpRate_TP_SL
  {
   if(GetMyPositionTicket() != 0) return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;

   // ── Kiểm tra Spread ──────────────────────────────────────────────
   if(InpMaxSpread > 0)
     {
      double spread = (tick.ask - tick.bid) / _Point;
      if(spread > InpMaxSpread)
        {
         if(!MQLInfoInteger(MQL_OPTIMIZATION))
            Print("⛔ EA_Event: Bỏ qua - Spread quá rộng (", DoubleToString(spread, 1),
                  " pts > MaxSpread ", InpMaxSpread, ")  | ", reason);
         return;
        }
     }

   double price  = (direction > 0) ? tick.ask : tick.bid;
   double slDist = NormalizeDouble(price * g_SL_Percent / 100.0, _Digits);

   // ── Kiểm tra Gap (giá đã chạy quá xa kể từ lúc tin ra) ──────────
   // Lấy giá tham chiếu từ event_time trong g_events (event vừa trigger)
   // Dùng g_lastEventPrice được gán bởi SignalEngine trước khi gọi OpenTrade
   if(InpMaxGapPercent > 0.0 && g_lastEventPrice > 0.0)
   // Nếu giá đã chạy quá X% khoảng cách từ giá vào đến TP thì bỏ qua (để tránh vào lệnh khi giá đã chạy quá xa)
     {
      double tpDist    = slDist * g_Rate_TP_SL;
      double gapMoved  = MathAbs(price - g_lastEventPrice);
      double maxGap    = tpDist * InpMaxGapPercent / 100.0;
      if(gapMoved > maxGap)
        {
         if(!MQLInfoInteger(MQL_OPTIMIZATION))
            Print("⛔ EA_Event: Bỏ qua - Giá đã chạy quá xa (",
                  DoubleToString(gapMoved / _Point, 0), " pts, giới hạn ",
                  DoubleToString(maxGap / _Point, 0), " pts)  | ", reason);
         g_lastEventPrice = 0.0;
         return;
        }
     }
   g_lastEventPrice = 0.0;

   // Đảm bảo SL >= stops level tối thiểu của broker
   double minStop = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   slDist = MathMax(slDist, minStop + _Point);

   double sl, tp;
   if(direction > 0)
     {
      sl = NormalizeDouble(price - slDist, _Digits);
      tp = NormalizeDouble(price + slDist * g_Rate_TP_SL, _Digits);
      trade.Buy(g_LotSize, _Symbol, price, sl, tp, "EA_Event|" + reason);
     }
   else
     {
      sl = NormalizeDouble(price + slDist, _Digits);
      tp = NormalizeDouble(price - slDist * g_Rate_TP_SL, _Digits);
      trade.Sell(g_LotSize, _Symbol, price, sl, tp, "EA_Event|" + reason);
     }

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      if(trade.ResultRetcode() == TRADE_RETCODE_DONE)
         Print("✅ EA_Event: Mở ", (direction > 0 ? "BUY" : "SELL"),
               " @ ", price, "  SL=", sl, "  TP=", tp, "  | ", reason);
      else
         Print("❌ EA_Event: Lỗi #", trade.ResultRetcode(),
               " ", trade.ResultRetcodeDescription());
     }
  }

//--------------------------------------------------------------------
// Đóng vị thế sau InpCloseMinute phút nếu chưa hit TP/SL
//--------------------------------------------------------------------
void ManagePosition()
  {
   if(InpCloseMinute <= 0) return;

   ulong ticket = GetMyPositionTicket();
   if(ticket == 0) return;
   if(!PositionSelectByTicket(ticket)) return;

   datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
   if(TimeCurrent() - openTime >= (datetime)(InpCloseMinute * 60))
     {
      trade.PositionClose(ticket);
      if(!MQLInfoInteger(MQL_OPTIMIZATION))
         Print("⏰ EA_Event: Đóng #", ticket, " sau ", InpCloseMinute, " phút.");
     }
  }

#endif
