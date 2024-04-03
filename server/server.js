const express = require('express');
const moment = require('moment');
const { exec } = require('child_process');
const fs = require('fs');
const app = express();
const port = 3000;
const { downloadData, modifyFiles, processData, postProcess } = require('./dataProcessing');
app.use(express.json());

app.get('/', (req, res) => {
  res.sendFile('/users/geniuser/server/index.html');
});

function waitForDirectory(directoryPath, callback) {
  const intervalId = setInterval(() => {
    if (fs.existsSync(directoryPath)) {
      clearInterval(intervalId);
      callback();
    }
  }, 5000); // Check every second
}

app.post('/processDate', (req, res) => {
  const data = req.body;
  const dateFormatted = moment(data.date, 'YYYY-MM-DD').format('YYYYMMDD');
  const YMDH = `${dateFormatted}00`
  const MAX_FHR = 24;
  const FHR_INC = 3;
  const DATASET = `${data.name}-${dateFormatted}`;
  const dateTime = moment(`${data.date} ${data.time}`, 'YYYYMMDD HH:mm:ss');
  const startDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');
  dateTime.add(1, 'days');
  const endDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');

  const command = `bash /users/geniuser/processDate.sh ${YMDH} ${MAX_FHR} ${FHR_INC} ${DATASET} ${startDate} ${endDate} 37 95`;

  console.log(command);
  // exec(command, (error, stdout, stderr) => {
  //   if (error) {
  //     console.error(`Error: ${error.message}`);
  //     return;
  //   }
  //   if (stderr) {
  //     console.error(`stderr: ${stderr}`);
  //     return;
  //   }
  //   console.log(`stdout: ${stdout}`);
  // });
  const directoryPath = `/users/geniuser/${DATASET}/gifs`;
    waitForDirectory(directoryPath, () => {
      res.json({ folderName: directoryPath });

    });
  // res.send(`Processing data: ${data.uid}`);
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
