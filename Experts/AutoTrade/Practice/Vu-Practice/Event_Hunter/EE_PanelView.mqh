//+------------------------------------------------------------------+
//|                      EE_PanelView.mqh                            |
//| View: Status panel - 3 trạng thái                               |
//|  1. NEXT TARGET   – Tin đang rình + đếm ngược                   |
//|  2. RISK PARAMS   – Lot / SL / TP                               |
//|  3. FILTERS       – Spread live + Max Gap                       |
//+------------------------------------------------------------------+
#ifndef EE_PANEL_VIEW_MQH
#define EE_PANEL_VIEW_MQH

#include "Model/EE_Constants.mqh"
#include "Model/EE_EventModel.mqh"

//====================================================================
// LAYOUT
//====================================================================
#define EEP_X     10     // left margin (pixels from left edge)
#define EEP_Y     50     // top margin  (pixels from top edge)
#define EEP_W     275    // panel width
#define EEP_TX    14     // text indent inside panel
#define EEP_LH    18     // row line height
#define EEP_FONT  "Consolas"

// Section height:
// Sec1: header(22) + 3 rows(18×3) + gap(8) = 84
// Sec2: header(22) + 5 rows(18×5) + gap(8) = 120   (Risk%, Lot, SL, TP, Trade Mode)
// Sec3: header(22) + 3 rows(18×3) + gap(8) = 84    (+Auto Close row)
// Sec4 interactive: header(22) + 3 rows×24 + pad(6) = 100
#define EEP_SECH   84
#define EEP_SEC2H  120
#define EEP_SEC3H  84
#define EEP_SEC4H  100

//====================================================================
// COLORS
//====================================================================
#define EEP_BG       C'12,18,40'
#define EEP_HDR1     C'15,55,120'   // blue  – Next Target
#define EEP_HDR2     C'10,85,55'    // green – Risk Params
#define EEP_HDR3     C'85,45,10'    // orange – Filters
#define EEP_WHITE    clrWhite
#define EEP_YELLOW   C'255,215,60'
#define EEP_GREEN    C'70,220,100'
#define EEP_RED      C'255,75,75'
#define EEP_DIM      C'150,155,175'

//====================================================================
// CACHE – Next event (updated max once per minute on real chart)
//====================================================================
datetime g_panelNextTime     = 0;
string   g_panelNextTitle    = "";
string   g_panelNextCurrency = "";
datetime g_panelLookupAt     = 0;

//====================================================================
// PRIMITIVES
//====================================================================
void _EEPRect(string n, int x, int y, int w, int h, color bg)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,        h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,        100);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _EEPLbl(string n, int x, int y, string t, color c, int sz = 8)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, n, OBJPROP_TEXT,      t);
   ObjectSetString(0, n, OBJPROP_FONT,      EEP_FONT);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,  sz);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     c);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,    true);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,     120);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void _EEPBtn(string n, int x, int y, int w, int h, string t)
  {
   if(ObjectFind(0, n) < 0)
      ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,       h);
   ObjectSetString(0, n, OBJPROP_TEXT,       t);
   ObjectSetString(0, n, OBJPROP_FONT,       EEP_FONT);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,   10);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,    C'40,40,68');
   ObjectSetInteger(0, n, OBJPROP_COLOR,      clrWhite);
   ObjectSetInteger(0, n, OBJPROP_STATE,      false);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,      130);
  }

//====================================================================
// COUNTDOWN STRING
//====================================================================
string _EEPCountdown(datetime target)
  {
   if(target == 0)
      return "Chua tim thay";
   datetime now = TimeCurrent();
   if(target <= now)
      return "Da qua";
   int s = (int)(target - now);
   if(s >= 3600)
      return StringFormat("Con %dh %dm", s / 3600, (s % 3600) / 60);
   if(s >= 60)
      return StringFormat("Con %d phut %ds", s / 60, s % 60);
   return StringFormat("Con %d giay !!!", s);
  }

//====================================================================
// FIND NEXT MATCHING EVENT
//====================================================================
void _EEPRefreshNext()
  {
   datetime now = TimeCurrent();
// Real chart: throttle lookup to once per minute
   if(!MQLInfoInteger(MQL_TESTER) && now - g_panelLookupAt < 60 && g_panelLookupAt > 0)
      return;
   g_panelLookupAt      = now;
   g_panelNextTime      = 0;
   g_panelNextTitle     = "Khong co";
   g_panelNextCurrency  = "";

   if(MQLInfoInteger(MQL_TESTER))
     {
      // Scan sorted g_events for first future unprocessed event
      for(int i = g_nextEventIdx; i < ArraySize(g_events); i++)
        {
         if(!g_events[i].processed && g_events[i].event_time > now)
           {
            g_panelNextTime     = g_events[i].event_time;
            g_panelNextTitle    = g_events[i].title;
            g_panelNextCurrency = g_events[i].currency;
            return;
           }
        }
     }
   else
     {
      // Real chart: query MQL5 calendar for upcoming 7 days
      MqlCalendarValue values[];
      if(CalendarValueHistory(values, now, now + 7 * 24 * 3600) <= 0)
         return;
      for(int i = 0; i < ArraySize(values); i++)
        {
         if(values[i].actual_value != LONG_MIN)
            continue; // already released
         MqlCalendarEvent   ev;
         MqlCalendarCountry ct;
         if(!CalendarEventById(values[i].event_id, ev))
            continue;
         if(!CalendarCountryById(ev.country_id, ct))
            continue;
         if(InpFilterByCurrency && !IsCurrencyRelevant(ct.currency))
            continue;
         if(StringFind(ev.name, InpEventTitle) < 0)
            continue;
         if(g_panelNextTime == 0 || values[i].time < g_panelNextTime)
           {
            g_panelNextTime     = values[i].time;
            g_panelNextTitle    = ev.name;
            g_panelNextCurrency = ct.currency;
           }
        }
      if(g_panelNextTime == 0)
         g_panelNextTitle = "Khong tim thay";
     }
  }

//====================================================================
// DRAW / UPDATE PANEL  (throttled: 1 update/second, skip if no chart)
//====================================================================
void DrawEEPanel()
  {
   static datetime s_lastDraw = 0;
   datetime now = TimeCurrent();
   if(now - s_lastDraw < 1)
      return;
   s_lastDraw = now;

   _EEPRefreshNext();

   int x  = EEP_X;
   int y  = EEP_Y;
   int w  = EEP_W;
   int tx = x + EEP_TX;
   int th = EEP_SECH + EEP_SEC2H + EEP_SEC3H + EEP_SEC4H; // total panel height

// ─── Background ─────────────────────────────────────────────
   _EEPRect("EEP_bg", x, y, w, th, EEP_BG);

// ════════════════════════════════════════════════════════════
// SECTION 1 – NEXT TARGET
// ════════════════════════════════════════════════════════════
   int s1 = y;
   _EEPRect("EEP_h1", x, s1, w, 22, EEP_HDR1);
   _EEPLbl("EEP_h1t", tx, s1 + 4, "[ NEXT TARGET ]", EEP_WHITE, 9);

// Tên sự kiện (kèm currency)
   string evDisp = (g_panelNextCurrency != "")
                   ? "[" + g_panelNextCurrency + "] " + g_panelNextTitle
                   : g_panelNextTitle;
   _EEPLbl("EEP_r1k", tx,      s1 + 26, "Su kien  :", EEP_DIM,    8);
   _EEPLbl("EEP_r1v", tx + 72, s1 + 26, evDisp,       EEP_YELLOW, 8);

// Giờ tin
   string timeDisp = (g_panelNextTime > 0)
                     ? TimeToString(g_panelNextTime, TIME_DATE | TIME_MINUTES)
                     : "---";
   _EEPLbl("EEP_r2k", tx,      s1 + 44, "Gio tin  :", EEP_DIM,   8);
   _EEPLbl("EEP_r2v", tx + 72, s1 + 44, timeDisp,     EEP_WHITE, 8);

// Đếm ngược (đỏ khi còn < 5 phút)
   string cd    = _EEPCountdown(g_panelNextTime);
   color  cdClr = (g_panelNextTime > 0 && (g_panelNextTime - now) <= 300)
                  ? EEP_RED : EEP_GREEN;
   _EEPLbl("EEP_r3k", tx,      s1 + 62, "Dem nguoc:", EEP_DIM, 8);
   _EEPLbl("EEP_r3v", tx + 72, s1 + 62, cd,           cdClr,   8);

// ════════════════════════════════════════════════════════════
// SECTION 2 – RISK PARAMETERS
// ════════════════════════════════════════════════════════════
   int s2 = s1 + EEP_SECH;
   _EEPRect("EEP_h2", x, s2, w, 22, EEP_HDR2);
   _EEPLbl("EEP_h2t", tx, s2 + 4, "[ RISK PARAMETERS ]", EEP_WHITE, 9);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

// Risk %
   string riskValue;
   color  riskClr;
   if(inp_risk_percent > 0)
     {
      double riskAmt  = AccountInfoDouble(ACCOUNT_EQUITY) * inp_risk_percent / 100.0;
      string cur      = AccountInfoString(ACCOUNT_CURRENCY);
      riskValue = DoubleToString(inp_risk_percent, 1) + "%  ("
                  + DoubleToString(riskAmt, 2) + " " + cur + ")";
      riskClr = EEP_YELLOW;
     }
   else
     {
      riskValue = "Tat";
      riskClr   = EEP_DIM;
     }
   _EEPLbl("EEP_r4k", tx,      s2 + 26, "Risk %    :", EEP_DIM,  8);
   _EEPLbl("EEP_r4v", tx + 72, s2 + 26, riskValue,    riskClr,  8);

// Lot
   _EEPLbl("EEP_r4lk", tx,      s2 + 44, "Lot       :", EEP_DIM,    8);
   _EEPLbl("EEP_r4lv", tx + 72, s2 + 44, DoubleToString(g_LotSize, 2),
           (inp_risk_percent > 0) ? EEP_DIM : EEP_YELLOW, 8);

// SL
   double slPts = ask * g_SL_Percent / 100.0 / _Point;
   string slStr = DoubleToString(g_SL_Percent, 1) + "%  (" + DoubleToString(slPts, 0) + " pts)";
   _EEPLbl("EEP_r5k", tx,      s2 + 62, "Stop Loss :", EEP_DIM,    8);
   _EEPLbl("EEP_r5v", tx + 72, s2 + 62, slStr,          EEP_YELLOW, 8);

// TP
   double tpPts = slPts * g_Rate_TP_SL;
   string tpStr = "x" + DoubleToString(g_Rate_TP_SL, 1) + " SL  (" + DoubleToString(tpPts, 0) + " pts)";
   _EEPLbl("EEP_r6k", tx,      s2 + 80, "Take Profit:", EEP_DIM,    8);
   _EEPLbl("EEP_r6v", tx + 72, s2 + 80, tpStr,           EEP_YELLOW, 8);

// Trade mode (single / multi-symbol)
   string msValue;
   color  msClr;
   if(inp_multi_symbol)
     {
      msValue = (g_symbolCount > 0)
                ? "Multi (" + IntegerToString(g_symbolCount) + " syms)"
                : "Multi";
      msClr = EEP_GREEN;
     }
   else
     {
      msValue = "Single: " + _Symbol;
      msClr = EEP_DIM;
     }
   _EEPLbl("EEP_r6mk", tx,      s2 + 98, "Trade Mode :", EEP_DIM, 8);
   _EEPLbl("EEP_r6mv", tx + 72, s2 + 98, msValue,        msClr,   8);

// ════════════════════════════════════════════════════════════
// SECTION 3 – FILTERS
// ════════════════════════════════════════════════════════════
   int s3 = s2 + EEP_SEC2H;
   _EEPRect("EEP_h3", x, s3, w, 22, EEP_HDR3);
   _EEPLbl("EEP_h3t", tx, s3 + 4, "[ FILTERS ]", EEP_WHITE, 9);

// Spread (live, đổi màu)
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   double sp    = (tick.ask - tick.bid) / _Point;
   bool   spOK  = (InpMaxSpread <= 0 || sp <= InpMaxSpread);
   string spStr = DoubleToString(sp, 1) + " pts";
   if(InpMaxSpread > 0)
      spStr += "  / max " + IntegerToString(InpMaxSpread);
   spStr += spOK ? "  [OK]" : "  [!]";
   _EEPLbl("EEP_r7k", tx,      s3 + 26, "Spread    :", EEP_DIM,                8);
   _EEPLbl("EEP_r7v", tx + 72, s3 + 26, spStr, spOK ? EEP_GREEN : EEP_RED,    8);

// Max Gap
   string gapStr = (InpMaxGapPercent > 0.0)
                   ? DoubleToString(InpMaxGapPercent, 1) + "% cua TP"
                   : "Tat";
   _EEPLbl("EEP_r8k", tx,      s3 + 44, "Max Gap   :", EEP_DIM,   8);
   _EEPLbl("EEP_r8v", tx + 72, s3 + 44, gapStr,        EEP_WHITE, 8);

// Auto close (sau bao nhiêu phút)
   string closeStr = (InpCloseMinute > 0)
                     ? IntegerToString(InpCloseMinute) + " phut"
                     : "Tat";
   _EEPLbl("EEP_r8ck", tx,      s3 + 62, "Auto Close :", EEP_DIM,   8);
   _EEPLbl("EEP_r8cv", tx + 72, s3 + 62, closeStr,       EEP_WHITE, 8);

// ════════════════════════════════════════════════════════════
// SECTION 4 – ĐIỀU CHỈNH THAM SỐ  [ − ] value [ + ]
// ════════════════════════════════════════════════════════════
   int s4 = s3 + EEP_SEC3H;
   _EEPRect("EEP_h4",  x,  s4, w, 22, C'75,20,110');
   _EEPLbl("EEP_h4t", tx, s4 + 4, "[ DIEU CHINH THAM SO ]", EEP_WHITE, 9);

   int bx = tx + 68; // cột nút [−]
   int vx = tx + 93; // cột giá trị
   int px = tx + 148; // cột nút [+]
   int bw = 22;
   int bh = 18;

// Lot
   _EEPLbl("EEP_c1k",   tx, s4 + 28, "Lot      :", EEP_DIM, 8);
   _EEPBtn("EEP_bm_lot", bx, s4 + 26, bw, bh, "-");
   _EEPLbl("EEP_vl_lot", vx, s4 + 28, DoubleToString(g_LotSize, 2), EEP_YELLOW, 8);
   _EEPBtn("EEP_bp_lot", px, s4 + 26, bw, bh, "+");

// SL%
   _EEPLbl("EEP_c2k",  tx, s4 + 52, "Stop Loss:", EEP_DIM, 8);
   _EEPBtn("EEP_bm_sl", bx, s4 + 50, bw, bh, "-");
   _EEPLbl("EEP_vl_sl", vx, s4 + 52, DoubleToString(g_SL_Percent, 1) + "%", EEP_YELLOW, 8);
   _EEPBtn("EEP_bp_sl", px, s4 + 50, bw, bh, "+");

// TP×
   _EEPLbl("EEP_c3k",  tx, s4 + 76, "TP Rate  :", EEP_DIM, 8);
   _EEPBtn("EEP_bm_tp", bx, s4 + 74, bw, bh, "-");
   _EEPLbl("EEP_vl_tp", vx, s4 + 74, "x" + DoubleToString(g_Rate_TP_SL, 1), EEP_YELLOW, 8);
   _EEPBtn("EEP_bp_tp", px, s4 + 74, bw, bh, "+");

   ChartRedraw(0);
  }

//====================================================================
// POLL NÚT TRONG BACKTEST  (OnChartEvent không hoạt động lúc backtest)
// Gọi trong OnTick khi MQL_TESTER == true
//====================================================================
void PanelScanButtons()
  {
   // Bỏ qua khi Optimize – ObjectGetInteger() rất chậm, không cần UI
   if(MQLInfoInteger(MQL_OPTIMIZATION)) return;
   string btns[] = {"EEP_bm_lot","EEP_bp_lot","EEP_bm_sl","EEP_bp_sl","EEP_bm_tp","EEP_bp_tp"};
   for(int i = 0; i < ArraySize(btns); i++)
     {
      if(ObjectGetInteger(0, btns[i], OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btns[i], OBJPROP_STATE, false);
         string s = btns[i];
         if(s == "EEP_bm_lot")
           {
            g_LotSize    -= 0.01;
            if(g_LotSize    < 0.01)
               g_LotSize    = 0.01;
           }
         if(s == "EEP_bp_lot")
           {
            g_LotSize    += 0.01;
           }
         if(s == "EEP_bm_sl")
           {
            g_SL_Percent -= 0.5;
            if(g_SL_Percent < 0.5)
               g_SL_Percent = 0.5;
           }
         if(s == "EEP_bp_sl")
           {
            g_SL_Percent += 0.5;
           }
         if(s == "EEP_bm_tp")
           {
            g_Rate_TP_SL -= 0.5;
            if(g_Rate_TP_SL < 1.0)
               g_Rate_TP_SL = 1.0;
           }
         if(s == "EEP_bp_tp")
           {
            g_Rate_TP_SL += 0.5;
           }
         ObjectSetString(0, "EEP_vl_lot", OBJPROP_TEXT, DoubleToString(g_LotSize,    2));
         ObjectSetString(0, "EEP_vl_sl",  OBJPROP_TEXT, DoubleToString(g_SL_Percent, 1) + "%");
         ObjectSetString(0, "EEP_vl_tp",  OBJPROP_TEXT, "x" + DoubleToString(g_Rate_TP_SL, 1));
         ChartRedraw(0);
         return; // xử lý 1 nút mỗi tick, tránh xung đột
        }
     }
  }

//====================================================================
// XỬ LÝ CLICK NÚT [ − ] / [ + ]  (gọi trong OnChartEvent của EA chính)
//====================================================================
void PanelChartEvent(const int id, const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   bool changed = false;

// Lot: bước 0.01
   if(sparam == "EEP_bm_lot")
     {
      g_LotSize -= 0.01;
      if(g_LotSize < 0.01)
         g_LotSize = 0.01;
      changed = true;
     }
   if(sparam == "EEP_bp_lot")
     {
      g_LotSize += 0.01;
      changed = true;
     }

// SL%: bước 0.5
   if(sparam == "EEP_bm_sl")
     {
      g_SL_Percent -= 0.5;
      if(g_SL_Percent < 0.5)
         g_SL_Percent = 0.5;
      changed = true;
     }
   if(sparam == "EEP_bp_sl")
     {
      g_SL_Percent += 0.5;
      changed = true;
     }

// TP×: bước 0.5
   if(sparam == "EEP_bm_tp")
     {
      g_Rate_TP_SL -= 0.5;
      if(g_Rate_TP_SL < 1.0)
         g_Rate_TP_SL = 1.0;
      changed = true;
     }
   if(sparam == "EEP_bp_tp")
     {
      g_Rate_TP_SL += 0.5;
      changed = true;
     }

   if(changed)
     {
      // Cập nhật Section 4 tức thì, Section 2 sẽ tự refresh ở DrawEEPanel() tick tiếp
      ObjectSetString(0, "EEP_vl_lot", OBJPROP_TEXT, DoubleToString(g_LotSize,    2));
      ObjectSetString(0, "EEP_vl_sl",  OBJPROP_TEXT, DoubleToString(g_SL_Percent, 1) + "%");
      ObjectSetString(0, "EEP_vl_tp",  OBJPROP_TEXT, "x" + DoubleToString(g_Rate_TP_SL, 1));
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // nhả nút
      ChartRedraw(0);
     }
  }

//====================================================================
// CLEANUP ON DEINIT
//====================================================================
void DeleteEEPanel()
  {
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
     {
      string nm = ObjectName(0, i);
      if(StringFind(nm, "EEP_") == 0)
         ObjectDelete(0, nm);
     }
   ChartRedraw(0);
  }

#endif
//+------------------------------------------------------------------+
