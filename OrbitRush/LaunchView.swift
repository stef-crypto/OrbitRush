import SwiftUI

struct LaunchView: View {
    @State private var orbitRotation = -35.0
    @State private var glow = false
    @State private var progress = 0.08

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.015, green: 0.025, blue: 0.08), Color(red: 0.045, green: 0.02, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            stars

            VStack(spacing: 34) {
                ZStack {
                    Circle()
                        .stroke(Color.cyan.opacity(0.26), lineWidth: 2)
                        .frame(width: 220, height: 220)
                        .scaleEffect(x: 1, y: 0.42)
                        .rotationEffect(.degrees(-18))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange, .red.opacity(0.9)],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 75
                            )
                        )
                        .frame(width: 122, height: 122)
                        .shadow(color: .red.opacity(glow ? 0.85 : 0.42), radius: glow ? 38 : 20)

                    rocketImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 62, height: 62)
                        .offset(y: -110)
                        .rotationEffect(.degrees(orbitRotation + 90))
                        .rotationEffect(.degrees(orbitRotation), anchor: .bottom)
                        .shadow(color: .cyan, radius: 9)
                }
                .frame(height: 270)

                VStack(spacing: 8) {
                    Text("ORBIT RUSH")
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .tracking(1.5)
                    Text("EIN FINGER. UNENDLICH WEIT.")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.7)
                        .foregroundStyle(.cyan)
                }

                VStack(spacing: 10) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * progress)
                                .shadow(color: .cyan.opacity(0.7), radius: 7)
                        }
                    }
                    .frame(width: 210, height: 7)

                    Text("GALAXIE WIRD GELADEN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
            .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.45)) {
                orbitRotation = 325
                progress = 1
            }
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var stars: some View {
        Canvas { context, size in
            for index in 0..<70 {
                let x = CGFloat((index * 83) % 997) / 997 * size.width
                let y = CGFloat((index * 137) % 991) / 991 * size.height
                let radius = CGFloat(index % 3 + 1) * 0.55
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.2 + Double(index % 5) * 0.1)))
            }
        }
        .ignoresSafeArea()
    }

    private var rocketImage: Image {
        if let url = Bundle.main.url(forResource: "rocket", withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: image)
        }
        return Image(systemName: "paperplane.fill")
    }
}
