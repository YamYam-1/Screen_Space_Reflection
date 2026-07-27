Shader "CustomShader/SSR"
{
    Properties
    {
        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MaxDistance("MaxDistance", float) = 20.0
        _Stride("stride", float) = 0.3
        _Jitter("jitter", float) = 0.3
        _Thickness("Thickness", float) = 0.5
        _Maxsteps("Maxsteps", int) = 50

    }

    SubShader
    {

        Tags{   
                    "RenderPipeline"="UniversalPipeline"
                    "RenderType"="Transparent"
                    "Queue"="Transparent"
                }

        Pass
        {
            ZWrite On
            ZTest Less

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #pragma vertex SSRPassVertex
            #pragma fragment SSRPassFragment
            #include "SSRPass.hlsl"


            ENDHLSL

        }

    }

}
