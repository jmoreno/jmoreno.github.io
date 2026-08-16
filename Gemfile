source "https://rubygems.org"

# Mismo gem que usa GitHub Pages para compilar el sitio en remoto:
# si el sitio compila en local con "bundle exec jekyll serve", compilará
# igual cuando GitHub lo construya tras el "git push".
gem "github-pages", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-feed"
  gem "jekyll-seo-tag"
  gem "jekyll-sitemap"
end

# Windows/JRuby no traen zoneinfo por defecto
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "wdm", "~> 0.1.1", platforms: [:mingw, :x64_mingw, :mswin]
