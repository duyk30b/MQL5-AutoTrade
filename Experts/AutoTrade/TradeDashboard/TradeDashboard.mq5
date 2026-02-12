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

CTrade                  cTrade;
UICommon                uiCommon;

TradeDashboardContainer tradeDashboardContainer;
TDPopupPosition         tdPopupPosition;

input ulong             MagicNumber = 20260206;
input int               Slippage    = 5;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
   EventSetMillisecondTimer(500);
   cTrade.SetExpertMagicNumber(MagicNumber);
   cTrade.SetDeviationInPoints(Slippage);

   if(!tradeDashboardContainer.Create(20, 20, 500, 410)) {
      Print("Không thể tạo Panel!");
      return INIT_FAILED;
   }
   tdPopupPosition.Create(520, 30, 300, 200, false);

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
   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      tradeDashboardContainer.RefreshDataByTick();
   } else {
      if((bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
         tradeDashboardContainer.ProcessOnMQLTester();
      }
   }
}

void OnTimer() {
   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      tradeDashboardContainer.RefreshDataByTimer();
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   tradeDashboardContainer.OnChartEvent(id, lparam, dparam, sparam);
   tdPopupPosition.OnChartEvent(id, lparam, dparam, sparam);

}

// Danh sách các hàm callback
void openPopupModifyPosition(ulong ticketId) {
   tdPopupPosition.openPopup(ticketId);
}
