#ifndef TRADE_DASHBOARD_CONTEXT_MQH
#define TRADE_DASHBOARD_CONTEXT_MQH

#include <AutoTrade/UI/UICommon.mqh>
#include <Trade/Trade.mqh>

enum ENUM_VOLUME_TYPE {
   VOLUME_TYPE_INPUT, // Lấy volume từ input
   VOLUME_TYPE_MONEY,
   VOLUME_TYPE_PERCENT_BALANCE,
   VOLUME_TYPE_PERCENT_EQUITY
};
enum GRID_STATE {
   GRID_STATE_ORDER,     // Order pending
   GRID_STATE_POSITION,  // Position đang chạy
   GRID_STATE_CLOSED,    // Đã đóng (Deal OUT)
   GRID_STATE_CANCELLED, // Đã hủy (Deal OUT)
};

input ulong      MagicNumber   = 20260206;
input int        Slippage      = 5;
long             g_chartId     = 0;
double           g_volumeValue = 0;
ENUM_VOLUME_TYPE g_volumeType  = VOLUME_TYPE_INPUT;

// clang-format off
color g_clrBtnGreenBg        = C'0,128,0';    // ForestGreen
color g_clrBtnGreenBorder    = C'0,180,0';
color g_clrBtnGreenText      = clrWhite;

color g_clrBtnRedBg     = C'220,20,60';
color g_clrBtnRedBorder = C'255,60,100';
color g_clrBtnRedText   = clrWhite;

color g_clrBtnCancelBg     = C'200,200,200';
color g_clrBtnCancelBorder = C'160,160,160';
color g_clrBtnCancelText   = C'40,40,40';

color g_clrBtnDisabledBg     = C'160,160,160';
color g_clrBtnDisabledBorder = C'120,120,120';
color g_clrBtnDisabledText   = C'230,230,230';

color g_clrTextGreen = C'50,205,50';  // Green
color g_clrTextRed = C'255,80,80';    // Red
color g_clrTextOrange = C'255,165,0'; // Orange
color g_textColorBaseLight = C'200,200,200';

//  color g_clrBtnSubmitBg       = C'0,128,0';       // Green
//  color g_clrBtnSubmitBorder   = C'0,180,0';
//  color g_clrBtnSubmitText     = clrWhite;
// clang-format on

extern CTrade   cTrade;
extern UICommon uiCommon;
MqlTick         Tick;

struct PositionInfo {
   ulong              ticket;
   string             symbol;
   ENUM_POSITION_TYPE type;
   bool               enableTrailingStop;
   double             trailingStopStartPoints;
   double             trailingStopStepPoints;
   double             trailingStopDistancePoints;
};

extern PositionInfo g_positionList[];

struct GridInfo {
   string             id;
   ulong              ticketOrder;
   ulong              ticketPosition;
   ulong              ticketDealOpen;
   ulong              ticketDealClose;
   ENUM_POSITION_TYPE positionType;
   string             symbol;
   GRID_STATE         gridState;
   double             volume;
   double             openPrice;
   double             stopLossPrice;
   double             takeProfitPrice;
   double             closePrice;
   double             profit;
};

GridInfo g_gridList[];
int      FindIndexGridByTicketOrder(ulong ticketOrder) {
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].ticketOrder == ticketOrder) {
         return i;
      }
   }
   return -1;
}
int FindIndexGridByTicketPosition(ulong ticketPosition) {
   for(int i = 0; i < ArraySize(g_gridList); i++) {
      if(g_gridList[i].ticketPosition == ticketPosition) {
         return i;
      }
   }
   return -1;
}

void   openPopupModifyPosition(ulong ticketId);
void   changeVolumeRisk();

double CalculateSafeMaxLot(string symbol, double lotStep, double minLot, double brokerMaxLot) {
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double marginUsed    = AccountInfoDouble(ACCOUNT_MARGIN);
   double soLevel       = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);

   // Margin cần thiết để mở 1 lot của symbol này
   // Cách tính chính xác nhất: dùng OrderCalcMargin
   double marginPerLot = 0;
   double askPrice     = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(!OrderCalcMargin(ORDER_TYPE_BUY, symbol, 1.0, askPrice, marginPerLot)) {
      return minLot; // fallback an toàn
   }

   // Equity tối thiểu phải duy trì để không bị SO
   // SO xảy ra khi: Equity / MarginUsed * 100 <= soLevel
   // Sau khi mở lệnh mới, MarginUsed tăng thêm -> nguy cơ SO tăng
   // (marginUsed + marginNewLot) * soLevel / 100 < accountEquity
   // => X < accountEquity * 100 / soLevel - marginUsed

   double maxUsableMargin = (accountEquity * 100.0 / (soLevel > 0 ? soLevel : 100.0)) - marginUsed;

   if(maxUsableMargin <= 0)
      return 0.0;

   double safeMaxLot = maxUsableMargin / marginPerLot;
   return safeMaxLot;
}

double CalculateVolumeWithRiskMoney(double riskMoney, double stopLossPoints, string symbol) {
   SymbolInfoTick(symbol, Tick);
   double priceOpen     = Tick.ask; // Giá mở lệnh BUY sẽ là giá Ask, SELL sẽ là giá Bid
   double lotStep       = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot        = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot        = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   double valuePerPoint = 0.0;
   bool   checked       = OrderCalcProfit(
      ORDER_TYPE_BUY,
      _Symbol,
      1,
      priceOpen, // giá mở (Ask lúc BUY)
      priceOpen + SymbolInfoDouble(symbol, SYMBOL_POINT),
      valuePerPoint
   );
   if(!checked) {
      return 0.0;
   }
   double volumeRisk = riskMoney / (stopLossPoints * valuePerPoint);

   // Tính lại maxLot
   double safeMaxLot = CalculateSafeMaxLot(symbol, lotStep, minLot, maxLot);
   maxLot            = MathMin(maxLot, safeMaxLot);

   return MathFloor(volumeRisk / lotStep) * lotStep;
};

double CalculateVolumeWithRiskMoneyV2(double riskMoney, double stopLossPoints, string symbol) {
   // POINT: Đơn vị giá nhỏ nhất theo số digit mà symbol hiển thị. Phụ thuộc vào SYMBOL_DIGITS
   // Ví dụ: EURUSD 5-digit: Giá: 1.10000 → 1.10001 ==> POINT = 0.00001
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   // TickSize = bước giá nhỏ nhất mà symbol có thể thay đổi
   // Ví dụ: EURUSD 5-digit: Giá: 1.10000 → 1.10001 ==> TickSize = 0.00001 => TH này giống _POINTS
   // Ví dụ: Digits = 2;_Point = 0.01; TickSize = 0.25
   // TH này thì Giá hiển thị: 100.00, 100.01, 100.02 ...
   // Nhưng thực tế chỉ khớp lệnh được: 100.00 → 100.25 → 100.50 → 100.75
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   // TickValue = số tiền lời/lỗ khi giá di chuyển 1 tick size với 1 lot tiêu chuẩn (100,000
   // units). Ví dụ: Nếu TickSize = 0.00001 ==> TicketValue = 1 USD với cặp EURUSD
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

   // Giá trị tiền của 1 point với 1 lot
   double valuePerPoint = tickValue / tickSize * point;
   // Số tiền mất nếu SL hit với 1 lot
   double lossPerLot = stopLossPoints * valuePerPoint;

   if(lossPerLot <= 0)
      return 0.0;
   double volume  = riskMoney / lossPerLot;

   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   volume         = MathFloor(volume / lotStep) * lotStep;
   volume         = MathMax(minLot, MathMin(volume, maxLot));

   return volume;
};

double CalculateVolumeWithRiskPercentBalance(
   double riskPercent, double stopLossPoints, string symbol
) {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * riskPercent / 100.0;
   return CalculateVolumeWithRiskMoney(riskMoney, stopLossPoints, symbol);
};

double CalculateVolumeWithRiskPercentEquity(
   double riskPercent, double stopLossPoints, string symbol
) {
   double balance   = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = balance * riskPercent / 100.0;
   return CalculateVolumeWithRiskMoney(riskMoney, stopLossPoints, symbol);
};

double CalculateStopLossWithRiskMoney(double riskMoney, double volume, string symbol) {
   if(volume <= 0.0)
      return 0.0;

   double point         = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tickSize      = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue     = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

   double valuePerPoint = tickValue / tickSize * point;

   if(valuePerPoint <= 0.0)
      return 0.0;

   double stopLossPoints = riskMoney / (volume * valuePerPoint);

   return stopLossPoints;
}

double CalculateStopLossWithRiskPercent(double riskPercent, double volume, string symbol) {
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * riskPercent / 100.0;

   return CalculateStopLossWithRiskMoney(riskMoney, volume, symbol);
}

#endif // TRADE_DASHBOARD_CONTEXT_MQH