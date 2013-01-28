require 'open-uri'

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
    end
  end
  
  def get_page url
    Nokogiri::HTML(open(url))  # Nokogiri is the gem that will allow us to scrape the websites for activities
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
      
      
end
