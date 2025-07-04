require 'cgi'
require 'json'

# IMPORTANT: Custom builders in Bridgetown 1.3.x must use module namespace
# Without the module wrapper, you'll get a Zeitwerk::NameError
module Builders
  class AtomFeedBuilder < Bridgetown::Builder
    def build
      hook :site, :post_write do |site|
        Bridgetown.logger.info "AtomFeedBuilder:", "Generating atom feed..."
        generate_atom_feed(site)
        generate_latest_post_meta(site)
      end
    end

  private

  def generate_atom_feed(site)
    posts = site.collections.posts.resources.select(&:published?).sort_by(&:date).reverse.take(20)
    
    atom_content = <<~XML
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
        #{posts.map { |post| atom_entry(post) }.join("\n")}
      </feed>
    XML

    File.write(File.join(site.config.destination, "atom.xml"), atom_content)
  end

  def atom_entry(post)
    <<~XML
      <entry>
        <title>#{CGI.escapeHTML(post.data.title)}</title>
        <link href="#{site.config.url}#{post.relative_url}"/>
        <updated>#{post.date.xmlschema}</updated>
        <id>#{site.config.url}#{post.relative_url}</id>
        <content type="html"><![CDATA[#{post.content}
        
<p><small>This content is licensed under <a href="http://creativecommons.org/licenses/by-nc-nd/4.0/">CC BY-NC-ND 4.0</a></small></p>]]></content>
        <rights>This content is licensed under CC BY-NC-ND 4.0</rights>
        #{post.data.tags&.map { |tag| "<category term=\"#{CGI.escapeHTML(tag)}\"/>" }&.join("\n")}
      </entry>
    XML
  end

  def generate_latest_post_meta(site)
    latest_post = site.collections.posts.resources.select(&:published?).max_by(&:date)
    
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