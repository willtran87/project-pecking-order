// The pinned Emscripten WebGL2 presenter queries SCISSOR_TEST and
// DRAW_FRAMEBUFFER_BINDING on every commit. Track those renderer-owned states
// at their mutation points instead; the blit and restoration are unchanged.
export function installFrameStateTracking(gl) {
  if (gl.__peckingFrameState) return gl.__peckingFrameState;
  const state = {
    scissor: gl.getParameter(3089),
    drawFramebuffer: gl.getParameter(36006),
  };
  const enable = gl.enable;
  const disable = gl.disable;
  const bindFramebuffer = gl.bindFramebuffer;
  const deleteFramebuffer = gl.deleteFramebuffer;
  gl.enable = function(cap) {
    const result = enable.call(this, cap);
    if (cap === 3089) state.scissor = true;
    return result;
  };
  gl.disable = function(cap) {
    const result = disable.call(this, cap);
    if (cap === 3089) state.scissor = false;
    return result;
  };
  gl.bindFramebuffer = function(target, framebuffer) {
    const result = bindFramebuffer.call(this, target, framebuffer);
    if (target === 36160 || target === 36009) state.drawFramebuffer = framebuffer;
    return result;
  };
  gl.deleteFramebuffer = function(framebuffer) {
    const result = deleteFramebuffer.call(this, framebuffer);
    if (framebuffer && state.drawFramebuffer === framebuffer) state.drawFramebuffer = null;
    return result;
  };
  // A restored context resets GL state. Read it once after restoration, including
  // any initialization performed by an earlier restoration listener.
  gl.canvas.addEventListener('webglcontextrestored', () => {
    state.scissor = gl.getParameter(3089);
    state.drawFramebuffer = gl.getParameter(36006);
  });
  gl.__peckingFrameState = state;
  return state;
}

const originalBlit = 'blitOffscreenFramebuffer:context=>{var gl=context.GLctx;var prevScissorTest=gl.getParameter(3089);if(prevScissorTest)gl.disable(3089);var prevFbo=gl.getParameter(36006);';
const trackedBlit = 'blitOffscreenFramebuffer:context=>{var gl=context.GLctx;var prevScissorTest=context.peckingFrameState.scissor;if(prevScissorTest)gl.disable(3089);var prevFbo=context.peckingFrameState.drawFramebuffer;';
const originalContext = 'var context={handle,attributes:webGLContextAttributes,version:webGLContextAttributes.majorVersion,GLctx:ctx};';
const trackedContext = 'var context={handle,attributes:webGLContextAttributes,version:webGLContextAttributes.majorVersion,GLctx:ctx,peckingFrameState:GL.trackFrameState(ctx)};';
const installer = `trackFrameState:${installFrameStateTracking.toString()},`;

export function prepareFrameState(js) {
  if (js.includes(trackedBlit) && js.includes(trackedContext) && js.includes(installer)) return js;
  if (js.split(originalBlit).length !== 2 || js.split(originalContext).length !== 2) {
    throw new Error('Unsupported Web frame presenter; verify the pinned engine before patching.');
  }
  return js.replace(originalBlit, installer + trackedBlit).replace(originalContext, trackedContext);
}
