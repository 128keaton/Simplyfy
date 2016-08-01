//
//  SongSelectionViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/27/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class SongSelectionViewController: UITableViewController, SPTAudioStreamingDelegate {

	var playlist: SPTPlaylistSnapshot!
	var session: SPTSession!
	var partialPlaylist: SPTPartialPlaylist!
	var auth: SPTAuth?
	var allTracks: [SPTPartialTrack]? = []
	var playerIntitalized = false
	var manager: PlayController?
	var homeViewController: HomeViewController?
	var previousIndexPath: NSIndexPath?

	var fromHome = false

	override func viewDidLoad() {
		super.viewDidLoad()
		auth = SPTAuth.defaultInstance()
		self.setupAuthorization()
		manager = (UIApplication.sharedApplication().delegate as! AppDelegate).playController
	}

	func setupAuthorization() {
		homeViewController = (UIApplication.sharedApplication().delegate as! AppDelegate).homeViewController

		self.session = homeViewController!.session

		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		self.getPlaylistSnapshot()
	}

	func getPlaylistSnapshot() -> Void {
		if (self.session != nil) && (self.partialPlaylist != nil) {
			SPTPlaylistSnapshot.playlistWithURI(self.partialPlaylist.playableUri, session: session, callback: { (error, snapshot) -> Void in
				if error != nil {
					NSLog("Error SPTRequest: \(error)")
				} else {
					print("fetched tracks")
					self.playlist = snapshot as! SPTPlaylistSnapshot

					self.getTracks(self.session, trackList: self.playlist.firstTrackPage, callback: { tracks in
						var playlistTracks: [SPTPlaylistTrack] = []
						for track in tracks {
							playlistTracks.append(track as! SPTPlaylistTrack)
						}

						playlistTracks.sortInPlace({ $0.addedAt.compare($1.addedAt) == NSComparisonResult.OrderedDescending })
						for track in playlistTracks {
							self.allTracks?.append(track)
						}
						self.tableView.reloadData()
					})
				}
			})
		}
	}

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.playlist != nil {
			return (self.allTracks?.count)!
		} else {
			return 0
		}
	}

	func getTracks(session: SPTSession, trackList: SPTListPage, callback: (Array<SPTPartialTrack> -> Void)) {
		// recursive case, if has next page, get it, then call this with a callback that assumes that this returns all tracks, and then callback again so that function that called this can get all tracks that this has
		if (trackList.hasNextPage) {
			trackList.requestNextPageWithSession(session, callback: { (err, list) -> Void in
				if let l = list as? SPTListPage {
					self.getTracks(session, trackList: l, callback: { tracks in
						var t = tracks
						for i in 0 ..< trackList.items.count {
							t.append(trackList.items[i] as! SPTPartialTrack)
						}
						callback(t)
					})
				}
			})
		} else { // base case, just get all the tracks, then callback so function that called gets all tracks
			var tracks = Array<SPTPartialTrack>()
			for i in 0 ..< trackList.items.count {
				tracks.append(trackList.items[i] as! SPTPartialTrack)
			}
			callback(tracks)
		}
	}
	@IBAction func shuffle() {

		if playerIntitalized == false {
			playerIntitalized = true
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = randomInt(0, max: (allTracks?.count)!)
		} else {
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = randomInt(0, max: (allTracks?.count)!)
		}

		self.tableView.beginUpdates()
		manager?.pause()
		manager?.playShuffle()
		let song = manager?.getCurrentSong()
		let shufflePath = NSIndexPath(forRow: (manager?.songs?.indexOf(song!))!, inSection: 0)

		if previousIndexPath != nil {

			self.tableView.reloadRowsAtIndexPaths([shufflePath, previousIndexPath!], withRowAnimation: .Automatic)
		} else {
			self.tableView.reloadRowsAtIndexPaths([shufflePath], withRowAnimation: .Automatic)
		}
		previousIndexPath = shufflePath
		self.tableView.endUpdates()
	}
	func randomInt(min: Int, max: Int) -> Int {
		return min + Int(arc4random_uniform(UInt32(max - min + 1)))
	}

	/*@IBAction func close() {
	 let parent = self.parentViewController
	 self.dismissViewControllerAnimated(true, completion: nil)
	 self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)

	 }*/
	@IBAction func toAlbum() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		print(allTracks![indexPath.row].uri)

		if playerIntitalized == false {
			playerIntitalized = true
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = indexPath.row
			manager?.initWithSongs()
		} else {
			manager?.player?.setIsPlaying(false, callback: nil)
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = indexPath.row
			manager?.beginPlaying(true)
		}
		let song = manager?.getCurrentSong()
		let shufflePath = NSIndexPath(forRow: (manager?.songs?.indexOf(song!))!, inSection: 0)

		self.tableView.beginUpdates()
		if previousIndexPath != nil {
			self.tableView.reloadRowsAtIndexPaths([shufflePath, previousIndexPath!], withRowAnimation: .Automatic)
		} else if fromHome == true {
			self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
		} else {
			self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
		}
		print("Parent VC: \(self.parentViewController). Parent parent: \(self.parentViewController?.parentViewController)")
		previousIndexPath = shufflePath
		self.tableView.endUpdates()
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Track", forIndexPath: indexPath)

		if self.playlist != nil {

			let track = allTracks![indexPath.row]
			if track.name.characters.count > 30 {
				let name = track.name
				cell.textLabel?.text = name.trunc(30)
			} else {
				cell.textLabel!.text = track.name
			}

			if track.artists[0].name.characters.count > 20 {
				cell.detailTextLabel?.text = track.artists[0].name.trunc(20)
			} else {
				cell.detailTextLabel!.text = track.artists[0].name
			}
			cell.detailTextLabel?.font = UIFont.systemFontOfSize(14)
			cell.detailTextLabel?.textColor = UIColor.grayColor()
			if manager?.isPlaying == true {
				if track.name == manager?.getCurrentSong().name {
					cell.detailTextLabel?.textColor = UIColor.whiteColor()
					cell.detailTextLabel?.font = UIFont.fontAwesomeOfSize(20)
					cell.detailTextLabel?.text = String.fontAwesomeIconWithName(FontAwesome.Play)
				}
			}
		}

		return cell
	}
}

extension String {
	func trunc(length: Int, trailing: String? = "...") -> String {
		if self.characters.count > length {
			return self.substringToIndex(self.startIndex.advancedBy(length)) + (trailing ?? "")
		} else {
			return self
		}
	}
}
