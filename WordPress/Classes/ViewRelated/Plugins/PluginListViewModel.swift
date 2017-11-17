import WordPressKit
import WordPressFlux

protocol PluginPresenter: class {
    func present(plugin: PluginState, capabilities: SitePluginCapabilities)
}

class PluginListViewModel: Observable {
    enum State {
        case loading
        case ready(SitePlugins)
        case error(String)
    }

    let siteID: Int
    let changeDispatcher = Dispatcher<Void>()
    private var state: State = .loading {
        didSet {
            changeDispatcher.dispatch()
        }
    }

    private let store: PluginStore
    private var storeReceipt: Receipt?
    private var actionReceipt: Receipt?
    private var queryReceipt: Receipt?

    init(siteID: Int, store: PluginStore = StoreContainer.shared.plugin) {
        self.siteID = siteID
        self.store = store
        storeReceipt = store.onChange { [weak self] in
            self?.refreshPlugins()
        }
        actionReceipt = ActionDispatcher.global.subscribe { [weak self] (action) in
            guard case PluginAction.receivePluginsFailed(let receivedSiteID, let error) = action,
                case receivedSiteID = siteID else {
                    return
            }
            self?.state = .error(error.localizedDescription)
        }
        queryReceipt = store.query(.all(siteID: siteID))
        refreshPlugins()
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch state {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading plugins", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view plugins", comment: "")
                )
            }
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {
        switch state {
        case .loading, .error:
            return .Empty
        case .ready(let sitePlugins):
            let rows = sitePlugins.plugins.map({ pluginState in
                return PluginListRow(
                    name: pluginState.name,
                    state: pluginState.stateDescription,
                    action: { [weak presenter] (row) in
                        presenter?.present(plugin: pluginState, capabilities: sitePlugins.capabilities)
                })
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [PluginListRow.self]
    }

    private func refreshPlugins() {
        guard let plugins = store.getPlugins(siteID: siteID) else {
            return
        }
        state = .ready(plugins)
    }
}
