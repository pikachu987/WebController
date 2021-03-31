//
//  ViewController.swift
//  WebController
//
//  Created by pikachu987 on 09/27/2018.
//  Copyright (c) 2018 pikachu987. All rights reserved.
//

import UIKit
import WebController

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.navigationBar.isTranslucent = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.barTintColor = .white
    }
    
    @IBAction func showSimple(_ sender: UIButton) {
        let webController = WebController()
        webController.load("http://www.apple.com")
        self.navigationController?.pushViewController(webController, animated: true)
    }
    
    @IBAction func showCustom(_ sender: UIButton) {
        let webController = WebController()
        webController.delegate = self
        webController.toolView.setBackBarButtonItem(UIImage(named: "icBack"))
        webController.toolView.setForwardBarButtonItem(UIImage(named: "icFront"))
        webController.toolView.tintColor = .white
        webController.toolView.barTintColor = UIColor.black
        webController.toolView.toolbar.isTranslucent = false
        webController.barTintColor = .black
        webController.titleTintColor = .white
        webController.progressView.trackTintColor = .white
        webController.progressView.progressTintColor = .black
        webController.indicatorView.color = .white
        webController.load("https://www.google.com")
        self.navigationController?.pushViewController(webController, animated: true)
    }
}

// MARK: WebControllerDelegate
extension ViewController: WebControllerDelegate {
    func webController(_ webController: WebController, error: Error) {
        print("error: \(error)")
    }

    func webController(_ webController: WebController, didLoading: Bool) {
        print("didLoading: \(didLoading)")
    }

    func webController(_ webController: WebController, didChangeURL: URL?) {
        guard let didChangeURL = didChangeURL else { return }
        print("didChangeURL: \(didChangeURL)")
    }

    func webController(_ webController: WebController, didChangeTitle: String?) {
        guard let didChangeTitle = didChangeTitle else { return }
        print("didChangeTitle: \(didChangeTitle)")
    }

    func webController(_ webController: WebController, title: String?) -> String? {
        return title?.replacingOccurrences(of: " ▾", with: "")
    }
}
