import Foundation

final class CategoryViewModel {
    
    // MARK: - Bindings
    var onCategoriesUpdated: (() -> Void)?
    var onCategorySelected: ((String) -> Void)?
    
    // MARK: - Properties
    private let trackerCategoryStore: TrackerCategoryStore
    private(set) var categories: [String] = []
    private(set) var selectedCategory: String?
    
    // MARK: - Initialization
    init(trackerCategoryStore: TrackerCategoryStore, selectedCategory: String?) {
        self.trackerCategoryStore = trackerCategoryStore
        self.selectedCategory = selectedCategory
        self.trackerCategoryStore.delegate = self
        loadCategories()
    }
    
    // MARK: - Public Methods
    func loadCategories() {
        self.categories = trackerCategoryStore.categories.map { $0.title }
        onCategoriesUpdated?()
    }
    
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func categoryTitle(at index: Int) -> String {
        guard index >= 0 && index < categories.count else { return "" }
        return categories[index]
    }
    
    func selectCategory(at index: Int) {
        guard index >= 0 && index < categories.count else { return }
        let category = categories[index]
        selectedCategory = category
        onCategorySelected?(category)
    }
    
    func isSelected(at index: Int) -> Bool {
        guard index >= 0 && index < categories.count else { return false }
        return categories[index] == selectedCategory
    }
    
    func addNewCategory(title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        _ = try trackerCategoryStore.createCategory(with: trimmedTitle)
        loadCategories()
    }
}

// MARK: - TrackerCategoryStoreDelegate
extension CategoryViewModel: TrackerCategoryStoreDelegate {
    func store(_ store: TrackerCategoryStore, didUpdate update: TrackerCategoryStoreUpdate) {
        loadCategories()
    }
}
