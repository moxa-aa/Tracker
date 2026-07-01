import UIKit

final class OnboardingPageViewController: UIViewController {
    
    private let backgroundImageName: String
    private let titleText: String
    
    init(backgroundImageName: String, titleText: String) {
        self.backgroundImageName = backgroundImageName
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Background Image View
        let backgroundImageView = UIImageView()
        backgroundImageView.image = UIImage(named: backgroundImageName)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .ypBlack
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -270)
        ])
    }
}

final class OnboardingViewController: UIPageViewController {
    
    var onCompletion: (() -> Void)?
    
    private lazy var pages: [UIViewController] = {
        let firstPage = OnboardingPageViewController(
            backgroundImageName: "onboarding_bg1",
            titleText: "Отслеживайте только то, что хотите"
        )
        let secondPage = OnboardingPageViewController(
            backgroundImageName: "onboarding_bg2",
            titleText: "Даже если это не литры воды и йога"
        )
        return [firstPage, secondPage]
    }()
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = pages.count
        control.currentPage = 0
        control.currentPageIndicatorTintColor = .ypBlack
        control.pageIndicatorTintColor = .ypGray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Вот это технологии!", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.ypWhite, for: .normal)
        button.backgroundColor = .ypBlack
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapConfirmButton), for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        
        setupViews()
    }
    
    private func setupViews() {
        view.addSubview(pageControl)
        view.addSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            confirmButton.heightAnchor.constraint(equalToConstant: 60),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -24)
        ])
    }
    
    @objc private func didTapConfirmButton() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onCompletion?()
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        guard previousIndex >= 0 else { return nil }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        guard nextIndex < pages.count else { return nil }
        return pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentViewController = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = index
        }
    }
}
