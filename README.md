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
![408_02_Obji](https://github.com/user-attachments/assets/e4baa4bc-e8cd-4d68-b2ae-6e71f989bc25)
## Fortschrittsanzeigen und Meldungen
Aktuelle Linux-Systeme können den Fortschritt im Dock-Icon (Ubuntu Gnome) oder der Taskleistenschaltfläche (Cinnamon, KDE) anzeigen. Das ist beispielsweise zu sehen, wenn Sie Dateien über den Dateimanager kopieren. Beim Standard-Gnome (Fedora, Debian) signalisieren die Programmicons keinen Fortschritt. Das würde auch wenig Sinn ergeben, weil das Dock nur nach einem Klick auf „Aktivitäten“ sichtbar wird. Wer sich die gleichen Funktionen wie bei Ubuntu wünscht, installiert die Gnome-Erweiterung Dash to Dock (siehe www.pcwelt.de/1148753).
## Beispielprogramm für Fortschrittsanzeigen
Klicken Sie auf „Code“ und danach auf „Download ZIP“. Entpacken Sie aus dem Archiv die Ordner „ProgressDemo“ und „TeaTimerDemo“ in den Lazarus-Projektordner „~/fpcupdeluxe/projects“. Starten Sie das Script „install.sh“ aus dem Ordner „ProgressDemo/install“. Es erzeugt den Programmstarter „ProgressDemo.desktop“ im Ordner „.local/share/applications“, die Pfadangaben darin verweisen auf den Installationsordner. Die „.desktop“-Datei ist zwingende Voraussetzung dafür, dass der Desktop den Fortschritt anzeigt.

Starten Sie das Programm „ProgressDemo“ und klicken Sie auf „Start“. Das Programmicon im Dock beziehungsweise die Taskleistenschaltfläche zeigen den jeweiligen Wert des Zählers. Wenn Sie die Option „Fortschrittsanzeige“ wählen, erscheint ein Fortschrittsbalken. Setzen Sie ein Häkchen vor „Benachrichtigung am Ende“ für eine Systemmeldung nach Abschluss des Zählvorgangs. Bei Ubuntu 24.04 zeigt das Icon danach eine „1“, die eine ungelesene Benachrichtigung symbolisiert. Sollte das nicht erwünscht sein, setzen Sie ein Häkchen vor „notify-send benutzen“. Das Programm verwendet dann das Kommandozeilentool notify-send und die „1“ wird nicht angezeigt.

Unter Windows kann man über die Schaltflächen unter „Nur Windows“ einen grünen oder roten Kreis über die Taskleistenschaltfläche legen, der einen bestimmten Status signalisieren kann. Bei Auswahl von „Numerischer Wert“ ersetzt ProgessDemo einfach den Programmtitel durch den Wert des Zählers. Der ist auf der Schaltfläche aber nur sichtbar, wenn die Taskleiste für die Anzeige von Beschriftungen konfiguriert ist.
![408_05_ProgressDemo](https://github.com/user-attachments/assets/3316c2d7-0723-4bd4-9cef-488cc261bf0c)
![408_03_Leisten](https://github.com/user-attachments/assets/576018c5-c19c-46b9-bbf0-92f6aeb5083e)
## Ein Timer als nützliche Anwendung
Den praktischen Einsatz von Fortschrittsanzeigen demonstriert das Programm TeaTimerDemo. Starten Sie das Script „install.sh“ aus dem Ordner „TeaTimerDemo/install“, um eine „.desktop-Datei“ zu erzeugen.
Stellen Sie eine Zeit unter „Stunden“, „Minuten“ und/oder „Sekunden“ ein. Nach einem Klick auf „Start“ beginnt der Countdown. Abhängig von der Auswahl unter „Fortschrittsanzeige“ ist auf dem Bildschirm eine numerische Anzeige in Sekunden oder ein Fortschrittsbalken zu sehen.

Das Ende des Countdowns lässt sich akustisch signalisieren, indem Sie ein Häkchen vor „Audio-Benachrichtigung“ setzen und darunter eine Audiodatei angeben. „Fenster für Benachrichtigung anzeigen“ blendet nach Ablauf ein Fenster mit dem unter „Meldungstext“ eingetragenen Text ein. Ist „Systembenachrichtigung (Notify)“ aktiviert, wird die Meldung an das System gesendet.
![408_06_TeaTimerDemo](https://github.com/user-attachments/assets/f18d84ce-180e-499f-832c-fd064da4a296)
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

