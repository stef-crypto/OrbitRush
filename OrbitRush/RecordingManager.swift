import ReplayKit
import UIKit
import Combine

@MainActor
final class RecordingManager: NSObject, ObservableObject, @preconcurrency RPPreviewViewControllerDelegate {
    static let shared = RecordingManager()

    @Published private(set) var isRecording = false
    @Published private(set) var isBusy = false

    func toggleRecording() {
        guard !isBusy else { return }
        isRecording ? stop() : start()
    }

    private func start() {
        let recorder = RPScreenRecorder.shared()
        guard recorder.isAvailable else { return }
        isBusy = true
        recorder.isMicrophoneEnabled = false
        recorder.startRecording { [weak self] error in
            Task { @MainActor in
                self?.isBusy = false
                self?.isRecording = error == nil
                if let error { print("ReplayKit start: \(error.localizedDescription)") }
            }
        }
    }

    private func stop() {
        isBusy = true
        RPScreenRecorder.shared().stopRecording { [weak self] preview, error in
            Task { @MainActor in
                guard let self else { return }
                self.isBusy = false
                self.isRecording = false
                if let error { print("ReplayKit stop: \(error.localizedDescription)") }
                guard let preview else { return }
                preview.previewControllerDelegate = self
                self.present(preview)
            }
        }
    }

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true)
    }

    private func present(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        presenter.present(viewController, animated: true)
    }
}
