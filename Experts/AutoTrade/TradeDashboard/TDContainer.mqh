#include "TDTabSetting.mqh"
#include "TDTabTrade.mqh"
#include "TDTablePositions.mqh"
#include "TradeDashboardContext.mqh"

#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIPanel.mqh>

enum TDTabType {
   TD_TAB_TRADE,  // Tab Trade
   TD_TAB_SETTING // Tab Setting
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
   TDTabSetting           m_tdTabSetting;

   int                    m_x;
   int                    m_y;
   int                    m_width;
   int                    m_height;

   TDTabType              m_currentTab;

   string                 m_ObjNewsName;
   string                 m_ObjTabMenuTradeName;
   string                 m_ObjTabMenuSettingName;

   bool                   Create(int x, int y, int width, int height) {
      Initialization();
      StartDraw(x, y, width, height);

      string tdTabTradeObjNameList[];
      int    countTdTabTradeObjName = m_tdTabTrade.GetObjectNameList(tdTabTradeObjNameList);
      for(int i = 0; i < countTdTabTradeObjName; i++) {
         m_uiPanelContainer.AddPanelChildName(tdTabTradeObjNameList[i]);
      }

      string tdTabSettingObjNameList[];
      int    countTdTabSettingObjName = m_tdTabSetting.GetObjectNameList(tdTabSettingObjNameList);
      for(int i = 0; i < countTdTabSettingObjName; i++) {
         m_uiPanelContainer.AddPanelChildName(tdTabSettingObjNameList[i]);
      }

      m_uiPanelContainer.PanelRefreshPosition();
      RefreshData();
      return true;
   }

   void Initialization() {
      m_panelContainerListener.SetContainer(&this);

      m_currentTab            = TD_TAB_TRADE;

      m_ObjNewsName           = "M_ObjNewsName";
      m_ObjTabMenuTradeName   = "M_ObjTabMenuTradeName";
      m_ObjTabMenuSettingName = "M_ObjTabMenuSettingName";

      m_uiPanelContainer.Initialization(g_chartId, "TradingPanel");
      m_uiPanelContainer.SetHeaderTitle("Trade Dashboard");

      m_tdTabTrade.Initialization();
      m_tdTabSetting.Initialization();
   }

   virtual void onIsMinimizedPanelChange(bool _isMinimized) override {
      m_tdTabTrade.m_tdTablePositions.SetIsMinimized(_isMinimized);
   }

   void StartDraw(int x, int y, int width, int height);
   void RefreshData();
   void ClickTabMenuTrade();
   void ClickTabMenuSetting();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterRefresh();
   void OnMQLTesterEvent();
};

void TDContainer::StartDraw(int x, int y, int width, int height) {
   m_x = x;
   Print("•>[TDContainer.mqh:102]: m_x: ", m_x);
   m_y      = y;
   m_width  = width;
   m_height = height;

   m_uiPanelContainer.StartDraw(m_x, m_y, m_width, m_height, true);
   int yOffsetPanel = m_uiPanelContainer.GetHeaderHeight();

   uiCommon.CreateLabel(
      g_chartId,
      m_ObjNewsName,
      "NEWS: ...",
      m_x + 10,
      m_y + yOffsetPanel + 10,
      8,
      clrLimeGreen
   );
   uiCommon.setZOrder(g_chartId, m_ObjNewsName, 100);

   uiCommon.CreateButton(
      g_chartId,
      m_ObjTabMenuTradeName,
      "Trade",
      m_x + m_width - 140,
      m_y + yOffsetPanel + 6,
      60,
      20,
      clrWhite,
      clrGray,
      clrDarkGray
   );
   uiCommon.setZOrder(g_chartId, m_ObjTabMenuTradeName, 100);
   m_uiPanelContainer.AddPanelChildName(m_ObjTabMenuTradeName);
   uiCommon.CreateButton(
      g_chartId,
      m_ObjTabMenuSettingName,
      "Setting",
      m_x + m_width - 70,
      m_y + yOffsetPanel + 6,
      60,
      20,
      clrWhite,
      clrGray,
      clrDarkGray
   );
   uiCommon.setZOrder(g_chartId, m_ObjTabMenuSettingName, 100);
   m_uiPanelContainer.AddPanelChildName(m_ObjTabMenuSettingName);

   yOffsetPanel = yOffsetPanel + 30; // 30 is distance from header to tab content

   if(m_currentTab == TD_TAB_TRADE) {
      m_tdTabTrade.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
   } else {
      m_tdTabSetting.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
   }
}

void TDContainer::RefreshData() {
   m_tdTabTrade.RefreshData();
   m_tdTabSetting.RefreshData();
}

void TDContainer::ClickTabMenuTrade() {
   ObjectSetInteger(g_chartId, m_ObjTabMenuTradeName, OBJPROP_STATE, false);
   if(m_currentTab != TD_TAB_TRADE) {
      m_currentTab = TD_TAB_TRADE;
      int yOffsetPanel
         = m_uiPanelContainer.GetHeaderHeight() + 30; // 30 is distance from header to tab content

      m_tdTabSetting.DestroyDraw();
      m_tdTabTrade.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
      ChartRedraw(g_chartId);
   }
}
void TDContainer::ClickTabMenuSetting() {
   ObjectSetInteger(g_chartId, m_ObjTabMenuSettingName, OBJPROP_STATE, false);
   if(m_currentTab != TD_TAB_SETTING) {
      m_currentTab = TD_TAB_SETTING;
      int yOffsetPanel
         = m_uiPanelContainer.GetHeaderHeight() + 30; // 30 is distance from header to tab content

      m_tdTabTrade.DestroyDraw();
      m_tdTabSetting.StartDraw(m_x, m_y + yOffsetPanel, m_width, m_height - yOffsetPanel);
      ChartRedraw(g_chartId);
   }
}

void TDContainer::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_uiPanelContainer.OnChartEvent(id, lparam, dparam, sparam);
   m_tdTabTrade.OnChartEvent(id, lparam, dparam, sparam);
   m_tdTabSetting.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjTabMenuTradeName) {
         ClickTabMenuTrade();
      } else if(sparam == m_ObjTabMenuSettingName) {
         ClickTabMenuSetting();
      }
   }
}

void TDContainer::OnMQLTesterRefresh() {
   RefreshData();
   m_tdTabTrade.m_tdTablePositions.RefreshTicketPositionsData();
}

void TDContainer::OnMQLTesterEvent() {
   m_uiPanelContainer.OnMQLTesterEvent();
   m_tdTabTrade.OnMQLTesterEvent();
   m_tdTabSetting.OnMQLTesterEvent();
   if(uiCommon.getState(g_chartId, m_ObjTabMenuTradeName)) {
      ClickTabMenuTrade();
   }
   if(uiCommon.getState(g_chartId, m_ObjTabMenuSettingName)) {
      ClickTabMenuSetting();
   }
}
