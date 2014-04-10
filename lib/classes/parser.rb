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