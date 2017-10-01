import Foundation
import Gridicons

class LoginSocialErrorViewController: UITableViewController {
    fileprivate var errorTitle: String
    fileprivate var errorDescription: String

    init(title: String, description: String) {
        errorTitle = title
        errorDescription = description

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        errorTitle = aDecoder.value(forKey: "errorTitle") as? String ?? ""
        errorDescription = aDecoder.value(forKey: "errorDescription") as? String ?? ""

        super.init(coder: aDecoder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.estimatedRowHeight = 100.0

        view.backgroundColor = WPStyleGuide.greyLighten30()
    }
}


// MARK: UITableViewDelegate methods

extension LoginSocialErrorViewController {
    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case buttons = 1

        static var count: Int {
            return buttons.rawValue + 1
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Sections.titleAndDescription.rawValue:
            return 300.0
        case Sections.buttons.rawValue:
            fallthrough
        default:
            return 50.0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}


// MARK: UITableViewDataSource methods

extension LoginSocialErrorViewController
{
    private struct Constants {
        static let buttonCount = 3
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.buttons.rawValue:
            return Constants.buttonCount
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Sections.titleAndDescription.rawValue:
            cell = titleAndDescriptionCell()
        case Sections.buttons.rawValue:
            fallthrough
        default:
            cell = buttonCell(index: indexPath.row)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }

    private func titleAndDescriptionCell() -> UITableViewCell {
        return LoginSocialErrorCell(title: errorTitle, description: errorDescription)
    }

    private func buttonCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell(frame: .zero)
        let buttonText: String
        let buttonIcon: UIImage
        switch index {
        case 0:
            buttonText = NSLocalizedString("Try with another email", comment: "When social login fails, this button offers to let the user try again with a differen email address")
            buttonIcon = Gridicon.iconOfType(.undo)
        case 1:
            buttonText = NSLocalizedString("Try with the site address", comment: "When social login fails, this button offers to let them try tp login using a URL")
            buttonIcon = Gridicon.iconOfType(.domains)
        case 2:
            fallthrough
        default:
            buttonText = NSLocalizedString("Sign up", comment: "When social login fails, this button offers to let them signup for a new WordPress.com account")
            buttonIcon = Gridicon.iconOfType(.mySites)
        }
        cell.textLabel?.text = buttonText
        cell.imageView?.image = buttonIcon.imageWithTintColor(WPStyleGuide.grey())
        return cell
    }
}
