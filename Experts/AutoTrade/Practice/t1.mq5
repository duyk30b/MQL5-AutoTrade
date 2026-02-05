//+------------------------------------------------------------------+
//|                                                           t1.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

// NHẬP THƯ VIỆN GIAO DỊCH
#include <Trade/Trade.mqh>

// KHAI BÁO BIẾN TOÀN CỤC
CTrade trade;                // Công cụ để mở/đóng lệnh giao dịch
static int tick_counter = 0; // Biến đếm số tick để tối ưu hóa tốc độ

//+------------------------------------------------------------------+
//| 1. LẤY GIÁ HIỆN TẠI (REAL TIME)
//| Hàm này lấy giá mua (ASK), giá bán (BID), giá giao dịch cuối (LAST)
//+------------------------------------------------------------------+
void GetCurrentPrice()
{
  // Lấy giá BID: giá bán hiện tại (người mua chờ ở giá này)
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  // Lấy giá ASK: giá mua hiện tại (người bán chờ ở giá này)
  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

  // Lấy giá LAST: giá giao dịch cuối cùng
  double last = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

  // In log ra cửa sổ Experts
  Print("BID: ", bid, " | ASK: ", ask, " | LAST: ", last);
}

//+------------------------------------------------------------------+
//| 2. LẤY GIÁ CỦA THỜI KỲ BẤT KỲ TRONG QUÁ KHỨ
//| Hàm này lấy giá OPEN, HIGH, LOW, CLOSE của nến trước hoặc khung khác
//+------------------------------------------------------------------+
void GetHistoricalPrice()
{
  // ========== LẤY GIÁ CỦA NẾN TRƯỚC TRONG KHUNG THỜI GIAN HIỆN TẠI ==========
  // Nếu EA chạy trên M5 thì lấy dữ liệu M5 trước
  // Nếu EA chạy trên H1 thì lấy dữ liệu H1 trước
  datetime targetTime = StringToTime("2023.01.22 18:00");
  int index = iBarShift(_Symbol, PERIOD_H1, targetTime, true);

  // Lấy Close của nến trước (PERIOD_CURRENT = khung thời gian hi6767ện tại, 1 = 1 nến trước)
  double close_prev = iClose(_Symbol, PERIOD_CURRENT, index);

  // Lấy Open của nến trước
  double open_prev = iOpen(_Symbol, PERIOD_CURRENT, iBarShift(_Symbol, PERIOD_H1, StringToTime("2023.01.22 18:00"), true));

  // Lấy High (giá cao nhất) của nến trước
  double high_prev = iHigh(_Symbol, PERIOD_CURRENT, 1);

  // Lấy Low (giá thấp nhất) của nến trước
  double low_prev = iLow(_Symbol, PERIOD_CURRENT, 1);

  // In log ra thông tin nến trước
  Print("Nến trước - OPEN: ", open_prev, " | HIGH: ", high_prev, " | LOW: ", low_prev, " | CLOSE: ", close_prev);

  // ========== LẤY GIÁ TỪ CÁC KHUNG THỜI GIAN KHÁC (H1, D1) ==========

  // Lấy Close của H1 trước (PERIOD_H1 = 1 giờ, 1 = 1 nến trước)
  double close_h1 = iClose(_Symbol, PERIOD_H1, 1);

  // Lấy Close của D1 hiện tại (PERIOD_D1 = 1 ngày, 0 = nến hiện tại)
  double close_d1 = iClose(_Symbol, PERIOD_D1, 0);

  // In log ra thông tin khác
  Print("H1 Close: ", close_h1, " | D1 Close: ", close_d1);
}

//+------------------------------------------------------------------+
//| 3. MỞ LỆNH BUY/SELL LIMIT VÀ STOP
//| Hàm này mở lệnh chờ (không giao dịch ngay mà chờ giá tới)
//+------------------------------------------------------------------+
void OpenOrders()
{
  // Lấy giá mua (ASK) hiện tại
  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

  // Lấy giá bán (BID) hiện tại
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  // Lấy giá trị 1 PIP của cặp tiền (0.0001 với EURUSD)
  double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

  // ========== BUY LIMIT: MUA Ở GIÁ THẤP HƠN GIÁ HIỆN TẠI ==========
  // Ví dụ: Giá hiện tại 1.1000, đặt lệnh mua ở 1.0900 (thấp hơn 100 pip)
  // Khi giá rơi xuống 1.0900 thì lệnh tự động thực thi
  // trade.BuyLimit(0.1, bid - 100 * point, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "BUY LIMIT");
  // Tham số: volume (0.1 lot), giá, cặp tiền, SL, TP, loại thời gian, hạn, ghi chú

  // ========== SELL LIMIT: BÁN Ở GIÁ CAO HƠN GIÁ HIỆN TẠI ==========
  // Ví dụ: Giá hiện tại 1.1000, đặt lệnh bán ở 1.1100 (cao hơn 100 pip)
  // Khi giá lên tới 1.1100 thì lệnh tự động thực thi
  // trade.SellLimit(0.1, ask + 100 * point, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SELL LIMIT");

  // ========== BUY STOP: MUA Ở GIÁ CAO HƠN (ĐỢT PHÁ LÊN) ==========
  // Ví dụ: Giá hiện tại 1.1000, đặt lệnh mua ở 1.1100 (cao hơn 100 pip)
  // Khi giá lên vượt qua 1.1100 (đột phá) thì lệnh mua tự động thực thi
  // trade.BuyStop(0.1, ask + 100 * point, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "BUY STOP");

  // ========== SELL STOP: BÁN Ở GIÁ THẤP HƠN (ĐỘT PHÁ XUỐNG) ==========
  // Ví dụ: Giá hiện tại 1.1000, đặt lệnh bán ở 1.0900 (thấp hơn 100 pip)
  // Khi giá rơi xuống vượt qua 1.0900 (đột phá) thì lệnh bán tự động thực thi
  // trade.SellStop(0.1, bid - 100 * point, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SELL STOP");

  Print("Các lệnh mở chờ đã được viết - xóa // trước 'trade' để kích hoạt");
}

//+------------------------------------------------------------------+
//| 4. ĐẶT STOP LOSS (SL) VÀ TAKE PROFIT (TP) CHO LỆNH
//| Hàm này mở lệnh BUY/SELL với SL (cắt lỗ) và TP (lấy lãi)
//+------------------------------------------------------------------+
void SetSLTP()
{
  // Lấy giá trị 1 PIP
  double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

  // Lấy giá mua (ASK) hiện tại
  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

  // Lấy giá bán (BID) hiện tại
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  // ========== CÁCH 1: MỞ LỆNH BUY VỚI SL VÀ TP ==========
  // trade.Buy(0.1, _Symbol, 0, bid - 100 * point, ask + 200 * point);
  // Tham số:
  //   0.1 = Volume (0.1 lot)
  //   _Symbol = Cặp tiền (EURUSD, GBPUSD, v.v.)
  //   0 = Slippage (độ lệch giá, 0 = không giới hạn)
  //   bid - 100 * point = Stop Loss (cắt lỗ ở 100 pip thấp hơn)
  //   ask + 200 * point = Take Profit (lấy lãi ở 200 pip cao hơn)

  // ========== CÁCH 2: CẬP NHẬT SL VÀ TP CỦA LỆNH ĐANG MỞ ==========

  // Lấy số hiệu (ticket) của lệnh - VÍ DỤ (thay bằng ticket thực tế)
  ulong ticket = 1000000001;

  // Cập nhật Stop Loss mới = bid - 50 pips
  // Cập nhật Take Profit mới = ask + 150 pips
  // trade.PositionModify(ticket, bid - 50 * point, ask + 150 * point);

  Print("SL/TP đã được cấu hình");
}

//+------------------------------------------------------------------+
//| 5. ĐÓNG MỘT LỆNH ĐANG MỞ
//| Hàm này tìm kiếm lệnh đang mở và đóng lệnh đầu tiên
//+------------------------------------------------------------------+
void CloseOrder()
{
  // Vòng lặp qua tất cả lệnh đang mở
  // Lý do lặp từ cuối về đầu: khi đóng lệnh, số lượng lệnh giảm
  // Nếu lặp từ đầu, sẽ bỏ sót một số lệnh
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    // Chọn lệnh thứ i bằng ticket của nó
    if (PositionSelectByTicket(PositionGetTicket(i)))
    {
      // Kiểm tra xem lệnh này có phải của cặp tiền hiện tại không
      if (PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
        // Lệnh này thuộc cặp tiền hiện tại
        // Bây giờ đóng lệnh này
        // trade.PositionClose(PositionGetTicket(i));

        // In log ra ticket của lệnh vừa đóng
        Print("Lệnh ticket: ", PositionGetTicket(i), " đã được đóng");

        // Thoát khỏi vòng lặp (chỉ đóng 1 lệnh)
        break;
      }
    }
  }
}

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION FUNCTION (Hàm khởi tạo)
//| Chạy 1 lần duy nhất khi EA bắt đầu
//+------------------------------------------------------------------+
int OnInit()
{
  // In log ra màn hình
  Print("Expert khởi động thành công!");

  // Gọi hàm lấy giá hiện tại
  GetCurrentPrice();

  // Trả về tín hiệu thành công
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION FUNCTION (Hàm kết thúc)
//| Chạy 1 lần duy nhất khi EA dừng
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Có thể viết code để dọn dẹp khi EA dừng
  // Ví dụ: Đóng tất cả lệnh, lưu dữ liệu, v.v.
}

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION (Hàm chính - chạy liên tục)
//| Hàm này chạy mỗi khi có tick (giá thay đổi)
//+------------------------------------------------------------------+
void OnTick()
{
  // ========== TỐI ƯU HÓA: CHỈ XỬ LÝ MỖI 10 TICK ==========
  // Tăng bộ đếm lên 1
  tick_counter++;

  // Nếu chưa tới 10 tick, thoát hàm (không xử lý)
  if (tick_counter < 10)
    return;

  // Đã tới 10 tick, reset bộ đếm về 0
  tick_counter = 0;

  // ========== GỌI CÁC HÀM XỬ LÝ LOGIC ==========

  // Lấy giá hiện tại (mỗi 10 tick)
  GetCurrentPrice();

  // Lấy giá quá khứ (mỗi 10 tick)
  GetHistoricalPrice();

  // Mở lệnh (xóa // ở đầu để kích hoạt)
  // OpenOrders();

  // Đặt SL/TP (xóa // ở đầu để kích hoạt)
  // SetSLTP();

  // Đóng lệnh (xóa // ở đầu để kích hoạt)
  // CloseOrder();
}
//+------------------------------------------------------------------+