//+------------------------------------------------------------------+
// v2.3 SELL : price higher, rsi lower 
// SL in highest price, TP by inp_SlTp_rate
// if SL < 1atr => SL = 1atr
//+------------------------------------------------------------------+
#include                   <Trade\Trade.mqh>
CTrade                     my_Trade;
#include                   <Trade\PositionInfo.mqh>
CPositionInfo              my_Pos_Info;
#include                   <Trade\OrderInfo.mqh>
COrderInfo                 my_Order_Info;
enum e_buyorsell {
   none, buy, sell
};
input int                  inp_Rsi_MAperiod = 10 ;
input int                  inp_Rsi_HighCutoff = 70;
input double               inp_SlTp_rate = 1;


int   RsiHandle, Atrhandle;
double RsiBuff[], atrbuff[];
e_buyorsell buysellsignal;
MqlTick                    Tick;
MqlRates                   rates[];

int curEXTshift;
double lastEXTprice, curEXTprice, lastEXT_RSI, curEXT_RSI;
datetime lastEXTtime, curEXTtime;
double SL_distance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   RsiHandle = iRSI(_Symbol, PERIOD_CURRENT, inp_Rsi_MAperiod, PRICE_CLOSE);
   Atrhandle = iATR(_Symbol, PERIOD_CURRENT, 300);
   ArraySetAsSeries(RsiBuff, true);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}

//+------------------------------------------------------------------+
//| Ontester                                                         |
//+------------------------------------------------------------------+
double                     Balance_day[]; // main array
MqlDateTime                D_time;
int                        old_day =0 ;
void  get_balance_day(datetime time) {
   TimeToStruct(time,D_time);
   if(old_day != D_time.day) {
      old_day = D_time.day;
      Balance_day.Push(AccountInfoDouble(ACCOUNT_EQUITY));
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester(void) {
   int size = ArraySize(Balance_day);
   double change_day[];
   ArrayResize(change_day,size,10);
   change_day[0] =1;
   double sum = 1;
   for(int i=1; i<size; i++) {
      change_day[i] = Balance_day[i]/Balance_day[i-1];
      sum += change_day[i];
   }
   double ave = sum/size;
   sum = 0;
   double std[];
   ArrayResize(std,size,0);
   for(int i=0; i<size; i++) {
      std[i] = MathPow( change_day[i] - ave,2);
      sum += std[i];
   }
   double std_dev = MathSqrt(sum/size);
   double sharpe = (ave-1)/std_dev * MathSqrt(260);
   return(sharpe);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(!isNewBar()) return;
// get tick data

   SymbolInfoTick(_Symbol, Tick);
   CopyBuffer(RsiHandle, 0, 1, 100, RsiBuff); // RsiBuff[0] = Candle[1] , RsiBuff[1]= Candle[2]
   CopyBuffer(Atrhandle,0, 1, 1, atrbuff );
   CopyRates(_Symbol, PERIOD_CURRENT, 1, 1, rates);
   get_balance_day(Tick.time);

   buysellsignal = none;
   if(RsiBuff[0] < inp_Rsi_HighCutoff && RsiBuff[1] > inp_Rsi_HighCutoff) { // cut down from high
      // get cur ext price
      int i = 0;
      curEXT_RSI =0;
      while(RsiBuff[i+1] > inp_Rsi_HighCutoff) {
         curEXT_RSI = MathMax(curEXT_RSI,RsiBuff[i]);
         i++;
      }
      curEXT_RSI = MathMax(curEXT_RSI,RsiBuff[i]);
      curEXTshift = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, i, 1);
      curEXTprice = iHigh(_Symbol, PERIOD_CURRENT, curEXTshift);
      curEXTtime = iTime(_Symbol, PERIOD_CURRENT, curEXTshift);

      if(lastEXTprice != 0) {
         if(lastEXTprice < curEXTprice && lastEXT_RSI > curEXT_RSI) {
            buysellsignal = sell;
         }
      }

      lastEXTprice = curEXTprice;
      lastEXT_RSI = curEXT_RSI;
      lastEXTtime = curEXTtime;
   }

   // khong vao lenh o nhung nen dot bien do tin tuc (khoang gia > 5 lan atr)
   if(rates[0].high - rates[0].low > atrbuff[0] *5) buysellsignal = none;


   if(buysellsignal == sell && lastEXTprice > Tick.bid ) {
      SL_distance = lastEXTprice - Tick.bid;
      if(SL_distance < atrbuff[0] ) SL_distance = atrbuff[0]; // neu khoang cach SL qua nho => SL se la 1 atr
      my_Trade.Sell(0.01, _Symbol, 0, Tick.bid + SL_distance , Tick.bid - SL_distance * inp_SlTp_rate, NULL);
   }
}

//+------------------------------------------------------------------+
bool isNewBar() {
//--- remember the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

//--- if it is the first call of the function
   if(last_time==0) {
      //--- set time and exit
      last_time=lastbar_time;
      return(false);
   }

//--- if the time is different
   if(last_time!=lastbar_time) {
      //--- memorize time and return true
      last_time=lastbar_time;
      return(true);
   }
//--- if we pass to this line then the bar is not new, return false
   return(false);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
