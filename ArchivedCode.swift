//
//  ArchivedCode.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 1/15/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import Foundation
func parseHTMLDeps(html: String) -> Void {
    var depsList = [String]()
    do {
        let doc = try Kanna.HTML(html: html, encoding: String.Encoding.utf8)
        // Search for nodes by CSS selector
        for p in doc.css("div[class^='item']") {
            depsList.append(p.text!)
        }
    }
    catch {
        print("error")
    }
    
    var depsFinal = [String]()
    for i in depsList {
        if i.contains("\n") {
            // do nothing
        }
        else {
            if i.contains("Department") {
                let p = i.replacingOccurrences(of: " Department", with: "")
                depsFinal.append(p)
            }
            else if i.contains("Program") {
                let p = i.replacingOccurrences(of: " Program", with: "")
                depsFinal.append(p)
            }
                
            else {
                depsFinal.append(i)
            }
        }
    }
    self.depData = depsFinal
    self.typePickerView.reloadAllComponents()
}

func parseHTMLProfs(html: String) -> Void {
    var profsList = [String]()
    do {
        let doc = try Kanna.HTML(html: html, encoding: String.Encoding.utf8)
        // Search for nodes by CSS selector
        for p in doc.css("h3[class^='altheader']") {
            profsList.append(p.text!)
        }
    }
    catch {
        print("error")
    }
    var finalProfs = [[String]]()
    for i in profsList {
        let lines = i.components(separatedBy: CharacterSet.newlines)
        var names = [String]()
        for x in lines {
            if x == "" {
                // do nothing
            }
            else {
                let n =  x.trimmingCharacters(in: .whitespacesAndNewlines)
                names.append(n)
            }
        }
        finalProfs.append(names)
    }
    self.professors = finalProfs
}
