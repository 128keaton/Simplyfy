//
//  FirstViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, SPTAudioStreamingDelegate {

	var session: SPTSession?
	var player: SPTAudioStreamingController? = SPTAudioStreamingController.sharedInstance()

	var auth: SPTAuth?

	override func viewDidLoad() {
		super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.initialUpdates), name: "loginSuccessfull", object: nil)

		let userDefaults = NSUserDefaults.standardUserDefaults()

		if let sessionObj: AnyObject = userDefaults.objectForKey("SpotifySession") { // session available
			let sessionDataObj = sessionObj as! NSData

			let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession

			if !session.isValid() && auth != nil {
				auth!.renewSession(session, callback: { (error: NSError!, renewdSession: SPTSession!) -> Void in
					if error == nil {
						let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
						userDefaults.setObject(sessionData, forKey: "SpotifySession")
						userDefaults.synchronize()
						print("new session")
						self.session = renewdSession
						self.didLogin(renewdSession)
					} else {
						print("error refreshing session")
					}
				})
			} else {
				print("session valid")
				self.session = session
				didLogin(session)
			}
		} else {
			// UI updates
			self.performSelector(#selector(HomeViewController.shouldLogin), withObject: nil, afterDelay: 0.2)
		}

		// Do any additional setup after loading the view, typically from a nib.
	}

	override func viewDidAppear(animated: Bool) {
		// self.shouldLogin()
	}
	func initialUpdates() {
		let userDefaults = NSUserDefaults.standardUserDefaults()

		if let sessionObj: AnyObject = userDefaults.objectForKey("SpotifySession") {
			let sessionDataObj = sessionObj as! NSData
			let firstTimeSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
			self.session = firstTimeSession
			didLogin(firstTimeSession)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	func playNewSong(){
		
	}
	func shouldLogin() {
		print("I be log in")
		auth = SPTAuth.defaultInstance()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		UIApplication.sharedApplication().openURL(auth!.loginURL)
	}
	func didLogin(session: SPTSession) {
		print("did login")
		self.session = session
	}
}
