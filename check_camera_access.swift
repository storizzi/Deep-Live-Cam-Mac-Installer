import AVFoundation
import Cocoa

func requestCameraAccess(completion: @escaping (Bool) -> Void) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
            print("Camera access granted.")
        } else {
            print("Camera access denied.")
        }
        completion(granted)
    }
}

func checkCameraAuthorizationStatus(completion: @escaping (Bool) -> Void) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
        print("Camera access is authorized.")
        completion(true)
    case .notDetermined:
        print("Camera access is not determined. Requesting access...")
        requestCameraAccess { granted in
            completion(granted)
        }
    case .denied:
        print("Camera access is denied. Please enable it in System Settings.")
        completion(false)
    case .restricted:
        print("Camera access is restricted.")
        completion(false)
    @unknown default:
        print("Unknown camera access status.")
        completion(false)
    }
}


// Attempt to access the camera to trigger a permission prompt
if checkCameraAuthorizationStatus() {
    print("Accessing the camera...")
    
    guard let device = AVCaptureDevice.default(for: .video) else {
        print("No camera device found.")
        exit(1)
    }
    
    do {
        let input = try AVCaptureDeviceInput(device: device)
        let session = AVCaptureSession()
        session.addInput(input)
        session.startRunning()
        print("Camera session started.")
        
        // Keep the session running briefly to ensure it's active
        sleep(2)
        
        session.stopRunning()
        exit(0)  // Exit with success since camera access is confirmed
    } catch {
        print("Failed to start camera session: \(error.localizedDescription)")
        exit(1)
    }
} else {
    print("Camera access was not granted.")
    print("To manually enable camera access:")
    print("1. Open 'System Settings' (or 'System Preferences' on older macOS versions).")
    print("2. Go to 'Privacy & Security' > 'Camera'.")
    print("3. Find your terminal application (e.g., Terminal, iTerm).")
    print("4. Ensure the checkbox next to your terminal application is checked.")
    exit(1)
}
