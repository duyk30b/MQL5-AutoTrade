#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIInputRadio.mqh>
#include <AutoTrade/UI/UITable.mqh>

enum ENUM_GRID_TYPE {
   GRID_TYPE_BUY, // Grid loại Buy
   GRID_TYPE_SELL // Grid loại Sell
};

class TDTabGrid {
 private:
   int               m_x;
   int               m_y;
   int               m_width;
   int               m_height;

   UITable           m_table;
   int               m_tableRows;
   int               m_tableColumns;
   int               m_tablePage;

   double            m_currenPrice;

   string            m_ObjLabelGridTypeName;
   ENUM_GRID_TYPE    m_gridType; // Loại grid hiện tại (Buy/Sell)
   UIInputRadio      m_irGridTypeBuy;
   UIInputRadio      m_irGridTypeSell;
   UIInputRadioGroup m_irGridTypeGroup;

   UIInputNumber     m_ipGridEntryPrice;
   UIInputNumber     m_ipGridStopLossPoints;
   UIInputNumber     m_ipGridStopLossPrice;
   UIInputNumber     m_ipGridTakeProfitPoints;
   UIInputNumber     m_ipGridTakeProfitPrice;
   UIInputNumber     m_ipGridPositionSize;
   UIInputNumber     m_ipGridBaseLot;
   UIInputNumber     m_ipGridNextLotMultiplier;

   string            m_ObjBtnStartGridName;

 public:
   void Initialization() {
      m_tableRows    = 6;
      m_tableColumns = 9;
      m_tablePage    = 1;

      m_table.SetCallback(&this, TDTabGrid::OnTableChange);
      m_irGridTypeGroup.SetCallback(&this, TDTabGrid::OnInputRadioChangeGridType);

      m_ipGridEntryPrice.SetCallback(&this, TDTabGrid::OnChangeEntryPrice);
      m_ipGridStopLossPoints.SetCallback(&this, TDTabGrid::OnChangeStopLossPoints);
      m_ipGridTakeProfitPoints.SetCallback(&this, TDTabGrid::OnChangeTakeProfitPoints);
      m_ipGridStopLossPrice.SetCallback(&this, TDTabGrid::OnChangeStopLossPrice);
      m_ipGridTakeProfitPrice.SetCallback(&this, TDTabGrid::OnChangeTakeProfitPrice);

      m_table.Initialization(g_chartId, "TDTabGrid_Table", m_tableRows, m_tableColumns);
      m_table.SetZOrderBase(200);
      m_table.SetHeader(0, "State", 50, CELL_TYPE_TEXT);
      m_table.SetHeader(1, "Symbol", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(2, "Type", 65, CELL_TYPE_TEXT);
      m_table.SetHeader(3, "Volume", 50, CELL_TYPE_TEXT);
      m_table.SetHeader(4, "Open", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(5, "SL", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(6, "TP", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(7, "Close", 55, CELL_TYPE_TEXT);
      m_table.SetHeader(8, "Profit", 60, CELL_TYPE_TEXT);

      m_ObjLabelGridTypeName = "TDTabGrid_LabelGridType";
      m_irGridTypeGroup.AddInputRadio(&m_irGridTypeBuy);
      m_irGridTypeGroup.AddInputRadio(&m_irGridTypeSell);
      m_irGridTypeBuy.Initialization(g_chartId, "TDTabGrid_IpRadioGridBuy");
      m_irGridTypeSell.Initialization(g_chartId, "TDTabGrid_IpRadioGridSell");

      m_ipGridEntryPrice.Initialization(g_chartId, "TDTabGrid_IpGridEntryPrice");
      m_ipGridStopLossPoints.Initialization(g_chartId, "TDTabGrid_IpGridStopLossPoints");
      m_ipGridStopLossPrice.Initialization(g_chartId, "TDTabGrid_IpGridStopLossPrice");
      m_ipGridTakeProfitPoints.Initialization(g_chartId, "TDTabGrid_IpGridTakeProfitPoints");
      m_ipGridTakeProfitPrice.Initialization(g_chartId, "TDTabGrid_IpGridTakeProfitPrice");
      m_ipGridPositionSize.Initialization(g_chartId, "TDTabGrid_IpGridPositionSize");
      m_ipGridBaseLot.Initialization(g_chartId, "TDTabGrid_IpGridBaseLot");
      m_ipGridNextLotMultiplier.Initialization(g_chartId, "TDTabGrid_IpGridNextLotMultiplier");

      m_ObjBtnStartGridName = "TDTabGrid_BtnStartGrid";
   }

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
         // Xử lý khi thay đổi loại grid (Buy/Sell)
         self.m_gridType      = (ENUM_GRID_TYPE)(int)value;
         double stopLossPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            stopLossPrice = self.m_currenPrice - self.m_ipGridStopLossPoints.GetValue() * _Point;
         } else {
            stopLossPrice = self.m_currenPrice + self.m_ipGridStopLossPoints.GetValue() * _Point;
         }
         self.m_ipGridStopLossPrice.UpdateValue(stopLossPrice);

         double takeProfitPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            takeProfitPrice
               = self.m_currenPrice + self.m_ipGridTakeProfitPoints.GetValue() * _Point;
         } else {
            takeProfitPrice
               = self.m_currenPrice - self.m_ipGridTakeProfitPoints.GetValue() * _Point;
         }
         self.m_ipGridTakeProfitPrice.UpdateValue(takeProfitPrice);
         ChartRedraw(g_chartId);
      }
   }

   static void OnChangeEntryPrice(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_currenPrice = value;
         // Cập nhật lại Stop Loss và Take Profit theo Entry Price mới
         double stopLossPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            stopLossPrice = self.m_currenPrice - self.m_ipGridStopLossPoints.GetValue() * _Point;
         } else {
            stopLossPrice = self.m_currenPrice + self.m_ipGridStopLossPoints.GetValue() * _Point;
         }
         self.m_ipGridStopLossPrice.UpdateValue(stopLossPrice);

         double takeProfitPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            takeProfitPrice
               = self.m_currenPrice + self.m_ipGridTakeProfitPoints.GetValue() * _Point;
         } else {
            takeProfitPrice
               = self.m_currenPrice - self.m_ipGridTakeProfitPoints.GetValue() * _Point;
         }
         self.m_ipGridTakeProfitPrice.UpdateValue(takeProfitPrice);
      }
   }

   static void OnChangeStopLossPoints(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         double stopLossPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            stopLossPrice = self.m_currenPrice - value * _Point;
         } else {
            stopLossPrice = self.m_currenPrice + value * _Point;
         }
         self.m_ipGridStopLossPrice.UpdateValue(stopLossPrice);
      }
   }

   static void OnChangeTakeProfitPoints(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         double takeProfitPrice = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            takeProfitPrice = self.m_currenPrice + value * _Point;
         } else {
            takeProfitPrice = self.m_currenPrice - value * _Point;
         }
         self.m_ipGridTakeProfitPrice.UpdateValue(takeProfitPrice);
      }
   }

   static void OnChangeStopLossPrice(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         double stopLossPoints = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            stopLossPoints = NormalizeDouble((self.m_currenPrice - value) / _Point, _Digits);
         } else {
            stopLossPoints = NormalizeDouble((value - self.m_currenPrice) / _Point, _Digits);
         }
         self.m_ipGridStopLossPoints.UpdateValue(stopLossPoints);
      }
   }

   static void OnChangeTakeProfitPrice(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabGrid *self = (TDTabGrid *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         double takeProfitPoints = 0;
         if(self.m_gridType == GRID_TYPE_BUY) {
            takeProfitPoints = NormalizeDouble((value - self.m_currenPrice) / _Point, _Digits);
         } else {
            takeProfitPoints = NormalizeDouble((self.m_currenPrice - value) / _Point, _Digits);
         }
         self.m_ipGridTakeProfitPoints.UpdateValue(takeProfitPoints);
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      string tableObjNameList[];
      int    tableObjCount = m_table.GetObjectNameList(tableObjNameList);

      string irGridTypeGroupObjNameList[];
      int irGridTypeGroupObjCount = m_irGridTypeGroup.GetObjectNameList(irGridTypeGroupObjNameList);

      string m_ipGridEntryPriceObjNameList[];
      int    m_ipGridEntryPriceObjCount
         = m_ipGridEntryPrice.GetObjectNameList(m_ipGridEntryPriceObjNameList);

      string m_ipGridStopLossPointsObjNameList[];
      int    m_ipGridStopLossPointsObjCount
         = m_ipGridStopLossPoints.GetObjectNameList(m_ipGridStopLossPointsObjNameList);

      string m_ipGridStopLossPriceObjNameList[];
      int    m_ipGridStopLossPriceObjCount
         = m_ipGridStopLossPrice.GetObjectNameList(m_ipGridStopLossPriceObjNameList);

      string m_ipGridTakeProfitPointsObjNameList[];
      int    m_ipGridTakeProfitPointsObjCount
         = m_ipGridTakeProfitPoints.GetObjectNameList(m_ipGridTakeProfitPointsObjNameList);

      string m_ipGridTakeProfitPriceObjNameList[];
      int    m_ipGridTakeProfitPriceObjCount
         = m_ipGridTakeProfitPrice.GetObjectNameList(m_ipGridTakeProfitPriceObjNameList);

      string m_ipGridPositionSizeObjNameList[];
      int    m_ipGridPositionSizeObjCount
         = m_ipGridPositionSize.GetObjectNameList(m_ipGridPositionSizeObjNameList);

      string m_ipGridBaseLotObjNameList[];
      int m_ipGridBaseLotObjCount = m_ipGridBaseLot.GetObjectNameList(m_ipGridBaseLotObjNameList);

      string m_ipGridNextLotMultiplierObjNameList[];
      int    m_ipGridNextLotMultiplierObjCount
         = m_ipGridNextLotMultiplier.GetObjectNameList(m_ipGridNextLotMultiplierObjNameList);

      int count = 0;
      ArrayResize(
         objNameList,
         tableObjCount + 1 + irGridTypeGroupObjCount + m_ipGridEntryPriceObjCount
            + m_ipGridStopLossPointsObjCount + m_ipGridStopLossPriceObjCount
            + m_ipGridTakeProfitPointsObjCount + m_ipGridTakeProfitPriceObjCount
            + m_ipGridPositionSizeObjCount + m_ipGridBaseLotObjCount
            + m_ipGridNextLotMultiplierObjCount + 1
      );

      for(int i = 0; i < tableObjCount; i++) {
         objNameList[count++] = tableObjNameList[i];
      }

      objNameList[count++] = m_ObjLabelGridTypeName;
      for(int i = 0; i < irGridTypeGroupObjCount; i++) {
         objNameList[count++] = irGridTypeGroupObjNameList[i];
      }

      for(int i = 0; i < m_ipGridEntryPriceObjCount; i++) {
         objNameList[count++] = m_ipGridEntryPriceObjNameList[i];
      }
      for(int i = 0; i < m_ipGridStopLossPointsObjCount; i++) {
         objNameList[count++] = m_ipGridStopLossPointsObjNameList[i];
      }
      for(int i = 0; i < m_ipGridStopLossPriceObjCount; i++) {
         objNameList[count++] = m_ipGridStopLossPriceObjNameList[i];
      }
      for(int i = 0; i < m_ipGridTakeProfitPointsObjCount; i++) {
         objNameList[count++] = m_ipGridTakeProfitPointsObjNameList[i];
      }
      for(int i = 0; i < m_ipGridTakeProfitPriceObjCount; i++) {
         objNameList[count++] = m_ipGridTakeProfitPriceObjNameList[i];
      }
      for(int i = 0; i < m_ipGridPositionSizeObjCount; i++) {
         objNameList[count++] = m_ipGridPositionSizeObjNameList[i];
      }
      for(int i = 0; i < m_ipGridBaseLotObjCount; i++) {
         objNameList[count++] = m_ipGridBaseLotObjNameList[i];
      }
      for(int i = 0; i < m_ipGridNextLotMultiplierObjCount; i++) {
         objNameList[count++] = m_ipGridNextLotMultiplierObjNameList[i];
      }

      objNameList[count++] = m_ObjBtnStartGridName;
      return count;
   }

   void OpenTab(int x, int y, int width, int height);
   void StartDraw(int x, int y, int width, int height);
   void DestroyDraw();
   void RefreshData();
   void ClickBtnStartGrid();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void TDTabGrid::OpenTab(int x, int y, int width, int height) {
   SymbolInfoTick(_Symbol, Tick);
   double bid    = Tick.bid;
   double ask    = Tick.ask;

   m_currenPrice = bid;

   StartDraw(x, y, width, height);
   m_irGridTypeGroup.SetValue(GRID_TYPE_BUY);
   m_ipGridPositionSize.UpdateValue(4);
   m_ipGridBaseLot.UpdateValue(0.01);
   m_ipGridNextLotMultiplier.UpdateValue(2);
   m_ipGridEntryPrice.UpdateValue(m_currenPrice);
   m_ipGridStopLossPoints.UpdateValue(1000);
   m_ipGridStopLossPrice.UpdateValue(m_currenPrice - 1000 * _Point);
   m_ipGridTakeProfitPoints.UpdateValue(500);
   m_ipGridTakeProfitPrice.UpdateValue(m_currenPrice + 500 * _Point);
   ChartRedraw(g_chartId);
}

void TDTabGrid::StartDraw(int x, int y, int width, int height) {
   m_x              = x;
   m_y              = y;
   m_width          = width;
   m_height         = height;
   int yOffsetPanel = 0;

   m_table.StartDraw(x, y);
   yOffsetPanel += m_table.GetHeight() + 5;

   // Create input radio for grid type selection
   uiCommon.CreateLabel(
      g_chartId,
      m_ObjLabelGridTypeName,
      "Grid Type:",
      m_x + 10,
      m_y + yOffsetPanel,
      10,
      clrWhite
   );
   uiCommon.setZOrder(g_chartId, m_ObjLabelGridTypeName, 100);
   m_irGridTypeBuy.SetValue(GRID_TYPE_BUY);
   m_irGridTypeBuy.SetChecked(m_gridType == GRID_TYPE_BUY);
   m_irGridTypeBuy.StartDraw(m_x + 100, m_y + yOffsetPanel, "Grid Buy", 10);

   m_irGridTypeSell.SetValue(GRID_TYPE_SELL);
   m_irGridTypeSell.SetChecked(m_gridType == GRID_TYPE_SELL);
   m_irGridTypeSell.StartDraw(m_x + 200, m_y + yOffsetPanel, "Grid Sell", 10);
   yOffsetPanel += 30;

   // Create grid position size, base lot và next lot multiplier
   m_ipGridPositionSize.SetLabel("Position Size:", clrWhite);
   m_ipGridPositionSize.SetStep(1);
   m_ipGridPositionSize.SetDigits(0);
   m_ipGridPositionSize.SetValue(1);
   m_ipGridPositionSize.SetMinValue(1);
   m_ipGridPositionSize.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 30) / 2, 45);

   // Create input entry price
   m_ipGridEntryPrice.SetLabel("Entry Price:", clrWhite);

   m_ipGridEntryPrice.SetStep(0.0001);
   m_ipGridEntryPrice.SetDigits(_Digits);
   m_ipGridEntryPrice.SetValue(0);
   m_ipGridEntryPrice.SetMinValue(0);
   m_ipGridEntryPrice.StartDraw(m_x + m_width / 2 + 5, m_y + yOffsetPanel, (m_width - 30) / 2, 45);
   yOffsetPanel += 55;

   m_ipGridBaseLot.SetLabel("Base Lot:", clrWhite);
   m_ipGridBaseLot.SetStep(0.01);
   m_ipGridBaseLot.SetDigits(2);
   m_ipGridBaseLot.SetValue(0.01);
   m_ipGridBaseLot.SetMinValue(0.01);
   m_ipGridBaseLot.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 30) / 2, 45);

   m_ipGridNextLotMultiplier.SetLabel("Next Lot Multiplier:", clrWhite);
   m_ipGridNextLotMultiplier.SetStep(0.1);
   m_ipGridNextLotMultiplier.SetDigits(1);
   m_ipGridNextLotMultiplier.SetValue(1.5);
   m_ipGridNextLotMultiplier.SetMinValue(1.0);
   m_ipGridNextLotMultiplier
      .StartDraw(m_x + m_width / 2 + 5, m_y + yOffsetPanel, (m_width - 30) / 2, 45);
   yOffsetPanel += 55;

   // Create input stop loss points
   m_ipGridStopLossPoints.SetLabel("Stop Loss Points:", clrWhite);
   m_ipGridStopLossPoints.SetStep(10);
   m_ipGridStopLossPoints.SetDigits(0);
   m_ipGridStopLossPoints.SetValue(10);
   m_ipGridStopLossPoints.SetMinValue(0);
   m_ipGridStopLossPoints.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 30) / 2, 45);

   // Create input stop loss price
   m_ipGridStopLossPrice.SetLabel("Stop Loss Price:", clrWhite);
   m_ipGridStopLossPrice.SetStep(0.0001);
   m_ipGridStopLossPrice.SetDigits(_Digits);
   m_ipGridStopLossPrice.SetValue(0);
   m_ipGridStopLossPrice.SetMinValue(0);
   m_ipGridStopLossPrice
      .StartDraw(m_x + m_width / 2 + 5, m_y + yOffsetPanel, (m_width - 30) / 2, 45);
   yOffsetPanel += 55;

   // Create input take profit points
   m_ipGridTakeProfitPoints.SetLabel("Take Profit Points:", clrWhite);
   m_ipGridTakeProfitPoints.SetStep(10);
   m_ipGridTakeProfitPoints.SetDigits(0);
   m_ipGridTakeProfitPoints.SetValue(10);
   m_ipGridTakeProfitPoints.SetMinValue(0);
   m_ipGridTakeProfitPoints.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 30) / 2, 45);

   // Create input take profit price
   m_ipGridTakeProfitPrice.SetLabel("Take Profit Price:", clrWhite);
   m_ipGridTakeProfitPrice.SetStep(0.0001);
   m_ipGridTakeProfitPrice.SetDigits(_Digits);
   m_ipGridTakeProfitPrice.SetValue(0);
   m_ipGridTakeProfitPrice.SetMinValue(0);
   m_ipGridTakeProfitPrice
      .StartDraw(m_x + m_width / 2 + 5, m_y + yOffsetPanel, (m_width - 30) / 2, 45);

   yOffsetPanel += 65;

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
}

void TDTabGrid::DestroyDraw() {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      ObjectDelete(g_chartId, objNameList[i]);
   }
}

void TDTabGrid::RefreshData() {
   // Vẫn còn đang sót trường hợp mới mở được 1 lệnh đã TP luôn, thì các lệnh còn lại vẫn ở trạng
   // thái Order, chưa xử lý tiếp
   int gridListSize = ArraySize(g_gridList);

   for(int i = 0; i < m_tableRows; i++) {
      int index = i + (m_tablePage - 1) * m_tableRows;

      if(index >= gridListSize) {
         m_table.SetRowData(i, 0);
         for(int j = 0; j < m_tableColumns; j++) {
            m_table.SetCell(i, j, "-", CELL_TYPE_TEXT);
         }
         continue;
      }
      if(g_gridList[index].gridState == GRID_STATE_ORDER) {
         if(OrderSelect(g_gridList[i].ticketOrder)) {
            string rowsData[9];
            rowsData[0] = "Order";
            rowsData[1] = OrderGetString(ORDER_SYMBOL);
            // Cắt bỏ "ORDER_TYPE_" để chỉ còn "BUY"/"SELL"
            rowsData[2]
               = StringSubstr(EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)), 11);
            rowsData[3] = DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT), 2);
            rowsData[4] = DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN), _Digits);
            rowsData[5] = DoubleToString(OrderGetDouble(ORDER_SL), _Digits);
            rowsData[6] = DoubleToString(OrderGetDouble(ORDER_TP), _Digits);
            rowsData[7] = "-";
            rowsData[8] = "-";
            for(int j = 0; j < 9; j++) {
               m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
            }
         }
      } else if(g_gridList[index].gridState == GRID_STATE_POSITION) {
         if(PositionSelectByTicket(g_gridList[i].ticketPosition)) {
            double profit = PositionGetDouble(POSITION_PROFIT);

            string rowsData[9];
            rowsData[0] = "Position";
            rowsData[1] = PositionGetString(POSITION_SYMBOL);
            rowsData[2] = StringSubstr(
               EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)),
               14
            );
            rowsData[3] = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
            rowsData[4] = DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), _Digits);
            rowsData[5] = DoubleToString(PositionGetDouble(POSITION_SL), _Digits);
            rowsData[6] = DoubleToString(PositionGetDouble(POSITION_TP), _Digits);
            rowsData[7] = "-";
            rowsData[8] = DoubleToString(profit, 4);

            for(int j = 0; j < 9; j++) {
               m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
            }
            // Set profit color
            color profitColor;
            if(profit > 0) {
               profitColor = g_clrTextGreen; // Green
            } else if(profit < 0) {
               profitColor = g_clrTextRed;   // Red
            } else {
               profitColor = g_textColorBaseLight;
            }
            m_table.SetCellTextColor(i, 8, profitColor);
         }
      } else if(g_gridList[index].gridState == GRID_STATE_CLOSED) {
         double profit = g_gridList[index].profit;

         string rowsData[9];
         rowsData[0] = "Close";
         rowsData[1] = g_gridList[index].symbol;
         rowsData[2]
            = StringSubstr(EnumToString((ENUM_POSITION_TYPE)g_gridList[index].positionType), 14);
         rowsData[3] = DoubleToString(g_gridList[index].volume, 2);
         rowsData[4] = DoubleToString(g_gridList[index].openPrice, _Digits);
         rowsData[5] = DoubleToString(g_gridList[index].stopLossPrice, _Digits);
         rowsData[6] = DoubleToString(g_gridList[index].takeProfitPrice, _Digits);
         rowsData[7] = DoubleToString(g_gridList[index].closePrice, _Digits);
         rowsData[8] = DoubleToString(profit, 4);
         for(int j = 0; j < 9; j++) {
            m_table.SetCell(i, j, rowsData[j], CELL_TYPE_TEXT);
         }
         // Set profit color
         color profitColor;
         if(profit > 0) {
            profitColor = g_clrTextGreen; // Green
         } else if(profit < 0) {
            profitColor = g_clrTextRed;   // Red
         } else {
            profitColor = g_textColorBaseLight;
         }
         m_table.SetCellTextColor(i, 8, profitColor);
         m_table.SetCellTextFontFamily(i, 8, "Arial Bold");
      }

      else {
         m_table.SetCell(i, 0, IntegerToString(g_gridList[index].gridState), CELL_TYPE_TEXT);
         for(int j = 1; j < m_tableColumns; j++) {
            m_table.SetCell(i, j, "-", CELL_TYPE_TEXT);
         }
      }
   }
}

void TDTabGrid::ClickBtnStartGrid() {
   ObjectSetInteger(g_chartId, m_ObjBtnStartGridName, OBJPROP_STATE, false);
   // Tạo gird mới, với số position dựa trên thông tin đã nhập
   int    positionSize     = (int)m_ipGridPositionSize.GetValue();
   double baseLot          = m_ipGridBaseLot.GetValue();
   double lotMultiplier    = m_ipGridNextLotMultiplier.GetValue();

   double entryPrice       = m_ipGridEntryPrice.GetValue();
   double stopLossPrice    = m_ipGridStopLossPrice.GetValue();
   double takeProfitPrice  = m_ipGridTakeProfitPrice.GetValue();
   double stopLossPoints   = m_ipGridStopLossPoints.GetValue();
   double takeProfitPoints = m_ipGridTakeProfitPoints.GetValue();
   double lotStep          = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double lotSize          = baseLot;
   double openPrice        = entryPrice;
   int    slPointsStep     = (int)MathFloor(stopLossPoints / positionSize);
   int    tpPointsStep     = (int)MathFloor(takeProfitPoints / positionSize);

   ArrayResize(g_gridList, positionSize);

   for(int i = 0; i < positionSize; i++) {
      string id                     = "Type=GRID;Index=" + IntegerToString(i);
      g_gridList[i].id              = id;
      g_gridList[i].gridState       = GRID_STATE_ORDER;
      g_gridList[i].symbol          = _Symbol;
      g_gridList[i].volume          = lotSize;
      g_gridList[i].openPrice       = openPrice;
      g_gridList[i].stopLossPrice   = stopLossPrice;
      g_gridList[i].takeProfitPrice = takeProfitPrice;

      if(m_gridType == GRID_TYPE_BUY) {
         bool result = cTrade.BuyLimit(
            lotSize,
            openPrice,
            _Symbol,
            stopLossPrice,
            takeProfitPrice,
            ORDER_TIME_GTC,
            0,
            id
         );
         if(result) {
            g_gridList[i].ticketOrder = cTrade.ResultOrder();
            lotSize                   = MathFloor(lotSize * lotMultiplier / lotStep) * lotStep;
            openPrice                 = openPrice - slPointsStep * _Point;
         }
      }
      if(m_gridType == GRID_TYPE_SELL) {
         bool result = cTrade.SellLimit(
            lotSize,
            openPrice,
            _Symbol,
            stopLossPrice,
            takeProfitPrice,
            ORDER_TIME_GTC,
            0,
            id
         );
         if(result) {
            g_gridList[i].ticketOrder = cTrade.ResultOrder();
            lotSize                   = MathFloor(lotSize * lotMultiplier / lotStep) * lotStep;
            openPrice                 = openPrice + slPointsStep * _Point;
         }
      }
   }
}

void TDTabGrid::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_table.OnChartEvent(id, lparam, dparam, sparam);
   m_irGridTypeGroup.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridEntryPrice.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridStopLossPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridStopLossPrice.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridTakeProfitPoints.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridTakeProfitPrice.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridPositionSize.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridBaseLot.OnChartEvent(id, lparam, dparam, sparam);
   m_ipGridNextLotMultiplier.OnChartEvent(id, lparam, dparam, sparam);
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnStartGridName) {
         ClickBtnStartGrid();
      }
   }
}

void TDTabGrid::OnMQLTesterEvent() {
   m_table.OnMQLTesterEvent();
   m_irGridTypeGroup.OnMQLTesterEvent();
   m_ipGridEntryPrice.OnMQLTesterEvent();
   m_ipGridStopLossPoints.OnMQLTesterEvent();
   m_ipGridStopLossPrice.OnMQLTesterEvent();
   m_ipGridTakeProfitPoints.OnMQLTesterEvent();
   m_ipGridTakeProfitPrice.OnMQLTesterEvent();
   m_ipGridPositionSize.OnMQLTesterEvent();
   m_ipGridBaseLot.OnMQLTesterEvent();
   m_ipGridNextLotMultiplier.OnMQLTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnStartGridName)) {
      ClickBtnStartGrid();
   }
}