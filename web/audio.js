// Audio player for web app
const audioContext = new (window.AudioContext || window.webkitAudioContext)();

// Preload audio files
const audioFiles = {
  tap: 'assets/audio/coin_sound.mp3',
  reward: 'assets/audio/reward_sound.mp3',
  error: 'assets/audio/error_sound.mp3'
};

// Cache for audio buffers
const audioBuffers = {};

// Load audio files
async function loadAudioFiles() {
  for (const [key, url] of Object.entries(audioFiles)) {
    try {
      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer();
      audioBuffers[key] = await audioContext.decodeAudioData(arrayBuffer);
      console.log(`Loaded audio: ${key}`);
    } catch (error) {
      console.error(`Error loading audio ${key}:`, error);
    }
  }
}

// Play sound function
function playSound(type) {
  if (!audioBuffers[type]) {
    console.warn(`Audio not loaded: ${type}`);
    return;
  }

  const source = audioContext.createBufferSource();
  source.buffer = audioBuffers[type];
  source.connect(audioContext.destination);
  source.start(0);
}

// Initialize audio
loadAudioFiles();

// Export functions to global scope
window.playTapSound = () => playSound('tap');
window.playRewardSound = () => playSound('reward');
window.playErrorSound = () => playSound('error'); 