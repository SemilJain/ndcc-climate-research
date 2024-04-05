const express = require('express');
const moment = require('moment');
const { exec } = require('child_process');
const fs = require('fs');
const app = express();
const port = 3000;
app.use(express.json());
app.use(express.static('/users/geniuser/gifs'));

app.get('/', (req, res) => {
  const ipAddress = req.ip; // Get visitor's IP address
  const userAgent = req.get('User-Agent'); // Get visitor's user agent (browser)
  const timestamp = new Date().toISOString(); // Get current timestamp

  // Log visitor information to a file (append mode)
  const logData = `${timestamp}, ${ipAddress}, ${userAgent}\n`;
  fs.appendFile('/users/geniuser/logs/visitor_log.csv', logData, (err) => {
    if (err) {
      console.error('Error logging visitor:', err);
    }
  });
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
  const ipAddress = req.ip;
  const userAgent = req.get('User-Agent');
  const timestamp = new Date().toISOString();

  // Log visitor information to a file (append mode)
  const logData = `${timestamp}, ${ipAddress}, ${userAgent}, ${data.name}, ${data.date}\n`;
  fs.appendFile('/users/geniuser/logs/user_log.csv', logData, (err) => {
    if (err) {
      console.error('Error logging visitor:', err);
    }
  });
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

  const command = `bash /users/geniuser/processDate.sh ${YMDH} ${MAX_FHR} ${FHR_INC} ${DATASET} ${startDate} ${endDate} 40 -97`;

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
