import UIKit
import CoreData

struct TrackerStoreUpdate {
    let insertedIndexPaths: [IndexPath]
    let deletedIndexPaths: [IndexPath]
    let updatedIndexPaths: [IndexPath]
    let movedIndexPaths: [(from: IndexPath, to: IndexPath)]
}

protocol TrackerStoreDelegate: AnyObject {
    func store(_ store: TrackerStore, didUpdate update: TrackerStoreUpdate)
}

final class TrackerStore: NSObject {
    weak var delegate: TrackerStoreDelegate?
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    
    private var insertedIndexPaths: [IndexPath] = []
    private var deletedIndexPaths: [IndexPath] = []
    private var updatedIndexPaths: [IndexPath] = []
    private var movedIndexPaths: [(from: IndexPath, to: IndexPath)] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let controller = NSFetchedResultsController<TrackerCoreData>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        self.fetchedResultsController = controller
        
        try? controller.performFetch()
    }
    
    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) throws {
        let categoryStore = TrackerCategoryStore(context: context)
        let categoryCoreData = try categoryStore.createCategory(with: categoryTitle)
        
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.color = tracker.color.hexString
        trackerCoreData.schedule = tracker.schedule.map { $0.rawValue }.joined(separator: ",")
        trackerCoreData.category = categoryCoreData
        
        try context.save()
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths.removeAll()
        deletedIndexPaths.removeAll()
        updatedIndexPaths.removeAll()
        movedIndexPaths.removeAll()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.store(
            self,
            didUpdate: TrackerStoreUpdate(
                insertedIndexPaths: insertedIndexPaths,
                deletedIndexPaths: deletedIndexPaths,
                updatedIndexPaths: updatedIndexPaths,
                movedIndexPaths: movedIndexPaths
            )
        )
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertedIndexPaths.append(newIndexPath)
            }
        case .delete:
            if let indexPath = indexPath {
                deletedIndexPaths.append(indexPath)
            }
        case .update:
            if let indexPath = indexPath {
                updatedIndexPaths.append(indexPath)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                movedIndexPaths.append((from: indexPath, to: newIndexPath))
            }
        @unknown default:
            break
        }
    }
}
