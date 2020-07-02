#!/usr/bin/env ruby
# Intron
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/Intron.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            lefts = cols[9].split(/,/)
            rights = cols[10].split(/,/)
            len = lefts.length
            if len > 1
                0.upto(len-2) { |i|
                    outfp.puts [cols[2], rights[i], lefts[i+1], "#{cols[12]}|#{cols[1]}", 0, cols[3]].join("\t")
                }
            end
        end
    end
    infp.close
end

# NC-exon
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/NC-exon.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] == cols[6] && cols[5] == cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                len = lefts.length
                if len > 1
                    if cols[3] == '+'
                        1.upto(len-1) { |i|
                            outfp.puts [cols[2], lefts[i], rights[i], "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                        }
                        else
                        (len-1).downto(1) { |i|
                            outfp.puts [cols[2], lefts[i], rights[i], "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                        }
                    end
                end
            end
        end
    end
    infp.close
end

# NC-upstream
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/NC-up.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] == cols[6] && cols[5] == cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                if cols[3] == '+'
                    left = lefts[0].to_i
                    outfp.puts [cols[2], left-500 < 0 ? 0 : left-500, left, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                    else
                    right = rights[-1].to_i
                    outfp.puts [cols[2], right, right+500, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# NC-1stexon
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/NC-1stexon.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] == cols[6] && cols[5] == cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                if cols[3] == '+'
                    outfp.puts [cols[2], lefts[0], rights[0],"#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                    else
                    outfp.puts [cols[2], lefts[-1], rights[-1],"#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# Coding-3UTR
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/Coding-3UTR.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] != cols[6] && cols[5] != cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                if cols[3] == '+'
                    cdsright = cols[7].to_i
                    0.upto(lefts.length-1) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if left < cdsright && cdsright < right
                            outfp.puts [cols[2], cdsright, right, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                            elsif cdsright < left
                            outfp.puts [cols[2], left, right, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                        end
                    }
                    else
                    cdsleft = cols[6].to_i
                    (rights.length-1).downto(0) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if left < cdsleft && cdsleft < right
                            outfp.puts [cols[2], left, cdsleft, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                            elsif right < cdsleft
                            outfp.puts [cols[2], left, right, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                        end
                    }
                end
            end
        end
    end
    infp.close
end

# Coding-CDS
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/Coding-CDS.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] != cols[6] && cols[5] != cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                cdsleft = cols[6].to_i
                cdsright = cols[7].to_i
                0.upto(lefts.length-1) { |i|
                    left = lefts[i].to_i
                    right = rights[i].to_i
                    if left <= cdsleft && cdsright <= right
                        outfp.puts [cols[2], cdsleft, cdsright, "#{cols[12]}|#{cols[1]}", 0, cols[3]].join("\t")
                        elsif left <= cdsleft && cdsleft <= right
                        outfp.puts [cols[2], cdsleft, right, "#{cols[12]}|#{cols[1]}", 0, cols[3]].join("\t")
                        elsif left <= cdsright && cdsright <= right
                        outfp.puts [cols[2], left, cdsright, "#{cols[12]}|#{cols[1]}", 0, cols[3]].join("\t")
                        elsif cdsleft <= left && right <= cdsright
                        outfp.puts [cols[2], left, right, "#{cols[12]}|#{cols[1]}", 0, cols[3]].join("\t")
                    end
                }
            end
        end
    end
    infp.close
end

# Coding-upstream
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/Coding-up.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] != cols[6] && cols[5] != cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                if cols[3] == '+'
                    left = lefts[0].to_i
                    outfp.puts [cols[2], (left-500 < 0 ? 0 : left-500), left, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                    else
                    right = rights[-1].to_i
                    outfp.puts [cols[2], right, right+500, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# Coding-5UTR
File.open("src/Gencode.txt", "r")  do |infp|
    File.open("src/anno/Coding-5UTR.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[5] != cols[6] && cols[5] != cols[7]
                lefts = cols[9].split(/,/)
                rights = cols[10].split(/,/)
                if cols[3] == '+'
                    cdsleft = cols[6].to_i
                    0.upto(lefts.length-1) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if right < cdsleft
                            outfp.puts [cols[2], left, right, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                            elsif left < cdsleft
                            outfp.puts [cols[2], left, cdsleft, "#{cols[12]}|#{cols[1]}", 0, '+'].join("\t")
                        end
                    }
                    else
                    cdsright = cols[7].to_i
                    (rights.length-1).downto(0) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if cdsright < left
                            outfp.puts [cols[2], left, right, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                            elsif cdsright < right
                            outfp.puts [cols[2], cdsright, right, "#{cols[12]}|#{cols[1]}", 0, '-'].join("\t")
                        end
                    }
                end
            end
        end
    end
    infp.close
end
