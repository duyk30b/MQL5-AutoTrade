//+------------------------------------------------------------------+
//|                                                           x2.mq5 |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 02.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"
#property version "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

/*
chiến lược kiểm tra nến hammer;

các tham số input;
input int hammer_body_rate = 30% ;
input int hammer_wick_rate = 10% ;
input int trend_body_rate = 80% ;
input double RR_rate = 1.5;

buy khi :;
nến 0 : (close - open) < hammer_body_rate * (close - low);
      (high - close) < hammer_wick_rate * (close - open);
nến 1+2+3 : (close - open ) > trend_body_rate * (high-low);
buy ở giá close của nến 0;

đặt stoploss cho lệnh buy = giá low của nến 0;
đặt TakeProfit cho lệnh buy = (khoảng cách từ giá buy đến stoploss) * RR_rate;

*/
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input ulong MagicNumber = 20260202;
input int   Slippage    = 5;

input double volumes        = 0.1;   // Khối lượng vào lệnh
input double hammerBodyRate = 0.30;
input double hammerWickRate = 0.10;
input double trendBodyRate  = 0.80;
input double rrRate         = 1.5;

datetime lastBarTime = 0;

int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   Print("EA Init MagicNumber = ", MagicNumber);
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) {
      return;
   }
   lastBarTime = currentBarTime;
   if(CheckHummerBuy()) {
      StartOpenBuy();
   }
}

MqlRates myRate[];
double   open0;
double   close0;
double   high0;
double   low0;

bool CheckHummerBuy() {
   CopyRates(_Symbol, _Period, 1, 4, myRate);
   open0  = myRate[0].open;
   close0 = myRate[0].close;
   high0  = myRate[0].high;
   low0   = myRate[0].low;

   // open0  = iOpen(_Symbol, _Period, 1);
   // close0 = iClose(_Symbol, _Period, 1);
   // high0  = iHigh(_Symbol, _Period, 1);
   // low0   = iLow(_Symbol, _Period, 1);
   if(close0 <= open0) {
      return false;
   }

   double body0 = close0 - open0;
   if(!(body0 < hammerBodyRate * (close0 - low0))) {
      return false;
   }
   if(!((high0 - close0) < hammerWickRate * body0)) {
      return false;
   }

   // return true;

   for(int i = 2; i <= 4; i++) {
      double data  = iOpen(_Symbol, _Period, i);
      double open  = iOpen(_Symbol, _Period, i);
      double close = iClose(_Symbol, _Period, i);
      double high  = iHigh(_Symbol, _Period, i);
      double low   = iLow(_Symbol, _Period, i);

      double body  = close - open;
      double range = high - low;

      if(range <= 0 || body <= 0)
         return false;

      // phải là nến giảm mạnh
      if(close >= open)
         return false;

      if(!(body > trendBodyRate * range))
         return false;
   }
   return true;
}

void StartOpenBuy() {
   double entry    = iClose(_Symbol, _Period, 1);
   double stopLoss = iLow(_Symbol, _Period, 1);
   double risk     = entry - stopLoss;
   if(risk <= 0) {
      return;
   }

   double takeProfit = entry + risk * rrRate;

   bool result = trade.Buy(
       volumes,                                 // volume
       _Symbol,                                 // symbol
       SymbolInfoDouble(_Symbol, SYMBOL_ASK),   // price
       NormalizeDouble(stopLoss, _Digits),      // SL
       NormalizeDouble(takeProfit, _Digits),    // TP
       "Hammer Buy"                             // comment
   );

   if(!result) {
      Print("Buy failed. Error = ", GetLastError());
   }
}
