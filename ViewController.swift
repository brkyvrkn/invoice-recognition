//
//  ViewController.swift
//
//  Created by Berkay Vurkan on 08/08/2017.
//  Copyright © 2017 Berkay Vurkan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let cvWrapper = OpenCVWrapper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cvWrapper.isWorking()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

}
