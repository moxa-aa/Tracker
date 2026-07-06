import XCTest
import CoreData
import SnapshotTesting
@testable import Tracker

final class TrackerTests: XCTestCase {
    
    private var persistentContainer: NSPersistentContainer!
    private var context: NSManagedObjectContext!
    private var trackerStore: TrackerStore!
    private var trackerCategoryStore: TrackerCategoryStore!
    private var trackerRecordStore: TrackerRecordStore!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        persistentContainer = NSPersistentContainer(name: "Tracker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load Persistent Stores")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load in-memory store: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        context = persistentContainer.viewContext
        trackerStore = TrackerStore(context: context)
        trackerCategoryStore = TrackerCategoryStore(context: context)
        trackerRecordStore = TrackerRecordStore(context: context)
    }
    
    override func tearDownWithError() throws {
        persistentContainer = nil
        context = nil
        trackerStore = nil
        trackerCategoryStore = nil
        trackerRecordStore = nil
        try super.tearDownWithError()
    }
    
    func testTrackersViewControllerLightMode() throws {
        let tracker1 = Tracker(
            id: UUID(uuidString: "7BD1ED76-A82C-41DB-B5CB-5E04C4BD1E8C")!,
            name: "Test Pinned Tracker",
            color: .ypBlue,
            emoji: "🐱",
            schedule: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            isPinned: true
        )
        
        let tracker2 = Tracker(
            id: UUID(uuidString: "8AC0D465-9A41-36EC-D2A5-AC3EAE4C852D")!,
            name: "Test Regular Tracker",
            color: .ypRed,
            emoji: "🌺",
            schedule: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            isPinned: false
        )
        
        try trackerStore.addTracker(tracker1, toCategoryWithTitle: "Home")
        try trackerStore.addTracker(tracker2, toCategoryWithTitle: "Home")
        
        let vc = TrackersViewController(
            trackerStore: trackerStore,
            trackerCategoryStore: trackerCategoryStore,
            trackerRecordStore: trackerRecordStore
        )
        
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 1
        if let fixedDate = calendar.date(from: components) {
            vc.currentDate = fixedDate
            vc.datePicker.date = fixedDate
        }
        
        vc.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
    
    func testTrackersViewControllerDarkMode() throws {
        let tracker1 = Tracker(
            id: UUID(uuidString: "7BD1ED76-A82C-41DB-B5CB-5E04C4BD1E8C")!,
            name: "Test Pinned Tracker",
            color: .ypBlue,
            emoji: "🐱",
            schedule: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            isPinned: true
        )
        
        let tracker2 = Tracker(
            id: UUID(uuidString: "8AC0D465-9A41-36EC-D2A5-AC3EAE4C852D")!,
            name: "Test Regular Tracker",
            color: .ypRed,
            emoji: "🌺",
            schedule: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            isPinned: false
        )
        
        try trackerStore.addTracker(tracker1, toCategoryWithTitle: "Home")
        try trackerStore.addTracker(tracker2, toCategoryWithTitle: "Home")
        
        let vc = TrackersViewController(
            trackerStore: trackerStore,
            trackerCategoryStore: trackerCategoryStore,
            trackerRecordStore: trackerRecordStore
        )
        
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 1
        if let fixedDate = calendar.date(from: components) {
            vc.currentDate = fixedDate
            vc.datePicker.date = fixedDate
        }
        
        vc.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
    
    func testNumberOfDaysLocalization() throws {
        let resultEn = L10n.numberOfDays(5)
        print("Localization result: \(resultEn)")
        XCTAssertNotEqual(resultEn, "numberOfDays")
        XCTAssertFalse(resultEn.contains("null"))
    }
}
