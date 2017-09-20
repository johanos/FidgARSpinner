//
//  VirtualObject.swift
//  FidgetSpin
//
//  Created by Johan Ospina on 9/17/17.
//  Copyright © 2017 Johan Ospina. All rights reserved.
//

import Foundation
import ARKit
import SceneKit.ModelIO


class VirtualObject: SCNNode {
    var modelUrl: String?
    var recentVirtualObjectDistances = [Float]()
    
    func loadModel(from url: String) {
        
        self.modelUrl = url
        DispatchQueue.global(qos: .background).async {
            let start = Date()
            
            let scene = SCNScene(named: "art.scnassets/fidgetSpinner.scn")!
            let fidgetSpinner = scene.rootNode.childNode(withName: "FidgetSpinner", recursively: true)
            
            self.addChildNode(fidgetSpinner ?? SCNNode())
            
            DispatchQueue.main.async {
                [weak self] in
                self?.modelDidLoad()
                let timeTaken = Date().timeIntervalSince(start)
                print("Model Loading took \(timeTaken) seconds!")
            }
        }
        
    }
    
    func modelDidLoad(){
        //tell things...
    }
}

extension VirtualObject {
    
    static func isNodePartOfVirtualObject(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        if node.parent != nil {
            return isNodePartOfVirtualObject(node.parent!)
        }
        
        return nil
    }
    
}
