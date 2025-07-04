# Quick Reference - Bridgetown 1.3.x

## 🚀 Commands

```bash
# Start dev server
bundle exec bridgetown start    # ✅ CORRECT
bundle exec bridgetown serve    # ❌ DOESN'T EXIST!

# Build site
bundle exec bridgetown build    # ✅ CORRECT
```

## 📁 Critical Files

**MUST HAVE these files or things break:**

1. `config/puma.rb` - Sets port to 4000
2. `server/roda_app.rb` - Must use `class RodaApp < Roda`
3. `Rakefile` - Must NOT redefine tasks

## 🔧 If Things Break

| Problem | Solution |
|---------|----------|
| "Unknown task: serve" | Use `start` not `serve` |
| Server on port 9292 | Add `config/puma.rb` |
| Deprecation warning | Fix `server/roda_app.rb` |
| Custom builder errors | Use `module Builders` wrapper |

## 🌐 Server Info

- **Dev URL**: http://localhost:4000
- **NOT**: http://localhost:9292 (that means puma.rb is missing)

Remember: This is Bridgetown 1.3.x, not 1.2.x - commands changed!