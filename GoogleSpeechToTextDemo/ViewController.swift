//
//  ViewController.swift
//  GoogleTextToSpeechDemo
//
//  Created by shivani Bajaj on 2/26/20.
//  Copyright © 2020 Shivani Bajaj. All rights reserved.
//

import UIKit
import AVFoundation
import googleapis

class ViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultsTableView: UITableView!
    
    // MARK: Variables and Constants
    
    var audioData: NSMutableData!
    var speechAlternatives = [SpeechRecognitionAlternative]()
    var isRecordingStarted = false
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AudioController.sharedInstance.delegate = self
        resultsTableView.tableFooterView = UIView(frame: .zero)
    }
    
    @IBAction func startRecording(_ sender: Any) {
        isRecordingStarted = !isRecordingStarted
        if isRecordingStarted {
            recordingButton.setTitle("Stop Recording", for: .normal)
            record()
        } else {
            stopRecording(byEmptingData: true)
        }
    }
    
    func record() {
        emptyPreviousData()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
        } catch {

        }
        audioData = NSMutableData()
        _ = AudioController.sharedInstance.prepare(specifiedSampleRate: Constants.SAMPLE_RATE)
        SpeechRecognitionService.sharedInstance.sampleRate = Constants.SAMPLE_RATE
        _ = AudioController.sharedInstance.start()
    }
    
    func stopRecording(byEmptingData emptyData: Bool = false, withRestart restartRecording: Bool = false) {
        isRecordingStarted = false
        recordingButton.setTitle("Start Recording", for: .normal)
        stopAudio()
        if emptyData {
            emptyPreviousData()
        }
        if restartRecording {
            print("Session restarted")
            record()
        }
    }
    
    func stopAudio(withRestart restartRecording: Bool = false) {
      _ = AudioController.sharedInstance.stop()
      SpeechRecognitionService.sharedInstance.stopStreaming()
        print("Session finished")
    }
    
    func emptyPreviousData() {
        speechAlternatives = []
    }
}

extension ViewController: AudioControllerDelegate {
    func processSampleData(_ data: Data) -> Void {
      activityIndicator.startAnimating()
      audioData.append(data)
      // We recommend sending samples in 100ms chunks
      let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
        * Double(Constants.SAMPLE_RATE) /* samples/second */
        * 2 /* bytes/sample */);

      if (audioData.length > chunkSize) {
        SpeechRecognitionService.sharedInstance.streamAudioData(audioData,
                                                                completion:
          { [weak self] (response, error) in
              guard let strongSelf = self else {
                  return
              }
              strongSelf.activityIndicator.stopAnimating()
              if let error = error {
                strongSelf.stopRecording(byEmptingData: true, withRestart: true)
              } else if let response = response {
                  var finished = false
                  print(response)
                
                  for result in response.resultsArray! {
                      print("********************")
                      print("\n Result array is\n \(response.resultsArray!)")
                      if let result = result as? StreamingRecognitionResult {
                        if let alternatives = result.alternativesArray as? [SpeechRecognitionAlternative] {
                            strongSelf.speechAlternatives += alternatives
                        }
                        strongSelf.resultsTableView.reloadData()
                          if result.isFinal {
                              finished = true
                          }
                      }
                  }
                  if finished {
                    print("Session stopped")
                    strongSelf.stopRecording()
                  }
              }
        })
        self.audioData = NSMutableData()
      }
    }
}

// MARK: TableView DataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return speechAlternatives.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell")!
        cell.textLabel?.text = speechAlternatives[indexPath.row].transcript
        return cell
    }
}
