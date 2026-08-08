#ifndef SSR_PASS_INCLUDED
#define SSR_PASS_INCLUDED

float4 _BaseColor;
float _MaxDistance;
float _Stride;
float _Jitter;
int _Maxsteps;
float _Thickness;



struct Attributes
{
    float3 positionOS : POSITION;
    float3 normal : NORMAL;
    float2 baseUV : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 viewPos : TEXCOORD0;
    float3 normalVS : TEXCOORD1;

};

Varyings SSRPassVertex(Attributes input)
{
    
    
    Varyings output;
    
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    output.viewPos = TransformWorldToView(positionWS);
    
    float3 normalWS = TransformObjectToWorldNormal(input.normal);
    output.normalVS = normalize(TransformWorldToViewDir(normalWS));
    
    
    return output;
    
}



float4 SSRPassFragment(Varyings input) : SV_Target
{
    float3 cs_Orig = input.viewPos;
    float3 V = normalize(input.viewPos);
    float3 N = normalize(input.normalVS);
    float3 cs_Dir = normalize(reflect(V, N));

    
    float Length = ((cs_Orig.z + cs_Dir.z * _MaxDistance) > -_ProjectionParams.y) ? ((-_ProjectionParams.y) - cs_Orig.z) / cs_Dir.z : _MaxDistance;
    float3 cs_EndPoint = cs_Orig + cs_Dir * Length;
    float2 hitPixel = float2(-1, -1);
    
    float4 H0 = mul(UNITY_MATRIX_P, float4(cs_Orig, 1.0)), H1 = mul(UNITY_MATRIX_P, float4(cs_EndPoint, 1.0));
    float K0 = 1.0 / H0.w, K1 = 1.0 / H1.w;
    float3 Q0 = cs_Orig * K0, Q1 = cs_EndPoint * K1;
   
    float2 P0 = H0.xy * K0;
    float2 P1 = H1.xy * K1;
    
    // Screen Space
    P0 = (P0 * float2(0.5, -0.5) + 0.5) * _ScreenParams.xy;
    P1 = (P1 * float2(0.5, -0.5) + 0.5) * _ScreenParams.xy;

    P1 += distance(P0, P1) < 0.0001 ? float2(0.01, 0.01) : float2(0.0, 0.0);
    float2 delta = P1 - P0;
    
    // 많은 변화량 쪽 방향 기준으로 변환
    bool useY = false;
    useY = abs(delta.x) < abs(delta.y);
    delta = useY ? delta.yx : delta.xy;
    P0 = useY ? P0.yx : P0.xy;
    P1 = useY ? P1.yx : P1.xy;
    
    float stepDir = sign(delta.x), invdx = stepDir / delta.x;
    
    float3 dQ = (Q1 - Q0) * invdx;
    float dK = (K1 - K0) * invdx;
    float2 dP = float2(stepDir, delta.y * invdx);
    
    dP *= _Stride;
    dQ *= _Stride;
    dK *= _Stride;
    
    P0 += dP * _Jitter;
    Q0 += dQ * _Jitter;
    K0 += dK * _Jitter;
    
    float prevZMaxEstimate = cs_Orig.z;
    
    float3 Q = Q0;
    float K = K0;
    float stepCount = 0.0;
    float end =  P1.x * stepDir;
    bool isHit = false;
    
    for (float2 P = P0; (P.x * stepDir <= end) && (stepCount < _Maxsteps); P += dP, Q.z += dQ.z, K += dK, stepCount += 1.0)
    {
        hitPixel = useY ? P.yx : P;
        
        // ray marching 시작
        float rayZMin = prevZMaxEstimate;
        float rayZMax = ((dQ.z * 0.5 + Q.z) / (dK * 0.5 + K));
        prevZMaxEstimate = rayZMax;
        
        if (rayZMin > rayZMax)
        {
            float temp = rayZMin;
            rayZMin = rayZMax;
            rayZMax = temp;
        }

        // Z 값 비교 시작 (정밀을 위해 LOAD_TEXTURE2D 사용 - 해당 uv 좌표의 값을 정확히 가져옴(보간 X), But, SAMPLE_TEXTURE2D는 가운데를 샘플링하므로 정확하지 않음)
        float sceneZMax = LOAD_TEXTURE2D(_CameraDepthTexture, int2(hitPixel)).r;
        sceneZMax = -LinearEyeDepth(sceneZMax, _ZBufferParams); // 비선형을 -> 뷰 공간으로 양수로 반환, Unity의 View Space는 카메라 앞쪽이 음수Z이므로 - 붙여야함
        
        float sceneZMin = sceneZMax - _Thickness;
        
        

        if (((rayZMax >= sceneZMin) && (rayZMin <= sceneZMax)) || (sceneZMax == 0))
        {
            isHit = true;
            break;
        }
    }
    
    Q.xy += dQ.xy * stepCount;
    
    //3D 계산
    //float3 hitPoint = Q * (1.0 / K);

    float2 hitUV = hitPixel / _ScreenParams.xy;

    if (isHit)
    {
        // 화면 안쪽 영역 확인
        bool isInsideScreen = (hitPixel.x >= 0 && hitPixel.x < _ScreenParams.x &&
                               hitPixel.y >= 0 && hitPixel.y < _ScreenParams.y);
        
        if (isInsideScreen)
        {
            float3 reflectionColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, hitUV).rgb;
            return float4(reflectionColor, 1.0);
        }
    }
    
    // 반사가 안된 부분
    return float4(_BaseColor.rgb, 1.0);
}

#endif
