import XCTest
@testable import RealDeal

final class GeoUtilsTests: XCTestCase {

    // Same point → zero distance
    func testDistanceSamePoint() {
        let coord = Coordinate(latitude: 43.6532, longitude: -79.3832)
        let distance = GeoUtils.distance(from: coord, to: coord)
        XCTAssertEqual(distance, 0.0, accuracy: 0.001)
    }

    // Toronto to Vancouver is ~2,100 miles
    func testDistanceTorontoToVancouver() {
        let toronto   = Coordinate(latitude: 43.6532, longitude: -79.3832)
        let vancouver = Coordinate(latitude: 49.2827, longitude: -123.1207)
        let distance  = GeoUtils.distance(from: toronto, to: vancouver)
        XCTAssertEqual(distance, 2100, accuracy: 100)
    }

    // Distance is symmetric
    func testDistanceIsSymmetric() {
        let a = Coordinate(latitude: 45.4215, longitude: -75.6972) // Ottawa
        let b = Coordinate(latitude: 51.0447, longitude: -114.0719) // Calgary
        let ab = GeoUtils.distance(from: a, to: b)
        let ba = GeoUtils.distance(from: b, to: a)
        XCTAssertEqual(ab, ba, accuracy: 0.001)
    }

    // Short distance (~1 mile apart) stays within reasonable accuracy
    func testShortDistanceAccuracy() {
        let a = Coordinate(latitude: 49.2827, longitude: -123.1207)
        let b = Coordinate(latitude: 49.2971, longitude: -123.1207) // ~1 mile north
        let distance = GeoUtils.distance(from: a, to: b)
        XCTAssertEqual(distance, 1.0, accuracy: 0.2)
    }

    // Crossing the equator
    func testDistanceCrossingEquator() {
        let north = Coordinate(latitude: 10.0, longitude: 0.0)
        let south = Coordinate(latitude: -10.0, longitude: 0.0)
        let distance = GeoUtils.distance(from: north, to: south)
        XCTAssertGreaterThan(distance, 0)
        XCTAssertEqual(distance, 1381, accuracy: 5)
    }
}
