import UIKit

final class TrackersViewController: UIViewController {

    // MARK: - UI Components
    private let searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.placeholder = L10n.trackersSearch
        textField.backgroundColor = .ypLightGray
        textField.textColor = .ypBlack
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let emptyStateView = EmptyStateView()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 9
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 82, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale.current
        return picker
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.trackersFilters, for: .normal)
        button.backgroundColor = .ypBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - State Properties
    private let trackerStore: TrackerStore
    private let trackerCategoryStore: TrackerCategoryStore
    private let trackerRecordStore: TrackerRecordStore

    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = [] {
        didSet {
            updateCompletedTrackersIDs()
        }
    }
    private var completedTrackersIDs: Set<UUID> = []
    private var selectedFilter: TrackerFilter = .all
    
    private func updateCompletedTrackersIDs() {
        let calendar = Calendar.current
        let currentCompleted = completedTrackers.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
        completedTrackersIDs = Set(currentCompleted.map { $0.trackerId })
    }
    
    private var visibleCategories: [TrackerCategory] = []
    var currentDate: Date = Date() {
        didSet {
            updateCompletedTrackersIDs()
        }
    }
    private var searchQuery: String = ""

    init(trackerStore: TrackerStore, trackerCategoryStore: TrackerCategoryStore, trackerRecordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.trackerCategoryStore = trackerCategoryStore
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trackerStore.delegate = self
        trackerCategoryStore.delegate = self
        trackerRecordStore.delegate = self
        
        loadCategories()
        loadCompletedTrackers()
        
        setupUI()
        setupNavigationBar()
        setupConstraints()
        updateVisibleCategories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.report(event: "open", screen: "Main", item: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AnalyticsService.shared.report(event: "close", screen: "Main", item: nil)
    }
    
    private func loadCategories() {
        self.categories = trackerCategoryStore.categories
        updateVisibleCategories()
    }
    
    private func loadCompletedTrackers() {
        self.completedTrackers = (try? trackerRecordStore.fetchRecords()) ?? []
    }

    // MARK: - Setup UI & Layout
    private func setupUI() {
        view.backgroundColor = .ypWhite
        view.addSubview(searchTextField)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(filterButton)
        
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(
            TrackerHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerHeaderView.identifier
        )
        
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    }

    private func setupNavigationBar() {
        navigationItem.title = L10n.tabTrackers
        navigationController?.navigationBar.prefersLargeTitles = true

        // Left add button
        let plusImage = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        )
        let plusButton = UIBarButtonItem(
            image: plusImage,
            style: .plain,
            target: self,
            action: #selector(plusButtonTapped)
        )
        plusButton.tintColor = .ypBlack
        navigationItem.leftBarButtonItem = plusButton

        // Right date picker
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        navigationItem.rightBarButtonItem = datePickerItem
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Search text field
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Empty state view (centered in the remaining screen space)
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Filter button
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.widthAnchor.constraint(equalToConstant: 114)
        ])
    }

    // MARK: - Actions & Callbacks
    @objc private func plusButtonTapped() {
        AnalyticsService.shared.report(event: "click", screen: "Main", item: "add_track")
        let typeSelectionVC = TrackerTypeSelectionViewController()
        typeSelectionVC.delegate = self
        let navController = UINavigationController(rootViewController: typeSelectionVC)
        present(navController, animated: true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        if selectedFilter == .today {
            selectedFilter = .all
        }
        updateVisibleCategories()
    }

    @objc private func searchTextChanged() {
        searchQuery = searchTextField.text ?? ""
        updateVisibleCategories()
    }
    
    @objc private func filterButtonTapped() {
        AnalyticsService.shared.report(event: "click", screen: "Main", item: "filter")
        let filterVC = FilterViewController(selectedFilter: selectedFilter)
        filterVC.delegate = self
        let navController = UINavigationController(rootViewController: filterVC)
        present(navController, animated: true)
    }
    
    private func togglePin(_ tracker: Tracker) {
        do {
            try trackerStore.togglePinTracker(tracker)
        } catch {
            print("Failed to toggle pin: \(error)")
        }
    }
    
    private func editTracker(_ tracker: Tracker, indexPath: IndexPath) {
        AnalyticsService.shared.report(event: "click", screen: "Main", item: "edit")
        let categoryTitle = visibleCategories[indexPath.section].title
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        let editVC = CreateTrackerViewController()
        editVC.configureForEditing(tracker: tracker, categoryTitle: categoryTitle, completedDays: completedDays)
        editVC.delegate = self
        
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    private func confirmDelete(_ tracker: Tracker) {
        let alert = UIAlertController(
            title: L10n.deleteAlertTitle,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: L10n.deleteAlertDelete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            AnalyticsService.shared.report(event: "click", screen: "Main", item: "delete")
            do {
                try self.trackerStore.deleteTracker(tracker)
            } catch {
                print("Failed to delete tracker: \(error)")
            }
        }
        
        let cancelAction = UIAlertAction(title: L10n.deleteAlertCancel, style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    // MARK: - Filtering Logic
    private func updateVisibleCategories() {
        updateCompletedTrackersIDs()
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: currentDate)
        let selectedWeekDay: WeekDay
        switch weekdayNumber {
        case 1: selectedWeekDay = .sunday
        case 2: selectedWeekDay = .monday
        case 3: selectedWeekDay = .tuesday
        case 4: selectedWeekDay = .wednesday
        case 5: selectedWeekDay = .thursday
        case 6: selectedWeekDay = .friday
        case 7: selectedWeekDay = .saturday
        default: selectedWeekDay = .monday
        }
        
        let hasTrackersOnDate = categories.contains { category in
            category.trackers.contains { tracker in
                tracker.schedule.contains(selectedWeekDay)
            }
        }
        filterButton.isHidden = !hasTrackersOnDate
        
        var pinnedTrackers: [Tracker] = []
        var filteredCategories: [TrackerCategory] = []
        
        for category in categories {
            let categoryTrackers = category.trackers.filter { tracker in
                let matchesDay = tracker.schedule.contains(selectedWeekDay)
                let matchesSearch = searchQuery.isEmpty || tracker.name.lowercased().contains(searchQuery.lowercased())
                
                let matchesFilter: Bool
                switch selectedFilter {
                case .all, .today:
                    matchesFilter = true
                case .completed:
                    matchesFilter = completedTrackersIDs.contains(tracker.id)
                case .incomplete:
                    matchesFilter = !completedTrackersIDs.contains(tracker.id)
                }
                
                return matchesDay && matchesSearch && matchesFilter
            }
            
            let unpinnedTrackers = categoryTrackers.filter { !$0.isPinned }
            let categoryPinned = categoryTrackers.filter { $0.isPinned }
            pinnedTrackers.append(contentsOf: categoryPinned)
            
            if !unpinnedTrackers.isEmpty {
                filteredCategories.append(TrackerCategory(title: category.title, trackers: unpinnedTrackers))
            }
        }
        
        if !pinnedTrackers.isEmpty {
            let pinnedCategory = TrackerCategory(title: L10n.categoryPinned, trackers: pinnedTrackers)
            filteredCategories.insert(pinnedCategory, at: 0)
        }
        
        self.visibleCategories = filteredCategories
        collectionView.reloadData()
        
        let isListEmpty = visibleCategories.isEmpty
        if isListEmpty {
            if !searchQuery.isEmpty {
                emptyStateView.configure(text: L10n.emptyStateNoTrackersFound, image: UIImage(named: "emptyStateSearch"))
            } else if selectedFilter == .completed || selectedFilter == .incomplete {
                emptyStateView.configure(text: L10n.emptyStateNoTrackersFound, image: UIImage(named: "emptyStateSearch"))
            } else {
                emptyStateView.configure(text: L10n.emptyStateWhatToTrack, image: UIImage(named: "emptyStateStar"))
            }
        }
        emptyStateView.isHidden = !isListEmpty
        collectionView.isHidden = isListEmpty
    }
}

// MARK: - UITextFieldDelegate
extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - TrackerCellDelegate
extension TrackersViewController: TrackerCellDelegate {
    func didTapDoneButton(in cell: TrackerCell) {
        AnalyticsService.shared.report(event: "click", screen: "Main", item: "track")
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: currentDate)
        if selectedDay > today {
            return
        }
        
        let isCompleted = completedTrackersIDs.contains(tracker.id)
        
        if isCompleted {
            completedTrackers.removeAll { record in
                record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: currentDate)
            }
            try? trackerRecordStore.removeRecord(TrackerRecord(trackerId: tracker.id, date: currentDate))
        } else {
            let newRecord = TrackerRecord(trackerId: tracker.id, date: currentDate)
            completedTrackers.append(newRecord)
            try? trackerRecordStore.addRecord(newRecord)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.identifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        let calendar = Calendar.current
        let isCompleted = completedTrackersIDs.contains(tracker.id)
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: currentDate)
        let isEnabled = selectedDay <= today
        
        cell.configure(
            with: tracker,
            isCompleted: isCompleted,
            completedDays: completedDays,
            isEnabled: isEnabled
        )
        cell.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerHeaderView.identifier,
            for: indexPath
        ) as? TrackerHeaderView else {
            return UICollectionReusableView()
        }
        
        header.configure(with: visibleCategories[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 32 - 9) / 2
        return CGSize(width: width, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 46)
    }
}

// MARK: - CreateTrackerDelegate
extension TrackersViewController: CreateTrackerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            try trackerStore.addTracker(tracker, toCategoryWithTitle: categoryTitle)
        } catch {
            print("Failed to add tracker: \(error)")
        }
    }
    
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            try trackerStore.updateTracker(tracker, toCategoryWithTitle: categoryTitle)
        } catch {
            print("Failed to update tracker: \(error)")
        }
    }
}

// MARK: - TrackerStoreDelegate
extension TrackersViewController: TrackerStoreDelegate {
    func store(_ store: TrackerStore, didUpdate update: TrackerStoreUpdate) {
        loadCategories()
    }
}

// MARK: - TrackerCategoryStoreDelegate
extension TrackersViewController: TrackerCategoryStoreDelegate {
    func store(_ store: TrackerCategoryStore, didUpdate update: TrackerCategoryStoreUpdate) {
        loadCategories()
    }
}

// MARK: - TrackerRecordStoreDelegate
extension TrackersViewController: TrackerRecordStoreDelegate {
    func store(_ store: TrackerRecordStore, didUpdate update: TrackerRecordStoreUpdate) {
        loadCompletedTrackers()
        updateVisibleCategories()
    }
}

// MARK: - FilterViewControllerDelegate
extension TrackersViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filter: TrackerFilter) {
        self.selectedFilter = filter
        if filter == .today {
            currentDate = Date()
            datePicker.setDate(currentDate, animated: true)
        }
        updateVisibleCategories()
    }
}

// MARK: - Context Menu
extension TrackersViewController {
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        let pinTitle = tracker.isPinned ? L10n.contextUnpin : L10n.contextPin
        let pinAction = UIAction(title: pinTitle) { [weak self] _ in
            self?.togglePin(tracker)
        }
        
        let editAction = UIAction(title: L10n.contextEdit) { [weak self] _ in
            self?.editTracker(tracker, indexPath: indexPath)
        }
        
        let deleteAction = UIAction(title: L10n.contextDelete, attributes: .destructive) { [weak self] _ in
            self?.confirmDelete(tracker)
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [pinAction, editAction, deleteAction])
        }
    }
}
