import UIKit

protocol NewCategoryViewControllerDelegate: AnyObject {
    func didCreateCategory(with title: String)
}

final class NewCategoryViewController: UIViewController {
    
    // MARK: - Delegate
    weak var delegate: NewCategoryViewControllerDelegate?
    
    // MARK: - UI Components
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
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
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.backgroundColor = .ypGray
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = "Новая категория"
        navigationItem.hidesBackButton = true
        
        view.addSubview(nameTextField)
        view.addSubview(doneButton)
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Text field layout
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            // Done button layout at bottom
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        let isNotEmpty = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        doneButton.isEnabled = isNotEmpty
        doneButton.backgroundColor = isNotEmpty ? .ypBlack : .ypGray
    }
    
    @objc private func doneButtonTapped() {
        guard let text = nameTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        delegate?.didCreateCategory(with: text)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension NewCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
