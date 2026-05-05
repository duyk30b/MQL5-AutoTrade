//+------------------------------------------------------------------+
// v1.0 buy : stoch fast cut up stoch slow and < 20
//Sl : atr 
//Tp : sl and RR
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

input int                  inp_Stoch_Kperiod = 5 ;
input int                  inp_Stoch_Dperiod = 3 ;
input int                  inp_Stoch_Slowing = 3 ;
input ENUM_MA_METHOD       inp_Stoch_MAmethod = MODE_EMA ;       // type of smoothing
input int                  inp_LowLevel = 20;
input int                  inp_HighLevel = 80;
input bool                 inp_Follow_trend = true;
input double               inp_SlAtr_rate = 1;
input double               inp_SlTp_rate = 1;

int   StochHandle, Atrhandle;
double K_Buff[],D_Buff[],atrbuff[];
e_buyorsell buysellsignal;
MqlTick                    Tick;
MqlRates                   rates[];

double SL_distance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   StochHandle = iStochastic(_Symbol, PERIOD_CURRENT, inp_Stoch_Kperiod, inp_Stoch_Dperiod, inp_Stoch_Slowing, inp_Stoch_MAmethod, STO_LOWHIGH);
   Atrhandle = iATR(_Symbol, PERIOD_CURRENT, 300);
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(!isNewBar()) return;
// get tick data

   SymbolInfoTick(_Symbol, Tick);
   CopyBuffer(StochHandle, 0, 1, 2, K_Buff); // RsiBuff[0] = Candle[1] , RsiBuff[1]= Candle[2]
   CopyBuffer(StochHandle, 1, 1, 2, D_Buff); // RsiBuff[0] = Candle[1] , RsiBuff[1]= Candle[2]
   CopyBuffer(Atrhandle,0, 1, 1, atrbuff );
   CopyRates(_Symbol, PERIOD_CURRENT, 1, 1, rates);
   get_balance_day(Tick.time);

   buysellsignal = none;
   if(K_Buff[0] < D_Buff[0] && K_Buff[1] > D_Buff[1] && K_Buff[0] < inp_LowLevel )
    { // cut up from low => buy
      buysellsignal = buy;
   }
   if(K_Buff[0] > D_Buff[0] && K_Buff[1] < D_Buff[1] && K_Buff[0] > inp_HighLevel )
    { // cut dn from high => sell
      buysellsignal = sell;
   }
   // khong vao lenh o nhung nen dot bien do tin tuc (khoang gia > 5 lan atr)
   if(rates[0].high - rates[0].low > atrbuff[0] *5) buysellsignal = none;

   if(!inp_Follow_trend){
      if(buysellsignal == sell)buysellsignal = buy;
      else if(buysellsignal == buy)buysellsignal = sell;
   }

   if(buysellsignal == buy ) {
      my_Trade.Buy(0.01, _Symbol, 0, Tick.ask - inp_SlAtr_rate * atrbuff[0] , Tick.ask + inp_SlAtr_rate * atrbuff[0] * inp_SlTp_rate, NULL);
   }
   if(buysellsignal == sell ) {
      my_Trade.Sell(0.01, _Symbol, 0, Tick.bid + inp_SlAtr_rate * atrbuff[0] , Tick.bid - inp_SlAtr_rate * atrbuff[0] * inp_SlTp_rate, NULL);
   }
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
