import UIKit

final class TrackerLogoView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        let topBar = UIView()
        topBar.backgroundColor = .white
        topBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBar)

        let leftLeg = UIView()
        leftLeg.backgroundColor = .white
        leftLeg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftLeg)

        let rightLeg = UIView()
        rightLeg.backgroundColor = .white
        rightLeg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightLeg)


        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 80),
            heightAnchor.constraint(equalToConstant: 80),

            topBar.topAnchor.constraint(equalTo: topAnchor),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 12),

            leftLeg.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            leftLeg.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftLeg.widthAnchor.constraint(equalToConstant: 12),
            leftLeg.bottomAnchor.constraint(equalTo: bottomAnchor),

            rightLeg.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            rightLeg.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightLeg.widthAnchor.constraint(equalToConstant: 12),
            rightLeg.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

final class LaunchViewController: UIViewController {
    private let trackerStore: TrackerStore
    private let trackerCategoryStore: TrackerCategoryStore
    private let trackerRecordStore: TrackerRecordStore
    
    init(trackerStore: TrackerStore, trackerCategoryStore: TrackerCategoryStore, trackerRecordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.trackerCategoryStore = trackerCategoryStore
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        scheduleTransition()
    }

    private func setupUI() {
        view.backgroundColor = .ypBlue

        let logoImageView = UIImageView(image: UIImage(named: "practicumLogo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 91),
            logoImageView.heightAnchor.constraint(equalToConstant: 94)
        ])
    }

    private func scheduleTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            let hasCompleted = UserDefaults.standard.bool(forKey: UserDefaults.hasCompletedOnboardingKey)
            if !hasCompleted {
                self.switchToOnboarding()
            } else {
                self.switchToTabBar()
            }
        }
    }

    private func switchToOnboarding() {
        let window = self.view.window ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
        guard let window = window else { return }

        let onboardingVC = OnboardingViewController()
        onboardingVC.onCompletion = { [weak window] in
            guard let window = window else { return }
            UserDefaults.standard.set(true, forKey: UserDefaults.hasCompletedOnboardingKey)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let tabBarVC = TabBarViewController(
                trackerStore: appDelegate.trackerStore,
                trackerCategoryStore: appDelegate.trackerCategoryStore,
                trackerRecordStore: appDelegate.trackerRecordStore
            )
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = tabBarVC
            }, completion: nil)
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = onboardingVC
        }, completion: nil)
    }

    private func switchToTabBar() {
        let window = self.view.window ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
        guard let window = window else { return }

        let tabBarVC = TabBarViewController(
            trackerStore: trackerStore,
            trackerCategoryStore: trackerCategoryStore,
            trackerRecordStore: trackerRecordStore
        )

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarVC
        }, completion: nil)
    }
}
