# Introducing the contacts_txt gem

The contacts_txt gem can handle reading and writing contacts in a plain text format. 


In the following example a contacts.txt file is create in the */tmp* directory and the file is parsed by the gem which allows the contact records to be displayed or updated.

file: contacts.txt
<pre>
contacts.txt
============

John Smith 
tel: 0131 334 1212
tags: gas parts 
notes: spoke to him regarding the availablity of part no. 341455. He said he would get back to me.

Tiffany Saunders
email: t.saunders@trouncerecruitment.net
tags: recruitment
note: She said she would call me if there were any new developments
</pre>



    require 'contacts_txt'

    ct = ContactsTxt.new 'contacts.txt'

    puts ct.to_s

Output:

<pre>
contacts.txt
============

John Smith
tel: 0131 334 1212
tags: gas parts
notes: spoke to him regarding the availablity of part no. 341455. He said he would get back to me.

Tiffany Saunders
tags: recruitment
email: t.saunders@trouncerecruitment.net
</pre>

Note: The ordering of fields may change from the original input because of the order in which they appear in the Dynarex schema.

## Resources

* contacts_txt https://rubygems.org/gems/contacts_txt

contacts contacts_txt gem addressbook dynarex
