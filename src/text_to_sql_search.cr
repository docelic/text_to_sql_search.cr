require "yaml"
require "./text_to_sql_search/**"

module TextToSqlSearch
	class Config
		@infix_operator   = /^[<>=:]$/
		@prefix_operator  = /^[<>=]$/
		@inversion_word    = /^(?:\!|not|no)$/
		@ignored_word     = /^(?:than)/i
		@split_regex      = /"(.*?)"|\s+|([()><:=+!-])/
		@strip            = true
		@default_joiner   = "AND"
		@default_negative = false
		@first_element    = "1"
		@passthru_opening = /^[\(]$/
		@passthru_closing = /^[\)]$/
		@and_word         = /^(?:and)/i
		@or_word          = /^(?:or)/i
		@yes_word         = /^(?:\+|has|with|includes)$/
		@no_word          = /^(?:\-|not|no|without)$/
		@quantifier       = /^\d+$/
		
		def initialize; end
		
		YAML.mapping(
			infix_operator:   {type: Regex},
			prefix_operator:  {type: Regex},
			inversion_word:   {type: Regex},
			ignored_word:     {type: Regex},
			split_regex:      {type: Regex},
			strip:            {type: Bool},
			default_joiner:   {type: String},
			default_negative: {type: Bool},
			first_element:    {type: String},
			passthru_opening: {type: Regex},
			passthru_closing: {type: Regex},
			and_word:         {type: Regex},
			or_word:          {type: Regex},
			yes_word:         {type: Regex},
			no_word:          {type: Regex},
		)
	end

	class Base
		# Instantiates new, default config. Returns existing config on subsequent calls.
		def config
			@config||= Config.new
		end
		
		# Given list and current position, peeks into upcoming elements to determine their type.
		# All decision-making is done based on current config.
		def peek_next( list, i, ignored= config.ignored_word)
			while el= list[i+=1]?
				next if el=~ ignored
				return :operator if el=~ config.infix_operator
				return :inversion if el=~ config.inversion_word
				return :todo
			end
		end

		def parse( input)
			# These happen one time to prepare the input line for parsing
			input= input.strip if config.strip
			tokens= input.split( config.split_regex).
			tokens.reject! {|t| t.blank? }
			
			# These initialize one-time and accumulate values as parsing advances
			terms= config.first_element # Accumulated SQL WHERE terms
			values= [] of String        # Their corresponding values (replacements for "?"s)
			count= tokens.size          # Total number of tokens we have for parsing
			i= 0                        # Current position in tokens array
			
			# These are re-set to these same defaults after each key=value is fully processed and a new one begins
			joiner= config.default_joiner      # Default joiner to put in SQL between (key=value) pairs
			negative= config.default_negative  # Are we in positive match or negative by default?
			content_before= ""                 # Small accumulator for pass-thru characters like opening parentheses

			while i< count
				token= tokens[i].strip if config.strip

				case token
				when config.ignored_word
					i+= 1
					next
				when config.inversion_word
					negative= !negative
					i+= 1
					next
				when config.passthru_opening
					content_before+= token
					i+= 1
					next
				when config.passthru_closing
					terms+= token
					i+= 1
					next
				when config.and_word
					joiner=token
					i+= 1
					next
				when config.or_word
					joiner=token
					i+= 1
					next
				when config.yes_word
					# Next word is field
					field= tokens[i+=1]
					value= "0"
					op= "+"
				when config.no_word
					# Next word is field
					field= tokens[i+=1]
					value= "0"
					op= "-"
				when config.quantifier
					# Next word is what and we're done
					value= token
					field= tokens[i+=1]
					op= "="
				when config.prefix_operator
					# Next word is value, next after is field
					value= tokens[i+=1]
					field= tokens[i+=1]
					op= token
				else
				end

			end
		end
	end
end
