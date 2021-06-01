# 구해줘 펫즈, Save Pets

</br>

### 1. 데모 영상

[데모 영상 보러가기](https://user-images.githubusercontent.com/20268101/120226192-b0571980-c281-11eb-9c59-8288b7d655c1.mp4)





### 2. 서비스 소개

![savepets_main](https://user-images.githubusercontent.com/20268101/120218227-60258a80-c274-11eb-8f81-2abcfc561f43.png)



### 3. 주요 기술 및 설명

#### [Client]



</br>

* **iOS**
  * UIKit
  * GCD (DispatchSemaphore)
  * AVFoundation
  * Vision
  * CoreML

</br>



#### 1) 실시간 카메라 비문 인식 구현방법 - Vision & CoreML

카메라 Output으로 받아오는 sampleBuffer에서 반려견 비문을 실시간으로 검출하기 위해 Vision 라이브러리를 사용하였습니다. 

Vision 라이브러리에서 제공하는 VNCoreMLModel 은 CoreML 기반의 머신러닝/딥러닝 모델을 사용합니다. 

때문에 Vision 코드에서 머신러닝/딥러닝 모델을 사용하기 위해서는 기존 모델을 CoreML 형태의 모델로 변환시키거나,
처음부터 CoreML 형태로 학습시키는 방법이 있습니다. 

처음에는 Pytorch 로 학습된 YOLO 모델을 활용하여 전자의 방식대로 시도했지만 실제로 사용하는데에는 어려움이  있었고, 이후에는 후자의 방법으로 진행하였습니다.

정리하자면 Object Detection 모델인 YOLO 를 CoreML 형태로 학습하였고, 추출한 CoreML 모델(DogNoseDetector.mlmodel)을 Vision 라이브러리에 성공적으로 적용하였습니다.

또한 CoreML을 사용했기 때문에 온전히 모바일 컴퓨팅 파워를 사용하여 반려견의 코를 실시간으로 검출하게 되었습니다.

</br>



#### 2) 실시간 카메라 비문 인식 구현방법 - AVFoundation & Vision



<img src = "https://user-images.githubusercontent.com/20268101/120230863-2a3fd080-c28b-11eb-912c-68fc673f1bd6.png" width="40%"> 



비문 촬영을 위한 커스텀 카메라를 구현하기 위해 Apple Standard Library 에서 제공하는 AVFoundation 의 AVCaptureVideoDataOutputSampleBufferDelegate 를 사용하였습니다.

AVCaptureVideoDataOutputSampleBufferDelegate에서 제공하는 captureOutput 함수가 호출될 때, 카메라에서 받아오는 sampleBuffer는 VNImageRequestHandler 함수를 거치게 되며, 해당 함수에서는 이미지 내에서 반려견의 코를 탐지하는 작업을 처리하게 됩니다. 

정확하게는,  VNImageRequestHandler 함수는 VNCoreMLRequest 로 생성된 이미지 처리 request를 sampleBuffer에 적용하는 작업을 수행합니다. 

VNCoreMLRequest 객체를 생성할 때는 completionHandler 함수를 지정해줄 수 있는데, completionHandler 함수에서는 이미지 처리 결과값을 받아와 후처리 작업을 수행 할 수 있게 해줍니다. 

후 처리 작업에서는 결과값으로 받아온 반려견의 코와 콧구멍의 좌표(0~1 사이 값으로 정규화된 좌표)들을 활용하여 Detection Overlay Layer 위에 사각형 테두리들을 그려줍니다. 

또한 후 처리 작업을 수행할때마다 Detection Overlay Layer는 Preview Layer 위에서 계속 갱신됩니다.

</br>



#### 3) Vision 작업 스레드와 메인 스레드 간에 동기화 - DispatchSemaphore & Vision

NoseSelectionViewController에서는 유저가 선택한 여러 장의 비문 사진들이 조건에 부합하는지 (반려견의 코가 존재 하는지, 코가 너무 작지는 않은지) 검사하게 됩니다.

이미지가 조건에 부합하는지 검사하는 과정에는 VNImageRequestHandler 함수가 사용되는데, 이 때 비동기로 VNImageRequestHandler 작업을 수행하는 스레드와 UI 를 그려주는 메인 스레드간에 공통으로 사용되는 클래스 멤버 변수가 동기화되지 않는 문제가 발생합니다.

이 문제는 DispatchSemaphore에서 제공하는 wait과 signal 메소드를 사용하여 쉽게 해결 할 수 있었습니다.

</br>

![120224786-0bd3d800-c27f-11eb-8ea0-c09641ec1c96](https://user-images.githubusercontent.com/20268101/120224786-0bd3d800-c27f-11eb-8ea0-c09641ec1c96.png)

![120224781-07a7ba80-c27f-11eb-87a7-42e937193ef8](https://user-images.githubusercontent.com/20268101/120224781-07a7ba80-c27f-11eb-87a7-42e937193ef8.png)



#### [Back end]

* **Server**
  * Flask
  * MySQL
  * AWS
* **Machine Learning**
  * OpenCV
  * Scikit learn
  * Pytorch

</br>



### 4. UI/UX

#### 1) 비문 등록하기 (카메라/앨범선택)

|                                                              |                                                              |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![120216339-dbd20800-c271-11eb-80ee-12759a44ca35](https://user-images.githubusercontent.com/20268101/120216339-dbd20800-c271-11eb-80ee-12759a44ca35.png) | ![120221033-aaa90600-c278-11eb-8faa-5c04c2d6423c](https://user-images.githubusercontent.com/20268101/120221033-aaa90600-c278-11eb-8faa-5c04c2d6423c.png) | ![120216337-db397180-c271-11eb-9bba-159e554b4b57](https://user-images.githubusercontent.com/20268101/120216337-db397180-c271-11eb-9bba-159e554b4b57.png) |
| ![120222169-7cc4c100-c27a-11eb-8829-cb0041a7523e](https://user-images.githubusercontent.com/20268101/120222169-7cc4c100-c27a-11eb-8829-cb0041a7523e.png) | ![120216333-daa0db00-c271-11eb-8731-f9aac8700b00](https://user-images.githubusercontent.com/20268101/120216333-daa0db00-c271-11eb-8731-f9aac8700b00.png) |                                                              |
| ![120221032-a977d900-c278-11eb-90d1-5e506d9698e2](https://user-images.githubusercontent.com/20268101/120221032-a977d900-c278-11eb-90d1-5e506d9698e2.png) | ![120221031-a8df4280-c278-11eb-9006-e3f1b7b130b9](https://user-images.githubusercontent.com/20268101/120221031-a8df4280-c278-11eb-9006-e3f1b7b130b9.png) | ![120221025-a7ae1580-c278-11eb-9304-5273ac9b0523](https://user-images.githubusercontent.com/20268101/120221025-a7ae1580-c278-11eb-9304-5273ac9b0523.png) |
| ![120221008-a2e96180-c278-11eb-8ee0-fdcbd3a0805c](https://user-images.githubusercontent.com/20268101/120221008-a2e96180-c278-11eb-8ee0-fdcbd3a0805c.png) | ![120216326-da084480-c271-11eb-86f6-ea12f123956b](https://user-images.githubusercontent.com/20268101/120216326-da084480-c271-11eb-86f6-ea12f123956b.png) | ![120216323-d83e8100-c271-11eb-91b8-5e93db02a112](https://user-images.githubusercontent.com/20268101/120216323-d83e8100-c271-11eb-91b8-5e93db02a112.png) |
| ![120216311-d379cd00-c271-11eb-8aad-ccb193881ea1](https://user-images.githubusercontent.com/20268101/120216311-d379cd00-c271-11eb-8aad-ccb193881ea1.png) | ![120216353-deccf880-c271-11eb-8170-25b6087b977d](https://user-images.githubusercontent.com/20268101/120216353-deccf880-c271-11eb-8170-25b6087b977d.png) | ![120221828-058f2d00-c27a-11eb-8db7-3517c4f582b6](https://user-images.githubusercontent.com/20268101/120221828-058f2d00-c27a-11eb-8db7-3517c4f582b6.png) |



#### 2) 비문 조회하기 (카메라/앨범선택)

|                                                              |                                                              |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![120216339-dbd20800-c271-11eb-80ee-12759a44ca35](https://user-images.githubusercontent.com/20268101/120216339-dbd20800-c271-11eb-80ee-12759a44ca35.png) | ![120221926-29eb0980-c27a-11eb-8ac1-adf1483d1f54](https://user-images.githubusercontent.com/20268101/120221926-29eb0980-c27a-11eb-8ac1-adf1483d1f54.png) | ![120222169-7cc4c100-c27a-11eb-8829-cb0041a7523e](https://user-images.githubusercontent.com/20268101/120222169-7cc4c100-c27a-11eb-8829-cb0041a7523e.png) |
| ![120216325-d96fae00-c271-11eb-987d-d46f2f4755d6](https://user-images.githubusercontent.com/20268101/120216325-d96fae00-c271-11eb-987d-d46f2f4755d6.png) | ![120221937-2eafbd80-c27a-11eb-83df-81017923a218](https://user-images.githubusercontent.com/20268101/120221937-2eafbd80-c27a-11eb-83df-81017923a218.png) |                                                              |
| ![120216334-db397180-c271-11eb-94e2-da8e3977df19](https://user-images.githubusercontent.com/20268101/120216334-db397180-c271-11eb-94e2-da8e3977df19.png) | ![120216330-da084480-c271-11eb-926e-e55d350b4a5e](https://user-images.githubusercontent.com/20268101/120216330-da084480-c271-11eb-926e-e55d350b4a5e.png) | ![120222091-60288900-c27a-11eb-9ea8-89e6f25641db](https://user-images.githubusercontent.com/20268101/120222091-60288900-c27a-11eb-9ea8-89e6f25641db.png) |



