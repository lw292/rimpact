namespace :rimpact do
  desc "Creates the necessary files and directories that Rimpact expects if they do not already exist."
  task :setup do
    require 'fileutils'
    # Create some directories in the public directory
    dirnames = %w(data results preferred external)
    dirnames.each do |dirname|
      if !File.directory?("public/"+dirname)
        Dir.mkdir("public/"+dirname)
        puts "Created directory public/"+dirname+"."
      else
        puts "Directory public/"+dirname+" already exists. Skipping..."
      end
    end
    # Create empty csv files to satisfy the Address class requirement
    filenames = %w(preferred/cities.csv preferred/regions.csv)
    filenames.each do |filename|
      if !File.exists?('public/'+filename)
        FileUtils.touch('public/'+filename)
        puts "Created empty public/"+filename+"."
      else
        puts "File public/"+filename+" already exists. Skipping..."
      end
    end
  end
end
