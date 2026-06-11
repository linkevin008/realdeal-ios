import XCTest
import CoreLocation
@testable import RealDeal

/// Tests for the listing creation form rules: geocoded coordinates,
/// country-aware postal validation, and required specifications.
@MainActor
final class PropertyCreationFormTests: XCTestCase {

    private func makeViewModel() -> PropertyCreationViewModel {
        let service = PropertyListingService(
            repository: MockPropertyRepository(),
            imageStorage: MockImageStorage()
        )
        let vm = PropertyCreationViewModel(service: service, currentUserId: "user-1")
        vm.street = "456 Oak Avenue"
        vm.city = "Springfield"
        vm.province = "IL"
        vm.postalCode = "62704"
        vm.country = "US"
        vm.price = "425000"
        vm.propertyDescription = "Charming 3-bed near downtown"
        vm.bedrooms = "3"
        vm.bathrooms = "2"
        vm.squareFeet = "2100"
        vm.yearBuilt = "1998"
        return vm
    }

    func testCreateGeocodesAddressIntoCoordinates() async {
        let vm = makeViewModel()
        var geocodedAddress: String?
        vm.geocode = { address in
            geocodedAddress = address
            return CLLocationCoordinate2D(latitude: 39.79, longitude: -89.64)
        }

        await vm.createProperty()

        XCTAssertNil(vm.errorMessage)
        XCTAssertNotNil(vm.successMessage)
        XCTAssertEqual(vm.latitude, "39.79")
        XCTAssertEqual(vm.longitude, "-89.64")
        XCTAssertTrue(geocodedAddress?.contains("456 Oak Avenue") == true,
                      "geocoder should receive the entered street address")
    }

    func testGeocodeFailureBlocksSave() async {
        let vm = makeViewModel()
        vm.geocode = { _ in throw ValidationError.invalidLocation }

        await vm.createProperty()

        XCTAssertNil(vm.successMessage)
        XCTAssertNotNil(vm.locationValidationError)
    }

    func testMissingSpecificationsBlockSave() async {
        let vm = makeViewModel()
        vm.bedrooms = ""
        vm.geocode = { _ in CLLocationCoordinate2D(latitude: 0, longitude: 0) }

        await vm.createProperty()

        XCTAssertNil(vm.successMessage)
        XCTAssertNotNil(vm.specificationsValidationError)
    }

    func testImplausibleYearBuiltBlocksSave() async {
        let vm = makeViewModel()
        vm.yearBuilt = "1500"
        vm.geocode = { _ in CLLocationCoordinate2D(latitude: 0, longitude: 0) }

        await vm.createProperty()

        XCTAssertNil(vm.successMessage)
        XCTAssertNotNil(vm.specificationsValidationError)
    }

    func testPostalValidationFollowsCountry() {
        XCTAssertNil(PropertyCreationViewModel.postalCodeError("90210", country: "US"))
        XCTAssertNil(PropertyCreationViewModel.postalCodeError("12345-6789", country: "US"))
        XCTAssertNotNil(PropertyCreationViewModel.postalCodeError("A1A 1A1", country: "US"))
        XCTAssertNil(PropertyCreationViewModel.postalCodeError("A1A 1A1", country: "CA"))
        XCTAssertNil(PropertyCreationViewModel.postalCodeError("M5E0A9", country: "CA"))
        XCTAssertNotNil(PropertyCreationViewModel.postalCodeError("90210", country: "CA"))
    }

    func testSupportedCountriesLoadAndReconcileSelection() async {
        let vm = makeViewModel()
        vm.country = "FR" // not supported — should snap to a supported one

        await vm.loadSupportedCountries()

        let codes = vm.supportedCountries.map(\.code).sorted()
        XCTAssertEqual(codes, ["CA", "US"])
        XCTAssertTrue(codes.contains(vm.country),
                      "selection must be reconciled to a supported country")
    }
}
