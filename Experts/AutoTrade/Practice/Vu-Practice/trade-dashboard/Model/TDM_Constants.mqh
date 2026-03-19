//+------------------------------------------------------------------+
//|                        TDM_Constants.mqh                         |
//| Enums, Structs, Input Parameters, Global State Variables         |
//+------------------------------------------------------------------+
#ifndef TDM_CONSTANTS_MQH
#define TDM_CONSTANTS_MQH

#include <Trade/Trade.mqh>

// === INPUT PARAMETERS ===
enum ENUM_RISK_TYPE
  {
   RISK_PERCENT_BALANCE, // Tính % rủi ro theo số dư Balance
   RISK_PERCENT_EQUITY,  // Tính % rủi ro theo Vốn thực tế Equity
   RISK_FIXED_USD,       // Tính rủi ro bằng số Tiền cố định (USD)
   RISK_FIXED_LOT        // Đánh Volume (Lot) bình thường (Thủ công)
  };

input ENUM_RISK_TYPE RiskCalcMode = RISK_PERCENT_BALANCE;
input double DefaultRiskValue = 1.0;

input double LotSize = 0.1;
input int    StopLossPoints = 500;
input int    TakeProfitPoints = 1000;
input int    MagicNumber = 123456;
input int    UIUpdateSeconds = 1;
input int    ButtonStepPoints = 100;

input string _ts = "=== TRAILING STOP SETTINGS ===";
input int    TrailingStartPoints = 100; // Để 100 cho nhạy ở tài khoản Real
input int    TrailingDistPoints  = 50;
input bool   ManageManualTrades  = true; // BẬT ON: Tự kéo TS cho lệnh đánh trên Điện Thoại

input string _dca = "=== DCA SETTINGS ===";
input int    DCAOrderCount       = 5;     // Số lệnh sẽ DCA (5 = mở 1 order market + 4 pending)
input double DCAMultiplier       = 1.5;   // Hệ số nhân từ 1 level sang level tiếp theo
input bool   EnableDCA_Input      = true;  // Bật/Tắt DCA (mặc định)
bool         EnableDCA            = true;  // Runtime toggle

input string _news = "=== NEWS FILTER ===";
input bool   EnableNewsFilter   = true;    // Lọc tin: chặn trade trong vùng tin
input int    NewsMinutesBefore  = 15;      // Phút chặn TRƯỚC giờ tin
input int    NewsMinutesAfter   = 15;      // Phút chặn SAU giờ tin
input bool   NewsHighImpactOnly = true;    // Chỉ lọc tin tác động cao (★★★)
input string NewsCurrencies     = "USD"; // Tiền tệ cần theo dõi (phân cách bằng dấu phẩy, VD: "USD,EUR,GBP")
input string NewsFilePath       = "news_data.csv";     // File CSV dùng cho Backtest (trong Common/Files/)

// === BIẾN GLOBAL ===
CTrade trade;
bool panelCreated = false;
datetime lastUIUpdate = 0;
int lastPositionsCount = -1;
int nextDCAChainId = 1;

int currentMainSL = 0;
int currentMainTP = 0;
double currentMainLot = 0.01;
double currentRiskValue = 1.0;
int currentMainTS_Start = 100;
int currentMainTS_Dist = 50;
int currentMainDCA_Count = 5;
double currentMainDCA_Mult = 1.5;

// === TÊN NÚT MAIN PANEL ===
string btnMainSL_Sub = "btnMainSL_Sub", btnMainSL_Add = "btnMainSL_Add";
string btnMainTP_Sub = "btnMainTP_Sub", btnMainTP_Add = "btnMainTP_Add";
string btnMainLot_Sub = "btnMainLot_Sub", btnMainLot_Add = "btnMainLot_Add";
string btnMainRisk_Sub = "btnMainRisk_Sub", btnMainRisk_Add = "btnMainRisk_Add";
string btnMainTSStart_Sub = "btnMainTSStart_Sub", btnMainTSStart_Add = "btnMainTSStart_Add";
string btnMainTSDist_Sub = "btnMainTSDist_Sub", btnMainTSDist_Add = "btnMainTSDist_Add";
string btnMainDCACount_Sub = "btnMainDCACount_Sub", btnMainDCACount_Add = "btnMainDCACount_Add";
string btnMainDCAMult_Sub = "btnMainDCAMult_Sub", btnMainDCAMult_Add = "btnMainDCAMult_Add";

// === POPUP STATE ===
bool   popupActive = false;
ulong  editTicket  = 0;
double popupCurrentSL = 0;
double popupCurrentTP = 0;
int    popupCurrentTS_Start = 0;
int    popupCurrentTS_Dist = 0;

// === TÊN NÚT POPUP ===
string lblPopup      = "lblPopupTitle";
string bgPopup       = "popupBG";
string txtSLVal      = "txtPopupSLVal", txtTPVal = "txtPopupTPVal";
string txtTSStartVal = "txtPopupTSStartVal", txtTSDistVal = "txtPopupTSDistVal";
string btnConfirm    = "btnPopupConfirm", btnCancel = "btnPopupCancel";
string btnSL_Sub     = "btnPopupSL_Sub", btnSL_Add = "btnPopupSL_Add";
string btnTP_Sub     = "btnPopupTP_Sub", btnTP_Add = "btnPopupTP_Add";
string btnTSStart_Sub = "btnPopupTSStart_Sub", btnTSStart_Add = "btnPopupTSStart_Add";
string btnTSDist_Sub = "btnPopupTSDist_Sub", btnTSDist_Add = "btnPopupTSDist_Add";

// === DANH SÁCH UI OBJECTS ===
string UI[] = {"panelBG","panelHeader","lblTitle","lblMode","lblInfo","lblProfit","lblEstLoss",
               "edtSL","edtTP","edtLot","edtRisk","edtTSStart","edtTSDist","edtDCACount","edtDCAMult",
               "lblSL","lblTP","lblLot","lblRisk","lblTSStart","lblTSDist","lblDCAMult",
               "btnBuy","btnSell",
               "btnMainSL_Sub", "btnMainSL_Add", "btnMainTP_Sub", "btnMainTP_Add",
               "btnMainLot_Sub", "btnMainLot_Add", "btnMainRisk_Sub", "btnMainRisk_Add",
               "btnMainTSStart_Sub", "btnMainTSStart_Add", "btnMainTSDist_Sub", "btnMainTSDist_Add",
               "btnMainDCACount_Sub", "btnMainDCACount_Add", "btnMainDCAMult_Sub", "btnMainDCAMult_Add",
               "btnCloseAllDCA","btnDCAToggle"
              };

// === STRUCT BỘ NHỚ TRAILING STOP ===
struct TradeMemory { ulong ticket; int ts_start; int ts_dist; bool is_active; };
TradeMemory tsMem[];
string backupFileName = "TradeDashboard_Mem_" + IntegerToString(MagicNumber) + ".bin";

// === HÀM TIỆN ÍCH DÙNG CHUNG ===
double NormalizePrice(double price) { return NormalizeDouble(price, _Digits); }

#endif
//+------------------------------------------------------------------+
