//+------------------------------------------------------------------+
//|                                           PositionManager.mq5     |
//|                   Full Position Management with Edit Dialog       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "3.00"

#include <AutoTrade/UI/UITable.mqh>
#include <AutoTrade/UI/UICommon.mqh>
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input ENUM_TABLE_THEME InpTheme = THEME_DARK;  // Table Theme
input int InpUpdateInterval = 1;                // Update Interval (seconds)

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
UICommon uiCommon;
UITable* g_table = NULL;
datetime g_lastUpdate = 0;

// Custom objects for buttons
struct ButtonInfo {
   int row;
   int col;
   string objectName;
};
ButtonInfo g_buttons[];

// Edit dialog
bool g_editDialogActive = false;
int g_editingRow = -1;
ulong g_editingTicket = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Create table
   g_table = new UITable("PositionTable", 20, 50, 0);
   
   if(g_table == NULL) {
      Print("Failed to create table");
      return INIT_FAILED;
   }
   
   // Set theme from input
   g_table.SetTheme(InpTheme);
   
   // Define columns
   g_table.AddColumn("Symbol", 60, CELL_TYPE_TEXT);
   g_table.AddColumn("Type", 40, CELL_TYPE_TEXT);
   g_table.AddColumn("Volume", 50, CELL_TYPE_TEXT);
   g_table.AddColumn("Price", 60, CELL_TYPE_TEXT);
   g_table.AddColumn("SL", 60, CELL_TYPE_TEXT);
   g_table.AddColumn("TP", 60, CELL_TYPE_TEXT);
   g_table.AddColumn("Profit", 60, CELL_TYPE_TEXT);
   g_table.AddColumn("Edit", 50, CELL_TYPE_CUSTOM);    // Custom cell for button
   g_table.AddColumn("Close", 50, CELL_TYPE_CUSTOM);   // Custom cell for button
   
   // Initial update
   UpdatePositions();
   
   Print("Position Manager EA initialized successfully");
   Print("Theme: ", (InpTheme == THEME_DARK) ? "Dark" : "Light");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Delete all custom buttons
   DeleteAllButtons();
   
   // Delete edit dialog if active
   DeleteEditDialog();
   
   // Delete table
   if(g_table != NULL) {
      delete g_table;
      g_table = NULL;
   }
   
   Print("Position Manager EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   datetime currentTime = TimeCurrent();
   
   if(currentTime - g_lastUpdate >= InpUpdateInterval) {
      UpdatePositions();
      g_lastUpdate = currentTime;
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
   
   // Handle mouse move for hover effect
   if(id == CHARTEVENT_MOUSE_MOVE && g_table != NULL) {
      int x = (int)lparam;
      int y = (int)dparam;
      g_table.OnMouseMove(x, y);
   }
   
   // Handle object clicks
   if(id == CHARTEVENT_OBJECT_CLICK) {
      // Check if it's an Edit button
      if(StringFind(sparam, "btn_edit_") == 0) {
      Print("•>[Test.mq5:121]: sparam: ", sparam);
         int row = GetRowFromButtonName(sparam);
         if(row >= 0) {
            HandleEditClick(row);
         }
      }
      // Check if it's a Close button
      else if(StringFind(sparam, "btn_close_") == 0) {
         int row = GetRowFromButtonName(sparam);
         if(row >= 0) {
            HandleCloseClick(row);
         }
      }
      // Check edit dialog buttons
      else if(sparam == "edit_dialog_save") {
         HandleEditSave();
      }
      else if(sparam == "edit_dialog_cancel") {
         DeleteEditDialog();
      }
   }
}

//+------------------------------------------------------------------+
//| Update positions                                                 |
//+------------------------------------------------------------------+
void UpdatePositions() {
   if(g_table == NULL) return;
   
   // Delete old buttons
   DeleteAllButtons();
   
   // Clear table data
   g_table.ClearData();
   
   int totalPositions = PositionsTotal();
   
   if(totalPositions == 0) {
      g_table.Draw();
      return;
   }
   
   // Add positions to table
   for(int i = 0; i < totalPositions; i++) {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0) {
         string symbol = PositionGetString(POSITION_SYMBOL);
         int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         
         string rowData[9];
         rowData[0] = symbol;
         rowData[1] = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         rowData[2] = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2);
         rowData[3] = DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), digits);
         
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         
         rowData[4] = (sl > 0) ? DoubleToString(sl, digits) : "-";
         rowData[5] = (tp > 0) ? DoubleToString(tp, digits) : "-";
         rowData[6] = DoubleToString(PositionGetDouble(POSITION_PROFIT), 2);
         rowData[7] = IntegerToString(ticket);  // Store ticket for reference
         rowData[8] = "";
         
         g_table.AddRow(rowData);
      }
   }
   
   // Draw table
   g_table.Draw();
   
   // Create buttons for each row
   CreateButtons();
   
   // Update profit colors
   UpdateProfitColors();
}

//+------------------------------------------------------------------+
//| Create custom buttons for Edit and Close columns                 |
//+------------------------------------------------------------------+
void CreateButtons() {
   if(g_table == NULL) return;
   
   int rowCount = g_table.GetRowCount();
   ArrayResize(g_buttons, rowCount * 2);  // 2 buttons per row
   
   int buttonIndex = 0;
   
   for(int row = 0; row < rowCount; row++) {
      // Create Edit button (column 7)
      CreateButton(row, 7, "Edit", buttonIndex++);
      
      // Create Close button (column 8)
      CreateButton(row, 8, "Close", buttonIndex++);
   }
}

//+------------------------------------------------------------------+
//| Create a single button                                           |
//+------------------------------------------------------------------+
void CreateButton(int row, int col, string text, int buttonIndex) {
   int x, y, width, height;
   if(!g_table.GetCellPosition(row, col, x, y, width, height)) {
      return;
   }
   
   // Button dimensions
   int btnWidth = width - 10;
   int btnHeight = height - 8;
   int btnX = x + 5;
   int btnY = y + 4;
   
   // Button name
   string btnName = "btn_" + StringSubstr(text, 0, 5) + "_" + IntegerToString(row);
   uiCommon.CreateButton(0, btnName, text, btnWidth, btnHeight, clrWhite, C'70,130,180');
   uiCommon.setPosition(0, btnName, btnX, btnY);
   uiCommon.setFontSize(0, btnName,  8);
   // Store button info
   g_buttons[buttonIndex].row = row;
   g_buttons[buttonIndex].col = col;
   g_buttons[buttonIndex].objectName = btnName;
}

//+------------------------------------------------------------------+
//| Delete all buttons                                               |
//+------------------------------------------------------------------+
void DeleteAllButtons() {
   for(int i = 0; i < ArraySize(g_buttons); i++) {
      ObjectDelete(0, g_buttons[i].objectName);
      ObjectDelete(0, g_buttons[i].objectName + "_text");
   }
   ArrayResize(g_buttons, 0);
}

//+------------------------------------------------------------------+
//| Get row number from button name                                  |
//+------------------------------------------------------------------+
int GetRowFromButtonName(string buttonName) {
   string parts[];
   int count = StringSplit(buttonName, '_', parts);
   
   if(count >= 3) {
      return (int)StringToInteger(parts[2]);
   }
   
   return -1;
}

//+------------------------------------------------------------------+
//| Update profit colors                                             |
//+------------------------------------------------------------------+
void UpdateProfitColors() {
   int rowCount = g_table.GetRowCount();
   
   for(int row = 0; row < rowCount; row++) {
      string profitStr = g_table.GetCellValue(row, 6);
      double profit = StringToDouble(profitStr);
      
      color profitColor;
      if(profit > 0) {
         profitColor = (InpTheme == THEME_DARK) ? C'50,205,50' : C'0,150,0';  // Green
      } else if(profit < 0) {
         profitColor = (InpTheme == THEME_DARK) ? C'255,80,80' : C'200,0,0';  // Red
      } else {
         profitColor = (InpTheme == THEME_DARK) ? C'200,200,200' : C'60,60,80';
      }
      
      g_table.UpdateCell(row, 6, profitStr, profitColor);
   }
}

//+------------------------------------------------------------------+
//| Handle Edit button click                                         |
//+------------------------------------------------------------------+
void HandleEditClick(int row) {
   if(g_table == NULL || row < 0) return;
   
   // Get ticket from row data (stored in column 7)
   string ticketStr = g_table.GetCellValue(row, 7);
   Print("•>[Test.mq5:302]: ticketStr: ", ticketStr);
   ulong ticket = (ulong)StringToInteger(ticketStr);
   
   // Select position
   if(!PositionSelectByTicket(ticket)) {
      Print("Position not found: ", ticket);
      return;
   }
   
   g_editingRow = row;
   g_editingTicket = ticket;
   
   // Show edit dialog
   ShowEditDialog(ticket);
}

//+------------------------------------------------------------------+
//| Handle Close button click                                        |
//+------------------------------------------------------------------+
void HandleCloseClick(int row) {
   if(g_table == NULL || row < 0) return;
   
   // Get ticket
   string ticketStr = g_table.GetCellValue(row, 7);
   ulong ticket = (ulong)StringToInteger(ticketStr);
   
   // Confirm
   string symbol = g_table.GetCellValue(row, 0);
   string type = g_table.GetCellValue(row, 1);
   string volume = g_table.GetCellValue(row, 2);
   
   int answer = MessageBox(
      "Close position?\n\n" +
      "Symbol: " + symbol + "\n" +
      "Type: " + type + "\n" +
      "Volume: " + volume,
      "Confirm Close",
      MB_YESNO | MB_ICONQUESTION
   );
   
   if(answer == IDYES) {
      ClosePosition(ticket);
   }
}

//+------------------------------------------------------------------+
//| Close position                                                    |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket) {
   if(!PositionSelectByTicket(ticket)) {
      Print("Position not found");
      return;
   }
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double volume = PositionGetDouble(POSITION_VOLUME);
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = symbol;
   request.volume = volume;
   request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (posType == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(symbol, SYMBOL_ASK);
   request.deviation = 10;
   request.comment = "Closed by Manager";
   
   if(OrderSend(request, result)) {
      Print("✓ Position closed successfully");
      Print("Ticket: ", ticket);
      Print("Result: ", result.comment);
      Sleep(200);
      UpdatePositions();
   } else {
      Print("✗ Failed to close position");
      Print("Error: ", GetLastError());
      Print("Result: ", result.comment);
      
      MessageBox(
         "Failed to close position\n\n" +
         "Error: " + IntegerToString(GetLastError()) + "\n" +
         result.comment,
         "Error",
         MB_OK | MB_ICONERROR
      );
   }
}

//+------------------------------------------------------------------+
//| Show edit dialog                                                 |
//+------------------------------------------------------------------+
void ShowEditDialog(ulong ticket) {
   if(!PositionSelectByTicket(ticket)) return;
   
   DeleteEditDialog();  // Delete old dialog if exists
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   
   // Dialog background
   ObjectCreate(0, "edit_dialog_bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_XSIZE, 350);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_YSIZE, 200);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_COLOR, C'100,100,100');
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "edit_dialog_bg", OBJPROP_BACK, false);
   
   // Title
   ObjectCreate(0, "edit_dialog_title", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_title", OBJPROP_XDISTANCE, 220);
   ObjectSetInteger(0, "edit_dialog_title", OBJPROP_YDISTANCE, 160);
   ObjectSetString(0, "edit_dialog_title", OBJPROP_TEXT, "Edit Position: " + symbol);
   ObjectSetString(0, "edit_dialog_title", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "edit_dialog_title", OBJPROP_FONTSIZE, 11);
   ObjectSetInteger(0, "edit_dialog_title", OBJPROP_COLOR, C'50,50,50');
   
   // SL Label
   ObjectCreate(0, "edit_dialog_sl_label", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_sl_label", OBJPROP_XDISTANCE, 220);
   ObjectSetInteger(0, "edit_dialog_sl_label", OBJPROP_YDISTANCE, 195);
   ObjectSetString(0, "edit_dialog_sl_label", OBJPROP_TEXT, "Stop Loss:");
   ObjectSetString(0, "edit_dialog_sl_label", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "edit_dialog_sl_label", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "edit_dialog_sl_label", OBJPROP_COLOR, C'50,50,50');
   
   // SL Edit box
   ObjectCreate(0, "edit_dialog_sl", OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_YDISTANCE, 190);
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_YSIZE, 25);
   ObjectSetString(0, "edit_dialog_sl", OBJPROP_TEXT, DoubleToString(currentSL, digits));
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_ALIGN, ALIGN_LEFT);
   ObjectSetInteger(0, "edit_dialog_sl", OBJPROP_READONLY, false);
   
   // TP Label
   ObjectCreate(0, "edit_dialog_tp_label", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_tp_label", OBJPROP_XDISTANCE, 220);
   ObjectSetInteger(0, "edit_dialog_tp_label", OBJPROP_YDISTANCE, 235);
   ObjectSetString(0, "edit_dialog_tp_label", OBJPROP_TEXT, "Take Profit:");
   ObjectSetString(0, "edit_dialog_tp_label", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "edit_dialog_tp_label", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "edit_dialog_tp_label", OBJPROP_COLOR, C'50,50,50');
   
   // TP Edit box
   ObjectCreate(0, "edit_dialog_tp", OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_YDISTANCE, 230);
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_YSIZE, 25);
   ObjectSetString(0, "edit_dialog_tp", OBJPROP_TEXT, DoubleToString(currentTP, digits));
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_ALIGN, ALIGN_LEFT);
   ObjectSetInteger(0, "edit_dialog_tp", OBJPROP_READONLY, false);
   
   // Save button
   ObjectCreate(0, "edit_dialog_save", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_YDISTANCE, 280);
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_XSIZE, 90);
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_YSIZE, 30);
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_BGCOLOR, C'70,130,180');
   ObjectSetInteger(0, "edit_dialog_save", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   
   ObjectCreate(0, "edit_dialog_save_text", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_save_text", OBJPROP_XDISTANCE, 345);
   ObjectSetInteger(0, "edit_dialog_save_text", OBJPROP_YDISTANCE, 287);
   ObjectSetString(0, "edit_dialog_save_text", OBJPROP_TEXT, "Save");
   ObjectSetString(0, "edit_dialog_save_text", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "edit_dialog_save_text", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "edit_dialog_save_text", OBJPROP_COLOR, clrWhite);
   
   // Cancel button
   ObjectCreate(0, "edit_dialog_cancel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_XDISTANCE, 420);
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_YDISTANCE, 280);
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_XSIZE, 90);
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_YSIZE, 30);
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_BGCOLOR, C'150,150,150');
   ObjectSetInteger(0, "edit_dialog_cancel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   
   ObjectCreate(0, "edit_dialog_cancel_text", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "edit_dialog_cancel_text", OBJPROP_XDISTANCE, 440);
   ObjectSetInteger(0, "edit_dialog_cancel_text", OBJPROP_YDISTANCE, 287);
   ObjectSetString(0, "edit_dialog_cancel_text", OBJPROP_TEXT, "Cancel");
   ObjectSetString(0, "edit_dialog_cancel_text", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "edit_dialog_cancel_text", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "edit_dialog_cancel_text", OBJPROP_COLOR, clrWhite);
   
   g_editDialogActive = true;
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Handle edit save                                                 |
//+------------------------------------------------------------------+
void HandleEditSave() {
   if(!PositionSelectByTicket(g_editingTicket)) {
      Print("Position not found");
      DeleteEditDialog();
      return;
   }
   
   // Get values from edit boxes
   string slStr = ObjectGetString(0, "edit_dialog_sl", OBJPROP_TEXT);
   string tpStr = ObjectGetString(0, "edit_dialog_tp", OBJPROP_TEXT);
   
   double newSL = StringToDouble(slStr);
   double newTP = StringToDouble(tpStr);
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   // Normalize
   newSL = NormalizeDouble(newSL, digits);
   newTP = NormalizeDouble(newTP, digits);
   
   // Modify position
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_SLTP;
   request.position = g_editingTicket;
   request.symbol = symbol;
   request.sl = newSL;
   request.tp = newTP;
   
   if(OrderSend(request, result)) {
      Print("✓ Position modified successfully");
      Print("New SL: ", newSL, " | New TP: ", newTP);
      DeleteEditDialog();
      Sleep(200);
      UpdatePositions();
   } else {
      Print("✗ Failed to modify position");
      Print("Error: ", GetLastError());
      
      MessageBox(
         "Failed to modify position\n\n" +
         "Error: " + IntegerToString(GetLastError()) + "\n" +
         result.comment,
         "Error",
         MB_OK | MB_ICONERROR
      );
   }
}

//+------------------------------------------------------------------+
//| Delete edit dialog                                               |
//+------------------------------------------------------------------+
void DeleteEditDialog() {
   ObjectDelete(0, "edit_dialog_bg");
   ObjectDelete(0, "edit_dialog_title");
   ObjectDelete(0, "edit_dialog_sl_label");
   ObjectDelete(0, "edit_dialog_sl");
   ObjectDelete(0, "edit_dialog_tp_label");
   ObjectDelete(0, "edit_dialog_tp");
   ObjectDelete(0, "edit_dialog_save");
   ObjectDelete(0, "edit_dialog_save_text");
   ObjectDelete(0, "edit_dialog_cancel");
   ObjectDelete(0, "edit_dialog_cancel_text");
   
   g_editDialogActive = false;
   g_editingRow = -1;
   g_editingTicket = 0;
   
   ChartRedraw();
}
//+------------------------------------------------------------------+