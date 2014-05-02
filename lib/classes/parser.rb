class RefParsers::RISParser
  def initialize
    @type_key = "TY"
    @types = %w(ABST ADVS ART BILL BOOK CASE CHAP COMP CONF CTLG DATA ELEC GEN HEAR ICOMM INPR JFULL JOUR MAP MGZN MPCT MUSIC NEWS PAMP PAT PCOMM RPRT SER SLIDE SOUND STAT THES UNBILl UNPB VIDEO WEB)
    @terminator_key = "ER"
    @line_regex = /^([A-Z][A-Z0-9])  -( (.*))?$/
    @key_regex_order = 1
    @value_regex_order = 3
    @regex_match_length = 4
  end
  def open(file)
    body = File.open(file, "r:bom|utf-8").read().strip
    line_regex = /^([A-Z][A-Z0-9])  -( (.*))?$/
    key_regex_order = 1
    regex_match_length = 4
    last_key = ""
    File.open(file, 'w') do |new_file| 
      body.lines.each do |line|
        if !line.blank?
          m = line.match(line_regex)
          if m && m.length == regex_match_length
            last_key = m[key_regex_order]
            new_line = line
          else
            new_line = last_key + "  - " + line
          end
        else
          new_line = line
        end
        new_file << new_line
      end
    end
    super
  end
end
class RefParsers::LineParser
  def open(filename)
    references = []
    entries = parse(File.read(filename, encoding: 'UTF-8'))
    entries.each do |entry|
      references << Reference.new(entry)
    end
    references
  end
end