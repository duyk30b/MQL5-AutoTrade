#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UICheckbox.mqh>
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputNumber.mqh>
#include <AutoTrade/UI/UIInputRadio.mqh>

class TDTabSetting {
 private:
   int               m_x;
   int               m_y;
   int               m_width;
   int               m_height;

   double            m_volumeValue;
   ENUM_VOLUME_TYPE  m_volumeType;

   UIInputRadio      m_irVolumeTypeInput;
   UIInputRadio      m_irVolumeTypeMoney;
   UIInputRadio      m_irVolumeTypePercentBalance;
   UIInputRadio      m_irVolumeTypePercentEquity;

   UIInputRadioGroup m_irVolumeTypeGroup;

   UIInputNumber     m_ipVolumeValue;

   string            m_ObjDescriptionVolumeName;
   string            m_ObjBtnSubmitName;

 public:
   void Initialization() {
      m_irVolumeTypeGroup.SetCallback(&this, OnChangeIpRadioVolumeType);
      m_ipVolumeValue.SetCallback(&this, OnChangeIpVolumeValue);

      m_irVolumeTypeGroup.AddInputRadio(&m_irVolumeTypeInput);
      m_irVolumeTypeGroup.AddInputRadio(&m_irVolumeTypeMoney);
      m_irVolumeTypeGroup.AddInputRadio(&m_irVolumeTypePercentBalance);
      m_irVolumeTypeGroup.AddInputRadio(&m_irVolumeTypePercentEquity);
      m_irVolumeTypeInput.Initialization(g_chartId, "TD_TAB_SETTING_IR_VOLUME_TYPE_INPUT");
      m_irVolumeTypeMoney.Initialization(g_chartId, "TD_TAB_SETTING_IR_VOLUME_TYPE_MONEY");
      m_irVolumeTypePercentBalance.Initialization(
         g_chartId,
         "TD_TAB_SETTING_IR_VOLUME_TYPE_PERCENT_BALANCE"
      );
      m_irVolumeTypePercentEquity.Initialization(
         g_chartId,
         "TD_TAB_SETTING_IR_VOLUME_TYPE_PERCENT_EQUITY"
      );

      m_ipVolumeValue.Initialization(g_chartId, "TD_TAB_SETTING_IP_VOLUME_VALUE");
      m_ObjDescriptionVolumeName = "TD_TAB_SETTING_OBJ_DESCRIPTION_VOLUME";
      m_ObjBtnSubmitName         = "TD_TAB_SETTING_BTN_SUBMIT";
   }

   static void OnChangeIpRadioVolumeType(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.SetVolumeType((ENUM_VOLUME_TYPE)(int)value);
         double volumeValue = 0;

         if(int(value) == VOLUME_TYPE_INPUT) {
            self.m_ipVolumeValue.UpdateLabel("Volume risk: Input");
            self.m_ipVolumeValue.UpdateDisabled(true);
         }
         if(int(value) == VOLUME_TYPE_MONEY) {
            self.m_ipVolumeValue.UpdateLabel("Volume risk: Money ($)");
            self.m_ipVolumeValue.UpdateDisabled(false);
         }
         if(int(value) == VOLUME_TYPE_PERCENT_BALANCE) {
            self.m_ipVolumeValue.UpdateLabel("Volume risk: Percent Balance (%)");
            self.m_ipVolumeValue.UpdateDisabled(false);
         }
         if(int(value) == VOLUME_TYPE_PERCENT_EQUITY) {
            self.m_ipVolumeValue.UpdateLabel("Volume risk: Percent Equity (%)");
            self.m_ipVolumeValue.UpdateDisabled(false);
         }

         if(int(value) == g_volumeType) {
            volumeValue = g_volumeValue;
         }

         self.SetVolumeValue(volumeValue);
         self.m_ipVolumeValue.UpdateValue(volumeValue);
         ChartRedraw(g_chartId);
      }
   }

   static void OnChangeIpVolumeValue(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.SetVolumeValue(value);
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      string irVolumeTypeGroupObjNameList[];
      int    irVolumeTypeGroupObjCount
         = m_irVolumeTypeGroup.GetObjectNameList(irVolumeTypeGroupObjNameList);

      string ipVolumeValueObjNameList[];
      int    ipVolumeValueObjCount = m_ipVolumeValue.GetObjectNameList(ipVolumeValueObjNameList);

      ArrayResize(
         objNameList,
         1 + irVolumeTypeGroupObjCount + ipVolumeValueObjCount + 1

      );
      int count            = 0;
      objNameList[count++] = m_ObjDescriptionVolumeName;
      for(int i = 0; i < irVolumeTypeGroupObjCount; i++)
         objNameList[count++] = irVolumeTypeGroupObjNameList[i];
      for(int i = 0; i < ipVolumeValueObjCount; i++)
         objNameList[count++] = ipVolumeValueObjNameList[i];
      objNameList[count++] = m_ObjBtnSubmitName;

      return count;
   }

   void SetVolumeType(ENUM_VOLUME_TYPE volumeType) {
      m_volumeType = volumeType;
      syncButtonSaveColor();
   }
   void SetVolumeValue(double volumeValue) {
      m_volumeValue = volumeValue;
      syncButtonSaveColor();
   }

   void syncButtonSaveColor() {
      if(g_volumeType != m_volumeType || g_volumeValue != m_volumeValue) {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrWhite);
      } else {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrSlateGray);
      }
   }

   void StartDraw(int x, int y, int width, int height);
   void DestroyDraw();
   void RefreshData();
   void ClickBtnSubmit();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void TDTabSetting::StartDraw(int x, int y, int width, int height) {
   m_x              = x;
   m_y              = y;
   m_width          = width;
   m_height         = height;

   m_volumeType     = g_volumeType;
   m_volumeValue    = g_volumeValue;

   int yOffsetPanel = 10;

   // Vẽ tiêu đề cho phần Volume
   uiCommon.CreateLabel(
      g_chartId,
      m_ObjDescriptionVolumeName,
      "1. Volume Risk settings:",
      m_x + 10,
      m_y + yOffsetPanel,
      10,
      clrWhite
   );
   uiCommon.setZOrder(g_chartId, m_ObjDescriptionVolumeName, 100);

   yOffsetPanel     = yOffsetPanel + 24;

   int checkboxSize = 15;
   int fontSize     = 10;
   int paddingY     = 8;

   m_irVolumeTypeInput.SetValue(VOLUME_TYPE_INPUT);
   m_irVolumeTypeInput.SetChecked(m_volumeType == VOLUME_TYPE_INPUT);
   m_irVolumeTypeInput.StartDraw(m_x + 10, m_y + yOffsetPanel, "Input volume", fontSize);

   m_irVolumeTypeMoney.SetValue(VOLUME_TYPE_MONEY);
   m_irVolumeTypeMoney.SetChecked(m_volumeType == VOLUME_TYPE_MONEY);
   m_irVolumeTypeMoney
      .StartDraw(m_x + 10, m_y + yOffsetPanel + checkboxSize + paddingY, "Money", fontSize);

   m_irVolumeTypePercentBalance.SetValue(VOLUME_TYPE_PERCENT_BALANCE);
   m_irVolumeTypePercentBalance.SetChecked(m_volumeType == VOLUME_TYPE_PERCENT_BALANCE);
   m_irVolumeTypePercentBalance.StartDraw(
      m_x + 10,
      m_y + yOffsetPanel + (checkboxSize + paddingY) * 2,
      "Percent Balance",
      fontSize
   );

   m_irVolumeTypePercentEquity.SetValue(VOLUME_TYPE_PERCENT_EQUITY);
   m_irVolumeTypePercentEquity.SetChecked(m_volumeType == VOLUME_TYPE_PERCENT_EQUITY);
   m_irVolumeTypePercentEquity.StartDraw(
      m_x + 10,
      m_y + yOffsetPanel + (checkboxSize + paddingY) * 3,
      "Percent Equity",
      fontSize
   );

   if(m_volumeType == VOLUME_TYPE_INPUT) {
      m_ipVolumeValue.SetLabel("Volume risk: Input", clrWhite);
      m_ipVolumeValue.SetDisabled(true);
   } else if(m_volumeType == VOLUME_TYPE_MONEY) {
      m_ipVolumeValue.SetLabel("Volume risk: Money ($)", clrWhite);
      m_ipVolumeValue.SetDisabled(false);
   } else if(m_volumeType == VOLUME_TYPE_PERCENT_BALANCE) {
      m_ipVolumeValue.SetLabel("Volume risk: Percent Balance (%)", clrWhite);
      m_ipVolumeValue.SetDisabled(false);
   } else if(m_volumeType == VOLUME_TYPE_PERCENT_EQUITY) {
      m_ipVolumeValue.SetLabel("Volume risk: Percent Equity (%)", clrWhite);
      m_ipVolumeValue.SetDisabled(false);
   }

   m_ipVolumeValue.SetValue(m_volumeValue);
   m_ipVolumeValue.StartDraw(m_x + m_width / 2, m_y + yOffsetPanel, 220, 45);
   m_ipVolumeValue.UpdateDisabled(m_volumeType == VOLUME_TYPE_INPUT);

   yOffsetPanel = yOffsetPanel + (checkboxSize + paddingY) * 4 + 10;
   // Tạo nút Submit
   uiCommon.CreateButton(
      g_chartId,
      m_ObjBtnSubmitName,
      "SAVE",
      m_x + m_width / 2 - 50,
      m_y + yOffsetPanel,
      100,
      35
   );
   uiCommon.setZOrder(g_chartId, m_ObjBtnSubmitName, 100);
   syncButtonSaveColor();
}

void TDTabSetting::DestroyDraw() {
   string objNameList[];
   int    objCount = GetObjectNameList(objNameList);
   for(int i = 0; i < objCount; i++) {
      ObjectDelete(g_chartId, objNameList[i]);
   }
}

void TDTabSetting::RefreshData() {}

void TDTabSetting::ClickBtnSubmit() {
   g_volumeType  = (ENUM_VOLUME_TYPE)m_irVolumeTypeGroup.GetValue();
   g_volumeValue = m_ipVolumeValue.GetValue();
   changeVolumeRisk();

   Sleep(100);
   ObjectSetInteger(g_chartId, m_ObjBtnSubmitName, OBJPROP_STATE, false);
   syncButtonSaveColor();
}

void TDTabSetting::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_irVolumeTypeGroup.OnChartEvent(id, lparam, dparam, sparam);
   m_ipVolumeValue.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnSubmitName) {
         ClickBtnSubmit();
      }
   }
}

void TDTabSetting::OnMQLTesterEvent() {
   m_irVolumeTypeGroup.OnMQLTesterEvent();
   m_ipVolumeValue.OnMQLTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnSubmitName)) {
      ClickBtnSubmit();
   }
}
