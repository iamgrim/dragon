# encoding: utf-8
module TalkerUtilities
  def valid_name?(name, options={})
    len = name.length
    
    if len < 2
      output "The name must be at least 2 letters long."
      return false
    end
    
    if len > 15
      output "The name must be 15 letters or less."
      return false
    end
    
    unless name =~ /^[a-zA-Z]/
      output "The first character of the name must be a letter of the alphabet."
      return false
    end
    
    if name =~ /[^a-zA-Z0-9]/
      output "The name can only contain letters of the alphabet and numbers."
      return false
    end
    
    if name.downcase == "merlin"
      output "That name is reserved for Chad Tallent. If you are Chad then please send a message to http://twitter.com/dragonworldtalk from your Twitter account to authenticate yourself."
      return false
    end
    
    unless options[:allow_bad_words]
      if %w{admin all announce bank bollocks cunt connect directed everyone everybody foreskin fuck game games item newbie newbies object public private settext shit social socials you wank }.include?(name.downcase)
        output "Sorry, that name can not be used."
        return false
      end
    end
    true
  end
  
  ANSI_COLOURS = {
    'n' => "\033[0m",    # reset
    'N' => "\033[0m", 
    'L' => "\033[1m",    # bold
    'l' => "\033[2m",    # faint
    'u' => "\033[4m",    # underline
    'U' => "\033[4m", 
    'k' => "\033[5m",    # blink
    'K' => "\033[5m",
    'h' => "\033[7m",    # reverse
    'H' => "\033[7m",
    'd' => "\033[0;30m", # black
    'r' => "\033[0;31m", # red
    'g' => "\033[0;32m", # green
    'y' => "\033[0;33m", # yellow/brown
    'b' => "\033[0;34m", # blue
    'p' => "\033[0;35m", # purple
    'c' => "\033[0;36m", # cyan
    'w' => "\033[0;37m", # grey/white
    'D' => "\033[1;30m", # bold black
    'R' => "\033[1;31m", # bold red
    'G' => "\033[1;32m", # bold green
    'Y' => "\033[1;33m", # bold yellow
    'B' => "\033[1;34m", # bold blue
    'P' => "\033[1;35m", # bold purple
    'C' => "\033[1;36m", # bold cyan
    'W' => "\033[1;37m", # bold white
    's' => "\033[0;40m", # bg black
    'e' => "\033[0;41m", # bg red
    'f' => "\033[0;42m", # bg green
    't' => "\033[0;43m", # bg yellow
    'v' => "\033[0;44m", # bg blue
    'o' => "\033[0;45m", # bg purple
    'x' => "\033[0;46m", # bg cyan
    'q' => "\033[0;47m", # bg white
    '^' => '^'
  }.freeze
  
  RANDOM_COLOUR = {
    'a' => %w{y r c p g b w},
    'A' => %w{Y R C P G B W}
  }
  
  def colourise(string, colour_mode)
    if colour_mode == :wands
      string
    else
      case colour_mode
      when :ansi
        colours     = ANSI_COLOURS
      else
        colours     = {'^' => '^'}
      end
  
      stored_string  = ""
      scanner = StringScanner.new(string)
      while match = scanner.scan_until(/\^(\S?)/)
        stored_string << match.slice(0, match.length - scanner.matched_size)
        l = scanner[1]
        l = RANDOM_COLOUR[l][rand(RANDOM_COLOUR[l].length)] if RANDOM_COLOUR.keys.include?(l)
        stored_string << colours[l] if !l.blank? && colours.keys.include?(l)
      end
      stored_string << scanner.rest if scanner.rest?
      stored_string
    end
  end

  def commas_and(list)
    list = list.compact
    if list.empty?
      ""
    else
      last = list.pop
      list.join(", ") + (list.empty? ? last : " and #{last}")
    end
  end
  
  def pluralise(word, amount)
    "#{word}#{amount != 1 ? 's' : ''}"
  end
  
  def is_are(amount)
    amount == 1 ? 'is' : 'are'
  end
  
  def time_in_words(secs)
    secs = secs.to_i
    if secs == 0
      "No time at all"
    else
      buf = []
      [[31536000, "year"], [86400, "day"], [3600, "hour"], [60, "minute"]].each do |amount, name|
        i = secs / amount
        secs %= amount
        buf << pluralise("#{i} #{name}", i) if i > 0
      end
      buf << pluralise("#{secs} second", secs) if secs > 0
      commas_and(buf)
    end
  end
  
  def short_time(secs)
    secs = secs.to_i
    
    days  = secs / 86400 ; secs %= 86400
    hours = secs / 3600  ; secs %= 3600
    mins  = secs / 60    ; secs %= 60
    
    if days > 0
         sprintf "%2dd%2.2dh", days, hours
    elsif hours > 0
         sprintf "%2dh%2.2dm", hours, mins
    else
         sprintf "%2dm%2.2ds", mins, secs
    end
  end
  
  # for boxed content  
  def box(title, text)
    buffer = "^B\u{250C}\u{2500}\u{2524} ^Y#{title} ^B\u{251C}" + ("\u{2500}" * (72 - title.length)) + "\u{2510}^n\n"
    if text.length > 0
    buffer += text.split("\n").map { |s|
      width = 75 + s.length - colourise(s, false).length
      sprintf("^B\u{2502}^n %-#{width}.#{width}s ^B\u{2502}^n", s)
      }.join("\n") + "\n"
    end
    buffer += "^B\u{2514}" + "\u{2500}" * 77 + "\u{2518}^n\n"
  end
  
  # dual-title box!
  def box_extra(title, subtitle, text)
    buffer = "^B\u{250C}\u{2500}\u{2524} ^Y#{title} ^B\u{251C}" + ("\u{2500}" * (67 - (title.length + subtitle.length))) + "\u{2524} ^c#{subtitle} ^B\u{251C}\u{2500}\u{2510}^n\n"
    if text.length > 0
    buffer += text.split("\n").map { |s|
      width = 75 + s.length - colourise(s, false).length
      sprintf("^B\u{2502}^n %-#{width}.#{width}s ^B\u{2502}^n", s)
      }.join("\n") + "\n"
    end
    buffer += "^B\u{2514}" + "\u{2500}" * 77 + "\u{2518}^n\n"
  end
  
  # for content that exceeds the 80 character width box
  def title_line(text)
    "^B\u{2500}\u{2500}\u{2524} ^Y#{text} ^B\u{251C}" + ("\u{2500}" * (73 - text.length)) + "^n"
  end
  
  def blank_line
    "^B\u{2500}" * 79 + "^n\n"
  end
  
  def get_arguments(string, num)
    result = string.blank? ? [] : string.split(/ /, num)
    while result.length < num
      result << ""
    end
    result.map {|s|s.strip!}
    result
  end
  
  def gender_string(type)
    g = self.gender || :female
    Social::GENDER_WORDS.has_key?(type) ? Social::GENDER_WORDS[type][g] : ""
  end
  
  def multi_target?(string)
    string =~ /,/ || string =~ /^[1-9]/
  end

  UNICODE_FALLBACKS = {
    
    "\u{00ab}" => "<<",   # left-pointing double angle quotation mark
    "\u{00bb}" => ">>",   # right-pointing double angle quotation mark
    "\u{00a3}" => "#",   # pound
    "\u{20ac}" => "E",   # euro
    "\u{2013}" => "-",   # en dash
    "\u{2014}" => "-",   # em dash
    "\u{2015}" => "-",   # horizontal bar
    "\u{2018}" => "'",   # open single quote
    "\u{2019}" => "'",   # close single quote
    "\u{201c}" => "\"",  # open double quote
    "\u{201d}" => "\"",  # close double quote
    "\u{20ab}" => "d",   # drogna
    "\u{2591}" => "-",   # bsh grass
    "\u{25cf}" => "*",   # black circle
    "\u{25e6}" => "o",   # empty circle
    "\u{263c}" => "=",   # crater
    "\u{00d7}" => "X",   # multiply
    "\u{25ba}" => ">",   # black right-pointing pointer
    "\u{25c4}" => ">",   # black left-pointing pointer
    "\u{2192}" => "->",  # rightwards arrow
    "\u{2190}" => "<-",  # leftwards arrow
    "\u{266a}" => "o/~", # eighth note
    "\u{266b}" => "o/~", # beamed eighth notes
    "\u{25a0}" => "=",   # black square
    "\u{2500}" => "-",   # box drawing horizontal line
    "\u{2502}" => "|",   # box drawing vertical line
    "\u{250c}" => " ",   # box down and right
    "\u{2510}" => " ",   # box down and left
    "\u{2514}" => " ",   # box up and right
    "\u{2518}" => " ",   # box up and left
    "\u{2524}" => "/",   # box vertical and left
    "\u{251c}" => "\\",  # box vertical and right
    "\u{2640}" => "(F)", # female gender symbol
    "\u{2642}" => "(M)", # male gender symbol
    "\u{2550}" => "=",   # box double horizontal line
    "\u{255e}" => "|",   # box vertical single and right double
    "\u{256a}" => "|",   # box vertical singe and horizontal double
    "\u{2561}" => "|",   # box vertical single and left double
    "\u{2660}" => "(S)", # spade
    "\u{2663}" => "(C)", # club
    "\u{2665}" => "(H)", # heart
    "\u{2666}" => "(D)", # diamond
    "\u{2022}" => "-",   # bullet
    "\u{25a1}" => " ",   # empty square
    "\u{00a0}" => " ",   # no-break space
    "\u{00a1}" => "!",
    "\u{00a2}" => "c",
    "\u{00a5}" => "Y",
    "\u{00a6}" => "|",
    "\u{00a9}" => "(c)",
    "\u{00ab}" => "<<",
    "\u{00ac}" => "!",
    "\u{00ad}" => "-",
    "\u{00ae}" => "(r)",
    "\u{00b1}" => "+-",
    "\u{00bb}" => ">>",
    "\u{00bc}" => "1/4",
    "\u{00bd}" => "1/2",
    "\u{00be}" => "3/4",
    "\u{00bf}" => "?",
    "\u{00c0}" => "A",
    "\u{00c1}" => "A",
    "\u{00c2}" => "A",
    "\u{00c3}" => "A",
    "\u{00c4}" => "A",
    "\u{00c5}" => "A",
    "\u{00c6}" => "AE",
    "\u{00c7}" => "C",
    "\u{00c8}" => "E",
    "\u{00c9}" => "E",
    "\u{00ca}" => "E",
    "\u{00cb}" => "E",
    "\u{00cc}" => "I",
    "\u{00cd}" => "I",
    "\u{00ce}" => "I",
    "\u{00cf}" => "I",
    "\u{00d0}" => "Dh",
    "\u{00d1}" => "N",
    "\u{00d2}" => "O",
    "\u{00d3}" => "O",
    "\u{00d4}" => "O",
    "\u{00d5}" => "O",
    "\u{00d6}" => "O",
    "\u{00d7}" => "x",
    "\u{00d8}" => "O",
    "\u{00d9}" => "U",
    "\u{00da}" => "U",
    "\u{00db}" => "U",
    "\u{00dc}" => "U",
    "\u{00dd}" => "Y",
    "\u{00de}" => "Th",
    "\u{00df}" => "ss",
    "\u{00e0}" => "a",
    "\u{00e1}" => "a",
    "\u{00e2}" => "a",
    "\u{00e3}" => "a",
    "\u{00e4}" => "a",
    "\u{00e5}" => "a",
    "\u{00e6}" => "ae",
    "\u{00e7}" => "c",
    "\u{00e8}" => "e",
    "\u{00e9}" => "e",
    "\u{00ea}" => "e",
    "\u{00eb}" => "e",
    "\u{00ec}" => "i",
    "\u{00ed}" => "i",
    "\u{00ee}" => "i",
    "\u{00ef}" => "i",
    "\u{00f0}" => "dh",
    "\u{00f1}" => "n",
    "\u{00f2}" => "o",
    "\u{00f3}" => "o",
    "\u{00f4}" => "o",
    "\u{00f5}" => "o",
    "\u{00f6}" => "o",
    "\u{00f7}" => "/",
    "\u{00f8}" => "o",
    "\u{00f9}" => "u",
    "\u{00fa}" => "u",
    "\u{00fb}" => "u",
    "\u{00fc}" => "u",
    "\u{00fd}" => "y",
    "\u{00fe}" => "th",
    "\u{00ff}" => "y"
  }
  
  COUNTRIES_ISO3166_1 = {
    "Austria" => "AT", 
    "Belgium" => "BE", 
    "Bulgaria" => "BG", 
    "Cyprus" => "CY", 
    "Czech Republic" => "CZ", 
    "Denmark" => "DK", 
    "Estonia" => "EE", 
    "Finland" => "FI", 
    "France" => "FR", 
    "Germany" => "DE", 
    "Greece" => "GR", 
    "Hungary" => "HU", 
    "Ireland" => "IE", 
    "Italy" => "IT", 
    "Latvia" => "LV", 
    "Lithuania" => "LT", 
    "Luxembourg" => "LU", 
    "Malta" => "MT", 
    "Netherlands" => "NL", 
    "Poland" => "PL", 
    "Portugal" => "PT", 
    "Romania" => "RO", 
    "Slovakia" => "SK", 
    "Slovenia" => "SI", 
    "Spain" => "ES", 
    "Sweden" => "SE", 
    "United Kingdom" => "GB",
    "Afghanistan" => "AF", 
    "Albania" => "AL", 
    "Algeria" => "DZ", 
    "American Samoa" => "AS", 
    "Andorra" => "AD", 
    "Angola" => "AO", 
    "Anguilla" => "AI", 
    "Antarctica" => "AQ", 
    "Antigua And Barbuda" => "AG", 
    "Argentina" => "AR", 
    "Armenia" => "AM", 
    "Aruba" => "AW", 
    "Australia" => "AU", 
    "Azerbaijan" => "AZ", 
    "Bahamas" => "BS", 
    "Bahrain" => "BH", 
    "Bangladesh" => "BD", 
    "Barbados" => "BB", 
    "Belarus" => "BY", 
    "Belize" => "BZ", 
    "Benin" => "BJ", 
    "Bermuda" => "BM", 
    "Bhutan" => "BT", 
    "Bolivia" => "BO", 
    "Bosnia and Herzegowina" => "BA", 
    "Botswana" => "BW", 
    "Bouvet Island" => "BV", 
    "Brazil" => "BR", 
    "British Indian Ocean Territory" => "IO", 
    "Brunei Darussalam" => "BN", 
    "Burkina Faso" => "BF", 
    "Burma" => "MM", 
    "Burundi" => "BI", 
    "Cambodia" => "KH", 
    "Cameroon" => "CM", 
    "Canada" => "CA", 
    "Cape Verde" => "CV", 
    "Cayman Islands" => "KY", 
    "Central African Republic" => "CF", 
    "Chad" => "TD", 
    "Chile" => "CL", 
    "China" => "CN", 
    "Christmas Island" => "CX", 
    "Cocos (Keeling) Islands" => "CC", 
    "Colombia" => "CO", 
    "Comoros" => "KM", 
    "Congo" => "CG", 
    "Congo, the Democratic Republic of the" => "CD", 
    "Cook Islands" => "CK", 
    "Costa Rica" => "CR", 
    "Cote d'Ivoire" => "CI", 
    "Croatia" => "HR", 
    "Cuba" => "CU", 
    "Djibouti" => "DJ", 
    "Dominica" => "DM", 
    "Dominican Republic" => "DO", 
    "East Timor" => "TL", 
    "Ecuador" => "EC", 
    "Egypt" => "EG", 
    "El Salvador" => "SV", 
    "Equatorial Guinea" => "GQ", 
    "Eritrea" => "ER", 
    "Ethiopia" => "", 
    "Falkland Islands" => "FK", 
    "Faroe Islands" => "FO", 
    "Fiji" => "FJ", 
    "French Guiana" => "GF", 
    "French Polynesia" => "PF", 
    "French Southern Territories" => "TF", 
    "Gabon" => "GA", 
    "Gambia" => "GM", 
    "Georgia" => "GE", 
    "Ghana" => "GH", 
    "Gibraltar" => "GI", 
    "Greenland" => "GL", 
    "Grenada" => "GD", 
    "Guadeloupe" => "GP", 
    "Guam" => "GU", 
    "Guatemala" => "GT", 
    "Guinea" => "GN", 
    "Guinea-Bissau" => "GW", 
    "Guyana" => "GY", 
    "Haiti" => "HT", 
    "Heard and Mc Donald Islands" => "HM", 
    "Honduras" => "HN", 
    "Hong Kong" => "HK", 
    "Iceland" => "IS", 
    "India" => "IN", 
    "Indonesia" => "ID", 
    "Israel" => "IL", 
    "Iran" => "IR", 
    "Iraq" => "IQ", 
    "Jamaica" => "JM", 
    "Japan" => "JP", 
    "Jordan" => "JO", 
    "Kazakhstan" => "KZ", 
    "Kenya" => "KE", 
    "Kiribati" => "KI", 
    "Korea, Republic of" => "KP", 
    "Korea (South)" => "KR", 
    "Kuwait" => "KW", 
    "Kyrgyzstan" => "KG", 
    "Lao People's Democratic Republic" => "LA", 
    "Lebanon" => "LB", 
    "Lesotho" => "LS", 
    "Liberia" => "LR", 
    "Liechtenstein" => "LI", 
    "Macau" => "MO", 
    "Macedonia" => "MK", 
    "Madagascar" => "MG", 
    "Malawi" => "MW", 
    "Malaysia" => "MY", 
    "Maldives" => "MV", 
    "Mali" => "ML", 
    "Marshall Islands" => "MH", 
    "Martinique" => "MQ", 
    "Mauritania" => "MR", 
    "Mauritius" => "MU", 
    "Mayotte" => "YT", 
    "Mexico" => "MX", 
    "Micronesia, Federated States of" => "FM", 
    "Moldova, Republic of" => "MD", 
    "Monaco" => "MC", 
    "Mongolia" => "MN", 
    "Montenegro" => "ME",
    "Montserrat" => "MS", 
    "Morocco" => "MA", 
    "Mozambique" => "MZ", 
    "Myanmar" => "MM", 
    "Namibia" => "NA", 
    "Nauru" => "NR", 
    "Nepal" => "NP", 
    "Netherlands Antilles" => "AN", 
    "New Caledonia" => "NC", 
    "New Zealand" => "NZ", 
    "Nicaragua" => "NI", 
    "Niger" => "NE", 
    "Nigeria" => "NG", 
    "Niue" => "NU", 
    "Norfolk Island" => "NF", 
    "Northern Mariana Islands" => "MP", 
    "Norway" => "NO", 
    "Oman" => "OM", 
    "Pakistan" => "PK", 
    "Palau" => "PW", 
    "Panama" => "PA", 
    "Papua New Guinea" => "PG", 
    "Paraguay" => "PY", 
    "Peru" => "PE", 
    "Philippines" => "PH", 
    "Pitcairn" => "PN", 
    "Puerto Rico" => "PR", 
    "Qatar" => "QA", 
    "Reunion" => "RE", 
    "Russia" => "RU", 
    "Rwanda" => "RW", 
    "Saint Kitts and Nevis" => "KN", 
    "Saint Lucia" => "LC", 
    "Saint Vincent and the Grenadines" => "VC", 
    "Samoa (Independent)" => "WS", 
    "San Marino" => "SM", 
    "Sao Tome and Principe" => "ST", 
    "Saudi Arabia" => "SA", 
    "Senegal" => "SN", 
    "Serbia" => "RS", 
    "Seychelles" => "SC", 
    "Sierra Leone" => "SL", 
    "Singapore" => "SG", 
    "Solomon Islands" => "SB", 
    "Somalia" => "SO", 
    "South Africa" => "ZA", 
    "South Georgia and the South Sandwich Islands" => "GS", 
    "South Korea" => "KR", 
    "Sri Lanka" => "LK", 
    "St. Helena" => "SH", 
    "St. Pierre and Miquelon" => "PM", 
    "Suriname" => "SR", 
    "Svalbard and Jan Mayen Islands" => "SJ", 
    "Swaziland" => "SZ", 
    "Switzerland" => "CH", 
    "Taiwan" => "TW", 
    "Tajikistan" => "TJ", 
    "Tanzania" => "TZ", 
    "Thailand" => "TH", 
    "Togo" => "TG", 
    "Tokelau" => "TK", 
    "Tonga" => "TO", 
    "Trinidad and Tobago" => "TT", 
    "Tunisia" => "TN", 
    "Turkey" => "TR", 
    "Turkmenistan" => "TM", 
    "Turks and Caicos Islands" => "TC", 
    "Tuvalu" => "TV", 
    "Uganda" => "UG", 
    "Ukraine" => "UA", 
    "United Arab Emirates" => "AE", 
    "United States" => "US", 
    "United States Minor Outlying Islands" => "UM", 
    "Uruguay" => "UY", 
    "Uzbekistan" => "UZ", 
    "Vanuatu" => "VU", 
    "Vatican City State (Holy See)" => "VA", 
    "Venezuela" => "VE", 
    "Viet Nam" => "VN", 
    "Virgin Islands (British)" => "VG", 
    "Virgin Islands (U.S.)" => "VI", 
    "Wallis and Futuna Islands" => "WF", 
    "Western Sahara" => "EH", 
    "Yemen" => "YE", 
    "Zambia" => "ZM", 
    "Zimbabwe" => "ZW"
  }

  ISO_COUNTRIES = COUNTRIES_ISO3166_1.invert  
  
  def encode_string(message, encoding)
    if encoding == :unicode
      message
    else
      UNICODE_FALLBACKS.each { |utf8, ascii| message = message.gsub(utf8, ascii) }
      
      message.encode("us-ascii", :undef => :replace, :replace => '')
    end
  end
end

# oh god how did this get here I am not good with computer
class String
  def wrap(column)
      self.gsub(/(.{1,#{column}})( +|$\n?)|(.{1,#{column}})/, "\\1\\3\n")
  end
end