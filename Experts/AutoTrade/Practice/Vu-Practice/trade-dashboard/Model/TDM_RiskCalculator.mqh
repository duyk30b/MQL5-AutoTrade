//+------------------------------------------------------------------+
//|                      TDM_RiskCalculator.mqh                      |
//| Logic: Margin, Lot Normalization, Risk Calculation                |
//+------------------------------------------------------------------+
#ifndef TDM_RISK_CALCULATOR_MQH
#define TDM_RISK_CALCULATOR_MQH

#include "TDM_Constants.mqh"

// Forward declarations (defined in TradeDashboardView.mqh)
void UpdateEstLossDisplay();

// --- LOGIC SỐ HỌC & KHIÊN BẢO VỆ MARGIN ---

//+------------------------------------------------------------------+
//| Tính Lot an toàn tối đa dựa trên Free Margin                    |
//+------------------------------------------------------------------+
double GetSafeMaxLot()
  {
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginPerLot = 0;
   double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, askPrice, marginPerLot) || marginPerLot <= 0)
     {
      Print("⚠️ CẢNH BÁO: Sàn lag không trả lời Margin! Kích hoạt khiên Min Lot.");
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     }
   double safeLot = (freeMargin * 0.98) / marginPerLot;
   return safeLot;
  }

//+------------------------------------------------------------------+
//| Chuẩn hóa Lot theo bước + giới hạn Margin                       |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double broker_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double safe_max = GetSafeMaxLot();
   double final_max = MathMin(broker_max, safe_max);
   final_max = MathFloor(final_max / step) * step;

   lot = MathRound(lot / step) * step;

   if(lot > final_max)
      lot = final_max;
   if(lot < min_lot)
      lot = min_lot;

   return lot;
  }

// =================================================================================
// === THUẬT TOÁN TÍNH TOÁN RỦI RO & KHỐI LƯỢNG ===
// =================================================================================

//+------------------------------------------------------------------+
//| Lấy giá trị 1 point (USD)                                        |
//+------------------------------------------------------------------+
double GetPointValue()
  {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0 || tickValue == 0)
      return 0;
   return tickValue * (_Point / tickSize);
  }

//+------------------------------------------------------------------+
//| TÍNH LOT THEO RISK — CÔNG THỨC THỐNG NHẤT (DCA & ĐƠN LẺ)      |
//| R = V × L1 × Σ( m^i × D_(i+1) )                               |
//| Khi n=1: suy biến thành L1 = R / (SL × V) = công thức đơn     |
//+------------------------------------------------------------------+
void AutoCalcLotByRisk()
  {
   if(currentMainSL <= 0 || currentRiskValue <= 0)
      return;
   if(RiskCalcMode == RISK_FIXED_LOT)
     {
      UpdateEstLossDisplay();
      return;
     }

   double pointValue = GetPointValue();
   if(pointValue == 0)
      return;

// 1. Tính tổng số tiền rủi ro (USD)
   double riskMoney = 0;
   if(RiskCalcMode == RISK_PERCENT_BALANCE)
      riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * (currentRiskValue / 100.0);
   else
      if(RiskCalcMode == RISK_PERCENT_EQUITY)
         riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * (currentRiskValue / 100.0);
      else
         if(RiskCalcMode == RISK_FIXED_USD)
            riskMoney = currentRiskValue;

// 2. Tính tổng trọng số khoảng cách của chuỗi DCA
//    Khoảng cách các lệnh DCA chia đều từ Entry đến SL
   double totalDistanceWeight = 0;
   int n = currentMainDCA_Count;
   double m = currentMainDCA_Mult;
   double step = (double)currentMainSL / n;

   for(int i = 0; i < n; i++)
     {
      double lotWeight = MathPow(m, i);
      double distanceToSL = currentMainSL - (i * step);
      totalDistanceWeight += (lotWeight * distanceToSL);
     }

// 3. Tính Lot gốc (Lệnh đầu tiên)
   if(totalDistanceWeight > 0)
     {
      double baseLot = riskMoney / (totalDistanceWeight * pointValue);
      currentMainLot = NormalizeLot(baseLot);
     }

   ObjectSetString(0, "edtLot", OBJPROP_TEXT, DoubleToString(currentMainLot, 2));
   UpdateEstLossDisplay();
  }

#endif
//+------------------------------------------------------------------+
