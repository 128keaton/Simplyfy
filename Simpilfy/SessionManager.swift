//
//  SessionManager.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/28/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation

class SessionManager: NSObject {

	var auth: SPTAuth?
	var delegate: SessionManagerDelegate?

	func getSession() {
		var goodSession: SPTSession?

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
						goodSession = renewdSession
						self.delegate?.doSomethingWithSession(goodSession!)
					} else {
						print("error refreshing session")
					}
				})
			} else {
				print("session valid")
				auth!.renewSession(session, callback: { (error: NSError!, renewdSession: SPTSession!) -> Void in
					if error == nil {
						let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
						userDefaults.setObject(sessionData, forKey: "SpotifySession")
						userDefaults.synchronize()
						print("new session")
						goodSession = renewdSession
						self.delegate?.doSomethingWithSession(goodSession!)
					} else {
						print("error refreshing session")
					}
				})
				delegate?.doSomethingWithSession(goodSession!)
				// didLogin(session)
			}
		} else {
			// UI updates

			self.performSelector(#selector(HomeViewController.shouldLogin), withObject: nil, afterDelay: 0.2)
		}
	}
	func didError() {
		auth = SPTAuth.defaultInstance()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		UIApplication.sharedApplication().openURL(auth!.loginURL)
	}
}

protocol SessionManagerDelegate {
	func doSomethingWithSession(session: SPTSession)
}