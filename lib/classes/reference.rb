class Reference
  attr_accessor :hash
  
  def initialize(hash)
    @hash = hash
  end
  
  def addresses
    fields = ["AD"]
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
    fields = ["PY", "Y1"]
    fields.each do |field|
      if !self.hash[field].nil?
        return self.hash[field][0..3]
      end
    end
  end
  
  def authors
    fields = ["AU", "A1"]
    authors = []
    fields.each do |field|
      if !self.hash[field].nil?
        authors << self.hash[field]
      end
    end
    return authors.flatten
  end
end