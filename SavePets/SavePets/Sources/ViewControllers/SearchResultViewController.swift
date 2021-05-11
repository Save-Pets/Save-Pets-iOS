//
//  SearchResultViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit

class SearchResultViewController: UIViewController {

    // IBOutlets
    
    @IBOutlet weak var dogImageView: UIImageView!
    @IBOutlet weak var enrollmentNumberLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var ownerPhoneNumberLabel: UILabel!
    @IBOutlet weak var ownerEmailLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var coincidenceRateLabel: UILabel!
    
    // View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeSearchResultViewController()
    }
    
    
    // Functions
    
    private func initializeSearchResultViewController() {
        self.dogImageView.roundUp(radius: 12)
        self.homeButton.roundUp(radius: 12)
    }
    
    private func popToHomeViewController() {
        guard let homeViewController = self.navigationController?.viewControllers.filter({ $0 is HomeViewController}).first as? HomeViewController else {
            return
        }
        
        self.navigationController?.popToViewController(homeViewController, animated: true)
    }
    
    @IBAction func homeButtonTouchUp(_ sender: UIButton) {
        self.popToHomeViewController()
    }
}
