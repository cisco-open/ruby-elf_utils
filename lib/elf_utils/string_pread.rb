module ElfUtils
  # provide a #pread method for String
  #
  # This refinement is to allow String instances to be used as the underlying
  # IO object for ElfFile.  Intended as a lighter-weight approach than
  # IOString.
  module StringPread
    refine String do
      # read up to `maxlen` bytes from the String starting at `offset`
      # @param maxlen [Integer] maximum number of bytes to read
      # @param offset [Integer] offset to begin reading at
      # @return [String, nil] bytes read or nil
      def pread(maxlen, offset)
        byteslice(offset, maxlen)
      end
    end
  end
end
