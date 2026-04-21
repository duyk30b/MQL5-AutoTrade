# inject_equity_reporter.py
# Nhúng thẳng code equity reporting vào bất kỳ EA .mq5 nào.
# Không cần file .mqh nào — tất cả tự chứa trong file output.
#
# Cách dùng:
#   python inject_equity_reporter.py <ea.mq5> [magic_number]
#
# Ví dụ:
#   python inject_equity_reporter.py "Moving Average.mq5"
#   python inject_equity_reporter.py "Moving Average.mq5" 1234501
#   python inject_equity_reporter.py MyEA.mq5 99999
#
# Output:
#   <thư mục EA>\<TênEA>_EBR.mq5  — compile bằng MetaEditor là xong
#
# File output mỗi optimization pass (trong MQL5\Files\):
#   <Symbol>_<TF>_equity_day.csv   — equity theo ngày
#   <Symbol>_<TF>_report.txt       — profit, sharpe, drawdown, ...

import re
import sys
from pathlib import Path

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

SCRIPT_DIR = Path(__file__).resolve().parent

# ============================================================
#  Khối code MQL5 sẽ được nhúng thẳng vào EA
# ============================================================

EQUITY_BLOCK = r"""
//+------------------------------------------------------------------+
//|  BEGIN: Equity Reporter (injected by inject_equity_reporter.py)  |
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
   double profit    = TesterStatistics(STAT_PROFIT);
   double eq_dd     = TesterStatistics(STAT_EQUITY_DD);
   double pct_trade = (_er_total_hour_bt > 0) ? (100.0*_er_hour_in_trade/_er_total_hour_bt) : 0.0;
   double pct_loss  = (_er_hour_in_trade > 0) ? (100.0*_er_hour_in_loss/_er_hour_in_trade)  : 0.0;
   FileWrite(fh, "symbol="                + _Symbol);
   FileWrite(fh, "timeframe="             + _er_TFToText((ENUM_TIMEFRAMES)_Period));
   FileWrite(fh, "profit="                + DoubleToString(profit, 2));
   FileWrite(fh, "custom_sharpe="         + DoubleToString(sharpe, 6));
   FileWrite(fh, "mt5_sharpe="            + DoubleToString(TesterStatistics(STAT_SHARPE_RATIO), 6));
   FileWrite(fh, "equity_dd="             + DoubleToString(eq_dd, 2));
   FileWrite(fh, "equity_dd_percent="     + DoubleToString(TesterStatistics(STAT_EQUITYDD_PERCENT), 2));
   FileWrite(fh, "equity_dd_relative="    + DoubleToString(TesterStatistics(STAT_EQUITY_DD_RELATIVE), 2));
   FileWrite(fh, "reward_risk="           + DoubleToString((eq_dd!=0.0)?(profit/eq_dd):0.0, 6));
   FileWrite(fh, "total_trades="          + DoubleToString(TesterStatistics(STAT_TRADES), 0));
   FileWrite(fh, "profit_trades="         + DoubleToString(TesterStatistics(STAT_PROFIT_TRADES), 0));
   FileWrite(fh, "loss_trades="           + DoubleToString(TesterStatistics(STAT_LOSS_TRADES), 0));
   FileWrite(fh, "expected_payoff="       + DoubleToString(TesterStatistics(STAT_EXPECTED_PAYOFF), 2));
   FileWrite(fh, "recovery_factor="       + DoubleToString(TesterStatistics(STAT_RECOVERY_FACTOR), 6));
   FileWrite(fh, "min_marginlevel="        + DoubleToString(TesterStatistics(STAT_MIN_MARGINLEVEL), 2));
   FileWrite(fh, "total_deals="           + DoubleToString(TesterStatistics(STAT_DEALS), 0));
   FileWrite(fh, "long_trades="           + DoubleToString(TesterStatistics(STAT_LONG_TRADES), 0));
   FileWrite(fh, "short_trades="          + DoubleToString(TesterStatistics(STAT_SHORT_TRADES), 0));
   FileWrite(fh, "profit_long_trades="    + DoubleToString(TesterStatistics(STAT_PROFIT_LONGTRADES), 0));
   FileWrite(fh, "profit_short_trades="   + DoubleToString(TesterStatistics(STAT_PROFIT_SHORTTRADES), 0));
   FileWrite(fh, "time_in_trade_percent=" + DoubleToString(pct_trade, 2));
   FileWrite(fh, "time_in_loss_percent="  + DoubleToString(pct_loss, 2));
   FileWrite(fh, "average_trade_hours="   + DoubleToString(_er_AvgTradeHours(magic), 2));
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
   _er_WriteEquityCSV(fp);
   double sh = _er_CustomSharpe();
   _er_WriteStatsReport(fp, sh, magic);
   return sh;
}
//+------------------------------------------------------------------+
//|  END: Equity Reporter                                            |
//+------------------------------------------------------------------+
"""

# ============================================================
#  Helpers xử lý source MQL5
# ============================================================

def find_func_open_brace(source: str, pattern: str):
    m = re.search(pattern, source)
    if not m:
        return None
    pos = m.end()
    while pos < len(source):
        c = source[pos]
        if c == '{':
            return pos
        elif c in ' \t\n\r':
            pos += 1
        else:
            return None
    return None


def inject_after_open_brace(source: str, brace_pos: int, code: str) -> str:
    return source[:brace_pos + 1] + '\n' + code + source[brace_pos + 1:]


def insert_equity_block(source: str) -> str:
    """Chèn EQUITY_BLOCK sau khối #include cuối cùng (hoặc #property, hoặc đầu file)."""
    includes = list(re.finditer(r'^[ \t]*#include\b.*$', source, re.MULTILINE))
    if includes:
        pos = includes[-1].end()
        return source[:pos] + '\n' + EQUITY_BLOCK + source[pos:]

    props = list(re.finditer(r'^[ \t]*#property\b.*$', source, re.MULTILINE))
    if props:
        pos = props[-1].end()
        return source[:pos] + '\n' + EQUITY_BLOCK + source[pos:]

    return EQUITY_BLOCK + '\n' + source


def has_ontester(source: str) -> bool:
    return bool(re.search(r'\bOnTester\s*\(\s*\)', source))


def make_tick_call(magic: int) -> str:
    ms = f', {magic}' if magic >= 0 else ''
    return f'   _er_OnTick(TimeCurrent(){ms});\n'


def make_ontester_side_call(magic: int) -> str:
    ms = f', {magic}' if magic >= 0 else ''
    prefix = '_Symbol + "_" + _er_TFToText((ENUM_TIMEFRAMES)_Period)'
    return f'   _er_OnTester({prefix}{ms});\n'


def make_new_ontester(magic: int) -> str:
    ms = f', {magic}' if magic >= 0 else ''
    prefix = '_Symbol + "_" + _er_TFToText((ENUM_TIMEFRAMES)_Period)'
    return (
        '\ndouble OnTester()\n'
        '  {\n'
        f'   return _er_OnTester({prefix}{ms});\n'
        '  }\n'
    )


# ============================================================
#  Inject chính
# ============================================================

def inject_ea(mq5_path: Path, magic: int) -> bool:
    if not mq5_path.exists():
        print(f'[ERR] Không tìm thấy file: {mq5_path}')
        return False

    try:
        source = mq5_path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        source = mq5_path.read_text(encoding='latin-1')

    if '_er_OnTick' in source or '_er_equity_day' in source:
        print(f'[SKIP] Đã inject rồi: {mq5_path.name}')
        return False

    # EA đã có đủ equity reporter riêng → copy thẳng, không inject thêm
    # Dùng all() — nếu chỉ có 1 phần → vẫn inject _er_* (namespace riêng, không đụng tên gốc)
    BUILTIN_MARKERS = ['CalculateCustomSharpe', 'WriteEquityDayFile', 'WriteStatsReportFile', 'SaveDailyEquity']
    if all(m in source for m in BUILTIN_MARKERS):
        out_path = mq5_path.parent / (mq5_path.stem + '_EBR.mq5')
        out_path.write_text(source, encoding='utf-8')
        print(f'\n[INFO] {mq5_path.name} đã có equity reporter sẵn — copy as-is → {out_path.name}')
        print('       Bước tiếp: mở MetaEditor → compile file _EBR.mq5')
        return True

    print(f'\n--- Injecting vào: {mq5_path.name} ---')
    print(f'    magic filter: {magic if magic >= 0 else "không lọc (theo symbol)"}')

    # 1. Nhúng khối global + hàm helper
    source = insert_equity_block(source)
    print('[ok]  Nhúng khối equity reporter (global + helpers)')

    # 2. _er_OnInit() trong OnInit
    brace = find_func_open_brace(source, r'\bint\s+OnInit\s*\([^)]*\)')
    if brace is not None:
        source = inject_after_open_brace(source, brace, '   _er_OnInit();\n')
        print('[ok]  Thêm _er_OnInit() trong OnInit()')
    else:
        print('[WARN] Không tìm thấy OnInit() — bỏ qua, biến global tự khởi tạo')

    # 3. _er_OnTick() trong OnTick hoặc OnBar
    tick_code = make_tick_call(magic)
    brace = find_func_open_brace(source, r'\bvoid\s+OnTick\s*\([^)]*\)')
    if brace is not None:
        source = inject_after_open_brace(source, brace, tick_code)
        print('[ok]  Thêm _er_OnTick() trong OnTick()')
    else:
        brace = find_func_open_brace(source, r'\bvoid\s+OnBar\s*\([^)]*\)')
        if brace is not None:
            source = inject_after_open_brace(source, brace, tick_code)
            print('[ok]  Thêm _er_OnTick() trong OnBar()')
        else:
            print('[WARN] Không tìm thấy OnTick()/OnBar()')

    # 4. OnTester
    if has_ontester(source):
        brace = find_func_open_brace(source, r'\bdouble\s+OnTester\s*\(\s*\)')
        if brace is not None:
            source = inject_after_open_brace(source, brace, make_ontester_side_call(magic))
            print('[ok]  Thêm _er_OnTester() vào OnTester() hiện có')
        else:
            print('[WARN] Phát hiện OnTester() nhưng không parse được — thêm thủ công')
    else:
        source = source.rstrip() + '\n' + make_new_ontester(magic)
        print('[ok]  Tạo mới OnTester()')

    out_path = mq5_path.parent / (mq5_path.stem + '_EBR.mq5')
    out_path.write_text(source, encoding='utf-8')
    print(f'\n[DONE] Đã ghi: {out_path}')
    print('       Bước tiếp: mở MetaEditor → compile file _EBR.mq5')
    return True


# ============================================================
#  Entry point
# ============================================================

def main():
    if len(sys.argv) < 2:
        print('Cách dùng:  python inject_equity_reporter.py <ea.mq5> [magic_number]')
        print()
        print('Ví dụ:')
        print('  python inject_equity_reporter.py "Moving Average.mq5"')
        print('  python inject_equity_reporter.py "Moving Average.mq5" 1234501')
        print('  python inject_equity_reporter.py MyEA.mq5 99999')
        print()
        print('Output: <TênEA>_EBR.mq5  (file gốc không bị thay đổi)')
        sys.exit(1)

    mq5_arg = sys.argv[1]
    magic   = int(sys.argv[2]) if len(sys.argv) > 2 else -1

    mq5_path = Path(mq5_arg)
    if not mq5_path.is_absolute():
        cwd_try = Path.cwd() / mq5_path
        if cwd_try.exists():
            mq5_path = cwd_try
        else:
            mql5_root = SCRIPT_DIR.parents[4]
            experts_try = mql5_root / 'Experts' / mq5_path
            if experts_try.exists():
                mq5_path = experts_try
            else:
                print(f'[ERR] Không tìm thấy: {mq5_arg}')
                print(f'      Thử: {cwd_try}')
                print(f'      Thử: {experts_try}')
                sys.exit(1)

    success = inject_ea(mq5_path, magic)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
