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
   string objName;
   int    offsetX;
   int    offsetY;
};

class UIPanelListener {
 public:
   virtual void onIsMinimizedChange(bool _isMinimized) = 0;
};

class UIPanel {
 private:
   UIPanelListener *m_listener;

   long             m_chartId; // Chart ID
   string           m_name;    // Tên panel

   // Vị trí và kích thước
   int m_x;      // Tọa độ X
   int m_y;      // Tọa độ Y
   int m_width;  // Chiều rộng
   int m_height; // Chiều cao

   // Trạng thái
   bool m_isShow;        // Trạng thái hiện/ẩn
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
   PanelChild m_panelControls[];

 public:
   UIPanel() {};
   ~UIPanel() { PanelDestroy(); };

   void SetListener(UIPanelListener *listener) { m_listener = listener; };

   // Khởi tạo panel
   void Initialization(
      long _chartId, string _name, int _x, int _y, int _width, int _height, bool _isShow
   ) {
      m_chartId         = _chartId;
      m_name            = _name;
      m_x               = _x;
      m_y               = _y;
      m_width           = _width;
      m_height          = _height;

      m_isShow          = _isShow;
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

      m_panelHeader.objName            = m_name + "_Header";
      m_panelHeader.offsetX            = 0;
      m_panelHeader.offsetY            = 0;

      m_panelHeaderTitle.objName       = m_name + "_Header_Title";
      m_panelHeaderTitle.offsetX       = 10;
      m_panelHeaderTitle.offsetY       = 8;

      m_panelHeaderBtnMin.objName      = m_name + "_Header_BtnMinimized";
      m_panelHeaderBtnMin.offsetX      = m_width - 75;
      m_panelHeaderBtnMin.offsetY      = 5;

      m_panelHeaderBtnLock.objName     = m_name + "_Header_BtnLock";
      m_panelHeaderBtnLock.offsetX     = m_width - 50;
      m_panelHeaderBtnLock.offsetY     = 5;

      m_panelHeaderBtnClose.objName    = m_name + "_Header_BtnClose";
      m_panelHeaderBtnClose.offsetX    = m_width - 25;
      m_panelHeaderBtnClose.offsetY    = 5;

      m_panelContentBackground.objName = m_name + "_Content_BackGround";
      m_panelContentBackground.offsetX = 0;
      m_panelContentBackground.offsetY = m_headerHeight;

      ArrayResize(m_panelContents, 0);
      ArrayResize(m_panelControls, 6);
      m_panelControls[0] = m_panelHeader;
      m_panelControls[1] = m_panelHeaderTitle;
      m_panelControls[2] = m_panelHeaderBtnMin;
      m_panelControls[3] = m_panelHeaderBtnLock;
      m_panelControls[4] = m_panelHeaderBtnClose;
      m_panelControls[5] = m_panelContentBackground;
   };
   void StartDrawContainer();
   void PanelDestroy();
   void PanelRefreshPosition();
   void PanelRefreshPositionExpect(int panelX, int panelY);
   void StartRedrawChart();
   void Close() { setShow(false); };

   // Thiết lập thuộc tính
   void SetHeaderTitle(string title);
   void SetHeaderBgColor(color clr) { m_headerBgColor = clr; }
   void SetHeaderTextColor(color clr) { m_headerTextColor = clr; }
   void SetContentBgColor(color clr) { m_contentBgColor = clr; }
   void SetBorderColor(color clr) { m_borderColor = clr; }

   // Lấy thông tin content area
   int GetPanelX() { return m_x; }
   int GetPanelY() { return m_y; }
   int GetWidth() { return m_width; }
   int GetHeight() { return m_height; }
   int GetHeaderHeight() { return m_headerHeight; }
   int GetObjectNameList(string &objNameList[]);

   // Control
   void setShow(bool hidden);
   void AddPanelChild(string objName, int offsetX, int offsetY);
   void AddPanelChildName(string objName);
   void AddPanelChildNameList(string &objNameList[]);

   // Xử lý sự kiện
   void HandleClickBtnMinimize();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();

 private:
   // Tạo các thành phần
   bool DrawHeader();
   bool DrawHeaderTitle();
   bool DrawHeaderButtonMin();
   bool DrawHeaderButtonLock();
   bool DrawHeaderButtonClose();
   bool DrawContentBackground();

   // Xử lý thu nhỏ/phóng to
   void RefreshMinimizeStateUI();
   void RefreshMoveStateUI();

   // Xử lý kéo thả
   void DoDrag(int x, int y);
   void EndDrag();
};

void UIPanel::StartDrawContainer() {
   DrawHeader();
   DrawHeaderTitle();
   DrawHeaderButtonMin();
   DrawHeaderButtonLock();
   DrawHeaderButtonClose();
   DrawContentBackground();
}

//+------------------------------------------------------------------+
//| Xóa object |
//+------------------------------------------------------------------+
void UIPanel::PanelDestroy() {
   for(int i = 0; i < ArraySize(m_panelControls); i++) {
      if(ObjectFind(m_chartId, m_panelControls[i].objName) >= 0) {
         ObjectDelete(m_chartId, m_panelControls[i].objName);
      }
   }
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      if(ObjectFind(m_chartId, m_panelContents[i].objName) >= 0) {
         ObjectDelete(m_chartId, m_panelContents[i].objName);
      }
   }
   ArrayResize(m_panelControls, 0);
   ArrayResize(m_panelContents, 0);
   StartRedrawChart();
}

//+------------------------------------------------------------------+
//| Redraw chart |
//+------------------------------------------------------------------+
void UIPanel::StartRedrawChart() {
   ChartRedraw(m_chartId);
}

//+------------------------------------------------------------------+
//| Tạo header |
//+------------------------------------------------------------------+
bool UIPanel::DrawHeader() {
   string objName = m_panelHeader.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelHeader.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelHeader.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}

//+------------------------------------------------------------------+
//| Tạo header title |
//+------------------------------------------------------------------+
bool UIPanel::DrawHeaderTitle() {
   string objName = m_panelHeaderTitle.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelHeaderTitle.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelHeaderTitle.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}

//+------------------------------------------------------------------+
//| Tạo nút header button min |
//+------------------------------------------------------------------+
bool UIPanel::DrawHeaderButtonMin() {
   string objName = m_panelHeaderBtnMin.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelHeaderBtnMin.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelHeaderBtnMin.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}

bool UIPanel::DrawHeaderButtonLock() {
   string objName = m_panelHeaderBtnLock.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelHeaderBtnLock.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelHeaderBtnLock.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}

bool UIPanel::DrawHeaderButtonClose() {
   string objName = m_panelHeaderBtnClose.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_BUTTON, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelHeaderBtnClose.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelHeaderBtnClose.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}
//+------------------------------------------------------------------+
//| Tạo nền panel |
//+------------------------------------------------------------------+
bool UIPanel::DrawContentBackground() {
   string objName = m_panelContentBackground.objName;
   if(!ObjectCreate(m_chartId, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   ObjectSetInteger(m_chartId, objName, OBJPROP_XDISTANCE, m_x + m_panelContentBackground.offsetX);
   ObjectSetInteger(m_chartId, objName, OBJPROP_YDISTANCE, m_y + m_panelContentBackground.offsetY);
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
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );

   return true;
}

int UIPanel::GetObjectNameList(string &objNameList[]) {
   int controllCount = ArraySize(m_panelControls);
   int contentCount  = ArraySize(m_panelContents);
   int totalCount    = controllCount + contentCount;
   ArrayResize(objNameList, totalCount);

   int index = 0;
   for(int i = 0; i < controllCount; i++) {
      objNameList[index++] = m_panelControls[i].objName;
   }
   for(int i = 0; i < contentCount; i++) {
      objNameList[index++] = m_panelContents[i + controllCount].objName;
   }
   return totalCount;
};

void UIPanel::setShow(bool _isShow) {
   m_isShow           = _isShow;
   int timeFramesShow = _isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;

   // Cập nhật hiển thị Content
   for(int i = 0; i < ArraySize(m_panelControls); i++) {
      ObjectSetInteger(m_chartId, m_panelControls[i].objName, OBJPROP_TIMEFRAMES, timeFramesShow);
   }
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      ObjectSetInteger(m_chartId, m_panelContents[i].objName, OBJPROP_TIMEFRAMES, timeFramesShow);
   }
}

//+------------------------------------------------------------------+
//| Thiết lập tiêu đề |
//+------------------------------------------------------------------+
void UIPanel::SetHeaderTitle(string title) {
   m_headerTitle = title;
   ObjectSetString(m_chartId, m_panelHeaderTitle.objName, OBJPROP_TEXT, title);
}

//+------------------------------------------------------------------+
//| Thêm control vào danh sách |
//+------------------------------------------------------------------+
void UIPanel::AddPanelChild(string objName, int offsetX, int offsetY) {
   int size = ArraySize(m_panelContents);
   ArrayResize(m_panelContents, size + 1);
   m_panelContents[size].objName = objName;
   m_panelContents[size].offsetX = offsetX;
   m_panelContents[size].offsetY = offsetY;
   ObjectSetInteger(
      m_chartId,
      objName,
      OBJPROP_TIMEFRAMES,
      m_isShow ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );
}

void UIPanel::AddPanelChildName(string objName) {
   int offsetX = (int)ObjectGetInteger(m_chartId, objName, OBJPROP_XDISTANCE) - m_x;
   int offsetY = (int)ObjectGetInteger(m_chartId, objName, OBJPROP_YDISTANCE) - m_y;
   AddPanelChild(objName, offsetX, offsetY);
}

void UIPanel::AddPanelChildNameList(string &objNameList[]) {
   for(int i = 0; i < ArraySize(objNameList); i++) {
      AddPanelChildName(objNameList[i]);
   }
}

//+------------------------------------------------------------------+
//| Thu nhỏ/Phóng to |
//+------------------------------------------------------------------+
void UIPanel::RefreshMinimizeStateUI() {
   if(m_isMinimized) {
      ObjectSetString(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_TEXT, "□");
      ObjectSetInteger(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_FONTSIZE, 12);
   } else {
      ObjectSetString(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_TEXT, "−");
      ObjectSetInteger(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_FONTSIZE, 10);
   }

   // Cập nhật hiển thị Content
   ObjectSetInteger(
      m_chartId,
      m_panelContentBackground.objName,
      OBJPROP_TIMEFRAMES,
      !m_isMinimized ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
   );
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].objName,
         OBJPROP_TIMEFRAMES,
         !m_isMinimized ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS
      );
   }

   StartRedrawChart();
}

void UIPanel::RefreshMoveStateUI() {
   if(m_isUnlockMove || m_isClickHeader) {
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);
      ObjectSetInteger(m_chartId, m_panelHeader.objName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_panelContentBackground.objName, OBJPROP_COLOR, clrWhite);
      ObjectSetString(m_chartId, m_panelHeaderBtnLock.objName, OBJPROP_TEXT, "[□]");
   } else {
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, false);
      ObjectSetInteger(m_chartId, m_panelHeader.objName, OBJPROP_COLOR, m_borderColor);
      ObjectSetInteger(m_chartId, m_panelContentBackground.objName, OBJPROP_COLOR, m_borderColor);
      ObjectSetString(m_chartId, m_panelHeaderBtnLock.objName, OBJPROP_TEXT, "[■]");
   }
   StartRedrawChart();
}

//+------------------------------------------------------------------+
//| Thực hiện kéo |
//+------------------------------------------------------------------+
void UIPanel::DoDrag(int x, int y) {
   int deltaX       = x - m_mouseStartX;
   int deltaY       = y - m_mouseStartY;

   int panelXExpect = m_x + deltaX;
   int panelYExpect = m_y + deltaY;

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

   PanelRefreshPositionExpect(panelXExpect, panelYExpect);
   StartRedrawChart();
}

//+------------------------------------------------------------------+
//| Kết thúc kéo |
//+------------------------------------------------------------------+
void UIPanel::EndDrag() {
   m_x = (int)ObjectGetInteger(m_chartId, m_panelHeader.objName, OBJPROP_XDISTANCE);
   m_y = (int)ObjectGetInteger(m_chartId, m_panelHeader.objName, OBJPROP_YDISTANCE);
}

void UIPanel::PanelRefreshPositionExpect(int _xExpect, int _yExpect) {
   for(int i = 0; i < ArraySize(m_panelControls); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelControls[i].objName,
         OBJPROP_XDISTANCE,
         _xExpect + m_panelControls[i].offsetX
      );
      ObjectSetInteger(
         m_chartId,
         m_panelControls[i].objName,
         OBJPROP_YDISTANCE,
         _yExpect + m_panelControls[i].offsetY
      );
   }
   for(int i = 0; i < ArraySize(m_panelContents); i++) {
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].objName,
         OBJPROP_XDISTANCE,
         _xExpect + m_panelContents[i].offsetX
      );
      ObjectSetInteger(
         m_chartId,
         m_panelContents[i].objName,
         OBJPROP_YDISTANCE,
         _yExpect + m_panelContents[i].offsetY
      );
   }
}

void UIPanel::PanelRefreshPosition() {
   PanelRefreshPositionExpect(m_x, m_y);
}

//+------------------------------------------------------------------+
//| Xử lý sự kiện |
//+------------------------------------------------------------------+
void UIPanel::HandleClickBtnMinimize() {
   ObjectSetInteger(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_STATE, false);
   m_isMinimized = !m_isMinimized;
   RefreshMinimizeStateUI();
   if(m_listener != NULL) {
      m_listener.onIsMinimizedChange(m_isMinimized);
   }
}

void UIPanel::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_panelHeader.objName || sparam == m_panelHeaderTitle.objName) {
         m_isClickHeader = true;
         RefreshMoveStateUI();
      }
      if(sparam == m_panelHeaderBtnMin.objName) {
         HandleClickBtnMinimize();
      }
      if(sparam == m_panelHeaderBtnLock.objName) {
         ObjectSetInteger(m_chartId, m_panelHeaderBtnLock.objName, OBJPROP_STATE, false);
         m_isUnlockMove = !m_isUnlockMove;
         RefreshMoveStateUI();
      }
      if(sparam == m_panelHeaderBtnClose.objName) {
         ObjectSetInteger(m_chartId, m_panelHeaderBtnClose.objName, OBJPROP_STATE, false);
         Close();
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
   }
}

void UIPanel::OnMQLTesterEvent() {
   // Xử lý sự kiện trong MQL Tester nếu cần
   bool isBtnMinClicked = ObjectGetInteger(m_chartId, m_panelHeaderBtnMin.objName, OBJPROP_STATE);
   if(isBtnMinClicked) {
      HandleClickBtnMinimize();
   }
   bool isBtnLockClicked = ObjectGetInteger(m_chartId, m_panelHeaderBtnLock.objName, OBJPROP_STATE);
   if(isBtnLockClicked) {
      ObjectSetInteger(m_chartId, m_panelHeaderBtnLock.objName, OBJPROP_STATE, false);
      m_isUnlockMove = !m_isUnlockMove;
      RefreshMoveStateUI();
   }
   bool isBtnCloseClicked
      = ObjectGetInteger(m_chartId, m_panelHeaderBtnClose.objName, OBJPROP_STATE);
   if(isBtnCloseClicked) {
      ObjectSetInteger(m_chartId, m_panelHeaderBtnClose.objName, OBJPROP_STATE, false);
      Close();
   }
}

#endif // UI_PANEL_MQH