import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

export class ThreeSurfaceRenderer {
  constructor({ container, resolution, params }) {
    this.container = container;
    this.resolution = resolution;
    this.params = params;
    this.count = resolution * resolution;
    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(0x03030a, 0.045);
    this.camera = new THREE.PerspectiveCamera(55, innerWidth / innerHeight, 0.01, 100);
    this.camera.position.set(0, 0.65, 3.4);
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.setSize(innerWidth, innerHeight);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    container.appendChild(this.renderer.domElement);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.04;
    this.controls.autoRotate = true;
    this.controls.autoRotateSpeed = 0.38;

    this.clock = new THREE.Clock();
    this.initScene();
    addEventListener('resize', this.resize);
  }

  initScene() {
    const ambient = new THREE.AmbientLight(0xffffff, 0.42);
    const key = new THREE.DirectionalLight(0xb6d6ff, 1.25);
    key.position.set(3, 2, 4);
    const rim = new THREE.PointLight(0xff9bff, 16, 12);
    rim.position.set(-2, 1.2, -2);
    this.scene.add(ambient, key, rim);

    this.group = new THREE.Group();
    this.scene.add(this.group);
    this.buildGeometry(this.resolution);
    this.buildReferenceShells();
  }

  buildGeometry(resolution) {
    this.resolution = resolution;
    this.count = resolution * resolution;
    if (this.points) {
      this.group.remove(this.points);
      this.points.geometry.dispose();
      this.points.material.dispose();
    }
    this.positions = new Float32Array(this.count * 3);
    this.colors = new Float32Array(this.count * 3);
    this.sizes = new Float32Array(this.count);
    this.geometry = new THREE.BufferGeometry();
    this.geometry.setAttribute('position', new THREE.BufferAttribute(this.positions, 3));
    this.geometry.setAttribute('color', new THREE.BufferAttribute(this.colors, 3));
    this.geometry.setAttribute('size', new THREE.BufferAttribute(this.sizes, 1));

    this.material = new THREE.ShaderMaterial({
      transparent: true,
      depthWrite: false,
      vertexColors: true,
      uniforms: { uTime: { value: 0 }, uPixelRatio: { value: Math.min(devicePixelRatio, 2) } },
      vertexShader: `
        attribute float size;
        varying vec3 vColor;
        uniform float uTime;
        uniform float uPixelRatio;
        void main() {
          vColor = color;
          vec4 mv = modelViewMatrix * vec4(position, 1.0);
          gl_PointSize = max(1.2, size * uPixelRatio * 680.0 / max(0.25, -mv.z));
          gl_Position = projectionMatrix * mv;
        }
      `,
      fragmentShader: `
        varying vec3 vColor;
        void main() {
          vec2 uv = gl_PointCoord.xy - 0.5;
          float d = dot(uv, uv);
          float core = smoothstep(0.25, 0.0, d);
          float halo = smoothstep(0.25, 0.02, d) * 0.45;
          if (core + halo < 0.02) discard;
          gl_FragColor = vec4(vColor * (0.72 + core * 1.4), core * 0.86 + halo);
        }
      `
    });
    this.points = new THREE.Points(this.geometry, this.material);
    this.group.add(this.points);
  }

  buildReferenceShells() {
    const shellMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.055, wireframe: true });
    const shell = new THREE.Mesh(new THREE.SphereGeometry(1, 48, 24), shellMat);
    this.group.add(shell);

    const ringMat = new THREE.LineBasicMaterial({ color: 0x88ddff, transparent: true, opacity: 0.22 });
    for (let k = 0; k < 3; k++) {
      const curve = new THREE.EllipseCurve(0, 0, 1 + k * 0.23, 1 + k * 0.23, 0, Math.PI * 2, false, 0);
      const pts = curve.getPoints(192).map(p => new THREE.Vector3(p.x, 0, p.y));
      const line = new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(pts), ringMat.clone());
      line.rotation.x = k * 0.55 + 0.2;
      line.rotation.z = k * 0.33;
      this.group.add(line);
    }
  }

  update(data, time, tick, mode) {
    if (this.count !== data.length / 10) this.buildGeometry(Math.sqrt(data.length / 10));
    for (let i = 0; i < this.count; i++) {
      const src = i * 10;
      const dst = i * 3;
      this.positions[dst] = data[src];
      this.positions[dst + 1] = data[src + 1];
      this.positions[dst + 2] = data[src + 2];
      const phase = data[src + 4];
      const div = data[src + 5];
      const curl = data[src + 6];
      const energy = data[src + 7];
      this.colors[dst] = 0.18 + 0.82 * phase;
      this.colors[dst + 1] = 0.28 + 0.62 * curl;
      this.colors[dst + 2] = 0.45 + 0.55 * (1.0 - div * 0.45 + energy * 0.35);
      this.sizes[i] = data[src + 9];
    }
    this.geometry.attributes.position.needsUpdate = true;
    this.geometry.attributes.color.needsUpdate = true;
    this.geometry.attributes.size.needsUpdate = true;
    this.geometry.computeBoundingSphere();
    this.group.rotation.y = time * 0.055;
    this.group.rotation.x = Math.sin(time * 0.11) * 0.08;
    this.material.uniforms.uTime.value = time;
    this.controls.update();
    this.renderer.render(this.scene, this.camera);
    this.mode = mode;
  }

  resize = () => {
    this.camera.aspect = innerWidth / innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.setSize(innerWidth, innerHeight);
    if (this.material) this.material.uniforms.uPixelRatio.value = Math.min(devicePixelRatio, 2);
  };

  dispose() {
    removeEventListener('resize', this.resize);
    this.renderer.dispose();
  }
}
