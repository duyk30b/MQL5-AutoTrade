#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIPanel.mqh>
#include <AutoTrade/UI/UITable.mqh>

UITable                uiTable;

input ENUM_TABLE_THEME InpTheme = THEME_DARK;

struct ButtonInfo {
   int    row;
   int    col;
   string objectName;
};
class TDTablePositions : public UITableListener {
 public:
   int        m_x;
   int        m_y;
   int        m_rows;
   int        m_cols;
   int        m_page;

   bool       m_isMinimized;

   ButtonInfo g_buttons[];   // Store button info for event handling
   color      clrBtnBg;
   color      clrTextGreen;  // Green
   color      clrTextRed;    // Red
   color      clrTextOrange; // Orange

   color      textColorBase;

   bool       Initialization() {
      m_rows        = 6;
      m_cols        = 9;
      m_page        = 1;
      m_isMinimized = false;

      // clang-format off
      if (InpTheme == THEME_DARK) {
         clrBtnBg          = C'70,130,180';
         clrTextGreen = C'50,205,50';  // Green
         clrTextRed = C'255,80,80';  // Red
         clrTextOrange = C'255,165,0'; // Orange
         textColorBase   = C'200,200,200';
      } else if (InpTheme == THEME_LIGHT) {
         clrBtnBg          = C'30,144,255';
         clrTextGreen = C'0,150,0';     // Green
         clrTextRed = C'200,0,0';     // Red
         clrTextOrange = C'255,165,0'; // Orange
         textColorBase   = C'60,60,80';
      }
      // clang-format on

      uiTable.SetListener(&this);
      uiTable.Initialization(0, "PositionTable", m_rows, m_cols);

      uiTable.SetTheme(InpTheme);
      uiTable.SetZOrderBase(2);
      uiTable.SetHeader(0, "Symbol", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(1, "Type", 50, CELL_TYPE_TEXT);
      uiTable.SetHeader(2, "Volume", 50, CELL_TYPE_TEXT);
      uiTable.SetHeader(3, "Price", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(4, "SL", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(5, "TP", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(6, "Profit", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(7, "Edit", 50, CELL_TYPE_BUTTON);
      uiTable.SetHeader(8, "Close", 50, CELL_TYPE_BUTTON);

      return true;
   }

   virtual void onPageChange(int newPage) override {
      m_page = newPage;
      RefreshTicketPositionsData();
   }

   int  GetHeight() { return uiTable.GetHeight(); }

   void StartDraw(int x, int y);

   int  GetObjectNameList(string &objNameList[]) { return uiTable.GetObjectNameList(objNameList); }

   void SetIsMinimized(bool _isMinimized) { m_isMinimized = _isMinimized; }

   void RefreshTicketPositionsData() {
      int totalPositions = PositionsTotal();
      uiTable.setPagination(totalPositions, m_page);

      // Add positions to table
      for(int i = 0; i < m_rows; i++) {
         int positionIndex = (m_page - 1) * m_rows + i;

         if(positionIndex >= totalPositions) {
            uiTable.SetRowData(i, 0);
            for(int j = 0; j <= 6; j++) {
               uiTable.SetCell(i, j, "-", CELL_TYPE_TEXT);
            }
            uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
            uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8), false);
            continue;
         }

         ulong ticketId = PositionGetTicket(positionIndex);
         if(ticketId > 0) {
            uiTable.SetRowData(i, ticketId);
            string symbol = PositionGetString(POSITION_SYMBOL);
            int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double price  = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double sl     = PositionGetDouble(POSITION_SL);
            double tp     = PositionGetDouble(POSITION_TP);

            string rowData[9];
            rowData[0] = symbol;
            rowData[1] = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            rowData[2] = DoubleToString(volume, 2);
            rowData[3] = DoubleToString(price, digits);
            rowData[4] = (sl > 0) ? DoubleToString(sl, digits) : "-";
            rowData[5] = (tp > 0) ? DoubleToString(tp, digits) : "-";
            rowData[6] = DoubleToString(profit, 4);

            for(int j = 0; j <= 6; j++) {
               uiTable.SetCell(i, j, rowData[j], CELL_TYPE_TEXT);
            }
            uiTable.SetCell(i, 7, "Edit", CELL_TYPE_BUTTON);
            uiTable.SetCell(i, 8, "Close", CELL_TYPE_BUTTON);
            if(!m_isMinimized) {
               uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7), true);
               uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8), true);
            }

            // Set profit color
            color profitColor;
            if(profit > 0) {
               profitColor = clrTextGreen; // Green
            } else if(profit < 0) {
               profitColor = clrTextRed;   // Red
            } else {
               profitColor = textColorBase;
            }
            uiTable.SetCellTextColor(i, 6, profitColor);

            bool enableTrailingStop = false;
            for(int i = 0; i < ArraySize(g_positionList); i++) {
               if(g_positionList[i].ticket == ticketId) {
                  enableTrailingStop = g_positionList[i].enableTrailingStop;
                  break;
               }
            }
            if(enableTrailingStop) {
               uiTable.SetCellTextColor(i, 4, clrTextOrange); // Orange
            } else {
               uiTable.SetCellTextColor(i, 4, textColorBase);
            }

         } else {
            uiTable.SetRowData(i, 0);
            for(int j = 0; j <= 6; j++) {
               uiTable.SetCell(i, j, "ERROR", CELL_TYPE_TEXT);
               uiTable.SetCellTextColor(i, j, clrRed);
            }
            uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
            uiCommon.setShow(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8), false);
            continue;
         }
      }

      // Draw table
      ChartRedraw(g_chartId);
   }

   void HandleClosePosition(ulong ticketId) {
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

      if(answer == IDYES) {
         cTrade.PositionClose(ticketId);
      }
   }

   void HandleEditPosition(ulong ticketId) { openPopupModifyPosition(ticketId); }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      uiTable.OnChartEvent(id, lparam, dparam, sparam);
      if(id == CHARTEVENT_OBJECT_CLICK) {
         string prefixObjCellContent = uiTable.GetObjectNamePrefix(OBJ_CELL_CONTENT);
         if(StringFind(sparam, prefixObjCellContent) == 0) {
            int row, col;
            uiTable.GetCellPositionByObjectName(OBJ_CELL_CONTENT, sparam, row, col);
            ulong ticketId = uiTable.GetRowData(row);
            if(col == 7) {
               HandleEditPosition(ticketId);
            } else if(col == 8) {
               HandleClosePosition(ticketId);
            }
            return true;
         }
      }
      return true;
   }

   void OnMQLTesterEvent() {
      uiTable.OnMQLTesterEvent();
      for(int i = 0; i < m_rows; i++) {
         bool isEmptyRow = (uiTable.GetRowData(i) == 0);
         if(isEmptyRow)
            continue;

         bool isBtnEditPressed
            = uiCommon.getState(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7));
         if(isBtnEditPressed) {
            uiCommon.setState(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7), false);
            ulong ticketId = uiTable.GetRowData(i);
            HandleEditPosition(ticketId);
         }
         bool isBtnClosePressed
            = uiCommon.getState(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8));
         if(isBtnClosePressed) {
            uiCommon.setState(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8), false);
            ulong ticketId = uiTable.GetRowData(i);
            // Do ở môi trường tester, ta sẽ không hiện hộp thoại xác nhận
            cTrade.PositionClose(ticketId);
         }
      }
   };
};

void TDTablePositions::StartDraw(int x, int y) {
   m_x = x;
   m_y = y;
   uiTable.StartDraw(m_x, m_y);
}
