namespace :rimpact do
  namespace :ap do
    desc "Crunching data for a specific author."
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
      if !File.directory?(uniqname+"/authors")
        Dir.mkdir(uniqname+"/authors")
      end
      
      STDOUT.print "Whom is this data for? [John Smith]:"
      who = STDIN.gets.chomp
      who = 'John Smith' if who.empty?
    
      # Parse the raw data file into reference objects
      case file_type
      when "ris"
        all_references = RefParsers::RISParser.new.open(file)
      when "endnote"
        all_references = RefParsers::EndNoteParser.new.open(file)
      when "bibtex"
        all_references = BibTeX.open(file, :strip => false)
      end

      # Sorting records into year buckets
      # references_by_year = Hash.new
      # all_references.each do |r|
      #   year = r.year
      #   references_by_year[year] = [] if references_by_year[year].nil?
      #   references_by_year[year] << r
      # end
    end
  end
end