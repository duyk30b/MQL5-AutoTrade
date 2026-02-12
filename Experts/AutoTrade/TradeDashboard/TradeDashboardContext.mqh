#ifndef TRADE_DASHBOARD_CONTEXT_MQH
#define TRADE_DASHBOARD_CONTEXT_MQH

#include <AutoTrade/UI/UICommon.mqh>
#include <Trade/Trade.mqh>

extern CTrade   cTrade;
extern UICommon uiCommon;

void            openPopupModifyPosition(ulong ticketId);

#endif // TRADE_DASHBOARD_CONTEXT_MQH