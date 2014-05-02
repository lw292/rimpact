namespace :rimpact do
  namespace :authors do
    desc "Creates force-directed graphs of author collaboration networks."
    task :create => :environment do
      require 'fileutils'
      require 'csv'
      require 'erb'
      require 'io/console'
      current_dir = File.dirname(File.expand_path(__FILE__))
      Dir.glob(current_dir+"/../../../classes/*.rb").each {|f| require f}
      Dir.glob(current_dir+"/../classes/*.rb").each {|f| require f}
    
      # Getting necessary user input
      file_type = ""
      while file_type != '.ris' && file_type != '.bib'
        puts "Only RIS (.ris) or BibTeX (.bib) files are supported."
        STDOUT.print "Where is the data file? [public/data/data.ris]:"
        file = STDIN.gets.chomp
        file = 'public/data/data.ris' if file.empty?
        file_extname = File.extname(file)
        if file_extname == ".bib" || file_extname == ".ris"
          file_type = file_extname
        else
          STDOUT.print "What is the file type (must be either .ris or .bib)? [.ris]:"
          file_type = STDIN.gets.chomp
          file_type = '.ris' if file_type.empty?
        end 
      end
      
      STDOUT.print "Where to save the generated files? [public/results/jsmith]:"
      uniqname = STDIN.gets.chomp
      uniqname = 'public/results/jsmith' if uniqname.empty?
      if !File.directory?(uniqname)
        Dir.mkdir(uniqname)
      end
      if !File.directory?(uniqname+"/authors")
        Dir.mkdir(uniqname+"/authors")
      end
      
      STDOUT.print "Whom is this data for? [John Smith]:"
      who = STDIN.gets.chomp
      who = 'John Smith' if who.empty?
    
      # Parse the raw data file into reference objects
      if file_type == ".ris"
        all_references = RefParsers::RISParser.new.open(file)
      elsif file_type == ".bib"
        all_references = BibTeX.open(file, :strip => false)
      end

      # Sorting records into year buckets
      references_by_year = Hash.new
      all_references.each do |r|
        year = r.year
        references_by_year[year] = [] if references_by_year[year].nil?
        references_by_year[year] << r
      end
    
      skipped_count = 0
    
      # Looping through each year bucket
      references_by_year.each do |year, references|
          # Initializing nodes and links containers
          nodes = []
          links = []
          # Reset counters
          count = 0
          author_count = 0
          # Loop through each record
          references.each do |reference|
            # Get the authors from the record
            authors = reference.authors
            # If the number of authors is larger than ...
            if authors.size < 100
              # Reset containers
              author_ids = []
              author_links = []
              # Loop through each author
              authors.each do |value|
                # If a node already exists for this author in this year's data
                if nodes.any? {|n| n["name"] == value}
                  # Locate that node
                  node = nodes.find{|n| n["name"] == value}
                  # Increment the group count
                  node["group"] += 1
                  # Add the id of the author to the author id container for generating links
                  author_ids << node["id"]
                # Otherwise create a new node with a group count of 1
                else
                  nodes << {"name" => value, "group" => 1, "id" => author_count}
                  # Add the id (equals the author count) of the author to the author id container for generating links
                  author_ids << author_count
                  # Increment the author count
                  author_count += 1
                end
              end
          
              # Genearting links
              author_ids.combination(2).to_a.each do |p|
                author_links << p.sort
              end
              # Add the links to the big links array
              links.concat(author_links)
            else
              skipped_count += 1
            end
          
            # Counting progress
            count += 1
            if count%5 == 0
              print "#"
              $stdout.flush
            end
          end
        
          # Create final json output
          json = {
            "nodes" => nodes,
            "links" => []
          }
          Hash[links.group_by {|x| x}.map {|k,v| [k,v.count]}].each do |l, lcount|
            json['links'] << {"source" => l[0], "target" => l[1], "value" => lcount}
          end
          File.open(uniqname+"/authors/"+year+".json","w") do |f|
            f.write(json.to_json)
          end
        end
      
        # Getting years arrays
        years = references_by_year.keys
        all_years = years.clone.sort!
        years.reject!{|y| File.size(uniqname+"/authors/"+y+".json") > 524288}
        years.sort!

        # Generating html file ...
        template = ERB.new(File.read(current_dir+"/../templates/authors.html.erb"))
        File.open(uniqname+"/authors/index.html", "w+") do |f|
          f << template.result(binding)
        end
      
        puts "\n" + skipped_count.to_s + " references were skipped because they have too many authors."
    end
  end
end