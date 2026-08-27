import SwiftUI
import WatchKit

struct WatchGameView: View {
    @StateObject private var game = WatchGameModel()
    @State private var crownValue = 0.0
    @FocusState private var crownFocused: Bool

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    game.draw(in: context, size: size, date: timeline.date)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(game.score)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Spacer()
                    Text("BEST \(game.bestScore)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                if game.phase == .gameOver {
                    VStack(spacing: 4) {
                        Text("GAME OVER")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text("TIPPE FÜR NEUSTART")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.72), in: Capsule())
                } else {
                    Text(game.phase == .orbiting ? "TIPPE ZUM START" : "CROWN LENKT · TIPP RETTET")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(game.phase == .orbiting ? .cyan : .pink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.55), in: Capsule())
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if game.phase == .gameOver {
                game.restart()
            } else if game.phase == .orbiting {
                game.launch()
            } else {
                game.rescue()
            }
        }
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $crownValue,
            from: -100,
            through: 100,
            by: 0.25,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, value in
            game.steer(crownValue: value)
        }
        .onAppear {
            crownFocused = true
            game.start()
        }
        .onDisappear { game.stop() }
        .background(Color(red: 0.015, green: 0.022, blue: 0.07))
    }
}

@MainActor
final class WatchGameModel: ObservableObject {
    enum Phase { case orbiting, flying, gameOver }

    @Published private(set) var phase: Phase = .orbiting
    @Published private(set) var score = 0
    @Published private(set) var bestScore = UserDefaults.standard.integer(forKey: "watchBestScore")

    private var timer: Timer?
    private var lastTick = Date()
    private var orbitAngle = -Double.pi / 2
    private var orbitTime = 0.0
    private var player = CGPoint(x: 0.31, y: 0.63)
    private var velocity = CGVector(dx: 0, dy: 0)
    private var currentPlanet = CGPoint(x: 0.31, y: 0.53)
    private var targetPlanet = CGPoint(x: 0.70, y: 0.37)
    private var currentRadius = 0.115
    private var targetRadius = 0.095
    private var lastCrown = 0.0
    private var trail: [CGPoint] = []

    func start() {
        guard timer == nil else { return }
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func launch() {
        guard phase == .orbiting else { return }
        phase = .flying
        let tangent = orbitAngle + .pi / 2
        velocity = CGVector(dx: cos(tangent) * 0.34, dy: sin(tangent) * 0.34)
        WKInterfaceDevice.current().play(.start)
    }

    func rescue() {
        guard phase == .flying else { return }
        let dx = Double(targetPlanet.x - player.x)
        let dy = Double(targetPlanet.y - player.y)
        let length = max(hypot(dx, dy), 0.001)
        let luck = Double.random(in: -0.22...0.22)
        let angle = atan2(dy, dx) + luck
        velocity = CGVector(dx: cos(angle) * 0.37, dy: sin(angle) * 0.37)
        if length < 0.25 {
            velocity.dx *= 0.88
            velocity.dy *= 0.88
        }
        WKInterfaceDevice.current().play(.directionUp)
    }

    func steer(crownValue: Double) {
        let delta = crownValue - lastCrown
        lastCrown = crownValue
        guard phase == .flying, abs(delta) < 20 else { return }
        let angle = delta * 0.075
        let cosine = cos(angle)
        let sine = sin(angle)
        velocity = CGVector(
            dx: velocity.dx * cosine - velocity.dy * sine,
            dy: velocity.dx * sine + velocity.dy * cosine
        )
    }

    func restart() {
        score = 0
        orbitAngle = -.pi / 2
        currentPlanet = CGPoint(x: 0.31, y: 0.53)
        targetPlanet = CGPoint(x: 0.70, y: 0.37)
        currentRadius = 0.115
        targetRadius = 0.095
        trail.removeAll()
        phase = .orbiting
        placeOnOrbit()
        WKInterfaceDevice.current().play(.click)
    }

    private func tick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 0.05)
        lastTick = now

        switch phase {
        case .orbiting:
            orbitAngle += dt * (2.0 + Double(score) * 0.035)
            orbitTime += dt
            placeOnOrbit()
            if orbitTime > 5.5 { launch() }
        case .flying:
            player.x += velocity.dx * dt
            player.y += velocity.dy * dt
            trail.append(player)
            if trail.count > 16 { trail.removeFirst() }
            let distance = hypot(player.x - targetPlanet.x, player.y - targetPlanet.y)
            if distance < targetRadius + 0.025 {
                land()
            } else if player.x < -0.15 || player.x > 1.15 || player.y < -0.15 || player.y > 1.15 {
                endGame()
            }
        case .gameOver:
            break
        }
    }

    private func placeOnOrbit() {
        let radius = currentRadius + 0.035
        player = CGPoint(
            x: currentPlanet.x + cos(orbitAngle) * radius,
            y: currentPlanet.y + sin(orbitAngle) * radius
        )
    }

    private func land() {
        score += 1
        bestScore = max(bestScore, score)
        UserDefaults.standard.set(bestScore, forKey: "watchBestScore")
        currentPlanet = targetPlanet
        currentRadius = targetRadius
        let side = score.isMultiple(of: 2) ? 0.28 : 0.72
        targetPlanet = CGPoint(
            x: side + CGFloat.random(in: -0.07...0.07),
            y: CGFloat.random(in: 0.28...0.72)
        )
        targetRadius = Double.random(in: 0.075...0.105)
        orbitAngle = atan2(player.y - currentPlanet.y, player.x - currentPlanet.x)
        orbitTime = 0
        trail.removeAll()
        phase = .orbiting
        placeOnOrbit()
        WKInterfaceDevice.current().play(.success)
    }

    private func endGame() {
        phase = .gameOver
        trail.removeAll()
        WKInterfaceDevice.current().play(.failure)
    }

    func draw(in context: GraphicsContext, size: CGSize, date: Date) {
        var context = context
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(Path(bounds), with: .linearGradient(
            Gradient(colors: [Color(red: 0.01, green: 0.02, blue: 0.07), Color(red: 0.08, green: 0.015, blue: 0.12)]),
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: size.height)
        ))

        let pulse = 0.5 + sin(date.timeIntervalSinceReferenceDate * 1.8) * 0.12
        context.fill(
            Path(ellipseIn: CGRect(x: -size.width * 0.35, y: size.height * 0.08, width: size.width * 1.05, height: size.height * 0.55)),
            with: .radialGradient(
                Gradient(colors: [.purple.opacity(0.16), .blue.opacity(0.04), .clear]),
                center: CGPoint(x: size.width * 0.20, y: size.height * 0.28),
                startRadius: 2,
                endRadius: size.width * 0.55
            )
        )
        context.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.42, y: size.height * 0.40, width: size.width * 0.82, height: size.height * 0.52)),
            with: .radialGradient(
                Gradient(colors: [.cyan.opacity(0.10), .pink.opacity(0.035), .clear]),
                center: CGPoint(x: size.width * 0.76, y: size.height * 0.63),
                startRadius: 1,
                endRadius: size.width * 0.45
            )
        )

        for index in 0..<34 {
            let x = CGFloat((index * 79) % 331) / 331 * size.width
            let y = CGFloat((index * 113) % 337) / 337 * size.height
            let radius = CGFloat(index % 3 + 1) * 0.45
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.28)))
        }

        drawPlanet(currentPlanet, radius: currentRadius, colors: [.pink, .purple], in: &context, size: size)
        drawPlanet(targetPlanet, radius: targetRadius, colors: [.cyan, .blue], in: &context, size: size)

        let orbitRadius = (currentRadius + 0.035) * min(size.width, size.height)
        let orbitCenter = CGPoint(x: currentPlanet.x * size.width, y: currentPlanet.y * size.height)
        let orbitRect = CGRect(x: orbitCenter.x - orbitRadius, y: orbitCenter.y - orbitRadius,
                               width: orbitRadius * 2, height: orbitRadius * 2)
        context.stroke(Path(ellipseIn: orbitRect), with: .color(.white.opacity(0.13)),
                       style: StrokeStyle(lineWidth: 1, dash: [2, 4]))

        let targetR = targetRadius * min(size.width, size.height)
        let targetPoint = CGPoint(x: targetPlanet.x * size.width, y: targetPlanet.y * size.height)
        let pulseRadius = targetR + 5 + pulse * 3
        context.stroke(
            Path(ellipseIn: CGRect(x: targetPoint.x - pulseRadius, y: targetPoint.y - pulseRadius,
                                   width: pulseRadius * 2, height: pulseRadius * 2)),
            with: .color(.cyan.opacity(0.28)), lineWidth: 1.2
        )

        for (index, point) in trail.enumerated() {
            let alpha = Double(index + 1) / Double(max(trail.count, 1)) * 0.55
            let radius = 1.2 + CGFloat(index) / CGFloat(max(trail.count, 1)) * 1.8
            let rect = CGRect(x: point.x * size.width - radius, y: point.y * size.height - radius,
                              width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.cyan.opacity(alpha)))
            if index.isMultiple(of: 3) {
                context.fill(Path(ellipseIn: rect.insetBy(dx: 0.7, dy: 0.7)), with: .color(.pink.opacity(alpha * 0.75)))
            }
        }

        let point = CGPoint(x: player.x * size.width, y: player.y * size.height)
        let baseHeading = phase == .orbiting ? orbitAngle + .pi / 2 : atan2(velocity.dy, velocity.dx) + .pi / 2
        let sway = sin(date.timeIntervalSinceReferenceDate * 5.2) * (phase == .flying ? 0.075 : 0.035)
        let heading = baseHeading + sway

        if phase == .flying {
            let flamePoint = CGPoint(x: point.x - sin(heading) * 12, y: point.y + cos(heading) * 12)
            let flameRect = CGRect(x: flamePoint.x - 4, y: flamePoint.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: flameRect), with: .radialGradient(
                Gradient(colors: [.white, .cyan, .pink.opacity(0)]), center: flamePoint, startRadius: 0, endRadius: 5
            ))
        }

        let rocket = context.resolve(Image("rocket"))
        context.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: .radians(heading))
            layer.addFilter(.shadow(color: .cyan.opacity(0.85), radius: 4))
            layer.draw(rocket, in: CGRect(x: -13, y: -13, width: 26, height: 26))
        }
    }

    private func drawPlanet(_ center: CGPoint, radius: Double, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        let r = radius * min(size.width, size.height)
        let point = CGPoint(x: center.x * size.width, y: center.y * size.height)
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [.white.opacity(0.88), colors[0], colors[1], .black.opacity(0.72)]),
            center: CGPoint(x: rect.midX - r * 0.34, y: rect.midY - r * 0.34),
            startRadius: 1, endRadius: r
        ))
        context.stroke(Path(ellipseIn: rect), with: .color(colors[0].opacity(0.82)), lineWidth: 1.5)

        let highlight = CGRect(x: rect.minX + r * 0.32, y: rect.minY + r * 0.26, width: r * 0.34, height: r * 0.22)
        context.fill(Path(ellipseIn: highlight), with: .color(.white.opacity(0.16)))
    }
}
