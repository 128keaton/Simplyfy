//
//  AlbumSelectionViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/28/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import KTCenterFlowLayout
class AlbumSelectionController: UICollectionViewController, SessionManagerDelegate {
	var playlist: SPTPlaylistSnapshot!
	var session: SPTSession!
	var partialPlaylist: SPTPartialPlaylist!
	var auth: SPTAuth?
	var allTracks: [SPTPartialTrack]? = []
	var playerIntitalized = false
	var manager: PlayController?
	var homeViewController: HomeViewController?
	var previousIndexPath: NSIndexPath?
	var sessionManager: SessionManager?

	var cellWidth: CGFloat = 0

	var fromHome = false

	override func viewDidLoad() {
		super.viewDidLoad()
		auth = SPTAuth.defaultInstance()

		let layout = KTCenterFlowLayout()
		layout.minimumLineSpacing = 0.0
		layout.minimumInteritemSpacing = 0.0
		layout.itemSize = CGSizeMake(60, 60)
		self.collectionView?.collectionViewLayout = layout
		self.setupAuthorization()
		manager = (UIApplication.sharedApplication().delegate as! AppDelegate).playController
	}

	func setupAuthorization() {
		homeViewController = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController?.childViewControllers[0].childViewControllers[0] as? HomeViewController

		self.session = homeViewController!.session
		sessionManager?.getSession()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]

		self.getPlaylistSnapshot()
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

		manager?.playShuffle()
	}
	func randomInt(min: Int, max: Int) -> Int {
		return min + Int(arc4random_uniform(UInt32(max - min + 1)))
	}

	@IBAction func close() {
		self.dismissViewControllerAnimated(true, completion: nil)
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
						for track in tracks {
							self.allTracks?.append(track)
						}
						self.collectionView?.reloadData()
					})
				}
			})
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

	func doSomethingWithSession(session: SPTSession) {
		self.session = session
	}
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

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
			manager?.play()
		}
		if previousIndexPath != nil {
			let previousCell = self.collectionView?.cellForItemAtIndexPath(previousIndexPath!) as! AlbumCell
			previousCell.tapped()
		}
		previousIndexPath = indexPath

		let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! AlbumCell
		cell.tapped()
	}

	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return (allTracks!.count)
	}

	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Album", forIndexPath: indexPath) as! AlbumCell

		let track = allTracks![indexPath.row]
		let albumArtworkURL = track.album.largestCover.imageURL
		cell.front.kf_setImageWithURL(albumArtworkURL)
		cell.albumArtwork? = albumArtworkURL

		return cell
	}
}
