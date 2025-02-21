module ElfUtils
  class Section::Strtab < Section::Base
    def [](index)
      @strings ||= bytes
      str = @strings[index..].unpack1("Z*")
      str.empty? ? nil : str
    end
  end
end
