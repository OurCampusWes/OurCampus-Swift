//
//  scrapeProfs.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 3/11/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//
//

//
//    func foo() {
//        let image = ""
//
//
//        let missingUpdate = ["image": image]
//        ref = Database.database().reference()
//
//
//        self.ref?.child("Advertise/Current").updateChildValues(missingUpdate as [AnyHashable : Any])
//    }

//    func scrapeProfs() -> Void {
//        Alamofire.request("https://www.wesleyan.edu/academics/faculty/facultybyname.html").responseString { response in
//            print("\(response.result.isSuccess)")
//            if let html = response.result.value {
//                self.progressHUD.text = "Loading Reviews .."
//                self.parseHTMLProfs(html: html)
//            }
//        }
//    }
//
//    func scrapeDepProfs() -> Void {
//        Alamofire.request("https://www.wesleyan.edu/academics/faculty/facultybydepartment.html").responseString { response in
//            print("\(response.result.isSuccess)")
//            if let html = response.result.value {
//                self.progressHUD.text = "Finding Professors .."
//                self.parseHTMLDepProfs(html: html)
//            }
//        }
//    }
//
//    func parseHTMLDepProfs(html: String) -> Void {
//        var depsDict = [String: [String]]()
//        var dept_names = [String]()
//        var prof_names = [String]()
//        do {
//            let doc = try Kanna.HTML(html: html, encoding: String.Encoding.utf8)
//            let rows = doc.xpath("//div[@class='row']")
//            for r in rows {
//                let d = r.at_xpath("div/h2[@class='altheader']")
//                if d?.text!.count == 0 || d == nil {
//                    //dept_names.append("")
//                }
//                else {
//                    if (d?.text!.contains("Department"))! {
//                        let p = d?.text!.replacingOccurrences(of: " Department", with: "")
//                        dept_names.append(p!)
//                    }
//                    else if (d?.text!.contains("Program"))! {
//                        let p = d?.text!.replacingOccurrences(of: " Program", with: "")
//                        dept_names.append(p!)
//                    }
//                    else {
//                        dept_names.append((d?.text)!)
//                    }
//                }
//            }
//            for r in rows {
//                let p = r.at_xpath("div/div/h3[@class='altheader']/a")
//                let p2 = r.at_xpath("div[2]/div/h3[@class='altheader']/a")
//                if p?.text!.count == 0 || p == nil {
//                    prof_names.append("**********DEP**********")
//                }
//                else {
//                    if (p?.text?.contains("Ã"))! {
//                        //print(p?.text)
//
//                    }
//                    else {
//                        prof_names.append((p?.text)!)
//                    }
//                }
//                if p2?.text!.count == 0 || p2 == nil {
//                    // do nothing
//                }
//                else {
//                    if (p2?.text?.contains("Ã"))! {
//                       //print(p2?.text)
//                    }
//                    else {
//                        prof_names.append((p2?.text)!)
//                    }
//                }
//            }
//            var dep = dept_names[0]
//            var whichDept = 1
//            prof_names.removeFirst(3)
//
//            for p in prof_names {
//                if p != "**********DEP**********" {
//                    if depsDict[dep] == nil {
//                        depsDict[dep] = [p]
//                    }
//                    // remove special char names
//                    else if p.contains("Ã") {
//                        depsDict[dep] = depsDict[dep]!
//                    }
//                    else {
//                        depsDict[dep] = depsDict[dep]! + [p]
//                    }
//                }
//                else {
//                    if whichDept > dept_names.count - 1 {
//                        break
//                    }
//                    else {
//                        dep = dept_names[whichDept]
//                        whichDept = whichDept + 1
//                    }
//                }
//            }
//        }
//        catch {
//            print("Error getting Wesleyan website")
//        }
//        var depsDictCorrect = [String: [[String]]]()
//        for i in depsDict {
//            let v = i.value
//            var separated = [[String]]()
//            for j in v {
//                let lines = j.components(separatedBy: CharacterSet.newlines)
//                var names = [String]()
//                for x in lines {
//                    if x == "" {
//                        // do nothing
//                    }
//                    else {
//                        let n =  x.trimmingCharacters(in: .whitespacesAndNewlines)
//                        names.append(n)
//                    }
//                }
//                separated.append(names)
//            }
//            depsDictCorrect[i.key] = separated
//        }
//        self.depsProfsDict = depsDictCorrect
//
//        // get other lists
//
//        // departments
//        var depsLst = [String]()
//        for i in depsProfsDict {
//            depsLst.append(i.key)
//        }
//        depsLst.sort()
//        self.depData = depsLst
//
//        // professors
//        var profsLst = [[String]]()
//        for i in depsProfsDict {
//            for p in i.value {
//                profsLst.append(p)
//            }
//        }
//        let unique = Array(Set(profsLst))
//
//        self.professors = unique
//
//        var profDict = [[String]: [String]]()
//        // professor-department dictionary
//        for p in unique {
//            profDict[p] = []
//            for i in depsDictCorrect {
//                if i.value.contains(p) {
//                    if profDict[p] == nil {
//                        profDict[p] = [i.key]
//                    }
//                    else {
//                        profDict[p] = profDict[p]! + [i.key]
//                    }
//                }
//            }
//        }
//        self.profDepsDict = profDict
//    }
//
//    func parseHTMLProfs(html: String) -> Void {
//        var profsList = [String]()
//        do {
//            let doc = try Kanna.HTML(html: html, encoding: String.Encoding.utf8)
//            // Search for nodes by CSS selector
//            for p in doc.css("h3[class^='altheader']") {
//                profsList.append(p.text!)
//            }
//        }
//        catch {
//            print("error")
//        }
//        var finalProfs = [[String]]()
//        for i in profsList {
//            let lines = i.components(separatedBy: CharacterSet.newlines)
//            var names = [String]()
//            for x in lines {
//                if x == "" {
//                    // do nothing
//                }
//                else {
//                    let n =  x.trimmingCharacters(in: .whitespacesAndNewlines)
//                    names.append(n)
//                }
//            }
//            finalProfs.append(names)
//        }
//        let unique = Array(Set(finalProfs + professors))
//        // remove special char names
//        var unique2 = [[String]]()
//        for i in unique {
//            var weirdChar = false
//            for name in i {
//                if name.contains("Ã") {
//                    weirdChar = true
//                }
//            }
//            if !weirdChar {
//                unique2.append(i)
//            }
//        }
//
//        // add special character professors
//        unique2.append(["Blümel", "Reinhold"])
//        unique2.append(["Lutz", "Hüwel"])
//        unique2.append(["Valeria", "López Fadul"])
//        unique2.append(["Laverne", "Melón"])
//        unique2.append(["Ákos", "Östör"])
//        unique2.append(["Marcela", "Oteíza"])
//        unique2.append(["Stéphanie", "Ponsavady"])
//        unique2.append(["Felipe", "Ramírez"])
//        unique2.append(["Khachig", "Tölölyan"])
//
//        finalProfessorsList = unique2
//
//        //print(depData)
//        //print(finalProfessorsList)
//        //print(depsProfsDict)
//        //print(profDepsDict)
//    }
