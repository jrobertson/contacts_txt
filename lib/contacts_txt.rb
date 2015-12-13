#!/usr/bin/env ruby

# file: contacts_txt.rb

require 'dynarex'


class ContactsTxt

  attr_reader :to_s
  
  def initialize(filename='contacts.txt', path: '.', \
                                          fields: %w(tags email address notes))
    @fields  = %w(fullname firstname lastname tel) | fields
    @filename, @path = filename, path
    
    fpath = File.join(path, filename)
    
    @dx = if File.exists?(fpath) then    
      import_to_dx(File.read(fpath))
    else
      new_dx()
    end
  end
  
  def dx()
    @dx
  end

  def save(filename=@filename)
    
    s = dx_to_s(@dx, title: File.basename(filename) )
    File.write File.join(@path, filename), s
        
  end
  
  def to_s()
    dx_to_s @dx
  end

  private

  def dx_to_s(dx, title: File.basename(@filename))
    
    rows = dx.all.map do |row|
      
      h = row.to_h

      fullname = h.delete :fullname
      h.delete :firstname
      h.delete :lastname
      a = h.to_a.reject! {|k,v| v.empty?}

      ([fullname] + a.map {|x| x.join(': ') }).join("\n")
    end
    
    "%s\n%s\n\n%s" % [title, '=' * title.length, rows.join("\n\n")]
    
  end
  
  def import_to_dx(raw_s)

    s = raw_s.lstrip.lines[2..-1].join.strip.\
               split(/\s+(?=^[\w\s]+$)/).map {|x| 'fullname: ' + x }.join("\n")

    new_dx().import  "--+\n" + s
    
  end
  
  def new_dx()
    
    Dynarex.new "contacts/contact(#{@fields.join ', '})"
    
  end

end
