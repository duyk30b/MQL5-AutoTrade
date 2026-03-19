//+------------------------------------------------------------------+
//|                           TDM_DCA.mqh                            |
//| DCA Logic: Calculate, Place, Cancel, Multi-Chain Management       |
//+------------------------------------------------------------------+
#ifndef TDM_DCA_MQH
#define TDM_DCA_MQH

#include "TDM_Constants.mqh"
#include "TDM_RiskCalculator.mqh"

//+------------------------------------------------------------------+
//| Tính mốc giá DCA (chia đều từ Entry đến SL)                     |
//+------------------------------------------------------------------+
void CalculateDCAPrices(double currentPrice, double slPrice, int orderCount, double &prices[])
  {
   if(orderCount <= 1)
     {
      ArrayResize(prices, 0);
      return;
     }

   double distance = MathAbs(currentPrice - slPrice);
   if(distance <= 0)
     {
      ArrayResize(prices, 0);
      Print("⚠️ DCA: Khoảng cách giá = 0! Cần SL > 0 để tính mốc DCA.");
      return;
     }

   ArrayResize(prices, orderCount - 1);
   double step = distance / orderCount;

   for(int i = 0; i < orderCount - 1; i++)
     {
      if(slPrice < currentPrice) // BUY: SL below current price
         prices[i] = NormalizePrice(currentPrice - (step * (i + 1)));
      else // SELL: SL above current price
         prices[i] = NormalizePrice(currentPrice + (step * (i + 1)));
     }
  }

//+------------------------------------------------------------------+
//| Tính Lot DCA theo hệ số nhân                                    |
//+------------------------------------------------------------------+
double CalculateDCALot(double baseLot, int level)
  {
   double lot = baseLot;
   for(int i = 0; i < level; i++)
      lot *= currentMainDCA_Mult;
   return NormalizeLot(lot);
  }

//+------------------------------------------------------------------+
//| Đặt lệnh DCA pending (Limit)                                    |
//+------------------------------------------------------------------+
void PlaceDCAOrders(bool isBuy, double &prices[], double baseLot, double sl, double tp, int chainId)
  {
   for(int i = 0; i < ArraySize(prices); i++)
     {
      double lot = CalculateDCALot(baseLot, i + 1);
      double price = prices[i];

      string comment = "DCA#" + IntegerToString(chainId) + (isBuy ? " BUY" : " SELL") + " Level " + IntegerToString(i + 1);

      if(isBuy)
        {
         if(trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment))
            Print("✓ Đặt ", comment, " @ ", price, " Lot: ", lot, " TP: ", tp);
         else
            Print("❌ Lỗi đặt ", comment, " - Mã lỗi: ", trade.ResultRetcode());
        }
      else
        {
         if(trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment))
            Print("✓ Đặt ", comment, " @ ", price, " Lot: ", lot, " TP: ", tp);
         else
            Print("❌ Lỗi đặt ", comment, " - Mã lỗi: ", trade.ResultRetcode());
        }
     }
  }

//+------------------------------------------------------------------+
//| Đếm pending DCA orders trên Symbol hiện tại                     |
//+------------------------------------------------------------------+
int CountDCAPendingOrders()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT)
         continue;
      count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Hủy tất cả DCA pending orders (Symbol + Magic)                  |
//+------------------------------------------------------------------+
void CancelAllDCAPendingOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT)
         continue;

      if(trade.OrderDelete(ticket))
         Print("✓ Hủy lệnh DCA pending #", ticket);
      else
         Print("❌ Lỗi hủy lệnh DCA #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
     }
  }

// =================================================================================
// === DCA MULTI-CHAIN: QUẢN LÝ NHIỀU CHUỖI DCA ĐỒNG THỜI ===
// =================================================================================

//+------------------------------------------------------------------+
//| Trích xuất Chain ID từ comment lệnh                              |
//+------------------------------------------------------------------+
int ExtractChainId(string comment)
  {
   int pos = StringFind(comment, "DCA#");
   if(pos < 0)
      return 0;
   string sub = StringSubstr(comment, pos + 4);
   int endPos = StringFind(sub, " ");
   if(endPos > 0)
      sub = StringSubstr(sub, 0, endPos);
   return (int)StringToInteger(sub);
  }

//+------------------------------------------------------------------+
//| Lấy danh sách tất cả Chain ID đang hoạt động                    |
//+------------------------------------------------------------------+
void GetActiveChainIds(int &ids[], int &count)
  {
   count = 0;
   ArrayResize(ids, 0);
// Quét positions
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      int cid = ExtractChainId(PositionGetString(POSITION_COMMENT));
      if(cid <= 0)
         continue;
      bool found = false;
      for(int j = 0; j < count; j++)
         if(ids[j] == cid)
           { found = true; break; }
      if(!found)
        {
         ArrayResize(ids, count + 1);
         ids[count] = cid;
         count++;
        }
     }
// Quét pending orders
   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      int cid = ExtractChainId(OrderGetString(ORDER_COMMENT));
      if(cid <= 0)
         continue;
      bool found = false;
      for(int j = 0; j < count; j++)
         if(ids[j] == cid)
           { found = true; break; }
      if(!found)
        {
         ArrayResize(ids, count + 1);
         ids[count] = cid;
         count++;
        }
     }
  }

//+------------------------------------------------------------------+
//| Thống kê một chuỗi DCA: giá TB, lot, P&L, số lệnh              |
//+------------------------------------------------------------------+
void GetChainStats(int chainId, bool &isBuy, double &avgPrice, double &totalLots,
                   double &totalProfit, int &posCount, int &pendingCount)
  {
   avgPrice = 0;
   totalLots = 0;
   totalProfit = 0;
   posCount = 0;
   pendingCount = 0;
   isBuy = true;
   double sumPriceLot = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if(ExtractChainId(PositionGetString(POSITION_COMMENT)) != chainId)
         continue;

      double lot = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      sumPriceLot += price * lot;
      totalLots += lot;
      totalProfit += PositionGetDouble(POSITION_PROFIT);
      posCount++;
     }
   if(totalLots > 0)
      avgPrice = sumPriceLot / totalLots;

   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      if(ExtractChainId(OrderGetString(ORDER_COMMENT)) != chainId)
         continue;
      pendingCount++;
     }
  }

//+------------------------------------------------------------------+
//| Hủy pending orders của MỘT chuỗi DCA cụ thể                    |
//+------------------------------------------------------------------+
void CancelChainPendingOrders(int chainId)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT)
         continue;
      if(ExtractChainId(OrderGetString(ORDER_COMMENT)) != chainId)
         continue;

      if(trade.OrderDelete(ticket))
         Print("✓ Hủy DCA Chain#", chainId, " pending #", ticket);
      else
         Print("❌ Lỗi hủy DCA Chain#", chainId, " #", ticket, " - Mã: ", trade.ResultRetcode());
     }
  }

#endif
