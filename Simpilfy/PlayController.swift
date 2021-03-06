//
//  PlayController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/27/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class PlayController: NSObject, SPTAudioStreamingDelegate {

	var songs: [SPTPartialTrack]? = []
	var player: SPTAudioStreamingController? = SPTAudioStreamingController.sharedInstance()
	var session: SPTSession?
	var auth: SPTAuth?
	var uris: [NSURL]? = []

	var isInitialized = false
	var timeIntoSongPaused: NSTimeInterval = 0
	var currentSong = 0
	var currentPlaylistURI = NSURL()
	var newPlaylistURI = NSURL()

	var isPlaying = false
	var didShuffle = false
	var currentTrackURI = NSURL()

	func setupAuthorization() {
		auth = SPTAuth.defaultInstance()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		let rootViewController = (UIApplication.sharedApplication().delegate as! AppDelegate).homeViewController
		self.session = rootViewController!.session
	}

	func initWithSongs() {
		setupAuthorization()

		setupiOSDefaultControls()
		self.initializePlayerWithSession(self.session!)
		self.beginPlaying(false)
		self.setLockScreenData()
		self.setLockScreenPlayed()

		self.timeIntoSongPaused = self.player!.currentPlaybackPosition
	}
	func initializePlayerWithSession(session: SPTSession) {
		if (isInitialized == false && player?.loggedIn == false) {
			self.isInitialized = true
			do {
				try self.player?.startWithClientId("7fedf5f10ea84f069aae21eb9e06b73b")
			} catch _ {
				print("player already initalized")
			}
		}

		player?.delegate = self
		player?.loginWithAccessToken(session.accessToken)
	}

	func setupiOSDefaultControls() {
		MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.addTarget(self, action: #selector(PlayController.previous))

		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: #selector(PlayController.next))

		MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: #selector(PlayController.play))

		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: #selector(PlayController.pause))
	}

	func getCurrentSong() -> SPTPartialTrack {
		if didShuffle == true {
			resortURI()
			return songs![(uris?.indexOf(currentTrackURI))!]
		}
		return songs![currentSong % (songs?.count)!]
	}
	func notifyOfNewTrack() {
		NSNotificationCenter.defaultCenter().postNotificationName("updateTrack", object: self)
	}

	func resortURI() {
		uris?.removeAll()
		for track in songs! {
			uris?.append(track.uri)
		}
	}
	func playShuffle() {
		if isInitialized == false {
			setupAuthorization()
			setupiOSDefaultControls()
			self.initializePlayerWithSession(self.session!)
		}

		didShuffle = true
		uris?.removeAll()

		currentPlaylistURI = newPlaylistURI

		for track in songs! {
			uris?.append(track.uri)
		}
		uris?.shuffleInPlace()
		if currentSong >= uris?.count {
			currentSong = (uris?.indexOf((uris?.last)!))!
		}
		currentTrackURI = uris![currentSong]

		print("current track \(currentSong)")
		player?.playURIs(uris, fromIndex: Int32(currentSong), callback: nil)

		notifyOfNewTrack()
		isPlaying = true
		self.timeIntoSongPaused = self.player!.currentPlaybackPosition
		self.setLockScreenPlayed()
		self.setLockScreenData()
	}

	func setLockScreenPaused() {
		var dict = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo
		if (dict == nil) {
			dict = [String: AnyObject]()
		}
		var info = dict!

		info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
		info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSTimeInterval(self.timeIntoSongPaused)

		MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
	}

	func setLockScreenPlayed() {
		var dict = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo
		if (dict == nil) {
			dict = [String: AnyObject]()
		}
		var info = dict!

		info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
		info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSTimeInterval(self.timeIntoSongPaused)

		MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
	}
	func getAlbumArt(track: SPTPartialTrack) -> NSURL {

		guard let albumArtworkURL = track.album.largestCover else {
			return NSURL(string: "http://pixel.nymag.com/imgs/daily/vulture/2015/06/26/26-spotify.w529.h529.jpg")!
		}
		return albumArtworkURL.imageURL
	}

	func setLockScreenData() {
		let track = self.getCurrentSong()
		let artists = track.artists
		var artist: SPTPartialArtist

		if (artists.count > 0) {
			artist = (artists[0] as! SPTPartialArtist)
			SPTArtist.artistWithURI(artist.uri, session: self.session, callback: { (error, object) -> Void in
				if object != nil {
					if let artist = object as? SPTArtist {
						dispatch_async(dispatch_get_main_queue(), {
							var dict = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo
							if (dict == nil) {
								dict = [String: AnyObject]()
							}
							var info = dict!
							let art: UIImage? = UIImage(data: NSData(contentsOfURL: self.getAlbumArt(track))!)

							info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: art!)
							info[MPMediaItemPropertyTitle] = track.name
							info[MPMediaItemPropertyPlaybackDuration] = track.duration
							info[MPMediaItemPropertyArtist] = artist.name
							info[MPMediaItemPropertyAlbumArtist] = artist.name
							info[MPMediaItemPropertyAlbumTitle] = track.album.name
							info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.timeIntoSongPaused

							MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
						})
					}
				}
			})
		}
	}

	func beginPlaying(beenPlaying: Bool) {

		if newPlaylistURI != currentPlaylistURI || didShuffle == true {
			uris?.removeAll()
			player?.shuffle = false
		}
		currentPlaylistURI = newPlaylistURI
		for track in songs! {
			uris?.append(track.uri)
		}
		currentTrackURI = uris![currentSong]
		player?.playURIs(uris, fromIndex: Int32(currentSong), callback: nil)
		if beenPlaying == true {

			self.setLockScreenData()
			self.setLockScreenPlayed()

			self.setLockScreenData()
		}

		notifyOfNewTrack()
		isPlaying = true

		self.timeIntoSongPaused = self.player!.currentPlaybackPosition
	}
	func next() {
		if currentSong + 1 < (uris?.count)! {
			currentSong = currentSong + 1
		}
		beginPlaying(true)
	}
	func previous() {
		if currentSong - 1 > -1 {
			currentSong = currentSong - 1
			beginPlaying(true)
		}
	}
	func pause() {
		if player?.isPlaying == true {
			self.timeIntoSongPaused = self.player!.currentPlaybackPosition
			player?.setIsPlaying(false, callback: nil)
			isPlaying = false
			self.setLockScreenPaused()
		}
	}
	func play() {
		if player?.isPlaying == false {
			player?.setIsPlaying(true, callback: nil)
			isPlaying = true
			self.timeIntoSongPaused = self.player!.currentPlaybackPosition
			self.setLockScreenPlayed()
		}
	}
}

extension CollectionType {
	/// Return a copy of `self` with its elements shuffled
	func shuffle() -> [Generator.Element] {
		var list = Array(self)
		list.shuffleInPlace()
		return list
	}
}

extension MutableCollectionType where Index == Int {
	/// Shuffle the elements of `self` in-place.
	mutating func shuffleInPlace() {
		// empty and single-element collections don't shuffle
		if count < 2 { return }

		for i in 0 ..< count - 1 {
			let j = Int(arc4random_uniform(UInt32(count - i))) + i
			guard i != j else { continue }
			swap(&self[i], &self[j])
		}
	}
}