import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ categoryTitle: String)
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
        tableView.rowHeight = 75
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.configure(
            text: "Привычки и события можно\nобъединить по смыслу",
            image: UIImage(named: "emptyStateStar")
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
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
        navigationItem.title = "Категория"
        navigationItem.hidesBackButton = true
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addCategoryButton)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        
        addCategoryButton.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view layout
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -24),
            
            // Empty state view layout
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Add Category button layout at bottom
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Bindings
    private func bindViewModel() {
        viewModel.onCategoriesUpdated = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.updateUIState()
        }
        
        viewModel.onCategorySelected = { [weak self] category in
            guard let self = self else { return }
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
        return viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        cell.backgroundColor = .ypLightGray
        cell.selectionStyle = .none
        
        let title = viewModel.categoryTitle(at: indexPath.row)
        cell.textLabel?.text = title
        cell.textLabel?.textColor = .ypBlack
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        
        // Show checkmark if selected
        if viewModel.isSelected(at: indexPath.row) {
            let checkmarkImage = UIImage(systemName: "checkmark")
            let checkmarkView = UIImageView(image: checkmarkImage)
            checkmarkView.tintColor = .ypBlue
            cell.accessoryView = checkmarkView
        } else {
            cell.accessoryView = nil
        }
        
        // Custom rounding corners of rows
        let rowCount = viewModel.numberOfCategories()
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 16
        
        if rowCount == 1 {
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == rowCount - 1 {
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cell.layer.maskedCorners = []
        }
        
        // Add divider line between options
        cell.contentView.subviews.forEach { if $0.tag == 100 { $0.removeFromSuperview() } }
        if rowCount > 1 && indexPath.row < rowCount - 1 {
            let separator = UIView()
            separator.tag = 100
            separator.backgroundColor = .ypGray.withAlphaComponent(0.5)
            separator.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(separator)
            
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                separator.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
        
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
