//+------------------------------------------------------------------+
//|                         TDM_Memory.mqh                           |
//| Persistence: Save/Load TradeMemory & DCA ChainId to .BIN files   |
//+------------------------------------------------------------------+
#ifndef TDM_MEMORY_MQH
#define TDM_MEMORY_MQH

#include "TDM_Constants.mqh"

// =================================================================================
// === CÔNG NGHỆ BỘ NHỚ LÕI (RAM) + LƯU DỰ PHÒNG RA FILE (.BIN) ===
// =================================================================================

//+------------------------------------------------------------------+
//| Lưu bộ nhớ Trailing Stop ra file                                 |
//+------------------------------------------------------------------+
void SaveMemoryToFile()
  {
   int handle = FileOpen(backupFileName, FILE_WRITE|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      FileWriteInteger(handle, ArraySize(tsMem));
      for(int i=0; i<ArraySize(tsMem); i++)
         FileWriteStruct(handle, tsMem[i]);
      FileClose(handle);
     }
  }

//+------------------------------------------------------------------+
//| Load bộ nhớ Trailing Stop từ file                                |
//+------------------------------------------------------------------+
void LoadMemoryFromFile()
  {
   int handle = FileOpen(backupFileName, FILE_READ|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      int size = FileReadInteger(handle);
      if(size > 0 && size <= 10000)
        {
         ArrayResize(tsMem, size);
         for(int i=0; i<size; i++)
            FileReadStruct(handle, tsMem[i]);
        }
      FileClose(handle);
     }
   LoadDCAMemory();
  }

//+------------------------------------------------------------------+
//| Lưu DCA ChainId ra file                                          |
//+------------------------------------------------------------------+
void SaveDCAMemory()
  {
   string fname = "DCA_ChainId_" + IntegerToString(MagicNumber) + ".bin";
   int handle = FileOpen(fname, FILE_WRITE|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      FileWriteInteger(handle, nextDCAChainId);
      FileClose(handle);
     }
  }

//+------------------------------------------------------------------+
//| Load DCA ChainId từ file                                          |
//+------------------------------------------------------------------+
void LoadDCAMemory()
  {
   string fname = "DCA_ChainId_" + IntegerToString(MagicNumber) + ".bin";
   int handle = FileOpen(fname, FILE_READ|FILE_BIN);
   if(handle != INVALID_HANDLE)
     {
      nextDCAChainId = FileReadInteger(handle);
      if(nextDCAChainId < 1)
         nextDCAChainId = 1;
      FileClose(handle);
     }
  }

//+------------------------------------------------------------------+
//| Lưu thông tin TS của 1 lệnh vào RAM + File                      |
//+------------------------------------------------------------------+
void SaveTradeMemory(ulong t, int start, int dist)
  {
   bool found = false;
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         tsMem[i].ts_start = start;
         tsMem[i].ts_dist = dist;
         found = true;
         break;
        }
     }
   if(!found)
     {
      int size = ArraySize(tsMem);
      ArrayResize(tsMem, size + 1);
      tsMem[size].ticket = t;
      tsMem[size].ts_start = start;
      tsMem[size].ts_dist = dist;
      tsMem[size].is_active = false;
     }
   SaveMemoryToFile();
  }

//+------------------------------------------------------------------+
//| Đọc thông tin TS của 1 lệnh từ RAM                              |
//+------------------------------------------------------------------+
bool GetTradeMemory(ulong t, int &start, int &dist, bool &active)
  {
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         start = tsMem[i].ts_start;
         dist = tsMem[i].ts_dist;
         active = tsMem[i].is_active;
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Đánh dấu Trailing Stop đã kích hoạt                             |
//+------------------------------------------------------------------+
void MarkTSActive(ulong t)
  {
   for(int i=0; i<ArraySize(tsMem); i++)
     {
      if(tsMem[i].ticket == t)
        {
         tsMem[i].is_active = true;
         SaveMemoryToFile();
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//| Đăng ký lệnh mới vào bộ nhớ TS                                  |
//+------------------------------------------------------------------+
void RegisterNewTrades()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
         long posMagic = PositionGetInteger(POSITION_MAGIC);
         if(posMagic == MagicNumber || (posMagic == 0 && ManageManualTrades))
           {
            int s, d;
            bool a;
            if(!GetTradeMemory(ticket, s, d, a))
               SaveTradeMemory(ticket, currentMainTS_Start, currentMainTS_Dist);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Dọn dẹp bộ nhớ & đường kẻ TS của lệnh đã đóng                  |
//+------------------------------------------------------------------+
void CleanUpMemoryAndLines()
  {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "TS_Line_") == 0)
        {
         ulong t = (ulong)StringToInteger(StringSubstr(name, 8));
         if(!PositionSelectByTicket(t))
            ObjectDelete(0, name);
        }
     }
   bool memoryChanged = false;
   for(int i = ArraySize(tsMem) - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(tsMem[i].ticket))
        {
         ArrayRemove(tsMem, i, 1);
         memoryChanged = true;
        }
     }
   if(memoryChanged)
      SaveMemoryToFile();
  }

#endif
//+------------------------------------------------------------------+
