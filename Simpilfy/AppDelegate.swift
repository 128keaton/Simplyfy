//
//  AppDelegate.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {

	var window: UIWindow?

	let kTokenSwapURL = "https://peaceful-sierra-1249.herokuapp.com/swap"
	let kTokenRefreshServiceURL = "https://peaceful-sierra-1249.herokuapp.com/refresh"
	var auth: SPTAuth?
	var playController: PlayController?
	var homeViewController: HomeViewController?
	var playlistViewController: PlaylistViewController?
	var slideMenuController: ContainerViewController?
	var playlistNav: UINavigationController?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

		auth = SPTAuth.defaultInstance()
		playController = PlayController()
		SPTAuth.defaultInstance().sessionUserDefaultsKey = "SpotifySession"
		SPTAuth.defaultInstance().tokenRefreshURL = NSURL(string: kTokenRefreshServiceURL)
		SPTAuth.defaultInstance().tokenSwapURL = NSURL(string: kTokenSwapURL)
		// Override point for customization after application launch.
		UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		homeViewController = storyboard.instantiateViewControllerWithIdentifier("HomeViewController") as? HomeViewController
		playlistNav = storyboard.instantiateViewControllerWithIdentifier("PlaylistViewController") as? UINavigationController
		playlistViewController = playlistNav!.childViewControllers[0] as? PlaylistViewController
		let menu = storyboard.instantiateViewControllerWithIdentifier("Menu") as? MenuController

		slideMenuController = ContainerViewController(mainViewController: homeViewController!, leftMenuViewController: menu!, rightMenuViewController: playlistViewController!)

		slideMenuController!.delegate = homeViewController
		slideMenuController!.automaticallyAdjustsScrollViewInsets = true
		self.window?.rootViewController = slideMenuController
		self.window?.makeKeyAndVisible()

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
