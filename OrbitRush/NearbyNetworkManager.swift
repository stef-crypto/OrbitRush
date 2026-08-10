import Foundation
import Network

final class NearbyNetworkManager {
    private let queue = DispatchQueue(label: "com.stefko.orbitrush.nearby")
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private var didChooseResult = false

    var onConnected: (() -> Void)?
    var onData: ((Data) -> Void)?
    var onStatus: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var isConnected: Bool { connection != nil }

    func host() {
        stop()
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters, on: .any)
            listener.service = .init(name: String(ProcessInfo.processInfo.hostName.prefix(32)), type: "_orbitrush._tcp")
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready: self?.onStatus?("Warte auf das zweite Gerät …")
                case .failed: self?.onError?("Spiel konnte nicht erstellt werden. Prüfe die lokale Netzwerkfreigabe.")
                default: break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                guard self?.connection == nil else { connection.cancel(); return }
                self?.activate(connection)
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch { onError?("Spiel konnte nicht erstellt werden.") }
    }

    func search() {
        stop()
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_orbitrush._tcp", domain: nil), using: parameters)
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready: self?.onStatus?("Suche nach Orbit Rush in deiner Nähe …")
            case .waiting: self?.onStatus?("Warte auf lokale Netzwerkfreigabe …")
            case .failed: self?.onError?("Suche fehlgeschlagen. Prüfe WLAN und die lokale Netzwerkfreigabe.")
            default: break
            }
        }
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self, !self.didChooseResult, let result = results.first else { return }
            self.didChooseResult = true
            self.onStatus?("Gerät gefunden – verbinde …")
            self.activate(NWConnection(to: result.endpoint, using: parameters))
        }
        self.browser = browser
        browser.start(queue: queue)
    }

    func send(_ data: Data) {
        guard let connection else { return }
        var length = UInt32(data.count).bigEndian
        var framed = Data(bytes: &length, count: 4)
        framed.append(data)
        connection.send(content: framed, completion: .contentProcessed { [weak self] error in
            if error != nil { self?.onError?("Verbindung zum anderen Gerät verloren.") }
        })
    }

    func stop() {
        listener?.cancel(); browser?.cancel(); connection?.cancel()
        listener = nil; browser = nil; connection = nil
        receiveBuffer.removeAll(keepingCapacity: false)
        didChooseResult = false
    }

    private func activate(_ connection: NWConnection) {
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.listener?.cancel(); self?.browser?.cancel()
                self?.onConnected?(); self?.receiveNext()
            case .failed: self?.onError?("Verbindung zum anderen Gerät verloren.")
            default: break
            }
        }
        connection.start(queue: queue)
    }

    private func receiveNext() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            guard let self else { return }
            if let data { self.receiveBuffer.append(data); self.consumeFrames() }
            if error != nil || complete { self.onError?("Verbindung zum anderen Gerät verloren."); return }
            self.receiveNext()
        }
    }

    private func consumeFrames() {
        while receiveBuffer.count >= 4 {
            let length = receiveBuffer.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            guard length <= 65_536 else { onError?("Ungültige Spieldaten empfangen."); stop(); return }
            let end = 4 + Int(length)
            guard receiveBuffer.count >= end else { return }
            let payload = receiveBuffer.subdata(in: 4..<end)
            receiveBuffer.removeSubrange(0..<end)
            onData?(payload)
        }
    }
}
