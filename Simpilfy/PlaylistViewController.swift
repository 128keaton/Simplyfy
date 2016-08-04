//
//  SecondViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import Foundation
import MBProgressHUD

class PlaylistViewController: UITableViewController, SessionManagerDelegate {

	var session: SPTSession?

	var playlists: [SPTPartialPlaylist]? = []
	var selectedPlaylist: SPTPartialPlaylist?
	var sessionManager: SessionManager?
	var playlistOwners: [String]? = []
	var playlistsTiedWithOwners: Dictionary? = [String: [SPTPartialPlaylist]]()

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlaylistViewController.loginSuccessful), name: "didLogin", object: nil)
		super.viewDidLoad()

		self.setupAuthorization()
		self.tableView.delegate = self
		self.tableView.dataSource = self

		// Do any additional setup after loading the view, typically from a nib.
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{ return UIStatusBarStyle.LightContent }
	func setupAuthorization() {

		sessionManager = SessionManager()
		sessionManager?.auth = SPTAuth.defaultInstance()
		sessionManager?.delegate = self
		MBProgressHUD.showHUDAddedTo(self.view, animated: true)
		sessionManager?.getSession()
	}

	func loginSuccessful() {
		self.fetchPlaylists()
	}
	func fetchPlaylists() {

		SPTPlaylistList.playlistsForUserWithSession(session, callback: { (error, playlistList) -> Void in
			let list = playlistList as! SPTPlaylistList?
			if list != nil {
				print("list aint nil")
				self.getAllPlaylists(self.session!, playlistList: list!, callback: { playlists in
					self.playlists = playlists.sort { $0.name < $1.name }
					for user in(self.playlistsTiedWithOwners?.keys)! {
						let theUser = user as String
						self.playlistOwners?.append(theUser)
					}
					self.tableView.reloadData()
					UIView.transitionWithView(self.view,
						duration: 0.15,
						options: [.CurveEaseInOut, .TransitionCrossDissolve],
						animations: { () -> Void in
							self.tableView.reloadRowsAtIndexPaths(self.tableView.indexPathsForVisibleRows!, withRowAnimation: .None)
						}, completion: nil)
					MBProgressHUD.hideHUDForView(self.view, animated: true)
				})
			}
			if error != nil {

				print(error)
				self.sessionManager?.getSession()
				if (error.description.containsString("Code=-1012")) {
					print("Login error")
					self.sessionManager?.getSession()
				} else {
					print("Desc: \(error.description)")
				}
			}
		})
	}

	func doSomethingWithSession(session: SPTSession) {
		self.session = session
		self.performSelector(#selector(PlaylistViewController.fetchPlaylists), withObject: nil, afterDelay: 1.0)
		self.tableView.reloadData()
		print("did session")
	}
	func shouldLogin() {
		print("I be log in")
		UIApplication.sharedApplication().openURL(SPTAuth.defaultInstance().loginURL)
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSong" {
			let songSelection = segue.destinationViewController.childViewControllers[0] as! SongSelectionViewController
			songSelection.partialPlaylist = selectedPlaylist
			songSelection.title = selectedPlaylist?.name
		} else {
			let songSelection = segue.destinationViewController.childViewControllers[0] as! AlbumSelectionController
			songSelection.partialPlaylist = selectedPlaylist
			songSelection.title = selectedPlaylist?.name
		}
	}
	@IBAction func openMenu() {
		((UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController as! ContainerViewController).openLeft()
	}
	@IBAction func cancelToPlayersViewController(segue: UIStoryboardSegue) {
		print("unwind dammit")
	}
	func getAllPlaylists(session: SPTSession, playlistList: SPTListPage, callback: (Array<SPTPartialPlaylist> -> Void)) {
		// recursive case, if has next page, get it, then call this with a callback that assumes that this returns all playlist pages, and then callback again so that function that called this can get all playlist pages that this has
		if (playlistList.hasNextPage) {
			playlistList.requestNextPageWithSession(session, callback: { (err, list) -> Void in
				if let l = list as? SPTListPage {
					self.getAllPlaylists(session, playlistList: l, callback: { playlists in
						var p = playlists
						for i in 0 ..< playlistList.items.count {
							let ownerName = (playlistList.items[i] as! SPTPartialPlaylist).owner.canonicalUserName
							if (self.playlistOwners?.contains(ownerName) == false) {
								print("Appending:     \( ownerName)")
								self.playlistOwners?.append(ownerName)
							}

							if let playlistsFromOwner = self.playlistsTiedWithOwners![ownerName] {
								var newPlaylists = playlistsFromOwner

								if !newPlaylists.contains(playlistList.items[i] as! SPTPartialPlaylist) {
									print("Adding \((playlistList.items[i] as! SPTPartialPlaylist).name)")
									newPlaylists.append(playlistList.items[i] as! SPTPartialPlaylist)
								}
								self.playlistsTiedWithOwners![ownerName] = newPlaylists
							} else {
								var newPlaylists: [SPTPartialPlaylist]? = []

								newPlaylists?.append(playlistList.items[i] as! SPTPartialPlaylist)
								self.playlistsTiedWithOwners![ownerName] = newPlaylists
							}

							p.append(playlistList.items[i] as! SPTPartialPlaylist)
						}
						callback(p)
					})
				}
			})
		} else { // base case, just get all the playlists, then callback so function that called gets all playlists
			var playlists = Array<SPTPartialPlaylist>()
			for i in 0 ..< playlistList.items.count {
				let ownerName = (playlistList.items[i] as! SPTPartialPlaylist).owner.canonicalUserName
				if (self.playlistOwners?.contains(ownerName) == false) {
					print("Appending:     \( ownerName)")
					self.playlistOwners?.append(ownerName)
				}

				if let playlistsFromOwner = self.playlistsTiedWithOwners![ownerName] {
					var newPlaylists = playlistsFromOwner

					if !newPlaylists.contains({ $0.name == playlistList.items[i].name }) {
						print("Adding \((playlistList.items[i] as! SPTPartialPlaylist).name)")
						newPlaylists.append(playlistList.items[i] as! SPTPartialPlaylist)
					}
					self.playlistsTiedWithOwners![ownerName] = newPlaylists
				} else {
					var newPlaylists: [SPTPartialPlaylist]? = []

					newPlaylists?.append(playlistList.items[i] as! SPTPartialPlaylist)
					self.playlistsTiedWithOwners![ownerName] = newPlaylists
				}

				playlists.append(playlistList.items[i] as! SPTPartialPlaylist)
			}

			print(playlists.count)
			callback(playlists)
		}
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let key = playlistOwners![indexPath.section]

		selectedPlaylist = (self.playlistsTiedWithOwners![key])![indexPath.row]

		self.performSegueWithIdentifier("toAlbum", sender: nil)
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if playlistOwners![section] == "spotify" {
			return "Other"
		} else {
			return playlistOwners![section] + "'s Playlists"
		}
	}

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		print("Sections: \(playlistsTiedWithOwners?.keys.count)")
		return (playlistsTiedWithOwners?.keys.count)!
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if playlistsTiedWithOwners != nil {
			let key = playlistOwners![section]
			let tempPlaylists = self.playlistsTiedWithOwners![key]
			print("\(key):\(tempPlaylists)")
			return (tempPlaylists!.count)
		} else {
			return 0
		}
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let key = playlistOwners![indexPath.section]

		let cell = tableView.dequeueReusableCellWithIdentifier("cell")

		let playlist: SPTPartialPlaylist! = playlistsTiedWithOwners![key]![indexPath.row]

		if playlist != nil {
			cell!.textLabel?.text = playlist.name.uppercaseString
			cell!.detailTextLabel?.text = String(playlist.trackCount)
		}

		return cell!
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
