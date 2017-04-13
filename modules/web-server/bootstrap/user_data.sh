#!/bin/bash
echo "Initialize user data..."

curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
yum install -y nodejs

cat <<EOT >> app.js
var express = require('express'); \
var app = express(); \
app.get('/', function (req, res) { \
  res.send('Hello World says ${app_name}!'); \
}); \
app.listen(80, function () {
  console.log('Example app listening on port 80!');
});
EOT
npm install express
nohup node app.js &
echo "Initialize user data - complete"