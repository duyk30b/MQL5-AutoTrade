//#include <DanyInclude\DTrailingStop.mqh>;
// C_TrailingStop my_Trailing;
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>;

// position must be select before
class C_TrailingStop
{
   public:
   void TrailingStop(CPositionInfo &m_position, int _sl, int _tp, CTrade &m_trade);
};

void C_TrailingStop ::TrailingStop(CPositionInfo &m_position, int _sl, int _tp, CTrade &m_trade)
{
   double res_sl,base,delta,NowPrice ;
   if(_tp ==0 || _sl ==0) return;
   int tp = _tp ; int sl = _sl;
   double pos_sl= m_position.StopLoss();
   double pos_tp= m_position.TakeProfit();
   double pos_op= m_position.PriceOpen();
   
   if(pos_tp != 0 ) m_trade.PositionModify(m_position.Ticket(),pos_sl,0);
   
   if(m_position.PositionType()==POSITION_TYPE_BUY)
     {
      NowPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      if(pos_sl < pos_op){ base = pos_op; delta = tp*_Point; }
      else               { base = pos_sl; delta = sl*_Point; }
      
      if(NowPrice - base > delta )
      {
         res_sl = NowPrice - sl*_Point;
         if(res_sl > pos_sl + _Point) m_trade.PositionModify(m_position.Ticket(),res_sl,0);
      }
     }
   else
     {
      NowPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(pos_sl==0.0 || pos_sl > pos_op ) {base = pos_op; delta = tp*_Point; }
      else                                {base = pos_sl; delta = sl*_Point; }

      if(base - NowPrice > delta)
      {
         res_sl = NormalizeDouble( NowPrice + sl*_Point ,_Digits );
         if(pos_sl==0.0 || res_sl < pos_sl) 
         {
            m_trade.PositionModify(m_position.Ticket(),res_sl,0);
         }
      }
     }
}
/*
   for(int i=0;i<PositionsTotal();i++)
     {
      myposition.SelectByIndex(i);
      mytrailing.TrailingStop(myposition, Trailing_FixedPips_StopLevel, Trailing_FixedPips_ProfitLevel, myposition.PositionType() == POSITION_TYPE_BUY ? Tick.bid : Tick.ask, mytrade);
     }*/