module BBCoder
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def bbcoder(options = {})
      eval_class_methods = ""
      options[:title] ||= "bb"
      options[:column] = [options[:column]] unless options[:column].is_a?(Array)
      options[:column].each do |column_name|
        eval_class_methods += (
          <<-EOV
            def #{options[:title]}_#{column_name}
              return BBCoder.encode(self.#{column_name})
            end
            def #{options[:title]}_#{column_name}=(text)
              self.#{column_name} = BBCoder.decode(ERB::Util.html_escape(text))
            end
          EOV
        ) if column_name
      end
      class_eval eval_class_methods
    end
  end

  class << self
    #:nodoc:
    Tags = {
      :code            => [[/\[code\](.+?)\[\/code\]/i,           '<pre>\1</pre>'],                                    [/<pre>(.+?)<\/pre>/i,                                         '[code]\1[/code]']],
      :quote_name      => [[/\[quote="(.*?)"\](.+?)\[\/quote\]/i, '<blockquote><cite>\1:</cite><br />\2</blockquote>'],[/<blockquote><cite>(.*?):<\/cite><br \/>(.*?)<\/blockquote>/i,'[quote="\1"]\2[/quote]']],
      :quote           => [[/\[quote\](.+?)\[\/quote\]/i,         '<blockquote>\1</blockquote>'],                      [/<blockquote>(.*?)<\/blockquote>/i,                           '[quote]\2[/quote]']],
      :bold            => [[/\[b\](.+?)\[\/b\]/i,                 '<strong>\1</strong>'],                              [/<strong>(.*?)<\/strong>/i,                                   '[b]\1[/b]']],
      :italic          => [[/\[i\](.+?)\[\/i\]/i,                 '<em>\1</em>'],                                      [/<em>(.*?)<\/em>/i,                                           '[i]\1[/i]']],
      :underline       => [[/\[u\](.+?)\[\/u\]/i,                 '<u>\1</u>'],                                        [/<u>(.*?)<\/u>/i,                                             '[u]\1[/u]']],
      :email_name      => [[/\[email=(.+?)\](.+?)\[\/email\]/i,   '<a href="mailto:\1">\2</a>'],                       [/<a.*?href="mailto:(.*?)".*?>(.*?)<\/a>/i,                    '[email=\1]\2[/email]']],
      :email           => [[/\[email\](.+?)\[\/email\]/i,         '<a href="mailto:\1">\1</a>'],                       [/<a.*?href="mailto:(.*?)".*?>(.*?)<\/a>/i,                    '[email=\1]\2[/email]']],
      :url_title       => [[/\[url=(.+?)\](.+?)\[\/url\]/i,       '<a href="\1">\2</a>'],                              [/<a.*?href="(.*?)".*?>(.*?)<\/a>/i,                           '[url=\1]\2[/url]']],
      :url             => [[/\[url\](.+?)\[\/url\]/i,             '<a href="\1">\1</a>'],                              [/<a.*?href="(.*?)".*?>(.*?)<\/a>/i,                           '[url=\1]\2[/url]']],
      :image           => [[/\[img\](.+?)\[\/img\]/i,             '<img src="\1" />'],                                 [/<img.*?src="(.*?)".*?\/>/i,                                  '[img]\1[/img]']],
      :image_alt       => [[/\[img=(.+?)\](.+?)\[\/img\]/i,       '<img src="\1" alt="\2" />'],                        [/<img.*?src="(.*?)".*?alt="(.*?)".*?\/>/i,                    '[img=\1]\2[/img]']],
      :size            => [[/\[size=(\d{1,2})\](.+?)\[\/size\]/i, '<span style="font-size:\1px">\2</span>'],           [/<span.*?style="font-size:(.*?)px".*?>(.*?)<\/span>/i,        '[size=\1]\2[/size]']],
      :color           => [[/\[color=([^;]+?)\](.+?)\[\/color\]/i,'<span style="color: \1">\2</span>'],                [/<span.*?style="color:(.*?)".*?>(.*?)<\/span>/i,              '[color=\1]\2[/color]']],
      :br              => [[/\[br\]/i,                            '<br/>'],                                            [/<br\/>/i,                                                    "[br]"]],
      :br_n            => [[/\n/i,                                '<br/>'],                                            [/\n/i,                                                        "[br]"]],
      :list_item       => [[/\[\*\](.+?)\n/i,                     '<li>\1</li>'],                                      [/<li>(.*?)<\/li>/i,                                           "[*]\1\n"]], #must down with [br]
      :list            => [[/\[list\](.+?)\[\/list\]/i,           '<ul>\1</ul>'],                                      [/<ul>(.*?)<\/ul>/i,                                           '[list]\1[/list]']],
      :list_order      => [[/\[list=([1AaIi])\](.+?)\[\/list\]/i, '<ol type="\1">\2</ol>'],                            [/<ol.*?type="(.*?)".*?>(.*?)<\/ol>/i,                         '[list=\1]\2[/list]']]
    }
    # Tags in this list are invoked. To deactivate a particular tag, call BBCodeizer.deactivate.
    # These names correspond to either names above or methods in this module.
    TagList = [:code,:quote_name,:quote,:bold,:italic,:underline,:email_name,:email,:url_title,:url,:image,:image_alt,:size,:color,:br,:br_n,:list_item,:list,:list_order]

    # Parses all bbcode in +text+ and returns a new HTML-formatted string.

    def encode(text)
      code(text,:enbbcode) if text
    end
    def decode(text)
      code(text,:debbcode) if text
    end

    # Configuration option to deactivate particular +tags+.
    def deactivate(*tags)
      tags.each { |t| TagList.delete(t) }
    end

    # Configuration option to change the replacement string used for a particular +tag+. The source
    # code should be referenced to determine what an appropriate replacement +string+ would be.
    def encode_by(tag, string)
      Tags[tag][0][1] = string
    end
    def decode_by(tag, string)
      Tags[tag][1][1] = string
    end
    
  private
=begin
    def code(string)
      # code tags must match, else don't do any replacing.
      if string.scan(Tags[:start_code].first).size == string.scan(Tags[:end_code].first).size
        encode(string, :start_code, :end_code)
      end
    end
  
    def quote(string)
      # quotes must match, else don't do any replacing
      if string.scan(Tags[:start_quote].first).size == string.scan(Tags[:end_quote].first).size
        encode(string, :start_quote_with_cite, :start_quote_sans_cite, :end_quote)
      end
    end
=end
    def code(text , method)
      text = text.dup
      TagList.each do |tag|
        if Tags.has_key?(tag)
          self.send(method, text, tag)
        else
          self.send(tag, text)
        end
      end
      text
    end
    def enbbcode(string, *tags)
      tags.each do |tag|
        string.gsub!(*Tags[tag][1])
      end
    end
    def debbcode(string, *tags)
      tags.each do |tag|
        string.gsub!(*Tags[tag][0])
      end
    end
  end
end