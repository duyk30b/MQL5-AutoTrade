//v1.0
//#include <DanyInclude\D_ProtectionTrade.mqh>;
//C_ProtectionTrade my_Protect;
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class C_ProtectionTrade
  {
public:
   void              Protect(CPositionInfo &m_position, int percent, int _sl, CTrade &m_trade);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  C_ProtectionTrade::Protect(CPositionInfo &m_position,int percent,int _sl,CTrade &m_trade)
  {
   if(m_position.PositionType() == POSITION_TYPE_BUY)
     {
      if(m_position.StopLoss() < m_position.PriceOpen())
        {
         if(SymbolInfoDouble(_Symbol,SYMBOL_BID) > m_position.PriceOpen() + MathAbs(m_position.TakeProfit() - m_position.PriceOpen())*percent/100)
           {
            m_trade.PositionModify(m_position.Ticket(), m_position.PriceOpen() + _sl*_Point, m_position.TakeProfit());
           }
        }
     }
   else
     {
      if(m_position.StopLoss() > m_position.PriceOpen())
        {
         if(SymbolInfoDouble(_Symbol,SYMBOL_ASK) < m_position.PriceOpen() - MathAbs(m_position.TakeProfit() - m_position.PriceOpen())*percent/100)
           {
            m_trade.PositionModify(m_position.Ticket(), m_position.PriceOpen()+ _sl*_Point, m_position.TakeProfit());
           }
        }
     }
  }
//+------------------------------------------------------------------+
