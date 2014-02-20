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