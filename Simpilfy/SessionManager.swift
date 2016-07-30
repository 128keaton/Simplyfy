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
		SPTAuth.defaultInstance().sessionUserDefaultsKey = "SpotifySession"
		SPTAuth.defaultInstance().tokenRefreshURL = NSURL(string: kTokenRefreshServiceURL)
		SPTAuth.defaultInstance().tokenSwapURL = NSURL(string: kTokenSwapURL)
		SPTAuth.defaultInstance().sessionUserDefaultsKey = "SpotifySession"
		SPTAuth.defaultInstance().tokenRefreshURL = NSURL(string: kTokenRefreshServiceURL)
		SPTAuth.defaultInstance().tokenSwapURL = NSURL(string: kTokenSwapURL)
		SPTAuth.defaultInstance().clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		SPTAuth.defaultInstance().redirectURL = NSURL(string: "simplyfy://login")
		SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope]

		if let sessionObj: AnyObject = userDefaults.objectForKey("SpotifySession") { // session available
			let sessionDataObj = sessionObj as! NSData

			let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession

			if !session.isValid() && auth != nil {

				SPTAuth.defaultInstance().renewSession(session, callback: { (error: NSError!, renewdSession: SPTSession!) -> Void in
					if error == nil {
						let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
						userDefaults.setObject(sessionData, forKey: "SpotifySession")
						userDefaults.synchronize()
						print("new session")
						goodSession = renewdSession
						self.delegate?.doSomethingWithSession(goodSession!)
					} else {
						print("error refreshing session")
						self.didError()
					}
				})
			} else {
				print("session valid")
				SPTAuth.defaultInstance().renewSession(session, callback: { (error: NSError!, renewdSession: SPTSession!) -> Void in
					if error == nil {
						let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
						userDefaults.setObject(sessionData, forKey: "SpotifySession")
						userDefaults.synchronize()
						print("new session")
						goodSession = renewdSession
						self.delegate?.doSomethingWithSession(goodSession!)
					} else {
						print("error refreshing session")
						self.didError()
					}
				})
				delegate?.doSomethingWithSession(session)
				// didLogin(session)
			}
		} else {
			// UI updates

			didError()
		}
	}
	func didError() {
		UIApplication.sharedApplication().openURL(SPTAuth.defaultInstance().loginURL)
	}
}

protocol SessionManagerDelegate {
	func doSomethingWithSession(session: SPTSession)
}