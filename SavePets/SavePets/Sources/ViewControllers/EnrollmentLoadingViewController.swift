//
//  EnrollmentLoadingViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit

class EnrollmentLoadingViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var onwerNameLabel: UILabel!
    @IBOutlet weak var dogNameLabel: UILabel!
    
    // MARK: - Variables
    
    var ownerName: String?
    var dogName: String?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeEnrollmentLoadingViewController()
    }
    
    private func initializeEnrollmentLoadingViewController() {
        self.onwerNameLabel.text = ownerName
        self.dogNameLabel.text = dogName
    }

}
