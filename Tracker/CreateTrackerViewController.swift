import UIKit

protocol CreateTrackerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
}

final class CreateTrackerViewController: UIViewController {
    
    // MARK: - Delegate
    weak var delegate: CreateTrackerDelegate?
    
    // MARK: - State Properties
    private var isHabit: Bool = true
    private var trackerName: String = ""
    private var selectedSchedule: Set<WeekDay> = []
    private var selectedCategory: String?
    
    // MARK: - Selected Style Properties
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    
    private let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝️", "😪"
    ]
    
    private let colors: [UIColor] = [
        UIColor(hex: "#FD4C49"), // 1
        UIColor(hex: "#FF9241"), // 2
        UIColor(hex: "#007BFA"), // 3
        UIColor(hex: "#6E44FE"), // 4
        UIColor(hex: "#33CF74"), // 5
        UIColor(hex: "#E662B1"), // 6
        UIColor(hex: "#F9D4D4"), // 7
        UIColor(hex: "#34A7FE"), // 8
        UIColor(hex: "#46E69B"), // 9
        UIColor(hex: "#5C34FA"), // 10
        UIColor(hex: "#FF7455"), // 11
        UIColor(hex: "#FF9ECA"), // 12
        UIColor(hex: "#F5E06C"), // 13
        UIColor(hex: "#3562F8"), // 14
        UIColor(hex: "#832CF1"), // 15
        UIColor(hex: "#AD56F6"), // 16
        UIColor(hex: "#8D6CFF"), // 17
        UIColor(hex: "#2FD658")  // 18
    ]
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isScrollEnabled = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private var collectionViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .clear
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = .ypLightGray
        textField.textColor = .ypBlack
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.layer.cornerRadius = 16
        textField.layer.masksToBounds = true
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 75))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let optionsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.rowHeight = 75
        table.separatorStyle = .none
        table.isScrollEnabled = false
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(.ypRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.backgroundColor = .ypGray
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Configure Controller
    func configure(isHabit: Bool) {
        self.isHabit = isHabit
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = isHabit ? "Новая привычка" : "Новое нерегулярное событие"
        navigationItem.hidesBackButton = true
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameTextField)
        contentView.addSubview(optionsTableView)
        contentView.addSubview(collectionView)
        
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(createButton)
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: EmojiCollectionViewCell.identifier)
        collectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: ColorCollectionViewCell.identifier)
        collectionView.register(
            CreateTrackerHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CreateTrackerHeaderView.identifier
        )
        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        let tableHeight: CGFloat = isHabit ? 150 : 75
        
        NSLayoutConstraint.activate([
            // Scroll view layout
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -8),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Name text field
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            // Options table view
            optionsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            optionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: tableHeight),
            
            // Collection view below options table view
            collectionView.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: 32),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // Button stack view at the absolute bottom
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 450)
        collectionViewHeightConstraint?.isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionViewHeightConstraint?.constant = collectionView.contentSize.height
    }
    
    // MARK: - Validation
    private func validateInputs() {
        let isNameValid = !trackerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isScheduleValid = !isHabit || !selectedSchedule.isEmpty
        let isEmojiValid = selectedEmoji != nil
        let isColorValid = selectedColor != nil
        let isCategoryValid = selectedCategory != nil
        
        let isValid = isNameValid && isScheduleValid && isEmojiValid && isColorValid && isCategoryValid
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? .ypBlack : .ypGray
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange(_ textField: UITextField) {
        trackerName = textField.text ?? ""
        validateInputs()
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard let selectedEmoji = selectedEmoji,
              let selectedColor = selectedColor,
              let selectedCategory = selectedCategory else { return }
        
        let trackerSchedule: Set<WeekDay>
        if isHabit {
            trackerSchedule = selectedSchedule
        } else {
            trackerSchedule = Set(WeekDay.allCases)
        }
        
        let tracker = Tracker(
            id: UUID(),
            name: trackerName,
            color: selectedColor,
            emoji: selectedEmoji,
            schedule: trackerSchedule
        )
        
        delegate?.didCreateTracker(tracker, categoryTitle: selectedCategory)
        dismiss(animated: true)
    }
    
    // Helper to format selected weekdays into string (e.g. "Пн, Ср, Пт")
    private func formatScheduleSubtitle() -> String? {
        if selectedSchedule.isEmpty { return nil }
        if selectedSchedule.count == 7 { return "Каждый день" }
        
        // Sort days logically from Monday to Sunday
        let sortedDays = WeekDay.allCases.filter { selectedSchedule.contains($0) }
        let shortNames = sortedDays.map { day -> String in
            switch day {
            case .monday: return "Пн"
            case .tuesday: return "Вт"
            case .wednesday: return "Ср"
            case .thursday: return "Чт"
            case .friday: return "Пт"
            case .saturday: return "Сб"
            case .sunday: return "Вс"
            }
        }
        return shortNames.joined(separator: ", ")
    }
}

// MARK: - UITextFieldDelegate
extension CreateTrackerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITableViewDataSource
extension CreateTrackerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isHabit ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Reuse or create custom-styled subtitle cell
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "OptionCell")
        cell.backgroundColor = .ypLightGray
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.textColor = .ypBlack
        
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        cell.detailTextLabel?.textColor = .ypGray
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Категория"
            cell.detailTextLabel?.text = selectedCategory
        } else {
            cell.textLabel?.text = "Расписание"
            cell.detailTextLabel?.text = formatScheduleSubtitle()
        }
        
        // Rounding corners of the table rows
        let rowCount = isHabit ? 2 : 1
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 16
        
        if rowCount == 1 {
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == 1 {
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        // Add divider line between the two options if Habit
        if isHabit && indexPath.row == 0 {
            let separator = UIView()
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
extension CreateTrackerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let viewModel = CategoryViewModel(
                trackerCategoryStore: appDelegate.trackerCategoryStore,
                selectedCategory: selectedCategory
            )
            let categoryVC = CategoryViewController(viewModel: viewModel)
            categoryVC.delegate = self
            navigationController?.pushViewController(categoryVC, animated: true)
        } else if indexPath.row == 1 {
            // Push Schedule Screen
            let scheduleVC = ScheduleViewController()
            scheduleVC.delegate = self
            scheduleVC.configure(with: selectedSchedule)
            navigationController?.pushViewController(scheduleVC, animated: true)
        }
    }
}

// MARK: - ScheduleViewControllerDelegate
extension CreateTrackerViewController: ScheduleViewControllerDelegate {
    func didSelectSchedule(_ schedule: Set<WeekDay>) {
        self.selectedSchedule = schedule
        optionsTableView.reloadData()
        validateInputs()
    }
}

// MARK: - UICollectionViewDataSource
extension CreateTrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? emojis.count : colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiCollectionViewCell.identifier,
                for: indexPath
            ) as? EmojiCollectionViewCell else {
                return UICollectionViewCell()
            }
            let emoji = emojis[indexPath.item]
            let isSelected = emoji == selectedEmoji
            cell.configure(with: emoji, isSelected: isSelected)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorCollectionViewCell.identifier,
                for: indexPath
            ) as? ColorCollectionViewCell else {
                return UICollectionViewCell()
            }
            let color = colors[indexPath.item]
            let isSelected = color == selectedColor
            cell.configure(with: color, isSelected: isSelected)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: CreateTrackerHeaderView.identifier,
            for: indexPath
        ) as? CreateTrackerHeaderView else {
            return UICollectionReusableView()
        }
        
        let title = indexPath.section == 0 ? "Emoji" : "Цвет"
        header.configure(with: title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CreateTrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let leftRightInsets: CGFloat = 36
        let cellsWidth: CGFloat = 52 * 6
        let totalSpacing = collectionView.frame.width - leftRightInsets - cellsWidth
        return max(5, totalSpacing / 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 34)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            selectedEmoji = emojis[indexPath.item]
            collectionView.reloadSections(IndexSet(integer: 0))
        } else {
            selectedColor = colors[indexPath.item]
            collectionView.reloadSections(IndexSet(integer: 1))
        }
        validateInputs()
    }
}

// MARK: - EmojiCollectionViewCell
final class EmojiCollectionViewCell: UICollectionViewCell {
    static let identifier = "EmojiCollectionViewCell"
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        contentView.backgroundColor = isSelected ? .ypLightGray : .clear
    }
}

// MARK: - ColorCollectionViewCell
final class ColorCollectionViewCell: UICollectionViewCell {
    static let identifier = "ColorCollectionViewCell"
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        if isSelected {
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
        }
    }
}

// MARK: - CreateTrackerHeaderView
final class CreateTrackerHeaderView: UICollectionReusableView {
    static let identifier = "CreateTrackerHeaderView"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypBlack
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

// MARK: - CategoryViewControllerDelegate
extension CreateTrackerViewController: CategoryViewControllerDelegate {
    func didSelectCategory(_ categoryTitle: String) {
        self.selectedCategory = categoryTitle
        optionsTableView.reloadData()
        validateInputs()
    }
}
