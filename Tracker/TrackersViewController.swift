import UIKit

final class TrackersViewController: UIViewController {

    // MARK: - UI Components
    private let searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.placeholder = "Поиск"
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
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
    
    private func updateCompletedTrackersIDs() {
        let calendar = Calendar.current
        let currentCompleted = completedTrackers.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
        completedTrackersIDs = Set(currentCompleted.map { $0.trackerId })
    }
    
    private var visibleCategories: [TrackerCategory] = []
    private var currentDate: Date = Date() {
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
    }

    private func setupNavigationBar() {
        navigationItem.title = "Трекеры"
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
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
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
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Actions & Callbacks
    @objc private func plusButtonTapped() {
        let typeSelectionVC = TrackerTypeSelectionViewController()
        typeSelectionVC.delegate = self
        let navController = UINavigationController(rootViewController: typeSelectionVC)
        present(navController, animated: true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        updateVisibleCategories()
    }

    @objc private func searchTextChanged() {
        searchQuery = searchTextField.text ?? ""
        updateVisibleCategories()
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
        
        var filteredCategories: [TrackerCategory] = []
        
        for category in categories {
            let filteredTrackers = category.trackers.filter { tracker in
                let matchesDay = tracker.schedule.contains(selectedWeekDay)
                let matchesSearch = searchQuery.isEmpty || tracker.name.lowercased().contains(searchQuery.lowercased())
                return matchesDay && matchesSearch
            }
            
            if !filteredTrackers.isEmpty {
                filteredCategories.append(TrackerCategory(title: category.title, trackers: filteredTrackers))
            }
        }
        
        self.visibleCategories = filteredCategories
        collectionView.reloadData()
        
        let isListEmpty = visibleCategories.isEmpty
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
