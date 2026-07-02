import UIKit

protocol TrackerCellDelegate: AnyObject {
    func didTapDoneButton(in cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    
    // MARK: - Reuse Identifier
    static let identifier = "TrackerCell"
    
    // MARK: - Delegate
    weak var delegate: TrackerCellDelegate?
    
    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypBlack
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 17
        button.layer.masksToBounds = true
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupViews() {
        contentView.addSubview(cardView)
        cardView.addSubview(emojiContainerView)
        emojiContainerView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)
        
        contentView.addSubview(daysLabel)
        contentView.addSubview(doneButton)
        
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Card view
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            // Emoji container
            emojiContainerView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiContainerView.widthAnchor.constraint(equalToConstant: 24),
            emojiContainerView.heightAnchor.constraint(equalToConstant: 24),
            
            // Emoji label
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainerView.centerYAnchor),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            // Done button
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            doneButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            doneButton.widthAnchor.constraint(equalToConstant: 34),
            doneButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Days label
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor),
            daysLabel.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -8)
        ])
    }
    
    // MARK: - Actions
    @objc private func doneButtonTapped() {
        delegate?.didTapDoneButton(in: self)
    }
    
    // MARK: - Configure Cell
    func configure(with tracker: Tracker, isCompleted: Bool, completedDays: Int, isEnabled: Bool) {
        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        
        // Dynamic counter pluralization (Russian)
        daysLabel.text = formatDaysString(completedDays)
        
        // Button state styling
        doneButton.backgroundColor = tracker.color
        let imageName = isCompleted ? "checkmark" : "plus"
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        let image = UIImage(systemName: imageName, withConfiguration: config)
        doneButton.setImage(image, for: .normal)
        
        // Opacity and interaction rules based on whether it is future date / completed
        if isCompleted {
            doneButton.alpha = 0.3
        } else {
            doneButton.alpha = 1.0
        }
        
        doneButton.isEnabled = isEnabled
        if !isEnabled {
            doneButton.alpha = 0.15
        }
    }
    
    // Helper to format days string (e.g. 1 день, 2 дня, 5 дней)
    private func formatDaysString(_ count: Int) -> String {
        return L10n.numberOfDays(count)
    }
}
