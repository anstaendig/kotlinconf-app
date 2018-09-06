import UIKit
import konfios

enum SessionsMode {
    case all
    case favorites
}

class SessionsViewController: UITableViewController {
    private static let SEND_ID_ONCE_KEY = "send_uuid_once"
    private lazy var konfService = AppDelegate.me.konfService
    private var mode = SessionsMode.all
    private var sessionsTableData: [[KTSessionModel]] = []

    @IBOutlet weak var pullToRefresh: UIRefreshControl!

    @IBAction func tabSelected(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
        self.mode = (segmentedControl.selectedSegmentIndex == 0) ? .all : .favorites

        self.updateTableContent()
        if let tableView = self.tableView, sessionsTableData.count > 0 {
            tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }

    override func viewDidLoad() {
        if (mode == .all) {
            if (!sendUuidIfNeeded()) { self.refreshSessions(self) }
        } else {
            self.refreshFavorites()
            self.refreshVotes()
        }
    }
    
    private func sendUuidIfNeeded() -> Bool {
        let userDefaults = UserDefaults.standard
        guard !userDefaults.bool(forKey: SessionsViewController.SEND_ID_ONCE_KEY) else { return false }
        
//        konfService.register().then(block: { (result) -> KTStdlibUnit in
//            self.refreshSessions(self)
//
//            userDefaults.set(result as! Bool, forKey: SessionsViewController.SEND_ID_ONCE_KEY)
//            return KUnit
//        })
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateTableContent()
    }

    @IBAction func refreshSessions(_ sender: Any) {
        konfService.update { (data, error) -> KTStdlibUnit in
            self.pullToRefresh?.endRefreshing()
            
            if (error != nil) {
                error?.printStackTrace()
                self.showPopupText(title: "Failed to refresh")
            } else {
                self.updateTableContent()
            }
            return KTUnit
        }
    }

    private func refreshFavorites() {
//        konfService.refresh().then { (result) -> KTStdlibUnit in
//            if (self.mode == .favorites) {
//                self.updateTableContent()
//            }
//            return KUnit
//        }.catch { (error) -> KTStdlibUnit in
//            return KUnit
//        }
    }

    private func refreshVotes() {
//        konfService.refresh()
    }
    
    /**
     * Prepare TableView state
     */
    
    private func updateTableContent() {
        switch self.mode {
        case .all:
            fillDataWith(sessions: konfService.sessions)
            break
        case .favorites:
            fillDataWith(sessions: konfService.favorites)
            break
        }

        self.tableView?.reloadData()        
    }
    
    private func fillDataWith(sessions: [KTSessionModel]) {
//        let sortedSessions = sessions.sorted(by: { (left, right) -> Bool in
//            let byComparator = left.compareTo(other: right)
//            if byComparator != 0 { return byComparator < 0 }
//            if left.roomId != right.roomId { return left.roomId!.compare(right.roomId!).rawValue > 0 }
//            if left.id != right.id { return left.id!.compare(right.id!).rawValue > 0 }
//            return false
//        })

        sessionsTableData = []
        sessions.forEach({ (session) in
            if sessionsTableData.count == 0 ||
                sessionsTableData.last!.first!.startsAt != session.startsAt  {
                sessionsTableData.append([session]);
                return
            }

            sessionsTableData[sessionsTableData.count - 1].append(session)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch (segue.identifier ?? "") {
            case "ShowSession":
                guard
                    let selectedCell = sender as? SessionsTableViewCell,
                    let selectedPath = tableView?.indexPath(for: selectedCell)
                else { return }

                let sessionViewController = segue.destination as! SessionViewController
                let bucket = selectedPath.section
                let row = selectedPath.row
                if (sessionsTableData.count <= bucket || sessionsTableData[bucket].count <= row) { return }
                sessionViewController.session = sessionsTableData[bucket][row]
            default: break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sessionsTableData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sessionsTableData.count <= section { return 0 }
        return sessionsTableData[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Session", for: indexPath) as! SessionsTableViewCell
        let bucket = indexPath.section
        let row = indexPath.row
        if sessionsTableData.count <= bucket || sessionsTableData[bucket].count <= row { return cell }
        cell.setup(for: sessionsTableData[bucket][row])
        return cell
    }
}

class SessionsTableViewCell : UITableViewCell {
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var icon: UIImageView!

    func setup(for session: KTSessionModel) {
        titleLabel.text = session.title
        dateLabel.text = session.startsAt.toReadableDateTimeString()
    }
}
