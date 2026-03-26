import SwiftUI

struct FuelCheckHomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var scanVM = FuelCheckViewModel()
    @State private var selectedTab: FuelTab = .fuelCheck
    @State private var showScanner = false

    enum FuelTab: String, CaseIterable {
        case fuelCheck = "Fuel Check"
        case chowLog = "Chow Log"

        var icon: String {
            switch self {
            case .fuelCheck:
                return "barcode.viewfinder"
            case .chowLog:
                return "list.bullet.clipboard"
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                tabBar
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)

                TabView(selection: $selectedTab) {
                    fuelCheckTab
                        .tag(FuelTab.fuelCheck)
                    ChowLogDayView()
                        .tag(FuelTab.chowLog)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.Animation.spring, value: selectedTab)
            }
        }
        .navigationTitle(selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
        .onAppear {
            if let id = authVM.currentUserId {
                scanVM.configure(userId: id, goal: .maintenance)
                Task { await scanVM.loadHistory() }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            BarcodeScannerView(vm: scanVM)
        }
    }

    private var tabBar: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(FuelTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(AppTheme.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(AppTheme.Typography.titleSmall)
                    }
                    .foregroundColor(selectedTab == tab ? .white : AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        selectedTab == tab
                            ? AppTheme.Gradients.primaryButton
                            : LinearGradient(colors: [AppTheme.Colors.backgroundCard, AppTheme.Colors.backgroundCard], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(selectedTab == tab ? Color.clear : AppTheme.Colors.glassBorder, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier(tab == .fuelCheck ? "fuel-check-tab-fuel-check" : "fuel-check-tab-chow-log")
            }
        }
    }

    private var fuelCheckTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                scanHeroButton
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.md)

                scanContextCards
                    .padding(.horizontal, AppTheme.Spacing.md)

                if !scanVM.recentScans.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("Recent Scans")
                                .font(AppTheme.Typography.label)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(1)
                            Spacer()
                            NavigationLink("See all") {
                                ScanHistoryView(scanVM: scanVM)
                            }
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                        }

                        ForEach(scanVM.recentScans.prefix(5)) { scan in
                            ScanHistoryRow(scan: scan) { }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }

                if !scanVM.savedProducts.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Saved Products")
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(1)

                        ForEach(scanVM.savedProducts.prefix(3)) { saved in
                            if let product = saved.product {
                                savedProductRow(product: product)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }

                Spacer(minLength: AppTheme.Spacing.xxl)
            }
        }
    }

    private var scanHeroButton: some View {
        Button(action: { showScanner = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.xxl)
                    .fill(LinearGradient(colors: [AppTheme.Colors.backgroundCard, AppTheme.Colors.backgroundElevated], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.xxl).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
                    .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.1), radius: 20, x: 0, y: 8)

                VStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accentPrimary.opacity(0.1))
                            .frame(width: 90, height: 90)
                        Circle()
                            .fill(AppTheme.Gradients.primaryButton)
                            .frame(width: 72, height: 72)
                            .shadow(color: AppTheme.Colors.accentPrimary.opacity(0.5), radius: 16, x: 0, y: 6)
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 4) {
                        Text("Scan a Barcode")
                            .font(AppTheme.Typography.titleLarge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("PX, commissary, DFAC grab-and-go, gas station snacks, and supplements.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xl)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var scanContextCards: some View {
        let contexts: [(icon: String, label: String, color: String)] = [
            ("bag.fill", "PX / Shoppette", "#45B7D1"),
            ("storefront", "Commissary", "#96CEB4"),
            ("fork.knife", "DFAC Grab", "#FFD700"),
            ("pill.fill", "Supplements", "#A29BFE"),
            ("fuelpump.fill", "Gas Station", "#FF9F0A"),
            ("shippingbox.fill", "MRE Check", "#FF6B6B")
        ]

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Where to use")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                ForEach(contexts, id: \.label) { context in
                    VStack(spacing: 6) {
                        Image(systemName: context.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: context.color))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: context.color).opacity(0.12))
                            .cornerRadius(AppTheme.Radius.sm)
                        Text(context.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.backgroundCard)
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
                }
            }
        }
        .accessibilityIdentifier("fuel-check-scan-button")
    }

    private func savedProductRow(product: FuelProduct) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: product.category.icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(width: 40, height: 40)
                .background(AppTheme.Colors.backgroundElevated)
                .cornerRadius(AppTheme.Radius.sm)

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(Int(product.nutrition.calories)) cal · \(Int(product.nutrition.proteinG))g protein")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            if let scores = product.scores {
                FuelRatingPill(rating: scores.rating)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundCard)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.Colors.glassBorder, lineWidth: 1))
    }
}

struct ScanHistoryView: View {
    @ObservedObject var scanVM: FuelCheckViewModel

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if scanVM.isLoadingHistory {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accentPrimary))
            } else if scanVM.recentScans.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "barcode")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("No scans yet")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text("Scan your first product to see it here.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(scanVM.recentScans) { scan in
                            ScanHistoryRow(scan: scan) { }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
        }
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.Colors.backgroundPrimary, for: .navigationBar)
    }
}
