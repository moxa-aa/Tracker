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
    private let defaultCategoryTitle = "Важные дела"
    
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
        
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(createButton)
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        
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
            optionsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // Button stack view at the absolute bottom
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Validation
    private func validateInputs() {
        let isNameValid = !trackerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isScheduleValid = !isHabit || !selectedSchedule.isEmpty
        
        let isValid = isNameValid && isScheduleValid
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
        let trackerSchedule: Set<WeekDay>
        if isHabit {
            trackerSchedule = selectedSchedule
        } else {
            // For irregular events, they occur every day in schedule matching or we can represent them as scheduled for all days
            // The requirement says: "(Кнопки «Расписание» здесь нет, так как это нерегулярное событие)."
            // But let's check: a tracker matches schedule of a given day. For irregular events, they should show up every day or just be available to check in.
            // Let's set the schedule of irregular events to contain all 7 days of the week so it matches any day of the week selected by the date picker!
            // That is incredibly smart because then it will show up and be interactable on any day.
            trackerSchedule = Set(WeekDay.allCases)
        }
        
        // Random style details (Figma colors selection 1 to 6)
        let colors: [UIColor] = [
            UIColor(hex: "#FD4C49"),
            UIColor(hex: "#FF9241"),
            UIColor(hex: "#007BFA"),
            UIColor(hex: "#6E44FE"),
            UIColor(hex: "#33CF74"),
            UIColor(hex: "#F56B6C")
        ]
        let emojis = ["😪", "🧹", "💻", "💪", "🚀", "🎨", "🍿", "🍔", "🎸"]
        
        let randomColor = colors.randomElement() ?? UIColor(hex: "#33CF74")
        let randomEmoji = emojis.randomElement() ?? "😪"
        
        let tracker = Tracker(
            id: UUID(),
            name: trackerName,
            color: randomColor,
            emoji: randomEmoji,
            schedule: trackerSchedule
        )
        
        delegate?.didCreateTracker(tracker, categoryTitle: defaultCategoryTitle)
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
            cell.detailTextLabel?.text = defaultCategoryTitle
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
        if indexPath.row == 1 {
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
