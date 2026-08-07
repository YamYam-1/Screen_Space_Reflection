# Screen Space Reflection (Unity URP)

Efficient GPU Screen-Space Ray Tracing 논문을 참고해
Unity URP에 맞게 **View Space Ray Marching 기반 Screen Space Reflection(SSR)** 을 구현한 프로젝트입니다.

3D Ray를 Screen Space(2D)로 변환하여 DDA 방식으로 추적하고, Depth Buffer를 이용해 반사 지점을 구합니다.

---

## Demo

<img width="500" height="300" alt="Image" src="https://github.com/user-attachments/assets/2c5fca5b-5244-4b5e-84be-aba34f5b9afa" />

---

## Tech Stack

- Universal Render Pipeline (URP)
- HLSL

---

## Features

SSR은 Fragment 단계에서 진행됩니다.
먼저 해당 기술은 screen space 에서 진행되기 때문에 vertex에서 view space 정보를 넘겨줍니다.
screen space 는 쉽게 생각하면 됩니다. 그저 모니터의 픽셀 좌표라고 생각하시면 됩니다.

View Space -> Clip Space -> Screen Space

```cpp
// View Space
float4 H0 = mul(UNITY_MATRIX_P, float4(cs_Orig, 1.0));
float4 H1 = mul(UNITY_MATRIX_P, float4(cs_EndPoint, 1.0));

// Perspective Divide
float k0 = 1.0 / H0.w;
float k1 = 1.0 / H1.w;

float2 P0 = H0.xy * k0;
float2 P1 = H1.xy * k1;

// Screen Space
P0 = (P0 * float2(0.5, -0.5) + 0.5) * _ScreenParams.xy;
P1 = (P1 * float2(0.5, -0.5) + 0.5) * _ScreenParams.xy;
float2 P1 = H1.xy * k1;
```

구해진 Screen Space 에서 2D 차원에서 DDA 를 통해 인접한 픽셀로 이동합니다.
그 전에 변화량이 큰 방향으로 움직여야 샘플링에서 좋은 효과를 낼 수 있습니다.

```cpp
// 많은 변화량 쪽 방향 기준으로 변환
bool useY = false;
useY = abs(delta.x) < abs(delta.y);
delta = useY ? delta.yx : delta.xy;
P0 = useY ? P0.yx : P0.xy;
P1 = useY ? P1.yx : P1.xy;
```
이후 해당 ray가 marching(전진) 하면서 해당 픽셀이 저장된 depth_buffer 로 부딪혔는지 비교합니다.
논문에서는 G3D 엔진을 사용해서 depth 비교를 할 때 차이점이 있습니다.
URP 에서는 LOAD_TEXTURE2D를 통해 현재 카메라에 저장된 Depth_texture를 사용할 겁니다.
이 Load된 텍스처는 비선형으로 되어있어서 사용하기엔 부적절합니다. LinearEyeDepth을 통해 제대로 된 선형으로 바꿔줘야합니다.

```cpp
 // Z 값 비교 시작 (정밀을 위해 LOAD_TEXTURE2D 사용 - 해당 uv 좌표의 값을 정확히 가져옴(보간 X), But, SAMPLE_TEXTURE2D는 가운데를 샘플링하므로 정확하지 않음)
float sceneZMax = LOAD_TEXTURE2D(_CameraDepthTexture, int2(hitPixel)).r;
sceneZMax = -LinearEyeDepth(sceneZMax, _ZBufferParams); // 비선형을 -> 뷰 공간으로 양수로 반환, Unity의 View Space는 카메라 앞쪽이 음수Z이므로 - 붙여야함
        
float sceneZMin = sceneZMax - _Thickness;
        
if (((rayZMax >= sceneZMin) && (rayZMin <= sceneZMax)) || (sceneZMax == 0))
{
      isHit = true;
      break;
}
```
만약 ray가 depth 비교를 통해 구간에 맞으면 해당 픽셀은 반사를 할것입니다.
```cpp
if (((rayZMax >= sceneZMin) && (rayZMin <= sceneZMax)) || (sceneZMax == 0))
{
  isHit = true;
  break;
}
```

### 
---

## Refrence
- Efficient GPU Screen-Space Ray Tracing - Morgan McGuire
