require "formula"

Formula.core_files.each do |fi|
    begin
      f = Formula[fi]
    rescue
      opoo "#{fi}: something goes wrong."
      next
    end
      
    next unless f.bottle_defined?

    bottle_spec = f.stable.bottle_specification
    bottle_spec.collector.keys.each do |os|
      next if os == :x86_64_linux
      checksum = bottle_spec.collector[os]
      next unless checksum.hash_type == :sha256
      filename = Bottle::Filename.create(f, os, bottle_spec.revision)
      if ENV['HOMEBREW_TAP'].nil?
          root_url = bottle_spec.root_url
      else
          if ENV['HOMEBREW_BOTTLE_DOMAIN'].nil?
              root_url = "http://homebrew.bintray.com/bottles-#{ENV['HOMEBREW_TAP']}"
          else
              root_url = "#{ENV['HOMEBREW_BOTTLE_DOMAIN']}/bottles-#{ENV['HOMEBREW_TAP']}"
          end
      end
      url = "#{root_url}/#{filename}"

      file = HOMEBREW_CACHE/filename
      next if File.exist?("#{file}.checked")
      FileUtils.rm_f file

      begin
        curl "-sSL", "-m", "600", url, "-o", file
        file.verify_checksum(checksum)
      rescue ErrorDuringExecution
        FileUtils.rm_f file
        opoo "Failed to download #{url}"
        next
      rescue ChecksumMismatchError => e
        FileUtils.rm_f file
        opoo "Checksum mismatch #{url}", e
        next
      end
      FileUtils.touch("#{file}.checked")
      ohai  "#{filename} downloaded"

    end
end
