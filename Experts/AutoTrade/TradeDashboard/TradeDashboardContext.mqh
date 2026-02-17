#ifndef TRADE_DASHBOARD_CONTEXT_MQH
#define TRADE_DASHBOARD_CONTEXT_MQH

#include <AutoTrade/UI/UICommon.mqh>
#include <Trade/Trade.mqh>

extern CTrade   cTrade;
extern UICommon uiCommon;

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

void                openPopupModifyPosition(ulong ticketId);

#endif // TRADE_DASHBOARD_CONTEXT_MQH