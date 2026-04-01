//+------------------------------------------------------------------+
//|                    Trade Dashboard v7.0 FINAL                    |
//| Feature: Safe Margin, Catch Phone Trades, Error Alert Speaker    |
//| Architecture: MVC (Model-View-Controller)                        |
//+------------------------------------------------------------------+
#property copyright "Trade Dashboard"
#property version   "7.0"
#property strict

// =================================================================================
// === INCLUDE MVC MODULES (THỨ TỰ QUAN TRỌNG!) ===
// =================================================================================
#include "Model/TDM_Constants.mqh"       // 1. Enums, Structs, Global State
#include "Model/TDM_Memory.mqh"          // 2. Persistence (Save/Load .BIN)
#include "Model/TDM_RiskCalculator.mqh"  // 3. Risk, Lot, Margin
#include "Model/TDM_DCA.mqh"             // 4. DCA Logic          
#include "Model/TDM_NewsFilter.mqh"       // 5. News Filter
#include "Model/TDM_TrailingStop.mqh"    // 6. Trailing Stop
#include "Model/TDM_TradeExecution.mqh"  // 6. Trade Execution
#include "TradeDashboardView.mqh"        // 7. View (Panel, Popup, Chart Lines)

// =================================================================================
// === CONTROLLER: LOGIC CHÍNH ===
// =================================================================================
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   LoadMemoryFromFile();

   currentMainSL = StopLossPoints;
   currentMainTP = TakeProfitPoints;
   currentRiskValue = DefaultRiskValue;
   if(RiskCalcMode == RISK_FIXED_LOT)
      currentMainLot = NormalizeLot(LotSize);
   currentMainTS_Start = TrailingStartPoints;
   currentMainTS_Dist = TrailingDistPoints;
   currentMainDCA_Count = DCAOrderCount;
   currentMainDCA_Mult = DCAMultiplier;
   EnableDCA = EnableDCA_Input;

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      CreatePanel();
      if(RiskCalcMode != RISK_FIXED_LOT)
         AutoCalcLotByRisk();
      else
         UpdateEstLossDisplay();
      UpdateInfo(true);
     }
   if(UIUpdateSeconds > 0)
      EventSetTimer(UIUpdateSeconds);
   lastUIUpdate = TimeCurrent();

   Print("✓ Dashboard v7.0 MVC - Khởi động thành công!");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   SaveMemoryToFile();
   SaveDCAMemory();
   CancelAllDCAPendingOrders();
   for(int i = 0; i < ArraySize(UI); i++)
      ObjectDelete(0, UI[i]);
   DeleteAllPositionObjects();
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "TS_Line_") == 0 || StringFind(name, "DCA_Avg_") == 0)
         ObjectDelete(0, name);
     }
   CloseModifyPopup();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     {
      ScanButtonsBacktest();
      UpdateInfo(false);
      ChartRedraw();
      UpdateEstLossDisplay();
     }
   ProcessTrailingStop();
   ProcessNewsFilter();

// === QUẢN LÝ MULTI-CHAIN DCA: Hủy pending từng chuỗi khi hết position ===
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

         if(cposCount == 0 && cpendingCount > 0)
           {
            Print("⚠️ Chain#", chainIds[c], " hết position - Hủy ", cpendingCount, " lệnh chờ!");
            CancelChainPendingOrders(chainIds[c]);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!MQLInfoInteger(MQL_TESTER))
     {
      if(UIUpdateSeconds > 0 && TimeCurrent() - lastUIUpdate >= UIUpdateSeconds)
        {
         UpdateInfo(true);
         lastUIUpdate = TimeCurrent();
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& req,const MqlTradeResult& res)
  {
   UpdateInfo(true);
  }

// =================================================================================
// === CONTROLLER: XỬ LÝ SỰ KIỆN CLICK CHUỘT LÚC BACKTEST ===
// =================================================================================
void ScanButtonsBacktest()
  {
   if(!MQLInfoInteger(MQL_TESTER))
      return;

   if(ObjectGetInteger(0, "btnBuy", OBJPROP_STATE) == 1)
     {
      ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false);
      OpenBuy();
      return;
     }
   if(ObjectGetInteger(0, "btnSell", OBJPROP_STATE) == 1)
     {
      ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false);
      OpenSell();
      return;
     }

   if(!popupActive)
     {
      if(ObjectGetInteger(0, btnMainRisk_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainRisk_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("RISK", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainRisk_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainRisk_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("RISK", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainSL_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainSL_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("SL", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainSL_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainSL_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("SL", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTP_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTP_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("TP", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTP_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTP_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("TP", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainLot_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainLot_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("LOT", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainLot_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainLot_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("LOT", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTSStart_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTSStart_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("TS_START", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTSStart_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTSStart_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("TS_START", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTSDist_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTSDist_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("TS_DIST", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainTSDist_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainTSDist_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("TS_DIST", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainDCACount_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainDCACount_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("DCA_COUNT", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainDCACount_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainDCACount_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("DCA_COUNT", 1);
         return;
        }
      if(ObjectGetInteger(0, btnMainDCAMult_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainDCAMult_Sub, OBJPROP_STATE, false);
         AdjustMainPanelValue("DCA_MULT", -1);
         return;
        }
      if(ObjectGetInteger(0, btnMainDCAMult_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnMainDCAMult_Add, OBJPROP_STATE, false);
         AdjustMainPanelValue("DCA_MULT", 1);
         return;
        }

      // NÚT TOGGLE DCA ON/OFF
      if(ObjectGetInteger(0, "btnDCAToggle", OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, "btnDCAToggle", OBJPROP_STATE, false);
         EnableDCA = !EnableDCA;
         ObjectSetString(0, "btnDCAToggle", OBJPROP_TEXT, EnableDCA ? "DCA: ON" : "DCA: OFF");
         ObjectSetInteger(0, "btnDCAToggle", OBJPROP_BGCOLOR, EnableDCA ? C'0,128,0' : C'128,0,0');
         AutoCalcLotByRisk();
         return;
        }

      // NÚT CLOSE ALL DCA
      if(ObjectGetInteger(0, "btnCloseAllDCA", OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, "btnCloseAllDCA", OBJPROP_STATE, false);
         CloseAllDCAChain();
         return;
        }

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         string btnClose = "Pos_Close_" + IntegerToString(ticket);
         string btnEdit = "Pos_Edit_" + IntegerToString(ticket);

         if(ObjectGetInteger(0, btnClose, OBJPROP_STATE) == 1)
           {
            ObjectSetInteger(0, btnClose, OBJPROP_STATE, false);
            CloseTicketPosition(ticket);
            return;
           }
         if(ObjectGetInteger(0, btnEdit, OBJPROP_STATE) == 1)
           {
            ObjectSetInteger(0, btnEdit, OBJPROP_STATE, false);
            ShowEditDialog(ticket);
            return;
           }
        }
     }

   if(popupActive)
     {
      if(ObjectGetInteger(0, btnConfirm, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false);
         ProcessPopupConfirm();
         return;
        }
      if(ObjectGetInteger(0, btnCancel, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false);
         CloseModifyPopup();
         return;
        }
      if(ObjectGetInteger(0, btnSL_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnSL_Sub, OBJPROP_STATE, false);
         AdjustPopupValue("SL", -1);
         return;
        }
      if(ObjectGetInteger(0, btnSL_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnSL_Add, OBJPROP_STATE, false);
         AdjustPopupValue("SL", 1);
         return;
        }
      if(ObjectGetInteger(0, btnTP_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTP_Sub, OBJPROP_STATE, false);
         AdjustPopupValue("TP", -1);
         return;
        }
      if(ObjectGetInteger(0, btnTP_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTP_Add, OBJPROP_STATE, false);
         AdjustPopupValue("TP", 1);
         return;
        }
      if(ObjectGetInteger(0, btnTSStart_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTSStart_Sub, OBJPROP_STATE, false);
         AdjustPopupValue("TS_START", -1);
         return;
        }
      if(ObjectGetInteger(0, btnTSStart_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTSStart_Add, OBJPROP_STATE, false);
         AdjustPopupValue("TS_START", 1);
         return;
        }
      if(ObjectGetInteger(0, btnTSDist_Sub, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTSDist_Sub, OBJPROP_STATE, false);
         AdjustPopupValue("TS_DIST", -1);
         return;
        }
      if(ObjectGetInteger(0, btnTSDist_Add, OBJPROP_STATE) == 1)
        {
         ObjectSetInteger(0, btnTSDist_Add, OBJPROP_STATE, false);
         AdjustPopupValue("TS_DIST", 1);
         return;
        }
     }
  }

// =================================================================================
// === CONTROLLER: XỬ LÝ SỰ KIỆN CLICK CHUỘT TRÊN CHART THỰC TẾ ===
// =================================================================================
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(MQLInfoInteger(MQL_TESTER))
      return;

   if(id == CHARTEVENT_KEYDOWN)
     {
      if(lparam == 66)
         OpenBuy();
      else
         if(lparam == 83)
            OpenSell();
      ChartRedraw();
     }
   else
      if(id == CHARTEVENT_OBJECT_CLICK && sparam != "")
        {
         if(sparam == btnConfirm)
           {
            ObjectSetInteger(0, btnConfirm, OBJPROP_STATE, false);
            ProcessPopupConfirm();
           }
         else
            if(sparam == btnCancel)
              {
               ObjectSetInteger(0, btnCancel, OBJPROP_STATE, false);
               CloseModifyPopup();
              }
            else
               if(sparam == btnSL_Sub)
                 {
                  ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                  AdjustPopupValue("SL", -1);
                 }
               else
                  if(sparam == btnSL_Add)
                    {
                     ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                     AdjustPopupValue("SL", 1);
                    }
                  else
                     if(sparam == btnTP_Sub)
                       {
                        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                        AdjustPopupValue("TP", -1);
                       }
                     else
                        if(sparam == btnTP_Add)
                          {
                           ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                           AdjustPopupValue("TP", 1);
                          }
                        else
                           if(sparam == btnTSStart_Sub)
                             {
                              ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                              AdjustPopupValue("TS_START", -1);
                             }
                           else
                              if(sparam == btnTSStart_Add)
                                {
                                 ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                 AdjustPopupValue("TS_START", 1);
                                }
                              else
                                 if(sparam == btnTSDist_Sub)
                                   {
                                    ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                    AdjustPopupValue("TS_DIST", -1);
                                   }
                                 else
                                    if(sparam == btnTSDist_Add)
                                      {
                                       ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                       AdjustPopupValue("TS_DIST", 1);
                                      }
                                    else
                                       if(sparam == btnMainRisk_Sub)
                                         {
                                          ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                          AdjustMainPanelValue("RISK", -1);
                                         }
                                       else
                                          if(sparam == btnMainRisk_Add)
                                            {
                                             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                             AdjustMainPanelValue("RISK", 1);
                                            }
                                          else
                                             if(sparam == btnMainSL_Sub)
                                               {
                                                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                AdjustMainPanelValue("SL", -1);
                                               }
                                             else
                                                if(sparam == btnMainSL_Add)
                                                  {
                                                   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                   AdjustMainPanelValue("SL", 1);
                                                  }
                                                else
                                                   if(sparam == btnMainTP_Sub)
                                                     {
                                                      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                      AdjustMainPanelValue("TP", -1);
                                                     }
                                                   else
                                                      if(sparam == btnMainTP_Add)
                                                        {
                                                         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                         AdjustMainPanelValue("TP", 1);
                                                        }
                                                      else
                                                         if(sparam == btnMainLot_Sub)
                                                           {
                                                            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                            AdjustMainPanelValue("LOT", -1);
                                                           }
                                                         else
                                                            if(sparam == btnMainLot_Add)
                                                              {
                                                               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                               AdjustMainPanelValue("LOT", 1);
                                                              }
                                                            else
                                                               if(sparam == btnMainTSStart_Sub)
                                                                 {
                                                                  ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                  AdjustMainPanelValue("TS_START", -1);
                                                                 }
                                                               else
                                                                  if(sparam == btnMainTSStart_Add)
                                                                    {
                                                                     ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                     AdjustMainPanelValue("TS_START", 1);
                                                                    }
                                                                  else
                                                                     if(sparam == btnMainTSDist_Sub)
                                                                       {
                                                                        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                        AdjustMainPanelValue("TS_DIST", -1);
                                                                       }
                                                                     else
                                                                        if(sparam == btnMainTSDist_Add)
                                                                          {
                                                                           ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                           AdjustMainPanelValue("TS_DIST", 1);
                                                                          }
                                                                        else
                                                                           if(sparam == btnMainDCACount_Sub)
                                                                             {
                                                                              ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                              AdjustMainPanelValue("DCA_COUNT", -1);
                                                                             }
                                                                           else
                                                                              if(sparam == btnMainDCACount_Add)
                                                                                {
                                                                                 ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                 AdjustMainPanelValue("DCA_COUNT", 1);
                                                                                }
                                                                              else
                                                                                 if(sparam == btnMainDCAMult_Sub)
                                                                                   {
                                                                                    ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                    AdjustMainPanelValue("DCA_MULT", -1);
                                                                                   }
                                                                                 else
                                                                                    if(sparam == btnMainDCAMult_Add)
                                                                                      {
                                                                                       ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                       AdjustMainPanelValue("DCA_MULT", 1);
                                                                                      }
                                                                                    else
                                                                                       if(sparam == "btnBuy")
                                                                                         {
                                                                                          ObjectSetInteger(0, "btnBuy", OBJPROP_STATE, false);
                                                                                          OpenBuy();
                                                                                         }
                                                                                       else
                                                                                          if(sparam == "btnSell")
                                                                                            {
                                                                                             ObjectSetInteger(0, "btnSell", OBJPROP_STATE, false);
                                                                                             OpenSell();
                                                                                            }
                                                                                          else
                                                                                             if(sparam == "btnDCAToggle")
                                                                                               {
                                                                                                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                                EnableDCA = !EnableDCA;
                                                                                                ObjectSetString(0, "btnDCAToggle", OBJPROP_TEXT, EnableDCA ? "DCA: ON" : "DCA: OFF");
                                                                                                ObjectSetInteger(0, "btnDCAToggle", OBJPROP_BGCOLOR, EnableDCA ? C'0,128,0' : C'128,0,0');
                                                                                                AutoCalcLotByRisk();
                                                                                               }
                                                                                             else
                                                                                                if(sparam == "btnCloseAllDCA")
                                                                                                  {
                                                                                                   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                                   CloseAllDCAChain();
                                                                                                  }
                                                                                                else
                                                                                                   if(StringFind(sparam, "Pos_Close_") == 0)
                                                                                                     {
                                                                                                      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                                      ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 10));
                                                                                                      CloseTicketPosition(ticket);
                                                                                                     }
                                                                                                   else
                                                                                                      if(StringFind(sparam, "Pos_Edit_") == 0)
                                                                                                        {
                                                                                                         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                                                                                                         ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 9));
                                                                                                         ShowEditDialog(ticket);
                                                                                                        }
         ChartRedraw();
        }
  }

// === TĂNG GIẢM MAIN PANEL ===
void AdjustMainPanelValue(string type, int direction)
  {
   int step = ButtonStepPoints;
   if(type == "RISK")
     {
      if(RiskCalcMode == RISK_FIXED_LOT)
         return;
      double riskStep = (RiskCalcMode == RISK_FIXED_USD) ? 10.0 : 0.1;
      currentRiskValue += (direction * riskStep);
      if(currentRiskValue <= 0.1)
         currentRiskValue = 0.1;
      ObjectSetString(0, "edtRisk", OBJPROP_TEXT, DoubleToString(currentRiskValue, 2));
      AutoCalcLotByRisk(); // Tính Lot (tự nhận diện DCA ON/OFF)
     }
   else
      if(type == "SL")
        {
         currentMainSL += (direction * step);
         if(currentMainSL < 10)
            currentMainSL = 10;
         ObjectSetString(0, "edtSL", OBJPROP_TEXT, IntegerToString(currentMainSL));
         AutoCalcLotByRisk(); // Kéo SL cũng tính xuôi ra Lot
        }
      else
         if(type == "TP")
           {
            currentMainTP += (direction * step);
            if(currentMainTP < 0)
               currentMainTP = 0;
            ObjectSetString(0, "edtTP", OBJPROP_TEXT, IntegerToString(currentMainTP));
           }
         else
            if(type == "LOT")
              {
               double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP), minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
               currentMainLot += (direction * volStep);
               if(currentMainLot < minLot)
                  currentMainLot = minLot;
               if(currentMainLot > maxLot)
                  currentMainLot = maxLot;
               currentMainLot = NormalizeLot(currentMainLot);
               ObjectSetString(0, "edtLot", OBJPROP_TEXT, DoubleToString(currentMainLot, 2));

               // KHÔNG GỌI HÀM TÍNH NGƯỢC NỮA, CHỈ CẬP NHẬT DÒNG TIỀN ĐỎ
               UpdateEstLossDisplay();
              }
            else
               if(type == "TS_START")
                 {
                  currentMainTS_Start += (direction * step);
                  if(currentMainTS_Start < 0)
                     currentMainTS_Start = 0;
                  ObjectSetString(0, "edtTSStart", OBJPROP_TEXT, IntegerToString(currentMainTS_Start));
                 }
               else
                  if(type == "TS_DIST")
                    {
                     currentMainTS_Dist += (direction * step);
                     if(currentMainTS_Dist < 0)
                        currentMainTS_Dist = 0;
                     ObjectSetString(0, "edtTSDist", OBJPROP_TEXT, IntegerToString(currentMainTS_Dist));
                    }
                  else
                     if(type == "DCA_COUNT")
                       {
                        currentMainDCA_Count += direction;
                        if(currentMainDCA_Count < 1)
                           currentMainDCA_Count = 1;
                        ObjectSetString(0, "edtDCACount", OBJPROP_TEXT, IntegerToString(currentMainDCA_Count));
                       }
                     else
                        if(type == "DCA_MULT")
                          {
                           currentMainDCA_Mult += (direction * 0.1);
                           if(currentMainDCA_Mult < 1.0)
                              currentMainDCA_Mult = 1.0;
                           currentMainDCA_Mult = NormalizeDouble(currentMainDCA_Mult, 1);
                           ObjectSetString(0, "edtDCAMult", OBJPROP_TEXT, DoubleToString(currentMainDCA_Mult, 1));
                          }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AdjustPopupValue(string type, int direction)
  {
   bool is_active = false;
   int dummy1, dummy2;
   GetTradeMemory(editTicket, dummy1, dummy2, is_active);
   if(type == "TS_START")
     {
      if(is_active)
         return;
      popupCurrentTS_Start += (direction * ButtonStepPoints);
      if(popupCurrentTS_Start < 0)
         popupCurrentTS_Start = 0;
     }
   else
      if(type == "TS_DIST")
        {
         if(is_active)
            return;
         popupCurrentTS_Dist += (direction * ButtonStepPoints);
         if(popupCurrentTS_Dist < 0)
            popupCurrentTS_Dist = 0;
        }
   double step = ButtonStepPoints * _Point;
   long posType = PositionGetInteger(POSITION_TYPE);
   if(type == "SL")
     {
      if(popupCurrentSL == 0)
        {
         double open = 0;
         if(PositionSelectByTicket(editTicket))
            open = PositionGetDouble(POSITION_PRICE_OPEN);
         popupCurrentSL = (posType == POSITION_TYPE_BUY) ? (open - step) : (open + step);
        }
      else
         popupCurrentSL += (posType == POSITION_TYPE_BUY ? -1 : 1) * (direction * step);
      popupCurrentSL = NormalizePrice(popupCurrentSL);
     }
   else
      if(type == "TP")
        {
         if(popupCurrentTP == 0)
           {
            double open = 0;
            if(PositionSelectByTicket(editTicket))
               open = PositionGetDouble(POSITION_PRICE_OPEN);
            popupCurrentTP = (posType == POSITION_TYPE_BUY) ? (open + step) : (open - step);
           }
         else
            popupCurrentTP += (posType == POSITION_TYPE_BUY ? 1 : -1) * (direction * step);
         popupCurrentTP = NormalizePrice(popupCurrentTP);
        }
   UpdatePopupDisplay();
  }
//+------------------------------------------------------------------+
