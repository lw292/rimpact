class Address
  require 'csv'
  
  @@preferred_regions = []
  CSV.foreach("public/preferred/regions.csv") do |row|
    @@preferred_regions << Gnlookup::Region.find(row[0])
  end
  @@preferred_cities = []
  CSV.foreach("public/preferred/cities.csv") do |row|
    @@preferred_cities << Gnlookup::City.find(row[0])
  end
  
  attr_accessor :string
  
  def initialize(string)
    @string = string
  end
  
  # Cities
  # Returns an array of city objects
  def cities
    cities = []
    pieces = self.string.split(",")
    pieces.each do |piece|
      value = piece.strip.chomp(".")
      cities << Gnlookup::City.where("name_n = ?", I18n.transliterate(value).downcase)
    end
    return cities.flatten
  end
  def lone_cities
    return self.cities - self.city_region_combos - self.city_country_combos - self.city_region_country_combos
  end
  def preferred_lone_cities
    return self.lone_cities.reject{|c| !@@preferred_cities.include?(c)}
  end
  
  # Regions
  # Returns an array of regions objects
  def regions
    regions = []
    pieces = self.string.split(",")
    pieces.each do |piece|
      value = piece.strip.chomp(".")
      us_address_pattern = /(^[A-Z]{2}\s\d{5}$)|(^[A-Z]{2}\s\d{5}-\d{4}$)/
      if !(us_address_pattern =~ value).nil? # If this matches a US address pattern
        state_name = value.split(" ")[0].chomp(".") # Get the state name
        regions << Gnlookup::Region.where("name_n = ? OR iso_n = ?", I18n.transliterate(state_name).downcase, I18n.transliterate(state_name).downcase) # Search with state names
      else
        regions << Gnlookup::Region.where("name_n = ? OR iso_n = ?", I18n.transliterate(value).downcase, I18n.transliterate(value).downcase) # Search with raw value
      end
    end
    return regions.flatten
  end
  def lone_regions
    return self.regions - self.city_region_combos.collect{|c| c.region} - self.city_region_country_combos.collect{|c| c.region} - self.region_country_combos
  end
  def preferred_lone_regions
    return self.lone_regions.reject{|r| !@@preferred_regions.include?(r)}
  end
  
  # Zipcodes
  # Returns an array of zipcode objects
  def zipcodes
    zipcodes = []
    pieces = self.string.split(",")
    pieces.each do |piece|
      value = piece.strip.chomp(".")
      us_address_pattern = /(^[A-Z]{2}\s\d{5}$)|(^[A-Z]{2}\s\d{5}-\d{4}$)/
      if !(us_address_pattern =~ value).nil? # If this matches a US address pattern
        zipcode = value.split(" ")[1].split("-")[0]
        zipcodes << Gnlookup::Zipcode.where("zipcode_n = ?", I18n.transliterate(zipcode).downcase)
      end
    end
    return zipcodes.flatten
  end
  
  # Countries
  # Returns an array of country objects
  def countries
    countries = []
    pieces = self.string.split(",")
    pieces.each do |piece|
      value = piece.strip.chomp(".")
      countries << Gnlookup::Country.where("name_n = ? OR iso_n = ? OR iso3_n = ?", I18n.transliterate(value).downcase, I18n.transliterate(value).downcase, I18n.transliterate(value).downcase)
    end
    return countries.flatten
  end
  def lone_countries
    return self.countries - self.city_country_combos.collect{|c| c.country} - self.city_region_country_combos.collect{|c| c.country} - self.region_country_combos.collect{|r| r.country}
  end
  
  # City_region_country combos
  # Returns an array of city objects
  def city_region_country_combos
    combos = []
    if !self.cities.blank? && !self.regions.blank? && !self.countries.blank?
      self.cities.each do |city|
        if self.regions.include?(city.region) && self.countries.include?(city.country)
          combos << city
        end
      end
    end
    return combos
  end
  
  # City_region combos
  # Returns an array of city objects
  def city_region_combos
    combos = []
    if !self.cities.blank? && !self.regions.blank?
      self.cities.each do |city|
        if self.regions.include? city.region
          combos << city
        end
      end
    end
    return combos
  end
  def lone_city_region_combos
    return self.city_region_combos - self.city_region_country_combos
  end
  
  # City_country combos
  # Returns an array of city objects
  def city_country_combos
    combos = []
    if !self.cities.blank? && !self.countries.blank?
      self.cities.each do |city|
        if self.countries.include? city.country
          combos << city
        end
      end
    end
    return combos
  end
  def lone_city_country_combos
    return self.city_country_combos - self.city_region_country_combos
  end
  def preferred_lone_city_country_combos
    return self.lone_city_country_combos.reject{|c| !@@preferred_cities.include?(c)}
  end
    
  # Region_country combos
  # Returns an array of region objects
  def region_country_combos
    combos = []
    if !self.regions.blank? && !self.countries.blank?
      self.regions.each do |region|
        if self.countries.include? region.country
          combos << region
        end
      end
    end
    return combos
  end
  def lone_region_country_combos
    return self.region_country_combos - self.city_region_country_combos.collect{|c| c.region}
  end
  
  # The best one place
  # Could return a City, Region, or a Country
  # Must test the type of returned object when using
  def place
    # City-region-country combos: just return it
    if !self.city_region_country_combos.blank?
      return self.city_region_country_combos[0]
    # If a US zipcode can be identified, just return it
    elsif !self.zipcodes.blank?
      return self.zipcodes[0]
    # City_region combo: just return it.
    # Pretend that it is not ambiguous while there might be a slight chance that it is, but it is not worth our time to check.
    elsif !self.lone_city_region_combos.blank?
      return self.lone_city_region_combos[0]
    # City_country combo: preferred -> non-preferred (non-US city) -> non-preferred (US country)
    # Non-preferred ones need to be extracted and analyzed.
    elsif !self.lone_city_country_combos.blank?
      if !self.preferred_lone_city_country_combos.blank?
        return self.preferred_lone_city_country_combos[0]
      else
        if self.lone_city_country_combos[0].country.name != "United States"
          return self.lone_city_country_combos[0]
        else
          return self.lone_city_country_combos[0].country
        end
      end
    # Region_country combo: just return it
    elsif !self.lone_region_country_combos.blank?
      return self.lone_city_country_combos[0]
    # Country: just return it
    elsif !self.lone_countries.blank?
      return self.lone_countries[0]
    # Region: preferred
    # Non-preferred needs to be extracted and analyzed.
    elsif !self.preferred_lone_regions.blank?
      return self.preferred_lone_regions[0]
    # City: preferred
    # Non-preferred needs to be extracted and analyzed.
    elsif !self.preferred_lone_cities.blank?
      return self.preferred_lone_cities[0]
    # Unparsable, return nil
    else
      return nil
    end
  end
  
  # The ambuiguity place
  # Could return a City, Region
  # Must test the type of returned object when using
  def ambiguity
    # City-region-country combos: not ambiguous
    if !self.city_region_country_combos.blank?
      return false
    # US zipcode: not ambiguous
    elsif !self.zipcodes.blank?
      return false
    # City_region combo: pretend that it is not ambiguous
    elsif !self.lone_city_region_combos.blank?
      return false
    # City_country combo: US non-preferred
    elsif !self.lone_city_country_combos.blank?
      if !self.preferred_lone_city_country_combos.blank?
        return false
      else
        if self.lone_city_country_combos[0].country.name != "United States"
          return false
        else
          return self.lone_city_country_combos[0]
        end
      end
    # Region_country combo: not ambiguous
    elsif !self.lone_region_country_combos.blank?
      return false
    # Country: not ambiguous
    elsif !self.lone_countries.blank?
      return false
    # Region: non-preferred
    elsif !self.lone_regions.blank?
      if !self.preferred_lone_regions.blank?
        return false
      else
        return self.lone_regions[0]
      end
    # City: non-preferred
    elsif !self.lone_cities.blank?
      if !self.preferred_lone_cities.blank?
        return false
      else
        return self.lone_cities[0]
      end
    # Unparsable: not ambiguous
    else
      return nil
    end
  end
  
end
