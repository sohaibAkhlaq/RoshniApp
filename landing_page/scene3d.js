/* ==========================================================================
   ROSHNI (روشنی) — 3D PROCEDURAL THREE.JS UNIVERSE
   Zero-Gravity Smartphone, Floating AI Particles, & Scroll-Linked Storytelling
   ========================================================================== */

// --- Global 3D State ---
let scene, camera, renderer;
let phoneGroup, phoneScreenMesh, screenTexture, screenCanvas, screenCtx;
let particleSystem, radarSphere, sonarRings = [], explodedLayers = [];
let originalParticlePositions = null;
let targetMouseX = 0, targetMouseY = 0;
let touchStartX = 0, touchSpinRotation = 0, isTouchSpinning = false;
let currentScrollProgress = 0;
let activeSimMode = 'mode-a'; // mode-a: PKR, mode-b: Urdu OCR, mode-c: Obstacle, custom: Upload
let activeCustomImage = null;
let isPhoneScanning = false;
let scanProgress = 1.0; // 0.0 to 1.0
let scanDuration = 1.6; // seconds
let scanStartTime = 0;
let clock = new THREE.Clock();

// --- Initialize 3D Universe ---
function init3DScene() {
  const container = document.getElementById('canvas-3d-container');
  if (!container || typeof THREE === 'undefined') return;

  scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0x060913, 0.035);

  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.set(0, 0, 16);

  renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, powerPreference: "high-performance" });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  container.appendChild(renderer.domElement);

  // --- Lighting Setup ---
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
  scene.add(ambientLight);

  const goldLight = new THREE.PointLight(0xFFCA28, 2.5, 30);
  goldLight.position.set(8, 8, 8);
  goldLight.castShadow = true;
  scene.add(goldLight);

  const cyanLight = new THREE.PointLight(0x00E5FF, 2.5, 30);
  cyanLight.position.set(-8, -8, 6);
  scene.add(cyanLight);

  const topLight = new THREE.DirectionalLight(0xffffff, 0.8);
  topLight.position.set(0, 15, 10);
  scene.add(topLight);

  // --- Build Procedural Objects ---
  createProceduralSmartphone();
  createFloatingAIParticles();
  createRadarAndSonar();
  createExplodedArchitectureLayers();

  window.addEventListener('resize', onWindowResize);
  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('touchstart', onTouchStart, { passive: true });
  document.addEventListener('touchmove', onTouchMove, { passive: true });
  document.addEventListener('touchend', onTouchEnd, { passive: true });

  animate3D();
}

// --- 1. Procedural Claymorphic/Glassmorphic Smartphone ---
function createProceduralSmartphone() {
  phoneGroup = new THREE.Group();

  const bodyGeo = new THREE.BoxGeometry(3.6, 7.4, 0.4);
  const bodyMat = new THREE.MeshStandardMaterial({
    color: 0x0F1322,
    roughness: 0.2,
    metalness: 0.8,
  });
  const phoneBody = new THREE.Mesh(bodyGeo, bodyMat);
  phoneBody.castShadow = true;
  phoneBody.receiveShadow = true;
  phoneGroup.add(phoneBody);

  const borderGeo = new THREE.BoxGeometry(3.64, 7.44, 0.38);
  const borderMat = new THREE.MeshBasicMaterial({
    color: 0xFFCA28,
    wireframe: true,
    transparent: true,
    opacity: 0.3
  });
  const borderMesh = new THREE.Mesh(borderGeo, borderMat);
  phoneGroup.add(borderMesh);

  screenCanvas = document.createElement('canvas');
  screenCanvas.width = 512;
  screenCanvas.height = 1024;
  screenCtx = screenCanvas.getContext('2d');
  
  screenTexture = new THREE.CanvasTexture(screenCanvas);
  screenTexture.anisotropy = 16;

  const screenGeo = new THREE.PlaneGeometry(3.4, 7.1);
  const screenMat = new THREE.MeshBasicMaterial({
    map: screenTexture,
    transparent: true,
    opacity: 0.95
  });
  phoneScreenMesh = new THREE.Mesh(screenGeo, screenMat);
  phoneScreenMesh.position.z = 0.21;
  phoneGroup.add(phoneScreenMesh);

  const lensGeo = new THREE.CylinderGeometry(0.35, 0.35, 0.15, 32);
  const lensMat = new THREE.MeshStandardMaterial({ color: 0x00E5FF, metalness: 0.9, roughness: 0.1 });
  
  const lens1 = new THREE.Mesh(lensGeo, lensMat);
  lens1.rotation.x = Math.PI / 2;
  lens1.position.set(-1.0, 2.7, -0.25);
  phoneGroup.add(lens1);

  const lens2 = new THREE.Mesh(lensGeo, lensMat);
  lens2.rotation.x = Math.PI / 2;
  lens2.position.set(-1.0, 1.8, -0.25);
  phoneGroup.add(lens2);

  updatePhoneScreenContent('mode-a');
  scene.add(phoneGroup);
}

// --- Trigger Interactive Golden Laser Scan Sweep ---
function triggerPhoneLaserScan(mode, customImg = null) {
  activeSimMode = mode;
  if (customImg) activeCustomImage = customImg;
  isPhoneScanning = true;
  scanProgress = 0.0;
  scanStartTime = clock.getElapsedTime();
  updatePhoneScreenContent(mode, activeCustomImage, 0.0, true);
}

// --- Dynamic Canvas Texture Updater for Simulator Sandbox ---
function updatePhoneScreenContent(mode, customImg = null, progress = 1.0, isScanning = false) {
  activeSimMode = mode;
  if (customImg) activeCustomImage = customImg;
  if (!screenCtx) return;

  const ctx = screenCtx;
  const w = screenCanvas.width;
  const h = screenCanvas.height;
  const scanY = 160 + progress * 680; // Laser Y position from Y=160 to Y=840

  // Background Dark Obsidian Gradient
  const grad = ctx.createLinearGradient(0, 0, 0, h);
  grad.addColorStop(0, '#060913');
  grad.addColorStop(1, '#0F1322');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, w, h);

  // Roshni Header Bar
  ctx.fillStyle = '#FFCA28';
  ctx.font = 'bold 36px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('✨ ROSHNI AI', w / 2, 80);
  ctx.font = '22px sans-serif';
  ctx.fillStyle = '#00E5FF';
  ctx.fillText('Live Vision Assistant', w / 2, 120);

  ctx.strokeStyle = 'rgba(255, 202, 40, 0.4)';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(40, 150);
  ctx.lineTo(w - 40, 150);
  ctx.stroke();

  // --- Draw Base Graphics or Uploaded Image ---
  if (mode === 'custom' && activeCustomImage) {
    ctx.save();
    ctx.strokeStyle = 'rgba(255, 202, 40, 0.4)';
    ctx.lineWidth = 4;
    ctx.strokeRect(40, 170, w - 80, 660);
    ctx.beginPath();
    ctx.rect(40, 170, w - 80, 660);
    ctx.clip();
    ctx.drawImage(activeCustomImage, 40, 170, w - 80, 660);
    ctx.restore();

    // Dynamic Bounding Boxes over user's image
    drawCornerBoundingBox(ctx, 65, 220, 380, 260, '[5000 PKR Note - 99.6%]', scanY, !isScanning);
    drawCornerBoundingBox(ctx, 90, 520, 330, 240, '[Urdu Signboard - Detected]', scanY, !isScanning);
  }
  else if (mode === 'mode-a') {
    ctx.fillStyle = '#10B981';
    ctx.fillRect(60, 220, w - 120, 280);
    ctx.strokeStyle = '#FFCA28';
    ctx.lineWidth = 6;
    ctx.strokeRect(60, 220, w - 120, 280);

    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 55px sans-serif';
    ctx.fillText('₨ 1000', w / 2, 340);
    ctx.font = '28px sans-serif';
    ctx.fillText('STATE BANK OF PAKISTAN', w / 2, 400);

    drawCornerBoundingBox(ctx, 45, 200, w - 90, 320, '[1000 PKR Note - 99.8%]', scanY, !isScanning);
  } 
  else if (mode === 'mode-b') {
    ctx.fillStyle = 'rgba(255, 255, 255, 0.08)';
    ctx.fillRect(50, 200, w - 100, 350);
    ctx.strokeStyle = '#FFCA28';
    ctx.lineWidth = 3;
    ctx.strokeRect(50, 200, w - 100, 350);

    ctx.fillStyle = '#FFCA28';
    ctx.font = 'bold 50px serif';
    ctx.fillText('روشنی ہمیشہ آپ کے ساتھ', w / 2, 330);
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '26px sans-serif';
    ctx.fillText('Extracted Urdu Script', w / 2, 410);

    drawCornerBoundingBox(ctx, 40, 190, w - 80, 370, '[Urdu OCR Script - 100%]', scanY, !isScanning);
  } 
  else if (mode === 'mode-c') {
    ctx.strokeStyle = '#FF4444';
    ctx.lineWidth = 4;
    ctx.strokeRect(70, 230, 160, 280);
    ctx.fillStyle = '#FF4444';
    ctx.font = 'bold 22px sans-serif';
    ctx.fillText('Chair 1.2m', 150, 220);

    ctx.strokeStyle = '#00E5FF';
    ctx.lineWidth = 4;
    ctx.strokeRect(270, 270, 180, 220);
    ctx.fillStyle = '#00E5FF';
    ctx.fillText('Door 2.8m', 360, 260);

    drawCornerBoundingBox(ctx, 60, 210, 180, 310, '[Obstacle: Chair - 1.2m]', scanY, !isScanning);
    drawCornerBoundingBox(ctx, 260, 250, 200, 250, '[Exit: Doorway - 2.8m]', scanY, !isScanning);
  }

  // --- Glowing Golden Laser Line Sweep ---
  if (isScanning && progress < 1.0) {
    ctx.save();
    ctx.shadowColor = '#FFCA28';
    ctx.shadowBlur = 35;
    ctx.strokeStyle = '#FFCA28';
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(30, scanY);
    ctx.lineTo(w - 30, scanY);
    ctx.stroke();

    // Bright White Core
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.restore();
  }

  // Bottom Audio Waveform Animation
  ctx.fillStyle = '#00E5FF';
  for (let i = 0; i < 15; i++) {
    const barH = 20 + Math.random() * 80;
    ctx.fillRect(70 + i * 26, 880 - barH, 14, barH);
  }
  ctx.fillStyle = '#FFCA28';
  ctx.font = '24px sans-serif';
  ctx.fillText(isScanning ? '⚡ Laser Scanning in Progress...' : '🔊 Audio Neural Guidance Active', w / 2, 940);

  screenTexture.needsUpdate = true;
}

// --- Dynamic Bounding Box with Futuristic Corner Brackets & Confidence Tag ---
function drawCornerBoundingBox(ctx, x, y, w, h, label, scanY, isFinished) {
  if (!isFinished && scanY < y) return;

  const alpha = isFinished ? 1.0 : Math.min(1.0, (scanY - y) / (h * 0.45));
  if (alpha <= 0) return;

  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.shadowColor = '#00E5FF';
  ctx.shadowBlur = 20;
  ctx.strokeStyle = '#00E5FF';
  ctx.lineWidth = 4;
  
  const cLen = Math.min(w, h) * 0.22;

  // Top-Left
  ctx.beginPath(); ctx.moveTo(x + cLen, y); ctx.lineTo(x, y); ctx.lineTo(x, y + cLen); ctx.stroke();
  // Top-Right
  ctx.beginPath(); ctx.moveTo(x + w - cLen, y); ctx.lineTo(x + w, y); ctx.lineTo(x + w, y + cLen); ctx.stroke();
  // Bottom-Left
  ctx.beginPath(); ctx.moveTo(x, y + h - cLen); ctx.lineTo(x, y + h); ctx.lineTo(x + cLen, y + h); ctx.stroke();
  // Bottom-Right
  ctx.beginPath(); ctx.moveTo(x + w - cLen, y + h); ctx.lineTo(x + w, y + h); ctx.lineTo(x + w, y + h - cLen); ctx.stroke();

  // Cyan Translucent Fill
  ctx.fillStyle = 'rgba(0, 229, 255, 0.12)';
  ctx.fillRect(x, y, w, isFinished ? h : Math.min(h, scanY - y));

  // Floating AI Confidence Tag Pill
  ctx.font = 'bold 20px sans-serif';
  const textMetrics = ctx.measureText(label);
  const tagW = textMetrics.width + 30;
  const tagX = x;
  const tagY = y - 36;
  
  ctx.fillStyle = '#00E5FF';
  ctx.shadowBlur = 15;
  ctx.fillRect(tagX, tagY, tagW, 32);
  
  ctx.fillStyle = '#060913';
  ctx.shadowBlur = 0;
  ctx.fillText(label, tagX + 15, tagY + 23);
  
  ctx.restore();
}

// --- 2. Floating AI Particles in Zero Gravity ---
function createFloatingAIParticles() {
  const count = 200;
  const geo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const colors = new Float32Array(count * 3);
  
  const colorGold = new THREE.Color(0xFFCA28);
  const colorCyan = new THREE.Color(0x00E5FF);

  for (let i = 0; i < count; i++) {
    positions[i * 3] = (Math.random() - 0.5) * 40;
    positions[i * 3 + 1] = (Math.random() - 0.5) * 40;
    positions[i * 3 + 2] = (Math.random() - 0.5) * 30;

    const chosenColor = Math.random() > 0.4 ? colorGold : colorCyan;
    colors[i * 3] = chosenColor.r;
    colors[i * 3 + 1] = chosenColor.g;
    colors[i * 3 + 2] = chosenColor.b;
  }

  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

  const mat = new THREE.PointsMaterial({
    size: 0.25,
    vertexColors: true,
    transparent: true,
    opacity: 0.8,
    blending: THREE.AdditiveBlending
  });

  originalParticlePositions = new Float32Array(positions);
  particleSystem = new THREE.Points(geo, mat);
  scene.add(particleSystem);
}

// --- 3. Wireframe Radar Sphere & Sonar Rings ---
function createRadarAndSonar() {
  const radarGeo = new THREE.SphereGeometry(4.5, 24, 24);
  const radarMat = new THREE.MeshBasicMaterial({
    color: 0x00E5FF,
    wireframe: true,
    transparent: true,
    opacity: 0.15
  });
  radarSphere = new THREE.Mesh(radarGeo, radarMat);
  scene.add(radarSphere);

  for (let i = 0; i < 3; i++) {
    const ringGeo = new THREE.RingGeometry(3 + i * 1.5, 3.1 + i * 1.5, 64);
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0xFFCA28,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.2 - i * 0.05
    });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    ring.rotation.x = Math.PI / 2;
    scene.add(ring);
    sonarRings.push(ring);
  }
}

// --- 4. Exploded Architectural Layers (Section 5) ---
function createExplodedArchitectureLayers() {
  const colors = [0x00E5FF, 0xFFCA28, 0x10B981];

  for (let i = 0; i < 3; i++) {
    const layerGeo = new THREE.PlaneGeometry(4.2, 7.8);
    const layerMat = new THREE.MeshBasicMaterial({
      color: colors[i],
      wireframe: true,
      transparent: true,
      opacity: 0.0
    });
    const layerMesh = new THREE.Mesh(layerGeo, layerMat);
    scene.add(layerMesh);
    explodedLayers.push(layerMesh);
  }
}

function onWindowResize() {
  if (!camera || !renderer) return;
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}

function onMouseMove(e) {
  targetMouseX = (e.clientX / window.innerWidth) * 2 - 1;
  targetMouseY = -(e.clientY / window.innerHeight) * 2 + 1;
}

// --- Mobile Touch Swipe 360 Rotation ---
function onTouchStart(e) {
  if (e.touches && e.touches.length === 1) {
    touchStartX = e.touches[0].clientX;
    isTouchSpinning = true;
  }
}

function onTouchMove(e) {
  if (!isTouchSpinning || !e.touches || e.touches.length !== 1) return;
  const currentX = e.touches[0].clientX;
  const deltaX = (currentX - touchStartX) * 0.015;
  touchSpinRotation += deltaX;
  touchStartX = currentX;
  targetMouseX = (currentX / window.innerWidth) * 2 - 1;
  targetMouseY = -(e.touches[0].clientY / window.innerHeight) * 2 + 1;
}

function onTouchEnd() {
  isTouchSpinning = false;
}

// --- 5. Main Render Loop & Animation Dynamics ---
function animate3D() {
  requestAnimationFrame(animate3D);

  const delta = clock.getDelta();
  const elapsedTime = clock.getElapsedTime();

  // Handle Live Laser Scanning Animation
  if (isPhoneScanning) {
    scanProgress = Math.min(1.0, (elapsedTime - scanStartTime) / scanDuration);
    updatePhoneScreenContent(activeSimMode, activeCustomImage, scanProgress, true);
    if (scanProgress >= 1.0) {
      isPhoneScanning = false;
      updatePhoneScreenContent(activeSimMode, activeCustomImage, 1.0, false);
    }
  }

  if (phoneGroup && camera) {
    const hoverY = Math.sin(elapsedTime * 1.5) * 0.25;
    const hoverRotX = Math.cos(elapsedTime * 1.2) * 0.05;
    const hoverRotY = Math.sin(elapsedTime * 1.0) * 0.05;

    phoneGroup.rotation.x = THREE.MathUtils.lerp(phoneGroup.rotation.x, hoverRotX + targetMouseY * 0.2, 0.05);
    phoneGroup.rotation.y = THREE.MathUtils.lerp(phoneGroup.rotation.y, hoverRotY + targetMouseX * 0.4 + touchSpinRotation, 0.05);
    phoneGroup.position.y = THREE.MathUtils.lerp(phoneGroup.position.y, hoverY, 0.05);

    if (!isTouchSpinning) {
      touchSpinRotation *= 0.95; // Smooth momentum spin decay
    }

    applyScrollTransitions(elapsedTime);
  }

  // --- Zero-Gravity Particle Physics & Mouse Repulsion ---
  if (particleSystem && originalParticlePositions) {
    const positions = particleSystem.geometry.attributes.position.array;
    const count = positions.length / 3;

    // Convert normalized mouse target (-1 to 1) to approximate 3D world space
    const mouseWorldX = targetMouseX * 16;
    const mouseWorldY = targetMouseY * 12;
    const repulsionRadius = 6.5;
    const repulsionForce = 0.38;

    for (let i = 0; i < count; i++) {
      const idx = i * 3;
      let px = positions[idx];
      let py = positions[idx + 1];
      let pz = positions[idx + 2];

      const origX = originalParticlePositions[idx];
      const origY = originalParticlePositions[idx + 1];
      const origZ = originalParticlePositions[idx + 2];

      // Calculate distance to cursor
      const dx = px - mouseWorldX;
      const dy = py - mouseWorldY;
      const distSq = dx * dx + dy * dy;

      if (distSq < repulsionRadius * repulsionRadius && distSq > 0.01) {
        const dist = Math.sqrt(distSq);
        const force = (1.0 - dist / repulsionRadius) * repulsionForce;
        px += (dx / dist) * force;
        py += (dy / dist) * force;
      }

      // Gentle spring restoring force pulling back to home + floating swirl
      px += (origX + Math.sin(elapsedTime * 0.8 + i) * 0.4 - px) * 0.04;
      py += (origY + Math.cos(elapsedTime * 0.8 + i) * 0.4 - py) * 0.04;
      pz += (origZ + Math.sin(elapsedTime * 0.5 + i * 2) * 0.3 - pz) * 0.04;

      positions[idx] = px;
      positions[idx + 1] = py;
      positions[idx + 2] = pz;
    }
    particleSystem.geometry.attributes.position.needsUpdate = true;
    particleSystem.rotation.y += 0.0006;
  }
  if (radarSphere) {
    radarSphere.rotation.y -= 0.003;
    radarSphere.rotation.z += 0.002;
    radarSphere.scale.setScalar(1 + Math.sin(elapsedTime * 2) * 0.08);
  }
  sonarRings.forEach((ring, idx) => {
    ring.position.y = Math.sin(elapsedTime * 1.5 + idx) * 0.4 - 2;
    ring.rotation.z += 0.005 * (idx + 1);
  });

  if (renderer && scene && camera) {
    renderer.render(scene, camera);
  }
}

// --- 6. Scroll-Linked Transitions across 8 Sections ---
function applyScrollTransitions(time) {
  const scrollY = window.scrollY || document.documentElement.scrollTop;
  const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
  const progress = maxScroll > 0 ? scrollY / maxScroll : 0;
  currentScrollProgress = progress;

  if (progress <= 0.12) {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, 0, 0.05);
    radarSphere.material.opacity = 0.15;
    hideExplodedLayers();
  }
  else if (progress > 0.12 && progress <= 0.28) {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, window.innerWidth > 992 ? 3.5 : 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, -2, 0.05);
    phoneGroup.rotation.z = THREE.MathUtils.lerp(phoneGroup.rotation.z, -0.15, 0.05);
    radarSphere.material.opacity = 0.35;
    hideExplodedLayers();
  }
  else if (progress > 0.28 && progress <= 0.42) {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, window.innerWidth > 992 ? -3.0 : 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, 3.5, 0.05);
    phoneGroup.rotation.z = THREE.MathUtils.lerp(phoneGroup.rotation.z, 0, 0.05);
    radarSphere.material.opacity = 0.2;
    hideExplodedLayers();
  }
  else if (progress > 0.42 && progress <= 0.56) {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, 0, 0.05);
    phoneGroup.rotation.z = THREE.MathUtils.lerp(phoneGroup.rotation.z, Math.sin(time) * 0.4, 0.05);
    hideExplodedLayers();
  }
  else if (progress > 0.56 && progress <= 0.70) {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, window.innerWidth > 992 ? 2.5 : 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, -1, 0.05);
    
    explodedLayers.forEach((layer, idx) => {
      layer.material.opacity = 0.35;
      const offsetZ = (idx - 1) * 3.0;
      layer.position.set(phoneGroup.position.x, phoneGroup.position.y, offsetZ);
      layer.rotation.y = phoneGroup.rotation.y;
    });
  }
  else {
    phoneGroup.position.x = THREE.MathUtils.lerp(phoneGroup.position.x, 0, 0.05);
    phoneGroup.position.z = THREE.MathUtils.lerp(phoneGroup.position.z, 1.5, 0.05);
    phoneGroup.rotation.y += 0.01;
    hideExplodedLayers();
  }
}

function hideExplodedLayers() {
  explodedLayers.forEach(layer => {
    layer.material.opacity = THREE.MathUtils.lerp(layer.material.opacity, 0, 0.1);
  });
}

// Export for window access in main.js
window.updatePhoneScreenContent = updatePhoneScreenContent;
window.triggerPhoneLaserScan = triggerPhoneLaserScan;
window.init3DScene = init3DScene;
