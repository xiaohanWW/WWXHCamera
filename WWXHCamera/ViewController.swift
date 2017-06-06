//
//  ViewController.swift
//  WWXHCamera
//
//  Created by 魏武 on 2017/5/27.
//  Copyright © 2017年 weiwu. All rights reserved.
//

import UIKit

class ViewController: UIViewController,WWXHCameraViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cameraViewController(_: WWXHCameraViewController, didFinishPickingImage image: UIImage) {
        // 这里获取到图片 然后可以做些操作...
    }
    
}

