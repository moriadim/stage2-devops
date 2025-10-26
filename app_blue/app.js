const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;
const RELEASE_ID = process.env.RELEASE_ID || '1.0.0';
const POOL = process.env.APP_POOL || 'blue';

app.get('/version', (req, res) => {
  res.json({ pool: POOL, release: RELEASE_ID, port: PORT });
});

app.listen(PORT, () => {
  console.log(`Blue app running on port ${PORT}`);
});
