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

//--- FORWARD DECLARATIONS (Chong loi Compile) ---
void _er_OnInit();
void _er_OnTick(datetime t, int magic=-1);
double _er_OnTester(const string fp, int magic=-1);
//------------------------------------------------

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
   _er_OnInit();

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
   _er_OnTick(TimeCurrent());

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
   _er_OnTester(_Symbol + "_" + _er_TFToText((ENUM_TIMEFRAMES)_Period));

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


//--- INJECTED BY PYTHON (BOTTOM) ---

//+------------------------------------------------------------------+
//|  BEGIN: Equity Reporter (injected by auto_optimize_multisymbol)  |
//+------------------------------------------------------------------+
double   _er_equity_day[];
datetime _er_equity_day_time[];
int      _er_saved_doy     = -1;
int      _er_saved_year    = -1;
int      _er_old_hour      = -1;
int      _er_hour_in_trade = 0;
int      _er_hour_in_loss  = 0;
int      _er_total_hour_bt = 0;

string _er_TFToText(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";   case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";   case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";   case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";  case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";  case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";  case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";   case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";   case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";   case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";   case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return IntegerToString((int)tf);
   }
}

void _er_SaveDailyEquity(datetime t, int magic)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   if(_er_saved_doy != dt.day_of_year || _er_saved_year != dt.year)
   {
      _er_saved_doy  = dt.day_of_year;
      _er_saved_year = dt.year;
      int idx = ArraySize(_er_equity_day);
      ArrayResize(_er_equity_day,      idx + 1);
      ArrayResize(_er_equity_day_time, idx + 1);
      _er_equity_day[idx]      = AccountInfoDouble(ACCOUNT_EQUITY);
      _er_equity_day_time[idx] = t;
   }
   if(_er_old_hour != dt.hour)
   {
      _er_old_hour = dt.hour;
      _er_total_hour_bt++;
      bool has_pos = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong tk = PositionGetTicket(i);
         if(tk == 0 || !PositionSelectByTicket(tk)) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(magic >= 0 && (int)PositionGetInteger(POSITION_MAGIC) != magic) continue;
         has_pos = true; break;
      }
      if(has_pos) _er_hour_in_trade++;
      if(AccountInfoDouble(ACCOUNT_EQUITY) < AccountInfoDouble(ACCOUNT_BALANCE))
         _er_hour_in_loss++;
   }
}

void _er_EnsureFinalSnapshot(int magic)
{
   datetime now = TimeCurrent();
   if(now <= 0) now = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(now <= 0) return;
   if(ArraySize(_er_equity_day_time) == 0) { _er_SaveDailyEquity(now, magic); return; }
   MqlDateTime ld, nd;
   TimeToStruct(_er_equity_day_time[ArraySize(_er_equity_day_time)-1], ld);
   TimeToStruct(now, nd);
   if(ld.day_of_year != nd.day_of_year || ld.year != nd.year)
      _er_SaveDailyEquity(now, magic);
   else
      _er_equity_day[ArraySize(_er_equity_day)-1] = AccountInfoDouble(ACCOUNT_EQUITY);
}

void _er_WriteEquityCSV(const string fp)
{
   int fh = FileOpen(fp + "_equity_day.csv", FILE_WRITE|FILE_CSV);
   if(fh == INVALID_HANDLE) return;
   FileWrite(fh, "date", "equity");
   for(int i = 0; i < ArraySize(_er_equity_day); i++)
      FileWrite(fh, TimeToString(_er_equity_day_time[i], TIME_DATE),
                    DoubleToString(_er_equity_day[i], 2));
   FileClose(fh);
}

double _er_CustomSharpe()
{
   int sz = ArraySize(_er_equity_day);
   if(sz < 2) return 0.0;
   double rets[]; ArrayResize(rets, sz-1);
   double mean = 0.0; int cnt = 0;
   for(int i = 1; i < sz; i++)
   {
      if(_er_equity_day[i-1] <= 0.0) continue;
      rets[cnt] = (_er_equity_day[i] / _er_equity_day[i-1]) - 1.0;
      mean += rets[cnt]; cnt++;
   }
   if(cnt < 2) return 0.0;
   mean /= cnt;
   double var = 0.0;
   for(int i = 0; i < cnt; i++) var += MathPow(rets[i]-mean, 2.0);
   var /= cnt;
   double sd = MathSqrt(var);
   if(sd <= 0.0) return 0.0;
   return (mean/sd) * MathSqrt(260.0);
}

double _er_AvgTradeHours(int magic)
{
   if(!HistorySelect(0, TimeCurrent())) return 0.0;
   int total = HistoryDealsTotal(); if(total <= 0) return 0.0;
   ulong entry_deals[]; double total_hrs = 0.0; int cnt = 0;
   for(int i = 0; i < total; i++)
   {
      ulong tk = HistoryDealGetTicket(i); if(tk == 0) continue;
      if(HistoryDealGetString(tk, DEAL_SYMBOL) != _Symbol) continue;
      if(magic >= 0 && (int)HistoryDealGetInteger(tk, DEAL_MAGIC) != magic) continue;
      int etype = (int)HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(etype == DEAL_ENTRY_IN)
      {
         int idx = ArraySize(entry_deals); ArrayResize(entry_deals, idx+1); entry_deals[idx] = tk;
      }
      else if(etype == DEAL_ENTRY_OUT)
      {
         long pos_id = HistoryDealGetInteger(tk, DEAL_POSITION_ID);
         datetime tc = (datetime)HistoryDealGetInteger(tk, DEAL_TIME);
         for(int j = ArraySize(entry_deals)-1; j >= 0; j--)
         {
            if((long)HistoryDealGetInteger(entry_deals[j], DEAL_POSITION_ID) != pos_id) continue;
            datetime to = (datetime)HistoryDealGetInteger(entry_deals[j], DEAL_TIME);
            if(tc > to) { total_hrs += (double)(tc-to)/3600.0; cnt++; }
            break;
         }
      }
   }
   return (cnt > 0) ? total_hrs/cnt : 0.0;
}

void _er_WriteStatsReport(const string fp, const double sharpe, int magic)
{
   int fh = FileOpen(fp + "_report.txt", FILE_WRITE|FILE_TXT);
   if(fh == INVALID_HANDLE) return;
   
   double pct_trade = (_er_total_hour_bt > 0) ? (100.0*_er_hour_in_trade/_er_total_hour_bt) : 0.0;
   double pct_loss  = (_er_hour_in_trade > 0) ? (100.0*_er_hour_in_loss/_er_hour_in_trade)  : 0.0;
   double profit    = TesterStatistics(STAT_PROFIT);
   double eq_dd     = TesterStatistics(STAT_EQUITY_DD);
   
   FileWrite(fh, "symbol="                + _Symbol);
   FileWrite(fh, "timeframe="             + _er_TFToText((ENUM_TIMEFRAMES)_Period));
      // --- THONG SO EA TU DONG --- 
   FileWrite(fh, "inp_Stoch_Kperiod=" + (string)inp_Stoch_Kperiod);
   FileWrite(fh, "inp_Stoch_Dperiod=" + (string)inp_Stoch_Dperiod);
   FileWrite(fh, "inp_Stoch_Slowing=" + (string)inp_Stoch_Slowing);
   FileWrite(fh, "inp_Stoch_MAmethod=" + (string)inp_Stoch_MAmethod);
   FileWrite(fh, "inp_LowLevel=" + (string)inp_LowLevel);
   FileWrite(fh, "inp_HighLevel=" + (string)inp_HighLevel);
   FileWrite(fh, "inp_Follow_trend=" + (string)inp_Follow_trend);
   FileWrite(fh, "inp_SlAtr_rate=" + (string)inp_SlAtr_rate);
   FileWrite(fh, "inp_SlTp_rate=" + (string)inp_SlTp_rate);

   FileWrite(fh, "custom_sharpe="         + DoubleToString(sharpe, 6));
   FileWrite(fh, "time_in_trade_percent=" + DoubleToString(pct_trade, 2));
   FileWrite(fh, "time_in_loss_percent="  + DoubleToString(pct_loss, 2));
   FileWrite(fh, "average_trade_hours="   + DoubleToString(_er_AvgTradeHours(magic), 2));
   FileWrite(fh, "reward_risk="           + DoubleToString((eq_dd!=0.0)?(profit/eq_dd):0.0, 6));

   // Các thông số MT5
   FileWrite(fh, "profit="                + DoubleToString(TesterStatistics(STAT_PROFIT), 2));
   FileWrite(fh, "gross_profit="          + DoubleToString(TesterStatistics(STAT_GROSS_PROFIT), 2));
   FileWrite(fh, "gross_loss="            + DoubleToString(TesterStatistics(STAT_GROSS_LOSS), 2));
   FileWrite(fh, "profit_factor="         + DoubleToString(TesterStatistics(STAT_PROFIT_FACTOR), 4));
   FileWrite(fh, "expected_payoff="       + DoubleToString(TesterStatistics(STAT_EXPECTED_PAYOFF), 2));
   FileWrite(fh, "recovery_factor="       + DoubleToString(TesterStatistics(STAT_RECOVERY_FACTOR), 4));
   FileWrite(fh, "sharpe_ratio="          + DoubleToString(TesterStatistics(STAT_SHARPE_RATIO), 4));
   FileWrite(fh, "balance_dd="            + DoubleToString(TesterStatistics(STAT_BALANCE_DD), 2));
   FileWrite(fh, "equity_dd="             + DoubleToString(TesterStatistics(STAT_EQUITY_DD), 2));
   FileWrite(fh, "min_marginlevel="       + DoubleToString(TesterStatistics(STAT_MIN_MARGINLEVEL), 2));
   FileWrite(fh, "deals="                 + DoubleToString(TesterStatistics(STAT_DEALS), 0));
   FileWrite(fh, "trades="                + DoubleToString(TesterStatistics(STAT_TRADES), 0));
   FileWrite(fh, "profit_trades="         + DoubleToString(TesterStatistics(STAT_PROFIT_TRADES), 0));
   FileWrite(fh, "loss_trades="           + DoubleToString(TesterStatistics(STAT_LOSS_TRADES), 0));
   FileWrite(fh, "max_profit_trade="      + DoubleToString(TesterStatistics(STAT_MAX_PROFITTRADE), 2));
   FileWrite(fh, "max_loss_trade="        + DoubleToString(TesterStatistics(STAT_MAX_LOSSTRADE), 2));
   FileWrite(fh, "con_profit_max_money="  + DoubleToString(TesterStatistics(STAT_CONPROFITMAX), 2));
   FileWrite(fh, "con_loss_max_money="    + DoubleToString(TesterStatistics(STAT_CONLOSSMAX), 2));

   FileClose(fh);
}

void _er_OnInit()
{
   ArrayResize(_er_equity_day, 0); ArrayResize(_er_equity_day_time, 0);
   _er_saved_doy=_er_saved_year=_er_old_hour=-1;
   _er_hour_in_trade=_er_hour_in_loss=_er_total_hour_bt=0;
}

void _er_OnTick(datetime t, int magic=-1) { _er_SaveDailyEquity(t, magic); }

double _er_OnTester(const string fp, int magic=-1)
{
   _er_EnsureFinalSnapshot(magic);
   
   // Bơm thêm ID siêu nhỏ (Microsecond) vào tên file để 45 kịch bản không đè lên nhau
   string unique_fp = fp + "_pass_" + IntegerToString(GetMicrosecondCount());
   
   _er_WriteEquityCSV(unique_fp);
   double sh = _er_CustomSharpe();
   _er_WriteStatsReport(unique_fp, sh, magic);
   return sh;
}
//+------------------------------------------------------------------+
//|  END: Equity Reporter                                            |
//+------------------------------------------------------------------+

