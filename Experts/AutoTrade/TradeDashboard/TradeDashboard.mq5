//+------------------------------------------------------------------+
//|                                                            2.mq5 |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 10.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"
#property version "1.00"

#include "TradeDashboardContext.mqh"
#include "TradeDashboardPanel.mqh"
#include "TradeDashboardTablePositions.mqh"

input ulong                  MagicNumber = 20260206;
input int                    Slippage    = 5;

TradeDashboardPanel          tradeDashboardPanel;
TradeDashboardTablePositions tradeDashboardTablePositions;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
   EventSetMillisecondTimer(500);
   cTrade.SetExpertMagicNumber(MagicNumber);
   cTrade.SetDeviationInPoints(Slippage);

   if(!tradeDashboardPanel.Create()) {
      Print("Không thể tạo Panel!");
      return INIT_FAILED;
   }
   Print("Khởi tạo Panel thành công!");
   if(!tradeDashboardTablePositions.Create()) {
      Print("Không thể tạo table!");
      return INIT_FAILED;
   }
   Print("Khởi tạo Table thành công!");

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
   tradeDashboardPanel.RefreshData();
   if((bool)MQLInfoInteger(MQL_TESTER) && (bool)MQLInfoInteger(MQL_VISUAL_MODE)) {
      ProcessOnMQLTester();
   }
}

void OnTimer() {
   tradeDashboardTablePositions.UpdateTicketPositionsData();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   // Xử lý sự kiện của panel
   tradeDashboardPanel.OnChartEvent(id, lparam, dparam, sparam);
   tradeDashboardTablePositions.OnChartEvent(id, lparam, dparam, sparam);
}

void ProcessOnMQLTester() {
   bool btnBuyState = uiCommon.getState(0, g_ObjBtnBuyName);
   if(btnBuyState == true) {
      tradeDashboardPanel.ExecuteBuy();
      ObjectSetInteger(0, g_ObjBtnBuyName, OBJPROP_STATE, false);
   }

   bool btnSellState = uiCommon.getState(0, g_ObjBtnSellName);
   if(btnSellState == true) {
      tradeDashboardPanel.ExecuteSell();
      ObjectSetInteger(0, g_ObjBtnSellName, OBJPROP_STATE, false);
   }

   bool btnCloseAllState = uiCommon.getState(0, g_ObjBtnCloseAllName);
   if(btnCloseAllState == true) {
      tradeDashboardPanel.ExcuteCloseAllPositions();
      ObjectSetInteger(0, g_ObjBtnCloseAllName, OBJPROP_STATE, false);
   }
}
