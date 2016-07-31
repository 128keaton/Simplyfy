//
//  SideBarController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/30/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import PageMenu
class SideBarController: UIViewController {
	var controllerArray: [UIViewController] = []
	var pageMenu: CAPSPageMenu?
	var homeViewController: HomeViewController?
	var playlistViewController: PlaylistViewController?

	override func viewDidLoad() {
		self.navigationController?.navigationBar.barTintColor = UIColor(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0, alpha: 1.0)
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
		self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
		self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.orangeColor()]

		let homeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("HomeViewController") as! HomeViewController
		let playlistController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlaylistViewController") as! PlaylistViewController
		playlistViewController = playlistController
		homeViewController = homeController
		homeController.title = "now playing"
		playlistController.title = "playlists"
		controllerArray.append(homeController)
		controllerArray.append(playlistController)
		let parameters: [CAPSPageMenuOption] = [
				.ScrollMenuBackgroundColor(UIColor(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0, alpha: 1.0)),
				.ViewBackgroundColor(UIColor(red: 20.0 / 255.0, green: 20.0 / 255.0, blue: 20.0 / 255.0, alpha: 1.0)),
				.SelectionIndicatorColor(UIColor.orangeColor()),
				.BottomMenuHairlineColor(UIColor(red: 70.0 / 255.0, green: 70.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)),
				.MenuItemFont(UIFont(name: "HelveticaNeue", size: 13.0)!),
				.MenuHeight(40.0),
				.MenuItemWidth(90.0),
				.CenterMenuItems(true)
		]

		pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRectMake(0.0, 0.0, self.view.frame.width, self.view.frame.height), pageMenuOptions: parameters)
		self.addChildViewController(pageMenu!)
		self.view.addSubview(pageMenu!.view)
		pageMenu!.didMoveToParentViewController(self)
	}
}
