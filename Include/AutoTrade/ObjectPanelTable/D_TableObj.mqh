//+------------------------------------------------------------------+
//|     v1.0   build complete                                  |
//+------------------------------------------------------------------+
/*
1 Put the file in the MQL4\Inclue folder

2 In your indicator/expert/script type
   #include <DanyInclude\\D_Table.mqh>

3 Declare your table by:
   string table_prefix = "my_table_";
   Table *my_Table = new Table(ChartID(), 0, table_prefix);

4 Initialize your table by calling: myTable.Create();
//use the default values; or myTable.Create(int x=0, int y=0, int w=0, int h=0, int xOffset=3, int yOffset=3, int cellWidth=0, int cellHeight=0, int cellSpace=2, int fontSize=8, string fontName="Terminal") //to set each value as you wishes

5 Create a 2-Dimensional string array to story your data:
string my_cells[rows][cols] //as MQL4 don't not support 2-D dynamic array, therefore, currently only support static 2-D array.

   int roww = 0;
      my_cells[roww][0] = "";
      my_cells[roww][1] = DoubleToStr(AccountBalance(),2);
      roww++;

6 To show your table: myTable.Show(cells);

*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Table {
 private:
   long              _id;
   int               _subwin, _x, _y, _myX, _myY,
                     _cellW, _cellH, _cellSpace,
                     _tableW, _tableH,
                     _fontSize, _cols, _rows;
   string            _name, _fontName;
   bool              _showTableBg, _showCellBg;
   color             _textColor, _TableBgColor, _CellBgColor;
   ENUM_BASE_CORNER  _corner;
   ENUM_ANCHOR_POINT _anchor;

   bool              _IsObjectExist(string name) {
      if(ObjectFind(_id, name)>0)
         return true;
      return false;
   };
   int               _GetX(int col) {
      int x_ret = 0;
      if(_corner == CORNER_RIGHT_UPPER || _corner == CORNER_RIGHT_LOWER) {
         x_ret = _myX - col*(_cellW + _cellSpace);
      } else {
         x_ret = _myX + col*(_cellW+_cellSpace);
      }
      return(x_ret);
   };
   int               _GetY(int row) {
      int y_ret = 0;
      if(_corner == CORNER_LEFT_LOWER || _corner == CORNER_RIGHT_LOWER) {
         y_ret = _myY - row*(_cellH + _cellSpace);
      } else {
         y_ret = _myY + row*(_cellH+_cellSpace);
      }
      return(y_ret);
   };

 public:
   void              Table(long id, int subwin, string name);
   void              Create(ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, int x=0, int y=0,
                            int cellWidth=0, int cellHeight=0, int cellSpace=2,color cellColor = clrNONE,
                            int tableWidth=0, int tableHeight=0, color tableColor=clrNONE,
                            int fontSize=8,color textColor=clrYellow);
   void              Delete();
   bool              Show(string &cells[][]);
   bool              CellTextUpdate(string text,int row,int col);
};
//---
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Table::CellTextUpdate(string text,int row,int col) {
   string name = "";
   StringConcatenate(name , _name , "r", row, "c", col);
   if(ObjectGetString(_id,name, OBJPROP_TEXT, 0) != text) {
      if(ObjectSetString(_id,name, OBJPROP_TEXT, text)) {
         ChartRedraw();
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Table::Show(string &cells[][]) {
   _cols = ArrayRange(cells, 1);
   _rows = ArrayRange(cells, 0);

// caculator if cell or table not set W H
   if(_cellH ==0 && _tableH !=0)
      _cellH = (int)_tableH / _rows - _cellSpace;
   if(_cellH !=0 && _tableH == 0)
      _tableH = (int)(_cellH +_cellSpace)* _rows;
   if(_cellW ==0 && _tableW != 0)
      _cellW = (int)_tableW / _cols - _cellSpace;
   if(_cellW !=0 && _tableW == 0)
      _tableW = (int)(_cellW +_cellSpace)*_cols;

// caculator myX myY this is left upper point of my table
   _myX = _x ;
   _myY = _y ;
   if(_corner == CORNER_LEFT_LOWER  || _corner == CORNER_RIGHT_LOWER)
      _myY = _y + _tableH;
   if(_corner == CORNER_RIGHT_UPPER || _corner == CORNER_RIGHT_LOWER)
      _myX = _x + _tableW;

// creat rectan and border of table
   if(_showTableBg) {
      int table_border =3;
      int tableX = _myX;
      int tableY =_myY;
      if(_corner == CORNER_RIGHT_UPPER || _corner == CORNER_RIGHT_LOWER)
         tableX = _myX+3;
      else
         tableX = _myX-3;
      if(_corner ==  CORNER_LEFT_LOWER || _corner == CORNER_RIGHT_LOWER)
         tableY = _myY+3;
      else
         tableY = _myY-3;

      RectLabelCreate(_id,_name + "bgTable", 0, tableX, tableY,
                      _tableW + table_border, _tableH + table_border,
                      _TableBgColor,BORDER_FLAT, _corner, ANCHOR_LEFT_UPPER,
                      clrGray, STYLE_SOLID, 1);
   }

// creat rectan and label of cell
   for(int r=0; r<_rows; r++) {
      for(int c=0; c<_cols; c++) {
         string name ="";
         StringConcatenate(name ,_name, "r", r, "c", c);
         string cellBgName = name+"bg";
         int x = _GetX(c);
         int y = _GetY(r);

         if(_showCellBg) {
            RectLabelCreate(_id,cellBgName, _subwin, x, y, _cellW, _cellH,
                            _CellBgColor,BORDER_SUNKEN, _corner, ANCHOR_LEFT_UPPER, clrRed, STYLE_SOLID, 1);
         }

         if(!_IsObjectExist(name)) {
            if(!LabelCreate(_id,name, _subwin, x, y, _corner,
                            cells[r][c],_fontName,_fontSize,_textColor,ANCHOR_LEFT_UPPER))
               return false;
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Table::Create(ENUM_BASE_CORNER corner=0,int x=0,int y=0,
                   int cellWidth=0,int cellHeight=0,int cellSpace=2,color cellColor = clrNONE,
                   int tableWidth=0, int tableHeight=0,color tableColor=clrNONE,
                   int fontSize=8,color textColor=clrYellow) {
   _corner = corner;
//--- corner to anchor
   if(_corner == CORNER_LEFT_UPPER)
      _anchor = ANCHOR_LEFT_UPPER;
   else if(_corner == CORNER_LEFT_LOWER)
      _anchor = ANCHOR_LEFT_LOWER;
   else if(_corner == CORNER_RIGHT_UPPER)
      _anchor = ANCHOR_LEFT_UPPER;
   else if(_corner == CORNER_RIGHT_LOWER)
      _anchor = ANCHOR_LEFT_LOWER;

   _x = x;
   _y = y;

// cell properties
   _cellW = cellWidth;
   _cellH = cellHeight;
   _cellSpace = cellSpace;
   if(cellColor != clrNONE) {
      _showCellBg = true;
      _CellBgColor = cellColor;
   }

// table properties
   _tableW = tableWidth;
   _tableH = tableHeight;
   if(tableColor != clrNONE) {
      _showTableBg = true;
      _TableBgColor = tableColor;
   }

// text properties
   _fontSize = fontSize;
   _fontName = "Arial";
   _textColor = textColor;

   _cols = -1;
   _rows = -1;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Table::Table(long id, int subwin, string name) {
   _id = id;
   _subwin = subwin;
   _name = name;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Table::Delete() {
   if(_subwin==0) {
      int i = ObjectsTotal(_id, _subwin) - 1;
      while(i>=0) {
         string name = ObjectName(_id,i);
         if(StringFind(name, _name)>-1)
            ObjectDelete(_id,name);
         i--;
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             textclr=clrRed,               // color
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER) { // anchor type
   const double            angle=0.0;                // text slope
   const bool              back=false;               // in the background
   const bool              selection=false;          // highlight to move
   const bool              hidden=true;              // hidden in the object list
   const long              z_order=0;                // priority for mouse click

//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0)) {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
   }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,textclr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}

//+------------------------------------------------------------------+
//| Create rectangle label                                           |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=0,             // subwindow index
                     int              x=0,                      // X coordinate
                     int              y=0,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const color            back_clr=C'236,233,216',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const ENUM_ANCHOR_POINT anchor= ANCHOR_LEFT_UPPER, // THIS IS MY OPTION
                     const color            clrBorder=clrRed,               // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1             // flat border width
                    ) {

   const bool             back=false;               // in the background
   const bool             selection=false;          // highlight to move
   const bool             hidden=true;             // hidden in the object list
   const long             z_order=0;                // priority for mouse click
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0)) {
      Print(__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
   }
//--- my caculation anchor point
   if(anchor == ANCHOR_LEFT_LOWER) {
      if(corner == CORNER_LEFT_UPPER || corner == CORNER_RIGHT_UPPER) {
         y = y - height;
      } else {
         y = y + height;
      }
   } else if(anchor == ANCHOR_RIGHT_UPPER) {
      if(corner == CORNER_RIGHT_UPPER || corner == CORNER_RIGHT_LOWER) {
         x = x + width;
      } else {
         x = x - width;
      }
   } else if(anchor == ANCHOR_RIGHT_LOWER) {
      if(corner == CORNER_LEFT_UPPER || corner == CORNER_RIGHT_UPPER) {
         y = y - height;
      } else {
         y = y + height;
      }

      if(corner == CORNER_RIGHT_UPPER || corner == CORNER_RIGHT_LOWER) {
         x = x + width;
      } else {
         x = x - width;
      }
   }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set label size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border type
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrBorder);
//--- set flat border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set flat border width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);

   return(true);
}
//+------------------------------------------------------------------+
/* this is test table Ea

#include <DanyInclude\\D_Table.mqh>
string table_prefix = "my_table_";
Table *my_Table = new Table(ChartID(), 0, table_prefix);
string my_cells[2][2];

input ENUM_BASE_CORNER inp_corner = CORNER_LEFT_LOWER;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      my_Table.Create(inp_corner , 10 ,10 ,200, 50 , 2, clrAqua , 500 , 100, clrRed , 8 , clrYellow);
      int roww = 0;
      my_cells[roww][0] = "AccountBalance";
      my_cells[roww][1] = DoubleToStr(AccountBalance(),2);
      roww++;

      my_cells[roww][0] = "num";
      my_cells[roww][1] = "12312312321";
      roww++;

      my_Table.Show(my_cells);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   my_Table.Delete();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   my_Table.CellTextUpdate(DoubleToStr(AccountEquity(),2) , 0 , 1 );
  }
//+------------------------------------------------------------------+

*/
//+------------------------------------------------------------------+
