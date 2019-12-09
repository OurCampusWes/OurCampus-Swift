//
//  BrowseDepsViewController.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/3/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class BrowseDepsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var text: String = ""
    @IBOutlet weak var department: UILabel!
    var depsList = [String: [[String]]]()
    var profList = [String]()
    
    var ref: DatabaseReference?
    var ratesList = [TopRatesModel]()
    var difficultyList = [TopRatesModel]()
    var overallRates = [TopRatesModel]()
    @IBOutlet weak var tblRates: UITableView!
    var chosenProf: String!
    
    let network = NetworkManager.sharedInstance
    
    var ratesOrDiff : Bool!
    @IBOutlet weak var bestProfs: UIButton!
    @IBOutlet weak var easiestProfs: UIButton!
    @IBOutlet weak var noSubmissionsLabel: UILabel!
    
    var profsDepsDict = [[String] : [String]]()
    var depsList2 = [String]()
    var profsAndDeps = [String]()
    var psSplitUpNames = [[String]]()
    var classes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        
        department!.text = text
        department.adjustsFontSizeToFitWidth = true
        
        ref = Database.database().reference()
        profList = setProfs(text: text)
        
        for prof in profList {
            getRatings(p: prof)
        }
        
        network.reachability.whenUnreachable = { reachability in
            self.showOfflinePage()
        }
        
        self.tblRates.addSubview(self.refreshControl)
        ratesOrDiff = true
        setUpFilterButtons()
        tblRates.isHidden = true
        noSubmissionsLabel.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is BrowseProfsViewController
        {
            let vc = segue.destination as? BrowseProfsViewController
            vc?.text = chosenProf
            vc?.profsDepsDict = profsDepsDict
        }
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
    
    // refresh table
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        refreshControl.attributedTitle = NSMutableAttributedString(string: "Fetching Professors ...")
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        ratesOrDiff = true
        setUpFilterButtons()
        self.ratesList.removeAll()
        for prof in profList {
            getRatings(p: prof)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.tblRates.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    func getRatings(p: String) {
        let p2 = p.replacingOccurrences(of: ".", with: "")
        self.ref?.child("Ratings/" + p2).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.childrenCount > 0 {
                var rates = [Double]()
                var difficulties = [Double]()
                var num = 0
                for x in snapshot.children.allObjects as! [DataSnapshot] {
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
                let r = self.getAverage(lst: rates)
                let d = self.getAverage(lst: difficulties)
                let r1 = TopRatesModel(rate1: r, prof1: p2, n: String(num))
                let d1 = TopRatesModel(rate1: d, prof1: p2, n: String(num))
                
                // ensure post has not been added
                var contains = false
                for i in self.ratesList {
                    if i.prof == p2 {
                        contains = true
                    }
                }
                
                if contains == false {
                    self.ratesList.append(r1)
                    
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
                    if i.prof == p2 {
                        contains2 = true
                    }
                }
                
                if contains2 == false {
                    self.difficultyList.append(d1)
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
                }
            }
        })
        ref?.removeAllObservers()
    }
    
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ratesOrDiff {
            return self.ratesList.count
        }
        return difficultyList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratesCell", for: indexPath) as! TopRatingsTableViewCell
        let rateModel: TopRatesModel
        
        if ratesOrDiff {
            if indexPath.row == 0 {
                tblRates.isHidden = false
                noSubmissionsLabel.isHidden = true
            }
            
            rateModel = ratesList[indexPath.row]
            
            cell.prof.text = rateModel.prof
            cell.rate.text = rateModel.rate
            cell.number.text = "(" + rateModel.num! + ")"
            if let rate = cell.rate.text, let dubRate = Double(rate) {
                if dubRate >= 4.0 {
                    cell.prof.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                    cell.rate.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                    cell.number.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                }
                else if dubRate <= 2.0 {
                    cell.prof.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                    cell.rate.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                    cell.number.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                }
                else {
                    cell.prof.textColor = UIColor.black
                    cell.rate.textColor = UIColor.black
                    cell.number.textColor = UIColor.black
                }
            }
            
        }
        else {
            if indexPath.row == 0 {
                tblRates.isHidden = false
                noSubmissionsLabel.isHidden = true
            }
            
            rateModel = difficultyList[indexPath.row]
            
            cell.prof.text = rateModel.prof
            cell.rate.text = rateModel.rate
            cell.number.text = "(" + rateModel.num! + ")"
            if let rate = cell.rate.text, let dubRate = Double(rate) {
                if dubRate >= 4.0 {
                    cell.prof.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                    cell.rate.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                    cell.number.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
                }
                else if dubRate <= 2.0 {
                    cell.prof.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                    cell.rate.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                    cell.number.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
                }
                else {
                    cell.prof.textColor = UIColor.black
                    cell.rate.textColor = UIColor.black
                    cell.number.textColor = UIColor.black
                }
            }
        }
       
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ratesOrDiff {
            chosenProf = ratesList[indexPath.row].prof
        }
        else {
            chosenProf = difficultyList[indexPath.row].prof
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "toProfs", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func setProfs(text: String) -> [String] {
        for keys in depsList.keys {
            if text == keys {
                return convertProfs(ps: depsList[keys]!)
            }
        }
        return ["ERROR"]
    }
    
    func convertProfs(ps: [[String]]) -> [String] {
        var newLst = [String]()
        for p in ps {
            newLst.append(p[1] + ", " + p[0])
        }
        return newLst
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
    
}
