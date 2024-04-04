const express = require('express');
const moment = require('moment');
const { exec } = require('child_process');
const fs = require('fs');
const app = express();
const port = 3000;
const { downloadData, modifyFiles, processData, postProcess } = require('./dataProcessing');
app.use(express.json());
app.use(express.static('/users/geniuser/gifs'));

app.get('/', (req, res) => {
  res.sendFile('/users/geniuser/server/index.html');
});

// function waitForDirectory(directoryPath, callback) {
//   const intervalId = setInterval(() => {
//     if (fs.existsSync(directoryPath)) {
//       clearInterval(intervalId);
//       callback();
//     }
//   }, 5000);
// }

function waitForDirectory(directoryPath, maxTime, callback) {
  let timeElapsed = 0;
  const intervalId = setInterval(() => {
    timeElapsed += 5000;
    if (fs.existsSync(directoryPath)) {
      clearInterval(intervalId);
      callback(null);
    } else if (timeElapsed >= maxTime) {
      clearInterval(intervalId);
      callback(new Error('Timeout occurred while waiting for directory'));
    }
  }, 5000);
}

app.post('/processDate', (req, res) => {
  const data = req.body;
  data.name = data.name.replace(/\s/g, '');
  const dateFormatted = moment(data.date, 'YYYY-MM-DD').format('YYYYMMDD');
  const YMDH = `${dateFormatted}00`
  const directoryPath = `/users/geniuser/gifs/${YMDH}`;
  if (fs.existsSync(directoryPath)) {
    return res.json({ folderName: YMDH });
  }
  const MAX_FHR = 24;
  const FHR_INC = 3;
  const DATASET = `${data.name}-${dateFormatted}`;
  const dateTime = moment(`${data.date} ${data.time}`, 'YYYYMMDD HH:mm:ss');
  const startDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');
  dateTime.add(1, 'days');
  const endDate = dateTime.format('YYYY-MM-DD_HH:mm:ss');

  const command = `bash /users/geniuser/processDate.sh ${YMDH} ${MAX_FHR} ${FHR_INC} ${DATASET} ${startDate} ${endDate} 37 95`;

  console.log(command);
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error.message}`);
    }
    if (stderr) {
      console.error(`stderr: ${stderr}`);
    }
    console.log(`stdout: ${stdout}`);
  });
  const maxTime = 2400000;
  waitForDirectory(directoryPath, maxTime, (error) => {
    if (error) {
      console.log(error.message);
      return res.status(500).json({ error: error.message });
    }
    return res.json({ folderName: YMDH });
  });

});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
