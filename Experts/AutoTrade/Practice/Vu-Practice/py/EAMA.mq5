#property strict

#include <Trade/Trade.mqh>
CTrade trade;

input int    inp_MA_Period      = 200;
input double inp_Lot            = 0.1;
input int    inp_TakeProfitPts  = 500;
input int    inp_StopLossPts    = 400;
input int    inp_MagicNumber    = 20260315;

int      ma_handle = INVALID_HANDLE;
datetime last_bar_time = 0;

// OnTester data

double   equity_day[];
datetime equity_day_time[];
int      saved_day_of_year = -1;
int      saved_year = -1;
int      old_hour = -1;
int      hour_in_trade = 0;
int      hour_in_loss = 0;
int      total_hour_bt = 0;

string TimeframeToText(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return "M1";
      case PERIOD_M2:   return "M2";
      case PERIOD_M3:   return "M3";
      case PERIOD_M4:   return "M4";
      case PERIOD_M5:   return "M5";
      case PERIOD_M6:   return "M6";
      case PERIOD_M10:  return "M10";
      case PERIOD_M12:  return "M12";
      case PERIOD_M15:  return "M15";
      case PERIOD_M20:  return "M20";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H2:   return "H2";
      case PERIOD_H3:   return "H3";
      case PERIOD_H4:   return "H4";
      case PERIOD_H6:   return "H6";
      case PERIOD_H8:   return "H8";
      case PERIOD_H12:  return "H12";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return IntegerToString((int)tf);
   }
}

string BoolToText(bool value)
{
   return value ? "true" : "false";
}

bool IsNewBar()
{
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_bar_time == 0)
      return false;

   if(last_bar_time == 0)
   {
      last_bar_time = current_bar_time;
      return true;
   }

   if(current_bar_time != last_bar_time)
   {
      last_bar_time = current_bar_time;
      return true;
   }

   return false;
}

int FindOpenPositionType()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((int)PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      return (int)PositionGetInteger(POSITION_TYPE);
   }

   return -1;
}

bool CloseCurrentSymbolPositions()
{
   bool all_closed = true;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((int)PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      if(!trade.PositionClose(ticket))
         all_closed = false;
   }

   return all_closed;
}

void SaveDailyEquity(datetime current_time)
{
   MqlDateTime dt;
   TimeToStruct(current_time, dt);

   if(saved_day_of_year != dt.day_of_year || saved_year != dt.year)
   {
      saved_day_of_year = dt.day_of_year;
      saved_year = dt.year;

      int next_index = ArraySize(equity_day);
      ArrayResize(equity_day, next_index + 1);
      ArrayResize(equity_day_time, next_index + 1);

      equity_day[next_index] = AccountInfoDouble(ACCOUNT_EQUITY);
      equity_day_time[next_index] = current_time;
   }

   if(old_hour != dt.hour)
   {
      old_hour = dt.hour;
      total_hour_bt++;

      bool has_position = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;
         if((int)PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
            continue;
         has_position = true;
         break;
      }

      if(has_position)
         hour_in_trade++;

      if(AccountInfoDouble(ACCOUNT_EQUITY) < AccountInfoDouble(ACCOUNT_BALANCE))
         hour_in_loss++;
   }
}

void EnsureFinalEquitySnapshot()
{
   datetime now_time = TimeCurrent();
   if(now_time <= 0)
      now_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(now_time <= 0)
      return;

   if(ArraySize(equity_day_time) == 0)
   {
      SaveDailyEquity(now_time);
      return;
   }

   MqlDateTime last_dt;
   MqlDateTime now_dt;
   TimeToStruct(equity_day_time[ArraySize(equity_day_time) - 1], last_dt);
   TimeToStruct(now_time, now_dt);

   if(last_dt.day_of_year != now_dt.day_of_year || last_dt.year != now_dt.year)
      SaveDailyEquity(now_time);
   else
      equity_day[ArraySize(equity_day) - 1] = AccountInfoDouble(ACCOUNT_EQUITY);
}

bool WriteEquityDayFile(const string file_prefix)
{
   string filename = file_prefix + "_equity_day.csv";
   int file_handle = FileOpen(filename, FILE_WRITE | FILE_CSV);
   if(file_handle == INVALID_HANDLE)
   {
      Print("Cannot open equity file: ", filename, " error=", GetLastError());
      return false;
   }

   FileWrite(file_handle, "date", "equity");
   for(int i = 0; i < ArraySize(equity_day); i++)
      FileWrite(file_handle, TimeToString(equity_day_time[i], TIME_DATE), DoubleToString(equity_day[i], 2));

   FileClose(file_handle);
   return true;
}

double CalculateCustomSharpe()
{
   int size = ArraySize(equity_day);
   if(size < 2)
      return 0.0;

   double returns[];
   ArrayResize(returns, size - 1);

   double mean = 0.0;
   int valid_count = 0;
   for(int i = 1; i < size; i++)
   {
      if(equity_day[i - 1] <= 0.0)
         continue;

      double daily_return = (equity_day[i] / equity_day[i - 1]) - 1.0;
      returns[valid_count] = daily_return;
      mean += daily_return;
      valid_count++;
   }

   if(valid_count < 2)
      return 0.0;

   mean /= valid_count;

   double variance = 0.0;
   for(int i = 0; i < valid_count; i++)
      variance += MathPow(returns[i] - mean, 2.0);

   variance /= valid_count;
   double std_dev = MathSqrt(variance);
   if(std_dev <= 0.0)
      return 0.0;

   return (mean / std_dev) * MathSqrt(260.0);
}

double CalculateAverageTradeHours()
{
   if(!HistorySelect(0, TimeCurrent()))
      return 0.0;

   int total_deals = HistoryDealsTotal();
   if(total_deals <= 0)
      return 0.0;

   ulong entry_deals[];
   double total_hours = 0.0;
   int trade_count = 0;

   for(int i = 0; i < total_deals; i++)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket == 0)
         continue;

      if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if((int)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) != inp_MagicNumber)
         continue;

      int entry_type = (int)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry_type == DEAL_ENTRY_IN)
      {
         int idx = ArraySize(entry_deals);
         ArrayResize(entry_deals, idx + 1);
         entry_deals[idx] = deal_ticket;
      }
      else if(entry_type == DEAL_ENTRY_OUT)
      {
         long position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
         datetime close_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);

         for(int j = ArraySize(entry_deals) - 1; j >= 0; j--)
         {
            if((long)HistoryDealGetInteger(entry_deals[j], DEAL_POSITION_ID) != position_id)
               continue;

            datetime open_time = (datetime)HistoryDealGetInteger(entry_deals[j], DEAL_TIME);
            if(close_time > open_time)
            {
               total_hours += (double)(close_time - open_time) / 3600.0;
               trade_count++;
            }
            break;
         }
      }
   }

   if(trade_count <= 0)
      return 0.0;

   return total_hours / trade_count;
}

bool WriteStatsReportFile(const string file_prefix, const double custom_sharpe)
{
   string filename = file_prefix + "_report.txt";
   int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT);
   if(file_handle == INVALID_HANDLE)
   {
      Print("Cannot open report file: ", filename, " error=", GetLastError());
      return false;
   }

   double profit            = TesterStatistics(STAT_PROFIT);
   double equity_dd         = TesterStatistics(STAT_EQUITY_DD);
   double reward_risk       = (equity_dd != 0.0) ? (profit / equity_dd) : 0.0;
   double total_trades      = TesterStatistics(STAT_TRADES);
   double profit_trades     = TesterStatistics(STAT_PROFIT_TRADES);
   double loss_trades       = TesterStatistics(STAT_LOSS_TRADES);
   double percent_in_trade  = (total_hour_bt > 0) ? (100.0 * hour_in_trade / total_hour_bt) : 0.0;
   double percent_in_loss   = (hour_in_trade > 0) ? (100.0 * hour_in_loss / hour_in_trade) : 0.0;
   double average_trade_hrs = CalculateAverageTradeHours();

   FileWrite(file_handle, "symbol=" + _Symbol);
   FileWrite(file_handle, "timeframe=" + TimeframeToText((ENUM_TIMEFRAMES)_Period));
   FileWrite(file_handle, "ma_period=" + IntegerToString(inp_MA_Period));
   FileWrite(file_handle, "lot=" + DoubleToString(inp_Lot, 2));
   FileWrite(file_handle, "tp_points=" + IntegerToString(inp_TakeProfitPts));
   FileWrite(file_handle, "sl_points=" + IntegerToString(inp_StopLossPts));
   FileWrite(file_handle, "profit=" + DoubleToString(profit, 2));
   FileWrite(file_handle, "custom_sharpe=" + DoubleToString(custom_sharpe, 6));
   FileWrite(file_handle, "mt5_sharpe=" + DoubleToString(TesterStatistics(STAT_SHARPE_RATIO), 6));
   FileWrite(file_handle, "equity_dd=" + DoubleToString(equity_dd, 2));
   FileWrite(file_handle, "equity_dd_percent=" + DoubleToString(TesterStatistics(STAT_EQUITYDD_PERCENT), 2));
   FileWrite(file_handle, "equity_dd_relative=" + DoubleToString(TesterStatistics(STAT_EQUITY_DD_RELATIVE), 2));
   FileWrite(file_handle, "reward_risk=" + DoubleToString(reward_risk, 6));
   FileWrite(file_handle, "total_trades=" + DoubleToString(total_trades, 0));
   FileWrite(file_handle, "profit_trades=" + DoubleToString(profit_trades, 0));
   FileWrite(file_handle, "loss_trades=" + DoubleToString(loss_trades, 0));
   FileWrite(file_handle, "expected_payoff=" + DoubleToString(TesterStatistics(STAT_EXPECTED_PAYOFF), 2));
   FileWrite(file_handle, "recovery_factor=" + DoubleToString(TesterStatistics(STAT_RECOVERY_FACTOR), 6));
   FileWrite(file_handle, "min_marginlevel=" + DoubleToString(TesterStatistics(STAT_MIN_MARGINLEVEL), 2));
   FileWrite(file_handle, "total_deals=" + DoubleToString(TesterStatistics(STAT_DEALS), 0));
   FileWrite(file_handle, "long_trades=" + DoubleToString(TesterStatistics(STAT_LONG_TRADES), 0));
   FileWrite(file_handle, "short_trades=" + DoubleToString(TesterStatistics(STAT_SHORT_TRADES), 0));
   FileWrite(file_handle, "profit_long_trades=" + DoubleToString(TesterStatistics(STAT_PROFIT_LONGTRADES), 0));
   FileWrite(file_handle, "profit_short_trades=" + DoubleToString(TesterStatistics(STAT_PROFIT_SHORTTRADES), 0));
   FileWrite(file_handle, "time_in_trade_percent=" + DoubleToString(percent_in_trade, 2));
   FileWrite(file_handle, "time_in_loss_percent=" + DoubleToString(percent_in_loss, 2));
   FileWrite(file_handle, "average_trade_hours=" + DoubleToString(average_trade_hrs, 2));

   FileClose(file_handle);
   return true;
}

int OnInit()
{
   trade.SetExpertMagicNumber(inp_MagicNumber);

   ma_handle = iMA(_Symbol, PERIOD_CURRENT, inp_MA_Period, 0, MODE_SMA, PRICE_CLOSE);
   if(ma_handle == INVALID_HANDLE)
   {
      Print("Failed to create MA handle. Error=", GetLastError());
      return INIT_FAILED;
   }

   ArrayResize(equity_day, 0);
   ArrayResize(equity_day_time, 0);
   saved_day_of_year = -1;
   saved_year = -1;
   old_hour = -1;
   hour_in_trade = 0;
   hour_in_loss = 0;
   total_hour_bt = 0;

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(ma_handle != INVALID_HANDLE)
      IndicatorRelease(ma_handle);
}

void OnTick()
{
   SaveDailyEquity(TimeCurrent());

   if(!IsNewBar())
      return;

   double ma_buffer[3];
   ArraySetAsSeries(ma_buffer, true);
   if(CopyBuffer(ma_handle, 0, 0, 3, ma_buffer) < 3)
      return;

   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
   if(close1 == 0.0 || close2 == 0.0)
      return;

   bool cross_up = (close2 <= ma_buffer[2] && close1 > ma_buffer[1]);
   bool cross_down = (close2 >= ma_buffer[2] && close1 < ma_buffer[1]);

   int current_position_type = FindOpenPositionType();

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
      return;

   double buy_sl = ask - inp_StopLossPts * _Point;
   double buy_tp = ask + inp_TakeProfitPts * _Point;
   double sell_sl = bid + inp_StopLossPts * _Point;
   double sell_tp = bid - inp_TakeProfitPts * _Point;

   if(cross_up)
   {
      if(current_position_type == POSITION_TYPE_SELL)
         CloseCurrentSymbolPositions();

      current_position_type = FindOpenPositionType();
      if(current_position_type != POSITION_TYPE_BUY)
         trade.Buy(inp_Lot, _Symbol, 0.0, buy_sl, buy_tp, "MA200 Buy");
   }
   else if(cross_down)
   {
      if(current_position_type == POSITION_TYPE_BUY)
         CloseCurrentSymbolPositions();

      current_position_type = FindOpenPositionType();
      if(current_position_type != POSITION_TYPE_SELL)
         trade.Sell(inp_Lot, _Symbol, 0.0, sell_sl, sell_tp, "MA200 Sell");
   }
}

double OnTester()
{
   EnsureFinalEquitySnapshot();

   string file_prefix = _Symbol + "_" + TimeframeToText((ENUM_TIMEFRAMES)_Period)
                      + "_MAPeriod" + IntegerToString(inp_MA_Period)
                      + "_Lot" + DoubleToString(inp_Lot, 2)
                      + "_TP" + IntegerToString(inp_TakeProfitPts)
                      + "_SL" + IntegerToString(inp_StopLossPts);

   WriteEquityDayFile(file_prefix);

   double custom_sharpe = CalculateCustomSharpe();
   WriteStatsReportFile(file_prefix, custom_sharpe);

   return custom_sharpe;
}
