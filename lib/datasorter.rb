require "csv"
require "json"
require "nokogiri"
require "open-uri"

@bars_file = File.join(__dir__, '../data/bars_data.json')
@bars_data = []
@datatypes_file = File.join(__dir__, '../data/datatypes.csv')
@bars_file_addr = File.join(__dir__, '../data/bars_data_addr.json')

def read_bars_data_json(file)
  if File.exist?(file)
    File.open(file, "r") do |file|
      @bars_data = JSON.parse(file.read)
    end
  end
  return @bars_data
end

read_bars_data_json(@bars_file_addr)

@data_raw = []
@data_keys = []
@data_types = []
@data_types_tally = []

def extract_data
  @bars_data.each do |bar_data|
    @data_raw << bar_data["data"]
  end
  @data_raw.flatten!
  @data_raw.each do |data|
    @data_keys << data.keys
    @data_types << data.keys
  end
  @data_types = @data_types.uniq
  @data_types_tally = @data_keys.tally.sort_by { |key, count| -count } #sort by count
  #@data_types_tally = @data_keys.tally.sort #sort alphabetically
end

extract_data()

def save_csv
  CSV.open(@datatypes_file, "wb") do |csv|
    # Write header row
    csv << ["type", "count"]
    @data_types_tally.each do |data_type|
      csv << [data_type[0][0], data_type[1]]
    end
  end
end

save_csv()

@data_raw = []
@exclude_data = []

def query
  @bars_data.each do |bar_data|
    haskey = 0
    bar_data["data"].each do |hash|
      if hash.has_key?("addr:city")
        haskey = haskey + 1
      end
    end
    if haskey > 1
      @exclude_data << bar_data["index"]
    end
  end
  p @exclude_data
end

query()

def address_builder
  @bars_data.each do |bar_data|
    name = ""
    housenumber = ""
    street = ""
    postcode = ""
    city = ""
    bar_data["data"].each do |data|
      name = data["name"] if data["name"]
      housenumber = data["addr:housenumber"] if data["addr:housenumber"]
      street = data["addr:street"] if data["addr:street"]
      postcode = data["addr:postcode"] if data["addr:postcode"]
      city = data["addr:city"] if data["addr:city"]
    end
    address = "#{name}, #{housenumber} #{street} #{postcode} #{city}"
    address = address.squeeze(" ")
    bar_data["data"] << { "address": address }
  end
end

address_builder()

def save_bars_data_json
  File.open(@bars_file_addr, "w") do |file|
    file.write(JSON.pretty_generate(@bars_data))
  end
end



#save_bars_data_json()
