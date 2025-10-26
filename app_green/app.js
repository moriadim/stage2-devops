const express = require('express');
const app = express();

const pool = process.env.APP_POOL || 'green';
const release = process.env.RELEASE_ID || '2.0.0';
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.json({ pool, release });
});

app.listen(port, () => {
  console.log(`App ${pool} (v${release}) running on port ${port}`);
});
