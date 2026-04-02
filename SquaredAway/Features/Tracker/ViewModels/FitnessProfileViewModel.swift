import SwiftUI

// MARK: - FitnessProfileViewModel
@MainActor
final class FitnessProfileViewModel: ObservableObject {

    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 10
    @Published var weightLbs: String = ""
    @Published var goalWeightLbs: String = ""
    @Published var fitnessGoal: PTFitnessGoal = .improvePTScore
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var workoutSplit: WorkoutSplit = .upperLower
    @Published var weeklyTarget: Int = 4
    @Published var isSaving: Bool = false
    @Published var saveSuccess: Bool = false
    @Published private(set) var savedProfile: FitnessProfile?
    @Published var errorMessage: String? = nil

    private let service = PTService.shared
    private var userId: UUID?
    private var existingProfileId: UUID?

    func configure(userId: UUID) { self.userId = userId }

    func load(from profile: FitnessProfile) {
        existingProfileId = profile.id
        let totalInches = profile.heightCm / 2.54
        heightFeet = Int(totalInches / 12)
        heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        weightLbs = String(format: "%.0f", profile.weightLbs)
        goalWeightLbs = profile.goalWeightLbs.map { String(format: "%.0f", $0) } ?? ""
        fitnessGoal = profile.fitnessGoal
        experienceLevel = profile.experienceLevel
        workoutSplit = profile.workoutSplit
        weeklyTarget = profile.weeklyWorkoutTarget
    }

    // MARK: - Live BMI Computation
    var heightCm: Double { Double(heightFeet * 12 + heightInches) * 2.54 }
    var weightKg: Double { (Double(weightLbs) ?? 0) * 0.453592 }
    var goalWeightKg: Double? { Double(goalWeightLbs).map { $0 * 0.453592 } }

    var bmi: Double {
        guard heightCm > 0, weightKg > 0 else { return 0 }
        let meters = heightCm / 100
        return weightKg / (meters * meters)
    }
    var bmiCategory: BMICategory { BMICategory.from(bmi: bmi) }
    var bmiFormatted: String { String(format: "%.1f", bmi) }

    var isValid: Bool {
        (Double(weightLbs) ?? 0) > 0 && heightCm > 0
    }

    // MARK: - Save
    func save() async {
        guard let userId, isValid else { return }
        isSaving = true
        defer { isSaving = false }

        let profile = FitnessProfile(
            id: existingProfileId ?? UUID(),
            userId: userId,
            heightCm: heightCm,
            weightKg: weightKg,
            goalWeightKg: goalWeightKg,
            fitnessGoal: fitnessGoal,
            experienceLevel: experienceLevel,
            workoutSplit: workoutSplit,
            dailyCalorieTarget: nil,
            weeklyWorkoutTarget: weeklyTarget,
            createdAt: Date(),
            updatedAt: Date()
        )
        do {
            savedProfile = try await service.upsertProfile(profile)
            saveSuccess = true
        } catch {
            errorMessage = "Couldn't save profile."
        }
    }
}
