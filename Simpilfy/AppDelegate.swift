//
//  AppDelegate.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

	var window: UIWindow?

	var auth: SPTAuth?
	var playController: PlayController?
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

		auth = SPTAuth.defaultInstance()
		playController = PlayController()
		UIApplication.sharedApplication().statusBarStyle = .LightContent
		UINavigationBar.appearance().barStyle = .Black
		// Override point for customization after application launch.
		return true
	}
	func openURL(url: NSURL) {
		UIApplication.sharedApplication().openURL(url)
	}
	func application(app: UIApplication, openURL url: NSURL, options: [String: AnyObject]) -> Bool {
		if auth?.canHandleURL(url) == true {
			auth?.handleAuthCallbackWithTriggeredAuthURL(url, callback: { (let error: NSError?, let session: SPTSession?) in
				if error != nil {
					print("Authorization error: " + (error?.localizedDescription)!)
					return
				}
				NSNotificationCenter.defaultCenter().postNotificationName("didLogin", object: nil)
				let userDefaults = NSUserDefaults.standardUserDefaults()

				let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session!)

				userDefaults.setObject(sessionData, forKey: "SpotifySession")

				userDefaults.synchronize()

				NSNotificationCenter.defaultCenter().postNotificationName("loginSuccessfull", object: nil)
			})
			return true
		}

		return false
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}
