require 'restaurant'
require 'support/string_extend'

class Guide
  class Config
    @@actions = %w[list find add quit delete]
    @@action_list = 'Actions: ' + @@actions.join(', ')
    def self.actions
      @@actions
    end

    def self.action_list
      @@action_list
    end
  end

  def initialize(path = nil)
    Restaurant.filepath = path
    if Restaurant.file_usable?
      puts 'Found restaurant file.'
    elsif Restaurant.create_file
      puts 'Created a restaurant file.'
    else
      puts "Exiting.\n\n"
      exit!
    end
  end

  def launch!
    introduction
    result = nil
    until result == :quit
      action, args = get_action
      result = do_action(action, args)
    end

    conclusion
  end

  def get_action
    action = nil
    until Guide::Config.actions.include?(action)
      puts Guide::Config.action_list if action
      print '> '
      user_response = gets.chomp
      args = user_response.downcase.strip.split(' ')
      action = args.shift
    end
    return action, args
  end

  def do_action(action, args=[])
    case action
    when 'list'
      list(args)
    when 'find'
      keyword = args.shift
      find(keyword)
    when 'add'
      add
    when 'quit'
      :quit
    else
      puts "\nI don't know that command. lease choose \"list\", \"add\", \"find\", or \"quit\".\n\n"
    end
  end

  def add
    puts "\nAdd a restaurant\n\n".upcase
    args = {}

    restaurant = Restaurant.build_using_questions

    if restaurant.save
      output_action_header("#{restaurant.name} was added to the list, serving #{restaurant.cuisine} for around $#{restaurant.price}.")
    else
      output_action_header("Save Error: Restaurant not added to the list!")
    end
  end

  def list(args=[])
    sort_order = args.shift
    sort_order = args.shift if sort_order == 'by'
    sort_order = "name" unless ['name', 'cuisine', 'price'].include?(sort_order)

    output_action_header("Listing restaurants")

    restaurants = Restaurant.saved_restaurants
    restaurants.sort! do |r1, r2|
      case sort_order
      when 'name'
        r1.name.downcase <=> r2.name.downcase
      when 'cuisine'
        r1.cuisine.downcase <=> r2.cuisine.downcase
      when 'price'
        r1.price.delete('$').to_i <=> r2.price.delete('$').to_i
      end
    end
    output_restaurant_table(restaurants)
    puts "Sort using: 'list (cuisine, name, or price)'"
  end


  def find(keyword="")
    output_action_header("Find a restaurant")
    if keyword
      restaurants = Restaurant.saved_restaurants
      found = restaurants.select do |rest|
        rest.name.downcase.include?(keyword.downcase) ||
        rest.cuisine.downcase.include?(keyword.downcase) ||
        rest.price.to_i <= keyword.to_i
      end
      output_restaurant_table(found)
    else
      puts "Find using a keyword to search the restaurant list."
      puts "Examples: 'find chicken', 'find Mexican', 'find mex'\n\n"
    end
  end

  def introduction
    puts "\n\n<<< Welcome to the Food Finder >>>\n\n"
    puts 'This program will allow you to list restaurants based'
    puts 'on name, food type, and price. You can also add and'
    puts "remove restaurants from the list.\n\n"
    puts Guide::Config.action_list
  end

  def conclusion
    puts "\n<<< You have exited the program. Goodbye!! >>>\n\n\n"
  end

  private

  def output_action_header(text)
    puts "\n#{text.upcase.center(60)}\n\n"
  end

  def output_restaurant_table(restaurants=[])
    print " " + "Name".ljust(30)
    print " " + "Cuisine".ljust(20)
    print " " + "Price".rjust(6) + "\n"
    puts "-" * 60
    restaurants.each do |rest|
      line = " " << rest.name.ljust(30)
      line << " " + rest.cuisine.ljust(20)
      line << " " + rest.formatted_price.rjust(6)
      puts line
    end
    puts "No listings found" if restaurants.empty?
    puts "-" * 60
  end
end
