//
//  ViewController.swift
//  MCTest
//
//  Created by Jack Kearney on 3/7/16.
//  Copyright © 2016 Jack Kearney. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import MBProgressHUD

class OwnerViewController: UIViewController {
  
  @IBOutlet weak var connectionsLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!

  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  var allCards: [Card]!
  
  var session = OwnerSessionManager()
  
  var allowSoloPlay = true
  
  override func viewDidLoad() {
    super.viewDidLoad()

    startButton.enabled = false
    activityIndicator.startAnimating()
    FirebaseClient.sharedInstance.getCards("demo") { (cards: [Card]!) -> Void in
      self.allCards = cards
      self.startButton.enabled = true
      self.activityIndicator.stopAnimating()
    }

    session.delegate = self
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  func createGameAndBroadcast() {
    let game = Game.createGame(withCards: allCards, andNumberOfPeers: session.peers.count)
    
    LocalGameManager.sharedInstance.game = game
    LocalGameManager.sharedInstance.localPlayer = game.ownerPlayer
    LocalGameManager.sharedInstance.session = session

    for (index, peer) in session.peers.enumerate() {
      var value = [String: AnyObject]()
      value["player"] = game.allPlayers[index]
      value["game"] = game

      session.sendMessage("assignPlayerAndGame", value: value, toPeer: peer)
    }
    
    session.stop()
  }
  
  @IBAction func onStartGame(sender: UIButton) {
    if allowSoloPlay || session.peers.count > 0 {
      createGameAndBroadcast()
      performSegueWithIdentifier("ownerStartGame", sender: self)
    } else {
      let alertController = UIAlertController(title: "Nobody connected!",
        message: nil,
        preferredStyle: .Alert)
      let cancelAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
      alertController.addAction(cancelAction)
      presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
  @IBAction func onDismiss(sender: AnyObject) {
    session.stop()
    dismissViewControllerAnimated(true, completion: nil)
  }
}

extension OwnerViewController: SessionManagerDelegate {
  func sessionManager(sessionManager: SessionManager, peerDidConnect peerID: MCPeerID) {
    dispatch_async(dispatch_get_main_queue()) {
      self.connectionsLabel.text = "\(self.session.peers.count)"
    }
  }

  func sessionManager(sessionManager: SessionManager, thisSessionDidConnect: Bool) {}
  func sessionManager(sessionManager: SessionManager, didReceiveData data: NSDictionary) {}
}
