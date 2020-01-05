#!/usr/bin/env ruby

# file: contacts_txt.rb

require 'dynarex'


class ContactsTxt
  include RXFHelperModule

  attr_reader :to_s
  
  def initialize(src=nil, fields: %w(role organisation mobile 
                 sms email dob tags address notes note mobile2 ), 
                 username: nil, password: nil, debug: false)
    
    @debug = debug
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
    when :dfs
      @path, @filename =  File.dirname(src), File.basename(src)
    when :unknown
      @path, @filename = '.', 'contacts.txt'
    end
    
    @dx = txt.lines.length > 1 ? import_to_dx(txt) : new_dx()

  end
  
  def all()
    @dx.all
  end
  
  def dx()
    @dx
  end
  
  def find_by_id(id)
    
    @dx.find_by_id id
    
  end
  
  def find_by_mobile(raw_number, countrycode='44')

    number = Regexp.new raw_number.sub(/^(?:0|#{countrycode})/,'').gsub(/[ -]*/,'')
    
    @dx.all.find {|x| x.mobile.gsub(/[ -]*/,'') =~ number }    

  end  
  
  def find_by_name(s)

    # Appending a hashtag to the name can help with finding the specific record
    # e.g. 'Peter#plumber' or 'Peter #plumber' 
    
    raw_name, tag = s.split('#',2).map(&:strip)
    
    name = Regexp.new "\b#{raw_name}\b|#{raw_name}",  Regexp::IGNORECASE
    puts 'name: ' + name.inspect if @debug
    
    a = @dx.all.select do |x| 
      x.fullname =~ name or x.firstname =~ name or x.lastname =~ name
    end
    
    if tag then
      a.find {|x| x.tags.split.map(&:downcase).include? tag.downcase } 
    else
      a
    end

  end  
  
  def find_by_sms(raw_number, countrycode='44')

    number = Regexp.new raw_number\
        .sub(/^(?:0|#{countrycode})/,'').gsub(/[ -]*/,'')
    
    @dx.all.find {|x| x.sms.gsub(/[ -]*/,'') =~ number \
                  or x.mobile.gsub(/[ -]*/,'') =~ number }    

  end  
  
  # find using the tel, mobile, or mobile2 fields 
  #
  def find_by_telno(raw_number)

    number = Regexp.new raw_number.gsub(/[ -]*/,'')
    
    @dx.all.find do |x|
            
      numbers = %i(tel mobile mobile2).map do |y|
        x.method(y).call.gsub(/[ -]*/,'') if x.respond_to? y
      end
      
      puts 'numbers: ' + numbers.inspect if @debug
      numbers.grep(number).any?
    end

  end    

  # returns a Dynarex object
  #    
  def email_list()
    @dx.filter {|x| x.email.length > 0}
  end
  
  def list_names()
    
    @dx.all.inject([]) do |r, x|
      x.fullname.length >= 1 ? r << x.fullname : r
    end

  end
  
  def mobile_list()
    @dx.filter {|x| x.mobile.length > 0}
  end  

  def multi_tel_index()

    a = @dx.all.map do |x|

      tel = %i(tel mobile mobile2).detect do |name|
        !x.method(name).call.empty?
      end
      next unless tel
      "%s %s" % [x.fullname, x.method(tel).call]
    end.compact 


    # group by first name
    r = a.group_by {|x| x[0]}

    a2 = a.clone

    # group by last name
    r2 = a.group_by {|x| x.split(/ /,2).last[0]}
    c = r2.merge(r)

    c.each do |k, v|

      puts "k: %s v: %s" % [k, v]
      v.concat(r2[k]) if r2[k]  
      
    end

    h = c.sort.each {|k,v| v.uniq!}.to_h

    out = []

    h.each do |k,v|

      out << ' ' + (' ' * 30) + k

      v.each do |x|

        name, phone = x.split(/(?=\d)/,2)
        out << "\n" + (name.length >= 29 ? name[0..26] + '...' : name)
        tel = (' ' + ' ' * (26 - phone.length)) + 't: ' + phone
        out <<  tel + "\n"
        out << ('-' * 30) 

      end  

    end

    puts out.join("\n")

  end

  def save(filename=@filename)
    
    s = dx_to_s(@dx)
    FileX.write File.join(@path, filename), s
    @dx.save File.join(@path, filename.sub(/\.txt$/,'.xml'))
        
  end
  
  def to_dx()
    @dx
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

    new_dx().import  "--+\n" + s.split(/\s+(?=^[\w\s\(\)]+$)/)\
      .map {|x| 'fullname: ' + x }.join("\n")    
    
  end
  
  def new_dx()
    
    Dynarex.new "contacts/contact(#{@fields.join ', '})"
    
  end

end

class ContactsTxtAgent < ContactsTxt
  
  def find_mobile_by_name(s)
    
    result = find_by_name(s)

    r = validate(result)  
    
    numbers = [r.sms.empty? ? r.mobile : r.sms, r.mobile].uniq\
        .map {|x| x.sub(/\([^\)]+\)/,'').strip}
    
    h = {}
    h[:msg] = if numbers.length > 1 then
      "The SMS number for %s is %s and the mobile number is %s" % \
          [r.fullname, *numbers]
    elsif numbers.first.length > 0 then
      "The mobile number for %s is %s" % [r.fullname, numbers.first]
    elsif r.tel.length > 0 then
      "I don't have a mobile number, but the landline telephone " + \
          "number for %s is %s" % [r.fullname, r.tel]
    else
      "I don't have a telephone number for " + r.fullname
    end

    h[:tags] = r.tags.to_s
    h    
  end
  
  def find_tel_by_name(s)
    
    result = find_by_name(s)
    r = validate(result)                    
    
    h = {}
    
    if r.tel.empty? then
      return find_mobile_by_name(s)
    else
      h[:msg] = "The telephone number for %s is %s" % [r.fullname, r.tel]
    end
    
    h[:tags] = r.tags.to_s
    h        
  end

  private
  
  def validate(result)
    
    case result.class.to_s
    when 'RecordX'
      result
    when 'Array'
      result.first
    when 'NilClass'
      return "I couldn't find that name."
    end    
    
  end
  
end
