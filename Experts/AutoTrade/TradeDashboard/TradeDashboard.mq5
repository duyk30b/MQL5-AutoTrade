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

#include <AutoTrade/UI/UICommon.mqh>

#include <Trade/Trade.mqh>

uint            lastUITimerEvent   = 0;
uint            lastUITimerRefresh = 0;

CTrade          cTrade;
UICommon        uiCommon;

TDContainer     tdContainer;
TDPopupPosition tdPopupPosition;

input ulong     MagicNumber                 = 20260206;
input int       Slippage                    = 5;

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

   int totalPositions = PositionsTotal();
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

   if(!tdContainer.Create(20, 20, 500, 500)) {
      Print("Không thể tạo Panel!");
      return INIT_FAILED;
   }
   tdContainer.m_tdTabTrade.SetStopLossPoints(g_slPointsDefault);
   tdContainer.m_tdTabTrade.SetTakeProfitPoints(g_tpPointsDefault);
   tdContainer.m_tdTabTrade.SetEnableTrailingStop(g_enableTrailingStopDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopStartPoints(g_tsStartPointsDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopStepPoints(g_tsStepPointsDefault);
   tdContainer.m_tdTabTrade.SetTrailingStopDistancePoints(g_tsDistancePointsDefault);

   tdPopupPosition.Initialization();
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
      StartProcessTrailingStop();
   }
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

// Danh sách hàm xử lý chính cho Trailing Stop, được gọi ở OnTick và OnTimer
void StartProcessTrailingStop() {
   int totalPositions = PositionsTotal();
   for(int i = 0; i < totalPositions; i++) {
      // Tránh lỗi khi thực tế nhiều item hơn trong g_positionList
      if(i >= ArraySize(g_positionList)) {
         continue;
      }
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

// Danh sách các hàm callback
void openPopupModifyPosition(ulong ticketId) {
   tdPopupPosition.openPopup(ticketId);
}

void changeVolumeRisk() {
   tdContainer.RefreshData();
}
