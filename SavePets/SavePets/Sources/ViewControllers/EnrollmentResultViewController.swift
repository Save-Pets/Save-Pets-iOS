//
//  EnrollmentResultViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit

class EnrollmentResultViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var dogImageView: UIImageView!
    @IBOutlet weak var dogEnrollmentNumberLabel: UILabel!
    @IBOutlet weak var dogNameLabel: UILabel!
    @IBOutlet weak var dogBirthYearLabel: UILabel!
    @IBOutlet weak var dogGenderLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    
    // MARK: - Variables
    
    
    // View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeEnrollmentResultViewController()
    }
    
    
    // Functions
    
    private func popToHomeViewController() {
        guard let homeViewController = self.navigationController?.viewControllers.filter({ $0 is HomeViewController}).first as? HomeViewController else {
            return
        }
        
        self.navigationController?.popToViewController(homeViewController, animated: true)
    }
    
    private func initializeEnrollmentResultViewController() {
        self.dogImageView.roundUp(radius: 12)
        self.homeButton.roundUp(radius: 12)
    }
    
    @IBAction func homeButtonTouchUp(_ sender: UIButton) {
        self.popToHomeViewController()
    }
}
