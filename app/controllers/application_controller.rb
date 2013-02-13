require 'open-uri'

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def find_activities url
    if url[/calendar.boston/]
      
      root = "http://calendar.boston.com"
      main = get_main(url, ".z-listing-module-more", root)
      links = get_links(main, ".title_content", "a", root, 10)
      return links
      
    elsif url[/sfmoma/]
      
      root = "http://sfmoma.org"
      main = get_main(url, "#level-2 a", root)
      links = get_links(main, ".url", nil, root, 10)
      return links      
      
    elsif url[/openspace/]
      
      root = "http://openspace.org/activities"
      main = get_page(root)
      links = get_links(main, ".grid_copy", ".copy_link", root, 10)
      return links
      
    elsif url[/workshopsf/]
      root = "http://www.workshopsf.org"
      main = get_main(url, "td:nth-child(2) a", root)
      links = get_links(main, "a", nil, root, 10)
      return links
      
    elsif url[/events.stanford/]
      root = "http://events.stanford.edu"
      main = get_main(url, "a", root)
      links = get_links(main, ".event-box", nil, root, 10)
      return links
      
    else
      find_more_activities url
    end
    
  end
      
  
  def get_links main, table, element, root, limit # Collects ten links from the root activities page
    links = []
    i = 0
    main.css("#{table}").each do |section|
      if i < limit
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
  
      
  def find_more_activities url # Attempts to find main events pages and collect links from there
    root = get_root(url)
    
    searches = find_events_list(url, root)
    options = find_event_options(url, root)
    links = find_similar_events(searches, options, root, 10)
    
    links.sort_by! { |link| link.length }
    links.reverse! # Ordered by length by longest, assuming longest URLs are more related to event
    
    return links
    
  end
  
  
  def find_events_list url, root
    agent = Mechanize.new # This gem runs with Nokogiri under the hood, but returns more information
    looking = false
    searches = []
    main = url
    begin
      agent.get(url) # Searches the page for links that may be the main events page
    rescue
    end
    agent.page.links.each do |link|
      if link.text[/(Event|event|Activit|activit)/]
        fixed_link = normalise_url(link.href, root)
        if is_valid_url?(fixed_link) && !searches.include?(fixed_link)
          searches << fixed_link
        end
      end
    end
    
    begin  # Finds the main events address working backwards from the original event URL
      adds = main.reverse.partition("/").map! { |add| add.reverse! }
      main = adds.last
      looking = is_valid_url?(main)
    end until looking
    
    searches << main
    searches.sort_by! { |search| search.length }
    searches.reverse! # Ordered by length by longest, assuming longest URLs are more related to event
    
    return searches
  end
  
  
  def find_event_options url, root
    start = root.length + 1
    finish = url.length
    path = url[start..finish]
    
    options = path.split("/").reverse # Creates options for event keywords from original event URL, reversed so most relevant is first
    options << "" # If nothing else found, search for URLs with root URL
    
    return options
  end
  
  
  def find_similar_events search_list, option_list, root, limit
    agent = Mechanize.new
    i = 0
    links = []
    
    search_list.each do |search| # Searches through potential events pages for URLs that match likely event keywords until 10 are found
      if i < limit
        begin
          agent.get(search) # Uses Mechanize to load the page and searches for links that match the likely options
        rescue
          break
        end
        
        option_list.each do |option|
          if agent.page && agent.page.links.present? && i < limit
            
            agent.page.links.each do |link|
              if i < limit
                if link.href
                  if link.href.include?(option)
                    fixed_link = normalise_url(link.href, root)
                    if is_valid_url?(fixed_link) && !links.include?(fixed_link)
                      links << fixed_link
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
    
    return links
  end
    
  
  def normalise_path path
    unless path[0] == "/"
      path.insert(0, "/")
    end
    return path
  end
  
  
  def normalise_url url, root
    if url.include?("http")
      return url
    else
      full_url = root + normalise_path(url)
      return full_url
    end
  end
  
  
  def is_valid_url? address
    agent = Mechanize.new
    begin
      agent.get(address)
    rescue
      return false
    end
    return true
  end
      
      
end
