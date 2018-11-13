//
//  ViewController.swift
//  MetalSample
//
//  Created by Paradox Lab on 25/10/18.
//  Copyright © 2018 Paradox Lab. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController,MTKViewDelegate {
    

    @IBOutlet weak var metalView: MTKView!
    var metalRenderer:MetalRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        metalView.delegate = self
//        metalView.framebufferOnly = true
//        metalView.colorPixelFormat = .bgra8Unorm
//        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.clearColor = MTLClearColor.init()
//        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        metalRenderer = MetalRenderer.init(view: metalView)

    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
//        print("mtkView")
        metalRenderer?.setupRenderer()
        
    }
    
    func draw(in view: MTKView) {
//        print("draw")
        metalRenderer?.render()
    }


}

