# v3.2 Build by clawbot
# Tích hợp inject_equity_reporter — tự động inject + compile EA trước khi optimize
#
import subprocess
import numpy as np
import pandas as pd
import os
import re
import configparser
import xml.etree.ElementTree as ET
import time
import shutil
import sys
import threading
import queue
from pathlib import Path
from datetime import datetime

symbol_startyear = {
    "AUDCAD": "2007",
    "AUDCHF": "2007",
    "AUDJPY": "2004",
    "AUDNZD": "2009",
    "AUDUSD": "2004",
    "CADCHF": "2007",
    "CADJPY": "2005",
    "CHFJPY": "2004",
    "EURAUD": "2006",
    "EURCAD": "2006",
    "EURCHF": "2004",
    "EURGBP": "2004",
    "EURJPY": "2004",
    "EURNZD": "2007",
    "EURUSD": "2004",
    "GBPAUD": "2007",
    "GBPCAD": "2007",
    "GBPCHF": "2004",
    "GBPJPY": "2004",
    "GBPNZD": "2007",
    "GBPUSD": "2004",
    "NZDUSD": "2005",
    "USDCAD": "2004",
    "USDCHF": "2004",
    "USDJPY": "2004",
}

BASE_DIR = Path(__file__).resolve().parent
INPUT_INI_PATH = BASE_DIR / 'input.ini'
CONFIG_INI_PATH = BASE_DIR / 'config.ini'
STATE_TXT_PATH = BASE_DIR / 'state.txt'
MT5_LOCAL_CONFIG_PATH = BASE_DIR / 'mt5_paths.ini'
DEFAULT_MT5_PROGRAM_PATH = r'C:\Program Files\MetaTrader 5\terminal64.exe'

# ============================================================
#  INJECT EQUITY REPORTER (merged from inject_equity_reporter.py)
# ============================================================

EQUITY_BLOCK = r"""
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
   //--- INJECT_INPUTS_HERE ---
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
"""


def _inj_find_func_open_brace(source: str, pattern: str):
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


def _inj_inject_after(source: str, brace_pos: int, code: str) -> str:
    return source[:brace_pos + 1] + '\n' + code + source[brace_pos + 1:]


def _inj_insert_block(source: str) -> str:
    # 1. Đọc file input.ini siêu an toàn (chống lỗi font BOM)
    inputs_code = "   // --- THONG SO EA TU DONG --- \n"
    try:
        import configparser
        cfg = configparser.ConfigParser()
        cfg.optionxform = str
        # Đọc bằng utf-8-sig để triệt tiêu mọi lỗi ẩn của file text
        with open(str(INPUT_INI_PATH), 'r', encoding='utf-8-sig') as f:
            cfg.read_file(f)
        if cfg.has_section('TesterInputs'):
            for key, val in cfg.items('TesterInputs'):
                if ' ' not in key:
                    # Trở lại dùng ép kiểu (string) vạn năng, loại bỏ GlobalVariableGet
                    inputs_code += f'   FileWrite(fh, "{key}=" + (string){key});\n'
    except Exception as e:
        print(f"Lỗi đọc input: {e}")

    # 2. Thay thế điểm neo thành code in thông số
    block = EQUITY_BLOCK.replace('//--- INJECT_INPUTS_HERE ---', inputs_code)

    # 3. TẠO KHAI BÁO TRƯỚC (FORWARD DECLARATIONS) NHÉT LÊN ĐẦU FILE
    forward_decls = "\n//--- FORWARD DECLARATIONS (Chong loi Compile) ---\n"
    forward_decls += "void _er_OnInit();\n"
    forward_decls += "void _er_OnTick(datetime t, int magic=-1);\n"
    forward_decls += "double _er_OnTester(const string fp, int magic=-1);\n"
    forward_decls += "//------------------------------------------------\n"

    # Tìm vị trí ngay dưới #include để nhét Khai báo trước vào
    import re
    includes = list(re.finditer(r'^[ \t]*#(include|property)\b.*$', source, re.MULTILINE))
    if includes:
        pos = includes[-1].end()
        source = source[:pos] + '\n' + forward_decls + source[pos:]
    else:
        source = forward_decls + '\n' + source

    # 4. ĐẨY TOÀN BỘ KHỐI LỆNH (BLOCK) XUỐNG ĐÁY FILE
    # Nằm ở đây, nó sẽ "thấy" toàn bộ các biến input (Lot, TP, MA...) của EA!
    return source + '\n\n//--- INJECTED BY PYTHON (BOTTOM) ---\n' + block + '\n'

def inject_ea(mq5_path: Path, magic: int) -> bool:
    """Inject equity reporter vào file .mq5. Trả về True nếu inject mới, False nếu skip/lỗi."""
    if not mq5_path.exists():
        return False
    try:
        source = mq5_path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        source = mq5_path.read_text(encoding='latin-1')

    if '_er_OnTick' in source or '_er_equity_day' in source:
        return False  # đã inject rồi (SKIP)

    source = _inj_insert_block(source)

    brace = _inj_find_func_open_brace(source, r'\bint\s+OnInit\s*\([^)]*\)')
    if brace is not None:
        source = _inj_inject_after(source, brace, '   _er_OnInit();\n')

    ms = f', {magic}' if magic >= 0 else ''
    tick_code = f'   _er_OnTick(TimeCurrent(){ms});\n'
    brace = _inj_find_func_open_brace(source, r'\bvoid\s+OnTick\s*\([^)]*\)')
    if brace is not None:
        source = _inj_inject_after(source, brace, tick_code)
    else:
        brace = _inj_find_func_open_brace(source, r'\bvoid\s+OnBar\s*\([^)]*\)')
        if brace is not None:
            source = _inj_inject_after(source, brace, tick_code)

    prefix = '_Symbol + "_" + _er_TFToText((ENUM_TIMEFRAMES)_Period)'
    # Nâng cấp bộ lọc để nhận diện được cả OnTester() lẫn OnTester(void)
    if re.search(r'\bOnTester\s*\([^)]*\)', source):
        brace = _inj_find_func_open_brace(source, r'\bdouble\s+OnTester\s*\([^)]*\)')
        if brace is not None:
            source = _inj_inject_after(source, brace, f'   _er_OnTester({prefix}{ms});\n')
    else:
        source = source.rstrip() + f'\ndouble OnTester()\n  {{\n   return _er_OnTester({prefix}{ms});\n  }}\n'

    out_path = mq5_path.parent / (mq5_path.stem + '_XYZ.mq5')
    out_path.write_text(source, encoding='utf-8')
    return True


def find_metaeditor_path(mt5_program_path: str) -> str:
    """Tìm metaeditor64.exe cạnh terminal64.exe."""
    editor = Path(mt5_program_path).parent / 'metaeditor64.exe'
    return str(editor) if editor.exists() else None


def compile_mq5(metaeditor_path: str, mq5_path: Path) -> bool:
    """Compile file .mq5 bằng MetaEditor. Trả về True nếu thành công."""
    log(f'[Inject] Compiling: {mq5_path.name} ...')
    ex5_path = mq5_path.with_suffix('.ex5')
    # Xóa .ex5 cũ để phân biệt compile mới thành công hay không
    if ex5_path.exists():
        try:
            ex5_path.unlink()
        except Exception:
            pass
    # Dùng shell=True với inner quotes để xử lý tên file có khoảng trắng
    # (MetaEditor parse argument /compile:path nội bộ và split tại space nếu không có quotes)
    cmd = f'"{metaeditor_path}" /compile:"{mq5_path}" /log'
    subprocess.call(cmd, shell=True)
    # MetaEditor có thể spawn process con — chờ tối đa 30s cho .ex5 xuất hiện
    for _ in range(30):
        if ex5_path.exists():
            log(f'[Inject] Compile OK: {ex5_path.name}')
            return True
        time.sleep(1)
    log(f'[Inject] Compile FAIL: {mq5_path.name} — không tìm thấy .ex5 sau 30s')
    return False


def get_inject_magic(input_cfg) -> int:
    """Đọc magic number để inject. Ưu tiên [Tester] inject_magic, rồi TesterInputs."""
    if input_cfg.has_option('Tester', 'inject_magic'):
        try:
            return int(input_cfg.get('Tester', 'inject_magic'))
        except ValueError:
            pass
    if input_cfg.has_section('TesterInputs'):
        for key, val in input_cfg.items('TesterInputs'):
            if 'magic' in key.lower():
                try:
                    # format MT5: "value||min||max||step||use"
                    return int(val.split('||')[0].strip())
                except (ValueError, IndexError):
                    pass
    return -1


def maybe_inject_and_compile(input_cfg, mt5_folder_path: Path, mt5_program_path: str) -> bool:
    expert_val = input_cfg.get('Tester', 'expert')
    expert_base = expert_val
    if expert_base.lower().endswith('.ex5') or expert_base.lower().endswith('.mq5'):
        expert_base = expert_base[:-4]
    if expert_base.endswith('_XYZ'): return True

    expert_stem = expert_val
    if expert_stem.lower().endswith('.ex5'): expert_stem = expert_stem[:-4]
    elif expert_stem.lower().endswith('.mq5'): expert_stem = expert_stem[:-4]
    mq5_path = mt5_folder_path / 'MQL5' / (expert_stem + '.mq5')
    if not mq5_path.exists():
        fallback = mt5_folder_path / 'MQL5' / 'Experts' / (expert_stem + '.mq5')
        if fallback.exists(): mq5_path = fallback
        else: return False

    ebr_path = mq5_path.parent / (mq5_path.stem + '_XYZ.mq5')
    ex5_path = ebr_path.with_suffix('.ex5')
    magic = get_inject_magic(input_cfg)

    # --- TỰ ĐỘNG TRẢM FILE CŨ ĐỂ ÉP TOOL TIÊM CODE MỚI ---
    if ebr_path.exists():
        try: ebr_path.unlink()
        except: pass
    if ex5_path.exists():
        try: ex5_path.unlink()
        except: pass

    # Tiêm code mới nhất
    inject_ea(mq5_path, magic)

    metaeditor_path = find_metaeditor_path(mt5_program_path)
    if not metaeditor_path: return False
    if not compile_mq5(metaeditor_path, ebr_path): return False

    new_expert = expert_val[:-4] + '_XYZ.ex5' if expert_val.lower().endswith('.ex5') else expert_val + '_XYZ'
    input_cfg.set('Tester', 'expert', new_expert)
    return True

    # Tìm file .mq5 — strip .ex5 nếu user để nguyên đuôi trong input.ini
    expert_stem = expert_val
    if expert_stem.lower().endswith('.ex5'):
        expert_stem = expert_stem[:-4]
    elif expert_stem.lower().endswith('.mq5'):
        expert_stem = expert_stem[:-4]
    mq5_path = mt5_folder_path / 'MQL5' / (expert_stem + '.mq5')
    if not mq5_path.exists():
        # Thử thêm prefix Experts\ nếu chưa có (MT5 lưu EA trong MQL5\Experts\)
        fallback = mt5_folder_path / 'MQL5' / 'Experts' / (expert_stem + '.mq5')
        if fallback.exists():
            mq5_path = fallback
            log(f'[Inject] Tìm thấy tại Experts\\: {mq5_path.name}')
        else:
            log(f'[Inject] Không tìm thấy .mq5: {mq5_path}')
            log(f'[Inject] Đã thử thêm tiền tố Experts\\, cũng không thấy: {fallback}')
            log(f'[Inject] Kiểm tra lại expert= trong input.ini (đường dẫn tương đối từ MQL5\\)')
            return False

    ebr_path = mq5_path.parent / (mq5_path.stem + '_XYZ.mq5')
    ex5_path = ebr_path.with_suffix('.ex5')

    magic = get_inject_magic(input_cfg)

    BUILTIN_MARKERS = ['CalculateCustomSharpe', 'WriteEquityDayFile', 'WriteStatsReportFile', 'SaveDailyEquity']

    # Inject nếu _EBR chưa tồn tại hoặc chưa được inject
    need_compile = True
    if ebr_path.exists():
        try:
            content = ebr_path.read_text(encoding='utf-8', errors='replace')
            already_injected = '_er_OnTick' in content or '_er_equity_day' in content
            has_builtin = all(m in content for m in BUILTIN_MARKERS)
            if already_injected or has_builtin:
                log(f'[Inject] {ebr_path.name} đã inject sẵn, bỏ qua inject.')
                if ex5_path.exists():
                    log(f'[Inject] {ex5_path.name} đã tồn tại, bỏ qua compile.')
                    need_compile = False
            else:
                log(f'[Inject] {ebr_path.name} tồn tại nhưng chưa inject — inject lại.')
                inject_ea(mq5_path, magic)
        except Exception:
            inject_ea(mq5_path, magic)
    else:
        # Check source gốc xem đã có built-in equity reporter chưa
        try:
            src = mq5_path.read_text(encoding='utf-8', errors='replace')
            has_builtin_src = all(m in src for m in BUILTIN_MARKERS)
        except Exception:
            has_builtin_src = False

        if has_builtin_src:
            log(f'[Inject] {mq5_path.name} đã có equity reporter sẵn — copy as-is.')
            ebr_path.write_text(src, encoding='utf-8')
            log(f'[Inject] Đã tạo: {ebr_path.name}')
        else:
            log(f'[Inject] Injecting {mq5_path.name} (magic={magic if magic >= 0 else "none"}) ...')
            inject_ea(mq5_path, magic)
            log(f'[Inject] Đã tạo: {ebr_path.name}')

    if need_compile:
        metaeditor_path = find_metaeditor_path(mt5_program_path)
        if not metaeditor_path:
            log(f'[Inject] Không tìm thấy metaeditor64.exe cạnh {mt5_program_path}')
            return False
        if not compile_mq5(metaeditor_path, ebr_path):
            return False

    # Cập nhật Expert trong memory → dùng cho tất cả jobs
    # Chèn _XYZ trước .ex5 (hoặc thêm vào cuối nếu không có đuôi)
    if expert_val.lower().endswith('.ex5'):
        new_expert = expert_val[:-4] + '_XYZ.ex5'
    else:
        new_expert = expert_val + '_XYZ'
    input_cfg.set('Tester', 'expert', new_expert)
    log(f'[Inject] Expert cập nhật: {new_expert}')
    return True

# ============================================================
#  END: Inject section
# ============================================================


def log(message):
    print(message, flush=True)


def ask_yes_no(prompt):
    while True:
        answer = input(f"{prompt} (yes/no): ").strip().lower()
        if answer in ('yes', 'y'):
            return True
        if answer in ('no', 'n'):
            return False
        log('Vui lòng nhập yes hoặc no.')


def ensure_input_exists():
    if not INPUT_INI_PATH.exists():
        log(f'Không tìm thấy file input.ini: {INPUT_INI_PATH}')
        sys.exit(1)


def read_input_config():
    input_cfg = configparser.ConfigParser()
    input_cfg.optionxform = str  # preserve case of keys
    input_cfg.read(INPUT_INI_PATH, encoding='utf-8')
    return input_cfg


def show_input_ini_and_confirm():
    log('===== INPUT.INI =====')
    content = INPUT_INI_PATH.read_text(encoding='utf-8', errors='replace')
    print(content, flush=True)
    log('=====================')
    if not ask_yes_no('Bạn có chắc chắn với input này không?'):
        log('Người dùng chọn NO. Dừng tool.')
        sys.exit(0)


def detect_terminal_candidates():
    base_terminal_dir = Path(os.environ.get('APPDATA', '')) / 'MetaQuotes' / 'Terminal'
    candidates = []
    if not base_terminal_dir.exists():
        return candidates

    for folder in base_terminal_dir.iterdir():
        if not folder.is_dir():
            continue
        if folder.name.lower() in ('common', 'community'):
            continue
        if (folder / 'origin.txt').exists() and (folder / 'MQL5').exists():
            candidates.append(folder)
    return candidates


def build_mt5_paths_from_hash(mt5_hash):
    appdata = Path(os.environ.get('APPDATA', ''))
    mt5_folder_path = appdata / 'MetaQuotes' / 'Terminal' / mt5_hash
    mt5_tester_path = appdata / 'MetaQuotes' / 'Tester' / mt5_hash
    reports_path = mt5_folder_path / 'reports'
    return mt5_folder_path, mt5_tester_path, reports_path


def save_mt5_local_config(mt5_hash, mt5_program_path):
    cfg = configparser.ConfigParser()
    cfg['MT5'] = {
        'hash': mt5_hash,
        'mt5_program_path': mt5_program_path,
    }
    with open(MT5_LOCAL_CONFIG_PATH, 'w', encoding='utf-8') as f:
        cfg.write(f)


def load_mt5_local_config():
    if not MT5_LOCAL_CONFIG_PATH.exists():
        return None
    cfg = configparser.ConfigParser()
    cfg.read(MT5_LOCAL_CONFIG_PATH, encoding='utf-8')
    if not cfg.has_section('MT5'):
        return None
    mt5_hash = cfg.get('MT5', 'hash', fallback='').strip()
    mt5_program_path = cfg.get('MT5', 'mt5_program_path', fallback=DEFAULT_MT5_PROGRAM_PATH).strip()
    if not mt5_hash:
        return None
    return mt5_hash, mt5_program_path


def load_mt5_from_input_ini():
    """Đọc [MT5] section từ input.ini.
    Hỗ trợ nhiều terminal qua terminal_hashes / mt5_program_paths (comma-separated).
    Backward compatible với terminal_hash đơn lẻ.
    Trả về list of (hash, program_path) hoặc None.
    """
    if not INPUT_INI_PATH.exists():
        return None
    cfg = configparser.ConfigParser()
    cfg.read(INPUT_INI_PATH, encoding='utf-8')
    if not cfg.has_section('MT5'):
        return None

    # Thử đọc dạng nhiều terminal: terminal_hashes (comma-separated)
    hashes_raw = cfg.get('MT5', 'terminal_hashes', fallback='').strip()
    paths_raw  = cfg.get('MT5', 'mt5_program_paths', fallback='').strip()

    if hashes_raw:
        hashes = [h.strip() for h in hashes_raw.split(',') if h.strip()]
        paths  = [p.strip() for p in paths_raw.split(',') if p.strip()]
        # Nếu chỉ có 1 path, dùng chung cho tất cả
        if len(paths) == 1:
            paths = paths * len(hashes)
        elif len(paths) < len(hashes):
            paths += [DEFAULT_MT5_PROGRAM_PATH] * (len(hashes) - len(paths))
        return list(zip(hashes, paths))

    # Backward compatible: terminal_hash đơn lẻ
    mt5_hash = cfg.get('MT5', 'terminal_hash', fallback='').strip()
    mt5_program_path = cfg.get('MT5', 'mt5_program_path', fallback=DEFAULT_MT5_PROGRAM_PATH).strip()
    if mt5_hash:
        return [(mt5_hash, mt5_program_path)]
    return None


def setup_mt5_paths():
    """Trả về list of (mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path)."""
    # Ưu tiên đọc từ input.ini [MT5] trước
    from_ini = load_mt5_from_input_ini()
    if from_ini is not None:
        terminals = []
        for mt5_hash, mt5_program_path in from_ini:
            mt5_folder_path, mt5_tester_path, reports_path = build_mt5_paths_from_hash(mt5_hash)
            if mt5_folder_path.exists() and mt5_tester_path.exists() and Path(mt5_program_path).exists():
                log(f'Dùng MT5 từ input.ini [MT5]: {mt5_hash}')
                terminals.append((mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path))
            else:
                log(f'[MT5] hash={mt5_hash} không hợp lệ, bỏ qua.')
        if terminals:
            return terminals
        log('[MT5] trong input.ini không có terminal hợp lệ. Sẽ dùng mt5_paths.ini.')

    saved = load_mt5_local_config()
    if saved is not None:
        mt5_hash, mt5_program_path = saved
        mt5_folder_path, mt5_tester_path, reports_path = build_mt5_paths_from_hash(mt5_hash)
        if mt5_folder_path.exists() and mt5_tester_path.exists() and Path(mt5_program_path).exists():
            log(f'Đã dùng cấu hình MT5 đã lưu: {mt5_hash}')
            return [(mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path)]
        log('Cấu hình MT5 đã lưu không còn hợp lệ. Sẽ cấu hình lại.')

    log('Đây là lần đầu chạy tool trên máy này (hoặc chưa có cấu hình MT5 hợp lệ).')
    log('Chọn cách cấu hình path MT5:')
    log('1. Auto-detect')
    log('2. Tự điền hash thư mục MT5 (ví dụ: D0E8209F77C8CF37AD8BF550E51FF075)')

    while True:
        choice = input('Nhập lựa chọn (1/2): ').strip()
        if choice in ('1', '2'):
            break
        log('Vui lòng nhập 1 hoặc 2.')

    mt5_program_path = DEFAULT_MT5_PROGRAM_PATH
    if choice == '1':
        candidates = detect_terminal_candidates()
        if not candidates:
            log('Không auto-detect được MT5 terminal. Hãy chạy lại và chọn cách 2.')
            sys.exit(1)
        if len(candidates) == 1:
            selected = candidates[0]
        else:
            log('Tìm thấy nhiều terminal candidate:')
            for idx, candidate in enumerate(candidates, start=1):
                log(f'{idx}. {candidate}')
            while True:
                pick = input(f'Chọn terminal (1-{len(candidates)}): ').strip()
                if pick.isdigit() and 1 <= int(pick) <= len(candidates):
                    selected = candidates[int(pick) - 1]
                    break
                log('Lựa chọn không hợp lệ.')
        mt5_hash = selected.name
    else:
        while True:
            mt5_hash = input('Nhập hash MT5 folder: ').strip()
            if mt5_hash:
                break
            log('Hash không được để trống.')

    mt5_folder_path, mt5_tester_path, reports_path = build_mt5_paths_from_hash(mt5_hash)
    if not mt5_folder_path.exists():
        log(f'Không tìm thấy mt5_folder_path: {mt5_folder_path}')
        sys.exit(1)
    if not mt5_tester_path.exists():
        log(f'Không tìm thấy mt5_tester_path: {mt5_tester_path}')
        sys.exit(1)
    if not Path(mt5_program_path).exists():
        log(f'Không tìm thấy terminal64.exe: {mt5_program_path}')
        sys.exit(1)

    save_mt5_local_config(mt5_hash, mt5_program_path)
    log(f'Đã lưu cấu hình MT5 vào: {MT5_LOCAL_CONFIG_PATH}')
    return [(mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path)]


def maybe_clear_state_and_reports(reports_path):
    if ask_yes_no('Bạn có muốn xóa state.txt và tất cả file trong reports folder không?'):
        if STATE_TXT_PATH.exists():
            STATE_TXT_PATH.unlink()
            log(f'Đã xóa: {STATE_TXT_PATH}')
        reports_path.mkdir(parents=True, exist_ok=True)
        removed = 0
        for item in reports_path.iterdir():
            if item.is_dir():
                shutil.rmtree(item)
            else:
                item.unlink()
            removed += 1
        log(f'Đã xóa {removed} item trong reports folder.')
    else:
        log('Giữ nguyên state.txt và reports folder.')


def build_input_symbols_period(input_cfg):
    # Nếu state.txt đã tồn tại → tiếp tục từ danh sách còn lại (resume)
    if STATE_TXT_PATH.exists():
        remaining = np.loadtxt(STATE_TXT_PATH, dtype=str)
        if remaining.ndim == 0:
            remaining = np.array([str(remaining)])
        if len(remaining) > 0:
            log(f'Tìm thấy state.txt — tiếp tục {len(remaining)} job còn lại.')
            return remaining
    # Tạo mới từ input.ini
    input_symbols_period = np.array([])
    get_symbols = input_cfg.get('Symbols', 'symbols').split(',')
    get_symbols = [s.strip() for s in get_symbols if s.strip()]
    get_period = input_cfg.get('Tester', 'period').split(',')
    get_period = [s.strip() for s in get_period if s.strip()]
    for symbol in get_symbols:
        for period in get_period:
            input_symbols_period = np.append(input_symbols_period, symbol + '_' + period)
    np.savetxt(STATE_TXT_PATH, input_symbols_period, fmt='%s')
    return input_symbols_period


import configparser
from datetime import datetime

def copy_agent_outputs(mt5_tester_path, reports_path, symbol_period=None):
    def read_file_safe(filepath):
        try:
            with open(filepath, 'r', encoding='utf-16') as f: return f.read()
        except:
            with open(filepath, 'r', encoding='utf-8-sig', errors='ignore') as f: return f.read()

    ea_name = "EA"
    try:
        cfg = configparser.ConfigParser()
        cfg.read('input.ini', encoding='utf-8')
        if cfg.has_section('Tester') and cfg.has_option('Tester', 'expert'):
            ea_val = cfg.get('Tester', 'expert')
            ea_name = ea_val.split('.ex5')[0].replace('_XYZ', '').replace('\\', '/').split('/')[-1]
    except Exception: pass

    allfolderfile = os.listdir(mt5_tester_path)
    copied_csv = 0
    copied_txt = 0

    target_dir = os.path.join(reports_path, 'agents', symbol_period) if symbol_period else os.path.join(reports_path, 'agents')
    os.makedirs(target_dir, exist_ok=True)

    # --- BƯỚC 1: Thu thập tất cả file CSV từ mọi Agent ---
    all_csv_entries = []  # list of (mtime, csv_filename, filepath, foldername)
    for foldername in allfolderfile:
        if 'Agent' not in foldername: continue
        filepath = os.path.join(mt5_tester_path, foldername, 'MQL5', 'Files')
        if not os.path.isdir(filepath): continue
        for csv_filename in os.listdir(filepath):
            if not csv_filename.lower().endswith('.csv'): continue
            source_csv = os.path.join(filepath, csv_filename)
            mtime = os.path.getmtime(source_csv)
            all_csv_entries.append((mtime, csv_filename, filepath, foldername))

    # --- BƯỚC 2: Sort theo thời gian chỉnh sửa (file xong trước → Pass nhỏ hơn) ---
    all_csv_entries.sort(key=lambda x: (x[0], x[1]))

    # --- BƯỚC 3: Xử lý từng file theo thứ tự, đánh Pass tuần tự ---
    for pass_seq, (mtime, csv_filename, filepath, foldername) in enumerate(all_csv_entries, start=1):
        source_csv = os.path.join(filepath, csv_filename)
        csv_content = read_file_safe(source_csv)
        if not csv_content: continue

        files_in_dir = os.listdir(filepath)
        txt_filename = csv_filename[:-15] + "_report.txt" if "_equity_day.csv" in csv_filename.lower() else os.path.splitext(csv_filename)[0] + ".txt"

        params = {}
        if txt_filename in files_in_dir:
            txt_content = read_file_safe(os.path.join(filepath, txt_filename))
            if txt_content:
                for line in txt_content.splitlines():
                    if '=' in line:
                        parts = line.split('=', 1)
                        key = parts[0].strip().lower()
                        val = parts[1].strip()
                        params[key] = val
                copied_txt += 1

        symbol = params.get('symbol', 'Unknown')
        timeframe = params.get('timeframe', 'TF')
        now_str = datetime.fromtimestamp(mtime).strftime("%Y%m%d_%H%M%S")

        new_filename = f"{ea_name}_{symbol}_{timeframe}_{now_str}_Pass{pass_seq}_equity_day.csv"

        try:
            with open(os.path.join(target_dir, new_filename), 'w', encoding='utf-8-sig') as f_out:
                # Header chuẩn CSV 3 cột
                f_out.write("type,key,value\n")
                # Phần stats từ _report.txt
                for k, v in params.items():
                    f_out.write(f"stats,{k},{v}\n")
                # Dòng trống tách biệt 2 phần
                f_out.write(",,,\n")
                # Phần equity từ _equity_day.csv
                for line in csv_content.splitlines():
                    line = line.replace('\t', ',').strip()
                    if not line: continue
                    if line.lower().startswith('date'): continue  # bỏ header gốc
                    parts = line.split(',', 1)
                    if len(parts) == 2:
                        f_out.write(f"equity,{parts[0].strip()},{parts[1].strip()}\n")
            copied_csv += 1
        except Exception as e:
            print(f'Lỗi gộp: {e}')

    return copied_csv, copied_txt


def convert_xml_to_xlsx(opt_report_path, target_path):
    input_data = ET.parse(opt_report_path)
    root = input_data.getroot()
    prefix = '{urn:schemas-microsoft-com:office:spreadsheet}'
    row = 0
    data = []
    for child in root.iter(prefix + 'Row'):
        row += 1
    for child in root.iter(prefix + 'Data'):
        data.append(child.text)
    collume = len(data) // row
    num = np.array(data)
    reshaped = num.reshape(row, collume)
    df = pd.DataFrame(reshaped)
    df.to_excel(target_path, header=False, index=False)
    os.remove(opt_report_path)


def run_one_job(terminal_idx, mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path,
                input_cfg, job_queue, state_lock, total_jobs, completed_counter, stop_event):
    """Worker chạy trên 1 MT5 terminal, lấy job từ queue cho đến hết."""
    symbol_subfix = input_cfg.get('Symbols', 'subfix')
    model = input_cfg.get('Tester', 'model')
    model_name = model
    if model == '4':
        model_name = 'EBR'
    elif model == '1':
        model_name = '1OHLC'
    elif model == '2':
        model_name = 'OPO'

    # Mỗi terminal dùng config file riêng để tránh xung đột
    config_path = BASE_DIR / f'config_{terminal_idx}.ini'

    while not stop_event.is_set():
        try:
            symbol_period = job_queue.get_nowait()
        except queue.Empty:
            break

        parts = symbol_period.split('_')
        symbol = parts[0]
        period = parts[1]

        with state_lock:
            completed_counter[0] += 1
            job_num = completed_counter[0]
        log(f'[Terminal {terminal_idx}] [{job_num}/{total_jobs}] Running optimize: {symbol} {period}')

        from_date = input_cfg.get('Tester', 'fromdate')
        if from_date == '0':
            from_date = symbol_startyear.get(symbol, '2004') + '.01.01'
        todate = input_cfg.get('Tester', 'todate')

        report_filename = f'opt_{symbol}{symbol_subfix}_{period}_{from_date}_{todate}_{model_name}'
        report_path_for_ini = '\\' + os.path.join('reports', report_filename)

        # Leverage: "1:100" → "100" (MT5 chỉ nhận số, không nhận format "1:100")
        leverage_raw = input_cfg.get('Tester', 'leverage', fallback='100')
        leverage_val = leverage_raw.split(':')[-1] if ':' in leverage_raw else leverage_raw

        # Ghi config thủ công: không có spaces quanh =, không có [Common] section
        # để giống hệt format MT5 profile files
        with open(config_path, 'w', encoding='utf-8') as f:
            f.write('[Tester]\n')
            f.write(f'Expert={input_cfg.get("Tester", "expert")}\n')
            f.write(f'Symbol={symbol}{symbol_subfix}\n')
            f.write(f'Period={period}\n')
            f.write(f'Login={input_cfg.get("Tester", "login", fallback="123456")}\n')
            f.write(f'Deposit={input_cfg.get("Tester", "deposit")}\n')
            f.write(f'Leverage={leverage_val}\n')
            f.write(f'Model={model}\n')
            f.write(f'ExecutionMode={input_cfg.get("Tester", "executionmode", fallback="1")}\n')
            f.write(f'Optimization={input_cfg.get("Tester", "optimization", fallback="1")}\n')
            f.write(f'OptimizationCriterion={input_cfg.get("Tester", "optimizationcriterion")}\n')
            f.write(f'FromDate={from_date}\n')
            f.write(f'ToDate={todate}\n')
            f.write(f'ForwardMode=0\n')
            f.write(f'Report={report_path_for_ini}\n')
            f.write(f'ReplaceReport={input_cfg.get("Tester", "replacereport", fallback="1")}\n')
            f.write(f'ShutDownTerminal={input_cfg.get("Tester", "shutdownterminal", fallback="1")}\n')
            f.write('[TesterInputs]\n')
            for key, val in input_cfg.items('TesterInputs'):
                f.write(f'{key}={val}\n')

        log(f'[Terminal {terminal_idx}] Launching MT5: {mt5_program_path}')
        subprocess.call([mt5_program_path, '/config:' + str(config_path)])

        opt_report_path = reports_path / f'{report_filename}.xml'
        target_path     = reports_path / f'{report_filename}.xlsx'

        if opt_report_path.exists():
            convert_xml_to_xlsx(opt_report_path, target_path)
            copied_csv, copied_txt = copy_agent_outputs(mt5_tester_path, reports_path, f'{symbol}{symbol_subfix}_{period}')
            log(f'[Terminal {terminal_idx}] Done: {symbol} {period} | csv={copied_csv} txt={copied_txt}')
            # Cập nhật state.txt ngay sau khi job hoàn thành (an toàn khi tắt máy đột ngột)
            with state_lock:
                remaining = []
                try:
                    while True:
                        remaining.append(job_queue.get_nowait())
                except queue.Empty:
                    pass
                for item in remaining:
                    job_queue.put(item)
                if remaining:
                    np.savetxt(STATE_TXT_PATH, remaining, fmt='%s')
                else:
                    if STATE_TXT_PATH.exists():
                        STATE_TXT_PATH.unlink()
            time.sleep(5)
        else:
            log(f'[Terminal {terminal_idx}] FAIL: Không thấy XML report: {opt_report_path}')
            stop_event.set()
            job_queue.task_done()
            break

        job_queue.task_done()

    log(f'[Terminal {terminal_idx}] Worker kết thúc.')


def run():
    ensure_input_exists()
    input_cfg = read_input_config()
    show_input_ini_and_confirm()

    terminals = setup_mt5_paths()

    # Tự động inject + compile EA trước khi chạy optimization
    if not maybe_inject_and_compile(input_cfg, terminals[0][0], terminals[0][3]):
        log('[ERR] Inject/compile EA thất bại. Dừng lại.')
        sys.exit(1)

    # Dùng reports_path của terminal đầu tiên để clear, các terminal còn lại report vào thư mục của mình
    for mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path in terminals:
        reports_path.mkdir(parents=True, exist_ok=True)

    maybe_clear_state_and_reports(terminals[0][2])

    input_symbols_period = build_input_symbols_period(input_cfg)
    total_jobs = len(input_symbols_period)
    log(f'Tổng số job: {total_jobs} | Số MT5 terminal: {len(terminals)}')

    # Đẩy tất cả jobs vào queue
    job_q = queue.Queue()
    for sp in input_symbols_period:
        job_q.put(sp)

    state_lock = threading.Lock()
    completed_counter = [0]
    stop_event = threading.Event()

    threads = []
    for idx, (mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path) in enumerate(terminals, start=1):
        t = threading.Thread(
            target=run_one_job,
            args=(idx, mt5_folder_path, mt5_tester_path, reports_path, mt5_program_path,
                  input_cfg, job_q, state_lock, total_jobs, completed_counter, stop_event),
            daemon=True,
        )
        threads.append(t)

    log('Bắt đầu chạy...')
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    remaining = list(job_q.queue)
    if remaining:
        log(f'Còn lại {len(remaining)} job chưa chạy. Đã lưu vào state.txt.')
    else:
        log('Hoàn thành tất cả jobs!')


if __name__ == '__main__':
    run()