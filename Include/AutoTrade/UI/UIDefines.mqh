#ifndef UI_DEFINES_MQH
#define UI_DEFINES_MQH

enum UI_EVENT_TYPE {
   UI_EVENT_NONE,         // Không có sự kiện nào
   UI_EVENT_CHANGE_VALUE, // Change value của input
   UI_EVENT_CHANGE_PAGE   // Change page của table
};

typedef void (*FOnChange)(void *parent, UI_EVENT_TYPE type, double value);

class UIListener {
 public:
   virtual void listen(void *child, UI_EVENT_TYPE type, double value) = 0;
};

double g_inputHeightRate = 2.2; // Hệ số để tính chiều cao input dựa trên font size
double g_labelHeightRate = 1.8; // Hệ số để tính khoảng cách label dựa trên font size

#endif                          // UI_DEFINES_MQH