import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID {
        static let pro = "com.stefko.orbitrush.pro"
        static let neon = "com.stefko.orbitrush.neonpack"
        static let legends = "com.stefko.orbitrush.legendspack"
        static let multiplayer = "com.stefko.orbitrush.multiplayer"
        static let all = [pro, multiplayer, neon, legends]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIDs: Set<String> = []
    @Published var message: String?
    @Published var isBusy = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactions()
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    var ownsPro: Bool { purchasedIDs.contains(ProductID.pro) }
    var ownsNeon: Bool { ownsPro || purchasedIDs.contains(ProductID.neon) }
    var ownsLegends: Bool { ownsPro || purchasedIDs.contains(ProductID.legends) }
    var ownsMultiplayer: Bool {
#if DEBUG
        true
#else
        ownsPro || purchasedIDs.contains(ProductID.multiplayer)
#endif
    }

    func product(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    func refresh() async {
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { ProductID.all.firstIndex(of: $0.id)! < ProductID.all.firstIndex(of: $1.id)! }
            await refreshEntitlements()
        } catch {
            message = "Store momentan nicht erreichbar."
        }
    }

    func purchase(_ product: Product) async {
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verified(verification)
                purchasedIDs.insert(transaction.productID)
                await transaction.finish()
                message = "Kauf erfolgreich – danke!"
            case .pending:
                message = "Der Kauf wartet auf Bestätigung."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "Der Kauf konnte nicht abgeschlossen werden."
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = purchasedIDs.isEmpty ? "Keine früheren Käufe gefunden." : "Käufe wiederhergestellt."
        } catch {
            message = "Wiederherstellung fehlgeschlagen."
        }
    }

    private func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.revocationDate == nil else { continue }
            owned.insert(transaction.productID)
        }
        purchasedIDs = owned
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let transaction = try? Self.verified(result) else { continue }
                await self?.refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    nonisolated private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        try Self.verified(result)
    }

    private enum StoreError: Error { case failedVerification }
}
