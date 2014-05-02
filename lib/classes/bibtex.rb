class BibTeX::Names
  def to_array_of_strings
    array_of_strings = []
    self.each do |name|
      array_of_strings << name.to_s
    end
    array_of_strings
  end
end
class BibTeX::Entry
  def authors
    if self.has_field?('author')
      self.author.to_array_of_strings
    else
      return []
    end
  end
  def year
    if self.has_field?('year')
      super.to_s
    else
      ""
    end
  end
  def addresses
    aos = []
    if self.has_field?('affiliation')
      affiliations = self.affiliation.to_s.split(/[\n\r;]/).collect{|a| a.strip}
      affiliations.each do |affiliation|
        aos << Address.new(affiliation)
      end
    end
    return aos
  end
end
