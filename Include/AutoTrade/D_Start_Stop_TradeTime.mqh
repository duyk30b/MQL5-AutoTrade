//+------------------------------------------------------------------+
bool CheckTradeTime_intraDay(int start_hour , int start_min , int stop_hour , int stop_min)
{
   // check true condition  
   if(start_hour > 24 || start_hour < 0 || stop_hour > 24 || stop_hour < 0 ||
      start_min > 60 || start_min < 0 || stop_min < 0 || stop_min > 60 )
     {  Alert("Wrong Input Trade Time");  return(false);   }
   
   MqlDateTime _TimeStruct;
   TimeToStruct(TimeCurrent(),_TimeStruct);
   int curHour = _TimeStruct.hour; int curMin = _TimeStruct.min;
   if(curHour < start_hour || curHour > stop_hour) return(false); 
   else
   {
      if       (curHour == start_hour && curMin < start_min) return(false);
      else if  (curHour == stop_hour && curMin >= stop_min)  return(false);
      else return ( true);
   }
}

bool CheckLastDayofMonth()
{
   MqlDateTime _TimeStruct;TimeToStruct(TimeCurrent(),_TimeStruct);
              // Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
   int dpm[] ={0,31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31  };
   if(_TimeStruct.year %4 == 0){dpm[2] = 29; }
   if(_TimeStruct.day == dpm[_TimeStruct.mon]) return true;
   
   return false;
}

bool CheckLastDayAllowTradeofMonth()
{
   MqlDateTime _TimeStruct;TimeToStruct(TimeCurrent(),_TimeStruct);
                 // Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
   int dpm[] ={0,31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31  };
   if(_TimeStruct.year %4 == 0){dpm[2] = 29; }
   if(_TimeStruct.day <= dpm[_TimeStruct.mon] -3)return false;
   
   // check if tomorow not allow trade => today is last of trade
   ENUM_DAY_OF_WEEK next_DAYOFWEEK = _TimeStruct.day_of_week < 6 ? _TimeStruct.day_of_week+1 : 0 ;
   datetime _start , _stop ;
   bool checkAllowTrade =SymbolInfoSessionTrade(_Symbol , next_DAYOFWEEK , 0 ,_start , _stop );
   if(checkAllowTrade) return false;
   
   return true;
}
 