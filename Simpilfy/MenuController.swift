//
//  MenuController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/31/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import SlideMenuControllerSwift
import GlitchLabel
class MenuController: UITableViewController {
	var menu: ContainerViewController?

	var home: HomeViewController?
	var playlist: UIViewController?
	@IBOutlet var artworkView: UIImageView?
	override func viewDidLoad() {
		UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
		menu = (UIApplication.sharedApplication().delegate as! AppDelegate).slideMenuController
		home = (UIApplication.sharedApplication().delegate as! AppDelegate).homeViewController
		playlist = self.storyboard?.instantiateViewControllerWithIdentifier("PlaylistViewController")

		print("yay?")
	}
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		self.view.layoutIfNeeded()
	}
	override func viewDidAppear(animated: Bool) {
		if (home?.player?.isPlaying == true) {
			self.artworkView!.kf_setImageWithURL(home!.getAlbumArt(home!.currentTrack!))
		}
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch indexPath.row {
		case 0:
			menu?.changeMainViewController(home!, close: true)
			break
		case 1:
			menu?.changeMainViewController(playlist!, close: true)
			break

		default:
			break
		}
	}
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
}

class ContainerViewController: SlideMenuController {

	override func awakeFromNib() {
		if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("HomeViewController").navigationController {
			self.mainViewController = controller
		}
		if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("Menu") {
			self.leftViewController = controller
		}
		super.awakeFromNib()
	}
}
