import UIKit

final class StatisticsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .ypWhite
        navigationItem.title = L10n.statisticsTitle
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
