//+------------------------------------------------------------------+
//|                                                      UITable.mqh |
//|                     Pure UI Table - Rendering Only              |
//+------------------------------------------------------------------+
#ifndef UI_TABLE_MQH
#define UI_TABLE_MQH

#property copyright "Copyright 2026"
#property link ""
#property version "3.00"
#property strict

//+------------------------------------------------------------------+
//| Enum for table themes                                             |
//+------------------------------------------------------------------+
enum ENUM_TABLE_THEME { THEME_DARK, THEME_LIGHT };

//+------------------------------------------------------------------+
//| Enum for cell content type                                       |
//+------------------------------------------------------------------+
enum ENUM_CELL_TYPE {
   CELL_TYPE_NONE,
   CELL_TYPE_TEXT,  // Plain text
   CELL_TYPE_CUSTOM // Custom object (button, image, etc.) - EA handles creation
};

enum ENUM_TABLE_OBJECT_TYPE {
   OBJ_BACKGROUND,
   OBJ_HEADER_BG,
   OBJ_HEADER_TEXT,
   OBJ_CELL_BG,
   OBJ_CELL_CONTENT,
};

struct TableCell {
   int            row;
   int            col;
   string         text;
   ENUM_CELL_TYPE cellType;
};

struct TableRow {
   ulong     data;
   TableCell cells[];
};

struct TableHeader {
   string         headerText;
   int            width;
   ENUM_CELL_TYPE cellType;
};

class UITable {
 private:
   // Basic properties
   long   m_chartId; // Chart ID
   string m_name;
   int    m_x;
   int    m_y;

   // Table structure
   TableRow    m_tableRows[];
   TableHeader m_tableHeader[];
   int         m_rowHeight;
   int         m_headerHeight;
   int         m_zOrderBase;

   // Theme colors - Dark
   color m_headerBgColor_Dark;
   color m_contentBgColor_Dark;
   color m_altRowBgColor_Dark;
   color m_borderColor_Dark;
   color m_headerTextColor_Dark;
   color m_contentTextColor_Dark;
   color m_hoverColor_Dark;

   // Theme colors - Light
   color m_headerBgColor_Light;
   color m_contentBgColor_Light;
   color m_altRowBgColor_Light;
   color m_borderColor_Light;
   color m_headerTextColor_Light;
   color m_contentTextColor_Light;
   color m_hoverColor_Light;

   // Current theme
   ENUM_TABLE_THEME m_currentTheme;

   // Hover state
   int m_hoverRow;

   // Font settings
   string m_fontName;
   int    m_fontSize;

   color  GetCurrentHeaderBgColor() {
      return (m_currentTheme == THEME_DARK) ? m_headerBgColor_Dark : m_headerBgColor_Light;
   };
   color GetCurrentContentBgColor() {
      return (m_currentTheme == THEME_DARK) ? m_contentBgColor_Dark : m_contentBgColor_Light;
   };
   color GetCurrentAltRowBgColor() {
      return (m_currentTheme == THEME_DARK) ? m_altRowBgColor_Dark : m_altRowBgColor_Light;
   };
   color GetCurrentBorderColor() {
      return (m_currentTheme == THEME_DARK) ? m_borderColor_Dark : m_borderColor_Light;
   };
   color GetCurrentHeaderTextColor() {
      return (m_currentTheme == THEME_DARK) ? m_headerTextColor_Dark : m_headerTextColor_Light;
   };
   color GetCurrentContentTextColor() {
      return (m_currentTheme == THEME_DARK) ? m_contentTextColor_Dark : m_contentTextColor_Light;
   };
   color GetCurrentHoverColor() {
      return (m_currentTheme == THEME_DARK) ? m_hoverColor_Dark : m_hoverColor_Light;
   };
   color GetRowBackgroundColor(int row) {
      if(row == m_hoverRow)
         return GetCurrentHoverColor();
      return (row % 2 == 0) ? GetCurrentContentBgColor() : GetCurrentAltRowBgColor();
   };

   void CreateBackground();
   void CreateHeaders();
   void CreateCells();
   void UpdateRowColors(int row);

 public:
   // Constructor & Destructor
   UITable() {};
   ~UITable() { TableDestroy(); };

   // Khởi tạo panel
   bool   Initialization(long chartId, string name, int x, int y, int rows, int cols);
   void   TableDestroy();

   string GetObjectName(ENUM_TABLE_OBJECT_TYPE tableObjectType, int row = 0, int col = 0);
   string GetObjectNamePrefix(ENUM_TABLE_OBJECT_TYPE tableObjectType);
   void   GetCellPositionByObjectName(
        ENUM_TABLE_OBJECT_TYPE tableObjectType, string objectName, int &row, int &col
     );
   void SetTheme(ENUM_TABLE_THEME theme) { m_currentTheme = theme; }
   void SetZOrderBase(int zOrderBase) { m_zOrderBase = zOrderBase; };
   void SetRowHeight(int height) { m_rowHeight = height; }
   void SetHeaderHeight(int height) { m_headerHeight = height; }
   void SetFont(string fontName, int fontSize) {
      m_fontName = fontName;
      m_fontSize = fontSize;
   };

   // Theme color setters
   void SetDarkThemeColors(
      color headerBg,
      color contentBg,
      color altRowBg,
      color border,
      color headerText,
      color contentText,
      color hover
   );
   void SetLightThemeColors(
      color headerBg,
      color contentBg,
      color altRowBg,
      color border,
      color headerText,
      color contentText,
      color hover
   );

   // Column management
   void ClearAllText();

   // Data management
   void SetHeader(
      int columnIndex, string headerText, int width, ENUM_CELL_TYPE cellType = CELL_TYPE_TEXT
   );
   ulong GetRowData(int row) { return m_tableRows[row].data; };
   void  SetRowData(int row, ulong data) { m_tableRows[row].data = data; };
   void  SetCell(int row, int col, string text, ENUM_CELL_TYPE cellType);
   void  SetCellTextColor(int row, int col, color textColor = clrNONE);

   // Drawing methods
   void TableStartDrawBase();
   void TableRedrawChart();

   // Event handling
   bool OnMouseMove(int x, int y);

   // Getters
   ENUM_CELL_TYPE GetCellType(int row, int col) { return m_tableRows[row].cells[col].cellType; };
   bool           GetCellPosition(int row, int col, int &x, int &y, int &width, int &height);
   int            GetRowAtPosition(int x, int y);
   int            GetColumnAtPosition(int x, int y);
   string         GetCellObjectPrefix(int row, int col); // For EA to create custom objects
};

bool UITable::Initialization(long chartId, string name, int x, int y, int rows, int cols) {
   m_chartId      = chartId;
   m_name         = name;
   m_x            = x;
   m_y            = y;
   m_rowHeight    = 25;
   m_headerHeight = 30;
   m_hoverRow     = -1;

   m_currentTheme = THEME_DARK;
   m_zOrderBase   = 0;

   ArrayResize(m_tableRows, rows);
   for(int i = 0; i < rows; i++) {
      ArrayResize(m_tableRows[i].cells, cols);
   }
   ArrayResize(m_tableHeader, cols);

   // clang-format off
   // Default Dark theme
   m_headerBgColor_Dark   = C'30,30,90';
   m_contentBgColor_Dark  = C'35,35,35';
   m_altRowBgColor_Dark   = C'45,45,45';
   m_borderColor_Dark     = C'60,60,60';
   m_headerTextColor_Dark = C'220,220,220';
   m_contentTextColor_Dark = C'200,200,200';
   m_hoverColor_Dark      = C'50,50,80';

   // Default Light theme
   m_headerBgColor_Light   = C'70,130,180';
   m_contentBgColor_Light  = clrWhite;
   m_altRowBgColor_Light   = C'248,248,252';
   m_borderColor_Light     = C'210,210,220';
   m_headerTextColor_Light = clrWhite;
   m_contentTextColor_Light = C'60,60,80';
   m_hoverColor_Light      = C'235,240,255';
   // clang-format on

   m_fontName = "Arial";
   m_fontSize = 8;

   ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);

   return true;
}

//+------------------------------------------------------------------+
//| Set dark theme colors                                            |
//+------------------------------------------------------------------+
void UITable::SetDarkThemeColors(
   color headerBg,
   color contentBg,
   color altRowBg,
   color border,
   color headerText,
   color contentText,
   color hover
) {
   m_headerBgColor_Dark    = headerBg;
   m_contentBgColor_Dark   = contentBg;
   m_altRowBgColor_Dark    = altRowBg;
   m_borderColor_Dark      = border;
   m_headerTextColor_Dark  = headerText;
   m_contentTextColor_Dark = contentText;
   m_hoverColor_Dark       = hover;
}

//+------------------------------------------------------------------+
//| Set light theme colors                                           |
//+------------------------------------------------------------------+
void UITable::SetLightThemeColors(
   color headerBg,
   color contentBg,
   color altRowBg,
   color border,
   color headerText,
   color contentText,
   color hover
) {
   m_headerBgColor_Light    = headerBg;
   m_contentBgColor_Light   = contentBg;
   m_altRowBgColor_Light    = altRowBg;
   m_borderColor_Light      = border;
   m_headerTextColor_Light  = headerText;
   m_contentTextColor_Light = contentText;
   m_hoverColor_Light       = hover;
}

string UITable::GetObjectNamePrefix(ENUM_TABLE_OBJECT_TYPE tableObjectType) {
   switch(tableObjectType) {
      case OBJ_BACKGROUND: {
         return m_name + "_" + "background";
      };
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
      default: return "unknown";
   }
};

string UITable::GetObjectName(ENUM_TABLE_OBJECT_TYPE tableObjectType, int row = 0, int col = 0) {
   string prefix = GetObjectNamePrefix(tableObjectType);
   switch(tableObjectType) {
      case OBJ_BACKGROUND: return prefix;
      case OBJ_HEADER_BG : {
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
      default: return "unknown";
   }
};

void UITable::GetCellPositionByObjectName(
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
}

void UITable::SetHeader(int columnIndex, string headerText, int width, ENUM_CELL_TYPE cellType) {
   m_tableHeader[columnIndex].headerText = headerText;
   m_tableHeader[columnIndex].width      = width;
   m_tableHeader[columnIndex].cellType   = cellType;
}

void UITable::TableStartDrawBase() {
   CreateBackground();
   CreateHeaders();
   CreateCells();
   TableRedrawChart();
}

//+------------------------------------------------------------------+
//| Create background                                                |
//+------------------------------------------------------------------+
void UITable::CreateBackground() {
   int totalWidth = 0;
   for(int i = 0; i < ArraySize(m_tableHeader); i++) {
      totalWidth += m_tableHeader[i].width;
   }

   int    totalHeight = m_headerHeight + (ArraySize(m_tableRows) * m_rowHeight);
   string objBgName   = GetObjectName(OBJ_BACKGROUND); // Reuse header bg prefix for background

   ObjectCreate(m_chartId, objBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_XSIZE, totalWidth);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_YSIZE, totalHeight);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_BGCOLOR, GetCurrentContentBgColor());
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_COLOR, GetCurrentBorderColor());
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objBgName, OBJPROP_ZORDER, m_zOrderBase + 0);
}

//+------------------------------------------------------------------+
//| Create headers                                                   |
//+------------------------------------------------------------------+
void UITable::CreateHeaders() {
   int xOffset   = m_x;
   int colsCount = ArraySize(m_tableHeader);
   for(int col = 0; col < colsCount; col++) {
      string objHeaderBgName = GetObjectName(OBJ_HEADER_BG, 0, col);
      ObjectCreate(m_chartId, objHeaderBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_XDISTANCE, xOffset);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_XSIZE, m_tableHeader[col].width);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_YSIZE, m_headerHeight);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BGCOLOR, GetCurrentHeaderBgColor());
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_COLOR, GetCurrentBorderColor());
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, objHeaderBgName, OBJPROP_ZORDER, m_zOrderBase + 0);

      string objHeaderTextName = GetObjectName(OBJ_HEADER_TEXT, 0, col);
      ObjectCreate(m_chartId, objHeaderTextName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_XDISTANCE, xOffset + 5);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_YDISTANCE, m_y + 8);
      ObjectSetString(m_chartId, objHeaderTextName, OBJPROP_TEXT, m_tableHeader[col].headerText);
      ObjectSetString(m_chartId, objHeaderTextName, OBJPROP_FONT, m_fontName);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_FONTSIZE, m_fontSize + 1);
      ObjectSetInteger(m_chartId, objHeaderTextName, OBJPROP_COLOR, GetCurrentHeaderTextColor());
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
         ObjectCreate(m_chartId, objCellBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_XDISTANCE, xOffset);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_XSIZE, m_tableHeader[col].width);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_YSIZE, m_rowHeight);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BGCOLOR, rowBgColor);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_COLOR, GetCurrentBorderColor());
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_BACK, false);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_HIDDEN, true);
         ObjectSetInteger(m_chartId, objCellBgName, OBJPROP_ZORDER, m_zOrderBase + 0);

         if(m_tableHeader[col].cellType == CELL_TYPE_TEXT) {
            string objCellContentName = GetObjectName(OBJ_CELL_CONTENT, row, col);
            string text               = m_tableRows[row].cells[col].text;
            color  textColor          = GetCurrentContentTextColor();
            ObjectCreate(m_chartId, objCellContentName, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_XDISTANCE, xOffset + 5);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_YDISTANCE, yPos + 6);
            ObjectSetString(m_chartId, objCellContentName, OBJPROP_TEXT, text);
            ObjectSetString(m_chartId, objCellContentName, OBJPROP_FONT, m_fontName);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_FONTSIZE, m_fontSize);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_COLOR, textColor);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_HIDDEN, true);
            ObjectSetInteger(m_chartId, objCellContentName, OBJPROP_ZORDER, m_zOrderBase + 1);
         }
         xOffset += m_tableHeader[col].width;
      }
   }
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

void UITable::SetCell(int row, int col, string text, ENUM_CELL_TYPE cellType) {
   m_tableRows[row].cells[col].text     = text;
   m_tableRows[row].cells[col].cellType = cellType;
   string cellTextName                  = GetObjectName(OBJ_CELL_CONTENT, row, col);
   ObjectSetString(m_chartId, cellTextName, OBJPROP_TEXT, text);
}

void UITable::SetCellTextColor(int row, int col, color textColor = clrNONE) {
   string cellTextName = GetObjectName(OBJ_CELL_CONTENT, row, col);
   if(textColor != clrNONE) {
      ObjectSetInteger(m_chartId, cellTextName, OBJPROP_COLOR, textColor);
   }
}

//+------------------------------------------------------------------+
//| Get cell position - for EA to create custom objects              |
//+------------------------------------------------------------------+
bool UITable::GetCellPosition(int row, int col, int &x, int &y, int &width, int &height) {
   if(row < 0 || row >= ArraySize(m_tableRows) || col < 0 || col >= ArraySize(m_tableHeader))
      return false;

   x = m_x;
   for(int i = 0; i < col; i++) {
      x += m_tableHeader[i].width;
   }

   y      = m_y + m_headerHeight + (row * m_rowHeight);
   width  = m_tableHeader[col].width;
   height = m_rowHeight;

   return true;
}

//+------------------------------------------------------------------+
//| Get row at mouse position                                        |
//+------------------------------------------------------------------+
int UITable::GetRowAtPosition(int x, int y) {
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
}

//+------------------------------------------------------------------+
//| Get column at mouse position                                     |
//+------------------------------------------------------------------+
int UITable::GetColumnAtPosition(int x, int y) {
   int colsCount = ArraySize(m_tableHeader);

   int xOffset   = m_x;

   for(int col = 0; col < colsCount; col++) {
      if(x >= xOffset && x < xOffset + m_tableHeader[col].width) {
         return col;
      }
      xOffset += m_tableHeader[col].width;
   }

   return -1;
}

//+------------------------------------------------------------------+
//| Get cell object prefix for EA to create custom objects           |
//+------------------------------------------------------------------+
string UITable::GetCellObjectPrefix(int row, int col) {
   return m_name + "_custom_" + IntegerToString(row) + "_" + IntegerToString(col);
}

//+------------------------------------------------------------------+
//| Handle mouse move for hover effect                               |
//+------------------------------------------------------------------+
bool UITable::OnMouseMove(int x, int y) {
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

      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Delete all table objects                                         |
//+------------------------------------------------------------------+
void UITable::TableDestroy() {
   ObjectDelete(m_chartId, m_name + "_background");
   int rowsCount = ArraySize(m_tableRows);
   int colsCount = ArraySize(m_tableHeader);

   ObjectDelete(m_chartId, GetObjectName(OBJ_BACKGROUND));

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
   TableRedrawChart();
}

void UITable::TableRedrawChart() {
   ChartRedraw(m_chartId);
}

#endif // UI_TABLE_MQH