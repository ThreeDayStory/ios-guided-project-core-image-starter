import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var blurSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
	
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else { return } // use Alert before crashing/returning

            var scaledSize = imageView.bounds.size
            // you can also make it so that when you start interaction it
            // lowers the resolution so that it's quicker and smoother
            // Then when you let up on the slider the res is higher
            // so that it saves at the higher res scale
            let scale: CGFloat = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            
            guard let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize) else { return } // use Alert
            scaledImage = CIImage(image: scaledUIImage)
        }
    }

    var scaledImage: CIImage? {
        didSet {
            updateImage()
        }
    }
    private let context = CIContext()
    private let colorControlsFilter = CIFilter.colorControls()
    private let blurFilter = CIFilter.gaussianBlur()

	override func viewDidLoad() {
		super.viewDidLoad()
//        originalImage = imageView.image
//        let filter = CIFilter.gaussianBlur()
        print(colorControlsFilter.attributes)
	}
	
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is not available")
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self

        present(imagePicker, animated: true, completion: nil)
    }

    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }

    private func image(byFiltering inputImage: CIImage) -> UIImage {

        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.saturation = saturationSlider.value
        colorControlsFilter.brightness = brightnessSlider.value
        colorControlsFilter.contrast = contrastSlider.value
        blurFilter.inputImage = colorControlsFilter.outputImage
        blurFilter.radius = blurSlider.value

        guard let outputImage = blurFilter.outputImage else { return originalImage! }
        guard let renderedImage = context.createCGImage(outputImage, from: outputImage.extent) else { return originalImage! }

        return UIImage(cgImage: renderedImage)
    }

	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		// TODO: show the photo picker so we can choose on-device photos
		// UIImagePickerController + Delegate
        presentImagePickerController()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        guard let originalImage = originalImage?.flattened,
            let ciImage = CIImage(image: originalImage) else { return }

        let processedImage = self.image(byFiltering: ciImage)
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
            }) { (success, error) in
                if let error = error {
                    print("Error savinf photo: \(error)")
                    // NSLog("%@", error)
                    return
                }

                DispatchQueue.main.async {
                    self.presentSuccessfulSaveAlert()
                }
            }
        }
	}

    private func presentSuccessfulSaveAlert() {
        let alert = UIAlertController(title: "Photo Saved!", message: "The photo has been saved to your Photo Library!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
	

	// MARK: Slider events
	
    @IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func contrastChanged(_ sender: Any) {
        updateImage()
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        updateImage()
    }
    @IBAction func blurChanged(_ sender: Any) {
        updateImage()
    }
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }

        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
