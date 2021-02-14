import AVFoundation
import UIKit
import Speech
import Alamofire
import SwiftyJSON
import RMQClient

class LoginViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var audioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode!
    
    let speechRecognizer = SFSpeechRecognizer()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var audioSession: AVAudioSession!
    
    var recognitionLock: Bool = false
    
    var questionLock: Bool = false
    
    var imageTaken: UIImage!
    
    var imagePicker = UIImagePickerController()
    
    var objectRecognized: String = ""
    
    @IBOutlet weak var saidText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.startRecording()
        }
        
    }
    
    func openCam() {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.showsCameraControls = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
//    func imagePickerController(_ picker: UIImagePickerController,
//    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey :
//    Any]) {
//        if let img = info[.originalImage] as? UIImage {
//            //self.imageView.image = img
//            imageTaken = img
//            print("image taken")
//            self.dismiss(animated: true, completion: nil)
//        }
//        else {
//            print("error")
//        }
//        
//        //imagePicker.dismiss(animated: true, completion: nil)
//        imageView.isHidden = false
//        imageView.image = imageTaken
//        
//        // convert the image to base64
//        let imageData: NSData = imageTaken.jpeg(.medium)! as NSData
//        let strBase64 = imageData.base64EncodedString(options: [])
//        //getItems(with: strBase64)
//    }
    
    func getItems(){
        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/getLabels", method: .get, encoding: JSONEncoding.default).responseData {response in
            if let json = response.data {
                do{
                    let data = try JSON(data: json)
                    print(data)
                    let object1:String = "\(data[0])"
                    self.objectRecognized = object1
                    self.describe(withObject: object1)
                }
                catch{
                    print("JSON Error")
                }
            }
        }
    }
    
    func getAnswers(withQuestion question: String){
        
        let parameters: [String: Any] = [
            "question": question
        ]

        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/qna", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData {response in
            if let json = response.data {
                do{
                    let data = try JSON(data: json)
                    let item = "\(data["choices"][0]["text"])"
                    self.describe(withObject: item)
                }
                catch{
                    print("JSON Error")
                }
            }
        }
    }
    
    func send(withData motionData: String) {
        let delegate = RMQConnectionDelegateLogger()
        let conn = RMQConnection(uri: "amqp://user1:rtc2021@168.61.18.117:5672", delegate: delegate)
        conn.start()
        let ch = conn.createChannel()
        
        let q = ch.queue("hello")
        ch.defaultExchange().publish(motionData.data(using: .utf8)!, routingKey: q.name)
        
        conn.close()
    }
    
    
    // MARK: - Speech recognition
    private func startRecording() {
        
        //self.stopRecording()
        // MARK: 1. Create a recognizer.
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            return
        }
        
        
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
            if lastString.lowercased() == "front" && !self.recognitionLock{
                self.recognitionLock = true
                //self.performSegue(withIdentifier: "toLogin", sender: self)
                self.openFrontCam()
                let timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { timer in
                    self.getItems()
                    self.recognitionLock = false
                }
                let _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                    self.describe(withObject: self.objectRecognized)
                }
                
                self.describe(withObject: self.objectRecognized)
            }
            if lastString.lowercased() == "right" && !self.recognitionLock{
                self.recognitionLock = true
                //self.performSegue(withIdentifier: "toLogin", sender: self)
                self.openLeftCam()
                let timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { timer in
                    self.getItems()
                    self.recognitionLock = false
                }
                let _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                    self.describe(withObject: self.objectRecognized)
                }
                
                
            }
            if lastString.lowercased() == "left" && !self.recognitionLock{
                self.recognitionLock = true
                //self.performSegue(withIdentifier: "toLogin", sender: self)
                self.openRightCam()
                let timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { timer in
                    self.getItems()
                    self.recognitionLock = false
                }
                let _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                    self.describe(withObject: self.objectRecognized)
                }
                
            }
            
            if lastString.lowercased() == "computer" && !self.questionLock{
                self.questionLock = true
                self.saidText.text = ""
                self.getAnswers(withQuestion: "what is a computer")
                
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
    
    func describe(withObject item: String) {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: item)
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        self.startRecording()
        //openCam()
    }
    
    func openFrontCam() {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: "open frontal camera")
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        send(withData: "front")
        self.startRecording()
        //openCam()
    }
    
    func openLeftCam() {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: "open right camera")
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        send(withData: "left")
        self.startRecording()
        //openCam()
    }
    
    func openRightCam() {
        self.stopRecording()
        let speedd = AVSpeechSynthesizer()
        var voicert = AVSpeechUtterance()
        voicert = AVSpeechUtterance(string: "open left camera")
        voicert.voice = AVSpeechSynthesisVoice(language: "en-US")
        voicert.rate = 0.5
        speedd.speak(voicert)
        send(withData: "right")
        self.startRecording()
        //openCam()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.removeFromParent()
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }

    private func stopRecording() {
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
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
