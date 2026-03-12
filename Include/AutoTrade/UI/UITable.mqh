//+------------------------------------------------------------------+
//|                                                      UITable.mqh |
//|                     Pure UI Table - Rendering Only              |
//+------------------------------------------------------------------+
#ifndef UI_TABLE_MQH
#define UI_TABLE_MQH

#property copyright "UITable Library"
#property link ""
#property version "1.00"
#property strict

#include <AutoTrade/UI/UIDefines.mqh>

//+------------------------------------------------------------------+
//| Enum for table themes                                             |
//+------------------------------------------------------------------+
enum ENUM_TABLE_THEME { THEME_DARK, THEME_LIGHT };

//+------------------------------------------------------------------+
//| Enum for cell content type                                       |
//+------------------------------------------------------------------+
enum ENUM_CELL_TYPE {
   CELL_TYPE_NONE,
   CELL_TYPE_TEXT,   // Plain text
   CELL_TYPE_BUTTON, // Button
   CELL_TYPE_CUSTOM  // Custom object (button, image, etc.) - EA handles creation
};

enum ENUM_TABLE_OBJECT_TYPE {
   OBJ_HEADER_BG,
   OBJ_HEADER_TEXT,
   OBJ_CELL_BG,
   OBJ_CELL_CONTENT,
   OBJ_PAGINATION_TOTAL,
   OBJ_PAGINATION_PREVIOUS_PAGE,
   OBJ_PAGINATION_PAGE,
   OBJ_PAGINATION_NEXT_PAGE,
};

struct TableCell {
   int            row;
   int            col;
   string         text;
   ENUM_CELL_TYPE cellType;
};

struct TableRow {
   string    data;
   TableCell cells[];
};

struct TableHeader {
   string         headerText;
   int            width;
   ENUM_CELL_TYPE cellType;
};

class UITable {
 private:
   UIListener *m_listener;
   FOnChange   m_callback;
   void       *m_parent; // lưu pointer đến object chủ

   // Basic properties
   long   m_chartId; // Chart ID
   string m_name;
   int    m_x;
   int    m_y;

   int    m_total;
   int    m_page;
   int    m_pageTotal;

   // Table structure
   TableRow    m_tableRows[];
   TableHeader m_tableHeader[];
   int         m_rowHeight;
   int         m_headerHeight;
   int         m_zOrderBase;

   // Theme colors
   color m_textColorBase;
   color m_headerTextColor;
   color m_headerBgColor;
   color m_contentBtnBgColor;
   color m_cellBorderColor;
   color m_rowBgColorOdd;
   color m_rowBgColorEven;
   color m_rowBgColorHover;
   color m_paginationBtnBgColor;
   color m_paginationBtnBorderColor;

   // Current theme
   ENUM_TABLE_THEME m_currentTheme;

   // Hover state
   int m_hoverRow;

   // Font settings
   string m_fontName;
   int    m_fontSize;

   color  GetRowBackgroundColor(int row) {
      if(row == m_hoverRow) {
         return m_rowBgColorHover;
      }
      return (row % 2 == 0) ? m_rowBgColorEven : m_rowBgColorOdd;
   };

   void CreateHeaders();
   void CreateCells();
   void UpdateRowColors(int row);
   void CreatePagination();

 public:
   // Constructor & Destructor
   UITable() {};
   ~UITable() { TableDestroy(); };

   void SetListener(UIListener *listener) { m_listener = listener; };
   void SetCallback(void *ctx, FOnChange cb) {
      m_callback = cb;
      m_parent   = ctx;
   }

   // Khởi tạo panel
   void Initialize(long chartId, string name, int rows, int cols) {
      m_chartId      = chartId;
      m_name         = name;

      m_total        = 0;
      m_page         = 1;
      m_pageTotal    = 1;
      m_rowHeight    = 25;
      m_headerHeight = 30;
      m_hoverRow     = -1;

      m_currentTheme = THEME_DARK;
      m_zOrderBase   = 0;

      ArrayResize(m_tableRows, rows);
      for(int i = 0; i < rows; i++) {
         ArrayResize(m_tableRows[i].cells, cols);
         for(int j = 0; j < cols; j++) {
            m_tableRows[i].cells[j].row      = i;
            m_tableRows[i].cells[j].col      = j;
            m_tableRows[i].cells[j].cellType = CELL_TYPE_NONE;
            m_tableRows[i].cells[j].text     = " ";
         }
      }
      ArrayResize(m_tableHeader, cols);

      // clang-format off
      if (m_currentTheme == THEME_DARK)
      {
         m_headerTextColor = C'220,220,220';
         m_headerBgColor   = C'30,30,90';
         m_textColorBase = C'200,200,200';
         m_contentBtnBgColor = C'70,130,180';
         m_cellBorderColor     = C'60,60,60';
         m_rowBgColorOdd  = C'35,35,35';
         m_rowBgColorEven   = C'45,45,45';
         m_rowBgColorHover      = C'50,50,80';
         m_paginationBtnBgColor     = C'70,70,120';
         m_paginationBtnBorderColor = C'100,100,160';

      } else if (m_currentTheme == THEME_LIGHT)
      {
         m_headerTextColor = clrWhite;
         m_headerBgColor   = C'70,130,180';
         m_textColorBase = C'60,60,80';
         m_contentBtnBgColor = C'30,144,255';
         m_cellBorderColor     = C'210,210,220';
         m_rowBgColorOdd  = clrWhite;
         m_rowBgColorEven   = C'248,248,252';
         m_rowBgColorHover      = C'235,240,255';
         m_paginationBtnBgColor     = C'100,149,237';
         m_paginationBtnBorderColor = C'150,200,255';
      }
      // clang-format on

      m_fontName = "Arial";
      m_fontSize = 8;

      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);
   };

   void TableDestroy();
   int  GetWidth() {
      int with = 0;
      for(int i = 0; i < ArraySize(m_tableHeader); i++) {
         with += m_tableHeader[i].width;
      }
      return with;
   };
   int GetHeight() {
      int height = m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight) + 30;
      return height;
   };
   ENUM_CELL_TYPE GetCellType(int row, int col) { return m_tableRows[row].cells[col].cellType; };
   string         GetObjectName(ENUM_TABLE_OBJECT_TYPE tableObjectType, int row = 0, int col = 0) {
      string prefix = GetObjectNamePrefix(tableObjectType);
      switch(tableObjectType) {
         case OBJ_HEADER_BG: {
            return prefix + "_" + IntegerToString(col);
         };
         case OBJ_HEADER_TEXT: {
            return prefix + "_" + IntegerToString(col);
         };
         case OBJ_CELL_BG: {
            return prefix + "_" + IntegerToString(row) + "_" + IntegerToString(col);
         }
         case OBJ_CELL_CONTENT: {
            return prefix + "_" + IntegerToString(row) + "_" + IntegerToString(col);
         }
         default: return prefix;
      }
   };
   string GetObjectNamePrefix(ENUM_TABLE_OBJECT_TYPE tableObjectType) {
      switch(tableObjectType) {
         case OBJ_HEADER_BG: {
            return m_name + "_" + "headerBg";
         };
         case OBJ_HEADER_TEXT: {
            return m_name + "_" + "headerText";
         };
         case OBJ_CELL_BG: {
            return m_name + "_" + "cellBg";
         }
         case OBJ_CELL_CONTENT: {
            return m_name + "_" + "cellContent";
         }
         case OBJ_PAGINATION_TOTAL: {
            return m_name + "_" + "paginationTotal";
         }
         case OBJ_PAGINATION_PREVIOUS_PAGE: {
            return m_name + "_" + "paginationPrevPage";
         }
         case OBJ_PAGINATION_PAGE: {
            return m_name + "_" + "paginationPage";
         }
         case OBJ_PAGINATION_NEXT_PAGE: {
            return m_name + "_" + "paginationNextPage";
         }

         default: return "unknown";
      }
   };
   int GetObjectNameList(string &objNameList[]) {
      int rowsCount = ArraySize(m_tableRows);
      int colsCount = ArraySize(m_tableHeader);
      int objCount  = (rowsCount + 1) * colsCount * 2 + 4; // Cells + Headers + Background
      ArrayResize(objNameList, objCount);
      int index = 0;
      // Headers
      for(int col = 0; col < colsCount; col++) {
         objNameList[index++] = GetObjectName(OBJ_HEADER_BG, 0, col);
         objNameList[index++] = GetObjectName(OBJ_HEADER_TEXT, 0, col);
      }
      // Cells
      for(int row = 0; row < rowsCount; row++) {
         for(int col = 0; col < colsCount; col++) {
            objNameList[index++] = GetObjectName(OBJ_CELL_BG, row, col);
            objNameList[index++] = GetObjectName(OBJ_CELL_CONTENT, row, col);
         }
      }
      objNameList[index++] = GetObjectName(OBJ_PAGINATION_TOTAL, 0, 0);
      objNameList[index++] = GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE, 0, 0);
      objNameList[index++] = GetObjectName(OBJ_PAGINATION_PAGE, 0, 0);
      objNameList[index++] = GetObjectName(OBJ_PAGINATION_NEXT_PAGE, 0, 0);
      return objCount;
   };
   void GetCellPositionByObjectName(
      ENUM_TABLE_OBJECT_TYPE tableObjectType, string objectName, int &row, int &col
   ) {
      string parts[];
      int    count = StringSplit(objectName, '_', parts);

      switch(tableObjectType) {
         case OBJ_HEADER_BG: {
            col = (int)StringToInteger(parts[2]);
         };
         case OBJ_HEADER_TEXT: {
            col = (int)StringToInteger(parts[2]);
         };
         case OBJ_CELL_BG: {
            row = (int)StringToInteger(parts[2]);
            col = (int)StringToInteger(parts[3]);
         }
         case OBJ_CELL_CONTENT: {
            row = (int)StringToInteger(parts[2]);
            col = (int)StringToInteger(parts[3]);
         }
      }
   };
   void GetCellPosition(int row, int col, int &x, int &y, int &width, int &height) {
      if(row < 0 || row >= ArraySize(m_tableRows) || col < 0 || col >= ArraySize(m_tableHeader))
         return;

      x = m_x;
      for(int i = 0; i < col; i++) {
         x += m_tableHeader[i].width;
      }

      y      = m_y + m_headerHeight + (row * m_rowHeight);
      width  = m_tableHeader[col].width;
      height = m_rowHeight;
   };
   int GetRowAtPosition(int x, int y) {
      int colsCount  = ArraySize(m_tableHeader);
      int rowsCount  = ArraySize(m_tableRows);

      int totalWidth = 0;
      for(int i = 0; i < colsCount; i++) {
         totalWidth += m_tableHeader[i].width;
      }

      int tableTop    = m_y + m_headerHeight;
      int tableBottom = tableTop + (rowsCount * m_rowHeight);

      if(x >= m_x && x <= m_x + totalWidth && y >= tableTop && y < tableBottom) {
         return (y - tableTop) / m_rowHeight;
      }

      return -1;
   };
   int GetColumnAtPosition(int x, int y) {
      int colsCount = ArraySize(m_tableHeader);

      int xOffset   = m_x;

      for(int col = 0; col < colsCount; col++) {
         if(x >= xOffset && x < xOffset + m_tableHeader[col].width) {
            return col;
         }
         xOffset += m_tableHeader[col].width;
      }

      return -1;
   };
   string GetCellObjectPrefix(int row, int col) {
      return m_name + "_custom_" + IntegerToString(row) + "_" + IntegerToString(col);
   }

   void SetTheme(ENUM_TABLE_THEME theme) { m_currentTheme = theme; }
   void SetZOrderBase(int zOrderBase) { m_zOrderBase = zOrderBase; };
   void SetRowHeight(int height) { m_rowHeight = height; }
   void SetHeaderHeight(int height) { m_headerHeight = height; }
   void SetFont(string fontName, int fontSize) {
      m_fontName = fontName;
      m_fontSize = fontSize;
   };
   void SetTextColorBase(color textColorBase) { m_textColorBase = textColorBase; }

   void ClearAllText();

   // Data management
   void SetHeader(
      int columnIndex, string headerText, int width, ENUM_CELL_TYPE cellType = CELL_TYPE_TEXT
   ) {
      m_tableHeader[columnIndex].headerText = headerText;
      m_tableHeader[columnIndex].width      = width;
      m_tableHeader[columnIndex].cellType   = cellType;
   };
   void setPagination(int _total, int _page) {
      m_total          = _total;
      m_page           = _page;
      m_pageTotal      = (_total + ArraySize(m_tableRows) - 1) / ArraySize(m_tableRows);

      string totalText = "Total: " + IntegerToString(m_total);
      string pageText  = IntegerToString(m_page) + " / " + IntegerToString(m_pageTotal);

      string objPaginationTotalName = GetObjectName(OBJ_PAGINATION_TOTAL);
      string objPaginationPageName  = GetObjectName(OBJ_PAGINATION_PAGE);

      ObjectSetString(m_chartId, objPaginationTotalName, OBJPROP_TEXT, totalText);
      ObjectSetString(m_chartId, objPaginationPageName, OBJPROP_TEXT, pageText);
   };
   string GetRowData(int row) { return m_tableRows[row].data; };
   void   SetRowData(int row, string data) { m_tableRows[row].data = data; };

   void   SetCell(int row, int col, string text, ENUM_CELL_TYPE cellType) {
      m_tableRows[row].cells[col].text     = text;
      m_tableRows[row].cells[col].cellType = cellType;
      string cellTextName                  = GetObjectName(OBJ_CELL_CONTENT, row, col);
      ObjectSetString(m_chartId, cellTextName, OBJPROP_TEXT, text);
   };
   void SetCellTextColor(int row, int col, color textColor = clrNONE) {
      string cellTextName = GetObjectName(OBJ_CELL_CONTENT, row, col);
      if(textColor != clrNONE) {
         ObjectSetInteger(m_chartId, cellTextName, OBJPROP_COLOR, textColor);
      }
   };
   void SetCellTextFontFamily(int row, int col, string fontName, int fontSize = -1) {
      string cellTextName = GetObjectName(OBJ_CELL_CONTENT, row, col);
      ObjectSetString(m_chartId, cellTextName, OBJPROP_FONT, fontName);
      if(fontSize != -1) {
         ObjectSetInteger(m_chartId, cellTextName, OBJPROP_FONTSIZE, fontSize);
      }
   };

   void EmitChangePage(int page) {
      if(m_listener != NULL) {
         m_listener.listen(&this, UI_EVENT_CHANGE_PAGE, page);
      }
      if(m_callback != NULL) {
         m_callback(m_parent, UI_EVENT_CHANGE_PAGE, page);
      }
   }

   void StartRedrawChart() { ChartRedraw(m_chartId); };
   void StartDraw(int x, int y);
   void HandleClickBtnPaginationPrevious();
   void HandleClickBtnPaginationNext();
   void OnRealtimeEvent(
      const int id, const long &lparam, const double &dparam, const string &sparam
   );
   void OnStrategyTesterEvent();
};

void UITable::StartDraw(int x, int y) {
   m_x = x;
   m_y = y;
   CreateHeaders();
   CreateCells();
   CreatePagination();
   StartRedrawChart();
}

//+------------------------------------------------------------------+
//| Create headers                                                   |
//+------------------------------------------------------------------+
void UITable::CreateHeaders() {
   int xOffset   = m_x;
   int colsCount = ArraySize(m_tableHeader);
   for(int col = 0; col < colsCount; col++) {
      string objHeaderBgName = GetObjectName(OBJ_HEADER_BG, 0, col);
      if(!ObjectCreate(m_chartId, objHeaderBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
         Print("Failed to create header background: ", objHeaderBgName, " Error: ", GetLastError());
         return;
      }

      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_XDISTANCE, xOffset);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_XSIZE, m_tableHeader[col].width);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_YSIZE, m_headerHeight);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BGCOLOR, m_headerBgColor);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_COLOR, m_cellBorderColor);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_ZORDER, m_zOrderBase + 0);

      string objHeaderTextName = GetObjectName(OBJ_HEADER_TEXT, 0, col);
      if(!ObjectCreate(m_chartId, objHeaderTextName, OBJ_LABEL, 0, 0, 0)) {
         Print("Failed to create header text: ", objHeaderTextName, " Error: ", GetLastError());
         return;
      }
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_XDISTANCE, xOffset + 5);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_YDISTANCE, m_y + 8);
      ObjectSetString(m_chartId, objHeaderTextName, OBJPROP_TEXT, m_tableHeader[col].headerText);
      ObjectSetString(m_chartId, objHeaderTextName, OBJPROP_FONT, m_fontName);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_FONTSIZE, m_fontSize + 1);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_COLOR, m_headerTextColor);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_ZORDER, m_zOrderBase + 1);

      xOffset += m_tableHeader[col].width;
   }
}

//+------------------------------------------------------------------+
//| Create cells                                                     |
//+------------------------------------------------------------------+
void UITable::CreateCells() {
   int rowsCount = ArraySize(m_tableRows);
   int colsCount = ArraySize(m_tableHeader);

   for(int row = 0; row < rowsCount; row++) {
      int   xOffset    = m_x;
      int   yPos       = m_y + m_headerHeight + (row * m_rowHeight);
      color rowBgColor = GetRowBackgroundColor(row);

      for(int col = 0; col < colsCount; col++) {
         // Cell background
         string objCellBgName = GetObjectName(OBJ_CELL_BG, row, col);
         if(!ObjectCreate(m_chartId, objCellBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
            Print("Failed to create cell background: ", objCellBgName, " Error: ", GetLastError());
            return;
         }
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_XDISTANCE, xOffset);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_XSIZE, m_tableHeader[col].width);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_YSIZE, m_rowHeight);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BGCOLOR, rowBgColor);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_COLOR, m_cellBorderColor);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BACK, false);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_HIDDEN, true);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_ZORDER, m_zOrderBase + 0);

         if(m_tableHeader[col].cellType == CELL_TYPE_TEXT) {
            string objCellContentName = GetObjectName(OBJ_CELL_CONTENT, row, col);
            string text               = m_tableRows[row].cells[col].text;
            if(!ObjectCreate(m_chartId, objCellContentName, OBJ_LABEL, 0, 0, 0)) {
               Print(
                  "Failed to create cell content: ",
                  objCellContentName,
                  " Error: ",
                  GetLastError()
               );
               return;
            }
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_XDISTANCE, xOffset + 5);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_YDISTANCE, yPos + 6);
            ObjectSetString(m_chartId, objCellContentName, OBJPROP_TEXT, text);
            ObjectSetString(m_chartId, objCellContentName, OBJPROP_FONT, m_fontName);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_FONTSIZE, m_fontSize);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_COLOR, m_textColorBase);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_HIDDEN, true);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_ZORDER, m_zOrderBase + 1);
         }

         if(m_tableHeader[col].cellType == CELL_TYPE_BUTTON) {
            string objCellContentName = GetObjectName(OBJ_CELL_CONTENT, row, col);
            string text               = m_tableRows[row].cells[col].text;
            if(!ObjectCreate(m_chartId, objCellContentName, OBJ_BUTTON, 0, 0, 0)) {
               Print(
                  "Failed to create cell button: ",
                  objCellContentName,
                  " Error: ",
                  GetLastError()
               );
               return;
            }
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_XDISTANCE, xOffset + 5);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_YDISTANCE, yPos + 4);
            ObjectSetInteger(
               m_chartId,
               objCellContentName,
               OBJPROP_XSIZE,
               m_tableHeader[col].width - 10
            );
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_YSIZE, m_rowHeight - 8);

            ObjectSetString(m_chartId, objCellContentName, OBJPROP_TEXT, text);
            ObjectSetString(m_chartId, objCellContentName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_FONTSIZE, m_fontSize);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_COLOR, clrWhite);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_BGCOLOR, m_contentBtnBgColor);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_BORDER_COLOR, clrSilver);

            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_BACK, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_STATE, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_SELECTED, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_HIDDEN, true);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_ZORDER, m_zOrderBase + 5);
            // tạm thời ẩn đi
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
         }

         xOffset += m_tableHeader[col].width;
      }
   }
}

void UITable::CreatePagination() {
   int btnWidth  = 24;
   int btnHeight = 15;

   // Create Total Label
   string objPaginationTotalName = GetObjectName(OBJ_PAGINATION_TOTAL);
   string paginationText         = "Total: " + IntegerToString(m_total);
   if(!ObjectCreate(m_chartId, objPaginationTotalName, OBJ_LABEL, 0, 0, 0)) {
      Print(
         "Failed to create pagination total label: ",
         objPaginationTotalName,
         " Error: ",
         GetLastError()
      );
      return;
   }
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_XDISTANCE, m_x + 10);
   ObjectSetInteger(
      m_chartId,
      objPaginationTotalName,
      OBJPROP_YDISTANCE,
      m_y + m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight) + 5
   );
   ObjectSetString(m_chartId, objPaginationTotalName, OBJPROP_TEXT, paginationText);
   ObjectSetString(m_chartId, objPaginationTotalName, OBJPROP_FONT, m_fontName);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_COLOR, m_textColorBase);

   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objPaginationTotalName, OBJPROP_ZORDER, m_zOrderBase + 1);

   // Create Previous Page Button
   string objPaginationPreviousPageName = GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE);
   if(!ObjectCreate(m_chartId, objPaginationPreviousPageName, OBJ_BUTTON, 0, 0, 0)) {
      Print(
         "Failed to create pagination previous page button: ",
         objPaginationPreviousPageName,
         " Error: ",
         GetLastError()
      );
      return;
   }
   ObjectSetInteger(
      m_chartId,
      objPaginationPreviousPageName,
      OBJPROP_XDISTANCE,
      m_x + GetWidth() - 10 - btnWidth - 40 - 10 - btnWidth

   );
   ObjectSetInteger(
      m_chartId,
      objPaginationPreviousPageName,
      OBJPROP_YDISTANCE,
      m_y + m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight) + 5
   );
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_XSIZE, 24);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_YSIZE, 15);
   ObjectSetString(m_chartId, objPaginationPreviousPageName, OBJPROP_TEXT, "«");
   ObjectSetString(m_chartId, objPaginationPreviousPageName, OBJPROP_FONT, m_fontName);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(
      m_chartId,
      objPaginationPreviousPageName,
      OBJPROP_BGCOLOR,
      m_paginationBtnBgColor
   );
   ObjectSetInteger(
      m_chartId,
      objPaginationPreviousPageName,
      OBJPROP_BORDER_COLOR,
      m_paginationBtnBorderColor
   );
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objPaginationPreviousPageName, OBJPROP_ZORDER, m_zOrderBase + 1);

   // Create Page Label
   string objPaginationPageName = GetObjectName(OBJ_PAGINATION_PAGE);
   string pageText              = IntegerToString(m_page) + " / " + IntegerToString(m_pageTotal);

   if(!ObjectCreate(m_chartId, objPaginationPageName, OBJ_LABEL, 0, 0, 0)) {
      Print(
         "Failed to create pagination page label: ",
         objPaginationPageName,
         " Error: ",
         GetLastError()
      );
      return;
   }
   ObjectSetInteger(
      m_chartId,
      objPaginationPageName,
      OBJPROP_XDISTANCE,
      m_x + GetWidth() - 10 - btnWidth - 40
   );

   ObjectSetInteger(
      m_chartId,
      objPaginationPageName,
      OBJPROP_YDISTANCE,
      m_y + m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight) + 5
   );
   ObjectSetString(m_chartId, objPaginationPageName, OBJPROP_TEXT, pageText);
   ObjectSetString(m_chartId, objPaginationPageName, OBJPROP_FONT, m_fontName);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_COLOR, m_textColorBase);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objPaginationPageName, OBJPROP_ZORDER, m_zOrderBase + 1);

   // Create Next Page Button
   string objPaginationNextPageName = GetObjectName(OBJ_PAGINATION_NEXT_PAGE);
   if(!ObjectCreate(m_chartId, objPaginationNextPageName, OBJ_BUTTON, 0, 0, 0)) {
      Print(
         "Failed to create pagination next page button: ",
         objPaginationNextPageName,
         " Error: ",
         GetLastError()
      );
      return;
   }
   ObjectSetInteger(
      m_chartId,
      objPaginationNextPageName,
      OBJPROP_XDISTANCE,
      m_x + GetWidth() - 10 - btnWidth
   );
   ObjectSetInteger(
      m_chartId,
      objPaginationNextPageName,
      OBJPROP_YDISTANCE,
      m_y + m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight) + 5
   );
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_XSIZE, 24);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_YSIZE, 15);
   ObjectSetString(m_chartId, objPaginationNextPageName, OBJPROP_TEXT, "»");
   ObjectSetString(m_chartId, objPaginationNextPageName, OBJPROP_FONT, m_fontName);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_BGCOLOR, m_paginationBtnBgColor);
   ObjectSetInteger(
      m_chartId,
      objPaginationNextPageName,
      OBJPROP_BORDER_COLOR,
      m_paginationBtnBorderColor
   );
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objPaginationNextPageName, OBJPROP_ZORDER, m_zOrderBase + 1);
}

//+------------------------------------------------------------------+
//| Update row colors                                                |
//+------------------------------------------------------------------+
void UITable::UpdateRowColors(int row) {
   if(row < 0 || row >= ArraySize(m_tableRows))
      return;

   color rowBgColor = GetRowBackgroundColor(row);

   for(int col = 0; col < ArraySize(m_tableHeader); col++) {
      string objCellBgName = GetObjectName(OBJ_CELL_BG, row, col);
      ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BGCOLOR, rowBgColor);
   }
}

//+------------------------------------------------------------------+
//| Clear columns                                                     |
//+------------------------------------------------------------------+
void UITable::ClearAllText() {
   for(int i = 0; i < ArraySize(m_tableRows); i++) {
      for(int j = 0; j < ArraySize(m_tableRows[i].cells); j++) {
         m_tableRows[i].cells[j].text = "";
      }
   }
}

//+------------------------------------------------------------------+
//| Delete all table objects                                         |
//+------------------------------------------------------------------+
void UITable::TableDestroy() {
   ObjectDelete(m_chartId, m_name + "_background");
   int rowsCount = ArraySize(m_tableRows);
   int colsCount = ArraySize(m_tableHeader);

   for(int col = 0; col < colsCount; col++) {
      ObjectDelete(m_chartId, GetObjectName(OBJ_HEADER_BG, 0, col));
      ObjectDelete(m_chartId, GetObjectName(OBJ_HEADER_TEXT, 0, col));
   }

   for(int row = 0; row < rowsCount; row++) {
      for(int col = 0; col < colsCount; col++) {
         ObjectDelete(m_chartId, GetObjectName(OBJ_CELL_BG, row, col));
         ObjectDelete(m_chartId, GetObjectName(OBJ_CELL_CONTENT, row, col));
      }
   }
   StartRedrawChart();
   ObjectDelete(m_chartId, GetObjectName(OBJ_PAGINATION_TOTAL));
   ObjectDelete(m_chartId, GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE));
   ObjectDelete(m_chartId, GetObjectName(OBJ_PAGINATION_PAGE));
   ObjectDelete(m_chartId, GetObjectName(OBJ_PAGINATION_NEXT_PAGE));
}

void UITable::HandleClickBtnPaginationPrevious() {
   ObjectSetInteger(m_chartId, GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE), OBJPROP_STATE, false);
   if(m_page > 1) {
      EmitChangePage(m_page - 1);
   }
};
void UITable::HandleClickBtnPaginationNext() {
   ObjectSetInteger(m_chartId, GetObjectName(OBJ_PAGINATION_NEXT_PAGE), OBJPROP_STATE, false);
   if(m_page < m_pageTotal) {
      EmitChangePage(m_page + 1);
   }
};

void UITable::OnRealtimeEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_MOUSE_MOVE) {
      int x   = (int)lparam;
      int y   = (int)dparam;
      int row = GetRowAtPosition(x, y);

      if(m_hoverRow != row) {
         int oldHoverRow = m_hoverRow;
         m_hoverRow      = row;

         if(oldHoverRow >= 0) {
            UpdateRowColors(oldHoverRow);
         }
         if(m_hoverRow >= 0) {
            UpdateRowColors(m_hoverRow);
         }
      }
      StartRedrawChart();
   }
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE)) {
         HandleClickBtnPaginationPrevious();
      }
      if(sparam == GetObjectName(OBJ_PAGINATION_NEXT_PAGE)) {
         HandleClickBtnPaginationNext();
      }
   }
};

void UITable::OnStrategyTesterEvent() {
   bool btnPreviousState
      = ObjectGetInteger(m_chartId, GetObjectName(OBJ_PAGINATION_PREVIOUS_PAGE), OBJPROP_STATE);
   if(btnPreviousState) {
      HandleClickBtnPaginationPrevious();
   }

   bool btnNextState
      = ObjectGetInteger(m_chartId, GetObjectName(OBJ_PAGINATION_NEXT_PAGE), OBJPROP_STATE);
   if(btnNextState) {
      HandleClickBtnPaginationNext();
   }
};

#endif // UI_TABLE_MQH