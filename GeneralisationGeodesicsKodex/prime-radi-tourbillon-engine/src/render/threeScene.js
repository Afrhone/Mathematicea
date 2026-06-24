import * as THREE from 'three';
import { standardModelPalette } from '../engine/standardModelToy.js';

export class PrimeRadiScene {
  constructor(container) {
    this.container = container;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(58, innerWidth / innerHeight, 0.01, 100);
    this.camera.position.set(0, 0, 6.2);
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(2, devicePixelRatio));
    this.renderer.setSize(innerWidth, innerHeight);
    container.appendChild(this.renderer.domElement);
    this.clockGroup = new THREE.Group();
    this.fieldGroup = new THREE.Group();
    this.scene.add(this.fieldGroup, this.clockGroup);
    this.points = null;
    this.coil = null;
    this.makeStars();
    window.addEventListener('resize', () => this.resize());
  }

  makeStars() {
    const geometry = new THREE.BufferGeometry();
    const count = 800;
    const pos = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const r = 9 + Math.random() * 20;
      const a = Math.random() * Math.PI * 2;
      const z = (Math.random() - 0.5) * 14;
      pos[i * 3] = Math.cos(a) * r;
      pos[i * 3 + 1] = Math.sin(a) * r;
      pos[i * 3 + 2] = z;
    }
    geometry.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const mat = new THREE.PointsMaterial({ size: 0.018, transparent: true, opacity: 0.65 });
    this.scene.add(new THREE.Points(geometry, mat));
  }

  resize() {
    this.camera.aspect = innerWidth / innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(innerWidth, innerHeight);
  }

  update(state, config = {}) {
    const { field, tourbillon } = state;
    this.updateField(field, config.smMix ?? 0.42);
    this.updateCoil(tourbillon);
    this.clockGroup.rotation.z += 0.004;
    this.fieldGroup.rotation.z -= 0.0015;
  }

  updateField(fieldState, smMix) {
    const { field, width, height } = fieldState;
    const stride = 3;
    const count = Math.floor(width * height / stride / stride);
    const pos = new Float32Array(count * 3);
    const colors = new Float32Array(count * 3);
    let k = 0;
    for (let y = 0; y < height; y += stride) {
      for (let x = 0; x < width; x += stride) {
        const i = y * width + x;
        const u = x / (width - 1);
        const v = y / (height - 1);
        const theta = u * Math.PI * 2;
        const strip = (v - 0.5) * 2;
        const twist = theta * 0.5;
        const r = 1.2 + 0.5 * strip * Math.cos(twist) + field[i] * 0.22;
        pos[k * 3] = r * Math.cos(theta);
        pos[k * 3 + 1] = r * Math.sin(theta);
        pos[k * 3 + 2] = strip * Math.sin(twist) + field[i] * 0.9;
        const c = standardModelPalette(field[i], smMix);
        colors[k * 3] = c.r;
        colors[k * 3 + 1] = c.g;
        colors[k * 3 + 2] = c.b;
        k++;
      }
    }
    if (!this.points) {
      const g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      g.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      const m = new THREE.PointsMaterial({ size: 0.028, vertexColors: true, transparent: true, opacity: 0.86 });
      this.points = new THREE.Points(g, m);
      this.fieldGroup.add(this.points);
    } else {
      this.points.geometry.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      this.points.geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      this.points.geometry.attributes.position.needsUpdate = true;
      this.points.geometry.attributes.color.needsUpdate = true;
    }
  }

  updateCoil(vertices) {
    const pos = new Float32Array(vertices.length * 3);
    const colors = new Float32Array(vertices.length * 3);
    vertices.forEach((v, i) => {
      pos[i * 3] = v.x;
      pos[i * 3 + 1] = v.y;
      pos[i * 3 + 2] = v.z;
      const c = standardModelPalette(Math.sin(v.prime) * 0.5 + v.torsion, 0.55);
      colors[i * 3] = c.r;
      colors[i * 3 + 1] = c.g;
      colors[i * 3 + 2] = c.b;
    });
    if (!this.coil) {
      const g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      g.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      const m = new THREE.LineBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.92 });
      this.coil = new THREE.Line(g, m);
      this.clockGroup.add(this.coil);
    } else {
      this.coil.geometry.setAttribute('position', new THREE.BufferAttribute(pos, 3));
      this.coil.geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    }
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }
}
