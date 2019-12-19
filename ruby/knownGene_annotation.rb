#!/usr/bin/env ruby
# Intron
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/Intron.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            lefts = cols[12].split(/,/)
            rights = cols[13].split(/,/)
            len = lefts.length
            if len > 1
                0.upto(len-2) { |i|
                    outfp.puts [cols[5], rights[i], lefts[i+1], "#{cols[4]}|#{cols[0]}", 0, cols[6]].join("\t")
                }
            end
        end
    end
    infp.close
end

# NC-exon
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/NC-exon.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] == cols[9] && cols[7] == cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                len = lefts.length
                if len > 1
                    if cols[6] == '+'
                        1.upto(len-1) { |i|
                            outfp.puts [cols[5], lefts[i], rights[i], "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                        }
                        else
                        (len-1).downto(1) { |i|
                            outfp.puts [cols[5], lefts[i], rights[i], "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                        }
                    end
                end
            end
        end
    end
    infp.close
end

# NC-upstream
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/NC-up.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] == cols[9] && cols[7] == cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                if cols[6] == '+'
                    left = lefts[0].to_i
                    outfp.puts [cols[5], left-500 < 0 ? 0 : left-500, left, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                    else
                    right = rights[-1].to_i
                    outfp.puts [cols[5], right, right+500, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# NC-1stexon
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/NC-1stexon.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] == cols[9] && cols[7] == cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                if cols[6] == '+'
                    outfp.puts [cols[5], lefts[0], rights[0],"#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                    else
                    outfp.puts [cols[5], lefts[-1], rights[-1],"#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# Coding-3UTR
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/Coding-3UTR.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] != cols[9] && cols[7] != cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                if cols[6] == '+'
                    cdsright = cols[10].to_i
                    0.upto(lefts.length-1) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if left < cdsright && cdsright <= right
                            outfp.puts [cols[5], cdsright, right, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                            elsif cdsright < left
                            outfp.puts [cols[5], left, right, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                        end
                    }
                    else
                    cdsleft = cols[9].to_i
                    (rights.length-1).downto(0) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if left <= cdsleft && cdsleft < right
                            outfp.puts [cols[5], left, cdsleft, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                            elsif right < cdsleft
                            outfp.puts [cols[5], left, right, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                        end
                    }
                end
            end
        end
    end
    infp.close
end

# Coding-CDS
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/Coding-CDS.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] != cols[9] && cols[7] != cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                cdsleft = cols[9].to_i
                cdsright = cols[10].to_i
                0.upto(lefts.length-1) { |i|
                    left = lefts[i].to_i
                    right = rights[i].to_i
                    if left <= cdsleft && cdsright <= right
                        outfp.puts [cols[5], cdsleft, cdsright, "#{cols[4]}|#{cols[0]}", 0, cols[6]].join("\t")
                        elsif left <= cdsleft && cdsleft <= right
                        outfp.puts [cols[5], cdsleft, right, "#{cols[4]}|#{cols[0]}", 0, cols[6]].join("\t")
                        elsif left <= cdsright && cdsright <= right
                        outfp.puts [cols[5], left, cdsright, "#{cols[4]}|#{cols[0]}", 0, cols[6]].join("\t")
                        elsif cdsleft <= left && right <= cdsright
                        outfp.puts [cols[5], left, right, "#{cols[4]}|#{cols[0]}", 0, cols[6]].join("\t")
                    end
                }
            end
        end
    end
    infp.close
end

# Coding-upstream
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/Coding-up.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] != cols[9] && cols[7] != cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                if cols[6] == '+'
                    left = lefts[0].to_i
                    outfp.puts [cols[5], (left-500 < 0 ? 0 : left-500), left, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                    else
                    right = rights[-1].to_i
                    outfp.puts [cols[5], right, right+500, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                end
            end
        end
    end
    infp.close
end

# Coding-5UTR
File.open("src/knowngene-names.txt", "r")  do |infp|
    File.open("src/anno/Coding-5UTR.bed", "w") do |outfp|
        while line = infp.gets
            cols = line.rstrip.split(/\t/)
            if cols[7] != cols[9] && cols[7] != cols[10]
                lefts = cols[12].split(/,/)
                rights = cols[13].split(/,/)
                if cols[6] == '+'
                    cdsleft = cols[9].to_i
                    0.upto(lefts.length-1) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if right < cdsleft
                            outfp.puts [cols[5], left, right, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                            elsif left < cdsleft
                            outfp.puts [cols[5], left, cdsleft, "#{cols[4]}|#{cols[0]}", 0, '+'].join("\t")
                        end
                    }
                    else
                    cdsright = cols[10].to_i
                    (rights.length-1).downto(0) { |i|
                        left = lefts[i].to_i
                        right = rights[i].to_i
                        if cdsright < left
                            outfp.puts [cols[5], left, right, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                            elsif cdsright < right
                            outfp.puts [cols[5], cdsright, right, "#{cols[4]}|#{cols[0]}", 0, '-'].join("\t")
                        end
                    }
                end
            end
        end
    end
    infp.close
end
