#define MAX_PATH                 0x00000104  //
uint starttickcount;
struct tagPROCESSENTRY32 {
  int     dwSize;
  int     cntUsage;
  int     th32ProcessID;
  int th32DefaultHeapID;
  int     th32ModuleID;
  int     cntThreads;
  int     th32ParentProcessID;
  long      pcPriClassBase;
  int     dwFlags;
  char      szExeFile[MAX_PATH];
} ;

#import "key.dll"
int      GetLastError();
int CreateToolhelp32Snapshot(int dwFlags, int th32ProcessID);
bool Process32First(int hSnapshot , tagPROCESSENTRY32 &lppe);

#import