# Personal Blog with Federated Presence

A static personal website built with Bridgetown that automatically syndicates content to the Fediverse (via ActivityPub) and Bluesky (via AT Protocol).

## Quick Start

1. Install dependencies:
   ```bash
   bundle install
   npm install
   ```

2. Configure your site in `src/_data/site_metadata.yml`

3. Start the development server:
   ```bash
   bundle exec bridgetown start
   ```
   
   The server will run on http://localhost:4000

4. Create a new post:
   ```bash
   # Create a file in src/_posts/YYYY-MM-DD-title.md
   ```

## Writing and Publishing Posts

> 📚 **For detailed content creation instructions, see [POSTING_GUIDE.md](POSTING_GUIDE.md)**

### Creating a New Post

1. **Create the post file** in `src/_posts/` with this naming format:
   ```
   src/_posts/YYYY-MM-DD-your-post-title.md
   ```
   Example: `src/_posts/2025-01-04-my-first-post.md`

2. **Add the front matter** at the top of your file:
   ```yaml
   ---
   title: "Your Post Title"
   date: 2025-01-04 10:30:00 -0500
   layout: post
   summary: "A brief description for social media (optional)"
   tags:
     - technology
     - personal
   syndicate_to_bluesky: true    # Set to false to skip Bluesky
   syndicate_to_fediverse: true  # Set to false to skip Fediverse
   ---
   ```

3. **Write your content** in Markdown below the front matter:
   ```markdown
   This is my first paragraph.

   ## Section Header

   More content here with **bold** and *italic* text.

   - Bullet points
   - Work great too

   [Links](https://example.com) are easy to add.
   ```

4. **Preview locally** (optional):
   ```bash
   bundle exec bridgetown start
   # Visit http://localhost:4000 to see your post
   ```

5. **Publish your post**:
   ```bash
   git add src/_posts/YYYY-MM-DD-your-post-title.md
   git commit -m "Add new post: Your Post Title"
   git push origin main
   ```

### What Happens After You Push

1. **Automatic Build**: Netlify detects your push and builds the site
2. **Feed Generation**: Your post is added to the Atom feed at `/atom.xml`
3. **Federation**:
   - **Fediverse**: Bridgy Fed polls your feed (5-60 minute delay) and shares to ActivityPub
   - **Bluesky**: Netlify function posts immediately after successful deploy
4. **Live Site**: Your post appears on your website within 1-2 minutes

### Tips for Content Creation

- **Images**: Place images in `src/images/` and reference them:
  ```markdown
  ![Alt text](/images/my-image.jpg)
  ```

- **Draft Posts**: To create a draft that won't be published:
  ```yaml
  ---
  title: "Draft Post"
  date: 2025-01-04
  layout: post
  published: false  # This keeps it from being built
  ---
  ```

- **Scheduling**: Posts with future dates won't appear until that date passes

- **Social Media Preview**: The `summary` field is used for Bluesky posts. If not provided, the post title is used.

## Initial Deployment Setup

1. Push to GitHub
2. Connect repository to Netlify
3. Set environment variables in Netlify:
   - `BLUESKY_HANDLE`: Your Bluesky handle (e.g., `yourname.bsky.social`)
   - `BLUESKY_APP_PASSWORD`: Generate at https://bsky.app/settings/app-passwords
4. Configure your domain in Netlify
5. Update `src/.well-known/webfinger` with your actual domain
6. Update `bridgetown.config.yml` with your production URL
7. Set up Bridgy Fed:
   - Visit https://fed.brid.gy/
   - Enter your domain
   - Follow the setup instructions

## Common Content Workflows

### Quick Post (No Preview)
```bash
# 1. Create post
echo '---
title: "Quick Update"
date: 2025-01-04 15:30:00 -0500
layout: post
---

Your content here.' > src/_posts/2025-01-04-quick-update.md

# 2. Publish
git add src/_posts/2025-01-04-quick-update.md
git commit -m "Add post: Quick Update"
git push
```

### Post with Images
```bash
# 1. Add image
cp ~/Desktop/photo.jpg src/images/

# 2. Create post referencing the image
# In your post:
# ![Description of photo](/images/photo.jpg)

# 3. Commit both files
git add src/images/photo.jpg src/_posts/2025-01-04-photo-post.md
git commit -m "Add post with photo"
git push
```

### Private Post (No Federation)
```yaml
---
title: "Private Thoughts"
date: 2025-01-04
layout: post
syndicate_to_bluesky: false
syndicate_to_fediverse: false
---
```

### Updating an Existing Post
```bash
# 1. Edit the post
nano src/_posts/2025-01-04-my-post.md

# 2. Commit the update
git add src/_posts/2025-01-04-my-post.md
git commit -m "Update post: fix typo"
git push
```

Note: Updates won't re-syndicate to Bluesky/Fediverse

## Post Front Matter Reference

All available front matter options:

```yaml
---
# Required
title: "Post Title"
date: 2025-01-04 10:30:00 -0500
layout: post

# Optional
summary: "Brief description for social media"
tags:
  - tag1
  - tag2
published: true                # Set to false for drafts
syndicate_to_bluesky: true    # Set to false to skip Bluesky
syndicate_to_fediverse: true  # Set to false to skip Fediverse
---
```

## Common Commands

```bash
# Start development server (port 4000)
bundle exec bridgetown start

# Build the site without starting server
bundle exec bridgetown build

# Build with verbose output for debugging
bundle exec bridgetown build --verbose

# Start server without frontend build
bundle exec bridgetown start --skip-frontend
```

## Troubleshooting

- **Server runs on wrong port**: The server should run on port 4000. This is configured in `config/puma.rb`
- **"Unknown task: serve" error**: Use `bridgetown start`, not `serve`
- **Deprecation warnings**: Already handled - using Roda with bridgetown_server plugin

## License

This project uses dual licensing:

- **Code** (all files except content in `src/_posts/`): MIT License
- **Content** (posts in `src/_posts/`): Creative Commons BY-NC-ND 4.0

See [LICENSE.md](LICENSE.md) for details.