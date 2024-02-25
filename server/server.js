const express = require('express');
const moment = require('moment');
const app = express();
const port = 3000;
const { downloadData, modifyFiles, processData, postProcess } = require('./dataProcessing');
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Welcome to CloudLab-Citizen Science Portal!!!');
});

app.post('/processDate', (req, res) => {
  const { data } = req.body;
  const YMDH = `${data.date}00`
  const MAX_FHR = 24;
  const FHR_INC = 3;
  const DATASET = data.uid;
  const dateTime = moment(`${data.date} ${data.time}`, 'YYYYMMDD HH:mm:ss');
  const startDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');
  dateTime.add(1, 'days');
  const endDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');

  const command = `bash /users/geniuser/processDate.sh ${YMDH} ${MAX_FHR} ${FHR_INC} ${DATASET} ${startDate} ${endDate} ${data.lat} ${data.lon}`;

  exec(command, (error, stdout, stderr) => {
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

  res.send(`Processing data: ${data}`);
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
