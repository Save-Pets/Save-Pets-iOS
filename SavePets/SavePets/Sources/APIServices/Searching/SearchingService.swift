//
//  EnrollmentService.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation
import Alamofire

struct SearchingService {
    
    static let shared = SearchingService()
    
    func postSearching (
        noseImage: UIImage,
        completion: @escaping (NetworkResult<Any>) -> Void
    ) {
        let url = APIConstants.searchingURL
        let header: HTTPHeaders = [
            "Content-type": "multipart/form-data"
        ]
        
        let dataRequest = AF.upload(multipartFormData: { multipartFormData in
            let cropSize = CGSize(width: 640, height: 640)
            guard let compressedNoseImage = noseImage.crop(to: cropSize).jpegData(compressionQuality: 0.7) else {
                return
            }
            multipartFormData.append(compressedNoseImage, withName: "dogNose", fileName: "dogNose.jpeg", mimeType: "image/jpeg")
        }, to: url, method: .post, headers: header)
        
        dataRequest.responseData { response in
            switch response.result {
            case .success:
                guard let statusCode = response.response?.statusCode, let data = response.value else {
                    return
                }
                let networkResults: NetworkResult<Any> = judgeSearching(status: statusCode, data: data)
                completion(networkResults)
            case .failure:
                completion(.networkFail)
            }
        }
    }
    
    private func judgeSearching(status: Int, data: Data) -> NetworkResult<Any> {
        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode(GenericResponse<SearchingResult>.self, from: data) else {
            return .pathErr
        }
        switch status {
        case 200:
            guard let unwrappedData = decodedData.data else { return .serverErr }
            return .success(unwrappedData)
        case 400...500:
            return .serverErr
        default:
            return .networkFail
        }
    }
}
