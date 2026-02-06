/*
v1.3 function to draw the object
ButtonCreate
TextCreate
HLineCreate
TrendlineCreate
LabelCreate
RectLabelCreate
ArrowCreate 
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool D_Button(const string            name="Button",            // button name
              const ENUM_BASE_CORNER  corner=CORNER_RIGHT_LOWER, // chart corner for anchoring
              const int               x=0,                      // X coordinate
              const int               y=0,                      // Y coordinate
              const int               width=50,                 // button width
              const int               height=18,               // button height
              const string            text="Button",            // text
              const color             clrtext=clrBlack,             // text color
              const color             back_clr=clrYellow,  // background color
              const int               font_size=10             // font size
             ) {              // priority for mouse click
   const long              chart_ID=ChartID() ;
   const int               sub_window=0;             // subwindow index
   const string            font="Arial";             // font
   const color             border_clr=clrNONE;       // border color
   const bool              state=false;              // pressed/released
   const bool              back=false;               // in the background
   const bool              selection=false;          // highlight to move
   const bool              hidden=true;              // hidden in the object list
   const long              z_order=0 ;
//--- reset the error value
   ResetLastError();
//--- create the button
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0)) {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
   }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrtext);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
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
//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool D_Text(   const string            name="Text",              // object name
               const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
               datetime                time=0,                   // anchor point time
               double                  price=0,                  // anchor point price
               const string            text="Text",              // the text itself
               const int               font_size=10,             // font size
               const color             clr=clrRed               // color

           ) {
   const long              chart_ID=ChartID();               // chart's ID
   const int               sub_window=0;             // subwindow index
   const string            font="Arial";             // font
   const double            angle=0.0;                // text slope
   const bool              back=false;               // in the background
   const bool              selection=false;          // highlight to move
   const bool              hidden=true;              // hidden in the object list
   const long              z_order=0;                // priority for mouse click

//--- create Text object
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
   }
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
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
//---
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool D_HLine(       const string          name="HLine",// line name
                    double                price=0,           // line price
                    const color           clr=clrRed,        // line color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                    const int             width=1           // line width
            ) {
   const long            chart_ID=ChartID();        // chart's ID
   const int             sub_window=0;      // subwindow index
   const bool            back=false;        // in the background
   const bool            selection=true;    // highlight to move
   const bool            hidden=true;       // hidden in the object list
   const long            z_order=0;        // priority for mouse click
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
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
//+------------------------------------------------------------------+
//| Create a trend line by the given coordinates                     |
//+------------------------------------------------------------------+
bool D_Trendline(const string          name="TrendLine",  // line name
                 datetime              time1=0,           // first point time
                 double                price1=0,          // first point price
                 datetime              time2=0,           // second point time
                 double                price2=0,          // second point price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1           // line width
                ) {
   const long            chart_ID=ChartID();        // chart's ID
   const int             sub_window=0;      // subwindow index

   const bool            back=false;        // in the background
   const bool            selection=true;    // highlight to move
   const bool            ray_left=false;    // line's continuation to the left
   const bool            ray_right=false;   // line's continuation to the right
   const bool            hidden=true;       // hidden in the object list
   const long            z_order=0;         // priority for mouse click
//--- set anchor points' coordinates if they are not set
//ChangeTrendEmptyPoints(time1,price1,time2,price2);
//--- reset the error value
   ResetLastError();
//--- create a trend line by the given coordinates
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) {
      Print(__FUNCTION__,
            ": failed to create a trend line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool D_Label(const string            name="Label",             // label name
             const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
             const int               x=0,                      // X coordinate
             const int               y=0,                      // Y coordinate
             const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER,   // anchor type
             const string            text="Label",             // text
             const int               font_size=10,             // font size
             const color             clr=clrRed               // color
            ) {
   const long              chart_ID=ChartID();        // chart's ID
   const int               sub_window=0;             // subwindow index
   const string            font="Arial";             // font
   const double            angle=0.0;                // text slope
   const bool              back=false;               // in the background
   const bool              selection=false;          // highlight to move
   const bool              hidden=true;              // hidden in the object list
   const long              z_order=0;                // priority for mouse click

//--- reset the error value
   ResetLastError();
//--- create a text label
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0)) {
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
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
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
bool D_RectLabel(   const string           name="RectLabel",         // label name
                    int                    x=0,                      // X coordinate
                    int                    y=0,                      // Y coordinate
                    const int              width=50,                 // width
                    const int              height=18,                // height
                    const color            back_clr=C'236,233,216',  // background color
                    const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                    const ENUM_ANCHOR_POINT anchor= ANCHOR_LEFT_UPPER // THIS IS MY OPTION
                ) {
   const long             chart_ID=ChartID();               // chart's ID
   const int              sub_window=0;             // subwindow index
   const ENUM_BORDER_TYPE border=BORDER_FLAT;     // border type
   const color            clrBorder=clrRed;           // flat border color (Flat)
   const ENUM_LINE_STYLE  style=STYLE_SOLID;        // flat border style
   const int              line_width=1;             // flat border width
   const bool             back=false;               // in the background
   const bool             selection=false;          // highlight to move
   const bool             hidden=true;             // hidden in the object list
   const long             z_order=0;                // priority for mouse click
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0)) {
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
   } else if (anchor == ANCHOR_RIGHT_UPPER) {
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
//+------------------------------------------------------------------+
//| Create the arrow                                                 |
//+------------------------------------------------------------------+
bool D_Arrow(
   const string            name="Arrow",         // arrow name
   datetime                time=0,               // anchor point time
   double                  price=0,              // anchor point price
   const uchar             arrow_code=242,       // arrow code
   const ENUM_ARROW_ANCHOR anchor=ANCHOR_BOTTOM, // anchor point position
   const color             clr=clrRed,           // arrow color
   const ENUM_LINE_STYLE   style=STYLE_SOLID,    // border line style
   const int               width=3              // arrow size
   ) {            

   const long             chart_ID=ChartID();       // chart's ID
   const int              sub_window=0;             // subwindow index

   const bool              back=false;           // in the background
   const bool              selection=false;       // highlight to move
   const bool              hidden=true;          // hidden in the object list
   const long              z_order=0;          // priority for mouse click
//--- create an arrow
   if(ObjectFind(chart_ID, name) <0 && !ObjectCreate(chart_ID,name,OBJ_ARROW,sub_window,time,price)) {
      Print(__FUNCTION__,
            ": failed to create an arrow! Error code = ",GetLastError());
      return(false);
   }
//--- set the arrow code
   ObjectSetInteger(chart_ID,name,OBJPROP_ARROWCODE,arrow_code);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set the arrow color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set the arrow's size
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the arrow by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
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
