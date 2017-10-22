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
#   if status
#     puts "Todo ha ido bien"
#     puts "\n## Publicando tweet de último post escrito"
#     Rake::Task[:share_with_twitter].execute
#   end
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
