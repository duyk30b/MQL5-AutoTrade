#ifndef UI_DEFINES_MQH
#define UI_DEFINES_MQH

enum UI_EVENT_TYPE {
   UI_EVENT_CHANGE_VALUE, // Change value của input
   UI_EVENT_CHANGE_PAGE   // Change page của table
};

typedef void (*FOnChange)(void *context, UI_EVENT_TYPE type, double value);

class UIInputListener {
 public:
   virtual void onChangeValue(double newValue) = 0;
};

#endif // UI_DEFINES_MQH