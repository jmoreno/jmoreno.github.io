require 'twitter'
require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'

twitter_consumer_key        = "iKlFXudh6s2W8gdaGuf0KssIq"
twitter_consumer_secret     = "ECgJAdc04KSH7tfJHZmb9mox6kXM7F9ld1W7ckrflf70sVU6YN"
twitter_access_token        = "99518813-ocEhp9MmGmwkx1tMR15PNTddyYMG81ljAHq8I2cjw"
twitter_access_token_secret = "fNxXteJ35AWf4JGYaPlPnIR2bAWgxnQPukMWNP6TgaSxE"
medium_integration_token    = "2fa749744efd787deafdf7819aa67da0f51943f574356529722aba8073978cd81"
medium_user_id              = "115595d86fa77c73315eee59c5e3db78c1611d9dbd0ec85ad19f1a80e110583a8"

task :publish_on_medium do
 
  if File.exists? ".medium/posts.info"
    File.open(".medium/posts.info", 'rb') {|f| @posts = Marshal::load(f)}
  else
    @posts = []
  end
   
  @posts.each{ |post|
    if post["response"] == ""
      puts "Publicando en Medium: " + post["title"]
      content = "<h1>#{post['title']}</h1>#{post['content']}"
      
#       uri = URI('https://api.medium.com/v1/me')
#
# 			Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
# 	      request = Net::HTTP::Get.new(uri, {"Authorization" => "Bearer #{medium_integration_token}"})
# 			  response = http.request request # Net::HTTPResponse object
# 			  puts response.body
# 			end

      uri = URI("https://api.medium.com/v1/users/#{medium_user_id}/posts")

			Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
	      request = Net::HTTP::Post.new(uri, {"Authorization" => "Bearer #{medium_integration_token}"})
	      request.set_form_data('title' => post['title'], 'contentFormat' => 'html', 'content' => content, 'canonicalUrl' => post['permalink'], 'publishStatus' => 'public', 'notifyFollowers' => true)
			  response = http.request request # Net::HTTPResponse object
			  post['response'] = response.body
			end

    end
  }
 
  File.open(".medium/posts.info", 'wb') {|f| f.write(Marshal.dump(@posts)) }
 
end

desc "Publicación automática"
task :publicar do
  puts "\n## Generación del sitio estático con Octopress"
  status = system("bundle exec jekyll build -q")
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
    puts "\n## Publicando en Medium el último post escrito"
    Rake::Task[:publish_on_medium].execute
  end
end