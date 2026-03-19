//+------------------------------------------------------------------+
//|                     TradeDashboardView.mqh                       |
//| View: Panel UI, Popup, Chart Lines, Display Updates               |
//+------------------------------------------------------------------+
#ifndef TRADE_DASHBOARD_VIEW_MQH
#define TRADE_DASHBOARD_VIEW_MQH

#include "Model/TDM_Constants.mqh"
#include "Model/TDM_Memory.mqh"
#include "Model/TDM_RiskCalculator.mqh"
#include "Model/TDM_DCA.mqh"

// Forward declarations (defined in TDM_TradeExecution.mqh)
bool ModifySingleTicket(ulong ticket, double newSL, double newTP);

// =================================================================================
// === CÁC HÀM TIỆN ÍCH UI (Primitives) ===
// =================================================================================

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize, int zOrder=100)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int w, int h, string text, color bgClr, int fontSize, int zOrder=100)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateEdit(string name, int x, int y, int w, int h, string text, int zOrder=100, bool readOnly=false)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, readOnly ? C'220,220,220' : clrWhite);
   ObjectSetInteger(0, name, OBJPROP_COLOR, readOnly ? clrDimGray : clrBlack);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_READONLY, readOnly);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int w, int h, color clr, int zorder)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

// =================================================================================
// === CHART LINES (Trailing Stop & DCA Average) ===
// =================================================================================

//+------------------------------------------------------------------+
//| Vẽ đường Trailing Stop trên chart                                |
//+------------------------------------------------------------------+
void DrawTrailingStopLine(ulong ticket, double price)
  {
   string lineName = "TS_Line_" + IntegerToString(ticket);
   if(ObjectFind(0, lineName) < 0)
     {
      ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrMagenta);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);
      ObjectSetString(0, lineName, OBJPROP_TEXT, " Trailing Stop #" + IntegerToString(ticket));
      ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
     }
   else
      ObjectSetDouble(0, lineName, OBJPROP_PRICE, price);
  }

//+------------------------------------------------------------------+
//| Vẽ đường giá trung bình của chuỗi DCA trên chart                |
//+------------------------------------------------------------------+
void DrawDCAAvgPriceLine(int chainId, double avgPrice, bool isBuy)
  {
   string lineName = "DCA_Avg_" + IntegerToString(chainId);
   color lineClr = isBuy ? clrDodgerBlue : clrOrangeRed;
   if(ObjectFind(0, lineName) < 0)
     {
      ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, avgPrice);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
     }
   else
      ObjectSetDouble(0, lineName, OBJPROP_PRICE, avgPrice);
   string dir = isBuy ? "BUY" : "SELL";
   ObjectSetString(0, lineName, OBJPROP_TEXT,
                   " Chain#" + IntegerToString(chainId) + " " + dir + " Avg: " + DoubleToString(avgPrice, _Digits));
  }

//+------------------------------------------------------------------+
//| Xóa đường giá TB của các chuỗi DCA đã đóng hết                  |
//+------------------------------------------------------------------+
void CleanUpDCAAvgLines()
  {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "DCA_Avg_") == 0)
        {
         int cid = (int)StringToInteger(StringSubstr(name, 8));
         bool hasPositions = false;
         for(int j = 0; j < PositionsTotal(); j++)
           {
            ulong ticket = PositionGetTicket(j);
            if(ticket == 0)
               continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol)
               continue;
            if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
               continue;
            if(ExtractChainId(PositionGetString(POSITION_COMMENT)) == cid)
              { hasPositions = true; break; }
           }
         if(!hasPositions)
            ObjectDelete(0, name);
        }
     }
  }

// =================================================================================
// === ESTIMATED LOSS DISPLAY ===
// =================================================================================

//+------------------------------------------------------------------+
//| Cập nhật hiển thị tiền lỗ ước tính (dòng đỏ)                   |
//+------------------------------------------------------------------+
void UpdateEstLossDisplay()
  {
   if(!panelCreated)
      return;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double targetLossMoney = balance * (currentRiskValue / 100.0);
   if(RiskCalcMode == RISK_FIXED_USD)
      targetLossMoney = currentRiskValue;

   double lossPct = (balance > 0) ? (targetLossMoney / balance) * 100.0 : 0;

   string lossTxt = StringFormat("Est. Loss: -$%.2f (%.2f%%)", targetLossMoney, lossPct);
   ObjectSetString(0, "lblEstLoss", OBJPROP_TEXT, lossTxt);

   ChartRedraw();
  }

// =================================================================================
// === TẠO PANEL CHÍNH ===
// =================================================================================

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreatePanel()
  {
   if(panelCreated)
      return;
   int x = 10, y = 20, w = 280, h = 484;
   CreateRect("panelBG", x-5, y-5, w+10, h+10, C'25,25,40', 0);
   CreateRect("panelHeader", x, y, w, 35, C'50,50,100', 0);
   CreateLabel("lblTitle", x+80, y+5, "TRADE DASHBOARD", clrWhite, 11);
   y += 35;
   string mode = MQLInfoInteger(MQL_TESTER) ? "MODE: BACKTEST" : "MODE: REAL TRADE";
   color modeClr = MQLInfoInteger(MQL_TESTER) ? C'200,200,255' : clrLime;
   CreateLabel("lblMode", x+10, y, mode, modeClr, 8);
   y += 18;
   CreateLabel("lblInfo", x+10, y, "Positions: 0", clrWhite, 8);
   CreateLabel("lblProfit", x+140, y, "P&L: 0.00", clrYellow, 8);

   y += 20;
   string modeText = (RiskCalcMode == RISK_FIXED_USD) ? "$" : ((RiskCalcMode == RISK_FIXED_LOT) ? "Info" : "%");
   CreateLabel("lblEstLoss", x+50, y, "Est. Loss: -$0.00 (0.00%)", clrRed, 8);

   y += 20;
   CreateLabel("lblRisk", x+10, y, "Risk ("+modeText+"): ", clrWhite, 8);
   CreateButton(btnMainRisk_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtRisk", x+97, y-2, 45, 18, DoubleToString(currentRiskValue, 2), 100, true);
   CreateButton(btnMainRisk_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblSL", x+10, y, "SL (pts):", clrWhite, 8);
   CreateButton(btnMainSL_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtSL", x+97, y-2, 45, 18, IntegerToString(currentMainSL), 100, true);
   CreateButton(btnMainSL_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblLot", x+10, y, "Lot:", clrWhite, 8);
   CreateButton(btnMainLot_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtLot", x+97, y-2, 45, 18, DoubleToString(currentMainLot, 2), 100, true);
   CreateButton(btnMainLot_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblTP", x+10, y, "TP (pts):", clrWhite, 8);
   CreateButton(btnMainTP_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTP", x+97, y-2, 45, 18, IntegerToString(currentMainTP), 100, true);
   CreateButton(btnMainTP_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblTSStart", x+10, y, "T.Start:", clrWhite, 8);
   CreateButton(btnMainTSStart_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTSStart", x+97, y-2, 45, 18, IntegerToString(currentMainTS_Start), 100, true);
   CreateButton(btnMainTSStart_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblTSDist", x+10, y, "T.Dist:", clrWhite, 8);
   CreateButton(btnMainTSDist_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtTSDist", x+97, y-2, 45, 18, IntegerToString(currentMainTS_Dist), 100, true);
   CreateButton(btnMainTSDist_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateButton("btnDCAToggle", x+10, y-2, 63, 18, EnableDCA ? "DCA: ON" : "DCA: OFF", EnableDCA ? C'0,128,0' : C'128,0,0', 8);
   CreateButton(btnMainDCACount_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtDCACount", x+97, y-2, 45, 18, IntegerToString(currentMainDCA_Count), 100, true);
   CreateButton(btnMainDCACount_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);
   y += 22;
   CreateLabel("lblDCAMult", x+10, y, "DCA Mult:", clrWhite, 8);
   CreateButton(btnMainDCAMult_Sub, x+75, y-2, 20, 18, "-", clrRed, 10);
   CreateEdit("edtDCAMult", x+97, y-2, 45, 18, DoubleToString(currentMainDCA_Mult, 1), 100, true);
   CreateButton(btnMainDCAMult_Add, x+144, y-2, 20, 18, "+", clrGreen, 10);

   y += 25;
   CreateButton("btnBuy", x+10, y, 120, 32, "BUY", clrGreen, 11);
   CreateButton("btnSell", x+140, y, 120, 32, "SELL", clrRed, 11);

   y += 38;
   CreateButton("btnCloseAllDCA", x+10, y, 250, 28, "CLOSE ALL DCA", C'180,0,0', 10);

   panelCreated = true;
   ChartRedraw();
  }

// =================================================================================
// === CẬP NHẬT THÔNG TIN PANEL ===
// =================================================================================

//+------------------------------------------------------------------+
//| Cập nhật toàn bộ thông tin hiển thị                              |
//+------------------------------------------------------------------+
void UpdateInfo(bool forceUpdate)
  {
   RegisterNewTrades();
   int currentPositions = PositionsTotal();
   bool layoutChanged = (currentPositions != lastPositionsCount);
   if(!forceUpdate && !layoutChanged)
     {
      UpdatePnLText();
      return;
     }
   lastPositionsCount = currentPositions;

   if(layoutChanged)
     {
      DeleteAllPositionObjects();
      CleanUpMemoryAndLines();
      CleanUpDCAAvgLines();
     }

   int yPos = 384;

// === HIỂN THỊ THÔNG TIN CÁC CHUỖI DCA (GIÁ TRUNG BÌNH) ===
   if(EnableDCA)
     {
      int chainIds[];
      int chainCount = 0;
      GetActiveChainIds(chainIds, chainCount);

      for(int c = 0; c < chainCount; c++)
        {
         bool cisBuy;
         double cavgPrice, ctotalLots, ctotalProfit;
         int cposCount, cpendingCount;
         GetChainStats(chainIds[c], cisBuy, cavgPrice, ctotalLots, ctotalProfit, cposCount, cpendingCount);

         if(cposCount > 0)
           {
            DrawDCAAvgPriceLine(chainIds[c], cavgPrice, cisBuy);
            string dir = cisBuy ? "BUY" : "SELL";
            color chainClr = cisBuy ? clrDodgerBlue : clrOrangeRed;
            string chainText = StringFormat("C#%d %s | %d pos | Avg:%s | %.2f",
                                            chainIds[c], dir, cposCount,
                                            DoubleToString(cavgPrice, _Digits), ctotalProfit);
            string chainLbl = "DCA_Chain_" + IntegerToString(chainIds[c]);
            CreateLabel(chainLbl, 15, yPos, chainText, chainClr, 8);
            yPos += 18;
           }
        }
     }

// === HIỂN THỊ DANH SÁCH POSITION ===
   int cnt = 0;
   double profit = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long posMagic = PositionGetInteger(POSITION_MAGIC);
      if(posMagic != MagicNumber && posMagic != 0)
         continue;

      cnt++;
      profit += PositionGetDouble(POSITION_PROFIT);
      string posText = StringFormat("#%I64u | %s | %.2f", ticket, PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL", PositionGetDouble(POSITION_VOLUME));
      string posText2 = StringFormat("P/L: %.2f", PositionGetDouble(POSITION_PROFIT));
      string lblName = "Pos_Label_" + IntegerToString(ticket);

      int dummy1, dummy2;
      bool is_ts_active = false;
      GetTradeMemory(ticket, dummy1, dummy2, is_ts_active);

      color lblColor = is_ts_active ? clrMagenta : clrWhite;

      if(layoutChanged)
        {
         CreateLabel(lblName, 20, yPos, posText + " | " + posText2, lblColor, 8);
         CreateButton("Pos_Close_" + IntegerToString(ticket), 220, yPos-2, 35, 18, "X", clrRed, 8);
         CreateButton("Pos_Edit_" + IntegerToString(ticket), 260, yPos-2, 35, 18, "E", clrOrange, 8);
        }
      else
        {
         ObjectSetString(0, lblName, OBJPROP_TEXT, posText + " | " + posText2);
         ObjectSetInteger(0, lblName, OBJPROP_COLOR, lblColor);
        }
      yPos += 25;
     }
   UpdatePnLText();
   AutoCalcLotByRisk();
  }

//+------------------------------------------------------------------+
//| Cập nhật dòng P&L                                               |
//+------------------------------------------------------------------+
void UpdatePnLText()
  {
   double profit = 0;
   int cnt = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         long posMagic = PositionGetInteger(POSITION_MAGIC);
         if(posMagic == MagicNumber || posMagic == 0)
           {
            profit += PositionGetDouble(POSITION_PROFIT);
            cnt++;
           }
        }
     }
   color clr = (profit >= 0) ? clrLime : clrRed;
   if(ObjectFind(0, "lblProfit") >= 0)
     {
      ObjectSetInteger(0, "lblProfit", OBJPROP_COLOR, clr);
      ObjectSetString(0, "lblInfo", OBJPROP_TEXT, StringFormat("Positions: %d", cnt));
      ObjectSetString(0, "lblProfit", OBJPROP_TEXT, StringFormat("P&L: %.2f", profit));
     }
  }

//+------------------------------------------------------------------+
//| Xóa tất cả UI objects của danh sách position                    |
//+------------------------------------------------------------------+
void DeleteAllPositionObjects()
  {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "Pos_") == 0 || StringFind(name, "DCA_Chain_") == 0)
         ObjectDelete(0, name);
     }
  }

// =================================================================================
// === POPUP EDIT DIALOG ===
// =================================================================================

//+------------------------------------------------------------------+
//| Hiện dialog sửa lệnh                                            |
//+------------------------------------------------------------------+
void ShowEditDialog(ulong ticket)
  {
   if(popupActive && editTicket == ticket)
      return;
   if(!PositionSelectByTicket(ticket))
      return;
   editTicket = ticket;
   popupCurrentSL = PositionGetDouble(POSITION_SL);
   popupCurrentTP = PositionGetDouble(POSITION_TP);
   bool is_ts_active = false;
   if(!GetTradeMemory(ticket, popupCurrentTS_Start, popupCurrentTS_Dist, is_ts_active))
     {
      popupCurrentTS_Start = 0;
      popupCurrentTS_Dist = 0;
     }
   popupActive = true;
   int x = 320, y = 180, w = 360, h = 250, zBG = 150, zItem = 200;

   CreateRect(bgPopup, x-8, y-8, w+16, h+16, C'200,200,200', zBG);
   ObjectSetInteger(0, bgPopup, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   CreateLabel(lblPopup, x+10, y+10, "Sửa lệnh #" + IntegerToString(ticket), clrBlack, 11, zItem);

   CreateLabel("lblSLTitle", x+20, y+40, "Stop Loss:", clrBlack, 9, zItem);
   CreateButton(btnSL_Sub, x+90, y+38, 30, 22, "-", clrRed, 12, zItem);
   CreateEdit(txtSLVal, x+125, y+38, 80, 22, "", zItem, true);
   CreateButton(btnSL_Add, x+210, y+38, 30, 22, "+", clrGreen, 12, zItem);
   CreateLabel("lblTPTitle", x+20, y+75, "Take Profit:", clrBlack, 9, zItem);
   CreateButton(btnTP_Sub, x+90, y+73, 30, 22, "-", clrRed, 12, zItem);
   CreateEdit(txtTPVal, x+125, y+73, 80, 22, "", zItem, true);
   CreateButton(btnTP_Add, x+210, y+73, 30, 22, "+", clrGreen, 12, zItem);

   if(is_ts_active)
     {
      CreateLabel("lblTSStartTitle", x+20, y+110, "T.Start (LOCKED):", clrRed, 9, zItem);
      CreateEdit(txtTSStartVal, x+125, y+108, 80, 22, IntegerToString(popupCurrentTS_Start), zItem, true);
      CreateLabel("lblTSDistTitle", x+20, y+145, "T.Dist (LOCKED):", clrRed, 9, zItem);
      CreateEdit(txtTSDistVal, x+125, y+143, 80, 22, IntegerToString(popupCurrentTS_Dist), zItem, true);
     }
   else
     {
      CreateLabel("lblTSStartTitle", x+20, y+110, "T.Start (pts):", clrNavy, 9, zItem);
      CreateButton(btnTSStart_Sub, x+90, y+108, 30, 22, "-", clrRed, 12, zItem);
      CreateEdit(txtTSStartVal, x+125, y+108, 80, 22, "", zItem, true);
      CreateButton(btnTSStart_Add, x+210, y+108, 30, 22, "+", clrGreen, 12, zItem);
      CreateLabel("lblTSDistTitle", x+20, y+145, "T.Dist (pts):", clrNavy, 9, zItem);
      CreateButton(btnTSDist_Sub, x+90, y+143, 30, 22, "-", clrRed, 12, zItem);
      CreateEdit(txtTSDistVal, x+125, y+143, 80, 22, "", zItem, true);
      CreateButton(btnTSDist_Add, x+210, y+143, 30, 22, "+", clrGreen, 12, zItem);
     }
   CreateButton(btnConfirm, x+30, y+190, 140, 35, "XÁC NHẬN", clrGreen, 10, zItem);
   CreateButton(btnCancel, x+190, y+190, 140, 35, "HỦY BỎ", clrRed, 10, zItem);

   UpdatePopupDisplay();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Cập nhật hiển thị popup                                          |
//+------------------------------------------------------------------+
void UpdatePopupDisplay()
  {
   ObjectSetString(0, txtSLVal, OBJPROP_TEXT, (popupCurrentSL == 0) ? "0.0000" : DoubleToString(popupCurrentSL, _Digits));
   ObjectSetString(0, txtTPVal, OBJPROP_TEXT, (popupCurrentTP == 0) ? "0.0000" : DoubleToString(popupCurrentTP, _Digits));
   ObjectSetString(0, txtTSStartVal, OBJPROP_TEXT, IntegerToString(popupCurrentTS_Start));
   ObjectSetString(0, txtTSDistVal, OBJPROP_TEXT, IntegerToString(popupCurrentTS_Dist));
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Xử lý khi bấm XÁC NHẬN trên popup                              |
//+------------------------------------------------------------------+
void ProcessPopupConfirm()
  {
   ModifySingleTicket(editTicket, popupCurrentSL, popupCurrentTP);
   SaveTradeMemory(editTicket, popupCurrentTS_Start, popupCurrentTS_Dist);
   CloseModifyPopup();
  }

//+------------------------------------------------------------------+
//| Đóng popup                                                       |
//+------------------------------------------------------------------+
void CloseModifyPopup()
  {
   ObjectDelete(0, bgPopup);
   ObjectDelete(0, lblPopup);
   ObjectDelete(0, "lblSLTitle");
   ObjectDelete(0, btnSL_Sub);
   ObjectDelete(0, txtSLVal);
   ObjectDelete(0, btnSL_Add);
   ObjectDelete(0, "lblTPTitle");
   ObjectDelete(0, btnTP_Sub);
   ObjectDelete(0, txtTPVal);
   ObjectDelete(0, btnTP_Add);
   ObjectDelete(0, "lblTSStartTitle");
   ObjectDelete(0, btnTSStart_Sub);
   ObjectDelete(0, txtTSStartVal);
   ObjectDelete(0, btnTSStart_Add);
   ObjectDelete(0, "lblTSDistTitle");
   ObjectDelete(0, btnTSDist_Sub);
   ObjectDelete(0, txtTSDistVal);
   ObjectDelete(0, btnTSDist_Add);
   ObjectDelete(0, btnConfirm);
   ObjectDelete(0, btnCancel);
   popupActive = false;
   editTicket = 0;
   ChartRedraw();
  }

#endif
//+------------------------------------------------------------------+
