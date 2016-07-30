//
//  AlbumCell.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/28/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
class AlbumCell: UICollectionViewCell {
	var albumArtwork: NSURL!

	var back: UILabel!
	var front: UIImageView!
	var showingBack = false
	var initNumber: Int = 0

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
		let smallFrame = CGRectMake(0, 0, 60, 60)
		front = UIImageView(frame: smallFrame)
		front.contentMode = UIViewContentMode.ScaleAspectFit
		self.contentView.addSubview(front)

		back = UILabel(frame: smallFrame)

		back.font = UIFont.fontAwesomeOfSize(30)
		back.text = String.fontAwesomeIconWithName(.Play)
		back.textAlignment = .Center
		back.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
		back.textColor = UIColor.whiteColor()
		back.hidden = true
		self.contentView.addSubview(back)
	}

	func tapped() {

		if showingBack == true {
			NSLog("showBack")

			UIView.transitionWithView(self.contentView, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: {

				self.back.hidden = true
				}, completion: nil)
			showingBack = false
		} else {
			UIView.transitionWithView(self.contentView, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: {

				self.back.hidden = false
				}, completion: nil)

			showingBack = true
		}
	}
	override func prepareForReuse() {

		if showingBack {
			UIView.transitionWithView(self.contentView, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: {

				self.back.hidden = true
				}, completion: nil)
			showingBack = false
		}
	}
	func getImage(url: NSURL) -> UIImage {
		let tempImageView = UIImageView(frame: CGRectZero)
		tempImageView.kf_setImageWithURL(url)
		return tempImageView.image!
	}
}
