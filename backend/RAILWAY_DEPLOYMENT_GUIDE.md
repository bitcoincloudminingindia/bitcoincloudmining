# 🚀 Railway Deployment Guide

## Quick Setup Steps

### 1. Create Railway Project

1. Go to [Railway.app](https://railway.app)
2. Click "Start a New Project"
3. Connect your GitHub repository
4. Select this repository
5. Choose "Deploy from GitHub repo"

### 2. Configure Environment Variables

Go to your Railway project settings and add these environment variables:

```bash
NODE_ENV=production
BACKEND_TYPE=railway
PORT=5000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=30d
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_app_password
```

### 3. Deploy

1. Railway will automatically detect and deploy your Node.js app
2. The deployment will use the `railway.json` configuration
3. Server will start with `node server.js`

## ✅ Verification Steps

### 1. Check Health Endpoints

After deployment, test these URLs:

```bash
# Basic health check
curl https://bitcoincloudmining-production.up.railway.app/health

# Detailed API health
curl https://bitcoincloudmining-production.up.railway.app/api/health

# Quick status
curl https://bitcoincloudmining-production.up.railway.app/status

# Backend identification
curl https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=identify
```

### 2. Expected Response for Backend ID

The identity endpoint should return:

```json
{
  "success": true,
  "backend": "railway",
  "baseUrl": "https://bitcoincloudmining-production.up.railway.app",
  "message": "This response is from the RAILWAY backend",
  "environment": "production"
}
```

## 🔄 Failover System Test

### Test Both Backends

```bash
# Test Render backend
curl https://bitcoincloudmining.onrender.com/api/failover-test?action=identify

# Test Railway backend  
curl https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=identify
```

### Test Failover Scenarios

```bash
# Simulate slow Railway response (should trigger failover to Render)
curl "https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=delay&ms=5000"

# Simulate Railway error (should trigger failover to Render)
curl "https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=error"
```

## 📱 Flutter App Integration

The Flutter app is already configured for failover:

- **Primary**: Render (https://bitcoincloudmining.onrender.com)
- **Secondary**: Railway (https://bitcoincloudmining-production.up.railway.app)

No changes needed in Flutter app - the `BackendFailoverManager` will automatically:

1. Try Render first
2. If Render fails, switch to Railway
3. Cache the working backend for 5 minutes
4. Retry failed backends periodically

## 🔍 Monitoring

### Railway Dashboard

Monitor your deployment:

- **Logs**: Check Railway dashboard for real-time logs
- **Metrics**: View CPU, memory, and network usage
- **Deployments**: Track deployment history

### Health Monitoring

Set up monitoring for these endpoints:

- `/health` - Primary health check
- `/api/health` - Detailed health with database status
- `/status` - Lightweight status for load balancers
- `/ping` - Fastest response time check

## 🚨 Troubleshooting

### Common Issues

1. **Environment Variables Missing**
   ```bash
   # Check Railway logs for missing variables
   # Add them in Railway project settings
   ```

2. **Database Connection Failed**
   ```bash
   # Verify MONGODB_URI is correct
   # Check database whitelist for Railway IPs
   ```

3. **Backend Not Responding**
   ```bash
   # Check Railway deployment logs
   # Verify domain is pointing correctly
   ```

### Debug Commands

```bash
# Check server logs
railway logs

# Check environment variables
railway variables

# Restart deployment
railway redeploy
```

## 📋 Deployment Checklist

- [ ] Repository connected to Railway
- [ ] Environment variables configured
- [ ] Deployment successful
- [ ] Health endpoints responding
- [ ] Backend identification working
- [ ] Failover system tested
- [ ] Flutter app tested with both backends

## 🔄 Updates and Maintenance

### Updating Deployment

1. Push changes to GitHub
2. Railway will auto-deploy
3. Monitor deployment logs
4. Test health endpoints
5. Verify failover still works

### Rolling Back

If deployment fails:

1. Go to Railway dashboard
2. Select previous deployment
3. Click "Redeploy"
4. Monitor logs for issues

## 📞 Support

If you encounter issues:

1. Check Railway deployment logs
2. Test health endpoints manually
3. Verify environment variables
4. Check Flutter app failover logs
5. Contact Railway support if needed