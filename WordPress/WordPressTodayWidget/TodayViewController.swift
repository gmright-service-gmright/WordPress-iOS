import UIKit
import NotificationCenter
import CocoaLumberjack
import WordPressComStatsiOS
import WordPressShared

class TodayViewController: UIViewController {
    @IBOutlet var unconfiguredView: UIStackView!
    @IBOutlet var configureMeLabel: UILabel!
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var configuredView: UIStackView!
    @IBOutlet var countContainerView: UIView!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var configureMeButton: UIButton!

    var siteID: NSNumber?
    var timeZone: TimeZone?
    var oauthToken: String?
    var siteName: String = ""
    var visitorCount: Int = 0
    var viewCount: Int = 0
    var isConfigured = false
    var tracks = Tracks(appGroupName: WPAppGroupName)

    override func viewDidLoad() {
        super.viewDidLoad()

        let labelText = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app " +
            "under your site > Stats > Today.", comment: "Unconfigured stats today widget helper text")
        configureMeLabel.text = labelText

        let buttonText = NSLocalizedString("Open WordPress", comment: "Today widget button to launch WP app")
        configureMeButton.setTitle(buttonText, for: .normal)

        let backgroundImage = UIImage(color: .primary)
        let resizableBackgroundImage = backgroundImage?.resizableImage(withCapInsets: UIEdgeInsets.zero)
        configureMeButton.setBackgroundImage(resizableBackgroundImage, for: .normal)

        configureMeButton.clipsToBounds = true
        configureMeButton.layer.cornerRadius = 5.0

        siteNameLabel.text = "-"
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = "-"
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = "-"

        changeTextColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadSavedData()
        updateLabels()
        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TodayWidgetStats.saveData(views: viewCount, visitors: visitorCount)
    }

    func loadSavedData() {
        let data = TodayWidgetStats.loadSavedData()
        visitorCount = data.visitors
        viewCount = data.views
    }

    func updateLabels() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        visitorsCountLabel.text = numberFormatter.string(from: NSNumber(value: visitorCount)) ?? "0"
        viewsCountLabel.text = numberFormatter.string(from: NSNumber(value: viewCount)) ?? "0"

        siteNameLabel.text = siteName
    }

    func changeTextColor() {
        configureMeLabel.textColor = .text
        siteNameLabel.textColor = .text
        visitorsCountLabel.textColor = .text
        viewsCountLabel.textColor = .text
        visitorsLabel.textColor = .textSubtle
        viewsLabel.textColor = .textSubtle
    }

    @IBAction func launchContainingApp() {
        if let unwrappedSiteID = siteID {
            tracks.trackExtensionStatsLaunched(unwrappedSiteID.intValue)
            extensionContext!.open(URL(string: "\(WPComScheme)://viewstats?siteId=\(unwrappedSiteID)")!, completionHandler: nil)
        } else {
            tracks.trackExtensionConfigureLaunched()
            extensionContext!.open(URL(string: "\(WPComScheme)://")!, completionHandler: nil)
        }
    }

    func updateUIBasedOnWidgetConfiguration() {
        unconfiguredView.isHidden = isConfigured
        configuredView.isHidden = !isConfigured

        view.setNeedsUpdateConstraints()
    }

    func retrieveSiteConfiguration() {
        let sharedDefaults = UserDefaults(suiteName: WPAppGroupName)!
        siteID = sharedDefaults.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber
        siteName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        oauthToken = fetchOAuthBearerToken()

        if let timeZoneName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey) {
            timeZone = TimeZone(identifier: timeZoneName)
        }

        isConfigured = siteID != nil && timeZone != nil && oauthToken != nil
    }

    func fetchOAuthBearerToken() -> String? {
        let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetKeychainTokenKey, andServiceName: WPStatsTodayWidgetKeychainServiceName, accessGroup: WPAppKeychainAccessGroup)

        return oauth2Token as String?
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()
        DispatchQueue.main.async {
            self.updateUIBasedOnWidgetConfiguration()
        }

        if isConfigured == false {
            DDLogError("Missing site ID, timeZone or oauth2Token")

            completionHandler(NCUpdateResult.failed)
            return
        }

        tracks.trackExtensionAccessed()

        let statsService: WPStatsService = WPStatsService(siteId: siteID,
                                                          siteTimeZone: timeZone,
                                                          oauth2Token: oauthToken,
                                                          andCacheExpirationInterval: 0,
                                                          apiBaseUrlString: WordPressComRestApi.apiBaseURLString)
        statsService.retrieveTodayStats(completionHandler: { wpStatsSummary, error in
            DDLogInfo("Downloaded data in the Today widget")

            DispatchQueue.main.async {
                self.visitorCount = (wpStatsSummary?.visitors)!
                self.viewCount = (wpStatsSummary?.views)!

                self.siteNameLabel?.text = self.siteName
                self.visitorsCountLabel?.text = self.visitorCount
                self.viewsCountLabel?.text = self.viewCount
            }
            completionHandler(NCUpdateResult.newData)
            }, failureHandler: { error in
                DDLogError("\(String(describing: error))")

                if let error = error as? URLError, error.code == URLError.badServerResponse {
                    self.isConfigured = false
                    self.updateUIBasedOnWidgetConfiguration()
                }

                completionHandler(NCUpdateResult.failed)
        })
    }
}
