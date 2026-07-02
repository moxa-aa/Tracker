import UIKit
import CoreData

struct TrackerCategoryStoreUpdate {
    let insertedIndexPaths: [IndexPath]
    let deletedIndexPaths: [IndexPath]
    let updatedIndexPaths: [IndexPath]
    let movedIndexPaths: [(from: IndexPath, to: IndexPath)]
}

protocol TrackerCategoryStoreDelegate: AnyObject {
    func store(_ store: TrackerCategoryStore, didUpdate update: TrackerCategoryStoreUpdate)
}

final class TrackerCategoryStore: NSObject {
    weak var delegate: TrackerCategoryStoreDelegate?
    
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>
    
    private var insertedIndexPaths: [IndexPath] = []
    private var deletedIndexPaths: [IndexPath] = []
    private var updatedIndexPaths: [IndexPath] = []
    private var movedIndexPaths: [(from: IndexPath, to: IndexPath)] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let controller = NSFetchedResultsController<TrackerCategoryCoreData>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController = controller
        
        super.init()
        
        controller.delegate = self
        try? controller.performFetch()
    }
    
    var categories: [TrackerCategory] {
        guard let objects = fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap { categoryCoreData in
            guard let title = categoryCoreData.title else { return nil }
            let trackersSet = categoryCoreData.trackers as? Set<TrackerCoreData> ?? []
            let trackers = trackersSet.compactMap { trackerCoreData -> Tracker? in
                guard let id = trackerCoreData.id,
                      let name = trackerCoreData.name,
                      let colorHex = trackerCoreData.color,
                      let emoji = trackerCoreData.emoji else { return nil }
                let days = (trackerCoreData.schedule ?? "").split(separator: ",").compactMap { WeekDay(rawValue: String($0)) }
                return Tracker(
                    id: id,
                    name: name,
                    color: UIColor(hex: colorHex),
                    emoji: emoji,
                    schedule: Set(days)
                )
            }
            return TrackerCategory(title: title, trackers: trackers.sorted(by: { $0.name < $1.name }))
        }
    }
    
    func categoryCoreData(with title: String) throws -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        return try context.fetch(request).first
    }
    
    func createCategory(with title: String) throws -> TrackerCategoryCoreData {
        if let existing = try categoryCoreData(with: title) {
            return existing
        }
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        try context.save()
        return category
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths.removeAll()
        deletedIndexPaths.removeAll()
        updatedIndexPaths.removeAll()
        movedIndexPaths.removeAll()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.store(
            self,
            didUpdate: TrackerCategoryStoreUpdate(
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
