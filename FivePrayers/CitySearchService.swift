import Foundation
import Combine
import MapKit

@MainActor
final class CitySearchService: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [CitySearchResult] = []
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .query]
    }

    func updateQuery(_ text: String) {
        query = text
        errorMessage = nil
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
            isSearching = false
            completer.cancel()
            return
        }
        isSearching = true
        completer.queryFragment = text
    }

    func resolve(_ result: CitySearchResult) async throws -> PrayerLocation {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = [result.title, result.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                throw CitySearchError.noResults
            }
            let placemark = item.placemark
            let city = placemark.locality ?? placemark.name ?? result.title
            let country = placemark.country ?? result.subtitle
            let coordinate = placemark.coordinate
            let timezone = placemark.timeZone?.identifier ?? TimeZone.current.identifier
            return PrayerLocation(
                city: city, country: country,
                latitude: coordinate.latitude, longitude: coordinate.longitude,
                timezone: timezone
            )
        } catch let err as CitySearchError {
            throw err
        } catch {
            throw CitySearchError.resolveFailed(error)
        }
    }
}

extension CitySearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let mapped = completer.results.map { c in
            CitySearchResult(title: c.title, subtitle: c.subtitle,
                             city: c.title, country: c.subtitle,
                             latitude: nil, longitude: nil, timezone: nil)
        }
        Task { @MainActor [weak self] in
            self?.results = mapped
            self?.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.isSearching = false
            self?.errorMessage = error.localizedDescription
        }
    }
}

enum CitySearchError: LocalizedError {
    case noResults
    case resolveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noResults:              return "No city found. Try a different search."
        case .resolveFailed(let e):   return "Could not locate city: \(e.localizedDescription)"
        }
    }
}
