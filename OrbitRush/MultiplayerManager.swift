import Foundation
import GameKit
import MultipeerConnectivity
import UIKit

@MainActor
final class MultiplayerManager: NSObject, ObservableObject {
    static let shared = MultiplayerManager()

    enum Phase: Equatable {
        case idle, finding, waiting, countdown(Int), playing, suddenDeath, finished
    }

    enum Mode { case gameCenter, nearby }

    @Published var phase: Phase = .idle
    @Published var opponentName = "GEGNER"
    @Published var localScore = 0
    @Published var remoteScore = 0
    @Published var secondsLeft = 60
    @Published var message: String?
    @Published var remotePlayerStyle = "rocket"

    var onRoundStart: (() -> Void)?
    var onRoundEnd: (() -> Void)?
    var onPlayerStyleResolved: ((String) -> Void)?

    private var match: GKMatch?
    private var mode: Mode = .gameCenter
    private var clockTask: Task<Void, Never>?
    private var didScheduleStart = false
    private let serviceType = "orbitrush"
    private lazy var peerID = MCPeerID(displayName: String(UIDevice.current.name.prefix(32)))
    private lazy var nearbySession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browserController: MCBrowserViewController?
    private var isNearbyHost = false
    private var isMatchHost = false
    private let nearbyNetwork = NearbyNetworkManager()
    private var nearbyNetworkConnected = false

    var isVisible: Bool { phase != .idle }
    var resultTitle: String {
        if localScore > remoteScore { return "DU GEWINNST!" }
        return "DU VERLIERST"
    }

    func findMatch() {
        mode = .gameCenter
        guard GKLocalPlayer.local.isAuthenticated else {
            message = "Bitte zuerst bei Game Center anmelden."
            GameCenterManager.shared.authenticate()
            return
        }
        reset(keepVisible: true)
        phase = .finding
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.inviteMessage = "Komm zu einer Runde Orbit Rush!"
        guard let controller = GKMatchmakerViewController(matchRequest: request) else {
            message = "Matchmaking konnte nicht geöffnet werden."
            phase = .idle
            return
        }
        controller.matchmakerDelegate = self
        present(controller)
    }

    func hostNearby() {
        reset(keepVisible: true)
        mode = .nearby
        isNearbyHost = true
        phase = .waiting
        opponentName = "SUCHE IN DER NÄHE"
        configureNearbyNetwork()
        nearbyNetwork.host()
    }

    func browseNearby() {
        reset(keepVisible: true)
        mode = .nearby
        isNearbyHost = false
        phase = .finding
        configureNearbyNetwork()
        nearbyNetwork.search()
    }

    func submit(score: Int) {
        guard phase == .playing || phase == .suddenDeath, score != localScore else { return }
        localScore = score
        send(Packet(kind: .score, value: score, startTime: nil))
        checkSuddenDeath()
    }

    func cancel() {
        match?.disconnect()
        stopNearby()
        reset(keepVisible: false)
    }

    func rematch() {
        if mode == .nearby, nearbyNetworkConnected {
            localScore = 0
            remoteScore = 0
            if isNearbyHost {
                let start = Date().timeIntervalSince1970 + 2.5
                send(Packet(kind: .start, value: nil, startTime: start))
                scheduleStart(at: start)
            } else {
                phase = .waiting
            }
            return
        }
        match?.disconnect()
        findMatch()
    }

    private func connected(_ match: GKMatch) {
        self.match = match
        match.delegate = self
        phase = .waiting
        let remote = match.players.first
        opponentName = remote?.displayName ?? "GEGNER"
        guard match.expectedPlayerCount == 0, !didScheduleStart else { return }
        didScheduleStart = true
        let remoteID = remote?.gamePlayerID ?? ""
        isMatchHost = GKLocalPlayer.local.gamePlayerID < remoteID
        sendPlayerStyle()
        if isMatchHost {
            let start = Date().timeIntervalSince1970 + 2.5
            send(Packet(kind: .start, value: nil, startTime: start))
            scheduleStart(at: start)
        }
    }

    private func scheduleStart(at date: TimeInterval) {
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let remaining = date - Date().timeIntervalSince1970
                if remaining <= 0 { break }
                phase = .countdown(max(1, Int(ceil(remaining))))
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard !Task.isCancelled else { return }
            localScore = 0
            remoteScore = 0
            secondsLeft = 60
            phase = .playing
            onRoundStart?()
            for second in stride(from: 59, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, phase == .playing else { return }
                secondsLeft = second
            }
            if localScore == remoteScore {
                phase = .suddenDeath
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else {
                finishRound()
            }
        }
    }

    private func finishRound() {
        guard phase == .playing || phase == .suddenDeath else { return }
        send(Packet(kind: .finish, value: localScore, startTime: nil))
        phase = .finished
        onRoundEnd?()
        UINotificationFeedbackGenerator().notificationOccurred(localScore >= remoteScore ? .success : .warning)
    }

    private func send(_ packet: Packet) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        if mode == .nearby, nearbyNetworkConnected {
            nearbyNetwork.send(data)
        } else if let match {
            try? match.sendData(toAllPlayers: data, with: .reliable)
        }
    }

    private func receive(_ data: Data) {
        guard let packet = try? JSONDecoder().decode(Packet.self, from: data) else { return }
        switch packet.kind {
        case .player:
            let remoteStyle = packet.text ?? "rocket"
            remotePlayerStyle = remoteStyle
            resolveDuplicatePlayer(remoteStyle: remoteStyle)
        case .start:
            if let start = packet.startTime { scheduleStart(at: start) }
        case .score:
            remoteScore = packet.value ?? remoteScore
            checkSuddenDeath()
        case .finish:
            remoteScore = packet.value ?? remoteScore
        }
    }

    private func checkSuddenDeath() {
        guard phase == .suddenDeath, localScore != remoteScore else { return }
        finishRound()
    }

    private func sendPlayerStyle() {
        let style = UserDefaults.standard.string(forKey: "selectedPlayer") ?? "rocket"
        send(Packet(kind: .player, value: nil, startTime: nil, text: style))
    }

    private func resolveDuplicatePlayer(remoteStyle: String) {
        let current = UserDefaults.standard.string(forKey: "selectedPlayer") ?? "rocket"
        guard current == remoteStyle else { return }
        let keepsSelection = mode == .nearby ? isNearbyHost : isMatchHost
        guard !keepsSelection else { return }
        let replacement = ["rocket", "dino", "m5", "eagle"].first { $0 != remoteStyle } ?? "dino"
        UserDefaults.standard.set(replacement, forKey: "selectedPlayer")
        onPlayerStyleResolved?(replacement)
        message = "\(remoteStyle.uppercased()) war schon vergeben. Du spielst als \(replacement.uppercased())."
    }

    private func reset(keepVisible: Bool) {
        clockTask?.cancel()
        clockTask = nil
        match = nil
        didScheduleStart = false
        opponentName = "GEGNER"
        localScore = 0
        remoteScore = 0
        remotePlayerStyle = "rocket"
        secondsLeft = 60
        phase = keepVisible ? .finding : .idle
    }

    private func nearbyConnected(to peer: MCPeerID) {
        opponentName = peer.displayName
        phase = .waiting
        advertiser?.stopAdvertisingPeer()
        if isNearbyHost, !didScheduleStart {
            didScheduleStart = true
            let start = Date().timeIntervalSince1970 + 2.5
            send(Packet(kind: .start, value: nil, startTime: start))
            scheduleStart(at: start)
        }
    }

    private func configureNearbyNetwork() {
        nearbyNetworkConnected = false
        nearbyNetwork.onStatus = { [weak self] text in
            Task { @MainActor in self?.opponentName = text }
        }
        nearbyNetwork.onConnected = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.nearbyNetworkConnected = true
                self.opponentName = "VERBUNDEN"
                self.phase = .waiting
                self.sendPlayerStyle()
                if self.isNearbyHost, !self.didScheduleStart {
                    self.didScheduleStart = true
                    let start = Date().timeIntervalSince1970 + 2.5
                    self.send(Packet(kind: .start, value: nil, startTime: start))
                    self.scheduleStart(at: start)
                }
            }
        }
        nearbyNetwork.onData = { [weak self] data in
            Task { @MainActor in self?.receive(data) }
        }
        nearbyNetwork.onError = { [weak self] text in
            Task { @MainActor in
                guard let self, self.phase != .idle, self.phase != .finished else { return }
                self.message = text
                self.reset(keepVisible: false)
            }
        }
    }

    private func stopNearby() {
        nearbyNetwork.stop()
        nearbyNetworkConnected = false
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browserController?.dismiss(animated: true)
        browserController = nil
        nearbySession.disconnect()
    }

    private func present(_ controller: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \ .isKeyWindow)?.rootViewController else { return }
        var presenter = root
        while let shown = presenter.presentedViewController { presenter = shown }
        presenter.present(controller, animated: true)
    }

    private struct Packet: Codable {
        enum Kind: String, Codable { case player, start, score, finish }
        let kind: Kind
        let value: Int?
        let startTime: TimeInterval?
        var text: String? = nil
    }
}

extension MultiplayerManager: @preconcurrency MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(nearbySession.connectedPeers.isEmpty, nearbySession)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        message = "Nahes Spiel konnte nicht gestartet werden. Prüfe WLAN und Bluetooth."
        reset(keepVisible: false)
    }
}

extension MultiplayerManager: @preconcurrency MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
        phase = .waiting
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
        reset(keepVisible: false)
    }
}

extension MultiplayerManager: @preconcurrency MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch state {
            case .connected: self.nearbyConnected(to: peerID)
            case .notConnected where self.phase != .idle && self.phase != .finished:
                self.message = "Das andere Gerät ist nicht mehr verbunden."
                self.reset(keepVisible: false)
            default: break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor [weak self] in self?.receive(data) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                             fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultiplayerManager: @preconcurrency GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        reset(keepVisible: false)
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        message = error.localizedDescription
        reset(keepVisible: false)
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        connected(match)
    }
}

extension MultiplayerManager: @preconcurrency GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        receive(data)
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .connected { connected(match) }
        if state == .disconnected, phase != .finished {
            message = "Die Verbindung zum Gegner wurde getrennt."
            reset(keepVisible: false)
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        message = error?.localizedDescription ?? "Multiplayer-Verbindung fehlgeschlagen."
        reset(keepVisible: false)
    }
}
