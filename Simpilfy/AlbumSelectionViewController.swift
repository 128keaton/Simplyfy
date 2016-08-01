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
import MBProgressHUD

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

	override func canBecomeFirstResponder() -> Bool {
		return true
	}

	override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
		if motion == .MotionShake {

			self.shuffle()
		}
	}
	func setupAuthorization() {

		MBProgressHUD.showHUDAddedTo(self.view, animated: true)
		session = (UIApplication.sharedApplication().delegate as! AppDelegate).homeViewController?.session
		sessionManager?.getSession()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]

		self.getPlaylistSnapshot()
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSong" {
			let songSelection = segue.destinationViewController.childViewControllers[0] as! SongSelectionViewController
			songSelection.partialPlaylist = self.partialPlaylist
			songSelection.title = self.partialPlaylist.name
		}
	}

	func shuffle() {

		if playerIntitalized == false {
			playerIntitalized = true
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks!.shuffle()
		} else {
			manager?.newPlaylistURI = partialPlaylist.uri
			manager?.songs = allTracks!.shuffle()
		}

		manager?.playShuffle()
		let track = manager?.getCurrentSong()
		addHudToView((track?.name)!, artist: ((track?.artists[0] as! SPTPartialArtist).name)!)
	}
	func addHudToView(song: String, artist: String) {
		let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
		hud.mode = .Text
		hud.label.text = "Playing: " + song
		hud.detailsLabel.text = "By: " + artist
		self.performSelector(#selector(AlbumSelectionController.hideHud), withObject: nil, afterDelay: 1.0)
	}
	func hideHud() {
		MBProgressHUD.hideHUDForView(self.view, animated: true)
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
						var playlistTracks: [SPTPlaylistTrack] = []
						for track in tracks {
							playlistTracks.append(track as! SPTPlaylistTrack)
						}

						playlistTracks.sortInPlace({ $0.addedAt.compare($1.addedAt) == NSComparisonResult.OrderedDescending })
						for track in playlistTracks {
							self.allTracks?.append(track)
						}

						self.collectionView?.reloadData()
						MBProgressHUD.hideHUDForView(self.view, animated: true)
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
	override func viewDidAppear(animated: Bool) {

		if ((manager?.isPlaying) == true && NSUserDefaults.standardUserDefaults().stringForKey("playlistName") == self.playlist.name) {
			let song = manager?.getCurrentSong()
			let shufflePath = NSIndexPath(forRow: (manager?.songs?.indexOf(song!))!, inSection: 0)

			if previousIndexPath != nil {

				self.collectionView?.reloadItemsAtIndexPaths([shufflePath, previousIndexPath!])
			} else {
				if self.collectionView?.cellForItemAtIndexPath(shufflePath) != nil {
					self.collectionView?.reloadItemsAtIndexPaths([shufflePath])
				}
			}
		}
		NSUserDefaults.standardUserDefaults().setObject(playlist.name, forKey: "playlistName")
		NSUserDefaults.standardUserDefaults().synchronize()
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

		if ((manager?.isPlaying) == true && NSUserDefaults.standardUserDefaults().stringForKey("playlistName") == self.playlist.name) {
			let song = manager?.getCurrentSong()
			let shufflePath = NSIndexPath(forRow: (manager?.songs?.indexOf(song!))!, inSection: 0)

			if previousIndexPath != nil {
				self.collectionView?.reloadItemsAtIndexPaths([shufflePath, previousIndexPath!])
			} else {
				self.collectionView?.reloadSections(NSIndexSet(index: 0))
			}
		} else {
			let song = manager?.getCurrentSong()
			let shufflePath = NSIndexPath(forRow: (manager?.songs?.indexOf(song!))!, inSection: 0)
			self.collectionView?.reloadItemsAtIndexPaths([shufflePath])
		}
		previousIndexPath = indexPath
	}

	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return (allTracks!.count)
	}

	func getAlbumArt(track: SPTPartialTrack) -> NSURL {

		guard let albumArtworkURL = track.album.largestCover else {
			return NSURL(string: "http://pixel.nymag.com/imgs/daily/vulture/2015/06/26/26-spotify.w529.h529.jpg")!
		}
		return albumArtworkURL.imageURL
	}
	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Album", forIndexPath: indexPath) as! AlbumCell

		let track = allTracks![indexPath.row]

		cell.front.kf_setImageWithURL(getAlbumArt(track))
		if manager?.isPlaying == true {
			if track.name == manager?.getCurrentSong().name {
				cell.tapped()
			}
		}
		return cell
	}
}

extension Array {
	mutating func shuffle() {
		for i in 0 ..< (count - 1) {
			let j = Int(arc4random_uniform(UInt32(count - i))) + i
			swap(&self[i], &self[j])
		}
	}
}