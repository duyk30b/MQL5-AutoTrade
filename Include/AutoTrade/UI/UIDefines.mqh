#ifndef UI_DEFINES_MQH
#define UI_DEFINES_MQH

enum UI_EVENT_TYPE {
   UI_EVENT_CHANGE_VALUE // Change value của input
};

typedef void (*FOnChange)(void *context, UI_EVENT_TYPE type, double value);

#endif // UI_DEFINES_MQH