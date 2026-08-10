import GameKit
import UIKit

@MainActor
final class GameCenterManager: NSObject, @preconcurrency GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()
    static let leaderboardID = "com.stefko.orbitrush.highscore"

    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                self.present(viewController)
            }
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            if let error {
                print("Game Center authentication: \(error.localizedDescription)")
            }
        }
    }

    func submit(score: Int) {
        guard GKLocalPlayer.local.isAuthenticated, score >= 0 else { return }
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID]
        ) { error in
            if let error {
                print("Leaderboard score upload: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }
        let controller = GKGameCenterViewController(state: .leaderboards)
        controller.gameCenterDelegate = self
        present(controller)
    }

    func reportAchievement(id: String, percent: Double) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = max(0, min(100, percent))
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error { print("Achievement upload: \(error.localizedDescription)") }
        }
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
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
