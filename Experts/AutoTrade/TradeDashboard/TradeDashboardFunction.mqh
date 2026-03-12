#ifndef TRADE_DASHBOARD_FUNCTION_MQH
#define TRADE_DASHBOARD_FUNCTION_MQH

#include "TradeDashboardContext.mqh"
#include <AutoTrade/Utils/UtilString.mqh>

void upsertGridTicketOrder(ulong ticketOrder) {
   if(!OrderSelect(ticketOrder)) {
      return;
   }
   string comment  = OrderGetString(ORDER_COMMENT);
   string gridName = UtilString::GetValueFromEncodedString(comment, GridNameKey);
   if(gridName == "") {
      return;
   }

   int gridIndex = -1;
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].gridName == gridName) {
         gridIndex = i;
         break;
      }
   }

   if(gridIndex == -1) {
      gridIndex = ArraySize(g_gridList);
      ArrayResize(g_gridList, gridIndex + 1);
      g_gridList[gridIndex].gridName        = gridName;
      g_gridList[gridIndex].symbol          = OrderGetString(ORDER_SYMBOL);
      g_gridList[gridIndex].stopLossPrice   = OrderGetDouble(ORDER_SL);
      g_gridList[gridIndex].takeProfitPrice = OrderGetDouble(ORDER_TP);
   }

   int orderIndex = -1;
   for(int i = 0; i < ArraySize(g_gridList[gridIndex].ticketOrderList); i++) {
      if(g_gridList[gridIndex].ticketOrderList[i].ticketOrder == ticketOrder) {
         orderIndex = i;
         break;
      }
   }
   if(orderIndex == -1) {
      orderIndex = ArraySize(g_gridList[gridIndex].ticketOrderList);
      ArrayResize(g_gridList[gridIndex].ticketOrderList, orderIndex + 1);
   }
   g_gridList[gridIndex].ticketOrderList[orderIndex].ticketOrder = ticketOrder;
   g_gridList[gridIndex].ticketOrderList[orderIndex].volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
   g_gridList[gridIndex].ticketOrderList[orderIndex].priceOpen = OrderGetDouble(ORDER_PRICE_OPEN);
   g_gridList[gridIndex].ticketOrderList[orderIndex].orderState
      = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
};

int upsertGridItemPosition(ulong ticketPosition) {
   if(!PositionSelectByTicket(ticketPosition)) {
      return -1;
   }

   string comment  = PositionGetString(POSITION_COMMENT);
   string gridName = UtilString::GetValueFromEncodedString(comment, GridNameKey);
   if(gridName == "") {
      return -1;
   }

   int gridIndex = -1;
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].gridName == gridName) {
         gridIndex = i;
         break;
      }
   }
   if(gridIndex == -1) {
      gridIndex = ArraySize(g_gridList);
      ArrayResize(g_gridList, gridIndex + 1);
      g_gridList[gridIndex].gridName        = gridName;
      g_gridList[gridIndex].symbol          = PositionGetString(POSITION_SYMBOL);
      g_gridList[gridIndex].stopLossPrice   = PositionGetDouble(POSITION_SL);
      g_gridList[gridIndex].takeProfitPrice = PositionGetDouble(POSITION_TP);
   }

   int positionIndex = -1;
   for(int i = 0; i < ArraySize(g_gridList[gridIndex].ticketPositionList); i++) {
      if(g_gridList[gridIndex].ticketPositionList[i].ticketPosition == ticketPosition) {
         positionIndex = i;
         break;
      }
   }

   if(positionIndex == -1) {
      positionIndex = ArraySize(g_gridList[gridIndex].ticketPositionList);
      ArrayResize(g_gridList[gridIndex].ticketPositionList, positionIndex + 1);
      g_gridList[gridIndex].ticketPositionList[positionIndex].ticketPosition = ticketPosition;
      g_gridList[gridIndex].ticketPositionList[positionIndex].volume
         = PositionGetDouble(POSITION_VOLUME);
      g_gridList[gridIndex].ticketPositionList[positionIndex].priceOpen
         = PositionGetDouble(POSITION_PRICE_OPEN);
   }
   return gridIndex;
};

void addGridItemDealOut(ulong ticketDeal) {
   // Deal out không có comment
   // string comment    = HistoryDealGetString(ticketDeal, DEAL_COMMENT);
   // string gridName   = UtilString::GetValueFromEncodedString(comment, GridNameKey);

   // Chỉ quan tâm đến deal out
   ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticketDeal, DEAL_ENTRY);
   if(!(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)) {
      return;
   }

   ulong  ticketPosition = HistoryDealGetInteger(ticketDeal, DEAL_POSITION_ID);
   int    gridIndex      = -1;
   double priceOpen      = 0;

   for(int i = 0; i < ArraySize(g_gridList); i++) {
      for(int j = 0; j < ArraySize(g_gridList[i].ticketPositionList); j++) {
         if(g_gridList[i].ticketPositionList[j].ticketPosition == ticketPosition) {
            gridIndex = i;
            priceOpen = g_gridList[i].ticketPositionList[j].priceOpen;
            break;
         }
      }
   }
   if(gridIndex == -1) {
      return;
   }

   double           volume     = HistoryDealGetDouble(ticketDeal, DEAL_VOLUME);
   string           symbol     = HistoryDealGetString(ticketDeal, DEAL_SYMBOL);
   double           stopLoss   = HistoryDealGetDouble(ticketDeal, DEAL_SL);
   double           takeProfit = HistoryDealGetDouble(ticketDeal, DEAL_TP);
   double           profit     = HistoryDealGetDouble(ticketDeal, DEAL_PROFIT);
   double           swap       = HistoryDealGetDouble(ticketDeal, DEAL_SWAP);
   double           commission = HistoryDealGetDouble(ticketDeal, DEAL_COMMISSION);
   double           fee        = HistoryDealGetDouble(ticketDeal, DEAL_FEE);
   double           closePrice = HistoryDealGetDouble(ticketDeal, DEAL_PRICE);
   ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(ticketDeal, DEAL_REASON);

   int              dealIndex  = ArraySize(g_gridList[gridIndex].ticketDealList);
   ArrayResize(g_gridList[gridIndex].ticketDealList, dealIndex + 1);
   g_gridList[gridIndex].ticketDealList[dealIndex].ticketDeal     = ticketDeal;
   g_gridList[gridIndex].ticketDealList[dealIndex].ticketPosition = ticketPosition;
   g_gridList[gridIndex].ticketDealList[dealIndex].volume         = volume;
   g_gridList[gridIndex].ticketDealList[dealIndex].profit         = profit;
   g_gridList[gridIndex].ticketDealList[dealIndex].swap           = swap;
   g_gridList[gridIndex].ticketDealList[dealIndex].commission     = commission;
   g_gridList[gridIndex].ticketDealList[dealIndex].fee            = fee;
   g_gridList[gridIndex].ticketDealList[dealIndex].closePrice     = closePrice;
   g_gridList[gridIndex].ticketDealList[dealIndex].dealReason     = dealReason;
   g_gridList[gridIndex].ticketDealList[dealIndex].priceOpen      = priceOpen;
}

void removeGridItemOrder(ulong ticketOrder) {
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      for(int j = 0; j < ArraySize(g_gridList[i].ticketOrderList); j++) {
         if(g_gridList[i].ticketOrderList[j].ticketOrder == ticketOrder) {
            // Xóa ticketOrder khỏi ticketOrderList
            for(int k = j; k < ArraySize(g_gridList[i].ticketOrderList) - 1; k++) {
               g_gridList[i].ticketOrderList[k] = g_gridList[i].ticketOrderList[k + 1];
            }
            ArrayResize(
               g_gridList[i].ticketOrderList,
               ArraySize(g_gridList[i].ticketOrderList) - 1
            );
            return;
         }
      }
   }
};

int removeGridItemPosition(ulong ticketPosition) {
   int gridIndex = -1;
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      for(int j = 0; j < ArraySize(g_gridList[i].ticketPositionList); j++) {
         if(g_gridList[i].ticketPositionList[j].ticketPosition == ticketPosition) {
            // Xóa ticketPosition khỏi ticketPositionList
            gridIndex = i;

            for(int k = j; k < ArraySize(g_gridList[i].ticketPositionList) - 1; k++) {
               g_gridList[i].ticketPositionList[k] = g_gridList[i].ticketPositionList[k + 1];
            }
            ArrayResize(
               g_gridList[i].ticketPositionList,
               ArraySize(g_gridList[i].ticketPositionList) - 1
            );
            return gridIndex;
         }
      }
   }
   return gridIndex;
};

void removeAllGridItemOrder(int gridIndex) {
   if(gridIndex < 0 || gridIndex >= ArraySize(g_gridList)) {
      return;
   }
   for(int j = 0; j < ArraySize(g_gridList[gridIndex].ticketOrderList); j++) {
      ulong ticketOrder = g_gridList[gridIndex].ticketOrderList[j].ticketOrder;
      cTrade.OrderDelete(ticketOrder);
   }
};

void recalculateGridInfo(int gridIndex) {
   if(gridIndex < 0 || gridIndex >= ArraySize(g_gridList)) {
      return;
   }
   double totalVolume = 0;
   double totalCost   = 0;
   for(int i = 0; i < ArraySize(g_gridList[gridIndex].ticketPositionList); i++) {
      double volume  = g_gridList[gridIndex].ticketPositionList[i].volume;
      double price   = g_gridList[gridIndex].ticketPositionList[i].priceOpen;
      totalVolume   += volume;
      totalCost     += volume * price;
   }
   double averageOpenPrice                = (totalVolume == 0) ? 0 : (totalCost / totalVolume);
   g_gridList[gridIndex].averageOpenPrice = averageOpenPrice;

   if(averageOpenPrice != 0 && !g_gridList[gridIndex].tsStarted) {
      double point            = SymbolInfoDouble(g_gridList[gridIndex].symbol, SYMBOL_POINT);
      double tsStartPoints    = g_gridList[gridIndex].tsStartPoints;
      double tsDistancePoints = g_gridList[gridIndex].tsDistancePoints;
      double tsStepPoints     = g_gridList[gridIndex].tsStepPoints;
      double takeProfitPrice  = g_gridList[gridIndex].takeProfitPrice;

      double newTsPeakPrice   = 0;
      double newStopLossPrice = 0;
      if(g_gridList[gridIndex].gridType == GRID_TYPE_BUY) {
         newTsPeakPrice   = averageOpenPrice + tsStartPoints * point;
         newStopLossPrice = newTsPeakPrice - tsDistancePoints * point;
      } else if(g_gridList[gridIndex].gridType == GRID_TYPE_SELL) {
         newTsPeakPrice   = averageOpenPrice - tsStartPoints * point;
         newStopLossPrice = newTsPeakPrice + tsDistancePoints * point;
      }

      g_gridList[gridIndex].tsPeakPrice   = newTsPeakPrice;
      g_gridList[gridIndex].stopLossPrice = newStopLossPrice;
      for(int j = 0; j < ArraySize(g_gridList[gridIndex].ticketPositionList); j++) {
         ulong ticketPosition = g_gridList[gridIndex].ticketPositionList[j].ticketPosition;
         cTrade.PositionModify(ticketPosition, newStopLossPrice, takeProfitPrice);
      }
   }
}

void ProcessGridListTrailingStop() {
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(!g_gridList[i].enableTrailingStop) {
         continue;
      }
      if(g_gridList[i].averageOpenPrice == 0) {
         continue;
      }
      if(ArraySize(g_gridList[i].ticketPositionList) == 0) {
         continue;
      }

      string symbol           = g_gridList[i].symbol;
      double priceOpen        = g_gridList[i].averageOpenPrice;
      double sl               = g_gridList[i].stopLossPrice;
      double tp               = g_gridList[i].takeProfitPrice;

      double tsStartPoints    = g_gridList[i].tsStartPoints;
      double tsStepPoints     = g_gridList[i].tsStepPoints;
      double tsDistancePoints = g_gridList[i].tsDistancePoints;
      double tsPeakPrice      = g_gridList[i].tsPeakPrice;

      double point            = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if(g_gridList[i].gridType == GRID_TYPE_BUY) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(bid >= tsPeakPrice) {
            g_gridList[i].tsStarted   = true;
            g_gridList[i].tsPeakPrice = bid + tsStepPoints * point;
            double newStopLoss        = bid - tsDistancePoints * point;
            for(int j = 0; j < ArraySize(g_gridList[i].ticketPositionList); j++) {
               ulong ticketPosition = g_gridList[i].ticketPositionList[j].ticketPosition;
               cTrade.PositionModify(ticketPosition, newStopLoss, tp);
            }
            g_gridList[i].stopLossPrice = newStopLoss;
         }
      }
      if(g_gridList[i].gridType == GRID_TYPE_SELL) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(tsPeakPrice - ask >= tsStepPoints * point) {
            g_gridList[i].tsStarted   = true;
            g_gridList[i].tsPeakPrice = ask;
            double newStopLoss        = ask + tsDistancePoints * point;
            for(int j = 0; j < ArraySize(g_gridList[i].ticketPositionList); j++) {
               ulong ticketPosition = g_gridList[i].ticketPositionList[j].ticketPosition;
               cTrade.PositionModify(ticketPosition, newStopLoss, tp);
            }
            g_gridList[i].stopLossPrice = newStopLoss;
         }
      }
   }
}

void ProcessTradeNormalTrailingStop() {
   for(int i = 0; i < ArraySize(g_positionList); i++) {
      if(!g_positionList[i].enableTrailingStop) {
         continue;
      }
      if(!PositionSelectByTicket(g_positionList[i].ticket)) {
         continue;
      }

      string symbol           = PositionGetString(POSITION_SYMBOL);
      double priceOpen        = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl               = PositionGetDouble(POSITION_SL);
      double tp               = PositionGetDouble(POSITION_TP);

      double tsStartPoints    = g_positionList[i].trailingStopStartPoints;
      double tsStepPoints     = g_positionList[i].trailingStopStepPoints;
      double tsDistancePoints = g_positionList[i].trailingStopDistancePoints;

      double POINT            = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if(g_positionList[i].type == POSITION_TYPE_BUY) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if((bid - priceOpen) >= tsStartPoints * POINT) {
            double newStopLoss = priceOpen + (tsStartPoints - tsDistancePoints) * POINT;
            if(sl < newStopLoss || sl == 0) {
               cTrade.PositionModify(g_positionList[i].ticket, newStopLoss, tp);
               g_positionList[i].trailingStopStartPoints += tsStepPoints;
            }
         }
      } else if(g_positionList[i].type == POSITION_TYPE_SELL) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if((priceOpen - ask) >= tsStartPoints * POINT) {
            double newStopLoss = priceOpen - (tsStartPoints - tsDistancePoints) * POINT;
            if(sl > newStopLoss || sl == 0) {
               cTrade.PositionModify(g_positionList[i].ticket, newStopLoss, tp);
               g_positionList[i].trailingStopStartPoints += tsStepPoints;
            }
         }
      }
   }
}

void ProcessNewsSetting() {
   if(ArraySize(g_newsList) == 0) {
      return;
   }

   if(g_beforeNewsProtectionEnable && g_beforeNewsMinutes > 0) {
      // Tại môi trường tester, thì timeCurrent lấy thời gian test, không phải thời gian hệ thống
      datetime now = TimeCurrent();

      // Print("Current tick time: ", TimeToString(now, TIME_DATE | TIME_SECONDS));
      // MqlTick tick;
      // if(SymbolInfoTick(_Symbol, tick)) {
      //    datetime tick_time = tick.time;
      //    Print("Tick time: ", TimeToString(tick_time, TIME_DATE | TIME_SECONDS));
      // }
      bool isBeforeNews = false;
      for(int i = 0; i < ArraySize(g_newsList); i++) {
         datetime newsTime = g_newsList[i].time;
         if(newsTime - g_beforeNewsMinutes * 60 < now && now < newsTime) {
            isBeforeNews = true;
            break;
         }
      }

      if(isBeforeNews) {
         if(g_beforeNewsEnableCloseAllOrder) {
            int total = OrdersTotal();
            for(int i = total - 1; i >= 0; i--) {
               ulong ticketOrder = OrderGetTicket(i);
               if(!OrderSelect(ticketOrder)) {
                  cTrade.OrderDelete(OrderGetInteger(ORDER_TICKET));
               }
            }
         }
         if(g_beforeNewsEnableCloseAllPosition) {
            int total = PositionsTotal();
            for(int i = total - 1; i >= 0; i--) {
               ulong ticketPosition = PositionGetTicket(i);
               if(PositionSelectByTicket(ticketPosition)) {
                  cTrade.PositionClose(ticketPosition);
               }
            }
         }
      }
   }
}

void ProcessBusinessSetting() {
   ProcessGridListTrailingStop();
   ProcessTradeNormalTrailingStop();
   ProcessNewsSetting();
}

#endif // TRADE_DASHBOARD_FUNCTION_MQH