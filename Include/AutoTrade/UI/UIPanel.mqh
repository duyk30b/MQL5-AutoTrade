//+------------------------------------------------------------------+
//|      PanelLibrary.mqh  | | Thư viện Panel tùy chỉnh cho MT5      |
//+------------------------------------------------------------------+
#ifndef UI_PANEL_MQH
#define UI_PANEL_MQH

#property copyright "Custom Panel Library"
#property link ""
#property version "1.00"

//+------------------------------------------------------------------+
//|         Lớp UIPanel - Panel có thể thu nhỏ và kéo thả            |
//+------------------------------------------------------------------+

struct PanelChild {
   string name;
   int    offsetX;
   int    offsetY;

   void   Init(string _name, int _x, int _y) {
      name    = _name;
      offsetX = _x;
      offsetY = _y;
   }
};
class UIPanel {
 private:
   long   m_chartId; // Chart ID
   string m_name;    // Tên panel

   // Vị trí và kích thước
   int m_panelX; // Tọa độ X
   int m_panelY; // Tọa độ Y
   int m_width;  // Chiều rộng
   int m_height; // Chiều cao

   // Trạng thái
   bool m_isMinimized;   // Trạng thái thu nhỏ
   bool m_isUnlockMove;  // Trạng thái khóa di chuyển
   bool m_isClickHeader; // Đang kéo panel
   bool m_isDragging;    // Đang kéo panel
   int  m_mouseStartX;   // Vị trí X bắt đầu kéo
   int  m_mouseStartY;   // Vị trí Y bắt đầu kéo

   // Thuộc tính
   string     m_headerTitle;             // Tiêu đề panel
   int        m_headerHeight;            // Chiều cao header

   color      m_headerBgColor;           // Màu header
   color      m_headerTextColor;         // Màu chữ
   color      m_headerButtonBgColor;     // Màu viền
   color      m_headerButtonBorderColor; // Màu viền
   color      m_contentBgColor;          // Màu nền
   color      m_borderColor;             // Màu viền

   PanelChild m_panelHeader;
   PanelChild m_panelHeaderTitle;
   PanelChild m_panelHeaderBtnLock;
   PanelChild m_panelHeaderBtnMin;
   PanelChild m_panelHeaderBtnClose;
   PanelChild m_panelContentBackground;

   PanelChild m_panelContents[];
   PanelChild m_panelControlls[];

 public:
   UIPanel();
   ~UIPanel();

   // Khởi tạo panel
   bool Initialization(long chartId, string name, int x, int y, int width, int height);
   void PanelDestroy();
   void PanelRefreshPosition(int panelX, int panelY);
   void PanelRedrawChart();

   // Thiết lập thuộc tính
   void SetHeaderTitle(string title);
   void SetHeaderBgColor(color clr) { m_headerBgColor = clr; }
   void SetHeaderTextColor(color clr) { m_headerTextColor = clr; }
   void SetContentBgColor(color clr) { m_contentBgColor = clr; }
   void SetBorderColor(color clr) { m_borderColor = clr; }

   // Lấy thông tin content area
   int GetPanelX() { return m_panelX; }
   int GetPanelY() { return m_panelY; }
   int GetWidth() { return m_width; }
   int GetHeight() { return m_height; }

   // Thêm control vào danh sách quản lý
   void AddPanelChild(string name, int offsetX, int offsetY);
   void AddPanelChildName(string name);

   // Xử lý sự kiện
   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

 private:
   // Tạo các thành phần
   bool CreateHeader();
   bool CreateHeaderTitle();
   bool CreateHeaderButtonMin();
   bool CreateHeaderButtonLock();
   bool CreateHeaderButtonClose();
   bool CreateContentBackground();

   // Xử lý thu nhỏ/phóng to
   void ToggleMinimize();
   void RefreshMoveStateUI();

   // Xử lý kéo thả
   void DoDrag(int x, int y);
   void EndDrag();
};

//+------------------------------------------------------------------+
//| Constructor |
//+------------------------------------------------------------------+
UIPanel::UIPanel() {}

//+------------------------------------------------------------------+
//| Destructor |
//+------------------------------------------------------------------+
UIPanel::~UIPanel() {
   PanelDestroy();
}

//+------------------------------------------------------------------+
//| Tạo panel |
//+------------------------------------------------------------------+
bool UIPanel::Initialization(long chartId, string name, int x, int y, int width, int height) {
   m_chartId         = chartId;
   m_name            = name;
   m_panelX          = x;
   m_panelY          = y;
   m_width           = width;
   m_height          = height;

   m_isMinimized     = false;
   m_isUnlockMove    = false;
   m_isClickHeader   = false;
   m_isDragging      = false;

   m_headerHeight    = 30;
   m_headerTitle     = "UIPanel";
   m_headerTextColor = clrWhite;
   // clang-format off
   m_headerBgColor   = C'25,25,112'; // Navy blue
   m_headerButtonBgColor = C'60,60,60'; // Dark gray
   m_headerButtonBorderColor = C'80,80,80'; // Dark gray
   m_contentBgColor  = C'45,45,45'; // Dark gray
   m_borderColor     = C'70,70,70'; // Light gray
   // clang-format on

   m_panelHeader.name               = m_name + "_Header";
   m_panelHeader.offsetX            = 0;
   m_panelHeader.offsetY            = 0;

   m_panelHeaderTitle.name          = m_name + "_Header_Title";
   m_panelHeaderTitle.offsetX       = 10;
   m_panelHeaderTitle.offsetY       = 8;

   m_panelHeaderBtnMin.name         = m_name + "_Header_BtnMinimized";
   m_panelHeaderBtnMin.offsetX      = m_width - 75;
   m_panelHeaderBtnMin.offsetY      = 5;

   m_panelHeaderBtnLock.name        = m_name + "_Header_BtnLock";
   m_panelHeaderBtnLock.offsetX     = m_width - 50;
   m_panelHeaderBtnLock.offsetY     = 5;

   m_panelHeaderBtnClose.name       = m_name + "_Header_BtnClose";
   m_panelHeaderBtnClose.offsetX    = m_width - 25;
   m_panelHeaderBtnClose.offsetY    = 5;

   m_panelContentBackground.name    = m_name + "_Content_BackGround";
   m_panelContentBackground.offsetX = 0;
   m_panelContentBackground.offsetY = m_headerHeight;

   // Tạo các thành phần
   if(!CreateHeader())
      return false;
   if(!CreateHeaderTitle())
      return false;
   if(!CreateHeaderButtonMin())
      return false;
   if(!CreateHeaderButtonLock())
      return false;
   if(!CreateHeaderButtonClose())
      return false;
   if(!CreateContentBackground())
      return false;

   ArrayResize(m_panelContents, 0);
   ArrayResize(m_panelControlls, 6);
   m_panelControlls[0] = m_panelHeader;
   m_panelControlls[1] = m_panelHeaderTitle;
   m_panelControlls[2] = m_panelHeaderBtnMin;
   m_panelControlls[3] = m_panelHeaderBtnLock;
   m_panelControlls[4] = m_panelHeaderBtnClose;
   m_panelControlls[5] = m_panelContentBackground;
   return true;
}

//+------------------------------------------------------------------+
//| Xóa object |
//+------------------------------------------------------------------+
void UIPanel::PanelDestroy() {
   for(int i = 0; i < ArraySize(m_panelControlls); i++) {
      if(ObjectFind(m_chartId, m_panelControlls[i].name) >= 0) {
         ObjectDelete(m_chartId, m_panelControlls[i].name);
      }
   }
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      if(ObjectFind(m_chartId, m_panelContents[i].name) >= 0) {
         ObjectDelete(m_chartId, m_panelContents[i].name);
      }
   }
   ArrayResize(m_panelControlls, 0);
   ArrayResize(m_panelContents, 0);
   PanelRedrawChart();
}

//+------------------------------------------------------------------+
//| Redraw chart |
//+------------------------------------------------------------------+
void UIPanel::PanelRedrawChart() {
   ChartRedraw(m_chartId);
}

//+------------------------------------------------------------------+
//| Tạo header |
//+------------------------------------------------------------------+
bool UIPanel::CreateHeader() {
   string objName = m_panelHeader.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_panelX + m_panelHeader.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_panelX + m_panelHeader.offsetY);
   ObjectSetInteger(m_chartId, objName, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YSIZE, m_headerHeight);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, m_borderColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BGCOLOR, m_headerBgColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, true); // Cho phép click
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 0);

   return true;
}

//+------------------------------------------------------------------+
//| Tạo header title |
//+------------------------------------------------------------------+
bool UIPanel::CreateHeaderTitle() {
   string objName = m_panelHeaderTitle.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_panelX + m_panelHeaderTitle.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_panelX + m_panelHeaderTitle.offsetY);
   ObjectSetInteger(m_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(m_chartId, objName, OBJPROP_TEXT, m_headerTitle);
   ObjectSetString(m_chartId, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, m_headerTextColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, true); // Cho phép click
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 1);

   return true;
}

//+------------------------------------------------------------------+
//| Tạo nút header button min |
//+------------------------------------------------------------------+
bool UIPanel::CreateHeaderButtonMin() {
   string objName = m_panelHeaderBtnMin.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_panelX + m_panelHeaderBtnMin.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_panelX + m_panelHeaderBtnMin.offsetY);
   ObjectSetInteger(m_chartId, objName, OBJPROP_XSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(m_chartId, objName, OBJPROP_TEXT, "−");
   ObjectSetString(m_chartId, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BGCOLOR, m_headerButtonBgColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BORDER_COLOR, m_headerButtonBorderColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 1);

   return true;
}

bool UIPanel::CreateHeaderButtonLock() {
   string objName = m_panelHeaderBtnLock.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_panelX + m_panelHeaderBtnLock.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_panelX + m_panelHeaderBtnLock.offsetY);
   ObjectSetInteger(m_chartId, objName, OBJPROP_XSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(m_chartId, objName, OBJPROP_TEXT, "[■]");
   ObjectSetString(m_chartId, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, 6);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BGCOLOR, m_headerButtonBgColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BORDER_COLOR, m_headerButtonBorderColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 1);

   return true;
}

bool UIPanel::CreateHeaderButtonClose() {
   string objName = m_panelHeaderBtnClose.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_XDISTANCE,
      m_panelX + m_panelHeaderBtnClose.offsetX
   );
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_YDISTANCE,
      m_panelX + m_panelHeaderBtnClose.offsetY
   );
   ObjectSetInteger(m_chartId, objName, OBJPROP_XSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YSIZE, 20);
   ObjectSetInteger(m_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(m_chartId, objName, OBJPROP_TEXT, "×");
   ObjectSetString(m_chartId, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chartId, objName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BGCOLOR, m_headerButtonBgColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BORDER_COLOR, m_headerButtonBorderColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_STATE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 1);

   return true;
}
//+------------------------------------------------------------------+
//| Tạo nền panel |
//+------------------------------------------------------------------+
bool UIPanel::CreateContentBackground() {
   string objName = m_panelContentBackground.name;
   if(!ObjectCreate(m_chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_XDISTANCE,
      m_panelX + m_panelContentBackground.offsetX
   );
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_YDISTANCE,
      m_panelX + m_panelContentBackground.offsetY
   );
   ObjectSetInteger(m_chartId, objName, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YSIZE, m_height);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BGCOLOR, m_contentBgColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chartId, objName, OBJPROP_COLOR, m_borderColor);
   ObjectSetInteger(m_chartId, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(m_chartId, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(m_chartId, objName, OBJPROP_BACK, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(m_chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chartId, objName, OBJPROP_ZORDER, 0);

   return true;
}

//+------------------------------------------------------------------+
//| Thiết lập tiêu đề |
//+------------------------------------------------------------------+
void UIPanel::SetHeaderTitle(string title) {
   m_headerTitle = title;
   ObjectSetString(m_chartId, m_panelHeaderTitle.name, OBJPROP_TEXT, title);
}

//+------------------------------------------------------------------+
//| Thêm control vào danh sách |
//+------------------------------------------------------------------+
void UIPanel::AddPanelChild(string name, int offsetX, int offsetY) {
   int size = ArraySize(m_panelContents);
   ArrayResize(m_panelContents, size + 1);
   m_panelContents[size].name    = name;
   m_panelContents[size].offsetX = offsetX;
   m_panelContents[size].offsetY = offsetY;
}

void UIPanel::AddPanelChildName(string name) {
   int size = ArraySize(m_panelContents);
   ArrayResize(m_panelContents, size + 1);
   m_panelContents[size].name    = name;
   m_panelContents[size].offsetX = (int)ObjectGetInteger(m_chartId, name, OBJPROP_XDISTANCE);
   m_panelContents[size].offsetY = (int)ObjectGetInteger(m_chartId, name, OBJPROP_YDISTANCE);
}

//+------------------------------------------------------------------+
//| Xử lý sự kiện |
//+------------------------------------------------------------------+
bool UIPanel::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_panelHeader.name || sparam == m_panelHeaderTitle.name) {
         m_isClickHeader = true;
         RefreshMoveStateUI();
         return true;
      }
      if(sparam == m_panelHeaderBtnMin.name) {
         ToggleMinimize();
         return true;
      }
      if(sparam == m_panelHeaderBtnLock.name) {
         m_isUnlockMove = !m_isUnlockMove;
         RefreshMoveStateUI();
         return true;
      }
      if(sparam == m_panelHeaderBtnClose.name) {
         PanelDestroy();
         return true;
      }
   }

   // Di chuyển chuột
   if(id == CHARTEVENT_MOUSE_MOVE) {
      bool isLeftMousePressed = ((int)StringToInteger(sparam) & 1) != 0; // Chuột trái đang giữ

      if(isLeftMousePressed) {
         if(m_isUnlockMove || m_isClickHeader) {
            int x = (int)lparam;
            int y = (int)dparam;
            if(!m_isDragging) {
               m_isDragging  = true;
               m_mouseStartX = x;
               m_mouseStartY = y;
            }
            DoDrag(x, y);
         }

      } else {
         if(m_isDragging) {
            m_isDragging    = false;
            m_isClickHeader = false;
            EndDrag();
            RefreshMoveStateUI();
         }
      }
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Thu nhỏ/Phóng to |
//+------------------------------------------------------------------+
void UIPanel::ToggleMinimize() {
   m_isMinimized = !m_isMinimized;

   if(m_isMinimized) {
      ObjectSetString(m_chartId, m_panelHeaderBtnMin.name, OBJPROP_TEXT, "□");
      ObjectSetInteger(m_chartId, m_panelHeaderBtnMin.name, OBJPROP_FONTSIZE, 12);
   } else {
      ObjectSetString(m_chartId, m_panelHeaderBtnMin.name, OBJPROP_TEXT, "−");
      ObjectSetInteger(m_chartId, m_panelHeaderBtnMin.name, OBJPROP_FONTSIZE, 10);
   }

   // Cập nhật hiển thị Content
   ObjectSetInteger(
      m_chartId,
      m_panelContentBackground.name,
      OBJPROP_TIMEFRAMES,
      !m_isMinimized ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].name,
         OBJPROP_TIMEFRAMES,
         !m_isMinimized ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
      );
   }

   PanelRedrawChart();
}

void UIPanel::RefreshMoveStateUI() {
   if(m_isUnlockMove || m_isClickHeader) {
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);
      ObjectSetInteger(m_chartId, m_panelHeader.name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_panelContentBackground.name, OBJPROP_COLOR, clrWhite);
      ObjectSetString(m_chartId, m_panelHeaderBtnLock.name, OBJPROP_TEXT, "[□]");
   } else {
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, false);
      ObjectSetInteger(m_chartId, m_panelHeader.name, OBJPROP_COLOR, m_borderColor);
      ObjectSetInteger(m_chartId, m_panelContentBackground.name, OBJPROP_COLOR, m_borderColor);
      ObjectSetString(m_chartId, m_panelHeaderBtnLock.name, OBJPROP_TEXT, "[■]");
   }
   PanelRedrawChart();
}

//+------------------------------------------------------------------+
//| Thực hiện kéo |
//+------------------------------------------------------------------+
void UIPanel::DoDrag(int x, int y) {
   int deltaX       = x - m_mouseStartX;
   int deltaY       = y - m_mouseStartY;

   int panelXExpect = m_panelX + deltaX;
   int panelYExpect = m_panelY + deltaY;

   // Giới hạn trong biên chart
   if(panelXExpect < 0)
      panelXExpect = 0;
   if(panelYExpect < 0)
      panelYExpect = 0;

   int chartWidth  = (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
   int chartHeight = (int)ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS);

   if(panelXExpect + m_width > chartWidth)
      panelXExpect = chartWidth - m_width;
   if(panelYExpect + m_height > chartHeight)
      panelYExpect = chartHeight - m_height;

   PanelRefreshPosition(panelXExpect, panelYExpect);
   PanelRedrawChart();
}

//+------------------------------------------------------------------+
//| Kết thúc kéo |
//+------------------------------------------------------------------+
void UIPanel::EndDrag() {
   m_panelX = (int)ObjectGetInteger(m_chartId, m_panelHeader.name, OBJPROP_XDISTANCE);
   m_panelY = (int)ObjectGetInteger(m_chartId, m_panelHeader.name, OBJPROP_YDISTANCE);
}

void UIPanel::PanelRefreshPosition(int _panelX, int _panelY) {
   for(int i = 0; i < ArraySize(m_panelControlls); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelControlls[i].name,
         OBJPROP_XDISTANCE,
         _panelX + m_panelControlls[i].offsetX
      );
      ObjectSetInteger(
         m_chartId,
         m_panelControlls[i].name,
         OBJPROP_YDISTANCE,
         _panelY + m_panelControlls[i].offsetY
      );
   }
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].name,
         OBJPROP_XDISTANCE,
         _panelX + m_panelContents[i].offsetX
      );
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].name,
         OBJPROP_YDISTANCE,
         _panelY + m_panelContents[i].offsetY
      );
   }
}

#endif // UI_PANEL_MQH