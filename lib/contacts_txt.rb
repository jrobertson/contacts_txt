#!/usr/bin/env ruby

# file: contacts_txt.rb

require 'dynarex'


class ContactsTxt

  attr_reader :to_s
  
  def initialize(raw_filename='contacts.txt', path: File.dirname(raw_filename), \
                        fields: %w(mobile email dob tags address notes))
    @fields  = %w(fullname firstname lastname tel) | fields
    
    @path = path    
    @filename =  path == '.' ? raw_filename : File.basename(raw_filename)

    fpath = File.join(path, @filename)
    
    @dx = File.exists?(fpath) ? import_to_dx(File.read(fpath)) : new_dx()

  end
  
  def dx()
    @dx
  end
  
  # returns a Dynarex object
  #  
  def email_list()
    @dx.filter {|x| x.email.length > 0}
  end

  def save(filename=@filename)
    
    s = dx_to_s(@dx, title: File.basename(filename) )
    File.write File.join(@path, filename), s
    @dx.save File.join(@path, filename.sub(/\.txt$/,'.xml'))
        
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