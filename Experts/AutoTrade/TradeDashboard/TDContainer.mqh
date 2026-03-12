#include "TDTabGrid.mqh"
#include "TDTabNews.mqh"
#include "TDTabTrade.mqh"
#include "TDTablePositions.mqh"
#include "TradeDashboardContext.mqh"

#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIPanel.mqh>

enum TDTabType {
   TD_TAB_TRADE, // Tab Trade
   TD_TAB_NEWS,  // Tab News
   TD_TAB_GRID   // Tab Grid
};

class TDContainerListener {
 public:
   virtual void onIsMinimizedPanelChange(bool _isMinimized) = 0;
};

class PanelContainerListener : public UIPanelListener {
 public:
   TDContainerListener *m_container;
   virtual void         onIsMinimizedChange(bool _isMinimized) override {
      if(m_container) {
         m_container.onIsMinimizedPanelChange(_isMinimized);
      }
   };
   void SetContainer(TDContainerListener *container) { m_container = container; };
};

class TDContainer : public TDContainerListener {
 public:
   PanelContainerListener m_panelContainerListener;

   UIPanel                m_uiPanelContainer;
   TDTabTrade             m_tdTabTrade;
   TDTabNews              m_tdTabNews;
   TDTabGrid              m_tdTabGrid;

   int                    m_x;
   int                    m_y;
   int                    m_width;
   int                    m_height;

   TDTabType              m_currentTab;

   string                 m_ObjTimeCurrentName;
   string                 m_ObjTabMenuTradeName;
   string                 m_ObjTabMenuGridName;
   string                 m_ObjTabMenuNewsName;

   TDContainer() {}
   ~TDContainer() {
      Print("•>[TDContainer.mqh:55]: TDContainer: Destructor called, deleting objects...");
      ObjectDelete(g_chartId, m_ObjTimeCurrentName);
      ObjectDelete(g_chartId, m_ObjTabMenuTradeName);
      ObjectDelete(g_chartId, m_ObjTabMenuGridName);
      ObjectDelete(g_chartId, m_ObjTabMenuNewsName);
   }

   void Create(int x, int y, int width, int height) {
      Initialize();
      StartDraw(x, y, width, height);

      m_uiPanelContainer.AddPanelChildName(m_ObjTabMenuTradeName);
      m_uiPanelContainer.AddPanelChildName(m_ObjTabMenuGridName);
      m_uiPanelContainer.AddPanelChildName(m_ObjTabMenuNewsName);

      string tdTabTradeObjNameList[];
      int    countTdTabTradeObjName = m_tdTabTrade.GetObjectNameList(tdTabTradeObjNameList);
      for(int i = 0; i < countTdTabTradeObjName; i++) {
         m_uiPanelContainer.AddPanelChildName(tdTabTradeObjNameList[i]);
      }

      string tdTabSettingObjNameList[];
      int    countTdTabSettingObjName = m_tdTabNews.GetObjectNameList(tdTabSettingObjNameList);
      for(int i = 0; i < countTdTabSettingObjName; i++) {
         m_uiPanelContainer.AddPanelChildName(tdTabSettingObjNameList[i]);
      }

      string tdTabGridObjNameList[];
      int    countTdTabGridObjName = m_tdTabGrid.GetObjectNameList(tdTabGridObjNameList);
      for(int i = 0; i < countTdTabGridObjName; i++) {
         m_uiPanelContainer.AddPanelChildName(tdTabGridObjNameList[i]);
      }

      m_uiPanelContainer.PanelRefreshPosition();
      RefreshData();
   }

   void Initialize() {
      m_panelContainerListener.SetContainer(&this);

      m_currentTab          = TD_TAB_TRADE;

      m_ObjTimeCurrentName  = "Obj_TDContainer_ObjTimeCurrentName";
      m_ObjTabMenuTradeName = "Obj_TDContainer_ObjTabMenuTradeName";
      m_ObjTabMenuNewsName  = "Obj_TDContainer_ObjTabMenuNewsName";
      m_ObjTabMenuGridName  = "Obj_TDContainer_ObjTabMenuGridName";
      m_uiPanelContainer.Initialize(g_chartId, "TradingPanel");
      m_uiPanelContainer.SetHeaderTitle("Trade Dashboard");

      m_tdTabTrade.Initialize();
      m_tdTabNews.Initialize();
      m_tdTabGrid.Initialize();
   }

   virtual void onIsMinimizedPanelChange(bool _isMinimized) override {
      m_tdTabTrade.m_tdTablePositions.SetIsMinimized(_isMinimized);
   }

   void StartDraw(int x, int y, int width, int height);
   void OnRealtimeRefresh();
   void OnStrategyTesterRefresh();
   void ClickTabMenuTrade();
   void ClickTabMenuSetting();
   void ClickTabMenuGrid();
   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();

 private:
   void RefreshData() {
      if((bool)MQLInfoInteger(MQL_TESTER)) {
         OnStrategyTesterRefresh();
      } else {
         OnRealtimeRefresh();
      }
   }
};

void TDContainer::StartDraw(int x, int y, int width, int height) {
   m_x      = x;
   m_y      = y;
   m_width  = width;
   m_height = height;

   m_uiPanelContainer.StartDraw(m_x, m_y, m_width, m_height, true);
   int yOffsetPanel = m_uiPanelContainer.GetHeaderHeight();

   uiCommon.CreateLabel(
      g_chartId,
      m_ObjTimeCurrentName,
      "Time: ...",
      m_x + 10,
      m_y + yOffsetPanel + 10,
      8,
      clrLimeGreen
   );
   uiCommon.setZOrder(g_chartId, m_ObjTimeCurrentName, 100);

   uiCommon.CreateButton(
      g_chartId,
      m_ObjTabMenuTradeName,
      "Trade",
      m_x + m_width - 210,
      m_y + yOffsetPanel + 6,
      60,
      20,
      clrWhite,
      clrGray,
      clrDarkGray
   );
   uiCommon.setZOrder(g_chartId, m_ObjTabMenuTradeName, 100);
   uiCommon.CreateButton(
      g_chartId,
      m_ObjTabMenuGridName,
      "Grid",
      m_x + m_width - 140,
      m_y + yOffsetPanel + 6,
      60,
      20,
      clrWhite,
      clrGray,
      clrDarkGray
   );
   uiCommon.setZOrder(g_chartId, m_ObjTabMenuGridName, 100);

   uiCommon.CreateButton(
      g_chartId,
      m_ObjTabMenuNewsName,
      "News",
      m_x + m_width - 70,
      m_y + yOffsetPanel + 6,
      60,
      20,
      clrWhite,
      clrGray,
      clrDarkGray
   );
   uiCommon.setZOrder(g_chartId, m_ObjTabMenuNewsName, 100);

   yOffsetPanel = yOffsetPanel + 30; // 30 is distance from header to tab content

   if(m_currentTab == TD_TAB_TRADE) {
      m_tdTabTrade.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
   } else if(m_currentTab == TD_TAB_NEWS) {
      m_tdTabNews.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
   } else if(m_currentTab == TD_TAB_GRID) {
      m_tdTabGrid.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
   }
}

void TDContainer::OnRealtimeRefresh() {
   // Cập nhật thời gian hiện tại
   string timeCurrentStr = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   uiCommon.setText(g_chartId, m_ObjTimeCurrentName, "Time: " + timeCurrentStr);

   if(m_currentTab == TD_TAB_TRADE) {
      m_tdTabTrade.RefreshData();
   } else if(m_currentTab == TD_TAB_NEWS) {
      m_tdTabNews.OnRealtimeRefresh();
   } else if(m_currentTab == TD_TAB_GRID) {
      m_tdTabGrid.RefreshData();
   }
}

void TDContainer::OnStrategyTesterRefresh() {
   // Cập nhật thời gian hiện tại
   string timeCurrentStr = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   uiCommon.setText(g_chartId, m_ObjTimeCurrentName, "Time: " + timeCurrentStr);

   if(m_currentTab == TD_TAB_TRADE) {
      m_tdTabTrade.RefreshData();
   } else if(m_currentTab == TD_TAB_NEWS) {
      m_tdTabNews.OnStrategyTesterRefresh();
   } else if(m_currentTab == TD_TAB_GRID) {
      m_tdTabGrid.RefreshData();
   }
   m_tdTabTrade.m_tdTablePositions.RefreshTicketPositionsData();
}

void TDContainer::ClickTabMenuTrade() {
   ObjectSetInteger(g_chartId, m_ObjTabMenuTradeName, OBJPROP_STATE, false);
   if(m_currentTab != TD_TAB_TRADE) {
      m_currentTab = TD_TAB_TRADE;
      int yOffsetPanel
         = m_uiPanelContainer.GetHeaderHeight() + 30; // 30 is distance from header to tab content

      m_tdTabNews.DestroyDraw();
      m_tdTabGrid.DestroyDraw();
      m_tdTabTrade.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
      ChartRedraw(g_chartId);
   }
}
void TDContainer::ClickTabMenuSetting() {
   ObjectSetInteger(g_chartId, m_ObjTabMenuNewsName, OBJPROP_STATE, false);
   if(m_currentTab != TD_TAB_NEWS) {
      m_currentTab = TD_TAB_NEWS;
      int yOffsetPanel
         = m_uiPanelContainer.GetHeaderHeight() + 30; // 30 is distance from header to tab content

      m_tdTabTrade.DestroyDraw();
      m_tdTabGrid.DestroyDraw();
      m_tdTabNews.OpenTab(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
      ChartRedraw(g_chartId);
   }
}

void TDContainer::ClickTabMenuGrid() {
   ObjectSetInteger(g_chartId, m_ObjTabMenuGridName, OBJPROP_STATE, false);
   if(m_currentTab != TD_TAB_GRID) {
      m_currentTab = TD_TAB_GRID;
      int yOffsetPanel
         = m_uiPanelContainer.GetHeaderHeight() + 30; // 30 is distance from header to tab content

      m_tdTabTrade.DestroyDraw();
      m_tdTabNews.DestroyDraw();
      m_tdTabGrid.OpenTab(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
      ChartRedraw(g_chartId);
   }
}

void TDContainer::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_uiPanelContainer.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_tdTabTrade.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_tdTabNews.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_tdTabGrid.OnRealtimeEvent(id, lparam, dparam, sparam);
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjTabMenuTradeName) {
         ClickTabMenuTrade();
      } else if(sparam == m_ObjTabMenuNewsName) {
         ClickTabMenuSetting();
      } else if(sparam == m_ObjTabMenuGridName) {
         ClickTabMenuGrid();
      }
   }
}

void TDContainer::OnStrategyTesterEvent() {
   m_uiPanelContainer.OnStrategyTesterEvent();
   m_tdTabTrade.OnStrategyTesterEvent();
   m_tdTabNews.OnStrategyTesterEvent();
   m_tdTabGrid.OnStrategyTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjTabMenuTradeName)) {
      ClickTabMenuTrade();
   }
   if(uiCommon.getState(g_chartId, m_ObjTabMenuNewsName)) {
      ClickTabMenuSetting();
   }
   if(uiCommon.getState(g_chartId, m_ObjTabMenuGridName)) {
      ClickTabMenuGrid();
   }
}
