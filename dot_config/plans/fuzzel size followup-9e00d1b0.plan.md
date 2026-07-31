<!-- 9e00d1b0-d366-4f81-ba43-42383190adbe -->
# fuzzel이 여전한 이유 / 다음 조치

## 지금 확인된 사실

이 세션의 활성 출력:

- **HDMI-A-1, 2560x1440, scale=1.0** (Philips 32")

fuzzel 1.12.0 로그로 비교하면:

- `dpi-aware=yes` → `24.00pt / 31.03px` (DPI 93)
- `dpi-aware=auto` → 동일 (`31.03px`)
- `dpi-aware=no` → `32.00px` (DPI 96)

**scale 1에서는 yes ≈ auto라서, 이전 수정은 이 모니터에서 거의 티가 안 납니다.** “여전한데?”가 여기서 나온 거라면 그게 이유입니다.

kitty는 `font_size 11`을 진짜 pt/DPI로 그려서 compositor scale과 별개로 물리 크기가 안정적이고, fuzzel `size=24`는 런처용으로 원래 큰 편입니다.

## 다음에 할 일 (체감한 상황에 따라)

**A. 1.6 스케일 모니터에서 테스트했고 여전히 큼**

[`~/.config/fuzzel/fuzzel.ini`](~/.config/fuzzel/fuzzel.ini)에서 `size`를 낮춥니다. 예: `size=24` → `size=15` (kitty 11과 런처 가독성 사이의 타협). `dpi-aware=yes`는 유지. 그다음 두 프로필에서 fuzzel 한 번씩 확인 후, 필요하면 1pt 단위로만 微调. chezmoi add → commit/push.

**B. 지금 이 HDMI(scale 1) 화면에서도 여전히/원래 큼**

그건 스케일 이슈가 아니라 **24pt 자체가 큼**. 같은 방식으로 `size`만 줄이면 됩니다.

## 구현 시 기본값

별도 답이 없으면 **A로 보고 `size=15` + `dpi-aware=yes` 유지**로 진행합니다. (저해상도에서 쓰던 24보다 작아지지만, 스케일된 쪽과 맞춰지는 쪽을 우선.)
