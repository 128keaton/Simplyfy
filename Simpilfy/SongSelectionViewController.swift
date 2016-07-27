//
//  SongSelectionViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/27/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class SongSelectionViewController: UITableViewController, SPTAudioStreamingDelegate{
	
	var playlist: SPTPlaylistSnapshot!
	var session: SPTSession!
	var partialPlaylist: SPTPartialPlaylist!
	var auth: SPTAuth?
	var allTracks: [SPTPartialTrack]? = []
	var playerIntitalized = false
	var manager: PlayController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		auth = SPTAuth.defaultInstance()
		self.setupAuthorization()
		manager = (UIApplication.sharedApplication().delegate as! AppDelegate).playController
		
	}
	
	func setupAuthorization() {
		let homeViewController = self.parentViewController?.parentViewController?.childViewControllers[0].childViewControllers[0] as! HomeViewController
		
		self.session = homeViewController.session
		
		
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
						for track in tracks{
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
						for  i in 0..<trackList.items.count{
							t.append(trackList.items[i] as! SPTPartialTrack)
						}
						callback(t)
					})
				}
			})
		} else { // base case, just get all the tracks, then callback so function that called gets all tracks
			var tracks = Array<SPTPartialTrack>()
			for i in 0..<trackList.items.count{
				tracks.append(trackList.items[i] as! SPTPartialTrack)
			}
			callback(tracks)
		}
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		print(allTracks![indexPath.row].uri)
		if playerIntitalized == false{
			playerIntitalized = true
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = indexPath.row
		  manager?.initWithSongs()
		}else{
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks
			manager?.currentSong = indexPath.row
			manager?.beginPlaying(true)
		}

	
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Track", forIndexPath: indexPath)
		
		if self.playlist != nil {
			
				let track = allTracks![indexPath.row] 
				cell.textLabel!.text = track.name
		}

		
		return cell
	}
	
	
}