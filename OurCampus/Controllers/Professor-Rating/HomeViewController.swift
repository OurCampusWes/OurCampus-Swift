//
//  HomeViewController.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/12/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import Firebase
import FirebaseAuth
import FirebaseDatabase
import SystemConfiguration
import Kanna
import Alamofire
import Fabric
import Crashlytics
import FirebaseMessaging
import FirebaseStorage
import MessageUI

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // declare database
    var ref : DatabaseReference?
    
    // firebase account
    var user : User?
    
    var depData: [String] = [String]()
    
    // rates
    var ratesList = [TopRatesModel]()
    var difficultyList = [TopRatesModel]()
    var overallRates = [TopRatesModel]()
    var chosenProf: String!
    
    // table of teacher rates
    @IBOutlet weak var tblRates: UITableView!
    
    let network = NetworkManager.sharedInstance
    
    var progressHUD: ProgressHUD!
    
    var professors = [[String]]()
    
    var depsProfsDict = [String: [[String]]]()
    var profsDepsDict = [[String] : [String]]()
    
    // refresh table
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        refreshControl.attributedTitle = NSMutableAttributedString(string: "Fetching Top Professors ...")
        return refreshControl
    }()
    @IBOutlet weak var bestProfs: UIButton!
    @IBOutlet weak var easiestProfs: UIButton!
    var ratesOrDiff : Bool!
    
    var classes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        self.getRatings()
        tblRates.isHidden = true
        progressHUD = ProgressHUD(text: "Loading")
        view.addSubview(self.progressHUD)
        self.tblRates.addSubview(self.refreshControl)
        // if user is not logged in then go back to sign in, if they are then display account email
        if Auth.auth().currentUser != nil {
            self.user = Auth.auth().currentUser
        }
        else {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        // instantiating database
        self.ref = Database.database().reference()
        
        // check network
        self.network.reachability.whenUnreachable = { reachability in
            self.showOfflinePage()
        }
        
        ratesOrDiff = true
        setUpFilterButtons()
        self.getRatings()
        self.tblRates.reloadData()
        
        // study: https://www.uis.edu/aeo/wp-content/uploads/sites/10/2014/09/Race-and-Gender-Bias-in-Higher-Education-Could-Faculty-Course-Ev.pdf
        let alert = UIAlertController(title: "ATTENTION", message: "Research has shown unconscious biases in regards to race, gender, and other identities can at times negatively influence our professor evaluations. While these reviews do not directly impact teacher tenure and hiring, they could potentially influence a professor's class size, and therefore their career. Please keep these potential biases in mind when filling out an evalutation.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        
        depsProfsDict = getDepsProfs()
        depData = getDeps()
        professors = getProfList()
        profsDepsDict = getProfDeps()
        classes = getClasses()
        
        
    }

    
    func getTabBarBadge() {
        if let tabItems = tabBarController?.tabBar.items {
            // In this case we want to modify the badge number of the third tab:
            let tabItem = tabItems[2]
            var notis = 0
            
            let path = "Users/" + self.user!.uid + "/Notifications"
            self.ref?.child(path).observeSingleEvent(of: .value, with: {(snapshot) in
                if snapshot.childrenCount > 0 {
                    for e in snapshot.children.allObjects as! [DataSnapshot] {
                        let infoObj = e.value as? [String: AnyObject]
                        let eventid = infoObj?["eventid"] as! String
                        let viewed = infoObj?["viewed"] as! Bool
                        // get event display name
                        self.ref?.child("Events/" + eventid).observeSingleEvent(of: .value, with: {(snapshot3) in
                            if snapshot3.childrenCount > 0 {
                                let infoObj2 = snapshot3.value as? [String: AnyObject]
                                let eventtitle = infoObj2?["title"] as! String
                                if !viewed {
                                    notis += 1
                                }
                                if notis == 0 {
                                    tabItem.badgeValue = nil
                                }
                                else {
                                    tabItem.badgeValue = String(notis)
                                }
                            }
                        })
                    }
                }
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getTabBarBadge()
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // segue to other VCs
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
       
        if segue.destination is OldPostsViewController
        {
            let vc = segue.destination as? OldPostsViewController
            vc?.user = user?.email ?? ""
        }
        
        else if segue.destination is BrowseProfsViewController
        {
            let vc = segue.destination as? BrowseProfsViewController
            vc?.text = chosenProf
            vc?.psSplitUpNames = professors
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList2 = depData
            vc?.depsListWithProfs = depsProfsDict
            vc?.classes = classes
        }
            
        else if segue.destination is SearchProfsViewController
        {
            let vc = segue.destination as? SearchProfsViewController
            vc?.profsSplitUpNames = professors
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList = depData
            vc?.depsListWithProfs = depsProfsDict
            vc?.classes = classes
        }
            
        else if segue.destination is SearchToBrowseViewController
        {
            let vc = segue.destination as? SearchToBrowseViewController
            vc?.psSplitUpNames = professors
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList = depData
            vc?.depsListWithProfs = depsProfsDict
            vc?.classes = classes
        }
        
        else if segue.destination is SubscribeViewController {
            let vc = segue.destination as? SubscribeViewController
            vc?.allClasses = classes
        }
    }
    @IBAction func toPrivacy(_ sender: Any) {
        performSegue(withIdentifier: "toPrivacy", sender: nil)
    }
    
    func setUpFilterButtons() {
        easiestProfs.layer.cornerRadius = 5
        easiestProfs.layer.borderWidth = 2.0
        easiestProfs.layer.masksToBounds = true
        easiestProfs.titleLabel?.font = UIFont(name: "Georgia", size: 14)
        easiestProfs.setTitleColor(UIColor.black, for: .normal)
        easiestProfs.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        easiestProfs.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        
        bestProfs.layer.cornerRadius = 5
        bestProfs.layer.borderWidth = 2.0
        bestProfs.layer.masksToBounds = true
        bestProfs.titleLabel?.font = UIFont(name: "Georgia", size: 14)
        bestProfs.setTitleColor(UIColor.black, for: .normal)
        bestProfs.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        bestProfs.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.tblRates.isHidden = true
        self.ratesList.removeAll()
        self.tblRates.reloadData()
        self.reloadData()
    }
    
    func reloadData() {
        var total = 0
        self.ref?.child("Ratings").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for p in snapshot.children.allObjects as! [DataSnapshot] {
                    let prof = p.key as String
                    self.ref?.child("Ratings" + "/" + prof).observeSingleEvent(of: .value, with: {(snapshot2) in
                        if snapshot2.childrenCount > 0 {
                            var rates = [Double]()
                            var difficulties = [Double]()
                            var num = 0
                            for x in snapshot2.children.allObjects as! [DataSnapshot] {
                                let infoObj = x.value as? [String: AnyObject]
                                let r = infoObj?["rate"]
                                let rateStr = r as! String
                                let rateInt:Int = Int(rateStr) ?? 0
                                let rateDub:Double = Double(exactly: rateInt) ?? 0.0
                                let d = infoObj?["difficulty"]
                                
                           
                               
                                let dStr = d as! String
                                let dInt:Int = Int(dStr) ?? 0
                                let dDub:Double = Double(exactly: dInt) ?? 0.0
                                rates.append(rateDub)
                                difficulties.append(dDub)
                                num += 1
                            }
                            
                            total += num
                            let r = self.getAverage(lst: rates)
                            let d = self.getAverage(lst: difficulties)
                            let r1 = TopRatesModel(rate1: r, prof1: prof, n: String(num))
                            let d1 = TopRatesModel(rate1: d, prof1: prof, n: String(num))
                            
                            var contains = false
                            for i in self.ratesList {
                                if i.prof == prof {
                                    contains = true
                                }
                            }
                            if contains == false {
                                
                                //                                if self.ratesList.count > 20 {
                                //                                    let r2 = self.ratesList[20].rate ?? "0"
                                //                                    let a = Double(r2) ?? 10000.0
                                //                                    let b = Double(r) ?? 0.0
                                //                                    if a.isLess(than: b) {
                                //                                        self.ratesList[20] = r1
                                //                                    }
                                //                                }
                                //                                else {
                                self.ratesList.append(r1)
                                //                                }
                                
                                self.ratesList = self.ratesList.sorted(by: { (a, b) -> Bool in
                                    if let x1 = a.rate {
                                        if let x2 = b.rate {
                                            let x1Dub = Double(x1) ?? 0.0
                                            let x2Dub = Double(x2) ?? 0.0
                                            return x1Dub > x2Dub
                                        }
                                        return false
                                    }
                                    return false
                                })
                            }
                            
                            self.tblRates.reloadData()
                            
                            var contains2 = false
                            for i in self.difficultyList {
                                if i.prof == prof {
                                    contains2 = true
                                }
                            }
                            
                            if contains2 == false {
                                //                                if self.difficultyList.count > 20 {
                                //                                    let d2 = self.difficultyList[20].rate ?? "0"
                                //                                    let a = Double(d2) ?? 10000.0
                                //                                    let b = Double(d) ?? 0.0
                                //                                    if b.isLess(than: a) {
                                //                                        self.difficultyList[20] = d1
                                //                                    }
                                //                                }
                                //                                else {
                                self.difficultyList.append(d1)
                                //                                }
                                self.difficultyList = self.difficultyList.sorted(by: { (a, b) -> Bool in
                                    if let x1 = a.rate {
                                        if let x2 = b.rate {
                                            let x1Dub = Double(x1) ?? 0.0
                                            let x2Dub = Double(x2) ?? 0.0
                                            return x1Dub < x2Dub
                                        }
                                        return false
                                    }
                                    return false
                                })
                                self.tblRates.reloadData()
                            }
                        }
                    })
                }
            }
        })
        
        refreshControl.endRefreshing()
        self.tblRates.isHidden = false
        ref?.removeAllObservers()
        
    }
    @IBAction func goToSubscribe(_ sender: Any) {
        let alert = UIAlertController(title: "Hold up", message: "This feature will be available for next semester's pregistration", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
//        self.performSegue(withIdentifier: "toSubscribe", sender: nil)
    }
    
//    func setUpAdImage() {
//        currentAd.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
//        currentAd.contentMode = .scaleAspectFit
//        currentAd.layer.borderWidth = 2
//
//        Database.database().reference().child("Advertise/Current").observeSingleEvent(of: .value, with: {(snapshot) in
//            if snapshot.childrenCount > 0 {
//                for i in snapshot.children.allObjects as! [DataSnapshot] {
//                    let image = i.value as! String
//                    let imageData = NSData(base64Encoded: image, options: [])
//                    let image2 = UIImage(data: imageData! as Data)
//                    self.currentAd.image = image2
//                }
//            }})
//
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(gesture:)))
//
//        // add it to the image view;
//        currentAd.addGestureRecognizer(tapGesture)
//        // make sure imageView can be interacted with by user
//        currentAd.isUserInteractionEnabled = true
//    }
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        performSegue(withIdentifier: "toAd", sender: nil)
    }
    
    @IBAction func toMyReviews(_ sender: Any) {
        performSegue(withIdentifier: "toMyReviews", sender: nil)
    }
    
    
    @IBAction func searchTapped(_ sender: Any) {
        performSegue(withIdentifier: "searchProfs", sender: nil)
    }
    
    @IBAction func toSettings(_ sender: Any) {
        self.performSegue(withIdentifier: "toSettings", sender: nil)
    }
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    @IBAction func toTerms(_ sender: Any) {
        performSegue(withIdentifier: "toTerms", sender: nil)
    }
    
    
    // set number of teachers in table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ratesOrDiff {
            return ratesList.count
        }
        return difficultyList.count
    }
    
    // set value of each teacher and their rating in table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratesCell", for: indexPath) as! TopRatingsTableViewCell
        let rateModel: TopRatesModel
        
        if indexPath.row == 0 {
            self.progressHUD.isHidden = true
            self.tblRates.isHidden = false
        }
        
        if ratesOrDiff {
            rateModel = ratesList[indexPath.row]
            
            cell.prof.text = rateModel.prof
            cell.rate.text = rateModel.rate
            cell.number.text = "(" + rateModel.num! + ")"
            if indexPath.row == 0 {
                tblRates.isHidden = false
                progressHUD.isHidden = true
            }
            let rate = Double(rateModel.rate!) ?? 0.0
            
            if rate > 4.0  {
                cell.prof.text = cell.prof.text!
            }
        }
        else {
            rateModel = difficultyList[indexPath.row]
            
            cell.prof.text = rateModel.prof
            cell.rate.text = rateModel.rate
            cell.number.text = "(" + rateModel.num! + ")"
            if indexPath.row == 0 {
                tblRates.isHidden = false
                progressHUD.isHidden = true
            }
            let rate = Double(rateModel.rate!) ?? 0.0
            
            if rate < 2.0 {
                cell.prof.text = cell.prof.text!
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselectrow")
        if ratesOrDiff {
            chosenProf = ratesList[indexPath.row].prof
        }
        else {
            chosenProf = difficultyList[indexPath.row].prof
        }
        performSegue(withIdentifier: "toProfs", sender: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // get each teacher"s ratings
    func getRatings() {
        var total = 0
        self.ref?.child("Ratings").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for p in snapshot.children.allObjects as! [DataSnapshot] {
                    let prof = p.key as String
                    self.ref?.child("Ratings" + "/" + prof).observeSingleEvent(of: .value, with: {(snapshot2) in
                        if snapshot2.childrenCount > 0 {
                            var rates = [Double]()
                            var difficulties = [Double]()
                            var num = 0
                            for x in snapshot2.children.allObjects as! [DataSnapshot] {
                                let infoObj = x.value as? [String: AnyObject]
                                let r = infoObj?["rate"]
                                let rateStr = r as! String
                                let rateInt:Int = Int(rateStr) ?? 0
                                let rateDub:Double = Double(exactly: rateInt) ?? 0.0
                                let d = infoObj?["difficulty"]
                                let dStr = d as! String
                                let dInt:Int = Int(dStr) ?? 0
                                let dDub:Double = Double(exactly: dInt) ?? 0.0
                                rates.append(rateDub)
                                difficulties.append(dDub)
                                num += 1
                                
                                // users after giveaway date november 1st 2019
//                                let user = infoObj?["user"] as! String
//                                let date = infoObj?["timestamp"] as! String
//                                let dateformatter = DateFormatter()
//                                dateformatter.dateFormat = "MM/dd/yy, h:mm a"
//                                if date.contains("AM") || date.contains("PM")  {
//                                    let a = dateformatter.date(from: date)!
//                                    let b = dateformatter.date(from: "11/11/19, 9:00 AM")
//                                    if a > b! {
//                                        print(user)
//                                    }
//                                }
                                
                            }
                            
                            total += num
                            let r = self.getAverage(lst: rates)
                            let d = self.getAverage(lst: difficulties)
                            let r1 = TopRatesModel(rate1: r, prof1: prof, n: String(num))
                            let d1 = TopRatesModel(rate1: d, prof1: prof, n: String(num))
                          
                            var contains = false
                            for i in self.ratesList {
                                if i.prof == prof {
                                    contains = true
                                }
                            }
                            if contains == false {
                                
//                                if self.ratesList.count > 20 {
//                                    let r2 = self.ratesList[20].rate ?? "0"
//                                    let a = Double(r2) ?? 10000.0
//                                    let b = Double(r) ?? 0.0
//                                    if a.isLess(than: b) {
//                                        self.ratesList[20] = r1
//                                    }
//                                }
//                                else {
                                self.ratesList.append(r1)
//                                }
                                
                                self.ratesList = self.ratesList.sorted(by: { (a, b) -> Bool in
                                    if let x1 = a.rate {
                                        if let x2 = b.rate {
                                            let x1Dub = Double(x1) ?? 0.0
                                            let x2Dub = Double(x2) ?? 0.0
                                            return x1Dub > x2Dub
                                        }
                                        return false
                                    }
                                    return false
                                })
                            }
                            
                            self.tblRates.reloadData()
                            
                            var contains2 = false
                            for i in self.difficultyList {
                                if i.prof == prof {
                                    contains2 = true
                                }
                            }
                            
                            if contains2 == false {
//                                if self.difficultyList.count > 20 {
//                                    let d2 = self.difficultyList[20].rate ?? "0"
//                                    let a = Double(d2) ?? 10000.0
//                                    let b = Double(d) ?? 0.0
//                                    if b.isLess(than: a) {
//                                        self.difficultyList[20] = d1
//                                    }
//                                }
//                                else {
                                self.difficultyList.append(d1)
//                                }
                                self.difficultyList = self.difficultyList.sorted(by: { (a, b) -> Bool in
                                    if let x1 = a.rate {
                                        if let x2 = b.rate {
                                            let x1Dub = Double(x1) ?? 0.0
                                            let x2Dub = Double(x2) ?? 0.0
                                            return x1Dub < x2Dub
                                        }
                                        return false
                                    }
                                    return false
                                })
                                print("Reviews: " + String(total))
                            }
                        }
                    })
                }
            }
        })
        ref?.removeAllObservers()
    }
    
    // get average rating to be ranked and dislayed
    func getAverage(lst: [Double]) -> String {
        var sum = 0.0
        for i in lst {
            sum += i
        }
        let avg = sum / Double(lst.count)
        let avg2 = Double(round(100*avg)/100)
        let strAvg:String = String(avg2)
        return strAvg
    }
    
    @IBAction func submitReview(_ sender: Any) {
        performSegue(withIdentifier: "toSearch", sender: nil)
    }
    
    @IBAction func bestProfs(_ sender: Any) {
        if !ratesOrDiff {
            self.ratesOrDiff = true
            bestProfs.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            bestProfs.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            easiestProfs.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            easiestProfs.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            self.tblRates.reloadData()
        }
    }
    
    @IBAction func easyProfs(_ sender: Any) {
        if ratesOrDiff {
            self.ratesOrDiff = false
            bestProfs.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            bestProfs.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            easiestProfs.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            easiestProfs.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            self.tblRates.reloadData()
        }
    }
    
    // clears table for when page reloads
    func clearTable() {
        self.ratesList.removeAll()
    }
    
    func getProfDeps() -> [[String]: [String]] {
        return [["Khachig", "Tölölyan"]: ["English", "German Studies", "College of Letters"], ["Felipe", "Ramírez"]: ["Mathematics and Computer Science"], ["Stéphanie", "Ponsavady"]: ["Romance Languages and Literatures"], ["Marcela", "Oteíza"]: ["Theater", "College of the Environment"], ["Ákos", "Östör"]: ["Anthropology"], ["Laverne", "Melón"]: ["Biology"], ["Valeria", "López Fadul"]: ["History", "Latin American Studies"], ["Lutz", "Hüwel"]: ["Physics"],["Blümel", "Reinhold"]: ["Physics"], ["Tony", "Hernandez"]: ["Theater"], ["Victoria", "Smolkin"]: ["College of Social Studies", "History", "Russian, East European, and Eurasian Studies"], ["Lisa", "Weinert"]: ["Shapiro Writing Center"], ["Jeremy", "Zwelling"]: ["Religion"], ["William", "Trousdale"]: ["Physics"], ["Joslyn", "Barnhart Trager"]: ["Government"], ["Elizabeth", "McAlister"]: ["African American Studies", "Religion", "Feminist, Gender, and Sexuality Studies", "American Studies"], ["Hilary", "Barth"]: ["Psychology"], ["Elizabeth", "Milroy"]: ["Art and Art History"], ["Peter", "Dunn"]: ["Romance Languages and Literatures"], ["Julie", "Mulvihill"]: ["Dance"], ["Roman", "Utkin"]: ["Russian, East European, and Eurasian Studies", "Feminist, Gender, and Sexuality Studies"], ["Patrick", "Dowdey"]: ["College of East Asian Studies"], ["Robert", "Cassidy"]: ["Government", "Allbritton Center for the Study of Public Life"], ["Peter", "Wang"]: ["Economics"], ["David", "Kuenzel"]: ["Economics"], ["Meg Furniss", "Weisberg"]: ["Romance Languages and Literatures"], ["Ronald", "Jenkins"]: ["Theater"], ["Eun Ju", "Jung"]: ["Psychology"], ["David", "Snyder"]: ["Physical Education"], ["Rosemary", "Ostfeld"]: ["College of the Environment"], ["Natasha", "Korda"]: ["English", "Center for the Humanities", "Feminist, Gender, and Sexuality Studies"], ["Joseph", "Bruno"]: ["Chemistry"], ["Joseph", "Rouse"]: ["Environmental Studies", "Philosophy", "Science in Society"], ["Katja", "Kolcio"]: ["Environmental Studies", "Russian, East European, and Eurasian Studies", "Dance"], ["John", "Crooke"]: ["Physical Education"], ["Salvatore", "Scibona"]: ["Shapiro Writing Center"], ["Andrea", "Patalano"]: ["Psychology", "Neuroscience and Behavior"], ["Karl", "Scheibe"]: ["Psychology"], ["Martin", "Baeumel"]: ["German Studies"], ["Cecilia", "Miller"]: ["College of Social Studies", "History", "Medieval Studies"], ["David", "Langley"]: ["Chemistry"], ["Marguerite", "Nguyen"]: ["Environmental Studies", "English", "College of East Asian Studies"], ["Phillip", "Wagoner"]: ["Art and Art History", "Archaeology"], ["Anthony", "Keats"]: ["Economics"], ["Alexandra", "Zax"]: ["Psychology"], ["Anthony", "Infante"]: ["Molecular Biology and Biochemistry"], ["Mark", "Hovey"]: ["Mathematics and Computer Science", "College of Integrative Sciences"], ["Psyche", "Loui"]: ["Psychology", "College of Integrative Sciences", "Neuroscience and Behavior"], ["Indira", "Karamcheti"]: ["American Studies"], ["Jeffrey", "Schiff"]: ["Art and Art History"], ["Paul", "Bonin-Rodriguez"]: ["Center for the Arts"], ["Drew", "Black"]: ["Physical Education"], ["Sonali", "Chakravarti"]: ["College of Social Studies", "Government"], ["Ethan", "Kleinberg"]: ["History", "College of Letters"], ["Edward", "Moran"]: ["Astronomy", "College of Integrative Sciences"], ["Katherine", "Brewer Ball"]: ["African American Studies", "Theater"], ["James", "McGuire"]: ["Government", "Latin American Studies"], ["Alfred", "Turco"]: ["English"], ["Emily", "Larned"]: ["Art and Art History"], ["Takeshi", "Watanabe"]: ["College of East Asian Studies"], ["Scott", "Plous"]: ["Psychology"], ["Duffield", "White"]: ["Russian, East European, and Eurasian Studies"], ["Gillian", "Brunet"]: ["Economics"], ["Preston", "Green"]: ["Allbritton Center for the Study of Public Life"], ["John", "Connor"]: ["English"], ["Joseph", "Knee"]: ["Chemistry"], ["Royette", "Tavernier"]: ["Psychology"], ["Yoshiko", "Samuel"]: ["College of East Asian Studies"], ["Ben", "Model"]: ["College of Film and the Moving Image"], ["Harris", "Friedberg"]: ["English"], ["William", "Pinch"]: ["Environmental Studies", "History"], ["Suzanne", "O\"Connell"]: ["Earth and Environmental Sciences"], ["Jane", "Eisner"]: ["Allbritton Center for the Study of Public Life"], ["Lisa", "Cohen"]: ["English", "Feminist, Gender, and Sexuality Studies"], ["Mirko", "Rucnov"]: ["College of Film and the Moving Image"], ["Laurie", "Nussdorfer"]: ["History", "College of Letters"], ["Paul", "Erickson"]: ["Environmental Studies", "History", "Science in Society"], ["Gale", "Lackey"]: ["Physical Education"], ["Michael", "Armstrong Roche"]: ["Romance Languages and Literatures", "Medieval Studies", "Latin American Studies"], ["Philip", "Carney"]: ["Physical Education"], ["Masami", "Imai"]: ["College of East Asian Studies", "Economics"], ["Kate", "TenEyck"]: ["Art and Art History"], ["Casey", "Hayman"]: ["African American Studies"], ["Joseph", "Reed"]: ["English"], ["Julia", "Randall"]: ["Art and Art History"], ["Noemie", "Solomon"]: ["Center for the Arts"], ["Candice", "Etson"]: ["Physics", "Chemistry", "College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Anthony", "Davis"]: ["Chemistry"], ["Douglas", "Martin"]: ["English", "Shapiro Writing Center"], ["Khalil", "Johnson"]: ["African American Studies"], ["T. David", "Westmoreland"]: ["Chemistry", "College of Integrative Sciences"], ["Jesse", "Torgerson"]: ["History", "College of Letters", "Medieval Studies"], ["Demetrius", "Eudell"]: ["History"], ["Hari", "Krishnan"]: ["Feminist, Gender, and Sexuality Studies", "Dance"], ["Ann", "Burke"]: ["Biology"], ["Abigail", "Hornstein"]: ["Economics"], ["Rich", "Olson"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Erik", "Grimmer-Solem"]: ["College of Social Studies", "History", "German Studies"], ["Prof.", "Sumarsam"]: ["Music"], ["Elizabeth", "Hepford"]: ["English", "Shapiro Writing Center"], ["Daniella", "Gandolfo"]: ["Anthropology"], ["J.", "Donady"]: ["Biology"], ["Mitali", "Thakor"]: ["Science in Society"], ["Sherman", "Hawkins"]: ["English"], ["Justin", "Peck"]: ["Government"], ["Peter", "Merkx"]: ["Mathematics and Computer Science"], ["Kee-Hong", "Choi"]: ["Psychology"], ["Michael", "Roberts"]: ["Classical Studies"], ["Hyejoo", "Back"]: ["College of East Asian Studies"], ["Basak", "Kus"]: ["Sociology"], ["Elijah", "Huge"]: ["Environmental Studies", "Art and Art History"], ["Rachel", "Ellis Neyra"]: ["English", "African American Studies"], ["Tula", "Telfair"]: ["Environmental Studies", "Art and Art History"], ["Ronald", "Ebrecht"]: ["Music"], ["Richard", "Boyd"]: ["Government"], ["Octavio", "Flores-Cuadra"]: ["Romance Languages and Literatures"], ["Saray", "Shai"]: ["Mathematics and Computer Science"], ["Gloster", "Aaron"]: ["Office for Equity and Inclusion", "Biology", "College of Integrative Sciences", "Neuroscience and Behavior"], ["Maria", "Ospina"]: ["Romance Languages and Literatures", "Latin American Studies"], ["Jonathan", "Best"]: ["Art and Art History"], ["Andrew", "Chung"]: ["Music"], ["Kari", "Weil"]: ["Environmental Studies", "College of the Environment", "College of Letters"], ["Frederick", "Cohan"]: ["Environmental Studies", "Biology", "College of Integrative Sciences"], ["Phillip", "Wesolek"]: ["Mathematics and Computer Science"], ["Margot", "Weiss"]: ["Anthropology", "Feminist, Gender, and Sexuality Studies", "American Studies"], ["Alyson", "Hildum"]: ["Mathematics and Computer Science"], ["Courtney", "Fullilove"]: ["Environmental Studies", "History", "Science in Society"], ["Nancy", "Schwartz"]: ["Government"], ["Martha", "Gilmore"]: ["Earth and Environmental Sciences"], ["Kim", "Diver"]: ["Earth and Environmental Sciences"], ["Peter", "Gottschalk"]: ["Religion", "Science in Society"], ["Kate", "Mullen"]: ["Physical Education"], ["Marichal", "Monts"]: ["Music"], ["Joseph", "Siry"]: ["Art and Art History"], ["Arthur", "Wensinger"]: ["German Studies"], ["William", "Coley"]: ["English"], ["Robert", "Steele"]: ["Psychology"], ["Jonathan", "Cutler"]: ["Sociology"], ["Matthew", "Garrett"]: ["English", "American Studies"], ["Melanie", "Khamis"]: ["Economics", "Latin American Studies"], ["Morgan", "Day Frank"]: ["English"], ["Victor", "Gourevitch"]: ["Philosophy"], ["Kate", "Galloway"]: ["Music"], ["Francis", "Starr"]: ["Physics", "College of Integrative Sciences"], ["Janice", "Willis"]: ["Religion"], ["Camilla", "Zamboni"]: ["Romance Languages and Literatures"], ["Marilyn", "Katz"]: ["Classical Studies"], ["Vera", "Schwarcz"]: ["History"], ["Ralph", "Baierlein"]: ["Physics"], ["Melisa", "Moreno Garcia"]: ["Chemistry"], ["Patricia", "Beaman"]: ["Dance"], ["Gregory", "Pardlo"]: ["Shapiro Writing Center"], ["Donald", "Russell"]: ["Physical Education"], ["Elizabeth", "Jackson"]: ["Romance Languages and Literatures"], ["Olga", "Sendra Ferrer"]: ["Romance Languages and Literatures"], ["Kathleen", "Conlin"]: ["Theater"], ["Ulrich", "Bach"]: ["German Studies"], ["Eiko", "Otake"]: ["Dance"], ["Barbara", "Adams"]: ["Center for Pedagogical Innovation"], ["Philip", "Scowcroft"]: ["Mathematics and Computer Science"], ["Ruth", "Weissman"]: ["Psychology"], ["Logan", "Dancey"]: ["Government"], ["Fred", "Ellis"]: ["Physics"], ["Amy", "Bloom"]: ["English", "Shapiro Writing Center"], ["Rob", "Rosenthal"]: ["Sociology"], ["Michael", "Schlabs"]: ["Allbritton Center for the Study of Public Life"], ["Quiara", "Hudes"]: ["Theater"], ["Pedro", "Alejandro"]: ["Dance"], ["Calvin", "Anderson"]: ["Theater"], ["Laura", "Grabel"]: ["Biology"], ["Laura", "McCargar"]: ["Allbritton Center for the Study of Public Life"], ["Albert", "Jackson"]: ["Physical Education"], ["John", "Seamon"]: ["Psychology"], ["John", "Bonin"]: ["College of Social Studies", "Russian, East European, and Eurasian Studies", "Economics"], ["Andrew", "Walker"]: ["Center for the Americas"], ["Victoria", "Manfredi"]: ["Mathematics and Computer Science"], ["Geoffrey", "Wheeler"]: ["Physical Education"], ["Mark", "Woodworth"]: ["Physical Education"], ["Alba", "Ramos"]: ["Physics"], ["Greg", "Voth"]: ["Physics", "College of Integrative Sciences"], ["Lisa", "Dierker"]: ["Psychology"], ["David", "Bodznick"]: ["Biology"], ["I.", "Harjito"]: ["Music"], ["Ruth", "Nisse"]: ["English", "Medieval Studies"], ["Stephen", "Devoto"]: ["Biology", "Neuroscience and Behavior"], ["Sara", "Kalisnik Verovsek"]: ["Mathematics and Computer Science"], ["Thomas", "Morgan"]: ["Physics"], ["Michael", "Slowik"]: ["College of Film and the Moving Image"], ["Gabriela", "Jarzebowska"]: ["College of Letters"], ["Rachel", "Lowe"]: ["Chemistry"], ["Andrea", "Roberts"]: ["Chemistry"], ["Andrew", "Szegedy-Maszak"]: ["Environmental Studies", "Classical Studies"], ["Amy", "Tang"]: ["English", "American Studies"], ["Edwin", "Sanchez"]: ["Theater"], ["Christiaan", "Hogendorn"]: ["Economics"], ["Dan", "Licata"]: ["Mathematics and Computer Science"], ["Richard", "Ohmann"]: ["English"], ["Ann", "duCille"]: ["English"], ["Melvin", "Strauss"]: ["Music"], ["James", "Lipton"]: ["Mathematics and Computer Science", "College of Integrative Sciences"], ["Johan", "Varekamp"]: ["Environmental Studies", "Latin American Studies", "Earth and Environmental Sciences"], ["Earl", "Phillips"]: ["Environmental Studies"], ["Brian", "Fay"]: ["Philosophy"], ["Paul", "Schwaber"]: ["College of Letters"], ["Peter", "Rutland"]: ["College of Social Studies", "Government", "Russian, East European, and Eurasian Studies", "Allbritton Center for the Study of Public Life"], ["Chelsie", "McPhilimy"]: ["Dance"], ["Pinar", "Durgun"]: ["Archaeology"], ["Tyshawn", "Sorey"]: ["Music", "African American Studies"], ["Jerome", "Long"]: ["Religion"], ["John", "Finn"]: ["Government"], ["Keiji", "Shinohara"]: ["College of East Asian Studies", "Art and Art History"], ["Jennifer", "Rose"]: ["Center for Pedagogical Innovation"], ["Yamil", "Velez"]: ["Government"], ["Vera", "Grant"]: ["German Studies"], ["Robyn", "Autry"]: ["Sociology"], ["Dana", "Royer"]: ["Environmental Studies", "Earth and Environmental Sciences"], ["Norman", "Danner"]: ["Mathematics and Computer Science"], ["Anthony", "Hager"]: ["Mathematics and Computer Science"], ["Robert", "Rollefson"]: ["Physics"], ["David", "Laub"]: ["College of Film and the Moving Image"], ["Brian", "Northrop"]: ["Chemistry", "College of Integrative Sciences"], ["Gina Athena", "Ulysse"]: ["Anthropology", "Feminist, Gender, and Sexuality Studies"], ["Oliver", "Holmes"]: ["History"], ["Joseph", "Reilly"]: ["Physical Education"], ["Victoria", "Pitts-Taylor"]: ["Science in Society", "Feminist, Gender, and Sexuality Studies", "Sociology"], ["Anne", "Greene"]: ["English", "Shapiro Writing Center"], ["Leslie", "Weinberg"]: ["Theater"], ["Elan", "Abrell"]: ["Philosophy"], ["Alex", "Dupuy"]: ["Sociology"], ["Ulrich", "Plass"]: ["German Studies", "College of Letters"], ["Jay", "Hoggard"]: ["Music", "African American Studies"], ["Mary-Jane", "Rubenstein"]: ["Religion", "Science in Society", "Feminist, Gender, and Sexuality Studies"], ["Scott", "Higgins"]: ["College of Film and the Moving Image"], ["Giovanni", "Miglianti"]: ["Romance Languages and Literatures"], ["Jin Hi", "Kim"]: ["Music"], ["Rene", "Buell"]: ["Chemistry"], ["Clara", "Wilkins"]: ["Psychology"], ["Ethan", "Coven"]: ["Mathematics and Computer Science"], ["Scott", "Aalgaard"]: ["College of East Asian Studies"], ["Christopher", "Parslow"]: ["Art and Art History", "Archaeology", "Classical Studies"], ["John", "Raba"]: ["Physical Education"], ["Barry", "Chernoff"]: ["Environmental Studies", "College of the Environment", "Biology", "Earth and Environmental Sciences"], ["Irina", "Aleshkovsky"]: ["Russian, East European, and Eurasian Studies"], ["Ilesanmi", "Adeboye"]: ["Mathematics and Computer Science"], ["Renee", "Johnson Thornton"]: ["African American Studies"], ["Richard", "Lindquist"]: ["Physics"], ["John", "Murillo"]: ["English"], ["Richard", "Parkin"]: ["College of Film and the Moving Image"], ["Charles", "Sanislow"]: ["Psychology", "Neuroscience and Behavior"], ["Michelle", "Personick"]: ["Chemistry", "College of Integrative Sciences"], ["John", "Dankwa"]: ["Music"], ["Joe", "Cacaci"]: ["College of Film and the Moving Image"], ["Gary", "Shaw"]: ["History", "Medieval Studies"], ["Bruce", "Masters"]: ["History"], ["Jennifer", "Tucker"]: ["Environmental Studies", "History", "Science in Society", "Feminist, Gender, and Sexuality Studies"], ["Kyungmi", "Kim"]: ["Psychology"], ["Abderrahman", "Aissa"]: ["Classical Studies"], ["Kerwin", "Kaye"]: ["College of Social Studies", "Feminist, Gender, and Sexuality Studies", "Sociology"], ["Tess", "Bird"]: ["Shapiro Writing Center"], ["Said", "Sayrafiezadeh"]: ["Shapiro Writing Center"], ["Howard", "Needler"]: ["College of Letters"], ["Sally", "Bachner"]: ["English"], ["Patrick", "Tynan"]: ["Physical Education"], ["Wendy", "Rayack"]: ["College of Social Studies", "Economics"], ["Ben", "Somera"]: ["Physical Education"], ["Damien", "Sheehan-Connor"]: ["College of Social Studies", "Economics"], ["Michael", "Whalen"]: ["Physical Education"], ["Patricia", "Rodriguez Mosquera"]: ["Psychology", "Feminist, Gender, and Sexuality Studies"], ["Gary", "Yohe"]: ["Environmental Studies", "Economics"], ["Joyce", "Jacobsen"]: ["Economics"], ["Jeffrey", "Naecker"]: ["Economics"], ["Rachael", "Barlow"]: ["Shapiro Writing Center"], ["Wai Kiu", "Chan"]: ["Mathematics and Computer Science"], ["Charles", "Barber"]: ["College of Letters"], ["Paula", "Paige"]: ["Romance Languages and Literatures"], ["Han", "Li"]: ["Mathematics and Computer Science"], ["Rex", "Pratt"]: ["Chemistry"], ["Judith", "Brown"]: ["History"], ["Ellen", "Thomas"]: ["Earth and Environmental Sciences", "College of Integrative Sciences"], ["Giulio", "Gallarotti"]: ["Environmental Studies", "College of Social Studies", "Government"], ["L.", "Bendall"]: ["Philosophy"], ["Antonio", "Machado-Allison"]: ["College of the Environment"], ["Eirene", "Visvardi"]: ["Classical Studies"], ["Xiaoxue", "Zhao"]: ["Economics"], ["Sharisse", "Kanet"]: ["Philosophy"], ["Carlos", "Jimenez Hoyos"]: ["Chemistry"], ["Sarah", "Wiliarty"]: ["College of Social Studies", "Government", "German Studies", "Feminist, Gender, and Sexuality Studies"], ["Kelly", "Thayer"]: ["Mathematics and Computer Science"], ["Roy", "Kilgard"]: ["Astronomy", "College of Integrative Sciences"], ["Richard", "Grossman"]: ["Economics"], ["Marc", "Eisner"]: ["Environmental Studies", "Government"], ["Anna", "Shusterman"]: ["Psychology"], ["David", "Nelson"]: ["Music"], ["Peggy", "Carey Best"]: ["Allbritton Center for the Study of Public Life", "Sociology"], ["Allan", "Berlind"]: ["Biology"], ["Ana", "Perez-Girones"]: ["Romance Languages and Literatures"], ["Francesco Marco", "Aresu"]: ["Romance Languages and Literatures", "Medieval Studies"], ["Clifton", "Watson"]: ["Allbritton Center for the Study of Public Life"], ["Alison", "O\"Neil"]: ["Chemistry", "College of Integrative Sciences", "Neuroscience and Behavior"], ["Catherine", "Damman"]: ["Center for the Humanities"], ["Martha", "Crenshaw"]: ["Government"], ["James", "Gutmann"]: ["Earth and Environmental Sciences"], ["Stephen", "Collins"]: ["College of Film and the Moving Image"], ["Elizabeth", "Bobrick"]: ["Classical Studies"], ["Joel", "Pfister"]: ["English", "American Studies"], ["David", "Morgan"]: ["History"], ["Michael", "Rice"]: ["Mathematics and Computer Science"], ["Stephanie", "Weiner"]: ["English"], ["Claire", "Grace"]: ["Art and Art History"], ["Tiphanie", "Yanique"]: ["English", "African American Studies"], ["Ishita", "Mukerji"]: ["Environmental Studies", "College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Richard", "Buel"]: ["History"], ["Matthew", "Treme"]: ["Romance Languages and Literatures"], ["Wallace", "Pringle"]: ["Chemistry"], ["Noah", "Baerman"]: ["Music"], ["Miyuki", "Hatano-Cohen"]: ["College of East Asian Studies"], ["John", "Paoletti"]: ["Art and Art History"], ["Jeff", "Rider"]: ["Romance Languages and Literatures", "Medieval Studies"], ["Ann", "Wightman"]: ["History"], ["Joan", "Cho"]: ["Government", "College of East Asian Studies"], ["Paula", "Matthusen"]: ["Music"], ["Nadya", "Potemkina"]: ["Music", "Russian, East European, and Eurasian Studies"], ["C. Stewart", "Gillmor"]: ["History"], ["Nadja", "Aksamija"]: ["Art and Art History"], ["Nihal", "de Lanerolle"]: ["Neuroscience and Behavior"], ["Richard", "Miller"]: ["Economics"], ["Xiaomiao", "Zhu"]: ["College of East Asian Studies"], ["Barbara", "Craig"]: ["Government"], ["Walter Jr.", "Curry"]: ["Physical Education"], ["Alexis", "May"]: ["Psychology"], ["Ron", "Cameron"]: ["Religion"], ["Joseph", "Coolon"]: ["Biology", "College of Integrative Sciences"], ["Nathan", "Brody"]: ["Psychology"], ["Ying Jia", "Tan"]: ["History", "College of East Asian Studies"], ["Michael", "Calter"]: ["Chemistry", "College of Integrative Sciences"], ["Catherine", "Poisson"]: ["Romance Languages and Literatures", "Feminist, Gender, and Sexuality Studies"], ["George", "Petersson"]: ["Chemistry"], ["Colin", "Smith"]: ["Chemistry", "College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Swapnil", "Rai"]: ["College of Film and the Moving Image"], ["Ronald", "Kuivila"]: ["Music"], ["William", "Stowe"]: ["English"], ["Sonia", "Sultan"]: ["Environmental Studies", "Biology"], ["Nicole", "Stanton"]: ["Environmental Studies", "African American Studies", "Dance"], ["Shona", "Kerr"]: ["Physical Education"], ["Stephen", "Angle"]: ["Philosophy", "College of East Asian Studies"], ["Serena", "Witzke"]: ["Classical Studies"], ["Adam", "Fieldsteel"]: ["Mathematics and Computer Science"], ["Mary Alice", "Haddad"]: ["Environmental Studies", "Government", "College of East Asian Studies"], ["Catherine", "Ostrow"]: ["Romance Languages and Literatures"], ["Naho", "Maruta"]: ["College of East Asian Studies"], ["Allison", "Orr"]: ["College of the Environment"], ["John", "Cooley"]: ["College of Integrative Sciences"], ["Edward", "Torres"]: ["Theater"], ["Mahama", "Bandaogo"]: ["Economics"], ["Alice", "Hadler"]: ["English"], ["David", "Adams"]: ["Psychology"], ["John", "Biatowas"]: ["Music"], ["Justine", "Quijada"]: ["Russian, East European, and Eurasian Studies", "Religion", "College of the Environment"], ["Daniel", "Alvey"]: ["Mathematics and Computer Science"], ["Yaniv", "Feller"]: ["Religion"], ["Salvatore", "LaRusso"]: ["Music"], ["Paula", "Park"]: ["Romance Languages and Literatures", "Latin American Studies"], ["Lingjing", "Li"]: ["College of East Asian Studies"], ["Barbara", "Juhasz"]: ["Allbritton Center for the Study of Public Life", "Psychology", "College of Integrative Sciences", "Neuroscience and Behavior"], ["Mary Ann", "Clawson"]: ["Sociology"], ["Carol", "Wood"]: ["Mathematics and Computer Science"], ["Christopher", "Weaver"]: ["College of Integrative Sciences"], ["H. Shellae", "Versey"]: ["Environmental Studies", "African American Studies", "Psychology"], ["Russell", "Murphy"]: ["Government"], ["Douglas", "Bauer"]: ["Shapiro Writing Center"], ["Brian", "Stewart"]: ["Environmental Studies", "Physics", "College of Integrative Sciences"], ["Daniel", "Drew"]: ["Allbritton Center for the Study of Public Life"], ["Matthew", "Kurtz"]: ["Psychology", "Neuroscience and Behavior"], ["Courtney Weiss", "Smith"]: ["English", "Science in Society"], ["Katherine", "Kuenzli"]: ["German Studies", "Art and Art History"], ["Michael", "Weir"]: ["Biology", "College of Integrative Sciences"], ["Stephen", "Cooke"]: ["Chemistry"], ["Karl", "Boulware"]: ["Economics"], ["Peter", "Mark"]: ["Art and Art History"], ["Janice", "Naegele"]: ["Biology", "Neuroscience and Behavior"], ["Anthony", "Scott"]: ["College of Film and the Moving Image"], ["George", "Paily"]: ["Physics"], ["Timothy", "Ku"]: ["Earth and Environmental Sciences", "College of Integrative Sciences"], ["R. Lincoln", "Keiser"]: ["Anthropology"], ["Jon", "Wilson"]: ["Physical Education"], ["Daniel", "Krizanc"]: ["Environmental Studies", "Mathematics and Computer Science", "College of Integrative Sciences"], ["Steven", "Almond"]: ["Shapiro Writing Center"], ["Joyce", "Powzyk"]: ["Biology"], ["Cynthia", "Matthew"]: ["Psychology"], ["Donald", "Oliver"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Megan", "Glick"]: ["Science in Society", "American Studies"], ["Ayesha", "Ali"]: ["Economics"], ["Christian", "Milik"]: ["Theater"], ["J. Kehaulani", "Kauanui"]: ["Anthropology", "Center for the Americas", "American Studies"], ["Joseph", "Fitzpatrick"]: ["Russian, East European, and Eurasian Studies", "College of Letters"], ["Min-Feng", "Tu"]: ["Physics"], ["Iddrisu", "Saaka"]: ["Dance"], ["Clark", "Maines"]: ["Art and Art History"], ["Abraham", "Adzenyah"]: ["Music"], ["Richard", "Elphick"]: ["History"], ["Joya", "Powell"]: ["Dance"], ["Gabrielle", "Ponce-Hegenauer"]: ["College of Letters"], ["Seth", "Redfield"]: ["Astronomy", "College of Integrative Sciences"], ["Typhaine", "Leservot"]: ["Romance Languages and Literatures", "College of Letters"], ["Ariel", "Levy"]: ["Shapiro Writing Center"], ["Janeann", "Dill"]: ["College of Film and the Moving Image"], ["Richard", "Adelstein"]: ["College of Social Studies", "Economics"], ["Priscilla", "Meyer"]: ["Russian, East European, and Eurasian Studies"], ["Michael", "Meere"]: ["Romance Languages and Literatures", "Medieval Studies"], ["Heather", "Vermeulen"]: ["Center for the Humanities"], ["Talya", "Zemach-Bersin"]: ["Feminist, Gender, and Sexuality Studies"], ["Lisa", "Dombrowski"]: ["College of Film and the Moving Image", "College of East Asian Studies"], ["Erika", "Franklin Fowler"]: ["Government"], ["Bernardo", "Gonzalez"]: ["Romance Languages and Literatures"], ["Joseph", "Weiss"]: ["Anthropology"], ["Suara", "Adediran"]: ["Chemistry"], ["Ellen", "Nerenberg"]: ["Romance Languages and Literatures"], ["Kim", "Williams"]: ["Physical Education"], ["Amir", "Bogen"]: ["Center for Jewish Studies"], ["Peter", "LeTourneau"]: ["Earth and Environmental Sciences"], ["Louise", "Brown"]: ["Government"], ["Nick", "Hastings"]: ["Earth and Environmental Sciences"], ["Jeanine", "Basinger"]: ["College of Film and the Moving Image"], ["Jesse", "Nasta"]: ["African American Studies"], ["Amy", "Grillo"]: ["Center for Pedagogical Innovation"], ["Iris", "Bork-Goldfield"]: ["German Studies"], ["Brando", "Skyhorse"]: ["Shapiro Writing Center"], ["Courtney", "Patterson-Faye"]: ["Sociology"], ["Michael", "Keane"]: ["Mathematics and Computer Science"], ["Phillip", "Resor"]: ["Earth and Environmental Sciences"], ["Conor", "Byrne"]: ["College of Film and the Moving Image"], ["J. Donald", "Moon"]: ["Environmental Studies", "College of Social Studies", "Government"], ["Louise", "Neary"]: ["Romance Languages and Literatures"], ["Susanne", "Fusso"]: ["Russian, East European, and Eurasian Studies"], ["Tushar", "Irani"]: ["Philosophy", "College of Letters"], ["Ruth", "Johnson"]: ["Biology", "College of Integrative Sciences"], ["Meng-ju", "Sher"]: ["College of the Environment", "Physics", "College of Integrative Sciences"], ["Sebastian", "Zimmeck"]: ["Mathematics and Computer Science"], ["Mark", "Slobin"]: ["Music"], ["John", "Carr"]: ["Theater"], ["Charles", "Halvorson"]: ["History"], ["Albert", "Fry"]: ["Chemistry"], ["Patricia", "Hill"]: ["American Studies"], ["Philip", "Pomper"]: ["History"], ["Elise", "Springer"]: ["Philosophy", "Feminist, Gender, and Sexuality Studies"], ["Neely", "Bruce"]: ["Music"], ["Henry", "Abelove"]: ["English"], ["Manju", "Hingorani"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Meredith", "Hughes"]: ["Astronomy", "College of Integrative Sciences"], ["Nathanael", "Greene"]: ["History"], ["Jason", "Lam"]: ["Chemistry"], ["James", "Greenwood"]: ["Earth and Environmental Sciences"], ["Chenmu", "Xing"]: ["Psychology"], ["Lewis", "West"]: ["Religion"], ["Andrew", "Quintman"]: ["Religion", "College of East Asian Studies"], ["Danielle", "Vogel"]: ["English"], ["Daniel", "Smyth"]: ["Philosophy", "College of Letters"], ["Claire", "Schwartz"]: ["Feminist, Gender, and Sexuality Studies"], ["Michelle", "Murolo"]: ["Molecular Biology and Biochemistry"], ["William", "Johnston"]: ["Environmental Studies", "History", "College of East Asian Studies", "Science in Society"], ["Michael", "Fried"]: ["Physical Education"], ["Jeffers", "Lennox"]: ["History"], ["Peter", "Patton"]: ["Earth and Environmental Sciences"], ["Michael", "Lorenzo"]: ["Economics"], ["Mengjun", "Liu"]: ["College of East Asian Studies"], ["Amy", "MacQueen"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Elizabeth", "Traube"]: ["Anthropology", "Feminist, Gender, and Sexuality Studies"], ["Michael", "McAlear"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Chriss", "Sneed"]: ["African American Studies"], ["Jane", "Alden"]: ["Music", "Medieval Studies"], ["Axelle", "Karera"]: ["Philosophy", "African American Studies"], ["Gilbert", "Skillman"]: ["College of Social Studies", "Economics"], ["Summer", "Jack"]: ["Theater"], ["Ellen", "Widmer"]: ["College of East Asian Studies"], ["Anthony", "Hatch"]: ["Environmental Studies", "African American Studies", "Science in Society", "College of the Environment", "Sociology"], ["Pamardi", "Silvester"]: ["Music", "Dance"], ["Tira", "Palmquist"]: ["Theater"], ["Cori", "Anderson"]: ["Molecular Biology and Biochemistry"], ["Krishna", "Winston"]: ["Environmental Studies", "German Studies"], ["Ioana Emy", "Matesan"]: ["College of Social Studies", "Government"], ["Erika", "Taylor"]: ["Environmental Studies", "Chemistry", "College of Integrative Sciences"], ["Anthony", "Braxton"]: ["Music"], ["Rashida", "McMahon"]: ["English", "African American Studies"], ["Barbara", "Merjan"]: ["Music"], ["Patricia", "Klecha-Porter"]: ["Physical Education"], ["Benjamin", "Krupicka"]: ["Government"], ["Jennifer", "Lane"]: ["Physical Education"], ["Annemarie", "Arnold"]: ["German Studies"], ["Constance", "Leidy"]: ["Mathematics and Computer Science"], ["Cameron", "Hill"]: ["Mathematics and Computer Science", "College of Integrative Sciences"], ["Robert", "Lane"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Irina", "Russu"]: ["Chemistry", "College of Integrative Sciences"], ["Sarah", "Kamens"]: ["Psychology"], ["Douglas", "Charles"]: ["Anthropology", "Archaeology"], ["Sean", "McCann"]: ["English", "Shapiro Writing Center"], ["Roger Mathew", "Grant"]: ["Music"], ["Scott", "Kessel"]: ["Art and Art History"], ["Andrew", "Curran"]: ["Romance Languages and Literatures"], ["David", "Pollack"]: ["Mathematics and Computer Science"], ["Donald", "Long"]: ["Physical Education"], ["John", "Biddiscombe"]: ["Physical Education"], ["Mitchell", "Riley"]: ["Mathematics and Computer Science"], ["James", "Mulrooney"]: ["Biology"], ["Gertrude", "Hughes"]: ["English"], ["B.", "Balasubrahmaniyan"]: ["Music"], ["Ronald", "Schatz"]: ["History"], ["Anu (Aradhana)", "Sharma"]: ["Anthropology", "Feminist, Gender, and Sexuality Studies"], ["Christina", "Crosby"]: ["English", "Feminist, Gender, and Sexuality Studies"], ["Ao", "Wang"]: ["College of East Asian Studies"], ["Kelly", "Senters"]: ["Government"], ["Stewart", "Novick"]: ["Chemistry", "College of Integrative Sciences"], ["Marina", "Bilbija"]: ["English"], ["Jennifer", "Calivas"]: ["Art and Art History"], ["Peter", "Solomon"]: ["Physical Education"], ["Laura Ann", "Twagira"]: ["History", "Feminist, Gender, and Sexuality Studies"], ["William", "Francisco"]: ["Theater"], ["Ashraf", "Rushdy"]: ["English", "African American Studies", "Feminist, Gender, and Sexuality Studies"], ["Helen", "Treloar"]: ["Neuroscience and Behavior"], ["Sarah", "Carney"]: ["Psychology"], ["Mario", "Hernandez"]: ["Sociology"], ["Lily", "Saint"]: ["English"], ["David", "Beveridge"]: ["Chemistry", "College of Integrative Sciences"], ["Judy", "Hussie-Taylor"]: ["Center for the Arts"], ["Karen L.", "Collins"]: ["Mathematics and Computer Science", "College of Integrative Sciences"], ["Michael", "Singer"]: ["Environmental Studies", "Biology"], ["John", "Kirn"]: ["Biology", "Neuroscience and Behavior"], ["Corey", "Sorenson"]: ["Theater"], ["Harry", "Sinnamon"]: ["Psychology"], ["Christopher", "Potter"]: ["Physical Education"], ["Richard", "Slotkin"]: ["English"], ["Eric", "Charry"]: ["Music", "Latin American Studies"], ["Kasey", "Jernigan"]: ["Center for the Americas"], ["Sasha", "Rudensky"]: ["Russian, East European, and Eurasian Studies", "Art and Art History"], ["Jodi", "McKenna"]: ["Physical Education"], ["Susan", "Lourie"]: ["Dance"], ["Leo", "Lensing"]: ["College of Film and the Moving Image", "German Studies"], ["Jill", "Morawski"]: ["Psychology", "Science in Society", "Feminist, Gender, and Sexuality Studies"], ["Amity", "Gaige"]: ["Shapiro Writing Center"], ["Simba", "Kamuriwo"]: ["Music"], ["Joyce", "Lowrie"]: ["Romance Languages and Literatures"], ["Makaela", "Kingsley"]: ["Allbritton Center for the Study of Public Life"], ["Douglas", "Foyle"]: ["College of Social Studies", "Government"], ["Helen", "Poulos"]: ["College of the Environment"], ["Mike", "Robinson"]: ["Psychology", "College of Integrative Sciences", "Neuroscience and Behavior"], ["Jason", "Katzenstein"]: ["English", "Shapiro Writing Center"], ["Sanford", "Shieh"]: ["Philosophy"], ["Daniel", "Moller"]: ["College of Integrative Sciences"], ["Martin", "Gosman"]: ["Economics"], ["Marc", "Longenecker"]: ["College of Film and the Moving Image"], ["Laura", "Grappo"]: ["Feminist, Gender, and Sexuality Studies", "American Studies"], ["Joshua", "Lubin-Levy"]: ["Center for the Arts"], ["Christopher", "Chenier"]: ["Art and Art History", "College of Integrative Sciences"], ["William", "Herbst"]: ["Astronomy", "College of Integrative Sciences"], ["Gayle", "Pemberton"]: ["English", "African American Studies"], ["Scott", "Holmes"]: ["College of Integrative Sciences", "Molecular Biology and Biochemistry"], ["Christopher", "Rasmussen"]: ["Mathematics and Computer Science"], ["Lori", "Gruen"]: ["Philosophy", "Science in Society", "Feminist, Gender, and Sexuality Studies"], ["Su", "Zheng"]: ["Music", "College of East Asian Studies", "Feminist, Gender, and Sexuality Studies"], ["Steven", "Horst"]: ["Philosophy", "Science in Society"], ["Talia", "Andrei"]: ["College of East Asian Studies", "Art and Art History"], ["David", "Constantine"]: ["Mathematics and Computer Science"], ["Alex", "Kavvos"]: ["Mathematics and Computer Science"], ["Lily", "Herman"]: ["Allbritton Center for the Study of Public Life"], ["Aly", "Camara"]: ["Dance"], ["Lois", "Brown"]: ["English", "African American Studies", "Feminist, Gender, and Sexuality Studies"], ["Hirsh", "Sawhney"]: ["English"], ["Kate", "Birney"]: ["Art and Art History", "Archaeology", "Classical Studies"], ["Melissa", "Katz"]: ["Art and Art History", "Medieval Studies"], ["Philip", "Bolton"]: ["Chemistry"], ["Yunjeong", "Lee"]: ["College of East Asian Studies"], ["Herbert", "Arnold"]: ["German Studies"], ["Chia-Yu Joy", "Lu"]: ["Music"], ["Phyllis", "Rose"]: ["English"], ["Lauren", "Silber"]: ["English", "Shapiro Writing Center"], ["Robert", "Conn"]: ["Romance Languages and Literatures", "Latin American Studies"], ["Alexander", "Osborn"]: ["Art and Art History"], ["Urip", "Maeny"]: ["Dance"], ["Yu-ting", "Huang"]: ["College of East Asian Studies"], ["Eva", "Meredith"]: ["Physical Education"], ["Greg", "Goldberg"]: ["Sociology"], ["Sue", "Fisher"]: ["Sociology"], ["Michael", "Frisch"]: ["Chemistry"], ["Marcus", "Leppanen"]: ["Psychology"], ["Alvin", "Lucier"]: ["Music"], ["Norman", "Shapiro"]: ["Romance Languages and Literatures"], ["Richard", "Vann"]: ["History"], ["Abigail", "Boggs"]: ["Feminist, Gender, and Sexuality Studies", "Sociology"], ["Justin", "Bryant"]: ["Mathematics and Computer Science"], ["Carla", "Abdo-Katsipis"]: ["College of Social Studies"], ["Dalit", "Katz"]: ["Center for Jewish Studies", "Religion"], ["Leslie", "Gabel-Brett"]: ["Allbritton Center for the Study of Public Life"], ["Steven", "Stemler"]: ["Psychology"], ["Gay", "Smith"]: ["Theater"], ["Daniel", "DiCenzo"]: ["Physical Education"], ["Tsampikos", "Kottos"]: ["Mathematics and Computer Science", "Physics", "College of Integrative Sciences"]]
    }
    
    func getDeps() -> [String] {
        return ["African American Studies", "Allbritton Center for the Study of Public Life", "American Studies", "Anthropology", "Archaeology", "Art and Art History", "Astronomy", "Biology", "Center for Jewish Studies", "Center for Pedagogical Innovation", "Center for the Americas", "Center for the Arts", "Center for the Humanities", "Chemistry", "Classical Studies", "College of East Asian Studies", "College of Film and the Moving Image", "College of Integrative Sciences", "College of Letters", "College of Social Studies", "College of the Environment", "Dance", "Earth and Environmental Sciences", "Economics", "English", "Environmental Studies", "Feminist, Gender, and Sexuality Studies", "German Studies", "Government", "History", "Latin American Studies", "Mathematics and Computer Science", "Medieval Studies", "Molecular Biology and Biochemistry", "Music", "Neuroscience and Behavior", "Office for Equity and Inclusion", "Philosophy", "Physical Education", "Physics", "Psychology", "Religion", "Romance Languages and Literatures", "Russian, East European, and Eurasian Studies", "Science in Society", "Shapiro Writing Center", "Sociology", "Theater"]
    }
    
    func getDepsProfs() -> [String: [[String]]] {
        return ["Center for the Humanities": [["Catherine", "Damman"], ["Natasha", "Korda"], ["Heather", "Vermeulen"]], "American Studies": [["Matthew", "Garrett"], ["Megan", "Glick"], ["Laura", "Grappo"], ["Patricia", "Hill"], ["Indira", "Karamcheti"], ["J. Kehaulani", "Kauanui"], ["Elizabeth", "McAlister"], ["Joel", "Pfister"], ["Amy", "Tang"], ["Margot", "Weiss"]], "College of Social Studies": [["Carla", "Abdo-Katsipis"], ["Richard", "Adelstein"], ["John", "Bonin"], ["Sonali", "Chakravarti"], ["Douglas", "Foyle"], ["Giulio", "Gallarotti"], ["Erik", "Grimmer-Solem"], ["Kerwin", "Kaye"], ["Ioana Emy", "Matesan"], ["Cecilia", "Miller"], ["J. Donald", "Moon"], ["Wendy", "Rayack"], ["Peter", "Rutland"], ["Damien", "Sheehan-Connor"], ["Gilbert", "Skillman"], ["Victoria", "Smolkin"], ["Sarah", "Wiliarty"]], "Physical Education": [["John", "Biddiscombe"], ["Drew", "Black"], ["Philip", "Carney"], ["John", "Crooke"], ["Walter Jr.", "Curry"], ["Daniel", "DiCenzo"], ["Michael", "Fried"], ["Albert", "Jackson"], ["Shona", "Kerr"], ["Patricia", "Klecha-Porter"], ["Gale", "Lackey"], ["Jennifer", "Lane"], ["Donald", "Long"], ["Jodi", "McKenna"], ["Eva", "Meredith"], ["Kate", "Mullen"], ["Christopher", "Potter"], ["John", "Raba"], ["Joseph", "Reilly"], ["Donald", "Russell"], ["David", "Snyder"], ["Peter", "Solomon"], ["Ben", "Somera"], ["Patrick", "Tynan"], ["Michael", "Whalen"], ["Geoffrey", "Wheeler"], ["Kim", "Williams"], ["Jon", "Wilson"], ["Mark", "Woodworth"]], "Allbritton Center for the Study of Public Life": [["Peggy", "Carey Best"], ["Robert", "Cassidy"], ["Daniel", "Drew"], ["Jane", "Eisner"], ["Leslie", "Gabel-Brett"], ["Preston", "Green"], ["Lily", "Herman"], ["Barbara", "Juhasz"], ["Makaela", "Kingsley"], ["Laura", "McCargar"], ["Peter", "Rutland"], ["Michael", "Schlabs"], ["Clifton", "Watson"]], "Romance Languages and Literatures": [["Stéphanie", "Ponsavady"], ["Francesco Marco", "Aresu"], ["Michael", "Armstrong Roche"], ["Robert", "Conn"], ["Andrew", "Curran"], ["Peter", "Dunn"], ["Octavio", "Flores-Cuadra"], ["Bernardo", "Gonzalez"], ["Elizabeth", "Jackson"], ["Typhaine", "Leservot"], ["Joyce", "Lowrie"], ["Michael", "Meere"], ["Giovanni", "Miglianti"], ["Louise", "Neary"], ["Ellen", "Nerenberg"], ["Maria", "Ospina"], ["Catherine", "Ostrow"], ["Paula", "Paige"], ["Paula", "Park"], ["Ana", "Perez-Girones"], ["Catherine", "Poisson"], ["Jeff", "Rider"], ["Olga", "Sendra Ferrer"], ["Norman", "Shapiro"], ["Matthew", "Treme"], ["Meg Furniss", "Weisberg"], ["Camilla", "Zamboni"]], "Office for Equity and Inclusion": [["Gloster", "Aaron"]], "Sociology": [["Robyn", "Autry"], ["Abigail", "Boggs"], ["Peggy", "Carey Best"], ["Mary Ann", "Clawson"], ["Jonathan", "Cutler"], ["Alex", "Dupuy"], ["Sue", "Fisher"], ["Greg", "Goldberg"], ["Anthony", "Hatch"], ["Mario", "Hernandez"], ["Kerwin", "Kaye"], ["Basak", "Kus"], ["Courtney", "Patterson-Faye"], ["Victoria", "Pitts-Taylor"], ["Rob", "Rosenthal"]], "Physics": [["Lutz", "Hüwel"], ["Blümel", "Reinhold"], ["Ralph", "Baierlein"], ["Fred", "Ellis"], ["Candice", "Etson"], ["Tsampikos", "Kottos"], ["Richard", "Lindquist"], ["Thomas", "Morgan"], ["George", "Paily"], ["Alba", "Ramos"], ["Robert", "Rollefson"], ["Meng-ju", "Sher"], ["Francis", "Starr"], ["Brian", "Stewart"], ["William", "Trousdale"], ["Min-Feng", "Tu"], ["Greg", "Voth"]], "African American Studies": [["Katherine", "Brewer Ball"], ["Lois", "Brown"], ["Rachel", "Ellis Neyra"], ["Anthony", "Hatch"], ["Casey", "Hayman"], ["Jay", "Hoggard"], ["Khalil", "Johnson"], ["Renee", "Johnson Thornton"], ["Axelle", "Karera"], ["Elizabeth", "McAlister"], ["Rashida", "McMahon"], ["Jesse", "Nasta"], ["Gayle", "Pemberton"], ["Ashraf", "Rushdy"], ["Chriss", "Sneed"], ["Tyshawn", "Sorey"], ["Nicole", "Stanton"], ["H. Shellae", "Versey"], ["Tiphanie", "Yanique"]], "German Studies": [["Khachig", "Tölölyan"], ["Annemarie", "Arnold"], ["Herbert", "Arnold"], ["Ulrich", "Bach"], ["Martin", "Baeumel"], ["Iris", "Bork-Goldfield"], ["Vera", "Grant"], ["Erik", "Grimmer-Solem"], ["Katherine", "Kuenzli"], ["Leo", "Lensing"], ["Ulrich", "Plass"], ["Arthur", "Wensinger"], ["Sarah", "Wiliarty"], ["Krishna", "Winston"]], "Government": [["Joslyn", "Barnhart Trager"], ["Richard", "Boyd"], ["Louise", "Brown"], ["Robert", "Cassidy"], ["Sonali", "Chakravarti"], ["Joan", "Cho"], ["Barbara", "Craig"], ["Martha", "Crenshaw"], ["Logan", "Dancey"], ["Marc", "Eisner"], ["John", "Finn"], ["Douglas", "Foyle"], ["Erika", "Franklin Fowler"], ["Giulio", "Gallarotti"], ["Mary Alice", "Haddad"], ["Benjamin", "Krupicka"], ["Ioana Emy", "Matesan"], ["James", "McGuire"], ["J. Donald", "Moon"], ["Russell", "Murphy"], ["Justin", "Peck"], ["Peter", "Rutland"], ["Nancy", "Schwartz"], ["Kelly", "Senters"], ["Yamil", "Velez"], ["Sarah", "Wiliarty"]], "College of the Environment": [["Marcela", "Oteíza"], ["Barry", "Chernoff"], ["Anthony", "Hatch"], ["Antonio", "Machado-Allison"], ["Allison", "Orr"], ["Rosemary", "Ostfeld"], ["Helen", "Poulos"], ["Justine", "Quijada"], ["Meng-ju", "Sher"], ["Kari", "Weil"]], "Chemistry": [["Suara", "Adediran"], ["David", "Beveridge"], ["Philip", "Bolton"], ["Joseph", "Bruno"], ["Rene", "Buell"], ["Michael", "Calter"], ["Stephen", "Cooke"], ["Anthony", "Davis"], ["Candice", "Etson"], ["Michael", "Frisch"], ["Albert", "Fry"], ["Carlos", "Jimenez Hoyos"], ["Joseph", "Knee"], ["Jason", "Lam"], ["David", "Langley"], ["Rachel", "Lowe"], ["Melisa", "Moreno Garcia"], ["Brian", "Northrop"], ["Stewart", "Novick"], ["Alison", "O\"Neil"], ["Michelle", "Personick"], ["George", "Petersson"], ["Rex", "Pratt"], ["Wallace", "Pringle"], ["Andrea", "Roberts"], ["Irina", "Russu"], ["Colin", "Smith"], ["Erika", "Taylor"], ["T. David", "Westmoreland"]], "Archaeology": [["Kate", "Birney"], ["Douglas", "Charles"], ["Pinar", "Durgun"], ["Christopher", "Parslow"], ["Phillip", "Wagoner"]], "College of Letters": [["Khachig", "Tölölyan"], ["Charles", "Barber"], ["Joseph", "Fitzpatrick"], ["Tushar", "Irani"], ["Gabriela", "Jarzebowska"], ["Ethan", "Kleinberg"], ["Typhaine", "Leservot"], ["Howard", "Needler"], ["Laurie", "Nussdorfer"], ["Ulrich", "Plass"], ["Gabrielle", "Ponce-Hegenauer"], ["Paul", "Schwaber"], ["Daniel", "Smyth"], ["Jesse", "Torgerson"], ["Kari", "Weil"]], "Classical Studies": [["Abderrahman", "Aissa"], ["Kate", "Birney"], ["Elizabeth", "Bobrick"], ["Marilyn", "Katz"], ["Christopher", "Parslow"], ["Michael", "Roberts"], ["Andrew", "Szegedy-Maszak"], ["Eirene", "Visvardi"], ["Serena", "Witzke"]], "Center for Pedagogical Innovation": [["Barbara", "Adams"], ["Amy", "Grillo"], ["Jennifer", "Rose"]], "Environmental Studies": [["Barry", "Chernoff"], ["Frederick", "Cohan"], ["Marc", "Eisner"], ["Paul", "Erickson"], ["Courtney", "Fullilove"], ["Giulio", "Gallarotti"], ["Mary Alice", "Haddad"], ["Anthony", "Hatch"], ["Elijah", "Huge"], ["William", "Johnston"], ["Katja", "Kolcio"], ["Daniel", "Krizanc"], ["J. Donald", "Moon"], ["Ishita", "Mukerji"], ["Marguerite", "Nguyen"], ["Earl", "Phillips"], ["William", "Pinch"], ["Joseph", "Rouse"], ["Dana", "Royer"], ["Michael", "Singer"], ["Nicole", "Stanton"], ["Brian", "Stewart"], ["Sonia", "Sultan"], ["Andrew", "Szegedy-Maszak"], ["Erika", "Taylor"], ["Tula", "Telfair"], ["Jennifer", "Tucker"], ["Johan", "Varekamp"], ["H. Shellae", "Versey"], ["Kari", "Weil"], ["Krishna", "Winston"], ["Gary", "Yohe"]], "Biology": [["Laverne", "Melón"], ["Gloster", "Aaron"], ["Allan", "Berlind"], ["David", "Bodznick"], ["Ann", "Burke"], ["Barry", "Chernoff"], ["Frederick", "Cohan"], ["Joseph", "Coolon"], ["Stephen", "Devoto"], ["J.", "Donady"], ["Laura", "Grabel"], ["Ruth", "Johnson"], ["John", "Kirn"], ["James", "Mulrooney"], ["Janice", "Naegele"], ["Joyce", "Powzyk"], ["Michael", "Singer"], ["Sonia", "Sultan"], ["Michael", "Weir"]], "College of East Asian Studies": [["Scott", "Aalgaard"], ["Talia", "Andrei"], ["Stephen", "Angle"], ["Hyejoo", "Back"], ["Joan", "Cho"], ["Lisa", "Dombrowski"], ["Patrick", "Dowdey"], ["Mary Alice", "Haddad"], ["Miyuki", "Hatano-Cohen"], ["Yu-ting", "Huang"], ["Masami", "Imai"], ["William", "Johnston"], ["Yunjeong", "Lee"], ["Lingjing", "Li"], ["Mengjun", "Liu"], ["Naho", "Maruta"], ["Marguerite", "Nguyen"], ["Andrew", "Quintman"], ["Yoshiko", "Samuel"], ["Keiji", "Shinohara"], ["Ying Jia", "Tan"], ["Ao", "Wang"], ["Takeshi", "Watanabe"], ["Ellen", "Widmer"], ["Su", "Zheng"], ["Xiaomiao", "Zhu"]], "Dance": [["Pedro", "Alejandro"], ["Patricia", "Beaman"], ["Aly", "Camara"], ["Katja", "Kolcio"], ["Hari", "Krishnan"], ["Susan", "Lourie"], ["Urip", "Maeny"], ["Chelsie", "McPhilimy"], ["Julie", "Mulvihill"], ["Eiko", "Otake"], ["Joya", "Powell"], ["Iddrisu", "Saaka"], ["Pamardi", "Silvester"], ["Nicole", "Stanton"]], "College of Film and the Moving Image": [["Jeanine", "Basinger"], ["Conor", "Byrne"], ["Joe", "Cacaci"], ["Stephen", "Collins"], ["Janeann", "Dill"], ["Lisa", "Dombrowski"], ["Scott", "Higgins"], ["David", "Laub"], ["Leo", "Lensing"], ["Marc", "Longenecker"], ["Ben", "Model"], ["Richard", "Parkin"], ["Swapnil", "Rai"], ["Mirko", "Rucnov"], ["Anthony", "Scott"], ["Michael", "Slowik"]], "Center for Jewish Studies": [["Amir", "Bogen"], ["Dalit", "Katz"]], "Center for the Arts": [["Paul", "Bonin-Rodriguez"], ["Judy", "Hussie-Taylor"], ["Joshua", "Lubin-Levy"], ["Noemie", "Solomon"]], "Science in Society": [["Paul", "Erickson"], ["Courtney", "Fullilove"], ["Megan", "Glick"], ["Peter", "Gottschalk"], ["Lori", "Gruen"], ["Anthony", "Hatch"], ["Steven", "Horst"], ["William", "Johnston"], ["Jill", "Morawski"], ["Victoria", "Pitts-Taylor"], ["Joseph", "Rouse"], ["Mary-Jane", "Rubenstein"], ["Courtney Weiss", "Smith"], ["Mitali", "Thakor"], ["Jennifer", "Tucker"]], "Economics": [["Richard", "Adelstein"], ["Ayesha", "Ali"], ["Mahama", "Bandaogo"], ["John", "Bonin"], ["Karl", "Boulware"], ["Gillian", "Brunet"], ["Martin", "Gosman"], ["Richard", "Grossman"], ["Christiaan", "Hogendorn"], ["Abigail", "Hornstein"], ["Masami", "Imai"], ["Joyce", "Jacobsen"], ["Anthony", "Keats"], ["Melanie", "Khamis"], ["David", "Kuenzel"], ["Michael", "Lorenzo"], ["Richard", "Miller"], ["Jeffrey", "Naecker"], ["Wendy", "Rayack"], ["Damien", "Sheehan-Connor"], ["Gilbert", "Skillman"], ["Peter", "Wang"], ["Gary", "Yohe"], ["Xiaoxue", "Zhao"]], "Philosophy": [["Elan", "Abrell"], ["Stephen", "Angle"], ["L.", "Bendall"], ["Brian", "Fay"], ["Victor", "Gourevitch"], ["Lori", "Gruen"], ["Steven", "Horst"], ["Tushar", "Irani"], ["Sharisse", "Kanet"], ["Axelle", "Karera"], ["Joseph", "Rouse"], ["Sanford", "Shieh"], ["Daniel", "Smyth"], ["Elise", "Springer"]], "Medieval Studies": [["Jane", "Alden"], ["Francesco Marco", "Aresu"], ["Michael", "Armstrong Roche"], ["Melissa", "Katz"], ["Michael", "Meere"], ["Cecilia", "Miller"], ["Ruth", "Nisse"], ["Jeff", "Rider"], ["Gary", "Shaw"], ["Jesse", "Torgerson"]], "Psychology": [["David", "Adams"], ["Hilary", "Barth"], ["Nathan", "Brody"], ["Sarah", "Carney"], ["Kee-Hong", "Choi"], ["Lisa", "Dierker"], ["Barbara", "Juhasz"], ["Eun Ju", "Jung"], ["Sarah", "Kamens"], ["Kyungmi", "Kim"], ["Matthew", "Kurtz"], ["Marcus", "Leppanen"], ["Psyche", "Loui"], ["Cynthia", "Matthew"], ["Alexis", "May"], ["Jill", "Morawski"], ["Andrea", "Patalano"], ["Scott", "Plous"], ["Mike", "Robinson"], ["Patricia", "Rodriguez Mosquera"], ["Charles", "Sanislow"], ["Karl", "Scheibe"], ["John", "Seamon"], ["Anna", "Shusterman"], ["Harry", "Sinnamon"], ["Robert", "Steele"], ["Steven", "Stemler"], ["Royette", "Tavernier"], ["H. Shellae", "Versey"], ["Ruth", "Weissman"], ["Clara", "Wilkins"], ["Chenmu", "Xing"], ["Alexandra", "Zax"]], "Feminist, Gender, and Sexuality Studies": [["Abigail", "Boggs"], ["Lois", "Brown"], ["Lisa", "Cohen"], ["Christina", "Crosby"], ["Laura", "Grappo"], ["Lori", "Gruen"], ["Kerwin", "Kaye"], ["Natasha", "Korda"], ["Hari", "Krishnan"], ["Elizabeth", "McAlister"], ["Jill", "Morawski"], ["Victoria", "Pitts-Taylor"], ["Catherine", "Poisson"], ["Patricia", "Rodriguez Mosquera"], ["Mary-Jane", "Rubenstein"], ["Ashraf", "Rushdy"], ["Claire", "Schwartz"], ["Anu (Aradhana)", "Sharma"], ["Elise", "Springer"], ["Elizabeth", "Traube"], ["Jennifer", "Tucker"], ["Laura Ann", "Twagira"], ["Gina Athena", "Ulysse"], ["Roman", "Utkin"], ["Margot", "Weiss"], ["Sarah", "Wiliarty"], ["Talya", "Zemach-Bersin"], ["Su", "Zheng"]], "Art and Art History": [["Nadja", "Aksamija"], ["Talia", "Andrei"], ["Jonathan", "Best"], ["Kate", "Birney"], ["Jennifer", "Calivas"], ["Christopher", "Chenier"], ["Claire", "Grace"], ["Elijah", "Huge"], ["Melissa", "Katz"], ["Scott", "Kessel"], ["Katherine", "Kuenzli"], ["Emily", "Larned"], ["Clark", "Maines"], ["Peter", "Mark"], ["Elizabeth", "Milroy"], ["Alexander", "Osborn"], ["John", "Paoletti"], ["Christopher", "Parslow"], ["Julia", "Randall"], ["Sasha", "Rudensky"], ["Jeffrey", "Schiff"], ["Keiji", "Shinohara"], ["Joseph", "Siry"], ["Tula", "Telfair"], ["Kate", "TenEyck"], ["Phillip", "Wagoner"]], "English": [["Khachig", "Tölölyan"], ["Henry", "Abelove"], ["Sally", "Bachner"], ["Marina", "Bilbija"], ["Amy", "Bloom"], ["Lois", "Brown"], ["Lisa", "Cohen"], ["William", "Coley"], ["John", "Connor"], ["Christina", "Crosby"], ["Morgan", "Day Frank"], ["Ann", "duCille"], ["Rachel", "Ellis Neyra"], ["Harris", "Friedberg"], ["Matthew", "Garrett"], ["Anne", "Greene"], ["Alice", "Hadler"], ["Sherman", "Hawkins"], ["Elizabeth", "Hepford"], ["Gertrude", "Hughes"], ["Jason", "Katzenstein"], ["Natasha", "Korda"], ["Douglas", "Martin"], ["Sean", "McCann"], ["Rashida", "McMahon"], ["John", "Murillo"], ["Marguerite", "Nguyen"], ["Ruth", "Nisse"], ["Richard", "Ohmann"], ["Gayle", "Pemberton"], ["Joel", "Pfister"], ["Joseph", "Reed"], ["Phyllis", "Rose"], ["Ashraf", "Rushdy"], ["Lily", "Saint"], ["Hirsh", "Sawhney"], ["Lauren", "Silber"], ["Richard", "Slotkin"], ["Courtney Weiss", "Smith"], ["William", "Stowe"], ["Amy", "Tang"], ["Alfred", "Turco"], ["Danielle", "Vogel"], ["Stephanie", "Weiner"], ["Tiphanie", "Yanique"]], "Astronomy": [["William", "Herbst"], ["Meredith", "Hughes"], ["Roy", "Kilgard"], ["Edward", "Moran"], ["Seth", "Redfield"]], "Earth and Environmental Sciences": [["Barry", "Chernoff"], ["Kim", "Diver"], ["Martha", "Gilmore"], ["James", "Greenwood"], ["James", "Gutmann"], ["Nick", "Hastings"], ["Timothy", "Ku"], ["Peter", "LeTourneau"], ["Suzanne", "O\"Connell"], ["Peter", "Patton"], ["Phillip", "Resor"], ["Dana", "Royer"], ["Ellen", "Thomas"], ["Johan", "Varekamp"]], "Music": [["Abraham", "Adzenyah"], ["Jane", "Alden"], ["Noah", "Baerman"], ["B.", "Balasubrahmaniyan"], ["John", "Biatowas"], ["Anthony", "Braxton"], ["Neely", "Bruce"], ["Eric", "Charry"], ["Andrew", "Chung"], ["John", "Dankwa"], ["Ronald", "Ebrecht"], ["Kate", "Galloway"], ["Roger Mathew", "Grant"], ["I.", "Harjito"], ["Jay", "Hoggard"], ["Simba", "Kamuriwo"], ["Jin Hi", "Kim"], ["Ronald", "Kuivila"], ["Salvatore", "LaRusso"], ["Chia-Yu Joy", "Lu"], ["Alvin", "Lucier"], ["Paula", "Matthusen"], ["Barbara", "Merjan"], ["Marichal", "Monts"], ["David", "Nelson"], ["Nadya", "Potemkina"], ["Pamardi", "Silvester"], ["Mark", "Slobin"], ["Tyshawn", "Sorey"], ["Melvin", "Strauss"], ["Prof.", "Sumarsam"], ["Su", "Zheng"]], "History": [["Valeria", "López Fadul"], ["Judith", "Brown"], ["Richard", "Buel"], ["Richard", "Elphick"], ["Paul", "Erickson"], ["Demetrius", "Eudell"], ["Courtney", "Fullilove"], ["C. Stewart", "Gillmor"], ["Nathanael", "Greene"], ["Erik", "Grimmer-Solem"], ["Charles", "Halvorson"], ["Oliver", "Holmes"], ["William", "Johnston"], ["Ethan", "Kleinberg"], ["Jeffers", "Lennox"], ["Bruce", "Masters"], ["Cecilia", "Miller"], ["David", "Morgan"], ["Laurie", "Nussdorfer"], ["William", "Pinch"], ["Philip", "Pomper"], ["Ronald", "Schatz"], ["Vera", "Schwarcz"], ["Gary", "Shaw"], ["Victoria", "Smolkin"], ["Ying Jia", "Tan"], ["Jesse", "Torgerson"], ["Jennifer", "Tucker"], ["Laura Ann", "Twagira"], ["Richard", "Vann"], ["Ann", "Wightman"]], "Shapiro Writing Center": [["Steven", "Almond"], ["Rachael", "Barlow"], ["Douglas", "Bauer"], ["Tess", "Bird"], ["Amy", "Bloom"], ["Amity", "Gaige"], ["Anne", "Greene"], ["Elizabeth", "Hepford"], ["Jason", "Katzenstein"], ["Ariel", "Levy"], ["Douglas", "Martin"], ["Sean", "McCann"], ["Gregory", "Pardlo"], ["Said", "Sayrafiezadeh"], ["Salvatore", "Scibona"], ["Lauren", "Silber"], ["Brando", "Skyhorse"], ["Lisa", "Weinert"]], "College of Integrative Sciences": [["Gloster", "Aaron"], ["David", "Beveridge"], ["Michael", "Calter"], ["Christopher", "Chenier"], ["Frederick", "Cohan"], ["Karen L.", "Collins"], ["John", "Cooley"], ["Joseph", "Coolon"], ["Candice", "Etson"], ["William", "Herbst"], ["Cameron", "Hill"], ["Manju", "Hingorani"], ["Scott", "Holmes"], ["Mark", "Hovey"], ["Meredith", "Hughes"], ["Ruth", "Johnson"], ["Barbara", "Juhasz"], ["Roy", "Kilgard"], ["Tsampikos", "Kottos"], ["Daniel", "Krizanc"], ["Timothy", "Ku"], ["Robert", "Lane"], ["James", "Lipton"], ["Psyche", "Loui"], ["Amy", "MacQueen"], ["Michael", "McAlear"], ["Daniel", "Moller"], ["Edward", "Moran"], ["Ishita", "Mukerji"], ["Brian", "Northrop"], ["Stewart", "Novick"], ["Alison", "O\"Neil"], ["Donald", "Oliver"], ["Rich", "Olson"], ["Michelle", "Personick"], ["Seth", "Redfield"], ["Mike", "Robinson"], ["Irina", "Russu"], ["Meng-ju", "Sher"], ["Colin", "Smith"], ["Francis", "Starr"], ["Brian", "Stewart"], ["Erika", "Taylor"], ["Ellen", "Thomas"], ["Greg", "Voth"], ["Christopher", "Weaver"], ["Michael", "Weir"], ["T. David", "Westmoreland"]], "Theater": [["Marcela", "Oteíza"], ["Calvin", "Anderson"], ["Katherine", "Brewer Ball"], ["John", "Carr"], ["Kathleen", "Conlin"], ["William", "Francisco"], ["Tony", "Hernandez"], ["Quiara", "Hudes"], ["Summer", "Jack"], ["Ronald", "Jenkins"], ["Christian", "Milik"], ["Tira", "Palmquist"], ["Edwin", "Sanchez"], ["Gay", "Smith"], ["Corey", "Sorenson"], ["Edward", "Torres"], ["Leslie", "Weinberg"]], "Latin American Studies": [["Valeria", "López Fadul"], ["Michael", "Armstrong Roche"], ["Eric", "Charry"], ["Robert", "Conn"], ["Melanie", "Khamis"], ["James", "McGuire"], ["Maria", "Ospina"], ["Paula", "Park"], ["Johan", "Varekamp"]], "Mathematics and Computer Science": [["Felipe", "Ramírez"], ["Ilesanmi", "Adeboye"], ["Daniel", "Alvey"], ["Justin", "Bryant"], ["Wai Kiu", "Chan"], ["Karen L.", "Collins"], ["David", "Constantine"], ["Ethan", "Coven"], ["Norman", "Danner"], ["Adam", "Fieldsteel"], ["Anthony", "Hager"], ["Alyson", "Hildum"], ["Cameron", "Hill"], ["Mark", "Hovey"], ["Sara", "Kalisnik Verovsek"], ["Alex", "Kavvos"], ["Michael", "Keane"], ["Tsampikos", "Kottos"], ["Daniel", "Krizanc"], ["Constance", "Leidy"], ["Han", "Li"], ["Dan", "Licata"], ["James", "Lipton"], ["Victoria", "Manfredi"], ["Peter", "Merkx"], ["David", "Pollack"], ["Christopher", "Rasmussen"], ["Michael", "Rice"], ["Mitchell", "Riley"], ["Philip", "Scowcroft"], ["Saray", "Shai"], ["Kelly", "Thayer"], ["Phillip", "Wesolek"], ["Carol", "Wood"], ["Sebastian", "Zimmeck"]], "Anthropology": [["Ákos", "Östör"], ["Douglas", "Charles"], ["Daniella", "Gandolfo"], ["J. Kehaulani", "Kauanui"], ["R. Lincoln", "Keiser"], ["Anu (Aradhana)", "Sharma"], ["Elizabeth", "Traube"], ["Gina Athena", "Ulysse"], ["Joseph", "Weiss"], ["Margot", "Weiss"]], "Neuroscience and Behavior": [["Gloster", "Aaron"], ["Nihal", "de Lanerolle"], ["Stephen", "Devoto"], ["Barbara", "Juhasz"], ["John", "Kirn"], ["Matthew", "Kurtz"], ["Psyche", "Loui"], ["Janice", "Naegele"], ["Alison", "O\"Neil"], ["Andrea", "Patalano"], ["Mike", "Robinson"], ["Charles", "Sanislow"], ["Helen", "Treloar"]], "Russian, East European, and Eurasian Studies": [["Irina", "Aleshkovsky"], ["John", "Bonin"], ["Joseph", "Fitzpatrick"], ["Susanne", "Fusso"], ["Katja", "Kolcio"], ["Priscilla", "Meyer"], ["Nadya", "Potemkina"], ["Justine", "Quijada"], ["Sasha", "Rudensky"], ["Peter", "Rutland"], ["Victoria", "Smolkin"], ["Roman", "Utkin"], ["Duffield", "White"]], "Center for the Americas": [["Kasey", "Jernigan"], ["J. Kehaulani", "Kauanui"], ["Andrew", "Walker"]], "Molecular Biology and Biochemistry": [["Cori", "Anderson"], ["Candice", "Etson"], ["Manju", "Hingorani"], ["Scott", "Holmes"], ["Anthony", "Infante"], ["Robert", "Lane"], ["Amy", "MacQueen"], ["Michael", "McAlear"], ["Ishita", "Mukerji"], ["Michelle", "Murolo"], ["Donald", "Oliver"], ["Rich", "Olson"], ["Colin", "Smith"]], "Religion": [["Ron", "Cameron"], ["Yaniv", "Feller"], ["Peter", "Gottschalk"], ["Dalit", "Katz"], ["Jerome", "Long"], ["Elizabeth", "McAlister"], ["Justine", "Quijada"], ["Andrew", "Quintman"], ["Mary-Jane", "Rubenstein"], ["Lewis", "West"], ["Janice", "Willis"], ["Jeremy", "Zwelling"]]]
    }
    
    func getProfList() -> [[String]] {
        var lst =  [["Esty", "Kaisha"], ["Nasta", "Jesse"], ["Johnson", "Khalil Anthony"], ["McMahon", "Rashida Z. Shaw"], ["Bilbija", "Marina"], ["Monts", "Marichal B"], ["Barlow", "Rachael"], ["Powell", "Joya"], ["McAlister", "Elizabeth"], ["Tang", "Amy Cynthia"], ["Rushdy", "Ashraf H.A."], ["Vermeulen", "Heather"], ["Hoggard", "Jay Clinton"], ["Sorey", "Tyshawn"], ["Scott", "Briele"], ["Glick", "Megan H."], ["Karamcheti", "Indira"], ["Grappo", "Laura"], ["Day Frank", "Morgan"], ["Pfister", "Joel"], ["Grace", "Claire"], ["Morawski", "Jill G."], ["Nguyen", "Marguerite"], ["Schatz", "Ronald W."], ["Boggs", "Abigail Huston"], ["Rayack", "Wendy"], ["Traube", "Elizabeth G."], ["Weiss", "Margot"], ["Vrevich", "Kevin"], ["Gandolfo", "Daniella"], ["El Zein", "Rayya"], ["Weiss", "Joseph"], ["Thakor", "Mitali"], ["Sharma", "Anu (Aradhana)"], ["Ulysse", "Gina Athena"], ["Aissa", "Abderrahman"], ["Birney", "Kate"], ["Kuenzli", "Katherine M."], ["Wagoner", "Phillip B."], ["Ackley", "Joseph Salvatore"], ["Aksamija", "Nadja"], ["Siry", "Joseph M."], ["Andrei", "Talia Johanna"], ["Randall", "Julia A."], ["TenEyck", "Kate"], ["Telfair", "Tula"], ["Chenier", "Christopher James"], ["Huge", "Elijah"], ["Osborn", "Alexander Cooke"], ["Schiff", "Jeffrey"], ["Bowman", "Dannielle"], ["Shinohara", "Keiji"], ["Hulsey", "John"], ["Chaffee", "Benjamin"], ["Redfield", "Seth"], ["Herbst", "William"], ["Hughes", "Meredith"], ["Moran", "Edward C."], ["Gilmore", "Martha S."], ["Powzyk", "Joyce Ann"], ["Murolo", "Michelle Aaron"], ["Coolon", "Joseph David"], ["Johnson", "Ruth Ineke"], ["McAlear", "Michael A."], ["Anderson", "Cori"], ["Poulos", "Helen Mills"], ["Holmes", "Scott G."], ["Naegele", "Janice R."], ["Devoto", "Stephen H."], ["Singer", "Michael"], ["Oliver", "Donald B."], ["Burke", "Ann Campbell"], ["de Lanerolle", "Nihal C."], ["Mulrooney", "James Paul"], ["Aaron", "Gloster B."], ["Treloar", "Helen B."], ["Weir", "Michael P."], ["Melón", "Laverne"], ["Visvardi", "Eirene"], ["Hansen", "Hans"], ["Witzke", "Serena S."], ["Szegedy-Maszak", "Andrew"], ["Tölölyan", "Khachig"], ["Bernard", "Allison"], ["Huang", "Yu-ting"], ["Park", "Hyun Hee"], ["Imai", "Masami"], ["Foust", "Mathew"], ["Angle", "Stephen"], ["Zheng", "Su"], ["Tan", "Ying Jia"], ["Aalgaard", "Scott W."], ["Haddad", "Mary Alice"], ["Zhao", "Xiaoxue"], ["Kim", "Jin Hi"], ["Merjan", "Barbara"], ["Lu", "Chia-Yu Joy"], ["Zhu", "Xiaomiao"], ["Liu", "Mengjun"], ["Hatano-Cohen", "Miyuki"], ["Maruta", "Naho"], ["Back", "Hyejoo"], ["Lee", "Yunjeong"], ["Hadler", "Alice Berliner"], ["Smyth", "Daniel"], ["Davis", "Anthony P."], ["Smith", "Colin A."], ["Jimenez Hoyos", "Carlos Alberto"], ["Roberts", "Andrea"], ["Northrop", "Brian Hale"], ["Gupta", "Anisha"], ["Olson", "Rich"], ["O'Neil", "Alison L."], ["Novick", "Stewart E."], ["Calter", "Michael A."], ["Taylor", "Erika A."], ["Russu", "Irina M."], ["Mukerji", "Ishita"], ["Knee", "Joseph L."], ["Roth", "Michael S."], ["Korda", "Natasha"], ["Fics", "Ryan"], ["Tucker", "Jennifer"], ["Garrett", "Matthew Carl"], ["Teva", "David Leipziger"], ["Moller", "Daniel"], ["Thayer", "Kelly Marie"], ["Oleinikov", "Pavel V"], ["Nazzaro", "Valerie L."], ["Weise", "Matthew"], ["Krizanc", "Daniel"], ["Shai", "Saray"], ["Diver", "Kim"], ["Hildum", "Alyson"], ["Bishop", "Cameron"], ["Hill", "Cameron Donnay"], ["Fieldsteel", "Adam"], ["Rasmussen", "Christopher"], ["Kalisnik Verovsek", "Sara"], ["Chan", "Wai Kiu"], ["Li", "Han"], ["Ellis", "Fred M."], ["Juhasz", "Barbara Jean"], ["Dierker", "Lisa C."], ["Kurtz", "Matthew M."], ["Anderson", "Beth"], ["Patalano", "Andrea L."], ["Kaparakis", "Emmanuel I."], ["Ouyang", "Ning"], ["Feller", "Yaniv"], ["Katz", "Dalit"], ["Fitzpatrick", "Joseph J."], ["Barber", "Charles"], ["Torgerson", "Jesse Wayne"], ["Armstrong Roche", "Michael"], ["Kleinberg", "Ethan"], ["Weil", "Kari"], ["Zimmeck", "Sebastian"], ["Lipton", "James"], ["Wolfe", "Pippin"], ["Ryan", "Sarah"], ["Cassidy", "Robert"], ["Gosman", "Martin"], ["Ostfeld", "Rosemary Elizabeth"], ["Busemeyer", "Stephen"], ["Daley", "David"], ["Greene", "Anne F."], ["Kingsley", "Makaela Jane"], ["Abdo-Katsipis", "Carla"], ["Watson", "Clifton Nathaniel"], ["Cavallaro", "Jim"], ["Rosewarne", "Lauren"], ["Rutland", "Peter"], ["Hovey", "Mark A."], ["Matesan", "Ioana Emy"], ["Wurgaft", "Benjamin"], ["Chakravarti", "Sonali"], ["Adelstein", "Richard P."], ["Krishnan", "Hari"], ["McPhilimy", "Chelsie"], ["Saaka", "Iddrisu"], ["Alejandro", "Pedro"], ["Stanton", "Nicole Lynn"], ["Kolcio", "Katja P."], ["Beaman", "Patricia L."], ["Anderson", "Calvin O'Malley"], ["Greenwood", "James P."], ["Wintsch", "Robert"], ["Resor", "Phillip G."], ["Royer", "Dana"], ["Chernoff", "Barry"], ["O'Connell", "Suzanne B."], ["Ku", "Timothy C.W."], ["Sheehan-Connor", "Damien Francis"], ["Raynor", "Jennifer"], ["McInerney", "Mark"], ["Boulware", "Karl David"], ["Izumi", "Ryuichiro"], ["Brunet", "Gillian"], ["Hornstein", "Abigail S."], ["Hogendorn", "Christiaan"], ["Khamis", "Melanie"], ["Grossman", "Richard S."], ["Keats", "Anthony Bruno"], ["Kuenzel", "David Julian"], ["Silber", "Lauren"], ["Hepford", "Elizabeth Ann"], ["Grillo", "Amy"], ["Ellis Neyra", "Ren"], ["Weiner", "Stephanie Kuduk"], ["McCann", "Sean"], ["Friedberg", "Harris A."], ["Nisse", "Ruth"], ["Pitts-Taylor", "Victoria"], ["Murillo", "John"], ["Bachner", "Sally"], ["Sanchez", "Edwin"], ["Brewer Ball", "Katherine"], ["Vogel", "Danielle"], ["Antoni", "Robert"], ["Roberson", "Blythe"], ["Cohen", "Lisa"], ["Martin", "Douglas Arthur"], ["Eisner", "Marc A."], ["Erickson", "Paul Hilding"], ["Abrell", "Elan Louis"], ["Winston", "Krishna R."], ["Twagira", "Laura Ann"], ["Good", "Justin Peter"], ["Dolan", "Lindsay R"], ["Rouse", "Joseph T."], ["Kaye", "Kerwin"], ["Memran", "Michelle"], ["Helverson", "Sophia"], ["Rubenstein", "Mary-Jane Victoria"], ["Wiliarty", "Sarah E."], ["Crosby", "Christina"], ["Shepard", "Sadia Dana"], ["Higgins", "Scott"], ["Longenecker", "Marc Robert"], ["Dombrowski", "Lisa A."], ["Lensing", "Leo A."], ["Strain", "Tracy Heather"], ["Rucnov", "Mirko"], ["Collins", "Stephen Edward"], ["Parkin", "Richard"], ["Lock", "Tom"], ["MacLowry", "Randall M."], ["Cacaci", "Joe"], ["Ostrow", "Catherine R."], ["Gates", "Caroline"], ["Paris-Bouvret", "Emmanuel"], ["Rider", "Jeff"], ["Leservot", "Typhaine"], ["Ponsavady", "Stéphanie"], ["Poisson", "Catherine"], ["Curran", "Andrew S."], ["Peck", "Justin Craig"], ["Mark", "Alyx"], ["Dudas", "Mary"], ["Gallarotti", "Giulio"], ["Barnhart Trager", "Joslyn"], ["McGuire", "James W."], ["Hagel", "Nina"], ["Foyle", "Douglas C."], ["Moon", "J. Donald"], ["Franklin Fowler", "Erika"], ["Bork-Goldfield", "Iris"], ["Plass", "Ulrich"], ["Baeumel", "Martin"], ["Holmes", "Oliver W."], ["Pinch", "William R."], ["Smolkin", "Victoria"], ["Masters", "Bruce A."], ["Eudell", "Demetrius L."], ["Shaw", "Gary"], ["Greene", "Nathanael"], ["Slaughter", "Joseph P."], ["López Fadul", "Valeria"], ["Miller", "Cecilia"], ["FazaleHaq", "Hafiz Muhammad"], ["Confalonieri", "Corrado"], ["Zamboni", "Camilla"], ["Perna", "Joseph"], ["Basile", "Joseph M."], ["Vinci", "Keith"], ["Park", "Paula C."], ["Walker", "Andrew"], ["Ospina", "Maria"], ["Oliveira", "Andre"], ["Sawyer", "Noelle"], ["Bryant", "Justin Alexander"], ["Kruckman", "Alex"], ["Leidy", "Constance"], ["Ramírez", "Felipe A."], ["Pollack", "David"], ["Collins", "Karen L."], ["Lane", "Robert P."], ["Grant", "Roger Mathew"], ["Alden", "Jane"], ["Matthusen", "Paula"], ["Balasubrahmaniyan", "B."], ["Daukeyeva", "Saida"], ["Charry", "Eric"], ["Kuivila", "Ronald J."], ["Baumgartner", "Robert"], ["Potemkina", "Nadya"], ["Wiseman", "Roy H."], ["Bennett", "Garrett"], ["Ribchinsky", "Julie Ann"], ["Kessel", "Scott M."], ["Aklaff", "Pheeroan"], ["Stockton", "Sarah"], ["Hoyle", "Robert J."], ["Lombardozzi", "Tony"], ["Sesma", "Megan"], ["Van Cleve", "Libby"], ["Bozzi", "Eugene"], ["Halsted", "Carolyn Frances"], ["Troxler", "Yvonne"], ["Simmons", "Fred"], ["Brown", "Nancy"], ["Lazur", "Allison"], ["Warshaw", "Marvin D."], ["Elliot", "Perry C."], ["Gale", "Priscilla E."], ["Earhart", "Robert"], ["Yueh", "Chai-lun"], ["Suriyakham", "Charlie"], ["Duruoz", "Cem"], ["Scott", "Stanley A."], ["Edwards", "Peter Craig"], ["Bergeron", "John R."], ["Gates", "Giacomo"], ["Nelson", "David Paul"], ["Chriss", "Alcee"], ["Biatowas", "John E"], ["LaRusso", "Salvatore"], ["Dankwa", "John Wesley"], ["Harjito", "I."], ["Baerman", "Noah"], ["Kim", "Kyungmi"], ["Robinson", "Mike"], ["Fried", "Michael A"], ["Potter", "Christopher J."], ["Reilly", "Joseph P."], ["Curry", "Walter Jr."], ["Woodworth", "Mark A."], ["Raba", "John G."], ["DiCenzo", "Daniel A"], ["Tynan", "Patrick"], ["Solomon", "Peter Gordon"], ["Lane", "Jennifer Shea"], ["Kerr", "Shona"], ["McKenna", "Jodi"], ["Carney", "Philip D."], ["Wheeler", "Geoffrey H."], ["Somera", "Ben"], ["Crooke", "John T."], ["Meredith", "Eva Bergsten"], ["Black", "Drew"], ["Karera", "Axelle"], ["Horst", "Steven W."], ["Shieh", "Sanford"], ["Kanet", "Sharisse Leigh"], ["Tu", "Min-Feng"], ["Stewart", "Brian A."], ["Paily", "George Mathew"], ["Sher", "Meng-ju Renee"], ["Etson", "Candice M"], ["Starr", "Francis W."], ["Morgan", "Thomas J."], ["Kottos", "Tsampikos"], ["Hüwel", "Lutz"], ["Jackson", "Elizabeth Anne"], ["Stemler", "Steven E."], ["Shusterman", "Anna"], ["Barth", "Hilary C."], ["Versey", "H. Shellae"], ["May", "Alexis"], ["Carney", "Sarah Kristin"], ["Hoffarth", "Mark"], ["Sanislow", "Charles A."], ["Plous", "Scott L."], ["Rodriguez Mosquera", "Patricia M"], ["Rose", "Jennifer S."], ["Kabacoff", "Robert Ira"], ["Fusso", "Susanne Grace"], ["Utkin", "Roman"], ["Gottschalk", "Peter S."], ["Quintman", "Andrew H"], ["Cameron", "Ron"], ["Aleshkovsky", "Irina"], ["Bird", "Tess"], ["Smith", "Courtney Weiss"], ["Carey Best", "Peggy"], ["Goldberg", "Greg"], ["Patterson-Faye", "Courtney"], ["Haber", "Benjamin"], ["Oriji", "Chinwe  Ezinna"], ["Autry", "Robyn Kimberley"], ["Cutler", "Jonathan"], ["Neary", "Louise C."], ["Flores-Cuadra", "Octavio"], ["Perez-Girones", "Ana M."], ["Treme", "Matthew James"], ["Sendra Ferrer", "Olga"], ["Gonzalez", "Bernardo Antonio"], ["Paul", "Mary"], ["Milik", "Christian L."], ["Torres", "Edward"], ["Holland", "Andrew"], ["Pearl", "Katie"], ["Oliveras", "Maria-Christina"], ["Jenkins", "Ronald S."], ["Ngernwichit", "Jaymee"], ["Kreiner", "Tim"], ["Bonner", "Jeanne M."], ["Lennox", "Jeffers"], ["Kilgard", "Roy E."], ["Cohan", "Frederick M."], ["Sultan", "Sonia"], ["Kirn", "John"], ["Personick", "Michelle Louise"], ["Damman", "Catherine"], ["Thomas", "Ellen"], ["Constantine", "David"], ["Licata", "Dan"], ["Danner", "Norman"], ["Weaver", "Christopher S."], ["Bonin", "John P."], ["Johnston", "William D."], ["Hastings", "Nick"], ["Varekamp", "Johan C."], ["Skillman", "Gilbert L."], ["Bloom", "Amy B."], ["Springer", "Elise"], ["Gruen", "Lori"], ["Hatch", "Anthony Ryan"], ["Phillips", "Earl W."], ["Slowik", "Michael James"], ["Laub", "David Paul"], ["Model", "Ben"], ["Scott", "Anthony O."], ["Dancey", "Logan M."], ["Conn", "Robert T."], ["Adeboye", "Ilesanmi"], ["MacQueen", "Amy"], ["Bruce", "Neely"], ["Leppanen", "Marcus"], ["Whalen", "Michael F."], ["Williams", "Kim"], ["Mullen", "Kate"], ["Voth", "Greg A."], ["Blümel", "Reinhold"], ["Dubar", "Royette Tavernier"], ["Quijada", "Justine"]]
        
        return lst
    }
    
    func getClasses() -> [String] {
        var lst = ["AFAM111", "AFAM115", "AFAM201", "AFAM202", "AFAM203", "AFAM204", "AFAM206", "AFAM211", "AFAM212", "AFAM219", "AFAM222", "AFAM224", "AFAM225", "AFAM226", "AFAM232", "AFAM240", "AFAM241", "AFAM246", "AFAM249", "AFAM252", "AFAM262", "AFAM268", "AFAM269", "AFAM271", "AFAM274", "AFAM275", "AFAM276", "AFAM277", "AFAM284", "AFAM291", "AFAM298", "AFAM301", "AFAM307", "AFAM310", "AFAM322", "AFAM325", "AFAM334", "AFAM344", "AFAM353", "AFAM361", "AFAM386", "AFAM388", "AFAM389", "AFAM390", "AFAM396", "AFAM397", "AFAM450", "AMST117F", "AMST119", "AMST122", "AMST150", "AMST170", "AMST174", "AMST175", "AMST176", "AMST177", "AMST178", "AMST200", "AMST201", "AMST202", "AMST205", "AMST206", "AMST208", "AMST209", "AMST210", "AMST211", "AMST212", "AMST213", "AMST218", "AMST219", "AMST220", "AMST222", "AMST223", "AMST224", "AMST225", "AMST229", "AMST230", "AMST231", "AMST232", "AMST233", "AMST234", "AMST235", "AMST237", "AMST238", "AMST239", "AMST240", "AMST241", "AMST243", "AMST247", "AMST249", "AMST250", "AMST251", "AMST255", "AMST256", "AMST261", "AMST269", "AMST273", "AMST274", "AMST278", "AMST284", "AMST285", "AMST286", "AMST287", "AMST288", "AMST290", "AMST291", "AMST296", "AMST297", "AMST298", "AMST299", "AMST304", "AMST307", "AMST308", "AMST313", "AMST315", "AMST318", "AMST319", "AMST324", "AMST325", "AMST329", "AMST330", "AMST336", "AMST340", "AMST351", "AMST353", "AMST355", "AMST356", "AMST361", "AMST363", "AMST371", "AMST386", "ANTH101", "ANTH103", "ANTH110", "ANTH112", "ANTH113", "ANTH150", "ANTH165", "ANTH201", "ANTH202", "ANTH203", "ANTH207", "ANTH208", "ANTH210", "ANTH211", "ANTH217", "ANTH225", "ANTH227", "ANTH230", "ANTH231", "ANTH232", "ANTH238", "ANTH240", "ANTH243", "ANTH244", "ANTH249", "ANTH259", "ANTH268", "ANTH279", "ANTH290", "ANTH295", "ANTH296", "ANTH297", "ANTH302", "ANTH303", "ANTH305", "ANTH307", "ANTH308", "ANTH310", "ANTH312", "ANTH314", "ANTH315", "ANTH316", "ANTH318", "ANTH319", "ANTH349", "ANTH360", "ANTH372", "ANTH395", "ANTH400", "ARAB101", "ARAB102", "ARAB201", "ARAB202", "ARAB301", "ARAB311", "ARCP112", "ARCP153", "ARCP202", "ARCP204", "ARCP242", "ARCP245", "ARCP248", "ARCP258", "ARCP267", "ARCP314", "ARCP329", "ARCP372", "ARCP382", "ARCP425", "ARHA110", "ARHA126", "ARHA127", "ARHA135", "ARHA140", "ARHA151", "ARHA170", "ARHA181", "ARHA182", "ARHA208", "ARHA211", "ARHA212", "ARHA214", "ARHA215", "ARHA216", "ARHA218", "ARHA221", "ARHA224", "ARHA233", "ARHA239", "ARHA240", "ARHA241", "ARHA244", "ARHA246", "ARHA249", "ARHA251", "ARHA252", "ARHA253", "ARHA254", "ARHA257", "ARHA258", "ARHA260", "ARHA263", "ARHA264", "ARHA267", "ARHA277", "ARHA278", "ARHA279", "ARHA282", "ARHA283", "ARHA284", "ARHA286", "ARHA288", "ARHA290", "ARHA291", "ARHA292", "ARHA296", "ARHA299", "ARHA300", "ARHA310", "ARHA322", "ARHA329", "ARHA339", "ARHA352", "ARHA361", "ARHA363", "ARHA368", "ARHA381", "ARHA382", "ARST131", "ARST190", "ARST233", "ARST235", "ARST237", "ARST239", "ARST242", "ARST243", "ARST244", "ARST245", "ARST251", "ARST253", "ARST260", "ARST261", "ARST285", "ARST323", "ARST332", "ARST336", "ARST338", "ARST340", "ARST346", "ARST352", "ARST353", "ARST361", "ARST362", "ARST432", "ARST433", "ARST435", "ARST436", "ARST437", "ARST438", "ARST439", "ARST440", "ARST442", "ARST443", "ARST444", "ARST445", "ARST446", "ARST451", "ARST452", "ARST453", "ARST460", "ARST461", "ARST483", "ARST490", "ASTR105", "ASTR107", "ASTR111", "ASTR155", "ASTR211", "ASTR221", "ASTR222", "ASTR224", "ASTR231", "ASTR232", "ASTR240", "ASTR430", "ASTR431", "ASTR521", "ASTR522", "ASTR524", "ASTR531", "ASTR532", "ASTR540", "ASTR555", "BIOL106", "BIOL131", "BIOL137", "BIOL140", "BIOL145", "BIOL149", "BIOL155", "BIOL173", "BIOL181", "BIOL182", "BIOL191", "BIOL192", "BIOL194", "BIOL197", "BIOL208", "BIOL210", "BIOL212", "BIOL215", "BIOL216", "BIOL218", "BIOL220", "BIOL224", "BIOL228", "BIOL229", "BIOL231", "BIOL232", "BIOL235", "BIOL237", "BIOL243", "BIOL245", "BIOL247", "BIOL252", "BIOL254", "BIOL265", "BIOL266", "BIOL290", "BIOL295", "BIOL299", "BIOL310", "BIOL316", "BIOL318", "BIOL320", "BIOL325", "BIOL327", "BIOL328", "BIOL334", "BIOL340", "BIOL343", "BIOL345", "BIOL346", "BIOL347", "BIOL351", "BIOL354", "BIOL360", "BIOL500", "BIOL505", "BIOL506", "BIOL507", "BIOL508", "BIOL509", "BIOL510", "BIOL515", "BIOL516", "BIOL518", "BIOL540", "BIOL557", "BIOL590", "CCIV112", "CCIV118", "CCIV153", "CCIV170", "CCIV190", "CCIV201", "CCIV202", "CCIV205", "CCIV214", "CCIV223", "CCIV227", "CCIV228", "CCIV229", "CCIV231", "CCIV232", "CCIV234", "CCIV244", "CCIV271", "CCIV281", "CCIV301", "CCIV324", "CCIV329", "CCIV330", "CCIV341", "CEAS155", "CEAS160", "CEAS166", "CEAS168", "CEAS180", "CEAS181", "CEAS185", "CEAS201", "CEAS202", "CEAS203", "CEAS204", "CEAS205", "CEAS206", "CEAS207", "CEAS208", "CEAS210", "CEAS213", "CEAS215", "CEAS217", "CEAS221", "CEAS223", "CEAS224", "CEAS225", "CEAS232", "CEAS236", "CEAS241", "CEAS242", "CEAS244", "CEAS251", "CEAS252", "CEAS254", "CEAS259", "CEAS262", "CEAS263", "CEAS264", "CEAS267", "CEAS268", "CEAS274", "CEAS276", "CEAS277", "CEAS278", "CEAS279", "CEAS280", "CEAS283", "CEAS284", "CEAS285", "CEAS295", "CEAS296", "CEAS297", "CEAS300", "CEAS301", "CEAS338", "CEAS343", "CEAS345", "CEAS346", "CEAS355", "CEAS362", "CEAS385", "CEAS390", "CEAS395", "CEAS413", "CEAS416", "CEAS418", "CEAS428", "CEAS460", "CEAS461", "CGST121", "CGST130", "CGST131", "CGST136", "CGST201", "CGST202", "CGST208", "CGST210", "CGST227", "CGST303", "CHEM118", "CHEM119", "CHEM120", "CHEM141", "CHEM142", "CHEM143", "CHEM144", "CHEM152", "CHEM241", "CHEM242", "CHEM251", "CHEM252", "CHEM257", "CHEM258", "CHEM307", "CHEM308", "CHEM309", "CHEM317", "CHEM320", "CHEM321", "CHEM323", "CHEM325", "CHEM337", "CHEM338", "CHEM340", "CHEM342", "CHEM353", "CHEM358", "CHEM359", "CHEM361", "CHEM375", "CHEM376", "CHEM377", "CHEM379", "CHEM382", "CHEM383", "CHEM387", "CHEM390", "CHEM396", "CHEM520", "CHEM521", "CHEM522", "CHEM545", "CHEM547", "CHEM548", "CHEM557", "CHEM558", "CHEM565", "CHEM587", "CHEM588", "CHEM596", "CHIN101", "CHIN102", "CHIN103", "CHIN104", "CHIN105", "CHIN205", "CHIN206", "CHIN217", "CHIN218", "CHIN221", "CHIN222", "CHIN223", "CHIN230", "CHIN301", "CHUM224", "CHUM300", "CHUM302", "CHUM303", "CHUM304", "CHUM305", "CHUM306", "CHUM307", "CHUM309", "CHUM312", "CHUM313", "CHUM317", "CHUM320", "CHUM322", "CHUM323", "CHUM328", "CHUM331", "CHUM341", "CHUM343", "CHUM344", "CHUM347", "CHUM349", "CHUM351", "CHUM352", "CHUM354", "CHUM356", "CHUM359", "CHUM362", "CHUM367", "CHUM381", "CIS115", "CIS116", "CIS121", "CIS122", "CIS135", "CIS150", "CIS160", "CIS170", "CIS173", "CIS175", "CIS221", "CIS222", "CIS239", "CIS241", "CIS250", "CIS251", "CIS285", "CIS307", "CIS310", "CIS320", "CIS321", "CIS322", "CIS323", "CIS331", "CIS375", "CIS400", "CIS520", "CJST153", "CJST203", "CJST214", "CJST216", "CJST218", "CJST221", "CJST234", "CJST241", "CJST243", "CJST248", "CJST249", "CJST272", "CJST413", "COL108", "COL108F", "COL110", "COL112", "COL112F", "COL115", "COL116", "COL117", "COL118", "COL120", "COL126", "COL128", "COL129", "COL130F", "COL150", "COL186", "COL201", "COL204", "COL219", "COL220", "COL223", "COL225", "COL227", "COL228", "COL231", "COL233", "COL235", "COL236", "COL238", "COL241", "COL243", "COL244", "COL245", "COL246", "COL247", "COL249", "COL250", "COL251", "COL252", "COL253", "COL254", "COL256", "COL257", "COL258", "COL264", "COL266", "COL269", "COL270", "COL271", "COL272", "COL274", "COL275", "COL278", "COL283", "COL292", "COL297", "COL307", "COL308", "COL309", "COL332", "COL336", "COL338", "COL360", "COL370", "COL390", "COL391", "COMP112", "COMP114", "COMP115", "COMP211", "COMP212", "COMP260", "COMP301", "COMP312", "COMP321", "COMP323", "COMP331", "COMP332", "COMP360", "COMP500", "COMP510", "COMP521", "COMP523", "COMP531", "CSPL127", "CSPL140", "CSPL201", "CSPL202", "CSPL206", "CSPL210", "CSPL215", "CSPL220", "CSPL225", "CSPL229", "CSPL230", "CSPL235", "CSPL239", "CSPL240", "CSPL245", "CSPL262", "CSPL264", "CSPL265", "CSPL266", "CSPL280", "CSPL281", "CSPL302", "CSPL315", "CSPL320", "CSPL321", "CSPL330", "CSPL332", "CSPL366", "CSPL368", "CSPL493", "CSS220", "CSS230", "CSS240", "CSS271", "CSS320", "CSS330", "CSS340", "CSS371", "CSS391", "DANC103", "DANC105", "DANC107", "DANC111", "DANC202", "DANC205", "DANC211", "DANC213", "DANC215", "DANC237", "DANC244", "DANC249", "DANC250", "DANC251", "DANC260", "DANC261", "DANC300", "DANC302", "DANC307", "DANC309", "DANC318", "DANC354", "DANC359", "DANC360", "DANC362", "DANC364", "DANC365", "DANC371", "DANC377", "DANC378", "DANC398", "DANC435", "DANC445", "DANC447", "E&ES101", "E&ES160", "E&ES195", "E&ES197", "E&ES199", "E&ES213", "E&ES214", "E&ES215", "E&ES216", "E&ES220", "E&ES222", "E&ES223", "E&ES224", "E&ES225", "E&ES230", "E&ES231", "E&ES232", "E&ES234", "E&ES235", "E&ES236", "E&ES246", "E&ES248", "E&ES250", "E&ES251", "E&ES260", "E&ES261", "E&ES280", "E&ES281", "E&ES301", "E&ES313", "E&ES314", "E&ES317", "E&ES321", "E&ES322", "E&ES323", "E&ES324", "E&ES344", "E&ES359", "E&ES365", "E&ES371", "E&ES375", "E&ES380", "E&ES385", "E&ES386", "E&ES388", "E&ES397", "E&ES398", "E&ES399", "E&ES400", "E&ES497", "E&ES498", "E&ES500", "E&ES513", "E&ES517", "E&ES521", "E&ES522", "E&ES523", "E&ES524", "E&ES546", "E&ES555", "E&ES557", "E&ES565", "E&ES571", "E&ES575", "E&ES580", "E&ES581", "E&ES585", "E&ES586", "E&ES588", "ECON101", "ECON110", "ECON127", "ECON211", "ECON212", "ECON213", "ECON220", "ECON222", "ECON224", "ECON225", "ECON227", "ECON234", "ECON237", "ECON241", "ECON251", "ECON254", "ECON255", "ECON261", "ECON263", "ECON266", "ECON270", "ECON273", "ECON300", "ECON301", "ECON302", "ECON308", "ECON310", "ECON311", "ECON318", "ECON319", "ECON321", "ECON322", "ECON327", "ECON328", "ECON329", "ECON331", "ECON341", "ECON347", "ECON348", "ECON349", "ECON352", "ECON353", "ECON356", "ECON357", "ECON358", "ECON361", "ECON362", "ECON363", "ECON366", "ECON371", "ECON385", "ECON386", "EDST140", "EDST230", "EDST310", "ENGL105", "ENGL113", "ENGL130", "ENGL131", "ENGL131B", "ENGL132", "ENGL134", "ENGL135", "ENGL140", "ENGL142", "ENGL145", "ENGL146", "ENGL150", "ENGL154", "ENGL155", "ENGL160", "ENGL162", "ENGL165", "ENGL175", "ENGL175F", "ENGL176", "ENGL176F", "ENGL186", "ENGL190", "ENGL203", "ENGL204", "ENGL205", "ENGL206", "ENGL207", "ENGL208", "ENGL209", "ENGL210", "ENGL212", "ENGL213", "ENGL214", "ENGL215", "ENGL216", "ENGL218", "ENGL221", "ENGL223", "ENGL224", "ENGL225", "ENGL226", "ENGL229", "ENGL230", "ENGL231", "ENGL232", "ENGL235", "ENGL239", "ENGL241", "ENGL244", "ENGL245", "ENGL247", "ENGL249", "ENGL250", "ENGL251", "ENGL253", "ENGL254", "ENGL255", "ENGL256", "ENGL258", "ENGL260", "ENGL261", "ENGL262", "ENGL264", "ENGL266", "ENGL267", "ENGL268", "ENGL269", "ENGL270", "ENGL271", "ENGL272", "ENGL273", "ENGL274", "ENGL275", "ENGL276", "ENGL277", "ENGL278", "ENGL279", "ENGL280", "ENGL281", "ENGL283", "ENGL284", "ENGL286", "ENGL288", "ENGL289", "ENGL290", "ENGL291", "ENGL292", "ENGL293", "ENGL295", "ENGL296", "ENGL297", "ENGL298", "ENGL303", "ENGL304", "ENGL305", "ENGL307", "ENGL311", "ENGL312", "ENGL314", "ENGL315", "ENGL316", "ENGL317", "ENGL322", "ENGL323", "ENGL325", "ENGL326", "ENGL327", "ENGL328", "ENGL329", "ENGL330", "ENGL333", "ENGL334", "ENGL335", "ENGL336", "ENGL337", "ENGL339", "ENGL341", "ENGL342", "ENGL343", "ENGL344", "ENGL347", "ENGL349", "ENGL350", "ENGL351", "ENGL352", "ENGL353", "ENGL354", "ENGL356", "ENGL357", "ENGL358", "ENGL359", "ENGL360", "ENGL361", "ENGL365", "ENGL367", "ENGL368", "ENGL369", "ENGL371", "ENGL373", "ENGL374", "ENGL375", "ENGL376", "ENGL378", "ENGL379", "ENGL385", "ENGL386", "ENGL388", "ENGL399", "ENVS201", "ENVS206", "ENVS212", "ENVS215", "ENVS216", "ENVS220", "ENVS229", "ENVS230", "ENVS235", "ENVS245", "ENVS248", "ENVS252", "ENVS254", "ENVS260", "ENVS264", "ENVS267", "ENVS270", "ENVS275", "ENVS279", "ENVS280", "ENVS281", "ENVS282", "ENVS285", "ENVS288", "ENVS292", "ENVS296", "ENVS300", "ENVS303", "ENVS310", "ENVS314", "ENVS316", "ENVS325", "ENVS344", "ENVS347", "ENVS352", "ENVS353", "ENVS361", "ENVS391", "ENVS392", "ENVS440", "FGSS167", "FGSS200", "FGSS201", "FGSS204", "FGSS205", "FGSS206", "FGSS209", "FGSS210", "FGSS215", "FGSS216", "FGSS217", "FGSS218", "FGSS227", "FGSS235", "FGSS236", "FGSS237", "FGSS238", "FGSS240", "FGSS242", "FGSS244", "FGSS255", "FGSS264", "FGSS277", "FGSS281", "FGSS288", "FGSS293", "FGSS295", "FGSS302", "FGSS309", "FGSS318", "FGSS321", "FGSS326", "FGSS330", "FGSS345", "FGSS350", "FGSS351", "FGSS360", "FGSS386", "FGSS390", "FGSS405", "FILM104", "FILM105", "FILM157", "FILM288", "FILM300", "FILM303", "FILM304", "FILM305", "FILM306", "FILM307", "FILM309", "FILM311", "FILM314", "FILM315", "FILM320", "FILM322", "FILM324", "FILM326", "FILM328", "FILM329", "FILM330", "FILM331", "FILM336", "FILM341", "FILM342", "FILM346", "FILM347", "FILM352", "FILM355", "FILM358", "FILM360", "FILM366", "FILM370", "FILM381", "FILM386", "FILM387", "FILM388", "FILM389", "FILM390", "FILM391", "FILM392", "FILM414", "FILM418", "FILM442", "FILM448", "FILM450", "FILM451", "FILM454", "FILM455", "FILM456", "FILM457", "FILM460", "FIST122", "FIST123", "FIST125", "FIST126", "FIST127", "FIST129", "FIST130", "FIST176", "FIST201", "FIST220", "FIST221", "FIST224", "FIST226", "FIST229", "FIST232", "FIST233", "FIST235", "FIST244", "FIST254", "FIST300", "FIST301", "FREN101", "FREN102", "FREN110", "FREN111", "FREN112", "FREN215", "FREN222", "FREN223", "FREN224", "FREN230", "FREN237", "FREN238", "FREN254", "FREN281", "FREN305", "FREN306", "FREN310", "FREN324", "FREN325", "FREN330", "FREN333", "FREN334", "FREN348", "FREN357", "FREN372", "FREN382", "FREN391", "FRST297", "GOVT108", "GOVT110", "GOVT151", "GOVT155", "GOVT157", "GOVT158", "GOVT159", "GOVT203", "GOVT205", "GOVT206", "GOVT214", "GOVT215", "GOVT217", "GOVT220", "GOVT232", "GOVT238", "GOVT239", "GOVT250", "GOVT252", "GOVT253", "GOVT270", "GOVT271", "GOVT272", "GOVT274", "GOVT276", "GOVT277", "GOVT278", "GOVT280", "GOVT281", "GOVT282", "GOVT284", "GOVT285", "GOVT295", "GOVT296", "GOVT297", "GOVT298", "GOVT302", "GOVT303", "GOVT306", "GOVT309", "GOVT311", "GOVT314", "GOVT315", "GOVT322", "GOVT324", "GOVT325", "GOVT326", "GOVT328", "GOVT329", "GOVT330", "GOVT331", "GOVT332", "GOVT334", "GOVT335", "GOVT337", "GOVT338", "GOVT339", "GOVT340", "GOVT344", "GOVT345", "GOVT346", "GOVT348", "GOVT349", "GOVT352", "GOVT355", "GOVT366", "GOVT367", "GOVT369", "GOVT370", "GOVT372", "GOVT373", "GOVT374", "GOVT375", "GOVT376", "GOVT377", "GOVT378", "GOVT379", "GOVT380", "GOVT383", "GOVT385", "GOVT386", "GOVT387", "GOVT389", "GOVT391", "GOVT392", "GOVT395", "GOVT396", "GOVT398", "GOVT399", "GRK101", "GRK102", "GRK201", "GRK258", "GRK275", "GRK365", "GRK367", "GRST101", "GRST102", "GRST211", "GRST212", "GRST213", "GRST214", "GRST217", "GRST230", "GRST230F", "GRST251", "GRST252", "GRST254", "GRST255", "GRST257", "GRST260", "GRST261", "GRST262", "GRST263", "GRST264", "GRST272", "GRST275", "GRST279", "GRST301", "GRST302", "GRST310", "GRST335", "GRST376", "GRST379", "GRST390", "HEBR101", "HEBR102", "HEBR201", "HEBR202", "HEBR211", "HIST101", "HIST110", "HIST112", "HIST116", "HIST123", "HIST124", "HIST126", "HIST135", "HIST141", "HIST151", "HIST154", "HIST161", "HIST172", "HIST175", "HIST176", "HIST179", "HIST180", "HIST186", "HIST195", "HIST202", "HIST203", "HIST204", "HIST205", "HIST210", "HIST211", "HIST212", "HIST214", "HIST216", "HIST217", "HIST219", "HIST220", "HIST221", "HIST223", "HIST224", "HIST225", "HIST226", "HIST231", "HIST232", "HIST234", "HIST235", "HIST237", "HIST238", "HIST239", "HIST240", "HIST241", "HIST242", "HIST245", "HIST246", "HIST247", "HIST251", "HIST252", "HIST253", "HIST254", "HIST255", "HIST256", "HIST259", "HIST262", "HIST263", "HIST264", "HIST266", "HIST267", "HIST268", "HIST269", "HIST272", "HIST274", "HIST275", "HIST279", "HIST280", "HIST281", "HIST285", "HIST286", "HIST287", "HIST291", "HIST292", "HIST293", "HIST294", "HIST296", "HIST297", "HIST298", "HIST301", "HIST307", "HIST314", "HIST315", "HIST317", "HIST318", "HIST319", "HIST321", "HIST322", "HIST324", "HIST333", "HIST334", "HIST335", "HIST337", "HIST338", "HIST341", "HIST342", "HIST348", "HIST355", "HIST357", "HIST358", "HIST362", "HIST366", "HIST370", "HIST371", "HIST373", "HIST377", "HIST380", "HIST381", "HIST383", "HIST386", "HIST387", "HIST394", "HIST395", "HIST396", "HIST399", "IDEA170", "IDEA173", "IDEA175", "IDEA190", "IDEA233", "IDEA350", "ITAL101", "ITAL102", "ITAL103", "ITAL111", "ITAL112", "ITAL221", "ITAL222", "ITAL227", "ITAL229", "ITAL231", "ITAL233", "ITAL235", "ITAL236", "ITAL242", "ITAL247", "JAPN103", "JAPN104", "JAPN205", "JAPN206", "JAPN217", "JAPN218", "JAPN219", "JAPN220", "JAPN229", "JAPN230", "KREA153", "KREA154", "KREA205", "KREA206", "KREA217", "KREA218", "LANG190", "LANG191", "LANG290", "LAST200", "LAST211", "LAST217", "LAST219", "LAST226", "LAST240", "LAST245", "LAST252", "LAST254", "LAST258", "LAST265", "LAST270", "LAST272", "LAST273", "LAST278", "LAST280", "LAST281", "LAST283", "LAST285", "LAST291", "LAST292", "LAST296", "LAST302", "LAST307", "LAST308", "LAST309", "LAST320", "LAST322", "LAST335", "LAST344", "LAST348", "LAST373", "LAT101", "LAT102", "LAT104", "LAT201", "LAT202", "LAT262", "LAT270", "LAT281", "LAT301", "LAT322", "LAT331", "LAT353", "MATH117", "MATH118", "MATH119", "MATH120", "MATH121", "MATH122", "MATH132", "MATH211", "MATH221", "MATH222", "MATH223", "MATH225", "MATH226", "MATH228", "MATH229", "MATH231", "MATH232", "MATH241", "MATH243", "MATH244", "MATH246", "MATH252", "MATH255", "MATH261", "MATH262", "MATH271", "MATH272", "MATH273", "MATH274", "MATH513", "MATH514", "MATH515", "MATH516", "MATH523", "MATH524", "MATH525", "MATH526", "MATH543", "MATH544", "MATH545", "MATH546", "MB&B103", "MB&B107", "MB&B117", "MB&B119", "MB&B155", "MB&B160", "MB&B181", "MB&B182", "MB&B191", "MB&B192", "MB&B194", "MB&B203", "MB&B208", "MB&B209", "MB&B210", "MB&B212", "MB&B228", "MB&B231", "MB&B232", "MB&B242", "MB&B285", "MB&B286", "MB&B306", "MB&B315", "MB&B321", "MB&B325", "MB&B334", "MB&B340", "MB&B363", "MB&B377", "MB&B381", "MB&B382", "MB&B383", "MB&B387", "MB&B394", "MB&B395", "MB&B506", "MB&B515", "MB&B534", "MB&B535", "MB&B543", "MB&B557", "MB&B558", "MB&B577", "MB&B585", "MB&B586", "MB&B587", "MB&B588", "MDST135", "MDST151", "MDST207", "MDST212", "MDST214", "MDST216", "MDST217", "MDST221", "MDST222", "MDST231", "MDST232", "MDST234", "MDST235", "MDST239", "MDST251", "MDST257", "MDST295", "MDST302", "MDST310", "MDST330", "MDST353", "MDST373", "MUSC102", "MUSC103", "MUSC105", "MUSC106", "MUSC108", "MUSC109", "MUSC110", "MUSC111", "MUSC115", "MUSC116", "MUSC124", "MUSC125", "MUSC127", "MUSC129", "MUSC201", "MUSC202", "MUSC204", "MUSC205", "MUSC206", "MUSC207", "MUSC208", "MUSC210", "MUSC212", "MUSC220", "MUSC223", "MUSC230", "MUSC241", "MUSC243", "MUSC244", "MUSC246", "MUSC249", "MUSC261", "MUSC265", "MUSC269", "MUSC274", "MUSC275", "MUSC277", "MUSC280", "MUSC286", "MUSC287", "MUSC288", "MUSC289", "MUSC290", "MUSC291", "MUSC294", "MUSC300", "MUSC405", "MUSC406", "MUSC413", "MUSC416", "MUSC418", "MUSC428", "MUSC430", "MUSC431", "MUSC432", "MUSC433", "MUSC434", "MUSC436", "MUSC438", "MUSC439", "MUSC441", "MUSC442", "MUSC443", "MUSC445", "MUSC446", "MUSC447", "MUSC448", "MUSC450", "MUSC451", "MUSC452", "MUSC453", "MUSC455", "MUSC456", "MUSC457", "MUSC458", "MUSC459", "MUSC460", "MUSC461", "MUSC463", "MUSC464", "MUSC505", "MUSC506", "MUSC507", "MUSC508", "MUSC509", "MUSC510", "MUSC513", "MUSC515", "MUSC519", "MUSC520", "MUSC522", "MUSC525", "MUSC530", "NS&B149", "NS&B210", "NS&B213", "NS&B215", "NS&B220", "NS&B221", "NS&B222", "NS&B224", "NS&B225", "NS&B227", "NS&B228", "NS&B239", "NS&B243", "NS&B245", "NS&B247", "NS&B252", "NS&B254", "NS&B299", "NS&B317", "NS&B323", "NS&B325", "NS&B328", "NS&B329", "NS&B341", "NS&B342", "NS&B347", "NS&B351", "NS&B353", "NS&B356", "NS&B360", "NS&B383", "NS&B390", "NS&B392", "NS&B398", "NS&B399", "NS&B509", "NS&B510", "PHED101", "PHED102", "PHED104", "PHED106", "PHED107", "PHED116", "PHED118", "PHED119", "PHED120", "PHED121", "PHED122", "PHED123", "PHED124", "PHED127", "PHED130", "PHED133", "PHED137", "PHED138", "PHED139", "PHED140", "PHED142", "PHED144", "PHED147", "PHED152", "PHED155", "PHED157", "PHED159", "PHED169", "PHED170", "PHIL111", "PHIL115", "PHIL201", "PHIL202", "PHIL205", "PHIL207", "PHIL211", "PHIL212", "PHIL214", "PHIL215", "PHIL217", "PHIL218", "PHIL219", "PHIL221", "PHIL222", "PHIL231", "PHIL232", "PHIL251", "PHIL254", "PHIL256", "PHIL258", "PHIL259", "PHIL262", "PHIL263", "PHIL265", "PHIL267", "PHIL268", "PHIL269", "PHIL270", "PHIL272", "PHIL275", "PHIL276", "PHIL277", "PHIL278", "PHIL282", "PHIL283", "PHIL284", "PHIL286", "PHIL287", "PHIL289", "PHIL290", "PHIL291", "PHIL292", "PHIL293", "PHIL294", "PHIL303", "PHIL310", "PHIL321", "PHIL347", "PHIL353", "PHIL354", "PHIL355", "PHIL357", "PHIL359", "PHIL360", "PHIL362", "PHIL366", "PHIL375", "PHIL390", "PHYS105", "PHYS107", "PHYS111", "PHYS112", "PHYS113", "PHYS115", "PHYS116", "PHYS121", "PHYS122", "PHYS123", "PHYS124", "PHYS162", "PHYS170", "PHYS213", "PHYS214", "PHYS215", "PHYS217", "PHYS219", "PHYS221", "PHYS313", "PHYS315", "PHYS316", "PHYS324", "PHYS340", "PHYS342", "PHYS345", "PHYS358", "PHYS377", "PHYS505", "PHYS506", "PHYS507", "PHYS508", "PHYS509", "PHYS510", "PHYS513", "PHYS515", "PHYS516", "PHYS521", "PHYS522", "PHYS524", "PHYS542", "PHYS543", "PHYS545", "PHYS558", "PHYS565", "PHYS566", "PHYS567", "PHYS571", "PHYS572", "PHYS573", "PHYS574", "PHYS575", "PHYS577", "PHYS578", "PHYS587", "PHYS588", "PORT155", "PORT156", "PSYC105", "PSYC111", "PSYC131", "PSYC200", "PSYC202", "PSYC204", "PSYC205", "PSYC207", "PSYC208", "PSYC209", "PSYC210", "PSYC211", "PSYC213", "PSYC214", "PSYC215", "PSYC220", "PSYC221", "PSYC222", "PSYC225", "PSYC227", "PSYC228", "PSYC230", "PSYC245", "PSYC248", "PSYC250", "PSYC251", "PSYC253", "PSYC259", "PSYC260", "PSYC261", "PSYC265", "PSYC266", "PSYC267", "PSYC269", "PSYC277", "PSYC309", "PSYC314", "PSYC322", "PSYC325", "PSYC326", "PSYC327", "PSYC328", "PSYC329", "PSYC338", "PSYC341", "PSYC342", "PSYC343", "PSYC344", "PSYC347", "PSYC349", "PSYC350", "PSYC355", "PSYC361", "PSYC365", "PSYC380", "PSYC383", "PSYC386", "PSYC387", "PSYC388", "PSYC390", "PSYC391", "PSYC392", "PSYC394", "PSYC395", "PSYC396", "PSYC397", "PSYC398", "PSYC399", "QAC150", "QAC151", "QAC155", "QAC156", "QAC157", "QAC158", "QAC171", "QAC201", "QAC211", "QAC231", "QAC239", "QAC241", "QAC250", "QAC251", "QAC260", "QAC301", "QAC302", "QAC305", "QAC307", "QAC311", "QAC312", "QAC313", "QAC314", "QAC323", "QAC356", "QAC380", "QAC385", "QAC386", "REES209", "REES219", "REES233", "REES235", "REES254", "REES260", "REES268", "REES280", "REES289", "REES299", "RELI151", "RELI201", "RELI203", "RELI204", "RELI205", "RELI207", "RELI208", "RELI212", "RELI213", "RELI214", "RELI215", "RELI216", "RELI217", "RELI220", "RELI221", "RELI229", "RELI230", "RELI240", "RELI242", "RELI250", "RELI270", "RELI272", "RELI276", "RELI278", "RELI280", "RELI282", "RELI288", "RELI289", "RELI291", "RELI292", "RELI299", "RELI301", "RELI307", "RELI308", "RELI314", "RELI315", "RELI355", "RELI377", "RELI385", "RELI391", "RELI395", "RELI398", "RUSS101", "RUSS102", "RUSS201", "RUSS202", "RUSS205", "RUSS206", "RUSS209", "RUSS220", "RUSS232", "RUSS234", "RUSS240", "RUSS251", "RUSS252", "RUSS255", "RUSS260", "RUSS263", "RUSS267", "RUSS277", "RUSS301", "RUSS302", "SISP113", "SISP125", "SISP130", "SISP202", "SISP204", "SISP211", "SISP215", "SISP217", "SISP224", "SISP230", "SISP235", "SISP238", "SISP240", "SISP245", "SISP253", "SISP254", "SISP256", "SISP262", "SISP264", "SISP265", "SISP276", "SISP281", "SISP282", "SISP286", "SISP287", "SISP304", "SISP310", "SISP314", "SISP315", "SISP318", "SISP320", "SISP321", "SISP330", "SISP342", "SISP344", "SISP353", "SISP355", "SISP365", "SISP366", "SISP373", "SISP377", "SOC151", "SOC202", "SOC212", "SOC220", "SOC222", "SOC231", "SOC234", "SOC238", "SOC239", "SOC241", "SOC242", "SOC243", "SOC244", "SOC246", "SOC249", "SOC256", "SOC259", "SOC260", "SOC268", "SOC269", "SOC270", "SOC284", "SOC293", "SOC299", "SOC302", "SOC308", "SOC309", "SOC313", "SOC315", "SOC316", "SOC320", "SOC322", "SOC326", "SOC399D", "SOC399F", "SOC399G", "SOC399H", "SOC399I", "SOC399J", "SOC399K", "SOC405", "SOC406", "SPAN101", "SPAN102", "SPAN103", "SPAN110", "SPAN111", "SPAN112", "SPAN113", "SPAN203", "SPAN221", "SPAN227", "SPAN230", "SPAN231", "SPAN232", "SPAN233", "SPAN236", "SPAN250", "SPAN256", "SPAN257", "SPAN258", "SPAN259", "SPAN261", "SPAN264", "SPAN267", "SPAN270", "SPAN271", "SPAN272", "SPAN273", "SPAN275", "SPAN276", "SPAN278", "SPAN279", "SPAN280", "SPAN281", "SPAN282", "SPAN283", "SPAN284", "SPAN286", "SPAN287", "SPAN290", "SPAN291", "THEA105", "THEA110", "THEA115", "THEA135", "THEA150", "THEA167", "THEA183", "THEA185", "THEA199", "THEA202", "THEA203", "THEA210", "THEA218", "THEA220", "THEA235", "THEA237", "THEA245", "THEA246", "THEA261", "THEA266", "THEA267", "THEA279", "THEA281", "THEA285", "THEA289", "THEA291", "THEA302", "THEA305", "THEA309", "THEA310", "THEA315", "THEA316", "THEA318", "THEA319", "THEA329", "THEA331", "THEA348", "THEA350", "THEA351", "THEA354", "THEA357", "THEA359", "THEA360", "THEA364", "THEA365", "THEA381", "THEA383", "THEA385", "THEA399", "THEA427", "THEA431", "THEA433", "THEA434", "THEA435", "THEA437", "WRCT113", "WRCT120F", "WRCT130F", "WRCT135", "WRCT140", "WRCT140L", "WRCT150", "WRCT200", "WRCT224", "WRCT227", "WRCT250G", "WRCT250J", "WRCT250K", "WRCT250M", "WRCT250N", "WRCT250Q", "WRCT256", "WRCT264", "WRCT300", "WRCT302", "WRCT317", "WRCT347", "WRCT350", "AFAM116F", "AFAM171F", "AFAM233", "AFAM237", "AFAM250", "AFAM254", "AFAM279", "AFAM282", "AFAM282F", "AFAM324", "AFAM326", "AFAM360", "AFAM375", "AMST242", "AMST243A", "AMST259", "AMST264", "AMST265", "AMST270", "AMST316", "AMST334", "AMST357", "AMST375", "ANTH112F", "ANTH213", "ANTH304", "ANTH355", "ARCP244", "ARHA140F", "ARHA181F", "ARHA209", "ARHA210", "ARHA219", "ARHA379", "ARST286", "ARST350", "ARST380", "ASTR500", "BIOL140F", "BIOL213", "BIOL239", "BIOL241", "BIOL353", "BIOL357", "BIOL571", "BIOL599", "CCIV115F", "CCIV153F", "CCIV175F", "CCIV393", "CEAS158F", "CEAS218", "CEAS231", "CEAS234", "CEAS248", "CEAS257", "CEAS261", "CEAS320", "CEAS340", "CEAS363", "CEAS379", "CHIN351", "KREA255", "CGST132", "CGST231", "CGST250", "CGST251", "CGST255", "CGST290", "CHEM121F", "CHEM386", "CHEM395", "CHEM500", "CHEM507", "CHUM228", "CHUM248", "CHUM288", "CHUM311", "CHUM326", "CHUM353", "CHUM355", "CHUM383", "CIS265", "CIS266", "PSYC280", "COL121F", "COL138F", "COL150F", "COL226", "COL240", "COL285", "COL287", "COL290", "COL313", "COL339", "COL350", "COMP113", "COMP266", "COMP360D", "CSPL115F", "CSPL116F", "CSPL250", "CSPL250N", "CSPL250R", "CSPL263", "CSPL267", "CSPL277", "CSPL316", "CSPL317", "CSPL323", "DANC104F", "DANC212", "DANC375", "E&ES130F", "E&ES201", "E&ES221", "E&ES244", "E&ES245", "E&ES342", "ECON242", "ECON315", "ECON323", "EDST114F", "EDST202", "ENGL141F", "ENGL152F", "ENGL165F", "ENGL190F", "ENGL201E", "ENGL201J", "ENGL201L", "ENGL201R", "ENGL203A", "ENGL217", "ENGL233", "ENGL248", "ENGL257", "ENGL313", "ENGL324", "ENGL339A", "ENGL380", "ENGL382", "ENGL450", "ENVS197", "ENVS211", "ENVS225", "ENVS230F", "ENVS369", "SOC247", "FGSS115F", "FGSS200F", "FGSS265", "FGSS303", "FGSS304", "FGSS311", "FGSS327", "FGSS355", "FGSS387", "FILM319", "FILM357", "FILM385", "FILM430", "FILM458", "FREN273", "FREN356", "FREN399", "GELT230F", "GOVT116F", "GOVT155F", "GOVT201", "GOVT283", "GOVT323", "GRK250", "GRST231", "GRST290", "GRST330", "HIST101F", "HIST109F", "HIST118F", "HIST123F", "HIST140", "HIST177", "HIST201", "HIST208", "HIST257", "HIST302", "HIST328", "HIST345", "HIUR101", "HIUR201", "ITAL241", "LANG151", "LAST218", "LAST232", "LAST241", "LAST242", "LAT203", "LAT230", "MATH500", "MB&B101F", "MB&B265", "MB&B266", "MB&B303", "MB&B307", "MB&B386", "MB&B500", "MB&B507", "MB&B523", "MB&B571", "MDST204", "MDST209", "MDST210", "MDST350", "MUSC117F", "MUSC118F", "MUSC124F", "MUSC500", "NS&B280", "NS&B303", "NS&B357", "PHIL112", "PHIL213", "PHIL221F", "PHIL252", "PHIL253", "PHIL264", "PHIL351", "PHIL385", "PHYS207", "PHYS317", "PHYS395", "PHYS500", "PHYS517", "PHYS568", "PSYC138F", "PSYC206", "PSYC239", "PSYC240", "PSYC249", "PSYC352", "PSYC353", "PSYC379", "PSYC500", "QAC381", "REES205", "REES208F", "REES256", "REES277", "REES340", "REES344", "RELI228", "RELI255", "RELI280F", "RELI305", "RELI393", "RL&L210", "RL&L212", "RL&L240", "RL&L243", "RL&L244", "RL&L250", "RL&L290", "RULE205", "RULE208F", "RULE256", "RULE277", "RULE340", "RUSS208F", "RUSS256", "RUSS340", "SISP120F", "SISP213", "SISP221", "SISP259", "SISP305", "SISP352", "SISP385", "SOC257", "SOC266", "SOC311", "SOC352", "SPAN255", "SPAN285", "THEA212", "THEA231", "THEA233", "THEA280", "THEA286", "THEA390", "WRCT110F", "WRCT112F", "WRCT114F", "WRCT116F", "WRCT202", "WRCT250", "WRCT250R"]

        return Array(Set(lst))
    }
    

}
