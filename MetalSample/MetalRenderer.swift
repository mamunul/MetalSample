//
//  MetalRenderer.swift
//  MetalSample
//
//  Created by Paradox Lab on 11/11/18.
//  Copyright © 2018 Paradox Lab. All rights reserved.
//

import UIKit
import MetalKit
import CoreGraphics

struct Vertex{
    
    var x,y,z: Float     // position data
//    var r,g,b,a: Float   // color data
    var s,t: Float       // texture coordinates
    
    func floatBuffer() -> [Float] {
        return [x,y,z,s,t]
    }
    
};



class MetalRenderer: NSObject {
    
    let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
        // https://developer.apple.com/reference/coregraphics/cgdataproviderreleasedatacallback
        // N.B. 'CGDataProviderRelease' is unavailable: Core Foundation objects are automatically memory managed
       
        data.deallocate()
        return
    }
    
    // one instance per application
    let mtlDevice:MTLDevice?
    let mtlLibrary:MTLLibrary?
    let commandQueue:MTLCommandQueue?
    var commandBuffer:MTLCommandBuffer?
    
    // one instance per thread
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    var pipelineState:MTLRenderPipelineState?
    let view:MTKView
    var commandEncoder:MTLRenderCommandEncoder?
    var texture:MTLTexture?
    var indices:[Vertex]?
    var vbuffer:MTLBuffer?
    
    init(view:MTKView) {
        self.view = view
        mtlDevice = MTLCreateSystemDefaultDevice()
        mtlLibrary = mtlDevice?.makeDefaultLibrary()
        commandQueue = mtlDevice?.makeCommandQueue()
        self.view.device = mtlDevice
    }
    
    func setupRenderer(){
        configurePipelineDescriptor(vertexFunction: "basic_vertex", fragmentFunction: "basic_fragment")

        (vbuffer) = loadVertexData2(mtlDevice: mtlDevice!)
        pipelineState = try! mtlDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let image = UIImage.init(named: "ford")
        
        let pointer  = imageToPointer(image:image! )
        texture = loadTexture(imagePointer: pointer, imageSize: (image?.size)!, bytesPerRow: (image?.cgImage?.bytesPerRow)!)

    }

    
    private func loadVertexData2(mtlDevice:MTLDevice) -> (MTLBuffer?){
        
        let va = Vertex(x: -1.0, y: 1.0, z: 0.0, s: 0.0, t: 0.0)
        let vb = Vertex(x: 1.0, y: 1.0, z: 0.0, s: 1.0, t: 0.0)
        let vc = Vertex(x: -1.0, y: -1.0, z: 0.0, s: 0.0, t: 1.0)
        let vd = Vertex(x: 1.0, y: -1.0, z: 0.0, s: 1.0, t: 1.0)
        
        indices = [va,vc,vb,
            vc,vd, vb
        ]
        
        var vertices = [Float]()

        var i = 0
        for v in indices! {
            vertices.insert(contentsOf: v.floatBuffer(), at: i)
          i = i+5
            
        }
        
       
        let bufferSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        
        let vertexBuffer = mtlDevice.makeBuffer(bytes: vertices, length: bufferSize, options: [])
        
        vertexBuffer?.label = "vertices"
        return (vertexBuffer)
    }
    
    private func configurePipelineDescriptor(vertexFunction:String, fragmentFunction:String){
        
        let vertexFunction = mtlLibrary?.makeFunction(name: vertexFunction)
        let fragmentFunction = mtlLibrary?.makeFunction(name: fragmentFunction)
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        
        
    }
    
    private func configureRenderCommand(){
        let renderPassDescriptor = view.currentRenderPassDescriptor
        if renderPassDescriptor == nil {
            return
        }
        commandBuffer = mtlDevice?.makeCommandQueue()?.makeCommandBuffer()
        commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        commandEncoder?.setRenderPipelineState(pipelineState!)
        commandEncoder?.setVertexBuffer(vbuffer, offset: 0, index: 0)
        
        let sampler = defaultSampler(device: mtlDevice!)
        
        commandEncoder?.setFragmentTexture(texture, index: 0)
        commandEncoder?.setFragmentSamplerState(sampler, index: 0)
        
    }
    
    
    func defaultSampler(device: MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)!
    }
    
    func render(){
        configureRenderCommand()
        
        commandBuffer?.addCompletedHandler({ [weak self](commandBuffer) in
            let image = self?.textureToImage(texture: (self?.view.currentDrawable?.texture)!,size: (self?.view.frame.size)!)
            
        })
        
        commandEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: (indices?.count)!)
        commandEncoder?.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer?.present(drawable)
            
        }
        commandBuffer?.commit()
        
    }
    
    func offscreenRenderingPass(mtlDevice:MTLDevice,size:CGSize)->MTLRenderPassDescriptor{
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.width = Int(size.width)
        textureDescriptor.height = Int(size.height)
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = .renderTarget
        
        let sampleTexture = mtlDevice.makeTexture(descriptor: textureDescriptor)
        
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = sampleTexture
        renderPass.colorAttachments[0].loadAction = .clear
        renderPass.colorAttachments[0].clearColor =
            MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPass.colorAttachments[0].storeAction = .store
        
        return renderPass
    }
    
    func textureToImage(texture:MTLTexture, size:CGSize) ->UIImage{
        
        let selftureSize = size.width * size.height * 4
        let rowBytes = size.width * 4
        
        let region = MTLRegionMake2D(0, 0, Int(size.width), Int(size.height))
        let pixelBytes = UnsafeMutableRawPointer.allocate(byteCount: Int(size.width) * Int(size.height) * 4, alignment: 0)
        texture.getBytes(pixelBytes, bytesPerRow: Int(size.width) * 4, from: region, mipmapLevel: 0)
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
       
        let provider = CGDataProvider(dataInfo: nil, data: pixelBytes, size: Int(selftureSize),releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(rowBytes), space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        let image = UIImage.init(cgImage: cgImageRef)
        
        
        

        return image
    }
    
    func loadTexture(imagePointer:UnsafeMutableRawPointer, imageSize:CGSize, bytesPerRow:Int) -> MTLTexture{
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = Int(imageSize.width)
        textureDescriptor.height = Int(imageSize.height)
        
        let texture = mtlDevice?.makeTexture(descriptor: textureDescriptor)
        
        let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        
        texture?.replace(region: region, mipmapLevel: 0, withBytes: imagePointer, bytesPerRow: bytesPerRow)
        
        return texture!
        
    }
    
    func imageToPointer(image:UIImage) -> UnsafeMutableRawPointer{
        let imageData = UnsafeMutableRawPointer.allocate(byteCount: Int(image.size.width) * Int(image.size.height) * ((image.cgImage?.bitsPerComponent)!), alignment: 0)// [UInt8](repeating: 0, count: 0)
        
        let cgContextRef = CGContext.init(data: imageData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: (image.cgImage?.bitsPerComponent)!, bytesPerRow: (image.cgImage?.bytesPerRow)!, space: (image.cgImage?.colorSpace)!, bitmapInfo: (image.cgImage?.bitmapInfo)!.rawValue)
        
        cgContextRef?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: Int(image.size.width), height: Int(image.size.height)))
        
        return imageData
    }
    
    
}
