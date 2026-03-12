#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputCheckbox.mqh>
#include <AutoTrade/UI/UIInputDateTime.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIInputRadio.mqh>
#include <AutoTrade/UI/UITable.mqh>
#include <AutoTrade/Utils/UtilString.mqh>

class TDTabNews : public UIListener {
 private:
   int             m_x;
   int             m_y;
   int             m_width;
   int             m_height;

   datetime        m_lastUpdateTime;

   string          m_baseCurrency;
   string          m_profitCurrency;

   UIInputDateTime m_iptFromTime;
   UIInputDateTime m_iptToTime;
   string          m_objBtnStartReloadNewsListName;
   string          m_ObjBtnSaveNewsListName;

   UITable         m_table;
   int             m_tableRows;
   int             m_tableColumns;
   int             m_tablePage;

   bool            m_beforeNewsProtectionEnable;
   int             m_beforeNewsMinutes;
   bool            m_beforeNewsEnableStopNewOrder;
   bool            m_beforeNewsEnableCloseAllOrder;
   bool            m_beforeNewsEnableCloseAllPosition;
   bool            m_affterNewsProtectionEnable;

   UIInputCheckbox m_ipcBeforeNewsProtectionEnable;
   UIInputNumber   m_ipnBeforeNewsMinutes;
   UIInputCheckbox m_ipcBeforeNewsEnableStopNewOrder;
   UIInputCheckbox m_ipcBeforeNewsEnableCloseAllOrder;
   UIInputCheckbox m_ipcBeforeNewsEnableCloseAllPosition;

   UIInputCheckbox m_ipcAffterNewsProtectionEnable;

   string          m_ObjBtnSubmitName;

 public:
   TDTabNews() {}
   ~TDTabNews() {
      ObjectDelete(g_chartId, m_objBtnStartReloadNewsListName);
      ObjectDelete(g_chartId, m_ObjBtnSaveNewsListName);
      ObjectDelete(g_chartId, m_ObjBtnSubmitName);
   }

   void Initialize() {
      m_iptFromTime.SetListener(&this);
      m_iptToTime.SetListener(&this);

      m_table.SetListener(&this);

      m_ipcBeforeNewsProtectionEnable.SetListener(&this);
      m_ipnBeforeNewsMinutes.SetListener(&this);
      m_ipcBeforeNewsEnableStopNewOrder.SetListener(&this);
      m_ipcBeforeNewsEnableCloseAllOrder.SetListener(&this);
      m_ipcBeforeNewsEnableCloseAllPosition.SetListener(&this);

      m_baseCurrency   = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
      m_profitCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

      m_iptFromTime.Initialize(g_chartId, "TDTabNews_FromTime");
      m_iptToTime.Initialize(g_chartId, "TDTabNews_ToTime");
      m_objBtnStartReloadNewsListName = "Obj_TDTabNews_BtnStartReloadNewsList";
      m_ObjBtnSaveNewsListName        = "Obj_TDTabNews_BtnSaveNewsList";

      m_table.Initialize(g_chartId, "TDTabNews_Table", 5, 6);
      m_tableRows    = 5;
      m_tableColumns = 6;
      m_tablePage    = 1;

      m_table.SetZOrderBase(100);
      m_table.SetHeader(0, "Time", 110, CELL_TYPE_TEXT);
      m_table.SetHeader(1, "Cur", 40, CELL_TYPE_TEXT);
      m_table.SetHeader(2, "Important", 60, CELL_TYPE_TEXT);
      m_table.SetHeader(3, "Title", 150, CELL_TYPE_TEXT);
      m_table.SetHeader(4, "Forecast", 70, CELL_TYPE_TEXT);
      m_table.SetHeader(5, "Previous", 70, CELL_TYPE_TEXT);
      // m_table.SetHeader(6, "Actual", 50, CELL_TYPE_TEXT);

      m_ipcBeforeNewsProtectionEnable.Initialize(g_chartId, "TDTabNews_BeforeNewsProtectionEnable");
      m_ipnBeforeNewsMinutes.Initialize(g_chartId, "TDTabNews_BeforeNewsMinutes");
      m_ipcBeforeNewsEnableStopNewOrder.Initialize(
         g_chartId,
         "TDTabNews_BeforeNewsEnableStopNewOrder"
      );
      m_ipcBeforeNewsEnableCloseAllOrder.Initialize(
         g_chartId,
         "TDTabNews_BeforeNewsEnableCloseAllOrder"
      );
      m_ipcBeforeNewsEnableCloseAllPosition.Initialize(
         g_chartId,
         "TDTabNews_BeforeNewsEnableCloseAllPosition"
      );
      m_ipcAffterNewsProtectionEnable.Initialize(g_chartId, "TDTabNews_AffterNewsProtectionEnable");

      m_ObjBtnSubmitName = "Obj_TDTabNews_BtnSubmit";
   }

   virtual void listen(void *child, UI_EVENT_TYPE type, double value) override {
      if(type == UI_EVENT_CHANGE_PAGE) {
         if(child == &m_table) {
            m_tablePage = (int)value;
            RefreshTableNews();
         }
      }

      if(type == UI_EVENT_CHANGE_VALUE) {
         if(child == &m_ipcBeforeNewsProtectionEnable) {
            m_beforeNewsProtectionEnable = value == 1;
            m_ipnBeforeNewsMinutes.UpdateDisabled(value == 0);
            m_ipcBeforeNewsEnableCloseAllOrder.UpdateDisabled(value == 0);
            m_ipcBeforeNewsEnableCloseAllPosition.UpdateDisabled(value == 0);
            m_ipcBeforeNewsEnableStopNewOrder.UpdateDisabled(value == 0);
         }
         if(child == &m_ipnBeforeNewsMinutes) {
            m_beforeNewsMinutes = (int)value;
         }
         if(child == &m_ipcBeforeNewsEnableStopNewOrder) {
            m_beforeNewsEnableStopNewOrder = value == 1;
         }
         if(child == &m_ipcBeforeNewsEnableCloseAllOrder) {
            m_beforeNewsEnableCloseAllOrder = value == 1;
         }
         if(child == &m_ipcBeforeNewsEnableCloseAllPosition) {
            m_beforeNewsEnableCloseAllPosition = value == 1;
         }

         if(child == &m_ipcAffterNewsProtectionEnable) {
            m_affterNewsProtectionEnable = value == 1;
         }
         syncButtonSaveColor();
      }
   }
   int GetObjectNameList(string &objNameList[]) {
      string iptFromTimeObjNameList[];
      int    iptFromTimeObjCount = m_iptFromTime.GetObjectNameList(iptFromTimeObjNameList);
      string iptToTimeObjNameList[];
      int    iptToTimeObjCount = m_iptToTime.GetObjectNameList(iptToTimeObjNameList);

      string tableObjNameList[];
      int    tableObjCount = m_table.GetObjectNameList(tableObjNameList);

      string ipcBeforeNewsProtectionEnableObjNameList[];
      int ipcBeforeNewsProtectionEnableObjCount = m_ipcBeforeNewsProtectionEnable.GetObjectNameList(
         ipcBeforeNewsProtectionEnableObjNameList
      );
      string ipcBeforeNewsMinutesObjNameList[];
      int    ipcBeforeNewsMinutesObjCount
         = m_ipnBeforeNewsMinutes.GetObjectNameList(ipcBeforeNewsMinutesObjNameList);

      string ipcBeforeNewsEnableStopNewOrderObjNameList[];
      int    ipcBeforeNewsEnableStopNewOrderObjCount
         = m_ipcBeforeNewsEnableStopNewOrder.GetObjectNameList(
            ipcBeforeNewsEnableStopNewOrderObjNameList
         );
      string ipcBeforeNewsEnableCloseAllOrderObjNameList[];
      int    ipcBeforeNewsEnableCloseAllOrderObjCount
         = m_ipcBeforeNewsEnableCloseAllOrder.GetObjectNameList(
            ipcBeforeNewsEnableCloseAllOrderObjNameList
         );

      string ipcBeforeNewsEnableCloseAllPositionObjNameList[];
      int    ipcBeforeNewsEnableCloseAllPositionObjCount
         = m_ipcBeforeNewsEnableCloseAllPosition.GetObjectNameList(
            ipcBeforeNewsEnableCloseAllPositionObjNameList
         );

      string ipcAffterNewsProtectionEnableObjNameList[];
      int ipcAffterNewsProtectionEnableObjCount = m_ipcAffterNewsProtectionEnable.GetObjectNameList(
         ipcAffterNewsProtectionEnableObjNameList
      );

      ArrayResize(
         objNameList,
         iptFromTimeObjCount + iptToTimeObjCount + 2 + tableObjCount
            + ipcBeforeNewsProtectionEnableObjCount + ipcBeforeNewsMinutesObjCount
            + ipcBeforeNewsEnableStopNewOrderObjCount + ipcBeforeNewsEnableCloseAllOrderObjCount
            + ipcBeforeNewsEnableCloseAllPositionObjCount + ipcAffterNewsProtectionEnableObjCount
            + 1

      );
      int count = 0;
      for(int i = 0; i < iptFromTimeObjCount; i++) {
         objNameList[count++] = iptFromTimeObjNameList[i];
      }
      for(int i = 0; i < iptToTimeObjCount; i++) {
         objNameList[count++] = iptToTimeObjNameList[i];
      }
      objNameList[count++] = m_objBtnStartReloadNewsListName;
      objNameList[count++] = m_ObjBtnSaveNewsListName;

      for(int i = 0; i < tableObjCount; i++) {
         objNameList[count++] = tableObjNameList[i];
      }
      for(int i = 0; i < ipcBeforeNewsProtectionEnableObjCount; i++) {
         objNameList[count++] = ipcBeforeNewsProtectionEnableObjNameList[i];
      }
      for(int i = 0; i < ipcBeforeNewsMinutesObjCount; i++) {
         objNameList[count++] = ipcBeforeNewsMinutesObjNameList[i];
      }
      for(int i = 0; i < ipcBeforeNewsEnableStopNewOrderObjCount; i++) {
         objNameList[count++] = ipcBeforeNewsEnableStopNewOrderObjNameList[i];
      }
      for(int i = 0; i < ipcBeforeNewsEnableCloseAllOrderObjCount; i++) {
         objNameList[count++] = ipcBeforeNewsEnableCloseAllOrderObjNameList[i];
      }
      for(int i = 0; i < ipcBeforeNewsEnableCloseAllPositionObjCount; i++) {
         objNameList[count++] = ipcBeforeNewsEnableCloseAllPositionObjNameList[i];
      }
      for(int i = 0; i < ipcAffterNewsProtectionEnableObjCount; i++) {
         objNameList[count++] = ipcAffterNewsProtectionEnableObjNameList[i];
      }

      objNameList[count++] = m_ObjBtnSubmitName;

      return count;
   }

   void syncButtonSaveColor() {
      if(m_beforeNewsProtectionEnable != g_beforeNewsProtectionEnable
         || m_beforeNewsMinutes != g_beforeNewsMinutes
         || m_beforeNewsEnableStopNewOrder != g_beforeNewsEnableStopNewOrder
         || m_beforeNewsEnableCloseAllOrder != g_beforeNewsEnableCloseAllOrder
         || m_beforeNewsEnableCloseAllPosition != g_beforeNewsEnableCloseAllPosition
         || m_affterNewsProtectionEnable != g_affterNewsProtectionEnable) {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrWhite);
      } else {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrSlateGray);
      }
   }

   void OpenTab(int x, int y, int width, int height);
   void StartDraw(int x, int y, int width, int height);
   void DestroyDraw();
   void OnRealtimeRefresh();
   void OnStrategyTesterRefresh();
   void LoadNewsListByCalendar();
   bool LoadNewsListByFile();
   bool SaveNewsListToFile();
   void RefreshTableNews();
   void ClickBtnSubmit();
   void ClickBtnReloadNewsList();
   void ClickBtnSaveNewsList();
   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();

 private:
   void ForceRefreshData() {
      if((bool)MQLInfoInteger(MQL_TESTER)) {
         LoadNewsListByFile();
      } else {
         LoadNewsListByCalendar();
      }
      RefreshTableNews();
   }
};

void TDTabNews::OpenTab(int x, int y, int width, int height) {
   m_affterNewsProtectionEnable       = g_affterNewsProtectionEnable;
   m_beforeNewsProtectionEnable       = g_beforeNewsProtectionEnable;
   m_beforeNewsMinutes                = g_beforeNewsMinutes;
   m_beforeNewsEnableStopNewOrder     = g_beforeNewsEnableStopNewOrder;
   m_beforeNewsEnableCloseAllOrder    = g_beforeNewsEnableCloseAllOrder;
   m_beforeNewsEnableCloseAllPosition = g_beforeNewsEnableCloseAllPosition;

   m_lastUpdateTime                   = 0;

   StartDraw(x, y, width, height);
   ForceRefreshData();
}

void TDTabNews::StartDraw(int x, int y, int width, int height) {
   m_x                   = x;
   m_y                   = y;
   m_width               = width;
   m_height              = height;

   int      fontSize     = 10;
   int      yOffsetPanel = 0;

   datetime fromTime     = TimeCurrent();
   datetime toTime       = fromTime + 24 * 3600; // Mặc định lấy news 1 ngày tới

   if(!(bool)MQLInfoInteger(MQL_TESTER)) {
      m_iptFromTime.SetValueTime(fromTime);
      m_iptFromTime.SetLabel("From Date");
      m_iptFromTime.StartDraw(m_x + 10, m_y + yOffsetPanel, 130, fontSize - 2);

      m_iptToTime.SetValueTime(toTime);
      m_iptToTime.SetLabel("To Time");
      m_iptToTime.StartDraw(m_x + 150, m_y + yOffsetPanel, 130, fontSize - 2);

      uiCommon.CreateButton(
         g_chartId,
         m_objBtnStartReloadNewsListName,
         "Reload",
         m_x + m_width - 160,
         m_y + yOffsetPanel + 10,
         70,
         20
      );
      uiCommon.setFontSize(g_chartId, m_objBtnStartReloadNewsListName, fontSize - 2);
      uiCommon.setZOrder(g_chartId, m_objBtnStartReloadNewsListName, 200);
      uiCommon.CreateButton(
         g_chartId,
         m_ObjBtnSaveNewsListName,
         "Save",
         m_x + m_width - 80,
         m_y + yOffsetPanel + 10,
         70,
         20
      );
      uiCommon.setZOrder(g_chartId, m_ObjBtnSaveNewsListName, 100);
      uiCommon.setFontSize(g_chartId, m_ObjBtnSaveNewsListName, fontSize - 2);

      yOffsetPanel += 40;
   }

   m_table.StartDraw(x, y + yOffsetPanel);
   yOffsetPanel += m_table.GetHeight() + 5;

   // Tạo checkbox Enable Before News Protection
   m_ipcBeforeNewsProtectionEnable.SetValue(m_beforeNewsProtectionEnable);
   m_ipcBeforeNewsProtectionEnable.SetLabel("1. Enable Before News Protection");
   m_ipcBeforeNewsProtectionEnable.StartDraw(m_x + 10, m_y + yOffsetPanel, fontSize);
   m_ipcBeforeNewsProtectionEnable.SetZOrderBase(150);

   // Tạo ô nhập Minutes Before News
   m_ipnBeforeNewsMinutes.SetValue(m_beforeNewsMinutes);
   m_ipnBeforeNewsMinutes.SetLabel("Before Minutes");
   m_ipnBeforeNewsMinutes.SetDigits(0);
   m_ipnBeforeNewsMinutes.SetStep(1);
   m_ipnBeforeNewsMinutes.SetDisabled(!m_beforeNewsProtectionEnable);
   m_ipnBeforeNewsMinutes.StartDraw(m_x + m_width / 2 + 40, m_y + yOffsetPanel, 100, fontSize);

   // Tạo checkbox Stop New Order Before News
   yOffsetPanel = yOffsetPanel + 30;
   m_ipcBeforeNewsEnableStopNewOrder.SetValue(m_beforeNewsEnableStopNewOrder);
   m_ipcBeforeNewsEnableStopNewOrder.SetLabel("Stop New Order Before News");
   m_ipcBeforeNewsEnableStopNewOrder.SetDisabled(!m_beforeNewsProtectionEnable);
   m_ipcBeforeNewsEnableStopNewOrder.StartDraw(m_x + 40, m_y + yOffsetPanel, fontSize);
   m_ipcBeforeNewsEnableStopNewOrder.SetZOrderBase(150);

   // Tạo checkbox Close All Order Before News
   yOffsetPanel = yOffsetPanel + 20;
   m_ipcBeforeNewsEnableCloseAllOrder.SetValue(m_beforeNewsEnableCloseAllOrder);
   m_ipcBeforeNewsEnableCloseAllOrder.SetLabel("Close All Order Before News");
   m_ipcBeforeNewsEnableCloseAllOrder.SetDisabled(!m_beforeNewsProtectionEnable);
   m_ipcBeforeNewsEnableCloseAllOrder.StartDraw(m_x + 40, m_y + yOffsetPanel, fontSize);
   m_ipcBeforeNewsEnableCloseAllOrder.SetZOrderBase(150);

   // Tạo checkbox Close All Position Before News
   yOffsetPanel = yOffsetPanel + 20;
   m_ipcBeforeNewsEnableCloseAllPosition.SetValue(m_beforeNewsEnableCloseAllPosition);
   m_ipcBeforeNewsEnableCloseAllPosition.SetLabel("Close All Position Before News");
   m_ipcBeforeNewsEnableCloseAllPosition.SetDisabled(!m_beforeNewsProtectionEnable);
   m_ipcBeforeNewsEnableCloseAllPosition.StartDraw(m_x + 40, m_y + yOffsetPanel, fontSize);
   m_ipcBeforeNewsEnableCloseAllPosition.SetZOrderBase(150);

   // Tạo checkbox Enable Affter News Protection
   yOffsetPanel = yOffsetPanel + 40;
   m_ipcAffterNewsProtectionEnable.SetValue(m_affterNewsProtectionEnable);
   m_ipcAffterNewsProtectionEnable.SetLabel("2. Enable Affter News Protection");
   m_ipcAffterNewsProtectionEnable.StartDraw(m_x + 10, m_y + yOffsetPanel, fontSize);
   m_ipcAffterNewsProtectionEnable.SetZOrderBase(150);

   yOffsetPanel = yOffsetPanel + 65;

   // Tạo nút Submit
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnSubmitName,
      "SAVE",
      m_x + m_width / 2 - 50,
      m_y + yOffsetPanel,
      100,
      35
   );
   uiCommon.setZOrder(g_chartId, m_ObjBtnSubmitName, 100);
   syncButtonSaveColor();
}

void TDTabNews::OnRealtimeRefresh() {
   // Chỉ refresh news list mỗi 5 phút để tránh gọi API quá nhiều
   if(TimeCurrent() - m_lastUpdateTime > 300) {
      m_lastUpdateTime = TimeCurrent();
      LoadNewsListByCalendar();
      RefreshTableNews();
   }
}

void TDTabNews::OnStrategyTesterRefresh() {
   // Chỉ refresh khi openTab, vì lấy qua file thì không cần refresh nhiều lần
   // LoadNewsListByFile();
   // RefreshTableNews();
}

void TDTabNews::DestroyDraw() {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      ObjectDelete(g_chartId, objNameList[i]);
   }
}

void TDTabNews::LoadNewsListByCalendar() {
   datetime fromTime = m_iptFromTime.GetValueTime();
   datetime toTime   = m_iptToTime.GetValueTime();
   if(fromTime >= toTime) {
      MessageBox("From Time must be less than To Time", "Invalid Time Range", MB_ICONERROR);
      return;
   }

   Print(
      "•[TDTabNews.mqh:521]: Start Reload NewsList from Calendar, from: ",
      TimeToString(fromTime),
      ", to: ",
      TimeToString(toTime)
   );

   MqlCalendarValue calendarValues[];
   int              newsTotal = CalendarValueHistory(calendarValues, fromTime, toTime);

   Print("•[TDTabNews.mqh:533]: Total news events: ", newsTotal);

   ArrayResize(g_newsList, 0);

   for(int i = 0; i < newsTotal; i++) {
      MqlCalendarEvent event;
      if(!CalendarEventById(calendarValues[i].event_id, event))
         continue;

      MqlCalendarCountry country;
      if(!CalendarCountryById(event.country_id, country))
         continue;

      string currency = country.currency;
      if(currency != m_baseCurrency && currency != m_profitCurrency)
         continue;

      int newsListCount = ArraySize(g_newsList);
      ArrayResize(g_newsList, newsListCount + 1);
      g_newsList[newsListCount].time       = calendarValues[i].time;
      g_newsList[newsListCount].currency   = currency;
      g_newsList[newsListCount].title      = event.name;
      g_newsList[newsListCount].importance = event.importance;
      g_newsList[newsListCount].forecast
         = calendarValues[i].forecast_value == LONG_MIN ? 0 : calendarValues[i].forecast_value;
      g_newsList[newsListCount].previous
         = calendarValues[i].prev_value == LONG_MIN ? 0 : calendarValues[i].prev_value;
      g_newsList[newsListCount].actual
         = calendarValues[i].actual_value == LONG_MIN ? 0 : calendarValues[i].actual_value;
      g_newsList[newsListCount].digits     = event.digits;
      g_newsList[newsListCount].multiplier = event.multiplier;
      g_newsList[newsListCount].unit       = event.unit;
   }

   int newsListCount = ArraySize(g_newsList);
   for(int i = 0; i < newsListCount - 1; i++) {
      for(int j = i + 1; j < newsListCount; j++) {
         if(g_newsList[j].time < g_newsList[i].time) {
            NewsItem tmp  = g_newsList[i];
            g_newsList[i] = g_newsList[j];
            g_newsList[j] = tmp;
         }
      }
   }
}

bool TDTabNews::LoadNewsListByFile() {
   string filename = "NewsList_Test.csv";
   int    file     = FileOpen(filename, FILE_READ | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
   if(file == INVALID_HANDLE) {
      PrintFormat("Failed to open file '%s'. Error: %d", filename, GetLastError());
      return false;
   }

   // Bỏ qua header row
   FileReadString(file); // Time
   FileReadString(file); // Currency
   FileReadString(file); // Title
   FileReadString(file); // Importance
   FileReadString(file); // Forecast
   FileReadString(file); // Previous
   FileReadString(file); // Actual
   FileReadString(file); // Digits
   FileReadString(file); // Multiplier
   FileReadString(file); // Unit

   ArrayResize(g_newsList, 0);
   int count = 0;

   while(!FileIsEnding(file)) {
      // Đọc từng cell trong 1 row
      string timeStr    = FileReadString(file);
      string currency   = FileReadString(file);
      string title      = FileReadString(file);
      string importance = FileReadString(file);
      string forecast   = FileReadString(file);
      string previous   = FileReadString(file);
      string actual     = FileReadString(file);
      string digits     = FileReadString(file);
      string multiplier = FileReadString(file);
      string unit       = FileReadString(file);

      // Bỏ qua row rỗng (thường là dòng cuối file)
      if(timeStr == "")
         continue;

      // Thêm phần tử mới vào array
      ArrayResize(g_newsList, count + 1);

      g_newsList[count].time       = StringToTime(timeStr);
      g_newsList[count].currency   = currency;
      g_newsList[count].title      = title;
      g_newsList[count].importance = (ENUM_CALENDAR_EVENT_IMPORTANCE)StringToInteger(importance);
      g_newsList[count].forecast   = (long)StringToInteger(forecast);
      g_newsList[count].previous   = (long)StringToInteger(previous);
      g_newsList[count].actual     = (long)StringToInteger(actual);
      g_newsList[count].digits     = (uint)StringToInteger(digits);
      g_newsList[count].multiplier = (ENUM_CALENDAR_EVENT_MULTIPLIER)StringToInteger(multiplier);
      g_newsList[count].unit       = (ENUM_CALENDAR_EVENT_UNIT)StringToInteger(unit);

      count++;
   }

   FileClose(file);

   // Dùng FILE_COMMON
   string fullPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + filename;

   // Không dùng FILE_COMMON
   // string fullPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filename;

   PrintFormat("Imported %d news items from: %s", count, fullPath);
   return true;
}

bool TDTabNews::SaveNewsListToFile() {
   string filename = "NewsList.csv";
   // Dùng FILE_COMMON
   int file = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
   // Không dùng FILE_COMMON
   // int file = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(file == INVALID_HANDLE) {
      PrintFormat("Failed to open file '%s'. Error: %d", filename, GetLastError());
      return false;
   }
   // Header row
   FileWrite(
      file,
      "Time",
      "Currency",
      "Title",
      "Importance",
      "Forecast",
      "Previous",
      "Actual",
      "Digits",
      "Multiplier",
      "Unit"
   );
   int count = ArraySize(g_newsList);

   for(int i = 0; i < count; i++) {
      FileWrite(
         file,
         TimeToString(g_newsList[i].time, TIME_DATE | TIME_MINUTES),
         g_newsList[i].currency,
         g_newsList[i].title,
         IntegerToString(g_newsList[i].importance),
         IntegerToString(g_newsList[i].forecast),
         IntegerToString(g_newsList[i].previous),
         IntegerToString(g_newsList[i].actual),
         IntegerToString(g_newsList[i].digits),
         IntegerToString(g_newsList[i].multiplier),
         IntegerToString(g_newsList[i].unit)
      );
   }

   FileClose(file);

   // Dùng FILE_COMMON
   string fullPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + filename;

   // Không dùng FILE_COMMON
   // string fullPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filename;

   PrintFormat("Exported %d news items to: %s", count, fullPath);
   return true;
}

void TDTabNews::RefreshTableNews() {
   int newsListCount = ArraySize(g_newsList);
   m_table.setPagination(newsListCount, m_tablePage);
   for(int i = 0; i < m_tableRows; i++) {
      int newsListItemIndex = (m_tablePage - 1) * m_tableRows + i;
      if(newsListItemIndex >= newsListCount) {
         for(int j = 0; j < m_tableColumns; j++) {
            m_table.SetCell(i, j, "-", CELL_TYPE_TEXT);
         }
         continue;
      }

      m_table.SetCell(
         i,
         0,
         TimeToString(g_newsList[newsListItemIndex].time, TIME_DATE | TIME_SECONDS),
         CELL_TYPE_TEXT
      );
      m_table.SetCell(i, 1, g_newsList[newsListItemIndex].currency, CELL_TYPE_TEXT);
      m_table.SetCell(i, 2, g_newsList[newsListItemIndex].GetImportanceStr(), CELL_TYPE_TEXT);
      m_table.SetCell(i, 3, g_newsList[newsListItemIndex].title, CELL_TYPE_TEXT);
      m_table.SetCell(i, 4, g_newsList[newsListItemIndex].GetForecastStr(), CELL_TYPE_TEXT);
      m_table.SetCell(i, 5, g_newsList[newsListItemIndex].GetPreviousStr(), CELL_TYPE_TEXT);
      // m_table.SetCell(i, 6,
      // newsList[newsListItemIndex].GetActualStr(), CELL_TYPE_TEXT);
   }
}

void TDTabNews::ClickBtnSubmit() {
   g_beforeNewsProtectionEnable       = m_beforeNewsProtectionEnable;
   g_beforeNewsMinutes                = m_beforeNewsMinutes;
   g_beforeNewsEnableStopNewOrder     = m_beforeNewsEnableStopNewOrder;
   g_beforeNewsEnableCloseAllOrder    = m_beforeNewsEnableCloseAllOrder;
   g_beforeNewsEnableCloseAllPosition = m_beforeNewsEnableCloseAllPosition;
   g_affterNewsProtectionEnable       = m_affterNewsProtectionEnable;

   Sleep(100);
   ObjectSetInteger(g_chartId, m_ObjBtnSubmitName, OBJPROP_STATE, false);
   syncButtonSaveColor();
}

void TDTabNews::ClickBtnReloadNewsList() {
   ObjectSetInteger(g_chartId, m_objBtnStartReloadNewsListName, OBJPROP_STATE, false);
   ForceRefreshData();
}

void TDTabNews::ClickBtnSaveNewsList() {
   SaveNewsListToFile();
   ObjectSetInteger(g_chartId, m_ObjBtnSaveNewsListName, OBJPROP_STATE, false);
   Sleep(100);
}

void TDTabNews::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_iptFromTime.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_iptToTime.OnRealtimeEvent(id, lparam, dparam, sparam);

   m_table.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcBeforeNewsProtectionEnable.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnBeforeNewsMinutes.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcBeforeNewsEnableStopNewOrder.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcBeforeNewsEnableCloseAllOrder.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcBeforeNewsEnableCloseAllPosition.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcAffterNewsProtectionEnable.OnRealtimeEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnSubmitName) {
         ClickBtnSubmit();
      } else if(sparam == m_objBtnStartReloadNewsListName) {
         ClickBtnReloadNewsList();
      } else if(sparam == m_ObjBtnSaveNewsListName) {
         ClickBtnSaveNewsList();
      }
   }
}

void TDTabNews::OnStrategyTesterEvent() {
   m_iptFromTime.OnStrategyTesterEvent();
   m_iptToTime.OnStrategyTesterEvent();

   m_table.OnStrategyTesterEvent();
   m_ipcBeforeNewsProtectionEnable.OnStrategyTesterEvent();
   m_ipnBeforeNewsMinutes.OnStrategyTesterEvent();
   m_ipcBeforeNewsEnableStopNewOrder.OnStrategyTesterEvent();
   m_ipcBeforeNewsEnableCloseAllOrder.OnStrategyTesterEvent();
   m_ipcBeforeNewsEnableCloseAllPosition.OnStrategyTesterEvent();
   m_ipcAffterNewsProtectionEnable.OnStrategyTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnSubmitName)) {
      ClickBtnSubmit();
   }
   if(uiCommon.getState(g_chartId, m_objBtnStartReloadNewsListName)) {
      ClickBtnReloadNewsList();
   }
   if(uiCommon.getState(g_chartId, m_ObjBtnSaveNewsListName)) {
      ClickBtnSaveNewsList();
   }
}
