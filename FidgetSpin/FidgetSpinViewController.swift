//
//  ViewController.swift
//  FidgetSpin
//
//  Created by Johan Ospina on 9/1/17.
//  Copyright © 2017 Johan Ospina. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class FidgetSpinViewController: UIViewController {

    var screenCenter: CGPoint?
    var virtualObjectManager: VirtualObjectManager!
    let session = ARSession()
    
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    var dragOnInfinitePlanesEnabled = false
    
    var sceneView: ARSCNView!
    var fidgetSpinner: SCNNode?
    var isLoadingObject: Bool = false
    
    let fidgetQueue = DispatchQueue(label: "com.johanos.fidgetSpin.fidgetQueue");
    
    var planes = [ARPlaneAnchor: Plane]()
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    func resetTracking() {
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        fidgetQueue.async {
            self.focusSquare?.isHidden = true
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = FocusSquare()
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
        }
    }
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        DispatchQueue.main.async {
            var objectVisible = false
            for object in self.virtualObjectManager.virtualObjects {
                if self.sceneView.isNode(object, insideFrustumOf: self.sceneView.pointOfView!) {
                    objectVisible = true
                    break
                }
            }
            
            if objectVisible {
                self.focusSquare?.hide()
            } else {
                self.focusSquare?.unhide()
            }
            
            let (worldPos, planeAnchor, _) = self.virtualObjectManager.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.worldPosition)
            if let worldPos = worldPos {
                self.fidgetQueue.async {
                    self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        self.view.addSubview(sceneView)
    }
    
    func setupScene() {
        sceneView = ARSCNView(frame: self.view.bounds)
        
        virtualObjectManager = VirtualObjectManager(updateQueue: fidgetQueue)
        virtualObjectManager.delegate = self
        
        // set up scene view
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        
        directionalNode.eulerAngles = SCNVector3( -80.0 * ( Float.pi / 180.0), 0.0, 0.0)
        
        sceneView.setup()
        sceneView.scene.rootNode.addChildNode(ambientNode)
        sceneView.scene.rootNode.addChildNode(directionalNode)
        
        if let environmentMap = UIImage(named: "art.scnassets/environment.jpg") {
            self.sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        

        sceneView.delegate = self
        sceneView.session = session
        // sceneView.showsStatistics = true
        
        setupFocusSquare()
        virtualObjectManager.focusSquare = self.focusSquare
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        
        
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/fidgetSpinner.scn")!
//        fidgetSpinner = scene.rootNode.childNode(withName: "FidgetSpinner", recursively: true)
//
//        let distanceConstraint = SCNDistanceConstraint(target: self.sceneView.pointOfView)
//        distanceConstraint.maximumDistance = 10.0
//        distanceConstraint.minimumDistance = 5.5
//
//        fidgetSpinner?.constraints = [distanceConstraint]
        
        // Set the scene to the view
        //sceneView.scene = scene
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        if ARWorldTrackingConfiguration.isSupported {
            // Start the ARSession.
            resetTracking()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}


    

    // MARK: - ARSCNViewDelegate
extension FidgetSpinViewController : ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateFocusSquare()
         // If light estimation is enabled, update the intensity of the model's lights and the environment map
        if let lightEstimate = session.currentFrame?.lightEstimate {
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        fidgetQueue.async {
            self.addPlane(node: node, anchor: planeAnchor)
            self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        fidgetQueue.async {
            self.updatePlane(anchor: planeAnchor)
            self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        fidgetQueue.async {
            self.removePlane(anchor: planeAnchor)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("TS: \(camera.trackingState)")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
}

extension FidgetSpinViewController: VirtualObjectManagerDelegate {
    
    // MARK: - VirtualObjectManager delegate callbacks
    
    func virtualObjectManager(_ manager: VirtualObjectManager, willLoad object: VirtualObject) {
        DispatchQueue.main.async {
            // Show progress indicator
            
            self.isLoadingObject = true
        }
    }
    
    func virtualObjectManager(_ manager: VirtualObjectManager, didLoad object: VirtualObject) {
        DispatchQueue.main.async {
            self.isLoadingObject = false
        }
    }
    
    func virtualObjectManager(_ manager: VirtualObjectManager, couldNotPlace object: VirtualObject) {
    }
}

extension FidgetSpinViewController {
    // MARK: - Gesture Recognizers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }
        
        fidgetQueue.async {
            let virtualObject = VirtualObject()
            let position = self.focusSquare?.lastPosition ?? SCNVector3Zero
            
            
            self.virtualObjectManager.loadVirtualObject(virtualObject, to: position, cameraTransform: cameraTransform)
            
                self.sceneView.scene.rootNode.addChildNode(virtualObject)
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjectManager.virtualObjects.isEmpty {
            return
        }
        virtualObjectManager.reactToTouchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesCancelled(touches, with: event)
    }
}
