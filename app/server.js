const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Welcome to the Release Readiness Lab API');
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: process.env.RELEASE_VERSION || process.env.npm_package_version,
  });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
  });
}

module.exports = app;
