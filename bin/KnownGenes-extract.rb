#!/usr/bin/env ruby
# 5UTR
File.open("src/knowngene-names.txt", "r")  do |infp|
  File.open("src/5utr.bed", "w") do |outfp|
  while line = infp.gets
    cols = line.rstrip.split(/\t/)
    # no ORF ~ CDS start != CDS stop, since the start position is 0-based
    if cols[9] != cols[10]
      lefts = cols[12].split(/,/)
      rights = cols[13].split(/,/)
      if cols[6] == '+'
        cdsleft = cols[9].to_i
        0.upto(lefts.length-1) do |i|
          left = lefts[i].to_i
          right = rights[i].to_i
          if right < cdsleft
            outfp.puts [cols[5], left, right, cols[4], 0, '+'].join("\t")
          elsif left < cdsleft
            outfp.puts [cols[5], left, cdsleft, cols[4], 0, '+'].join("\t")
          end
        end
      else
        cdsright = cols[10].to_i
        (rights.length-1).downto(0) do |i|
          left = lefts[i].to_i
          right = rights[i].to_i
          if cdsright < left
            outfp.puts [cols[5], left, right, cols[4], 0, '-'].join("\t")
          elsif cdsright < right
            outfp.puts [cols[5], cdsright, right, cols[4], 0, '-'].join("\t")
          end
        end
      end
    end
  end
end
  infp.close
end

# Upstream 500bp
File.open("src/knowngene-names.txt", "r")  do |infp|
  File.open("src/proxup.bed", "w") do |outfp|
   while line = infp.gets
    cols = line.rstrip.split(/\t/)
    # no ORF ~ CDS start != CDS stop, since the start position is 0-based
    if cols[9] != cols[10]
      lefts = cols[12].split(/,/)
      rights = cols[13].split(/,/)
      if cols[6] == '+'
        left = lefts[0].to_i
        outfp.puts [cols[5], left-500, left, cols[4], 0, '+'].join("\t")
      else
        right = rights[-1].to_i
        outfp.puts [cols[5], right, right+500, cols[4], 0, '-'].join("\t")
      end
    end
  end
end
  infp.close
end

# exon
File.open("src/knowngene-names.txt", "r")  do |infp|
  File.open("src/exon.bed", "w") do |outfp|
  while line = infp.gets
    cols = line.rstrip.split(/\t/)
    if cols[9] != cols[10]
      lefts = cols[12].split(/,/)
      rights = cols[13].split(/,/)
      0.upto(lefts.length-1) do |i|
        left = lefts[i].to_i
        right = rights[i].to_i
        outfp.puts [cols[5], left, right, cols[4], 0, cols[6]].join("\t")
      end
    end
  end
end
  infp.close
end
