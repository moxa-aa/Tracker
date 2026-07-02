import UIKit

protocol FilterViewControllerDelegate: AnyObject {
    func didSelectFilter(_ filter: TrackerFilter)
}

enum TrackerFilter: String, CaseIterable {
    case all
    case today
    case completed
    case incomplete
    
    var localizedTitle: String {
        switch self {
        case .all: return L10n.filtersAll
        case .today: return L10n.filtersToday
        case .completed: return L10n.filtersCompleted
        case .incomplete: return L10n.filtersIncomplete
        }
    }
}

final class FilterViewController: UIViewController {
    
    weak var delegate: FilterViewControllerDelegate?
    private var selectedFilter: TrackerFilter
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.rowHeight = 75
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Initialization
    init(selectedFilter: TrackerFilter) {
        self.selectedFilter = selectedFilter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = L10n.filtersTitle
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
}

// MARK: - UITableViewDataSource
extension FilterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TrackerFilter.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.identifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let filter = TrackerFilter.allCases[indexPath.row]
        let isSelected = filter == selectedFilter
        
        let position: CellPosition
        if TrackerFilter.allCases.count == 1 {
            position = .single
        } else if indexPath.row == 0 {
            position = .first
        } else if indexPath.row == TrackerFilter.allCases.count - 1 {
            position = .last
        } else {
            position = .middle
        }
        
        cell.configure(title: filter.localizedTitle, isSelected: isSelected, position: position)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filter = TrackerFilter.allCases[indexPath.row]
        selectedFilter = filter
        tableView.reloadData()
        
        // Wait briefly for checkmark change visual effect, then inform delegate and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectFilter(filter)
            self.dismiss(animated: true)
        }
    }
}
