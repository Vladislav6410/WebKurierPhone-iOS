import AVFoundation
import SwiftUI
import UIKit

/// Captures the encoded photo bytes provided by AVFoundation without re-encoding UIImage.
struct VehicleCameraView: UIViewControllerRepresentable {
    let onPhoto: (Data) -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> VehicleCameraController {
        let controller = VehicleCameraController()
        controller.onPhoto = onPhoto
        controller.onCancel = onCancel
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ controller: VehicleCameraController, context: Context) {}
}

final class VehicleCameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onPhoto: ((Data) -> Void)?
    var onCancel: (() -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let preview = AVCaptureVideoPreviewLayer()
    private let sessionQueue = DispatchQueue(label: "webkurier.vehicleinspect.camera")
    private var configured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        preview.session = session
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        let shutter = UIButton(type: .system)
        shutter.setTitle("Снять", for: .normal)
        shutter.addTarget(self, action: #selector(capture), for: .touchUpInside)
        shutter.backgroundColor = .white
        shutter.layer.cornerRadius = 24
        shutter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shutter)

        let cancel = UIButton(type: .system)
        cancel.setTitle("Отмена", for: .normal)
        cancel.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancel)

        NSLayoutConstraint.activate([
            shutter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            shutter.widthAnchor.constraint(equalToConstant: 110),
            shutter.heightAnchor.constraint(equalToConstant: 48),
            cancel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        requestCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }

    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureCamera() }
                    else { self?.onError?("Доступ к камере запрещён. Разрешите доступ в настройках iPhone.") }
                }
            }
        default:
            onError?("Доступ к камере запрещён. Разрешите доступ в настройках iPhone.")
        }
    }

    private func configureCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let device = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async { self.onError?("Камера недоступна.") }
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                self.session.beginConfiguration()
                guard self.session.canAddInput(input), self.session.canAddOutput(self.output) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.onError?("Невозможно настроить фотосъёмку.") }
                    return
                }
                self.session.addInput(input)
                self.session.addOutput(self.output)
                self.configured = true
                self.session.commitConfiguration()
                self.session.startRunning()
            } catch {
                DispatchQueue.main.async { self.onError?(error.localizedDescription) }
            }
        }
    }

    @objc private func capture() {
        sessionQueue.async { [weak self] in
            guard let self, self.configured, self.session.isRunning else { return }
            let settings = self.output.availablePhotoCodecTypes.contains(.jpeg)
                ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                : AVCapturePhotoSettings()
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc private func cancelCapture() { onCancel?() }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            DispatchQueue.main.async { self.onError?(error.localizedDescription) }
            return
        }
        guard let bytes = photo.fileDataRepresentation(), !bytes.isEmpty else {
            DispatchQueue.main.async { self.onError?("Камера не вернула данные снимка.") }
            return
        }
        DispatchQueue.main.async { self.onPhoto?(bytes) }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
}
