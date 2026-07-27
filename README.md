# Screen Space Reflection (Unity URP)

Unity URP에서 **View Space Ray Marching 기반 Screen Space Reflection(SSR)** 을 직접 구현한 프로젝트입니다.

URP는 HDRP와 달리 기본적으로 Screen Space Reflection 기능을 제공하지 않습니다.

그래픽 렌더링 기법을 이해하기 위해 SSR을 직접 구현했으며,
이후 Planar Reflection과 비교하여 프로젝트에 적합한 반사 방식을 선택했습니다.

---

## Demo

<p align="center">
  <img src="./Images/SSR.gif" width="700"/>
</p>

---

## Tech Stack

- Unity 6
- Universal Render Pipeline (URP)
- HLSL
- C#

---

## Features

### View Space Ray Marching

카메라 공간(View Space)에서 반사 벡터를 계산한 뒤

Ray Marching을 수행하여 화면상의 Depth와 충돌 여부를 검사합니다.
