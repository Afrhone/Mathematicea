export class TurnEngine extends EventTarget {
  constructor({ compute, renderer, params }) {
    super();
    this.compute = compute;
    this.renderer = renderer;
    this.params = params;
    this.tick = 0;
    this.time = 0;
    this.last = performance.now();
    this.running = false;
    this.gpuCompute = null;
  }

  setGPUCompute(gpuCompute) {
    this.gpuCompute = gpuCompute;
  }

  start() {
    if (this.running) return;
    this.running = true;
    this.last = performance.now();
    requestAnimationFrame(this.frame);
  }

  stop() {
    this.running = false;
  }

  frame = async (now) => {
    if (!this.running) return;
    const dt = Math.min(0.05, (now - this.last) / 1000);
    this.last = now;
    if (!this.params.paused) {
      this.time += dt;
      this.tick += 1;
    }

    let data;
    let mode = 'CPU';
    if (this.params.gpu && this.gpuCompute?.ready) {
      try {
        data = await this.gpuCompute.compute(this.time, this.tick, this.params);
        mode = 'WebGPU compute → Three.js WebGL readback';
      } catch (err) {
        console.warn('WebGPU compute failed, falling back to CPU:', err);
        this.params.gpu = false;
      }
    }

    if (!data) data = this.compute.compute(this.time, this.tick);
    this.renderer.update(data, this.time, this.tick, mode);
    this.dispatchEvent(new CustomEvent('tick', { detail: { time: this.time, tick: this.tick, mode } }));
    requestAnimationFrame(this.frame);
  };
}
