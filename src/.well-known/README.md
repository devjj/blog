# WebFinger Configuration

The `webfinger` file in this directory is required for ActivityPub federation via Bridgy Fed.

## Important Notes

1. **Update the domain**: Replace `yourdomain.com` with your actual domain in the webfinger file
2. **File format**: Must be valid JSON (no comments allowed)
3. **File name**: Must be exactly `webfinger` (no extension)
4. **Build process**: This directory is included in the build because of `include: [".well-known"]` in bridgetown.config.yml

## Testing

After deployment, test your WebFinger endpoint:
```
https://yourdomain.com/.well-known/webfinger?resource=acct:yourdomain.com@yourdomain.com
```

It should return the JSON content with proper headers.