require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(number)
  number_arr = number.split('')
  clean_num_arr = []
  number_arr.each do |num|
    clean_num_arr.push(num) if num.match(/[0-9]/)
  end
  clean_number = clean_num_arr.join('')

  if clean_number.length == 10
    clean_number
  elsif clean_number.length == 11
    if clean_number[0] == '1'
      clean_number.slice!(0)
      clean_number
    else
      return 'bad number'
    end
  else
    return 'bad number'
  end

end

def find_hour(date)
  time = Time.strptime(date, "%m/%d/%Y %k:%M")
  time.hour
end

def find_day(date)
  time = Date.strptime(date, "%m/%d/%Y %k:%M")
  day = time.wday
end

def print_most_frequent_hours(hours)
  hash = hours.tally
  max = hash.values.max
  best_hours = hash.select { |k, v| v == max }.keys
  puts best_hours
end

def print_most_frequent_days(days)
  hash = days.tally
  max = hash.values.max
  best_days = hash.select { |k, v| v == max }.keys
  puts best_days
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials

    # legislator_names = legislators.map(&:name)
    # legislators_string = legislator_names.join(", ")
  
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# take this file and make an ERB template from it
template_letter = File.read('form_letter.html')
erb_template = ERB.new template_letter

hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  number = clean_number(row[:homephone])
  date = row[:regdate]

  registration_hour = find_hour(date)
  hours.push(registration_hour.to_i)

  registration_day = find_day(date)
  days.push(registration_day.to_i)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
  
  puts "#{name} #{zipcode} #{number} #{registration_day}"
end

puts 'The most frequent hours are:'
print_most_frequent_hours(hours)

puts 'The most frequent days are:'
print_most_frequent_days(days)
