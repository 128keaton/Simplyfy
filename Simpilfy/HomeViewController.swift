//
//  FirstViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, SPTAudioStreamingDelegate {

	var session: SPTSession?
	var player: PlayController?

	var auth: SPTAuth?

	var currentTrackID: String?
	var currentTrack: SPTPartialTrack?

	@IBOutlet var artworkView: UIImageView?
	@IBOutlet var artistLabel: UILabel?
	@IBOutlet var nameLabel: UILabel?
	// Buttons
	@IBOutlet var playButton: UIButton?
	@IBOutlet var previousButton: UIButton?
	@IBOutlet var nextButton: UIButton?

	override func viewDidLoad() {
		super.viewDidLoad()
		setupButtons()

		self.view.bringSubviewToFront(artworkView!)
		player = (UIApplication.sharedApplication().delegate as! AppDelegate).playController
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.updateInformation), name: "updateTrack", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.initialUpdates), name: "loginSuccessfull", object: nil)

		let userDefaults = NSUserDefaults.standardUserDefaults()

		if let sessionObj: AnyObject = userDefaults.objectForKey("SpotifySession") { // session available
			let sessionDataObj = sessionObj as! NSData

			let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession

			if !session.isValid() && auth != nil {
				auth!.renewSession(session, callback: { (error: NSError!, renewdSession: SPTSession!) -> Void in
					if error == nil {
						let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
						userDefaults.setObject(sessionData, forKey: "SpotifySession")
						userDefaults.synchronize()
						print("new session")
						self.session = renewdSession
						self.didLogin(renewdSession)
					} else {
						print("error refreshing session")
					}
				})
			} else {
				print("session valid")
				self.session = session
				didLogin(session)
			}
		} else {
			// UI updates
			self.performSelector(#selector(HomeViewController.shouldLogin), withObject: nil, afterDelay: 0.2)
		}

		// Do any additional setup after loading the view, typically from a nib.
	}
	func setupButtons() {
		playButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		playButton?.setTitle(String.fontAwesomeIconWithName(.Play), forState: .Normal)
		previousButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		previousButton?.setTitle(String.fontAwesomeIconWithName(.Backward), forState: .Normal)
		nextButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		nextButton?.setTitle(String.fontAwesomeIconWithName(.Forward), forState: .Normal)
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSong" {
			let currentPlaylist = (self.parentViewController?.parentViewController?.childViewControllers[1] as! PlaylistViewController).selectedPlaylist
			let songSelection = segue.destinationViewController.childViewControllers[0] as! SongSelectionViewController
			songSelection.partialPlaylist = currentPlaylist
			songSelection.fromHome = true
			songSelection.title = currentPlaylist?.name
		}
	}

	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		let currentPlaylist = (self.parentViewController?.parentViewController?.childViewControllers[1] as! PlaylistViewController).selectedPlaylist
		if currentPlaylist != nil {
			return true
		}
		return false
	}

	@IBAction func pausePlay() {
		if playButton?.titleLabel?.text == String.fontAwesomeIconWithName(.Play) {
			if player?.isInitialized == true {
				playButton?.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)
				player?.play()
			}
		} else {
			playButton?.setTitle(String.fontAwesomeIconWithName(.Play), forState: .Normal)
			player?.pause()
		}
	}

	@IBAction func next() {
		if player?.isInitialized == true {
			player?.next()
		}
	}
	@IBAction func previous() {
		if player?.isInitialized == true {
			player?.previous()
		}
	}
	func updateInformation() {
		if let track = player?.getCurrentSong() {

			currentTrack = track
			currentTrackID = currentTrack?.identifier
			let artworkURL = NSData(contentsOfURL: (currentTrack?.album.largestCover.imageURL)!)
			let artists = currentTrack?.artists[0] as! SPTPartialArtist

			self.artistLabel?.hidden = false
			self.nameLabel?.hidden = false
			self.artworkView?.image = UIImage(data: artworkURL!)
			self.artistLabel?.text = "By " + artists.name
			self.nameLabel?.text = currentTrack?.name
		}
	}
	override func viewDidAppear(animated: Bool) {
		if player?.isPlaying == true {
			playButton?.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)
		}
	}

	func initialUpdates() {
		let userDefaults = NSUserDefaults.standardUserDefaults()

		if let sessionObj: AnyObject = userDefaults.objectForKey("SpotifySession") {
			let sessionDataObj = sessionObj as! NSData
			let firstTimeSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
			self.session = firstTimeSession
			didLogin(firstTimeSession)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	func playNewSong() {
	}
	func shouldLogin() {
		print("I be log in")
		auth = SPTAuth.defaultInstance()
		auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
		auth!.redirectURL = NSURL(string: "simplyfy://login")
		auth!.requestedScopes = [SPTAuthStreamingScope]
		UIApplication.sharedApplication().openURL(auth!.loginURL)
	}
	func didLogin(session: SPTSession) {
		print("did login")
		self.session = session
	}
}
