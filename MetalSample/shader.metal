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
    float3 vertexCoordinate [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
} ;

struct VertexOut{
    float4 p [[position]];
    float2 textureCoordinate;
    
};

vertex VertexOut basic_vertex(const VertexIn vertices [[stage_in]]){
    
    VertexOut vertexOut;
    vertexOut.textureCoordinate = vertices.textureCoordinate;
    
    return vertexOut;
}

fragment float4 basic_fragment(const VertexOut vertices [[stage_in]],
                               texture2d<float>  tex2D     [[ texture(0) ]],
                               sampler           sampler2D [[ sampler(0) ]]){
    return float4(0.3,0.5,0.5,1);
//    return tex2D.sample(sampler2D,vertices.textureCoordinate);
}
