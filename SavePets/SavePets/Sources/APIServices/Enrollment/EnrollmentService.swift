//
//  SearchingService.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation
import Alamofire

struct EnrollmentService {
    
    static let shared = EnrollmentService()
    
    func postEnrollment (
        ownerName: String,
        phoneNumber: String,
        email: String,
        dogName: String,
        dogBreed: String,
        dogBirthYear: String,
        dogSex: String,
        dogProfileImage: UIImage,
        firstDogNoseImage: UIImage,
        secondDogNoseImage: UIImage,
        thirdDogNoseImage: UIImage,
        firthDogNoseImage: UIImage,
        fifthDogNoseImage: UIImage,
        completion: @escaping (NetworkResult<Any>) -> Void
    ) {
        let url = APIConstants.enrollmentURL
        let header: HTTPHeaders = [
            "Content-type": "multipart/form-data"
        ]
        
        let params: Parameters = [
            "registrant": ownerName,
            "phoneNum": phoneNumber,
            "email": email,
            "dogName": dogName,
            "dogBreed": dogBreed,
            "dogBirthYear": dogBirthYear,
            "dogSex": dogSex
        ]
        
        let dataRequest = AF.upload(multipartFormData: { multipartFormData in
            let cropSize = CGSize(width: 640, height: 640)
            guard let compressedProfileImage = dogProfileImage.crop(to: cropSize).jpegData(compressionQuality: 0.5),
            let compressedFirstDogNoseImage = firstDogNoseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7),
            let compressedSecondDogNoseImage = secondDogNoseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7),
            let compressedThirdDogNoseImage = thirdDogNoseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7),
            let compressedFirthDogNoseImage = firthDogNoseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7),
            let compressedFifthDogNoseImage = fifthDogNoseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7) else {
                return
            }
            multipartFormData.append(compressedProfileImage, withName: "dogProfile", fileName: "profile.jpeg", mimeType: "image/jpeg")
            multipartFormData.append(compressedFirstDogNoseImage, withName: "dogNose1", fileName: "firstDogNoseImage.jpeg", mimeType: "image/jpeg")
            multipartFormData.append(compressedSecondDogNoseImage, withName: "dogNose2", fileName: "secondDogNoseImage.jpeg", mimeType: "image/jpeg")
            multipartFormData.append(compressedThirdDogNoseImage, withName: "dogNose3", fileName: "thirdDogNoseImage.jpeg", mimeType: "image/jpeg")
            multipartFormData.append(compressedFirthDogNoseImage, withName: "dogNose4", fileName: "firthDogNoseImage.jpeg", mimeType: "image/jpeg")
            multipartFormData.append(compressedFifthDogNoseImage, withName: "dogNose5", fileName: "fifthDogNoseImage.jpeg", mimeType: "image/jpeg")
            
            for (key, value) in params {
                guard let safeValue = value as? String else { return }
                guard let safeValueData = safeValue.data(using: String.Encoding.utf8) else { return }
                multipartFormData.append(safeValueData, withName: key)
            }
            
        }, to: url, method: .post, headers: header)
        
        dataRequest.responseData { response in
            switch response.result {
            case .success:
                guard let statusCode = response.response?.statusCode, let data = response.value else {
                    return
                }
                let networkResults: NetworkResult<Any> = judgeEnrollment(status: statusCode, data: data)
                completion(networkResults)
            case .failure:
                completion(.networkFail)
            }
        }
    }
    
    private func judgeEnrollment(status: Int, data: Data) -> NetworkResult<Any> {
        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode(GenericResponse<EnrollmentResult>.self, from: data) else {
            return .pathErr
        }
        switch status {
        case 200:
            guard let unwrappedData = decodedData.data else {
                guard let unwrappedMessage = decodedData.message else {
                    return .serverErr
                }
                return .success(unwrappedMessage)
            }
            return .success(unwrappedData)
        case 400...500:
            return .serverErr
        default:
            return .networkFail
        }
    }
}
