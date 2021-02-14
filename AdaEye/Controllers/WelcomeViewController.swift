//
//  ViewController.swift
//  AdaEye
//
//  Created by Zheyuan Xu on 2/13/21.
//

import UIKit
import Speech
import AVFoundation

class WelcomeViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    var audioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode!
    
    let speechRecognizer = SFSpeechRecognizer()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var audioSession: AVAudioSession!
    
    var lockLogin: Bool! = false
    
    var lockUsername: Bool! = false
    
    var readyToLogin: Bool! = false
    
    var readyForPassword: Bool! = false
    
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var saidText: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameField.addUnderLine()
        passwordField.addUnderLine()
        loginButton.layer.cornerRadius = 5
        
        
        
        requestSpeechAuthorization()
//        var speedd = AVSpeechSynthesizer()
//        var voicert = AVSpeechUtterance()
//        voicert = AVSpeechUtterance(string: "Welcome to AdaEye, your intelligent navigation package.")
//        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
//        voicert.rate = 0.5
//        speedd.speak(voicert)
    }
    
    
    // MARK: - Speech recognition
    func startRecording() {
        
        //self.stopRecording()
        // MARK: 1. Create a recognizer.
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            return
        }
        
        self.lockUsername = false
        // MARK: 2. Create a speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest!.shouldReportPartialResults = true

        recognizer.recognitionTask(with: recognitionRequest!) { (result, error) in
            guard error == nil else {  return }
            guard let result = result else { return }
            let bestString = result.bestTranscription.formattedString
            var lastString: String = ""
            self.saidText.text = bestString
            for segment in result.bestTranscription.segments {
                let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                
                lastString = bestString.substring(from: indexTo)
                
            }
            if lastString == "login" && !self.lockLogin{
                self.readyToLogin = true
                self.lockLogin = true
                //self.performSegue(withIdentifier: "toLogin", sender: self)
                self.loginPrompt()
                
                
            }
            if self.readyToLogin && lastString.lowercased() == "user" && !self.lockUsername {
                self.lockUsername = true
                print("username said")
                self.lockUsername = true
                self.usernamePrompt()
                self.readyForPassword = true
                self.usernameField.text = "user"
            }
            
            if self.readyForPassword && lastString.lowercased() == "arrow" && !self.lockUsername {
                //self.stopRecording()
                self.passwordField.text = "arrow"
                _ = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { timer in
                    self.performSegue(withIdentifier: "toLogin", sender: self)
                }
            }
            print("got a new result: \(result.bestTranscription.formattedString), final : \(result.isFinal)")
            
            if result.isFinal {
                
            }
        }

        // MARK: 3. Create a recording and classification pipeline.
        audioEngine = AVAudioEngine()

        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        


        // Build the graph.
        audioEngine.prepare()

        // MARK: 4. Start recognizing speech.
        do {
            // Activate the session.
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Start the processing pipeline.
            try audioEngine.start()
        } catch {
            
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let uv = segue.destination as? LoginViewController {
            uv.modalPresentationStyle = .fullScreen
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.removeFromParent()
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }

    func stopRecording() {
        // End the recognition request.
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Stop recording.
        audioEngine.stop()
        audioEngine.reset()
        inputNode.removeTap(onBus: 0) // Call after audio engine is stopped as it modifies the graph.
        // Stop our session.
        try? audioSession.setActive(false)
        audioSession = nil
        print("record disabled")

    }

    func loginPrompt() {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: "Please say your login username")
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        self.startRecording()
    }

    func usernamePrompt() {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: "Please say your login credential")
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        self.startRecording()
    }

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization{ authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.startButton.isEnabled = true
                case .denied:
                    self.startButton.isEnabled = false
                case .restricted:
                    self.startButton.isEnabled = false
                case .notDetermined:
                    self.startButton.isEnabled = false
                @unknown default:
                    fatalError()
                }
            }
        }
    }

    @IBAction func voiceRec(_ sender: UIButton) {
        startRecording()
    }
}



extension UITextField {
    
    func addUnderLine () {
        let bottomLine = CALayer()
        
        bottomLine.frame = CGRect(x: 0.0, y: self.bounds.height + 3, width: self.bounds.width, height: 1.5)
        bottomLine.backgroundColor = UIColor.lightGray.cgColor
        
        self.borderStyle = UITextField.BorderStyle.none
        self.layer.addSublayer(bottomLine)
    }
    
}
