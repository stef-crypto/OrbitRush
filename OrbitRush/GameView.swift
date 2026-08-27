import SwiftUI
import SpriteKit
import PhotosUI

struct GameView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var showPlayerPicker = false
    @State private var showStats = false
    @State private var showShop = false
    @State private var showMultiplayerMenu = false
    @State private var showMainMenu = true
    @State private var tutorialPage = 0
    @State private var showSettings = false
    @StateObject private var recording = RecordingManager.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var multiplayer = MultiplayerManager.shared
    @AppStorage("selectedPlayer") private var selectedPlayer = "rocket"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("totalRuns") private var totalRuns = 0
    @AppStorage("totalLandings") private var totalLandings = 0
    @AppStorage("perfectLandings") private var perfectLandings = 0
    @AppStorage("totalCoinsCollected") private var totalCoinsCollected = 0
    @AppStorage("asteroidsDestroyed") private var asteroidsDestroyed = 0
    @AppStorage("dailyBest") private var dailyBest = 0
    @AppStorage("multiplayerWins") private var multiplayerWins = 0
    @AppStorage("multiplayerLosses") private var multiplayerLosses = 0
    @AppStorage("selectedTrail") private var selectedTrail = "classic"
    @AppStorage("reducedEffects") private var reducedEffects = false
    @AppStorage("colorBlindMode") private var colorBlindMode = false

    private let players = [
        ("rocket", "RAKETE"),
        ("dino", "DINO"),
        ("m5", "SPORTWAGEN"),
        ("eagle", "ADLER")
    ]

    @State private var scene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .background(Color(red: 0.025, green: 0.035, blue: 0.09))

            if !showMainMenu {
                VStack {
                    gameplayToolbar
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if !showMainMenu {
            PhotosPicker(selection: $photoItems, maxSelectionCount: 8, matching: .images) {
                HStack(spacing: 7) {
                    if isLoadingPhotos {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                    Text("PLANETEN")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
            .onChange(of: photoItems) { _, items in
                loadPhotos(items)
            }
            }

            if !showMainMenu {
            VStack(alignment: .leading, spacing: 10) {
                if showPlayerPicker {
                    HStack(spacing: 8) {
                        ForEach(players, id: \.0) { player in
                            Button {
                                scene.setPlayerStyle(player.0)
                                selectedPlayer = player.0
                                showPlayerPicker = false
                            } label: {
                                VStack(spacing: 4) {
                                    playerImage(player.0)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 54, height: 54)
                                        .shadow(color: .cyan.opacity(0.6), radius: 5)
                                    Text(player.1)
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(width: 68, height: 78)
                                .background(selectedPlayer == player.0 ? Color.cyan.opacity(0.28) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedPlayer == player.0 ? Color.cyan : Color.white.opacity(0.12), lineWidth: 1.5))
                            }
                        }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPlayerPicker.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        playerImage(selectedPlayer)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                        Text("SPIELER")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 18)
            .padding(.bottom, 18)
            .allowsHitTesting(true)
            }

            if !hasSeenTutorial {
                tutorialOverlay
                    .transition(.opacity)
                    .zIndex(200)
            }

            if showStats {
                statsOverlay
                    .zIndex(230)
            }

            if multiplayer.isVisible {
                multiplayerOverlay
                    .zIndex(210)
            }

            if showMainMenu && hasSeenTutorial {
                mainMenu
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(220)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                scene.pauseForBackground()
            }
        }
        .onChange(of: reducedEffects) { _, value in
            scene.setGameplayOptions(reducedEffects: value, colorBlindMode: colorBlindMode)
        }
        .onChange(of: colorBlindMode) { _, value in
            scene.setGameplayOptions(reducedEffects: reducedEffects, colorBlindMode: value)
        }
        .onAppear {
            GameCenterManager.shared.authenticate()
            scene.setTrailStyle(selectedTrail)
            scene.setGameplayOptions(reducedEffects: reducedEffects, colorBlindMode: colorBlindMode)
            scene.onScoreChanged = { score in
                MultiplayerManager.shared.submit(score: score)
            }
            multiplayer.onRoundStart = { [weak scene] in
                showMainMenu = false
                scene?.startMultiplayerRound()
            }
            multiplayer.onRoundEnd = { [weak scene] in scene?.finishMultiplayerRound() }
            multiplayer.onPlayerStyleResolved = { [weak scene] style in
                selectedPlayer = style
                scene?.setPlayerStyle(style)
            }
        }
        .sheet(isPresented: $showShop) {
            shopView
        }
        .sheet(isPresented: $showMultiplayerMenu) {
            multiplayerMenu
        }
        .sheet(isPresented: $showSettings) {
            settingsView
        }
    }

    private var gameplayToolbar: some View {
        HStack(spacing: 9) {
            hudButton("house.fill") {
                scene.pauseForMenu()
                withAnimation(.easeOut(duration: 0.2)) { showMainMenu = true }
            }

            Button { recording.toggleRecording() } label: {
                ZStack {
                    Circle()
                        .stroke(recording.isRecording ? Color.red : Color.white.opacity(0.45), lineWidth: 2)
                    Circle()
                        .fill(Color.red)
                        .frame(width: recording.isRecording ? 12 : 16, height: recording.isRecording ? 12 : 16)
                        .clipShape(recording.isRecording ? AnyShape(RoundedRectangle(cornerRadius: 3)) : AnyShape(Circle()))
                }
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .opacity(recording.isBusy ? 0.45 : 1)
            }
            .disabled(recording.isBusy)
            .accessibilityLabel(recording.isRecording ? "Aufnahme stoppen" : "Aufnahme starten")

            Menu {
                Button { showStats = true } label: {
                    Label("Statistik", systemImage: "chart.bar.fill")
                }
                Button { showShop = true } label: {
                    Label("Orbit Shop", systemImage: "bag.fill")
                }
                Button { GameCenterManager.shared.showLeaderboard() } label: {
                    Label("Rangliste", systemImage: "trophy.fill")
                }
                Button {
                    if store.ownsMultiplayer { showMultiplayerMenu = true } else { showShop = true }
                } label: {
                    Label("Multiplayer", systemImage: "person.2.fill")
                }

                Divider()

                Button {
                    soundEnabled.toggle()
                    SoundManager.shared.setSoundEnabled(soundEnabled)
                } label: {
                    Label(soundEnabled ? "Ton ausschalten" : "Ton einschalten",
                          systemImage: soundEnabled ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                Button {
                    musicEnabled.toggle()
                    SoundManager.shared.setMusicEnabled(musicEnabled)
                } label: {
                    Label(musicEnabled ? "Spielmusik ausschalten" : "Spielmusik einschalten",
                          systemImage: musicEnabled ? "music.note.slash" : "music.note")
                }
                Button { openMusicService("https://music.apple.com/") } label: {
                    Label("Apple Music öffnen", systemImage: "apple.logo")
                }
                Button { openMusicService("https://open.spotify.com/") } label: {
                    Label("Spotify öffnen", systemImage: "play.circle.fill")
                }
                Button { showSettings = true } label: {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Mehr Optionen")

            Spacer(minLength: 12)

            hudButton("pause.fill") { scene.togglePause() }
        }
    }

    private func hudButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var mainMenu: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color(red: 0.02, green: 0.04, blue: 0.13).opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                playerImage(selectedPlayer)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .shadow(color: .cyan.opacity(0.8), radius: 18)

                VStack(spacing: 4) {
                    Text("ORBIT RUSH")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                    Text("EIN FINGER. UNENDLICH WEIT.")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.cyan)
                }

                Button {
                    scene.startSoloGame()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) { showMainMenu = false }
                } label: {
                    Label("SOLO STARTEN", systemImage: "play.fill")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cyan, in: Capsule())
                }

                HStack(spacing: 12) {
                    Button {
                        scene.startDailyGame()
                        withAnimation { showMainMenu = false }
                    } label: {
                        Label("DAILY RUN", systemImage: "calendar")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.purple.opacity(0.55), in: Capsule())
                    }
                    Button {
                        scene.startTrainingGame()
                        withAnimation { showMainMenu = false }
                    } label: {
                        Label("TRAINING", systemImage: "graduationcap.fill")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.mint.opacity(0.45), in: Capsule())
                    }
                }
                .foregroundStyle(.white)

                Button {
                    if store.ownsMultiplayer { showMultiplayerMenu = true } else { showShop = true }
                } label: {
                    Label(store.ownsMultiplayer ? "MULTIPLAYER" : "MULTIPLAYER FREISCHALTEN", systemImage: store.ownsMultiplayer ? "person.2.fill" : "lock.fill")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.orange.opacity(0.82), in: Capsule())
                }

                HStack(spacing: 12) {
                    menuTile("SPIELER", icon: "figure.run", color: .cyan) {
                        scene.startSoloGame()
                        showPlayerPicker = true
                        showMainMenu = false
                    }
                    menuTile("SHOP", icon: "bag.fill", color: .mint) { showShop = true }
                    menuTile("STATS", icon: "chart.bar.fill", color: .purple) { showStats = true }
                    menuTile("RANGLISTE", icon: "trophy.fill", color: .yellow) { GameCenterManager.shared.showLeaderboard() }
                }

                Button {
                    tutorialPage = 0
                    withAnimation(.easeOut(duration: 0.2)) { hasSeenTutorial = false }
                } label: {
                    Label("SPIELANLEITUNG", systemImage: "questionmark.circle.fill")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }

                HStack(spacing: 18) {
                    Button { showSettings = true } label: {
                        Label("EINSTELLUNGEN", systemImage: "gearshape.fill")
                    }
                    Button { shareGame() } label: {
                        Label("TEILEN", systemImage: "square.and.arrow.up")
                    }
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))

                VStack(spacing: 5) {
                    Text("LEVEL \(ProgressManager.shared.level)   •   BEST \(UserDefaults.standard.integer(forKey: "bestScore"))   •   ✦ \(UserDefaults.standard.integer(forKey: "coins"))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    ProgressView(value: Double(ProgressManager.shared.xpInLevel), total: 100)
                        .tint(.cyan)
                        .frame(maxWidth: 230)
                }
                .foregroundStyle(.white.opacity(0.58))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func menuTile(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 19, weight: .bold)).foregroundStyle(color)
                Text(title).font(.system(size: 8, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("SPIELGEFÜHL") {
                    Toggle("Reduzierte Effekte", isOn: $reducedEffects)
                    Toggle("Kontrastreiche Zielhilfe", isOn: $colorBlindMode)
                }
                Section("MODI") {
                    Label("Training verhindert Game Over", systemImage: "graduationcap.fill")
                    Label("Daily Run nutzt jeden Tag dieselbe Route", systemImage: "calendar")
                }
                Section("FORTSCHRITT") {
                    LabeledContent("Level", value: "\(ProgressManager.shared.level)")
                    LabeledContent("Erfahrung", value: "\(ProgressManager.shared.xpInLevel) / 100 XP")
                    LabeledContent("Rang", value: playerRank)
                    LabeledContent("Entdeckte Zonen", value: "\(unlockedZoneCount) / 4")
                    ProgressView(value: Double(ProgressManager.shared.xpInLevel), total: 100).tint(.cyan)
                }
            }
            .navigationTitle("EINSTELLUNGEN")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showSettings = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var playerRank: String {
        switch ProgressManager.shared.level {
        case 1..<3: return "Orbit Rookie"
        case 3..<6: return "Sternenpilot"
        case 6..<10: return "Galaxy Ace"
        default: return "Void Legend"
        }
    }

    private var unlockedZoneCount: Int {
        let best = UserDefaults.standard.integer(forKey: "bestScore")
        return best >= 30 ? 4 : (best >= 18 ? 3 : (best >= 8 ? 2 : 1))
    }

    private func shareGame() {
        let best = UserDefaults.standard.integer(forKey: "bestScore")
        let text = "Mein Orbit-Rush-Rekord: \(best) Punkte 🚀 Schaffst du mehr?"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var presenter = root
        while let shown = presenter.presentedViewController { presenter = shown }
        controller.popoverPresentationController?.sourceView = presenter.view
        presenter.present(controller, animated: true)
    }

    private var multiplayerMenu: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 58, weight: .black))
                    .foregroundStyle(.orange)
                    .padding(.bottom, 8)
                Text("SPIELT ZU ZWEIT")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("Beide spielen 60 Sekunden. Wer mehr Planeten erreicht, gewinnt.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                multiplayerChoice(title: "SPIEL ERSTELLEN", subtitle: "Dein Freund sucht dich über WLAN/Bluetooth", icon: "antenna.radiowaves.left.and.right", color: .cyan) {
                    showMultiplayerMenu = false
                    multiplayer.hostNearby()
                }
                multiplayerChoice(title: "SPIEL IN DER NÄHE SUCHEN", subtitle: "Mit einem iPhone in deiner Nähe verbinden", icon: "dot.radiowaves.right", color: .mint) {
                    showMultiplayerMenu = false
                    multiplayer.browseNearby()
                }
                multiplayerChoice(title: "WELTWEIT SPIELEN", subtitle: "Freunde oder Gegner über Game Center", icon: "globe.europe.africa.fill", color: .orange) {
                    showMultiplayerMenu = false
                    multiplayer.findMatch()
                }

                Text("Für den Nahmodus müssen WLAN und Bluetooth auf beiden Geräten aktiviert sein.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
            .navigationTitle("MULTIPLAYER")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { showMultiplayerMenu = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
    }

    private func multiplayerChoice(title: String, subtitle: String, icon: String, color: Color,
                                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 14, weight: .black, design: .rounded))
                    Text(subtitle).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var multiplayerOverlay: some View {
        VStack {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DU").foregroundStyle(.cyan)
                    Text("\(multiplayer.localScore)").font(.title2).fontWeight(.black)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(multiplayer.phase == .playing ? "\(multiplayer.secondsLeft)" : multiplayerStatus)
                        .font(.system(size: multiplayer.phase == .playing ? 27 : 13, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                    Text("60 SECOND RUSH").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(multiplayer.opponentName.uppercased()).lineLimit(1).foregroundStyle(.orange)
                    Text("\(multiplayer.remoteScore)").font(.title2).fontWeight(.black)
                }
            }
            .font(.system(size: 11, weight: .black, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 18)
            .padding(.top, 104)

            Spacer()

            if multiplayer.phase == .finished {
                VStack(spacing: 15) {
                    Text(multiplayer.resultTitle).font(.system(size: 28, weight: .black, design: .rounded))
                    Text("\(multiplayer.localScore)  :  \(multiplayer.remoteScore)").font(.title.bold())
                    HStack {
                        Button("BEENDEN") { multiplayer.cancel() }
                            .buttonStyle(.bordered)
                        Button("REMATCH") { multiplayer.rematch() }
                            .buttonStyle(.borderedProminent).tint(.cyan)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .padding(24)
            } else if multiplayer.phase == .finding || multiplayer.phase == .waiting {
                Button("ABBRECHEN") { multiplayer.cancel() }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 28)
            }
        }
        .foregroundStyle(.white)
        .allowsHitTesting(multiplayerOverlayAllowsInteraction)
    }

    private var multiplayerOverlayAllowsInteraction: Bool {
        switch multiplayer.phase {
        case .playing, .suddenDeath, .countdown: return false
        default: return true
        }
    }

    private var multiplayerStatus: String {
        switch multiplayer.phase {
        case .finding: return "SUCHE…"
        case .waiting: return "VERBINDEN…"
        case .countdown(let value): return "START IN \(value)"
        case .suddenDeath: return "SUDDEN DEATH"
        case .finished: return "ERGEBNIS"
        default: return "BEREIT"
        }
    }

    private var shopView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Schalte Multiplayer und neue Styles dauerhaft frei. Keine Abos und keine Vorteile im Leaderboard.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)

                    storeCard(id: StoreManager.ProductID.pro, title: "ORBIT RUSH PRO", subtitle: "Multiplayer · werbefrei · alle Style-Pakete", icon: "crown.fill", color: .yellow)
                    storeCard(id: StoreManager.ProductID.multiplayer, title: "MULTIPLAYER", subtitle: "Nah und weltweit dauerhaft freischalten", icon: "person.2.fill", color: .orange)
                    storeCard(id: StoreManager.ProductID.neon, title: "NEON PACK", subtitle: "Pinker Neon-Trail mit stärkerem Glow", icon: "bolt.fill", color: .pink)
                    storeCard(id: StoreManager.ProductID.legends, title: "LEGENDS PACK", subtitle: "Violetter kosmischer Legenden-Trail", icon: "sparkles", color: .purple)

                    if store.ownsPro || store.ownsNeon || store.ownsLegends {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DEINE TRAILS").font(.system(size: 13, weight: .black, design: .rounded))
                            trailButton("CLASSIC", style: "classic", color: .cyan, unlocked: true)
                            trailButton("GOLD", style: "gold", color: .yellow, unlocked: store.ownsPro)
                            trailButton("NEON", style: "neon", color: .pink, unlocked: store.ownsNeon)
                            trailButton("LEGEND", style: "legend", color: .purple, unlocked: store.ownsLegends)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                    }

                    Button("Käufe wiederherstellen") {
                        Task { await store.restore() }
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                    Text("Einmalkäufe · kein Abo · jederzeit wiederherstellbar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Color(red: 0.025, green: 0.035, blue: 0.09).ignoresSafeArea())
            .navigationTitle("ORBIT SHOP")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showShop = false }
                }
            }
            .overlay {
                if store.isBusy { ProgressView().controlSize(.large) }
            }
            .alert("Orbit Shop", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
                Button("OK") { store.message = nil }
            } message: {
                Text(store.message ?? "")
            }
            .task { await store.refresh() }
        }
        .preferredColorScheme(.dark)
    }

    private func storeCard(id: String, title: String, subtitle: String, icon: String, color: Color) -> some View {
        let owned = store.purchasedIDs.contains(id) || (id != StoreManager.ProductID.pro && store.ownsPro)
        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .black, design: .rounded))
                Text(subtitle).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer()
            if owned {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            } else if let product = store.product(id) {
                Button(product.displayPrice) { Task { await store.purchase(product) } }
                    .buttonStyle(.borderedProminent)
                    .tint(color)
            } else {
                Text("BALD").font(.caption.bold()).foregroundStyle(.secondary)
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    private func trailButton(_ title: String, style: String, color: Color, unlocked: Bool) -> some View {
        Button {
            guard unlocked else { return }
            selectedTrail = style
            scene.setTrailStyle(style)
        } label: {
            HStack {
                Circle().fill(color).frame(width: 12, height: 12).shadow(color: color, radius: 5)
                Text(title)
                Spacer()
                Image(systemName: selectedTrail == style ? "checkmark.circle.fill" : (unlocked ? "circle" : "lock.fill"))
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(unlocked ? .white : .secondary)
            .padding(11)
            .background(color.opacity(selectedTrail == style ? 0.18 : 0.05), in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!unlocked)
    }

    private var statsOverlay: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
                .onTapGesture { withAnimation { showStats = false } }

            VStack(spacing: 18) {
                HStack {
                    Text("DEINE STATISTIK")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Spacer()
                    Button { withAnimation { showStats = false } } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2)
                    }
                }

                VStack(spacing: 10) {
                    statRow("RUNS", totalRuns)
                    statRow("LANDUNGEN", totalLandings)
                    statRow("PERFECT", perfectLandings)
                    statRow("STERNE", totalCoinsCollected)
                    statRow("ASTEROIDEN", asteroidsDestroyed)
                    statRow("MULTIPLAYER-SIEGE", multiplayerWins)
                    statRow("MULTIPLAYER-NIEDERLAGEN", multiplayerLosses)
                }

                VStack(spacing: 8) {
                    Text("TAGESMISSION")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("Erreiche \(ProgressManager.shared.dailyGoal) Punkte")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    ProgressView(value: Double(min(dailyBest, ProgressManager.shared.dailyGoal)), total: Double(ProgressManager.shared.dailyGoal))
                        .tint(.yellow)
                    Text("HEUTE: \(dailyBest)  •  BELOHNUNG: 25 ✦")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(15)
                .background(Color.cyan.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
            }
            .foregroundStyle(.white)
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(24)
            .frame(maxWidth: 430)
        }
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text("\(value)").fontWeight(.black)
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
    }

    private var tutorialOverlay: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.08).opacity(0.98)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                HStack {
                    Text("SO SPIELST DU")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1.5)
                    Spacer()
                    Button("ÜBERSPRINGEN") { finishTutorial() }
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                tutorialAnimation
                    .frame(width: 220, height: 210)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .id(tutorialPage)

                VStack(spacing: 12) {
                    Text(tutorialStep.title)
                        .font(.system(size: 29, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(tutorialStep.text)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 340)
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<tutorialSteps.count, id: \.self) { index in
                        Capsule()
                            .fill(index == tutorialPage ? tutorialStep.color : Color.white.opacity(0.18))
                            .frame(width: index == tutorialPage ? 26 : 8, height: 8)
                    }
                }

                Button {
                    if tutorialPage < tutorialSteps.count - 1 {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { tutorialPage += 1 }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } else {
                        finishTutorial()
                    }
                } label: {
                    Text(tutorialPage == tutorialSteps.count - 1 ? "VERSTANDEN – LOS!" : "WEITER")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(tutorialStep.color, in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 52)
            .frame(maxWidth: 430)
        }
    }

    private var tutorialAnimation: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let wave = sin(time * 3.2)
            let progress = (time * 0.55).truncatingRemainder(dividingBy: 1)

            ZStack {
                Circle()
                    .fill(tutorialStep.color.opacity(0.10))
                    .frame(width: 196, height: 196)
                Circle()
                    .stroke(tutorialStep.color.opacity(0.38), lineWidth: 2)
                    .frame(width: 154, height: 154)

                if tutorialPage == 0 {
                    playerImage(selectedPlayer)
                        .resizable().scaledToFit()
                        .frame(width: 58, height: 58)
                        .scaleEffect(1 + max(0, wave) * 0.13)
                    Circle()
                        .stroke(tutorialStep.color.opacity(0.8), lineWidth: 3)
                        .frame(width: 74, height: 74)
                        .scaleEffect(0.8 + progress * 0.7)
                        .opacity(1 - progress)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 48, y: 55 - max(0, wave) * 9)
                } else if tutorialPage == 1 {
                    dottedPath
                    playerImage(selectedPlayer)
                        .resizable().scaledToFit()
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(28))
                        .offset(x: -58 + progress * 116, y: 55 - progress * 110)
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .offset(x: 62, y: -58)
                } else if tutorialPage == 2 {
                    playerImage(selectedPlayer)
                        .resizable().scaledToFit()
                        .frame(width: 62, height: 62)
                        .rotationEffect(.degrees(progress * 190))
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 78, weight: .black))
                        .foregroundStyle(tutorialStep.color.opacity(0.72))
                        .rotationEffect(.degrees(-20))
                        .scaleEffect(0.95 + max(0, wave) * 0.08)
                } else if tutorialPage == 3 {
                    playerImage(selectedPlayer)
                        .resizable().scaledToFit()
                        .frame(width: 58, height: 58)
                        .offset(x: -45)
                    Capsule()
                        .fill(tutorialStep.color)
                        .frame(width: 28, height: 8)
                        .shadow(color: tutorialStep.color, radius: 8)
                        .offset(x: -12 + progress * 104)
                        .opacity(progress < 0.88 ? 1 : 0)
                    Image(systemName: "burst.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(.yellow)
                        .offset(x: 70)
                        .scaleEffect(progress > 0.72 ? 1.25 : 0.7)
                        .opacity(progress > 0.68 ? 1 : 0.35)
                } else {
                    Text(String(3 - Int((time * 1.1).truncatingRemainder(dividingBy: 3))))
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(tutorialStep.color)
                        .scaleEffect(1 + max(0, wave) * 0.10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(tutorialStep.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 128, height: 128)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }

    private var dottedPath: some View {
        Path { path in
            path.move(to: CGPoint(x: 28, y: 162))
            path.addQuadCurve(to: CGPoint(x: 188, y: 38), control: CGPoint(x: 115, y: 125))
        }
        .stroke(tutorialStep.color.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 9]))
        .frame(width: 216, height: 200)
    }

    private struct TutorialStep {
        let icon: String
        let title: String
        let text: String
        let color: Color
    }

    private var tutorialSteps: [TutorialStep] {
        [
            TutorialStep(icon: "hand.tap.fill", title: "IM RICHTIGEN MOMENT", text: "Du kreist um einen Planeten. Tippe kurz, um in der angezeigten Richtung abzuspringen.", color: .cyan),
            TutorialStep(icon: "hand.draw.fill", title: "LENKE DEINEN FLUG", text: "Berühre während des Flugs eine Stelle und halte den Finger. Deine Figur zieht spürbar in diese Richtung.", color: .mint),
            TutorialStep(icon: "arrow.uturn.backward.circle.fill", title: "RETTE DEN SPRUNG", text: "Tippe deine Figur im Flug mehrmals an. Jede Wendung gibt dir eine neue Chance auf den Zielplaneten.", color: .purple),
            TutorialStep(icon: "scope", title: "RÄUME DEN WEG FREI", text: "Wische von deiner Figur in Schussrichtung. Zerstöre Asteroiden – aber pass auf Sterne und Boni auf.", color: .orange),
            TutorialStep(icon: "timer", title: "BLEIB IN BEWEGUNG", text: "Nach kurzer Zeit erscheint 3–2–1. Bei null startet deine Figur automatisch. Sammle Sterne und lande möglichst mittig.", color: .yellow)
        ]
    }

    private var tutorialStep: TutorialStep {
        tutorialSteps[min(max(tutorialPage, 0), tutorialSteps.count - 1)]
    }

    private func finishTutorial() {
        tutorialPage = 0
        withAnimation(.easeOut(duration: 0.25)) { hasSeenTutorial = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func playerImage(_ name: String) -> Image {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: image)
        }
        return Image(systemName: "questionmark.circle.fill")
    }

    private func openMusicService(_ address: String) {
        guard let url = URL(string: address) else { return }
        UIApplication.shared.open(url)
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoadingPhotos = true
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                scene.setPlanetImages(images)
                isLoadingPhotos = false
            }
        }
    }
}
