# Railway Backend Deployment Notes

## Important: Backend Identification

When deploying to Railway, modify the `/api/failover-test` endpoint in `server.js` to identify itself as the Railway backend:

### Change This Line:

```javascript
// In server.js, around line 355, change:
backend: 'render', // You can change this to 'railway' for the Railway deployment

// To:
backend: 'railway', // This is the Railway backend
```

### And This Message:

```javascript
// Change:
message: 'This response is from the Render backend',

// To:
message: 'This response is from the Railway backend',
```

### And These Headers:

```javascript
// Change:
headers: {
  'X-Backend-Server': 'render',
  'X-Server-Instance': process.env.HOSTNAME || 'unknown'
}

// To:
headers: {
  'X-Backend-Server': 'railway',
  'X-Server-Instance': process.env.HOSTNAME || 'unknown'
}

// And:
res.set('X-Backend-Server', 'render');

// To:
res.set('X-Backend-Server', 'railway');
```

## Environment Variables for Railway

Make sure to set these environment variables in your Railway deployment:

```
NODE_ENV=production
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=30d
MONGODB_URI=your_mongodb_connection_string
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
PORT=5000
```

## Health Check URLs

After deployment, your Railway backend will respond to these health check endpoints:

- `https://bitcoincloudmining-production.up.railway.app/health`
- `https://bitcoincloudmining-production.up.railway.app/api/health`
- `https://bitcoincloudmining-production.up.railway.app/status`
- `https://bitcoincloudmining-production.up.railway.app/ping`

## Testing the Failover System

1. **Test Backend Identity**:
   ```
   curl https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=identify
   ```

2. **Test Both Backends**:
   ```bash
   # Test Render backend
   curl https://bitcoincloudmining.onrender.com/api/failover-test?action=identify
   
   # Test Railway backend  
   curl https://bitcoincloudmining-production.up.railway.app/api/failover-test?action=identify
   ```

3. **Simulate Failover Scenarios**:
   ```bash
   # Simulate slow response (should trigger failover)
   curl "https://bitcoincloudmining.onrender.com/api/failover-test?action=delay&ms=5000"
   
   # Simulate server error (should trigger failover)
   curl "https://bitcoincloudmining.onrender.com/api/failover-test?action=error"
   ```

## Deployment Steps

1. **Deploy to Railway**:
   - Connect your GitHub repository to Railway
   - Set the environment variables listed above
   - Deploy the application

2. **Modify Backend Identification**:
   - Before deploying, modify the server.js file as described above
   - Or use environment variables to determine backend type

3. **Test Health Endpoints**:
   - Verify all health endpoints are working
   - Check that the backend identifies itself correctly

4. **Update Flutter App**:
   - The Flutter failover system is already configured with both URLs
   - No changes needed in the Flutter app

## Monitoring

Monitor your Railway deployment using:

- **Health Check**: `GET /health`
- **Detailed Status**: `GET /api/health`
- **Metrics**: `GET /api/metrics`
- **Logs**: Check Railway dashboard for logs

## Alternative: Environment-Based Identification

Instead of manually changing the code, you can use environment variables:

```javascript
// In server.js, use environment variable:
backend: process.env.BACKEND_TYPE || 'render',
message: `This response is from the ${process.env.BACKEND_TYPE || 'render'} backend`,

// Set environment variable in Railway:
BACKEND_TYPE=railway
```

This way, you can use the same codebase for both deployments.