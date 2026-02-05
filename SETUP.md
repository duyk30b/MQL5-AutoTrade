# Sử dụng GIT

## Đặt vấn đề: 
    + Bắt buộc phải sử dụng các file có sẵn của MT5
    + Cần sync file bằng Git, tuy nhiên các file đó lại nằm lẫn trong các thư mục của MT5 như Experts, Indicators, ....

## Clone
- Clone git vào 1 thư mục bất kỳ: `git@github.com:duyk30b/MQL5-AutoTrade.git`
- Copy folder .git và file .gitignore vào thư mục MQL5 được tạo sẵn từ MetaTrade
- Git sẽ hiểu là bị xoá hết các file đang có
- Restore lại tất cả các file đó
- Giờ sử dụng như bình thường

## Quy tắc branch
### Team thị trường
- Chỉ cần pull code từ nhánh master
### Team developer
- Mỗi người sẽ chỉ push code lên nhánh cá nhân
- Pull request và review tại nhánh developer
- Sau khi code tại nhánh developer ổn định => Merge từ developer vào master