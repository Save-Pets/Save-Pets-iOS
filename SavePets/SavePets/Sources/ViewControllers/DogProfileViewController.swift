//
//  DogProfileViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/04.
//

import UIKit
import Presentr

class DogProfileViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileChangeButton: UIButton!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var breedButton: UIButton!
    @IBOutlet weak var birthYearButton: UIButton!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Variables
    var enrollment: Enrollment?
    private var imagePicker: UIImagePickerController?
    private var profileImage: UIImage?
    private var name: String?
    private var breed: String?
    private var birthYear: String?
    private var gender: String?
    private let presenter: Presentr = {
        let customPresenter = Presentr(presentationType: PresentationType.bottomHalf)
        customPresenter.roundCorners = true
        customPresenter.cornerRadius = 12
        return customPresenter
    }()
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeDogProfileViewController()
        self.initializeImagePickerView()
        self.initializeNavigationBar()
        self.initializeTextFieldView()
    }
    
    // MARK: - Functions
    
    private func initializeDogProfileViewController() {
        self.profileImageView.roundUp(radius: self.profileImageView.frame.height/2)
        self.nameView.roundUp(radius: 12)
        self.saveButton.roundUp(radius: 12)
        self.breedButton.roundUp(radius: 12)
        self.birthYearButton.roundUp(radius: 12)
        self.genderButton.roundUp(radius: 12)
        
        self.disableSaveButton()
        self.profileImageView.setBorder(color: UIColor.systemOrange.cgColor, width: 3)
        self.nameView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.breedButton.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.birthYearButton.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.genderButton.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
    }
    
    private func initializeTextFieldView() {
        self.nameTextField.delegate = self
    }
    
    private func initializeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.navigationItem.backButtonTitle = "뒤로가기"
    }
    
    private func initializeImagePickerView() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.sourceType = .photoLibrary
        self.imagePicker?.allowsEditing = true
        self.imagePicker?.delegate = self
    }
    
    private func presentImagePickerViewController() {
        guard let imagePicker = self.imagePicker else { return }
        imagePicker.modalPresentationStyle = .automatic
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func pushToOwnerProfileViweController() {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let ownerProfileViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.ownerProfileViewController) as? OwnerProfileViewController else {
            return
        }
        
        guard let profile = self.profileImage, let name = self.name, let breed = self.breed, let birthYear = self.birthYear, let sex = self.gender else { return }
        
        ownerProfileViewController.enrollment = Enrollment(
            owner: nil,
            dog: Dog(profile: profile, name: name, breed: breed, birthYear: birthYear, sex: sex),
            firstImage: self.enrollment?.firstImage,
            secondImage: self.enrollment?.secondImage,
            thirdImage: self.enrollment?.thirdImage,
            firthImage: self.enrollment?.firthImage,
            fifthImage: self.enrollment?.fifthImage
        )
        self.navigationController?.pushViewController(ownerProfileViewController, animated: true)
    }
    
    private func enableSaveButton() {
        self.saveButton.isEnabled = true
        self.saveButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableSaveButton() {
        self.saveButton.isEnabled = false
        self.saveButton.backgroundColor = UIColor.lightGray
    }
    
    private func updateSaveButton() {
        let isVerified = self.verify()
        isVerified ? self.enableSaveButton() : self.disableSaveButton()
    }
    
    private func verifyProperty(_ property: Any?) -> Bool {
        guard let _ = property else { return false }
        return true
    }
    
    private func verifyNameProperty(_ name: String?) -> Bool {
        guard let unwrappedName = name else { return false }
        return !unwrappedName.isEmpty
    }
    
    private func verify() -> Bool {
        return self.verifyNameProperty(self.name) && self.verifyProperty(self.breed) && self.verifyProperty(self.birthYear) && self.verifyProperty(self.gender) && self.verifyProperty(self.profileImage)
    }
    
    
    private func presentModalViewController(usage: ModalViewUsage) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let modalViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.modalViewController) as? ModalViewController else {
            return
        }
        
        modalViewController.modalViewUsage = usage
        modalViewController.modalViewControllerDelegate = self
        
        customPresentViewController(presenter, viewController: modalViewController, animated: true, completion: nil)
    }
    
    @IBAction func profileChangeButtonTouchUp(_ sender: UIButton) {
        self.presentImagePickerViewController()
    }
    
    @IBAction func breedButtonTouchUp(_ sender: UIButton) {
        self.presentModalViewController(usage: .breed)
    }
        
    @IBAction func birthYearButtonTouchUp(_ sender: UIButton) {
        self.presentModalViewController(usage: .birthYear)
    }
    @IBAction func genderButtonTouchUp(_ sender: UIButton) {
        self.presentModalViewController(usage: .gender)
    }
    @IBAction func saveButtonTouchUp(_ sender: UIButton) {
        self.pushToOwnerProfileViweController()
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension DogProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var pickedImage: UIImage?
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            pickedImage = image
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            pickedImage = image
        }
        
        self.profileImageView.image = pickedImage
        self.profileImage = pickedImage
        self.updateSaveButton()
        self.imagePicker?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TextFieldDelegate

extension DogProfileViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.name = textField.text
        self.updateSaveButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.name = textField.text
        self.updateSaveButton()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - ModalViewControllerDelegate

extension DogProfileViewController: ModalViewControllerDelegate {
    func selectPickerView(selection: String, usage: ModalViewUsage) {
        switch usage {
        case .breed:
            self.breedButton.setTitle(selection, for: .normal)
            self.breedButton.setTitleColor(UIColor.black, for: .normal)
            self.breed = selection
        case .birthYear:
            self.birthYearButton.setTitle(selection, for: .normal)
            self.birthYearButton.setTitleColor(UIColor.black, for: .normal)
            self.birthYear = selection
        case .gender:
            self.genderButton.setTitle(selection, for: .normal)
            self.genderButton.setTitleColor(UIColor.black, for: .normal)
            self.gender = selection
        }
        self.updateSaveButton()
    }
}
