//+------------------------------------------------------------------+
//|                       ROBOT GIAO DỊCH TỰ ĐỘNG - t2.mq5           |
//|                                                                   |
//| CHỨC NĂNG CHỦ YẾU (THEO THỨ TỰ):                                  |
//| 1. ĐẶT SL, TP CHO LỆNH ĐANG MỞ: BUY LIMIT                       |
//| 2. ĐÓNG 1 LỆNH 10 TIẾNG SAU KHI MỞ LỆNH                          |
//| 3. MỞ 2 LỆNH BUY Ở CÁCH NHAU 1000 POINT                          |
//| 4. ĐÓNG LỆNH BUY ĐANG CÓ LỜI NHIỀU HƠN SAU 24H                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.00"

// NHẬP THƯ VIỆN GIAO DỊCH
// Đây là thư viện do MetaTrader cung cấp để giúp mở/đóng lệnh dễ dàng
#include <Trade/Trade.mqh>

//================= KHAI BÁO BIẾN TOÀN CỤC =================
// Những biến này sống suốt thời gian robot chạy

// CTrade: Công cụ để mở/đóng lệnh giao dịch
// Nó như một "nhân viên" giúp chúng ta thực hiện lệnh giao dịch
CTrade trade;

// SỬA: Lưu thời gian ĐẶT lệnh (không phải kích hoạt)
datetime order1SetupTime = 0;  // Thời gian đặt lệnh 1
datetime order2SetupTime = 0;  // Thời gian đặt lệnh 2

// XÓA các biến không dùng:
// datetime orderOpenTime[100];  // ❌ Xóa
// ulong orderTicket[100];       // ❌ Xóa
// int orderCount = 0;           // ❌ Xóa

double takeProfit = 100;         // LỢI NHUẬN MỤC TIÊU = 100 điểm
double stopLoss = 50;            // LỖ DỪNG TỐI ĐA = 50 điểm
double gapPoint = 1000;          // KHOẢNG CÁCH giữa 2 lệnh = 1000 điểm
double lotSize = 0.1;            // KÍCH THƯỚC MỗI LỆNH = 0.1 lot
//+------------------------------------------------------------------+
//| CHỨC NĂNG KHỞI TẠO: Chạy 1 lần duy nhất khi robot khởi động       |
//+------------------------------------------------------------------+
int OnInit()
  {
   // LẤY GIÁ HIỆN TẠI
   // SYMBOL_BID: giá mua (người bán)
   // Ví dụ: EURUSD = 1.1050
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   Print("===== KHỞI ĐỘNG ROBOT =====");
   Print("Giá hiện tại: ", bid);
   
   //================= TÍNH TOÁN GIÁ MỞ LỆNH =================
   // Lệnh LIMIT: Lệnh sẽ CHỈNH KHÔNG thực hiện ngay, mà chờ đến khi giá xuống đủ mức
   
   // LỆNH 1: Mua ở giá thấp hơn 100 điểm so với giá hiện tại
   // Nếu bid = 1.1050 → buyPrice1 = 1.0950
   double buyPrice1 = bid - 100*_Point;
   
   // LỆNH 2: Mua ở giá thấp hơn 1100 điểm so với giá hiện tại
   // (100 + 1000 = 1100)
   // Nếu bid = 1.1050 → buyPrice2 = 1.0950 (đã trừ thêm 1000)
   double buyPrice2 = bid - (100 + gapPoint)*_Point;
   
   //================= TÍNH TOÁN LỢI NHUẬN VÀ LỖ =================
   // Nếu lệnh được lập tức tại giá mua, thì TP và SL sẽ là:
   
   // LỆNH 1: Nếu mua ở 1.0950
   double tp1 = buyPrice1 + takeProfit*_Point;      // Đóng lời tại 1.1050 (+100 điểm)
   double sl1 = buyPrice1 - stopLoss*_Point;        // Đóng lỗ tại 1.0900 (-50 điểm)
   
   // LỆNH 2: Nếu mua ở 1.0850 (thấp hơn 100 điểm so với lệnh 1)
   double tp2 = buyPrice2 + takeProfit*_Point;      // Đóng lời tại 1.0950 (+100 điểm)
   double sl2 = buyPrice2 - stopLoss*_Point;        // Đóng lỗ tại 1.0800 (-50 điểm)
   
   //================= MỞ LỆNH 1 =================
   // trade.BuyLimit(kích thước, giá mua, cặp tiền, SL, TP, loại, ghi chú)
   // Lệnh này sẽ CHỜ cho đến khi giá xuống tới buyPrice1
   trade.BuyLimit(lotSize, buyPrice1, _Symbol, sl1, tp1, ORDER_TIME_GTC, 0, "Buy1");
   
   // Lưu thông tin lệnh 1
   order1SetupTime = TimeCurrent();   // Ghi lại thời gian đặt lệnh
   // orderOpenTime[orderCount] = TimeCurrent();   // Ghi lại thời gian mở
   // orderTicket[orderCount] = trade.ResultOrder();  // Lấy mã lệnh
   // orderCount++;  // Tăng bộ đếm
   
   Print("Lệnh 1 được tạo - Mua ở ", buyPrice1, " | TP: ", tp1, " | SL: ", sl1);
   
   //================= MỞ LỆNH 2 =================
   // Lệnh này sẽ CHỜ cho đến khi giá xuống tới buyPrice2 (1000 điểm thấp hơn lệnh 1)
   trade.BuyLimit(lotSize, buyPrice2, _Symbol, sl2, tp2, ORDER_TIME_GTC, 0, "Buy2");
   
   // Lưu thông tin lệnh 2
   order2SetupTime = TimeCurrent();   // Ghi lại thời gian đặt lệnh
   // orderOpenTime[orderCount] = TimeCurrent();   // Ghi lại thời gian mở
   // orderTicket[orderCount] = trade.ResultOrder();  // Lấy mã lệnh
   // orderCount++;  // Tăng bộ đếm
   
   Print("Lệnh 2 được tạo - Mua ở ", buyPrice2, " | TP: ", tp2, " | SL: ", sl2);
   Print("Khoảng cách giữa 2 lệnh: ", (buyPrice1 - buyPrice2)/_Point, " điểm");
   Print("===== ĐÃ KHỞI ĐỘNG XONG =====");
   
   return(INIT_SUCCEEDED);  // Khởi động thành công
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| CHỨC NĂNG TICK: Chạy liên tục, mỗi khi giá thay đổi               |
//| Tick = 1 lần cập nhật giá                                         |
//+------------------------------------------------------------------+
void OnTick()
  {
   // KIỂM TRA VÀ ĐÓNG 1 LỆNH SAU 10 TIẾNG
   // 10 tiếng = 10 * 3600 giây = 36000 giây
   // Hàm này sẽ chạy mỗi tick, kiểm tra xem có lệnh nào đã mở 10 tiếng chưa
   // Nếu có → đóng nó (chỉ đóng 1 lệnh duy nhất mỗi lần gọi)
   CloseOrderAfterTime(10*3600);
   
   // KIỂM TRA VÀ ĐÓNG LỆNH CÓ LỜI NHIỀU NHẤT SAU 24 TIẾNG
   // 24 tiếng = 24 * 3600 giây = 86400 giây
   // Hàm này sẽ:
   //   1. Kiểm tra tất cả lệnh BUY đang mở
   //   2. Nếu lệnh nào đã mở > 24h VÀ có lời
   //   3. Chọn lệnh có lời nhiều nhất
   //   4. Đóng lệnh đó
   CloseMostProfitableAfterTime(24*3600);
  }
//+------------------------------------------------------------------+
//| HÀM: XÓA 1 LỆNH CHỜ SAU X GIÂY                                    |
//| THAM SỐ: seconds = số giây cần chờ (ví dụ: 36000 = 10 tiếng)      |
//| CÁCH HOẠT ĐỘNG:                                                   |
//|   1. Lặp qua tất cả lệnh CHỜ (pending orders)                     |
//|   2. Tính xem lệnh đó đã đặt bao lâu rồi                          |
//|   3. Nếu >= X giây → xóa lệnh                                     |
//|   4. Chỉ xóa 1 lệnh rồi dừng (break)                              |
//+------------------------------------------------------------------+
void CloseOrderAfterTime(int seconds)
  {
   // Vòng lặp từ cuối về đầu (quan trọng: khi xóa lệnh, số lệnh giảm)
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      // OrdersTotal(): Tổng số lệnh CHỜ (pending orders)
      // OrderGetTicket(i): Lấy mã lệnh chờ thứ i
      ulong ticket = OrderGetTicket(i);
      
      // Chọn lệnh thứ i để làm việc với nó
      if(OrderSelect(ticket))
        {
         // Kiểm tra xem lệnh này có phải là cặp tiền HIỆN TẠI không
         // _Symbol: Cặp tiền robot đang chạy (ví dụ: EURUSD)
         if(OrderGetString(ORDER_SYMBOL) == _Symbol)
           {
            // LẤY THỜI GIAN ĐẶT LỆNH
            // ORDER_TIME_SETUP: Thời gian lệnh được đặt (định dạng datetime)
            datetime setupTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
            
            // LẤY GIÁ ĐẶT LỆNH
            // ORDER_PRICE_OPEN: Giá sẽ mở khi lệnh được kích hoạt
            double orderPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            
            // TÍNH THỜI GIAN ĐÃ TRÔI QUA (tính bằng giây)
            // TimeCurrent(): Thời gian hiện tại
            // Ví dụ: Nếu đặt lệnh 2 tiếng trước → elapsedTime = 7200 giây
            int elapsedTime = (int)(TimeCurrent() - setupTime);
            
            // KIỂM TRA ĐIỀU KIỆN: Nếu lệnh đã đặt >= X giây
            if(elapsedTime >= seconds)
              {
               // XÓA LỆNH CHỜ NÀY
               // trade.OrderDelete(): Lệnh xóa lệnh chờ
               trade.OrderDelete(ticket);
               
               // GHI LOG (để kiểm tra trong Journal/Experts)
               Print("✓ XÓA LỆNH CHỜ SAU THỜI GIAN");
               Print("  Ticket: ", ticket);
               Print("  Ngày giờ đặt lệnh: ", TimeToString(setupTime, TIME_DATE|TIME_MINUTES));
               Print("  Giá đặt: ", orderPrice);
               Print("  Thời gian chờ: ", elapsedTime/3600, " giờ ", (elapsedTime%3600)/60, " phút");
               
               // DỪNG VÒNG LẶP (break)
               // Để chỉ xóa 1 lệnh, không xóa thêm lệnh nào khác
               break;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| HÀM: ĐÓNG LỆNH CÓ LỜI NHIỀU NHẤT SAU X GIÂY                       |
//| THAM SỐ: seconds = số giây cần chờ (ví dụ: 86400 = 24 tiếng)      |
//| CÁCH HOẠT ĐỘNG:                                                   |
//|   1. Duyệt tất cả lệnh BUY đang mở                                |
//|   2. Nếu lệnh mở > 24h VÀ có lời → ghi nhớ lệnh có lời nhiều nhất|
//|   3. Sau cùng, đóng lệnh có lời nhiều nhất                        |
//+------------------------------------------------------------------+
void CloseMostProfitableAfterTime(int seconds)
  {
   // Khởi tạo biến để lưu lệnh có lời nhiều nhất
   double maxProfit = -999999;          // Giá trị lợi nhuận cực tiểu
   ulong maxProfitTicket = 0;           // Ticket của lệnh có lời nhất
   datetime maxProfitOpenTime = 0;      // Thời gian mở lệnh có lời nhất
    double maxProfitOpenPrice = 0;       // Giá mở của lệnh có lời nhất
   
   //================= BƯỚC 1: TÌM LỆNH CÓ LỜI NHIỀU NHẤT =================
   // Lặp qua tất cả lệnh đang mở
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      // Chọn lệnh thứ i
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         // Kiểm tra: Lệnh này có phải BUY của cặp tiền hiện tại không?
         // POSITION_TYPE_BUY: Lệnh mua (không phải bán)
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            // LẤY THÔNG TIN LỆNH
            // POSITION_PROFIT: Lợi nhuận/lỗ hiện tại (tính bằng tiền, ví dụ USD)
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            // Thời gian lệnh được mở
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
           
          // LẤY GIÁ MỞ LỆNH
          double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            
            // Tính thời gian đã trôi qua (tính bằng giây)
            int elapsedTime = (int)(TimeCurrent() - openTime);
            
            // KIỂM TRA ĐIỀU KIỆN:
            // - Lệnh đã mở >= 24 tiếng?  (elapsedTime >= seconds)
            // - Lệnh có lời?              (profit > 0)
            // - Lợi nhuận cao hơn lệnh trước? (profit > maxProfit)
            if(elapsedTime >= seconds && profit > maxProfit && profit > 0)
              {
               // CẬP NHẬT giá trị cao nhất
               maxProfit = profit;
               maxProfitTicket = PositionGetTicket(i);
               maxProfitOpenTime = openTime;
            maxProfitOpenPrice = openPrice;
              }
           }
        }
     }
   
   //================= BƯỚC 2: ĐÓNG LỆNH CÓ LỜI NHIỀU NHẤT =================
   // Nếu tìm thấy lệnh (maxProfitTicket > 0)
   if(maxProfitTicket > 0)
     {
      // Tính lại thời gian (để ghi log chính xác)
      int elapsedTime = (int)(TimeCurrent() - maxProfitOpenTime);
      
      // ĐÓNG LỆNH
      trade.PositionClose(maxProfitTicket);
      
      // GHI LOG
      Print("✓ ĐÓNG LỆNH CÓ LỜI NHIỀU NHẤT");
      Print("  Ticket: ", maxProfitTicket);
      Print("  Ngày giờ mở lệnh: ", TimeToString(maxProfitOpenTime, TIME_DATE|TIME_MINUTES));
      Print("  Vị trí giá mở: ", maxProfitOpenPrice);
      Print("  Lợi nhuận: $", maxProfit);
      Print("  Thời gian mở: ", elapsedTime/3600, " giờ ", (elapsedTime%3600)/60, " phút");
     }
  }

//+------------------------------------------------------------------+
void CloseOrder()
  {
   // Vòng lặp qua tất cả lệnh đang mở
   // Lý do lặp từ cuối về đầu: khi đóng lệnh, số lượng lệnh giảm
   // Nếu lặp từ đầu, sẽ bỏ sót một số lệnh
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      // Chọn lệnh thứ i bằng ticket của nó
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         // Kiểm tra xem lệnh này có phải của cặp tiền hiện tại không
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            // Lệnh này thuộc cặp tiền hiện tại
            // Bây giờ đóng lệnh này
            trade.PositionClose(PositionGetTicket(i));
            
            // In log ra ticket của lệnh vừa đóng
            Print("Lệnh ticket: ", PositionGetTicket(i), " đã được đóng");
            
            // Thoát khỏi vòng lặp (chỉ đóng 1 lệnh)
            break;
           }
        }
     }
  }