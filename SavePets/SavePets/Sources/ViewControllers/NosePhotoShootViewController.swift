//
//  NosePhotoShootViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit

class NosePhotoShootViewController: UIViewController {

    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initializeNavigationBar()
    }
    
    // MARK: - Functions

    private func initializeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }

}
