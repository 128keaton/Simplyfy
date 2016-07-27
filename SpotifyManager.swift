//
//  SpotifyManager.swift
//  Simpilfy
//
//  Created by Keaton Burleson on 7/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
class SpotifyManager: NSObject, SPTAudioStreamingDelegate{
    
    internal var session: SPTSession?

    var auth: SPTAuth?
    private var delegate: SpotifyManagerDelegate?
    
    func initalize(clientID: String, url: NSURL){
            auth = SPTAuth.defaultInstance()
            auth!.clientID = "7fedf5f10ea84f069aae21eb9e06b73b"
            auth!.redirectURL = NSURL(string: "simplyfy://login")
            auth!.requestedScopes = [SPTAuthStreamingScope]
            self.delegate?.shouldLogin((auth?.loginURL)!)
    }

    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController!) {
        let audioURL = NSURL(string: "spotify:track:58s6EuEYJdlb0kO7awm3Vp")
        delegate?.playDemo(audioURL!)
        
    }
}
protocol SpotifyManagerDelegate{
    func shouldLogin(url: NSURL)
    func didLogin(session: SPTSession)
    func playDemo(audioURL: NSURL)
    
}
