#include "TradeDashboardContext.mqh"
#include <AutoTrade/UI/UIDefines.mqh>
#include <AutoTrade/UI/UIInputCheckbox.mqh>
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

   UIInputRadio      m_iprVolumeTypeInput;
   UIInputRadio      m_iprVolumeTypeMoney;
   UIInputRadio      m_iprVolumeTypePercentBalance;
   UIInputRadio      m_iprVolumeTypePercentEquity;

   UIInputRadioGroup m_irVolumeTypeGroup;

   UIInputNumber     m_ipnVolumeValue;

   string            m_ObjDescriptionVolumeName;

   bool              m_enableTrailingStop;
   int               m_tsStartPoints;
   int               m_tsStepPoints;
   int               m_tsDistancePoints;

   UIInputCheckbox   m_ipcTrailingStopEnable;

   UIInputNumber     m_ipnTrailingStopStart;
   UIInputNumber     m_ipnTrailingStopStep;
   UIInputNumber     m_ipnTrailingStopDistance;

   string            m_ObjBtnSubmitName;

 public:
   TDTabSetting() {}
   ~TDTabSetting() {
      ObjectDelete(g_chartId, m_ObjDescriptionVolumeName);
      ObjectDelete(g_chartId, m_ObjBtnSubmitName);
   }

   void Initialize() {
      m_irVolumeTypeGroup.SetCallback(&this, OnChangeIpRadioVolumeType);
      m_ipnVolumeValue.SetCallback(&this, OnChangeIpVolumeValue);
      m_ipcTrailingStopEnable.SetCallback(&this, OnChangeTrailingStopEnable);
      m_ipnTrailingStopStart.SetCallback(&this, OnChangeTrailingStopStart);
      m_ipnTrailingStopStep.SetCallback(&this, OnChangeTrailingStopStep);
      m_ipnTrailingStopDistance.SetCallback(&this, OnChangeTrailingStopDistance);

      m_ObjDescriptionVolumeName = "TdTabSetting_ObjDescriptionVolume";
      m_irVolumeTypeGroup.AddInputRadio(&m_iprVolumeTypeInput);
      m_irVolumeTypeGroup.AddInputRadio(&m_iprVolumeTypeMoney);
      m_irVolumeTypeGroup.AddInputRadio(&m_iprVolumeTypePercentBalance);
      m_irVolumeTypeGroup.AddInputRadio(&m_iprVolumeTypePercentEquity);
      m_iprVolumeTypeInput.Initialize(g_chartId, "TdTabSetting_IprVolumeTypeInput");
      m_iprVolumeTypeMoney.Initialize(g_chartId, "TdTabSetting_IprVolumeTypeMoney");
      m_iprVolumeTypePercentBalance.Initialize(
         g_chartId,
         "TdTabSetting_IprVolumeTypePercentBalance"
      );
      m_iprVolumeTypePercentEquity.Initialize(g_chartId, "TdTabSetting_IprVolumeTypePercentEquity");

      m_ipnVolumeValue.Initialize(g_chartId, "TdTabSetting_IpnVolumeValue");
      m_ipcTrailingStopEnable.Initialize(g_chartId, "TdTabSetting_IpcTrailingStopEnable");
      m_ipnTrailingStopStart.Initialize(g_chartId, "TdTabSetting_IpnTrailingStopStart");
      m_ipnTrailingStopStep.Initialize(g_chartId, "TdTabSetting_IpnTrailingStopStep");
      m_ipnTrailingStopDistance.Initialize(g_chartId, "TdTabSetting_IpnTrailingStopDistance");

      m_ObjBtnSubmitName = "TdTabSetting_BTN_SUBMIT";
   }

   static void OnChangeIpRadioVolumeType(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.SetVolumeType((ENUM_VOLUME_TYPE)(int)value);
         double volumeValue = 0;

         if(int(value) == VOLUME_TYPE_INPUT) {
            self.m_ipnVolumeValue.UpdateLabel("Volume risk: Input");
            self.m_ipnVolumeValue.UpdateDisabled(true);
         }
         if(int(value) == VOLUME_TYPE_MONEY) {
            self.m_ipnVolumeValue.UpdateLabel("Volume risk: Money ($)");
            self.m_ipnVolumeValue.UpdateDisabled(false);
         }
         if(int(value) == VOLUME_TYPE_PERCENT_BALANCE) {
            self.m_ipnVolumeValue.UpdateLabel("Volume risk: Percent Balance (%)");
            self.m_ipnVolumeValue.UpdateDisabled(false);
         }
         if(int(value) == VOLUME_TYPE_PERCENT_EQUITY) {
            self.m_ipnVolumeValue.UpdateLabel("Volume risk: Percent Equity (%)");
            self.m_ipnVolumeValue.UpdateDisabled(false);
         }

         if(int(value) == g_volumeType) {
            volumeValue = g_volumeValue;
         }

         self.SetVolumeValue(volumeValue);
         self.m_ipnVolumeValue.UpdateValue(volumeValue);
         ChartRedraw(g_chartId);
      }
   }

   static void OnChangeIpVolumeValue(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.SetVolumeValue(value);
      }
   }

   static void OnChangeTrailingStopEnable(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         if(value == 1) {
            self.m_enableTrailingStop = true;
            self.m_ipnTrailingStopStart.UpdateDisabled(false);
            self.m_ipnTrailingStopStep.UpdateDisabled(false);
            self.m_ipnTrailingStopDistance.UpdateDisabled(false);
         } else {
            self.m_enableTrailingStop = false;
            self.m_ipnTrailingStopStart.UpdateDisabled(true);
            self.m_ipnTrailingStopStep.UpdateDisabled(true);
            self.m_ipnTrailingStopDistance.UpdateDisabled(true);
         }
         self.syncButtonSaveColor();
      }
   }

   static void OnChangeTrailingStopStart(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_tsStartPoints = (int)value;
         self.syncButtonSaveColor();
      }
   }

   static void OnChangeTrailingStopStep(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_tsStepPoints = (int)value;
         self.syncButtonSaveColor();
      }
   }

   static void OnChangeTrailingStopDistance(void *context, UI_EVENT_TYPE eventType, double value) {
      TDTabSetting *self = (TDTabSetting *)context;
      if(eventType == UI_EVENT_CHANGE_VALUE) {
         self.m_tsDistancePoints = (int)value;
         self.syncButtonSaveColor();
      }
   }

   int GetObjectNameList(string &objNameList[]) {
      string irVolumeTypeGroupObjNameList[];
      int    irVolumeTypeGroupObjCount
         = m_irVolumeTypeGroup.GetObjectNameList(irVolumeTypeGroupObjNameList);

      string ipVolumeValueObjNameList[];
      int    ipVolumeValueObjCount = m_ipnVolumeValue.GetObjectNameList(ipVolumeValueObjNameList);

      string ipcTrailingStopEnableObjNameList[];
      int    ipcTrailingStopEnableObjCount
         = m_ipcTrailingStopEnable.GetObjectNameList(ipcTrailingStopEnableObjNameList);
      string ipnTrailingStopStartObjNameList[];
      int    ipnTrailingStopStartObjCount
         = m_ipnTrailingStopStart.GetObjectNameList(ipnTrailingStopStartObjNameList);
      string ipnTrailingStopStepObjNameList[];
      int    ipnTrailingStopStepObjCount
         = m_ipnTrailingStopStep.GetObjectNameList(ipnTrailingStopStepObjNameList);
      string ipnTrailingStopDistanceObjNameList[];
      int    ipnTrailingStopDistanceObjCount
         = m_ipnTrailingStopDistance.GetObjectNameList(ipnTrailingStopDistanceObjNameList);

      ArrayResize(
         objNameList,
         1 + irVolumeTypeGroupObjCount + ipVolumeValueObjCount + ipcTrailingStopEnableObjCount
            + ipnTrailingStopStartObjCount + ipnTrailingStopStepObjCount
            + ipnTrailingStopDistanceObjCount + 1

      );
      int count            = 0;
      objNameList[count++] = m_ObjDescriptionVolumeName;
      for(int i = 0; i < irVolumeTypeGroupObjCount; i++)
         objNameList[count++] = irVolumeTypeGroupObjNameList[i];
      for(int i = 0; i < ipVolumeValueObjCount; i++)
         objNameList[count++] = ipVolumeValueObjNameList[i];
      for(int i = 0; i < ipcTrailingStopEnableObjCount; i++)
         objNameList[count++] = ipcTrailingStopEnableObjNameList[i];
      for(int i = 0; i < ipnTrailingStopStartObjCount; i++)
         objNameList[count++] = ipnTrailingStopStartObjNameList[i];
      for(int i = 0; i < ipnTrailingStopStepObjCount; i++)
         objNameList[count++] = ipnTrailingStopStepObjNameList[i];
      for(int i = 0; i < ipnTrailingStopDistanceObjCount; i++)
         objNameList[count++] = ipnTrailingStopDistanceObjNameList[i];
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
      if(g_volumeType != m_volumeType || g_volumeValue != m_volumeValue
         || g_enableTrailingStop != m_enableTrailingStop || g_tsStartPoints != m_tsStartPoints
         || g_tsStepPoints != m_tsStepPoints || g_tsDistancePoints != m_tsDistancePoints) {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnGreenBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrWhite);
      } else {
         uiCommon.setBackgroundColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBg);
         uiCommon.setBorderColor(g_chartId, m_ObjBtnSubmitName, g_clrBtnDisabledBorder);
         uiCommon.setTextColor(g_chartId, m_ObjBtnSubmitName, clrSlateGray);
      }
   }

   void OpenTab(int x, int y, int width, int height);
   void StartDraw(int x, int y, int width, int height);
   void DestroyDraw();
   void RefreshData();
   void ClickBtnSubmit();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnMQLTesterEvent();
};

void TDTabSetting::OpenTab(int x, int y, int width, int height) {
   m_volumeType         = g_volumeType;
   m_volumeValue        = g_volumeValue;
   m_enableTrailingStop = g_enableTrailingStop;
   m_tsStartPoints      = g_tsStartPoints;
   m_tsStepPoints       = g_tsStepPoints;
   m_tsDistancePoints   = g_tsDistancePoints;

   StartDraw(x, y, width, height);
}

void TDTabSetting::StartDraw(int x, int y, int width, int height) {
   m_x              = x;
   m_y              = y;
   m_width          = width;
   m_height         = height;

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

   m_iprVolumeTypeInput.SetValue(VOLUME_TYPE_INPUT);
   m_iprVolumeTypeInput.SetChecked(m_volumeType == VOLUME_TYPE_INPUT);
   m_iprVolumeTypeInput.StartDraw(m_x + 10, m_y + yOffsetPanel, "Input volume", fontSize);

   m_iprVolumeTypeMoney.SetValue(VOLUME_TYPE_MONEY);
   m_iprVolumeTypeMoney.SetChecked(m_volumeType == VOLUME_TYPE_MONEY);
   m_iprVolumeTypeMoney
      .StartDraw(m_x + 10, m_y + yOffsetPanel + checkboxSize + paddingY, "Money", fontSize);

   m_iprVolumeTypePercentBalance.SetValue(VOLUME_TYPE_PERCENT_BALANCE);
   m_iprVolumeTypePercentBalance.SetChecked(m_volumeType == VOLUME_TYPE_PERCENT_BALANCE);
   m_iprVolumeTypePercentBalance.StartDraw(
      m_x + 10,
      m_y + yOffsetPanel + (checkboxSize + paddingY) * 2,
      "Percent Balance",
      fontSize
   );

   m_iprVolumeTypePercentEquity.SetValue(VOLUME_TYPE_PERCENT_EQUITY);
   m_iprVolumeTypePercentEquity.SetChecked(m_volumeType == VOLUME_TYPE_PERCENT_EQUITY);
   m_iprVolumeTypePercentEquity.StartDraw(
      m_x + 10,
      m_y + yOffsetPanel + (checkboxSize + paddingY) * 3,
      "Percent Equity",
      fontSize
   );

   if(m_volumeType == VOLUME_TYPE_INPUT) {
      m_ipnVolumeValue.SetLabel("Volume risk: Input", clrWhite);
      m_ipnVolumeValue.SetDisabled(true);
   } else if(m_volumeType == VOLUME_TYPE_MONEY) {
      m_ipnVolumeValue.SetLabel("Volume risk: Money ($)", clrWhite);
      m_ipnVolumeValue.SetDisabled(false);
   } else if(m_volumeType == VOLUME_TYPE_PERCENT_BALANCE) {
      m_ipnVolumeValue.SetLabel("Volume risk: Percent Balance (%)", clrWhite);
      m_ipnVolumeValue.SetDisabled(false);
   } else if(m_volumeType == VOLUME_TYPE_PERCENT_EQUITY) {
      m_ipnVolumeValue.SetLabel("Volume risk: Percent Equity (%)", clrWhite);
      m_ipnVolumeValue.SetDisabled(false);
   }

   m_ipnVolumeValue.SetValue(m_volumeValue);
   m_ipnVolumeValue.SetDisabled(m_volumeType == VOLUME_TYPE_INPUT);
   m_ipnVolumeValue.StartDraw(m_x + m_width / 2, m_y + yOffsetPanel, 220, 45);

   yOffsetPanel = yOffsetPanel + (checkboxSize + paddingY) * 4 + 20;

   m_ipcTrailingStopEnable.SetValue(m_enableTrailingStop);
   m_ipcTrailingStopEnable.SetLabel("2. Enable Trailing Stop", clrWhite);
   m_ipcTrailingStopEnable.StartDraw(m_x + 10, m_y + yOffsetPanel, fontSize);

   yOffsetPanel = yOffsetPanel + 20;

   // Tạo ô nhập Trailing Stop Start
   m_ipnTrailingStopStart.SetLabel("TS Start (Points):", clrWhite);
   m_ipnTrailingStopStart.SetValue(m_tsStartPoints);
   m_ipnTrailingStopStart.SetStep(10);
   m_ipnTrailingStopStart.SetDigits(0);
   m_ipnTrailingStopStart.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipnTrailingStopStart.SetDisabled(false);
   } else {
      m_ipnTrailingStopStart.SetDisabled(true);
   }
   m_ipnTrailingStopStart.StartDraw(m_x + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập Trailing Stop Step
   m_ipnTrailingStopStep.SetLabel("TS Step (Points):", clrWhite);
   m_ipnTrailingStopStep.SetValue(m_tsStepPoints);
   m_ipnTrailingStopStep.SetStep(10);
   m_ipnTrailingStopStep.SetDigits(0);
   m_ipnTrailingStopStep.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipnTrailingStopStep.SetDisabled(false);
   } else {
      m_ipnTrailingStopStep.SetDisabled(true);
   }
   m_ipnTrailingStopStep
      .StartDraw(m_x + (m_width - 10) / 3 + 10, m_y + yOffsetPanel, (m_width - 10) / 3 - 10, 45);

   // Tạo ô nhập Trailing Stop Distance

   m_ipnTrailingStopDistance.SetLabel("TS Distance (Points):", clrWhite);
   m_ipnTrailingStopDistance.SetValue(m_tsDistancePoints);
   m_ipnTrailingStopDistance.SetStep(10);
   m_ipnTrailingStopDistance.SetDigits(0);
   m_ipnTrailingStopDistance.SetMinValue(0);
   if(m_enableTrailingStop) {
      m_ipnTrailingStopDistance.SetDisabled(false);
   } else {
      m_ipnTrailingStopDistance.SetDisabled(true);
   }
   m_ipnTrailingStopDistance.StartDraw(
      m_x + 2 * (m_width - 10) / 3 + 10,
      m_y + yOffsetPanel,
      (m_width - 10) / 3 - 10,
      45
   );

   yOffsetPanel = yOffsetPanel + 65;

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
   g_volumeValue = m_ipnVolumeValue.GetValue();
   changeVolumeRisk();

   Sleep(100);
   ObjectSetInteger(g_chartId, m_ObjBtnSubmitName, OBJPROP_STATE, false);
   syncButtonSaveColor();
}

void TDTabSetting::OnChartEvent(
   const int id, const long &lparam, const double &dparam, const string &sparam
) {
   m_irVolumeTypeGroup.OnChartEvent(id, lparam, dparam, sparam);
   m_ipnVolumeValue.OnChartEvent(id, lparam, dparam, sparam);
   m_ipcTrailingStopEnable.OnChartEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopStart.OnChartEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopStep.OnChartEvent(id, lparam, dparam, sparam);
   m_ipnTrailingStopDistance.OnChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_ObjBtnSubmitName) {
         ClickBtnSubmit();
      }
   }
}

void TDTabSetting::OnMQLTesterEvent() {
   m_irVolumeTypeGroup.OnMQLTesterEvent();
   m_ipnVolumeValue.OnMQLTesterEvent();
   m_ipcTrailingStopEnable.OnMQLTesterEvent();
   m_ipnTrailingStopStart.OnMQLTesterEvent();
   m_ipnTrailingStopStep.OnMQLTesterEvent();
   m_ipnTrailingStopDistance.OnMQLTesterEvent();

   if(uiCommon.getState(g_chartId, m_ObjBtnSubmitName)) {
      ClickBtnSubmit();
   }
}
