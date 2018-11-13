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
   
    
    func floatBuffer() -> [Float] {
        return [x,y,z]
    }
    
};
struct TexCoordinate{
     var s,t: Float       // texture coordinates
    func floatBuffer() -> [Float] {
        return [s,t]
    }
};
//struct TexCoordinate{
//
//}

class MetalRenderer: NSObject {
    
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
    
    init(view:MTKView) {
        self.view = view
        mtlDevice = MTLCreateSystemDefaultDevice()
        mtlLibrary = mtlDevice?.makeDefaultLibrary()
        commandQueue = mtlDevice?.makeCommandQueue()
        self.view.device = mtlDevice
    }
    
    func setupRenderer(){
        configurePipelineDescriptor(vertexFunction: "basic_vertex", fragmentFunction: "basic_fragment")
        addVertexDescriptionTo(pipelineDesc: pipelineDescriptor)
        pipelineState = try! mtlDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let image = UIImage.init(named: "ford")
        
        let pointer  = imageToPointer(image:image! )
        texture = loadTexture(imagePointer: pointer, imageSize: (image?.size)!, bytesPerRow: (image?.cgImage?.bytesPerRow)!)

    }
    
    private func addVertexDescriptionTo(pipelineDesc:MTLRenderPipelineDescriptor){
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = 4 * MemoryLayout<Float>.size
        vertexDescriptor.layouts[0].stride = 6 * MemoryLayout<Float>.size
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex
        
        pipelineDesc.vertexDescriptor = vertexDescriptor
        
        
    }
    
    private func loadVertexData2(mtlDevice:MTLDevice) -> (MTLBuffer,MTLBuffer){
        
        let va = Vertex(x: -1, y: 1, z: 0)
        let vb = Vertex(x: 1, y: 1, z: 0)
        let vc = Vertex(x: -1, y: -1, z: 0)
        let vd = Vertex(x: 1, y: -1, z: 0)
        
        let ta = TexCoordinate(s: 0, t: 0)
        let tb = TexCoordinate(s: 1, t: 0)
        let tc = TexCoordinate(s: 0, t: 1)
        let td = TexCoordinate(s: 1, t: 1)
        
        indices = [va,vb,vc,
            vc,vb,vd
        ]
        
        var vertices:[Float] = [ -1.0 , -1.0, 0.0, 1.0 ,
                                 1.0, -1.0, 0.0, 1.0 ,
                                 -1.0,  1.0, 0.0, 1.0 ,
                                 1.0,  1.0, 0.0, 1.0 ];
        
        let textureCoordinates:[Float] = [0.0, 1.0,
                                          1.0, 1.0,
                                          0.0, 0.0,
                                          1.0, 0.0];
        
        for v in indices! {
            vertices = v.floatBuffer()
            
        }
        
       
        
        let bufferSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        
        let vertexBuffer = mtlDevice.makeBuffer(bytes: vertices, length: bufferSize, options: [])
        
        let bufferSize2 = textureCoordinates.count * MemoryLayout.size(ofValue: textureCoordinates[0])
        
        let texBuffer = mtlDevice.makeBuffer(bytes: textureCoordinates, length: bufferSize2, options: [])
        
        
        return (vertexBuffer!,texBuffer!)
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
        let (vbuffer,tBuffer) = loadVertexData2(mtlDevice: mtlDevice!)
        
        commandEncoder?.setVertexBuffer(vbuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBuffer(tBuffer, offset: 0, index: 1)
        
      
        
        
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
        
        commandEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        commandEncoder?.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer?.present(drawable)
        }
        commandBuffer?.commit()
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
