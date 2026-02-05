//+------------------------------------------------------------------+
//|                                                           x1.mq5 |
//|                                         Copyright 2026, YourName |
//|                                                 https://mql5.com |
//| 01.02.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, YourName"
#property link "https://mql5.com"
#property version "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
// mở lệnh cùng lúc 5 thị trường :EURUSD, GBPUSD, USDCAD, NZDUSD, USDJPY
// mua khi RSI 1 > 70 RSI 2 <70, bán khi ngược lại (RSI1 < 30, RSI3 > 30),
// nếu lệnh 1 lỗ, c lệnh 2 sẽ vào lệnh với khối lượng gấp đôi
//+------------------------------------------------------------------+

/*
RSI (Relative Strength Index)
👉 là chỉ báo đo độ mạnh – yếu của giá: cho biết thị trường đang quá mua hay quá bán
👉 RSI so sánh: Mức tăng trung bình - Với mức giảm trung bình (trong N cây nến gần nhất)
RS = Avg Gain / Avg Loss
RSI = 100 - (100 / (1 + RS)) = (Gain / (Gain + Loss)) * 100

rsiSlowPeriod: RSI(14) nghĩa là: “Đánh giá sức mạnh giá trong 14 cây nến gần nhất” (Xu hướng chính)
rsiFastPeriod: RSI(7): nghĩa là: “Đánh giá sức mạnh giá trong 7 cây nến gần nhất” (RSI nhanh (fast RSI))
*/

input double baseLot       = 0.01;
input int    rsiFastPeriod = 7;
input int    RSI_BuyLevel  = 70;
input int    RSI_SellLevel = 30;
datetime     lastBarTime   = 0;

struct SymbolState {
   string             symbol;
   double             rsi1;
   double             rsi2;
   ulong              lastTicket;
   double             lastProfit;
   double             lastVolume;
   ENUM_POSITION_TYPE lastPositionType;
};

SymbolState symbolStateList[5] = {
    {"EURUSD", 0, 0, 0, 0, 0, 0},
    {"GBPUSD", 0, 0, 0, 0, 0, 0},
    {"USDCAD", 0, 0, 0, 0, 0, 0},
    {"NZDUSD", 0, 0, 0, 0, 0, 0},
    {"USDJPY", 0, 0, 0, 0, 0, 0},
};

int OnInit() {
   Print("EA started");
   EventSetMillisecondTimer(1);
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   EventKillTimer();
}

void onTimer() {
   for(int i = 0; i < 5; i++) {
      ProcessSymbolState(symbolStateList[i]);
   }
}

void ProcessSymbolState(SymbolState &symbolState) {
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   Print("========== currentBarTime: ", symbolState.symbol, currentBarTime);
   if(currentBarTime == lastBarTime) {
      return;
   }
   lastBarTime = currentBarTime;
   Print("========== currentBarTime: ", symbolState.symbol, lastBarTime);
   string symbol = symbolState.symbol;
   if(!SymbolSelect(symbol, true))
      return;
   RefreshDataSymbolState(symbolState);

   Print("========== symbolState.lastTicket: ", symbol, symbolState.lastTicket);
   if(symbolState.lastTicket == 0) {
      if(symbolState.rsi1 > RSI_BuyLevel && symbolState.rsi2 < RSI_BuyLevel) {
         Print("========== trade.Buy: ", symbol);
         trade.Buy(baseLot, symbol);
      } else if(symbolState.rsi1 < RSI_SellLevel && symbolState.rsi2 > RSI_SellLevel) {
         Print("========== trade.Sell: ", symbol);
         trade.Sell(baseLot, symbol);
      }
   }

   else if(symbolState.lastProfit < 0) {
      if(symbolState.rsi1 > RSI_BuyLevel && symbolState.rsi2 < RSI_BuyLevel) {
         if(symbolState.lastPositionType == POSITION_TYPE_SELL) {
            trade.PositionClose(symbolState.lastTicket);
            Print("========== trade.Buy: ", symbol);
            double newLot = symbolState.lastVolume * 2;
            trade.Buy(newLot, symbol);
         }
      } else if(symbolState.rsi1 < RSI_SellLevel && symbolState.rsi2 > RSI_SellLevel) {
         if(symbolState.lastPositionType == POSITION_TYPE_BUY) {
            trade.PositionClose(symbolState.lastTicket);
            Print("========== trade.Sell: ", symbol);
            double newLot = symbolState.lastVolume * 2;
            trade.Sell(newLot, symbol);
         }
         trade.Sell(baseLot, symbol);
      }
   }
}

void RefreshDataSymbolState(SymbolState &symbolState) {
   symbolState.lastTicket = 0;
   symbolState.lastVolume = 0;
   symbolState.lastProfit = 0;
   symbolState.rsi1       = 0;
   symbolState.rsi2       = 0;

   int handle = iRSI(symbolState.symbol, PERIOD_CURRENT, rsiFastPeriod, PRICE_CLOSE);
   if(handle != INVALID_HANDLE) {
      double buffer[];
      // start_pos = 0 => cây nến hiện tại
      CopyBuffer(handle, 0, 0, 3, buffer);
      // buffer[0] = RSI hiện tại
      symbolState.rsi1 = buffer[1];
      symbolState.rsi2 = buffer[2];
   }
   // IndicatorRelease() – dọn rác bộ nhớ
   IndicatorRelease(handle);

   int positionTotal = PositionsTotal();
   for(int i = 0; i < positionTotal; i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != symbolState.symbol)
         continue;
      if(PositionSelectByTicket(ticket)) {
         symbolState.lastTicket       = ticket;
         symbolState.lastProfit       = PositionGetDouble(POSITION_PROFIT);
         symbolState.lastVolume       = PositionGetDouble(POSITION_VOLUME);
         symbolState.lastPositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      }
   }
}
