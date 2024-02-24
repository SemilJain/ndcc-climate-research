const express = require('express');
const app = express();
const port = 3000;
const { downloadData, modifyFiles, processData, postProcess } = require('./dataProcessing');
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Welcome to CloudLab-Citizen Science Portal!!!');
});

app.post('/processDate', (req, res) => {
  const { data } = req.body;
  exec('bash /users/geniuser/processDate.sh', (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`stderr: ${stderr}`);
      return;
    }
    console.log(`stdout: ${stdout}`);
  });

  res.send(`Processed data: ${data}`);
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
