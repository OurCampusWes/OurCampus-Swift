//
//  BrowseProfsViewController.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/9/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class BrowseProfsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var text: String = ""
    @IBOutlet weak var professor: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var difficultyRate: UILabel!
    
    // declare database
    var ref : DatabaseReference?
    var refCheck : DatabaseReference?
    var rates = [Double]()
    var diffRates = [Double]()
    var lectureRates = [Double]()
    var recommendRates = [Double]()
    var fascilRates = [Double]()
    
    @IBOutlet weak var tblComments: UITableView!
    var commentList = [CommentsModel]()
    var commentListClass = [CommentsModel]()
    var savedList = [CommentsModel]()
    
    let network = NetworkManager.sharedInstance
    
    @IBOutlet weak var depsList: UITextView!
    @IBOutlet weak var numberOfRevs: UILabel!
    
    var user: User?
    
    var profsDepsDict = [[String] : [String]]()
    var depsList2 = [String]()
    var profsAndDeps = [String]()
    var depsListWithProfs = [String: [[String]]]()
    var psSplitUpNames = [[String]]()
    var classes = [String]()
    
    var selectedRow : Int!
    @IBOutlet weak var reviewStack: UIStackView!
    @IBOutlet weak var reviewsLabelInst: UILabel!
    @IBOutlet weak var noSubs: UILabel!
    @IBOutlet weak var topRowLabels: UIStackView!
    
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var recentButton: UIButton!
    @IBOutlet weak var classButton: UIButton!
    
    var recentOrClass: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        
        recentOrClass = true
        tblComments.isHidden = true
        buttonStack.isHidden = true
        topRowLabels.isHidden = true
        reviewsLabelInst.isHidden = true
        reviewStack.isHidden = true
        noSubs.isHidden = false
        getRatings()
        setUpButtons()
        
        let deps = getDeps()
        var depsFull = ""
        for x in deps {
            if deps[0] == x {
                depsFull = x
            }
            else {
                depsFull = depsFull + ", " + x
            }
        }
        depsList.text = depsFull
        
        tblComments.separatorColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        
        professor!.text = text
        
        // segue to compose
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.compose, target: self, action: #selector(self.navigateToSubmitVC))
        
        network.reachability.whenUnreachable = { reachability in
            self.showOfflinePage()
        }
        
        if Auth.auth().currentUser != nil {
            user = Auth.auth().currentUser
        }
        else {
            navigationController?.popToRootViewController(animated: true)
        }
        
        self.tblComments.addSubview(self.refreshControl)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is EvalClassViewController
        {
            let vc = segue.destination as? EvalClassViewController
            vc?.profsSplitUpNames = psSplitUpNames
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList = depsList2
            vc?.depsListWithProfs = depsListWithProfs
            vc?.classes = classes
            vc?.prof = text
        }
        
        else if segue.destination is BrowseReviewViewController {
            let vc = segue.destination as? BrowseReviewViewController
            let com = commentList[selectedRow]
            vc?.cl = com.className!
            vc?.rate = com.rate!
            vc?.grade = com.grade!
            vc?.comment = com.comment!
            vc?.userPosted = com.user!
            vc?.difficulty = com.difficulty!
            vc?.recommend = com.recommend!
            vc?.lecture = com.lecture!
            vc?.accessible = com.accessible!
            vc?.returnSpeed = com.returns!
            vc?.feedback = com.feedback!
            vc?.discussion = com.discussion!
        }
    }
    
    // refresh table
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        refreshControl.attributedTitle = NSMutableAttributedString(string: "Fetching Reviews ...")
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.commentList.removeAll()
        recentOrClass = true
        setUpButtons()
        getRatings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.tblComments.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    func setUpButtons() {
        recentButton.layer.cornerRadius = 5
        recentButton.layer.borderWidth = 2.0
        recentButton.layer.masksToBounds = true
        recentButton.titleLabel?.font = UIFont(name: "Georgia", size: 14)
        recentButton.setTitleColor(UIColor.black, for: .normal)
        recentButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        recentButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        
        classButton.layer.cornerRadius = 5
        classButton.layer.borderWidth = 2.0
        classButton.layer.masksToBounds = true
        classButton.titleLabel?.font = UIFont(name: "Georgia", size: 14)
        classButton.setTitleColor(UIColor.black, for: .normal)
        classButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        classButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if recentOrClass {
            return commentList.count
        }
        return commentListClass.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! BrowseProfessorsTableViewCell
        let com: CommentsModel
        
        if indexPath.row == 0 {
            tblComments.isHidden = false
            reviewsLabelInst.isHidden = false
            numberOfRevs.isHidden = false
            noSubs.isHidden = true
            topRowLabels.isHidden = false
            buttonStack.isHidden = false
            reviewStack.isHidden = false
            noSubs.isHidden = true
        }
        
        if recentOrClass {
            com = commentList[indexPath.row]
            cell.cl.text = com.className
            cell.rate.text = com.rate
            cell.difficulty.text = com.difficulty
            cell.comment.text = com.comment
        }
        else {
            com = commentListClass[indexPath.row]
            cell.cl.text = com.className
            cell.rate.text = com.rate
            cell.difficulty.text = com.difficulty
            cell.comment.text = com.comment
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let p1: CommentsModel
        p1 = commentList[indexPath.row]
        let num = p1.comment?.count
        return CGFloat(320 + (CGFloat(num!) / (UIScreen.main.bounds.width - 15)))
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        performSegue(withIdentifier: "toTable", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getAverage(lst: [Double]) -> Double {
        var sum = 0.0
        for i in lst {
            sum += i
        }
        let avg = sum / Double(lst.count)
        let avg2 = Double(round(100*avg)/100)
        
        return avg2
    }
    
    // compose a rating
    @objc func navigateToSubmitVC() {
        performSegue(withIdentifier: "toClass", sender: nil)
    }
    
    func getRatings() {
        refCheck = Database.database().reference()
        let profName = self.text.replacingOccurrences(of: ".", with: "")
        refCheck?.child("Ratings").observe(.value, with: {(snap) in
            if snap.childrenCount > 0 {
                for prof in snap.children.allObjects as! [DataSnapshot] {
                    let p1 = prof.key as String
                    if p1 == profName {
                        self.ref = Database.database().reference().child("Ratings" + "/" + profName + "/")
                        self.ref?.observeSingleEvent(of: .value, with: {(snapshot) in
                            if snapshot.childrenCount > 0 {
                                var num = 0 
                                for x in snapshot.children.allObjects as! [DataSnapshot] {
                                    let infoObj = x.value as? [String: AnyObject]
                                    let c = infoObj?["class"]
                                    let r = infoObj?["rate"]
                                    let dr = infoObj?["difficulty"]
                                    let com = infoObj?["comments"]
                                    let grade = infoObj?["grade"]
                                    let recom = infoObj?["recommend"]
                                    let feedback = infoObj?["feedback"]
                                    let access = infoObj?["accessible"]
                                    let lecture = infoObj?["lecture"]
                                    let returns = infoObj?["returns"]
                                    let discussion = infoObj?["discussion"]
                                    let user = infoObj?["user"] as! String?
                                    let date = infoObj?["timestamp"]
                                    
                                    var recommendedStr: String
                                    if recom as! String? == "Yes" {
                                        recommendedStr = "1"
                                    }
                                    else {
                                        recommendedStr = "0"
                                    }
                                    let comment1 = CommentsModel(rate1: r as! String?, difficulty1: dr as! String?, com1: com as! String?, className1: c as! String?, acc: access as! String?, feed: feedback as! String?, rec: recommendedStr, lect: lecture as! String?, ret: returns as! String?, disc: discussion as! String?, grade1: grade as! String?, user1: user, d: date as! String?)
                                    
                                    // ensure post has not already been added
                                    var contains = false
                                    for i in self.commentList {
                                        if i.user == user {
                                            contains = true
                                        }
                                    }
                                    if contains == false {
                                        self.commentList.append(comment1)
                                        let rateStr = r as! String
                                        let drStr = dr as! String
                                        let recStr = recommendedStr 
                                        let lectStr = lecture as! String
                                        let fascStr = discussion as! String
                                        let rateInt:Int = Int(rateStr) ?? 0
                                        let drInt:Int = Int(drStr) ?? 0
                                        let recInt:Int = Int(recStr) ?? 0
                                        let lectInt:Int = Int(lectStr) ?? 0
                                        let fascInt:Int = Int(fascStr) ?? 0
                                        let rateDub:Double = Double(exactly: rateInt) ?? 0.0
                                        let drDub:Double = Double(exactly: drInt) ?? 0.0
                                        let recDub:Double = Double(exactly: recInt) ?? 0.0
                                        let lectDub:Double = Double(exactly: lectInt) ?? 0.0
                                        let fascDub:Double = Double(exactly: fascInt) ?? 0.0
                                        self.rates.append(rateDub)
                                        self.diffRates.append(drDub)
                                        self.recommendRates.append(recDub)
                                        self.lectureRates.append(lectDub)
                                        self.fascilRates.append(fascDub)
                                        num += 1
                                        
                                        self.numberOfRevs.text = String(num)
                                    }
                                }
                            }
                            if self.numberOfRevs.text == "1" {
                                self.reviewsLabelInst.text = "Review (Tap to Expand):"
                            }
                            else {
                                self.reviewsLabelInst.text = "Reviews (Tap to Expand):"
                            }
                            self.commentListClass = self.commentList.sorted(by: { (a, b) -> Bool in
                                if let x1 = a.className {
                                    if let x2 = b.className {
                                        return x1 > x2
                                    }
                                    return false
                                }
                                return false
                            })
                            self.commentList = self.commentList.sorted(by: { (a, b) -> Bool in
                                if let x1 = a.date {
                                    if let x2 = b.date {
                                        let dateformatter = DateFormatter()
                                        dateformatter.dateFormat = "MM/dd/yy, h:mm a"
                                        if let a = dateformatter.date(from: x1) {
                                            if let b = dateformatter.date(from: x2) {
                                                return a > b
                                            }
                                            return false
                                        }
                                       return false
                                    }
                                    return false
                                }
                                return false
                            })
                            self.tblComments.isHidden = false
                            self.tblComments.reloadData()
                            self.rate.text = String(self.getAverage(lst: self.rates))
                            self.difficultyRate.text = String(self.getAverage(lst: self.diffRates))
                            self.rate.font = self.rate.font.withSize(36)
                            self.difficultyRate.font = self.difficultyRate.font.withSize(36)
                            let rateSt = self.rate.text ?? "0.0"
                            let rateAsDub: Double = Double(rateSt) ?? 0.0
                            let drSt = self.difficultyRate.text ?? "0.0"
                            let drAsDub: Double = Double(drSt) ?? 0.0
                            if rateAsDub > 2.5 {
                                self.rate.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                            }
                            else {
                                self.rate.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                            }
                            if drAsDub < 2.5 {
                                self.difficultyRate.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                            }
                            else {
                                self.difficultyRate.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                            }
                            
                            let recRateAvg = self.getAverage(lst: self.recommendRates)
                            let lectRateAvg = self.getAverage(lst: self.lectureRates)
                            let fascilRateAvg = self.getAverage(lst: self.fascilRates)
                            
                            
                            self.ref?.removeAllObservers()
                        })
                    }
                }
            }
        })
        ref?.removeAllObservers()
    }
    
    func getDeps() -> [String] {
        for p in self.profsDepsDict.keys {
            let key = convertProf(ps: p)
            let k = key.replacingOccurrences(of: ".", with: "")
            if (text == k) || (text == key) {
                return profsDepsDict[p]!
            }
        }
        return ["Professor is not listed under a department per Wesleyan's website"]
    }
    
    func convertProf(ps: [String]) -> String {
        return ps[1] + ", " + ps[0]
    }
    
    @IBAction func toolbar(_ sender: Any) {
        performSegue(withIdentifier: "toTools", sender: nil)
    }
    
    @IBAction func sortByClass(_ sender: Any) {
        if recentOrClass {
            self.savedList = self.commentList
            self.commentList = self.commentListClass
            classButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            classButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            recentButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            recentButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            recentOrClass = false
            tblComments.reloadData()
        }
        
    }
    @IBAction func sortByRecent(_ sender: Any) {
        if !recentOrClass {
            if self.savedList.count == 0 {
                self.savedList = self.commentList
            }
            self.commentList = self.savedList
            recentOrClass = true
            classButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            classButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            recentButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            recentButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            
            tblComments.reloadData()
        }
    }
    
}
