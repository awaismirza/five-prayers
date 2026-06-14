import Foundation

struct PrayerTimesAPIService {
    func fetchMonth(
        location: PrayerLocation,
        month: Int,
        year: Int,
        calculationMethod: Int = 3,
        school: Int = 0
    ) async throws -> [DailyPrayerTimes] {
        var comps = URLComponents(string: "https://api.aladhan.com/v1/calendar")!
        comps.queryItems = [
            URLQueryItem(name: "latitude",  value: "\(location.latitude)"),
            URLQueryItem(name: "longitude", value: "\(location.longitude)"),
            URLQueryItem(name: "method",    value: "\(calculationMethod)"),
            URLQueryItem(name: "school",    value: "\(school)"),
            URLQueryItem(name: "month",     value: "\(month)"),
            URLQueryItem(name: "year",      value: "\(year)")
        ]
        guard let url = comps.url else { throw APIError.badURL }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw APIError.networkFailed(error)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }

        do {
            let decoded = try JSONDecoder().decode(AlAdhanCalendarResponse.self, from: data)
            guard decoded.code == 200, let items = decoded.data else {
                throw APIError.badResponse
            }
            return try items.map { try parseDailyPrayerTimes(from: $0, locationId: location.id) }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.jsonParseFailed(error)
        }
    }

    private func parseDailyPrayerTimes(from item: AlAdhanDay, locationId: String) throws -> DailyPrayerTimes {
        // Date is "DD-MM-YYYY"
        let raw = item.date.gregorian.date
        let parts = raw.split(separator: "-")
        guard parts.count == 3,
              let day = Int(parts[0]), let month = Int(parts[1]), let year = Int(parts[2])
        else { throw APIError.parseTimeFailed(raw) }
        let dateKey = String(format: "%04d-%02d-%02d", year, month, day)

        return DailyPrayerTimes(
            dateKey:    dateKey,
            locationId: locationId,
            fajr:    try parseTime(item.timings.Fajr),
            dhuhr:   try parseTime(item.timings.Dhuhr),
            asr:     try parseTime(item.timings.Asr),
            maghrib: try parseTime(item.timings.Maghrib),
            isha:    try parseTime(item.timings.Isha)
        )
    }

    private func parseTime(_ raw: String) throws -> Int {
        // Strip suffix like " (AEST)"
        let clean = raw.components(separatedBy: " ").first ?? raw
        let parts = clean.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else {
            throw APIError.parseTimeFailed(raw)
        }
        return h * 60 + m
    }
}

// MARK: - Decodable response shapes

private struct AlAdhanCalendarResponse: Decodable {
    let code: Int
    let status: String
    let data: [AlAdhanDay]?
}

private struct AlAdhanDay: Decodable {
    let timings: AlAdhanTimings
    let date: AlAdhanDate
}

private struct AlAdhanTimings: Decodable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

private struct AlAdhanDate: Decodable {
    let gregorian: AlAdhanGregorianDate
}

private struct AlAdhanGregorianDate: Decodable {
    let date: String  // "DD-MM-YYYY"
}

// MARK: - Errors

enum APIError: LocalizedError {
    case badURL
    case networkFailed(Error)
    case badResponse
    case jsonParseFailed(Error)
    case parseTimeFailed(String)

    var errorDescription: String? {
        switch self {
        case .badURL:                 return "Invalid request URL."
        case .networkFailed(let e):   return "Network error: \(e.localizedDescription)"
        case .badResponse:            return "Unexpected response from server."
        case .jsonParseFailed(let e): return "Could not parse prayer times: \(e.localizedDescription)"
        case .parseTimeFailed(let s): return "Could not parse time value: \(s)"
        }
    }
}
