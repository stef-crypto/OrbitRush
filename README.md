# Orbit Rush

Ein nativer iPhone-Prototyp mit SwiftUI und SpriteKit.

## Version 3

- Quick-Combo-System für mutige, schnelle Sprünge
- Seltene goldene Planeten mit Bonuspunkten
- Trefferexplosionen, schwebende Punkte und stärkeres Feedback
- Lebendiger Sternenhintergrund und dynamischere Schwierigkeit

## Version 4

- Sanfte Flugsteuerung: Während des Flugs halten oder in Richtung Ziel wischen
- Bis zu acht eigene Fotos über den Planeten-Button auswählen
- Fotos werden auf bestehende und neue Planeten gelegt
- Flugsteuerung in v4.1 deutlich kräftiger und direkter abgestimmt

## Version 5

- Spieler-Auswahl mit Rakete, Dino, M5-artiger Sportlimousine und Doppeladler
- Eigene transparente Neon-Arcade-Sprites
- Auswahl wird dauerhaft gespeichert

## Version 6

- Sammelbare Sternenmünzen mit dauerhaftem Kontostand
- Schutzschild als Belohnung für jeweils zehn Punkte
- Gefährliche Asteroiden ab Score 8
- Pause-Funktion

## Version 6.1

- Figur während des Flugs direkt antippen für einen riskanten Rettungswurf zum Zielplaneten
- Mehrere Rettungsversuche pro Flug: Jeder schnelle Treffer auf die Figur würfelt einen neuen Kurs zum Ziel

## Version 7

- Auf der Figur beginnen und nach außen wischen, um in Wischrichtung zu schießen
- Projektile zerstören Asteroiden
- Getroffene Sternenboni werden ebenfalls zerstört und können nicht mehr gesammelt werden
- Kurzes Antippen der Figur bleibt der glücksbasierte Rettungsversuch

## Version 8

- Neustart stabilisiert: alte Game-over-Animationen und Gesten werden zuverlässig beendet
- Ein Tap nach Game-over startet die neue Runde sofort
- Run-Zusammenfassung mit Score und gesammelten Sternen
- Vollständiger Reset von Projektilen, Asteroiden, Schild, Combo, Pause und Rettungs-Cooldown

## Version 9 / App Store 1.0

- Eigenes Arcade-Sounddesign mit acht Effekten und Loop-Musik
- Separate Schalter für Ton und Musik
- Finales 1024×1024 App-Icon im Asset-Katalog
- Einmaliges Tutorial für sämtliche Gesten
- Datenschutzmanifest ohne Tracking oder Datenerhebung
- Release-Bundle `com.stefko.orbitrush`, Version 1.0, Build 1
- Deutsche App-Store-Metadaten, Datenschutzseite und Release-Checkliste

## Version 9.1 / App Store Build 2

- Gepunktete Vorschau zeigt beim Orbitieren die exakte Absprungrichtung
- Perfect Landings geben einen zusätzlichen Punkt
- Neuer Highscore wird als „NEW BEST!“ hervorgehoben
- Automatische Pause beim Wechseln oder Sperren der App

## Version 9.2 / App Store Build 3

- Globales Apple-Game-Center-Leaderboard
- Automatische Game-Center-Anmeldung
- Score-Upload nach jedem Run
- Pokal-Button öffnet Apples weltweite Ranglistenansicht

## Version 9.3 / App Store Build 4

- Dauerhafte Statistiken für Runs, Landungen, Perfects, Sterne und Asteroiden
- Täglich wechselndes Punkteziel mit 25-Sterne-Belohnung
- Sieben Game-Center-Achievements mit Fortschrittsübertragung
- Statistik- und Tagesmissionsansicht direkt im Spiel

## Version 9.4 / App Store Build 5

- Sichtbare, pulsierende Schild-Aura um die Spielfigur
- Dezentes Kamera-Shake bei Asteroiden, Schildrettung und Game-over
- Kurze farbige Bildschirmblitze für wichtige Treffer
- Verstärktes Audio- und Haptikfeedback bei Perfect Landings

## Version 9.5 / App Store Build 6

- Im Orbit gilt jetzt: kurzer Tipp springt, Wischen schießt ohne abzuspringen
- Hindernisse und Boni können vor dem Flug gezielt aus dem Weg geräumt werden
- Spieler-Thumbnails werden direkt aus den gebündelten PNG-Dateien geladen
- Größere, kontrastreichere Spieler-Auswahl mit sichtbarem Ressourcen-Fallback

## Version 9.6 / App Store Build 7

- Ton-Schalter steuert den Soundmanager jetzt unmittelbar statt indirekt über gespeicherte Einstellungen
- Laufende Effekte stoppen sofort beim Ausschalten
- Musikschalter aktualisiert Wiedergabe und gespeicherten Zustand zuverlässig

## Version 9.7 / App Store Build 8

- Musiknote öffnet jetzt ein Auswahlmenü
- Spielmusik direkt ein- oder ausschalten
- Apple Music oder Spotify über sichere Universal Links öffnen
- Spiel pausiert beim Wechsel zur Musik-App automatisch

## Version 9.8 / App Store Build 9

- ReplayKit-Aufnahme über roten Record-Button
- Spielbild und eigene Game-Sounds werden aufgenommen
- Zweiter Tipp stoppt und öffnet Apples Vorschau zum Teilen oder Speichern
- Sichtbarer Aufnahmezustand und Schutz vor mehrfacher Auslösung

## Version 9.9 / App Store Build 10

- Eigener animierter Ladebildschirm im Orbit-Rush-Neonstil
- Kreisende Rakete, leuchtender Planet, Sternenfeld und Ladebalken
- Sanfter Übergang ins Spiel nach vollständigem App-Start
- Kein zusätzlicher Ladebildschirm zwischen einzelnen Runs

## Version 9.10 / App Store Build 11

- Laufende SpriteKit-Szene bleibt über SwiftUI-Neuberechnungen hinweg stabil erhalten
- Spielerwechsel aktualisiert garantiert die sichtbare Szeneninstanz
- Auswahl wird sofort mit Haptik, Animation und Spielername bestätigt
- Texturfilter für saubere Darstellung der Spieler-Sprites

## Starten

1. `OrbitRush.xcodeproj` mit Xcode öffnen.
2. Ein iPhone oder einen iOS-Simulator auswählen.
3. Mit **Run** (`⌘R`) starten.

## Steuerung

Die Figur umkreist einen Planeten. Tippe, um sie tangential ins All zu schießen. Triff den nächsten Planeten, sammle Punkte und überlebe so lange wie möglich.
# v9.11 Monetarisierungsbasis

- Orbit Shop mit StoreKit 2 und verifizierten dauerhaften Käufen
- Orbit Rush Pro, Neon Pack und Legends Pack
- Käufe wiederherstellen und geräteübergreifend erkennen
- Gold-, Neon- und Legends-Flugspuren ohne Pay-to-win
- Bestehende Spielfiguren bleiben kostenlos
# v9.12 Orbit-Timer

- Nach 3,5 Sekunden auf einem Planeten erscheint ein 3–2–1-Countdown
- Bei null startet die Figur automatisch in der aktuellen Flugrichtung
- Countdown mit Impulsfeedback, ohne sofortigen unfairen Game-Over
# v9.13 Multiplayer Beta

- Game-Center-Echtzeitmatch für zwei Geräte
- Schnelles Match und Freundeseinladung über Apples Matchmaker
- Synchroner Countdown und 60-Second-Rush
- Live-Punktestand, Ergebnis und Rematch
- Verbindungsabbruch wird sauber behandelt
# v9.14 Intuitiver Multiplayer

- Neuer Multiplayer-Startbildschirm mit klarer Modusauswahl
- Direktes Spiel in der Nähe über WLAN/Bluetooth
- Weltweites Match weiterhin über Game Center
- Spiel erstellen, Spiel suchen, verständliche Statusmeldungen
- Nahmodus funktioniert unabhängig vom Game-Center-Matchmaking
# v9.15 Nahmodus-Verbindungsfix

- Nahes Spiel auf Apples aktuelles Network-Framework umgestellt
- Automatische Bonjour-Erkennung ohne veralteten Gerätebrowser
- Direkte TCP-Verbindung mit stabiler Paketübertragung
- Verständliche Statusmeldungen für Suche, Fund, Verbindung und Fehler
# v9.16 Eindeutige Multiplayer-Figuren

- Figurenauswahl wird beim Verbinden zwischen beiden Geräten synchronisiert
- Dieselbe Figur kann in einem Duell nicht doppelt verwendet werden
- Gastgeber behält seine Auswahl, Gast erhält automatisch eine freie Figur
- Sichtbare Bestätigung vor dem Match
# v9.17 Gewinner und Verlierer

- Nach 60 Sekunden gibt es immer einen eindeutigen Sieger
- Bei Gleichstand startet automatisch Sudden Death
- Die nächste erfolgreiche Planetenlandung entscheidet das Duell
- Ergebnis zeigt klar „Du gewinnst“ oder „Du verlierst“
# v10.0 Release Candidate

- Multiplayer ist ein dauerhafter Premium-Einmalkauf
- Orbit Rush Pro enthält Multiplayer und alle Style-Pakete
- Multiplayer-Button führt ohne Berechtigung direkt zum Orbit Shop
- App-Store-Texte, Datenschutz und Release-Checkliste aktualisiert
