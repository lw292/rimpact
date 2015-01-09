require 'bibtex'

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
  def times_cited
    if self.has_field?('note')
      regex = /(Cited By :|Times Cited: )(\d+)/
      if !regex.match(self.note.to_s).nil?
        regex.match(self.note.to_s)[2].to_i
      else
        0
      end
    else
      0
    end
  end
end
