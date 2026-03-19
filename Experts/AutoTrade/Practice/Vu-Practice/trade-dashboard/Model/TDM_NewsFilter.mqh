//+------------------------------------------------------------------+
//|                      TDM_NewsFilter.mqh                          |
//| Lọc tin tức: Chặn trade trong vùng tin tức quan trọng           |
//|                                                                  |
//| Real Chart → Tự động lấy từ MQL5 Economic Calendar (online)    |
//| Backtest   → Đọc file CSV từ Common\Files\ (offline)            |
//|                                                                  |
//| Cách tạo file CSV cho Backtest:                                  |
//|   Chạy script Scripts\DumpNewsCalendar.mq5 trên Real Chart      |
//|   → File tự tạo tại: Common\Files\news_data.csv                 |
//|                                                                  |
//| CSV Format (separator = dấu chấm phẩy, 6 cột):                 |
//|   THOI GIAN ; TIEN TE ; MUC DO ; SU KIEN ; THAT SU ; DU BAO    |
//|   2024.01.12 13:30 ; USD ; Cao ; Nonfarm Payrolls ; 256 ; 200   |
//|                                                                  |
//| MUC DO: Ngay le / Thap / Trung binh / Cao                       |
//|                                                                  |
//| Input liên quan (trong TDM_Constants.mqh):                      |
//|   EnableNewsFilter   → Bật/tắt toàn bộ tính năng               |
//|   NewsMinutesBefore  → Chặn bao nhiêu phút TRƯỚC giờ tin        |
//|   NewsMinutesAfter   → Chặn bao nhiêu phút SAU giờ tin          |
//|   NewsHighImpactOnly → true=Chỉ Cao | false=Trung bình + Cao    |
//|   NewsCurrencies     → VD: "USD,EUR,GBP" (phân cách bằng dấu ,)|
//|   NewsFilePath       → Tên file CSV (mặc định: news_data.csv)   |
//+------------------------------------------------------------------+
#ifndef TDM_NEWS_FILTER_MQH
#define TDM_NEWS_FILTER_MQH

#include "TDM_Constants.mqh"

// Forward declaration (defined in TDM_DCA.mqh)
void CancelAllDCAPendingOrders();

// === STATE ===
bool newsBlockActive = false;

// === STRUCT & DATA CHO BACKTEST ===
struct NewsEvent { datetime event_time; string currency; int impact; };
NewsEvent g_newsEvents[];
bool      g_newsFileLoaded = false;

//+------------------------------------------------------------------+
//| Kiểm tra currency có trong NewsCurrencies không                  |
//+------------------------------------------------------------------+
bool IsCurrencyFiltered(string currency)
  {
   string parts[];
   int n = StringSplit(NewsCurrencies, ',', parts);
   for(int i = 0; i < n; i++)
     {
      string s = parts[i];
      StringTrimLeft(s);
      StringTrimRight(s);
      if(s == currency) return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Real Trade: Dùng MQL5 Economic Calendar (tự động, không cần key) |
//+------------------------------------------------------------------+
bool IsNewsBlockedFromCalendar(datetime now)
  {
   datetime from = now - NewsMinutesAfter  * 60;
   datetime to   = now + NewsMinutesBefore * 60;

   MqlCalendarValue values[];
   int total = CalendarValueHistory(values, from, to);
   if(total <= 0)
     {
      // Uncomment dòng sau nếu muốn xem log mỗi tick (spam nhiều, dùng để debug):
      // Print("📅 Calendar: 0 sự kiện trong cửa sổ [", TimeToString(from), " → ", TimeToString(to), "]");
      return false;
     }

   for(int i = 0; i < ArraySize(values); i++)
     {
      MqlCalendarEvent  ev;
      MqlCalendarCountry ct;
      if(!CalendarEventById(values[i].event_id, ev))   continue;
      if(!CalendarCountryById(ev.country_id, ct))       continue;
      if(NewsHighImpactOnly && ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;
      if(!IsCurrencyFiltered(ct.currency))              continue;

      Print("📰 NEWS BLOCK: [", ct.currency, "] ", ev.name, " @ ", TimeToString(values[i].time));
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Backtest: Load CSV (Common/Files) một lần rồi cache vào RAM     |
//| Format: datetime;currency;impact;event (tạo bởi DumpNewsCalendar)|
//+------------------------------------------------------------------+
void LoadNewsFromFile()
  {
   if(g_newsFileLoaded) return;
   g_newsFileLoaded = true;
   ArrayResize(g_newsEvents, 0);

   // Đọc từ Common/Files (FILE_COMMON) — nơi DumpNewsCalendar.mq5 ghi vào
   int handle = FileOpen(NewsFilePath, FILE_READ|FILE_CSV|FILE_COMMON|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE)
     {
      Print("⚠️ NewsFilter: Không tìm thấy '", NewsFilePath, "' trong Common/Files/");
      Print("   → Chạy script DumpNewsCalendar.mq5 trên Real Chart để tạo file.");
      return;
     }

   ulong fileSize = FileSize(handle);
   Print("ℹ️ NewsFilter: File = ", fileSize / 1024, " KB. Đang load...");

   int count = 0;
   while(!FileIsEnding(handle))
     {
      // Đọc 6 cột: datetime ; currency ; impact_text ; event_name ; actual ; forecast
      string dtStr   = FileReadString(handle); // cột 1: thời gian
      string cur     = FileReadString(handle); // cột 2: tiền tệ
      string impStr  = FileReadString(handle); // cột 3: mức độ (Ngay le/Thap/Trung binh/Cao)
      string evName  = FileReadString(handle); // cột 4: tên sự kiện
      FileReadString(handle);                  // cột 5: thật sự (bỏ qua)
      FileReadString(handle);                  // cột 6: dự báo (bỏ qua)

      if(StringLen(dtStr) < 10) continue;

      datetime t = StringToTime(dtStr);
      if(t == 0) continue; // bỏ qua header hoặc dòng hỏng

      StringTrimLeft(cur); StringTrimRight(cur);

      // Map mức độ text → số
      int imp = 0;
      if(impStr == "Thap")        imp = 1;
      if(impStr == "Trung binh")  imp = 2;
      if(impStr == "Cao")         imp = 3;

      // Lọc theo NewsHighImpactOnly và NewsCurrencies
      if(NewsHighImpactOnly && imp < 3) continue;
      if(!IsCurrencyFiltered(cur))      continue;

      ArrayResize(g_newsEvents, count + 1);
      g_newsEvents[count].event_time = t;
      g_newsEvents[count].currency   = cur;
      g_newsEvents[count].impact     = imp;
      count++;
     }
   FileClose(handle);
   Print("✓ NewsFilter: Load ", count, " sự kiện từ '", NewsFilePath, "'");
  }

bool IsNewsBlockedFromFile(datetime now)
  {
   LoadNewsFromFile();
   datetime from = now - NewsMinutesAfter  * 60;
   datetime to   = now + NewsMinutesBefore * 60;
   for(int i = 0; i < ArraySize(g_newsEvents); i++)
      if(g_newsEvents[i].event_time >= from && g_newsEvents[i].event_time <= to)
         return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Hàm chính: trả về true nếu đang trong vùng cấm tin              |
//+------------------------------------------------------------------+
bool IsNewsBlocked()
  {
   if(!EnableNewsFilter) return false;
   datetime now = TimeCurrent();
   if(MQLInfoInteger(MQL_TESTER))
      return IsNewsBlockedFromFile(now);
   return IsNewsBlockedFromCalendar(now);
  }

//+------------------------------------------------------------------+
//| Gọi trong OnTick(): tự hủy pending khi bước vào vùng tin        |
//+------------------------------------------------------------------+
void ProcessNewsFilter()
  {
   if(!EnableNewsFilter)
     {
      static bool loggedDisabled = false;
      if(!loggedDisabled) { Print("ℹ️ NewsFilter: Đang TẮT (EnableNewsFilter=false)"); loggedDisabled=true; }
      return;
     }
   bool blocked = IsNewsBlocked();
   if(blocked && !newsBlockActive)
     {
      newsBlockActive = true;
      Print("🚫 NEWS FILTER ON: Vào vùng tin → Hủy pending orders!");
      CancelAllDCAPendingOrders();
     }
   else if(!blocked && newsBlockActive)
     {
      newsBlockActive = false;
      Print("✅ NEWS FILTER OFF: Qua vùng tin → Cho phép trade trở lại.");
     }
  }

#endif
