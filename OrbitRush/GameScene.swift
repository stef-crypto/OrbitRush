import SpriteKit
import UIKit

final class GameScene: SKScene {
    private enum State { case ready, orbiting, flying, gameOver }
    private enum SpaceZone: Int {
        case deepSpace, neonNebula, solarStorm, void

        var title: String {
            switch self {
            case .deepSpace: return "DEEP SPACE"
            case .neonNebula: return "NEON NEBULA"
            case .solarStorm: return "SOLAR STORM"
            case .void: return "THE VOID"
            }
        }

        var background: UIColor {
            switch self {
            case .deepSpace: return UIColor(red: 0.025, green: 0.035, blue: 0.09, alpha: 1)
            case .neonNebula: return UIColor(red: 0.09, green: 0.018, blue: 0.13, alpha: 1)
            case .solarStorm: return UIColor(red: 0.12, green: 0.035, blue: 0.018, alpha: 1)
            case .void: return UIColor(red: 0.012, green: 0.008, blue: 0.03, alpha: 1)
            }
        }

        var planetColors: [UIColor] {
            switch self {
            case .deepSpace: return [.systemPink, .systemOrange, .systemPurple, .systemTeal, .systemYellow]
            case .neonNebula: return [.systemPink, .systemPurple, .magenta, .systemCyan]
            case .solarStorm: return [.systemOrange, .systemRed, .systemYellow, .brown]
            case .void: return [.systemIndigo, .darkGray, .systemPurple, .white]
            }
        }
    }

    private let player = SKShapeNode(circleOfRadius: 10)
    private let playerSprite = SKSpriteNode()
    private let trail = SKEmitterNode()
    private let shieldAura = SKShapeNode(circleOfRadius: 35)
    private let cameraNode = SKCameraNode()
    private var aimDots: [SKShapeNode] = []
    private var currentPlanet = PlanetNode(radius: 43, color: .systemIndigo)
    private var targetPlanet = PlanetNode(radius: 36, color: .systemPink)
    private var state: State = .ready
    private var orbitAngle: CGFloat = -.pi / 2
    private var orbitDirection: CGFloat = 1
    private var orbitSpeed: CGFloat = 2.2
    private var flightVelocity = CGVector.zero
    private var lastTurnTime: TimeInterval = -1
    private var steeringPoint: CGPoint?
    private var playerGestureStart: CGPoint?
    private var playerGesturePoint: CGPoint?
    private var planetImages: [UIImage] = []
    private var lastUpdate: TimeInterval = 0
    private var score = 0
    private var combo = 0
    private var orbitTravel: CGFloat = 0
    private var orbitWaitTime: TimeInterval = 0
    private let orbitGraceTime: TimeInterval = 3.5
    private let orbitCountdownTime: TimeInterval = 3
    private var flightTime: TimeInterval = 0
    private var bestScore = UserDefaults.standard.integer(forKey: "bestScore")
    private var coins = UserDefaults.standard.integer(forKey: "coins")
    private var runCoins = 0
    private var hasShield = false
    private var collectible: SKShapeNode?
    private var asteroids: [SKShapeNode] = []
    private var projectiles: [ProjectileNode] = []
    var onScoreChanged: ((Int) -> Void)?
    private var multiplayerRoundActive = false
    private var multiplayerTotalScore = 0
    private var currentZone: SpaceZone = .deepSpace

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let shieldLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let summaryLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let orbitTimerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let zoneLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(cameraNode)
        camera = cameraNode
        backgroundColor = UIColor(red: 0.025, green: 0.035, blue: 0.09, alpha: 1)
        setupStars()
        setupHUD()
        setupPlayer()
        setPlayerStyle(UserDefaults.standard.string(forKey: "selectedPlayer") ?? "rocket")
        layoutGame(reset: true)
        SoundManager.shared.startMusic()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        layoutHUD()
        if oldSize != .zero { layoutGame(reset: false) }
    }

    private func setupStars() {
        for _ in 0..<90 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.6...1.8))
            star.fillColor = .white.withAlphaComponent(CGFloat.random(in: 0.2...0.75))
            star.strokeColor = .clear
            star.position = randomPoint(margin: 8)
            star.name = "star"
            star.zPosition = -10
            addChild(star)
        }
    }

    private func setupHUD() {
        scoreLabel.fontSize = 52
        scoreLabel.text = "0"
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        bestLabel.fontSize = 15
        bestLabel.fontColor = .white.withAlphaComponent(0.55)
        bestLabel.text = "BEST  \(bestScore)"
        bestLabel.zPosition = 20
        addChild(bestLabel)

        comboLabel.fontSize = 17
        comboLabel.fontColor = .systemYellow
        comboLabel.alpha = 0
        comboLabel.zPosition = 20
        addChild(comboLabel)

        coinLabel.fontSize = 16
        coinLabel.fontColor = .systemYellow
        coinLabel.text = "✦  \(coins)"
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.zPosition = 20
        addChild(coinLabel)

        shieldLabel.fontSize = 14
        shieldLabel.fontColor = .systemCyan
        shieldLabel.text = ""
        shieldLabel.horizontalAlignmentMode = .right
        shieldLabel.zPosition = 20
        addChild(shieldLabel)

        summaryLabel.fontSize = 16
        summaryLabel.fontColor = .white.withAlphaComponent(0.65)
        summaryLabel.alpha = 0
        summaryLabel.zPosition = 20
        addChild(summaryLabel)

        orbitTimerLabel.fontSize = 30
        orbitTimerLabel.fontColor = .systemYellow
        orbitTimerLabel.zPosition = 40
        orbitTimerLabel.alpha = 0
        addChild(orbitTimerLabel)

        zoneLabel.fontSize = 10
        zoneLabel.fontColor = .systemCyan
        zoneLabel.text = currentZone.title
        zoneLabel.zPosition = 20
        addChild(zoneLabel)

        titleLabel.fontSize = 37
        titleLabel.text = "ORBIT RUSH"
        titleLabel.zPosition = 20
        addChild(titleLabel)

        instructionLabel.fontSize = 18
        instructionLabel.fontColor = .white.withAlphaComponent(0.72)
        instructionLabel.text = "TIPPE ZUM STARTEN"
        instructionLabel.zPosition = 20
        addChild(instructionLabel)
        layoutHUD()
    }

    private func layoutHUD() {
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - 88)
        bestLabel.position = CGPoint(x: 0, y: size.height / 2 - 116)
        comboLabel.position = CGPoint(x: 0, y: size.height / 2 - 145)
        titleLabel.position = CGPoint(x: 0, y: 118)
        instructionLabel.position = CGPoint(x: 0, y: 78)
        coinLabel.position = CGPoint(x: -size.width / 2 + 22, y: size.height / 2 - 92)
        shieldLabel.position = CGPoint(x: size.width / 2 - 22, y: size.height / 2 - 92)
        summaryLabel.position = CGPoint(x: 0, y: 45)
        zoneLabel.position = CGPoint(x: 0, y: size.height / 2 - 164)
    }

    private func setupPlayer() {
        player.fillColor = .clear
        player.strokeColor = .clear
        player.zPosition = 10
        addChild(player)

        playerSprite.size = CGSize(width: 48, height: 48)
        playerSprite.zPosition = 1
        player.addChild(playerSprite)

        shieldAura.fillColor = .systemCyan.withAlphaComponent(0.08)
        shieldAura.strokeColor = .systemCyan.withAlphaComponent(0.8)
        shieldAura.lineWidth = 2
        shieldAura.glowWidth = 12
        shieldAura.zPosition = 0
        shieldAura.isHidden = true
        shieldAura.run(.repeatForever(.sequence([
            .group([.scale(to: 1.14, duration: 0.55), .fadeAlpha(to: 0.42, duration: 0.55)]),
            .group([.scale(to: 1, duration: 0.55), .fadeAlpha(to: 1, duration: 0.55)])
        ])))
        player.addChild(shieldAura)

        trail.particleTexture = nil
        trail.particleBirthRate = 75
        trail.particleLifetime = 0.28
        trail.particleScale = 0.11
        trail.particleScaleRange = 0.05
        trail.particleAlphaSpeed = -3.5
        trail.particleColor = .systemCyan
        trail.particleColorBlendFactor = 1
        trail.targetNode = self
        player.addChild(trail)

        for index in 0..<7 {
            let dot = SKShapeNode(circleOfRadius: max(1.5, 3.4 - CGFloat(index) * 0.28))
            dot.fillColor = .systemCyan.withAlphaComponent(0.75 - CGFloat(index) * 0.075)
            dot.strokeColor = .clear
            dot.glowWidth = 3
            dot.zPosition = 8
            dot.isHidden = true
            addChild(dot)
            aimDots.append(dot)
        }
    }

    private func layoutGame(reset: Bool) {
        if reset {
            currentPlanet.removeFromParent()
            targetPlanet.removeFromParent()
            addChild(currentPlanet)
            addChild(targetPlanet)
        }
        currentPlanet.position = CGPoint(x: -size.width * 0.20, y: -size.height * 0.15)
        targetPlanet.position = CGPoint(x: size.width * 0.23, y: size.height * 0.14)
        placePlayerOnOrbit()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .ready:
            state = .orbiting
            SoundManager.shared.play(.start)
            titleLabel.run(.fadeOut(withDuration: 0.2))
            instructionLabel.text = "TIPPE ZUM SPRINGEN"
            instructionLabel.run(.sequence([.wait(forDuration: 1.4), .fadeOut(withDuration: 0.5)]))
        case .orbiting:
            guard let touchPoint = touches.first?.location(in: self) else { return }
            playerGestureStart = touchPoint
            playerGesturePoint = touchPoint
        case .flying:
            guard let touchPoint = touches.first?.location(in: self) else { return }
            if hypot(touchPoint.x - player.position.x, touchPoint.y - player.position.y) < 58 {
                playerGestureStart = touchPoint
                playerGesturePoint = touchPoint
            } else {
                steeringPoint = touchPoint
            }
        case .gameOver:
            restart()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard state == .flying || state == .orbiting else { return }
        guard let point = touches.first?.location(in: self) else { return }
        if playerGestureStart != nil {
            playerGesturePoint = point
        } else {
            steeringPoint = point
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let start = playerGestureStart {
            let end = touches.first?.location(in: self) ?? playerGesturePoint ?? start
            let dx = end.x - start.x
            let dy = end.y - start.y
            if state == .orbiting {
                if hypot(dx, dy) >= 30 {
                    fireProjectile(dx: dx, dy: dy)
                } else {
                    launch()
                }
            } else if state == .flying {
                if hypot(dx, dy) >= 30 {
                    fireProjectile(dx: dx, dy: dy)
                } else if flightTime - lastTurnTime > 0.12 {
                    performEmergencyTurn()
                }
            }
        }
        playerGestureStart = nil
        playerGesturePoint = nil
        steeringPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerGestureStart = nil
        playerGesturePoint = nil
        steeringPoint = nil
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 1.0 / 30.0)
        lastUpdate = currentTime
        guard dt > 0 else { return }

        moveStars(by: CGFloat(dt))
        asteroids.forEach { $0.zRotation += CGFloat(dt) * 0.7 }
        updateProjectiles(dt: CGFloat(dt))

        switch state {
        case .orbiting:
            let step = orbitSpeed * CGFloat(dt)
            orbitAngle += step * orbitDirection
            orbitTravel += step
            orbitWaitTime += dt
            placePlayerOnOrbit()
            updateAimGuide()
            updateOrbitTimer()
        case .flying:
            flightTime += dt
            applySteering(dt: CGFloat(dt))
            player.position.x += flightVelocity.dx * CGFloat(dt)
            player.position.y += flightVelocity.dy * CGFloat(dt)
            checkFlight()
        default:
            break
        }
    }

    private func placePlayerOnOrbit() {
        let distance = currentPlanet.radius + 24
        player.position = CGPoint(
            x: currentPlanet.position.x + cos(orbitAngle) * distance,
            y: currentPlanet.position.y + sin(orbitAngle) * distance
        )
        playerSprite.zRotation = orbitAngle + (orbitDirection > 0 ? 0 : .pi)
    }

    private func launch() {
        state = .flying
        hideOrbitTimer()
        setAimGuideVisible(false)
        flightTime = 0
        lastTurnTime = -1
        let speed: CGFloat = 310 + min(CGFloat(score) * 8, 100)
        flightVelocity = CGVector(
            dx: -sin(orbitAngle) * speed * orbitDirection,
            dy: cos(orbitAngle) * speed * orbitDirection
        )
        updatePlayerRotation()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        SoundManager.shared.play(.launch)
    }

    private func updateOrbitTimer() {
        guard orbitWaitTime >= orbitGraceTime else {
            orbitTimerLabel.alpha = 0
            return
        }
        let remaining = max(0, orbitCountdownTime - (orbitWaitTime - orbitGraceTime))
        let number = max(1, Int(ceil(remaining)))
        let newText = "\(number)"
        orbitTimerLabel.position = CGPoint(x: currentPlanet.position.x,
                                           y: currentPlanet.position.y + currentPlanet.radius + 54)
        if orbitTimerLabel.text != newText {
            orbitTimerLabel.text = newText
            orbitTimerLabel.setScale(1.45)
            orbitTimerLabel.run(.scale(to: 1, duration: 0.18))
            UIImpactFeedbackGenerator(style: remaining <= 1 ? .heavy : .light).impactOccurred()
        }
        orbitTimerLabel.alpha = 1
        if remaining <= 0 {
            showCenterMessage("AUTO-START!", color: .systemOrange)
            launch()
        }
    }

    private func hideOrbitTimer() {
        orbitWaitTime = 0
        orbitTimerLabel.removeAllActions()
        orbitTimerLabel.alpha = 0
        orbitTimerLabel.text = nil
    }

    private func performEmergencyTurn() {
        lastTurnTime = flightTime
        steeringPoint = nil
        let targetAngle = atan2(targetPlanet.position.y - player.position.y,
                                targetPlanet.position.x - player.position.x)
        // A rescue shot aims toward the planet, but luck decides how accurate it is.
        let lucky = Int.random(in: 0..<100) < 65
        let error = lucky ? CGFloat.random(in: -0.10...0.10) : CGFloat.random(in: -0.30...0.30)
        let rescueAngle = targetAngle + error
        let speed = max(hypot(flightVelocity.dx, flightVelocity.dy), 310)
        flightVelocity.dx = cos(rescueAngle) * speed
        flightVelocity.dy = sin(rescueAngle) * speed
        let targetRotation = atan2(flightVelocity.dy, flightVelocity.dx) - .pi / 2
        playerSprite.removeAllActions()
        playerSprite.run(.rotate(toAngle: targetRotation, duration: 0.13, shortestUnitArc: true))
        burst(at: player.position, color: .systemPurple)
        showCenterMessage(lucky ? "LUCKY TURN!" : "RETTUNGSVERSUCH!", color: .systemPurple)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        SoundManager.shared.play(.turn)
    }

    private func fireProjectile(dx: CGFloat, dy: CGFloat) {
        let length = max(hypot(dx, dy), 1)
        let direction = CGVector(dx: dx / length, dy: dy / length)
        let projectile = ProjectileNode()
        projectile.position = CGPoint(x: player.position.x + direction.dx * 30,
                                      y: player.position.y + direction.dy * 30)
        projectile.velocity = CGVector(dx: direction.dx * 590, dy: direction.dy * 590)
        projectile.zRotation = atan2(direction.dy, direction.dx)
        addChild(projectile)
        projectiles.append(projectile)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        SoundManager.shared.play(.shoot)
    }

    private func updateProjectiles(dt: CGFloat) {
        guard !projectiles.isEmpty else { return }
        var removedProjectileIDs = Set<ObjectIdentifier>()
        var removedAsteroidIDs = Set<ObjectIdentifier>()

        for projectile in projectiles {
            projectile.position.x += projectile.velocity.dx * dt
            projectile.position.y += projectile.velocity.dy * dt

            if abs(projectile.position.x) > size.width / 2 + 40 || abs(projectile.position.y) > size.height / 2 + 40 {
                removedProjectileIDs.insert(ObjectIdentifier(projectile))
                continue
            }

            if let coin = collectible,
               hypot(projectile.position.x - coin.position.x, projectile.position.y - coin.position.y) < 22 {
                removedProjectileIDs.insert(ObjectIdentifier(projectile))
                collectible = nil
                burst(at: coin.position, color: .systemRed)
                coin.removeFromParent()
                showCenterMessage("BONUS ZERSTÖRT!", color: .systemRed)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                continue
            }

            for asteroid in asteroids where !removedAsteroidIDs.contains(ObjectIdentifier(asteroid)) {
                if hypot(projectile.position.x - asteroid.position.x, projectile.position.y - asteroid.position.y) < 31 {
                    removedProjectileIDs.insert(ObjectIdentifier(projectile))
                    removedAsteroidIDs.insert(ObjectIdentifier(asteroid))
                    burst(at: asteroid.position, color: .systemOrange)
                    flash(color: .systemOrange, alpha: 0.16)
                    shake(intensity: 7)
                    asteroid.removeFromParent()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    SoundManager.shared.play(.explosion)
                    ProgressManager.shared.recordAsteroid()
                    break
                }
            }
        }

        projectiles.removeAll { projectile in
            if removedProjectileIDs.contains(ObjectIdentifier(projectile)) {
                projectile.removeFromParent()
                return true
            }
            return false
        }
        asteroids.removeAll { removedAsteroidIDs.contains(ObjectIdentifier($0)) }
    }

    private func applySteering(dt: CGFloat) {
        guard let steeringPoint else { return }
        let dx = steeringPoint.x - player.position.x
        let dy = steeringPoint.y - player.position.y
        let distance = max(hypot(dx, dy), 1)
        // Strong enough to visibly correct a flight, while preserving the launch angle.
        let acceleration: CGFloat = 360
        flightVelocity.dx += dx / distance * acceleration * dt
        flightVelocity.dy += dy / distance * acceleration * dt

        let intendedSpeed: CGFloat = 310 + min(CGFloat(score) * 8, 100)
        let speed = max(hypot(flightVelocity.dx, flightVelocity.dy), 1)
        let clampedSpeed = min(max(speed, intendedSpeed * 0.88), intendedSpeed * 1.12)
        flightVelocity.dx = flightVelocity.dx / speed * clampedSpeed
        flightVelocity.dy = flightVelocity.dy / speed * clampedSpeed
        updatePlayerRotation()
    }

    private func updatePlayerRotation() {
        // All player art points upward; SpriteKit rotation zero points upward here.
        playerSprite.zRotation = atan2(flightVelocity.dy, flightVelocity.dx) - .pi / 2
    }

    private func updateAimGuide() {
        let direction = CGVector(dx: -sin(orbitAngle) * orbitDirection,
                                 dy: cos(orbitAngle) * orbitDirection)
        for (index, dot) in aimDots.enumerated() {
            let distance = CGFloat(index + 1) * 22 + 19
            dot.position = CGPoint(x: player.position.x + direction.dx * distance,
                                   y: player.position.y + direction.dy * distance)
            dot.isHidden = false
        }
    }

    private func setAimGuideVisible(_ visible: Bool) {
        aimDots.forEach { $0.isHidden = !visible }
    }

    func setPlayerStyle(_ name: String) {
        let validNames = ["rocket", "dino", "m5", "eagle"]
        let selected = validNames.contains(name) ? name : "rocket"
        playerSprite.texture = SKTexture(imageNamed: selected)
        playerSprite.texture?.filteringMode = .linear
        playerSprite.size = selected == "eagle" ? CGSize(width: 58, height: 58) : CGSize(width: 48, height: 48)
        UserDefaults.standard.set(selected, forKey: "selectedPlayer")
        playerSprite.run(.sequence([.scale(to: 1.25, duration: 0.1), .scale(to: 1, duration: 0.16)]))
        UISelectionFeedbackGenerator().selectionChanged()
        showCenterMessage("SPIELER: \(selected.uppercased())", color: .systemCyan)
    }

    func setTrailStyle(_ style: String) {
        switch style {
        case "gold":
            trail.particleColor = .systemYellow
            trail.particleBirthRate = 105
            trail.particleScale = 0.15
        case "neon":
            trail.particleColor = .systemPink
            trail.particleBirthRate = 120
            trail.particleScale = 0.13
        case "legend":
            trail.particleColor = .systemPurple
            trail.particleBirthRate = 95
            trail.particleScale = 0.19
        default:
            trail.particleColor = .systemCyan
            trail.particleBirthRate = 75
            trail.particleScale = 0.11
        }
        UserDefaults.standard.set(style, forKey: "selectedTrail")
        showCenterMessage("TRAIL: \(style.uppercased())", color: trail.particleColor)
    }

    private func checkFlight() {
        let dx = player.position.x - targetPlanet.position.x
        let dy = player.position.y - targetPlanet.position.y
        let captureDistance = targetPlanet.radius + 13
        if dx * dx + dy * dy <= captureDistance * captureDistance {
            captureTarget()
            return
        }


        if let collectible {
            let coinDistance = hypot(player.position.x - collectible.position.x, player.position.y - collectible.position.y)
            if coinDistance < 25 { collectCoin() }
        }

        for asteroid in asteroids {
            if hypot(player.position.x - asteroid.position.x, player.position.y - asteroid.position.y) < 27 {
                failOrUseShield(at: asteroid.position)
                return
            }
        }

        let margin: CGFloat = 75
        if abs(player.position.x) > size.width / 2 + margin || abs(player.position.y) > size.height / 2 + margin {
            failOrUseShield(at: player.position)
        }
    }

    private func captureTarget() {
        let towardTarget = CGVector(dx: targetPlanet.position.x - player.position.x,
                                    dy: targetPlanet.position.y - player.position.y)
        let targetLength = max(hypot(towardTarget.dx, towardTarget.dy), 1)
        let velocityLength = max(hypot(flightVelocity.dx, flightVelocity.dy), 1)
        let alignment = (towardTarget.dx * flightVelocity.dx + towardTarget.dy * flightVelocity.dy) / (targetLength * velocityLength)
        let isPerfect = alignment > 0.975
        let wasQuick = orbitTravel < .pi * 1.55
        combo = wasQuick ? combo + 1 : 0
        let comboBonus = combo >= 3 ? min(combo / 3, 3) : 0
        let planetBonus = targetPlanet.isBonus ? 2 : 0
        let gained = 1 + comboBonus + planetBonus + (isPerfect ? 1 : 0)
        score += gained
        updateSpaceZone()
        if multiplayerRoundActive {
            multiplayerTotalScore += gained
            onScoreChanged?(multiplayerTotalScore)
        } else {
            onScoreChanged?(score)
        }
        scoreLabel.text = "\(score)"
        scoreLabel.run(.sequence([.scale(to: 1.25, duration: 0.08), .scale(to: 1, duration: 0.12)]))
        showReward(points: gained, quick: wasQuick, bonus: targetPlanet.isBonus, perfect: isPerfect)
        burst(at: targetPlanet.position, color: targetPlanet.fillColor)
        if isPerfect {
            flash(color: .systemYellow, alpha: 0.13)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            SoundManager.shared.play(.coin)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ProgressManager.shared.recordLanding(perfect: isPerfect)

        if score >= 10 && score % 10 < gained && !hasShield {
            hasShield = true
            shieldAura.isHidden = false
            shieldLabel.text = "◉ SCHILD"
            showCenterMessage("SCHUTZSCHILD GELADEN", color: .systemCyan)
            SoundManager.shared.play(.shield)
        }

        let oldPlanet = currentPlanet
        currentPlanet = targetPlanet
        currentPlanet.pulse()
        orbitAngle = atan2(player.position.y - currentPlanet.position.y,
                           player.position.x - currentPlanet.position.x)

        let radial = CGVector(dx: cos(orbitAngle), dy: sin(orbitAngle))
        let cross = radial.dx * flightVelocity.dy - radial.dy * flightVelocity.dx
        orbitDirection = cross >= 0 ? 1 : -1
        orbitSpeed = min(2.2 + CGFloat(score) * 0.065, 4.4)
        orbitTravel = 0
        hideOrbitTimer()
        state = .orbiting
        setAimGuideVisible(true)

        oldPlanet.run(.sequence([.group([.fadeOut(withDuration: 0.25), .scale(to: 0.5, duration: 0.25)]), .removeFromParent()]))
        spawnTarget()
    }

    private func spawnTarget() {
        let colors = currentZone.planetColors
        let isBonus = score > 2 && Int.random(in: 0..<5) == 0
        targetPlanet = PlanetNode(
            radius: isBonus ? 27 : CGFloat.random(in: 31...44),
            color: isBonus ? .systemYellow : colors.randomElement()!,
            isBonus: isBonus,
            image: planetImages.randomElement()
        )
        var candidate = CGPoint.zero
        repeat {
            candidate = randomPoint(margin: 82)
        } while hypot(candidate.x - currentPlanet.position.x, candidate.y - currentPlanet.position.y) < 180
        targetPlanet.position = candidate
        targetPlanet.setScale(0.1)
        addChild(targetPlanet)
        targetPlanet.run(.springScale(to: 1, duration: 0.32))
        spawnExtras()
    }

    private func spawnExtras() {
        collectible?.removeFromParent()
        collectible = nil
        asteroids.forEach { $0.removeFromParent() }
        asteroids.removeAll()

        if Int.random(in: 0..<3) != 0 {
            let coin = SKShapeNode(circleOfRadius: 12)
            coin.fillColor = .systemYellow
            coin.strokeColor = .white
            coin.lineWidth = 2
            coin.glowWidth = 9
            coin.zPosition = 7
            let middle = CGPoint(x: (currentPlanet.position.x + targetPlanet.position.x) / 2,
                                 y: (currentPlanet.position.y + targetPlanet.position.y) / 2)
            coin.position = CGPoint(x: middle.x + CGFloat.random(in: -45...45), y: middle.y + CGFloat.random(in: -45...45))
            coin.run(.repeatForever(.sequence([.scale(to: 1.22, duration: 0.45), .scale(to: 0.88, duration: 0.45)])))
            addChild(coin)
            collectible = coin
        }

        guard score >= 8 else { return }
        let count = min(1 + score / 20, 3)
        for _ in 0..<count {
            let asteroid = makeAsteroid()
            var position = randomPoint(margin: 95)
            var attempts = 0
            while (hypot(position.x - currentPlanet.position.x, position.y - currentPlanet.position.y) < 105 ||
                   hypot(position.x - targetPlanet.position.x, position.y - targetPlanet.position.y) < 105) && attempts < 20 {
                position = randomPoint(margin: 95)
                attempts += 1
            }
            asteroid.position = position
            addChild(asteroid)
            asteroids.append(asteroid)
        }
    }

    private func makeAsteroid() -> SKShapeNode {
        let path = CGMutablePath()
        let points = 9
        for index in 0..<points {
            let angle = CGFloat(index) / CGFloat(points) * .pi * 2
            let radius = CGFloat.random(in: 17...27)
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = UIColor(white: 0.22, alpha: 1)
        node.strokeColor = .systemOrange.withAlphaComponent(0.75)
        node.lineWidth = 2
        node.glowWidth = 5
        node.zPosition = 5
        return node
    }

    private func collectCoin() {
        guard let coin = collectible else { return }
        collectible = nil
        coins += 1
        runCoins += 1
        ProgressManager.shared.recordCoin()
        UserDefaults.standard.set(coins, forKey: "coins")
        coinLabel.text = "✦  \(coins)"
        burst(at: coin.position, color: .systemYellow)
        coin.run(.sequence([.scale(to: 1.8, duration: 0.1), .fadeOut(withDuration: 0.12), .removeFromParent()]))
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        SoundManager.shared.play(.coin)
    }

    private func failOrUseShield(at point: CGPoint) {
        guard hasShield else {
            endGame()
            return
        }
        hasShield = false
        shieldAura.isHidden = true
        shieldLabel.text = ""
        steeringPoint = nil
        lastTurnTime = -1
        state = .orbiting
        setAimGuideVisible(true)
        orbitTravel = .pi * 2
        hideOrbitTimer()
        placePlayerOnOrbit()
        burst(at: point, color: .systemCyan)
        flash(color: .systemCyan, alpha: 0.18)
        shake(intensity: 9)
        showCenterMessage("SCHILD HAT DICH GERETTET", color: .systemCyan)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func showCenterMessage(_ text: String, color: UIColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.name = "transientFeedback"
        label.text = text
        label.fontSize = 17
        label.fontColor = color
        label.position = CGPoint(x: 0, y: 20)
        label.zPosition = 50
        addChild(label)
        label.run(.sequence([.fadeIn(withDuration: 0.08), .wait(forDuration: 0.9), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }

    private func endGame() {
        guard state != .gameOver else { return }
        if multiplayerRoundActive {
            recoverMultiplayerRun()
            return
        }
        state = .gameOver
        setAimGuideVisible(false)
        steeringPoint = nil
        playerGestureStart = nil
        playerGesturePoint = nil
        clearProjectiles()
        shieldAura.isHidden = true
        trail.particleBirthRate = 0
        player.removeAllActions()
        player.run(.sequence([.group([.fadeOut(withDuration: 0.25), .scale(to: 2.2, duration: 0.25)]), .hide()]))
        let isNewBest = score > bestScore
        bestScore = max(bestScore, score)
        UserDefaults.standard.set(bestScore, forKey: "bestScore")
        GameCenterManager.shared.submit(score: score)
        let dailyReward = ProgressManager.shared.recordRun(score: score)
        if dailyReward > 0 {
            coins += dailyReward
            UserDefaults.standard.set(coins, forKey: "coins")
            coinLabel.text = "✦  \(coins)"
        }
        bestLabel.text = "BEST  \(bestScore)"
        titleLabel.text = isNewBest ? "NEW BEST!" : "GAME OVER"
        titleLabel.fontColor = isNewBest ? .systemYellow : .white
        instructionLabel.text = "TIPPE FÜR NOCH EINE RUNDE"
        summaryLabel.text = dailyReward > 0
            ? "TAGESMISSION!  +\(dailyReward) ✦"
            : "SCORE  \(score)    •    +\(runCoins) ✦"
        comboLabel.run(.fadeOut(withDuration: 0.15))
        burst(at: player.position, color: .systemCyan)
        flash(color: .systemRed, alpha: 0.2)
        shake(intensity: 12)
        titleLabel.run(.fadeIn(withDuration: 0.25))
        instructionLabel.run(.fadeIn(withDuration: 0.25))
        summaryLabel.run(.fadeIn(withDuration: 0.25))
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        SoundManager.shared.play(.gameOver)
    }

    func startMultiplayerRound() {
        multiplayerRoundActive = true
        multiplayerTotalScore = 0
        restart()
        state = .orbiting
        titleLabel.text = "60 SECOND RUSH"
        titleLabel.fontColor = .systemCyan
        titleLabel.alpha = 1
        instructionLabel.text = "LOS!"
        instructionLabel.alpha = 1
        titleLabel.run(.sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.3)]))
        instructionLabel.run(.sequence([.wait(forDuration: 0.6), .fadeOut(withDuration: 0.25)]))
    }

    func startSoloGame() {
        isPaused = false
        restart()
        state = .ready
        titleLabel.text = "ORBIT RUSH"
        titleLabel.fontColor = .white
        titleLabel.alpha = 1
        instructionLabel.text = "TIPPE ZUM STARTEN"
        instructionLabel.alpha = 1
    }

    func pauseForMenu() {
        isPaused = true
    }

    private func updateSpaceZone() {
        let next: SpaceZone
        switch score {
        case 0..<8: next = .deepSpace
        case 8..<18: next = .neonNebula
        case 18..<30: next = .solarStorm
        default: next = .void
        }
        guard next != currentZone else { return }
        currentZone = next
        backgroundColor = next.background
        zoneLabel.text = next.title
        zoneLabel.fontColor = next.planetColors.first ?? .systemCyan
        enumerateChildNodes(withName: "star") { node, _ in
            (node as? SKShapeNode)?.fillColor = (next.planetColors.randomElement() ?? .white).withAlphaComponent(CGFloat.random(in: 0.25...0.72))
        }
        flash(color: next.planetColors.first ?? .systemCyan, alpha: 0.2)
        showCenterMessage(next.title, color: next.planetColors.first ?? .systemCyan)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func finishMultiplayerRound() {
        multiplayerRoundActive = false
        guard state != .gameOver else { return }
        endGame()
    }

    private func recoverMultiplayerRun() {
        state = .gameOver
        setAimGuideVisible(false)
        clearProjectiles()
        trail.particleBirthRate = 0
        burst(at: player.position, color: .systemRed)
        flash(color: .systemRed, alpha: 0.16)
        showCenterMessage("CRASH – WEITER!", color: .systemOrange)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        run(.sequence([.wait(forDuration: 0.65), .run { [weak self] in
            guard let self, self.multiplayerRoundActive else { return }
            self.restart()
            self.state = .orbiting
        }]))
    }

    private func restart() {
        isPaused = false
        childNode(withName: "pauseOverlay")?.removeFromParent()
        enumerateChildNodes(withName: "transientFeedback") { node, _ in node.removeFromParent() }
        player.removeAllActions()
        playerSprite.removeAllActions()
        scoreLabel.removeAllActions()
        comboLabel.removeAllActions()
        titleLabel.removeAllActions()
        instructionLabel.removeAllActions()
        summaryLabel.removeAllActions()

        score = 0
        currentZone = .deepSpace
        backgroundColor = currentZone.background
        zoneLabel.text = currentZone.title
        zoneLabel.fontColor = .systemCyan
        runCoins = 0
        combo = 0
        orbitTravel = 0
        hideOrbitTimer()
        flightTime = 0
        lastTurnTime = -1
        steeringPoint = nil
        playerGestureStart = nil
        playerGesturePoint = nil
        clearProjectiles()
        hasShield = false
        shieldAura.isHidden = true
        shieldLabel.text = ""
        collectible?.removeFromParent()
        collectible = nil
        asteroids.forEach { $0.removeFromParent() }
        asteroids.removeAll()
        scoreLabel.text = "0"
        scoreLabel.setScale(1)
        comboLabel.alpha = 0
        summaryLabel.alpha = 0
        orbitAngle = -.pi / 2
        orbitDirection = 1
        orbitSpeed = 2.2
        currentPlanet.removeFromParent()
        targetPlanet.removeFromParent()
        currentPlanet = PlanetNode(radius: 43, color: .systemIndigo)
        targetPlanet = PlanetNode(radius: 36, color: .systemPink)
        addChild(currentPlanet)
        addChild(targetPlanet)
        layoutGame(reset: false)
        player.isHidden = false
        player.alpha = 1
        player.setScale(1)
        playerSprite.alpha = 1
        playerSprite.setScale(1)
        titleLabel.fontColor = .white
        setTrailStyle(UserDefaults.standard.string(forKey: "selectedTrail") ?? "classic")
        titleLabel.alpha = 0
        instructionLabel.alpha = 0
        state = .orbiting
        setAimGuideVisible(true)
        lastUpdate = 0
    }

    private func clearProjectiles() {
        projectiles.forEach { $0.removeFromParent() }
        projectiles.removeAll()
    }

    private func flash(color: UIColor, alpha: CGFloat) {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: size.height + 40))
        overlay.fillColor = color
        overlay.strokeColor = .clear
        overlay.alpha = alpha
        overlay.zPosition = 500
        overlay.name = "transientFeedback"
        cameraNode.addChild(overlay)
        overlay.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
    }

    private func shake(intensity: CGFloat) {
        cameraNode.removeAction(forKey: "shake")
        let action = SKAction.sequence([
            .moveBy(x: -intensity, y: intensity * 0.55, duration: 0.025),
            .moveBy(x: intensity * 1.7, y: -intensity, duration: 0.035),
            .moveBy(x: -intensity * 0.7, y: intensity * 0.45, duration: 0.035),
            .move(to: .zero, duration: 0.04)
        ])
        cameraNode.run(action, withKey: "shake")
    }

    func togglePause() {
        if isPaused {
            isPaused = false
            childNode(withName: "pauseOverlay")?.removeFromParent()
        } else {
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.name = "pauseOverlay"
            label.text = "PAUSE"
            label.fontSize = 42
            label.position = CGPoint(x: 0, y: 0)
            label.zPosition = 100
            addChild(label)
            isPaused = true
        }
    }

    func pauseForBackground() {
        guard !isPaused, state == .orbiting || state == .flying else { return }
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.name = "pauseOverlay"
        label.text = "PAUSE"
        label.fontSize = 42
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 100
        addChild(label)
        isPaused = true
    }

    func setPlanetImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        planetImages = images
        currentPlanet.apply(image: images.randomElement()!)
        targetPlanet.apply(image: images.randomElement()!)
        showPhotoConfirmation(count: images.count)
    }

    private func showPhotoConfirmation(count: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.name = "transientFeedback"
        label.text = count == 1 ? "FOTO EINGEFÜGT" : "\(count) FOTOS EINGEFÜGT"
        label.fontSize = 16
        label.fontColor = .systemCyan
        label.position = CGPoint(x: 0, y: -size.height / 2 + 72)
        label.zPosition = 40
        addChild(label)
        label.run(.sequence([.fadeIn(withDuration: 0.1), .wait(forDuration: 1), .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    private func showReward(points: Int, quick: Bool, bonus: Bool, perfect: Bool) {
        let reward = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        reward.name = "transientFeedback"
        reward.text = perfect ? "PERFECT  +\(points)" : (bonus ? "GOLD  +\(points)" : "+\(points)")
        reward.fontSize = (bonus || perfect) ? 24 : 20
        reward.fontColor = (bonus || perfect) ? .systemYellow : .white
        reward.position = CGPoint(x: targetPlanet.position.x, y: targetPlanet.position.y + targetPlanet.radius + 20)
        reward.zPosition = 30
        addChild(reward)
        reward.run(.sequence([
            .group([.moveBy(x: 0, y: 38, duration: 0.55), .fadeOut(withDuration: 0.55)]),
            .removeFromParent()
        ]))

        if combo >= 3 {
            comboLabel.text = "QUICK COMBO  ×\(combo)"
            comboLabel.removeAllActions()
            comboLabel.run(.sequence([.fadeIn(withDuration: 0.08), .wait(forDuration: 0.65), .fadeOut(withDuration: 0.25)]))
        } else if !quick {
            comboLabel.alpha = 0
        }
    }

    private func burst(at point: CGPoint, color: UIColor) {
        for index in 0..<18 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.glowWidth = 3
            spark.position = point
            spark.zPosition = 15
            addChild(spark)
            let angle = (CGFloat(index) / 18) * .pi * 2 + CGFloat.random(in: -0.15...0.15)
            let distance = CGFloat.random(in: 45...105)
            spark.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.38),
                    .fadeOut(withDuration: 0.38),
                    .scale(to: 0.2, duration: 0.38)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func moveStars(by dt: CGFloat) {
        enumerateChildNodes(withName: "star") { [weak self] node, _ in
            guard let self else { return }
            node.position.y -= (8 + node.xScale * 5) * dt
            if node.position.y < -self.size.height / 2 {
                node.position.y = self.size.height / 2
                node.position.x = CGFloat.random(in: -self.size.width / 2...self.size.width / 2)
            }
        }
    }

    private func randomPoint(margin: CGFloat) -> CGPoint {
        let width = max(size.width / 2 - margin, 1)
        let height = max(size.height / 2 - margin, 1)
        return CGPoint(x: CGFloat.random(in: -width...width), y: CGFloat.random(in: -height...height))
    }
}

private final class ProjectileNode: SKShapeNode {
    var velocity = CGVector.zero

    override init() {
        super.init()
        path = CGPath(roundedRect: CGRect(x: -12, y: -3, width: 24, height: 6), cornerWidth: 3, cornerHeight: 3, transform: nil)
        fillColor = .systemCyan
        strokeColor = .white
        lineWidth = 1.5
        glowWidth = 9
        zPosition = 18
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class PlanetNode: SKShapeNode {
    let radius: CGFloat
    let isBonus: Bool

    init(radius: CGFloat, color: UIColor, isBonus: Bool = false, image: UIImage? = nil) {
        self.radius = radius
        self.isBonus = isBonus
        super.init()
        path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        fillColor = color
        strokeColor = color.withAlphaComponent(0.5)
        lineWidth = 5
        glowWidth = 16
        zPosition = 2

        let core = SKShapeNode(circleOfRadius: radius * 0.42)
        core.fillColor = .white.withAlphaComponent(0.12)
        core.strokeColor = .clear
        core.position = CGPoint(x: -radius * 0.22, y: radius * 0.22)
        addChild(core)

        if let image {
            apply(image: image)
        }

        if isBonus {
            let halo = SKShapeNode(circleOfRadius: radius + 11)
            halo.strokeColor = .systemYellow.withAlphaComponent(0.75)
            halo.fillColor = .clear
            halo.lineWidth = 2
            halo.glowWidth = 8
            halo.run(.repeatForever(.sequence([
                .group([.scale(to: 1.15, duration: 0.55), .fadeAlpha(to: 0.25, duration: 0.55)]),
                .group([.scale(to: 1, duration: 0), .fadeAlpha(to: 1, duration: 0)])
            ])))
            addChild(halo)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(image: UIImage) {
        fillTexture = SKTexture(image: image)
        fillColor = .white
    }

    func pulse() {
        run(.sequence([.scale(to: 1.13, duration: 0.1), .scale(to: 1, duration: 0.16)]))
    }
}

private extension SKAction {
    static func springScale(to value: CGFloat, duration: TimeInterval) -> SKAction {
        .sequence([.scale(to: value * 1.12, duration: duration * 0.62), .scale(to: value, duration: duration * 0.38)])
    }
}
