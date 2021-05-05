//
//  OwnerProfileViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/04.
//

import UIKit

class OwnerProfileViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var ownerNameView: UIView!
    @IBOutlet weak var ownerNameTextField: UITextField!
    @IBOutlet weak var ownerPhoneNumberView: UIView!
    @IBOutlet weak var ownerPhoneNumberTextField: UITextField!
    @IBOutlet weak var ownerEmailView: UIView!
    @IBOutlet weak var ownerEmailTextField: UITextField!
    @IBOutlet weak var enrollmentButton: UIButton!
    
    // MARK: - Variables
    
    private var ownerName: String?
    private var ownerPhoneNumber: String?
    private var ownerEmail: String?
    private weak var enrollmentLoadingViewController: EnrollmentLoadingViewController?
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeOwnerProfileViewController()
        self.initializeTextFieldView()
    }
    
    // MARK: - Functions
    
    private func initializeOwnerProfileViewController() {
        self.enrollmentButton.roundUp(radius: 12)
        self.ownerNameView.roundUp(radius: 12)
        self.ownerPhoneNumberView.roundUp(radius: 12)
        self.ownerEmailView.roundUp(radius: 12)
        
        self.disableEnrollmentButton()
        self.ownerNameView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.ownerPhoneNumberView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.ownerEmailView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
    }
    
    private func initializeTextFieldView() {
        self.ownerNameTextField.delegate = self
        self.ownerPhoneNumberTextField.delegate = self
        self.ownerEmailTextField.delegate = self
    }
    
    private func enableEnrollmentButton() {
        self.enrollmentButton.isEnabled = true
        self.enrollmentButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableEnrollmentButton() {
        self.enrollmentButton.isEnabled = false
        self.enrollmentButton.backgroundColor = UIColor.lightGray
    }
        
    private func presentEnrollmentLoadingViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let enrollmentLoadingViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.enrollmentLoadingViewController) as? EnrollmentLoadingViewController else {
            return
        }
        
        self.enrollmentLoadingViewController = enrollmentLoadingViewController
        enrollmentLoadingViewController.ownerName = self.ownerName
        enrollmentLoadingViewController.dogName = "뽀삐"
        enrollmentLoadingViewController.modalPresentationStyle = .fullScreen
        
        present(enrollmentLoadingViewController, animated: true, completion: nil)
    }
    
    private func pushToEnrollmentResultViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let enrollmentResultViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.enrollmentResultViewController) as? EnrollmentResultViewController else {
            return
        }
        
        self.navigationController?.pushViewController(enrollmentResultViewController, animated: true)
    }
    
    private func verifyProperty(_ name: String?) -> Bool {
        guard let unwrappedName = name else { return false }
        return !unwrappedName.isEmpty
    }
    
    private func verify() -> Bool {
        return self.verifyProperty(self.ownerName) && self.verifyProperty(self.ownerPhoneNumber) && self.verifyProperty(self.ownerEmail)
    }
    
    private func updateEnrollmentButton() {
        let isVerified = self.verify()
        isVerified ? self.enableEnrollmentButton() : self.disableEnrollmentButton()
    }

    @IBAction func enrollmentButtonTouchUp(_ sender: UIButton) {
        
        // 로딩화면 띄우기
        self.presentEnrollmentLoadingViewController()
        
        // TODO: - 서버로 등록 API 요청 보내기
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            // 로딩화면 종료
            self.enrollmentLoadingViewController?.dismiss(animated: true, completion: nil)
            // 결과 화면으로 넘어가기
            self.pushToEnrollmentResultViewController()
        })
        
    }
    
}

// MARK: - TextFieldDelegate

extension OwnerProfileViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField.isEqual(self.ownerNameTextField) {
            self.ownerName = self.ownerNameTextField.text
        } else if textField.isEqual(self.ownerPhoneNumberTextField) {
            self.ownerPhoneNumber = self.ownerPhoneNumberTextField.text
        } else {
            self.ownerEmail = self.ownerEmailTextField.text
        }
        self.updateEnrollmentButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(self.ownerNameTextField) {
            self.ownerName = self.ownerNameTextField.text
            self.ownerPhoneNumberTextField.becomeFirstResponder()
        } else if textField.isEqual(self.ownerPhoneNumberTextField) {
            self.ownerPhoneNumber = self.ownerPhoneNumberTextField.text
            self.ownerEmailTextField.becomeFirstResponder()
        } else {
            self.ownerEmail = self.ownerEmailTextField.text
            self.ownerEmailTextField.resignFirstResponder()
        }
        self.updateEnrollmentButton()
        textField.resignFirstResponder()
        return true
    }
}
