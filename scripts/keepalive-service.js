#!/usr/bin/env node
/**
 * OpenClaw Codespace Keepalive Service
 * 防止 GitHub Codespaces 因闲置而自动关闭
 * 
 * 运行方式：node keepalive-service.js &
 * 或者：npm run keepalive
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, '../logs/keepalive-service.log');
const KEEPALIVE_INTERVAL = 5 * 60 * 1000; // 每 5 分钟执行一次（Codespace 闲置超时通常是 30 分钟）

// 确保日志目录存在
const logDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    console.log(logLine.trim());
    fs.appendFileSync(LOG_FILE, logLine);
    
    // 保持日志文件大小（保留最近 200 行）
    try {
        const content = fs.readFileSync(LOG_FILE, 'utf-8');
        const lines = content.split('\n').slice(-200);
        fs.writeFileSync(LOG_FILE, lines.join('\n'));
    } catch (e) {
        // 忽略日志清理错误
    }
}

function checkOpenClawGateway() {
    return new Promise((resolve) => {
        exec('pgrep -f "openclaw-gateway"', (error, stdout) => {
            resolve(stdout.trim().length > 0);
        });
    });
}

function pingGitHub() {
    return new Promise((resolve) => {
        exec('curl -s -o /dev/null -w "%{http_code}" https://api.github.com', (error, stdout) => {
            resolve(stdout.trim());
        });
    });
}

function pingCodespace() {
    // 访问 Codespace 的端口来保持活跃
    return new Promise((resolve) => {
        exec('curl -s -o /dev/null -w "%{http_code}" http://localhost:18789 || echo "000"', (error, stdout) => {
            resolve(stdout.trim());
        });
    });
}

async function keepalive() {
    log('🔥 Keepalive triggered');
    
    // 检查 OpenClaw Gateway
    const isGatewayRunning = await checkOpenClawGateway();
    if (isGatewayRunning) {
        log('✅ OpenClaw Gateway is running');
    } else {
        log('⚠️ OpenClaw Gateway not found!');
    }
    
    // Ping GitHub API
    const ghStatus = await pingGitHub();
    log(`📍 GitHub API Status: ${ghStatus}`);
    
    // Ping Codespace 本地端口
    const csStatus = await pingCodespace();
    log(`📍 Codespace Local Status: ${csStatus}`);
    
    log('✨ Keepalive completed\n');
}

// 立即执行一次
keepalive();

// 定时执行
setInterval(keepalive, KEEPALIVE_INTERVAL);

log('🚀 Keepalive service started (interval: 5 minutes)');
log(`📝 Log file: ${LOG_FILE}`);

// 处理退出信号
process.on('SIGINT', () => {
    log('👋 Keepalive service stopping...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    log('👋 Keepalive service stopping...');
    process.exit(0);
});
