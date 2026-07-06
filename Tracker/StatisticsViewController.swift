import UIKit

final class StatisticsViewController: UIViewController {
    
    private let trackerRecordStore: TrackerRecordStore
    
    // MARK: - UI Components
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "emptyStateStatistics")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.statisticsEmptyText
        label.textColor = .ypBlack
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let borderView: GradientBorderView = {
        let view = GradientBorderView()
        view.borderWidth = 1.0
        view.cornerRadius = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypBlack
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypBlack
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = L10n.statisticsCompletedTrackers
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initializers
    init(trackerRecordStore: TrackerRecordStore) {
        self.trackerRecordStore = trackerRecordStore
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatistics()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = L10n.statisticsTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        
        view.addSubview(statsContainer)
        statsContainer.addSubview(cardView)
        cardView.addSubview(borderView)
        cardView.addSubview(countLabel)
        cardView.addSubview(captionLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Empty state view
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            emptyImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 70),
            emptyImageView.heightAnchor.constraint(equalToConstant: 70),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            
            // Stats container
            statsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Card view
            cardView.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            borderView.topAnchor.constraint(equalTo: cardView.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            countLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            countLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            captionLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 7),
            captionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    private func updateStatistics() {
        do {
            let records = try trackerRecordStore.fetchRecords()
            let completedCount = records.count
            
            if completedCount > 0 {
                countLabel.text = "\(completedCount)"
                statsContainer.isHidden = false
                emptyStateView.isHidden = true
            } else {
                statsContainer.isHidden = true
                emptyStateView.isHidden = false
            }
        } catch {
            statsContainer.isHidden = true
            emptyStateView.isHidden = false
        }
    }
}
