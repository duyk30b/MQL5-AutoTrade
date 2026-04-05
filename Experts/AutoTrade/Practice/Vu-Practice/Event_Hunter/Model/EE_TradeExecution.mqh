//+------------------------------------------------------------------+
//|                   EE_TradeExecution.mqh                          |
//| Mở lệnh (tính SL/TP), đóng vị thế sau N phút                   |
//+------------------------------------------------------------------+
#ifndef EE_TRADE_EXECUTION_MQH
#define EE_TRADE_EXECUTION_MQH

#include "EE_Constants.mqh"

// Forward declaration – định nghĩa thực ở EE_EventModel.mqh (include sau)
double CalcLotByRisk(double entryPrice, string symb);
double NormalizeLotForSymbol(double lot, string symb);

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
// Kiểm tra có lệnh mở nào trên bất kỳ symbol nào trong danh sách không
//--------------------------------------------------------------------
bool HasAnyOpenPosition()
  {
   if(inp_multi_symbol && g_symbolCount > 0)
     {
      for(int s = 0; s < g_symbolCount; s++)
         if(GetMyPositionTicket(g_symbols[s]) != 0)
            return true;
      return false;
     }
   return GetMyPositionTicket() != 0;
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

   MqlTick tick;
   if(!SymbolInfoTick(symb, tick))
      return;

   double pt  = SymbolInfoDouble(symb, SYMBOL_POINT);
   int    dgt = (int)SymbolInfoInteger(symb, SYMBOL_DIGITS);

   double price  = (direction > 0) ? tick.ask : tick.bid;
   double slDist = NormalizeDouble(price * g_SL_Percent / 100.0, dgt);

// Đảm bảo SL >= stops level tối thiểu của broker
   double minStop = (double)SymbolInfoInteger(symb, SYMBOL_TRADE_STOPS_LEVEL) * pt;
   slDist = MathMax(slDist, minStop + pt);

// ── Tính lot: risk manager hoặc fixed, sau đó nhân Martingale nếu có ──
   double lot = (inp_risk_percent > 0) ? CalcLotByRisk(price, symb) : g_LotSize;
   lot = GetMgLot(lot, symb);
   lot = NormalizeLotForSymbol(lot, symb);

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
// Đóng tất cả vị thế của EA trên symbol đã quá hạn InpCloseMinute
//--------------------------------------------------------------------
void ManagePosition(string symb = "")
  {
   if(InpCloseMinute <= 0)
      return;
   if(PositionsTotal() == 0)
      return;
   if(symb == "")
      symb = _Symbol;

   datetime limitTime = (datetime)(InpCloseMinute * 60);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) != symb)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(TimeCurrent() - openTime >= limitTime)
        {
         double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double volume = PositionGetDouble(POSITION_VOLUME);
         trade.PositionClose(ticket);
         if(!MQLInfoInteger(MQL_OPTIMIZATION))
            Print("⏰ EA_Event: Đóng #", ticket, " sau ", InpCloseMinute, " phút (profit=",
                  DoubleToString(profit, 2), ")  [", symb, "]");
        }
     }
  }

#endif
//+------------------------------------------------------------------+
