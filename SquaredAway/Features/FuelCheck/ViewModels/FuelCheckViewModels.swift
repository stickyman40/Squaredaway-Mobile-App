import Combine
import SwiftUI

@MainActor
final class FuelCheckViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var currentProduct: FuelProduct?
    @Published var currentScanId: UUID?
    @Published var showResult = false
    @Published var showAddToLog = false
    @Published var showPermissionAlert = false
    @Published var scannerActive = true
    @Published var recentScans: [FuelScan] = []
    @Published var savedProducts: [SavedProduct] = []
    @Published var isLoadingHistory = false
    @Published var userGoal: UserGoal = .maintenance
    @Published var isProductSaved = false
    @Published var errorMessage: String?

    private let service = BarcodeService.shared
    private var userId: UUID?

    func configure(userId: UUID, goal: UserGoal) {
        self.userId = userId
        self.userGoal = goal
    }

    func didScan(barcode: String) {
        guard scanState == .scanning || scanState == .idle else { return }
        scanState = .processing(barcode: barcode)
        scannerActive = false
        Task { await lookup(barcode: barcode) }
    }

    func resetScan() {
        withAnimation(AppTheme.Animation.standard) {
            scanState = .scanning
            showResult = false
            currentProduct = nil
            currentScanId = nil
            errorMessage = nil
        }

        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            scannerActive = true
            scanState = .idle
        }
    }

    func startScanning() {
        scanState = .scanning
        scannerActive = true
    }

    func toggleSaved() {
        guard let userId, let productId = currentProduct?.id else { return }

        Task {
            do {
                try await service.toggleSaved(productId: productId, userId: userId, currentlySaved: isProductSaved)
                withAnimation(AppTheme.Animation.spring) {
                    isProductSaved.toggle()
                }
                await loadSavedProducts()
            } catch {
                errorMessage = "Couldn't update saved products."
            }
        }
    }

    func loadHistory() async {
        guard let userId else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        async let scansResult = service.recentScans(userId: userId)
        async let savedResult = service.savedProducts(userId: userId)

        do {
            let (scans, saved) = try await (scansResult, savedResult)
            recentScans = scans
            savedProducts = saved
        } catch {
            errorMessage = "Couldn't load Fuel Check history."
        }
    }

    func loadSavedProducts() async {
        guard let userId else { return }
        savedProducts = (try? await service.savedProducts(userId: userId)) ?? []
    }

    func goalScore(for product: FuelProduct) -> Int {
        product.scores?.score(for: userGoal) ?? product.scores?.overall ?? 0
    }

    func handlePermissionDenied() {
        showPermissionAlert = true
        scannerActive = false
        scanState = .idle
    }

    private func lookup(barcode: String) async {
        guard let userId else {
            scanState = .idle
            return
        }

        do {
            let response = try await service.lookup(barcode: barcode, userId: userId, goal: userGoal)
            if response.found, let product = response.product {
                currentProduct = product
                currentScanId = response.scanId
                isProductSaved = savedProducts.contains { $0.productId == product.id }
                scanState = .found(product: product)
                withAnimation(AppTheme.Animation.spring) {
                    showResult = true
                }
            } else {
                scanState = .notFound(barcode: barcode)
            }
        } catch {
            errorMessage = error.localizedDescription
            scanState = .error(error.localizedDescription)
        }
    }
}

@MainActor
final class ChowLogViewModel: ObservableObject {
    @Published var summary: DailyNutritionSummary?
    @Published var goals: UserNutritionGoals?
    @Published var isLoading = false
    @Published var selectedDate = Date()
    @Published var showManualEntry = false
    @Published var errorMessage: String?
    @Published var manualName = ""
    @Published var manualCalories = ""
    @Published var manualProtein = ""
    @Published var manualCarbs = ""
    @Published var manualFat = ""
    @Published var manualMealType: MealType = .snack
    @Published var manualNotes = ""
    @Published var isLoggingManual = false

    private let service = BarcodeService.shared
    private var userId: UUID?

    func configure(userId: UUID) {
        self.userId = userId
    }

    var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var displayDate: String {
        if isToday { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task { await loadDay() }
    }

    func goToNextDay() {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        if next <= Date() {
            selectedDate = next
            Task { await loadDay() }
        }
    }

    func loadDay() async {
        guard let userId else { return }
        isLoading = true
        defer { isLoading = false }

        async let entriesResult = service.entriesForDate(selectedDateString, userId: userId)
        async let goalsResult = service.fetchGoals(userId: userId)

        do {
            let (entries, fetchedGoals) = try await (entriesResult, goalsResult)
            let resolvedGoals = fetchedGoals ?? UserNutritionGoals.defaults(for: .maintenance, userId: userId)
            goals = resolvedGoals
            summary = DailyNutritionSummary(date: selectedDateString, entries: entries, goals: resolvedGoals)
        } catch {
            errorMessage = "Couldn't load chow entries."
        }
    }

    func logProduct(
        _ product: FuelProduct,
        mealType: MealType,
        servings: Double,
        scanId: UUID?,
        notes: String? = nil
    ) async -> ChowEntry? {
        guard let userId else { return nil }

        let entry = ChowEntry(
            id: UUID(),
            userId: userId,
            mealType: mealType,
            servings: servings,
            source: .scan,
            productId: product.id,
            product: product,
            manualName: nil,
            manualCalories: nil,
            manualProteinG: nil,
            manualCarbsG: nil,
            manualFatG: nil,
            notes: notes,
            logDate: selectedDateString,
            loggedAt: Date(),
            updatedAt: Date()
        )

        do {
            let saved = try await service.logEntry(entry: entry)
            if let scanId {
                try? await service.markScanLogged(scanId: scanId, entryId: saved.id)
            }
            await loadDay()
            return saved
        } catch {
            errorMessage = "Couldn't save chow entry."
            return nil
        }
    }

    func logManualEntry() async {
        guard let userId, !manualName.isEmpty, let calories = Double(manualCalories) else { return }
        isLoggingManual = true
        defer { isLoggingManual = false }

        let entry = ChowEntry(
            id: UUID(),
            userId: userId,
            mealType: manualMealType,
            servings: 1,
            source: .manual,
            productId: nil,
            product: nil,
            manualName: manualName,
            manualCalories: calories,
            manualProteinG: Double(manualProtein),
            manualCarbsG: Double(manualCarbs),
            manualFatG: Double(manualFat),
            notes: manualNotes.isEmpty ? nil : manualNotes,
            logDate: selectedDateString,
            loggedAt: Date(),
            updatedAt: Date()
        )

        do {
            _ = try await service.logEntry(entry: entry)
            resetManualForm()
            showManualEntry = false
            await loadDay()
        } catch {
            errorMessage = "Couldn't save entry."
        }
    }

    func deleteEntry(_ entry: ChowEntry) async {
        do {
            try await service.deleteEntry(id: entry.id)
            await loadDay()
        } catch {
            errorMessage = "Couldn't delete entry."
        }
    }

    func updateServings(for entry: ChowEntry, servings: Double) async {
        var updated = entry
        updated.servings = servings
        updated.updatedAt = Date()
        do {
            try await service.updateEntry(updated)
            await loadDay()
        } catch {
            errorMessage = "Couldn't update servings."
        }
    }

    func saveGoals(_ goals: UserNutritionGoals) async {
        do {
            try await service.saveGoals(goals)
            self.goals = goals
        } catch {
            errorMessage = "Couldn't save nutrition goals."
        }
    }

    private func resetManualForm() {
        manualName = ""
        manualCalories = ""
        manualProtein = ""
        manualCarbs = ""
        manualFat = ""
        manualNotes = ""
    }
}
