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
    float3 vertexCoordinate;
    float2 textureCoordinate;
} ;

struct VertexOut{
    float3 color;
    float4 vertexCoordinate [[position]];
    float2 textureCoordinate;
    
};

vertex VertexOut basic_vertex(constant packed_float3* vertices [[buffer(0)]], constant packed_float2* tex [[buffer(1)]], uint vid [[vertex_id]]){
    
    VertexOut vertexOut;
    vertexOut.vertexCoordinate = float4(vertices[vid],1.0);
    vertexOut.textureCoordinate = tex[vid];
    
    return vertexOut;
}

fragment float4 basic_fragment(const VertexOut vertices [[stage_in]],
                               texture2d<float>  tex2D     [[ texture(0) ]],
                               sampler           sampler2D [[ sampler(0) ]]){
//    return float4(0.3,0.5,0.5,1.0);
    return tex2D.sample(sampler2D,vertices.textureCoordinate);
}
