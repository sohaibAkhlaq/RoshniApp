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
  const cards = document.querySelectorAll('.bento-card, .metric-card, .timeline-card, .glass-card');
  cards.forEach(card => {
    const playCue = () => {
      if (!isAudioCuesActive) return;
      const title = card.querySelector('h3, h4, .counter-value')?.innerText || '';
      const desc = card.querySelector('p')?.innerText || '';
      speakAudioCue(`${title}. ${desc}`, currentLang === 'ur' ? 'ur-PK' : 'en-US');
    };
    card.addEventListener('mouseenter', playCue);
    card.addEventListener('click', playCue);
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

  // Section 4: Timeline
  { selector: '#story .badge-pill', en: '<svg class="roshni-icon icon-gold"><use href="#icon-sun"></use></svg> 24/7 Companion Timeline', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-sun"></use></svg> چوبیس گھنٹے کا ساتھی' },
  { selector: '#story-title', en: 'A Day with <span class="text-gradient-cyan">Roshni</span>', ur: '<span class="text-gradient-cyan">روشنی</span> کے ساتھ ایک دن' },
  { selector: '#story > div > p', en: 'Watch how Roshni seamlessly accompanies a visually impaired user through independence, mobility, and confidence from morning till evening.', ur: 'دیکھیں کہ کس طرح روشنی ایک نابینا صارف کو صبح سے شام تک آزادی، نقل و حرکت، اور اعتماد کے ساتھ ہمراہ رکھتی ہے۔' },
  { selector: '.timeline-grid > div:nth-child(1) h3', en: 'Morning Independence', ur: 'صبح کی آزادی' },
  { selector: '.timeline-grid > div:nth-child(1) p', en: 'Reading morning Urdu newspapers, sorting official mail, and scanning utility bills independently at the breakfast table using Urdu OCR and Smart Document Scanner.', ur: 'صبح کے اخبارات پڑھنا، سرکاری ڈاک چھانٹنا، اور ناشتے کی میز پر بل اسکین کرنا اردو او سی آر کی مدد سے۔' },
  { selector: '.timeline-grid > div:nth-child(2) h3', en: 'Confident Navigation', ur: 'پر اعتماد نقل و حرکت' },
  { selector: '.timeline-grid > div:nth-child(2) p', en: 'Walking outdoors on busy city streets with real-time 3D camera radar announcing obstacles, stairs, and doorway entrances via Bluetooth earphones.', ur: 'مصروف سڑکوں پر چلتے ہوئے ریئل ٹائم تھری ڈی کیمرہ ریڈار کے ذریعے رکاوٹوں اور راستوں کی صوتی رہنمائی۔' },
  { selector: '.timeline-grid > div:nth-child(3) h3', en: 'Seamless Shopping', ur: 'آسان خریداری' },
  { selector: '.timeline-grid > div:nth-child(3) p', en: 'Verifying cash notes instantly at checkout with the PKR Currency Classifier. No more confusion between 500, 1000, or 5000 Rupee notes!', ur: 'خریداری کے دوران پیسوں کی فوری تصدیق۔ ۵۰۰، ۱۰۰۰، اور ۵۰۰۰ روپے کے نوٹوں میں اب کوئی الجھن نہیں!' },

  // Section 5: Architecture
  { selector: '#architecture .badge-pill', en: '<svg class="roshni-icon icon-cyan"><use href="#icon-cpu"></use></svg> Built Under the Hood', ur: '<svg class="roshni-icon icon-cyan"><use href="#icon-cpu"></use></svg> اندرونی ساخت' },
  { selector: '#arch-title', en: 'Accessibility-First <br><span class="text-gradient-gold">Architecture & Engineering</span>', ur: 'معذوری کو مدنظر رکھ کر <br><span class="text-gradient-gold">بنایا گیا بہترین نظام</span>' },
  { selector: '#architecture .subtitle-text', en: 'As you scroll here, the 3D smartphone separates into an exploded view showing the core layers that make Roshni reliable, lightning-fast, and 100% blind-accessible.', ur: 'یہاں وہ بنیادی ٹیکنالوجی دکھائی گئی ہے جو روشنی کو قابل اعتماد، تیز ترین اور ۱۰۰ فیصد نابینا افراد کے لیے قابل رسائی بناتی ہے۔' },
  { selector: '#architecture .glass-card:nth-child(1) h3', en: '<svg class="roshni-icon"><use href="#icon-speaker"></use></svg> Voice & Screen Reader First', ur: '<svg class="roshni-icon"><use href="#icon-speaker"></use></svg> صوتی اور اسکرین ریڈر' },
  { selector: '#architecture .glass-card:nth-child(1) p', en: 'Full Flutter Semantics integration built from day one. Every button, card, and image preview announces itself clearly.', ur: 'پہلے دن سے فلٹر سیمینٹکس کا استعمال۔ ہر بٹن اور کارڈ خود کو واضح آواز میں متعارف کرواتا ہے۔' },
  { selector: '#architecture .glass-card:nth-child(2) h3', en: '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> Persistent Skip-Flow', ur: '<svg class="roshni-icon"><use href="#icon-zap"></use></svg> بغیر لاگ ان کا نظام' },
  { selector: '#architecture .glass-card:nth-child(2) p', en: 'Intelligent offline-ready session memory that never traps users in forced logins or complicated onboarding screens.', ur: 'ایک ذہین آف لائن نظام جو صارفین کو زبردستی لاگ ان یا پیچیدہ اسکرینوں میں نہیں پھنساتا۔' },
  { selector: '#architecture .glass-card:nth-child(3) h3', en: '<svg class="roshni-icon"><use href="#icon-cpu"></use></svg> Offline Firestore Caching', ur: '<svg class="roshni-icon"><use href="#icon-cpu"></use></svg> آف لائن کیشنگ' },
  { selector: '#architecture .glass-card:nth-child(3) p', en: 'Instant unlimited local database caching for seamless operation of Currency Classifier & Object Detection without internet.', ur: 'انٹرنیٹ کے بغیر کرنسی کی شناخت اور رکاوٹوں کی نشاندہی کے لیے لامحدود لوکل ڈیٹا بیس۔' },
  { selector: '#architecture .glass-card:nth-child(4) h3', en: '<svg class="roshni-icon"><use href="#icon-shield"></use></svg> Hardware Shortcuts', ur: '<svg class="roshni-icon"><use href="#icon-shield"></use></svg> ہارڈویئر شارٹ کٹس' },
  { selector: '#architecture .glass-card:nth-child(4) p', en: 'Triple-press power button integration for instant emergency camera launch and eyes-free gesture navigation.', ur: 'پاور بٹن کو تین بار دبانے سے ایمرجنسی کیمرہ اور اشاروں کے ذریعے نیویگیشن کا آغاز۔' },

  // Section 6: Metrics
  { selector: '#metrics .badge-pill', en: '<svg class="roshni-icon icon-gold"><use href="#icon-bar-chart"></use></svg> Benchmark Performance', ur: '<svg class="roshni-icon icon-gold"><use href="#icon-bar-chart"></use></svg> بہترین کارکردگی' },
  { selector: '#metrics-title', en: 'Impact Metrics & <span class="text-gradient-cyan">AI Performance</span>', ur: 'اثرات اور <span class="text-gradient-cyan">اے آئی کی کارکردگی</span>' },
  { selector: '#metrics > div > p.subtitle-text', en: 'Rigorous testing and benchmark data prove Roshni delivers unmatched accuracy and speed when it matters most.', ur: 'سخت ٹیسٹنگ اور ڈیٹا ثابت کرتے ہیں کہ روشنی بہترین درستگی اور رفتار فراہم کرتی ہے۔' },
  { selector: '.metrics-grid .metric-card:nth-child(1) h3', en: 'PKR Currency Accuracy', ur: 'کرنسی کی درستگی' },
  { selector: '.metrics-grid .metric-card:nth-child(1) p', en: 'Tested across worn, folded, and new Pakistani Rupee notes.', ur: 'پراانے، مڑے ہوئے اور نئے پاکستانی نوٹوں پر آزمایا گیا۔' },
  { selector: '.metrics-grid .metric-card:nth-child(2) h3', en: 'Real-Time Edge Inference', ur: 'ریئل ٹائم رفتار' },
  { selector: '.metrics-grid .metric-card:nth-child(2) p', en: 'Ultra-low latency object detection on standard mobile hardware.', ur: 'عام موبائل پر بھی انتہائی کم وقت میں رکاوٹوں کی شناخت۔' },
  { selector: '.metrics-grid .metric-card:nth-child(3) h3', en: 'Screen Reader Compatible', ur: 'اسکرین ریڈر کے موافق' },
  { selector: '.metrics-grid .metric-card:nth-child(3) p', en: 'Built from the ground up for full TalkBack and VoiceOver support.', ur: 'ٹاک بیک اور وائس اوور کی مکمل سپورٹ کے ساتھ تیار کردہ۔' },
  { selector: '.metrics-grid .metric-card:nth-child(4) h3', en: 'Essential Vision Tools', ur: 'ضروری بصری ٹولز' },
  { selector: '.metrics-grid .metric-card:nth-child(4) p', en: 'All integrated into a single lightweight, battery-friendly package.', ur: 'تمام فیچرز ایک ہلکی پھلکی اور بیٹری بچانے والی ایپ میں۔' },

  // Section 7: Download
  { selector: '#download-title', en: 'Ready to See the World in a <span class="text-gradient-gold">New Light?</span>', ur: 'کیا آپ دنیا کو ایک <span class="text-gradient-gold">نئی روشنی میں دیکھنے کے لیے تیار ہیں؟</span>' },
  { selector: '#download .subtitle-text', en: 'Download Roshni today on your Android or iOS device. Experience true visual independence, real-time Urdu OCR, and effortless PKR note recognition.', ur: 'آج ہی روشنی اپنے انڈرائیڈ یا آئی او ایس فون پر ڈاؤن لوڈ کریں۔ حقیقی بصری خود مختاری، اردو او سی آر اور کرنسی کی فوری پہچان کا تجربہ کریں۔' },
  { selector: '#download .btn-primary span', en: '<svg class="roshni-icon"><use href="#icon-android"></use></svg> Download Android APK (Direct)', ur: '<svg class="roshni-icon"><use href="#icon-android"></use></svg> انڈرائیڈ اے پی کے (براہ راست)' },
  { selector: '#download .btn-secondary span', en: '<svg class="roshni-icon"><use href="#icon-apple"></use></svg> iOS App Store (Coming Soon)', ur: '<svg class="roshni-icon"><use href="#icon-apple"></use></svg> آئی او ایس ایپ اسٹور (جلد آ رہا ہے)' },

  // Section 8: Footer
  { selector: '.footer-section h3', en: '<svg class="roshni-icon icon-lg icon-gold"><use href="#icon-spark"></use></svg> Roshni (روشنی)', ur: '<svg class="roshni-icon icon-lg icon-gold"><use href="#icon-spark"></use></svg> روشنی' },
  { selector: '.footer-section > div > div:nth-child(1) p', en: 'Making the world accessible, one feature at a time. Designed with love and high-contrast precision for visually impaired individuals in Pakistan.', ur: 'دنیا کو قابل رسائی بنانا، ایک وقت میں ایک قدم۔ پاکستان میں بصارت سے محروم افراد کے لیے محبت اور مکمل درستگی کے ساتھ ڈیزائن کیا گیا۔' },
  { selector: '.footer-section > div > div:nth-child(2) h4', en: 'Core Features', ur: 'بنیادی خصوصیات' },
  { selector: '.footer-section > div > div:nth-child(3) h4', en: 'Community', ur: 'کمیونٹی' },
  { selector: '.footer-section > div > div:nth-child(4) h4', en: 'Developer Contact', ur: 'ڈیولپر سے رابطہ' },
  { selector: '.footer-section > div > div:nth-child(4) > div:nth-child(3)', en: 'Lead Engineer & AI Architect', ur: 'لیڈ انجینئر اور اے آئی آرکیٹیکٹ' }
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
