require 'pry'
require 'json'
require 'active_support/all'
require 'csv'
# cat form_logs.json | jq -r -s  '[.[].log]' > merge.json
json = ARGV[0]

logs_json = JSON.parse(File.read(json), symbolize_names: true)
avarages = logs_json
  .select { |logs| logs.find { |log| log[:action] == 'submit' } } # 完了まで行ってるlog
  .flatten
  .group_by { |log| log[:field] } # field毎の中央値を出力する
  .each_with_object({}) { |(field, logs), dest|
    next dest if field.nil?
    times = logs
      .select { |log| log[:action] == 'update' && !log[:first_updated_at].nil? } # updateかつupdated_atあるのを対象
      .map { |log| Time.parse(log[:last_updated_at]) - Time.parse(log[:first_updated_at]) }.compact.sort

    puts "field: #{field} 中央値: #{times.size % 2 == 0 ? times[times.size/2 - 1, 2].inject(:+) / 2.0 : times[times.size/2]}"
    dest[field] = times
    dest
  }

avarages.each { |k, vs|
  CSV.open("csvs/#{k}.csv", 'w') do |csv|
    csv << [k]
    vs.each { |v|
      csv << [v]
    }
  end
}
