require 'mechanize'
require 'json'

module TransitInUa
  class Client
    BASE_URL = "http://transit.in.ua"

    def get_cities
      get_index unless @cities
      @cities
    end

    def get_types
      get_index unless @types
      @types
    end

    def get_routes
      get_index unless @routes
      @routes
    end

    def get_route(route_id)
      get_routes(Array(route_id))[0]
    end

    def get_routes(route_ids)
      get_json_data(route_url(route_id))
    end

    def get_units(route_id)
      get_json_data(units_url(route_id))
    end

    def route_url(id)
      "#{BASE_URL}/import.php?dataRequest[]=#{id}"
    end

    def units_url(id)
      "#{BASE_URL}/importTransport.php?dataRequest[]=#{id}"
    end
  private
    def agent
      @agent ||= Mechanize.new
    end

    def get_json_data(url)
      page = agent.get(url)
      page.body.gsub!("\xEF\xBB\xBF",'')
      page.body.force_encoding('utf-8')
      page.body.strip!
      if page.body == ''
        nil
      else
        JSON.parse(page.body)
      end
    end

    def get_index
      page = agent.get(BASE_URL)
      city_links = page.parser.css('div.menu-name-menu-route a.city')
      type_links = page.parser.css('div.menu-name-menu-route a.transport')
      route_links = page.parser.css('div.menu-name-menu-route a.number')

      @cities = {}
      city_links.each {|a| @cities[a[:id].strip] = {name: a.text.strip}}

      @types = {}
      type_links.each{|a| @types[a[:id].strip] = {name: a.text.strip}}

      @routes = {}
      route_links.each do |a|
        city, type, _ = a[:id].strip.split('-', 3)
        @routes[a[:id].strip] = {name: a.text.strip, type: type, city: city}
      end
    end
  end
end