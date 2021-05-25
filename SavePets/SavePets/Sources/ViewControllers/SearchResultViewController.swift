//
//  SearchResultViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit

class SearchResultViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var dogImageView: UIImageView!
    @IBOutlet weak var profileStackView: UIStackView!
    @IBOutlet weak var enrollmentNumberLabel: UILabel!
    @IBOutlet weak var dogNameLabel: UILabel!
    @IBOutlet weak var dogBreedLabel: UILabel!
    @IBOutlet weak var dogBirthYearLabel: UILabel!
    @IBOutlet weak var dogSexLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var ownerPhoneNumberLabel: UILabel!
    @IBOutlet weak var ownerEmailLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var matchRateLabel: UILabel!
    @IBOutlet weak var matchInfoLabel: UILabel!
    
    
    // MARK: - Variables
    
    var searchingResult: SearchingResult?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeSearchResultViewController()
    }
    
    
    // MARK: - Functions
    
    private func initializeSearchResultViewController() {
        self.dogImageView.roundUp(radius: 12)
        self.homeButton.roundUp(radius: 12)
        
        guard let isSuccess = self.searchingResult?.isSuccess else { return }
        
        if isSuccess {
            self.updateDogInfo(enrollmentNumber: self.searchingResult?.dogRegistNum, name: self.searchingResult?.dogName, breed: self.searchingResult?.dogBreed, birthYear: self.searchingResult?.dogBirthYear, sex: self.searchingResult?.dogSex, imageURL: self.searchingResult?.dogProfile)
            self.updateOwnerInfo(ownerName: self.searchingResult?.registrant, phoneNumber: self.searchingResult?.phoneNum, email: self.searchingResult?.email)
            self.updateMatchInfo(matchRate: self.searchingResult?.matchRate, message: "일치합니다")
        } else {
            self.removeDogImageView()
            self.removeProfileStackView()
            self.hideMatchRateLabel()
            self.matchInfoLabel.text = "조회된 반려견이\n없습니다"
        }
    }
    
    private func removeDogImageView() {
        self.dogImageView.removeFromSuperview()
    }
    
    private func removeProfileStackView() {
        self.profileStackView.removeFromSuperview()
    }
    
    private func hideMatchRateLabel() {
        self.matchRateLabel.isHidden = true
    }
    
    private func updateDogInfo(enrollmentNumber: String?, name: String?, breed: String?, birthYear: String?, sex: String?, imageURL: String?) {
        
        self.enrollmentNumberLabel.text = enrollmentNumber
        self.dogNameLabel.text = name
        self.dogBreedLabel.text = breed
        self.dogBirthYearLabel.text = birthYear
        self.dogSexLabel.text = sex
        
        
        guard let safeEnrollmentNumber = enrollmentNumber else {
            return
        }
        guard let dogImageURL = URL(string: APIConstants.baseURL + "/static/img/" + safeEnrollmentNumber + ".jpg") else { return }
        self.dogImageView.imageDownload(url: dogImageURL, contentMode: .scaleAspectFill)
    }
    
    private func updateOwnerInfo(ownerName: String?, phoneNumber: String?, email: String?) {
        self.ownerLabel.text = ownerName
        self.ownerPhoneNumberLabel.text = phoneNumber
        self.ownerEmailLabel.text = email
    }
    
    private func updateMatchInfo(matchRate: String?, message: String) {
        guard let safeMatchRate = matchRate else { return }
        self.matchRateLabel.text = "\(safeMatchRate)%"
        self.matchInfoLabel.text = message
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
