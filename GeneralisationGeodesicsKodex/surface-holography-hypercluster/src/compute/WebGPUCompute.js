const WORKGROUP_SIZE = 64;

export class WebGPUCompute {
  constructor({ resolution }) {
    this.resolution = resolution;
    this.count = resolution * resolution;
    this.ready = false;
  }

  async init() {
    if (!navigator.gpu) throw new Error('navigator.gpu is not available. Use Chrome/Edge on localhost or HTTPS.');
    this.adapter = await navigator.gpu.requestAdapter();
    if (!this.adapter) throw new Error('No WebGPU adapter found.');
    this.device = await this.adapter.requestDevice();
    const source = await fetch(new URL('../shaders/holography.compute.wgsl', import.meta.url)).then(r => r.text());
    this.module = this.device.createShaderModule({ label: 'surface-holography-compute', code: source });
    this.pipeline = this.device.createComputePipeline({
      label: 'hypercluster-compute-pipeline',
      layout: 'auto',
      compute: { module: this.module, entryPoint: 'main' }
    });
    this.allocate(this.resolution);
    this.ready = true;
  }

  allocate(resolution) {
    this.resolution = resolution;
    this.count = resolution * resolution;
    this.byteLength = this.count * 10 * Float32Array.BYTES_PER_ELEMENT;
    this.output = this.device.createBuffer({
      label: 'hypercluster-output-buffer',
      size: this.byteLength,
      usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
    });
    this.readback = this.device.createBuffer({
      label: 'hypercluster-readback-buffer',
      size: this.byteLength,
      usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
    });
    this.uniform = this.device.createBuffer({
      label: 'hypercluster-param-uniform',
      size: 4 * 16,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
    });
    this.bindGroup = this.device.createBindGroup({
      label: 'hypercluster-bind-group',
      layout: this.pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.output } },
        { binding: 1, resource: { buffer: this.uniform } }
      ]
    });
    this.data = new Float32Array(this.count * 10);
  }

  async compute(t, tick, params) {
    if (params.resolution !== this.resolution) this.allocate(params.resolution);
    const u = new Float32Array(16);
    u[0] = t;
    u[1] = tick;
    u[2] = this.resolution;
    u[3] = this.count;
    u[4] = params.amplitude;
    u[5] = params.holography;
    u[6] = params.entanglement;
    u[7] = params.supersymmetry;
    u[8] = params.asymmetry;
    u[9] = params.bubble;
    u[10] = params.curl;
    u[11] = params.divergence;
    u[12] = params.spin;
    u[13] = params.wave;
    u[14] = params.thetaOperand;
    u[15] = params.df;
    this.device.queue.writeBuffer(this.uniform, 0, u.buffer);

    const encoder = this.device.createCommandEncoder({ label: 'hypercluster-compute-encoder' });
    const pass = encoder.beginComputePass({ label: 'hypercluster-compute-pass' });
    pass.setPipeline(this.pipeline);
    pass.setBindGroup(0, this.bindGroup);
    pass.dispatchWorkgroups(Math.ceil(this.count / WORKGROUP_SIZE));
    pass.end();
    encoder.copyBufferToBuffer(this.output, 0, this.readback, 0, this.byteLength);
    this.device.queue.submit([encoder.finish()]);

    await this.readback.mapAsync(GPUMapMode.READ);
    this.data.set(new Float32Array(this.readback.getMappedRange()).slice());
    this.readback.unmap();
    return this.data;
  }
}
