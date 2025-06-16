const https = require('https');
const fs = require('fs');
const path = require('path');

const audioFiles = [
  {
    name: 'coin_sound.mp3',
    url: 'https://freesound.org/data/previews/270/270304_5123851-lq.mp3'
  },
  {
    name: 'reward_sound.mp3',
    url: 'https://freesound.org/data/previews/270/270315_5123851-lq.mp3'
  },
  {
    name: 'error_sound.mp3',
    url: 'https://freesound.org/data/previews/270/270316_5123851-lq.mp3'
  },
  {
    name: 'background.mp3',
    url: 'https://freesound.org/data/previews/270/270317_5123851-lq.mp3'
  },
  {
    name: 'collect.mp3',
    url: 'https://freesound.org/data/previews/270/270318_5123851-lq.mp3'
  }
];

const downloadFile = (url, filename) => {
  const filepath = path.join(__dirname, 'assets', 'audio', filename);
  const file = fs.createWriteStream(filepath);

  https.get(url, (response) => {
    if (response.statusCode !== 200) {
      console.error(`Failed to download ${filename}: ${response.statusCode}`);
      return;
    }

    response.pipe(file);
    file.on('finish', () => {
      file.close();
      console.log(`Downloaded ${filename}`);
    });
  }).on('error', (err) => {
    fs.unlink(filepath, () => {});
    console.error(`Error downloading ${filename}: ${err.message}`);
  });
};

// Create audio directory if it doesn't exist
const audioDir = path.join(__dirname, 'assets', 'audio');
if (!fs.existsSync(audioDir)) {
  fs.mkdirSync(audioDir, { recursive: true });
}

audioFiles.forEach(file => {
  downloadFile(file.url, file.name);
}); 