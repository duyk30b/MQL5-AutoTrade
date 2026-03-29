//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input string   inp_symbol_array = "EURUSD,GBPUSD,USDJPY,AUDCAD"; // Danh sách symbol, phân cách bằng dấu ","
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
   MqlTick refTick;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   SymbolInfoTick("GBPUSD", refTick);
   SymbolInfoTick("USDJPY", refTick);
   SymbolInfoTick("AUDCAD", refTick);
  }
//+------------------------------------------------------------------+
 