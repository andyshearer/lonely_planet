require 'rubygems'
require 'net/http'
require 'cgi'
require 'xmlsimple'


module Lonelyplanet
  # the default hostname at which the LonelyPlanet API is hosted
  DEFAULT_HOST = 'http://api.lonelyplanet.com'
  # the default api path to the LonelyPlanet API
  DEFAULT_API_PATH = '/services/get/'
  VERSION = '1.0.0'
  
  # Main client class managing all interaction with the YouTube server.
  # Server communication is handled via method_missing() emulating an
  # RPC-like call and performing all of the work to send out the HTTP
  # request and retrieve the XML response.  Inspired by the Flickr
  # interface by Scott Raymond <http://redgreenblu.com/flickr/>.
  # This in turn was insperation from the youtube gem by Shane Vitarana
  
  class Client
    def initialize(dev_id = nil, host = DEFAULT_HOST, api_path = DEFAULT_API_PATH)
      raise "developer id required" unless dev_id
      @dev_id = dev_id
      @host = host
      @api_path = api_path
    end
    
    def geotree(destination = nil, language = 'eng', hide_empty = 'false', id_type = 'description')
      raise "destination string required" unless destination
        response = geotree_api(destination, language, hide_empty, id_type)
        _parse_geotaxonomy_response(response)
    end
    
    def destination(destination = nil, language = 'eng', erm = 'false')
       raise "destination string required" unless destination
       response = destination_api(destination, language, erm)
        _parse_destination_response(response)
       # puts "http://api.lonelyplanet.com/services/get/lps.destination/xml/#{@dev_id}"
    end
    
    def destination_pois(destination = nil, activity = '*', language = 'eng', count = 5)
        raise "destination string required" unless destination
        response = destination_pois_api(destination, activity, language, count)
        _parse_pois_response(response)
    end
    
    def tagged_pois(destination = nil, tag = nil, language = 'eng', count = 5)
        raise "destination string and tag required" unless destination and tag
        response = tagged_pois_api(destination, tag, language, count)
        _parse_pois_response(response)
    end
    
    def proximity_pois(latitude = nil, longitude = nil, poi = '*', activity = 'see', radius = '5', language = 'eng', count = 5)
        response = proximity_pois_api(latitude, longitude, poi, activity, radius, language, count)
        _parse_proximity_pois_response(response)
    end
    
    def poi(poi_id = nil, language = 'eng')
        raise "poi_id required" unless poi_id
        response = poi_api(poi_id, language)
        _parse_poi_response(response)
    end
    
    def bluelists(keyword = nil, language = 'eng', count = 15, order = 'popular')
      raise "keyword string required" unless keyword
      response = bluelists_api(keyword, language, count, order)
      _parse_bluelist_response(response)
    end
    
    def bluelist_items(bluelist_id = nil, language = 'eng', count = 5, order = 'popular' )
      raise "bluelist_id required" unless bluelist_id
      response = bluelist_items_api(bluelist_id, language, count, order)
      
      # TODO, not fully implemented due to a rubbish example
    end
    
    def keyword_images(keyword = nil, language = 'eng', count = 5, order = 'title')
      raise "keyword string required" unless keyword
      response = images_api(keyword, language, count, order)
      _parse_images_response(response)
    end
    
    def search(keyword = nil, types = '*', mode = 'mixed', language = 'eng', count = 5, order = 'popular')
      raise "keyword string required" unless keyword
      response = search_api(keyword, types, mode, language, count, order)
      _parse_search_response(response)
    end
    
    def lpi(photographer = '*', location = '*', count = 5, keywords = nil, andor = nil)
      response = search_api(photographer, location, count, keywords, andor)
    end
    
    private
    # All API methods are implemented with this method.  This method is
    # like a remote method call, it encapsulates the request/response
    # cycle to the remote host. It extracts the remote method API name
    # based on the ruby method name.
    def method_missing(method_id, *params)
      _request(method_id.to_s.sub('_api', ''), *params)
    end

    def _request(method, *params)
      url = _request_url(method, *params)
      response = XmlSimple.xml_in(_http_get(url))  #, { 'ForceArray' => [ 'video', 'friend' ] }
    #  raise response['error']['description'] + " : url=#{url}" unless response['status'] == 'ok' 
      response
    end

    def _request_url(method, *params)
      param_list = String.new
      unless params.empty?
       
        params.each { |v|
          if v != nil # this technically isn't correct, as if some are nill, the order will mess up
            param_list << "#{CGI.escape(v.to_s)}/" 
          end
        }
      end
      url = "#{@host}#{@api_path}lps.#{method}/xml/#{@dev_id}/#{param_list}"
    end

    def _http_get(url)
      Net::HTTP.get_response(URI.parse(url)).body.to_s
    end

    def _parse_destination_response(response)
      Destination.new(response) 
    end
    
    def _parse_proximity_pois_response(response)
        pois = response['proximity_pois'][0]['poi']
        pois.is_a?(Array)? pois.compact.map { |poi| Poi.new(poi) } : nil
    end
    
    def _parse_pois_response(response)
      pois = response['destination_pois'][0]['poi']
      pois.is_a?(Array)? pois.compact.map { |poi| Poi.new(poi) } : nil
    end
    
    def _parse_poi_response(response)
      Poi.new(response)
    end
    
    def _parse_images_response(response)
      images = response['images'][0]['image']
      images.is_a?(Array)? images.compact.map { |image| Image.new(image) } : nil
    end
    
    def _parse_geotaxonomy_response(response)
      # puts response.to_yaml
      Geotaxonomy.new(response)
    end
    
    def _parse_bluelist_response(response)
      bluelists = response['bluelists'][0]['bluelist']
      bluelists.is_a?(Array)? bluelists.compact.map { |bluelist| Bluelist.new(bluelist) } : nil
    end
    
    def  _parse_search_response(response)
      items = response['all'][0]['item']
      items.is_a?(Array)? items.compact.map { |item| Result.new(item) } : nil
      
    end
  end
  
  class Geotaxonomy
    attr_reader :name
    attr_reader :destination_id
    attr_reader :language
    attr_reader :parents
    
    def initialize(payload)
      @name = payload['term'][0]['name'].to_s
      @destination_id = payload['term'][0]['destination_id'].to_s
      @language = payload['language'].to_s
      @parents = payload['parents'][0]['parent'].compact.map { |parent| Parent.new(parent) }
    end
    
    class Parent
      attr_reader :name
      attr_reader :tid
      def initialize(payload)
        @name = payload['name'].to_s
        @tid = payload['tid'].to_s
      end
    end
  end
  
  class Bluelist
    attr_reader :title
    attr_reader :votes
    
    def initialize(payload)
      @title = payload['title'].to_s
      @votes = payload['votes'].to_i rescue 0 # they never write 0 for some reason.
    end
  end
  
  
  class Destination
    attr_reader :title
    attr_reader :intro_mini
    attr_reader :intro_short
    attr_reader :intro_medium 
    attr_reader :history_modern
    attr_reader :history_pre_c20
    attr_reader :history_recent
    attr_reader :weather
    attr_reader :latitude
    attr_reader :longitude
    attr_reader :node_id
    attr_reader :sleep
    attr_reader :night
    attr_reader :shop
    attr_reader :see
    attr_reader :eat

    def initialize(payload)
      @title = payload['title'].to_s
      @intro_mini = payload['intro_mini'].to_s
      @intro_short = payload['into_short'].to_s
      @intro_medium = payload['intro_medium'].to_s
      @history_modern = payload['history_modern'].to_s
      @history_pre_c20 = payload['history_pre_c20'].to_s
      @history_recent = payload['history_recent'].to_s
      @weather = payload['weather'].to_s
      @latitude = payload['latitude'].to_s
      @longitude = payload['longitude'].to_s
      @node_id = payload['node_id'].to_s
      @sleep = payload['sleep'][0]
      @night = payload['night'][0]
      @shop = payload['shop'][0]
      @see = payload['see'][0]
      @eat  = payload['eat'][0]
    end    
  end
  
  class Poi
    attr_reader :title
    attr_reader :address
    attr_reader :neighbourhood
    attr_reader :tags
    attr_reader :node_id
    attr_reader :distance
    attr_reader :latitude
    attr_reader :longitude
    attr_reader :transport

    def initialize(payload)
      @title = payload['title'].to_s
      @address = payload['address'].to_s
      @neighbourhood = payload['neighbourhood'].to_s
      @tags = payload['tags'].to_s
      @node_id = payload['node_id'].to_s
      @distance = payload['distance']
      @latitude = payload['latitude']
      @longitude = payload['longitude']
      @transport = payload['transport']
      @email = payload['email']
      @website = payload['website']
      @review_summary = payload['review_summary']
    end
  end
  
  class Image
    attr_reader :title
    attr_reader :thumbnail
    attr_reader :filepath
    attr_reader :node_id
    
    def initialize(payload)
      @title = payload['title'].to_s
      @thumbnail = payload['thumbnail'].to_s
      @filepath = payload['filepath'].to_s
      @node_id = payload['node_id'].to_s
    end
  end
  
  class Result
    attr_reader :title
    attr_reader :destination_id
    attr_reader :content_type
    attr_reader :sub_type
    attr_reader :node_id
    def initialize(payload)
      @title = payload['title'].to_s
      @destination_id = payload['destination_id'].to_s.to_i
      @content_type = payload['content_type'].to_s
      @sub_type = payload['sub_type'].to_s
      @node_id = payload['node_id'].to_i
    end
  end

end