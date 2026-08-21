import Foundation

@MainActor
final class ProgressManager {
    static let shared = ProgressManager()

    private let defaults = UserDefaults.standard

    var dailyGoal: Int {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return 15 + (day % 4) * 5
    }

    var dailyBest: Int {
        resetDailyIfNeeded()
        return defaults.integer(forKey: "dailyBest")
    }

    var level: Int { max(1, defaults.integer(forKey: "playerXP") / 100 + 1) }
    var xp: Int { defaults.integer(forKey: "playerXP") }
    var xpInLevel: Int { xp % 100 }

    func recordLanding(perfect: Bool) {
        increment("totalLandings")
        if perfect { increment("perfectLandings") }
        defaults.set(xp + (perfect ? 8 : 4), forKey: "playerXP")
        reportMilestones()
    }

    func recordCoin() {
        increment("totalCoinsCollected")
        reportMilestones()
    }

    func recordAsteroid() {
        increment("asteroidsDestroyed")
        defaults.set(xp + 2, forKey: "playerXP")
        reportMilestones()
    }

    /// Returns the daily mission reward when it is earned for the first time.
    func recordRun(score: Int) -> Int {
        resetDailyIfNeeded()
        increment("totalRuns")
        defaults.set(max(defaults.integer(forKey: "dailyBest"), score), forKey: "dailyBest")

        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.score10", percent: score >= 10 ? 100 : Double(score) * 10)
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.score25", percent: min(100, Double(score) * 4))
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.score50", percent: min(100, Double(score) * 2))

        if score >= dailyGoal && !defaults.bool(forKey: "dailyRewardClaimed") {
            defaults.set(true, forKey: "dailyRewardClaimed")
            return 25
        }
        return 0
    }

    private func reportMilestones() {
        let landings = defaults.integer(forKey: "totalLandings")
        let perfects = defaults.integer(forKey: "perfectLandings")
        let collected = defaults.integer(forKey: "totalCoinsCollected")
        let destroyed = defaults.integer(forKey: "asteroidsDestroyed")
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.landings100", percent: min(100, Double(landings)))
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.perfect25", percent: min(100, Double(perfects) * 4))
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.collector100", percent: min(100, Double(collected)))
        GameCenterManager.shared.reportAchievement(id: "com.stefko.orbitrush.hunter25", percent: min(100, Double(destroyed) * 4))
    }

    private func increment(_ key: String) {
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private func resetDailyIfNeeded() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard defaults.string(forKey: "dailyDate") != today else { return }
        defaults.set(today, forKey: "dailyDate")
        defaults.set(0, forKey: "dailyBest")
        defaults.set(false, forKey: "dailyRewardClaimed")
    }
}
