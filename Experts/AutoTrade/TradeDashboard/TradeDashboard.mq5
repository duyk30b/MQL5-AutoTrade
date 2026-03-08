//+------------------------------------------------------------------+
//|                                                            2.mq5 |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 10.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"
#property version "1.00"

#include "TDContainer.mqh"
#include "TDPopupPosition.mqh"
#include "TradeDashboardContext.mqh"
#include "TradeDashboardFunction.mqh"

#include <AutoTrade/UI/UICommon.mqh>
#include <AutoTrade/Utils/UtilString.mqh>

#include <Trade/Trade.mqh>

uint            lastUITimerEvent   = 0;
uint            lastUITimerRefresh = 0;

CTrade          cTrade;
UICommon        uiCommon;

TDContainer     tdContainer;
TDPopupPosition tdPopupPosition;

input int       g_slPointsDefault           = 500;
input int       g_tpPointsDefault           = 1000;
input bool      g_enableTrailingStopDefault = true;
input int       g_tsStartPointsDefault      = 500;
input int       g_tsStepPointsDefault       = 10;
input int       g_tsDistancePointsDefault   = 100;

PositionInfo    g_positionList[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
   EventSetMillisecondTimer(500);
   cTrade.SetExpertMagicNumber(MagicNumber);
   cTrade.SetDeviationInPoints(Slippage);

   Print(" ACCOUNT_LEVERAGE : " + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));
   Print(" ACCOUNT_MARGIN_SO_CALL : " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)));
   Print(" ACCOUNT_MARGIN_SO_SO : " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)));

   int totalOrders = OrdersTotal();
   for(int i = 0; i < totalOrders; i++) {
      ulong ticketOrder = OrderGetTicket(i);
      upsertGridTicketOrder(ticketOrder);
   }

   int totalPositions = PositionsTotal();
   for(int i = 0; i < totalPositions; i++) {
      ulong ticketPosition = PositionGetTicket(i);
      upsertGridItemPosition(ticketPosition);
   }

   ArrayResize(g_positionList, totalPositions);
   for(int i = 0; i < totalPositions; i++) {
      if(PositionGetTicket(i)) {
         g_positionList[i].ticket                     = PositionGetTicket(i);
         g_positionList[i].enableTrailingStop         = false;
         g_positionList[i].trailingStopStartPoints    = 0;
         g_positionList[i].trailingStopStepPoints     = 0;
         g_positionList[i].trailingStopDistancePoints = 0;
      }
   }

   tdContainer.Create(20, 20, 500, 590);
   tdContainer.m_tdTabTrade.SetStopLossPoints(g_slPointsDefault);
   tdContainer.m_tdTabTrade.SetTakeProfitPoints(g_tpPointsDefault);
   tdContainer.m_tdTabTrade.SetEnableTrailingStop(g_enableTrailingStopDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopStartPoints(g_tsStartPointsDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopStepPoints(g_tsStepPointsDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopDistancePoints(g_tsDistancePointsDefault);

   tdPopupPosition.Initialize();
   tdPopupPosition.StartDraw(520, 20, 300, 390, false);
   Print("Create Panel Success!");

   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason) {
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {
   if((bool)MQLInfoInteger(MQL_TESTER) && (bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
      // Không gọi 2 hàm này ở onTimer, vì ở môi trường Test, onTimer chỉ được chạy khi có tick
      OnMQLTesterEvent();
      OnMQLTesterRefresh();
   }
   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      tdContainer.RefreshData();
   }
   StartProcessTrailingStop();
}

void OnTimer() {
   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      tdContainer.RefreshData();
      StartProcessTrailingStop();
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   tdContainer.OnChartEvent(id, lparam, dparam, sparam);
   tdPopupPosition.OnChartEvent(id, lparam, dparam, sparam);
}

void OnTradeTransaction(
   const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result
) {
   ENUM_TRADE_TRANSACTION_TYPE type           = trans.type;
   ulong                       ticketOrder    = trans.order;    // ORDER ticket
   ulong                       ticketPosition = trans.position; // POSITION ticket
   ulong                       ticketDeal     = trans.deal;
   string                      tradeInfo      = StringFormat(
      "-ticketOrder: %.1f -ticketPosition %.1f -ticketDeal: %.1f",
      ticketOrder,
      ticketPosition,
      ticketDeal
   );
   switch(type) {
      case TRADE_TRANSACTION_ORDER_ADD:
         // Print("TRADE_TRANSACTION_ORDER_ADD: ", tradeInfo);
         upsertGridTicketOrder(ticketOrder);
         break;
      case TRADE_TRANSACTION_ORDER_UPDATE:
         // Print("TRADE_TRANSACTION_ORDER_UPDATE: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_ORDER_DELETE:
         // Print("TRADE_TRANSACTION_ORDER_DELETE: ", tradeInfo);
         removeGridItemOrder(ticketOrder);
         break;
      case TRADE_TRANSACTION_DEAL_ADD:
         // Print("TRADE_TRANSACTION_DEAL_ADD: ", tradeInfo);
         if(HistoryDealSelect(ticketDeal)) {
            ENUM_DEAL_ENTRY dealEntry
               = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticketDeal, DEAL_ENTRY);
            ENUM_DEAL_REASON reason
               = (ENUM_DEAL_REASON)HistoryDealGetInteger(ticketDeal, DEAL_REASON);
            if(dealEntry == DEAL_ENTRY_IN) {
               int gridIndex = upsertGridItemPosition(ticketPosition);
               recalculateGridInfo(gridIndex);
            } else if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY) {
               addGridItemDealOut(ticketDeal);
               int gridIndex = removeGridItemPosition(ticketPosition);
               if(reason == DEAL_REASON_TP || reason == DEAL_REASON_SL) {
                  removeAllGridItemOrder(gridIndex);
               }
               recalculateGridInfo(gridIndex);
            } else if(dealEntry == DEAL_ENTRY_OUT_BY) {
               // Print("DEAL_ENTRY_OUT_BY: ", tradeInfo);
            } else if(dealEntry == DEAL_ENTRY_INOUT) {
               // Print("DEAL_ENTRY_INOUT: ", tradeInfo);
            }
         }

         break;
      case TRADE_TRANSACTION_DEAL_UPDATE:
         // Print("TRADE_TRANSACTION_DEAL_UPDATE: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_DEAL_DELETE:
         // Print("TRADE_TRANSACTION_DEAL_DELETE: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_HISTORY_ADD:
         // Print("TRADE_TRANSACTION_HISTORY_ADD: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_HISTORY_UPDATE:
         // Print("TRADE_TRANSACTION_HISTORY_UPDATE: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_HISTORY_DELETE:
         // Print("TRADE_TRANSACTION_HISTORY_DELETE: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_POSITION:
         // Print("TRADE_TRANSACTION_POSITION: ", tradeInfo);
         break;
      case TRADE_TRANSACTION_REQUEST:
         // Print("TRADE_TRANSACTION_REQUEST: ", tradeInfo);
         break;
      default: break;
   }
}

void OnMQLTesterEvent() {
   if((GetTickCount() - lastUITimerEvent) < 100) {
      return;
   }
   lastUITimerEvent = GetTickCount();

   tdContainer.OnMQLTesterEvent();
   tdPopupPosition.OnMQLTesterEvent();
}

void OnMQLTesterRefresh() {
   if((GetTickCount() - lastUITimerRefresh) < 500) {
      return;
   }
   lastUITimerRefresh = GetTickCount();

   tdContainer.OnMQLTesterRefresh();
   tdPopupPosition.OnMQLTesterRefresh();
}

// Danh sách các hàm callback
void openPopupModifyPosition(ulong ticketId) {
   tdPopupPosition.openPopup(ticketId);
}

void changeVolumeRisk() {
   tdContainer.RefreshData();
}
