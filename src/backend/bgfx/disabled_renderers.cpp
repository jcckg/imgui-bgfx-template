#include <bgfx/bgfx.h>

namespace bgfx {

struct RendererContextI;

namespace {

RendererContextI* disabledRendererCreate(const Init&) {
    return nullptr;
}

void disabledRendererDestroy() {
}

} // namespace

#if !defined(BGFX_CONFIG_RENDERER_NOOP) || !BGFX_CONFIG_RENDERER_NOOP
namespace noop {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace noop
#endif

#if !defined(BGFX_CONFIG_RENDERER_AGC) || !BGFX_CONFIG_RENDERER_AGC
namespace agc {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace agc
#endif

#if !defined(BGFX_CONFIG_RENDERER_DIRECT3D11) || !BGFX_CONFIG_RENDERER_DIRECT3D11
namespace d3d11 {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace d3d11
#endif

#if !defined(BGFX_CONFIG_RENDERER_DIRECT3D12) || !BGFX_CONFIG_RENDERER_DIRECT3D12
namespace d3d12 {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace d3d12
#endif

#if !defined(BGFX_CONFIG_RENDERER_GNM) || !BGFX_CONFIG_RENDERER_GNM
namespace gnm {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace gnm
#endif

#if !defined(BGFX_CONFIG_RENDERER_METAL) || !BGFX_CONFIG_RENDERER_METAL
namespace mtl {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace mtl
#endif

#if !defined(BGFX_CONFIG_RENDERER_NVN) || !BGFX_CONFIG_RENDERER_NVN
namespace nvn {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace nvn
#endif

#if (!defined(BGFX_CONFIG_RENDERER_OPENGL) || !BGFX_CONFIG_RENDERER_OPENGL) && (!defined(BGFX_CONFIG_RENDERER_OPENGLES) || !BGFX_CONFIG_RENDERER_OPENGLES)
namespace gl {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace gl
#endif

#if !defined(BGFX_CONFIG_RENDERER_VULKAN) || !BGFX_CONFIG_RENDERER_VULKAN
namespace vk {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace vk
#endif

#if !defined(BGFX_CONFIG_RENDERER_WEBGPU) || !BGFX_CONFIG_RENDERER_WEBGPU
namespace wgpu {
RendererContextI* rendererCreate(const Init& init) {
    return disabledRendererCreate(init);
}
void rendererDestroy() {
    disabledRendererDestroy();
}
} // namespace wgpu
#endif

} // namespace bgfx
