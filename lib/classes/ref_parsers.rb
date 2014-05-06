require 'ref_parsers'

class RefParsers::RISParser
  def initialize
    @type_key = "TY"
    @types = %w(ABST ADVS ART BILL BOOK CASE CHAP COMP CONF CTLG DATA ELEC GEN HEAR ICOMM INPR JFULL JOUR MAP MGZN MPCT MUSIC NEWS PAMP PAT PCOMM RPRT SER SLIDE SOUND STAT THES UNBILl UNPB VIDEO WEB)
    @terminator_key = "ER"
    @line_regex = /^([A-Z][A-Z0-9])  -( (.*))?$/
    @key_regex_order = 1
    @value_regex_order = 3
    @regex_match_length = 4
    @key_value_separator = "  - "
    @file_type = "RIS"
    @key_prefix = ""
  end
end

class RefParsers::EndNoteParser
  def initialize
    @type_key = "0"
    @types = ["Generic", "Artwork", "Audiovisual Material", "Bill", "Book", "Book Section", "Case", "Chart or Table", "Classical Work", "Computer Program", "Conference Paper", "Conference Proceedings", "Edited Book", "Equation", "Electronic Article", "Electronic Book", "Electronic Source", "Figure", "Film or Broadcast", "Government Document", "Hearing", "Journal Article", "Legal Rule/Regulation", "Magazine Article", "Manuscript", "Map", "Newspaper Article", "Online Database", "Online Multimedia", "Patent", "Personal Communication", "Report", "Statute", "Thesis", "Unpublished Work", "Unused 1", "Unused 2", "Unused 3"]
    @terminator_key = nil
    @line_regex = /^%([A-NP-Z0-9\?\@\!\#\$\]\&\(\)\*\+\^\>\<\[\=\~])\s+(.*)$/
    @key_regex_order = 1
    @value_regex_order = 2
    @regex_match_length = 3
    @key_value_separator = " "
    @file_type = "EndNote"
    @key_prefix = "%"
  end
end

class RefParsers::LineParser
  def open(filename)
    # Read the file content, but remove the initial bom characters
    body = File.open(filename, "r:bom|utf-8").read().strip
    # Add keys to values separated by newlines
    last_key = ""
    data = ""
    body.lines.each do |line|
      if !line.blank?
        m = line.match(@line_regex)
        if m && m.length == @regex_match_length
          last_key = m[@key_regex_order]
          new_line = line
        else
          new_line = @key_prefix + last_key + @key_value_separator + line
        end
      else
        new_line = line
      end
      data << new_line + "\n"
    end
    # Parse them into entries
    entries = parse(data)
    # Convert entries to reference objects
    references = []
    entries.each do |entry|
      references << RefParsers::Reference.new(entry, @file_type)
    end
    references
  end
end

class RefParsers::Reference
  attr_accessor :hash, :file_type

  def initialize(hash, file_type)
    @hash = hash
    @file_type = file_type
  end

  def addresses
    if @file_type == "RIS"
      fields = ["AD"]
    elsif @file_type == "EndNote"
      fields = ["+"]
    end
    addresses = []
    aos = []
    fields.each do |field|
      if !self.hash[field].nil?
        addresses << self.hash[field]
      end
    end
    addresses.flatten.each do |a|
      aos << Address.new(a)
    end
    return aos
  end

  def year
    if @file_type == "RIS"
      fields = ["PY", "Y1"]
    elsif @file_type == "EndNote"
      fields = ["D"]
    end
    fields.each do |field|
      if !self.hash[field].nil?
        return self.hash[field][0..3]
      end
    end
  end

  def authors
    if @file_type == "RIS"
      fields = ["AU", "A1"]
    elsif @file_type == "EndNote"
      fields = ["A"]
    end
    authors = []
    fields.each do |field|
      if !self.hash[field].nil?
        authors << self.hash[field]
      end
    end
    return authors.flatten
  end
end
