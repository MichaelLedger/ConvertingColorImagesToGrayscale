/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of iOS view controller that demonstrates matrix multiplication.
*/

import UIKit
import Accelerate
import SwiftUI

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    
    @IBOutlet var portraitConstraints: [NSLayoutConstraint]!
    @IBOutlet var landscapeConstraints: [NSLayoutConstraint]!
    
    var currentIndex: Int = 0
    var imageNameArr: [String] = ["Food_4.JPG", "lucency.png", "336FD40E-E423-4A91-8FC3-AA5A3B90E65A-2409-00000314C5761332.jpg"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(configConstrainsWhenDeviceOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        configConstrainsViaScreenSize()
        
        reloadSampleImage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @IBAction func previousBarButtonItemClicked(_ sender: UIBarButtonItem) {
        if currentIndex <= 0 {
            currentIndex = imageNameArr.count - 1
        } else {
            currentIndex -= 1
        }
        reloadSampleImage()
    }
    
    @IBAction func nextBarButtonItemClicked(_ sender: UIBarButtonItem) {
        if currentIndex >= imageNameArr.count - 1 {
            currentIndex = 0
        } else {
            currentIndex += 1
        }
        reloadSampleImage()
    }
    
    private func reloadSampleImage() {
        guard imageNameArr.count > currentIndex else { return }
        
        let imageName: String = imageNameArr[currentIndex]
        /*
         The Core Graphics image representation of the source asset.
         */
        let cgImage: CGImage = {
            guard let cgImage = #imageLiteral(resourceName: imageName).cgImage else {
                fatalError("Unable to get CGImage")
            }
            
            return cgImage
        }()
        
        /*
         The format of the source asset.
         */
        lazy var format: vImage_CGImageFormat = {
            guard
                let format = vImage_CGImageFormat(cgImage: cgImage) else {
                    fatalError("Unable to create format.")
            }
            
            return format
        }()
        
        /*
         The vImage buffer containing a scaled down copy of the source asset.
         */
        lazy var sourceBuffer: vImage_Buffer = {
            guard
                var sourceImageBuffer = try? vImage_Buffer(cgImage: cgImage,
                                                           format: format),
                
                var scaledBuffer = try? vImage_Buffer(width: Int(sourceImageBuffer.height),
                                                      height: Int(sourceImageBuffer.width),
                                                      bitsPerPixel: format.bitsPerPixel) else {
                                                        fatalError("Unable to create source buffers.")
            }
            
            defer {
                sourceImageBuffer.free()
            }
            
            vImageScale_ARGB8888(&sourceImageBuffer,
                                 &scaledBuffer,
                                 nil,
                                 vImage_Flags(kvImageNoFlags))
            
            return scaledBuffer
        }()
        
        /*
         The 1-channel, 8-bit vImage buffer used as the operation destination.
         */
        lazy var destinationBuffer: vImage_Buffer = {
            guard let destinationBuffer = try? vImage_Buffer(width: Int(sourceBuffer.width),
                                                  height: Int(sourceBuffer.height),
                                                  bitsPerPixel: 8) else {
                                                    fatalError("Unable to create destination buffers.")
            }
            
            return destinationBuffer
        }()
        
        // Declare the three coefficients that model the eye's sensitivity
        // to color.
        let redCoefficient: Float = 0.2126
        let greenCoefficient: Float = 0.7152
        let blueCoefficient: Float = 0.0722
        
        // Create a 1D matrix containing the three luma coefficients that
        // specify the color-to-grayscale conversion.
        let divisor: Int32 = 0x1000
        let fDivisor = Float(divisor)
        
        var coefficientsMatrix = [
            Int16(redCoefficient * fDivisor),
            Int16(greenCoefficient * fDivisor),
            Int16(blueCoefficient * fDivisor)
        ]
        
        // Use the matrix of coefficients to compute the scalar luminance by
        // returning the dot product of each RGB pixel and the coefficients
        // matrix.
        let preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        
        vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer,
                                               &destinationBuffer,
                                               &coefficientsMatrix,
                                               divisor,
                                               preBias,
                                               postBias,
                                               vImage_Flags(kvImageNoFlags))
        
        // Create a 1-channel, 8-bit grayscale format that's used to
        // generate a displayable image.
        guard let monoFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent) else {
                return
        }
        
        // Create a Core Graphics image from the grayscale destination buffer.
        let result = try? destinationBuffer.createCGImage(format: monoFormat)
        
        let originalImage = UIImage(named: imageName)
        
        // Display the grayscale result.
        if let result = result, let originalImage = originalImage {
            let grayImage = UIImage(cgImage: result, scale: originalImage.scale, orientation: originalImage.imageOrientation)
            imageView.image = FBYFilterEffectHelper.image(with: grayImage, scaledTo: originalImage.size)
        }
        
        imageView2.image = FBYFilterEffectHelper.greyscaleImage(originalImage)
        
        imageView3.image = FBYFilterEffectHelper.greyscaleImageNew(originalImage, type: 4)//recommend
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//        configConstrainsWhenDeviceOrientationChanged()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.configConstrainsWhenDeviceOrientationChanged()
//        }
    }
    
    func configConstrainsViaScreenSize() {
        if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
            NSLayoutConstraint.deactivate(self.portraitConstraints)
            NSLayoutConstraint.activate(self.landscapeConstraints)
        } else {
            NSLayoutConstraint.deactivate(self.landscapeConstraints)
            NSLayoutConstraint.activate(self.portraitConstraints)
        }
    }
    
    @objc func configConstrainsWhenDeviceOrientationChanged() {
        // this will make sure that otherConstraint won't be animated but will take effect immediately
//        self.view.setNeedsLayout()
//        self.view.layoutIfNeeded()
        
//        UIView.animate(withDuration: 0.3) {
//            // Make the animation happen
//            self.view.layoutIfNeeded()
//        }
        
        let animator = UIViewPropertyAnimator(duration: 0.3,
                                              timingParameters: UICubicTimingParameters(animationCurve: .easeOut))
        animator.addAnimations {
            if UIDevice.current.orientation.isLandscape {
                NSLayoutConstraint.deactivate(self.portraitConstraints)
                NSLayoutConstraint.activate(self.landscapeConstraints)
            } else if UIDevice.current.orientation.isPortrait {
                NSLayoutConstraint.deactivate(self.landscapeConstraints)
                NSLayoutConstraint.activate(self.portraitConstraints)
            } else {
                // do nothing.
            }
//            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}
