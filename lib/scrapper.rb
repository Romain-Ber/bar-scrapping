require "csv"
require "json"
require "nokogiri"
require "open-uri"

@apilinks_file = File.join(__dir__, '../data/apilinks.csv')
@apilinks = []
@bars_file = File.join(__dir__, '../data/bars_data.json')
@bars_data = []

def loadhref(url)
  doc = Nokogiri::HTML.parse(URI.open(url), nil, "utf-8")
  # Extracting data-type and data-id attributes
  data_type = doc.search('.search_results_entry a').map { |link| link['data-type'] }
  data_id = doc.search('.search_results_entry a').map { |link| link['data-id'] }
  # Building API links
  data_type.each_with_index do |type, index|
    @apilinks << "https://www.openstreetmap.org/api/0.6/#{type}/#{data_id[index]}"
  end
end

# Calling the method to load hrefs
loadhref("../data/rennes.html")
loadhref("../data/nantes.html")

def save_csv
  CSV.open(@apilinks_file, "wb") do |csv|
    # Write header row
    csv << ["api-link"]
    @apilinks.each do |apilink|
      csv << [apilink]
    end
  end
end

# Save data to CSV file
save_csv()

def apicall
  @apilinks.each_with_index do |apilink, index|
    doc = Nokogiri::HTML.parse(URI.open(apilink), nil, "utf-8")
    # Iterate through each node
    doc.xpath('//node').each do |node|
      # Initialize a hash for each set of data
      bars_data_entry = { index: index, apilink: apilink, data: [] }
      # Extract k and v attributes and store in the data array
      node.xpath('tag').each do |tag|
        bars_data_entry[:data] << { tag['k'] => tag['v'] }
      end
      # Store the bars data entry in the @bars_data array
      @bars_data << bars_data_entry
    end
  end
end

apicall()

def save_bars_data_json
  File.open(@bars_file, "w") do |file|
    file.write(JSON.pretty_generate(@bars_data))
  end
end

save_bars_data_json()
