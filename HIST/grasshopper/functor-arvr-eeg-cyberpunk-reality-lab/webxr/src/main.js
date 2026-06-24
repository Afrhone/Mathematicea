import * as THREE from 'three';

const canvas = document.getElementById('scene');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.xr.enabled = true;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x05040a);

const camera = new THREE.PerspectiveCamera(70, window.innerWidth/window.innerHeight, 0.01, 100);
camera.position.z = 4;

const group = new THREE.Group();
scene.add(group);

const mat = new THREE.MeshBasicMaterial({ wireframe: true });
for (let i = 0; i < 64; i++) {
  const geo = new THREE.TorusKnotGeometry(0.2 + i*0.006, 0.02, 32, 8);
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.x = Math.sin(i) * 1.5;
  mesh.position.y = Math.cos(i*0.7) * 1.5;
  mesh.position.z = (i - 32) * 0.03;
  group.add(mesh);
}

const light = new THREE.PointLight(0xffffff, 2);
light.position.set(2, 2, 2);
scene.add(light);

async function fetchState() {
  try {
    const r = await fetch('/api/functor/state');
    const j = await r.json();
    document.getElementById('state').textContent = JSON.stringify(j, null, 2);
  } catch (e) {
    document.getElementById('state').textContent = String(e);
  }
}
setInterval(fetchState, 2000);
fetchState();

document.getElementById('xr').onclick = async () => {
  if (navigator.xr) {
    const session = await navigator.xr.requestSession('immersive-vr', { optionalFeatures: ['local-floor'] });
    renderer.xr.setSession(session);
  }
};

renderer.setAnimationLoop((t) => {
  group.rotation.x = t * 0.0001;
  group.rotation.y = t * 0.00017;
  renderer.render(scene, camera);
});
