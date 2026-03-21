import Foundation

// MARK: - Geographic Utilities

enum GeoUtils {
    /// Calculates the distance in miles between two coordinates using the Haversine formula.
    static func distance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadiusMiles = 3959.0

        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLatRad = (to.latitude - from.latitude) * .pi / 180
        let deltaLonRad = (to.longitude - from.longitude) * .pi / 180

        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMiles * c
    }
}
