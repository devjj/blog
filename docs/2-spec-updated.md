# Software Design Document: Personal Website & Federated Presence

**Version:** 3.0  
**Date:** January 4, 2025  
**Status:** Implementation-Tested

## 1. Introduction & Overview

### 1.1. Purpose

This document provides a complete, tested specification for building a personal website with federated social presence. It incorporates all lessons learned from a working implementation, providing clear guidance to avoid common pitfalls.

### 1.2. Goals

* **Core:** A fast, secure, and reliable static website
* **Content:** Streamlined workflow for publishing posts using Markdown
* **Design:** Architecture allowing rapid iteration on visual design
* **Federation:** Automatic syndication to ActivityPub and AT Protocol networks
* **Maintainability:** Minimal, robust toolchain requiring little maintenance

### 1.3. Key Implementation Notes

* Bridgetown 1.3.x uses `start` command, not `serve`
* The server runs on port 4000 by default (configured via Puma)
* Custom builders must be in proper module namespace
* The `bridgetown-feed` plugin should be used for Atom feed generation

## 2. System Architecture

### 2.1. Component Overview

```
┌─────────────┐     git push    ┌─────────────┐     build      ┌─────────────┐
│   Author    │────────────────▶│  Git Repo   │───────────────▶│   Netlify   │
│  (Content)  │                 │  (GitHub)   │                 │   (CI/CD)   │
└─────────────┘                 └─────────────┘                 └──────┬──────┘
                                                                       │ deploy
                                                    ┌──────────────────┴──────────────────┐
                                                    │                                     │
                                                    ▼                                     ▼
┌─────────────┐  polls feed   ┌─────────────────────────┐      ┌──────────────────────┐
│ Bridgy Fed  │◀──────────────│    Static Website       │      │  ATProto Function    │
│(ActivityPub)│               │   (HTML/CSS/JS)         │      │ (Netlify Function)   │
└─────────────┘               │ • atom.xml              │◀─────│                      │
                              │ • latest_post_meta.json │      │                      │
                              │ • .well-known/webfinger │      │                      │
                              └─────────────────────────┘      └──────────┬───────────┘
                                                                          │ API call
                                                                          ▼
                                                               ┌──────────────────────┐
                                                               │      Bluesky         │
                                                               │   (AT Protocol)      │
                                                               └──────────────────────┘
```

### 2.2. Directory Structure

```
blog/
├── src/                        # Source files
│   ├── _posts/                # Blog posts (Markdown)
│   ├── _layouts/              # HTML templates
│   ├── _data/                 # Site configuration
│   │   └── site_metadata.yml  # Site metadata
│   ├── .well-known/           # WebFinger for ActivityPub
│   │   └── webfinger         # WebFinger JSON file
│   ├── css/                   # Stylesheets (imports from frontend)
│   ├── js/                    # JavaScript (static copies)
│   ├── index.md              # Homepage
│   └── about.md              # About page
├── netlify/
│   └── functions/             # Serverless functions
│       └── post_to_bluesky.rb # ATProto syndication
├── plugins/
│   └── builders/              # Custom Bridgetown builders
│       └── atom_feed_builder.rb
├── frontend/                  # Frontend source files
│   ├── javascript/           # JavaScript sources
│   └── styles/               # CSS sources
├── config/                    # Configuration files
│   ├── initializers.rb       # Bridgetown initializers
│   └── puma.rb              # Puma server config
├── server/
│   └── roda_app.rb          # Roda application
├── output/                   # Build output (git-ignored)
├── bridgetown.config.yml     # Main configuration
├── Gemfile                   # Ruby dependencies
├── package.json              # Node dependencies
├── netlify.toml              # Netlify configuration
├── Rakefile                  # Build tasks
├── config.ru                 # Rack configuration
└── esbuild.config.js         # JavaScript bundler config
```

## 3. Implementation Details

### 3.1. Core Configuration Files

#### bridgetown.config.yml
```yaml
# Site configuration
url: "https://yourdomain.com" # Change for production
permalink: pretty
timezone: America/New_York

# Directory configuration
source: src
destination: output
collections_dir: .
plugins_dir: plugins

# Collections
collections:
  posts:
    output: true
    permalink: /:year/:month/:day/:title/

# Defaults
defaults:
  - scope:
      path: "_posts"
    values:
      layout: "post"
      syndicate_to_bluesky: true
      syndicate_to_fediverse: true

# Feed plugin configuration
feed:
  categories:
    - updates

# Include dot files/folders
include:
  - .well-known
```

#### Gemfile
```ruby
source "https://rubygems.org"

gem "bridgetown", "~> 1.3.4"
gem "puma", "~> 6.0"

# Bridgetown plugins
group :bridgetown_plugins do
  gem "bridgetown-feed", "~> 3.0"
end
```

#### config/puma.rb
```ruby
# Critical: Sets the correct port for Bridgetown
port ENV.fetch("PORT") { 4000 }
environment ENV.fetch("RACK_ENV") { "development" }
plugin :tmp_restart
```

### 3.2. Server Configuration

#### server/roda_app.rb
```ruby
# IMPORTANT: Use Roda, not Bridgetown::Rack::Roda (deprecated)
class RodaApp < Roda
  plugin :bridgetown_server

  plugin :default_headers,
    'Content-Type'=>'text/html',
    'X-Content-Type-Options'=>'nosniff',
    'X-Frame-Options'=>'deny',
    'X-XSS-Protection'=>'1; mode=block'

  route do |r|
    r.bridgetown  # Serves the Bridgetown site
  end
end
```

### 3.3. Atom Feed Generation

#### plugins/builders/atom_feed_builder.rb
```ruby
require 'cgi'
require 'json'

# IMPORTANT: Must use proper module namespace
module Builders
  class AtomFeedBuilder < Bridgetown::Builder
    def build
      hook :site, :post_write do |site|
        generate_atom_feed(site)
        generate_latest_post_meta(site)
      end
    end

    private

    def generate_atom_feed(site)
      posts = site.collections.posts.resources
        .select(&:published?)
        .sort_by(&:date)
        .reverse
        .take(20)
      
      atom_content = build_atom_xml(site, posts)
      File.write(File.join(site.config.destination, "atom.xml"), atom_content)
    end

    def build_atom_xml(site, posts)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>#{site.metadata.title}</title>
          <link href="#{site.config.url}/atom.xml" rel="self"/>
          <link href="#{site.config.url}/"/>
          <updated>#{posts.first&.date&.xmlschema || Time.now.xmlschema}</updated>
          <id>#{site.config.url}/</id>
          <author>
            <name>#{site.metadata.author}</name>
            <email>#{site.metadata.email}</email>
          </author>
          <generator>Bridgetown</generator>
          #{posts.map { |post| atom_entry(site, post) }.join("\n")}
        </feed>
      XML
    end

    def atom_entry(site, post)
      <<~XML
        <entry>
          <title>#{CGI.escapeHTML(post.data.title)}</title>
          <link href="#{site.config.url}#{post.relative_url}"/>
          <updated>#{post.date.xmlschema}</updated>
          <id>#{site.config.url}#{post.relative_url}</id>
          <content type="html"><![CDATA[#{post.content}]]></content>
          #{post.data.tags&.map { |tag| "<category term=\"#{CGI.escapeHTML(tag)}\"/>" }&.join("\n")}
        </entry>
      XML
    end

    def generate_latest_post_meta(site)
      latest_post = site.collections.posts.resources
        .select(&:published?)
        .max_by(&:date)
      
      return unless latest_post

      meta = {
        title: latest_post.data.title,
        url: "#{site.config.url}#{latest_post.relative_url}",
        date: latest_post.date.iso8601,
        syndicate_to_bluesky: latest_post.data.syndicate_to_bluesky != false,
        syndicate_to_fediverse: latest_post.data.syndicate_to_fediverse != false
      }

      File.write(
        File.join(site.config.destination, "latest_post_meta.json"),
        JSON.pretty_generate(meta)
      )
    end
  end
end
```

### 3.4. WebFinger Configuration

#### src/.well-known/webfinger
```json
{
  "subject": "acct:yourdomain.com@yourdomain.com",
  "links": [
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://fed.brid.gy/yourdomain.com"
    }
  ]
}
```

### 3.5. Netlify Configuration

#### netlify.toml
```toml
[build]
  command = "bundle install && npm install && bundle exec bridgetown build"
  publish = "output"

[build.environment]
  RUBY_VERSION = "3.2.2"
  NODE_VERSION = "20.9.0"

[functions]
  directory = "netlify/functions"

# Headers for WebFinger support
[[headers]]
  for = "/.well-known/webfinger"
  [headers.values]
    Content-Type = "application/jrd+json"
    Access-Control-Allow-Origin = "*"

# Deploy success notification webhook
[[plugins]]
  package = "@netlify/plugin-webhook"
  [plugins.inputs]
    url = "/.netlify/functions/post_to_bluesky"
    event = "onSuccess"

# Redirect rules
[[redirects]]
  from = "/feed"
  to = "/atom.xml"
  status = 302
```

## 4. Common Issues and Solutions

### 4.1. Command Issues
- **Problem:** `bundle exec bridgetown serve` causes infinite loop
- **Solution:** Use `bundle exec bridgetown start` instead

### 4.2. Port Issues
- **Problem:** Server runs on port 9292 instead of 4000
- **Solution:** Create `config/puma.rb` with port configuration

### 4.3. Deprecation Warnings
- **Problem:** `Bridgetown::Rack::Roda` deprecation warning
- **Solution:** Use `class RodaApp < Roda` with `plugin :bridgetown_server`

### 4.4. Plugin Loading
- **Problem:** Custom builders not loading
- **Solution:** Use proper module namespace (`module Builders`)

### 4.5. Static File Issues
- **Problem:** `.well-known` directory not copied
- **Solution:** Add `include: [".well-known"]` to `bridgetown.config.yml`

## 5. Development Workflow

### 5.1. Initial Setup
```bash
# Install dependencies
bundle install
npm install

# Create necessary directories
mkdir -p src/_posts src/_layouts src/_data src/.well-known src/css src/js
mkdir -p frontend/javascript frontend/styles
mkdir -p netlify/functions plugins/builders config server
```

### 5.2. Local Development
```bash
# Start development server (port 4000)
bundle exec bridgetown start

# Build only (no server)
bundle exec bridgetown build

# Build with verbose output
bundle exec bridgetown build --verbose
```

### 5.3. Publishing Posts
1. Create file: `src/_posts/YYYY-MM-DD-title.md`
2. Add front matter:
   ```yaml
   ---
   title: Post Title
   date: YYYY-MM-DD
   layout: post
   summary: Optional summary for social media
   tags: [tag1, tag2]
   syndicate_to_bluesky: true
   syndicate_to_fediverse: true
   ---
   ```
3. Write content in Markdown
4. Commit and push to trigger deployment

## 6. Deployment Checklist

1. **Local Testing**
   - [ ] Run `bundle exec bridgetown build` successfully
   - [ ] Verify `output/atom.xml` exists
   - [ ] Verify `output/latest_post_meta.json` exists
   - [ ] Test with `bundle exec bridgetown start`

2. **Netlify Setup**
   - [ ] Connect GitHub repository
   - [ ] Set environment variables:
     - `BLUESKY_HANDLE`
     - `BLUESKY_APP_PASSWORD`
   - [ ] Verify build command in netlify.toml

3. **Domain Configuration**
   - [ ] Update `url` in `bridgetown.config.yml`
   - [ ] Update WebFinger with correct domain
   - [ ] Configure DNS

4. **Federation Setup**
   - [ ] Register domain with Bridgy Fed
   - [ ] Verify WebFinger endpoint works
   - [ ] Test first post syndication

## 7. Maintenance Notes

- The `output/` directory should be git-ignored
- Ruby version: 3.2.2+ (3.2.5 tested)
- Node version: 20.9.0+ (22.12.0 tested)
- Bridgetown version: 1.3.4 (specific version for stability)
- Regular dependency updates recommended quarterly

This specification represents a complete, working implementation that has been thoroughly tested and debugged.