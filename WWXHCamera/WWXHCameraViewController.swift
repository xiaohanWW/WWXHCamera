//
//  WWXHCameraViewController.swift
//  WWXHCamera
//
//  Created by 魏武 on 2017/5/27.
//  Copyright © 2017年 weiwu. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import CoreMotion

enum FlashBtnType: Int {
    case on = 11131
    case auto = 11132
    case off = 11133
}

let SCREENWIDTH = UIScreen.main.bounds.size.width
let SCREENHEIGHT = UIScreen.main.bounds.size.height

protocol WWXHCameraViewControllerDelegate: class {
    func cameraViewController(_ : WWXHCameraViewController, didFinishPickingImage image: UIImage)
}

class WWXHCameraViewController: UIViewController {
    // session 用来执行输入设备和输出设备之间的数据传递
    var session: AVCaptureSession = AVCaptureSession()
    // 输入设备
    var videoInput: AVCaptureInput?
    // 照片输出流
    var stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    // 预览图层
    var previewLayer: AVCaptureVideoPreviewLayer?
    // 管理者对象
    var motionManger: CMMotionManager = CMMotionManager()
    // 拍照点击按钮
    var takePhotoBtn: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
    // 拍照返回按钮
    var backBtn: UIButton = UIButton(frame: CGRect(x: 45, y: 0, width: 26, height: 26))
    // 提醒文字
    var tipsLabel: UILabel?
    // 闪光灯打开
    var flashlightButtonOn: UIButton = UIButton(frame: CGRect(x: 20, y: 20, width: 25, height: 25))
    // 闪光灯关闭
    var flashlightButtonOff: UIButton = UIButton(frame: CGRect(x: 60, y: 20, width: 25, height: 25))
    // 闪光灯自动
    var flashlightButtonAuto: UIButton = UIButton(frame: CGRect(x: 100, y: 20, width: 25, height: 25))
    // 前后摄像头切换按钮
    var cameraSwitchButton: UIButton = UIButton(frame: CGRect(x: SCREENWIDTH - 20 - 30, y: 0, width: 30, height: 30))
    
    var isUsingFrontFacingCamera: Bool = true
    
    var delegate: WWXHCameraViewControllerDelegate?
    
    var coverImage = UIImage(named: "zhaoxiangdingwei") // 这个遮罩图片要外部传
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.setupAVCaptureSession()
        self.setUpUI()
        self.setCoverImage(image: coverImage!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
        if (motionManger.isDeviceMotionActive) {
            motionManger.stopDeviceMotionUpdates()
        }
    }
    
    func setupAVCaptureSession() {
        self.session.sessionPreset = AVCaptureSessionPresetHigh
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do {
            // 锁定设备之后才能修改设置,修改完再锁上
            try device?.lockForConfiguration()
            device?.flashMode = AVCaptureFlashMode.auto
            device?.unlockForConfiguration()
        } catch (let error){
            print(error)
        }
        
        do {
            try videoInput = AVCaptureDeviceInput(device: device)
        } catch (let error){
            print(error)
        }
        // 输出设置 AVVideoCodecJPEG  -> 输出jpeg格式图片
        stillImageOutput.outputSettings = [AVVideoCodecJPEG: AVVideoCodecKey]
        session.canAddInput(videoInput) ? session.addInput(videoInput) : ()
        session.canAddOutput(stillImageOutput) ? session.addOutput(stillImageOutput) : ()
        
        //初始化预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRect(x: 0, y: 0, width: SCREENWIDTH, height: SCREENHEIGHT)
        if let previewLayer_ = previewLayer {
            self.view.layer.addSublayer(previewLayer_)
        }
    }
    
    // 设置遮罩
    func setCoverImage(image: UIImage) {
        let coverImageView = UIImageView(image: image)
        coverImageView.center = self.view.center
        self.view.addSubview(coverImageView)
    }
    
    func setUpUI() {
        self.view.backgroundColor = UIColor.black
        // 初始化相机按钮
        takePhotoBtn.addTarget(self, action: #selector(takePhoto), for: UIControlEvents.touchUpInside)
        takePhotoBtn.setImage(UIImage(named: "photo_nor"), for: UIControlState.normal)
        takePhotoBtn.setImage(UIImage(named: "photo_high"), for: UIControlState.highlighted)
        takePhotoBtn.setImage(UIImage(named: "photo_dis"), for: UIControlState.disabled)
        takePhotoBtn.center = CGPoint(x: SCREENWIDTH * 0.5, y: SCREENHEIGHT - takePhotoBtn.frame.size.height - 10)
        self.view.addSubview(takePhotoBtn)
        
        // 初始化返回按钮
        backBtn.setImage(UIImage(named: "back_bottom"), for: UIControlState.normal)
        backBtn.addTarget(self, action: #selector(back), for: UIControlEvents.touchUpInside)
        backBtn.center.y = takePhotoBtn.center.y
        self.view.addSubview(backBtn)
        
        // 初始化闪光灯开启按钮
        flashlightButtonOn.setImage(UIImage(named: "flashlight_on"), for: UIControlState.normal)
        flashlightButtonOn.setImage(UIImage(named: "flashlight_on_sel"), for: UIControlState.selected)
        flashlightButtonOn.addTarget(self, action: #selector(flashlightButtonClick), for: UIControlEvents.touchUpInside)
        flashlightButtonOn.tag = FlashBtnType.on.rawValue
        self.view.addSubview(flashlightButtonOn)
        
        // 初始化闪光灯自动按钮
        flashlightButtonAuto.setImage(UIImage(named: "flashlight_auto"), for: UIControlState.normal)
        flashlightButtonAuto.setImage(UIImage(named: "flashlight_auto_sel"), for: UIControlState.selected)
        flashlightButtonAuto.addTarget(self, action: #selector(flashlightButtonClick), for: UIControlEvents.touchUpInside)
        flashlightButtonAuto.tag = FlashBtnType.auto.rawValue
        self.view.addSubview(flashlightButtonAuto)
        
        // 初始化闪光灯关闭按钮
        flashlightButtonOff.setImage(UIImage(named: "flashlight_off"), for: UIControlState.normal)
        flashlightButtonOff.setImage(UIImage(named: "flashlight_off_sel"), for: UIControlState.selected)
        flashlightButtonOff.addTarget(self, action: #selector(flashlightButtonClick), for: UIControlEvents.touchUpInside)
        flashlightButtonOff.tag = FlashBtnType.off.rawValue
        self.view.addSubview(flashlightButtonOff)
        
        // 设置闪光灯默认是自动
        flashlightButtonAuto.isSelected = true
        flashlightButtonOn.isSelected = false
        flashlightButtonOff.isSelected = false
        
        // 初始化前后摄像头切换按钮
        cameraSwitchButton.center.y = flashlightButtonOff.center.y
        cameraSwitchButton.setImage(UIImage(named: "sight_camera_switch"), for: UIControlState.normal)
        cameraSwitchButton.addTarget(self, action: #selector(switchCameraSegmentedControlClick), for: UIControlEvents.touchUpInside)
        self.view.addSubview(cameraSwitchButton)
        
    }
    
    func avOrientationForDeviceOrientation(deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        if (deviceOrientation == UIDeviceOrientation.landscapeLeft) {
            return AVCaptureVideoOrientation.landscapeRight
        } else if (deviceOrientation == UIDeviceOrientation.landscapeRight){
            return AVCaptureVideoOrientation.landscapeLeft
        } else {
            return nil
        }
    }
    
    func takePhoto() {
        
        guard let stillImageConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) else {
            print("相机初始化失败")
            return
        }
        let curDeviceOrientation = UIDevice.current.orientation
        if let avcaptureOrientation = self.avOrientationForDeviceOrientation(deviceOrientation: curDeviceOrientation) {
            stillImageConnection.videoOrientation = avcaptureOrientation
            stillImageConnection.videoScaleAndCropFactor = 1
        }
        stillImageOutput.captureStillImageAsynchronously(from: stillImageConnection) {[unowned self] (imageDataSampleBuffer, error) in
            
            if let error_ = error {
                print(error_)
                return
            }
            guard let _ = imageDataSampleBuffer else {
                return
            }
            
            if let jpegData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
                if let tempImage = UIImage(data: jpegData, scale: 1) {
                    if let tempCgImage = tempImage.cgImage {
                        let image = UIImage(cgImage: tempCgImage, scale: 0.1, orientation: UIImageOrientation.up)
                        self.delegate?.cameraViewController(self, didFinishPickingImage: image)
                        print("拍照完成")
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
        
    }
    
    func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func flashlightButtonClick(_ sender: UIButton) {
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
            do {
                // 锁定设备之后才能修改设置,修改完再锁上
                try device.lockForConfiguration()
                if (device.hasFlash) {
                    if (sender.tag == FlashBtnType.on.rawValue) {
                        device.flashMode = AVCaptureFlashMode.on
                        flashlightButtonOn.isSelected = true
                        flashlightButtonAuto.isSelected = false
                        flashlightButtonOff.isSelected = false
                    } else if (sender.tag == FlashBtnType.auto.rawValue) {
                        flashlightButtonOn.isSelected = false
                        flashlightButtonAuto.isSelected = true
                        flashlightButtonOff.isSelected = false
                    } else if (sender.tag == FlashBtnType.off.rawValue) {
                        flashlightButtonOn.isSelected = false
                        flashlightButtonAuto.isSelected = false
                        flashlightButtonOff.isSelected = true
                    }
                } else {
                    print("设备不支持闪光灯")
                }
                device.unlockForConfiguration()
            } catch (let error){
                print(error)
            }
        }
    }
    
    func switchCameraSegmentedControlClick(_ sender: UIButton) {
        let desiredPosition = isUsingFrontFacingCamera ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back
        for d in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if ((d as! AVCaptureDevice).position == desiredPosition) {
                previewLayer?.session.beginConfiguration()
                do {
                    let input = try AVCaptureDeviceInput(device: d as! AVCaptureDevice)
                    for oldInput in (previewLayer?.session.inputs)! {
                        previewLayer?.session.removeInput(oldInput as! AVCaptureInput)
                    }
                    previewLayer?.session.addInput(input)
                    previewLayer?.session.commitConfiguration()
                } catch (let error) {
                    print(error)
                }
                break
            }
        }
        isUsingFrontFacingCamera = !isUsingFrontFacingCamera
    }
}


















