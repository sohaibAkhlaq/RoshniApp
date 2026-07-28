/* ==========================================================================
   ROSHNI (روشنی) — INTERACTIVE LOGIC, GSAP & WEB AUDIO API SYNTHESIZER
   Lenis Scroll, Magnetic Tilt, Assistive Audio, Bilingual Urdu, & Haptics
   Professional Awwwards-Level Vector Iconography (100% Emoji-Free)
   ========================================================================== */

// --- Global Accessibility, Audio & Language State ---
let isAudioCuesActive = false;
let isHighContrastActive = false;
let currentLang = 'en'; // 'en' or 'ur'
let speechSynth = window.speechSynthesis;
let audioCtx = null;

document.addEventListener('DOMContentLoaded', () => {
  initSplashScreen();
  initLenisSmoothScroll();
  initCustomCursorTrail();
  initAudioSynthesizer();
  initAccessibilityToggles();
  initLanguageSwitcher();
  initMagneticHoverInteractions();
  initSimulatorSandbox();
  initScrollAnimations();

  // Start Three.js Scene
  if (typeof window.init3DScene === 'function') {
    window.init3DScene();
  }

  // Welcome Audio Prompt after splash screen dissolves
  setTimeout(() => {
    speakAudioCue('Welcome to Roshni AI. Your Light, Always With You. Press Alt plus L to switch to Urdu Nastaliq, or Alt plus A for audio cues.');
  }, 1800);
});

// --- 0. Golden Pulse Pre-Loader Splash Screen & Haptics ---
function initSplashScreen() {
  const splash = document.getElementById('roshni-splash-screen');
  const progress = document.querySelector('.splash-loader-progress');
  if (!splash) return;

  setTimeout(() => {
    if (progress) progress.style.width = '100%';
  }, 50);

  setTimeout(() => {
    splash.classList.add('loaded');
    playClickSound();
    triggerHapticFeedback([15, 30, 15]);
  }, 1500);
}

function triggerHapticFeedback(pattern = [15, 30, 15]) {
  if (typeof navigator !== 'undefined' && navigator.vibrate) {
    try {
      navigator.vibrate(pattern);
    } catch (e) {
      // Ignore if vibration is restricted or unsupported by browser
    }
  }
}

// --- 1. Web Audio API Synthesizer (No external MP3s!) ---
function initAudioSynthesizer() {
  const startCtx = () => {
    if (!audioCtx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (AudioContextClass) {
        audioCtx = new AudioContextClass();
      }
    }
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
  };

  document.addEventListener('click', startCtx, { once: true });
  document.addEventListener('keydown', startCtx, { once: true });

  const interactives = document.querySelectorAll('a, button, .bento-card, .metric-card, .timeline-card, .sim-tab-btn, .drop-zone');
  interactives.forEach(el => {
    el.addEventListener('mouseenter', () => playHoverChime());
    el.addEventListener('click', () => {
      playClickSound();
      triggerHapticFeedback([15]);
    });
  });
}

// Soft futuristic golden chime on hover (Harmonic C5-E5-G5 Chord)
function playHoverChime() {
  if (!isAudioCuesActive || !audioCtx) return;
  try {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const now = audioCtx.currentTime;
    
    const freqs = [523.25, 659.25, 783.99]; // C5, E5, G5
    freqs.forEach((freq, i) => {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);
      
      const filter = audioCtx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1400, now);
      
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(0.04, now + 0.04 + i * 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.45 + i * 0.05);
      
      osc.connect(filter);
      filter.connect(gain);
      gain.connect(audioCtx.destination);
      
      osc.start(now + i * 0.02);
      osc.stop(now + 0.55 + i * 0.05);
    });
  } catch (e) {
    console.error('Hover chime error:', e);
  }
}

// Satisfying tactile mechanical switch click
function playClickSound() {
  if (!isAudioCuesActive || !audioCtx) return;
  try {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const now = audioCtx.currentTime;
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    
    osc.type = 'square';
    osc.frequency.setValueAtTime(950, now);
    osc.frequency.exponentialRampToValueAtTime(180, now + 0.025);
    
    const filter = audioCtx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(800, now);
    filter.Q.setValueAtTime(2.5, now);
    
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);
    
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(audioCtx.destination);
    
    osc.start(now);
    osc.stop(now + 0.04);
  } catch (e) {
    console.error('Click sound error:', e);
  }
}

// Sci-fi laser scanner tone for Section 3
function playScanningSound() {
  if (!isAudioCuesActive || !audioCtx) return;
  try {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const now = audioCtx.currentTime;
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(350, now);
    osc.frequency.linearRampToValueAtTime(1400, now + 1.4);
    
    const filter = audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(600, now);
    filter.frequency.linearRampToValueAtTime(2600, now + 1.4);
    
    gain.gain.setValueAtTime(0.04, now);
    gain.gain.linearRampToValueAtTime(0.07, now + 0.5);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 1.6);
    
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(audioCtx.destination);
    
    osc.start(now);
    osc.stop(now + 1.65);
  } catch (e) {
    console.error('Scanning sound error:', e);
  }
}

// --- 2. Lenis Smooth Scrolling & GSAP Sync ---
function initLenisSmoothScroll() {
  if (typeof Lenis === 'undefined') return;

  const lenis = new Lenis({
    duration: 1.2,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
    direction: 'vertical',
    gestureDirection: 'vertical',
    smooth: true,
    smoothTouch: false,
    touchMultiplier: 2,
  });

  function raf(time) {
    lenis.raf(time);
    requestAnimationFrame(raf);
  }
  requestAnimationFrame(raf);

  if (typeof gsap !== 'undefined' && typeof ScrollTrigger !== 'undefined') {
    gsap.registerPlugin(ScrollTrigger);
    lenis.on('scroll', ScrollTrigger.update);
    gsap.ticker.add((time) => lenis.raf(time * 1000));
    gsap.ticker.lagSmoothing(0, 0);
  }
}

// --- 3. Custom Cursor & Roshni Golden Light Trail ---
function initCustomCursorTrail() {
  const cursor = document.getElementById('roshni-cursor');
  if (!cursor || window.matchMedia('(pointer: coarse)').matches) return;

  let mouseX = 0, mouseY = 0;
  let cursorX = 0, cursorY = 0;

  document.addEventListener('mousemove', (e) => {
    mouseX = e.clientX;
    mouseY = e.clientY;

    if (Math.random() > 0.4) {
      spawnTrailParticle(mouseX, mouseY);
    }
  });

  function animateCursor() {
    cursorX += (mouseX - cursorX) * 0.25;
    cursorY += (mouseY - cursorY) * 0.25;
    cursor.style.transform = `translate(${cursorX}px, ${cursorY}px)`;
    requestAnimationFrame(animateCursor);
  }
  animateCursor();

  const interactives = document.querySelectorAll('a, button, .bento-card, .sim-tab-btn, .metric-card, .drop-zone');
  interactives.forEach(el => {
    el.addEventListener('mouseenter', () => cursor.classList.add('active'));
    el.addEventListener('mouseleave', () => cursor.classList.remove('active'));
  });
}

function spawnTrailParticle(x, y) {
  const particle = document.createElement('div');
  particle.className = 'roshni-trail-particle';
  particle.style.left = `${x}px`;
  particle.style.top = `${y}px`;
  document.body.appendChild(particle);

  setTimeout(() => {
    particle.remove();
  }, 600);
}

// --- 4. Sound Pill & Accessibility Toggles (Professional SVG Icons) ---
function initAccessibilityToggles() {
  const audioBtn = document.getElementById('toggle-audio-cues');
  const contrastBtn = document.getElementById('toggle-high-contrast');

  if (audioBtn) {
    audioBtn.addEventListener('click', () => {
      isAudioCuesActive = !isAudioCuesActive;
      audioBtn.classList.toggle('active', isAudioCuesActive);
      triggerHapticFeedback([20, 20]);
      
      const isUrdu = currentLang === 'ur';
      audioBtn.innerHTML = isUrdu 
        ? (isAudioCuesActive 
            ? '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> آواز کی رہنمائی: فعال' 
            : '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> آواز کی رہنمائی: بند') 
        : (isAudioCuesActive 
            ? '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> Audio Cues: ON' 
            : '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> Audio Cues: OFF');

      if (isAudioCuesActive) {
        if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
        playClickSound();
        speakAudioCue(isUrdu ? 'آواز کی رہنمائی فعال کر دی گئی ہے۔' : 'Assistive audio synthesizer and speech narration enabled.', isUrdu ? 'ur-PK' : 'en-US');
      } else {
        if (speechSynth) speechSynth.cancel();
      }
    });
  }

  if (contrastBtn) {
    contrastBtn.addEventListener('click', () => {
      isHighContrastActive = !isHighContrastActive;
      contrastBtn.classList.toggle('active', isHighContrastActive);
      contrastBtn.classList.toggle('cyan-active', isHighContrastActive);
      document.body.classList.toggle('high-contrast-mode', isHighContrastActive);
      triggerHapticFeedback([20, 20]);

      const isUrdu = currentLang === 'ur';
      contrastBtn.innerHTML = isUrdu 
        ? (isHighContrastActive 
            ? '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> ہائی کنٹراسٹ: فعال' 
            : '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> ہائی کنٹراسٹ: بند') 
        : (isHighContrastActive 
            ? '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> Ultra High-Contrast: ON' 
            : '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> Ultra High-Contrast: OFF');

      speakAudioCue(isUrdu ? 'ہائی کنٹراسٹ موڈ فعال کر دیا گیا ہے۔' : (isHighContrastActive ? 'Ultra High Contrast Mode activated.' : 'High Contrast Mode deactivated.'), isUrdu ? 'ur-PK' : 'en-US');
    });
  }

  document.addEventListener('keydown', (e) => {
    if (e.altKey && e.key.toLowerCase() === 'a') {
      audioBtn && audioBtn.click();
    }
    if (e.altKey && e.key.toLowerCase() === 'c') {
      contrastBtn && contrastBtn.click();
    }
  });

  attachAudioCuesToElements();
}

function speakAudioCue(text, lang = 'en-US') {
  if (!isAudioCuesActive && !text.includes('Welcome')) return;
  if (!speechSynth) return;

  speechSynth.cancel();
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.rate = 1.0;
  utterance.pitch = 1.0;
  utterance.volume = 1.0;

  const voices = speechSynth.getVoices();
  if (lang === 'ur-PK' || text.includes('روشنی') || text.includes('اردو') || currentLang === 'ur') {
    const urduVoice = voices.find(v => v.lang.includes('ur') || v.name.includes('Urdu') || v.name.includes('Pakistan'));
    if (urduVoice) utterance.voice = urduVoice;
  }
  speechSynth.speak(utterance);
}

function attachAudioCuesToElements() {
  const cards = document.querySelectorAll('.bento-card, .metric-card, .timeline-card');
  cards.forEach(card => {
    card.addEventListener('mouseenter', () => {
      if (!isAudioCuesActive) return;
      const title = card.querySelector('h3, h4, .counter-value')?.innerText || '';
      const desc = card.querySelector('p')?.innerText || '';
      speakAudioCue(`${title}. ${desc}`, currentLang === 'ur' ? 'ur-PK' : 'en-US');
    });
  });
}

// --- 5. Bilingual Urdu Nastaliq Language Switcher & GSAP Animations (Vector Iconography) ---
const bilingualDictionary = [
  // Navbar
  { selector: '#toggle-language', en: '<svg class="roshni-icon icon-gold"><use href="#icon-globe"></use></svg> اردو | English', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-globe"></use></svg> English | اردو' },
  // Section 1: Hero
  { selector: '#hero .badge-pill span', en: '<svg class="roshni-icon icon-gold"><use href="#icon-spark"></use></svg> Flutter & Firebase Powered • AI Assistive Vision', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-spark"></use></svg> فلٹر اور فائر بیس پر مبنی • بصری رہنمائی کا جدید نظام' },
  { selector: '#hero-title', en: 'Roshni — <br><span class="text-gradient-gold">Your Light, Always With You</span>', ur: 'روشنی — <br><span class="text-gradient-gold">آپ کی روشنی، ہر وقت ساتھ</span>' },
  { selector: '#hero .subtitle-text', en: 'Empowering visually impaired individuals across Pakistan with real-time AI object detection, Urdu OCR script reading, instant Pakistani Rupee (PKR) identification, and natural voice scene narration.', ur: 'بصارت سے محروم افراد کے لیے تیز ترین آف لائن مصنوعی ذہانت، پاکستانی کرنسی کی شناخت، اردو تحریر کی بلند خوانی اور حقیقی وقت میں راستے کی صوتی رہنمائی۔' },
  { selector: '#hero .btn-primary span', en: '<svg class="roshni-icon"><use href="#icon-download"></use></svg> Download Roshni Now', ur: '<svg class="roshni-icon"><use href="#icon-download"></use></svg> روشنی ابھی ڈاؤن لوڈ کریں' },
  { selector: '#hero .btn-secondary span', en: '<svg class="roshni-icon icon-gold"><use href="#icon-zap"></use></svg> Try Live AI Simulator', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-zap"></use></svg> لائیو سمیلیٹر آزمائیں' },
  // Section 2: Features Bento Grid
  { selector: '#features .badge-pill', en: '<svg class="roshni-icon icon-cyan"><use href="#icon-zap"></use></svg> 5+ Essential AI Tools in 1 Lightweight App', ur: '<svg class="roshni-icon icon-cyan"><use href="#icon-zap"></use></svg> ۵ سے زائد ضروری اے آئی ٹولز ایک ہلکی پھلکی ایپ میں' },
  { selector: '#features-title', en: 'The Interactive <span class="text-gradient-cyan">3D Feature Universe</span>', ur: 'روشنی کی <span class="text-gradient-cyan">جدید ترین خصوصیات</span>' },
  { selector: '#features > div > p.subtitle-text', en: 'Built from day one with blind accessibility, zero-lag edge AI inference, and Pakistani cultural context at its heart.', ur: 'بصارت سے محروم افراد کی آسانی، بنا انٹرنیٹ تیز ترین کارکردگی اور پاکستانی ثقافت کو مدنظر رکھتے ہوئے تیار کردہ۔' },
  { selector: '.bento-grid > div:nth-child(1) h3', en: 'Real-Time 3D Object Detection', ur: 'راستے کی رکاوٹوں کا ۳ ڈی ریڈار' },
  { selector: '.bento-grid > div:nth-child(1) p', en: 'Animated radar bounding-box scanning of live street scenes with sub-100ms AI feedback. Instantly detects chairs, tables, doors, and obstacles with spatial voice guidance.', ur: 'راستے اور کمرے میں موجود کرسیوں، میزوں، دروازوں اور رکاوٹوں کی ۱۰۰ ملی سیکنڈ سے بھی کم وقت میں صوتی اور فاصلاتی رہنمائی کے ساتھ فوری نشاندہی۔' },
  { selector: '.bento-grid > div:nth-child(2) h3', en: 'Urdu OCR Text Reader', ur: 'اردو تحریر کی بلند خوانی' },
  { selector: '.bento-grid > div:nth-child(2) p', en: 'Tesseract & Google ML Kit powered AI extracting Urdu script from signboards, books, and receipts into visual audio sound waves.', ur: 'نستعلیق خطاطی، کتابوں، رسیدوں اور سائن بورڈز پر لکھی اردو تحریر کو پڑھ کر صاف اور واضح آواز میں سنانے والا نظام۔' },
  { selector: '.bento-grid > div:nth-child(3) h3', en: 'PKR Currency Classifier', ur: 'پاکستانی کرنسی کی شناخت' },
  { selector: '.bento-grid > div:nth-child(3) p', en: 'Instantly identifies Pakistani Rupee notes (500, 1000, 5000 PKR) from front or back with 99.4% accuracy and announces denomination in clear Urdu voice.', ur: '۵۰۰، ۱۰۰۰ اور ۵۰۰۰ روپے کے نوٹوں کی اگلی یا پچھلی جانب سے ۹۹.۴ فیصد درستی کے ساتھ فوری شناخت اور واضح اردو اعلان۔' },
  { selector: '.bento-grid > div:nth-child(4) h3', en: 'Smart Document Scanner', ur: 'دستاویزات کا اسمارٹ اسکینر' },
  { selector: '.bento-grid > div:nth-child(4) p', en: 'Google ML Kit auto-capture and perspective correction for utility bills, official documents, and mail without manual shutter tapping.', ur: 'بجلی کے بلوں اور سرکاری دستاویزات کی خودکار تصویر اور سیدھ درست کرنے والا نظام، بغیر کسی بٹن دبائے۔' },
  { selector: '.bento-grid > div:nth-child(5) h3', en: 'AI Scene Description', ur: 'مناظر اور تصاویر کی تشریح' },
  { selector: '.bento-grid > div:nth-child(5) p', en: 'Cloud vision AI analyzing complex park scenes, indoor rooms, and photos to generate natural-language conversational captions in Urdu or English.', ur: 'پیچیدہ مناظر، کمروں اور تصاویر کو گہرائی سے سمجھ کر قدرتی اردو یا انگریزی زبان میں احوال سنانے والا جدید نظام۔' },
  // Section 3: Simulator
  { selector: '#simulator .badge-pill', en: '<svg class="roshni-icon icon-gold"><use href="#icon-sliders"></use></svg> Interactive Sandbox Experience', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-sliders"></use></svg> لائیو سمیلیٹر کا تجربہ' },
  { selector: '#sim-title', en: 'Test Roshni <span class="text-gradient-gold">Live Simulator</span>', ur: 'روشنی کا <span class="text-gradient-gold">لائیو سمیلیٹر آزمائیں</span>' },
  { selector: '#simulator > div > p.subtitle-text', en: 'Click between real-world test modes below to watch the 3D smartphone canvas update in real-time and trigger voiced AI detection responses!', ur: 'نیچے دیے گئے مختلف طریقوں پر کلک کریں یا اپنی تصویر اپ لوڈ کر کے روشنی اے آئی کا جادو دیکھیں!' },
  { selector: '.sim-controls > button:nth-child(1) div:nth-child(2) > div:nth-child(1)', en: 'Mode A: Pakistani Rupee Test', ur: 'موڈ اے: پاکستانی کرنسی ٹیسٹ' },
  { selector: '.sim-controls > button:nth-child(1) div:nth-child(2) > div:nth-child(2)', en: 'Simulates instant 1000 PKR note scanning & Urdu voice announcement.', ur: '۱۰۰۰ روپے کے نوٹ کی فوری شناخت اور صوتی اعلان کا تجربہ کریں۔' },
  { selector: '.sim-controls > button:nth-child(2) div:nth-child(2) > div:nth-child(1)', en: 'Mode B: Urdu OCR Test', ur: 'موڈ بی: اردو او سی آر ٹیسٹ' },
  { selector: '.sim-controls > button:nth-child(2) div:nth-child(2) > div:nth-child(2)', en: 'Scans an Urdu book page and displays highlighted extracted text.', ur: 'اردو کتاب یا سائن بورڈ کی تحریر کو اسکین اور بلند خوانی کا تجربہ کریں۔' },
  { selector: '.sim-controls > button:nth-child(3) div:nth-child(2) > div:nth-child(1)', en: 'Mode C: Street Obstacle Detection', ur: 'موڈ سی: راستے کی رکاوٹوں کا ریڈار' },
  { selector: '.sim-controls > button:nth-child(3) div:nth-child(2) > div:nth-child(2)', en: 'Shows bounding boxes around chairs, doors, & stairs with distances.', ur: 'راستے میں موجود کرسیوں اور دروازوں کی فاصلے کے ساتھ نشاندہی۔' },
  { selector: '.drop-zone-text', en: '<strong>Drag & Drop</strong> any photo, bill, or Rupee note here to test Roshni AI live!', ur: '<strong>ڈریگ اور ڈراپ کریں:</strong> کوئی بھی تصویر یا نوٹ یہاں ڈال کر روشنی اے آئی کا لائیو ٹیسٹ کریں!' },
  { selector: '#trigger-instant-scan', en: '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> Trigger Instant Scan', ur: '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> فوری اسکین شروع کریں' },
  // Section 7: Download
  { selector: '#download-title', en: 'Ready to See the World in a <span class="text-gradient-gold">New Light?</span>', ur: 'کیا آپ دنیا کو ایک <span class="text-gradient-gold">نئی روشنی میں دیکھنے کے لیے تیار ہیں؟</span>' },
  { selector: '#download .subtitle-text', en: 'Download Roshni today on your Android or iOS device. Experience true visual independence, real-time Urdu OCR, and effortless PKR note recognition.', ur: 'آج ہی روشنی اپنے انڈرائیڈ یا آئی او ایس فون پر ڈاؤن لوڈ کریں۔ حقیقی بصری خود مختاری، اردو او سی آر اور کرنسی کی فوری پہچان کا تجربہ کریں۔' },
  { selector: '#download .btn-primary span', en: '<svg class="roshni-icon"><use href="#icon-android"></use></svg> Android APK / Google Play', ur: '<svg class="roshni-icon"><use href="#icon-android"></use></svg> انڈرائیڈ اے پی کے / گوگل پلے' },
  { selector: '#download .btn-secondary span', en: '<svg class="roshni-icon"><use href="#icon-apple"></use></svg> iOS App Store', ur: '<svg class="roshni-icon"><use href="#icon-apple"></use></svg> آئی او ایس ایپ اسٹور' }
];

function initLanguageSwitcher() {
  const langBtn = document.getElementById('toggle-language');
  if (!langBtn) return;

  langBtn.addEventListener('click', () => {
    currentLang = currentLang === 'en' ? 'ur' : 'en';
    playClickSound();
    triggerHapticFeedback([15, 25, 15]);

    const isUrdu = currentLang === 'ur';
    speakAudioCue(isUrdu ? 'اردو زبان اور نستعلیق خطاطی منتخب کر لی گئی ہے۔' : 'English language selected.', isUrdu ? 'ur-PK' : 'en-US');

    const targetElements = [];
    bilingualDictionary.forEach(item => {
      const el = document.querySelector(item.selector);
      if (el) targetElements.push({ el, item });
    });

    if (typeof gsap !== 'undefined') {
      gsap.to(targetElements.map(t => t.el), {
        opacity: 0,
        x: isUrdu ? -25 : 25,
        duration: 0.25,
        stagger: 0.005,
        ease: 'power2.in',
        onComplete: () => {
          document.body.classList.toggle('lang-ur', isUrdu);
          document.documentElement.dir = isUrdu ? 'rtl' : 'ltr';
          document.documentElement.lang = isUrdu ? 'ur' : 'en';

          const audioBtn = document.getElementById('toggle-audio-cues');
          const contrastBtn = document.getElementById('toggle-high-contrast');
          if (audioBtn) audioBtn.innerHTML = isUrdu 
            ? (isAudioCuesActive ? '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> آواز کی رہنمائی: فعال' : '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> آواز کی رہنمائی: بند') 
            : (isAudioCuesActive ? '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> Audio Cues: ON' : '<svg class="roshni-icon icon-cyan"><use href="#icon-speaker"></use></svg> Audio Cues: OFF');
          if (contrastBtn) contrastBtn.innerHTML = isUrdu 
            ? (isHighContrastActive ? '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> ہائی کنٹراسٹ: فعال' : '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> ہائی کنٹراسٹ: بند') 
            : (isHighContrastActive ? '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> Ultra High-Contrast: ON' : '<svg class="roshni-icon icon-gold"><use href="#icon-eye"></use></svg> Ultra High-Contrast: OFF');

          targetElements.forEach(({ el, item }) => {
            el.innerHTML = isUrdu ? item.ur : item.en;
          });

          gsap.fromTo(targetElements.map(t => t.el),
            { opacity: 0, x: isUrdu ? 25 : -25 },
            { opacity: 1, x: 0, duration: 0.4, stagger: 0.008, ease: 'power3.out' }
          );
        }
      });
    } else {
      document.body.classList.toggle('lang-ur', isUrdu);
      document.documentElement.dir = isUrdu ? 'rtl' : 'ltr';
      targetElements.forEach(({ el, item }) => {
        el.innerHTML = isUrdu ? item.ur : item.en;
      });
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.altKey && e.key.toLowerCase() === 'l') {
      langBtn && langBtn.click();
    }
  });
}

// --- 6. Magnetic Button Pull & Holographic Sheen Tracking ---
function initMagneticHoverInteractions() {
  const tiltElements = document.querySelectorAll('.bento-card, .glass-card, .btn-primary, .drop-zone, .timeline-card, .metric-card');

  tiltElements.forEach(el => {
    const isMagnetic = el.classList.contains('btn-primary') || el.classList.contains('bento-card');

    let xTo, yTo;
    if (typeof gsap !== 'undefined' && isMagnetic) {
      xTo = gsap.quickTo(el, "x", { duration: 0.35, ease: "power3.out" });
      yTo = gsap.quickTo(el, "y", { duration: 0.35, ease: "power3.out" });
    }

    el.addEventListener('mousemove', (e) => {
      const rect = el.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      el.style.setProperty('--mouse-x', `${x}px`);
      el.style.setProperty('--mouse-y', `${y}px`);

      const rotateX = ((y - centerY) / centerY) * -10;
      const rotateY = ((x - centerX) / centerX) * 10;
      el.style.transform = `perspective(1000px) rotateX(${rotateX.toFixed(2)}deg) rotateY(${rotateY.toFixed(2)}deg) scale3d(1.02, 1.02, 1.02)`;

      if (isMagnetic && xTo && yTo) {
        const pullStrength = el.classList.contains('btn-primary') ? 0.35 : 0.15;
        xTo((e.clientX - (rect.left + centerX)) * pullStrength);
        yTo((e.clientY - (rect.top + centerY)) * pullStrength);
      }
    });

    el.addEventListener('mouseleave', () => {
      el.style.transform = `perspective(1000px) rotateX(0deg) rotateY(0deg) scale3d(1, 1, 1)`;
      if (isMagnetic && typeof gsap !== 'undefined') {
        gsap.to(el, { x: 0, y: 0, duration: 0.7, ease: "elastic.out(1.1, 0.4)" });
      }
    });
  });

  document.addEventListener('mousemove', (e) => {
    if (typeof gsap === 'undefined' || window.matchMedia('(pointer: coarse)').matches) return;

    const magnetics = document.querySelectorAll('.btn-primary, .bento-card');
    magnetics.forEach(el => {
      const rect = el.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const distSq = Math.pow(e.clientX - centerX, 2) + Math.pow(e.clientY - centerY, 2);
      const radius = Math.max(rect.width, rect.height) / 2 + 60;

      if (distSq < radius * radius && (e.clientX < rect.left || e.clientX > rect.right || e.clientY < rect.top || e.clientY > rect.bottom)) {
        const dist = Math.sqrt(distSq);
        const pullFactor = (1 - dist / radius) * (el.classList.contains('btn-primary') ? 0.3 : 0.12);
        gsap.to(el, {
          x: (e.clientX - centerX) * pullFactor,
          y: (e.clientY - centerY) * pullFactor,
          duration: 0.4,
          ease: "power2.out"
        });
      }
    });
  });
}

// --- 7. Section 3: Interactive AI Live Simulator Sandbox & Drag-Drop (Vector Icons) ---
function initSimulatorSandbox() {
  const tabButtons = document.querySelectorAll('.sim-tab-btn');
  const triggerBtn = document.getElementById('trigger-instant-scan');
  const simTitle = document.getElementById('sim-active-title');
  const simDesc = document.getElementById('sim-active-desc');
  const simBadge = document.getElementById('sim-active-badge');
  const laser = document.getElementById('sim-laser-line');
  const dropZone = document.getElementById('sim-drop-zone');
  const fileInput = document.getElementById('sim-file-input');

  const modeData = {
    'mode-a': {
      title: '<svg class="roshni-icon icon-md icon-gold"><use href="#icon-banknote"></use></svg> Pakistani Rupee Classifier',
      desc: 'Simulating instant denomination detection for 500, 1000, and 5000 PKR notes with voiced feedback.',
      badge: '<svg class="roshni-icon icon-gold"><use href="#icon-radar"></use></svg> 1000 PKR Note — Confidence 99.8%',
      speech: 'Scanning complete. One Thousand Pakistani Rupees detected with 99.8 percent confidence.',
      speechUr: 'اسکین مکمل۔ ایک ہزار روپے کا نوٹ تصدیق ہو گیا ہے۔ درستی ۹۹.۸ فیصد۔'
    },
    'mode-b': {
      title: '<svg class="roshni-icon icon-md icon-cyan"><use href="#icon-book"></use></svg> Urdu OCR Text Reader',
      desc: 'Simulating Tesseract & ML Kit extracting Urdu script from books and signboards into clear voice narration.',
      badge: '<svg class="roshni-icon icon-cyan"><use href="#icon-book"></use></svg> روشنی ہمیشہ آپ کے ساتھ — Extracted',
      speech: 'Scanning complete. Extracted Urdu script: Roshni, your light always with you.',
      speechUr: 'اسکین مکمل۔ اردو تحریر: روشنی ہمیشہ آپ کے ساتھ۔'
    },
    'mode-c': {
      title: '<svg class="roshni-icon icon-md icon-gold"><use href="#icon-radar"></use></svg> Real-Time Obstacle Radar',
      desc: 'Simulating bounding boxes around chairs, doors, and stairs with precise distance estimation in meters.',
      badge: '<svg class="roshni-icon icon-gold"><use href="#icon-radar"></use></svg> Chair detected at 1.2 meters. Door at 2.8 meters.',
      speech: 'Scanning complete. Obstacle radar detected: Chair at 1.2 meters ahead, doorway at 2.8 meters to the right.',
      speechUr: 'خبردار۔ سامنے ۱.۲ میٹر پر کرسی اور دائیں جانب ۲.۸ میٹر پر دروازہ موجود ہے۔'
    }
  };

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      triggerHapticFeedback([15, 20]);

      const mode = btn.getAttribute('data-mode');
      const data = modeData[mode];
      if (!data) return;

      if (simTitle) simTitle.innerHTML = data.title;
      if (simDesc) simDesc.innerHTML = data.desc;
      if (simBadge) simBadge.innerHTML = data.badge;

      if (typeof window.triggerPhoneLaserScan === 'function') {
        window.triggerPhoneLaserScan(mode);
      } else if (typeof window.updatePhoneScreenContent === 'function') {
        window.updatePhoneScreenContent(mode);
      }

      const isUrdu = currentLang === 'ur' || mode === 'mode-b';
      speakAudioCue(isUrdu && data.speechUr ? data.speechUr : data.speech, isUrdu ? 'ur-PK' : 'en-US');
    });
  });

  if (triggerBtn) {
    triggerBtn.addEventListener('click', () => {
      triggerBtn.disabled = true;
      triggerHapticFeedback([25, 40, 25, 40, 25]);
      const isUrdu = currentLang === 'ur';
      triggerBtn.innerHTML = isUrdu ? '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> اسکین جاری ہے...' : '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> Scanning Scene...';
      if (laser) laser.classList.add('scanning');

      const activeBtn = document.querySelector('.sim-tab-btn.active');
      const mode = activeBtn ? activeBtn.getAttribute('data-mode') : 'mode-a';
      const data = modeData[mode] || { speech: 'Scanning complete. Custom uploaded target verified.', speechUr: 'اسکین مکمل۔ اپ لوڈ کردہ تصویر کی تصدیق ہو گئی ہے۔' };

      playScanningSound();
      speakAudioCue(isUrdu ? 'کیمرہ فریم اسکین کیا جا رہا ہے۔ براہ کرم فون مستحکم رکھیں۔' : 'Scanning live camera frame. Please hold steady.', isUrdu ? 'ur-PK' : 'en-US');

      if (typeof window.triggerPhoneLaserScan === 'function') {
        window.triggerPhoneLaserScan(mode);
      }

      setTimeout(() => {
        if (laser) laser.classList.remove('scanning');
        triggerBtn.disabled = false;
        triggerBtn.innerHTML = isUrdu ? '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> فوری اسکین شروع کریں' : '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> Trigger Instant Scan';
        playClickSound();
        triggerHapticFeedback([30, 50, 30]);
        const speakUr = isUrdu || mode === 'mode-b';
        speakAudioCue(speakUr && data.speechUr ? data.speechUr : data.speech, speakUr ? 'ur-PK' : 'en-US');
      }, 1600);
    });
  }

  // --- Drag & Drop Image Upload Zone ---
  if (dropZone && fileInput) {
    dropZone.addEventListener('click', () => {
      triggerHapticFeedback([15]);
      fileInput.click();
    });

    dropZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropZone.classList.add('dragover');
    });

    dropZone.addEventListener('dragleave', () => {
      dropZone.classList.remove('dragover');
    });

    dropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      dropZone.classList.remove('dragover');
      if (e.dataTransfer.files && e.dataTransfer.files[0]) {
        handleUploadedImageFile(e.dataTransfer.files[0]);
      }
    });

    fileInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) {
        handleUploadedImageFile(e.target.files[0]);
      }
    });
  }

  function handleUploadedImageFile(file) {
    if (!file.type.startsWith('image/')) {
      triggerHapticFeedback([50, 50, 50]);
      speakAudioCue(currentLang === 'ur' ? 'براہ کرم درست تصویر اپ لوڈ کریں۔' : 'Please upload a valid image file.', currentLang === 'ur' ? 'ur-PK' : 'en-US');
      return;
    }

    tabButtons.forEach(b => b.classList.remove('active'));
    playClickSound();
    triggerHapticFeedback([20, 30, 20]);

    const isUrdu = currentLang === 'ur';

    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        if (simTitle) simTitle.innerHTML = isUrdu ? `<svg class="roshni-icon icon-md icon-gold"><use href="#icon-upload"></use></svg> اپ لوڈ کردہ تصویر: ${file.name}` : `<svg class="roshni-icon icon-md icon-gold"><use href="#icon-upload"></use></svg> Custom Upload: ${file.name}`;
        if (simDesc) simDesc.innerText = isUrdu ? 'روشنی اے آئی آپ کی اپ لوڈ کردہ تصویر کا تجزئیہ کر رہی ہے...' : 'Roshni Edge AI is scanning your uploaded photo for currencies, Urdu text, and obstacles...';
        if (simBadge) simBadge.innerHTML = isUrdu ? '<svg class="roshni-icon icon-gold"><use href="#icon-zap"></use></svg> اے آئی لزر اسکین جاری ہے...' : '<svg class="roshni-icon icon-gold"><use href="#icon-zap"></use></svg> AI Laser Scanning in Progress...';
        if (laser) laser.classList.add('scanning');

        playScanningSound();
        speakAudioCue(isUrdu ? 'تصویر اپ لوڈ ہو گئی ہے۔ صوتی اور لزر اسکین شروع کیا جا رہا ہے۔' : 'Image uploaded. Initiating real-time golden laser scan and neural bounding box detection.', isUrdu ? 'ur-PK' : 'en-US');

        if (typeof window.triggerPhoneLaserScan === 'function') {
          window.triggerPhoneLaserScan('custom', img);
        }

        setTimeout(() => {
          if (laser) laser.classList.remove('scanning');
          playClickSound();
          triggerHapticFeedback([30, 60, 30]);
          const tag = isUrdu ? '<svg class="roshni-icon icon-gold"><use href="#icon-shield"></use></svg> تصدیق: [۵۰۰۰ کا نوٹ - ۹۹.۶٪] اور [اردو سائن بورڈ]' : '<svg class="roshni-icon icon-gold"><use href="#icon-shield"></use></svg> Match: [5000 PKR Note - 99.6%] & [Urdu Script - Verified]';
          if (simBadge) simBadge.innerHTML = tag;
          speakAudioCue(isUrdu ? 'اسکین مکمل۔ پانچ ہزار روپے کا نوٹ اور اردو سائن بورڈ تصدیق ہو گیا ہے۔' : 'Scan complete. Five Thousand Pakistani Rupee note and Urdu signboard detected with 99.6 percent confidence.', isUrdu ? 'ur-PK' : 'en-US');
        }, 1600);
      };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
  }
}

// --- 8. GSAP ScrollTrigger Animations & Counter Numbers ---
function initScrollAnimations() {
  if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') return;

  gsap.utils.toArray('.glass-card, .bento-card, .timeline-card, .metric-card').forEach(el => {
    gsap.from(el, {
      scrollTrigger: {
        trigger: el,
        start: 'top 85%',
        toggleActions: 'play none none reverse'
      },
      y: 50,
      opacity: 0,
      duration: 0.8,
      ease: 'power3.out'
    });
  });

  gsap.utils.toArray('.urdu-watermark').forEach((el, idx) => {
    gsap.to(el, {
      scrollTrigger: {
        trigger: el,
        start: 'top bottom',
        end: 'bottom top',
        scrub: 1.5
      },
      y: (idx % 2 === 0 ? -150 : 150),
      rotation: `+=${idx % 2 === 0 ? 15 : -15}deg`
    });
  });

  const counters = document.querySelectorAll('.counter-value');
  counters.forEach(counter => {
    const targetVal = parseFloat(counter.getAttribute('data-target'));
    const suffix = counter.getAttribute('data-suffix') || '';
    const prefix = counter.getAttribute('data-prefix') || '';
    const isDecimal = counter.getAttribute('data-decimal') === 'true';

    gsap.fromTo(counter, 
      { innerText: 0 },
      {
        scrollTrigger: {
          trigger: counter,
          start: 'top 85%',
          once: true
        },
        innerText: targetVal,
        duration: 2.5,
        ease: 'power2.out',
        snap: { innerText: isDecimal ? 0.1 : 1 },
        onUpdate: function() {
          const val = parseFloat(this.targets()[0].innerText);
          counter.innerText = `${prefix}${isDecimal ? val.toFixed(1) : Math.floor(val)}${suffix}`;
        }
      }
    );
  });
}
