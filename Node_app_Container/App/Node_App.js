const express = require('express');
const app = express();

// Change default port to 80, or keep process.env.PORT if defined
const port = process.env.PORT || 80;

app.get('/', (req, res) => {
    res.send('Hello from the Dockerized app on Azure with Node.js and Express!');
});

app.listen(port, () => {
    console.log(`App listening on http://localhost:${port}`);
});
