//+------------------------------------------------------------------+
//|                     TDM_TradeExecution.mqh                       |
//| Trade Execution: Buy, Sell, DCA Market, Close, Modify            |
//+------------------------------------------------------------------+
#ifndef TDM_TRADE_EXECUTION_MQH
#define TDM_TRADE_EXECUTION_MQH

#include "TDM_Constants.mqh"
#include "TDM_RiskCalculator.mqh"
#include "TDM_DCA.mqh"
#include "TDM_Memory.mqh"

// Forward declarations (defined in TradeDashboardView.mqh)
void UpdateInfo(bool forceUpdate);
// Forward declaration (defined in TDM_NewsFilter.mqh)
bool IsNewsBlocked();

// === LOGIC THỰC THI GIAO DỊCH ===

// Wrapper gọi nhanh
void OpenBuy()  { OpenTrade(true);  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenSell() { OpenTrade(false); }
void OpenBuyDCA()  { OpenDCA(true);  }
void OpenSellDCA() { OpenDCA(false); }

//+------------------------------------------------------------------+
//| Mở lệnh đơn lẻ (không DCA)                                      |
//+------------------------------------------------------------------+
void OpenTrade(bool isBuy)
  {
   if(IsNewsBlocked())
     {
      Print("🚫 NEWS FILTER: Không mở lệnh trong vùng tin tức!");
      return;
     }
   if(EnableDCA)
     {
      OpenDCA(isBuy);
      return;
     }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;
   double price = NormalizePrice(isBuy ? tick.ask : tick.bid);
   double sl = (currentMainSL == 0) ? 0 : NormalizePrice(isBuy ? price - currentMainSL*_Point : price + currentMainSL*_Point);
   double tp = (currentMainTP == 0) ? 0 : NormalizePrice(isBuy ? price + currentMainTP*_Point : price - currentMainTP*_Point);
   double lot = NormalizeLot(currentMainLot);
   bool ok = isBuy ? trade.Buy(lot, _Symbol, price, sl, tp, "Buy Dashboard")
             : trade.Sell(lot, _Symbol, price, sl, tp, "Sell Dashboard");
   if(ok)
      UpdateInfo(true);
   else
      Print("❌ LỖI ", (isBuy ? "BUY" : "SELL"), "! Mã: ", trade.ResultRetcode());
  }

//+------------------------------------------------------------------+
//| Mở lệnh + chuỗi DCA                                             |
//+------------------------------------------------------------------+
void OpenDCA(bool isBuy)
  {
   if(IsNewsBlocked())
     {
      Print("🚫 NEWS FILTER: Không mở DCA trong vùng tin tức!");
      return;
     }
   if(!EnableDCA || currentMainDCA_Count < 1)
     {
      OpenTrade(isBuy);
      return;
     }
   if(currentMainSL <= 0)
     {
      Print("❌ DCA yêu cầu SL > 0!");
      return;
     }
   if(RiskCalcMode != RISK_FIXED_LOT)
      AutoCalcLotByRisk();
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;
   int chainId = nextDCAChainId++;
   SaveDCAMemory();
   double price = NormalizePrice(isBuy ? tick.ask : tick.bid);
   double sl    = NormalizePrice(isBuy ? price - currentMainSL*_Point : price + currentMainSL*_Point);
   double tp    = (currentMainTP == 0) ? 0 : NormalizePrice(isBuy ? price + currentMainTP*_Point : price - currentMainTP*_Point);
   double lot   = NormalizeLot(currentMainLot);
   string dir   = isBuy ? "BUY" : "SELL";
   string comment = "DCA#" + IntegerToString(chainId) + " " + dir + " Market";
   bool ok = isBuy ? trade.Buy(lot, _Symbol, price, sl, tp, comment)
             : trade.Sell(lot, _Symbol, price, sl, tp, comment);
   if(!ok)
     {
      Print("❌ LỖI MỞ DCA ", dir, "! Mã: ", trade.ResultRetcode());
      return;
     }
   Print("✓ Mở ", comment, " @ ", price, " Lot: ", lot);
   if(currentMainDCA_Count > 1)
     {
      double dcaPrices[];
      CalculateDCAPrices(price, sl, currentMainDCA_Count, dcaPrices);
      PlaceDCAOrders(isBuy, dcaPrices, lot, sl, tp, chainId);
     }
   UpdateInfo(true);
  }

//+------------------------------------------------------------------+
//| Đóng 1 lệnh / toàn bộ chuỗi DCA / Sửa SL-TP                   |
//+------------------------------------------------------------------+
void CloseTicketPosition(ulong ticket)
  {
   if(trade.PositionClose(ticket))
     {
      Print("✓ Đóng #", ticket);
      UpdateInfo(true);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllDCAChain()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != MagicNumber && magic != 0)
         continue;
      if(trade.PositionClose(ticket))
         Print("✓ DCA đóng #", ticket);
      else
         Print("❌ DCA lỗi đóng #", ticket, " Mã: ", trade.ResultRetcode());
     }
   CancelAllDCAPendingOrders();
   Print("✓ Đã đóng toàn bộ chuỗi DCA!");
   UpdateInfo(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ModifySingleTicket(ulong ticket, double newSL, double newTP)
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(trade.PositionModify(ticket, newSL, newTP))
     {
      Print("✓ Sửa #", ticket);
      UpdateInfo(true);
      return true;
     }
   Print("❌ Lỗi sửa #", ticket, " Mã: ", trade.ResultRetcode());
   return false;
  }

#endif
//+------------------------------------------------------------------+
