# Content Creator's Guide

This guide is for writers who want to publish posts without worrying about the technical details.

## 📝 Writing a New Post

### Step 1: Create Your Post File

Posts go in the `src/_posts/` folder with a specific naming format:

```
YYYY-MM-DD-title-of-your-post.md
```

Examples:
- `2025-01-04-hello-world.md`
- `2025-01-15-my-thoughts-on-coffee.md`
- `2025-02-28-february-reflections.md`

### Step 2: Add Post Information (Front Matter)

Every post starts with "front matter" - basic info about your post between `---` marks:

```yaml
---
title: "My Awesome Post Title"
date: 2025-01-04 14:30:00 -0500
layout: post
summary: "A brief preview of my post for social media"
tags:
  - personal
  - technology
---
```

**Time zones:**
- `-0500` = Eastern Time
- `-0600` = Central Time  
- `-0700` = Mountain Time
- `-0800` = Pacific Time

### Step 3: Write Your Content

After the second `---`, write your post using Markdown:

```markdown
This is a paragraph. Just write normally!

## This is a Section Header

Here's another paragraph with **bold text** and *italic text*.

### Smaller Section Header

Making lists is easy:

- First item
- Second item
- Third item

Or numbered:

1. First step
2. Second step
3. Third step

Add links like this: [Click here](https://example.com)

> This is a quote. It will be styled differently.

Want to add code? Use backticks:
`inline code` or blocks:

```
code block
goes here
```
```

### Step 4: Adding Images

1. Put your image in the `src/images/` folder
2. Reference it in your post:

```markdown
![Description of the image](/images/your-image-name.jpg)
```

Example:
```markdown
Here's a photo from my morning walk:

![Sunrise over the lake](/images/sunrise-2025-01-04.jpg)

The colors were amazing!
```

### Step 5: Preview Your Post (Optional)

Want to see how it looks before publishing?

1. Open Terminal/Command Prompt
2. Navigate to your blog folder
3. Run: `bundle exec bridgetown start`
4. Open http://localhost:4000 in your browser
5. Press Ctrl+C to stop when done

### Step 6: Publish Your Post

```bash
# Add your new post
git add src/_posts/2025-01-04-your-post.md

# If you added images, add those too
git add src/images/your-image.jpg

# Commit with a message
git commit -m "Add post: Your Post Title"

# Push to publish
git push origin main
```

## 🎯 Common Scenarios

### "I want to write a draft"

Add `published: false` to your front matter:

```yaml
---
title: "Work in Progress"
date: 2025-01-04
layout: post
published: false
---
```

### "I don't want this on social media"

Control where your post goes:

```yaml
---
title: "Just for my website"
date: 2025-01-04
layout: post
syndicate_to_bluesky: false    # Won't post to Bluesky
syndicate_to_fediverse: false   # Won't post to Mastodon/Fediverse
---
```

### "I made a typo!"

1. Edit the file
2. Save it
3. Run:
   ```bash
   git add src/_posts/2025-01-04-your-post.md
   git commit -m "Fix typo in post"
   git push
   ```

Note: This updates your website but won't re-post to social media.

### "I want to schedule a post"

Use a future date in your front matter. The post won't appear until that date:

```yaml
---
title: "Valentine's Day Post"
date: 2025-02-14 09:00:00 -0500
layout: post
---
```

## 📱 Social Media Integration

Your posts automatically share to:
- **Mastodon/Fediverse**: Within 5-60 minutes (varies)
- **Bluesky**: Immediately after your site updates

What gets posted:
- On Bluesky: Your `summary` (or title if no summary) + link
- On Fediverse: Full post content

## 💡 Writing Tips

### Good Post Titles
- Be descriptive: "My Trip to Paris" vs "Trip"
- Avoid special characters: Use "and" not "&"
- Keep it under 60 characters

### Good Summaries
- 1-2 sentences maximum
- Think "tweet length" - under 200 characters
- Make people want to click!

### Good Tags
- Use lowercase: `coffee` not `Coffee`
- Be consistent: always use `book-reviews` not sometimes `books`
- 2-5 tags per post is plenty

## 🆘 Troubleshooting

**"My post isn't showing up!"**
- Check the date isn't in the future
- Make sure `published: true` (or omit it)
- Verify the filename format is correct

**"Images aren't working!"**
- Image must be in `src/images/`
- Use forward slashes: `/images/photo.jpg`
- Check the filename matches exactly (case-sensitive!)

**"Git says error!"**
- Make sure you're in the blog folder
- Try `git status` to see what's happening
- When in doubt, ask for help!

## 📋 Post Template

Copy this for new posts:

```markdown
---
title: "Your Title Here"
date: 2025-01-04 10:00:00 -0500
layout: post
summary: "Brief description for social media"
tags:
  - tag1
  - tag2
---

Your content starts here...
```

Remember: The most important thing is to write! Don't worry about getting everything perfect. You can always edit later.