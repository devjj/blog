# WebFinger Configuration

The `webfinger` file in this directory is required for ActivityPub federation via Bridgy Fed.

## Important Notes

1. **Domain configured**: The webfinger file is already configured for jsj.dev
2. **File format**: Must be valid JSON (no comments allowed)
3. **File name**: Must be exactly `webfinger` (no extension)
4. **Build process**: This directory is included in the build because of `include: [".well-known"]` in bridgetown.config.yml

## Testing

After deployment, test your WebFinger endpoint:
```
https://jsj.dev/.well-known/webfinger?resource=acct:jsj.dev@jsj.dev
```

It should return the JSON content with proper headers.