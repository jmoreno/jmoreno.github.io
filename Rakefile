require 'twitter'
require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'

twitter_consumer_key        = "oowGNxGF38LlTYObqDlQCQ"
twitter_consumer_secret     = "EpErK20RlO9VPTPufExgeDzDQIJ1fkbr5dikT171Bg"
twitter_access_token        = "99518813-yNGjsxxBSWQYcluuY16lB4lYgel7xgR2S0jry53n5"
twitter_access_token_secret = "gh8LPBMtAjYyqkz3wckwEHu3zMsHaNFVyMcIVsKHBOmO2"

task :clean_tweet_list do
 
  if File.exists? ".karmaplugin/tweets.info"
    File.open(".karmaplugin/tweets.info", 'rb') {|f| @tweets = Marshal::load(f)}
  else
    @tweets = []
  end
   
  @tweets.each{ |tweet|
    if tweet["tweet"] == ""
      puts "Omitiendo tweet: " + tweet["title"]
      tweet["tweet"] = "Tweet omitido. Pruebas"
    end
  }
 
  File.open(".karmaplugin/tweets.info", 'wb') {|f| f.write(Marshal.dump(@tweets)) }
 
end
 

task :share_with_twitter do
 
  # Twitter config (for tweeting posts)
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = twitter_consumer_key
    config.consumer_secret     = twitter_consumer_secret
    config.access_token        = twitter_access_token
    config.access_token_secret = twitter_access_token_secret
  end
 
  if File.exists? ".karmaplugin/tweets.info"
    File.open(".karmaplugin/tweets.info", 'rb') {|f| @tweets = Marshal::load(f)}
  else
    @tweets = []
  end
   
  @tweets.each{ |tweet|
    if tweet["tweet"] == ""
      puts "Publicando tweet: " + tweet["title"]
      tweet_response = client.update("#{tweet["title"]} #{tweet["klink"]}")
      tweet["tweet"] = tweet_response
    end
  }
 
  File.open(".karmaplugin/tweets.info", 'wb') {|f| f.write(Marshal.dump(@tweets)) }
 
end

desc "Post to Medium"
task :post_to_medium do
 
  if File.exists? ".medium/posts.info"
    File.open(".medium/posts.info", 'rb') {|f| @posts = Marshal::load(f)}
  else
    @posts = []
  end
   
  @posts.each{ |post|
    if post["posted"] == "NO"
      puts "Publicando en Medium: " + post["title"]
      url = URI.parse("https://api.medium.com")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new("/v1/users/115595d86fa77c73315eee59c5e3db78c1611d9dbd0ec85ad19f1a80e110583a8/posts")
      request.add_field("Authorization", "Bearer 2fa749744efd787deafdf7819aa67da0f51943f574356529722aba8073978cd81")
      request.add_field("User-agent", 'Mozilla/5.0')
      request.add_field("Content-Type", 'application/json')
      request.add_field("Accept", 'application/json')
      request.add_field("Accept-Charset", 'utf-8')
      data = {
      	"title" => post["title"], 
      	"contentFormat" => "html",
      	"content" => post["content"],
      	"publishStatus" => "draft",
      	"canonicalUrl" => post["permalink"]
      	}
      request.body = data.to_json
      puts "antes"
      response = http.request(request)
      puts "despues"
    end
  }
 
  File.open(".medium/posts.info", 'wb') {|f| f.write(Marshal.dump(@posts)) }
 
end

desc "Publicación automática"
task :publicar do
  puts "\n## Generación del sitio estático con Octopress"
  status = system("jekyll build -q")
  if status
    puts "Todo ha ido bien"
    puts "\n## Despliegue del sitio en Github Pages"
    status = system("octopress deploy")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Staging modified files"
    status = system("git add -A")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Committing a site build at #{Time.now.utc}"
    message = "Build site at #{Time.now.utc}"
    status = system("git commit -m \"#{message}\"")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Pushing commits to remote"
    status = system("git push origin source")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Publicando tweet de último post escrito"
    Rake::Task[:share_with_twitter].execute
  end
end

desc "Publicación automática sin tweet."
task :publicar_solo do
  puts "\n## Generación del sitio estático con Octopress"
  status = system("jekyll build -q")
  if status
    puts "Todo ha ido bien"
    puts "\n## Despliegue del sitio en Github Pages"
    status = system("octopress deploy")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Staging modified files"
    status = system("git add -A")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Committing a site build at #{Time.now.utc}"
    message = "Build site at #{Time.now.utc}"
    status = system("git commit -m \"#{message}\"")
  else
    puts "Algo ha salido mal"
  end
  if status
    puts "Todo ha ido bien"
    puts "\n## Pushing commits to remote"
    status = system("git push origin source")
    puts status ? "Todo ha ido bien" : "Algo ha salido mal"
  end
end
