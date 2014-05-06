namespace :rimpact do
  namespace :geo do
    desc "Creates graphs of geographical collaboration networks."
    task :create => :environment do

      require 'fileutils'
      require 'csv'
      require 'erb'
      require 'io/console'

      current_dir = File.dirname(File.expand_path(__FILE__))
      Dir.glob(current_dir+"/../../../classes/*.rb").each {|f| require f}
      Dir.glob(current_dir+"/../classes/*.rb").each {|f| require f}

      # Getting user input
      file_type = ""
      while file_type != 'ris' && file_type != 'bibtex' && file_type != 'endnote'
        puts "Only RIS, EndNote Export, or BibTeX files are supported."
        STDOUT.print "Where is the data file? [public/data/data.ris]:"
        file = STDIN.gets.chomp
        file = 'public/data/data.ris' if file.empty?
        file_extname = File.extname(file)
        case file_extname
        when ".bib"
          file_type = "bibtex"
        when ".ris"
          file_type = "ris"
        when ".enw"
          file_type = "endnote"
        else
          STDOUT.print "What is the file type (must be ris, bibtex, or endnote)? [ris]:"
          file_type = STDIN.gets.chomp
          file_type = 'ris' if file_type.empty?
        end 
      end
      
      STDOUT.print "Where to save the generated files? [public/results/jsmith]:"
      uniqname = STDIN.gets.chomp
      uniqname = 'public/results/jsmith' if uniqname.empty?
      if !File.directory?(uniqname)
        Dir.mkdir(uniqname)
      end
      if !File.directory?(uniqname+"/geo")
        Dir.mkdir(uniqname+"/geo")
      end
      
      STDOUT.print "Whom is this data for? [John Smith]:"
      who = STDIN.gets.chomp
      who = 'John Smith' if who.empty?
    
      # Parse the raw data file into reference objects
      case file_type
      when "ris"
        references = RefParsers::RISParser.new.open(file)
      when "endnote"
        references = RefParsers::EndNoteParser.new.open(file)
      when "bibtex"
        references = BibTeX.open(file, :strip => false)
      end
          
      # Initialize data containers
      areas = {
        "countries" => {
          "all" => []
        },
        "states" => {
          "all" => []
        }
      }
      points = {
        "cities" => {
          "all" => [],
          "international" => [],
          "domestic" => []
        }
      }
      connections = {
        "links" => {
          "all" => [],
          "domestic" => []
        },
        "spokes" => {
          "all" => [],
          "domestic" => []
        }
      }
      years = []
    
      # Counters for displaying the progress bar and the output message
      counters = {
        "references" => {
          "total" => 0,
          "skipped" => 0
        },
        "addresses" => {
          "total" => 0,
          "parsed" => 0,
          "zipcodes" => 0,
          "cities" => 0,
          "regions" => 0,
          "countries" => 0
        }
      }
    
      # Loop through the references
      references.each do |reference|
        # Get the year
        year = reference.year
        if !years.include? year
          years << year
        end
        # Get the addresses
        addresses = reference.addresses
        # If the number of addresses is larger than ...
        # This is here only because my computer is not beefy enough ...
        if addresses.size < 2000
          # Initialize containers for this individual paper
          countries = []
          states = []
          cities = []
        
          # Loop through the addresses
          addresses.each do |address|
            counters["addresses"]["total"] += 1
            # Try to parse the address to a "place"
            place = address.place
            if !place.nil?
              counters["addresses"]["parsed"] += 1
              # If it is a city, record the city, state (US only), and country.
              if place.is_a?(Gnlookup::City)
                counters["addresses"]["cities"] += 1
                if !cities.include? place
                  cities << place
                  points["cities"]["all"] << place
                  if place.country.name != "United States"
                     points["cities"]["international"] << place
                  else
                     points["cities"]["domestic"] << place
                  end
                  if place.country.name == "United States"
                    if !states.include? place.region
                      states << place.region
                      areas["states"]["all"] << place.region
                    end
                  end
                  if !countries.include? place.country
                    countries << place.country
                    areas["countries"]["all"] << place.country
                  end
                end
              # If it is a US zipcode, record the city, state, and country.
              elsif place.is_a?(Gnlookup::Zipcode)
                zipcode_city = place.city
                counters["addresses"]["zipcodes"] += 1
                if !cities.include? zipcode_city
                  cities << zipcode_city
                  points["cities"]["all"] << zipcode_city
                  if zipcode_city.country.name != "United States"
                     points["cities"]["international"] << zipcode_city
                  else
                     points["cities"]["domestic"] << zipcode_city
                  end
                  if zipcode_city.country.name == "United States"
                    if !states.include? zipcode_city.region
                      states << zipcode_city.region
                      areas["states"]["all"] << zipcode_city.region
                    end
                  end
                  if !countries.include? zipcode_city.country
                    countries << zipcode_city.country
                    areas["countries"]["all"] << zipcode_city.country
                  end
                end
              # If it is a region, record the country and the region if it is a US state.
              elsif place.is_a?(Gnlookup::Region)
                counters["addresses"]["regions"] += 1
                if place.country == "United States"
                  if !states.include? place
                    states << place
                    areas["states"]["all"] << place
                  end
                end
                if !countries.include? place.country
                  countries << place.country
                  areas["countries"]["all"] << place.country
                end
              # If it is a country, record the country.
              elsif place.is_a?(Gnlookup::Country)
                counters["addresses"]["countries"] += 1
                if !countries.include? place
                  countries << place
                  areas["countries"]["all"] << place
                end
              end
            end
          end
              
          # Generating city links (international and domestic) for this reference
          cities.combination(2).to_a.each do |pair|
            connections["links"]["all"] << pair.sort_by{|p| p.id}
          end
          cities.reject{|c| c.country.name != "United States"}.combination(2).to_a.each do |pair|
            connections["links"]["domestic"] << pair.sort_by{|p| p.id}
          end
        else
          counters["references"]["skipped"] += 1
        end
      
        # Counting records and display progress
        counters["references"]["total"] += 1
        if counters["references"]["total"]%5 == 0
          print "#"
          $stdout.flush
        end
      end
    
      # Sort the years for display on the template page
      years.sort!
    
      # Getting the "center" city for generating "spokes" data
      center = points["cities"]["all"].group_by {|x| x}.map {|k,v| [k,v.count]}[0][0]
    
      # Generating spoke data (international and domestic)
      if !center.nil?
        connections["links"]["all"].each do |link|
          if link[0].name == center.name || link[1].name == center.name
            connections["spokes"]["all"] << link
          end
        end
        if center.country.name == "United States"
          connections["links"]["domestic"].each do |link|
            if link[0].name == center.name || link[1].name == center.name
              connections["spokes"]["domestic"] << link
            end
          end
        end
      end
    
      # Counts for display on the template page
      counts = {
        "references" => counters["references"]["total"],
        "domestic_city" => points["cities"]["domestic"].group_by{|x| x}.map{|k, v| v.count}.size,
        "world_city" => points["cities"]["all"].group_by{|x| x}.map{|k, v| v.count}.size,
        "domestic_state" => areas["states"]["all"].group_by{|x| x}.map{|k, v| v.count}.size,
        "world_country" => areas["countries"]["all"].group_by{|x| x}.map{|k, v| v.count}.size
      }
    
      # Writing files
      areas.each do |ka,va|
        va.each do |kb,vb|
          CSV.open(uniqname+"/geo/"+ka+"_"+kb+".csv", 'w') do |csv|
            csv << ["name", "count"]
            Hash[vb.group_by {|x| x}.map {|k,v| [k,v.count]}].each do |l, lcount|
              csv << [l.name, lcount]
            end
          end
        end
      end
      points.each do |ka,va|
        va.each do |kb,vb|
          CSV.open(uniqname+"/geo/"+ka+"_"+kb+".csv", 'w') do |csv|
            csv << ["name", "region", "country", "lat", "lng", "count"]
            Hash[vb.group_by {|x| x}.map {|k,v| [k,v.count]}].each do |l, lcount|
              csv << [l.name, l.region.name, l.country.name, l.lat, l.lng, lcount]
            end
          end
        end
      end
      connections.each do |ka, va|
        va.each do |kb, vb|
          CSV.open(uniqname+"/geo/"+ka+"_"+kb+".csv", 'w') do |csv|
            csv << ["name1", "region1", "country1", "lat1", "lng1", "name2", "region2", "country2", "lat2", "lng2", "count"]
            Hash[vb.group_by {|x| x}.map {|k,v| [k,v.count]}].each do |l, lcount|
              csv << [l[0].name, l[0].region.name, l[0].country.name, l[0].lat, l[0].lng, l[1].name, l[1].region.name, l[1].country.name, l[1].lat, l[1].lng, lcount]
            end
          end
        end
      end
    
      # Copying files ...
      FileUtils.cp("public/external/geo/world.json", uniqname+"/geo/world.json")
      FileUtils.cp("public/external/geo/us.json", uniqname+"/geo/us.json")
            
      # Generating html template
      template = ERB.new(File.read(current_dir+"/../templates/geo.html.erb"))
      File.open(uniqname+"/geo/index.html", "w+") do |f|
        f << template.result(binding)
      end
    
      # Output message
      puts "\n" + counters["references"]["skipped"].to_s + " references were skipped because there are too many (2000 and more) addresses."
      puts "There were " + counters["addresses"]['total'].to_s + " addresses in the unskipped references, among which " + counters["addresses"]['parsed'].to_s + " were parsed."
      puts "Among the parsed addresses: "
      puts counters["addresses"]['zipcodes'].to_s + " were parsed to the zipcode level,"
      puts counters["addresses"]['cities'].to_s + " were parsed to the city level,"
      puts counters["addresses"]['regions'].to_s + " were parsed to the region level, and"
      puts counters["addresses"]['countries'].to_s + " were parsed to the country level."
      
    end
  
    desc "Checks if ambiguous addresses exist in the RIS data."
    task :check => :environment do
    
      require 'csv'
      require 'io/console'

      current_dir = File.dirname(File.expand_path(__FILE__))
      Dir.glob(current_dir+"/../../../classes/*.rb").each {|f| require f}
      Dir.glob(current_dir+"/../classes/*.rb").each {|f| require f}
    
      # Getting user input
      file_type = ""
      while file_type != 'ris' && file_type != 'bibtex' && file_type != 'endnote'
        puts "Only RIS, EndNote Export, or BibTeX files are supported."
        STDOUT.print "Where is the data file? [public/data/data.ris]:"
        file = STDIN.gets.chomp
        file = 'public/data/data.ris' if file.empty?
        file_extname = File.extname(file)
        case file_extname
        when ".bib"
          file_type = "bibtex"
        when ".ris"
          file_type = "ris"
        when ".enw"
          file_type = "endnote"
        else
          STDOUT.print "What is the file type (must be ris, bibtex, or endnote)? [ris]:"
          file_type = STDIN.gets.chomp
          file_type = 'ris' if file_type.empty?
        end 
      end
      
      STDOUT.print "Where to save the generated files? [public/results/jsmith]:"
      uniqname = STDIN.gets.chomp
      uniqname = 'public/results/jsmith' if uniqname.empty?
      if !File.directory?(uniqname)
        Dir.mkdir(uniqname)
      end
      if !File.directory?(uniqname+"/geo")
        Dir.mkdir(uniqname+"/geo")
      end
    
      # Parse the raw data file into reference objects
      case file_type
      when "ris"
        references = RefParsers::RISParser.new.open(file)
      when "endnote"
        references = RefParsers::EndNoteParser.new.open(file)
      when "bibtex"
        references = BibTeX.open(file, :strip => false)
      end
          
      count = 0
    
      buckets = {
        "unparsables" => [],
        "ambiguous_cities" => [],
        "ambiguous_regions" => []
      }
    
      references.each do |reference|
        addresses = reference.addresses
        addresses.each do |address|
          ambiguity = address.ambiguity
          if ambiguity.nil?
            buckets["unparsables"] << [address.string]
          elsif ambiguity.is_a?(Gnlookup::City)
            buckets["ambiguous_cities"] << [ambiguity.name, ambiguity.region.name, ambiguity.country.name, address.string]
          elsif ambiguity.is_a?(Gnlookup::Region)
            buckets["ambiguous_regions"] << [ambiguity.name, ambiguity.country.name, address.string]
          end
        end

        count += 1
        if count%5 == 0
          print "#"
          $stdout.flush
        end
      end

      buckets.each do |k,v|
        File.open(uniqname+"/geo/"+k+".csv", "w+") do |f|
          v.each do |item|
            f << item.join(",") + "\n"
          end
        end
      end
    
    end

    desc "Adds disambiguated cities to your preferred cities list."
    task :preferred => :environment do
      require 'csv'
      require 'io/console'

      current_dir = File.dirname(File.expand_path(__FILE__))
      Dir.glob(current_dir+"/../../../classes/*.rb").each {|f| require f}
      Dir.glob(current_dir+"/../classes/*.rb").each {|f| require f}
    
      # Getting user input
      STDOUT.print "Where are the source files? [public/results/jsmith]:"
      uniqname = STDIN.gets.chomp
      uniqname = 'public/results/jsmith' if uniqname.empty?
      if !File.directory?(uniqname)
        Dir.mkdir(uniqname)
      end
      if !File.directory?(uniqname+"/geo")
        Dir.mkdir(uniqname+"/geo")
      end
    
      found = []
      CSV.foreach(uniqname+"/geo/ambiguous_cities.csv") do |row|
        cities = Gnlookup::City.where(:name => row[0])
        cities.each do |city|
          if city.region.iso == row[1].strip
            found << city
            break
          end
        end
      end
      CSV.open("lib/impact/preferred/cities.csv", 'a') do |csv|
        found.each do |city|
          if !city.preferred?
            csv << [city.id, city.name, city.region.iso]
          end
        end
      end
    end
  end
end
