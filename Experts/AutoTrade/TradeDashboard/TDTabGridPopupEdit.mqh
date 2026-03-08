#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIPanel.mqh>

class TDTabGridPopupEdit {
 public:
   bool          m_isShow;
   bool          m_isFirstDraw;
   string        m_gridName;
   int           m_x;
   int           m_y;
   int           m_width;
   int           m_height;

   double        m_stopLossPrice;
   double        m_takeProfitPrice;

   UIPanel       m_uiPanelPopup;

   UIInputNumber m_ipTakeProfitPrice;
   UIInputNumber m_ipStopLossPrice;

   string        m_objBtnSubmitName;
   string        m_objBtnCancelName;

   void          Initialize() {
      m_isFirstDraw      = true;
      m_objBtnSubmitName = "TDTabGridPopupEdit_BtnSubmit";
      m_objBtnCancelName = "TDTabGridPopupEdit_BtnCancel";

      m_uiPanelPopup.Initialize(g_chartId, "TDTabGridPopupEdit");
      m_uiPanelPopup.SetHeaderTitle("Modify Grid");

      m_ipStopLossPrice.Initialize(g_chartId, "TDTabGridPopupEdit_StopLossPrice");
      m_ipTakeProfitPrice.Initialize(g_chartId, "TDTabGridPopupEdit_TakeProfitPrice");
   }

   void SetShow(bool show) { m_isShow = show; }
   void SetPosition(int x, int y) {
      m_x = x;
      m_y = y;
   }
   void SetSize(int width, int height) {
      m_width  = width;
      m_height = height;
   }

   void StartDraw(int x, int y, int width, int height, bool isShow);
   void OpenPopup(string gridName);

   void HandleClickSubmit();
   void HandleClickCancel();

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void TDTabGridPopupEdit::StartDraw(int x, int y, int width, int height, bool isShow) {
   m_isShow = isShow;
   m_x      = x;
   m_y      = y;
   m_width  = width;
   m_height = height;

   m_uiPanelPopup.StartDraw(m_x, m_y, m_width, m_height, m_isShow);

   int yOffsetPanel = m_uiPanelPopup.GetHeaderHeight() + 20;

   // Create Input StopLoss Price
   m_ipStopLossPrice.SetLabel("Stop Loss (Price):", clrWhite);
   m_ipStopLossPrice.SetStep(0.0001);
   m_ipStopLossPrice.SetDigits(_Digits);
   m_ipStopLossPrice.SetMinValue(0);
   m_ipStopLossPrice.StartDraw(m_x + 10, m_y + yOffsetPanel, m_width - 20, 45);
   m_ipStopLossPrice.SetValue(0);
   string ipSlValueObjNameList[];
   m_ipStopLossPrice.GetObjectNameList(ipSlValueObjNameList);
   m_uiPanelPopup.AddPanelChildNameList(ipSlValueObjNameList);

   yOffsetPanel += 55;

   // Create Input TakeProfit Price
   m_ipTakeProfitPrice.SetLabel("Take Profit (Price):", clrWhite);
   m_ipTakeProfitPrice.SetStep(0.0001);
   m_ipTakeProfitPrice.SetDigits(_Digits);
   m_ipTakeProfitPrice.SetMinValue(0);
   m_ipTakeProfitPrice.StartDraw(m_x + 10, m_y + yOffsetPanel, m_width - 20, 45);
   m_ipTakeProfitPrice.SetValue(0);
   string ipTpValueObjNameList[];
   m_ipTakeProfitPrice.GetObjectNameList(ipTpValueObjNameList);
   m_uiPanelPopup.AddPanelChildNameList(ipTpValueObjNameList);
   yOffsetPanel = yOffsetPanel + 60;

   // Tạo nút Submit
   uiCommon.CreateButton(
      g_chartId,
      m_objBtnSubmitName,
      "SAVE",
      m_x + m_width / 2 + 5,
      m_y + yOffsetPanel,
      (m_width - 30) / 2,
      35
   );
   uiCommon.setTextColor(g_chartId, m_objBtnSubmitName, g_clrBtnGreenText);
   uiCommon.setBackgroundColor(g_chartId, m_objBtnSubmitName, g_clrBtnGreenBg);
   uiCommon.setBorderColor(g_chartId, m_objBtnSubmitName, g_clrBtnGreenBorder);
   uiCommon.setZOrder(g_chartId, m_objBtnSubmitName, 100);

   // Tạo nút Cancel
   uiCommon.CreateButton(
      g_chartId,
      m_objBtnCancelName,
      "CANCEL",
      m_x + 10,
      m_y + yOffsetPanel,
      (m_width - 30) / 2,
      35
   );
   uiCommon.setTextColor(g_chartId, m_objBtnCancelName, clrWhite);
   uiCommon.setBackgroundColor(g_chartId, m_objBtnCancelName, g_clrBtnRedBg);
   uiCommon.setBorderColor(g_chartId, m_objBtnCancelName, g_clrBtnRedBorder);
   uiCommon.setZOrder(g_chartId, m_objBtnCancelName, 100);

   m_uiPanelPopup.PanelRefreshPosition();
}

void TDTabGridPopupEdit::OpenPopup(string gridName) {
   m_isShow   = true;
   m_gridName = gridName;
   m_uiPanelPopup.setShow(true);

   if(m_isFirstDraw) {
      m_isFirstDraw = false;
      StartDraw(m_x, m_y, m_width, m_height, m_isShow);

      string ipStopLossPriceObjNameList[];
      m_ipStopLossPrice.GetObjectNameList(ipStopLossPriceObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipStopLossPriceObjNameList);

      string ipTakeProfitPriceObjNameList[];
      m_ipTakeProfitPrice.GetObjectNameList(ipTakeProfitPriceObjNameList);
      m_uiPanelPopup.AddPanelChildNameList(ipTakeProfitPriceObjNameList);

      m_uiPanelPopup.AddPanelChildName(m_objBtnSubmitName);
      m_uiPanelPopup.AddPanelChildName(m_objBtnCancelName);

      m_uiPanelPopup.PanelRefreshPosition();
   }

   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].gridName == gridName) {
         m_stopLossPrice   = g_gridList[i].stopLossPrice;
         m_takeProfitPrice = g_gridList[i].takeProfitPrice;
         m_ipStopLossPrice.UpdateValue(m_stopLossPrice);
         m_ipTakeProfitPrice.UpdateValue(m_takeProfitPrice);
         break;
      }
   }

   ChartRedraw(g_chartId);
}

void TDTabGridPopupEdit::HandleClickSubmit() {
   uiCommon.setState(0, m_objBtnSubmitName, false);
   double sl = m_ipStopLossPrice.GetValue();
   double tp = m_ipTakeProfitPrice.GetValue();

   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].gridName == m_gridName) {
         for(int j = 0; j < ArraySize(g_gridList[i].ticketOrderList); j++) {
            ulong  ticketOrder = g_gridList[i].ticketOrderList[j].ticketOrder;
            double price       = g_gridList[i].ticketOrderList[j].priceOpen;

            // Start modifying the order
            if(!cTrade.OrderModify(ticketOrder, price, sl, tp, 0, ORDER_TIME_GTC)) {
               Print(
                  "Failed to modify order with ticket: ",
                  ticketOrder,
                  ". Error: ",
                  GetLastError()
               );
               MessageBox(
                  "Failed to modify order with ticket: " + IntegerToString(ticketOrder)
                     + ". Error: " + IntegerToString(GetLastError()),
                  "Error",
                  MB_OK | MB_ICONINFORMATION
               );
               return;
            }
         }

         for(int j = 0; j < ArraySize(g_gridList[i].ticketPositionList); j++) {
            ulong ticketPosition = g_gridList[i].ticketPositionList[j].ticketPosition;

            // Start modifying the position
            if(!cTrade.PositionModify(ticketPosition, sl, tp)) {
               Print(
                  "Failed to modify position with ticket: ",
                  ticketPosition,
                  ". Error: ",
                  GetLastError()
               );
               MessageBox(
                  "Failed to modify position with ticket: " + IntegerToString(ticketPosition)
                     + ". Error: " + IntegerToString(GetLastError()),
                  "Error",
                  MB_OK | MB_ICONINFORMATION
               );
               return;
            }
         }

         g_gridList[i].stopLossPrice   = sl;
         g_gridList[i].takeProfitPrice = tp;
         break;
      }
   }

   m_isShow = false;
   m_uiPanelPopup.Close();
}
void TDTabGridPopupEdit::HandleClickCancel() {
   uiCommon.setState(0, m_objBtnCancelName, false);
   m_isShow = false;
   m_uiPanelPopup.Close();
}

void TDTabGridPopupEdit::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_uiPanelPopup.OnChartEvent(id, lparam, dparam, sparam);
   m_ipStopLossPrice.OnChartEvent(id, lparam, dparam, sparam);
   m_ipTakeProfitPrice.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_objBtnSubmitName) {
         HandleClickSubmit();
      } else if(sparam == m_objBtnCancelName) {
         HandleClickCancel();
      }
   }
}

void TDTabGridPopupEdit::OnMQLTesterEvent() {
   m_uiPanelPopup.OnMQLTesterEvent();
   m_ipStopLossPrice.OnMQLTesterEvent();
   m_ipTakeProfitPrice.OnMQLTesterEvent();

   if(uiCommon.getState(g_chartId, m_objBtnSubmitName)) {
      HandleClickSubmit();
   }
   if(uiCommon.getState(g_chartId, m_objBtnCancelName)) {
      HandleClickCancel();
   }
}