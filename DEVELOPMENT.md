# Development Guide

This guide contains important information for developing and maintaining this Bridgetown site.

## ⚠️ Important Notes for Bridgetown 1.3.x

### Correct Commands

- ✅ Use: `bundle exec bridgetown start`
- ❌ NOT: `bundle exec bridgetown serve` (this command doesn't exist)
- ✅ Build: `bundle exec bridgetown build`

### Key Files That Prevent Common Issues

1. **`config/puma.rb`** - REQUIRED
   - Sets the server port to 4000
   - Without this file, server runs on port 9292

2. **`server/roda_app.rb`** 
   - Must inherit from `Roda`, not `Bridgetown::Rack::Roda`
   - Uses `plugin :bridgetown_server`

3. **`Rakefile`**
   - Do NOT redefine :serve, :build, or :clean tasks
   - Will cause infinite recursion

4. **`plugins/builders/`**
   - Custom builders must use module namespace
   - Example: `module Builders; class AtomFeedBuilder < Bridgetown::Builder`

## Project Structure

```
blog/
├── src/                 # Source files (Markdown, layouts, assets)
├── output/             # Generated site (git-ignored)
├── plugins/            # Custom Bridgetown builders
├── netlify/functions/  # Serverless functions
├── config/             # Puma and other configs
├── server/             # Roda application
└── frontend/           # JavaScript and CSS sources
```

## Development Workflow

### Starting Fresh

```bash
# Install dependencies
bundle install
npm install

# Start development server
bundle exec bridgetown start

# Server runs at http://localhost:4000
```

### Creating Posts

1. Create file: `src/_posts/YYYY-MM-DD-title.md`
2. Add front matter:
   ```yaml
   ---
   title: Your Title
   date: YYYY-MM-DD
   layout: post
   ---
   ```
3. Server auto-reloads on save

### Building for Production

```bash
# Build static files
bundle exec bridgetown build

# Output goes to output/ directory
```

## Common Issues

### Issue: "Unknown task: serve"
**Solution**: Use `bridgetown start` instead

### Issue: Server on wrong port (9292)
**Solution**: Ensure `config/puma.rb` exists with port 4000

### Issue: Deprecation warning about Bridgetown::Rack::Roda
**Solution**: Check `server/roda_app.rb` inherits from `Roda`

### Issue: Custom builders not loading
**Solution**: Use proper module namespace in plugins

### Issue: .well-known not copied
**Solution**: Check `include: [".well-known"]` in bridgetown.config.yml

## Testing Checklist

Before deploying:
- [ ] `bundle exec bridgetown build` succeeds
- [ ] `output/atom.xml` exists
- [ ] `output/latest_post_meta.json` exists
- [ ] `output/.well-known/webfinger` exists
- [ ] Server runs on port 4000

## Dependencies

- Ruby 3.2.2+ (tested with 3.2.5)
- Node.js 20.9.0+ (tested with 22.12.0)
- Bridgetown 1.3.4 (specific version for stability)