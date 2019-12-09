//
//  SlideUpSegue.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 1/31/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class FirstCustomSegue: UIStoryboardSegue {
    override func perform() {
        let firstVCView = self.source.view as UIView?
        let secondVCView = self.destination.view as UIView?
        
        // Get the screen width and height.
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        // Specify the initial position of the destination view.
        let rect = CGRect(x: 0.0, y: -screenHeight, width: screenWidth, height: screenHeight)
        secondVCView!.frame = rect
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(secondVCView!, aboveSubview: firstVCView!)
        
        // Animate the transition.
        UIView.animate(withDuration: 2, animations: { () -> Void in
            
            firstVCView?.frame = (firstVCView?.frame.offsetBy(dx: 0.0, dy: screenHeight))!
            
            secondVCView!.frame = (secondVCView?.frame.offsetBy(dx: 0.0, dy: screenHeight))!
            
        }) { (Finished) -> Void in
            self.source.present(self.destination, animated: false, completion: nil)
        }
        
    }
}
