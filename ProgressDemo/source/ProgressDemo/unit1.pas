unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,IntfGraphics, ComCtrls, FPimage{$IFDEF linux}  ,fileutil,dbus,libnotify,ctypes {$ENDIF}
  {$IFDEF WINDOWS} ,win32taskbarprogress  {$ENDIF};

type

  { TForm1 }

  TForm1 = class(TForm)
    btnRed: TButton;
    btnStart: TButton;
    btnStop: TButton;
    btnNotify: TButton;
    btnGreen: TButton;
    btnRemoveIcon: TButton;
    chkNotify: TCheckBox;
    chkNotifySend: TCheckBox;
    edtStartValue: TEdit;
    edtProgress: TEdit;
    GroupBox1: TGroupBox;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    pb: TProgressBar;
    rg1: TRadioGroup;
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;

    procedure btnRedClick(Sender: TObject);
    procedure btnNotifyClick(Sender: TObject);
    procedure btnRemoveIconClick(Sender: TObject);
    {$IFDEF linux}
    Procedure SendProgress(progr_val:double;count_val:Int64);
    Procedure DBusConnection();
    {$ENDIF}
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnGreenClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  //globale Variablen für die dbus-Kommunikation unter Linux
  {$IFDEF linux}
  conn: PDBusConnection;
  msg: PDBusMessage;
  args: DBusMessageIter;
  err: DBusError;
 {$ENDIF}
 //globale Variablen für Zähler und Fortschritt
  counter:integer;
  Step:double;
  Progress:double;
implementation

{$R *.lfm}

{ TForm1 }
// Die folgenden beiden Unterpropgramm dienen unter Linux
// der Kommunikation mit dem Dbus.
// Damit lässt sich ein Zähler oder ein Fortschrittsbalken
// über dem Dock-Icon (Gnome) oder der Taskbar-Schaltfläche (KDE) darstellen.
// Das funktioniert nur, wenn eine passende .desktop-Datei vorhanden ist.
{$IFDEF linux}
procedure TForm1.DBusConnection();
var
 ret: cint;
begin
  dbus_error_init(@err);
  { Connection }
  conn := dbus_bus_get(DBUS_BUS_SESSION, @err);

  if dbus_error_is_set(@err) <> 0 then
  begin
    ShowMessage('Connection Error: ' + err.message);
    dbus_error_free(@err);
  end;
  if conn = nil then
    begin
      ShowMessage('conn = nil');
      Exit;
    end;
 
  ret := dbus_bus_request_name(conn, 'com.canonical.Unity.LauncherEntry', DBUS_NAME_FLAG_REPLACE_EXISTING, @err);

  if dbus_error_is_set(@err) <> 0 then
  begin
    ShowMessage('Name Error: ' + err.message);
    dbus_error_free(@err);
  end;
  //sollte nihct passieren;-)
  if ret <> DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER then
  begin
    //ShowMessage('NOT DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER');
    //Exit;
  end;
end;
{$ENDIF}

{$IFDEF linux}
procedure TForm1.SendProgress(progr_val: double;count_val:Int64);
var
        b_val: dword;
        sub1, sub2: DBusMessageIter;
        sub3: DBusMessageIter;
        Property_: PChar;
        serial: dbus_uint32_t = 0;
begin
  // Signal erstellen und Fehler prüfen
  // Der Programmname muss hier hinterlegt sein.
   msg := dbus_message_new_signal('/de/ProgressDemo', // object name of the signal
                                  'com.canonical.Unity.LauncherEntry', // interface name of the signal
                                  'Update'); // name of the signal
   if (msg = nil) then
   begin
     ShowMessage('Message Null');
     Exit;
   end;
   dbus_message_iter_init_append(msg, @args);
   property_:='application://ProgressDemo.desktop';
   dbus_message_iter_append_basic(@args, DBUS_TYPE_STRING, @property_);
   dbus_message_iter_open_container(@args, DBUS_TYPE_ARRAY, '{sv}', @sub1);
   dbus_message_iter_open_container(@sub1, DBUS_TYPE_DICT_ENTRY, nil, @sub2);
  //nicht sichtbar / Zähler ausblenden
  if count_val=-1 then
  begin
  property_ := 'count-visible';
  b_val := 0; // 1 - visible, 0 - not visible
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'b', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_BOOLEAN, @b_val);
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);
  dbus_message_iter_close_container(@args, @sub1);
  end;
  //nicht sichtbar / Fortschrittsbalken ausblenden
  if progr_val=-1 then
  begin
  property_ := 'progress-visible';
  b_val := 0; // 1 - visible, 0 - not visible
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'b', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_BOOLEAN, @b_val);
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);
  dbus_message_iter_close_container(@args, @sub1);
  end;

  // Zähler anzeigen
  if count_val > 0 Then
  begin
  property_ := 'count-visible';
  b_val := 1; // 1 - visible, 0 - not visible
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'b', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_BOOLEAN, @b_val);
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);

  dbus_message_iter_open_container(@sub1, DBUS_TYPE_DICT_ENTRY, nil, @sub2);
  property_ := 'count';
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'x', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_INT64, @count_val);
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);
  dbus_message_iter_close_container(@args, @sub1);
  end;
  //Progressbar anzeigen
  if progr_val > 0 Then
   begin
  property_ := 'progress-visible';
  b_val := 1; // 1 - visible, 0 - not visible
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'b', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_BOOLEAN, @b_val);
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);
  //
  dbus_message_iter_open_container(@sub1, DBUS_TYPE_DICT_ENTRY, nil, @sub2);
  property_ := 'progress';
  dbus_message_iter_append_basic(@sub2, DBUS_TYPE_STRING, @property_);
  dbus_message_iter_open_container(@sub2, DBUS_TYPE_VARIANT, 'd', @sub3);
  dbus_message_iter_append_basic(@sub3, DBUS_TYPE_DOUBLE, @progr_val);
  //
  dbus_message_iter_close_container(@sub2, @sub3);
  dbus_message_iter_close_container(@sub1, @sub2);
  dbus_message_iter_close_container(@args, @sub1);
  end;
  // Nachricht senden
  if (dbus_connection_send(conn, msg, @serial) = 0) then
  begin
    ShowMessage('Out Of Memory, connection send!');
    Exit;
  end;

  dbus_connection_flush(conn);
  // Nachricht deinitialisieren
  dbus_message_unref(msg);
end;
{$ENDIF}
// Hier startet der Zähler
procedure TForm1.btnStartClick(Sender: TObject);
begin
  Counter:=StrToInt(edtStartValue.Text);
  {$IFDEF WINDOWS}
  GlobalTaskbarProgress.Icon:=nil;
  {$ENDIF}
  Progress:=0;
  pb.Max:=Counter;
  pb.Position:=0;
  pb.Visible:=True;
  Step:=1/Counter;
  Timer1.Interval:=1000;
  Timer1.Enabled:=True
end;

//Beispiel-Benachrichtigung senden
procedure TForm1.btnNotifyClick(Sender: TObject);
{$IFDEF linux}
var
  hello : PNotifyNotification;
  {$ENDIF}
begin
  {$IFDEF WINDOWS}
   TrayIcon1.Icon.Assign(Application.Icon);
   TrayIcon1.Visible:=True;
   TrayIcon1.BalloonTitle:='Hello world';
   TrayIcon1.BalloonFlags:= bfInfo;
   TrayIcon1.BalloonHint:='Dies ist eine Beispielbenachrichtigung.';
   TrayIcon1.BalloonTimeout:=600;
   TrayIcon1.ShowBalloonHint;
  {$ENDIF}
{$IFDEF linux}
if chkNotifySend.Checked then
// -t 4000, Benachrichtung 4 Sekunden anzeigen, danach ausblenden
 Sysutils.ExecuteProcess(FindDefaultExecutablePath('notify-send'), '-t 4000 "Hello world" "Dies ist eine Beispielbenachrichtigung."')
else
begin
notify_init(argv[0]);
hello := notify_notification_new ('Hello world', 'Dies ist eine Beispielbenachrichtigung.', 'dialog-information');
notify_notification_set_timeout(hello,4);
notify_notification_show (hello, nil);
end;
{$ENDIF}
end;
// Die Ausführung des Zählers/Timers beenden
procedure TForm1.btnStopClick(Sender: TObject);
begin
  pb.Visible:=False;
  Timer1.Enabled:=False;
  {$IFDEF linux}
  If rg1.ItemIndex=0 Then
   SendProgress(0,-1) //Zähler ausblenden
  else
   begin
     SendProgress(-1,0); //Fortschrittsbalken ausblenden
   end;
   {$ENDIF}
end;
//Beim Beenden des Programms Dbus-Verbindung beenden
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  {$IFDEF linux}
  dbus_connection_unref(conn);
  {$ENDIF}
end;
//
procedure TForm1.FormCreate(Sender: TObject);
begin
   Timer1.Enabled:=False; //nur zur Sicherheit
   {$IFDEF linux}
   DBusConnection(); //Dbus-Verbindung herstellen
   btnGreen.Enabled:=False; //Windows-Funktionen ausgrauen
   btnRed.Enabled:=False;
   btnRemoveIcon.Enabled:=False;
   {$ENDIF}
   //Elememente nur für Windows
   {$IFDEF WINDOWS}
   GlobalTaskbarProgress:= TWin7TaskProgressBar.Create;
   GlobalTaskbarProgress.Style:=TTaskBarProgressStyle(tbpsNormal);
   btnGreen.Enabled:=True;
   btnRed.Enabled:=True;
   btnRemoveIcon.Enabled:=True;
   chkNotifySend.Enabled:=False;
   {$ENDIF}
end;
// Timer für die Zählerfunktionen
procedure TForm1.Timer1Timer(Sender: TObject);
{$IFDEF linux}
var
  hello : PNotifyNotification;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
    If Counter=0 Then
     begin
    Timer1.Enabled:=False;
    Application.Title:='Progress-Demo';
    GlobalTaskbarProgress.Progress:=0;
    pb.Visible:=False;
     if chkNotify.Checked Then
       begin
        TrayIcon1.Icon.Assign(Application.Icon);
        TrayIcon1.Visible:=True;
        TrayIcon1.BalloonTitle:='Progress-Demo';
        TrayIcon1.BalloonFlags:= bfInfo;
        TrayIcon1.BalloonHint:='Zähler beendet.';
        TrayIcon1.BalloonTimeout:=600;
        TrayIcon1.ShowBalloonHint;
       end;
     Exit;
     end;
   If Counter>0 then
    begin
     If rg1.ItemIndex=1 Then
     begin
      Progress:=Progress + Step * 100;
      edtProgress.Text:=FloatToStr(Progress);
      GlobalTaskbarProgress.Progress:=Trunc(Progress);
      pb.Position:=Counter;
     end;
     If rg1.ItemIndex=0 Then
     begin
      Application.Title:=IntToStr(Counter);
      pb.Position:=Counter;
     end;
    end;
  // Counter herunterzählen
  dec(Counter);
  {$ENDIF}

  {$IFDEF linux}
  //Counter ist "0", Timer beenden
  If Counter=0 Then
   begin
    Timer1.Enabled:=False;
    Application.Title:='Progress-Demo';
    Form1.Caption:='Progress-Demo';
     If rg1.ItemIndex=0 Then
      begin
      SendProgress(0,-1);
      pb.Position:=StrToInt(edtStartValue.Text);
      pb.Visible:=False;
      end
     else
      begin
        edtProgress.Text:='1';
        SendProgress(-1,0);
        pb.Position:=StrToInt(edtStartValue.Text);
        pb.Visible:=False;
      end;
      if chkNotify.Checked Then
       begin
         if chkNotifySend.Checked then
          // -t 4000, Benachrichtung 4 Sekunden anzeigen, danach ausblenden
           Sysutils.ExecuteProcess(FindDefaultExecutablePath('notify-send'), '-t 4000 "Progress-Demo" "Zähler beendet."')
         else
          begin
           notify_init(argv[0]);
           hello := notify_notification_new ('Progress-Demo', 'Zähler beendet.', 'dialog-information');
           notify_notification_set_timeout(hello,4);
           notify_notification_show (hello, nil);
          end;
    end;
        Exit;

   end;

  // Fortschritt anzeigen
  If Counter>0 Then
   begin
  If rg1.ItemIndex=0 Then //numerisch
  begin
   SendProgress(0,Counter);

   edtProgress.Text:=IntToStr(Counter);
   pb.Position:=Counter;
  end
  else
  begin
    Progress:=Progress + Step; //Fortschrittsbalken
    SendProgress(Progress,0);
    // Zusätzlich den Counter statt des Programmnamens anzeigen
    Application.Title:=IntToStr(Counter);
    Form1.Caption:=IntToStr(Counter);
    edtProgress.Text:=FloatToStr(Progress);
    pb.Position:=Trunc(1+(Progress*10));
  end;
   Application.ProcessMessages;

  end;

  dec(Counter); //Counter herunterzählen

    {$ENDIF}
end;
// grünes Icon in der Windows-Taskleiste anzeigen
procedure TForm1.btnGreenClick(Sender: TObject);
{$IFDEF WINDOWS}
var
  IC:TIcon;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  IC:=TIcon.Create;
  ImageList1.GetIcon(0,IC);
  GlobalTaskbarProgress.Icon:=IC;
  IC.Free;
  {$ENDIF}
end;
// rotes Icon in der Windows-Taskleiste anzeigen
procedure TForm1.btnRedClick(Sender: TObject);
{$IFDEF WINDOWS}
var
    IC:TIcon;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
    IC:=TIcon.Create;
    ImageList1.GetIcon(1,IC);
    GlobalTaskbarProgress.Icon:=IC;
    IC.Free;
  {$ENDIF}
end;

// Das Icon von der Windows-Taskleiste entfernen
procedure TForm1.btnRemoveIconClick(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  GlobalTaskbarProgress.Icon:=nil;
  {$ENDIF}
end;
end.

