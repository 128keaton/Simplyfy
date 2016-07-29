//
//  AlbumCell.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/28/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class AlbumCell: UICollectionViewCell {
	@IBOutlet weak var albumImage: UIImageView?

	var back: UIView!
	var front: UIImageView!
	var showingBack = false
	var initNumber: Int = 0

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}

	func tapped() {

		back = UIView(frame: self.frame)
		front = UIImageView(frame: self.frame)
		back.backgroundColor = UIColor.blackColor()
		if albumImage != nil {
			front.image = albumImage?.image
		}
		self.contentView.addSubview(back)

		if showingBack {
			NSLog("showBack")

			UIView.transitionFromView(back, toView: front, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, completion: nil)

			showingBack = false
		} else {
			UIView.transitionFromView(albumImage!, toView: back, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
			showingBack = true
		}
	}
	override func prepareForReuse() {

		if showingBack {
			UIView.transitionFromView(back, toView: front, duration: 0, options: UIViewAnimationOptions.TransitionNone, completion: nil)
			showingBack = false
		}
	}
}
