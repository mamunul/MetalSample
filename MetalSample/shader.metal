//
//  shader.metal
//  MetalSample
//
//  Created by Paradox Lab on 11/11/18.
//  Copyright © 2018 Paradox Lab. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    packed_float3 vertexCoordinate;//must be packed for buffer
    packed_float2 textureCoordinate;
} ;

struct VertexOut{
    float4 vertexCoordinate [[position]];
    float2 textureCoordinate;
    
};

vertex VertexOut basic_vertex(const device VertexIn* vertices [[buffer(0)]],uint vid [[vertex_id]]){
    
    VertexOut vertexOut;
    vertexOut.vertexCoordinate = float4(vertices[vid].vertexCoordinate,1.0);
    vertexOut.textureCoordinate = vertices[vid].textureCoordinate;
    
    return vertexOut;
}

fragment float4 basic_fragment(const VertexOut vertices [[stage_in]],
                               texture2d<float>  tex2D     [[ texture(0) ]],
                               sampler           sampler2D [[ sampler(0) ]]){
//    return float4(0.3,0.5,0.5,1.0);
    return tex2D.sample(sampler2D,vertices.textureCoordinate)*float4(0.3,0.2,0.5,1.0);
}
