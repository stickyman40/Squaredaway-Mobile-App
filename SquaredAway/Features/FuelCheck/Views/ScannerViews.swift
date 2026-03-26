import AVFoundation
import SwiftUI

struct BarcodeScannerView: View {
    @ObservedObject var vm: FuelCheckViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var scanBeamOffset: CGFloat = -100
    @State private var cornerPulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.scannerActive {
                ScannerRepresentable(
                    onScan: { barcode in vm.didScan(barcode: barcode) },
                    onPermissionDenied: { vm.handlePermissionDenied() },
                    isActive: vm.scannerActive
                )
                .ignoresSafeArea()
            } else {
                Color.black.opacity(0.85).ignoresSafeArea()
            }

            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .mask(vignetteMask)

            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .frame(width: 280, height: 180)
                        .blendMode(.destinationOut)

                    cornerBrackets
                        .frame(width: 280, height: 180)

                    if vm.scanState == .scanning || vm.scanState == .idle {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, AppTheme.Colors.accentSecondary.opacity(0.9), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 260, height: 2)
                            .offset(y: scanBeamOffset)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .compositingGroup()
                Spacer()
            }

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Fuel Check")
                        .font(AppTheme.Typography.titleSmall)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        Task { await vm.loadHistory() }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.lg)

                Spacer()

                scanFeedbackView
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.startScanning()
            startBeamAnimation()
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                cornerPulse = true
            }
        }
        .alert("Camera Access Required", isPresented: $vm.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("SquaredAway needs camera access to scan barcodes. Enable it in Settings.")
        }
        .sheet(isPresented: $vm.showResult) {
            if let product = vm.currentProduct {
                ProductResultView(
                    product: product,
                    scanId: vm.currentScanId,
                    isSaved: vm.isProductSaved,
                    goal: vm.userGoal,
                    onSaveToggle: { vm.toggleSaved() },
                    onScanAgain: {
                        vm.showResult = false
                        vm.resetScan()
                    }
                )
            }
        }
    }

    private var vignetteMask: some View {
        ZStack {
            Rectangle().fill(Color.black)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 280, height: 180)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private var cornerBrackets: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                CornerBracket(index: index, pulse: cornerPulse)
            }
        }
    }

    private var scanFeedbackView: some View {
        Group {
            switch vm.scanState {
            case .idle, .scanning:
                feedbackPill(icon: "barcode.viewfinder", color: AppTheme.Colors.accentSecondary, text: "Point at a barcode")
            case .processing:
                HStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accentSecondary))
                    Text("Looking up product...")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(Color.black.opacity(0.7))
                .cornerRadius(AppTheme.Radius.full)
            case .notFound:
                feedbackPill(icon: "questionmark.circle.fill", color: AppTheme.Colors.warning, text: "Product not found. Try another.")
            case .error(let message):
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.error)
                    Text(message)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(Color.black.opacity(0.7))
                .cornerRadius(AppTheme.Radius.full)
            case .found:
                EmptyView()
            }
        }
        .animation(AppTheme.Animation.standard, value: vm.scanState)
    }

    private func feedbackPill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(Color.black.opacity(0.6))
        .cornerRadius(AppTheme.Radius.full)
    }

    private func startBeamAnimation() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            scanBeamOffset = 100
        }
    }
}

private struct CornerBracket: View {
    let index: Int
    let pulse: Bool

    private let length: CGFloat = 24
    private let thickness: CGFloat = 3
    private let radius: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let xOffset: CGFloat = index == 0 || index == 2 ? 0 : width - length
            let yOffset: CGFloat = index == 0 || index == 1 ? 0 : height - length
            let hFlip: CGFloat = index == 1 || index == 3 ? -1 : 1
            let vFlip: CGFloat = index == 2 || index == 3 ? -1 : 1

            Path { path in
                let x = xOffset
                let y = yOffset
                path.move(to: CGPoint(x: x, y: y + length * vFlip))
                path.addLine(to: CGPoint(x: x, y: y + radius * vFlip))
                path.addArc(
                    center: CGPoint(x: x + radius * hFlip, y: y + radius * vFlip),
                    radius: radius,
                    startAngle: .degrees(180 + (hFlip < 0 ? 90 : 0)),
                    endAngle: .degrees(270 + (hFlip < 0 ? 90 : 0) + (vFlip < 0 ? 90 : 0)),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: x + length * hFlip, y: y))
            }
            .stroke(pulse ? AppTheme.Colors.accentSecondary : AppTheme.Colors.accentPrimary, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
        }
    }
}

struct ScannerRepresentable: UIViewRepresentable {
    let onScan: (String) -> Void
    let onPermissionDenied: () -> Void
    var isActive = true

    func makeCoordinator() -> ScannerCoordinator {
        ScannerCoordinator(onScan: onScan, onPermissionDenied: onPermissionDenied)
    }

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        view.coordinator = context.coordinator
        context.coordinator.previewView = view
        Task { await context.coordinator.requestPermissionAndSetup(view: view) }
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
        if isActive {
            context.coordinator.startRunning()
        } else {
            context.coordinator.stopRunning()
        }
    }
}

final class ScannerPreviewView: UIView {
    var coordinator: ScannerCoordinator?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

final class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let onScan: (String) -> Void
    let onPermissionDenied: () -> Void
    weak var previewView: ScannerPreviewView?

    private var captureSession: AVCaptureSession?
    private var lastScannedCode = ""
    private var lastScanTime: Date = .distantPast
    private let minimumScanInterval: TimeInterval = 2

    init(onScan: @escaping (String) -> Void, onPermissionDenied: @escaping () -> Void) {
        self.onScan = onScan
        self.onPermissionDenied = onPermissionDenied
    }

    @MainActor
    func requestPermissionAndSetup(view: ScannerPreviewView) async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupSession(for: view)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            granted ? setupSession(for: view) : onPermissionDenied()
        case .denied, .restricted:
            onPermissionDenied()
        @unknown default:
            onPermissionDenied()
        }
    }

    private func setupSession(for view: ScannerPreviewView) {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix]

        DispatchQueue.main.async { [weak self] in
            guard let self, let previewView = self.previewView else { return }
            previewView.previewLayer.session = session
            previewView.previewLayer.videoGravity = .resizeAspectFill
        }

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        } catch { }

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func startRunning() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func stopRunning() {
        captureSession?.stopRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadata.stringValue,
              !code.isEmpty else {
            return
        }

        let now = Date()
        if code == lastScannedCode && now.timeIntervalSince(lastScanTime) < minimumScanInterval {
            return
        }

        lastScannedCode = code
        lastScanTime = now

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        captureSession?.stopRunning()
        onScan(code)
    }
}
