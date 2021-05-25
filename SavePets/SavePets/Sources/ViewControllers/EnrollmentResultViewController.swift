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
    @IBOutlet weak var dogBreedLabel: UILabel!
    @IBOutlet weak var dogBirthYearLabel: UILabel!
    @IBOutlet weak var dogSexLabel: UILabel!
    @IBOutlet weak var resultInfoLabel: UILabel!
    @IBOutlet weak var resultInfo2Label: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    
    // MARK: - Variables
    
    var enrollmentResult: EnrollmentResult?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeEnrollmentResultViewController()
    }
    
    
    // MARK: - Functions
    
    private func initializeEnrollmentResultViewController() {
        self.dogImageView.roundUp(radius: 12)
        self.homeButton.roundUp(radius: 12)
        
        self.updateDogInfo(enrollmentNumber: self.enrollmentResult?.dogRegistNum, name: self.enrollmentResult?.dogName, breed: self.enrollmentResult?.dogBreed, birthYear: self.enrollmentResult?.dogBirthYear, sex: self.enrollmentResult?.dogSex, imageURL: self.enrollmentResult?.dogProfile)
        
        guard let isSuccess = self.enrollmentResult?.isSuccess else { return }
        if isSuccess {
            self.resultInfoLabel.text = "등록 완료"
            self.resultInfo2Label.text = "되었습니다"
        } else {
            self.resultInfoLabel.text = "이미 등록된"
            self.resultInfo2Label.text = "반려견 입니다"
        }
    }
    
    private func updateDogInfo(enrollmentNumber: String?, name: String?, breed: String?, birthYear: String?, sex: String?, imageURL: String?) {
        
        self.dogEnrollmentNumberLabel.text = enrollmentNumber
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
