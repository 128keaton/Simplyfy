//
//  FirstViewController.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import Kingfisher
import UIImageColors
class HomeViewController: UIViewController, SPTAudioStreamingDelegate, SessionManagerDelegate {

	var session: SPTSession?
	var player: PlayController?

	var manager: SessionManager?

	var currentTrackID: String?
	var currentTrack: SPTPartialTrack?

	@IBOutlet var artworkView: UIImageView?
	@IBOutlet var artistLabel: UILabel?
	@IBOutlet var nameLabel: UILabel?
	// Buttons
	@IBOutlet var playButton: UIButton?
	@IBOutlet var previousButton: UIButton?
	@IBOutlet var nextButton: UIButton?
	@IBOutlet var songProgress: UISlider?

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		setupButtons()
		manager = SessionManager()
		manager?.delegate = self
		manager?.getSession()
		self.view.bringSubviewToFront(artworkView!)
		player = (UIApplication.sharedApplication().delegate as! AppDelegate).playController
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.updateInformation), name: "updateTrack", object: nil)

		// Do any additional setup after loading the view, typically from a nib.
	}
	func setupButtons() {
		playButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		playButton?.setTitle(String.fontAwesomeIconWithName(.Play), forState: .Normal)
		previousButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		previousButton?.setTitle(String.fontAwesomeIconWithName(.Backward), forState: .Normal)
		nextButton?.titleLabel?.font = UIFont.fontAwesomeOfSize(30)
		nextButton?.setTitle(String.fontAwesomeIconWithName(.Forward), forState: .Normal)
		playButton?.layer.borderColor = UIColor.whiteColor().CGColor
		playButton?.layer.borderWidth = 2.0
		playButton?.layer.cornerRadius = 10
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "toSong" {
			let currentPlaylist = (self.parentViewController?.childViewControllers[1] as! PlaylistViewController).selectedPlaylist
			let songSelection = segue.destinationViewController.childViewControllers[0] as! SongSelectionViewController
			songSelection.partialPlaylist = currentPlaylist
			songSelection.fromHome = true
			songSelection.title = currentPlaylist?.name
		}
	}
	func doSomethingWithSession(session: SPTSession) {
		self.session = session
	}
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		guard ((self.parentViewController?.childViewControllers[1] as! PlaylistViewController).selectedPlaylist != nil) else {
			return false
		}
		return true
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
	func getAlbumArt(track: SPTPartialTrack) -> NSURL {

		guard let albumArtworkURL = track.album.largestCover else {
			return NSURL(string: "http://pixel.nymag.com/imgs/daily/vulture/2015/06/26/26-spotify.w529.h529.jpg")!
		}
		return albumArtworkURL.imageURL
	}

	func updateInformation() {
		if let track = player?.getCurrentSong() {

			currentTrack = track
			let artists = currentTrack?.artists[0] as! SPTPartialArtist

			UIImage(data: NSData(contentsOfURL: self.getAlbumArt(track))!)!.getColors({ (let colors: UIImageColors?) in
				UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in

					self.view.backgroundColor = colors?.backgroundColor

					self.artistLabel?.pushTransition(0.4)
					self.artistLabel?.text = "By " + artists.name
					self.artistLabel?.textColor = colors?.secondaryColor

					self.nameLabel?.pushTransition(0.4)
					self.nameLabel?.text = (self.currentTrack?.name)! + " "
					self.nameLabel?.textColor = colors?.primaryColor

					if self.playButton?.titleLabel?.text != String.fontAwesomeIconWithName(.Pause) {
						self.playButton?.titleLabel?.textColor = colors?.primaryColor

						self.playButton?.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)
						self.playButton?.setTitleColor(colors?.primaryColor, forState: .Normal)
					}

					self.nextButton?.titleLabel?.textColor = colors?.primaryColor
					self.nextButton?.setTitleColor(colors?.secondaryColor, forState: .Highlighted)

					self.playButton?.titleLabel?.textColor = colors?.primaryColor
					self.playButton?.setTitleColor(colors?.secondaryColor, forState: .Highlighted)

					self.previousButton?.titleLabel?.textColor = colors?.primaryColor
					self.previousButton?.setTitleColor(colors?.secondaryColor, forState: .Highlighted)

					self.playButton?.layer.borderColor = colors?.secondaryColor.CGColor

					self.artworkView?.pushTransition(0.4)

					self.artworkView!.kf_setImageWithURL(self.getAlbumArt(track))
					}, completion: nil)
			})
			songProgress?.maximumValue = Float(track.duration)
			currentTrackID = currentTrack?.identifier
			let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
			dispatch_async(dispatch_get_global_queue(priority, 0)) {
			}

			self.artistLabel?.hidden = false
			self.nameLabel?.hidden = false
		}
	}


	override func viewDidAppear(animated: Bool) {
		if player?.isPlaying == true {
			playButton?.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
extension UIView {
	func pushTransition(duration: CFTimeInterval) {
		let animation: CATransition = CATransition()
		animation.timingFunction = CAMediaTimingFunction(name:
				kCAMediaTimingFunctionEaseInEaseOut)
		animation.type = kCATransitionPush
		animation.subtype = kCATransitionFromTop
		animation.duration = duration
		self.layer.addAnimation(animation, forKey: kCATransitionPush)
	}
}
