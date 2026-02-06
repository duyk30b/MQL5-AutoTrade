// Higher High and Lower low Include to use in Any Ea or Indicator

class C_Point
  {
public:                    
                     double price;
                     double high;
                     double low;
                    datetime time;
                    enum E_Status{Down=-1,Sideway=0,Up=1,};
                    E_Status Status;
                    E_Status BeforeStatus;
                    int BeforeLayerPoint;
  };
  
class C_Layer : public C_Point
  {
public:
                    C_Point p[];
                    bool newpoint;
  };


class C_LayerTrend : public C_Layer
  {
public:
                    C_Layer Layer[];
                    int LayerNum;
                    
                    void CreatLayerTrend( MqlRates &rate[] ); // this for OnInit
                    void CacuFirstLayer(bool onInit ,C_Layer &Layer0, MqlRates &rate[]);
                    void CacuDeepLayer(bool onInit , C_Layer &InLay , C_Layer &OutLay);    
                    
                    void ModifiLayerTrend(MqlRates &rate[]) ; // this for On tick
                    void CacuFirstLayer(C_Layer &Layer0, MqlRates &rate[]);                     
                    void CacuDeepLayer(C_Layer &InLay , C_Layer &OutLay, double _high1 , double _low1);
                    void NewLayerOnTick();
                    
                    int ExtLayer(C_Layer &_Layer , int from , int to , bool isLow);
                    void DrawLayer(int LayNum ,C_Layer &iLayer , int from, int width) ;
                    void DeleteObj(int LayNum , C_Layer &_Layer[]); // this for On DeInit
  }; 
  
                
//
// this for OnInit
//  
  
void C_LayerTrend :: CreatLayerTrend( MqlRates &rate[] )  
{
   //uint starttime = GetTickCount();
   ArrayResize(Layer,1,10);
   CacuFirstLayer(true ,Layer[0], rate );
   
   LayerNum = 0;
   while( ArraySize(Layer[LayerNum].p)>=4)
     {
      LayerNum++;
      ArrayResize(Layer,LayerNum+1,10);
      CacuDeepLayer(true ,Layer[LayerNum-1] ,Layer[LayerNum]);
      //PrintFormat("time %d = %d",LayerNum,GetTickCount()-starttime);starttime = GetTickCount();
     }
   // delete last point foreach Array
   for(int i=1;i<=LayerNum;i++)
     {
      ArrayResize(Layer[i].p , ArraySize(Layer[i].p)-1,10000);
     }
}

// CacuFirstLayer On Init 
void C_LayerTrend :: CacuFirstLayer(bool onInit ,C_Layer &Layer0, MqlRates &rate[])
   {
     ArrayResize(Layer0.p,ArraySize(rate),100000);
     Layer0.p[0].Status = Sideway;
     Layer0.p[0].price = rate[0].high/2 + rate[0].low/2;
     Layer0.p[0].high = rate[0].high;
     Layer0.p[0].low = rate[0].low;
     Layer0.p[0].time = rate[0].time;
      
     for(int i=1;i< ArraySize(rate);i++)
       {
        Layer0.p[i].Status=Sideway;
        Layer0.p[i].price = rate[i].high/2 + rate[i].low/2;
        Layer0.p[i].high = rate[i].high;
        Layer0.p[i].low = rate[i].low;
        Layer0.p[i].time =rate[i].time;        
        
        if(rate[i].high > rate[i-1].high && rate[i].low > rate[i-1].low)
          {
           Layer0.p[i].Status=Up;
           Layer0.p[i].price = rate[i].high;
          }
        if(rate[i].high < rate[i-1].high && rate[i].low < rate[i-1].low)
          {
           Layer0.p[i].Status=Down;
           Layer0.p[i].price = rate[i].low;
          }
       }     
   }


// deep layer on init
void C_LayerTrend ::  CacuDeepLayer(bool onInit , C_Layer &InLay , C_Layer &OutLay)
     {
      int InSize = ArraySize(InLay.p);
      ArrayResize(OutLay.p,1,10000);
      OutLay.p[0] = InLay.p[0];
      
      int i1 = 0;
      while(InLay.p[i1].Status == Sideway ) i1++;
      int j1= i1;
      while(InLay.p[j1].Status == InLay.p[i1].Status ||  InLay.p[j1].Status == Sideway) j1++;
      while(InLay.p[j1-1].Status == Sideway) j1--;
      ArrayResize(OutLay.p,2,10000);
      OutLay.p[1]=InLay.p[j1-1];
      OutLay.p[1].BeforeLayerPoint = j1-1;
      OutLay.p[1].BeforeStatus =OutLay.p[1].price > OutLay.p[0].price ? Up:Down ;
      int OutSize = ArraySize(OutLay.p);

      int i2 =j1;
      while(i2 < InSize && InLay.p[i2].price != 0)
        {
         int j2 = i2;
         while(j2< InSize && InLay.p[j2].price != 0 && (InLay.p[j2].Status != OutLay.p[OutSize-1].Status || InLay.p[j2].Status == Sideway) ) j2++;

         ArrayResize(OutLay.p,OutSize+1,10);
                  int k = ExtLayer(InLay , i2 , j2-1 , OutLay.p[OutSize-1].Status == Down);
         OutLay.p[OutSize]=InLay.p[k];
         OutLay.p[OutSize].Status = OutLay.p[OutSize-1].Status==Up? Down:Up;
         OutLay.p[OutSize].price = OutLay.p[OutSize].Status==Up? OutLay.p[OutSize].high: OutLay.p[OutSize].low;
         OutLay.p[OutSize].BeforeLayerPoint = k;
         OutLay.p[OutSize].BeforeStatus = OutLay.p[OutSize].Status;
         OutSize++;
         
         i2 =j2;
        }
      
      // caculator Outlayer Status
      
      for(int i=3;i<OutSize;i++)
        {
         OutLay.p[i].Status = Sideway;
         if(   OutLay.p[i].price > OutLay.p[i-2].price && 
               OutLay.p[i-1].price > OutLay.p[i-3].price &&
               OutLay.p[i].price > OutLay.p[i-1].price )
           {
            OutLay.p[i].Status = Up; OutLay.p[i-1].Status = Up; OutLay.p[i-2].Status = Up;
           }
         if(   OutLay.p[i].price < OutLay.p[i-2].price && 
               OutLay.p[i-1].price < OutLay.p[i-3].price &&
               OutLay.p[i].price < OutLay.p[i-1].price)
           {
            OutLay.p[i].Status = Down; OutLay.p[i-1].Status = Down; OutLay.p[i-2].Status = Down;
           }
        }
     }


// modifi layer on tick
//
//
//


void C_LayerTrend :: ModifiLayerTrend(MqlRates &rate[])
{
   CacuFirstLayer(Layer[0],rate);
   //Print("============================================================================");
   for(int i=1;i< ArraySize(Layer);i++)
     {
      //PrintFormat("InLay = Layer_%d , OutLay = Layer_%d" , i-1 ,i);
      CacuDeepLayer(Layer[i-1],Layer[i],rate[0].high ,rate[0].low);
     }
   NewLayerOnTick();
}

// CacuFirstLayer On tick
void C_LayerTrend :: CacuFirstLayer(C_Layer &Layer0, MqlRates &rate[])
   {
      int n = ArraySize(Layer0.p);
      if(Layer0.p[n].time == rate[0].time) return;
      ArrayResize(Layer0.p,n +1,100000);
      Layer0.p[n].Status = Sideway;
      Layer0.p[n].price = rate[0].high/2 + rate[0].low/2;
      Layer0.p[n].high = rate[0].high;
      Layer0.p[n].low = rate[0].low;
      Layer0.p[n].time = rate[0].time;
      Layer0.newpoint = true;
      
      if(Layer0.p[n].high > Layer0.p[n-1].high && Layer0.p[n].low > Layer0.p[n-1].low)
        {
         Layer0.p[n].Status = Up;
         Layer0.p[n].price = rate[0].high;
        }
      if(Layer0.p[n].high < Layer0.p[n-1].high && Layer0.p[n].low < Layer0.p[n-1].low)
        {
         Layer0.p[n].Status = Down;
         Layer0.p[n].price = rate[0].low;
        }
   }

// deep layer on tick
void C_LayerTrend :: CacuDeepLayer( C_Layer &InLay , C_Layer &OutLay, double _high1 , double _low1)
{
   
   InLay.newpoint = false;
   int InNum = ArraySize(InLay.p)-1;
   int OutNum = ArraySize(OutLay.p)-1;

   //PrintFormat("InLay.p[%d] ,Status= %s, Time= %s ",InNum, EnumToString(InLay.p[InNum].Status),TimeToString(InLay.p[InNum].time,TIME_DATE|TIME_MINUTES ));
   //PrintFormat("OutLay.p[%d],BeforeStatus = %s,price=%f, high1 = %f , low1 = %f " , OutNum , EnumToString(OutLay.p[OutNum].BeforeStatus), OutLay.p[OutNum].price, _high1 , _low1 );
   //PrintFormat("OutLay.p[%d],BeforeStatus = %s,price=%f " , OutNum-1 , EnumToString(OutLay.p[OutNum-1].BeforeStatus), OutLay.p[OutNum-1].price );

   
   if((InLay.p[InNum].Status == OutLay.p[OutNum].BeforeStatus && InLay.p[InNum].Status != Sideway && OutLay.p[OutNum].BeforeLayerPoint != InNum)|| 
      (OutLay.p[OutNum].BeforeStatus == Up && _high1 > OutLay.p[OutNum].price )||
      (OutLay.p[OutNum].BeforeStatus == Down && _low1 < OutLay.p[OutNum].price ) )
     {
      int n = ExtLayer(InLay ,OutLay.p[OutNum-1].BeforeLayerPoint != OutLay.p[OutNum].BeforeLayerPoint? OutLay.p[OutNum].BeforeLayerPoint : OutLay.p[OutNum].BeforeLayerPoint+1 ,InNum, OutLay.p[OutNum].BeforeStatus == Down );
      //PrintFormat("N = %d , InLay.p[n].time = %s" , n , TimeToString(InLay.p[n].time,TIME_DATE|TIME_MINUTES ));
      OutNum++;
      ArrayResize(OutLay.p,OutNum+1,10000);
      OutLay.p[OutNum].high = InLay.p[n].high;
      OutLay.p[OutNum].low = InLay.p[n].low;
      OutLay.p[OutNum].time = InLay.p[n].time;
      OutLay.p[OutNum].BeforeLayerPoint = n;
      OutLay.p[OutNum].BeforeStatus = OutLay.p[OutNum-1].BeforeStatus == Up? Down : Up;
      OutLay.p[OutNum].price = OutLay.p[OutNum].BeforeStatus == Up? InLay.p[n].high : InLay.p[n].low;
      OutLay.newpoint = true;
     }
     
   if(OutNum<4)return;
   if(OutLay.p[OutNum].price > OutLay.p[OutNum-2].price && 
         OutLay.p[OutNum-1].price > OutLay.p[OutNum-3].price &&
         OutLay.p[OutNum].price > OutLay.p[OutNum-1].price )
     {
      OutLay.p[OutNum].Status = Up; OutLay.p[OutNum-1].Status = Up; OutLay.p[OutNum-2].Status = Up;
     }
   if(   OutLay.p[OutNum].price < OutLay.p[OutNum-2].price && 
         OutLay.p[OutNum-1].price < OutLay.p[OutNum-3].price &&
         OutLay.p[OutNum].price < OutLay.p[OutNum-1].price)
     {
      OutLay.p[OutNum].Status = Down; OutLay.p[OutNum-1].Status = Down; OutLay.p[OutNum-2].Status = Down;
     }
}


//Creat new Layer on tick if last Layer >4

void C_LayerTrend :: NewLayerOnTick()
{
   int LastL = ArraySize(Layer)-1;
   int LLNum = ArraySize(Layer[LastL].p)-1;
   if( LLNum > 4  && Layer[LastL].p[LLNum].Status != Sideway)
     {
      int NewLay = LastL+1;
      ArrayResize(Layer,NewLay+1,10);
      CacuDeepLayer(true,Layer[LastL],Layer[NewLay]);
     }
}


// find highest and lowest in layer high and layer low
int C_LayerTrend :: ExtLayer(C_Layer &_Layer , int from , int to , bool isLow)
{
   int pos = from;
   if(isLow) {for(int i=from+1;i<=to;i++){if (_Layer.p[i].high >=_Layer.p[pos].high) pos =i;}} // find Highest
   else      {for(int j=from+1;j<=to;j++){if (_Layer.p[j].low  <=_Layer.p[pos].low)  pos =j;}} // find Lowest
   return pos;
}

     
void C_LayerTrend :: DrawLayer(int LayNum ,C_Layer &iLayer , int from , int width ) 
   {
   for(int i=from;i<ArraySize(iLayer.p)-1;i++)
     {
      string objName = "LAYER_" + (string)LayNum + "_" + (string)i;
      bool check = ObjectCreate(NULL,objName,OBJ_TREND,0,iLayer.p[i].time,iLayer.p[i].price,iLayer.p[i+1].time,iLayer.p[i+1].price);
      switch(iLayer.p[i+1].Status)
        {
         case Up :
           ObjectSetInteger(NULL,objName,OBJPROP_COLOR,clrLime);
           break;
         case Sideway :
           ObjectSetInteger(NULL,objName,OBJPROP_COLOR,clrYellow);
           break;
        }
      ObjectSetInteger(NULL,objName,OBJPROP_WIDTH,width); 
     }
   }
 
// delele all obj and release Layer array
void C_LayerTrend :: DeleteObj(int LayNum , C_Layer &_Layer[])
   {
      int size = ArraySize(_Layer[LayNum].p);
      for(int i=0;i<size;i++)
        {
         string objName = "LAYER_" + (string)LayNum + "_" + (string)i;
         if(ObjectFind(0,objName) >= 0)ObjectDelete(0,objName);
        }
   }
 
 
#include <Trade\Trade.mqh>;
#include <Trade\SymbolInfo.mqh>;
#include <Trade\PositionInfo.mqh>;
// this section for trading : rule

class C_TradeWithLayerTrend :public C_Layer
{
public:     
   void Process(C_Layer &layer , int SlPoint , int TpPoint );
   
   CTrade            m_trade; 
   CSymbolInfo       m_symbol; 
   CPositionInfo     m_position;
   int oldlay;
} TradeWithLayerTrend;



void C_TradeWithLayerTrend::Process(C_Layer &layer , int SlPoint , int TpPoint )
{
   m_symbol.RefreshRates();
   int laynum= ArraySize(layer.p)-1;
   if(oldlay == laynum) return;
   string comment = "Trade by Trend Layer " + (string)laynum;
   if(layer.p[laynum].BeforeStatus == Down )
     {
      if(m_position.Select(Symbol()) && m_position.PositionType()==POSITION_TYPE_SELL) m_trade.PositionClose(Symbol()); // Close Sell
      if( !m_position.Select(Symbol())) m_trade.Buy(0.1, NULL, m_symbol.Ask(), m_symbol.Ask() - SlPoint*Point(), m_symbol.Ask() + TpPoint*Point(),comment); // Open Buy
     }
   else
     {
      if(m_position.Select(Symbol()) && m_position.PositionType()==POSITION_TYPE_BUY) m_trade.PositionClose(Symbol()); // Close Buy
      if( !m_position.Select(Symbol()))m_trade.Sell(0.1, NULL, m_symbol.Bid(), m_symbol.Bid() + SlPoint*Point(), m_symbol.Bid() - TpPoint*Point(),comment); // Open Sell
     }
   oldlay = laynum;
}