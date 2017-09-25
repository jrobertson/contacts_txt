#!/usr/bin/env ruby

# file: contacts_txt.rb

require 'dynarex'


class ContactsTxt

  attr_reader :to_s
  
  def initialize(src=nil, fields: %w(mobile email dob tags address notes), 
                 username: nil, password: nil)
    
    @fields  = %w(fullname firstname lastname tel) | fields

    txt, type = if src then
      RXFHelper.read(src, username: username, password: password)
    else
      ['', :unknown]
    end
    
    case type
    when :file
      @path, @filename =  File.dirname(src), File.basename(src)
    when :url
      @path, @filename = '.', File.basename(src)
    when :unknown
      @path, @filename = '.', 'contacts.txt'
    end
    
    @dx = txt.lines.length > 1 ? import_to_dx(txt) : new_dx()

  end
  
  def dx()
    @dx
  end

  # returns a Dynarex object
  #    
  def email_list()
    @dx.filter {|x| x.email.length > 0}
  end
  
  def mobile_list()
    @dx.filter {|x| x.mobile.length > 0}
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

  def dx_to_s(dx)
    
    rows = dx.all.map do |row|
      
      h = row.to_h

      fullname = h.delete :fullname
      h.delete :firstname
      h.delete :lastname
      a = h.to_a.reject! {|k,v| v.empty?}

      ([fullname] + a.map {|x| x.join(': ') }).join("\n")
    end
    
    "<?contacts fields='%s'?>\n\n%s" % [@fields, rows.join("\n\n")]
    
  end
  
  def import_to_dx(raw_s)

    s = if raw_s =~ /<?contacts / then

      raw_contacts = raw_s.clone
      s2 = raw_contacts.slice!(/<\?contacts [^>]+\?>/)

      attributes = %w(fields delimiter id).inject({}) do |r, keyword|
        found = s2[/(?<=#{keyword}=['"])[^'"]+/]
        found ? r.merge(keyword.to_sym => found) : r
      end
      
      h = {
        fields: @fields.join(', '), 
      }.merge attributes          

      @fields = h[:fields].split(/ *, */)      

      if h[:root] then
        "\n\n" + h[:root] + "\n" + 
          raw_contacts.strip.lines.map {|line| '  ' + line}.join
      else
        raw_contacts
      end
      
    else
      
      raw_s.lstrip.lines[2..-1].join.strip

    end

    new_dx().import  "--+\n" + s.split(/\s+(?=^[\w\s]+$)/)\
      .map {|x| 'fullname: ' + x }.join("\n")    
    
  end
  
  def new_dx()
    
    Dynarex.new "contacts/contact(#{@fields.join ', '})"
    
  end

end