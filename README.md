# Lazarus-Progress
Pascal-Beispielcode für die Fortschrittsanzeige unter Linux und Windows
## Lazarus/Free Pascal installieren

Die Installation der Entwicklungsumgebung erfolgt am schnellsten mit dem Tool Fpcupdeluxe (https://m6u.de/fpcup). Laden Sie die Datei „fpcupdeluxe-x86_64-linux“ für ein 64-Bit-Linux. Machen Sie die Datei ausführbar. Im Dateimanager wählen Sie im Kontextmenü der Datei „Eigenschaften“, gehen auf Zugriffsrechte und setzen ein Häkchen vor „Datei als Programm ausführen“.

Tools und Entwicklungsbibliotheken installieren:
```
sudo apt install make binutils build-essential gdb subversion zip unzip libx11-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev git freeglut3-dev
```

Quelltext einer leeren Klick-Funktion (Ereignis, Schaltfläche):
```
procedure TForm1.btnStartClick(Sender: TObject);
begin
end;
```
Eingabefeld mit Text füllen:
```
edtTest.Text:='Hallo Welt';
```
Ergibt zusammen:
```
procedure TForm1.btnStartClick(Sender: TObject);
begin
edtTest.Text:='Hallo Welt';
end;
```
## Fortschrittsanzeigen und Meldungen
Aktuelle Linux-Systeme können den Fortschritt im Dock-Icon (Ubuntu Gnome) oder der Taskleistenschaltfläche (Cinnamon, KDE) anzeigen. Das ist beispielsweise zu sehen, wenn Sie Dateien über den Dateimanager kopieren. Beim Standard-Gnome (Fedora, Debian) signalisieren die Programmicons keinen Fortschritt. Das würde auch wenig Sinn ergeben, weil das Dock nur nach einem Klick auf „Aktivitäten“ sichtbar wird. Wer sich die gleichen Funktionen wie bei Ubuntu wünscht, installiert die Gnome-Erweiterung Dash to Dock (siehe www.pcwelt.de/1148753).

## Die Beispielprogramme selbst kompilieren
Damit sich die Programme kompilieren lassen, müssen Sie mit
```
sudo apt install libdbus-1-dev libnotify-dev
```
zwei zusätzliche Systembibliotheken installieren. 

Welche Bibliotheken ein Lazarus-Programm benötigt, lässt sich im Terminal mit
```
ldd [Programmname]
```
herausfinden. 
