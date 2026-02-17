//+------------------------------------------------------------------+
//|                                                            2.mq5 |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 10.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"
#property version "1.00"

#include "TDPopupPosition.mqh"
#include "TradeDashboardContainer.mqh"
#include "TradeDashboardContext.mqh"

#include <AutoTrade/UI/UICommon.mqh>

#include <Trade/Trade.mqh>

uint                    lastUITimerEvent   = 0;
uint                    lastUITimerRefresh = 0;

CTrade                  cTrade;
UICommon                uiCommon;

TradeDashboardContainer tradeDashboardContainer;
TDPopupPosition         tdPopupPosition;

input ulong             MagicNumber                 = 20260206;
input int               Slippage                    = 5;

input double            g_lotSizeDefault            = 0.1;
input int               g_slPointsDefault           = 4000;
input int               g_tpPointsDefault           = 4000;
input bool              g_enableTrailingStopDefault = true;
input int               g_tsStartPointsDefault      = 1000;
input int               g_tsStepPointsDefault       = 10;
input int               g_tsDistancePointsDefault   = 500;

PositionInfo            g_positionList[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
   EventSetMillisecondTimer(500);
   cTrade.SetExpertMagicNumber(MagicNumber);
   cTrade.SetDeviationInPoints(Slippage);

   if(!tradeDashboardContainer.Create(0, 20, 20, 500, 500)) {
      Print("Không thể tạo Panel!");
      return INIT_FAILED;
   }
   tradeDashboardContainer.SetLotSizeDefault(g_lotSizeDefault);
   tradeDashboardContainer.SetStopLossPointsDefault(g_slPointsDefault);
   tradeDashboardContainer.SetTakeProfitPointsDefault(g_tpPointsDefault);
   tradeDashboardContainer.SetEnableTrailingStop(g_enableTrailingStopDefault);
   tradeDashboardContainer.SetTrailingStopStartPointsDefault(g_tsStartPointsDefault);
   tradeDashboardContainer.SetTrailingStopStepPointsDefault(g_tsStepPointsDefault);
   tradeDashboardContainer.SetTrailingStopDistancePointsDefault(g_tsDistancePointsDefault);

   tdPopupPosition.Create(0, 520, 20, 300, 390, false);

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
      tradeDashboardContainer.RefreshData();
      tradeDashboardContainer.StartProcessTrailingStop();
   }
}

void OnTimer() {
   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      tradeDashboardContainer.RefreshData();
      tradeDashboardContainer.StartProcessTrailingStop();
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   tradeDashboardContainer.OnChartEvent(id, lparam, dparam, sparam);
   tdPopupPosition.OnChartEvent(id, lparam, dparam, sparam);
}

void OnMQLTesterEvent() {
   if((GetTickCount() - lastUITimerEvent) < 100) {
      return;
   }
   lastUITimerEvent = GetTickCount();

   tradeDashboardContainer.OnMQLTesterEvent();
   tdPopupPosition.OnMQLTesterEvent();
}

void OnMQLTesterRefresh() {
   if((GetTickCount() - lastUITimerRefresh) < 500) {
      return;
   }
   lastUITimerRefresh = GetTickCount();

   tradeDashboardContainer.OnMQLTesterRefresh();
   tdPopupPosition.OnMQLTesterRefresh();
}

// Danh sách các hàm callback
void openPopupModifyPosition(ulong ticketId) {
   tdPopupPosition.openPopup(ticketId);
}
