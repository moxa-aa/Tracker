import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ categoryTitle: String)
}

private enum UIConstants {
    static let rowHeight: CGFloat = 75
    static let tableViewTopOffset: CGFloat = 24
    static let tableViewHorizontalOffset: CGFloat = 16
    static let tableViewBottomOffset: CGFloat = -24
    static let buttonHorizontalOffset: CGFloat = 20
    static let buttonBottomOffset: CGFloat = -16
    static let buttonHeight: CGFloat = 60
}

private enum TextConstants {
    static let emptyStateText = L10n.emptyStateCategoriesPlaceholder
    static let addCategoryButtonTitle = L10n.categoryAdd
    static let navigationTitle = L10n.categoryTitle
}

final class CategoryViewController: UIViewController {
    
    // MARK: - Delegate
    weak var delegate: CategoryViewControllerDelegate?
    
    // MARK: - Properties
    private let viewModel: CategoryViewModel
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.rowHeight = UIConstants.rowHeight
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.configure(
            text: TextConstants.emptyStateText,
            image: UIImage(named: "emptyStateStar")
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TextConstants.addCategoryButtonTitle, for: .normal)
        button.backgroundColor = .ypBlack
        button.setTitleColor(.ypWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
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
        bindViewModel()
        updateUIState()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = TextConstants.navigationTitle
        navigationItem.hidesBackButton = true
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addCategoryButton)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        
        addCategoryButton.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UIConstants.tableViewTopOffset),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.tableViewHorizontalOffset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.tableViewHorizontalOffset),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: UIConstants.tableViewBottomOffset),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.tableViewHorizontalOffset),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.tableViewHorizontalOffset),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.buttonHorizontalOffset),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.buttonHorizontalOffset),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: UIConstants.buttonBottomOffset),
            addCategoryButton.heightAnchor.constraint(equalToConstant: UIConstants.buttonHeight)
        ])
    }
    
    // MARK: - Bindings
    private func bindViewModel() {
        viewModel.onCategoriesUpdated = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.updateUIState()
        }
        
        viewModel.onCategorySelected = { [weak self] category in
            guard let self else { return }
            self.delegate?.didSelectCategory(category)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func updateUIState() {
        let hasCategories = viewModel.numberOfCategories() > 0
        tableView.isHidden = !hasCategories
        emptyStateView.isHidden = hasCategories
    }
    
    // MARK: - Actions
    @objc private func addCategoryButtonTapped() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.delegate = self
        navigationController?.pushViewController(newCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let title = viewModel.categoryTitle(at: indexPath.row)
        let isSelected = viewModel.isSelected(at: indexPath.row)
        
        let rowCount = viewModel.numberOfCategories()
        let position: CellPosition
        if rowCount == 1 {
            position = .single
        } else if indexPath.row == 0 {
            position = .first
        } else if indexPath.row == rowCount - 1 {
            position = .last
        } else {
            position = .middle
        }
        
        cell.configure(title: title, isSelected: isSelected, position: position)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.row)
    }
}

// MARK: - NewCategoryViewControllerDelegate
extension CategoryViewController: NewCategoryViewControllerDelegate {
    func didCreateCategory(with title: String) {
        do {
            try viewModel.addNewCategory(title: title)
        } catch {
            print("Failed to save new category: \(error)")
        }
    }
}
