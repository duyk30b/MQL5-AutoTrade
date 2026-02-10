#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIPanel.mqh>
#include <AutoTrade/UI/UITable.mqh>

UIPanel                uiPanelPositionEdit;
UITable                uiTable;
input ENUM_TABLE_THEME InpTheme = THEME_DARK;

struct ButtonInfo {
   int    row;
   int    col;
   string objectName;
};
class TradeDashboardTablePositions {
 public:
   ButtonInfo g_buttons[]; // Store button info for event handling
   color      clrBtnBg;
   color      clrProfitPositive;
   color      clrProfitNegative;
   color      clrProfitNormal;
   int        maxRows;
   int        maxCols;

   bool       Create() {
      maxRows = 6;
      maxCols = 9;
      // clang-format off
      if (InpTheme == THEME_DARK) {
         clrBtnBg          = C'70,130,180';
         clrProfitPositive = C'50,205,50';  // Green
         clrProfitNegative = C'255,80,80';  // Red
         clrProfitNormal   = C'200,200,200';
      } else if (InpTheme == THEME_LIGHT) {
         clrBtnBg          = C'30,144,255';
         clrProfitPositive = C'0,150,0';     // Green
         clrProfitNegative = C'200,0,0';     // Red
         clrProfitNormal   = C'60,60,80';
      }
      // clang-format on

      if(!uiTable.Initialization(0, "PositionTable", panelX, panelY + 35, maxRows, maxCols)) {
         Print("Không thể tạo PositionTable!");
         return false;
      }

      uiTable.SetTheme(InpTheme);
      uiTable.SetZOrderBase(2);
      uiTable.SetHeader(0, "Symbol", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(1, "Type", 50, CELL_TYPE_TEXT);
      uiTable.SetHeader(2, "Volume", 50, CELL_TYPE_TEXT);
      uiTable.SetHeader(3, "Price", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(4, "SL", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(5, "TP", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(6, "Profit", 60, CELL_TYPE_TEXT);
      uiTable.SetHeader(7, "Edit", 50, CELL_TYPE_TEXT);
      uiTable.SetHeader(8, "Close", 50, CELL_TYPE_TEXT);

      uiTable.TableStartDrawBase();

      UpdateTicketPositionsData();
      return true;
   }

   void UpdateTicketPositionsData() {
      int totalPositions = PositionsTotal();
      // Add positions to table
      for(int i = 0; i < maxRows; i++) {
         if(i >= totalPositions) {
            uiTable.SetRowData(i, 0);
            for(int j = 0; j <= 8; j++) {
               uiTable.SetCell(i, j, "-", CELL_TYPE_NONE);
            }
            ObjectDelete(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7));
            ObjectDelete(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8));
            continue;
         }

         ulong ticketId = PositionGetTicket(i);
         if(ticketId > 0) {
            uiTable.SetRowData(i, ticketId);
            string symbol = PositionGetString(POSITION_SYMBOL);
            int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double sl     = PositionGetDouble(POSITION_SL);
            double tp     = PositionGetDouble(POSITION_TP);

            string rowData[9];
            rowData[0] = symbol;
            rowData[1] = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            rowData[2] = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
            rowData[3] = DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), digits);
            rowData[4] = (sl > 0) ? DoubleToString(sl, digits) : "-";
            rowData[5] = (tp > 0) ? DoubleToString(tp, digits) : "-";
            rowData[6] = DoubleToString(profit, 4);

            for(int j = 0; j <= 6; j++) {
               uiTable.SetCell(i, j, rowData[j], CELL_TYPE_TEXT);
            }

            // Set profit color
            color profitColor;
            if(profit > 0) {
               profitColor = clrProfitPositive; // Green
            } else if(profit < 0) {
               profitColor = clrProfitNegative; // Red
            } else {
               profitColor = clrProfitNormal;
            }
            uiTable.SetCellTextColor(i, 6, profitColor);

            // Set button data
            if(uiTable.GetCellType(i, 7) != CELL_TYPE_CUSTOM) {
               CreateCellButton(i, 7, "Edit");
            }
            if(uiTable.GetCellType(i, 8) != CELL_TYPE_CUSTOM) {
               CreateCellButton(i, 8, "Close");
            }

         } else {
            uiTable.SetRowData(i, 0);
            for(int j = 0; j <= 6; j++) {
               uiTable.SetCell(i, j, "ERROR", CELL_TYPE_NONE);
               uiTable.SetCellTextColor(i, j, clrRed);
            }
            ObjectDelete(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 7));
            ObjectDelete(0, uiTable.GetObjectName(OBJ_CELL_CONTENT, i, 8));
         }
      }

      // Draw table
      uiTable.TableRedrawChart();
   }

   void CreateCellButton(int row, int col, string text) {
      int x, y, width, height;
      if(!uiTable.GetCellPosition(row, col, x, y, width, height)) {
         return;
      }

      // Button dimensions
      int btnWidth  = width - 10;
      int btnHeight = height - 8;
      int btnX      = x + 5;
      int btnY      = y + 4;

      // Button name
      string objCellContentName = uiTable.GetObjectName(OBJ_CELL_CONTENT, row, col);
      uiCommon.CreateButton(0, objCellContentName, text, btnWidth, btnHeight, clrWhite, clrBtnBg);
      uiCommon.setPosition(0, objCellContentName, btnX, btnY);
      uiCommon.setFontSize(0, objCellContentName, 8);
      uiCommon.setZOrder(0, objCellContentName, 20);
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

   void HandleEditPosition(ulong ticketId) {
      uiPanelPositionEdit.Initialization(0, "PositionEditPanel", 550, 0, 300, 400);
   }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      if(id == CHARTEVENT_MOUSE_MOVE) {
         int x = (int)lparam;
         int y = (int)dparam;
         uiTable.OnMouseMove(x, y);
         return true;
      }
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
};
