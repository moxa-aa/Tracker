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
            self?.switchToTabBar()
        }
    }

    private func switchToTabBar() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        let tabBarVC = TabBarViewController()

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarVC
        }, completion: nil)
    }
}
