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
    @AppStorage("selectedTrail") private var selectedTrail = "classic"

    private let players = [
        ("rocket", "RAKETE"),
        ("dino", "DINO"),
        ("m5", "M5"),
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

            VStack {
                HStack {
                    Button {
                        recording.toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(recording.isRecording ? Color.red : Color.white.opacity(0.45), lineWidth: 2)
                            Circle()
                                .fill(Color.red)
                                .frame(width: recording.isRecording ? 13 : 17, height: recording.isRecording ? 13 : 17)
                                .clipShape(recording.isRecording ? AnyShape(RoundedRectangle(cornerRadius: 3)) : AnyShape(Circle()))
                        }
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                        .opacity(recording.isBusy ? 0.45 : 1)
                    }
                    .disabled(recording.isBusy)
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { showStats = true }
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.cyan)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        showShop = true
                    } label: {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.mint)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        GameCenterManager.shared.showLeaderboard()
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.yellow)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        if store.ownsMultiplayer {
                            showMultiplayerMenu = true
                        } else {
                            showShop = true
                        }
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        let enabled = !soundEnabled
                        soundEnabled = enabled
                        SoundManager.shared.setSoundEnabled(enabled)
                    } label: {
                        Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Menu {
                        Button {
                            let enabled = !musicEnabled
                            musicEnabled = enabled
                            SoundManager.shared.setMusicEnabled(enabled)
                        } label: {
                            Label(
                                musicEnabled ? "Spielmusik ausschalten" : "Spielmusik einschalten",
                                systemImage: musicEnabled ? "music.note.slash" : "music.note"
                            )
                        }

                        Divider()

                        Button {
                            openMusicService("https://music.apple.com/")
                        } label: {
                            Label("Apple Music öffnen", systemImage: "apple.logo")
                        }

                        Button {
                            openMusicService("https://open.spotify.com/")
                        } label: {
                            Label("Spotify öffnen", systemImage: "play.circle.fill")
                        }
                    } label: {
                        Image(systemName: musicEnabled ? "music.note" : "music.note.slash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Button {
                        scene.togglePause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                Spacer()
            }
            .padding(.top, 54)
            .padding(.trailing, 18)

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

            if !hasSeenTutorial {
                tutorialOverlay
                    .transition(.opacity)
                    .zIndex(200)
            }

            if showStats {
                statsOverlay
                    .zIndex(190)
            }

            if multiplayer.isVisible {
                multiplayerOverlay
                    .zIndex(210)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                scene.pauseForBackground()
            }
        }
        .onAppear {
            GameCenterManager.shared.authenticate()
            scene.setTrailStyle(selectedTrail)
            scene.onScoreChanged = { score in
                MultiplayerManager.shared.submit(score: score)
            }
            multiplayer.onRoundStart = { [weak scene] in scene?.startMultiplayerRound() }
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
            Color(red: 0.02, green: 0.03, blue: 0.08).opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                playerImage("rocket")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)

                VStack(spacing: 7) {
                    Text("ORBIT RUSH")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("Ein Finger. Unendlich weit.")
                        .foregroundStyle(.cyan)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }

                VStack(alignment: .leading, spacing: 15) {
                    tutorialRow(icon: "hand.tap.fill", text: "Tippen, um vom Planeten abzuspringen")
                    tutorialRow(icon: "hand.draw.fill", text: "Im Flug halten und sanft zum Ziel lenken")
                    tutorialRow(icon: "arrow.trianglehead.2.clockwise.rotate.90", text: "Figur antippen für einen Rettungsversuch")
                    tutorialRow(icon: "scope", text: "Von der Figur wegwischen, um zu schießen")
                    tutorialRow(icon: "star.fill", text: "Sterne sammeln – aber nicht abschießen")
                }
                .padding(.horizontal, 8)

                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        hasSeenTutorial = true
                    }
                } label: {
                    Text("LOS GEHT'S")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.cyan, in: Capsule())
                }
                .padding(.top, 8)
            }
            .foregroundStyle(.white)
            .padding(30)
            .frame(maxWidth: 430)
        }
    }

    private func tutorialRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
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
