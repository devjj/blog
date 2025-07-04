# Software Design Document: Personal Website & Federated Presence

**Version:** 2.0
**Date:** October 26, 2023
**Author:** Jose Jaramillo

## 1. Introduction & Overview

### 1.1. Purpose

This document outlines the design and architecture for a new personal website. The primary goal is to re-establish a web presence with a focus on simple, fast content publishing, modern design, and long-term maintainability. The system will function as a personal blog and will integrate with decentralized social networks, specifically the Fediverse (via ActivityPub) and the AT Protocol network.

### 1.2. Goals

*   **Core:** A fast, secure, and reliable static website.
*   **Content:** A streamlined workflow for publishing posts using Markdown.
*   **Design:** An architecture that allows for rapid iteration on the site's visual design and layout.
*   **Federation:** Automatically syndicate new posts to ActivityPub and AT Protocol networks, with per-post control.
*   **Maintainability:** Rely on a minimal, robust toolchain that requires little active maintenance.

### 1.3. Assumptions and Trade-offs

*   **Fediverse Syndication Delay:** We accept a variable syndication delay (typically 5-60 minutes) for ActivityPub in exchange for the simplicity and zero-maintenance benefit of using the third-party Bridgy Fed service.

## 2. System Architecture

The system is designed around a decoupled, static-first philosophy. The core website is a set of static files. Social federation is handled by external services and a serverless function that is triggered after a successful deployment.

### 2.1. Architectural Diagram

```
+-----------+      (git push)      +-----------------+      (build)       +-------------------+
|   You     |--------------------->|   Git Repo      |------------------->|  CI/CD Platform   |
| (Content) |                      | (GitHub/GitLab) |                    | (Netlify)         |
+-----------+                      +-----------------+                    +---------+---------+
                                                                                    | (deploy)
                                                              +---------------------+-------------------+
                                                              |                                         |
                                                              v                                         v (onSuccess trigger)
+----------------+  (poll feed) +----------------------------------+     +-------------------------------+
|  Bridgy Fed    |<-------------|         Static Website           |     |  ATProto Syndication Function |
| (ActivityPub)  |              |       (HTML/CSS/JS)              |     |  (Netlify Function / Ruby)    |
+----------------+              | +------------------------------+ |     +---------------+---------------+
                                | | Syndication Feed (atom.xml)  | |                     |
                                | +------------------------------+ |                     | (reads file)
                                | +------------------------------+ |<--------------------+
                                | | latest_post_meta.json        | |                     |
                                | +------------------------------+ |                     | (API call)
                                +----------------------------------+                     v
                                                                                +----------------+
                                                                                | Bluesky / PDS  |
                                                                                +----------------+
```

### 2.2. Component Descriptions

*   **Content Source:** All content will be stored as plain text Markdown (`.md`) files within a Git repository. Each file will contain front matter (YAML) for metadata.
*   **Static Site Generator (SSG):** **Bridgetown** will be used to transform the Markdown content and ERB/Liquid templates into a complete, static website.
*   **Static Website & Feeds:** The build output deployed to the CDN. This includes all HTML, CSS, and JS assets, as well as:
    *   **Syndication Feed:** An **Atom 1.0 feed (`atom.xml`)** containing the full, HTML-rendered content of posts with absolute URLs.
    *   **Post Metadata File:** A `latest_post_meta.json` file generated on each build, containing the title and canonical URL of the most recent post.
*   **CI/CD & Hosting Platform:** **Netlify** will monitor the Git repository, run the build command, deploy the output, and trigger the syndication function on success.
*   **ActivityPub Bridge:** **Bridgy Fed** will be configured to poll the site's Atom feed. It will act as the user's ActivityPub representative, creating a Fediverse identity (`@your.domain@your.domain`) and broadcasting new posts from the feed.
*   **WebFinger Resource:** A static file at `/.well-known/webfinger` is required by Bridgy Fed to verify domain ownership and establish the Fediverse identity.
*   **ATProto Syndication Function:** A serverless function (Ruby) triggered by a Netlify `onSuccess` notification. It reads `latest_post_meta.json`, checks if the post has already been syndicated, and if not, publishes a new "skeet" to the AT Protocol network.

## 3. Key Features & Requirements

### 3.1. Content Requirements

| ID | Feature | Requirement |
|---|---|---|
| F-01 | **Content Publishing** | User must be able to publish a new post by creating a single Markdown file and pushing it to Git. |
| F-02 | **Content Schema** | All posts must have `title`, `date`, and `layout` in their front matter. Optional fields include `summary`, `tags`, `syndicate_to_bluesky`, and `syndicate_to_fediverse`. |

### 3.2. Technical Requirements

| ID | Feature | Requirement | Implementation |
|---|---|---|---|
| T-01 | **Static Site** | The final website must consist only of static assets for performance and security. | Bridgetown build process. |
| T-02 | **Custom Domain** | The website must be served from a personal domain. | DNS configuration pointing to Netlify. |
| T-03 | **Design Iteration** | Support modern CSS and JavaScript development. | Bridgetown's esbuild integration and templating. |
| T-04 | **Reproducible Builds** | Tool versions must be locked to ensure builds are consistent between local and CI environments. | A `.tool-versions` file managed by `asdf`. |

### 3.3. Federation Requirements

| ID | Feature | Requirement | Implementation |
|---|---|---|---|
| FED-01 | **ActivityPub Syndication** | New posts must be automatically published to the Fediverse, unless `syndicate_to_fediverse: false` is in the post's front matter. | A valid Atom 1.0 feed consumed by Bridgy Fed. |
| FED-02 | **ATProto Syndication** | New posts must be automatically cross-posted to Bluesky, unless `syndicate_to_bluesky: false` is in the post's front matter. | Post-deploy serverless function on Netlify. |
| FED-03 | **Idempotency** | The ATProto syndication logic must prevent re-posting the same article on subsequent non-content builds. | The function will check the user's recent Bluesky posts for the article's canonical URL before posting. |
| FED-04 | **Federation Identity** | The system must support a valid WebFinger identity and include `rel="me"` links for service discovery and verification. | Static `webfinger` file and links in the HTML template. |
| FED-05 | **High-Quality Feed** | The syndication feed must be valid Atom 1.0, contain the full post content, and use absolute URLs for all links and images. | Bridgetown feed plugin configuration. |
| FED-06 | **Bluesky Post Formatting** | The post text sent to Bluesky should use the `summary` front matter field if present, otherwise the post `title`. The canonical URL will be appended. | Logic within the Ruby syndication function. |

### 3.4. Security Requirements

| ID | Feature | Requirement | Implementation |
|---|---|---|---|
| SEC-01 | **Credential Management** | API credentials for ATProto must not be stored in the Git repository. | Store `BLUESKY_HANDLE` and `BLUESKY_APP_PASSWORD` as secret Environment Variables in Netlify. |

## 4. Recommended Toolchain Summary

*   **Primary Language:** Ruby (v3.2.2+)
*   **Frontend JS Runtime:** Node.js (v20.9.0+)
*   **Static Site Generator:** Bridgetown
*   **Content Format:** Markdown with YAML Front Matter
*   **Version Control:** Git (hosted on GitHub)
*   **Hosting/CI/CD:** Netlify
*   **ActivityPub Integration:** Bridgy Fed
*   **ATProto Integration:** Custom Ruby script running as a Netlify Function.

## 5. Workflow

### 5.1. Local Development

1.  Ensure tooling versions are set via `asdf install`.
2.  Run `bridgetown serve` to start a local web server with live-reloading.
3.  Preview all content and design changes at `http://localhost:4000`.

### 5.2. Publishing a New Post

1.  Create a new file: `_posts/YYYY-MM-DD-my-new-post.md`.
2.  Add required YAML front matter (title, date, layout, etc.) and write the content in Markdown.
3.  Commit the changes: `git commit -m "Add new post: My New Post"`.
4.  Push to the main branch: `git push origin main`.

### 5.3. Automated Deployment & Federation

1.  Netlify detects the `git push`.
2.  It uses `netlify.toml` to install dependencies and run the `bridgetown build` command. This generates the `_site` directory, including `atom.xml` and `latest_post_meta.json`.
3.  The generated `_site` directory is atomically deployed to the CDN.
4.  Upon successful deployment, Netlify triggers the ATProto syndication function.
5.  The function reads `latest_post_meta.json`, verifies the post has not already been syndicated, respects the `syndicate_to_bluesky` flag, and calls the Bluesky API. It includes robust error handling to prevent deployment failures.
6.  Independently, Bridgy Fed polls the updated `atom.xml` feed on its own schedule and, upon finding a new post that is not opted-out, shares it to the Fediverse.

## 6. Next Steps & Configuration

1.  Initialize a local Bridgetown project and create a `.tool-versions` file.
2.  Create a GitHub repository and push the initial project.
3.  Create a `netlify.toml` file to define the build command (`bundle install && yarn install && bridgetown build`), publish directory (`_site`), and tool versions.
4.  Set up a new site on Netlify linked to the repository. Configure secret environment variables for ATProto credentials.
5.  Acquire a domain and configure DNS to point to Netlify.
6.  Create the `/.well-known/webfinger` file and add `rel="me"` links to the site's layout.
7.  Set up Bridgy Fed with the new domain and `atom.xml` feed URL.
8.  Write the `post_to_bluesky.rb` script as a Netlify Function and configure the `onSuccess` trigger.
9.  Begin creating content and iterating on the design.

