#include "TDTabGridPopupEdit.mqh"
#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputCheckbox.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIInputRadio.mqh>
#include <AutoTrade/UI/UIInputSelect.mqh>
#include <AutoTrade/UI/UIInputText.mqh>
#include <AutoTrade/UI/UITable.mqh>
#include <AutoTrade/Utils/UtilString.mqh>

class TDTabGrid : public UIListener {
 private:
   int                m_x;
   int                m_y;
   int                m_width;
   int                m_height;
   int                m_gridIndex;
   bool               m_enableCustomPrice;

   double             m_volumeRiskValue;
   ENUM_VOLUME_RISK   m_volumeRiskType;

   TDTabGridPopupEdit m_popupEdit;

   UIInputSelect      m_ipSelectGrid;

   string             m_labelGridInfo; // Label hiển thị thông tin grid ()
   string             m_btnEditGrid;
   string             m_btnCloseGrid;

   UITable            m_table;
   int                m_tableRows;
   int                m_tableColumns;
   int                m_tablePage;

   string             m_labelTotalProfit;

   string             m_ObjLabelGridTypeName;
   ENUM_GRID_TYPE     m_gridType; // Loại grid hiện tại (Buy/Sell)
   UIInputRadio       m_irGridTypeBuy;
   UIInputRadio       m_irGridTypeSell;
   UIInputRadioGroup  m_irGridTypeGroup;

   UIInputText        m_iptGridName;
   UIInputNumber      m_ipGridPositionSize;
   UIInputNumber      m_ipGridNextLotMultiplier;

   UIInputNumber      m_ipnGridEntryPrice;
   UIInputCheckbox    m_ipcCustomEntryPrice;
   UIInputNumber      m_ipGridStopLossPoints;
   UIInputNumber      m_ipGridTakeProfitPoints;

   UIInputNumber      m_ipnBaseLot;
   UIInputSelect      m_ipsVolumeRiskType;
   UIInputNumber      m_ipnVolumeRiskValue;

   UIInputCheckbox    m_ipcTrailingStopEnable;
   bool               m_enableTrailingStop;

   UIInputNumber      m_ipnTrailingStopStart;
   UIInputNumber      m_ipnTrailingStopStep;
   UIInputNumber      m_ipnTrailingStopDistance;

   string             m_ObjBtnStartGridName;
   string             m_lineAverageOpenPriceName;
   string             m_lineTSPeakPriceName;
   string             m_lineTSStopLossPriceName;

 public:
   TDTabGrid() {}
   ~TDTabGrid() {
      ObjectDelete(g_chartId, m_labelGridInfo);
      ObjectDelete(g_chartId, m_btnEditGrid);
      ObjectDelete(g_chartId, m_btnCloseGrid);
      ObjectDelete(g_chartId, m_labelTotalProfit);
      ObjectDelete(g_chartId, m_ObjLabelGridTypeName);
      ObjectDelete(g_chartId, m_ObjBtnStartGridName);
      ObjectDelete(g_chartId, m_lineAverageOpenPriceName);
      ObjectDelete(g_chartId, m_lineTSPeakPriceName);
      ObjectDelete(g_chartId, m_lineTSStopLossPriceName);
   }

   void Initialize() {
      m_enableCustomPrice = false;

      // Chỉ dùng 1 trong 2 cách: Dùng listener hoặc callback
      // m_ipSelectGrid.SetCallback(&this, TDTabGrid::OnChangeSelectGrid);
      m_ipSelectGrid.SetListener(&this);

      m_table.SetCallback(&this, TDTabGrid::OnTableChange);
      m_irGridTypeGroup.SetCallback(&this, TDTabGrid::OnInputRadioChangeGridType);

      m_ipGridPositionSize.SetCallback(&this, TDTabGrid::OnChangePositionSize);
      m_ipGridNextLotMultiplier.SetCallback(&this, TDTabGrid::OnChangeNextLotMultiplier);

      m_ipcCustomEntryPrice.SetCallback(&this, TDTabGrid::OnChangeCheckboxCustomPrice);
      m_ipGridStopLossPoints.SetCallback(&this, TDTabGrid::OnChangeStopLossPoints);
      m_ipGridTakeProfitPoints.SetCallback(&this, TDTabGrid::OnChangeTakeProfitPoints);

      m_ipsVolumeRiskType.SetCallback(&this, TDTabGrid::OnChangeVolumeRiskType);
      m_ipnVolumeRiskValue.SetCallback(&this, TDTabGrid::OnChangeVolumeRiskValue);
      m_ipnBaseLot.SetCallback(&this, TDTabGrid::OnChangeBaseLot);

      m_ipcTrailingStopEnable.SetCallback(&this, TDTabGrid::OnChangeCheckboxTrailingStopEnable);

      m_popupEdit.Initialize();

      m_ipSelectGrid.Initialize(g_chartId, "TDTabGrid_IpSelectGrid");
      for(int i = 0; i < ArraySize(g_gridList); i++) {
         m_ipSelectGrid.AddOption(i, g_gridList[i].gridName);
      }

      m_labelGridInfo = "TDTabGrid_LabelGridInfo";
      m_btnEditGrid   = "TDTabGrid_BtnEditGrid";
      m_btnCloseGrid  = "TDTabGrid_BtnCloseGrid";

      m_tableRows     = 6;
      m_tableColumns  = 8;
      m_tablePage     = 1;
      m_table.Initialize(
         g_chartId,
         "TDTabGridTable",
         m_tableRows,
         m_tableColumns
      ); // Lưu ý: name table không chứa ký tự "_"

      m_table.SetZOrderBase(200);
      m_table.SetHeader(0, "Ticket", 70, CELL_TYPE_TEXT);
      m_table.SetHeader(1, "State", 100, CELL_TYPE_TEXT);
      m_table.SetHeader(2, "Volume", 50, CELL_TYPE_TEXT);
      m_table.SetHeader(3, "Open", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(4, "Close", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(5, "Profit", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(6, "Swap", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(7, "Action", 60, CELL_TYPE_BUTTON);

      m_labelTotalProfit     = "TDTabGrid_LabelTotalProfit";

      m_ObjLabelGridTypeName = "TDTabGrid_LabelGridType";
      m_irGridTypeGroup.Initialize("TDTabGrid_IrGridTypeGroup");
      m_irGridTypeGroup.AddInputRadio(&m_irGridTypeBuy);
      m_irGridTypeGroup.AddInputRadio(&m_irGridTypeSell);
      m_irGridTypeBuy.Initialize(g_chartId, "TDTabGrid_IpRadioGridBuy");
      m_irGridTypeSell.Initialize(g_chartId, "TDTabGrid_IpRadioGridSell");

      m_iptGridName.Initialize(g_chartId, "TDTabGrid_IpGridName");
      m_ipGridPositionSize.Initialize(g_chartId, "TDTabGrid_IpGridPositionSize");
      m_ipGridNextLotMultiplier.Initialize(g_chartId, "TDTabGrid_IpGridNextLotMultiplier");

      m_ipnGridEntryPrice.Initialize(g_chartId, "TDTabGrid_IpGridEntryPrice");
      m_ipcCustomEntryPrice.Initialize(g_chartId, "TDTabGrid_IpcCustomPrice");
      m_ipGridStopLossPoints.Initialize(g_chartId, "TDTabGrid_IpGridStopLossPoints");
      m_ipGridTakeProfitPoints.Initialize(g_chartId, "TDTabGrid_IpGridTakeProfitPoints");

      m_ipsVolumeRiskType.Initialize(g_chartId, "TDTabGrid_IpsVolumeType");
      m_ipsVolumeRiskType.AddOption(VOLUME_RISK_INPUT, "Input");
      m_ipsVolumeRiskType.AddOption(VOLUME_RISK_MONEY, "Money");
      m_ipsVolumeRiskType.AddOption(VOLUME_RISK_PERCENT_BALANCE, "% Balance");
      m_ipsVolumeRiskType.AddOption(VOLUME_RISK_PERCENT_EQUITY, "% Equity");
      m_ipnBaseLot.Initialize(g_chartId, "TDTabGrid_IpGridBaseLot");
      m_ipnVolumeRiskValue.Initialize(g_chartId, "TDTabGrid_IpnVolumeValue");

      m_ipcTrailingStopEnable.Initialize(g_chartId, "TDTabGrid_IpcTrailingStopEnable");
      m_ipnTrailingStopStart.Initialize(g_chartId, "TDTabGrid_IpnTrailingStopStart");
      m_ipnTrailingStopStep.Initialize(g_chartId, "TDTabGrid_IpnTrailingStopStep");
      m_ipnTrailingStopDistance.Initialize(g_chartId, "TDTabGrid_IpnTrailingStopDistance");

      m_ObjBtnStartGridName      = "Obj_TDTabGrid_BtnStartGrid";
      m_lineAverageOpenPriceName = "Obj_TDTabGrid_LineAverageOpenPrice";
      m_lineTSPeakPriceName      = "Obj_TDTabGrid_LineTSPeakPrice";
      m_lineTSStopLossPriceName  = "Obj_TDTabGrid_LineTSStopLossPrice";
   }

   // Dùng 1 trong 2 cách: Listener hoặc Callback
   virtual void listen(void *child, UI_EVENT_TYPE type, double value) override {
      // Print("TDTabGrid listen: type=", type, " value=", value, " child=", child);
      // Print("m_ipSelectGrid: ", &m_ipSelectGrid);

      if(child == &m_ipSelectGrid) {
         if(type == UI_EVENT_CHANGE_VALUE) {
            m_gridIndex = (int)value;
            RefreshData();
         }
      }
   }

   // static void OnChangeSelectGrid(void *context, UI_EVENT_TYPE eventType, double value) {
   //    TDTabGrid *self = (TDTabGrid *)context;
   //    if(eventType == UI_EVENT_CHANGE_VALUE) {
   //       self.m_gridIndex = (int)value;
   //       self.RefreshData();
   //    }
   // }

   static void OnTableChange(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_PAGE) {
         self.m_tablePage = (int)value;
         self.RefreshData();
      }
   }

   static void OnInputRadioChangeGridType(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_gridType = (ENUM_GRID_TYPE)(int)value;
      }
   }

   static void OnChangePositionSize(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         if(self.m_volumeRiskType == VOLUME_RISK_INPUT) {
            self.RefreshIpnVolumeRiskValueLabel();
         } else {
            self.RefreshInputBaselot();
         }
         self.RefreshIpnBaseLotLabel();
      }
   }

   static void OnChangeNextLotMultiplier(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         if(self.m_volumeRiskType == VOLUME_RISK_INPUT) {
            self.RefreshIpnVolumeRiskValueLabel();
         } else {
            self.RefreshInputBaselot();
         }
         self.RefreshIpnBaseLotLabel();
      }
   }

   static void OnChangeCheckboxCustomPrice(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         // Cập nhật lại Base Lot khi Position Size thay đổi
         if(value == 1) {
            self.m_enableCustomPrice = true;
            self.m_ipnGridEntryPrice.UpdateDisabled(false);
         } else {
            self.m_enableCustomPrice = false;
            self.m_ipnGridEntryPrice.UpdateDisabled(true);
         }
         ChartRedraw(g_chartId);
      }
   }

   static void OnChangeStopLossPoints(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         if(self.m_volumeRiskType == VOLUME_RISK_INPUT) {
            self.RefreshIpnVolumeRiskValueLabel();
         } else {
            self.RefreshInputBaselot();
            self.RefreshIpnBaseLotLabel();
         }
      }
   }

   static void OnChangeTakeProfitPoints(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {}
   }

   static void OnChangeVolumeRiskType(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_volumeRiskType = (ENUM_VOLUME_RISK)(int)value;

         if(int(value) == VOLUME_RISK_INPUT) {
            self.m_ipnVolumeRiskValue.UpdateLabel("SL Money ($)");
            self.m_ipnVolumeRiskValue.UpdateDisabled(true);
            self.m_ipnBaseLot.UpdateDisabled(false);
         }
         if(int(value) == VOLUME_RISK_MONEY) {
            self.m_ipnVolumeRiskValue.UpdateLabel("Risk: Money ($)");
            self.m_ipnVolumeRiskValue.UpdateDisabled(false);
            self.m_ipnBaseLot.UpdateDisabled(true);
         }
         if(int(value) == VOLUME_RISK_PERCENT_BALANCE) {
            self.m_ipnVolumeRiskValue.UpdateLabel("Risk: % Balance");
            self.m_ipnVolumeRiskValue.UpdateDisabled(false);
            self.m_ipnBaseLot.UpdateDisabled(true);
         }
         if(int(value) == VOLUME_RISK_PERCENT_EQUITY) {
            self.m_ipnVolumeRiskValue.UpdateLabel("Risk: % Equity");
            self.m_ipnVolumeRiskValue.UpdateDisabled(false);
            self.m_ipnBaseLot.UpdateDisabled(true);
         }
         self.m_ipnVolumeRiskValue.UpdateValue(0);
         self.m_ipnBaseLot.UpdateValue(0);
         self.m_ipnBaseLot.UpdateLabel("Base Lot:     (Auto)");
      }
   }

   static void OnChangeBaseLot(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.RefreshIpnVolumeRiskValueLabel();
         self.RefreshIpnBaseLotLabel();
      }
   }

   static void OnChangeVolumeRiskValue(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_volumeRiskValue = value;
         self.RefreshInputBaselot();
         self.RefreshIpnBaseLotLabel();
      }
   }

   static void OnChangeCheckboxTrailingStopEnable(
      void *context, UI_EVENT_TYPE eventType, double value
   ) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         if(value == 1) {
            self.m_enableTrailingStop = true;
            self.m_ipnTrailingStopStart.UpdateDisabled(false);
            self.m_ipnTrailingStopStep.UpdateDisabled(false);
            self.m_ipnTrailingStopDistance.UpdateDisabled(false);
         } else {
            self.m_enableTrailingStop = false;
            self.m_ipnTrailingStopStart.UpdateDisabled(true);
            self.m_ipnTrailingStopStep.UpdateDisabled(true);
            self.m_ipnTrailingStopDistance.UpdateDisabled(true);
         }
         ChartRedraw(g_chartId);
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      string tableObjNameList[];
      int    tableObjCount = m_table.GetObjectNameList(tableObjNameList);

      string ipSelectGridObjNameList[];
      int    ipSelectGridObjCount = m_ipSelectGrid.GetObjectNameList(ipSelectGridObjNameList);

      string irGridTypeGroupObjNameList[];
      int irGridTypeGroupObjCount = m_irGridTypeGroup.GetObjectNameList(irGridTypeGroupObjNameList);

      string iptGridNameObjNameList[];
      int    iptGridNameObjCount = m_iptGridName.GetObjectNameList(iptGridNameObjNameList);

      string ipGridPositionSizeObjNameList[];
      int    ipGridPositionSizeObjCount
         = m_ipGridPositionSize.GetObjectNameList(ipGridPositionSizeObjNameList);

      string ipGridNextLotMultiplierObjNameList[];
      int    ipGridNextLotMultiplierObjCount
         = m_ipGridNextLotMultiplier.GetObjectNameList(ipGridNextLotMultiplierObjNameList);

      string ipnGridEntryPriceObjNameList[];
      int    ipnGridEntryPriceObjCount
         = m_ipnGridEntryPrice.GetObjectNameList(ipnGridEntryPriceObjNameList);

      string ipcCustomEntryPriceObjNameList[];
      int    ipcCustomEntryPriceObjCount
         = m_ipcCustomEntryPrice.GetObjectNameList(ipcCustomEntryPriceObjNameList);

      string ipGridStopLossPointsObjNameList[];
      int    ipGridStopLossPointsObjCount
         = m_ipGridStopLossPoints.GetObjectNameList(ipGridStopLossPointsObjNameList);

      string ipGridTakeProfitPointsObjNameList[];
      int    ipGridTakeProfitPointsObjCount
         = m_ipGridTakeProfitPoints.GetObjectNameList(ipGridTakeProfitPointsObjNameList);

      string ipsVolumeTypeObjNameList[];
      int ipsVolumeTypeObjCount = m_ipsVolumeRiskType.GetObjectNameList(ipsVolumeTypeObjNameList);

      string ipnBaseLotObjNameList[];
      int    ipnBaseLotObjCount = m_ipnBaseLot.GetObjectNameList(ipnBaseLotObjNameList);

      string ipnVolumeValueObjNameList[];
      int    ipnVolumeValueObjCount
         = m_ipnVolumeRiskValue.GetObjectNameList(ipnVolumeValueObjNameList);

      string ipcTrailingStopEnableObjNameList[];
      int    ipcTrailingStopEnableObjCount
         = m_ipcTrailingStopEnable.GetObjectNameList(ipcTrailingStopEnableObjNameList);
      string ipnTrailingStopStartObjNameList[];
      int    ipnTrailingStopStartObjCount
         = m_ipnTrailingStopStart.GetObjectNameList(ipnTrailingStopStartObjNameList);
      string ipnTrailingStopStepObjNameList[];
      int    ipnTrailingStopStepObjCount
         = m_ipnTrailingStopStep.GetObjectNameList(ipnTrailingStopStepObjNameList);
      string ipnTrailingStopDistanceObjNameList[];
      int    ipnTrailingStopDistanceObjCount
         = m_ipnTrailingStopDistance.GetObjectNameList(ipnTrailingStopDistanceObjNameList);

      int count = 0;
      ArrayResize(
         objNameList,
         ipSelectGridObjCount + 3 + tableObjCount + 1 + 1 + irGridTypeGroupObjCount
            + iptGridNameObjCount + ipGridPositionSizeObjCount + ipGridNextLotMultiplierObjCount
            + ipnGridEntryPriceObjCount + ipcCustomEntryPriceObjCount + ipGridStopLossPointsObjCount
            + ipGridTakeProfitPointsObjCount + ipsVolumeTypeObjCount + ipnBaseLotObjCount
            + ipnVolumeValueObjCount + ipcTrailingStopEnableObjCount + ipnTrailingStopStartObjCount
            + ipnTrailingStopStepObjCount + ipnTrailingStopDistanceObjCount + 1 + 3
      );

      for(int i = 0; i < ipSelectGridObjCount; i++) {
         objNameList[count++] = ipSelectGridObjNameList[i];
      }

      objNameList[count++] = m_labelGridInfo;
      objNameList[count++] = m_btnEditGrid;
      objNameList[count++] = m_btnCloseGrid;

      for(int i = 0; i < tableObjCount; i++) {
         objNameList[count++] = tableObjNameList[i];
      }

      objNameList[count++] = m_labelTotalProfit;

      objNameList[count++] = m_ObjLabelGridTypeName;
      for(int i = 0; i < irGridTypeGroupObjCount; i++) {
         objNameList[count++] = irGridTypeGroupObjNameList[i];
      }

      for(int i = 0; i < iptGridNameObjCount; i++) {
         objNameList[count++] = iptGridNameObjNameList[i];
      }
      for(int i = 0; i < ipGridPositionSizeObjCount; i++) {
         objNameList[count++] = ipGridPositionSizeObjNameList[i];
      }
      for(int i = 0; i < ipGridNextLotMultiplierObjCount; i++) {
         objNameList[count++] = ipGridNextLotMultiplierObjNameList[i];
      }

      for(int i = 0; i < ipnGridEntryPriceObjCount; i++) {
         objNameList[count++] = ipnGridEntryPriceObjNameList[i];
      }
      for(int i = 0; i < ipcCustomEntryPriceObjCount; i++) {
         objNameList[count++] = ipcCustomEntryPriceObjNameList[i];
      }

      for(int i = 0; i < ipGridStopLossPointsObjCount; i++) {
         objNameList[count++] = ipGridStopLossPointsObjNameList[i];
      }
      for(int i = 0; i < ipGridTakeProfitPointsObjCount; i++) {
         objNameList[count++] = ipGridTakeProfitPointsObjNameList[i];
      }
      for(int i = 0; i < ipsVolumeTypeObjCount; i++) {
         objNameList[count++] = ipsVolumeTypeObjNameList[i];
      }

      for(int i = 0; i < ipnBaseLotObjCount; i++) {
         objNameList[count++] = ipnBaseLotObjNameList[i];
      }

      for(int i = 0; i < ipnVolumeValueObjCount; i++) {
         objNameList[count++] = ipnVolumeValueObjNameList[i];
      }

      for(int i = 0; i < ipcTrailingStopEnableObjCount; i++) {
         objNameList[count++] = ipcTrailingStopEnableObjNameList[i];
      }
      for(int i = 0; i < ipnTrailingStopStartObjCount; i++) {
         objNameList[count++] = ipnTrailingStopStartObjNameList[i];
      }
      for(int i = 0; i < ipnTrailingStopStepObjCount; i++) {
         objNameList[count++] = ipnTrailingStopStepObjNameList[i];
      }
      for(int i = 0; i < ipnTrailingStopDistanceObjCount; i++) {
         objNameList[count++] = ipnTrailingStopDistanceObjNameList[i];
      }

      objNameList[count++] = m_ObjBtnStartGridName;
      objNameList[count++] = m_lineAverageOpenPriceName;
      objNameList[count++] = m_lineTSPeakPriceName;
      objNameList[count++] = m_lineTSStopLossPriceName;

      return count;
   }

   double CalcTotalLotExpected(double baseLot, double nextLotMultiplier, int positionSize) {
      double totalLotExpected = 0;
      for(int i = 0; i < positionSize; i++) {
         double lot        = baseLot * MathPow(nextLotMultiplier, i);
         totalLotExpected += lot;
      }
      return totalLotExpected;
   }

   double CalcMaxPointLoss(
      double baseLot, double nextLotMultiplier, int positionSize, int stopLossPoints
   ) {
      // Tính Tổng: maxPointLoss = Σ (stepPoints × (size-i) × baseLot × mult^i)
      // maxPointLoss = baseLot × Σ[(size-i) × stepPoints × mult^i]
      double maxPointLoss = 0;
      int    stepPoints   = stopLossPoints / positionSize;
      for(int i = 0; i < positionSize; i++) {
         double lot                = baseLot * MathPow(nextLotMultiplier, i);
         double currentLossPoints  = stepPoints * (positionSize - i);

         maxPointLoss             += currentLossPoints * lot;
      }
      return maxPointLoss;
   }

   double CalcBaseLot(
      double allowedMaxPointLoss, double nextLotMultiplier, int size, int stopLossPoints
   ) {
      // Tính baselot: baseLot = allowedMaxPointLoss / Σ[(stepPoints × (size-i) × mult^i)]
      int stepPoints = stopLossPoints / size; // dùng double để tránh mất precision
      // Tính hệ số tổng (không phụ thuộc baseLot)
      double sumCoeff = 0;
      for(int i = 0; i < size; i++) {
         double lossPoints  = stepPoints * (size - i) * MathPow(nextLotMultiplier, i);
         sumCoeff          += lossPoints;
      }
      if(sumCoeff <= 0)
         return 0;

      double baseLot = allowedMaxPointLoss / sumCoeff;
      return baseLot;
   }

   void RefreshInputBaselot() {
      if(m_volumeRiskType == VOLUME_RISK_INPUT) {
         return;
      }
      double riskMoney           = 0;
      double baseLot             = 0;
      double allowedMaxPointLoss = 0;
      if(m_volumeRiskType == VOLUME_RISK_MONEY) {
         riskMoney = m_volumeRiskValue;
      }
      if(m_volumeRiskType == VOLUME_RISK_PERCENT_BALANCE) {
         riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * m_volumeRiskValue / 100.0;
      }
      if(m_volumeRiskType == VOLUME_RISK_PERCENT_EQUITY) {
         riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * m_volumeRiskValue / 100.0;
      }
      double point         = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tickSize      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue     = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double valuePerPoint = tickValue / tickSize * point;

      allowedMaxPointLoss  = riskMoney / valuePerPoint;

      baseLot              = CalcBaseLot(
         allowedMaxPointLoss,
         m_ipGridNextLotMultiplier.GetValue(),
         (int)m_ipGridPositionSize.GetValue(),
         (int)m_ipGridStopLossPoints.GetValue()
      );
      m_ipnBaseLot.UpdateValue(baseLot);
   }

   void RefreshIpnVolumeRiskValueLabel() {
      if(m_volumeRiskType != VOLUME_RISK_INPUT) {
         return;
      }
      double baseLot        = m_ipnBaseLot.GetValue();
      double point          = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tickSize       = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double valuePerPoint  = tickValue / tickSize * point;

      double totalPointLoss = CalcMaxPointLoss(
         baseLot,
         m_ipGridNextLotMultiplier.GetValue(),
         (int)m_ipGridPositionSize.GetValue(),
         (int)m_ipGridStopLossPoints.GetValue()
      );
      double riskMoney = totalPointLoss * valuePerPoint;
      string label     = "SL Money: " + DoubleToString(riskMoney, 2) + "$";
      m_ipnVolumeRiskValue.UpdateLabel(label);
   }

   void RefreshIpnBaseLotLabel() {
      double baseLot           = m_ipnBaseLot.GetValue();
      double nextLotMultiplier = m_ipGridNextLotMultiplier.GetValue();
      int    positionSize      = (int)m_ipGridPositionSize.GetValue();

      double totalLotExpected  = CalcTotalLotExpected(baseLot, nextLotMultiplier, positionSize);
      string label             = "(Σ: " + DoubleToString(totalLotExpected, 2) + ")";
      m_ipnBaseLot.UpdateLabel("Base Lot:     " + label);
   }

   void OpenTab(int x, int y, int width, int height);
   void StartDraw(int x, int y, int width, int height);
   void DestroyDraw();
   void RefreshData();
   void HandleCloseOrder(ulong ticketId);
   void HandleClosePosition(ulong ticketId);
   void ClickBtnEditGrid();
   void ClickBtnCloseGrid();
   void ClickBtnStartGrid();
   void OnRealtimeEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnStrategyTesterEvent();
};

void TDTabGrid::OpenTab(int x, int y, int width, int height) {
   SymbolInfoTick(_Symbol, Tick);
   double bid  = Tick.bid;
   double ask  = Tick.ask;

   m_gridIndex = ArraySize(g_gridList) - 1; // Mặc định chọn grid mới tạo
   m_ipSelectGrid.SetValue(m_gridIndex);
   m_iptGridName.SetValue("Grid_" + IntegerToString(ArraySize(g_gridList) + 1));

   StartDraw(x, y, width, height);
   m_irGridTypeGroup.SetValue(GRID_TYPE_BUY);
   m_ipGridPositionSize.UpdateValue(4);
   m_ipGridNextLotMultiplier.UpdateValue(1);
   m_ipnGridEntryPrice.UpdateValue(bid);
   m_ipGridStopLossPoints.UpdateValue(3000);
   m_ipGridTakeProfitPoints.UpdateValue(10000);
   m_ipnBaseLot.UpdateDisabled(false);
   m_ipnBaseLot.UpdateValue(0.01);

   RefreshInputBaselot();
   ChartRedraw(g_chartId);
}

void TDTabGrid::StartDraw(int x, int y, int width, int height) {
   m_x              = x;
   m_y              = y;
   m_width          = width;
   m_height         = height;

   int fontSize     = 10;

   int yOffsetPanel = 10;

   m_ipSelectGrid.SetZOrderBase(100);
   m_ipSelectGrid.StartDraw(m_x + 10, m_y + yOffsetPanel, 90, fontSize);

   uiCommon.CreateLabel(
      g_chartId,
      m_labelGridInfo,
      "Grid Info:",
      m_x + 110,
      m_y + yOffsetPanel + 4,
      fontSize - 2,
      clrWhite
   );
   uiCommon.setZOrder(g_chartId, m_labelGridInfo, 100);

   uiCommon.CreateButton(
      g_chartId,
      m_btnEditGrid,
      "Edit Grid",
      m_x + m_width - 160,
      m_y + yOffsetPanel,
      70,
      20
   );
   uiCommon.setFontSize(g_chartId, m_btnEditGrid, fontSize - 2);
   uiCommon.setZOrder(g_chartId, m_btnEditGrid, 100);

   uiCommon.CreateButton(
      g_chartId,
      m_btnCloseGrid,
      "Close Grid",
      m_x + m_width - 80,
      m_y + yOffsetPanel,
      70,
      20
   );
   uiCommon.setFontSize(g_chartId, m_btnCloseGrid, fontSize - 2);
   uiCommon.setZOrder(g_chartId, m_btnCloseGrid, 100);

   yOffsetPanel += 25;

   m_table.StartDraw(x, y + yOffsetPanel);
   yOffsetPanel += m_table.GetHeight() + 5;

   uiCommon.CreateLabel(
      g_chartId,
      m_labelTotalProfit,
      "Total Profit: 0",
      m_x + 250,
      m_y + yOffsetPanel - 30,
      fontSize - 2,
      clrWhite
   );
   uiCommon.setZOrder(g_chartId, m_labelTotalProfit, 100);

   // Create input radio for grid type selection
   uiCommon.CreateLabel(
      g_chartId,
      m_ObjLabelGridTypeName,
      "Grid Type:",
      m_x + 10,
      m_y + yOffsetPanel,
      fontSize,
      clrWhite
   );
   uiCommon.setZOrder(g_chartId, m_ObjLabelGridTypeName, 100);

   m_irGridTypeBuy.SetValue(GRID_TYPE_BUY);
   m_irGridTypeBuy.SetChecked(m_gridType == GRID_TYPE_BUY);
   m_irGridTypeBuy.StartDraw(m_x + 100, m_y + yOffsetPanel, "Grid Buy", fontSize);

   m_irGridTypeSell.SetValue(GRID_TYPE_SELL);
   m_irGridTypeSell.SetChecked(m_gridType == GRID_TYPE_SELL);
   m_irGridTypeSell.StartDraw(m_x + 200, m_y + yOffsetPanel, "Grid Sell", fontSize);

   yOffsetPanel += 30;

   // Create input for grid name
   m_iptGridName.SetLabel("Grid Name:", clrWhite);
   m_iptGridName.SetZOrderBase(101);
   m_iptGridName.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   // Create grid position size, base lot và next lot multiplier
   m_ipGridPositionSize.SetLabel("Position Size:", clrWhite);
   m_ipGridPositionSize.SetStep(1);
   m_ipGridPositionSize.SetDigits(0);
   m_ipGridPositionSize.SetValue(1);
   m_ipGridPositionSize.SetMinValue(1);
   m_ipGridPositionSize
      .StartDraw(m_x + ((m_width - 40) / 3) + 20, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipGridNextLotMultiplier.SetLabel("Next Lot Multiplier:", clrWhite);
   m_ipGridNextLotMultiplier.SetStep(0.1);
   m_ipGridNextLotMultiplier.SetDigits(1);
   m_ipGridNextLotMultiplier.SetValue(1.5);
   m_ipGridNextLotMultiplier.SetMinValue(1.0);
   m_ipGridNextLotMultiplier.StartDraw(
      m_x + 2 * ((m_width - 40) / 3) + 30,
      m_y + yOffsetPanel,
      (m_width - 40) / 3,
      fontSize
   );

   yOffsetPanel += 50;
   // Create input entry price
   m_ipnGridEntryPrice.SetLabel("EntryPrice:", clrWhite);
   m_ipnGridEntryPrice.SetStep(0.0001);
   m_ipnGridEntryPrice.SetDigits(_Digits);
   m_ipnGridEntryPrice.SetValue(0);
   m_ipnGridEntryPrice.SetMinValue(0);
   m_ipnGridEntryPrice.SetDisabled(!m_enableCustomPrice);
   m_ipnGridEntryPrice.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipcCustomEntryPrice.SetValue(m_enableCustomPrice);
   m_ipcCustomEntryPrice.SetLabel("Custom");
   m_ipcCustomEntryPrice.SetZOrderBase(101);
   m_ipcCustomEntryPrice.StartDraw(m_x + 10 + 90, m_y + yOffsetPanel, fontSize);

   // Create input stop loss points
   m_ipGridStopLossPoints.SetLabel("SL Points:", clrWhite);
   m_ipGridStopLossPoints.SetStep(100);
   m_ipGridStopLossPoints.SetDigits(0);
   m_ipGridStopLossPoints.SetValue(10);
   m_ipGridStopLossPoints.SetMinValue(0);
   m_ipGridStopLossPoints
      .StartDraw(m_x + ((m_width - 40) / 3) + 20, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   // Create input take profit points
   m_ipGridTakeProfitPoints.SetLabel("TP Points:", clrWhite);
   m_ipGridTakeProfitPoints.SetStep(100);
   m_ipGridTakeProfitPoints.SetDigits(0);
   m_ipGridTakeProfitPoints.SetValue(10);
   m_ipGridTakeProfitPoints.SetMinValue(0);
   m_ipGridTakeProfitPoints.StartDraw(
      m_x + 2 * ((m_width - 40) / 3) + 30,
      m_y + yOffsetPanel,
      (m_width - 40) / 3,
      fontSize
   );

   yOffsetPanel += 50;

   m_ipsVolumeRiskType.SetLabel("Volume Risk:", clrWhite);
   m_ipsVolumeRiskType.SetZOrderBase(101);
   m_ipsVolumeRiskType.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipnBaseLot.SetLabel("Base Lot:", clrWhite);
   m_ipnBaseLot.SetStep(0.01);
   m_ipnBaseLot.SetDigits(2);
   m_ipnBaseLot.SetValue(0.01);
   m_ipnBaseLot.SetMinValue(0.01);
   m_ipnBaseLot
      .StartDraw(m_x + ((m_width - 40) / 3) + 20, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipnVolumeRiskValue.SetLabel("Risk Money ($): ", clrWhite);
   m_ipnVolumeRiskValue.SetStep(1);
   m_ipnVolumeRiskValue.SetDigits(0);
   m_ipnVolumeRiskValue.SetValue(0);
   m_ipnVolumeRiskValue.SetMinValue(0);
   m_ipnVolumeRiskValue.SetDisabled(true);
   m_ipnVolumeRiskValue.StartDraw(
      m_x + 2 * ((m_width - 40) / 3) + 30,
      m_y + yOffsetPanel,
      (m_width - 40) / 3,
      fontSize
   );

   yOffsetPanel += 55;

   m_ipcTrailingStopEnable.SetValue(m_enableTrailingStop);
   m_ipcTrailingStopEnable.SetLabel("Enable Trailing Stop");
   m_ipcTrailingStopEnable.SetZOrderBase(101);
   m_ipcTrailingStopEnable.StartDraw(m_x + 10, m_y + yOffsetPanel, fontSize);

   yOffsetPanel = yOffsetPanel + 20;
   m_ipnTrailingStopStart.SetLabel("TS Start (points):", clrWhite);
   m_ipnTrailingStopStart.SetStep(100);
   m_ipnTrailingStopStart.SetDigits(0);
   m_ipnTrailingStopStart.SetValue(500);
   m_ipnTrailingStopStart.SetMinValue(0);
   m_ipnTrailingStopStart.SetDisabled(!m_enableTrailingStop);
   m_ipnTrailingStopStart.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipnTrailingStopStep.SetLabel("TS Step (points):", clrWhite);
   m_ipnTrailingStopStep.SetStep(1);
   m_ipnTrailingStopStep.SetDigits(0);
   m_ipnTrailingStopStep.SetValue(10);
   m_ipnTrailingStopStep.SetMinValue(0);
   m_ipnTrailingStopStep.SetDisabled(!m_enableTrailingStop);
   m_ipnTrailingStopStep
      .StartDraw(m_x + ((m_width - 40) / 3) + 20, m_y + yOffsetPanel, (m_width - 40) / 3, fontSize);

   m_ipnTrailingStopDistance.SetLabel("TS Distance (points):", clrWhite);
   m_ipnTrailingStopDistance.SetStep(100);
   m_ipnTrailingStopDistance.SetDigits(0);
   m_ipnTrailingStopDistance.SetValue(200);
   m_ipnTrailingStopDistance.SetMinValue(0);
   m_ipnTrailingStopDistance.SetDisabled(!m_enableTrailingStop);
   m_ipnTrailingStopDistance.StartDraw(
      m_x + 2 * ((m_width - 40) / 3) + 30,
      m_y + yOffsetPanel,
      (m_width - 40) / 3,
      fontSize
   );

   yOffsetPanel += 55;

   // Tạo nút START GRID
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnStartGridName,
      "START GRID",
      m_x + m_width / 2 - 60,
      m_y + yOffsetPanel,
      120,
      35
   );
   uiCommon.setTextColor(g_chartId, m_ObjBtnStartGridName, g_clrBtnGreenText);
   uiCommon.setBackgroundColor(g_chartId, m_ObjBtnStartGridName, g_clrBtnGreenBg);
   uiCommon.setBorderColor(g_chartId, m_ObjBtnStartGridName, g_clrBtnGreenBorder);
   uiCommon.setZOrder(g_chartId, m_ObjBtnStartGridName, 100);

   uiCommon.CreateHorizontalLine(g_chartId, m_lineAverageOpenPriceName, 0);
   uiCommon.setLineStyle(g_chartId, m_lineAverageOpenPriceName, STYLE_DOT);
   uiCommon.setLineWidth(g_chartId, m_lineAverageOpenPriceName, 2);
   uiCommon.setLineColor(g_chartId, m_lineAverageOpenPriceName, clrOrange);
   uiCommon.setZOrder(g_chartId, m_lineAverageOpenPriceName, 50);
   uiCommon.setShow(g_chartId, m_lineAverageOpenPriceName, false);

   uiCommon.CreateHorizontalLine(g_chartId, m_lineTSPeakPriceName, 0);
   uiCommon.setLineStyle(g_chartId, m_lineTSPeakPriceName, STYLE_DOT);
   uiCommon.setLineWidth(g_chartId, m_lineTSPeakPriceName, 1);
   uiCommon.setLineColor(g_chartId, m_lineTSPeakPriceName, clrPurple);
   uiCommon.setZOrder(g_chartId, m_lineTSPeakPriceName, 50);
   uiCommon.setShow(g_chartId, m_lineTSPeakPriceName, false);

   uiCommon.CreateHorizontalLine(g_chartId, m_lineTSStopLossPriceName, 0);
   uiCommon.setLineStyle(g_chartId, m_lineTSStopLossPriceName, STYLE_DOT);
   uiCommon.setLineWidth(g_chartId, m_lineTSStopLossPriceName, 2);
   uiCommon.setLineColor(g_chartId, m_lineTSStopLossPriceName, clrViolet);
   uiCommon.setZOrder(g_chartId, m_lineTSStopLossPriceName, 50);
   uiCommon.setShow(g_chartId, m_lineTSStopLossPriceName, false);
}

void TDTabGrid::DestroyDraw() {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      ObjectDelete(g_chartId, objNameList[i]);
   }
}

void TDTabGrid::RefreshData() {
   // Update entry price
   if(!m_enableCustomPrice) {
      double priceOpen = 0;
      if(m_gridType == GRID_TYPE_BUY) {
         priceOpen = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      } else if(m_gridType == GRID_TYPE_SELL) {
         priceOpen = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      m_ipnGridEntryPrice.UpdateValue(priceOpen);
   }

   // Vẫn còn đang sót trường hợp mới mở được 1 lệnh đã TP luôn, thì các lệnh còn lại vẫn ở trạng
   // thái Order, chưa xử lý tiếp
   int gridListSize = ArraySize(g_gridList);
   if(m_gridIndex < 0 || m_gridIndex >= gridListSize) {
      for(int i = 0; i < m_tableRows; i++) {
         m_table.SetRowData(i, "");
         for(int j = 0; j < m_tableColumns - 1; j++) {
            m_table.SetCell(i, j, "-", CELL_TYPE_TEXT);
         }
         uiCommon.setShow(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
      }
      return;
   }

   // Update GridIndex
   m_ipSelectGrid.UpdateValue(m_gridIndex);

   uiCommon.setText(
      g_chartId,
      m_labelGridInfo,
      StringFormat(
         "%s | %s | SL=%.5f | TP=%.5f",
         g_gridList[m_gridIndex].symbol,
         StringSubstr(EnumToString((ENUM_GRID_TYPE)g_gridList[m_gridIndex].gridType), 10),
         g_gridList[m_gridIndex].stopLossPrice,
         g_gridList[m_gridIndex].takeProfitPrice
      )
   );

   int gridOrderCount    = ArraySize(g_gridList[m_gridIndex].ticketOrderList);
   int gridPositionCount = ArraySize(g_gridList[m_gridIndex].ticketPositionList);
   int gridDealCount     = ArraySize(g_gridList[m_gridIndex].ticketDealList);

   int gridItemCount     = gridOrderCount + gridPositionCount + gridDealCount;

   m_table.setPagination(
      m_gridIndex != -1 ? gridItemCount : 0,
      m_gridIndex != -1 ? m_tablePage : 1
   );

   for(int i = 0; i < m_tableRows; i++) {
      int gridItemIndex = i + (m_tablePage - 1) * m_tableRows;

      if(gridItemIndex >= gridItemCount) {
         m_table.SetRowData(i, "");
         for(int j = 0; j < m_tableColumns; j++) {
            m_table.SetCell(i, j, "-", CELL_TYPE_TEXT);
         }
         uiCommon.setShow(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
         continue;
      }

      if(gridItemIndex < gridOrderCount) {
         int    orderIndex  = gridItemIndex;
         ulong  ticketOrder = g_gridList[m_gridIndex].ticketOrderList[orderIndex].ticketOrder;
         string rowsData[8];
         rowsData[0] = IntegerToString(ticketOrder);
         rowsData[1]
            = "ORDER_"
              + StringSubstr(
                 EnumToString(
                    (ENUM_ORDER_STATE)g_gridList[m_gridIndex].ticketOrderList[orderIndex].orderState
                 ),
                 12
              );
         rowsData[2]
            = DoubleToString(g_gridList[m_gridIndex].ticketOrderList[orderIndex].volume, 2);
         rowsData[3] = DoubleToString(
            g_gridList[m_gridIndex].ticketOrderList[orderIndex].priceOpen,
            _Digits
         );
         rowsData[4] = "-";
         rowsData[5] = "-";
         rowsData[6] = "-";
         rowsData[7] = "-";
         for(int j = 0; j < 7; j++) {
            m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
         }
         m_table.SetCell(i, 7, "Close", CELL_TYPE_BUTTON);
         uiCommon.setShow(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), true);
         m_table.SetRowData(
            i,
            "TicketType=TicketOrder;TicketId=" + IntegerToString(ticketOrder) + ";"
         );
      } else if(gridItemIndex < gridOrderCount + gridPositionCount) {
         int   positionIndex = gridItemIndex - gridOrderCount;
         ulong ticketPosition
            = g_gridList[m_gridIndex].ticketPositionList[positionIndex].ticketPosition;
         if(PositionSelectByTicket(ticketPosition)) {
            double profit = PositionGetDouble(POSITION_PROFIT);

            string rowsData[8];
            rowsData[0] = IntegerToString(ticketPosition);
            rowsData[1] = StringSubstr(
               EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),
               14
            );
            rowsData[2] = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
            rowsData[3] = DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), _Digits);
            rowsData[4] = "-";
            rowsData[5] = DoubleToString(profit, 4);
            rowsData[6] = DoubleToString(PositionGetDouble(POSITION_SWAP), 4);

            g_gridList[m_gridIndex].ticketPositionList[positionIndex].profit = profit;

            for(int j = 0; j < 7; j++) {
               m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
            }
            m_table.SetCell(i, 7, "Close", CELL_TYPE_BUTTON);
            uiCommon.setShow(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), true);
            m_table.SetRowData(
               i,
               "TicketType=TicketPosition;TicketId=" + IntegerToString(ticketPosition) + ";"
            );
            // Set profit color
            color profitColor;
            if(profit > 0) {
               profitColor = g_clrTextGreen; // Green
            } else if(profit < 0) {
               profitColor = g_clrTextRed;   // Red
            } else {
               profitColor = g_textColorBaseLight;
            }
            m_table.SetCellTextColor(i, 5, profitColor);
         }
      } else {
         int    closeIndex = gridItemIndex - gridOrderCount - gridPositionCount;
         double profit     = g_gridList[m_gridIndex].ticketDealList[closeIndex].profit;

         string rowsData[8];
         rowsData[0]
            = IntegerToString(g_gridList[m_gridIndex].ticketDealList[closeIndex].ticketPosition);
         rowsData[1]
            = "DEAL_"
              + StringSubstr(
                 EnumToString(
                    (ENUM_DEAL_REASON)g_gridList[m_gridIndex].ticketDealList[closeIndex].dealReason
                 ),
                 12
              );
         rowsData[2] = DoubleToString(g_gridList[m_gridIndex].ticketDealList[closeIndex].volume, 2);
         rowsData[3]
            = DoubleToString(g_gridList[m_gridIndex].ticketDealList[closeIndex].priceOpen, _Digits);
         rowsData[4] = DoubleToString(
            g_gridList[m_gridIndex].ticketDealList[closeIndex].closePrice,
            _Digits
         );
         rowsData[5] = DoubleToString(profit, 4);
         rowsData[6] = DoubleToString(g_gridList[m_gridIndex].ticketDealList[closeIndex].swap, 4);
         for(int j = 0; j < 7; j++) {
            m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
         }
         uiCommon.setShow(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
         m_table.SetRowData(i, "");
         // Set profit color
         color profitColor;
         if(profit > 0) {
            profitColor = g_clrTextGreen; // Green
         } else if(profit < 0) {
            profitColor = g_clrTextRed;   // Red
         } else {
            profitColor = g_textColorBaseLight;
         }
         m_table.SetCellTextColor(i, 5, profitColor);
         m_table.SetCellTextFontFamily(i, 5, "Arial Bold");
      }
   }

   // Tính totalProfit
   double totalProfit = 0;
   for(int i = 0; i < gridPositionCount; i++) {
      totalProfit += g_gridList[m_gridIndex].ticketPositionList[i].profit;
   }
   for(int i = 0; i < gridDealCount; i++) {
      totalProfit += g_gridList[m_gridIndex].ticketDealList[i].profit;
   }
   string totalProfitText = StringFormat("Total Profit:  %.5f", totalProfit);

   // Set profit color
   color profitColor;
   if(totalProfit > 0) {
      profitColor = g_clrTextGreen; // Green
   } else if(totalProfit < 0) {
      profitColor = g_clrTextRed;   // Red
   } else {
      profitColor = g_textColorBaseLight;
   }
   uiCommon.setText(g_chartId, m_labelTotalProfit, totalProfitText);
   uiCommon.setTextColor(g_chartId, m_labelTotalProfit, profitColor);

   double averageOpenPrice = g_gridList[m_gridIndex].averageOpenPrice;
   double tsPeakPrice      = g_gridList[m_gridIndex].tsPeakPrice;
   double stopLossPrice    = g_gridList[m_gridIndex].stopLossPrice;
   if(averageOpenPrice != 0) {
      uiCommon.setLinePrice(g_chartId, m_lineAverageOpenPriceName, averageOpenPrice);
      uiCommon.setLinePrice(g_chartId, m_lineTSPeakPriceName, tsPeakPrice);
      uiCommon.setLinePrice(g_chartId, m_lineTSStopLossPriceName, stopLossPrice);

      uiCommon.setLineColor(g_chartId, m_lineAverageOpenPriceName, clrOrange);
      if(g_gridList[m_gridIndex].tsStarted) {
         uiCommon.setLineColor(g_chartId, m_lineTSPeakPriceName, clrPurple);
         uiCommon.setLineColor(g_chartId, m_lineTSStopLossPriceName, clrViolet);
      } else {
         uiCommon.setLineColor(g_chartId, m_lineTSPeakPriceName, clrBrown);
         uiCommon.setLineColor(g_chartId, m_lineTSStopLossPriceName, clrSaddleBrown);
      }

      uiCommon.setShow(g_chartId, m_lineAverageOpenPriceName, true);
      uiCommon.setShow(g_chartId, m_lineTSPeakPriceName, true);
      uiCommon.setShow(g_chartId, m_lineTSStopLossPriceName, true);
   } else {
      uiCommon.setShow(g_chartId, m_lineAverageOpenPriceName, false);
      uiCommon.setShow(g_chartId, m_lineTSPeakPriceName, false);
      uiCommon.setShow(g_chartId, m_lineTSStopLossPriceName, false);
   }
}

void TDTabGrid::ClickBtnEditGrid() {
   ObjectSetInteger(g_chartId, m_btnEditGrid, OBJPROP_STATE, false);
   m_popupEdit.SetPosition(m_x + m_width + 5, m_y);
   m_popupEdit.SetSize(200, 200);
   m_popupEdit.OpenPopup(g_gridList[m_gridIndex].gridName);
}

void TDTabGrid::HandleClosePosition(ulong ticketId) {
   if(!PositionSelectByTicket(ticketId)) {
      return;
   }
   string symbol = PositionGetString(POSITION_SYMBOL);
   string type   = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string volume = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
   string profit = DoubleToString(PositionGetDouble(POSITION_PROFIT), 4);

   int    answer = MessageBox(
      "Close position?\n\n" + "Symbol: " + symbol + "\n" + "Type: " + type + "\n"
         + "Volume: " + volume + "\n" + "Profit: " + profit,
      "Confirm Close Position",
      MB_YESNO | MB_ICONQUESTION
   );

   if(answer == IDYES || (bool)MQLInfoInteger(MQL_TESTER)) {
      cTrade.PositionClose(ticketId);
      RefreshData();
   }
}

void TDTabGrid::HandleCloseOrder(ulong ticketId) {
   if(!OrderSelect(ticketId)) {
      return;
   }
   string symbol = OrderGetString(ORDER_SYMBOL);
   string type   = (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY) ? "BUY" : "SELL";
   string volume = DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT), 2);

   int    answer = MessageBox(
      "Close order?\n\n" + "Symbol: " + symbol + "\n" + "Type: " + type + "\n"
         + "Volume: " + volume,
      "Confirm Close Order",
      MB_YESNO | MB_ICONQUESTION
   );

   // Trong môi trường tester, không hiện MessageBox
   if(answer == IDYES || (bool)MQLInfoInteger(MQL_TESTER)) {
      cTrade.OrderDelete(ticketId);
      RefreshData();
   }
}

void TDTabGrid::ClickBtnCloseGrid() {
   ObjectSetInteger(g_chartId, m_btnCloseGrid, OBJPROP_STATE, false);

   int gridListSize = ArraySize(g_gridList);

   if(m_gridIndex < 0 || m_gridIndex >= gridListSize) {
      Print("No active grid to close.");
      MessageBox("No active grid to close.", "Error", MB_OK | MB_ICONINFORMATION);
      return;
   }

   int answer = MessageBox(
      "Are you sure you want to close the grid? All open positions will be closed and pending "
      "orders will be canceled.",
      "Confirm Close Grid",
      MB_YESNO | MB_ICONQUESTION
   );

   // Trong môi trường tester, không hiện MessageBox
   if(answer == IDYES || (bool)MQLInfoInteger(MQL_TESTER)) {
      // Đóng tất cả vị thế liên quan đến grid này
      for(int i = 0; i < ArraySize(g_gridList[m_gridIndex].ticketOrderList); i++) {
         ulong ticket = g_gridList[m_gridIndex].ticketOrderList[i].ticketOrder;
         if(OrderSelect(ticket)) {
            cTrade.OrderDelete(ticket);
         }
      }
      for(int i = 0; i < ArraySize(g_gridList[m_gridIndex].ticketPositionList); i++) {
         ulong ticket = g_gridList[m_gridIndex].ticketPositionList[i].ticketPosition;
         if(PositionSelectByTicket(ticket)) {
            cTrade.PositionClose(ticket);
         }
      }

      RefreshData();
   }
}

void TDTabGrid::ClickBtnStartGrid() {
   ObjectSetInteger(g_chartId, m_ObjBtnStartGridName, OBJPROP_STATE, false);
   string gridNameNew = m_iptGridName.GetValue();
   if(StringLen(gridNameNew) == 0) {
      Print("Grid name cannot be empty. Please enter a valid grid name.");
      MessageBox(
         "Grid name cannot be empty. Please enter a valid grid name.",
         "Error",
         MB_OK | MB_ICONINFORMATION
      );
      return;
   }

   m_iptGridName.UpdateValue("Grid_" + IntegerToString(ArraySize(g_gridList) + 2));

   double bid              = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask              = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int    positionSize     = (int)m_ipGridPositionSize.GetValue();
   double baseLot          = m_ipnBaseLot.GetValue();
   double lotMultiplier    = m_ipGridNextLotMultiplier.GetValue();

   double entryPrice       = 0;
   double stopLossPoints   = m_ipGridStopLossPoints.GetValue();
   double takeProfitPoints = m_ipGridTakeProfitPoints.GetValue();
   double stopLossPrice    = 0;
   double takeProfitPrice  = 0;

   if(m_gridType == GRID_TYPE_BUY) {
      entryPrice      = m_enableCustomPrice ? m_ipnGridEntryPrice.GetValue() : bid;
      stopLossPrice   = entryPrice - stopLossPoints * _Point;
      takeProfitPrice = entryPrice + takeProfitPoints * _Point;
      if(entryPrice > bid) {
         Print("Entry price is above current price for Buy Grid. Please adjust the entry price.");
         MessageBox(
            "Entry price is above current price for Buy Grid. Please adjust the entry price.",
            "Error",
            MB_OK | MB_ICONINFORMATION
         );
         return;
      }
   }
   if(m_gridType == GRID_TYPE_SELL) {
      entryPrice      = m_enableCustomPrice ? m_ipnGridEntryPrice.GetValue() : ask;
      stopLossPrice   = entryPrice + stopLossPoints * _Point;
      takeProfitPrice = entryPrice - takeProfitPoints * _Point;
      if(entryPrice < ask) {
         Print("Entry price is below current price for Sell Grid. Please adjust the entry price.");
         MessageBox(
            "Entry price is below current price for Sell Grid. Please adjust the entry price.",
            "Error",
            MB_OK | MB_ICONINFORMATION
         );
         return;
      }
   }

   double lotStep      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double lotSize      = baseLot;
   int    slPointsStep = (int)MathFloor(stopLossPoints / positionSize);
   int    tpPointsStep = (int)MathFloor(takeProfitPoints / positionSize);

   int    gridIndex    = -1;
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].gridName == gridNameNew) {
         gridIndex = i;
         break;
      }
   }

   if(gridIndex == -1) {
      gridIndex = ArraySize(g_gridList);
      ArrayResize(g_gridList, gridIndex + 1);
      g_gridList[gridIndex].gridType           = m_gridType;
      g_gridList[gridIndex].gridName           = gridNameNew;
      g_gridList[gridIndex].symbol             = _Symbol;
      g_gridList[gridIndex].stopLossPrice      = stopLossPrice;
      g_gridList[gridIndex].takeProfitPrice    = takeProfitPrice;

      g_gridList[gridIndex].enableTrailingStop = m_enableTrailingStop;
      g_gridList[gridIndex].tsStartPoints      = (int)m_ipnTrailingStopStart.GetValue();
      g_gridList[gridIndex].tsStepPoints       = (int)m_ipnTrailingStopStep.GetValue();
      g_gridList[gridIndex].tsDistancePoints   = (int)m_ipnTrailingStopDistance.GetValue();
   }

   double priceOpen = entryPrice;
   for(int i = 0; i < positionSize; i++) {
      if(m_gridType == GRID_TYPE_BUY) {
         bool result = cTrade.BuyLimit(
            lotSize,
            priceOpen,
            _Symbol,
            stopLossPrice,
            takeProfitPrice,
            ORDER_TIME_GTC,
            0,
            GridNameKey + "=" + gridNameNew + ";"
         );
         if(result) {
            lotSize   = MathFloor(lotSize * lotMultiplier / lotStep) * lotStep;
            priceOpen = priceOpen - slPointsStep * _Point;
         }
      }
      if(m_gridType == GRID_TYPE_SELL) {
         bool result = cTrade.SellLimit(
            lotSize,
            priceOpen,
            _Symbol,
            stopLossPrice,
            takeProfitPrice,
            ORDER_TIME_GTC,
            0,
            GridNameKey + "=" + gridNameNew + ";"
         );
         if(result) {
            lotSize   = MathFloor(lotSize * lotMultiplier / lotStep) * lotStep;
            priceOpen = priceOpen + slPointsStep * _Point;
         }
      }
   }
   m_gridIndex++;
   m_ipSelectGrid.AddOption(m_gridIndex, gridNameNew);
   m_ipSelectGrid.StartRedraw();

   RefreshData();
}

void TDTabGrid::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_popupEdit.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipSelectGrid.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_table.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_irGridTypeGroup.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_iptGridName.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipGridPositionSize.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipGridNextLotMultiplier.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnGridEntryPrice.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcCustomEntryPrice.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipGridStopLossPoints.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipGridTakeProfitPoints.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipsVolumeRiskType.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnBaseLot.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnVolumeRiskValue.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipcTrailingStopEnable.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopStart.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopStep.OnRealtimeEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopDistance.OnRealtimeEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnStartGridName) {
         ClickBtnStartGrid();
      } else if(sparam == m_btnEditGrid) {
         ClickBtnEditGrid();
      } else if(sparam == m_btnCloseGrid) {
         ClickBtnCloseGrid();
      }

      string prefixObjCellContent = m_table.GetObjectNamePrefix(OBJ_CELL_CONTENT);
      if(StringFind(sparam, prefixObjCellContent) == 0) {
         ObjectSetInteger(g_chartId, sparam, OBJPROP_STATE, false);

         int row, col;
         m_table.GetCellPositionByObjectName(OBJ_CELL_CONTENT, sparam, row, col);
         string rowData    = m_table.GetRowData(row);
         string ticketType = UtilString::GetValueFromEncodedString(rowData, "TicketType");
         string ticketId   = UtilString::GetValueFromEncodedString(rowData, "TicketId");

         if(ticketType == "TicketOrder") {
            HandleCloseOrder(StringToInteger(ticketId));
         } else if(ticketType == "TicketPosition") {
            HandleClosePosition(StringToInteger(ticketId));
         }
      }
   }
}

void TDTabGrid::OnStrategyTesterEvent() {
   m_popupEdit.OnStrategyTesterEvent();
   m_ipSelectGrid.OnStrategyTesterEvent();
   m_table.OnStrategyTesterEvent();
   m_irGridTypeGroup.OnStrategyTesterEvent();
   m_iptGridName.OnStrategyTesterEvent();
   m_ipGridPositionSize.OnStrategyTesterEvent();
   m_ipGridNextLotMultiplier.OnStrategyTesterEvent();
   m_ipnGridEntryPrice.OnStrategyTesterEvent();
   m_ipcCustomEntryPrice.OnStrategyTesterEvent();
   m_ipGridStopLossPoints.OnStrategyTesterEvent();
   m_ipGridTakeProfitPoints.OnStrategyTesterEvent();
   m_ipsVolumeRiskType.OnStrategyTesterEvent();
   m_ipnBaseLot.OnStrategyTesterEvent();
   m_ipnVolumeRiskValue.OnStrategyTesterEvent();
   m_ipcTrailingStopEnable.OnStrategyTesterEvent();
   m_ipnTrailingStopStart.OnStrategyTesterEvent();
   m_ipnTrailingStopStep.OnStrategyTesterEvent();
   m_ipnTrailingStopDistance.OnStrategyTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnStartGridName)) {
      ClickBtnStartGrid();
   }
   if(uiCommon.getState(g_chartId, m_btnEditGrid)) {
      ClickBtnEditGrid();
   }
   if(uiCommon.getState(g_chartId, m_btnCloseGrid)) {
      ClickBtnCloseGrid();
   }
   for(int i = 0; i < m_tableRows; i++) {
      bool isEmptyRow = (m_table.GetRowData(i) == "");
      if(isEmptyRow)
         continue;

      bool isBtnClosePressed
         = uiCommon.getState(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7));
      if(isBtnClosePressed) {
         uiCommon.setState(g_chartId, m_table.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
         string rowData    = m_table.GetRowData(i);
         string ticketType = UtilString::GetValueFromEncodedString(rowData, "TicketType");
         string ticketId   = UtilString::GetValueFromEncodedString(rowData, "TicketId");

         if(ticketType == "TicketOrder") {
            HandleCloseOrder(StringToInteger(ticketId));
         } else if(ticketType == "TicketPosition") {
            HandleClosePosition(StringToInteger(ticketId));
         }
      }
   }
}