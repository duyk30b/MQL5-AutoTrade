//+------------------------------------------------------------------+
//|                         Trade Dashboard v7.0 FINAL               |
//| Feature: Safe Margin, Catch Phone Trades, Error Alert Speaker    |
//+------------------------------------------------------------------+
#property copyright "Trade Dashboard"
#property version   "7.0"
#property strict

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
input int    ButtonStepPoints = 10;

input string _ts = "=== TRAILING STOP SETTINGS ===";
input int    TrailingStartPoints = 100; // Để 100 cho nhạy ở tài khoản Real
input int    TrailingDistPoints  = 50;
input bool   ManageManualTrades  = true; // BẬT ON: Tự kéo TS cho lệnh đánh trên Điện Thoại

input string _dca = "=== DCA SETTINGS ===";
input int    DCAOrderCount       = 5;     // Số lệnh sẽ DCA (5 = mở 1 order market + 4 pending)
input double DCAMultiplier       = 1.5;   // Hệ số nhân từ 1 level sang level tiếp theo
input bool   EnableDCA           = true;  // Bật/Tắt DCA

// === BIẾN GLOBAL ===
CTrade trade;
bool panelCreated = false;
datetime lastUIUpdate = 0;
int lastPositionsCount = -1;
int nextDCAChainId = 1; // ID cho chuỗi DCA tiếp theo (tăng dần)

int currentMainSL = 0;
int currentMainTP = 0;
double currentMainLot = 0.01;
double currentRiskValue = 1.0;
int currentMainTS_Start = 100;
int currentMainTS_Dist = 50;
int currentMainDCA_Count = 5;
double currentMainDCA_Mult = 1.5;

string btnMainSL_Sub = "btnMainSL_Sub", btnMainSL_Add = "btnMainSL_Add";
string btnMainTP_Sub = "btnMainTP_Sub", btnMainTP_Add = "btnMainTP_Add";
string btnMainLot_Sub = "btnMainLot_Sub", btnMainLot_Add = "btnMainLot_Add";
string btnMainRisk_Sub = "btnMainRisk_Sub", btnMainRisk_Add = "btnMainRisk_Add";
string btnMainTSStart_Sub = "btnMainTSStart_Sub", btnMainTSStart_Add = "btnMainTSStart_Add";
string btnMainTSDist_Sub = "btnMainTSDist_Sub", btnMainTSDist_Add = "btnMainTSDist_Add";
string btnMainDCACount_Sub = "btnMainDCACount_Sub", btnMainDCACount_Add = "btnMainDCACount_Add";
string btnMainDCAMult_Sub = "btnMainDCAMult_Sub", btnMainDCAMult_Add = "btnMainDCAMult_Add";

bool   popupActive = false;
ulong  editTicket  = 0;
double popupCurrentSL = 0;
double popupCurrentTP = 0;
int    popupCurrentTS_Start = 0;
int    popupCurrentTS_Dist = 0;

string lblPopup      = "lblPopupTitle";
string bgPopup       = "popupBG";
string txtSLVal      = "txtPopupSLVal", txtTPVal = "txtPopupTPVal";
string txtTSStartVal = "txtPopupTSStartVal", txtTSDistVal = "txtPopupTSDistVal";
string btnConfirm    = "btnPopupConfirm", btnCancel = "btnPopupCancel";
string btnSL_Sub     = "btnPopupSL_Sub", btnSL_Add = "btnPopupSL_Add";
string btnTP_Sub     = "btnPopupTP_Sub", btnTP_Add = "btnPopupTP_Add";
string btnTSStart_Sub = "btnPopupTSStart_Sub", btnTSStart_Add = "btnPopupTSStart_Add";
string btnTSDist_Sub = "btnPopupTSDist_Sub", btnTSDist_Add = "btnPopupTSDist_Add";

string UI[] = {"panelBG","panelHeader","lblTitle","lblMode","lblInfo","lblProfit","lblEstLoss",
               "edtSL","edtTP","edtLot","edtRisk","edtTSStart","edtTSDist","edtDCACount","edtDCAMult",
               "lblSL","lblTP","lblLot","lblRisk","lblTSStart","lblTSDist","lblDCACount","lblDCAMult",
               "btnBuy","btnSell",
               "btnMainSL_Sub", "btnMainSL_Add", "btnMainTP_Sub", "btnMainTP_Add",
               "btnMainLot_Sub", "btnMainLot_Add", "btnMainRisk_Sub", "btnMainRisk_Add",
               "btnMainTSStart_Sub", "btnMainTSStart_Add", "btnMainTSDist_Sub", "btnMainTSDist_Add",
               "btnMainDCACount_Sub", "btnMainDCACount_Add", "btnMainDCAMult_Sub", "btnMainDCAMult_Add",
               "btnCloseAllDCA"
              };

// --- KHAI BÁO NGUYÊN MẪU HÀM ---
void CreatePanel();
void UpdateInfo(bool forceUpdate);
void ScanButtonsBacktest();
void OpenBuy();
void OpenSell();
void OpenBuyDCA();
void OpenSellDCA();
void ProcessPopupConfirm();
void CloseModifyPopup();
void ShowEditDialog(ulong ticket);
void CloseTicketPosition(ulong ticket);
void CloseAllDCAChain();
bool ModifySingleTicket(ulong ticket, double newSL, double newTP);
void UpdatePnLText();
void DeleteAllPositionObjects();
void AdjustPopupValue(string type, int direction);
void UpdatePopupDisplay();
void AdjustMainPanelValue(string type, int direction);
void ProcessTrailingStop();
void DrawTrailingStopLine(ulong ticket, double price);
void CleanUpMemoryAndLines();
void RegisterNewTrades();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AutoCalcLotByRisk();
void UpdateEstLossDisplay();
double GetPointValue();
double GetSafeMaxLot();

// --- DCA FUNCTIONS ---
void CalculateDCAPrices(double currentPrice, double slPrice, int orderCount, double &prices[]);
void PlaceDCAOrders(bool isBuy, double &prices[], double baseLot, double sl, double tp, int chainId);
void ManageDCAPendingOrders();
void CancelAllDCAPendingOrders();
void CancelChainPendingOrders(int chainId);
int ExtractChainId(string comment);
void GetActiveChainIds(int &ids[], int &count);
void GetChainStats(int chainId, bool &isBuy, double &avgPrice, double &totalLots, double &totalProfit, int &posCount, int &pendingCount);
void DrawDCAAvgPriceLine(int chainId, double avgPrice, bool isBuy);
void CleanUpDCAAvgLines();
void SaveDCAMemory();
void LoadDCAMemory();

// --- CÁC HÀM TIỆN ÍCH UI ---
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

// --- LOGIC SỐ HỌC & KHIÊN BẢO VỆ MARGIN ---
double NormalizePrice(double price) { return NormalizeDouble(price, _Digits); }

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
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
// === CÔNG NGHỆ BỘ NHỚ LÕI (RAM) + LƯU DỰ PHÒNG RA FILE (.BIN) ===
// =================================================================================
struct TradeMemory { ulong ticket; int ts_start; int ts_dist; bool is_active; };
TradeMemory tsMem[];
string backupFileName = "TradeDashboard_Mem_" + IntegerToString(MagicNumber) + ".bin";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SaveMemoryToFile()
  {
   int handle = FileOpen(backupFileName, FILE_WRITE|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      FileWriteInteger(handle, ArraySize(tsMem));
      for(int i=0; i<ArraySize(tsMem); i++)
         FileWriteStruct(handle, tsMem[i]);
      FileClose(handle);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LoadMemoryFromFile()
  {
   int handle = FileOpen(backupFileName, FILE_READ|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      int size = FileReadInteger(handle);
      if(size > 0 && size <= 10000)
        {
         ArrayResize(tsMem, size);
         for(int i=0; i<size; i++)
            FileReadStruct(handle, tsMem[i]);
        }
      FileClose(handle);
     }
   LoadDCAMemory();
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Calculate DCA price levels                    |
//+------------------------------------------------------------------+
void CalculateDCAPrices(double currentPrice, double slPrice, int orderCount, double &prices[])
  {
// FIX LỖI 1: Guard zero divide - kiểm tra TRƯỚC khi ArrayResize
   if(orderCount <= 1)
     {
      ArrayResize(prices, 0);
      return;
     }

   double distance = MathAbs(currentPrice - slPrice);
   if(distance <= 0)
     {
      ArrayResize(prices, 0);
      Print("⚠️ DCA: Khoảng cách giá = 0! Cần SL > 0 để tính mốc DCA.");
      return;
     }

   ArrayResize(prices, orderCount - 1);
   double step = distance / orderCount;

   for(int i = 0; i < orderCount - 1; i++)
     {
      if(slPrice < currentPrice) // BUY: SL below current price
         prices[i] = NormalizePrice(currentPrice - (step * (i + 1)));
      else // SELL: SL above current price
         prices[i] = NormalizePrice(currentPrice + (step * (i + 1)));
     }
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Calculate lot with multiplier                 |
//+------------------------------------------------------------------+
double CalculateDCALot(double baseLot, int level)
  {
   double lot = baseLot;
   for(int i = 0; i < level; i++)
      lot *= currentMainDCA_Mult;
   return NormalizeLot(lot);
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Place pending DCA orders                      |
//+------------------------------------------------------------------+
void PlaceDCAOrders(bool isBuy, double &prices[], double baseLot, double sl, double tp, int chainId)
  {
// Tất cả lệnh DCA dùng chung 1 mức TP (tính từ lệnh Market đầu tiên)
   for(int i = 0; i < ArraySize(prices); i++)
     {
      double lot = CalculateDCALot(baseLot, i + 1);
      double price = prices[i];

      string comment = "DCA#" + IntegerToString(chainId) + (isBuy ? " BUY" : " SELL") + " Level " + IntegerToString(i + 1);

      if(isBuy)
        {
         if(trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment))
            Print("✓ Đặt ", comment, " @ ", price, " Lot: ", lot, " TP: ", tp);
         else
            Print("❌ Lỗi đặt ", comment, " - Mã lỗi: ", trade.ResultRetcode());
        }
      else
        {
         if(trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment))
            Print("✓ Đặt ", comment, " @ ", price, " Lot: ", lot, " TP: ", tp);
         else
            Print("❌ Lỗi đặt ", comment, " - Mã lỗi: ", trade.ResultRetcode());
        }
     }
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Đếm pending DCA orders trên Symbol hiện tại   |
//+------------------------------------------------------------------+
int CountDCAPendingOrders()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      // Chỉ đếm lệnh LIMIT (không đếm Stop hay Stop Limit)
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT)
         continue;
      count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Cancel all DCA pending orders                 |
//| FIX LỖI 3: Xác định bằng Symbol + Magic (không phụ thuộc comment)
//+------------------------------------------------------------------+
void CancelAllDCAPendingOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      // Chỉ xóa lệnh LIMIT (không xóa Stop hay Stop Limit)
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT)
         continue;

      if(trade.OrderDelete(ticket))
         Print("✓ Hủy lệnh DCA pending #", ticket);
      else
         Print("❌ Lỗi hủy lệnh DCA #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Save DCA memory to file                       |
//+------------------------------------------------------------------+
void SaveDCAMemory()
  {
   string fname = "DCA_ChainId_" + IntegerToString(MagicNumber) + ".bin";
   int handle = FileOpen(fname, FILE_WRITE|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      FileWriteInteger(handle, nextDCAChainId);
      FileClose(handle);
     }
  }

//+------------------------------------------------------------------+
//| === DCA FUNCTION: Load DCA memory from file                     |
//+------------------------------------------------------------------+
void LoadDCAMemory()
  {
   string fname = "DCA_ChainId_" + IntegerToString(MagicNumber) + ".bin";
   int handle = FileOpen(fname, FILE_READ|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      nextDCAChainId = FileReadInteger(handle);
      if(nextDCAChainId < 1)
         nextDCAChainId = 1;
      FileClose(handle);
     }
  }

// =================================================================================
// === DCA MULTI-CHAIN: QUẢN LÝ NHIỀU CHUỖI DCA ĐỒNG THỜI ===
// =================================================================================
int ExtractChainId(string comment)
  {
   int pos = StringFind(comment, "DCA#");
   if(pos < 0)
      return 0;
   string sub = StringSubstr(comment, pos + 4);
   int endPos = StringFind(sub, " ");
   if(endPos > 0)
      sub = StringSubstr(sub, 0, endPos);
   return (int)StringToInteger(sub);
  }

//+------------------------------------------------------------------+
//| === Lấy danh sách tất cả Chain ID đang hoạt động                |
//+------------------------------------------------------------------+
void GetActiveChainIds(int &ids[], int &count)
  {
   count = 0;
   ArrayResize(ids, 0);
   // Quét positions
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      int cid = ExtractChainId(PositionGetString(POSITION_COMMENT));
      if(cid <= 0)
         continue;
      bool found = false;
      for(int j = 0; j < count; j++)
         if(ids[j] == cid)
           { found = true; break; }
      if(!found)
        {
         ArrayResize(ids, count + 1);
         ids[count] = cid;
         count++;
        }
     }
   // Quét pending orders
   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;
      int cid = ExtractChainId(OrderGetString(ORDER_COMMENT));
      if(cid <= 0)
         continue;
      bool found = false;
      for(int j = 0; j < count; j++)
         if(ids[j] == cid)
           { found = true; break; }
      if(!found)
        {
         ArrayResize(ids, count + 1);
         ids[count] = cid;
         count++;
        }
     }
  }

//+------------------------------------------------------------------+
//| === Thống kê một chuỗi DCA: giá TB, lot, P&L, số lệnh          |
//+------------------------------------------------------------------+
void GetChainStats(int chainId, bool &isBuy, double &avgPrice, double &totalLots,
                   double &totalProfit, int &posCount, int &pendingCount)
  {
   avgPrice = 0; totalLots = 0; totalProfit = 0;
   posCount = 0; pendingCount = 0; isBuy = true;
   double sumPriceLot = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(ExtractChainId(PositionGetString(POSITION_COMMENT)) != chainId) continue;

      double lot = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      sumPriceLot += price * lot;
      totalLots += lot;
      totalProfit += PositionGetDouble(POSITION_PROFIT);
      posCount++;
     }
   if(totalLots > 0)
      avgPrice = sumPriceLot / totalLots;

   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      if(ExtractChainId(OrderGetString(ORDER_COMMENT)) != chainId) continue;
      pendingCount++;
     }
  }

//+------------------------------------------------------------------+
//| === Hủy pending orders của MỘT chuỗi DCA cụ thể                |
//+------------------------------------------------------------------+
void CancelChainPendingOrders(int chainId)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      long orderType = OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT && orderType != ORDER_TYPE_SELL_LIMIT) continue;
      if(ExtractChainId(OrderGetString(ORDER_COMMENT)) != chainId) continue;

      if(trade.OrderDelete(ticket))
         Print("✓ Hủy DCA Chain#", chainId, " pending #", ticket);
      else
         Print("❌ Lỗi hủy DCA Chain#", chainId, " #", ticket, " - Mã: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| === Vẽ đường giá trung bình của chuỗi DCA trên chart            |
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
//| === Xóa đường giá TB của các chuỗi DCA đã đóng hết              |
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
            if(ticket == 0) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
            if(ExtractChainId(PositionGetString(POSITION_COMMENT)) == cid)
              { hasPositions = true; break; }
           }
         if(!hasPositions)
            ObjectDelete(0, name);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SaveTradeMemory(ulong t, int start, int dist)
  {
   bool found = false;
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         tsMem[i].ts_start = start;
         tsMem[i].ts_dist = dist;
         found = true;
         break;
        }
     }
   if(!found)
     {
      int size = ArraySize(tsMem);
      ArrayResize(tsMem, size + 1);
      tsMem[size].ticket = t;
      tsMem[size].ts_start = start;
      tsMem[size].ts_dist = dist;
      tsMem[size].is_active = false;
     }
   SaveMemoryToFile();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetTradeMemory(ulong t, int &start, int &dist, bool &active)
  {
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         start = tsMem[i].ts_start;
         dist = tsMem[i].ts_dist;
         active = tsMem[i].is_active;
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MarkTSActive(ulong t)
  {
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         tsMem[i].is_active = true;
         SaveMemoryToFile();
         return;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RegisterNewTrades()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
         long posMagic = PositionGetInteger(POSITION_MAGIC);
         if(posMagic == MagicNumber || (posMagic == 0 && ManageManualTrades))
           {
            int s, d;
            bool a;
            if(!GetTradeMemory(ticket, s, d, a))
               SaveTradeMemory(ticket, currentMainTS_Start, currentMainTS_Dist);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanUpMemoryAndLines()
  {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "TS_Line_") == 0)
        {
         ulong t = (ulong)StringToInteger(StringSubstr(name, 8));
         if(!PositionSelectByTicket(t))
            ObjectDelete(0, name);
        }
     }
   bool memoryChanged = false;
   for(int i = ArraySize(tsMem) - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(tsMem[i].ticket))
        {
         ArrayRemove(tsMem, i, 1);
         memoryChanged = true;
        }
     }
   if(memoryChanged)
      SaveMemoryToFile();
  }

// =================================================================================
// --- LOGIC CHÍNH ---
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

   if(!MQLInfoInteger(MQL_OPTIMIZATION))
     {
      CreatePanel();
      if(RiskCalcMode != RISK_FIXED_LOT)
         AutoCalcLotByRisk(); // Tính xuôi ngay từ đầu
      else
         UpdateEstLossDisplay(); // Nếu đánh Fixed Lot thì chỉ cập nhật tiền Lỗ màu đỏ
      UpdateInfo(true);
     }
   if(UIUpdateSeconds > 0)
      EventSetTimer(UIUpdateSeconds);
   lastUIUpdate = TimeCurrent();

   Print("✓ Dashboard v7.0 DCA - Khởi động thành công!");
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
      UpdateEstLossDisplay(); // Cập nhật liên tục khi test
     }
   ProcessTrailingStop();

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

         // Chuỗi không còn position nào nhưng còn pending → hủy pending của chuỗi đó
         if(cposCount == 0 && cpendingCount > 0)
           {
            Print("⚠️ Chain#", chainIds[c], " hết position - Hủy ", cpendingCount, " lệnh chờ!");
            CancelChainPendingOrders(chainIds[c]);
           }
        }
     }
  }

// =================================================================================
// === THUẬT TOÁN TÍNH TOÁN RỦI RO & KHỐI LƯỢNG ===
// =================================================================================
double GetPointValue()
  {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0 || tickValue == 0)
      return 0;
   return tickValue * (_Point / tickSize);
  }

//+------------------------------------------------------------------+
//| TÍNH LOT XUÔI THEO RISK VÀ SL                                    |
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

   double riskMoney = 0;
   if(RiskCalcMode == RISK_PERCENT_BALANCE)
      riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * (currentRiskValue / 100.0);
   else
      if(RiskCalcMode == RISK_PERCENT_EQUITY)
         riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * (currentRiskValue / 100.0);
      else
         if(RiskCalcMode == RISK_FIXED_USD)
            riskMoney = currentRiskValue;

   double rawLot = riskMoney / (currentMainSL * pointValue);
   currentMainLot = NormalizeLot(rawLot);

   ObjectSetString(0, "edtLot", OBJPROP_TEXT, DoubleToString(currentMainLot, 2));
   UpdateEstLossDisplay();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateEstLossDisplay()
  {
   if(!panelCreated)
      return;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

// TÍNH CHUẨN 1% TRÊN BALANCE LẺ (KHÔNG PHỤ THUỘC LOT LÀM TRÒN)
   double targetLossMoney = balance * (currentRiskValue / 100.0);
   if(RiskCalcMode == RISK_FIXED_USD)
      targetLossMoney = currentRiskValue;

   double lossPct = (balance > 0) ? (targetLossMoney / balance) * 100.0 : 0;

// HIỂN THỊ SỐ LẺ 2 CHỮ SỐ (Ví dụ: -$950.21)
   string lossTxt = StringFormat("Est. Loss: -$%.2f (%.2f%%)", targetLossMoney, lossPct);
   ObjectSetString(0, "lblEstLoss", OBJPROP_TEXT, lossTxt);

   ChartRedraw(); // Ép màn hình vẽ lại ngay lập tức
  }

// =================================================================================
// === THUẬT TOÁN TRAILING STOP ===
// =================================================================================
void ProcessTrailingStop()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   double bid = tick.bid;
   double ask = tick.ask;
   long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDist = stopsLevel * _Point;
   double safeStepPoints = 20 * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      long posMagic = PositionGetInteger(POSITION_MAGIC);
      if(posMagic != MagicNumber)
        {
         if(posMagic == 0 && !ManageManualTrades)
            continue;
         if(posMagic != 0)
            continue;
        }

      int my_ts_start = 0, my_ts_dist = 0;
      bool is_active = false;
      if(!GetTradeMemory(ticket, my_ts_start, my_ts_dist, is_active))
        {
         if(posMagic == 0 && ManageManualTrades)
           {
            SaveTradeMemory(ticket, currentMainTS_Start, currentMainTS_Dist);
            my_ts_start = currentMainTS_Start;
            my_ts_dist = currentMainTS_Dist;
           }
         else
            continue;
        }

      if(my_ts_start <= 0 || my_ts_dist <= 0)
         continue;

      long posType = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);

      double startOffset = my_ts_start * _Point;
      double distOffset = my_ts_dist * _Point;

      if(distOffset < minStopDist)
         distOffset = minStopDist;

      if(posType == POSITION_TYPE_BUY)
        {
         if(bid - openPrice >= startOffset)
           {
            double newSL = NormalizePrice(bid - distOffset);
            if(currentSL == 0 || newSL > currentSL)
              {
               if(currentSL == 0 || (newSL - currentSL) >= safeStepPoints)
                 {
                  if(trade.PositionModify(ticket, newSL, currentTP))
                    {
                     DrawTrailingStopLine(ticket, newSL);
                     if(!is_active)
                       {
                        MarkTSActive(ticket);
                        UpdateInfo(true);
                       }
                    }
                  else
                     Print("❌ LỖI KÉO TS LỆNH BUY #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
                 }
              }
           }
        }
      else
         if(posType == POSITION_TYPE_SELL)
           {
            if(openPrice - ask >= startOffset)
              {
               double newSL = NormalizePrice(ask + distOffset);
               if(currentSL == 0 || newSL < currentSL)
                 {
                  if(currentSL == 0 || (currentSL - newSL) >= safeStepPoints)
                    {
                     if(trade.PositionModify(ticket, newSL, currentTP))
                       {
                        DrawTrailingStopLine(ticket, newSL);
                        if(!is_active)
                          {
                           MarkTSActive(ticket);
                           UpdateInfo(true);
                          }
                       }
                     else
                        Print("❌ LỖI KÉO TS LỆNH SELL #", ticket, " - Mã lỗi: ", trade.ResultRetcode());
                    }
                 }
              }
           }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
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

// === XỬ LÝ SỰ KIỆN CLICK CHUỘT LÚC BACKTEST ===
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() { if(!MQLInfoInteger(MQL_TESTER)) { if(UIUpdateSeconds > 0 && TimeCurrent() - lastUIUpdate >= UIUpdateSeconds) { UpdateInfo(true); lastUIUpdate = TimeCurrent(); } } }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,const MqlTradeRequest& req,const MqlTradeResult& res)
  {
// Trigger update when trade transaction occurs
   UpdateInfo(true);
  }

//+------------------------------------------------------------------+
//| XỬ LÝ SỰ KIỆN CLICK CHUỘT TRÊN CHART THỰC TẾ                     |
//+------------------------------------------------------------------+
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

// === LOGIC THỰC THI GIAO DỊCH ===
void OpenBuy()
  {
   if(EnableDCA)
     {
      OpenBuyDCA();
      return;
     }

   MqlTick tick;
   if(SymbolInfoTick(_Symbol, tick))
     {
      double safeLot = NormalizeLot(currentMainLot);
      double ask = NormalizePrice(tick.ask);
      double sl = (currentMainSL == 0) ? 0 : NormalizePrice(ask - currentMainSL * _Point);
      double tp = (currentMainTP == 0) ? 0 : NormalizePrice(ask + currentMainTP * _Point);
      if(trade.Buy(safeLot, _Symbol, ask, sl, tp, "Buy Dashboard"))
         UpdateInfo(true);
      else
         Print("❌ LỖI KHÔNG THỂ BUY! Mã lỗi Sàn: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenSell()
  {
   if(EnableDCA)
     {
      OpenSellDCA();
      return;
     }

   MqlTick tick;
   if(SymbolInfoTick(_Symbol, tick))
     {
      double safeLot = NormalizeLot(currentMainLot);
      double bid = NormalizePrice(tick.bid);
      double sl = (currentMainSL == 0) ? 0 : NormalizePrice(bid + currentMainSL * _Point);
      double tp = (currentMainTP == 0) ? 0 : NormalizePrice(bid - currentMainTP * _Point);
      if(trade.Sell(safeLot, _Symbol, bid, sl, tp, "Sell Dashboard"))
         UpdateInfo(true);
      else
         Print("❌ LỖI KHÔNG THỂ SELL! Mã lỗi Sàn: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| === OPEN BUY WITH DCA ===                                        |
//+------------------------------------------------------------------+
void OpenBuyDCA()
  {
   if(!EnableDCA || currentMainDCA_Count < 1)
     {
      OpenBuy();
      return;
     }

   if(currentMainSL <= 0)
     {
      Print("❌ DCA yêu cầu SL > 0 để tính mốc giá DCA!");
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   int chainId = nextDCAChainId++;
   SaveDCAMemory();

   double ask = NormalizePrice(tick.ask);
   double sl = NormalizePrice(ask - currentMainSL * _Point);
   double tp = (currentMainTP == 0) ? 0 : NormalizePrice(ask + currentMainTP * _Point);
   double safeLot = NormalizeLot(currentMainLot);

   string comment = "DCA#" + IntegerToString(chainId) + " BUY Market";
   if(!trade.Buy(safeLot, _Symbol, ask, sl, tp, comment))
     {
      Print("❌ LỖI MỞ DCA BUY MARKET! Mã lỗi: ", trade.ResultRetcode());
      return;
     }

   Print("✓ Mở ", comment, " @ ", ask, " Lot: ", safeLot);

   if(currentMainDCA_Count > 1)
     {
      double dcaPrices[];
      CalculateDCAPrices(ask, sl, currentMainDCA_Count, dcaPrices);
      PlaceDCAOrders(true, dcaPrices, safeLot, sl, tp, chainId);
     }

   UpdateInfo(true);
  }

//+------------------------------------------------------------------+
//| === OPEN SELL WITH DCA ===                                       |
//+------------------------------------------------------------------+
void OpenSellDCA()
  {
   if(!EnableDCA || currentMainDCA_Count < 1)
     {
      OpenSell();
      return;
     }

   if(currentMainSL <= 0)
     {
      Print("❌ DCA yêu cầu SL > 0 để tính mốc giá DCA!");
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   int chainId = nextDCAChainId++;
   SaveDCAMemory();

   double bid = NormalizePrice(tick.bid);
   double sl = NormalizePrice(bid + currentMainSL * _Point);
   double tp = (currentMainTP == 0) ? 0 : NormalizePrice(bid - currentMainTP * _Point);
   double safeLot = NormalizeLot(currentMainLot);

   string comment = "DCA#" + IntegerToString(chainId) + " SELL Market";
   if(!trade.Sell(safeLot, _Symbol, bid, sl, tp, comment))
     {
      Print("❌ LỖI MỞ DCA SELL MARKET! Mã lỗi: ", trade.ResultRetcode());
      return;
     }

   Print("✓ Mở ", comment, " @ ", bid, " Lot: ", safeLot);

   if(currentMainDCA_Count > 1)
     {
      double dcaPrices[];
      CalculateDCAPrices(bid, sl, currentMainDCA_Count, dcaPrices);
      PlaceDCAOrders(false, dcaPrices, safeLot, sl, tp, chainId);
     }

   UpdateInfo(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTicketPosition(ulong ticket) { if(trade.PositionClose(ticket)) { Print("✓ Đã đóng lệnh #", ticket); UpdateInfo(true); } }

//+------------------------------------------------------------------+
//| === ĐÓNG TOÀN BỘ CHUỖI DCA: positions + pending orders          |
//+------------------------------------------------------------------+
void CloseAllDCAChain()
  {
// 1. ĐÓNG TẤT CẢ POSITIONS trên Symbol này có Magic
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long posMagic = PositionGetInteger(POSITION_MAGIC);
      if(posMagic != MagicNumber && posMagic != 0)
         continue;
      if(trade.PositionClose(ticket))
         Print("✓ DCA Chain: Đóng position #", ticket);
      else
         Print("❌ DCA Chain: Lỗi đóng #", ticket, " - Mã: ", trade.ResultRetcode());
     }

// 2. HỦY TẤT CẢ PENDING ORDERS
   CancelAllDCAPendingOrders();

   Print("✓ Đã đóng toàn bộ chuỗi DCA!");
   UpdateInfo(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ModifySingleTicket(ulong ticket, double newSL, double newTP)
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(trade.PositionModify(ticket, newSL, newTP))
     {
      Print("✓ Đã sửa lệnh #", ticket);
      UpdateInfo(true);
      return true;
     }
   else
     {
      Print("❌ Lỗi sửa lệnh #", ticket, " - Mã: ", trade.ResultRetcode());
      return false;
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
      AutoCalcLotByRisk(); // Chỉ tính xuôi ra Lot
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

// === POPUP EDIT ===
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
//|                                                                  |
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
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessPopupConfirm() { ModifySingleTicket(editTicket, popupCurrentSL, popupCurrentTP); SaveTradeMemory(editTicket, popupCurrentTS_Start, popupCurrentTS_Dist); CloseModifyPopup(); }
//+------------------------------------------------------------------+
//|                                                                  |
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

// === TẠO VÀ CẬP NHẬT PANEL CHÍNH ===
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
   CreateLabel("lblDCACount", x+10, y, "DCA Cnt:", clrWhite, 8);
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

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
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
//|                                                                  |
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
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
