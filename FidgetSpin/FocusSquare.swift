//
//  FocusSquare.swift
//  FidgetSpin
//
//  Created by Johan Ospina on 9/17/17.
//  Copyright © 2017 Johan Ospina. All rights reserved.
//

import Foundation
import ARKit

class FocusSquare: SCNNode {
    var focusSpot: SCNNode
    var lastPosition: SCNVector3?
    var lastPositionOnPlane: SCNVector3?
    
    private var recentFocusSquarePositions: [SCNVector3] = []
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []

    override init(){
        let focusSpotScene = SCNScene(named: "art.scnassets/FocusSpot.scn")
        if let focusSpotScene = focusSpotScene{
            self.focusSpot = focusSpotScene.rootNode.childNodes[0]
        } else {
            self.focusSpot = SCNNode(geometry: SCNSphere(radius: 0.2))
            
        }
        super.init()
        addChildNode(focusSpot)
    }
    
    func hide() {
        self.isHidden = false
    }
    
    func unhide() {
        self.isHidden = false
    }
    
    func update(for position: SCNVector3, planeAnchor: ARPlaneAnchor?, camera: ARCamera?) {
        lastPosition = position
        if let anchor = planeAnchor {
            //have a plane
            lastPositionOnPlane = position
            anchorsOfVisitedPlanes.insert(anchor)
        } else {
            //open()
        }
        updateTransform(for: position, camera: camera)
    }
    
    private func updateTransform(for position: SCNVector3, camera: ARCamera?) {
        // add to list of recent positions
        recentFocusSquarePositions.append(position)
        
        // remove anything older than the last 8
        recentFocusSquarePositions.keepLast(8)
        
        // move to average of recent positions to avoid jitter
        if let average = recentFocusSquarePositions.average {
            focusSpot.worldPosition = average
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
