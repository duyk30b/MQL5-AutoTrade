#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIPanel.mqh>

UIPanel uiPanelPopup;

string  pp_ObjBtnSubmitName = "PP_OBJ_BTN_SUBMIT_NAME";
string  pp_ObjBtnCancelName = "PP_OBJ_BTN_CANCEL_NAME";
string  pp_ObjLblSlName     = "PP_OBJ_LABEL_SL_NAME";
string  pp_ObjLblTpName     = "PP_OBJ_LABEL_TP_NAME";
string  pp_ObjEdtSlName     = "PP_OBJ_EDT_SL_NAME";
string  pp_ObjEdtTpName     = "PP_OBJ_EDT_TP_NAME";

class TDPopupPosition {
 public:
   bool  m_isShow;
   ulong m_ticketId;
   int   m_x;
   int   m_y;
   int   m_width;
   int   m_height;

   color clrBtnSubmitBg;
   color clrBtnSubmitBorder;
   color clrBtnCancelBg;
   color clrBtnCancelBorder;

   void  Create(int _x, int _y, int _width, int _height, bool _isShow) {
      m_isShow = _isShow;
      m_x      = _x;
      m_y      = _y;
      m_width  = _width;
      m_height = _height;

      Initialization();
      uiPanelPopup.StartDrawContainer();
      StartDrawPanelContent();
   }

   void Initialization() {
      // clang-format off
      clrBtnSubmitBg        = C'0,128,0';       // Green
      clrBtnSubmitBorder    = C'0,180,0';
      clrBtnCancelBg       = C'220,20,60';     // Crimson
      clrBtnCancelBorder   = C'255,60,100';
      // clang-format on

      uiPanelPopup.Initialization(0, "ModifyTicket", m_x, m_y, m_width, m_height, false);
      uiPanelPopup.SetHeaderTitle("Modify Ticket");
   }

   void StartDrawContainer() { uiPanelPopup.StartDrawContainer(); }

   void StartRedrawChart() { uiPanelPopup.StartRedrawChart(); }

   void StartDrawPanelContent() {
      // Tạo ô nhập Stop Loss
      uiCommon.CreateLabel(0, pp_ObjLblSlName, "Stop Loss:", 8, clrWhite);
      uiPanelPopup.AddPanelChild(pp_ObjLblSlName, 10, 50);
      uiCommon.CreateEdit(0, pp_ObjEdtSlName, (m_width - 10) / 2 - 10, 22, "");
      uiCommon.setZOrder(0, pp_ObjEdtSlName, 100);

      uiPanelPopup.AddPanelChild(pp_ObjEdtSlName, 10, 65);

      // Tạo ô nhập Take Profit
      uiCommon.CreateLabel(0, pp_ObjLblTpName, "Take Profit:", 8, clrWhite);
      uiPanelPopup.AddPanelChild(pp_ObjLblTpName, (m_width - 10) / 2 + 10, 50);
      uiCommon.CreateEdit(0, pp_ObjEdtTpName, (m_width - 10) / 2 - 10, 22, "");
      uiPanelPopup.AddPanelChild(pp_ObjEdtTpName, (m_width - 10) / 2 + 10, 65);
      uiCommon.setZOrder(0, pp_ObjEdtTpName, 100);

      // Tạo nút Submit
      uiCommon.CreateButton(0, pp_ObjBtnSubmitName, "SAVE", 80, 35);
      uiCommon.setTextColor(0, pp_ObjBtnSubmitName, clrWhite);
      uiCommon.setBackgroundColor(0, pp_ObjBtnSubmitName, clrBtnSubmitBg);
      uiCommon.setBorderColor(0, pp_ObjBtnSubmitName, clrBtnSubmitBorder);
      uiCommon.setZOrder(0, pp_ObjBtnSubmitName, 100);
      uiPanelPopup.AddPanelChild(pp_ObjBtnSubmitName, m_width / 2 + 5, 120);

      // Tạo nút Cancel
      uiCommon.CreateButton(0, pp_ObjBtnCancelName, "CANCEL", 80, 35);
      uiCommon.setTextColor(0, pp_ObjBtnCancelName, clrWhite);
      uiCommon.setBackgroundColor(0, pp_ObjBtnCancelName, clrBtnCancelBg);
      uiCommon.setBorderColor(0, pp_ObjBtnCancelName, clrBtnCancelBorder);
      uiCommon.setZOrder(0, pp_ObjBtnCancelName, 100);
      uiPanelPopup.AddPanelChild(pp_ObjBtnCancelName, m_width / 2 - 5 - 80, 120);

      uiPanelPopup.PanelRefreshPosition();
   }

   void setShow(bool show) { m_isShow = show; }

   void openPopup(ulong ticketId) {
      m_isShow   = true;
      m_ticketId = ticketId;
      uiPanelPopup.setShow(true);
      if(!PositionSelectByTicket(ticketId)) {
         return;
      }
      string symbol = PositionGetString(POSITION_SYMBOL);
      string type   = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      string volume = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
      string profit = DoubleToString(PositionGetDouble(POSITION_PROFIT), 4);
      string sl     = DoubleToString(PositionGetDouble(POSITION_SL), _Digits);
      string tp     = DoubleToString(PositionGetDouble(POSITION_TP), _Digits);

      uiCommon.setText(0, pp_ObjEdtSlName, sl);
      uiCommon.setText(0, pp_ObjEdtTpName, tp);
   }

   void HandleClickSubmit() {
      // Lấy giá trị từ ô nhập
      string slText = uiCommon.getText(0, pp_ObjEdtSlName);
      string tpText = uiCommon.getText(0, pp_ObjEdtTpName);

      double sl     = StringToDouble(slText);
      double tp     = StringToDouble(tpText);

      // Thực hiện lệnh sửa vị trí
      MqlTradeRequest request;
      MqlTradeResult  result;

      ZeroMemory(request);
      ZeroMemory(result);

      request.action   = TRADE_ACTION_SLTP;
      request.position = m_ticketId;
      request.sl       = sl;
      request.tp       = tp;

      if(!OrderSend(request, result)) {
         Print("Lỗi gửi lệnh sửa vị trí: ", GetLastError());
      } else {
         Print("Lệnh sửa vị trí thành công. Ticket: ", m_ticketId);
      }

      // Đóng popup sau khi xử lý
      m_isShow = false;
      uiPanelPopup.Close();
   }

   void HandleClickCancel() {
      m_isShow = false;
      uiPanelPopup.Close();
   }

   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
      uiPanelPopup.OnChartEvent(id, lparam, dparam, sparam);

      if(id == CHARTEVENT_OBJECT_CLICK) {
         // Xử lý click nút Submit
         if(sparam == pp_ObjBtnSubmitName) {
            uiCommon.setState(0, pp_ObjBtnSubmitName, false);
            HandleClickSubmit();
         }
         // Xử lý click nút Sell
         else if(sparam == pp_ObjBtnCancelName) {
            uiCommon.setState(0, pp_ObjBtnCancelName, false);
            HandleClickCancel();
         }
      }

      return true;
   }
};
