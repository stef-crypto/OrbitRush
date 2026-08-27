# Orbit Rush – Veröffentlichung heute

## Fertig im Projekt

- Release-Version 1.0, Build 23
- iOS-26-SDK-kompatibles Projekt
- 1024×1024 App-Icon ohne Transparenz
- Datenschutzmanifest für UserDefaults (`CA92.1`)
- Keine Werbung, kein Tracking, keine Drittanbieter-SDKs
- Kostenpflichtiger Multiplayer als dauerhafter StoreKit-2-Einmalkauf
- Eigenes Sounddesign und eigene Musik
- Einmaliges Tutorial, Audioeinstellungen und vollständiger Game-over-Reset
- Deutsche Store-Texte und Datenschutztext

## Von dir in App Store Connect

1. Prüfen, ob die kostenpflichtige Apple-Developer-Mitgliedschaft aktiv ist.
2. Neue App mit Bundle-ID `com.stefko.orbitrush` anlegen.
3. Xcode 26 auswählen und mit dem iOS-26-SDK archivieren.
4. Drei bis fünf echte Screenshots in der höchsten von App Store Connect angebotenen iPhone-Auflösung aufnehmen.
5. GitHub Pages für den Branch `main` aktivieren und die vorbereiteten Support-/Datenschutz-URLs testen.
6. `Metadata-de.md` und `Metadata-en.md` in App Store Connect eintragen.
7. Unter „App Privacy“ auswählen: **No, we do not collect data from this app**.
8. Das aktuelle Altersfreigabe-Formular wahrheitsgemäß ausfüllen; das Spiel enthält keine realistische Gewalt, Glücksspiele oder Nutzerinhalte.
9. Export-Compliance-Frage beantworten: Die App verwendet keine eigene oder nicht von Apple bereitgestellte Verschlüsselung.
10. In Xcode: **Product → Archive → Distribute App → App Store Connect → Upload**.
11. Verarbeiteten Build auswählen, „Add for Review“ und danach „Submit for Review“.

## In-App-Käufe vor dem Upload

Vier **nicht verbrauchbare** Produkte anlegen und gemeinsam mit Version 1.0 einreichen:

- `com.stefko.orbitrush.multiplayer` – Multiplayer dauerhaft – empfohlen 2,99 €
- `com.stefko.orbitrush.pro` – Orbit Rush Pro – empfohlen 5,99 €
- `com.stefko.orbitrush.neonpack` – Neon Pack – empfohlen 1,99 €
- `com.stefko.orbitrush.legendspack` – Legends Pack – empfohlen 1,99 €

Für jedes Produkt Anzeigename, Beschreibung und Review-Screenshot hinterlegen. Im Review-Hinweis erklären, dass Pro auch Multiplayer und beide Style-Pakete freischaltet. Käufe und „Käufe wiederherstellen“ vor Einreichung mit einem Sandbox-Account prüfen.

## Globales Game-Center-Leaderboard

1. In App Store Connect bei Orbit Rush **Game Center** aktivieren.
2. **Add Leaderboard → Classic Leaderboard** auswählen.
3. Reference Name: `Global Highscore`.
4. Permanente Leaderboard-ID: `com.stefko.orbitrush.highscore` — exakt so, nachträglich nicht änderbar.
5. Sortierung: **High to Low**; Score-Typ: ganze Zahl; kleinster Wert 0.
6. Deutsche Lokalisierung: Anzeigename `Globaler Highscore`, Einheit `Punkte`.
7. Leaderboard gemeinsam mit App-Version 1.0 zur Prüfung hinzufügen.

### Achievements in Game Center anlegen

Alle Achievements erhalten 100 Punkte Gesamtwert über das Set verteilt und werden mit der App eingereicht:

- `com.stefko.orbitrush.score10` — Erste zehn — 10 Punkte erreichen
- `com.stefko.orbitrush.score25` — Orbit-Profi — 25 Punkte erreichen
- `com.stefko.orbitrush.score50` — Weltraumlegende — 50 Punkte erreichen
- `com.stefko.orbitrush.landings100` — Vielflieger — 100 Landungen
- `com.stefko.orbitrush.perfect25` — Präzision — 25 Perfect Landings
- `com.stefko.orbitrush.collector100` — Sternensammler — 100 Sterne einsammeln
- `com.stefko.orbitrush.hunter25` — Asteroidenjäger — 25 Asteroiden zerstören

Eine Veröffentlichung am selben Tag ist nicht garantiert: Apples Verarbeitung und App Review bestimmen den tatsächlichen Freigabezeitpunkt.

## Optionale Apple-Watch-App

- Target `OrbitRush Watch App` ist eingebettet; Bundle-ID: `com.stefko.orbitrush.watchkitapp`.
- Mindestversion: watchOS 10.
- Auf echter Apple Watch prüfen: Installation, Crown-Lenkung, Rettungstipp, Haptik, Neustart und verschiedene Displaygrößen.
- Watch-Screenshots und App-Store-Metadaten ergänzen, wenn die Watch-App bereits mit Version 1.0 veröffentlicht wird.
- Falls der iPhone-Launch nicht verzögert werden soll, Watch-Target vor dem ersten Archive aus dem Embed-Schritt entfernen und als späteres Update ausliefern.
