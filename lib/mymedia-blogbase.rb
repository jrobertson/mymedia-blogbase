#!/usr/bin/env ruby

# file: mymedia-blogbase.rb

require 'rdiscount'
require 'mymedia'
require 'martile'


class MyMediaBlogBase < MyMedia::Base
  
  def initialize(media_type: 'blog', public_type: 'blog', ext: 'txt', config: nil)
    
    super(media_type: media_type, public_type: public_type, ext: ext, config: config)
    @media_src = "%s/media/%s" % [@home, @public_type]
    @target_ext = '.html'
    @rss = true
    
  end
  
  
  def copy_publish(filename, raw_msg='')    
   
    src_path = File.join(@media_src, filename)

    raise "tags missing or too many tags" if File.open(src_path,'r')\
          .readlines.last.split.length > 5
    
    file_publish(src_path) do |destination, raw_destination|
      
      raw_msg = ''

      File.open(destination,'w') do |f|

        txt_destination = destination.sub(/html$/,'txt')
        FileUtils.cp src_path, txt_destination
        
        doc = html(File.open(src_path, 'r').read, File.basename(txt_destination))
        raw_msg = microblog_title(doc)
        f.write doc.xml
      end

      FileUtils.cp destination, raw_destination
      
      raw_msg
    end

  end  
    


  protected
  
  def html(raw_buffer, filename)

    doc = nil
    
    begin

      buffer = Martile.new(raw_buffer).to_html
      buffer = string_modifier(buffer)

      a = buffer.strip.lines.to_a
      a.first.sub!(/^[^#]/, '#\0') # add a '#' to the title of it's not there
      # make a list from the tags
      
      s = a.pop[/[^>]+$/].split.map{|x| "<li>%s</li>" % x}.join
      a.push "%s<ul>%s</ul>" % [$`, s]
      
      s = a.join.gsub(/(?:^\[|\s\[)[^\]]+\]\((https?:\/\/[^\s]+)/) do |x|
        next x if x[/#{@domain}/]
        s2 = x[/https?:\/\/([^\/]+)/,1].split(/\./)
        r = s2.length >= 3 ? s2[1..-1] :  s2
        "%s [%s]" % [x, r.join('.')]
      end      

      raw_body = "<body>%s</body>" % RDiscount.new(s).to_html
      
      body = Rexle.new(raw_body)
            
      #format the code in the body

      document_modifier(body)

      ul = body.root.xpath('ul').last
      tags = ul.deep_clone

      ul.delete
      dl = "<dl id='info'><dt>Tags:</dt><dd/>\
        <dt>Source:</dt><dd><a href='#{filename}'>#{File.basename(filename)}</a></dd>\
        <dt>Published:</dt><dd>#{Time.now.strftime("%d-%m-%Y %H:%M")}</dd></dl>"

      body.root.add Rexle.new(dl)
      body.root.element('dl/dd').add tags        

      title = "%s %s | %s" % [body.root.text('h1'), \
        tags.xpath('li/text()').map{|x| "[%s]" % x}.join(' '), @domain]

      
      xml = RexleBuilder.new
      
      a = xml.html do 
        xml.head do
          xml.title title
          xml.link({rel: 'stylesheet', type: 'text/css', \
            href: @website + '/blog/layout.css', media: 'screen, projection, tv, print'},'')
          xml.link({rel: 'stylesheet', type: 'text/css', \
            href: @website + '/blog/style.css', media: 'screen, projection, tv, print'},'')          
          add_css_js(xml)      
        end
      end

      doc = Rexle.new(a)
      doc.root.add body
    
    rescue
      @logger.debug "mymedia-blogbase.rb: html: " + ($!).to_s
    end
    
    return doc
  end
  
  def xml(raw_buffer, filename, original_file)

    begin

      buffer = Martile.new(raw_buffer).to_html

      lines = buffer.strip.lines.to_a
      raw_title = lines.shift.chomp
      raw_tags = lines.pop[/[^>]+$/].split

      s = lines.join.gsub(/(?:^\[|\s\[)[^\]]+\]\((https?:\/\/[^\s]+)/) do |x|
        
        next x if x[/#{@domain}/]
        s2 = x[/https?:\/\/([^\/]+)/,1].split(/\./)
        r = s2.length >= 3 ? s2[1..-1] :  s2
        "%s [%s]" % [x, r.join('.')]
      end      

      html = RDiscount.new(s).to_html
      doc = Rexle.new("<body>%s</body>" % html)

      doc.root.xpath('//a').each do |x|

        next unless x.attributes[:href].empty?
        
        new_link = x.text.gsub(/\s/,'_')

        x.attributes[:href] = "#{@dynamic_website}/do/#{@public_type}/new/" + new_link
        x.attributes[:class] = 'new'
        x.attributes[:title] = x.text + ' (page does not exist)'
      end
      
      body = doc.root.children.join

      
      xml = RexleBuilder.new
      
      a = xml.page do 
        xml.summary do
          xml.title raw_title
          xml.tags { raw_tags.each {|tag| xml.tag tag }}
          xml.source_url filename
          xml.source_file File.basename(filename)
          xml.original_file original_file
          xml.published Time.now.strftime("%d-%m-%Y %H:%M")
        end
        
        xml.body body
      end
    
    rescue
      @logger.debug "mymedia-blogbase.rb: html: " + ($!).to_s
    end
    
    return Rexle.new(a)
  end
  

  def microblog_title2(doc)

    summary = doc.root.element('summary')
    title = summary.text('title')
    tags = summary.xpath('tags/tag/text()').map{|x| '#' + x}.join ' '

    url = "%s/%s/yy/mm/dd/hhmmhrs.html" % [@website, @media_type]
    full_title = (url + title + ' ' + tags)

    if full_title.length > 140 then
      extra = full_title.length - 140
      title = title[0..-(extra)] + ' ...'
    end

    title + ' ' + tags

  end  

  def microblog_title(doc)
    
    a = doc.root.element('head/title').text.split(/(?=\[(\w+)\])/)
    tags = a[1..-1].select.with_index {|x, i| i % 2 == 0}.map{|x| '#' + x}.join ' '
    title = a[0]
    url = "%s/%s/yy/mm/dd/hhmmhrs.html" % [@website, @media_type]
    full_title = (url + title + ' ' + tags)
    
    if full_title.length > 140 then
      extra = full_title.length - 140
      title = title[0..-(extra)] + ' ...'
    end

    title + ' ' + tags

  end  
  
  private

  def add_css_js(xml)
    # overridden in the RSF file
  end
  def string_modifier(s)
    # overridden in the RSF file
    s
  end
  def document_modifier(body)
    # overridden in the RSF file
  end


end
