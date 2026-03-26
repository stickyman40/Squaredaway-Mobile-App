import Foundation
import Supabase

final class BarcodeService {
    static let shared = BarcodeService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    static var todayString: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func lookup(barcode: String, userId: UUID, goal: UserGoal) async throws -> BarcodeLookupResponse {
        let payload = BarcodeLookupRequest(barcode: barcode, userId: userId, goal: goal)
        return try await request(
            path: "/functions/v1/barcode-lookup",
            method: "POST",
            body: payload
        )
    }

    func recentScans(userId: UUID, limit: Int = 20) async throws -> [FuelScan] {
        try await request(
            path: "/rest/v1/\(SupabaseManager.Tables.fuelScans)",
            method: "GET",
            queryItems: [
                .init(name: "select", value: "*,fuel_products(*,fuel_product_scores(*))"),
                .init(name: "user_id", value: "eq.\(userId.uuidString)"),
                .init(name: "order", value: "scanned_at.desc"),
                .init(name: "limit", value: "\(limit)")
            ]
        )
    }

    func savedProducts(userId: UUID, limit: Int = 40) async throws -> [SavedProduct] {
        try await request(
            path: "/rest/v1/\(SupabaseManager.Tables.fuelSaved)",
            method: "GET",
            queryItems: [
                .init(name: "select", value: "*,fuel_products(*,fuel_product_scores(*))"),
                .init(name: "user_id", value: "eq.\(userId.uuidString)"),
                .init(name: "order", value: "saved_at.desc"),
                .init(name: "limit", value: "\(limit)")
            ]
        )
    }

    func toggleSaved(productId: UUID, userId: UUID, currentlySaved: Bool) async throws {
        if currentlySaved {
            _ = try await requestNoContent(
                path: "/rest/v1/\(SupabaseManager.Tables.fuelSaved)",
                method: "DELETE",
                queryItems: [
                    .init(name: "product_id", value: "eq.\(productId.uuidString)"),
                    .init(name: "user_id", value: "eq.\(userId.uuidString)")
                ]
            )
        } else {
            let payload = SavedProductInsert(userId: userId, productId: productId)
            _ = try await requestNoContent(
                path: "/rest/v1/\(SupabaseManager.Tables.fuelSaved)",
                method: "POST",
                body: payload,
                prefer: "return=minimal"
            )
        }
    }

    func entriesForDate(_ date: String, userId: UUID) async throws -> [ChowEntry] {
        try await request(
            path: "/rest/v1/\(SupabaseManager.Tables.chowEntries)",
            method: "GET",
            queryItems: [
                .init(name: "select", value: "*,fuel_products(*,fuel_product_scores(*))"),
                .init(name: "user_id", value: "eq.\(userId.uuidString)"),
                .init(name: "log_date", value: "eq.\(date)"),
                .init(name: "order", value: "logged_at.asc")
            ]
        )
    }

    func logEntry(entry: ChowEntry) async throws -> ChowEntry {
        let payload = ChowEntryWrite(entry: entry)
        let rows: [ChowEntry] = try await request(
            path: "/rest/v1/\(SupabaseManager.Tables.chowEntries)",
            method: "POST",
            body: payload,
            prefer: "return=representation"
        )
        guard let row = rows.first else {
            throw APIError.invalidResponse
        }
        return row
    }

    func updateEntry(_ entry: ChowEntry) async throws {
        let payload = ChowEntryWrite(entry: entry)
        _ = try await requestNoContent(
            path: "/rest/v1/\(SupabaseManager.Tables.chowEntries)",
            method: "PATCH",
            queryItems: [.init(name: "id", value: "eq.\(entry.id.uuidString)")],
            body: payload,
            prefer: "return=minimal"
        )
    }

    func deleteEntry(id: UUID) async throws {
        _ = try await requestNoContent(
            path: "/rest/v1/\(SupabaseManager.Tables.chowEntries)",
            method: "DELETE",
            queryItems: [.init(name: "id", value: "eq.\(id.uuidString)")]
        )
    }

    func markScanLogged(scanId: UUID, entryId: UUID) async throws {
        let payload = ScanLoggedWrite(wasLogged: true, chowEntryId: entryId)
        _ = try await requestNoContent(
            path: "/rest/v1/\(SupabaseManager.Tables.fuelScans)",
            method: "PATCH",
            queryItems: [.init(name: "id", value: "eq.\(scanId.uuidString)")],
            body: payload,
            prefer: "return=minimal"
        )
    }

    func fetchGoals(userId: UUID) async throws -> UserNutritionGoals? {
        let rows: [UserNutritionGoals] = try await request(
            path: "/rest/v1/\(SupabaseManager.Tables.userNutritionGoals)",
            method: "GET",
            queryItems: [
                .init(name: "select", value: "*"),
                .init(name: "user_id", value: "eq.\(userId.uuidString)"),
                .init(name: "limit", value: "1")
            ]
        )
        return rows.first
    }

    func saveGoals(_ goals: UserNutritionGoals) async throws {
        _ = try await requestNoContent(
            path: "/rest/v1/\(SupabaseManager.Tables.userNutritionGoals)",
            method: "POST",
            body: goals,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        prefer: String? = nil
    ) async throws -> T {
        let data = try await perform(path: path, method: method, queryItems: queryItems, prefer: prefer)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        prefer: String? = nil
    ) async throws -> T {
        let data = try await perform(path: path, method: method, queryItems: queryItems, body: body, prefer: prefer)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func requestNoContent(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        prefer: String? = nil
    ) async throws {
        _ = try await perform(path: path, method: method, queryItems: queryItems, prefer: prefer)
    }

    private func requestNoContent<Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        prefer: String? = nil
    ) async throws -> Void {
        _ = try await perform(path: path, method: method, queryItems: queryItems, body: body, prefer: prefer)
    }

    private func perform(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        prefer: String? = nil
    ) async throws -> Data {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw try decodeError(data: data, statusCode: http.statusCode)
        }

        return data
    }

    private func perform<Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }

        if let body {
            request.httpBody = try Self.encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw try decodeError(data: data, statusCode: http.statusCode)
        }

        return data
    }

    private func accessToken() async throws -> String {
        let session = try await client.auth.session
        return session.accessToken
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: SupabaseConfig.projectURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidResponse
        }
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        return url
    }

    private func decodeError(data: Data, statusCode: Int) throws -> APIError {
        if let payload = try? Self.decoder.decode(APIErrorPayload.self, from: data) {
            return .server(payload.message ?? payload.error ?? "Request failed with status \(statusCode)")
        }

        if let message = String(data: data, encoding: .utf8), !message.isEmpty {
            return .server(message)
        }

        return .server("Request failed with status \(statusCode)")
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = DateParsers.fractional.date(from: value) ?? DateParsers.standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateParsers.fractional.string(from: date))
        }
        return encoder
    }()
}

private enum DateParsers {
    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private struct BarcodeLookupRequest: Encodable {
    let barcode: String
    let userId: UUID
    let goal: UserGoal

    enum CodingKeys: String, CodingKey {
        case barcode
        case userId = "user_id"
        case goal
    }
}

private struct SavedProductInsert: Encodable {
    let userId: UUID
    let productId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case productId = "product_id"
    }
}

private struct ChowEntryWrite: Encodable {
    let userId: UUID
    let mealType: MealType
    let servings: Double
    let source: ChowEntrySource
    let productId: UUID?
    let manualName: String?
    let manualCalories: Double?
    let manualProteinG: Double?
    let manualCarbsG: Double?
    let manualFatG: Double?
    let notes: String?
    let logDate: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mealType = "meal_type"
        case servings
        case source
        case productId = "product_id"
        case manualName = "manual_name"
        case manualCalories = "manual_calories"
        case manualProteinG = "manual_protein_g"
        case manualCarbsG = "manual_carbs_g"
        case manualFatG = "manual_fat_g"
        case notes
        case logDate = "log_date"
    }

    init(entry: ChowEntry) {
        userId = entry.userId
        mealType = entry.mealType
        servings = entry.servings
        source = entry.source
        productId = entry.productId
        manualName = entry.manualName
        manualCalories = entry.manualCalories
        manualProteinG = entry.manualProteinG
        manualCarbsG = entry.manualCarbsG
        manualFatG = entry.manualFatG
        notes = entry.notes
        logDate = entry.logDate
    }
}

private struct ScanLoggedWrite: Encodable {
    let wasLogged: Bool
    let chowEntryId: UUID

    enum CodingKeys: String, CodingKey {
        case wasLogged = "was_logged"
        case chowEntryId = "chow_entry_id"
    }
}

private struct APIErrorPayload: Decodable {
    let message: String?
    let error: String?
}

private enum APIError: LocalizedError {
    case invalidResponse
    case decoding(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .decoding(let message):
            return "Failed to decode server data: \(message)"
        case .server(let message):
            return message
        }
    }
}
