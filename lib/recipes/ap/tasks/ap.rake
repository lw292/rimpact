namespace :rimpact do
  namespace :ap do
    desc "Calculating H-indices from articles of the same author."
    task :calculate => :environment do
      require 'fileutils'
      require 'io/console'
      current_dir = File.dirname(File.expand_path(__FILE__))
      Dir.glob(current_dir+"/../../../classes/*.rb").each {|f| require f}
      Dir.glob(current_dir+"/../classes/*.rb").each {|f| require f}
      
      puts "Only BibTeX files are supported."
      STDOUT.print "Where is the data file? [public/data/data.bib]:"
      file = STDIN.gets.chomp
      file = 'public/data/data.bib' if file.empty?

      references = BibTeX.open(file, :strip => true)
      references_by_times_cited = references.sort_by { |reference| reference.times_cited }.reverse!
      references_by_year = references.sort_by { |reference| reference.year }

      references_without_first = references_by_year.clone
      references_without_first.shift
      
      references_without_first_by_times_cited = references_without_first.sort_by { |reference| reference.times_cited }.reverse!
      
      years=[]
      total_citations = 0
      references.each do |reference|
        if !reference.year.blank? && !years.include?(reference.year)
          years << reference.year
        end
        total_citations += reference.times_cited
      end
      
      years_without_first = []
      total_citations_without_first = 0
      references_without_first.each do |reference|
        if !reference.year.blank? && !years_without_first.include?(reference.year)
          years_without_first << reference.year
        end
        total_citations_without_first += reference.times_cited
      end
      
      years.sort!
      years_without_first.sort!
      
      references_by_times_cited.each_with_index do |reference,index|
        if index+1 >= reference.times_cited 
          @hindex = index
          break
        end
      end
      
      references_without_first_by_times_cited.each_with_index do |reference,index|
        if index+1 >= reference.times_cited 
          @normalized_hindex = index
          break
        end
      end

      puts "h-Index is: "+@hindex.to_s
      puts "Normalized h-Index is: "+@normalized_hindex.to_s
      puts "m-Index is: "+(@hindex/(years.last.to_f-years.first.to_f)).round(2).to_s
      puts "Normalized m-Index is: "+(@normalized_hindex/(years_without_first.last.to_f-years_without_first.first.to_f)).round(2).to_s
      puts "Total citation count is: "+total_citations.to_s
      puts "Normalized total citation count is: "+total_citations_without_first.to_s
      puts "Average citation count is: "+(total_citations.to_f/references.count).round(2).to_s
      puts "Normalized average citation count is: "+(total_citations_without_first.to_f/references_without_first.count).round(2).to_s
      puts "Date of second publication is: "+references_by_year[1].year
    end
  end
end