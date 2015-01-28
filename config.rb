###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

sprockets.append_path File.join root, 'bower_components'
sprockets.import_asset 'responsive-nav'
sprockets.import_asset 'ionicons'

activate :syntax, :line_numbers => false, :inline_theme => "Monokai"

configure :development do
  activate :livereload, :port => '35730'
end

configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :relative_assets
end

activate :blog do |blog|
  blog.name = "projects"
  blog.prefix = "projects"
  blog.permalink = "{title}.html"
  blog.sources = "{title}.html"
  blog.layout = "projects_layout"
end

activate :blog do |blog|
  blog.prefix = "blog"
  blog.name = "blog"
  blog.permalink = "{title}.html"
  blog.sources = "{title}.html"
  blog.layout = "blog_layout"
end

activate :deploy do |deploy|
  deploy.method = :git
  deploy.build_before = true

  # Optional Settings
  # deploy.remote   = 'custom-remote' # remote name or git url, default: origin
  # deploy.branch   = 'custom-branch' # default: gh-pages
  # deploy.strategy = :submodule      # commit strategy: can be :force_push or :submodule, default: :force_push
  # deploy.commit_message = 'custom-message'      # commit message (can be empty), default: Automated commit at `timestamp` by middleman-deploy `version`
end

# Nested Layouts for Projects and Blog Pages
page "blog/*",  :layout => :blog_layout
page "projects/*", :layout => :projects_layout
page "CNAME", :layout => false
set :relative_links, true


set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :directory_indexes

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

set :markdown_engine, :redcarpet
set :markdown,  :fenced_code_blocks => true, :autolink => true, :smartypants => true

