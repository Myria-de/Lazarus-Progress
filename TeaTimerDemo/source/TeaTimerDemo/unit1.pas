unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTIGrids, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, PopupNotifier, Spin, EditBtn, LCLType,
  IniPropStorage, Menus
  {$IFDEF linux}  ,ctypes,dbus,libnotify {$ENDIF}{$IFDEF windows}, win32taskbarprogress, MMSystem{$endif};

type
  { TForm1 }
  TForm1 = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    chkNotifySend: TCheckBox;
    chkInfinite: TCheckBox;
    chkFormZeigen: TCheckBox;
    chkNotify: TCheckBox;
    chkSysTray: TCheckBox;
    chkAudio: TCheckBox;
    chkPopup: TCheckBox;
    edtTimeout: TEdit;
    edtMeldung: TEdit;
    edtAudioFile: TFileNameEdit;
    GroupBox1: TGroupBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblStunden: TLabel;
    lblSekunden: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblMinuten: TLabel;
    Label5: TLabel;
    OpenDialog1: TOpenDialog;
    PopupNotifier1: TPopupNotifier;
    rg1: TRadioGroup;
    spnAudio: TSpinEdit;
    spnSekunden: TSpinEdit;
    spnMinuten: TSpinEdit;
    spnStunden: TSpinEdit;
    Timer1: TTimer;
    tmrPlayAudio: TTimer;
    tmrNotify: TTimer;
    TrayIcon1: TTrayIcon;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Timer1StopTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure tmrNotifyTimer(Sender: TObject);
    procedure tmrPlayAudioTimer(Sender: TObject);
    {$IFDEF linux}
    Procedure SendProgress(progr_val:double;count_val:Int64);
    Procedure DBusConnection();
    Procedure SendNotification();
    {$ENDIF}
  private
    { private declarations }

  public
    { public declarations }

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
  //Die globale Variable Counter enthält die Anzahl der eingestellten Sekunden.
  //Sie wird vom Timer jeweils um den Wert "1" heruntergezählt.
  //Ist Sie "0", ist die eingestellte Zeit abgelaufen und die Benachrichtigung wird angezeigt.
    counter: integer;
    ProgressStep: real;
    ProgressValue: real;
    AudioCounter: integer;
    //Die folgende globale Variable wird auf "True" gesetzt,
    //wenn der Benutzer auf "Stop" klickt.
    //Die Benachrichtigung beim Ablauf des Timers wird dann nicht abgezeigt
    //(siehe "procedure TForm1.Timer1StopTimer").
    FWantStop: boolean;

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
   msg := dbus_message_new_signal('/de/TeaTimerDemo', // object name of the signal
                                  'com.canonical.Unity.LauncherEntry', // interface name of the signal
                                  'Update'); // name of the signal
   if (msg = nil) then
   begin
     ShowMessage('Message Null');
     Exit;
   end;
   dbus_message_iter_init_append(msg, @args);
   property_:='application://TeaTimerDemo.desktop';
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

  // Counter anzeigen
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
  if progr_val >0 Then
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

// Timer starten
procedure TForm1.btnStartClick(Sender: TObject);
begin
  FWantStop := False;
  ProgressValue := 0;
  Counter := spnSekunden.Value + spnMinuten.Value * 60 + spnStunden.Value * 60 * 60;
  if Counter = 0 then
  begin
    ShowMessage('Sie müssen eine Zeit einstellen.');
    Exit;
  end;
  {$IFDEF windows}
  ProgressStep:=100/Counter;
  {$ENDIF}
  {$IFDEF linux}

  ProgressStep:=1/Counter;
  {$ENDIF}
  if chkSysTray.Checked then
  begin
    Form1.WindowState := wsMinimized;
  end;
  PopupNotifier1.Visible := False;
  Timer1.Interval := 1000;
  Timer1.Enabled := True;
end;

//Timer stoppen
procedure TForm1.btnStopClick(Sender: TObject);
begin
  // Vorgang abbrechen
  FWantStop := True;
  Timer1.Enabled := False;
  tmrPlayAudio.Enabled := False;
  {$IFDEF windows}
  GlobalTaskbarProgress.Progress:=0;
  Application.Title:='Tea-Timer-Demo';
  {$ENDIF}
  {$IFDEF linux}
  Application.Title:='Tea-Timer-Demo';
  Form1.Caption:='Tea-Timer-Demo';
  if rg1.ItemIndex=1
  then
   SendProgress(0,-1)
  else
  begin
   //SendProgress(1,0);
   SendProgress(-1,0);
  end;
  {$ENDIF}
end;

//Beim Beenden des Programms Timer stoppen, aufräumen
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Timer1.Enabled := False;
  tmrPlayAudio.Enabled := False;
  tmrNotify.Enabled:=False;
  // Mit Create erstellte Objekte freigeben
  {$IFDEF windows}
  GlobalTaskbarProgress.Free;
  {$ENDIF}
  {$IFDEF linux}
  dbus_connection_unref(conn);
  {$ENDIF}
end;

procedure TForm1.FormCreate(Sender: TObject);
//Wird beim Start des Programms ausgeführt
begin
  {$IFDEF linux}
  DBusConnection();
  {$ENDIF}
  {$IFDEF windows}
  GlobalTaskbarProgress:= TWin7TaskProgressBar.Create;
  GlobalTaskbarProgress.Style:=TTaskBarProgressStyle(tbpsNormal);
  chkNotifySend.Enabled:=False;
  {$ENDIF}
end;

//Dieser Event wird beim Stoppen des Timers ausgelöst
procedure TForm1.Timer1StopTimer(Sender: TObject);
begin
  if not FWantStop then
  begin
    if chkFormZeigen.Checked then
    begin
      //Programmfenster wieder anzeigen
      Form1.WindowState := wsNormal;
      Form1.Show;
    end;

    Application.Title:='Tea-Timer-Demo';
    Form1.Caption:='Tea-Timer-Demo';

   {$IFDEF windows}
    GlobalTaskbarProgress.Progress:=0;
    {$ENDIF}
    if edtMeldung.Text <> '' then PopupNotifier1.Text := edtMeldung.Text;
    //Popup-Fenster mit der Benachrichtigung anzeigen
    if chkPopup.Checked then
    begin
      PopupNotifier1.ShowAtPos(Screen.Width - 150, Screen.Height - 50);
    end;
    //Sound abspielen
    if chkAudio.Checked and FileExists(edtAudioFile.FileName) then
    begin
      if (spnAudio.Value <> 0) or (chkInfinite.Checked) then
      begin
        AudioCounter := spnAudio.Value;
        tmrPlayAudio.Interval := 500;
        tmrPlayAudio.Enabled := True;
      end
      else;
      {$IFDEF linux}
       //dieser Code wird nur unter Linux ausgeführt
       Sysutils.ExecuteProcess(FindDefaultExecutablePath('paplay'), edtAudioFile.FileName);
      {$ENDIF}
      {$IFDEF windows}
      //dieser Code wird nur unter Windows ausgeführt
       sndPlaySound(PChar(edtAudioFile.FileName),SND_NODEFAULT Or SND_ASYNC);
      {$ENDIF}
    end;
    {$IFDEF linux}
     //Fortschittsanzeige ausblenden
     if rg1.ItemIndex=1 //numerisch
      then
        SendProgress(0,-1)
      else
      begin
       SendProgress(-1,0); //Fortschrittsbalken
      end;
   tmrNotify.Enabled:=True;
    {$endif}
    {$IFDEF windows}
    if chkNotify.Checked Then
    begin
    TrayIcon1.Icon.Assign(Application.Icon);
    TrayIcon1.Visible:=True;
    TrayIcon1.BalloonTitle:='Tea-Timer-Demo';
    TrayIcon1.BalloonFlags:= bfInfo;
    TrayIcon1.BalloonHint:=edtMeldung.Text;
    TrayIcon1.BalloonTimeout:=600;
    TrayIcon1.ShowBalloonHint;
    end;
    {$endif}
  end;
end;

procedure TForm1.tmrNotifyTimer(Sender: TObject);
begin
  {$IFDEF linux}
     SendNotification;
     tmrNotify.Enabled:=False;
  {$endif}
end;

//Dieser Event wird vom Timer so oft ausgelöst,
//wie in der Eigenschaft "Interval" festgelegt wurde.
//Für den TeaTimer einmal in der Sekunde.
procedure TForm1.Timer1Timer(Sender: TObject);
var
  SS, MM, HH: string;
  intSS, intMM, intHH: integer;
begin


  //Stunden, Minuten und Sekunden für die Anzeige berechnen
  intHH := Trunc(Counter / 60 / 60);
  intMM := Trunc((Counter - intHH * 60 * 60) / 60);
  intSS := Trunc(Counter - intMM * 60 - intHH * 60 * 60);

  SS := IntToStr(intSS);
  MM := IntToStr(intMM);
  HH := IntToStr(intHH);
  //Aus optischen Gründen wird hier bei Bedarf eine "0"
  //vor die Zeitangabe gesetzt
  if Length(SS) = 1 then SS := '0' + SS;
  if Length(MM) = 1 then MM := '0' + MM;
  if Length(HH) = 1 then HH := '0' + HH;

  {$IFDEF linux}
  // Fortschrittsanzeige
  if Counter > 0 then
  begin
  if rg1.ItemIndex=0 then //Fortschrittsbalken
    begin
    ProgressValue:= ProgressValue + ProgressStep;
    SendProgress(ProgressValue,0);
    end
  else    //numerisch
   begin
    SendProgress(0,Counter);
    Application.Title:=IntToStr(Counter);
    Form1.Caption:=IntToStr(Counter);
  end;
  end;

  {$ENDIF}
  {$IFDEF windows}
  // Fortschrittsanzeige
  if rg1.ItemIndex=0 then //Fortschrittsbalken
    begin
     ProgressValue:= ProgressValue + ProgressStep;
     GlobalTaskbarProgress.Progress:=Trunc(ProgressValue);
   end
   else
   begin
    //Zähler statt Programmname in der Taskleiste anzeigen
   Application.Title:=IntToStr(Counter);
   Form1.Caption:=IntToStr(Counter);
   end;
  {$ENDIF}

  //Hier wird den Labels die Beschriftung zugewiesen
  lblSekunden.Caption := SS;
  lblMinuten.Caption := MM;
  lblStunden.Caption := HH;

    //Wenn der Counter auf "0" steht, ist die Zeit abgelaufen
  //Der Timer wird abgeschaltet und der OnStopTimer-Event ausgelöst
   if Counter = 0 then
  begin
    Timer1.Enabled := False;
    Exit; //Unterprogramm verlassen, es gibt nichts mehr zu tun
  end;
   //Integer-Variable Counter um 1 herunterzählen
   Dec(Counter);
end;

{$IFDEF linux}
// Benachrichtigung über die Notify-API (libnotify) senden
// Alternativ mit dem Kommandozeilentool notify-send
procedure TForm1.SendNotification();
var
    hello : PNotifyNotification;
    Timeout:Integer;
begin
if chkNotify.Checked Then
begin
  if chkNotifySend.Checked Then
  begin
  if edtTimeOut.text <> '' then
   begin
    if TryStrToInt(Trim(edtTimeOut.text),Timeout) then
    begin
     Timeout:=StrToInt(Trim(edtTimeOut.text))*1000;
     Sysutils.ExecuteProcess(FindDefaultExecutablePath('notify-send'), '-t ' + IntToStr(Timeout) + ' "Tea-Timer-Demo" ' + Chr(34) + edtMeldung.Text +Chr(34));
    end;
   end
  else
  begin
  Sysutils.ExecuteProcess(FindDefaultExecutablePath('notify-send'), '-t 1000 "Tea-Timer-Demo" ' + Chr(34) + edtMeldung.Text + Chr(34));
  end;
  end
  else
  begin
   notify_init(argv[0]);
   hello := notify_notification_new ('Tea-Timer-Demo', Pchar(edtMeldung.Text), 'dialog-information');
   if edtTimeOut.text <> '' then
    begin
     if TryStrToInt(Trim(edtTimeOut.text),Timeout) then
      begin
       Timeout:=StrToInt(Trim(edtTimeOut.text));
       notify_notification_set_timeout(hello,Timeout);
      end;
    end;
   notify_notification_set_urgency(hello,1);
   notify_notification_show (hello, nil);
  end;
end;
end;
{$endif}
// Audio abspielen
procedure TForm1.tmrPlayAudioTimer(Sender: TObject);
begin
  if chkAudio.Checked and FileExists(edtAudioFile.FileName) then
  begin
    tmrPlayAudio.Interval := 2000;
    if not chkInfinite.Checked then
      Dec(AudioCounter);
    {$IFDEF linux}
    Sysutils.ExecuteProcess(FindDefaultExecutablePath('paplay'), edtAudioFile.FileName);
    {$ENDIF}
    {$IFDEF windows}
    sndPlaySound(PChar(edtAudioFile.FileName),SND_NODEFAULT Or SND_ASYNC);
    {$ENDIF}
    Application.ProcessMessages;
    if AudioCounter = 0 then
      tmrPlayAudio.Enabled := False;
  end;
end;

end.
