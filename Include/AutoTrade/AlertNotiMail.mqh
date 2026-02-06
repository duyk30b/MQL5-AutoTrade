input string Message = "";
input bool Send_Alert = false ;
input bool Send_Notification = false ;
input bool Send_Mail = false ;

void SendAlertNotiMail(string iMessage)
{
   if(Send_Alert) Alert(iMessage);
   if(Send_Notification) SendNotification(iMessage);
   if(Send_Mail) SendMail(iMessage , iMessage);
}
