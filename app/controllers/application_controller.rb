require 'open-uri'
require 'net/http'

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def find_activities url
    if url[/calendar.boston/]
      
      root = "http://calendar.boston.com"
      main = get_main(url, ".z-listing-module-more", root)
      links = get_links(main, ".title_content", "a", root)
      return links
      
    elsif url[/sfmoma/]
      
      root = "http://sfmoma.org"
      main = get_main(url, "#level-2 a", root)
      links = get_links(main, ".url", nil, root)
      return links      
      
    elsif url[/openspace/]
      
      root = "http://openspace.org/activities"
      main = get_page(root)
      links = get_links(main, ".grid_copy", ".copy_link", root)
      return links
      
    elsif url[/workshopsf/]
      root = "http://www.workshopsf.org"
      main = get_main(url, "td:nth-child(2) a", root)
      links = get_links(main, "a", nil, root)
      return links
      
    elsif url[/events.stanford/]
      root = "http://events.stanford.edu"
      main = get_main(url, "a", root)
      links = get_links(main, ".event-box", nil, root)
      return links
      
    else
      find_more_activities url
    end
    
  end
  
  def find_more_activities url # Attempts to find root events page and collect links from here
    agent = Mechanize.new # This gem runs with Nokogiri under the hood, but returns more information
    looking = true
    extension = ""
    main = url
    root = get_root(url)
    searches = []
    links = []
    i = 0
    
    begin    
      agent.get(url) # Searches the page for links that may be the main events page
      agent.page.links.each do |link|
        if link.text[/(Event|event|Activit|activit)/]
          if link.href.include?("http")
            unless searches.include?(link.href)
              if is_valid(link.href)
                searches << link.href
              end
            end
          else
            full_link = root + normalise_path(link.href)
            unless links.include?(full_link)
              if is_valid(full_link)
                searches << full_link
              end
            end
          end
        end
      end
    rescue
    end
    
    while looking # Finds the main events address via the URL
      adds = main.reverse.partition("/")
      adds.each { |add| add.reverse! }
      if extension.empty?
        extension = adds.first
      else
        extension = adds.first + "/" + extension
      end
      main = adds.last
      looking = is_valid(main)
    end
    
    searches << main
    searches.sort_by! { |search| search.length }
    searches.reverse!
        
    start = root.length + 1
    finish = url.length
    path = url[start..finish]
    
    options = path.split("/").reverse # Creates options for event keywords from original event URL
    options << ""
    
    searches.each do |search| # Searches through potential events pages for URLs that match likely event keywords until 10 are found
      if i < 10
        begin
          agent.get(search) # Uses Mechanize to load the page and searches for links that match the likely options
        rescue
          break
        end
        options.each do |option|
          if agent.page && agent.page.links.present? && i < 10
            agent.page.links.each do |link|
              if i < 10
                if link.href
                  if link.href.include?(option)
                    if link.href.include?("http")
                      unless links.include?(link.href)
                        if is_valid(link.href) # To check for valid URL
                          links << link.href
                          i += 1
                        end
                      end
                    else
                      full_link = root + normalise_path(link.href)
                      unless links.include?(full_link)
                        if is_valid(full_link)
                          links << full_link
                          i += 1
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    
    return links
    
  end
  
  def get_page url
    Nokogiri::HTML(open(url))  # Nokogiri is the gem that will allow us to scrape the websites for activities
  end
  
  def get_root url # Returns root url 
    root = url
    found = false
    loop do
      adds = root.reverse.partition("/")
      adds.each { |elt| elt.reverse! }
      unless adds.last == "http:/"
        root = adds.last
      else
        break
      end
    end
    return root
  end
  
  def get_main url, where, root # This will take us from a single event page to one displaying many activities: the root domain
    article = get_page(url)
    more = article.at_css("#{where}")[:href]
    more = root + more unless more[/\A#{root}/]
    return get_page(more)
  end
  
  def get_links main, table, element, root # Collects ten links from the root activities page
    links = []
    i = 0
    main.css("#{table}").each do |section|
      if i < 10
        if element
          unless section.at_css("#{element}")[:href][0..3] == "http" || section.at_css("#{element}")[:href].nil? # Precaution to make sure only activities are considered
            path = normalise_path(section.at_css("#{element}")[:href])
            unless links.include?(root + path) # To make sure an activity only appears once in the list
              links << root + path
              i += 1
            end
          end
        else
          unless section[:href][0..3] == "http" || section[:href].nil?
            path = normalise_path(section[:href])
            unless links.include?(root + path)
              links << root + path
              i += 1
            end
          end
        end
      end
    end
    return links
  end
  
  def normalise_path path
    unless path[0] == "/"
      path.insert(0, "/")
    end
    return path
  end
  
  def is_valid address
    begin
      url = URI.parse(address)
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      if res.code == "200"
        return true
      else
        return false
      end
    rescue
      return false
    end
  end
      
      
end
