# Ruby SHA-1 implementation
# Old computer science assignment

require 'stringio'

def sha1_pad_and_prepare_string(string)
  #pad
  original_length_in_bits = string.size * 2 * 2 * 2
  string = string + "\x80"
  until (string.size % 64) == 56
  	#pad 0s until right size
    string += "\0"
  end

  string.force_encoding('ascii-8bit') 
  string = string + [original_length_in_bits >> 32, original_length_in_bits & 0xffffffff].pack("N2")
end

def sha1_hash(string)

  string = sha1_pad_and_prepare_string(string)


  # constraints
  # K(t) = 0x5A827999         ( 0 <= t <= 19) 
  # K(t) = 0x6ED9EBA1         (20 <= t <= 39) 
  # K(t) = 0x8F1BBCDC         (40 <= t <= 59) 
  # K(t) = 0xCA62C1D6         (60 <= t <= 79) 
  k_array = []
  k_array[0] = 0x5A827999
  k_array[1] = 0x6ED9EBA1
  k_array[2] = 0x8F1BBCDC
  k_array[3] = 0xCA62C1D6
  k_array.freeze #immutable

  #f(t;B,C,D) = (B AND C) OR ((NOT B) AND D)         ( 0 <= t <= 19) 
  #f(t;B,C,D) = B XOR C XOR D                        (20 <= t <= 39) 
  #f(t;B,C,D) = (B AND C) OR (B AND D) OR (C AND D)  (40 <= t <= 59) 
  #f(t;B,C,D) = B XOR C XOR D                        (60 <= t <= 79) 
  f_array = []
  f_array[0] =  lambda {|b, c, d| 
  	(b & c) | (b.^(0xffffffff) & d)
  }
  f_array[1] = lambda {|b, c, d| 
  	b ^ c ^ d
  }
  f_array[2] = lambda {|b, c, d| 
  	(b & c) | (b & d) | (c & d)
  }
  f_array[3] =  lambda {|b, c, d| 
  	b ^ c ^ d
  }
  f_array.freeze #immutable
 
  # buffers
  # H0 = 0x67452301
  # H1 = 0xEFCDAB89
  # H2 = 0x98BADCFE
  # H3 = 0x10325476
  # H4 = 0xC3D2E1F0
  h_array = []
  h_array[0] = 0x67452301
  h_array[1] = 0xEFCDAB89
  h_array[2] = 0x98BADCFE
  h_array[3] = 0x10325476
  h_array[4] = 0xC3D2E1F0

  s = lambda{|n, m| 
  	((m << n) &  0xffffffff) | (m >> (32 - n))
  }

 #initialize to prepare for processing the blocks
  io = StringIO.new(string)
  block = ""

#process blocks
  while io.read(64, block)
    arr = block.unpack("N16") #array of int

    (16..79).each {|num| 
    	arr[num] = s[1, arr[num-3] ^ arr[num-8] ^ arr[num-14] ^ arr[num-16]]
    }
 
 	#prepare hash values for this block
    a = h_array[0]
    b = h_array[1]
    c = h_array[2]
    d = h_array[3]
    e = h_array[4]

    80.times do |x|
      if(x < 20)
       i = 0 & 0xffffffff
      elsif (x < 40)
       i = 1 & 0xffffffff
      elsif (x < 60)
       i = 2 & 0xffffffff
      else
       i = 3 & 0xffffffff
      end

      asdf = (s[5, a] + k_array[i] + f_array[i][b, c, d] + arr[x] + e)
      asdf = asdf & 0xffffffff #encode

      #must be done in this order or else they'll overwrite themselves!
      e = d
      d = c
      c = s[30, b]
      b = a
      a = asdf
    end
 
    [a,b,c,d,e].each_with_index { |i,j| 
    	h_array[j] = (h_array[j] + i)
    }
  end
 
  result = h_array.pack("N5") #convert
  return result.unpack('H*') #this is so we can read it
end

#open and read file
file = File.read(ARGV[0])
#puts file.inspect
puts sha1_hash(file)

# To test, uncomment to test if these are equal..because they should be
#puts sha1_hash("pleaseletmein")
#puts "9a528b3faf29b31cc2633b76c4288f0e901aebbf"
