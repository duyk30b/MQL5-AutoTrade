//+------------------------------------------------------------------+
//| Ontester       save balance day
//+------------------------------------------------------------------+
double                     Balance_day[]; // main array
datetime                   Datetime_balance[]; // save date
MqlDateTime                D_time;
int                        old_day =0 ;
string                     date_b ="";
int                        old_hour =0;
int                        hour_intrade =0;
int                        hour_inloss = 0;
int                        total_hour_bt =0;
// for dca count
int                        dca_chain[20];
void  get_balance_day(datetime time) {
   TimeToStruct(time,D_time);
   if(old_day != D_time.day) {
      old_day = D_time.day;
      Balance_day.Push(AccountInfoDouble(ACCOUNT_EQUITY));
      date_b = (string)D_time.day + "."+ (string)D_time.mon + "."+ (string)D_time.year;
      Datetime_balance.Push(StringToTime(date_b));
   }
   if(old_hour != D_time.hour) {
      old_hour = D_time.hour;
      total_hour_bt +=1;
      if(PositionsTotal()!=0) hour_intrade +=1;
      if(AccountInfoDouble(ACCOUNT_EQUITY)<AccountInfoDouble(ACCOUNT_BALANCE)) hour_inloss+=1;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester(void) {
   int size = ArraySize(Balance_day);
   string para_optimize = _Symbol  + "_H1_" ;//+ (string)inp_percentile + "_" + (string)inp_start_num_signal + "_" + (string)inp_stop_num_signal;
// save balance file
   string filename =  para_optimize + "_D1_balance.csv";
   int file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
   if(file_handle==INVALID_HANDLE) return false;
   for(int i=0;i<size;i++)
      FileWrite(file_handle,Datetime_balance[i],Balance_day[i]);
   FileClose(file_handle);
// caculator average holding time
   my_His_Pos_Info.HistorySelect(0,TimeCurrent());

   int PosTotal = my_His_Pos_Info.PositionsTotal();
   ulong PosTimeTotal = 0;
   for(int i = 0; i < PosTotal; i++) {
      //--- Select a closed position by its index in the list
      if(my_His_Pos_Info.SelectByIndex(i)) {
         datetime time_open         = my_His_Pos_Info.TimeOpen();
         datetime time_close        = my_His_Pos_Info.TimeClose();
         PosTimeTotal += time_close - time_open;
      }
   }

   double   AverageTime = (PosTotal > 0) ? ((double)(PosTimeTotal/PosTotal)) : 0;
// get sharpe to report

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

// save my report
   filename = para_optimize + "_myreport.txt";
   file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_TXT);
   if(file_handle==INVALID_HANDLE) return false;
   FileWrite(file_handle, "D_Sharpe " + DoubleToString(sharpe,2) );
   FileWrite(file_handle, "Profit " + DoubleToString(TesterStatistics(STAT_PROFIT),2) );
   FileWrite(file_handle, "Equity_dd " + DoubleToString(TesterStatistics(STAT_EQUITY_DD),2) );
   FileWrite(file_handle, "Reward/Risk " + DoubleToString( (TesterStatistics(STAT_PROFIT)/TesterStatistics(STAT_EQUITY_DD)),2));
   FileWrite(file_handle, "Total_trades " + (string)TesterStatistics(STAT_TRADES) );
   FileWrite(file_handle, "Profit_trade " + (string)TesterStatistics(STAT_PROFIT_TRADES) );
   FileWrite(file_handle, "Loss_trades " + (string)TesterStatistics(STAT_LOSS_TRADES) );
   FileWrite(file_handle, "time_intrade " + DoubleToString( 100*hour_intrade/total_hour_bt,2));
   FileWrite(file_handle, "time_inloss " + DoubleToString( 100*hour_inloss/hour_intrade,2));
   FileWrite(file_handle, "average_trade_time " + DoubleToString( AverageTime/3600,2));
   FileWrite(file_handle, "Equity_dd_percent " + DoubleToString(TesterStatistics(STAT_EQUITYDD_PERCENT),2) );
   FileWrite(file_handle, "Equity_dd_relative " + DoubleToString(TesterStatistics(STAT_EQUITY_DD_RELATIVE),2) );
   FileWrite(file_handle, "Expected_payoff " + DoubleToString(TesterStatistics(STAT_EXPECTED_PAYOFF),2) );
   FileWrite(file_handle, "Recovery_factor " + DoubleToString(TesterStatistics(STAT_RECOVERY_FACTOR),2) );
   FileWrite(file_handle, "Sharpe_ratio " + DoubleToString(TesterStatistics(STAT_SHARPE_RATIO),2) );
   FileWrite(file_handle, "Min_Marginlevel " + DoubleToString(TesterStatistics(STAT_MIN_MARGINLEVEL),2) );
   FileWrite(file_handle, "Total_deals " + (string)TesterStatistics(STAT_DEALS) );
   FileWrite(file_handle, "Short_trades " + (string)TesterStatistics(STAT_SHORT_TRADES) );
   FileWrite(file_handle, "Long_trades " + (string)TesterStatistics(STAT_LONG_TRADES) );
   FileWrite(file_handle, "Profit_short_trades " + (string)TesterStatistics(STAT_PROFIT_SHORTTRADES) );
   FileWrite(file_handle, "Profit_long_trades " + (string)TesterStatistics(STAT_PROFIT_LONGTRADES) );
   FileClose(file_handle);
// save dca report : chi dung khi co dca trong ea , neu khong co dca xoa tu dong nay den truoc dong return
   filename = para_optimize + "_dcareport.txt";
   file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_TXT);
   if(file_handle==INVALID_HANDLE) return false;
   int total_chain =0;
   for(int i=0;i<ArraySize(dca_chain);i++) {
      total_chain += dca_chain[i];
   }
   FileWrite(file_handle, "total_chain " + (string)total_chain);

   double per_pos = 0.99 * total_chain;
   int get99_chain =0;
   int number_per =0; // chain can tim
   for(int i=0;i<ArraySize(dca_chain);i++) {
      get99_chain += dca_chain[i];
      if(get99_chain>per_pos) {
         number_per = i+1;
         break;
      }
   }
   FileWrite(file_handle, "chain_99% " + (string)number_per);
   int chainconlai = total_chain;
   for(int i=0;i<ArraySize(dca_chain);i++) {
      FileWrite(file_handle, "chain_" + (string)(i+1) + " " + (string)dca_chain[i]);
      FileWrite(file_handle, "chain_" + (string)(i+1) + "_percent " + DoubleToString((100*chainconlai/total_chain),2) );
      chainconlai = chainconlai - dca_chain[i];
   }
   FileClose(file_handle);
//+------------------------------------------------------------------+
//| huong dan dung phan tinh DCA : muc dich de thong ke dca ket thuc o may trade                                                          
//+------------------------------------------------------------------+
//void c_gvar :: CloseAllPosition() {
//   while(PositionsTotal()>0) {
//      if(my_Pos_Info.SelectByIndex(0)) { // select a position
//         my_Trade.PositionClose(my_Pos_Info.Ticket()); // then delete it --period
//      }
//   }
//   if(num_trade>0)dca_chain[num_trade-1] +=1; // <==================================== tinh xem chuoi dca nay ket thuc o may trade
//   num_trade = 0;
//}

   return(sharpe);
}
//+------------------------------------------------------------------+

//void OnTick() {
////---
//   SymbolInfoTick(_Symbol, Tick);
//   if(isNewBar()) {
//      get_balance_day(Tick.time);
//   }

