//+------------------------------------------------------------------+
//|                   EE_TradeExecution.mqh                          |
//| Mở lệnh (tính SL/TP), đóng vị thế sau N phút                   |
//+------------------------------------------------------------------+
#ifndef EE_TRADE_EXECUTION_MQH
#define EE_TRADE_EXECUTION_MQH

#include "EE_Constants.mqh"

// Forward declaration – định nghĩa thực ở EE_EventModel.mqh (include sau)
double CalcLotByRisk(double entryPrice, string symb);

//--------------------------------------------------------------------
// Tìm vị thế đang mở của EA (theo magic + symbol)
//--------------------------------------------------------------------
ulong GetMyPositionTicket(string symb = "")
// Duyệt qua tất cả vị thế mở, tìm vị thế có symbol và magic number khớp với EA
  {
   if(symb == "")
      symb = _Symbol;
   int total = PositionsTotal();
   if(total == 0) return 0;  // early exit – không có position nào
   for(int i = total - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)  == symb &&
         PositionGetInteger(POSITION_MAGIC)  == InpMagicNumber)
         return t;
     }
   return 0;
  }

//--------------------------------------------------------------------
// Mở lệnh: direction > 0 → BUY, < 0 → SELL
// SL = InpSL_Percent% từ giá vào | TP = SL × InpRate_TP_SL
//--------------------------------------------------------------------
void OpenTrade(int direction, string reason, string symb = "")
// Mở lệnh: direction > 0 → BUY, < 0 → SELL | SL = InpSL_Percent% từ giá vào | TP = SL × InpRate_TP_SL
// symb: symbol cần trade (rỗng = dùng _Symbol)
  {
   if(symb == "")
      symb = _Symbol;
   if(GetMyPositionTicket(symb) != 0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(symb, tick))
      return;

   double pt  = SymbolInfoDouble(symb, SYMBOL_POINT);
   int    dgt = (int)SymbolInfoInteger(symb, SYMBOL_DIGITS);

// ── Kiểm tra Spread ──────────────────────────────────────────────
   if(InpMaxSpread > 0)
     {
      double spread = (tick.ask - tick.bid) / pt;
      if(spread > InpMaxSpread)
        {
         if(!MQLInfoInteger(MQL_OPTIMIZATION))
            Print("⛔ EA_Event: Bỏ qua - Spread quá rộng (", DoubleToString(spread, 1),
                  " pts > MaxSpread ", InpMaxSpread, ")  [", symb, "] | ", reason);
         return;
        }
     }

   double price  = (direction > 0) ? tick.ask : tick.bid;
   double slDist = NormalizeDouble(price * g_SL_Percent / 100.0, dgt);

// ── Kiểm tra Gap (giá đã chạy quá xa kể từ lúc tin ra) ──────────
   if(InpMaxGapPercent > 0.0 && g_lastEventPrice > 0.0)
     {
      double tpDist    = slDist * g_Rate_TP_SL;
      double gapMoved  = MathAbs(price - g_lastEventPrice);
      double maxGap    = tpDist * InpMaxGapPercent / 100.0;
      if(gapMoved > maxGap)
        {
         if(!MQLInfoInteger(MQL_OPTIMIZATION))
            Print("⛔ EA_Event: Bỏ qua - Giá đã chạy quá xa (",
                  DoubleToString(gapMoved / pt, 0), " pts, giới hạn ",
                  DoubleToString(maxGap / pt, 0), " pts)  [", symb, "] | ", reason);
         g_lastEventPrice = 0.0;
         return;
        }
     }
   g_lastEventPrice = 0.0;

// Đảm bảo SL >= stops level tối thiểu của broker
   double minStop = (double)SymbolInfoInteger(symb, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   slDist = MathMax(slDist, minStop + pt);

// ── Tính lot: risk manager hoặc fixed (g_LotSize có thể điều chỉnh qua Panel) ──
   double lot = (inp_risk_percent > 0) ? CalcLotByRisk(price, symb) : g_LotSize;

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
      Print("🔍 [", symb, "] lot=", lot, " pt=", pt, " dgt=", dgt,
            " slDist=", slDist, " price=", price,
            " ask=", tick.ask, " bid=", tick.bid,
            " volMin=", SymbolInfoDouble(symb, SYMBOL_VOLUME_MIN),
            " volStep=", SymbolInfoDouble(symb, SYMBOL_VOLUME_STEP),
            " contract=", SymbolInfoDouble(symb, SYMBOL_TRADE_CONTRACT_SIZE));

   double sl, tp;
   if(direction > 0)
     {
      sl = NormalizeDouble(price - slDist, dgt);
      tp = NormalizeDouble(price + slDist * g_Rate_TP_SL, dgt);
      trade.Buy(lot, symb, price, sl, tp, "EA_Event|" + reason);
     }
   else
     {
      sl = NormalizeDouble(price + slDist, dgt);
      tp = NormalizeDouble(price - slDist * g_Rate_TP_SL, dgt);
      trade.Sell(lot, symb, price, sl, tp, "EA_Event|" + reason);
     }

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      if(trade.ResultRetcode() == TRADE_RETCODE_DONE)
         Print("✅ EA_Event: Mở ", (direction > 0 ? "BUY" : "SELL"),
               " @ ", price, "  Lot=", lot, "  SL=", sl, "  TP=", tp,
               "  [", symb, "] | ", reason);
      else
         Print("❌ EA_Event: Lỗi #", trade.ResultRetcode(),
               " ", trade.ResultRetcodeDescription(), "  [", symb, "]");
     }
  }

//--------------------------------------------------------------------
// Đóng vị thế sau InpCloseMinute phút nếu chưa hit TP/SL
//--------------------------------------------------------------------
void ManagePosition(string symb = "")
  {
   if(InpCloseMinute <= 0)
      return;
   if(PositionsTotal() == 0) return;  // early exit – không có position nào
   if(symb == "")
      symb = _Symbol;

   ulong ticket = GetMyPositionTicket(symb);
   if(ticket == 0)
      return;
   if(!PositionSelectByTicket(ticket))
      return;

   datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
   if(TimeCurrent() - openTime >= (datetime)(InpCloseMinute * 60))
     {
      trade.PositionClose(ticket);
      if(!MQLInfoInteger(MQL_OPTIMIZATION))
         Print("⏰ EA_Event: Đóng #", ticket, " sau ", InpCloseMinute, " phút.  [", symb, "]");
     }
  }

#endif
//+------------------------------------------------------------------+
