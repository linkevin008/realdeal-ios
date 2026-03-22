import XCTest
@testable import RealDeal

@MainActor
final class PropertyDetailViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeProperty(
        id: String = "p1",
        price: Decimal = 850_000,
        currency: String = "CAD",
        type: PropertyType = .house,
        specs: PropertySpecifications = PropertySpecifications(),
        images: [PropertyImage] = [],
        sellerId: String? = nil
    ) -> Property {
        Property(
            id: id,
            address: Address(street: "123 Main St", city: "Toronto", province: "ON", postalCode: "M5H 1J9", country: "Canada"),
            price: price,
            currency: currency,
            propertyType: type,
            description: "Test",
            specifications: specs,
            images: images,
            location: Coordinate(latitude: 43.6532, longitude: -79.3832),
            sellerId: sellerId
        )
    }

    private func makeViewModel(property: Property) -> PropertyDetailViewModel {
        let mockRepo = MockPropertyRepository()
        let remoteDS = MockRemoteDataSource()
        let persistence = PersistenceController(inMemory: true)
        let localDS = LocalDataSource(persistenceController: persistence)
        let userProfileRepo = UserProfileRepository(localDataSource: localDS, remoteDataSource: remoteDS)
        return PropertyDetailViewModel(
            property: property,
            propertyRepository: mockRepo,
            userProfileRepository: userProfileRepo
        )
    }

    // MARK: - formattedAddress

    func testFormattedAddress() {
        let vm = makeViewModel(property: makeProperty())
        XCTAssertEqual(vm.formattedAddress, "123 Main St, Toronto, ON M5H 1J9")
    }

    // MARK: - formattedPropertyType

    func testFormattedPropertyTypeCapitalized() {
        let vm = makeViewModel(property: makeProperty(type: .apartment))
        XCTAssertEqual(vm.formattedPropertyType, "Apartment")
    }

    // MARK: - formattedSpecifications

    func testFormattedSpecsWithAll() {
        let specs = PropertySpecifications(bedrooms: 3, bathrooms: 2.5, squareFeet: 1500)
        let vm = makeViewModel(property: makeProperty(specs: specs))
        let formatted = vm.formattedSpecifications
        XCTAssertTrue(formatted.contains("3 bed"))
        XCTAssertTrue(formatted.contains("2.5 bath"))
        XCTAssertTrue(formatted.contains("1,500 sqft"))
    }

    func testFormattedSpecsEmptyWhenNone() {
        let vm = makeViewModel(property: makeProperty(specs: PropertySpecifications()))
        XCTAssertTrue(vm.formattedSpecifications.isEmpty)
    }

    // MARK: - formattedLotSize

    func testFormattedLotSizeNilWhenAbsent() {
        let vm = makeViewModel(property: makeProperty(specs: PropertySpecifications()))
        XCTAssertNil(vm.formattedLotSize)
    }

    func testFormattedLotSizePresent() {
        let specs = PropertySpecifications(lotSize: 0.5)
        let vm = makeViewModel(property: makeProperty(specs: specs))
        XCTAssertEqual(vm.formattedLotSize, "0.5 acres")
    }

    // MARK: - formattedYearBuilt

    func testFormattedYearBuiltNilWhenAbsent() {
        let vm = makeViewModel(property: makeProperty())
        XCTAssertNil(vm.formattedYearBuilt)
    }

    func testFormattedYearBuiltPresent() {
        let specs = PropertySpecifications(yearBuilt: 1995)
        let vm = makeViewModel(property: makeProperty(specs: specs))
        XCTAssertEqual(vm.formattedYearBuilt, "Built in 1995")
    }

    // MARK: - hasImages / sortedImages

    func testHasImagesWhenEmpty() {
        let vm = makeViewModel(property: makeProperty(images: []))
        XCTAssertFalse(vm.hasImages)
    }

    func testHasImagesWhenPresent() {
        let img = PropertyImage(url: URL(string: "https://example.com/a.jpg")!, order: 0)
        let vm = makeViewModel(property: makeProperty(images: [img]))
        XCTAssertTrue(vm.hasImages)
    }

    func testSortedImagesOrder() {
        let img1 = PropertyImage(url: URL(string: "https://example.com/b.jpg")!, order: 2)
        let img2 = PropertyImage(url: URL(string: "https://example.com/a.jpg")!, order: 0)
        let img3 = PropertyImage(url: URL(string: "https://example.com/c.jpg")!, order: 1)
        let vm = makeViewModel(property: makeProperty(images: [img1, img2, img3]))
        let sorted = vm.sortedImages
        XCTAssertEqual(sorted[0].order, 0)
        XCTAssertEqual(sorted[1].order, 1)
        XCTAssertEqual(sorted[2].order, 2)
    }

    // MARK: - Image navigation

    func testShowFullScreenImage() {
        let img1 = PropertyImage(url: URL(string: "https://example.com/a.jpg")!, order: 0)
        let img2 = PropertyImage(url: URL(string: "https://example.com/b.jpg")!, order: 1)
        let vm = makeViewModel(property: makeProperty(images: [img1, img2]))
        vm.showFullScreenImage(at: 1)
        XCTAssertTrue(vm.isShowingFullScreenImage)
        XCTAssertEqual(vm.selectedImageIndex, 1)
    }

    func testNextImageAdvances() {
        let images = (0..<3).map { i in
            PropertyImage(url: URL(string: "https://example.com/\(i).jpg")!, order: i)
        }
        let vm = makeViewModel(property: makeProperty(images: images))
        vm.selectedImageIndex = 0
        vm.nextImage()
        XCTAssertEqual(vm.selectedImageIndex, 1)
    }

    func testNextImageClampsAtEnd() {
        let images = (0..<3).map { i in
            PropertyImage(url: URL(string: "https://example.com/\(i).jpg")!, order: i)
        }
        let vm = makeViewModel(property: makeProperty(images: images))
        vm.selectedImageIndex = 2
        vm.nextImage()
        XCTAssertEqual(vm.selectedImageIndex, 2)
    }

    func testPreviousImageGoesBack() {
        let images = (0..<3).map { i in
            PropertyImage(url: URL(string: "https://example.com/\(i).jpg")!, order: i)
        }
        let vm = makeViewModel(property: makeProperty(images: images))
        vm.selectedImageIndex = 2
        vm.previousImage()
        XCTAssertEqual(vm.selectedImageIndex, 1)
    }

    func testPreviousImageClampsAtStart() {
        let images = (0..<3).map { i in
            PropertyImage(url: URL(string: "https://example.com/\(i).jpg")!, order: i)
        }
        let vm = makeViewModel(property: makeProperty(images: images))
        vm.selectedImageIndex = 0
        vm.previousImage()
        XCTAssertEqual(vm.selectedImageIndex, 0)
    }

    // MARK: - Seller visibility

    func testVisibleSellerEmailNilWhenNoProfile() {
        let vm = makeViewModel(property: makeProperty(sellerId: "seller1"))
        XCTAssertNil(vm.visibleSellerEmail)
    }

    func testVisibleSellerEmailHiddenWhenNotAllowed() {
        let vm = makeViewModel(property: makeProperty(sellerId: "seller1"))
        vm.sellerProfile = UserProfile(
            id: "seller1",
            name: "Jane",
            email: "jane@example.com",
            phoneNumber: "416-555-0100",
            visibilitySettings: ProfileVisibility(showEmail: false, showPhone: true, showListings: true)
        )
        XCTAssertNil(vm.visibleSellerEmail)
        XCTAssertEqual(vm.visibleSellerPhone, "416-555-0100")
    }

    func testVisibleSellerEmailShownWhenAllowed() {
        let vm = makeViewModel(property: makeProperty(sellerId: "seller1"))
        vm.sellerProfile = UserProfile(
            id: "seller1",
            name: "Jane",
            email: "jane@example.com",
            visibilitySettings: ProfileVisibility(showEmail: true, showPhone: false, showListings: true)
        )
        XCTAssertEqual(vm.visibleSellerEmail, "jane@example.com")
        XCTAssertNil(vm.visibleSellerPhone)
    }
}
