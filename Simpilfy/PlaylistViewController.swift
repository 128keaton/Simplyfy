//
//  SecondViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import Foundation
class PlaylistViewController: UITableViewController {

	var session: SPTSession?

	var auth: SPTAuth?
	var playlists: [SPTPartialPlaylist]?
	var selectedPlaylist: SPTPartialPlaylist?

	override func viewDidLoad() {
		super.viewDidLoad()
		auth = SPTAuth.defaultInstance()
		self.setupAuthorization()
		self.tableView.delegate = self
		self.tableView.dataSource = self

		// Do any additional setup after loading the view, typically from a nib.
	}

	func setupAuthorization() {
		let homeViewController = self.parentViewController?.parentViewController?.childViewControllers[0].childViewControllers[0] as! HomeViewController

		self.session = homeViewController.session
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		self.fetchPlaylists()
		// setupSpotify()
	}

	func fetchPlaylists() {

		SPTPlaylistList.playlistsForUserWithSession(session, callback: { (error, playlistList) -> Void in
			let list = playlistList as! SPTPlaylistList?
			if list != nil {
				print("list aint nil")
				self.getAllPlaylists(self.session!, playlistList: list!, callback: { playlists in
					self.playlists = playlists
					self.tableView.reloadData()
				})
			}
			if error != nil {
				print(error.localizedDescription)
			}
		})
	}
	func shouldLogin() {
		print("I be log in")
		UIApplication.sharedApplication().openURL(auth!.loginURL)
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSong" {
			let songSelection = segue.destinationViewController as! SongSelectionViewController
			songSelection.partialPlaylist = selectedPlaylist
			songSelection.title = selectedPlaylist?.name
		}
	}
	func getAllPlaylists(session: SPTSession, playlistList: SPTListPage, callback: (Array<SPTPartialPlaylist> -> Void)) {
		// recursive case, if has next page, get it, then call this with a callback that assumes that this returns all playlist pages, and then callback again so that function that called this can get all playlist pages that this has
		if (playlistList.hasNextPage) {
			playlistList.requestNextPageWithSession(session, callback: { (err, list) -> Void in
				if let l = list as? SPTListPage {
					self.getAllPlaylists(session, playlistList: l, callback: { playlists in
						var p = playlists
						for i in 0 ..< playlistList.items.count {
							p.append(playlistList.items[i] as! SPTPartialPlaylist)
						}
						callback(p)
					})
				}
			})
		} else { // base case, just get all the playlists, then callback so function that called gets all playlists
			var playlists = Array<SPTPartialPlaylist>()
			for i in 0 ..< playlistList.items.count {
				playlists.append(playlistList.items[i] as! SPTPartialPlaylist)
			}
			print(playlists.count)
			callback(playlists)
		}
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedPlaylist = self.playlists![indexPath.row]
		self.performSegueWithIdentifier("toSong", sender: nil)
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if playlists != nil {
			print("Count darkula: \(playlists!.count)")
			return (playlists?.count)!
		} else {
			return 0
		}
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell")

		let playlist: SPTPartialPlaylist! = playlists![indexPath.row]

		if playlist != nil {
			cell!.textLabel?.text = playlist.name
			cell!.detailTextLabel?.text = String(playlist.trackCount)
		}

		return cell!
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

