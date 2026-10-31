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

    static func dismantleUIViewController(_ controller: VehicleCameraController, coordinator: ()) {
        controller.cancelWithoutCallback()
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
    // UI and completion state is confined to the main queue; session work is serial.
    private let shutter = UIButton(type: .system)
    private var configured = false
    private var capturing = false
    private var finished = false
    private var capturedBytes: Data?
    private var captureError: String?
    private var observers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        preview.session = session
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        shutter.isEnabled = false
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
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification, UIApplication.didEnterBackgroundNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.fail("Съёмка прервана. Откройте камеру и повторите попытку.")
            })
        }
        requestCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
        if let connection = preview.connection, connection.isVideoOrientationSupported {
            switch view.window?.windowScene?.interfaceOrientation {
            case .landscapeLeft: connection.videoOrientation = .landscapeLeft
            case .landscapeRight: connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
            default: connection.videoOrientation = .portrait
            }
        }
    }

    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self, !self.finished else { return }
                    if granted { self.configureCamera() }
                    else { self.fail("Доступ к камере запрещён. Разрешите доступ в настройках iPhone.") }
                }
            }
        default:
            fail("Доступ к камере запрещён или ограничен. Разрешите доступ в настройках iPhone.")
        }
    }

    private func configureCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let device = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async { self.fail("Камера недоступна.") }
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                self.session.beginConfiguration()
                guard self.session.canAddInput(input), self.session.canAddOutput(self.output) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { self.fail("Невозможно настроить фотосъёмку.") }
                    return
                }
                self.session.addInput(input)
                self.session.addOutput(self.output)
                self.session.commitConfiguration()
                guard self.output.availablePhotoCodecTypes.contains(.jpeg) else {
                    DispatchQueue.main.async { self.fail("Камера не поддерживает JPEG.") }
                    return
                }
                self.session.startRunning()
                DispatchQueue.main.async {
                    guard !self.finished else { return }
                    self.configured = true
                    self.shutter.isEnabled = true
                }
            } catch {
                DispatchQueue.main.async { self.fail(error.localizedDescription) }
            }
        }
    }

    @objc private func capture() {
        guard configured, !capturing, !finished else { return }
        capturing = true
        shutter.isEnabled = false
        // Preserve orientation in the encoded file's metadata. Preview decoding is separate.
        let orientation: AVCaptureVideoOrientation
        switch view.window?.windowScene?.interfaceOrientation {
        case .landscapeLeft: orientation = .landscapeLeft
        case .landscapeRight: orientation = .landscapeRight
        case .portraitUpsideDown: orientation = .portraitUpsideDown
        default: orientation = .portrait
        }
        sessionQueue.async { [self] in
            guard session.isRunning else {
                DispatchQueue.main.async { self.fail("Сессия камеры остановлена. Повторите съёмку.") }
                return
            }
            if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc private func cancelCapture() {
        guard !finished else { return }
        cancelWithoutCallback()
        onCancel?()
    }

    func cancelWithoutCallback() {
        finished = true
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        shutter.isEnabled = false
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func fail(_ message: String) {
        guard !finished else { return }
        cancelWithoutCallback()
        onError?(message)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let bytes = photo.fileDataRepresentation()
        DispatchQueue.main.async { [self] in
            guard !finished, capturing else { return }
            capturedBytes = bytes
            captureError = error?.localizedDescription
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        DispatchQueue.main.async { [self] in
            guard !finished, capturing else { return }
            if let message = error?.localizedDescription ?? captureError {
                fail(message)
                return
            }
            guard let bytes = capturedBytes, !bytes.isEmpty else {
                fail("Камера не вернула данные снимка. Повторите съёмку.")
                return
            }
            cancelWithoutCallback()
            onPhoto?(bytes)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWithoutCallback()
    }
}
